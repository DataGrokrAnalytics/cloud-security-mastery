# Week 3 Quiz — Network & Data Protection

Answer from memory first. The answer key is at the bottom — no peeking until you've tried all 10.

---

## Questions

**Q1.** Your application has three tiers: a load balancer, an application server, and a database. You want to ensure the database can only receive connections from the application server. Which AWS control achieves this most precisely?

- A) A NACL denying all traffic except from the application server's subnet
- B) A security group on the database allowing port 5432 only from the application server's security group ID
- C) A route table with no route to the internet on the database subnet
- D) An IAM policy preventing non-application users from connecting to the database

---

**Q2.** VPC Flow Logs capture metadata about network connections in your VPC. Which of the following is NOT captured by flow logs?

- A) Source and destination IP addresses
- B) The content of the HTTP request body
- C) Whether the connection was accepted or rejected
- D) Source and destination ports

---

**Q3.** A developer claims that enabling SSE-S3 (S3-managed keys) is sufficient for PCI DSS compliance. What is the most important limitation of SSE-S3 compared to SSE-KMS with a Customer Managed Key?

- A) SSE-S3 is slower and impacts performance
- B) SSE-S3 encryption keys are not logged in CloudTrail, so you have no audit trail of who decrypted what
- C) SSE-S3 is not supported for buckets with versioning enabled
- D) SSE-S3 cannot encrypt files larger than 5GB

---

**Q4.** You apply this bucket policy to an S3 bucket:
```json
{
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:*",
  "Condition": {"Bool": {"aws:SecureTransport": "false"}}
}
```
A developer runs `aws s3 cp file.txt s3://your-bucket/` using the AWS CLI. The CLI uses HTTPS by default. What happens?

- A) The upload is denied because the bucket policy denies all S3 actions
- B) The upload succeeds because the CLI uses HTTPS (`aws:SecureTransport` is `true`), so the Deny condition is not met
- C) The upload fails because `aws:SecureTransport` is always `false` for CLI operations
- D) The upload succeeds but the object is stored unencrypted

---

**Q5.** Amazon Macie runs a classification job on an S3 bucket and returns a HIGH severity finding for a CSV file. On inspection, the file contains test data with realistic-looking but entirely fabricated SSNs used for software testing. What is the correct response?

- A) Delete the file immediately — synthetic PII must be treated the same as real PII
- B) Suppress the finding with documentation explaining it's synthetic test data, reviewed and confirmed as not real PII
- C) Disable the SSN managed data identifier globally to prevent future false positives
- D) Ignore the finding — Macie generates too many false positives to act on

---

**Q6.** Amazon Inspector reports a CVSS 9.1 (Critical) CVE on an EC2 instance but the EPSS score is 0.003 (0.3% exploitation probability). A separate finding shows CVSS 7.4 (High) with EPSS 0.78 (78% exploitation probability). Which should you patch first?

- A) The Critical CVE first — always prioritise by CVSS score
- B) The High CVE first — the 78% exploitation probability means it's actively being exploited in the wild and poses the higher real-world risk
- C) Both simultaneously — severity and exploitation probability are equally weighted
- D) Neither — patch windows should be scheduled regardless of severity

---

**Q7.** You push a container image tagged `:latest` to an ECR repository with immutable tags enabled. You then push a different image with the same `:latest` tag. What happens?

- A) The second push succeeds and overwrites the first image
- B) The second push fails — immutable tags prevent overwriting an existing tag
- C) The second push succeeds but both images are stored and tagged `:latest-1` and `:latest-2`
- D) ECR prompts you to confirm overwriting the existing tag

---

**Q8.** A Lambda function needs to read from an S3 bucket and write results to a DynamoDB table. A colleague suggests attaching the AWS managed policy `AmazonS3FullAccess`. What is wrong with this approach?

- A) AWS managed policies cannot be attached to Lambda execution roles
- B) `AmazonS3FullAccess` grants access to all S3 buckets, including ones this function should never touch — violates least privilege
- C) The function needs `AmazonDynamoDBFullAccess` as well, not just S3 access
- D) Nothing — AWS managed policies are designed for Lambda functions

---

**Q9.** Without IRSA configured in an EKS cluster, what IAM permissions do pods have by default?

- A) No permissions — pods have no AWS access without explicit configuration
- B) The permissions of the worker node's EC2 instance profile — shared by all pods on that node
- C) A unique auto-generated role scoped to the pod's namespace
- D) Full AdministratorAccess — Kubernetes grants this to simplify initial setup

---

**Q10.** You want to ensure that even if an attacker gains access to the physical storage underlying your S3 bucket, your data cannot be read. Which combination of controls achieves this?

