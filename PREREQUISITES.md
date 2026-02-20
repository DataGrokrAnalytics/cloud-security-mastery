# Prerequisites — Read Before Day 1

## Do You Need an AWS Account?

Yes. You need a **personal AWS account**, not a shared team or corporate account. Here's why:

- Day 4 involves AWS Organizations, which affects your entire account hierarchy
- Day 1 requires root account access, which you won't have on a corporate account
- You need to be able to make (and clean up) real resources without approval workflows

→ Sign up: https://aws.amazon.com/free/

---

## What Background Do You Need?

### If you're a developer with minimal AWS experience
You should be comfortable with:
- Logging into the AWS console
- Knowing conceptually what EC2, S3, and IAM are
- Basic command line (ls, cd, cat)
- Reading JSON

You do **not** need to know: networking, security protocols, or any AWS security services.

### If you're a DevOps or SRE engineer
You likely already know the above. Pay extra attention to Week 2 (IAM) — the policy evaluation logic is where most infra engineers have gaps, and it's foundational to everything in Weeks 3 and 4.

### If you're a security generalist new to cloud
The technology is new but the concepts will feel familiar. The biggest mindset shift: in cloud, *configuration is the attack surface*, not just the network perimeter.

---

## Tools to Install Before Day 1

```bash
# AWS CLI v2
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Verify
aws --version   # should show aws-cli/2.x.x
```

**Week 2+ tools** (install when you get there, not all now):
- Python 3.9+ — for Lambda and SOAR labs in Week 4
- Git — for portfolio commits
- Checkov — for IaC scanning on Day 11 (`pip3 install checkov`)

All infrastructure labs use **CloudFormation** — no Terraform or extra tooling needed.

---

## Cost Protection — Do This on Day 1

Two guardrails before any lab:

**1. AWS Budgets alert at $5**
- Billing → Budgets → Create Budget → Monthly cost budget → $5 threshold
- Add your email. This fires when spend is *forecast* to exceed $5.

**2. Bookmark this URL**
- https://console.aws.amazon.com/cost-management/home
- Check it every Sunday

Every lab in this program stays within Free Tier limits. The only cost risk is forgetting to delete resources — which is why each week includes a cleanup script.

---

## Portfolio Setup (GitHub)

Each day ends with a commit. Create a private repo now:

```bash
# On GitHub: create a new private repo called "cloud-security-mastery-portfolio"
git clone https://github.com/YOUR_USERNAME/cloud-security-mastery-portfolio.git
cd cloud-security-mastery-portfolio
```

After each day's lab:
```bash
git add .
git commit -m "Day 01: Root MFA enabled, budget alert configured"
git push
```

Screenshots + commit history = verifiable evidence of your work.

---

## Pace Options

The default is 4 hours/day over 4 weeks. If that's not feasible:
- **2 hours/day** → run it over 8 weeks, split theory and lab across two sessions
- **Weekends only** → ~3 months, pair up with a colleague to stay accountable

Do not skip the Sunday cleanup — cost creep and resource conflicts compound quickly.

---

Ready? → [week-1/day-01.md](./week-1/day-01.md)
