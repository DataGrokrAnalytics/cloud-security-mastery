# Publishing Setup Guide
## GitHub → SharePoint → Microsoft Teams

This guide walks you and your co-maintainers through the one-time setup to
wire the repo to SharePoint and Teams. Once done, merging a PR is all it
takes to publish new content — no manual copying.

**Time to complete:** ~2 hours
**Who does this:** You (repo owner) + someone with SharePoint site admin access
**Prerequisites:** Full M365 tenant access, GitHub repo created

---

## Overview

```
Step 1 — Create the SharePoint Communication Site
Step 2 — Register an Azure App (GitHub needs permission to write to SharePoint)
Step 3 — Add GitHub Secrets (credentials stored securely in the repo)
Step 4 — Add the GitHub Action (publishes content on every merge to main)
Step 5 — Set up the Teams channel and tabs
Step 6 — Set up the Power Automate flow (auto-posts to Teams on publish)
Step 7 — Test end-to-end
```

---

## Step 1 — Create the SharePoint Communication Site

A Communication Site is designed for broadcasting content to an audience —
it's the right SharePoint template for a learning program.

1. Go to https://yourcompany.sharepoint.com
2. Click **+ Create site** → **Communication site**
3. Site name: `Cloud Security Mastery`
4. Site address: `cloud-security-mastery` (this becomes the URL)
5. Site description: `28-day cloud security learning program for the team`
6. Choose a design — **Blank** gives you the most control
7. **Finish**

**Set up the page structure:**

In the new site, create a page for each lesson. For now, create placeholders:

1. Site contents → **Pages** → **New** → **Page**
2. Name it: `Day-01-Account-Hardening`
3. Add a Text web part as the body placeholder
4. **Publish** (even as empty — the GitHub Action will overwrite the content)
5. Repeat for however many days you want to pre-create (or let the Action create them)

**Add a navigation structure:**

1. Site → **Edit** (top right) → **Navigation**
2. Add links grouped by week:
   ```
   Week 1: Foundations
     └── Day 01 — Account Hardening
     └── Day 02 — AWS Config
     └── ...
   Week 2: Identity
     └── ...
   ```

---

## Step 2 — Register an Azure App for GitHub Access

GitHub needs permission to write content to your SharePoint site.
You grant this by registering an app in Azure Active Directory.

1. Go to https://portal.azure.com
2. Search → **Azure Active Directory** → **App registrations** → **New registration**
3. Name: `github-sharepoint-publisher`
4. Supported account types: **Accounts in this organizational directory only**
5. Redirect URI: leave blank
6. **Register**

**Grant SharePoint permissions:**

1. In your new app → **API permissions** → **Add a permission**
2. **Microsoft Graph** → **Application permissions**
3. Search and add:
   - `Sites.ReadWrite.All` — allows reading and writing SharePoint pages
4. **Add permissions**
5. Click **Grant admin consent for [your org]** → **Yes**
   *(Requires a Global Admin or SharePoint Admin to click this)*

**Create a client secret:**

1. App → **Certificates & secrets** → **New client secret**
2. Description: `github-action-secret`
3. Expiry: **24 months** (set a calendar reminder to rotate before it expires)
4. **Add**
5. **Copy the Value immediately** — you cannot see it again after leaving this page

**Note these three values — you'll need them in Step 3:**
```
Application (client) ID:  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Directory (tenant) ID:    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Client secret value:      xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Step 3 — Add GitHub Secrets

Store the Azure credentials in GitHub so the Action can use them without
exposing them in code.

1. Your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** — add all three:

| Secret name | Value |
|---|---|
| `AZURE_CLIENT_ID` | Application (client) ID from Step 2 |
| `AZURE_TENANT_ID` | Directory (tenant) ID from Step 2 |
| `AZURE_CLIENT_SECRET` | Client secret value from Step 2 |
| `SHAREPOINT_SITE_URL` | e.g. `https://yourcompany.sharepoint.com/sites/cloud-security-mastery` |

---

## Step 4 — Add the GitHub Action

Create this file in your repo at `.github/workflows/publish-to-sharepoint.yml`:

```yaml
# .github/workflows/publish-to-sharepoint.yml
#
# Triggers on every push to main that touches a lesson .md file.
# Converts the Markdown to HTML and upserts it as a SharePoint page.

name: Publish Lessons to SharePoint

on:
  push:
    branches: [main]
    paths:
      - 'week-*/day-*.md'   # Only runs when lesson files change

jobs:
  publish:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4
        with:
          fetch-depth: 2   # Need previous commit to detect changed files

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install markdown requests msal

      - name: Find changed lesson files
        id: changed
        run: |
          # Get list of .md files changed in this push
          git diff --name-only HEAD~1 HEAD | grep '^week-.*/day-.*\.md$' > changed_files.txt || true
          cat changed_files.txt
          echo "files=$(cat changed_files.txt | tr '\n' ' ')" >> $GITHUB_OUTPUT

      - name: Publish changed files to SharePoint
        if: steps.changed.outputs.files != ''
        env:
          AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          SHAREPOINT_SITE_URL: ${{ secrets.SHAREPOINT_SITE_URL }}
        run: |
          python .github/scripts/publish_to_sharepoint.py changed_files.txt
```

