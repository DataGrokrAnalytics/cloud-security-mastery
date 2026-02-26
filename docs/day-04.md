# Day 04 — Policy-as-Code: AWS Organizations & SCPs

**Week 1: Foundations & Visibility** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will understand the difference between IAM policies and Service Control Policies, and implement a preventative guardrail that no account administrator can bypass — even with full admin permissions.

> ⚠️ **Before you start:** This lab creates an AWS Organization (free) and attaches SCPs to OUs. SCPs on the management account itself have no effect — but read each step carefully before applying any SCP. An incorrectly scoped deny SCP on the wrong OU could lock you out of actions in member accounts.

---

## 📖 Theory (2.5 hours)

### 1. Two Different Jobs: IAM vs. SCPs

Days 1–3 introduced IAM — policies that grant or deny permissions to specific identities (users, roles). Service Control Policies (SCPs) work at a completely different level, and confusing the two is one of the most common mistakes in AWS security.

**The one-sentence distinction:**
- IAM policies answer: *"What is this identity allowed to do?"*
- SCPs answer: *"What is the maximum anyone in this account is ever allowed to do?"*

SCPs do not grant permissions. They define ceilings. Think of it like a building's fire door — it limits where people can go regardless of what key they hold. An IAM policy is the key; the SCP is the door.

---

### 2. The Correct IAM Policy Evaluation Order

This is a commonly misrepresented concept — some AWS documentation presents it unclearly. The actual sequence when AWS evaluates whether to allow an API call:

```
1. Is there an explicit Deny in any SCP?          → DENY immediately
2. Is there an explicit Deny in any IAM policy?   → DENY immediately
3. Does the SCP allow this action?                → If not, DENY
4. Does an IAM policy allow this action?          → ALLOW
5. No explicit allow found anywhere?              → DENY (implicit)
```

The critical insight: **if an SCP doesn't explicitly allow something, it's implicitly denied** — regardless of what any IAM policy says. This is why SCPs are powerful: they define a boundary that no identity inside the account can escape, even a full administrator.

---

### 3. The AWS Organizations Hierarchy

AWS Organizations lets you group multiple AWS accounts into a tree structure:

```
Root (management account)
├── OU: Production
│   ├── Account: prod-web
│   └── Account: prod-data
├── OU: Development
│   └── Account: dev-sandbox
└── OU: Security
    └── Account: security-tooling
```

SCPs are attached to OUs or the Root. They apply to every account under that node. An SCP attached to the Root applies to every account in the entire organization — including the management account's child accounts, but not the management account itself.

**Important:** The management account is always exempt from SCPs. This is by design and cannot be changed — it's a safety mechanism so you can never fully lock yourself out of your organization.

---

### 4. FullAWSAccess — The Default SCP

When you first enable SCPs in Organizations, AWS attaches a policy called `FullAWSAccess` to every OU and account. This policy allows all actions — it's a permissive baseline that means "SCPs don't restrict anything yet."

Your custom deny SCPs work alongside `FullAWSAccess`. You don't remove `FullAWSAccess` — you add targeted deny policies on top of it. The deny takes precedence.

---

### 5. Common SCP Patterns

**Deny public S3 buckets**
Prevents any account from disabling S3 public access block settings — even a full admin.

**Region restriction**
Allows only specific AWS regions, blocking resource creation in unexpected locations. Useful for data residency requirements (e.g., all data must stay in eu-west-1).

**Protect audit infrastructure**
Denies changes to CloudTrail, Config, and Security Hub. An attacker who compromises an admin account cannot delete your audit logs.

**Enforce tagging**
Denies resource creation without specific tags (e.g., `Environment`, `Owner`). Enforces cost allocation and accountability across teams.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Organizations SCPs | https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html |
| SCP Examples Library | https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html |
| IAM Policy Evaluation Logic | https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html |
| NIST 800-53 Rev 5 | https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final |

---

## 🛠️ Lab (1 hour)

### Step 1 — Create an AWS Organization (15 min)

1. AWS Console → search → **AWS Organizations**
2. **Create an organization** → **Create organization**
3. Your current account becomes the **management account** — note this in your portfolio
4. Left menu → **AWS accounts** → you'll see your account listed under **Root**
5. Create an OU: right-click **Root** → **Create new organizational unit**
6. Name: `Sandbox` → **Create organizational unit**

---

### Step 2 — Enable SCPs (5 min)

1. Organizations → left menu → **Policies**
2. Click **Service control policies**
3. If not enabled: **Enable service control policies**
4. Confirm `FullAWSAccess` is shown — this is the default permissive baseline attached to everything

---

### Step 3 — Create a Deny-Public-S3 SCP (20 min)

This SCP prevents anyone in a member account from disabling S3 public access block settings — even if their IAM policy grants full S3 permissions.

1. Organizations → Policies → Service control policies → **Create policy**
2. Name: `Deny-S3-Public-Access-Disable`
3. Description: `Prevents disabling S3 block public access settings in any member account`
4. Replace the policy JSON editor content with:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDisableS3BlockPublicAccess",
      "Effect": "Deny",
      "Action": [
        "s3:PutBucketPublicAccessBlock",
        "s3:DeletePublicAccessBlock"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "s3:PublicAccessBlockConfiguration/BlockPublicAcls": "false",
          "s3:PublicAccessBlockConfiguration/IgnorePublicAcls": "false",
          "s3:PublicAccessBlockConfiguration/BlockPublicPolicy": "false",
          "s3:PublicAccessBlockConfiguration/RestrictPublicBuckets": "false"
        }
      }
    }
  ]
}
```

5. **Create policy**

---

### Step 4 — Attach to Sandbox OU and Verify (20 min)

1. Organizations → **AWS accounts** → click your **Sandbox** OU
2. **Policies** tab → **Attach** → select `Deny-S3-Public-Access-Disable` → **Attach policy**
3. Confirm: the Sandbox OU now shows both `FullAWSAccess` and your new SCP

**Document the policy logic for your portfolio:**
Write a brief explanation of what this SCP does and what attack scenario it prevents. Example:
> *"This SCP prevents any identity — including account administrators — from disabling S3 public access block settings in the Sandbox OU. This addresses the scenario where an attacker compromises an admin IAM role and attempts to expose S3 data by making buckets public. The SCP operates at the organization layer and cannot be bypassed by any IAM policy in member accounts."*

> **Note on testing:** SCPs don't apply to the management account itself. To see the deny in action you'd need a member account. For now, document the SCP and confirm it's attached — the portfolio evidence is the JSON + attachment screenshot.

---

## ✅ Checklist

- [ ] AWS Organization created with your account as management account
- [ ] Sandbox OU created under Root
- [ ] SCPs feature enabled
- [ ] `Deny-S3-Public-Access-Disable` SCP created with correct JSON
- [ ] SCP attached to Sandbox OU
- [ ] Screenshot: SCP policy JSON in Organizations console
- [ ] Screenshot: Sandbox OU showing both FullAWSAccess and your SCP attached
- [ ] One-paragraph explanation of the SCP written for portfolio

**Portfolio commit:**
```bash
git add screenshots/day-04-*.png
git commit -m "Day 04: AWS Organizations created, Deny-S3-Public-Access SCP implemented and attached to Sandbox OU"
git push
```

---

## 📝 Quiz

→ [week-1/quiz/week-1-quiz.md](./quiz/week-1-quiz.md) — Questions 8 & 9 cover today's content.

---

## 🧹 Cleanup

Nothing to delete today — the Organization and SCP should persist for the rest of the program.
