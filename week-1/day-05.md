# Day 05 — Compliance Operations: AWS Artifact & Evidence Collection

**Week 1: Foundations & Visibility** | 4 hours | Difficulty: Beginner

---

## 🎯 Objective

By the end of today you will understand how compliance frameworks (SOC 2, PCI DSS) divide responsibility between AWS and you, access AWS's own compliance reports via AWS Artifact, and build the foundation of a compliance evidence folder.

---

## 📖 Theory (2.5 hours)

### 1. Why Compliance Frameworks Matter Beyond Legal Obligation

SOC 2 and PCI DSS are often treated as boxes to tick for a contract or customer requirement. But they're also useful as security checklists — frameworks written by security professionals that represent collective wisdom about which controls matter most.

Even if your team isn't currently required to be SOC 2 certified, understanding the framework tells you what a well-run security program looks like. The controls aren't arbitrary — each one exists because its absence has caused real incidents.

---

### 2. SOC 2 — What It Actually Covers

SOC 2 (Service Organization Control 2) is an auditing standard developed by the AICPA. It evaluates a service organisation's controls against five Trust Services Criteria:

| Criterion | What It Covers |
|---|---|
| **Security** | Protection against unauthorised access — the mandatory criterion, always included |
| **Availability** | System is available for operation as agreed (uptime SLAs) |
| **Processing Integrity** | System processing is complete, valid, accurate, and timely |
| **Confidentiality** | Information designated as confidential is protected as committed |
| **Privacy** | Personal information is collected, used, retained, and disclosed appropriately |

**Type I vs. Type II:**
- **SOC 2 Type I** — A point-in-time snapshot: are the controls *designed* correctly? Faster to obtain (weeks), less assurance.
- **SOC 2 Type II** — Over a defined period (typically 6–12 months): are the controls *operating effectively*? More valuable to enterprise customers.

Most enterprise customers and procurement teams ask for Type II. The AWS controls that underpin your infrastructure are covered by AWS's own SOC 2 Type II report — your Type II covers your application layer.

---

### 3. PCI DSS 4.0 — Key Cloud Requirements

PCI DSS (Payment Card Industry Data Security Standard) applies to any organisation that stores, processes, or transmits payment card data. The 4.0 version (released 2022, mandatory from March 2025) has several cloud-specific additions:

| Requirement | What It Means for Cloud |
|---|---|
| Req 2 | Apply secure configurations — aligns directly with CSPM work from Days 2–3 |
| Req 7 | Restrict access based on business need — aligns with IAM least privilege (Week 2) |
| Req 10 | Log and monitor all access — aligns with CloudTrail and GuardDuty (Week 4) |
| Req 6.4.3 | All payment page scripts managed and authorised — new in 4.0 |
| Req 12.3.2 | Hardware and software inventoried annually — AWS Config helps here |

---

### 4. AWS Artifact — Your Compliance Document Portal

AWS Artifact is a self-service portal inside the AWS console that gives you on-demand access to AWS's own compliance reports and agreements. These documents demonstrate AWS's side of the shared responsibility model.

**What you can download:**
- AWS SOC 1, SOC 2 (Type I and II), SOC 3 reports
- PCI DSS Attestation of Compliance (AOC) and Responsibility Summary
- ISO 27001, 27017, 27018, 9001 certificates
- FedRAMP authorisation documentation
- HIPAA Business Associate Addendum (BAA)

**Why these matter for your compliance program:**
When a customer or auditor asks "is AWS compliant with X?", these are the documents that answer the question for AWS's half. You then separately demonstrate your controls for your half. Together, they form the complete compliance picture.

**What Artifact does NOT provide:**
A SOC 2 report for *your* application. That requires your own audit. Artifact covers AWS's infrastructure — your code, configuration, access controls, and processes are your responsibility to demonstrate.

---

### 5. Control Mapping — The Key Compliance Skill

Control mapping is the process of connecting a compliance requirement to the specific technical or administrative control that satisfies it. This is the core skill in compliance work.

**Example mapping for SOC 2 Security — Logical Access:**

| SOC 2 Requirement | AWS Control | Evidence |
|---|---|---|
| Access is restricted to authorised users | IAM policies with least privilege | IAM credential report, Access Analyzer findings |
| MFA required for privileged access | MFA enforcement for console users | Config rule: mfa-enabled-for-iam-console-access |
| Access is reviewed periodically | IAM Access Advisor | Quarterly access review screenshots |

