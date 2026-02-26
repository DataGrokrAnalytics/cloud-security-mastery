# Day 09 — Zero Trust & IAM Access Analyzer

**Week 2: Zero Trust Identity** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will understand the Zero Trust architecture model, have IAM Access Analyzer running to detect all external access to your AWS resources, and understand what each finding type means and how to respond.

---

## 📖 Theory (2.5 hours)

### 1. Zero Trust — What It Actually Means

"Zero Trust" is one of the most overused terms in security. Strip away the marketing and the principle is simple: **never trust, always verify, assume breach.**

In a traditional network model, once you were inside the corporate firewall you were largely trusted. VPN gave you "inside" status. Cloud destroyed this model — developers access AWS from coffee shops, CI/CD pipelines run from third-party clouds, microservices call each other across VPC boundaries. There is no meaningful "inside."

Zero Trust replaces implicit network-based trust with explicit, continuous verification of every request:

| Traditional | Zero Trust |
|---|---|
| Trust by network location (inside = trusted) | Trust by verified identity + context |
| Grant access once, rarely review | Grant minimum access, verify continuously |
| Perimeter defence | Defence at every resource |
| VPN for "secure" access | MFA + least privilege + short-lived credentials |

In AWS, Zero Trust is implemented through IAM — every API call is explicitly authenticated and authorised regardless of where it originates.

---

### 2. The Forrester Zero Trust eXtended Framework

Forrester's ZTX framework identifies five pillars of Zero Trust, all of which map directly to AWS services:

| ZTX Pillar | AWS Implementation |
|---|---|
| **Identity** | IAM users/roles, MFA, Access Analyzer |
| **Devices** | Systems Manager, EC2 instance profiles |
| **Networks** | VPC, Security Groups, NACLs, PrivateLink |
| **Applications** | Lambda authorisers, API Gateway, Cognito |
| **Data** | KMS, Macie, S3 bucket policies |

This program covers all five pillars across Weeks 2–4. Week 2 focuses on the Identity pillar — the most critical because it underpins all the others.

---

### 3. IAM Access Analyzer — What It Does

IAM Access Analyzer continuously analyses your resource-based policies and identifies resources that are accessible from outside your AWS account or organisation. It answers the question: *"What in my account can someone outside access, and through what path?"*

**What it analyses:**
- S3 bucket policies and ACLs
- IAM roles with cross-account trust policies
- KMS key policies
- Lambda function policies
- SQS queue policies
- Secrets Manager secret policies

**Finding types:**

| Finding Type | What It Means |
|---|---|
| **External access** | Resource accessible from outside your account (internet, another AWS account, AWS service) |
| **Cross-account access** | Resource accessible from a specific external AWS account |
| **Public access** | Resource accessible from anyone on the internet |
| **Unused access** | Identity has permissions it hasn't used in 90+ days |

**Archive vs. Resolve:**
- **Archive** a finding when it's intentional and reviewed (e.g., a public S3 website bucket)
- **Resolve** a finding by changing the resource policy to remove the unintended access
- Never leave findings in Active state without acting on them — it defeats the purpose

---

### 4. The Principle of Least Privilege — in Practice

Least privilege means granting only the minimum permissions required for a task. In theory, everyone agrees. In practice, it's violated constantly because:

- It's faster to grant `*` than to enumerate specific actions
- Permissions sprawl as features are added without removing old ones
- No one reviews IAM policies after the initial setup
- "I'll tighten it later" becomes permanent

**The right approach:**

Start with zero permissions and add only what's needed. Never start with broad permissions and try to restrict later — the cognitive effort is identical but the security outcome is completely different.

Use IAM Access Analyzer's **unused access** findings to identify identities that have permissions they haven't used. These are candidates for policy trimming.

Use IAM's **last accessed information** (visible on any role or user in the console) to see which services and actions have actually been used in the last 90 days — anything not in that list can potentially be removed.

---

## 🔗 References

| Resource | URL |
|---|---|
| IAM Access Analyzer | https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html |
| Forrester Zero Trust eXtended | https://www.forrester.com/blogs/the-definition-of-modern-zero-trust/ |
| Access Analyzer Finding Types | https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-findings.html |
| IAM Last Accessed Information | https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_access-advisor.html |

---

## 🛠️ Lab (1 hour)

### Step 1 — Enable IAM Access Analyzer (10 min)

1. AWS Console → **IAM** → left menu → **Access Analyzer**
2. **Create analyzer**
3. Analyzer name: `account-analyzer`
4. Zone of trust: **Current account** — this means findings represent access from *outside* your account
5. **Create analyzer**

Access Analyzer immediately begins scanning your resource policies. Findings appear within a few minutes.

---

### Step 2 — Review Your Findings (20 min)

1. IAM → Access Analyzer → **Findings** tab
2. For each finding, review:
   - **Resource** — what is accessible?
   - **Access level** — read, write, or admin?
   - **Principal** — who has access? (AWS account, service, or public)
   - **Condition** — any restrictions on when access is granted?

3. For each finding, decide:
   - **Is this intentional?** → Archive with a note
   - **Is this unintended?** → Resolve by modifying the resource policy

4. Click into any finding → read the **Finding details** panel → note the **Recommended action**

---

### Step 3 — Review IAM Last Accessed Data (20 min)

1. IAM → **Roles** → click any role (try your admin user's role or a service role)
2. **Access Advisor** tab
3. Review the list of services — note which services have **Never been accessed** or were last accessed over 90 days ago
4. These are candidates for permission removal

5. Now do the same for your IAM user:
   - IAM → Users → your admin user → **Access Advisor** tab
   - Review which services you've actually used since Day 1

6. Document one IAM role or user where you could remove at least one unused service permission.

---

### Step 4 — Create an Organisation-Level Analyzer (10 min)

The account-level analyzer catches access from outside your account. An organisation-level analyzer catches access from *outside your entire AWS organisation* — tighter scope, higher signal.

1. IAM → Access Analyzer → **Create analyzer**
2. Name: `org-analyzer`
3. Zone of trust: **Organization** (requires your account to be the management account)
4. **Create analyzer**

> If your account is not the management account of an Organization, skip this step and note it in your portfolio — this is something to implement when you have a multi-account setup.

---

## ✅ Checklist

- [ ] IAM Access Analyzer enabled (account-level)
- [ ] All findings reviewed — each either archived (intentional) or resolved (unintended)
- [ ] No Active findings with public access left unreviewed
- [ ] IAM last accessed data reviewed for at least one user and one role
- [ ] One unused permission identified and noted for removal
- [ ] Organisation-level analyzer created (or noted as pending for multi-account setup)
- [ ] Screenshot: Access Analyzer findings dashboard

**Portfolio commit:**
```bash
git add screenshots/day-09-*.png
git commit -m "Day 09: IAM Access Analyzer enabled, findings reviewed, Zero Trust baseline established"
git push
```

---

## 📝 Quiz

→ [week-2/quiz/week-2-quiz.md](./quiz/week-2-quiz.md) — Questions 3 & 4.

---

## 🧹 Cleanup

Keep both analyzers running — they provide continuous monitoring that feeds into Security Hub.
