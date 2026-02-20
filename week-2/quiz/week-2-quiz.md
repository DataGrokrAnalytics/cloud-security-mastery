# Week 2 Quiz — Zero Trust Identity

Answer from memory first. The answer key is at the bottom — no peeking until you've tried all 10.

---

## Questions

**Q1.** You need to grant a Lambda function access to a specific DynamoDB table. Which is the correct approach?

- A) Create an IAM user with access keys and store them in the Lambda environment variables
- B) Attach an IAM role to the Lambda function with a policy scoped to that specific table
- C) Use the root account credentials stored in Secrets Manager
- D) Grant the Lambda function AdministratorAccess to ensure it can always do what it needs

---

**Q2.** You are reviewing a custom IAM policy and see `"Action": "s3:*"` with `"Resource": "*"`. What is the correct response?

- A) This is fine — S3 is a low-risk service
- B) Flag it for review — this grants full S3 access including deleting buckets across all resources
- C) This is acceptable if the identity is a developer account
- D) Approve it — AWS managed policies use this pattern routinely

---

**Q3.** IAM Access Analyzer finds that an S3 bucket in your account is accessible from the internet. The bucket hosts your company's public documentation website. What should you do?

- A) Immediately make the bucket private — public buckets are never acceptable
- B) Archive the finding with a note explaining it's an intentional public documentation bucket, reviewed on this date
- C) Ignore the finding — Access Analyzer has too many false positives
- D) Delete the bucket and rebuild it without public access

---

**Q4.** An IAM Access Analyzer "unused access" finding shows that a role hasn't used its S3 write permissions in 120 days. What is the most appropriate response?

- A) Delete the role immediately
- B) Ignore it — roles accumulate permissions and that's normal
- C) Investigate whether S3 write is still needed; if not, remove it from the role's policy
- D) Add a Deny policy to block S3 write as a compensating control

---

**Q5.** A developer finds database credentials hardcoded in a Python file that was committed to a public GitHub repository 2 hours ago. What are the correct immediate steps? Select all that apply.

- A) Delete the GitHub commit
- B) Rotate the credentials immediately — assume they are compromised
- C) Make the repository private
- D) Check CloudTrail and database access logs for any unauthorised use in the last 2 hours
- E) Send a company-wide email explaining what happened

---

**Q6.** AWS Secrets Manager's automatic rotation feature rotates a database password every 30 days. Your application is using the secret. What happens to the application when the secret rotates?

- A) The application breaks — it needs to be redeployed with the new password
- B) Nothing — the application retrieves the secret from Secrets Manager at runtime, so it always gets the current value
- C) The application gets a temporary outage of up to 5 minutes during rotation
- D) The application must be updated to use the new secret ARN

---

**Q7.** Checkov scans a CloudFormation template and returns this finding:
```
Check: CKV_AWS_53: "Ensure S3 bucket has block public access enabled"
FAILED for resource: AWS::S3::Bucket.AppBucket
```
Which CloudFormation property fixes this finding?

- A) `AccessControl: Private`
- B) Add a bucket policy denying public access
- C) Add a `PublicAccessBlockConfiguration` block with all four settings set to `true`
- D) Set `VersioningConfiguration: Status: Enabled`

---

**Q8.** A developer needs SSH access to debug a production EC2 instance. Your security policy requires all admin access to be auditable and requires no inbound ports to be open. What is the correct solution?

- A) Open port 22 temporarily, connect, then close it after debugging
- B) Use AWS Systems Manager Session Manager — no SSH key or open port required, session logged to CloudTrail
- C) Create a bastion host in a public subnet with port 22 open to the developer's IP
- D) Ask the developer to use the EC2 serial console

---

**Q9.** You create a JIT role with `"aws:MultiFactorAuthPresent": "true"` in the trust policy. A developer assumes the role using long-term access keys (no MFA session). What happens?

- A) The assumption succeeds — MFA is only checked for console logins, not API calls
- B) The assumption fails — the condition requires MFA to be present in the session
- C) The assumption succeeds but the session is flagged in Security Hub
- D) AWS prompts the developer to enter an MFA code before proceeding

---

**Q10.** Which of the following best describes the Confused Deputy problem in IAM cross-account access?

- A) An IAM role that has too many permissions and can access resources it shouldn't
- B) A scenario where a trusted third-party service is tricked into accessing your resources on behalf of a different, unauthorised party
- C) An IAM user who assumes a role in the wrong account by mistake
- D) A cross-account trust that grants access to the wrong AWS service

