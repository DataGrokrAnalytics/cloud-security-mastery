# ☁️ Cloud Security Mastery Program

A 28-day, hands-on cloud security curriculum built for **mixed teams** — from developers
with no security background to DevOps engineers formalising their security knowledge.

**Cost:** $0 (AWS Free Tier) | **Time:** ~4 hours/day | **Target:** AWS Security Specialty (SCS-C02)

---

## 🎯 Who This Is For

| Background | What You'll Get |
|---|---|
| Developer (no security exp.) | Understand what you're responsible for securing and why it matters |
| DevOps / SRE | Formalise your security knowledge, learn detection and response |
| Security generalist | AWS-specific depth: services, APIs, automation, compliance |

No prior AWS security experience required. Basic AWS console familiarity (EC2, S3, IAM) is helpful but not mandatory.

---

## 📐 Program Structure

| Week | Theme | Days | Key Services |
|---|---|---|---|
| 1 | Foundations & Visibility | 1–7 | Config, Security Hub, Organizations, Artifact |
| 2 | Zero Trust Identity | 8–14 | IAM, Access Analyzer, Secrets Manager, Session Manager |
| 3 | Network & Data Protection | 15–21 | VPC, KMS, Macie, Inspector, ECR, EKS |
| 4 | Detection & Response | 22–28 | CloudTrail, GuardDuty, CNAPP, STRIDE, Lambda SOAR |

---

## 📁 Repo Structure

```
cloud-security-mastery/
├── README.md                  ← You are here
├── PREREQUISITES.md           ← Start here before Day 1
├── week-1/
│   ├── day-01.md              ← Daily lesson: theory + lab + checklist
│   ├── labs/
│   │   └── day-01-iam-hardening.sh   ← Reusable lab script
│   └── quiz/
│       └── week-1-quiz.md            ← Quiz + answer key
├── week-2/ ...
├── week-3/ ...
└── week-4/ ...
```

---

## 🗓️ Daily Lesson Format

Every `day-XX.md` follows this consistent structure:

```
🎯 OBJECTIVE     — What you'll be able to do by end of day
📖 THEORY        — Core concept, explained with real examples (2.5h)
🔗 REFERENCES    — Official docs + industry frameworks
🛠️  LAB          — Step-by-step AWS implementation (1h)
✅ CHECKLIST     — Measurable deliverables to verify you're done
📝 QUIZ          — Link to this week's quiz
```

---

## ⚠️ A Note on Accuracy

Statistics in this curriculum are drawn from named, publicly available reports
(Verizon DBIR, IBM Cost of a Data Breach, Palo Alto Unit 42). Where a claim
could not be verified against a primary source, it has been removed.
If you find an inaccuracy, please open a PR — see CONTRIBUTING.md.

---

## 🚀 Start Here

1. Read [PREREQUISITES.md](./PREREQUISITES.md)
2. Open [week-1/day-01.md](./week-1/day-01.md)

---

## 💡 Recommended Daily Rhythm

```
08:00–10:30   Theory reading + notes        (2.5h)
10:30–11:30   Hands-on AWS lab              (1.0h)
11:30–12:00   Document your work + commit   (0.5h)
```

Every Sunday: run the week's cleanup script, verify $0 spend in AWS Cost Explorer.
