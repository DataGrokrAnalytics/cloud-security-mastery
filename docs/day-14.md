# Day 14 — Week 2 Review & IAM Audit Portfolio

**Week 2: Zero Trust Identity** | 4 hours | Difficulty: All levels

---

## 🎯 Objective

By the end of today you will have a complete IAM audit report for your account, a Week 2 executive summary, all temporary lab resources cleaned up, and a clear picture of what Zero Trust looks like in practice — ready to carry that foundation into network and data protection in Week 3.

---

## 📖 Theory (2 hours)

### 1. IAM Audit Frameworks — What a Real Audit Covers

When a security team audits IAM in an AWS environment, they follow a structured checklist. Understanding this framework helps you build audit-ready environments from the start rather than scrambling before an audit.

**A standard IAM audit covers six areas:**

**1. Identity inventory**
Who exists? Users, roles, groups, identity providers. Are all identities associated with a real business purpose? Are there orphaned accounts from employees who've left?

**2. Credential hygiene**
MFA status for all console users. Age and usage of access keys. Password policy enforcement. Root account key existence.

**3. Permission analysis**
Are any identities over-privileged? Are wildcard actions (`*`) used in custom policies? Are any policies attached directly to users (should be groups or roles)? Are AWS managed policies used where more restrictive customer-managed policies are appropriate?

**4. Access paths**
What can each identity reach? Are there unintended cross-account trusts? Are resource-based policies granting unexpected external access? (This is what Access Analyzer surfaces.)

**5. Entitlement drift**
Have permissions grown over time without corresponding business need? When was the last access review? What do last-accessed timestamps show?

**6. Detective controls**
Is CloudTrail recording all IAM actions? Are there alerts for sensitive actions (root login, policy changes, new admin user creation)?

---

### 2. The IAM Security Maturity Model

A useful framework for assessing where an organisation sits on IAM security:

**Level 1 — Basic (most organisations start here)**
- IAM users with long-term access keys
- AdministratorAccess attached to developers
- No MFA enforcement
- Root used regularly

**Level 2 — Managed**
- MFA required for console access
- Some custom IAM policies (not just AWS managed)
- Access keys rotated periodically
- Root access locked down

**Level 3 — Defined (target for this program)**
- IAM roles used instead of users for all programmatic access
- Least-privilege custom policies for all identities
- JIT access for privileged operations
- Access Analyzer monitoring external access
- Credential report reviewed monthly

**Level 4 — Optimised**
- Full CIEM tooling with automated entitlement right-sizing
- Machine-generated IAM policies from access logs
- Continuous access reviews with automated revocation
- Zero standing privileges

By the end of Week 2, your learning account should be solidly at Level 3.

---

### 3. Week 2 in Context

```
Week 1: Foundations & Visibility    ✅ Complete
  └── Can you SEE what's misconfigured?

Week 2: Zero Trust Identity         ← You are here
  └── Can you CONTROL who accesses what?
  └── IAM policies, Access Analyzer, CIEM, IaC scanning,
      Session Manager, JIT access

Week 3: Network & Data Protection   → Starting Monday
  └── Can you PROTECT your data and network?

Week 4: Detection & Response
  └── Can you DETECT and RESPOND to threats?
```

Identity is the master key. The controls you've built this week — least-privilege policies, MFA enforcement, JIT access, credential hygiene — form the foundation that makes everything in Weeks 3 and 4 meaningful. A perfectly segmented network is irrelevant if an attacker can assume an over-privileged IAM role and bypass it entirely.

---

## 🔗 References

| Resource | URL |
|---|---|
| IAM Security Best Practices | https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html |
| AWS IAM Access Analyzer | https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html |
| CIS IAM Controls (Section 1) | https://www.cisecurity.org/benchmark/amazon_web_services |

---

## 🛠️ Lab (1.5 hours)

### Step 1 — Generate Your IAM Audit Report (45 min)

Create `portfolio/week-2/iam-audit-report.md` as a structured assessment of your account's IAM posture. Fill in every section with real data from your account.