- A) Bucket versioning + access logging
- B) VPC endpoint for S3 + security group restrictions
- C) SSE-KMS with a Customer Managed Key + CloudTrail logging of key usage
- D) Block public access + IAM policy restrictions

---
---

# ✅ Answer Key

*Only read this after attempting all 10 questions.*

---

**Q1 — Answer: B**

A security group referencing the source security group ID (not the subnet CIDR) is the most precise control here. It means only resources attached to that specific security group can connect — not any resource in the subnet. If you add a new EC2 instance to the app subnet without the app security group, it won't be able to connect to the database. Route tables (C) prevent internet access but don't restrict within-VPC connectivity. IAM (D) controls API access, not network connections.

---

**Q2 — Answer: B**

Flow logs capture connection metadata — IP addresses, ports, protocols, bytes, action (ACCEPT/REJECT). They do not capture packet contents, HTTP headers, request bodies, or any application-layer data. This is by design — capturing packet contents at scale would be prohibitively expensive and raises privacy concerns. For application-layer visibility, you'd use AWS WAF logs or application-level logging.

---

**Q3 — Answer: B**

With SSE-S3, AWS manages the keys internally and the encryption/decryption operations are not visible in CloudTrail. You can't prove who accessed specific data, when, or from where. With SSE-KMS and a CMK, every `GenerateDataKey` and `Decrypt` call appears in CloudTrail with the requester's IAM identity, timestamp, and source IP. This audit trail is what PCI DSS Requirement 10 and SOC 2 CC7.2 are looking for — not just encryption, but evidence that access was monitored.

---

**Q4 — Answer: B**

The Deny condition is `"aws:SecureTransport": "false"` — meaning the Deny fires only when the connection is NOT using TLS. Since the AWS CLI uses HTTPS by default, `aws:SecureTransport` evaluates to `true`, the condition is not met, and the Deny statement does not apply. The upload proceeds normally. An HTTP request (if somehow forced) would be denied. This is a common pattern that's easy to misread — the `"false"` in the condition triggers the Deny, not the Allow.

---

**Q5 — Answer: B**

Suppress with documentation. Disabling the SSN managed identifier globally (C) would hide real SSN findings across your entire account. Deleting the file (A) might not be necessary if the test data serves a legitimate purpose and isn't real PII. Ignoring (D) leaves the finding in Active state — no audit trail of review. The correct approach is to confirm the data is not real, document that confirmation, and suppress the specific finding. This is the pattern across all AWS security tools: manage findings with documentation, not with blanket disabling.

---

**Q6 — Answer: B**

EPSS measures the probability that a vulnerability will be actively exploited in the next 30 days, based on real-world data. An EPSS of 0.78 means this vulnerability is being widely exploited or has active exploit code in circulation — the attacker tooling exists and is in use. An EPSS of 0.003 means almost no real-world exploitation despite the high theoretical severity. In practice, a High CVE being actively exploited is more dangerous than a Critical CVE with no known exploit. Inspector's combined risk score factors in both CVSS and EPSS precisely for this prioritisation.

---

**Q7 — Answer: B**

Immutable tags mean what they say: once a tag is written, it cannot be overwritten or deleted. The second push fails with an error. This is a security control that prevents tag hijacking — a common supply chain attack where an attacker gains push access to a registry and replaces a trusted image tag (like `latest` or `v1.2.3`) with a malicious one. With immutable tags, your deployed tags are guaranteed to refer to the exact image you originally pushed.

---

**Q8 — Answer: B**

`AmazonS3FullAccess` grants full access to all S3 buckets in your account — read, write, delete, change bucket policies, disable encryption. The function needs to read from one specific bucket. Attaching a full-access policy violates least privilege and means a code injection vulnerability in the function could allow an attacker to read or delete any bucket in your account. The correct approach is a custom policy scoped to `s3:GetObject` and `s3:ListBucket` on the specific bucket ARN only.

---

**Q9 — Answer: B**

Without IRSA, pods inherit the IAM permissions of the worker node's EC2 instance profile — whatever role was attached to the EC2 instance when it joined the cluster. This role typically includes permissions for ECR pull, CloudWatch Logs, and EBS volume management. Any pod on that node can make API calls to those services. In a misconfigured cluster, the node role might have much broader permissions, giving every pod in the cluster equivalent access. IRSA solves this by giving individual pods their own scoped roles.

---

**Q10 — Answer: C**

SSE-KMS with a CMK encrypts the data using a key you control — someone with physical access to the storage media cannot read the data without the key. CloudTrail logging of key usage gives you the audit trail showing who accessed data and when. Versioning (A) and access logging protect against accidental deletion and provide access records, but don't encrypt the data. VPC endpoints (B) control network access but don't protect the data at rest. Block public access + IAM (D) control who can access the bucket but don't encrypt the data contents.
