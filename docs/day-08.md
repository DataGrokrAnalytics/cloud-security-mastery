# Day 08 — IAM Policy Mastery

**Week 2: Zero Trust Identity** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will understand how AWS evaluates IAM policies, be able to write and test your own custom policies, and catch the permission mistakes that cause most real-world cloud breaches.

---

## 📖 Theory (2.5 hours)

### 1. Why IAM Is the Master Key to Everything

In a traditional data centre, the network perimeter was the primary defence. If an attacker couldn't reach your server, they couldn't compromise it. In cloud, that perimeter barely exists — services communicate over APIs, developers access resources from laptops and CI/CD pipelines, and everything is authenticated through a single layer: IAM.

A compromised IAM identity with excessive permissions is more dangerous than a compromised server. The server has one blast radius; the IAM identity can touch every service it has permissions for, across every region, instantly.

This is why Week 2 exists before networking (Week 3) — identity is the higher-leverage target.

---

### 2. The Three Types of IAM Policy

**Identity-based policies** — attached to a user, group, or role. Answer: "what can this identity do?"

**Resource-based policies** — attached directly to a resource (S3 bucket, KMS key, SQS queue). Answer: "who can access this resource?" Resource-based policies can grant cross-account access without assuming a role.

**Session policies** — passed programmatically when assuming a role. They cannot grant more than the role's identity policy allows. Used to scope down permissions temporarily.

Understanding which type applies in a given scenario is essential for debugging access problems.

---

### 3. Policy Structure — Every Element Matters

Every IAM policy statement has five elements:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadOnly",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "StringEquals": {"aws:RequestedRegion": "eu-west-1"}
      }
    }
  ]
}
```

**Sid** — Statement ID. Optional but always include it — it's your documentation inside the policy. Use descriptive names like `AllowS3ReadOnly`, not `Statement1`.

**Effect** — `Allow` or `Deny`. Every statement must have one.

**Action** — The specific API call(s) this statement covers. Use least privilege: specify exactly what's needed, not `s3:*`. Wildcards (`*`) in actions are a red flag in any policy review.

**Resource** — Which specific resources this applies to. `"Resource": "*"` means all resources of that service type — almost always too broad. Scope to specific ARNs wherever possible.

**Condition** — Optional but powerful. Restricts when the policy applies: by IP address, by MFA presence, by region, by tag value, by time of day. Conditions are the mechanism for context-aware access control.

---

### 4. The Evaluation Order (Complete Picture)

Building on Day 4's introduction, here is the full evaluation sequence AWS runs for every API call:

```
1. Explicit Deny in any SCP?                     → DENY
2. Explicit Deny in any permission boundary?     → DENY
3. Explicit Deny in any identity-based policy?   → DENY
4. Explicit Deny in any resource-based policy?   → DENY
5. SCP allows the action?                        → Continue / DENY if not
6. Resource-based policy grants access?          → ALLOW (even without identity policy)
7. Identity-based policy allows the action?      → ALLOW
8. Nothing matched?                              → DENY (implicit)
```

The most important insight: **explicit Deny beats everything**. There is no way to override an explicit Deny with an Allow in another policy. This makes Deny statements your strongest tool for enforcing non-negotiable restrictions.

---

### 5. Common Policy Mistakes

**Mistake 1: Wildcards in Action**
```json
"Action": "s3:*"    ← gives full S3 access including deleting buckets
"Action": "s3:Get*" ← better, but still broader than necessary
"Action": ["s3:GetObject", "s3:ListBucket"] ← correct
```

**Mistake 2: Wildcards in Resource**
```json
"Resource": "*"                          ← all S3 buckets in all accounts
"Resource": "arn:aws:s3:::*"             ← all S3 buckets in your account
"Resource": "arn:aws:s3:::app-bucket/*"  ← correct
```

**Mistake 3: Missing the bucket ARN for ListBucket**
```json
// Wrong — ListBucket needs the bucket ARN, GetObject needs the object ARN
"Resource": "arn:aws:s3:::my-bucket/*"