```markdown
# IAM Audit Report
**Account ID:** [your account ID]
**Date:** [today's date]
**Auditor:** [your name]

---

## 1. Identity Inventory

| Identity Type | Count | Notes |
|---|---|---|
| IAM Users | | |
| IAM Roles | | |
| IAM Groups | | |
| Active access keys | | |

## 2. Credential Hygiene

| Check | Result | Action Taken |
|---|---|---|
| Root MFA enabled | ✅ / ❌ | |
| Root access keys exist | ✅ / ❌ | |
| All console users have MFA | ✅ / ❌ | |
| Access keys rotated <90 days | ✅ / ❌ | |
| Password policy meets CIS 1.8 | ✅ / ❌ | |

## 3. Permission Analysis

| Check | Result | Notes |
|---|---|---|
| Any user with AdministratorAccess | | |
| Any policy with Action: "*" | | |
| Any inline policies (vs managed) | | |
| Policies attached directly to users | | |

## 4. Access Paths (Access Analyzer)

| Finding Type | Count | Status |
|---|---|---|
| Public access findings | | Resolved / Archived |
| Cross-account access findings | | Resolved / Archived |
| Unused access findings | | Resolved / Archived |

## 5. JIT Controls

| Control | Implemented | Notes |
|---|---|---|
| JIT role with MFA requirement | ✅ Day 13 | JIT-ReadOnly-1Hour |
| Session Manager (no SSH) | ✅ Day 12 | ssm-lab-instance |
| Secrets in Secrets Manager | ✅ Day 10 | prod/myapp/database |

## 6. Detective Controls

| Control | Status | Notes |
|---|---|---|
| CloudTrail logging IAM actions | | |
| Alert on root account usage | | Configured Day 06 |
| Access Analyzer active | | |

## Summary Risk Rating: LOW / MEDIUM / HIGH

## Remaining Gaps
[List any IAM issues you identified but haven't resolved, with a remediation plan]
```

---

### Step 2 — Write Your Week 2 Executive Summary (20 min)

Create `portfolio/week-2/executive-summary.md`:

```markdown
# Week 2 Executive Summary — Zero Trust Identity

**Period:** [dates]
**Author:** [your name]

## What We Did
[2–3 sentences]

## Controls Implemented

| Control | Day | Business Value |
|---|---|---|
| 5 custom least-privilege IAM policies | Day 08 | Replaced broad AWS managed policies |
| IAM Access Analyzer | Day 09 | Continuous external access monitoring |
| Secrets Manager for credentials | Day 10 | Eliminated hardcoded secrets pattern |
| IaC security scanning (Checkov) | Day 11 | Misconfigs caught before deployment |
| Session Manager (no SSH/bastion) | Day 12 | Zero open inbound ports for admin access |
| JIT access with 1-hour TTL | Day 13 | No standing privileged access |

## IAM Posture

| Metric | Status |
|---|---|
| IAM Maturity Level | Level 3 — Defined |
| Identities with standing admin access | [count] |
| Open Access Analyzer findings | 0 |
| Secrets in code or environment variables | 0 |

## Next Week
Week 3 covers network segmentation and data protection — VPCs, KMS encryption,
Amazon Macie for PII detection, and container security.
```

---

### Step 3 — Cleanup (25 min)

**Terminate the EC2 instance from Day 12:**
```bash
aws ec2 terminate-instances --instance-ids YOUR-INSTANCE-ID
```

**Delete the Secrets Manager secret (optional — $0.40/month):**
```bash
aws secretsmanager delete-secret \
  --secret-id prod/myapp/database \
  --recovery-window-in-days 7
```

**Verify $0 spend:**
- AWS Cost Explorer → confirm this week's charges are within Free Tier
- Check for any running EC2 instances, NAT Gateways, or other billable resources

---

## ✅ Week 2 Final Checklist

**Day-by-day verification:**
- [ ] Day 08: 5 custom IAM policies created and tested in Policy Simulator
- [ ] Day 09: Access Analyzer enabled, all findings reviewed
- [ ] Day 10: Secrets Manager configured, credential report analysed
- [ ] Day 11: Checkov installed, insecure template scanned, secure template passes
- [ ] Day 12: Session Manager working with zero open inbound ports
- [ ] Day 13: JIT role with MFA + 1-hour TTL demonstrated

**Portfolio artifacts:**
- [ ] `portfolio/week-2/iam-audit-report.md`
- [ ] `portfolio/week-2/executive-summary.md`
- [ ] `week-2/labs/vpc-insecure.yaml`
- [ ] `week-2/labs/vpc-secure.yaml`
- [ ] Screenshots from each day

**Final metrics:**
- [ ] Open Access Analyzer findings: 0
- [ ] IAM users without MFA: 0
- [ ] Active access keys unused 90+ days: 0
- [ ] AWS spend this week: $____ (target: $0)

**Final portfolio commit:**
```bash
git add .
git commit -m "Week 02 complete: Zero Trust Identity — IAM audit, JIT access, Session Manager, IaC scanning"
git push
```

---

## 📝 Quiz

→ [week-2/quiz/week-2-quiz.md](./quiz/week-2-quiz.md) — Complete all 10 questions before starting Week 3.

---

## 🔜 Week 3 Preview

Week 3 shifts from *who* to *what* — protecting your network and data. You'll build a production-grade VPC from scratch, implement encryption with KMS, use Amazon Macie to find PII in S3, and get into container security with ECR and EKS.

The key mindset shift for Week 3: data at rest and in transit should always be encrypted, and your network should be segmented so that a compromise in one layer cannot spread freely to others.

→ Start Week 3: [week-3/day-15.md](../week-3/day-15.md)
