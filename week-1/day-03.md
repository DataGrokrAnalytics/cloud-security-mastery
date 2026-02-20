# Day 03 — Security Hub & CIS Benchmark

**Week 1: Foundations & Visibility** | 4 hours | Difficulty: Beginner

---

## 🎯 Objective

By the end of today you will have AWS Security Hub running with the CIS AWS Foundations Benchmark enabled, understand what your compliance score means, and have fixed your first real findings — moving your score visibly upward.

---

## 📖 Theory (2.5 hours)

### 1. The Problem Security Hub Solves

By Day 2 you have AWS Config running with 5 rules. By Day 23 you'll have GuardDuty, Macie, Inspector, and Access Analyzer all running too. Each service generates its own findings, in its own console, in its own format. Without aggregation, a security engineer would need to check 6 different dashboards across every AWS account just to answer "are we secure right now?"

Security Hub is the aggregation layer. It pulls findings from all AWS security services and supported third-party tools into a single normalised view, scores your environment against compliance frameworks, and lets you prioritise and act from one place.

---

### 2. The CIS AWS Foundations Benchmark

The Center for Internet Security (CIS) publishes security benchmarks — collections of controls representing industry consensus on what a securely configured environment looks like. The AWS Foundations Benchmark is the most widely adopted standard for AWS account security.

The benchmark is organised into five sections:

**Section 1: Identity and Access Management**
Controls covering root account security, MFA enforcement, password policy, access key rotation, and avoiding overly permissive IAM policies. These are foundational — if identity controls fail, every other control is undermined.

Examples:
- 1.4 — Ensure no root account access keys exist
- 1.5 — Ensure MFA is enabled on the root account
- 1.8 — Ensure IAM password policy requires minimum length of 14 characters
- 1.14 — Ensure access keys are rotated every 90 days

**Section 2: Storage**
Controls covering S3 bucket access and encryption settings.

Examples:
- 2.1.1 — Ensure S3 bucket public access block is enabled at account level
- 2.1.2 — Ensure S3 bucket versioning is enabled on CloudTrail log buckets

**Section 3: Logging**
Controls ensuring your audit trail is complete, tamper-evident, and encrypted.

Examples:
- 3.1 — Ensure CloudTrail is enabled in all regions
- 3.2 — Ensure CloudTrail log file validation is enabled
- 3.3 — Ensure CloudTrail logs are encrypted with KMS

**Section 4: Monitoring**
Controls requiring CloudWatch alarms for security-significant events — root login, policy changes, failed auth attempts.

Examples:
- 4.1 — Alarm for unauthorised API calls
- 4.3 — Alarm for changes to IAM policies
- 4.5 — Alarm for CloudTrail configuration changes

**Section 5: Networking**
Controls covering VPC configuration, default security groups, and network ACLs.

Examples:
- 5.1 — No network ACL allows unrestricted ingress on all ports
- 5.2 — Default security group in every VPC restricts all traffic
- 5.4 — Ensure routing tables for VPC peering are least access

---

### 3. Reading Your Compliance Score

Security Hub calculates a score (0–100%) for each enabled benchmark: the percentage of controls currently passing. A brand new AWS account typically scores between 30–50% on CIS — this is normal and expected, because many controls require services you haven't set up yet (CloudTrail, CloudWatch alarms, KMS).

**How to prioritise findings when you have hundreds:**

Start with the intersection of two filters:
1. **Severity: CRITICAL or HIGH** — the most exposed attack surface
2. **Production accounts** — business impact multiplies technical severity

A CRITICAL finding on an empty dev sandbox is lower priority than a HIGH finding on an account storing customer data.

**Quick wins to look for first:**
- Findings you can fix in under 5 minutes (password policy, account-level S3 block)
- Findings affecting many resources (one rule type failing across 50 EC2 instances)
- IAM findings — identity is the master key to everything else

---

### 4. Suppressing vs. Ignoring Findings

When a finding is a known false positive or an approved exception, you have two options:

**Suppress it (correct):** Mark it as suppressed in Security Hub with a documented reason — "Public S3 bucket for marketing website, reviewed by [name] on [date], approved exception." This appears in audit logs as a deliberate, reviewed decision.

**Ignore it (wrong):** Close the browser tab and pretend it doesn't exist. This appears in audit logs as a finding that was never addressed — a red flag for auditors and incident investigators alike.

