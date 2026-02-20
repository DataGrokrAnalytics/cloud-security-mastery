# Day 25 — STRIDE Threat Modelling

**Week 4: Detection & Operations** | 4 hours | Difficulty: Advanced

---

## 🎯 Objective

By the end of today you will understand the STRIDE threat modelling methodology, have applied it to your lab VPC architecture to identify the threats your controls are designed to address, and have a threat model document you can use as a template for real workloads.

---

## 📖 Theory (2.5 hours)

### 1. Why Threat Modelling

Security controls without threat modelling are answers to unasked questions. You might implement perfect encryption but have no protection against an insider threat. You might have excellent network segmentation but leave an identity path wide open.

Threat modelling is the structured practice of asking "what can go wrong?" before it goes wrong — for a specific system, from the perspective of an attacker. It has four questions:

1. **What are we building?** — Diagram the system: components, data flows, trust boundaries
2. **What can go wrong?** — Enumerate threats using a framework (STRIDE)
3. **What are we doing about it?** — Map threats to controls
4. **Did we do a good enough job?** — Validate coverage and residual risk

Done well, threat modelling tells you not just what controls to implement, but *why* each control exists and what attacker behaviour it defeats.

---

### 2. STRIDE — The Threat Framework

STRIDE is a mnemonic for six categories of threat, developed by Microsoft and widely used in the industry. Each category maps to a violated security property:

| Threat | Violated Property | Cloud Example |
|---|---|---|
| **S**poofing | Authentication | Attacker uses stolen IAM credentials to impersonate a legitimate user |
| **T**ampering | Integrity | Attacker modifies data in S3 or DynamoDB without detection |
| **R**epudiation | Non-repudiation | Attacker disables CloudTrail to erase evidence of their actions |
| **I**nformation Disclosure | Confidentiality | Public S3 bucket exposes customer PII |
| **D**enial of Service | Availability | Attacker floods an API Gateway endpoint or deploys many expensive Lambda functions |
| **E**levation of Privilege | Authorisation | Attacker exploits IAM misconfiguration to assume an admin role |

For each component in your architecture, you ask: which of these six threats applies? What is the severity if it materialises? What control mitigates it?

---

### 3. Data Flow Diagrams — The Threat Modelling Map

Before applying STRIDE, you need a data flow diagram (DFD) that shows:

**External entities** — things outside your system boundary that interact with it (users, external services, other AWS accounts)

**Processes** — components that transform or process data (Lambda functions, EC2 instances, ECS tasks)

**Data stores** — where data is persisted (S3, RDS, DynamoDB, Secrets Manager)

**Data flows** — how data moves between entities, processes, and stores (arrows with labels)

**Trust boundaries** — lines that separate areas of different trust levels (VPC subnets, AWS account boundaries, internet boundary)

Every trust boundary crossing is where STRIDE threats concentrate — it's the data flows that cross boundaries that are most at risk.

---

### 4. Threat Prioritisation — DREAD Scoring

After identifying threats, prioritise them using DREAD scoring (each dimension scored 1–3):

- **D**amage — how bad is the impact if this threat materialises?
- **R**eproducibility — how easy is it for an attacker to reproduce?
- **E**xploitability — how much skill/effort does exploitation require?
- **A**ffected users — how many users are impacted?
- **D**iscoverability — how easy is it for an attacker to find this vulnerability?

Total DREAD score (5–15): 12–15 = Critical, 8–11 = High, 5–7 = Medium.

DREAD is subjective, which is its weakness — different people score the same threat differently. But the process of scoring forces explicit discussion about risk that "this is bad" doesn't.

---

### 5. Threat Modelling as a Team Practice

The most valuable aspect of threat modelling is not the document it produces — it's the conversation it forces. A developer who has walked through the STRIDE threats on their own feature will write different code than one who hasn't.

At minimum, threat modelling should happen:
- When designing a new service or significant feature
- When adding a new data flow across a trust boundary
- After a security incident, to understand what the model missed
- Annually for your most critical services

The output should be a living document, updated as the architecture changes.

---

## 🔗 References

| Resource | URL |
|---|---|
| OWASP Threat Modelling | https://owasp.org/www-community/Threat_Modeling |
| Microsoft STRIDE | https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats |
| OWASP Threat Dragon (free tool) | https://owasp.org/www-project-threat-dragon/ |
| NIST 800-154 Data-Centric Threat Modelling | https://csrc.nist.gov/publications/detail/sp/800-154/draft |

---

## 🛠️ Lab (1 hour)

### Step 1 — Build Your DFD (20 min)

Draw a data flow diagram for the architecture you've built in this program. Use draw.io, OWASP Threat Dragon (free web app at https://www.threatdragon.com/), or even pen and paper photographed.

Your DFD should include these elements:

```
[Internet User] ──HTTPS──▶ [Load Balancer (Public SG)]
                                    │
                              Port 8080
                                    │
                                    ▼
                         [App Server (Private SG)]
                           │              │
                    Port 5432         Secrets Manager
                           │         API (Port 443)
                           ▼
                    [Database (DB SG)]

Trust boundaries:
  ── Internet / Public subnet
  ── Public subnet / Private subnet
  ── Private subnet / Database subnet
  ── AWS account / External services
```

Identify all data flows that cross trust boundaries — these are where your STRIDE analysis focuses.

---

### Step 2 — Apply STRIDE to Each Trust Boundary (25 min)

For each trust boundary crossing, complete this table. Populate it with your lab architecture:

Create `portfolio/week-4/threat-model.md`:

```markdown
# STRIDE Threat Model — Lab VPC Architecture
**Date:** [today]
**Author:** [your name]
**Architecture:** 3-tier VPC with S3, Lambda, KMS, GuardDuty, CloudTrail

---

## Data Flow Diagram
[attach or describe your DFD]

---

## STRIDE Analysis

### Trust Boundary: Internet → Public Subnet (Load Balancer)

| Threat | Description | Severity | Control | Residual Risk |
|---|---|---|---|---|
| Spoofing | Attacker forges requests as legitimate user | HIGH | TLS + WAF | LOW — HTTPS enforced by bucket policy |
| Tampering | Attacker modifies HTTP request in transit | HIGH | TLS in transit | LOW |
| Repudiation | User denies actions | MEDIUM | CloudTrail + ALB access logs | LOW |
| Info Disclosure | Sensitive data in HTTP response | HIGH | TLS, no sensitive data in LB response | LOW |
| Denial of Service | HTTP flood | MEDIUM | AWS Shield Standard (default) | MEDIUM — no WAF deployed |
| Elevation of Privilege | Exploit LB vulnerability to reach private subnet | HIGH | Security groups, patching | LOW |

### Trust Boundary: Public Subnet → Private Subnet (App Server)

| Threat | Description | Severity | Control | Residual Risk |
|---|---|---|---|---|
| Spoofing | Compromised LB makes requests as app | MEDIUM | Security group source restriction | LOW |
| Tampering | Attacker modifies app data in transit | LOW | Internal TLS (optional) | MEDIUM |
| Repudiation | App actions not logged | MEDIUM | CloudTrail + App logs | LOW |
| Info Disclosure | App exposes internal data to LB | LOW | Least-privilege responses | LOW |
| Denial of Service | App overwhelmed by LB traffic | MEDIUM | Auto-scaling | LOW |
| Elevation of Privilege | App compromise allows DB access | HIGH | DB SG restricts to app SG only | LOW |

### Trust Boundary: Private Subnet → S3 (via AWS API)

| Threat | Description | Severity | Control | Residual Risk |
|---|---|---|---|---|
| Spoofing | Stolen IAM role used to access S3 | CRITICAL | GuardDuty, CloudTrail alerts | MEDIUM |
| Tampering | Unauthorised modification of S3 objects | HIGH | Versioning, IAM least-privilege | LOW |
| Repudiation | S3 access not logged | HIGH | S3 server access logging, CloudTrail data events | LOW |
| Info Disclosure | Public bucket exposure | CRITICAL | Block public access + Macie | LOW |
| Denial of Service | S3 API throttling | LOW | S3 is highly available | LOW |
| Elevation of Privilege | Lambda role misuse to access other buckets | HIGH | Least-privilege role scoped to one bucket | LOW |

---

## Summary Risk Register

| Threat | DREAD Score | Control Gap | Owner |
|---|---|---|---|
| DoS on public endpoint | 8 | WAF not deployed | Week 4 gap |
| Stolen IAM credentials | 11 | GuardDuty detection only | Ongoing monitoring |
| Internal TLS app-to-app | 6 | No internal TLS | Accepted risk |

---

## Controls Coverage Map

| STRIDE Category | Primary Control | Secondary Control |
|---|---|---|
| Spoofing | MFA, JIT roles (Week 2) | GuardDuty UnauthorizedAccess findings |
| Tampering | S3 versioning, KMS encryption (Week 3) | CloudTrail integrity validation |
| Repudiation | CloudTrail multi-region (Week 1) | Log file validation |
| Info Disclosure | Macie, S3 block public access (Week 3) | Access Analyzer |
| Denial of Service | AWS Shield Standard | (WAF — gap identified) |
| Elevation of Privilege | IAM least privilege, SCPs (Week 2) | Config rules, Security Hub |
```

---

### Step 3 — Identify Your Top 3 Residual Risks (15 min)

From your completed threat model, identify the three threats with the highest residual risk — threats that your current controls do not fully address. Write them as actionable items:

```markdown
## Top 3 Residual Risks

1. **Stolen IAM credentials used from unexpected location**
   - Current state: GuardDuty detects post-compromise; no prevention
   - Recommended control: IP-based condition on sensitive IAM roles
   - Priority: HIGH

2. **No WAF on public endpoints**
   - Current state: Application layer attacks (SQLi, XSS) undetected
   - Recommended control: AWS WAF with managed rule groups
   - Priority: MEDIUM

3. **No internal TLS between app tier and database**
   - Current state: DB traffic within VPC is unencrypted
   - Recommended control: RDS with SSL enforcement
   - Priority: MEDIUM
```

---

## ✅ Checklist

- [ ] Data flow diagram created (draw.io, Threat Dragon, or hand-drawn)
- [ ] STRIDE applied to at least 3 trust boundary crossings
- [ ] Controls coverage map completed
- [ ] Top 3 residual risks identified with recommended actions
- [ ] `portfolio/week-4/threat-model.md` created
- [ ] Screenshot: DFD diagram

**Portfolio commit:**
```bash
git add portfolio/week-4/threat-model.md screenshots/day-25-*.png
git commit -m "Day 25: STRIDE threat model — 3 trust boundaries analysed, residual risks identified"
git push
```

---

## 📝 Quiz

→ [week-4/quiz/week-4-quiz.md](./quiz/week-4-quiz.md) — Questions 6 & 7.

---

## 🧹 Cleanup

No AWS resources created today. Nothing to delete.
