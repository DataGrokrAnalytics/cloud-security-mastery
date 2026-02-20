# Glossary

Key terms used throughout the program. If you encounter a term in a lesson
that isn't here, open a PR to add it.

---

## A

**Access Analyzer (IAM Access Analyzer)**
An AWS service that analyses resource policies to identify resources that are
accessible from outside your AWS account or organisation. Generates findings
for S3 buckets, IAM roles, KMS keys, Lambda functions, SQS queues, and more.

**Access Key**
A long-term credential consisting of an Access Key ID and a Secret Access Key,
used to authenticate programmatic AWS API calls. Should never be created for
the root account. Should be rotated regularly and replaced with IAM roles
wherever possible.

**ACL (Access Control List)**
A legacy AWS mechanism for controlling access to S3 buckets and objects.
Largely superseded by bucket policies and IAM policies. Should be disabled
in most modern AWS setups.

**ARN (Amazon Resource Name)**
A unique identifier for every AWS resource, in the format:
`arn:partition:service:region:account-id:resource`
Example: `arn:aws:s3:::my-bucket`

---

## C

**CIEM (Cloud Infrastructure Entitlement Management)**
The practice of managing and right-sizing permissions across cloud environments.
Focuses on identifying over-privileged identities, unused permissions, and
entitlement sprawl. AWS IAM Access Analyzer is a native CIEM tool.

**CIS (Center for Internet Security)**
A non-profit organisation that publishes security benchmarks — collections of
controls representing industry consensus on secure configuration. The CIS AWS
Foundations Benchmark is the most widely adopted standard for AWS account
security baseline.

**CloudTrail**
An AWS service that records every API call made in your account — who did what,
from where, and when. The foundation of all AWS audit logging and security
investigation. Should be enabled in all regions with log file validation.

**CMK (Customer Managed Key)**
A KMS encryption key that you create and control, as opposed to an AWS Managed
Key which AWS creates on your behalf. CMKs give you control over key rotation,
access policies, and deletion.

**CNAPP (Cloud-Native Application Protection Platform)**
Gartner's term for a unified security platform that combines CSPM, CWPP, CIEM,
and CDR into a single tool. AWS Security Hub with its native integrations
approximates a CNAPP at no additional cost.

**Compliance**
In a security context, the state of meeting the requirements of a defined
standard or regulation (SOC 2, PCI DSS, HIPAA, etc.). Compliance is a floor,
not a ceiling — a compliant environment is not necessarily a secure one.

**Config (AWS Config)**
An AWS service that continuously records the configuration state of your AWS
resources and evaluates them against rules. The primary CSPM tool in AWS.

**CSPM (Cloud Security Posture Management)**
The practice of continuously monitoring cloud resource configurations to detect
drift from security baselines. Focuses on misconfiguration rather than
behavioural threats. AWS Config is AWS's native CSPM service.

**CVE (Common Vulnerabilities and Exposures)**
A standardised identifier for publicly known security vulnerabilities.
Format: CVE-YEAR-NUMBER (e.g. CVE-2021-44228 for Log4Shell).
AWS Inspector uses CVE data to identify vulnerable software on EC2 instances
and in container images.

**CVSS (Common Vulnerability Scoring System)**
A standardised scoring system (0–10) for the severity of security
vulnerabilities. Used by AWS Inspector to prioritise findings:
- 9.0–10.0: Critical
- 7.0–8.9: High
- 4.0–6.9: Medium
- 0.1–3.9: Low

---

## D

**DLP (Data Loss Prevention)**
The practice of detecting and preventing sensitive data from leaving your
environment without authorisation. Amazon Macie is AWS's native DLP service,
using machine learning to identify PII, PHI, and credentials in S3.

---

## E

**EBS (Elastic Block Store)**
AWS's block storage service, used as the primary storage for EC2 instances.
Should always be encrypted — default EBS encryption can be enabled at the
account level to ensure all new volumes are encrypted automatically.

**ECR (Elastic Container Registry)**
AWS's managed Docker container image registry. Supports image scanning via
Amazon Inspector to detect known vulnerabilities in container images before
deployment.

