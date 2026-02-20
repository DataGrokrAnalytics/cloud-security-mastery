# Day 13 — Just-in-Time Access & Cross-Account Roles

**Week 2: Zero Trust Identity** | 4 hours | Difficulty: Advanced

---

## 🎯 Objective

By the end of today you will understand Just-in-Time (JIT) access patterns, be able to create cross-account IAM roles with time-limited session policies, and understand why standing privileges are the primary driver of lateral movement in cloud breaches.

---

## 📖 Theory (2.5 hours)

### 1. The Standing Privilege Problem

Standing privileges are permissions that exist permanently — an IAM user or role that always has admin access, always has database write access, always can assume a privileged role. They're convenient, and they're a persistent security liability.

The risk is simple: if an attacker compromises an identity with standing privileges, they immediately have everything that identity can do. There's no time window where the breach is limited — the full blast radius is available from the first second of compromise.

**The JIT principle:** Grant elevated access only when a specific task requires it, for a specific duration, and revoke it automatically when the time expires. An attacker who compromises a JIT identity during a window when it holds no elevated permissions gains almost nothing.

---

### 2. How JIT Access Works in AWS

AWS implements JIT through **temporary credentials** via the Security Token Service (STS). When an identity assumes an IAM role, STS issues temporary credentials with a configurable expiry (15 minutes to 12 hours). When the credentials expire, access is automatically revoked — no manual cleanup required.

**The assume-role pattern:**

```
Developer IAM user (no direct permissions)
          ↓
    sts:AssumeRole (with MFA required)
          ↓
  Temporary credentials (1-hour TTL)
          ↓
  Elevated role permissions (only during TTL)
          ↓
  Credentials expire → access revoked automatically
```

The developer's base IAM user has almost no permissions. To do privileged work, they explicitly request elevated access by assuming a role. The request requires MFA. The credentials expire automatically.

---

### 3. Session Policies — Scoping Down Temporarily

Session policies are an additional permission boundary applied at the moment of assuming a role. They cannot grant more than the role allows, but they can restrict further:

```bash
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/AdminRole" \
  --role-session-name "debug-session-$(date +%s)" \
  --duration-seconds 3600 \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": "arn:aws:s3:::specific-bucket/*"
    }]
  }'
```

Even though `AdminRole` has full access, this session is scoped to read-only access on a single bucket for 1 hour. This is the JIT pattern applied precisely.

---

### 4. Cross-Account Role Access

Cross-account roles allow identities in Account A to assume a role in Account B. This is the standard pattern for multi-account AWS environments — rather than duplicating users across every account, you maintain users centrally in an identity account and use roles for access everywhere else.

**Trust policy** (in Account B's role — defines who can assume it):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::ACCOUNT-A-ID:root"
    },
    "Action": "sts:AssumeRole",
    "Condition": {
      "Bool": {"aws:MultiFactorAuthPresent": "true"},
      "StringEquals": {"sts:ExternalId": "unique-external-id"}
    }
  }]
}
```

**The ExternalId condition** is important for third-party access. Without it, any principal in the trusted account could assume the role — including ones you didn't intend. ExternalId acts as a shared secret that the trusted party must provide, preventing confused deputy attacks.

---

### 5. The Confused Deputy Problem

A confused deputy attack occurs when a privileged service is tricked into performing actions on behalf of an attacker. In IAM:

1. Your account creates a role trusting a third-party SaaS tool (Account X)
2. A different customer of that SaaS also has an account (Account Y)
3. Account Y tells the SaaS to access Account X's resources using its role ARN
4. The SaaS, acting as a trusted service, assumes your role — on behalf of an attacker

The ExternalId condition prevents this: you set a unique ExternalId when creating the role, and the SaaS must provide that exact value when assuming it. Account Y doesn't know your ExternalId, so they can't impersonate the legitimate principal.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS STS AssumeRole | https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html |
| IAM Roles Terms and Concepts | https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html |
| Confused Deputy Prevention | https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html |
| Session Policy Limits | https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session |

---

## 🛠️ Lab (1 hour)

### Step 1 — Create a JIT Elevated Access Role (20 min)

Create a role that your IAM user can assume for short-term elevated access, requiring MFA.

1. IAM → **Roles** → **Create role**
2. Trusted entity: **AWS account** → **This account**
3. Add condition: **MFA required** → check ✅ **Require MFA**
4. Attach policy: `ReadOnlyAccess` (we'll use read-only so the lab is safe)
5. Role name: `JIT-ReadOnly-1Hour`
6. Description: `JIT role for temporary read-only access. Requires MFA. Session expires in 1 hour.`
7. **Create role**

Note the Role ARN from the role summary page.

---

### Step 2 — Assume the Role with a 1-Hour TTL (20 min)

```bash
# Assume the role with a 1-hour session (3600 seconds)
# Replace ACCOUNT-ID and add your MFA serial ARN and current token code

aws sts assume-role \
  --role-arn "arn:aws:iam::YOUR-ACCOUNT-ID:role/JIT-ReadOnly-1Hour" \
  --role-session-name "jit-session-$(date +%Y%m%d-%H%M%S)" \
  --duration-seconds 3600 \
  --serial-number "arn:aws:iam::YOUR-ACCOUNT-ID:mfa/YOUR-USERNAME" \
  --token-code "YOUR-CURRENT-MFA-CODE"
```

The output contains temporary `AccessKeyId`, `SecretAccessKey`, and `SessionToken` — plus an `Expiration` timestamp showing when they'll become invalid.

Export the credentials:
```bash
export AWS_ACCESS_KEY_ID="[from output]"
export AWS_SECRET_ACCESS_KEY="[from output]"
export AWS_SESSION_TOKEN="[from output]"

# Confirm the assumed identity
aws sts get-caller-identity
# Should show the JIT-ReadOnly-1Hour role, not your IAM user
```

---

### Step 3 — Verify Scope and Expiry (20 min)

With the temporary credentials active, verify they work and are scoped correctly:

```bash
# This should work — read-only access
aws s3 ls

# This should fail — no write access in ReadOnlyAccess policy
aws s3 mb s3://jit-test-bucket-$(date +%s)
# Expected: An error occurred (AccessDenied)
```

Document the expiration time from the `assume-role` output. This is the automatic revocation — when the timestamp passes, these credentials stop working without any manual action.

Clear the temporary credentials:
```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

# Confirm you're back to your regular identity
aws sts get-caller-identity
```

---

## ✅ Checklist

- [ ] `JIT-ReadOnly-1Hour` role created with MFA required in trust policy
- [ ] Role assumed successfully with MFA token code
- [ ] `aws sts get-caller-identity` confirms assumed role identity
- [ ] Write action confirmed as denied (scope enforced)
- [ ] Credentials cleared — back to base identity
- [ ] Expiration timestamp noted in portfolio
- [ ] Screenshot: `sts get-caller-identity` showing JIT role
- [ ] Screenshot: AccessDenied on write action

**Portfolio commit:**
```bash
git add screenshots/day-13-*.png
git commit -m "Day 13: JIT role with 1-hour TTL and MFA enforcement — temporary credentials demonstrated"
git push
```

---

## 📝 Quiz

→ [week-2/quiz/week-2-quiz.md](./quiz/week-2-quiz.md) — Question 9.

---

## 🧹 Cleanup

The `JIT-ReadOnly-1Hour` role has no persistent permissions and costs nothing. Keep it for the Week 2 portfolio review on Day 14.