---
---

# ✅ Answer Key

*Only read this after attempting all 10 questions.*

---

**Q1 — Answer: B**

IAM roles attached to Lambda functions are the correct pattern. The role's credentials are temporary, automatically rotated by AWS, and never stored anywhere accessible. Storing access keys in environment variables (A) creates a secret management problem — keys can be leaked via logs or if the function is misconfigured. AdministratorAccess (D) violates least privilege. Root credentials (C) should never be used programmatically.

---

**Q2 — Answer: B**

`s3:*` on `*` grants every S3 action — including `s3:DeleteBucket`, `s3:DeleteObject`, `s3:PutBucketPolicy` — on every bucket in every account reachable by this identity. This is massively over-privileged for almost any real use case. Even if a developer account is lower risk than production, building bad habits in dev leads to bad habits in prod. Flag it, identify the specific actions actually needed, and replace with those.

---

**Q3 — Answer: B**

Archive with documentation. This is a genuine false positive — the bucket is intentionally public for a valid business reason. "Archive" in Access Analyzer means "I've reviewed this, it's intentional, here's why." It removes the finding from your active queue without deleting the evidence that you reviewed it. This is the correct audit trail. Ignoring (C) leaves it in Active state, which means no evidence of review.

---

**Q4 — Answer: C**

Investigate first, then remove if not needed. Deleting the role (A) immediately could break something if there's a legitimate use you're not aware of. Ignoring it (B) defeats the purpose of CIEM. Adding a compensating Deny (D) is extra complexity without addressing the root cause — the permission should simply not exist if it's not needed. The goal is least privilege: only permissions that are actively needed should exist.

---

**Q5 — Answers: B, C, and D**

The credentials must be rotated immediately (B) — this is non-negotiable. Assume they are compromised from the moment of first exposure. Making the repo private (C) prevents further exposure but doesn't help anyone who already found the keys. Checking logs (D) tells you if they were already used and helps scope the incident.

Deleting the commit (A) is not reliable — GitHub history, forks, and caches mean the credentials may already be in other places. Rotation is more important than deletion. A company-wide email (E) is premature during the immediate response phase and may cause panic before you understand the impact.

---

**Q6 — Answer: B**

This is the key advantage of Secrets Manager over environment variables. When your application code retrieves the secret by calling `secretsmanager:GetSecretValue` at runtime (not at startup or deployment), it always gets the current version. Rotation updates the secret value; the next time your application requests it, it receives the new value automatically. The application doesn't need redeployment, doesn't have a stored copy of the old value, and doesn't need to know a rotation happened.

---

**Q7 — Answer: C**

The `PublicAccessBlockConfiguration` property with all four settings (`BlockPublicAcls`, `BlockPublicPolicy`, `IgnorePublicAcls`, `RestrictPublicBuckets`) set to `true` is the correct fix for CKV_AWS_53. `AccessControl: Private` (A) is a legacy ACL setting that Checkov doesn't check for this control. A bucket policy (B) can deny public access but is a different mechanism. Versioning (D) is unrelated to public access.

---

**Q8 — Answer: B**

Session Manager is exactly the right tool here. It requires no open inbound ports — the SSM Agent on the instance maintains an outbound connection to SSM. Sessions are authenticated via IAM (which can require MFA), and every session start/end is recorded in CloudTrail. The temporary open port (A) creates an exposure window and isn't auditable. A bastion host (C) is better than nothing but still requires an open port and a bastion to manage. The EC2 serial console (D) is for emergency access when the OS is unresponsive, not normal debugging.

---

**Q9 — Answer: B**

The assumption fails. `aws:MultiFactorAuthPresent` evaluates to `false` when the request comes from long-term credentials without an MFA session. The trust policy condition requires it to be `true`, so the condition is not met and the assume-role call is denied. This is the intended behaviour — the JIT role is only accessible to sessions with verified MFA. Note: using `Bool` vs `BoolIfExists` matters here; `Bool` evaluates strictly, while `BoolIfExists` only checks if the key is present.

---

**Q10 — Answer: B**

The Confused Deputy problem is a privilege escalation via a trusted intermediary. The "deputy" is the trusted third-party service — it holds a role your account trusts. An attacker (the "confused" party) tricks that service into using your role on their behalf, even though you didn't intend to grant them access. The ExternalId condition prevents this by requiring the trusted service to present a secret value that only the legitimate principal knows — making impersonation by other customers of the same service impossible.
