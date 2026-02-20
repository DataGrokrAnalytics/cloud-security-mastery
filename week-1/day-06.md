# Day 06 — CSPM Remediation & Automation

**Week 1: Foundations & Visibility** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will have moved your CIS score above 70% by systematically remediating findings, understand the difference between manual and automated remediation, and have a KMS key rotation policy active — closing one of the most common compliance gaps in AWS accounts.

---

## 📖 Theory (2.5 hours)

### 1. The Remediation Workflow

Finding a misconfiguration is only half the job. The other half is fixing it efficiently, verifiably, and without creating new problems. A professional remediation workflow has four steps:

**Assess:** Read the finding carefully. What resource is affected? What is the specific misconfiguration? What is the potential impact if exploited?

**Prioritise:** Is this a true positive or false positive? Is the resource in production or a dev sandbox? How severe is the finding?

**Remediate:** Fix the underlying configuration. Some remediations are one-click in the console; others require policy changes or architectural decisions.

**Verify:** Confirm the finding moves to Compliant in Config/Security Hub. Document what you changed and why. Commit the evidence.

Skipping verification is the most common mistake — a fix that doesn't register in your compliance tooling hasn't actually improved your posture as far as auditors are concerned.

---

### 2. Manual vs. Automated Remediation

**Manual remediation** is appropriate when:
- The fix requires a human decision (e.g., "should this bucket actually be public?")
- The misconfiguration is a one-off on a specific resource
- The resource is sensitive enough that automated changes carry risk

**Automated remediation** is appropriate when:
- The fix is unambiguous and safe to apply without human review
- The same misconfiguration recurs frequently (e.g., developers keep creating S3 buckets without encryption)
- Speed matters — automated remediation can fix a misconfiguration in seconds vs. hours

AWS Config supports **Remediation Actions** — you can attach an SSM Automation document to a rule, and Config will automatically run it when a resource becomes non-compliant. We'll build a more sophisticated version of this on Day 26 (Lambda SOAR). For now, understand the concept.

---

### 3. KMS Key Rotation — Why It Matters

AWS Key Management Service (KMS) lets you create and control encryption keys. Customer Managed Keys (CMKs) are keys you create and own — as opposed to AWS Managed Keys, which AWS creates on your behalf.

**Why rotation matters:**
If an encryption key is compromised — through a credential leak, an insider threat, or a cryptographic attack — an attacker who has your encrypted data can decrypt it. Rotating keys regularly limits the window of exposure: even if an old key was compromised, data encrypted with the new key is safe.

CIS Benchmark control 3.7 and AWS Foundational Security Best Practices both require annual automatic rotation for CMKs. Enabling it takes one click but is frequently missed.

**What rotation does and doesn't do:**
- ✅ AWS automatically creates a new key version annually
- ✅ New data is encrypted with the new key version
- ✅ Old data can still be decrypted (AWS keeps the old key material for decryption)
- ❌ Does not automatically re-encrypt existing data with the new key

---

### 4. Security Hub Insights — Prioritising at Scale

Security Hub's **Insights** feature lets you group and filter findings to see patterns that individual findings don't reveal.

Built-in insights worth using:
- **AWS resources with the most findings** — identifies your most problematic resources
- **Top accounts by count of findings** — useful in multi-account environments
- **Severity by resource type** — shows which resource types generate the most critical findings

You can also create custom insights. For example: "Show me all CRITICAL findings that have been open for more than 7 days" — useful for SLA tracking.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Config Remediation | https://docs.aws.amazon.com/config/latest/developerguide/remediation.html |
| AWS KMS Key Rotation | https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html |
| Security Hub Insights | https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-insights.html |
| CIS Control 3.7 | https://www.cisecurity.org/benchmark/amazon_web_services |

---

## 🛠️ Lab (1 hour)

### Step 1 — Remediate Your Top Config Findings (30 min)

Open Security Hub → **Findings** → filter by **Severity: HIGH or CRITICAL** → filter by **Status: FAILED**.

Work through your top findings. Here are the most common ones on a new account and how to fix each:

**Finding: No MFA on IAM users with console access**
1. IAM → Users → click the flagged user → Security credentials tab
2. Assign MFA device → follow the setup wizard
3. Verify: Config rule `mfa-enabled-for-iam-console-access` should move to Compliant within 15 min

**Finding: Security groups allow unrestricted SSH (0.0.0.0/0 on port 22)**
1. EC2 → Security Groups → find the flagged group
2. Inbound rules → Edit → find the port 22 rule with source `0.0.0.0/0`
3. Change source to your specific IP, or delete the rule if SSH isn't needed
4. Save rules

**Finding: Default VPC security group is not restricted**
1. VPC → Security Groups → find the default security group for your default VPC
2. Edit inbound rules → remove all inbound rules
3. Edit outbound rules → remove all outbound rules
4. The default VPC's default SG should have no rules — resources that need network access should use dedicated security groups

**Finding: EBS volume not encrypted**
1. This one can't be fixed retroactively on an existing volume — instead, set a default
2. EC2 Console → **EC2 Settings** (bottom of left menu) → **EBS encryption**
3. **Manage** → **Enable** default EBS encryption → select the default AWS managed key
4. All future EBS volumes will be encrypted automatically

---

### Step 2 — Enable KMS Key Rotation (15 min)

1. AWS Console → **KMS** → **Customer managed keys**
2. If you have no CMKs yet, create one:
   - **Create key** → Symmetric → Encrypt and decrypt → Next
   - Alias: `learning-lab-key`
   - Leave defaults → **Finish**
3. Click your key → **Key rotation** tab
4. **Edit** → check ✅ **Automatically rotate this KMS key every year**
5. **Save**

Verify: Security Hub finding for KMS rotation should move to Compliant within 30 minutes.

---

### Step 3 — Check Your CIS Score Improvement (15 min)

1. Security Hub → **Summary** → note your updated CIS score
2. Compare to your Day 3 baseline — document the improvement:

```
Day 03 baseline score:  _____%
Day 06 current score:   _____%
Improvement:            _____%
```

3. Look at the remaining failing controls — identify the top 3 you couldn't fix today and note why (some require CloudTrail from Day 22, CloudWatch alarms from Day 22, etc.)

---

## ✅ Checklist

- [ ] At least 3 Security Hub findings remediated
- [ ] Default VPC security group rules cleared
- [ ] Default EBS encryption enabled
- [ ] KMS CMK created with annual automatic rotation enabled
- [ ] CIS score improvement documented (Day 3 vs today)
- [ ] Screenshot: Security Hub showing improved score
- [ ] Screenshot: KMS key rotation setting enabled

**Portfolio commit:**
```bash
git add screenshots/day-06-*.png
git commit -m "Day 06: CIS score improved to X%, KMS rotation enabled, default EBS encryption enabled"
git push
```

---

## 📝 Quiz

→ [week-1/quiz/week-1-quiz.md](./quiz/week-1-quiz.md) — Review all questions before the Week 1 review tomorrow.

---

## 🧹 Cleanup

Keep the KMS key and the Config/Security Hub findings — you'll need them for next week. No lab resources to delete today.

> **Cost note:** A KMS CMK costs $1/month after the free tier. Delete it after the program if you don't plan to keep it: KMS → Customer managed keys → select key → Key actions → Schedule key deletion → minimum 7-day waiting period.
