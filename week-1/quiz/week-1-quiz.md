# Week 1 Quiz — Foundations & Visibility

Answer from memory first. The answer key is at the bottom — no peeking until you've tried all 10.

---

## Questions

**Q1.** Your company runs a web app on EC2. A developer accidentally leaves port 22 open to the internet in a security group and an attacker gets in. Who is responsible for this breach?

- A) AWS — they should have blocked the open port automatically
- B) Your company — security group configuration is the customer's responsibility
- C) Shared equally — AWS should have warned you
- D) The developer personally — they made the change

---

**Q2.** You want to enable the most phishing-resistant MFA available for your AWS root account. Which option should you choose?

- A) SMS one-time code sent to your phone
- B) TOTP authenticator app (Google Authenticator)
- C) FIDO2 hardware security key (YubiKey)
- D) Email verification code

---

**Q3.** Which of the following should you use the root account for? Select all that apply.

- A) Creating EC2 instances for a web application
- B) Enabling MFA on the root account itself
- C) Closing the AWS account permanently
- D) Creating IAM users for your team
- E) Reviewing billing and cost reports daily

---

**Q4.** AWS Config flags your company's S3 bucket that hosts a public marketing website as NON_COMPLIANT against `s3-bucket-public-read-prohibited`. What is the correct response?

- A) Make the bucket private immediately — all public buckets are a risk
- B) Suppress the finding with a documented reason: this bucket is intentionally public
- C) Disable the Config rule — it generates false positives
- D) Escalate to AWS Support to have the rule adjusted

---

**Q5.** What does AWS Config's configuration timeline let you do that a one-time compliance scan cannot?

- A) Predict future misconfigurations using machine learning
- B) See every configuration change to a resource — what changed, when, and which identity made the change
- C) Automatically roll back resources to a compliant state
- D) Schedule configuration checks for off-hours only

---

**Q6.** Your Security Hub shows 300 active findings. You have 2 hours. Which approach prioritises most effectively?

- A) Fix findings alphabetically by title
- B) Filter to CRITICAL severity on production accounts and fix the quickest ones first
- C) Fix the oldest findings first regardless of severity
- D) Export all findings and present them to your manager before doing anything

---

**Q7.** An SCP at the Root OU level contains:
```json
{ "Effect": "Deny", "Action": "cloudtrail:DeleteTrail", "Resource": "*" }
```
An IAM administrator in a member account has a policy granting full CloudTrail access. What happens when they try to delete the trail?

- A) Deletion succeeds — IAM policy explicitly grants the permission
- B) Deletion is denied — the SCP overrides any IAM allow
- C) Deletion succeeds only when using the root user of the member account
- D) AWS prompts for a second approval before proceeding

---

**Q8.** Which of the following correctly describes what an SCP "Allow" statement does?

- A) It grants the listed permissions to all identities in the account
- B) It defines the ceiling — listed actions *can* be granted by IAM, but the SCP itself grants nothing
- C) It overrides explicit IAM Deny statements for the listed actions
- D) It applies only to IAM roles, not IAM users or the root user

---

**Q9.** A prospect asks whether your SaaS product is SOC 2 compliant. You download your AWS SOC 2 Type II report from Artifact and send it to them. Is this sufficient?

- A) Yes — the AWS SOC 2 report covers the entire product stack
- B) No — the AWS report covers only AWS's infrastructure controls; you need a separate audit for your application controls
- C) Yes — any software running on AWS inherits AWS's SOC 2 certification
- D) No — SOC 2 doesn't apply to cloud-hosted software

---

**Q10.** The CloudWatch metric filter pattern for CIS 4.3 (root account usage) is:
```
{ $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }
```
Why does it include `$.userIdentity.invokedBy NOT EXISTS`?

- A) To exclude API calls made by AWS services on behalf of root (service-initiated events aren't human usage)
- B) To filter out API calls that don't have an ARN
- C) To improve query performance by reducing the number of events scanned
- D) To exclude failed API calls from triggering the alarm

---
---

# ✅ Answer Key

*Only read this after attempting all 10 questions.*

---

**Q1 — Answer: B**

Security group configuration is on the customer side of the shared responsibility model. AWS provides the security group *capability* — configuring it correctly is your job. AWS does offer tools (Config, Security Hub) that can flag this misconfiguration, but detecting a problem is different from being responsible for creating it.

---

**Q2 — Answer: C**

FIDO2 hardware keys are phishing-resistant because they perform a cryptographic handshake that verifies the *origin URL* of the login page. A fake `signin.aws.amazon.com.evil.com` page cannot fool the key — it checks the domain and refuses. TOTP apps (B) generate valid codes regardless of which website you're on, making them vulnerable to real-time proxy phishing attacks.

---

**Q3 — Answers: B and C**

Root should only be used for tasks that *require* root — and there are very few. Enabling MFA on root itself (B) is one of them, because you can't configure root's MFA from an IAM user. Closing the AWS account (C) requires root.

Creating EC2 instances (A), creating IAM users (D), and checking billing (E) should all be done through a regular IAM user or role with appropriate permissions. Using root for routine work is a security anti-pattern regardless of how convenient it seems.

---

**Q4 — Answer: B**

This is a false positive — the bucket is *intentionally* public to serve a website. The correct response is to suppress the finding in Security Hub or Config with a documented justification (e.g., "Public S3 bucket for static website hosting — reviewed and accepted by security team on [date]"). Disabling the rule entirely (C) would suppress legitimate violations across all buckets, which is far worse.

---

**Q5 — Answer: B**

Config's configuration timeline records every change to a resource's configuration over time, including which IAM identity made the change and when. This is invaluable for incident investigation — you can pinpoint exactly when a security group was modified, or when block public access was disabled. A point-in-time scan only tells you the *current* state, not the history.

---

**Q6 — Answer: B**

The right prioritisation combines severity (CRITICAL first) with business context (production accounts have higher blast radius) and tactical efficiency (quick fixes improve your score and build momentum). Alphabetical order (A) and age-based order (C) have no correlation with actual risk. Escalating without attempting anything (D) wastes your 2 hours entirely.

---

**Q7 — Answer: B**

SCP explicit denies override everything in member accounts — including IAM allows. IAM policy evaluation happens *inside* the boundary set by the SCP. Since the SCP denies `cloudtrail:DeleteTrail`, no IAM policy in that account can permit it. The only account exempt from SCPs is the management account itself — which is one reason production workloads shouldn't run there.

---

**Q8 — Answer: B**

This is the most commonly misunderstood aspect of SCPs. An SCP "Allow" does not *grant* permissions — it defines what *can be granted* by IAM policies. Think of the SCP as an outer fence: even if the inner gate (IAM) is open, you can't go where the outer fence blocks you. Conversely, if an action isn't in the SCP's allow scope, no IAM policy can grant it to anyone in that account.

---

**Q9 — Answer: B**

The AWS SOC 2 report demonstrates that AWS's infrastructure, data centres, and platform meet SOC 2 standards — their half of the shared responsibility model. It says nothing about how *your* application handles data, how *your* team manages access, or how *your* code is secured. You need your own separate SOC 2 audit. AWS Artifact reports are inputs to your compliance programme, not a substitute for it.

---

**Q10 — Answer: A**

AWS services sometimes invoke API calls on behalf of root automatically (service-linked actions). The condition `$.userIdentity.invokedBy NOT EXISTS` filters these out, so the alarm only fires when an actual human (or attacker) is using root credentials interactively — not when an AWS service is performing a routine automated action. Without this condition, the alarm would generate false positives from normal AWS service operations.