**ECS (Elastic Container Service)**
AWS's managed container orchestration service. Can run containers on EC2
instances (EC2 launch type) or as serverless containers (Fargate launch type).

**EKS (Elastic Kubernetes Service)**
AWS's managed Kubernetes service. Introduces Kubernetes-specific security
concerns: pod security policies, RBAC, network policies, and secrets management.

---

## F

**FIDO2**
An open authentication standard that enables hardware security key
authentication. FIDO2 keys (e.g. YubiKey) are phishing-resistant because they
verify the origin URL of the login page before authenticating.

**Finding**
A security issue identified by a security tool (Config, Security Hub,
GuardDuty, etc.). Findings have a severity (CRITICAL/HIGH/MEDIUM/LOW),
a resource identifier, and remediation guidance.

---

## G

**GuardDuty**
An AWS threat detection service that uses machine learning and threat
intelligence to detect malicious activity. Analyses CloudTrail logs, VPC Flow
Logs, and DNS logs. Does not require agents or changes to your infrastructure.

---

## I

**IaC (Infrastructure as Code)**
The practice of defining and managing infrastructure through code files
(CloudFormation, Terraform, CDK) rather than manual console actions.
Enables version control, peer review, and automated security scanning of
infrastructure before deployment.

**IAM (Identity and Access Management)**
AWS's service for managing identities (users, roles, groups) and their
permissions. IAM is the access control layer for everything in AWS — every
API call is authenticated and authorised through IAM.

**IAM Role**
An IAM identity with a set of permissions that can be assumed by AWS services,
EC2 instances, Lambda functions, or other AWS accounts. Preferred over IAM
users for programmatic access because credentials are temporary and rotated
automatically.

**Inspector (Amazon Inspector)**
An AWS vulnerability management service that continuously scans EC2 instances,
Lambda functions, and ECR container images for known software vulnerabilities
and unintended network exposure.

---

## J

**JIT (Just-In-Time) Access**
A privileged access pattern where elevated permissions are granted only when
needed and automatically expire after a defined period (e.g. 1 hour). Reduces
the window of exposure from standing privileged access.

---

## K

**KMS (Key Management Service)**
AWS's managed encryption key service. Used to create, manage, and control the
encryption keys that protect your data. Supports automatic annual key rotation
for Customer Managed Keys.

---

## L

**Lateral Movement**
An attacker technique (MITRE ATT&CK TA0008) where an attacker who has
compromised one system uses it as a stepping stone to reach other systems.
Network segmentation with VPCs and security groups is the primary defence.

**Least Privilege**
The security principle of granting only the minimum permissions required to
perform a specific task — nothing more. The most important principle in IAM
design.

---

## M

**Macie (Amazon Macie)**
An AWS data security service that uses machine learning to automatically
discover, classify, and protect sensitive data in S3. Detects PII (SSNs,
credit card numbers, passport numbers), PHI (HIPAA data), and credentials.

**MFA (Multi-Factor Authentication)**
An authentication method requiring two or more verification factors. In AWS,
supported as TOTP apps (Google Authenticator), hardware security keys (FIDO2),
and SMS (not recommended for privileged accounts).

**MITRE ATT&CK**
A globally accessible knowledge base of adversary tactics and techniques based
on real-world observations. Used to understand attacker behaviour and map
security controls to specific threats. Cloud matrix available at
https://attack.mitre.org/matrices/enterprise/cloud/

---

## N

**NACL (Network Access Control List)**
A stateless network filter applied at the subnet level in a VPC. Unlike
security groups (stateful), NACLs require explicit rules for both inbound
and outbound traffic. Evaluated before security groups.

**NIST (National Institute of Standards and Technology)**
A US federal agency that publishes widely adopted security frameworks and
standards, including NIST 800-53 (security controls catalogue) and the NIST
Cybersecurity Framework (CSF).

---

## O

