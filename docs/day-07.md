# Day 07 — Week 1 Review & Portfolio

**Week 1: Foundations & Visibility** | 4 hours | Difficulty: All levels

---

## 🎯 Objective

By the end of today you will have a complete, presentable Week 1 portfolio, a shared responsibility diagram you can explain to anyone, your CIS score above 80%, and all lab resources cleanly deleted — leaving a $0 bill and a solid foundation for Week 2.

---

## 📖 Theory (2 hours)

### 1. Supply Chain Risk — The Threat You Haven't Thought About Yet

Week 1 focused on your AWS account configuration. But your attack surface extends beyond resources you directly control. Supply chain risk covers the security of everything that flows into your environment:

**Third-party IAM access:** SaaS tools, CI/CD systems, and monitoring platforms often need IAM permissions to function. Each integration is a potential entry point. Common mistakes:
- Granting AdministratorAccess to a SaaS tool that only needs read access to S3
- Never reviewing or rotating external IAM credentials
- Not limiting which source IPs or AWS accounts can assume your cross-account roles

**Dependencies in your code:** npm packages, Python libraries, Docker base images — any of these can contain malicious code or known vulnerabilities. On Day 19 we'll cover container scanning; for now, understand that the dependency graph is part of your security boundary.

**What to do about it now:** Use IAM Access Analyzer (covered in Week 2) to find all external access to your AWS resources. For every third-party integration, ask: what is the minimum IAM permission this tool actually needs?

---

### 2. What a CIS Score Actually Measures — and What It Doesn't

By now your CIS score has improved from your Day 3 baseline. It's worth being clear about what that number means:

**What a high CIS score tells you:**
- Your account configuration matches industry-recognised security baselines
- Specific, well-defined misconfigurations have been addressed
- You have a documented, measurable security posture that can improve over time

**What a high CIS score does NOT tell you:**
- That your application code is secure
- That your IAM policies follow least privilege (CIS checks for presence of controls, not their quality)
- That you have detection and response capabilities
- That you're protected against zero-day exploits or sophisticated attackers

A CIS score is a floor, not a ceiling. It measures the basics. An organisation that scores 95% on CIS but has no GuardDuty, no CloudTrail, and no incident response plan is not secure — they just have a clean configuration.

Use the score for what it's good for: tracking improvement, demonstrating baseline hygiene to customers and auditors, and identifying quick wins.

---

### 3. Week 1 in Context — The Full Picture

Here's where Week 1 fits in the overall security program:

```
Week 1: Foundations & Visibility    ← You are here
  └── Can you SEE what's misconfigured? (Config, Security Hub)
  └── Can you PREVENT certain actions? (SCPs)
  └── Can you PROVE compliance? (Artifact, evidence folder)

Week 2: Zero Trust Identity
  └── Can you CONTROL who accesses what? (IAM, Access Analyzer)

Week 3: Network & Data Protection
  └── Can you PROTECT your data and network? (VPC, KMS, Macie)

Week 4: Detection & Response
  └── Can you DETECT and RESPOND to threats? (GuardDuty, SOAR)
```

Visibility (Week 1) enables everything else. You can't fix what you can't see, and you can't respond to threats you haven't detected.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Well-Architected Security Pillar | https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html |
| CIS AWS Foundations Benchmark | https://www.cisecurity.org/benchmark/amazon_web_services |
| AWS IAM Best Practices | https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html |

---

## 🛠️ Lab (1.5 hours)

### Step 1 — Create Your Shared Responsibility Diagram (30 min)

Create a visual diagram showing the shared responsibility model for your specific environment. Use any tool you prefer — draw.io (free at app.diagrams.net), Lucidchart, or even a hand-drawn diagram photographed.

Your diagram should show three columns:

```
┌─────────────────┬──────────────────────┬─────────────────────┐
│   AWS Manages   │    Both Manage       │   You Manage        │
├─────────────────┼──────────────────────┼─────────────────────┤
│ Physical infra  │ Patch mgmt (shared)  │ IAM policies        │
│ Hypervisor      │ Encryption (config)  │ S3 bucket policies  │
│ Network fabric  │                      │ Security groups     │
│ Global infra    │                      │ Application code    │
│ Managed service │                      │ Data classification │
│ availability    │                      │ Incident response   │
└─────────────────┴──────────────────────┴─────────────────────┘
```