The documentation discipline matters even on a personal learning account — it's a habit worth building now.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Security Hub | https://aws.amazon.com/security-hub/ |
| CIS AWS Foundations Benchmark | https://www.cisecurity.org/benchmark/amazon_web_services/ |
| Security Hub Controls Reference | https://docs.aws.amazon.com/securityhub/latest/userguide/standards-reference.html |
| AWS Foundational Security Best Practices | https://docs.aws.amazon.com/securityhub/latest/userguide/fsbp-standard.html |

---

## 🛠️ Lab (1 hour)

### Step 1 — Enable Security Hub (10 min)

1. AWS Console → search → **Security Hub** → **Go to Security Hub**
2. **Enable Security Hub**
3. On the standards selection page, enable:
   - ✅ **CIS AWS Foundations Benchmark v1.4.0**
   - ✅ **AWS Foundational Security Best Practices v1.0.0**
4. **Enable Security Hub**

Security Hub immediately begins pulling findings from AWS Config (which you enabled yesterday). The full compliance score takes up to 24 hours to fully populate.

---

### Step 2 — Review Your Initial Score (15 min)

1. Security Hub → **Summary** tab
2. Note your CIS score — record it here as your baseline: `_____%`
3. Click into **CIS AWS Foundations Benchmark** → view the controls list
4. Sort by **Status: Failed**
5. Identify and write down your top 5 failing controls:

```
Control  | Title                              | Severity
---------|------------------------------------|----------
         |                                    |
         |                                    |
         |                                    |
         |                                    |
         |                                    |
```

---

### Step 3 — Fix Two Quick Wins (35 min)

**Quick win 1 — CIS 1.8: IAM Password Policy (10 min)**

A strong password policy reduces the risk of brute-force attacks against IAM user credentials.

1. AWS Console → **IAM** → left menu → **Account settings**
2. Under **Password policy** → **Edit**
3. Configure:
   - Minimum password length: **14**
   - ✅ Require at least one uppercase letter
   - ✅ Require at least one lowercase letter
   - ✅ Require at least one number
   - ✅ Require at least one non-alphanumeric character
   - ✅ Enable password expiration: **90 days**
   - ✅ Prevent password reuse: **5 passwords**
4. **Save changes**

**Quick win 2 — CIS 2.1.1: S3 Account-Level Public Access Block (10 min)**

This single setting acts as a safety net for your entire account — even if an individual bucket's settings allow public access, this account-level block overrides it.

1. AWS Console → **S3**
2. Left menu → **Block Public Access settings for this account**
3. **Edit** → check all four boxes:
   - ✅ Block all public access
4. **Save changes** → type `confirm` → **Confirm**

**Verify your fixes (15 min)**

Return to Security Hub → Summary. Changes take 15–30 minutes to reflect. While waiting:
- Browse the **Findings** tab and read 3–5 individual findings in detail
- Note the structure: resource ARN, severity, description, remediation guidance
- Security Hub provides a remediation link for every finding — get familiar with using it

---

## ✅ Checklist

- [ ] Security Hub enabled
- [ ] CIS AWS Foundations Benchmark v1.4.0 active
- [ ] AWS Foundational Security Best Practices active
- [ ] Initial CIS score recorded (screenshot)
- [ ] Top 5 failing controls identified and written down
- [ ] IAM password policy updated to CIS 1.8 requirements
- [ ] S3 account-level public access block enabled
- [ ] Screenshot: Security Hub Summary dashboard
- [ ] Screenshot: CIS benchmark showing your score

**Portfolio commit:**
```bash
git add screenshots/day-03-*.png
git commit -m "Day 03: Security Hub enabled, CIS benchmark active, score improved with 2 quick wins"
git push
```

---

## 📝 Quiz

→ [week-1/quiz/week-1-quiz.md](./quiz/week-1-quiz.md) — Questions 6 & 7 cover today's content.

---

## 🧹 Cleanup

Nothing to clean up — Security Hub should remain enabled throughout the program.

> **Cost note:** Security Hub has a 30-day free trial. After that it charges per finding ingested per month. For a single learning account the cost is typically under $1/month — but check AWS Pricing if you plan to run it long-term: https://aws.amazon.com/security-hub/pricing/