**OU (Organizational Unit)**
A container within AWS Organizations that groups AWS accounts. SCPs attached
to an OU apply to all accounts within it. Used to apply different security
policies to different environments (production vs. development).

---

## P

**PAW (Privileged Access Workstation)**
A dedicated, hardened device used exclusively for privileged administrative
tasks. Reduces the risk of credential theft by separating sensitive work from
general browsing and email.

**PCI DSS (Payment Card Industry Data Security Standard)**
A security standard that applies to any organisation that stores, processes,
or transmits payment card data. Maintained by the PCI Security Standards
Council. Current version: 4.0.

**PHI (Protected Health Information)**
Health information that identifies an individual, protected under HIPAA in the
United States. Amazon Macie can detect PHI in S3 buckets.

**PII (Personally Identifiable Information)**
Information that can be used to identify an individual — names, SSNs, email
addresses, phone numbers, etc. Amazon Macie detects PII in S3.

---

## R

**Resource Policy**
A policy attached directly to an AWS resource (S3 bucket, KMS key, SQS queue)
that specifies who can access it. Evaluated alongside identity-based IAM
policies.

---

## S

**SCP (Service Control Policy)**
A policy applied at the AWS Organizations level that defines the maximum
permissions available to accounts in an OU. SCPs do not grant permissions —
they define ceilings. Applied before IAM policies in the evaluation order.

**Secrets Manager (AWS Secrets Manager)**
An AWS service for storing, rotating, and accessing secrets (database
credentials, API keys, passwords). Eliminates the need to hardcode credentials
in application code or environment variables.

**Security Group**
A stateful virtual firewall applied to AWS resources (EC2, RDS, Lambda, etc.)
at the resource level. Allows traffic that matches an explicit allow rule;
denies everything else. Changes take effect immediately.

**Security Hub (AWS Security Hub)**
An AWS security aggregation service that centralises findings from Config,
GuardDuty, Inspector, Macie, Access Analyzer, and third-party tools. Scores
your environment against compliance frameworks (CIS, PCI DSS, FSBP).

**Session Manager (AWS Systems Manager Session Manager)**
A feature of AWS Systems Manager that provides secure, audited shell access
to EC2 instances without requiring SSH keys, open inbound ports, or a bastion
host. All sessions are logged to CloudTrail and optionally to S3.

**SOAR (Security Orchestration, Automation and Response)**
The practice of automating security response workflows — detecting an event,
enriching it with context, and taking remediation action without human
intervention. On AWS, typically built with EventBridge + Lambda.

**SOC 2 (Service Organization Control 2)**
An auditing standard developed by the AICPA that evaluates a service
organisation's controls against five Trust Services Criteria: Security,
Availability, Processing Integrity, Confidentiality, and Privacy.

**STRIDE**
A threat modelling framework developed by Microsoft. Stands for: Spoofing,
Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation
of Privilege. Used to systematically identify threats to a system.

---

## T

**TOTP (Time-based One-Time Password)**
An MFA mechanism that generates a new 6-digit code every 30 seconds based on
the current time and a shared secret. Used by apps like Google Authenticator.
Vulnerable to real-time phishing attacks — use FIDO2 keys for privileged accounts.

**Transit Gateway**
An AWS networking service that acts as a central hub for connecting multiple
VPCs and on-premises networks. Replaces complex VPC peering mesh topologies
with a hub-and-spoke architecture.

---

## V

**VPC (Virtual Private Cloud)**
An isolated virtual network within AWS where you launch your resources.
Contains subnets, route tables, security groups, NACLs, and internet/NAT
gateways. Network segmentation within a VPC is a primary defence against
lateral movement.

**VPC Flow Logs**
Logs that capture information about IP traffic going to and from network
interfaces in a VPC. Used for network monitoring, troubleshooting, and
security analysis. Can be sent to S3 or CloudWatch Logs.

---

## Z

**Zero Trust**
A security model based on the principle "never trust, always verify" — no
user, device, or network is implicitly trusted, regardless of whether they
are inside or outside the corporate network. In cloud, implemented through
IAM least privilege, MFA, JIT access, and continuous verification.
