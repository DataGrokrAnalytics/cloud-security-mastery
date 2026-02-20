# Day 1 — AWS Account Hardening & MFA Foundation

**Week 1: Foundations & Visibility** | 4 hours | Difficulty: Beginner

---

## 🎯 Objective

By the end of today you will have:
- A hardened AWS Free Tier account with MFA on the root user
- A dedicated IAM admin user for all future lab work (root stays locked away)
- A billing alert so you can't accidentally spend money
- A clear mental model of the Shared Responsibility Model — the most important concept in cloud security

---

## 📖 Theory (2.5 hours)

### 1. The Shared Responsibility Model

The first thing to internalise about cloud security: **AWS and you split the security work**, and the exact split depends on which type of service you use.

| Service Type | Example | AWS Secures | You Secure |
|---|---|---|---|
| **IaaS** | EC2 | Physical hardware, hypervisor, network fabric | OS, middleware, runtime, app code, data |
| **PaaS** | RDS | Everything above + OS + DB engine patching | DB configuration, access control, data, encryption |
| **SaaS** | S3 | Almost everything beneath your data | Data classification, bucket policies, encryption settings, identities |

**The practical implication:** A misconfigured S3 bucket exposing customer data is not an AWS failure — it is yours. AWS secures the storage service itself; you are responsible for *how you configure access to it*. This is the source of most real-world cloud breaches.

> **Example breach — Capital One (2019):** An attacker exploited a misconfigured Web Application Firewall on an EC2 instance to access an IAM role, then used that role's excessive permissions to exfiltrate data from S3. AWS's infrastructure was fine. The misconfiguration — both the WAF config and the overly permissive IAM role — was entirely on the customer side of the responsibility model.

---

### 2. The Root Account — Why It's Dangerous

Every AWS account has a **root user** that has unconditional, unrestricted access to everything in the account. Root can:

- Delete every CloudTrail log (destroy all audit evidence)
- Close your AWS account entirely
- Remove MFA from all users
- Access billing information regardless of IAM policies

Attackers who compromise root credentials essentially own your entire AWS footprint. The risk is too high to use root for routine work.

**The rules:**
1. Enable MFA on root immediately — before anything else
2. Never create access keys for root (would allow API access without MFA)
3. Never use root for day-to-day work — create a separate IAM admin user
4. Store root credentials in a password manager + treat the MFA device like a physical key

---

### 3. MFA — Not All Second Factors Are Equal

MFA adds a second verification step, but different MFA types have meaningfully different security properties:

**TOTP apps** (Google Authenticator, Authy, Microsoft Authenticator)  
Generate a time-based 6-digit code that refreshes every 30 seconds.  
**Weakness:** Vulnerable to real-time phishing. An attacker can run a fake AWS login page that proxies your credentials and TOTP code to the real AWS in real time, before the code expires.

**Hardware security keys** (YubiKey, any FIDO2/WebAuthn key)  
The key performs a cryptographic handshake directly with your browser, and critically — it **verifies the domain name of the page you're logging into**. If the login page is `aws.amazon.com.evil.com` instead of `signin.aws.amazon.com`, the key refuses to authenticate. Real-time phishing becomes practically impossible.

**Recommendation for this program:** A TOTP app is fine for your personal learning account. In production, use hardware keys for root and any privileged users.

---

### 4. IAM Users vs. Root — The Right Setup

The correct structure for this program:

```
Root account  →  Locked away (MFA enabled, no access keys, rarely used)
      │
      └── IAM User: "admin" (you) → AdministratorAccess policy
                │
                └── All labs and daily work happen here
```

Why not just use root for the labs? Two reasons:

1. **Habit formation:** Production environments require this separation. Building the habit now matters.
2. **CloudTrail logging:** Actions performed as root are logged differently and are harder to filter and audit. An IAM user's actions are tagged with a clear identity.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Shared Responsibility Model | https://aws.amazon.com/compliance/shared-responsibility-model/ |
| AWS IAM MFA | https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html |
| AWS Free Tier limits | https://aws.amazon.com/free/ |
| AWS Budgets | https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html |
| Verizon DBIR (annual report) | https://www.verizon.com/business/resources/reports/dbir/ |

---

## 🛠️ Lab (1 hour)