Now create the Python script the Action calls.
Create `.github/scripts/publish_to_sharepoint.py`:

```python
#!/usr/bin/env python3
"""
publish_to_sharepoint.py

Reads a list of changed Markdown lesson files, converts each to HTML,
and upserts it as a SharePoint site page using the Microsoft Graph API.

A page is created if it doesn't exist, or updated if it does.
Page title and name are derived from the lesson filename and H1 heading.
"""

import os
import sys
import re
import json
import markdown
import requests
import msal

# ── Auth ──────────────────────────────────────────────────────────────────────

def get_access_token():
    """Authenticate with Azure AD and return a Graph API access token."""
    authority = f"https://login.microsoftonline.com/{os.environ['AZURE_TENANT_ID']}"
    app = msal.ConfidentialClientApplication(
        client_id=os.environ['AZURE_CLIENT_ID'],
        client_credential=os.environ['AZURE_CLIENT_SECRET'],
        authority=authority
    )
    result = app.acquire_token_for_client(
        scopes=["https://graph.microsoft.com/.default"]
    )
    if "access_token" not in result:
        print(f"Auth failed: {result.get('error_description', 'Unknown error')}")
        sys.exit(1)
    return result["access_token"]


# ── SharePoint helpers ────────────────────────────────────────────────────────

def get_site_id(token, site_url):
    """Resolve a SharePoint site URL to its Graph API site ID."""
    # Extract hostname and site path from full URL
    # e.g. https://contoso.sharepoint.com/sites/cloud-security-mastery
    match = re.match(r'https://([^/]+)(/.*)', site_url)
    if not match:
        print(f"Could not parse site URL: {site_url}")
        sys.exit(1)
    hostname, path = match.groups()

    url = f"https://graph.microsoft.com/v1.0/sites/{hostname}:{path}"
    resp = requests.get(url, headers={"Authorization": f"Bearer {token}"})
    resp.raise_for_status()
    return resp.json()["id"]


def page_exists(token, site_id, page_name):
    """Return the page ID if a page with this name exists, else None."""
    url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/pages"
    resp = requests.get(url, headers={"Authorization": f"Bearer {token}"})
    resp.raise_for_status()
    for page in resp.json().get("value", []):
        if page.get("name") == page_name:
            return page["id"]
    return None


def upsert_page(token, site_id, page_name, page_title, html_content):
    """Create or update a SharePoint site page with the given HTML content."""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    payload = {
        "@odata.type": "#microsoft.graph.sitePage",
        "name": page_name,
        "title": page_title,
        "canvasLayout": {
            "horizontalSections": [{
                "layout": "oneColumn",
                "columns": [{
                    "width": 12,
                    "webparts": [{
                        "@odata.type": "#microsoft.graph.textWebPart",
                        "innerHtml": html_content
                    }]
                }]
            }]
        }
    }

    existing_id = page_exists(token, site_id, page_name)
    if existing_id:
        # Update existing page
        url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/pages/{existing_id}"
        resp = requests.patch(url, headers=headers, json=payload)
    else:
        # Create new page
        url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/pages"
        resp = requests.post(url, headers=headers, json=payload)

    if resp.status_code not in (200, 201):
        print(f"Failed to upsert page '{page_name}': {resp.status_code} {resp.text}")
        resp.raise_for_status()

    # Publish the page so it's visible to all site members
    page_id = resp.json()["id"]
    publish_url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/pages/{page_id}/publish"
    requests.post(publish_url, headers={"Authorization": f"Bearer {token}"})
    return page_id


# ── Markdown processing ───────────────────────────────────────────────────────

def md_to_html(md_text):
    """Convert Markdown to HTML with table and fenced code support."""
    return markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "toc", "nl2br"]
    )


def extract_title(md_text):
    """Extract the first H1 heading from Markdown as the page title."""
    match = re.search(r'^#\s+(.+)$', md_text, re.MULTILINE)
    return match.group(1).strip() if match else "Untitled Lesson"


def filename_to_page_name(filepath):
    """
    Convert a file path like 'week-1/day-01.md' to a SharePoint page name
    like 'Week-1-Day-01' (no spaces, no extension, title-cased).
    """
    basename = os.path.splitext(os.path.basename(filepath))[0]  # day-01
    # Include week prefix for uniqueness
    parts = filepath.split(os.sep)
    week = parts[0] if parts else ""  # week-1
    return f"{week}-{basename}".replace(" ", "-").title()       # Week-1-Day-01


# ── Main ──────────────────────────────────────────────────────────────────────

def main(changed_files_path):
    with open(changed_files_path) as f:
        files = [line.strip() for line in f if line.strip()]

    if not files:
        print("No lesson files to publish.")
        return

    print(f"Publishing {len(files)} file(s) to SharePoint...")

    token = get_access_token()
    site_url = os.environ["SHAREPOINT_SITE_URL"]
    site_id = get_site_id(token, site_url)

    for filepath in files:
        if not os.path.exists(filepath):
            print(f"  Skipping {filepath} — file not found")
            continue

        with open(filepath, encoding="utf-8") as f:
            md_text = f.read()

        page_title = extract_title(md_text)
        page_name  = filename_to_page_name(filepath)
        html       = md_to_html(md_text)

        print(f"  Publishing: {filepath} → '{page_title}' ({page_name})")
        upsert_page(token, site_id, page_name, page_title, html)
        print(f"  ✅ Done")

    print("\nAll files published successfully.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: publish_to_sharepoint.py <changed_files.txt>")
        sys.exit(1)
    main(sys.argv[1])
```

