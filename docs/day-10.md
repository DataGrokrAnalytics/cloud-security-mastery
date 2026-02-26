# Day 10 — CIEM: Credential Management & Entitlement Sprawl

**Week 2: Zero Trust Identity** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will understand Cloud Infrastructure Entitlement Management (CIEM), have your secrets moved out of code and into Secrets Manager, and have generated an IAM credential report to identify every over-privileged and dormant identity in your account.

---

## 📖 Theory (2.5 hours)

### 1. What Is CIEM and Why Does It Exist?

Cloud Infrastructure Entitlement Management (CIEM) addresses a problem that scales poorly in cloud: permission sprawl.

In a small team with 5 AWS users, reviewing who has access to what is manageable. In an organisation with 200 engineers, 50 CI/CD service accounts, 30 Lambda execution roles, and 20 cross-account trusts — tracking permissions manually is impossible. Identities accumulate permissions over time as features are added. No one removes permissions when they're no longer needed. Old service accounts are forgotten but never deleted.

The result is an environment where the *effective* attack surface is far larger than anyone realises. An attacker who compromises any one of these over-privileged, dormant identities gains a foothold that may be exploitable for months before anyone notices.

CIEM is the discipline of continuously auditing and right-sizing entitlements — using tooling to surface what humans can't track manually.

---

### 2. The Credentials Problem

Secrets — database passwords, API keys, third-party tokens — have a natural tendency to end up in the wrong places:

- Hardcoded in application source code
- Stored in environment variables in Lambda or ECS
- Committed to Git repositories (sometimes public ones)
- Emailed between developers
- Stored in plaintext config files on EC2 instances

Every one of these is a breach waiting to happen. The correct pattern is to store secrets in a dedicated secrets management service — AWS Secrets Manager — and have applications retrieve them at runtime via API call.

**Why Secrets Manager over environment variables:**
- Secrets can be rotated automatically without redeploying code
- Access is controlled by IAM and auditable via CloudTrail
- Secrets are encrypted at rest with KMS
- Access can be restricted by IP, MFA status, or tag condition

**The rotation feature is the most important advantage.** A secret that automatically rotates every 30 days has a maximum exposure window of 30 days even if it's leaked — compared to a hardcoded secret that stays compromised until a human notices and manually rotates it.

---

### 3. IAM Credential Report

AWS generates a credential report — a CSV file listing every IAM user in your account and the status of their credentials:

| Column | What It Tells You |
|---|---|
| `password_enabled` | Does this user have console access? |
| `password_last_used` | When did they last log in? |
| `password_last_changed` | When was the password last rotated? |
| `mfa_active` | Do they have MFA enabled? |
| `access_key_1_active` | Do they have an active access key? |
| `access_key_1_last_used_date` | When was the key last used? |
| `access_key_1_last_rotated` | When was the key last rotated? |

This report is a goldmine for CIEM work. Users with console access but no MFA are a risk. Users whose access keys haven't been used in 90 days are candidates for key deletion. Users who haven't logged in for 180 days are candidates for account deactivation.

CIS Benchmark controls 1.12, 1.13, and 1.14 all relate directly to what this report reveals.

---

### 4. Dormant Credentials — A Specific Risk Pattern

Dormant credentials are active credentials belonging to identities that haven't been used recently. They represent a risk that's easy to miss precisely because they're quiet — no login activity, no API calls, nothing to trigger an alert.

But dormant doesn't mean harmless. An attacker who gains access to a dormant IAM user's credentials has a working set of keys that may go unnoticed for far longer than if they used an active account (where anomalous activity would stand out).

**The right policy:**
- Access keys unused for 90 days → deactivate (not delete — gives a recovery window)
- Access keys unused for 180 days → delete
- IAM users who haven't logged in for 90 days → review and potentially deactivate
- IAM users who have never logged in → delete (was the account ever needed?)

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Secrets Manager | https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html |
| IAM Credential Report | https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html |
| Secrets Manager Rotation | https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html |
| Gartner CIEM Definition | https://www.gartner.com/en/information-technology/glossary/cloud-infrastructure-entitlement-management-ciem |

---

## 🛠️ Lab (1 hour)

### Step 1 — Store a Secret in Secrets Manager (20 min)

1. AWS Console → **Secrets Manager** → **Store a new secret**
2. Secret type: **Other type of secret**
3. Key/value pairs — add:
   - Key: `db_username` Value: `app_user`
   - Key: `db_password` Value: `MySecurePassword123!`
4. **Next**
5. Secret name: `prod/myapp/database`
6. Description: `Database credentials for the application — Day 10 lab`
7. **Next** → Enable automatic rotation: leave off for now (requires a Lambda rotation function)
8. **Store**

**Retrieve the secret via CLI** to verify it works:
```bash
aws secretsmanager get-secret-value \
  --secret-id prod/myapp/database \
  --query SecretString \
  --output text
```

This is the pattern your application code should use — retrieve at runtime, never store locally.

---

### Step 2 — Generate and Analyse the IAM Credential Report (25 min)

1. AWS Console → **IAM** → left menu → **Credential report**
2. **Download Report** (CSV file)
3. Open in Excel, Google Sheets, or Numbers

Analyse each IAM user row and flag:

| Check | Flag if... |
|---|---|
| Console access without MFA | `password_enabled = true` AND `mfa_active = false` |
| Stale access keys | `access_key_1_last_used_date` > 90 days ago |
| Never-used access keys | `access_key_1_last_used_date = N/A` and key is active |
| Stale passwords | `password_last_used` > 90 days ago |
| Old access key rotation | `access_key_1_last_rotated` > 90 days ago |

Create a summary table in your portfolio:

```
IAM Credential Report Analysis — [date]

Users with console access but no MFA: [count]
Users with stale access keys (>90 days): [count]
Users with never-used access keys: [count]
Actions taken: [list what you fixed]
```

---

### Step 3 — Fix the Findings (15 min)

For each flagged item from Step 2, take action:

- **No MFA on console user** → Enable MFA (IAM → Users → user → Security credentials → Assign MFA)
- **Never-used access key** → Deactivate it (IAM → Users → user → Security credentials → Access keys → Make inactive)
- **Key not rotated in 90+ days** → Create a new key, update any applications using the old key, then delete the old key

Document every action taken — this is your audit trail.

---

## ✅ Checklist

- [ ] Secret created in Secrets Manager (`prod/myapp/database`)
- [ ] Secret successfully retrieved via CLI
- [ ] IAM Credential Report downloaded and analysed
- [ ] Summary table created with findings counts
- [ ] All flagged credentials addressed (MFA enabled, stale keys deactivated)
- [ ] Screenshot: Secrets Manager secret stored
- [ ] Screenshot: Credential report analysis summary

**Portfolio commit:**
```bash
git add screenshots/day-10-*.png
git commit -m "Day 10: Secrets Manager configured, credential report analysed, dormant credentials remediated"
git push
```

---

## 📝 Quiz

→ [week-2/quiz/week-2-quiz.md](./quiz/week-2-quiz.md) — Questions 5 & 6.

---

## 🧹 Cleanup

Keep the Secrets Manager secret — you'll reference it on Day 13. Note that Secrets Manager charges $0.40/secret/month after the 30-day free trial. Delete it after Day 14 if you want to avoid the charge.