Building this mapping table for your environment is how you prepare for an audit — you're not searching for evidence under pressure, you already know where everything is.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Artifact | https://docs.aws.amazon.com/artifact/latest/ug/what-is-aws-artifact.html |
| SOC 2 Trust Services Criteria | https://www.aicpa-cima.com/resources/download/2017-trust-services-criteria |
| PCI DSS v4.0 | https://www.pcisecuritystandards.org/document_library/ |
| AWS PCI DSS Compliance | https://aws.amazon.com/compliance/pci-dss-level-1-faqs/ |

---

## 🛠️ Lab (1 hour)

### Step 1 — Access AWS Artifact (15 min)

1. AWS Console → search → **AWS Artifact**
2. Left menu → **Reports**
3. Browse the available reports — you'll see SOC, PCI, ISO, and more
4. Click **AWS SOC 2 Type II Report** → read the description
5. To download: accept the NDA agreement → **Download**
   - You don't need to read the full report — note the audit period and auditor name
   - This document is what you'd provide to a customer asking about AWS's security posture

6. Find and access the **PCI DSS Attestation of Compliance (AOC)**
   - Note: this covers AWS's PCI certification, not yours
   - Also download the **PCI DSS Responsibility Summary** — this is the most useful document for understanding exactly which PCI requirements AWS handles vs. which are yours

---

### Step 2 — Build a Compliance Evidence Folder (30 min)

Create a structured evidence folder in your portfolio repository. This is the skeleton of a real compliance program.

Create the following folder structure in your Git portfolio:

```
compliance/
├── aws-artifact/
│   ├── aws-soc2-type2-[date].pdf       ← the report you just downloaded
│   └── aws-pci-responsibility-summary.pdf
└── control-mapping/
    └── soc2-security-controls.md       ← create this now
```

Create `compliance/control-mapping/soc2-security-controls.md` with this content, filling in what you've actually done so far:

```markdown
# SOC 2 Security Control Mapping
Last updated: [today's date]
Reviewer: [your name]

## CC6.1 — Logical and Physical Access Controls

| Control Requirement | Implementation | Evidence Location | Status |
|---|---|---|---|
| MFA required for privileged access | Root MFA + IAM user MFA enabled | Day 01 screenshots | ✅ Complete |
| No root access keys | Root access keys not created | Day 01 screenshots | ✅ Complete |
| IAM password policy enforced | 14-char min, complexity, expiry | Day 03 screenshots | ✅ Complete |

## CC6.3 — Access Removal

| Control Requirement | Implementation | Evidence Location | Status |
|---|---|---|---|
| Periodic access reviews | IAM Access Advisor (manual quarterly) | Pending | 🔄 Planned |

## CC7.1 — Vulnerability Management

| Control Requirement | Implementation | Evidence Location | Status |
|---|---|---|---|
| Continuous configuration monitoring | AWS Config + 5 managed rules | Day 02 screenshots | ✅ Complete |
| Compliance score tracked | Security Hub CIS Benchmark | Day 03 screenshots | ✅ Complete |
```

---

### Step 3 — Review the PCI Responsibility Summary (15 min)

The PCI DSS Responsibility Summary is a table that lists every PCI requirement and explicitly states whether AWS, you (the customer), or both are responsible for it.

1. Open the document you downloaded
2. Find Requirement 10 (Logging and Monitoring)
3. Note which logging controls are AWS's responsibility vs. yours
4. Add a brief note to your `soc2-security-controls.md` about one PCI requirement that surprised you

This exercise builds the habit of reading compliance documents critically — not just downloading them to satisfy an auditor.

---

## ✅ Checklist

- [ ] AWS Artifact accessed and explored
- [ ] AWS SOC 2 Type II report downloaded and saved to portfolio
- [ ] AWS PCI DSS Responsibility Summary downloaded
- [ ] `compliance/` folder structure created in portfolio repo
- [ ] `soc2-security-controls.md` created with at least the CC6.1 section filled in
- [ ] Screenshot: AWS Artifact reports page

**Portfolio commit:**
```bash
git add compliance/
git commit -m "Day 05: AWS Artifact accessed, SOC2 evidence folder created, control mapping started"
git push
```

---

## 📝 Quiz

→ [week-1/quiz/week-1-quiz.md](./quiz/week-1-quiz.md) — Question 10 covers today's content.

---

## 🧹 Cleanup

Nothing to delete today. The compliance folder you created is a permanent portfolio artifact.
