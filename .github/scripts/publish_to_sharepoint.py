#!/usr/bin/env python3
"""
publish_to_sharepoint.py

Called by the GitHub Action on every push to main that changes a lesson file.

For each changed Markdown file:
  1. Reads the file and extracts the H1 title
  2. Converts Markdown to HTML
  3. Creates or updates a SharePoint site page via Microsoft Graph API
  4. Publishes the page so it's immediately visible to team members

After all pages are published:
  5. Scans the repo for ALL existing day-XX.md files
  6. Rebuilds the SharePoint site navigation automatically, grouped by week:

     ☁️ Cloud Security Program
     ├── 🏠 Home
     ├── 📋 Prerequisites
     ├── 📅 Week 1: Foundations & Visibility
     │   ├── Day 01 — Account Hardening & MFA
     │   ├── Day 02 — AWS Config
     │   └── ...
     ├── 📅 Week 2: Zero Trust Identity
     │   └── ...
     └── ...

  No manual SharePoint navigation editing required — ever.

Usage:
    python publish_to_sharepoint.py changed_files.txt

Where changed_files.txt is a newline-separated list of relative file paths,
e.g.:
    week-1/day-01.md
    week-1/day-02.md
"""

import os
import sys
import re
import glob
import markdown
import requests
import msal


# ── Week metadata ─────────────────────────────────────────────────────────────
# Used to build readable week headings in the navigation.
# Update this if you rename a week theme.

WEEK_TITLES = {
    "week-1": "Week 1: Foundations & Visibility",
    "week-2": "Week 2: Zero Trust Identity",
    "week-3": "Week 3: Network & Data Protection",
    "week-4": "Week 4: Detection & Response",
}


# ── Authentication ────────────────────────────────────────────────────────────

def get_access_token() -> str:
    """Authenticate with Azure AD using client credentials and return a Graph API token."""
    authority = f"https://login.microsoftonline.com/{os.environ['AZURE_TENANT_ID']}"

    app = msal.ConfidentialClientApplication(
        client_id=os.environ["AZURE_CLIENT_ID"],
        client_credential=os.environ["AZURE_CLIENT_SECRET"],
        authority=authority,
    )
    result = app.acquire_token_for_client(
        scopes=["https://graph.microsoft.com/.default"]
    )

    if "access_token" not in result:
        error = result.get("error_description", "Unknown authentication error")
        print(f"❌ Authentication failed: {error}")
        sys.exit(1)

    return result["access_token"]


# ── SharePoint: Pages ─────────────────────────────────────────────────────────

def get_site_id(token: str, site_url: str) -> str:
    """Resolve a SharePoint site URL to its Graph API site ID."""
    match = re.match(r"https://([^/]+)(/.*)", site_url)
    if not match:
        print(f"❌ Cannot parse SharePoint site URL: {site_url}")
        sys.exit(1)

    hostname, path = match.groups()
    url = f"https://graph.microsoft.com/v1.0/sites/{hostname}:{path}"
    resp = requests.get(url, headers={"Authorization": f"Bearer {token}"})
    resp.raise_for_status()
    return resp.json()["id"]


def get_site_url_base(site_url: str) -> str:
    """Extract the base URL (scheme + hostname) from the full SharePoint site URL.

    e.g. 'https://contoso.sharepoint.com/sites/cloud-security-mastery'
      →  'https://contoso.sharepoint.com'
    """
    match = re.match(r"(https://[^/]+)", site_url)
    return match.group(1) if match else site_url


def get_site_path(site_url: str) -> str:
    """Extract just the site path from the full SharePoint site URL.

    e.g. 'https://contoso.sharepoint.com/sites/cloud-security-mastery'
      →  '/sites/cloud-security-mastery'
    """
    match = re.match(r"https://[^/]+(/.*)", site_url)
    return match.group(1) if match else "/"


def list_all_pages(token: str, site_id: str) -> list[dict]:
    """Return a list of all pages in the SharePoint site's Pages library."""
    url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/pages"
    resp = requests.get(url, headers={"Authorization": f"Bearer {token}"})
    resp.raise_for_status()
    return resp.json().get("value", [])


def find_existing_page(token: str, site_id: str, page_name: str) -> str | None:
    """Return the page ID if a page with this name already exists, else None."""
    for page in list_all_pages(token, site_id):
        if page.get("name") == page_name:
            return page["id"]
    return None


