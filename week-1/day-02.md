# Day 02 — CSPM Foundation: AWS Config

**Week 1: Foundations & Visibility** | 4 hours | Difficulty: Beginner

---

## 🎯 Objective

By the end of today you will have AWS Config running continuously across your account, your first managed rules active, and a clear understanding of what Cloud Security Posture Management is and why misconfiguration — not hacking — is the leading cause of cloud breaches.

---

## 📖 Theory (2.5 hours)

### 1. What Is CSPM?

Cloud Security Posture Management (CSPM) answers one question continuously: *"Are our cloud resources configured the way we think they are, right now?"*

Traditional security tools watch for malicious **behaviour** — an attacker running commands, exfiltrating data. CSPM watches for dangerous **configuration** — an S3 bucket left public, a security group open to the internet, a database with encryption turned off. Both matter, but most teams have a much bigger gap on the configuration side.

**Why misconfigurations dominate cloud incidents:**
According to Verizon's DBIR, misconfiguration is consistently one of the top causes of cloud-related breaches. The reason is structural: cloud resources are created via API calls in seconds. A single deployment can spin up dozens of resources with subtly wrong settings. Developers move fast and don't always know secure defaults. Manual security reviews can't keep pace.

> **Real example — Capital One (2019):** An attacker exploited a misconfigured WAF on an EC2 instance to access an IAM role, then used that role's excessive permissions to pull data from over 100 S3 buckets. AWS's infrastructure was fine. Every failure was a configuration mistake on the customer's side.

---

### 2. How AWS Config Works

AWS Config operates in three layers:

**Layer 1 — Resource recording**
Config continuously records the configuration state of every supported resource type in your account — EC2 instances, S3 buckets, IAM roles, security groups, VPCs, RDS databases, and hundreds more. Each snapshot is stored in an S3 bucket.

**Layer 2 — Configuration timeline**
For every resource, Config keeps a full history of every configuration change: what changed, when, and which IAM identity made the change. If someone opens port 22 to the internet on a Tuesday afternoon, Config records exactly that — invaluable for incident investigation.

**Layer 3 — Rules and compliance evaluation**
Config evaluates your resources against rules that define what "compliant" looks like. When a resource drifts from compliant, Config flags it. Optionally, it can trigger automatic remediation via AWS Systems Manager.

---

### 3. Managed Rules vs. Custom Rules

**Managed rules** are pre-built by AWS. You enable them with a few clicks:

| Rule name | What it checks |
|---|---|
| `s3-bucket-public-read-prohibited` | S3 buckets must not allow public read |
| `mfa-enabled-for-iam-console-access` | IAM users with console access must have MFA |
| `root-account-mfa-enabled` | Root account must have MFA active |
| `ec2-instances-in-vpc` | EC2 instances must be launched inside a VPC |
| `encrypted-volumes` | EBS volumes must be encrypted |
| `kms-cmk-not-scheduled-for-deletion` | No KMS keys should be pending deletion |

**Custom rules** are Lambda functions you write yourself, used when your organisation has requirements that managed rules don't cover — for example, "every EC2 instance must have an Owner tag" or "RDS instances must use a specific parameter group".

---

### 4. The False Positive Problem

Not every Config finding is a real problem. Around 40% of findings in mature environments are **intentional exceptions** — resources that violate the rule's letter but not its intent.

**Example:** Your company's public marketing website is hosted on S3. It will always trigger `s3-bucket-public-read-prohibited`. But it's intentionally public — that's the whole point.

The skill in CSPM operations isn't just finding misconfigs. It's **contextualising findings**: determining which ones represent real risk versus known, business-justified exceptions. Suppressing a finding without documentation is an audit risk; suppressing it with a clear reason is good practice.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Config Developer Guide | https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html |
| AWS Config Managed Rules | https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html |
| CIS AWS Foundations Benchmark | https://www.cisecurity.org/benchmark/amazon_web_services |
| MITRE ATT&CK Cloud — Initial Access | https://attack.mitre.org/tactics/TA0001/ |

---

## 🛠️ Lab (1 hour)

### Step 1 — Enable AWS Config (20 min)

1. AWS Console → search **Config** → **AWS Config**
2. Click **Get started**
3. Configure recording:
   - **Record all resources supported in this region** ✅
   - **Include global resources (e.g. IAM)** ✅ — this captures IAM users, roles, and policies
4. **Amazon S3 bucket:** Select **Create a bucket** — Config will name it automatically
5. **AWS Config role:** Select **Create AWS Config service-linked role**
6. Click **Next** → **Next** → **Confirm**

Wait 5–10 minutes for Config to complete its initial resource discovery. You'll see the resource count climb in the dashboard.

### Step 2 — Enable Your First Managed Rules (25 min)

1. Config → left menu → **Rules** → **Add rule**
2. Search: `root-account-mfa-enabled` → select it → **Next** → **Save**
3. Repeat for: `s3-bucket-public-read-prohibited`
4. Repeat for: `mfa-enabled-for-iam-console-access`
5. Repeat for: `ec2-instances-in-vpc`

Config evaluates each rule within a few minutes of activation.

### Step 3 — Read Your First Results (15 min)

1. Config → **Rules** → click `root-account-mfa-enabled`
2. Compliance status should show **Compliant** — you enabled root MFA on Day 1
3. Click `mfa-enabled-for-iam-console-access` — check which IAM users are flagged
4. Go to **Config → Dashboard** — note the total resource count and overall compliance percentage
5. Click into any non-compliant resource → read the finding detail → observe how Config tells you exactly which configuration attribute caused the failure

---

## ✅ Checklist

- [ ] AWS Config enabled with global resource recording (IAM) included
- [ ] Config S3 bucket created and receiving snapshots
- [ ] `root-account-mfa-enabled` rule active and showing Compliant
- [ ] `s3-bucket-public-read-prohibited` rule active
- [ ] `mfa-enabled-for-iam-console-access` rule active
- [ ] `ec2-instances-in-vpc` rule active
- [ ] Screenshot of Config Dashboard showing resource count and compliance overview
- [ ] Screenshot of at least one rule evaluation result

**Portfolio commit:**
```bash
git commit -m "Day 02: AWS Config enabled, 4 managed rules active, CSPM baseline established"
```

---

## 📝 Quiz

→ [week-1/quiz/week-1-quiz.md](./quiz/week-1-quiz.md) — Questions 4 & 5 cover today's content.

---

## 🧹 Cleanup

Nothing to clean up today — Config and its rules should remain active for the rest of the program. The S3 bucket Config creates stays within Free Tier limits.