---

## Step 5 — Set Up the Teams Channel

1. In Microsoft Teams → your team → **Add channel**
2. Channel name: `☁️ Cloud Security Program`
3. Description: `28-day cloud security learning program. New lessons posted daily.`
4. Privacy: **Standard** (visible to all team members)

**Add useful tabs to the channel:**

- **SharePoint tab:** + → SharePoint → select your Communication Site
  - Gives members direct access to lessons without leaving Teams
- **OneNote tab:** + → OneNote → Create a new notebook: `Security Program Notes`
  - Shared space for group notes; each person can also keep their own section
- **Website tab (optional):** + → Website → link to your GitHub repo
  - For the technical co-maintainers who want to see the source

**Pin a welcome message:**
Post a message explaining the program, link to the PREREQUISITES.md on SharePoint,
and pin it so it stays visible at the top of the channel.

---

## Step 6 — Set Up Power Automate (Auto-post to Teams on Publish)

This flow watches SharePoint for new/updated pages and automatically posts
a Teams message so people know a new lesson is available.

1. Go to https://make.powerautomate.com
2. **Create** → **Automated cloud flow**
3. Flow name: `Notify Teams When Lesson Published`
4. Trigger: search for **"When a file is created or modified (SharePoint)"**
5. Configure trigger:
   - Site Address: your SharePoint site
   - Library Name: **Site Pages**

6. **Add an action** → search **"Post message in a chat or channel (Teams)"**
7. Configure:
   - Post as: **Flow bot**
   - Post in: **Channel**
   - Team: your team
   - Channel: `☁️ Cloud Security Program`
   - Message (click in the field → use dynamic content):

```
📖 New lesson published!

**Title:** [Dynamic: Name]
**Link:** [Dynamic: Link to item]

Open the lesson in SharePoint, or check the SharePoint tab in this channel.
```

8. **Save**

**Test it:** Manually trigger a publish from GitHub (push a small change to any day-XX.md file). Within a few minutes the Teams message should appear.

---

## Step 7 — Weekly Quiz in Teams (Polls)

Rather than linking to a Markdown quiz file, post the weekly quiz as a
Teams Poll — it's interactive, takes 10 seconds to answer, and shows
group results immediately.

**How to post a quiz poll:**

1. In the `☁️ Cloud Security Program` channel
2. New message → click **…** (more options) → **Forms** (or Poll)
3. Enter the question and multiple-choice options
4. Enable **Multiple answers: No**
5. Enable **Share results automatically after voting**
6. **Send**

Post one poll per day during the week (questions from `week-X/quiz/week-X-quiz.md`),
or batch all week's questions on Friday as a "Week in Review" set.

The answer key in the quiz Markdown file is for self-study and after-the-fact reference.

---

## Maintainer Workflow (Day-to-Day)

Once everything is set up, this is all a content update takes:

```bash
# 1. Edit a lesson file
vim week-2/day-08.md

# 2. Commit and push to a branch
git add week-2/day-08.md
git commit -m "Day 08: Expand IAM policy evaluation section, fix example JSON"
git push origin fix/day-08-iam-eval

# 3. Open a pull request on GitHub
# 4. Co-maintainer reviews and approves
# 5. Merge to main

# → GitHub Action runs automatically
# → SharePoint page updates
# → Teams notification posts
# → Done. No manual steps.
```

---

## Rotating the Azure Client Secret

The client secret you created in Step 2 expires after 24 months.
Set a calendar reminder for 23 months from now with these steps:

1. Azure Portal → App registrations → `github-sharepoint-publisher`
2. Certificates & secrets → **New client secret** (create the new one first)
3. Copy the new value
4. GitHub repo → Settings → Secrets → update `AZURE_CLIENT_SECRET`
5. Test a publish to confirm it works
6. Delete the old secret from Azure

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Action fails with 401 | Client secret expired or wrong | Re-check Step 2–3 |
| Action fails with 403 | Admin consent not granted | Step 2 → Grant admin consent |
| Page creates but shows blank | HTML conversion issue | Check Action logs for Python errors |
| Teams post doesn't appear | Power Automate flow off | Check flow run history at make.powerautomate.com |
| Page updates but old content shows | SharePoint caching | Hard refresh (Ctrl+Shift+R) or wait 5 min |