def upsert_page(token: str, site_id: str, page_name: str, page_title: str, html_content: str) -> str:
    """
    Create a new SharePoint page, or update it if one with this name already exists.
    Returns the page ID.
    """
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    payload = {
        "@odata.type": "#microsoft.graph.sitePage",
        "name": page_name,
        "title": page_title,
        "canvasLayout": {
            "horizontalSections": [
                {
                    "layout": "oneColumn",
                    "columns": [
                        {
                            "width": 12,
                            "webparts": [
                                {
                                    "@odata.type": "#microsoft.graph.textWebPart",
                                    "innerHtml": html_content,
                                }
                            ],
                        }
                    ],
                }
            ]
        },
    }

    existing_id = find_existing_page(token, site_id, page_name)

    if existing_id:
        url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/pages/{existing_id}"
        resp = requests.patch(url, headers=headers, json=payload)
    else:
        url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/pages"
        resp = requests.post(url, headers=headers, json=payload)

    if resp.status_code not in (200, 201):
        print(f"❌ Failed to upsert page '{page_name}': {resp.status_code}\n{resp.text}")
        resp.raise_for_status()

    page_id = resp.json()["id"]

    # Publish immediately so it's visible to all site members
    publish_url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/pages/{page_id}/publish"
    requests.post(publish_url, headers={"Authorization": f"Bearer {token}"})

    return page_id


# ── SharePoint: Navigation ────────────────────────────────────────────────────

def build_nav_nodes(site_url: str, all_lesson_files: list[str]) -> list[dict]:
    """
    Build the full navigation node tree from all lesson files that exist in the repo.

    Structure produced:
        🏠 Home               → /sites/cloud-security-mastery
        📋 Prerequisites      → /sites/cloud-security-mastery/SitePages/Prerequisites.aspx
        📅 Week 1: Foundations & Visibility   (heading, no link)
            Day 01 — Account Hardening & MFA  → /SitePages/Week-1-Day-01.aspx
            Day 02 — AWS Config               → /SitePages/Week-1-Day-02.aspx
            ...
        📅 Week 2: Zero Trust Identity
            ...
    """
    site_path = get_site_path(site_url)
    pages_base = f"{site_path}/SitePages"

    # Group lesson files by week, sorted
    by_week: dict[str, list[str]] = {}
    for filepath in sorted(all_lesson_files):
        parts = filepath.replace("\\", "/").split("/")
        week  = parts[0]  # e.g. week-1
        by_week.setdefault(week, []).append(filepath)

    nodes = []

    # Home link
    nodes.append({
        "displayName": "🏠 Home",
        "webUrl": site_path,
        "children": [],
    })

    # Prerequisites link
    nodes.append({
        "displayName": "📋 Prerequisites",
        "webUrl": f"{pages_base}/Prerequisites.aspx",
        "children": [],
    })

    # One heading per week, with day pages as children
    for week_key in sorted(by_week.keys()):
        week_label = WEEK_TITLES.get(week_key, week_key.replace("-", " ").title())
        children = []

        for filepath in by_week[week_key]:
            page_name  = filepath_to_page_name(filepath)        # Week-1-Day-01
            page_title = extract_h1_title_from_file(filepath)   # Day 1 — AWS Account...
            children.append({
                "displayName": page_title,
                "webUrl": f"{pages_base}/{page_name}.aspx",
                "children": [],
            })

        nodes.append({
            "displayName": f"📅 {week_label}",
            "webUrl": "",          # week headings are non-clickable section labels
            "children": children,
        })

    return nodes


def update_navigation(token: str, site_id: str, site_url: str, all_lesson_files: list[str]) -> None:
    """
    Rebuild the SharePoint site's left-hand navigation from scratch using
    all lesson files currently present in the repo.

    SharePoint's navigation is managed via the site's NavigationLinks API.
    We replace the entire navigation on each run so it always reflects the
    current state of the repo — no stale links, no manual cleanup needed.
    """
    print("\n  Rebuilding site navigation...")

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    # Fetch the current navigation nodes so we can delete them first
    nav_url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/drive/root/children"

    # Use the SharePoint REST API for navigation (Graph doesn't expose nav directly)
    # We call the SharePoint REST endpoint via the same token
    sp_base = get_site_url_base(site_url)
    site_path = get_site_path(site_url)
    rest_base = f"{sp_base}{site_path}/_api/navigation/menustate"

    # Build the full navigation payload in SharePoint's MenuState format
    nav_nodes = build_nav_nodes(site_url, all_lesson_files)

    menu_nodes = []
    node_id = 1000  # SharePoint navigation nodes need unique integer IDs

    for top in nav_nodes:
        top_node = {
            "Id":          str(node_id),
            "Title":       top["displayName"],
            "Url":         top["webUrl"],
            "IsDeleted":   False,
            "IsHidden":    False,
            "Nodes":       [],
        }
        node_id += 1

        for child in top.get("children", []):
            top_node["Nodes"].append({
                "Id":        str(node_id),
                "Title":     child["displayName"],
                "Url":       child["webUrl"],
                "IsDeleted": False,
                "IsHidden":  False,
                "Nodes":     [],
            })
            node_id += 1

        menu_nodes.append(top_node)

    payload = {
        "menuState": {
            "StartingNodeTitle": "Quick launch",
            "SPSitePrefix":      "/",
            "SPWebPrefix":       site_path,
            "FriendlyUrlPrefix": "",
            "SimpleUrl":         "",
            "Nodes":             menu_nodes,
        }
    }

    sp_headers = {
        "Authorization": f"Bearer {token}",
        "Accept":        "application/json;odata=verbose",
        "Content-Type":  "application/json;odata=verbose",
    }

    resp = requests.post(rest_base, headers=sp_headers, json=payload)

    if resp.status_code in (200, 204):
        print(f"  ✅ Navigation updated — {len(all_lesson_files)} lesson(s) in menu")
    else:
        # Navigation update failing should not fail the whole publish run —
        # pages are already live, nav is a convenience layer
        print(f"  ⚠️  Navigation update returned {resp.status_code} — pages are still published")
        print(f"      Response: {resp.text[:300]}")