Save as `portfolio/week-1/shared-responsibility-diagram.png`.

---

### Step 2 — Write Your Week 1 Executive Summary (30 min)

Create `portfolio/week-1/executive-summary.md`. This is a one-page summary written as if you were briefing a manager or team lead — no jargon, clear outcomes, concrete numbers.

Template:

```markdown
# Week 1 Executive Summary — Cloud Security Foundations

**Period:** [dates]
**Author:** [your name]

## What We Did
Brief 2–3 sentence overview of the week's work.

## Security Posture Improvement

| Metric | Before | After |
|---|---|---|
| CIS AWS Foundations Score | ~35% (estimated) | [your score]% |
| Config rules monitoring | 0 | 5 |
| Critical findings open | [number] | [number] |

## Controls Implemented

| Control | Day | Status |
|---|---|---|
| Root MFA enabled | Day 01 | ✅ Complete |
| AWS Budgets alert | Day 01 | ✅ Complete |
| IAM admin user (no root usage) | Day 01 | ✅ Complete |
| AWS Config (5 managed rules) | Day 02 | ✅ Complete |
| Security Hub + CIS Benchmark | Day 03 | ✅ Complete |
| IAM password policy (CIS 1.8) | Day 03 | ✅ Complete |
| S3 account public access block | Day 03 | ✅ Complete |
| AWS Organizations + SCP | Day 04 | ✅ Complete |
| Compliance evidence folder | Day 05 | ✅ Complete |
| KMS key rotation | Day 06 | ✅ Complete |

## Remaining Gaps
List 3–5 things you know are still missing and will be addressed in later weeks.
For example: CloudTrail (Day 22), GuardDuty (Day 23), CloudWatch alarms (Day 22).

## Next Week
One sentence on what Week 2 covers.
```

---

### Step 3 — Final CIS Score Check and Cleanup (30 min)

**Check your score:**
1. Security Hub → Summary → note your final Week 1 CIS score
2. Target: >80% — if you're below this, review the failing controls and see if any are quick fixes
3. Add the final score to your executive summary

**Resource cleanup:**
No major resources to delete this week — Config, Security Hub, and Organizations should stay running. Check:

1. AWS Cost Explorer → confirm $0 spend this week
2. EC2 → Instances → confirm no running instances you forgot about
3. S3 → confirm only the Config bucket exists (no test buckets left open)

---

## ✅ Week 1 Final Checklist

**Day-by-day verification:**
- [ ] Day 01: Root MFA active, IAM admin user created with MFA, $5 budget alert set
- [ ] Day 02: AWS Config enabled, 5 rules active and evaluated
- [ ] Day 03: Security Hub active, CIS + FSBP benchmarks enabled
- [ ] Day 04: AWS Organizations created, Deny-S3 SCP attached to Sandbox OU
- [ ] Day 05: AWS Artifact accessed, compliance evidence folder created
- [ ] Day 06: 3+ findings remediated, KMS rotation enabled, EBS encryption defaulted

**Portfolio artifacts:**
- [ ] `portfolio/week-1/shared-responsibility-diagram.png`
- [ ] `portfolio/week-1/executive-summary.md`
- [ ] `compliance/control-mapping/soc2-security-controls.md`
- [ ] Screenshots folder with evidence from each day

**Final metrics:**
- [ ] CIS score: ____% (target: >80%)
- [ ] AWS spend this week: $____ (target: $0)

**Final portfolio commit:**
```bash
git add .
git commit -m "Week 01 complete: CIS score X%, all 7 days documented, portfolio ready"
git push
```

---

## 📝 Quiz

→ [week-1/quiz/week-1-quiz.md](./quiz/week-1-quiz.md) — Complete all 10 questions and check your answers before starting Week 2.

---

## 🔜 Week 2 Preview

Next week shifts from *visibility* to *identity*. You'll go deep on IAM policy mechanics, learn Zero Trust architecture, and build the access control foundations that underpin every security control you'll implement in Weeks 3 and 4.

The key mindset shift for Week 2: in cloud security, **identity is the new perimeter**. Firewalls and VPCs matter, but a compromised IAM role with excessive permissions can bypass all of them. Understanding IAM deeply is the single highest-leverage skill in cloud security.

→ Start Week 2: [week-2/day-08.md](../week-2/day-08.md)
