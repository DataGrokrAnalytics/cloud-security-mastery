# Further Reading

Curated resources to go deeper on each week's topics. Everything listed here
is either free or has a free tier. No paywalled content.

---

## 📚 Books

**The Web Application Hacker's Handbook** — Stuttard & Pinto
Foundational for understanding how applications get attacked. Relevant context
for Week 3 (network and workload protection).
Free preview: https://www.wiley.com

**Hacking the Cloud** — community knowledge base
Cloud-specific attack techniques, explained from the attacker's perspective.
Useful for understanding what you're defending against.
https://hackingthe.cloud

**AWS Security Best Practices** — AWS Whitepaper (free)
AWS's own guidance on security architecture. Dense but authoritative.
https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/aws-security-best-practices.html

---

## 📊 Annual Reports (Read at Least One)

These reports shape how the industry thinks about threats each year.
Reading one annually keeps your threat model current.

**Verizon Data Breach Investigations Report (DBIR)**
The most cited breach analysis report. Cloud misconfiguration consistently
appears as a top cause.
https://www.verizon.com/business/resources/reports/dbir/

**IBM Cost of a Data Breach Report**
Focuses on financial impact. Useful for business context and justifying
security investment.
https://www.ibm.com/reports/data-breach

**Palo Alto Unit 42 Cloud Threat Report**
Cloud-specific threat intelligence. Covers the most common attack paths
against AWS, Azure, and GCP environments.
https://unit42.paloaltonetworks.com/cloud-threat-report/

**CrowdStrike Global Threat Report**
Broader threat landscape with cloud-specific sections. Good for understanding
threat actor groups targeting cloud infrastructure.
https://www.crowdstrike.com/global-threat-report/

---

## 🏗️ Week 1: Foundations & Visibility

**AWS Well-Architected Framework — Security Pillar**
The definitive AWS guidance on security architecture. Read the Security Pillar
before or during Week 1.
https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html

**AWS Well-Architected Labs**
Hands-on labs aligned to the Well-Architected Framework. The security labs
complement this program directly.
https://wellarchitectedlabs.com/security/

**CIS AWS Foundations Benchmark v1.4**
The actual benchmark document. Reading it in full gives you context for why
each control exists, not just what it checks.
https://www.cisecurity.org/benchmark/amazon_web_services

**AWS Config Rules Repository**
Community-maintained library of custom Config rules. Useful when managed rules
don't cover your specific requirements.
https://github.com/awslabs/aws-config-rules

---

## 🔐 Week 2: Zero Trust Identity

**AWS IAM Best Practices**
AWS's own guidance on IAM. Short, practical, worth reading in full.
https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

**IAM Policy Evaluation Logic**
The definitive explanation of how AWS evaluates permissions. Essential reading
before working with SCPs, resource policies, or session policies.
https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html

**Checkov Documentation**
The IaC security scanner used in Day 11. Documentation covers all supported
checks and how to write custom policies.
https://www.checkov.io/1.Welcome/What%20is%20Checkov.html

**AWS re:Invent — IAM Deep Dive (YouTube)**
Search "AWS re:Invent IAM deep dive" on YouTube — there are several excellent
sessions that explain IAM mechanics with real examples. Free.

**Permiso — Cloud Identity Threat Research**
Research into identity-based cloud attacks. Useful for understanding what
attackers actually do with compromised IAM credentials.
https://permiso.io/blog

---

## 🌐 Week 3: Network & Data Protection

**AWS VPC Best Practices**
AWS's guidance on VPC design. Covers subnet architecture, security groups,
NACLs, and Transit Gateway patterns.
https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html

**Amazon Macie User Guide**
Full documentation for Macie, including how to write custom data identifiers
for organisation-specific sensitive data patterns.
https://docs.aws.amazon.com/macie/latest/user/what-is-macie.html

**AWS Inspector — CVE Coverage**
Documentation on what Inspector scans and how it prioritises findings.
https://docs.aws.amazon.com/inspector/latest/user/findings-understanding.html

**Kubernetes Security — Pod Security Standards**
Relevant for Day 20 (EKS security). The official Kubernetes documentation
on pod security policies and their replacements.
https://kubernetes.io/docs/concepts/security/pod-security-standards/

**NIST 800-40 — Patch Management**
The NIST guidance on enterprise patch management. Relevant for Inspector
findings and vulnerability SLAs.
https://csrc.nist.gov/publications/detail/sp/800-40/rev-4/final

---

## 🔍 Week 4: Detection & Response

**MITRE ATT&CK Cloud Matrix**
The definitive reference for cloud attacker tactics and techniques. Essential
for threat modelling on Day 25.
https://attack.mitre.org/matrices/enterprise/cloud/

**MITRE D3FEND**
The defensive counterpart to ATT&CK — maps defensive techniques to the
attacks they mitigate.
https://d3fend.mitre.org/

**AWS Security Hub Controls Reference**
Full list of Security Hub controls with descriptions and remediation guidance.
https://docs.aws.amazon.com/securityhub/latest/userguide/standards-reference.html

**GuardDuty Finding Types**
Complete reference for every GuardDuty finding type, what it means, and
recommended response.
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-active.html

**NIST 800-61 — Incident Response**
The foundational incident response framework. Preparation → Detection →
Analysis → Containment → Recovery → Post-incident. Referenced throughout Week 4.
https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final

**OWASP Threat Modelling**
The OWASP guide to threat modelling, including STRIDE. Relevant for Day 25.
https://owasp.org/www-community/Threat_Modeling

---

## 🎓 Certification Preparation

**AWS Security Specialty (SCS-C02) Exam Guide**
The official exam guide — lists every domain and the topics it covers.
Read this before Day 28 to assess your readiness.
https://aws.amazon.com/certification/certified-security-specialty/

**AWS Skill Builder**
AWS's official learning platform. Has free exam prep content and practice
questions for the Security Specialty.
https://skillbuilder.aws/

**TutorialsDojo — AWS Security Specialty Practice Exams**
Widely regarded as the best third-party practice exams. Paid but affordable.
https://tutorialsdojo.com/courses/aws-certified-security-specialty-practice-exams/

**Adrian Cantrill — AWS Security Specialty Course**
Detailed video course covering all exam domains. Paid.
https://learn.cantrill.io/

---

## 🛠️ Tools Referenced in This Program

| Tool | What It Does | Link |
|---|---|---|
| AWS CLI v2 | Command-line access to AWS APIs | https://aws.amazon.com/cli/ |
| Checkov | IaC security scanner (Day 11) | https://www.checkov.io/ |
| ScoutSuite | Multi-cloud security auditing tool (Day 27) | https://github.com/nccgroup/ScoutSuite |
| draw.io | Free diagramming tool for architecture diagrams | https://app.diagrams.net |
| AWS Policy Simulator | Test IAM policies before applying them | https://policysim.aws.amazon.com/ |
