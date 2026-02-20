# Contributing to Cloud Security Mastery

Thank you for helping improve this program. This guide covers how to suggest
fixes, add content, and keep the curriculum accurate and up to date.

---

## Who Should Contribute

- **Learners** — found a broken lab step, outdated screenshot, or unclear explanation? Please fix it
- **Co-maintainers** — building out new week content or lab scripts
- **Security practitioners** — spotting an inaccuracy, a better approach, or a missing topic

---

## Ground Rules

**1. Accuracy over completeness**
If you're not sure a fact is correct, don't include it. An incomplete lesson is
better than one with wrong information. If you use a statistic, link the primary
source — no secondary sources, no "according to various reports."

**2. Every lab step must be tested**
Before submitting a lab change, run through it yourself on a real AWS Free Tier
account. Steps that look right but fail in practice waste learners' time.

**3. Keep the tone consistent**
Lessons are written in plain English, second person ("you will"), present tense.
No marketing language, no unnecessary jargon. Read one existing lesson before
writing a new one.

**4. No org-specific content**
Don't add internal URLs, company names, email addresses, or anything that only
applies to one organisation. This is a public curriculum.

---

## How to Contribute

### Small fixes (typos, broken links, unclear wording)

1. Fork the repo
2. Make your change directly on a branch:
   ```bash
   git checkout -b fix/day-03-broken-link
   ```
3. Commit with a clear message:
   ```bash
   git commit -m "Day 03: Fix broken CIS benchmark link"
   ```
4. Open a pull request — describe what was wrong and what you changed

### Content changes (rewriting a section, updating a lab step)

Same as above, but add to your PR description:
- What specifically changed and why
- If a lab step changed: confirm you tested it on a real AWS account
- If a statistic changed: link the new primary source

### New content (new lesson, new lab script, new quiz question)

1. Open an **issue** first describing what you want to add and why
2. Wait for a maintainer to confirm it fits the program before building it
3. Then follow the same fork → branch → PR process

---

## File Naming Conventions

| Content type | Convention | Example |
|---|---|---|
| Lesson files | `day-XX.md` (zero-padded) | `day-08.md` |
| Lab scripts | `day-XX-short-description.sh` or `.py` | `day-11-checkov-scan.sh` |
| Quiz files | `week-X-quiz.md` | `week-2-quiz.md` |
| Screenshots | `day-XX-description.png` | `day-01-mfa-enabled.png` |

---

## Lesson File Structure

Every lesson must follow this structure in this order:

```markdown
# Day XX — Title

**Week X: Theme** | 4 hours | Difficulty: Beginner / Intermediate / Advanced

---

## 🎯 Objective
## 📖 Theory (2.5 hours)
## 🔗 References
## 🛠️ Lab (1 hour)
## ✅ Checklist
## 📝 Quiz
## 🧹 Cleanup
```

Do not add sections, rename sections, or change the order. Consistency across
all 28 lessons is intentional — learners develop a rhythm.

---

## Adding References

Every factual claim that isn't common knowledge needs a reference in the
`## 🔗 References` table. Format:

```markdown
| Resource Name | https://full-url-here |
```

Acceptable sources:
- AWS official documentation (docs.aws.amazon.com)
- AWS blogs (aws.amazon.com/blogs)
- NIST publications (csrc.nist.gov)
- CIS benchmarks (cisecurity.org)
- MITRE ATT&CK (attack.mitre.org)
- Named annual reports with a direct link (Verizon DBIR, IBM Cost of a Data Breach)

Not acceptable:
- Medium posts, Reddit threads, personal blogs
- Paywalled content learners can't access
- "According to industry sources" without a named source
- Statistics without a linked primary source

---

## Pull Request Checklist

Before opening a PR, confirm:

- [ ] Change tested on a real AWS Free Tier account (for lab changes)
- [ ] All links work
- [ ] No company-specific or internal content
- [ ] Lesson structure matches the template above
- [ ] Statistics have linked primary sources
- [ ] Commit message is descriptive (`Day 08: Fix IAM simulator lab step 3` not `fix stuff`)

---

## Maintainers

This repo is maintained by a small team. PRs are reviewed within a few business
days. If your PR hasn't been reviewed after a week, feel free to leave a comment
on it.