# ── Markdown processing ───────────────────────────────────────────────────────

def convert_markdown_to_html(md_text: str) -> str:
    """Convert Markdown to HTML. Supports tables, fenced code blocks, and TOC."""
    return markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "toc", "nl2br"],
    )


def extract_h1_title(md_text: str) -> str:
    """Extract the first H1 heading from Markdown text as the page title."""
    match = re.search(r"^#\s+(.+)$", md_text, re.MULTILINE)
    return match.group(1).strip() if match else "Untitled Lesson"


def extract_h1_title_from_file(filepath: str) -> str:
    """Read a file and extract its H1 title. Returns a fallback if the file is missing."""
    try:
        with open(filepath, encoding="utf-8") as f:
            return extract_h1_title(f.read())
    except FileNotFoundError:
        # File exists in a previous commit but not checked out — use the filename
        basename = os.path.splitext(os.path.basename(filepath))[0]
        return basename.replace("-", " ").title()


def filepath_to_page_name(filepath: str) -> str:
    """
    Derive a unique, URL-safe SharePoint page name from the lesson filepath.

    Example:
        'week-1/day-01.md'  →  'Week-1-Day-01'
        'week-3/day-17.md'  →  'Week-3-Day-17'
    """
    parts = filepath.replace("\\", "/").split("/")
    week     = parts[0] if len(parts) > 1 else "week-0"    # week-1
    basename = os.path.splitext(parts[-1])[0]               # day-01
    return f"{week}-{basename}".replace(" ", "-").title()   # Week-1-Day-01


def discover_all_lesson_files() -> list[str]:
    """
    Scan the repo for all day-XX.md lesson files across all weeks.
    Returns paths sorted by week then day number, e.g.:
        ['week-1/day-01.md', 'week-1/day-02.md', ..., 'week-4/day-28.md']
    """
    pattern = os.path.join("week-*", "day-*.md")
    files   = glob.glob(pattern)

    def sort_key(path):
        # Sort by (week number, day number) so nav is always in correct order
        week_match = re.search(r"week-(\d+)", path)
        day_match  = re.search(r"day-(\d+)", path)
        week_num   = int(week_match.group(1)) if week_match else 0
        day_num    = int(day_match.group(1))  if day_match  else 0
        return (week_num, day_num)

    return sorted(files, key=sort_key)


# ── Main ──────────────────────────────────────────────────────────────────────

def main(changed_files_path: str) -> None:
    with open(changed_files_path) as f:
        changed_files = [line.strip() for line in f if line.strip()]

    if not changed_files:
        print("No lesson files changed — nothing to publish.")
        return

    print(f"Publishing {len(changed_files)} lesson file(s) to SharePoint...\n")

    token    = get_access_token()
    site_url = os.environ["SHAREPOINT_SITE_URL"]
    site_id  = get_site_id(token, site_url)

    success, failed = 0, 0

    # ── Step 1: Publish each changed file ─────────────────────────────────────
    for filepath in changed_files:
        if not os.path.exists(filepath):
            print(f"  ⚠️  Skipping '{filepath}' — file not found in checkout")
            failed += 1
            continue

        with open(filepath, encoding="utf-8") as f:
            md_text = f.read()

        page_title = extract_h1_title(md_text)
        page_name  = filepath_to_page_name(filepath)
        html       = convert_markdown_to_html(md_text)

        print(f"  → {filepath}")
        print(f"     Title : {page_title}")
        print(f"     Page  : {page_name}")

        try:
            upsert_page(token, site_id, page_name, page_title, html)
            print(f"     ✅ Published\n")
            success += 1
        except Exception as e:
            print(f"     ❌ Failed: {e}\n")
            failed += 1

    print(f"Pages done. {success} published, {failed} failed.")

    # ── Step 2: Rebuild navigation from all lesson files in the repo ──────────
    # We scan for *all* day-XX.md files (not just the ones that changed) so the
    # nav always reflects the complete current state of the repo.
    all_lesson_files = discover_all_lesson_files()
    print(f"\n  Found {len(all_lesson_files)} total lesson file(s) in repo")

    update_navigation(token, site_id, site_url, all_lesson_files)

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: publish_to_sharepoint.py <changed_files.txt>")
        sys.exit(1)
    main(sys.argv[1])