> The shell script in `week-1/labs/day-01-iam-hardening.sh` automates Steps 3 and 4 if you prefer CLI over console. Steps 1 and 2 require the console — you can't enable MFA programmatically for root.

---

### Step 1 — Create Your AWS Free Tier Account (10 min)

*Skip this if you already have a personal AWS account.*

1. Go to https://aws.amazon.com/free/ → **Create a Free Account**
2. Enter your email address and choose an account name (e.g., `yourname-security-lab`)
3. Choose **Personal** account type
4. Enter a credit card — you won't be charged if you stay in Free Tier limits and run the cleanup scripts
5. Complete phone verification and choose the **Basic support plan** (free)
6. Log in at https://console.aws.amazon.com

---

### Step 2 — Enable MFA on the Root Account (15 min)

This is the single most important thing you'll do today.

1. Log in to the AWS console with your root credentials (the email/password you just created)
2. Top-right corner → click your account name → **Security credentials**
3. Scroll to **Multi-factor authentication (MFA)** → **Assign MFA device**
4. Choose:
   - **Authenticator app** → scan the QR code with Google Authenticator, Authy, or Microsoft Authenticator
   - **Security key** → if you have a YubiKey, plug it in and choose this instead
5. For TOTP: enter two consecutive 6-digit codes from your app to confirm sync
6. Click **Add MFA**

**Verify:** The MFA section now shows your device with status "Active".  
**Verify:** Log out and log back in — AWS should prompt for your MFA code.

---

### Step 3 — Configure a $5 Billing Alert (10 min)

1. AWS Console → search bar → **Budgets** → **AWS Budgets**
2. **Create budget** → **Use a template** → **Monthly cost budget**
3. Budget name: `security-lab-budget`
4. Budgeted amount: `5.00` (USD)
5. Email recipients: your email address
6. **Create budget**

This alert fires when AWS *forecasts* your month's spend will exceed $5 — giving you time to investigate before you're actually charged.

---

### Step 4 — Create an IAM Admin User (25 min)

From this point on, you'll use this user for all lab work — not root.

1. AWS Console → **IAM** → left menu → **Users** → **Create user**
2. **User name:** `admin` (or your name, no spaces)
3. Check ✅ **Provide user access to the AWS Management Console**
4. Select **I want to create an IAM user**
5. Set a strong password (16+ characters, mix of types)
6. Uncheck "User must create a new password at next sign-in" (it's just you)
7. **Next**

8. **Permissions:** Select **Add user to group** → **Create group**
9. Group name: `Administrators`
10. Search for and attach: `AdministratorAccess`
11. **Create user group**
12. Add your user to this group → **Next** → **Create user**

13. **Enable MFA on this user too:**
    - IAM → Users → click your new user → **Security credentials** tab
    - **Assign MFA device** → follow the same steps as root
    - Use a *different* TOTP entry in your app (not the same one as root)

14. Note your sign-in URL: it will look like `https://123456789012.signin.aws.amazon.com/console`

15. **Log out of root. Log back in as your new IAM user.** Use root from this point only when absolutely necessary.

---

## ✅ Checklist

Work through these before committing. Each item should be verifiable with a screenshot.

- [ ] AWS account accessible at https://console.aws.amazon.com
- [ ] MFA enabled on root (IAM → Security credentials → MFA device shows "Active")
- [ ] No access keys created for root (the Access keys section should say "You don't have any access keys")
- [ ] AWS Budgets alert active at $5 with your email
- [ ] IAM group `Administrators` exists with `AdministratorAccess` policy attached
- [ ] IAM user created and added to `Administrators` group
- [ ] MFA enabled on IAM user
- [ ] You are currently logged in as the IAM user, not root

**Screenshot to save:**
- IAM Security credentials page for root (showing MFA active, no access keys)
- Budgets dashboard showing your $5 alert
- IAM Users list showing your admin user

**Portfolio commit:**
```bash
git add screenshots/day-01-*.png
git commit -m "Day 01: Root MFA enabled, $5 budget alert, IAM admin user created with MFA"
git push
```

---

## 📝 Quiz

→ [week-1/quiz/week-1-quiz.md](./quiz/week-1-quiz.md)

Questions 1–3 cover today's content. Try to answer from memory first before checking the answer key.

---

## 🧹 Cleanup

Nothing to clean up today — the resources created (IAM user, budget) should persist for the rest of the program.