// Correct — both ARNs required for read access to work properly
"Resource": [
  "arn:aws:s3:::my-bucket",
  "arn:aws:s3:::my-bucket/*"
]
```

**Mistake 4: No Condition on sensitive actions**
An `Allow` on `iam:PassRole` without a condition lets the identity pass any role to any service. Scope it:
```json
"Condition": {
  "StringEquals": {"iam:PassedToService": "ec2.amazonaws.com"}
}
```

---

### 6. The IAM Policy Simulator

Before attaching any policy to a production identity, test it. The IAM Policy Simulator lets you simulate API calls against a policy without making real API calls:

- Test whether a specific action is allowed or denied
- See exactly which statement in which policy is granting or denying
- Debug "Access Denied" errors without trial and error

This should be a standard step in any IAM policy review workflow.

---

## 🔗 References

| Resource | URL |
|---|---|
| IAM Policy Reference | https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html |
| IAM Policy Simulator | https://policysim.aws.amazon.com/ |
| IAM Policy Evaluation Logic | https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html |
| AWS Managed vs Customer Managed Policies | https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html |

---

## 🛠️ Lab (1 hour)

### Step 1 — Write Five Custom IAM Policies (35 min)

Create each policy in IAM → Policies → Create policy → JSON tab. Do not attach them yet — just create and save.

**Policy 1: S3 Read-Only for a Specific Bucket**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadSpecificBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME",
        "arn:aws:s3:::YOUR-BUCKET-NAME/*"
      ]
    }
  ]
}
```
Name it: `S3ReadOnly-AppBucket`

---

**Policy 2: EC2 Read-Only (no start/stop/terminate)**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEC2ReadOnly",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:GetConsole*"
      ],
      "Resource": "*"
    }
  ]
}
```
Name it: `EC2ReadOnly`

---

**Policy 3: Deny Actions Outside a Specific Region**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOutsideEUWest1",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "sts:*",
        "cloudfront:*",
        "route53:*",
        "support:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": "eu-west-1"
        }
      }
    }
  ]
}
```
Name it: `DenyNonEUWest1Region`

> Note: Global services (IAM, STS, Route53) are excluded via `NotAction` because they don't have a regional endpoint.

---

**Policy 4: Allow Secrets Manager Read with MFA Required**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSecretsReadWithMFA",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```
Name it: `SecretsReadRequireMFA`

---

**Policy 5: Developer Policy — S3 + Lambda + CloudWatch, No IAM**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowDeveloperServices",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject", "s3:PutObject", "s3:ListBucket",
        "lambda:InvokeFunction", "lambda:GetFunction",
        "logs:CreateLogGroup", "logs:CreateLogStream",
        "logs:PutLogEvents", "logs:DescribeLogGroups"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyIAMChanges",
      "Effect": "Deny",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
```
Name it: `DeveloperPolicy-NoIAM`

---

### Step 2 — Test with IAM Policy Simulator (25 min)

1. Go to https://policysim.aws.amazon.com/
2. Left panel → **IAM users, groups, and roles** → select your admin IAM user
3. Under **Policies**, check `S3ReadOnly-AppBucket`
4. Right panel → Service: **S3** → Action: **PutObject** → **Run Simulation**
   - Expected result: **Denied** (the policy only allows Get and List)
5. Change Action to **GetObject** → **Run Simulation**
   - Expected result: **Allowed**
6. Now test `SecretsReadRequireMFA`:
   - Select the policy
   - Service: **Secrets Manager** → Action: **GetSecretValue**
   - Under **Simulation Settings** → set `aws:MultiFactorAuthPresent` to `false`
   - Run — expected result: **Denied**
   - Change to `true` → Run — expected result: **Allowed**
7. Screenshot both test results for your portfolio

---

## ✅ Checklist

- [ ] All 5 custom IAM policies created in your account
- [ ] `S3ReadOnly-AppBucket` tested — PutObject denied, GetObject allowed
- [ ] `SecretsReadRequireMFA` tested — denied without MFA, allowed with MFA
- [ ] Screenshots of Policy Simulator results saved
- [ ] Policy names and purpose noted in portfolio

**Portfolio commit:**
```bash
git add screenshots/day-08-*.png
git commit -m "Day 08: 5 custom IAM policies created and tested with Policy Simulator"
git push
```

---

## 📝 Quiz

→ [week-2/quiz/week-2-quiz.md](./quiz/week-2-quiz.md) — Questions 1 & 2.

---

## 🧹 Cleanup

Keep all 5 policies — you'll use them in Day 09 and Day 10 labs.
