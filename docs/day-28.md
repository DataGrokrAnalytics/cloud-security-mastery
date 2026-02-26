# Day 28 — Executive Portfolio & Program Completion

**Week 4: Detection & Operations** | 4 hours | Difficulty: All levels

---

## 🎯 Objective

Today is the capstone. You will assemble a complete, professional 28-day portfolio that demonstrates production-grade cloud security skills, write an executive summary that translates everything you've built into business language, and do a final account cleanup that leaves your AWS environment in a clean, known-good state.

---

## 📖 Theory (1.5 hours)

### 1. What You've Actually Built

Over 28 days you've implemented a complete cloud security programme from scratch. It's worth stepping back and seeing it as an integrated system rather than a list of individual tasks:

```
GOVERNANCE LAYER (Week 1)
  AWS Organizations + SCPs          → Policy enforcement before IAM
  AWS Config + Security Hub         → Continuous misconfiguration detection
  CIS Benchmark compliance          → Industry-standard posture measurement
  CloudTrail                        → Audit evidence for every action

IDENTITY LAYER (Week 2)
  Least-privilege IAM policies      → Minimal blast radius per identity
  IAM Access Analyzer               → Continuous external access monitoring
  JIT access with MFA               → No standing privileged credentials
  Secrets Manager                   → Zero hardcoded secrets
  Session Manager                   → No SSH keys or open inbound ports

PROTECTION LAYER (Week 3)
  3-tier VPC                        → Network segmentation stops lateral movement
  KMS CMK encryption                → Data unreadable without the key
  Macie PII scanning                → Sensitive data found wherever it lands
  Inspector CVE scanning            → Known vulnerabilities surfaced continuously
  ECR image scanning                → Container vulnerabilities caught before deploy

DETECTION LAYER (Week 4)
  CIS CloudWatch Alarms             → Real-time alerts on critical API events
  GuardDuty                         → ML-powered threat detection
  Security Hub CNAPP                → Unified risk dashboard across all sources
  SOAR pipeline                     → Detection to remediation in <30 seconds
  Threat model                      → Attack paths understood and mitigated
```

Each layer supports the others. Detection without governance means you detect problems you have no policy to prevent. Governance without detection means your policies are never tested against real attacker behaviour. This is the complete picture.

---

### 2. Telling the Story to a Hiring Manager or CISO

Technical depth matters, but the ability to translate it into business language is what differentiates senior security engineers from junior ones. When presenting this portfolio, lead with outcomes, not tools:

**Don't say:** "I enabled AWS Config with 5 managed rules and Security Hub with the CIS AWS Foundations Benchmark."

**Do say:** "I implemented continuous misconfiguration scanning that raised our CIS compliance score from 35% to 85% — meaning 50% more of our infrastructure now meets industry security standards, reducing the attack surface for configuration-based breaches which account for 80% of cloud incidents."

Every technical control has a business story:
- GuardDuty → "Reduced our mean time to detect credential compromise from days to minutes"
- SOAR pipeline → "Automated response to the most common misconfiguration type — response time from hours to under 30 seconds"
- JIT access → "Eliminated standing privileged credentials that could be used in a lateral movement attack"

Practice articulating these for your portfolio presentation.

---

### 3. What Comes Next

This program covers the foundations of AWS cloud security. The logical next steps:

**Certification:** AWS Security Specialty (SCS-C02) validates everything covered here. The exam tests the same services, same concepts, same decision frameworks. With 28 days of hands-on practice, you're well-positioned to pass. Estimated additional study: 2–4 weeks of practice exams.

**Depth:** Each week's topics is a career specialisation. CIEM, CSPM, container security, serverless security — any of these can go much deeper. The further reading file (`resources/further-reading.md`) has the resources for each.

**Breadth:** Multi-cloud. Azure Defender for Cloud maps to Security Hub. Azure Sentinel maps to CloudTrail + CloudWatch. GCP Security Command Center maps to Config + GuardDuty. The concepts transfer; the implementations differ.

**Practice:** The best way to deepen the skills is to use them on a real project — a personal project, an open-source contribution, or a home lab running a realistic workload.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Security Specialty Exam Guide | https://aws.amazon.com/certification/certified-security-specialty/ |
| AWS Skill Builder | https://skillbuilder.aws/ |
| TutorialsDojo Practice Exams | https://tutorialsdojo.com/aws-certified-security-specialty/ |
| AWS Security Reference Architecture | https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html |

---

## 🛠️ Lab (2.5 hours)

### Step 1 — Final CIS Score and Security Metrics (20 min)

Capture your final security posture numbers before cleanup:

```bash
# Final CIS score is in Security Hub — check the console
# Capture the number for your executive summary
echo "Record from Security Hub → Summary:"
echo "  CIS AWS Foundations Score: ____%"
echo "  AWS FSBP Score: ____%"
echo "  Overall Security Score: ____%"

# Count active findings
aws securityhub get-findings \
  --filters '{"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}],
              "WorkflowStatus":[{"Value":"NEW","Comparison":"EQUALS"}]}' \
  --query "length(Findings)" \
  --output text

# Count critical/high
aws securityhub get-findings \
  --filters '{"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}],
              "WorkflowStatus":[{"Value":"NEW","Comparison":"EQUALS"}],
              "SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"},
                               {"Value":"HIGH","Comparison":"EQUALS"}]}' \
  --query "length(Findings)" \
  --output text
```

---

### Step 2 — Write the Executive Summary (45 min)

Create `portfolio/executive-summary-28day.md` — this is the top-level document for your portfolio:

```markdown
# 28-Day Cloud Security Mastery — Executive Summary

**Programme:** Cloud Security Mastery Program
**Duration:** [start date] — [end date]  
**Author:** [your name]
**Portfolio:** https://github.com/[your-username]/cloud-security-mastery

---

## Programme Overview

A structured 28-day programme implementing enterprise-grade AWS cloud security
from scratch on a single AWS Free Tier account, covering governance, identity,
network and data protection, and detection and response.

**Investment:** 4 hours/day × 28 days = 112 hours  
**Cost:** $0 (AWS Free Tier)

---

## Security Posture Transformation

| Metric | Day 1 | Day 28 | Improvement |
|---|---|---|---|
| CIS AWS Foundations Score | ~35% | [your score]% | +[delta]% |
| Config rules monitoring | 0 | 5+ | — |
| CloudWatch security alarms | 0 | 11 | — |
| S3 buckets without encryption | [count] | 0 | 100% |
| IAM users without MFA | [count] | 0 | 100% |
| Hardcoded secrets in code | Unknown | 0 (Secrets Manager) | 100% |
| Mean time to detect (public S3) | Hours/days | <5 min (GuardDuty) | >90% |
| Mean time to respond (public S3) | Manual | <30 sec (SOAR) | >99% |

---

## Controls Implemented by Layer

### Governance (Week 1)
- AWS Config with 5 managed rules — continuous misconfiguration detection
- Security Hub with CIS v1.4 and FSBP — unified compliance scoring
- AWS Organizations with SCP — policy enforcement above IAM
- CloudTrail multi-region with log validation — tamper-evident audit trail
- AWS Artifact — SOC 2 and PCI DSS compliance evidence

### Identity (Week 2)
- 5 custom least-privilege IAM policies replacing AWS managed policies
- IAM Access Analyzer — continuous external access monitoring
- Secrets Manager — zero hardcoded credentials
- Checkov IaC scanning — misconfigurations caught before deployment
- Session Manager — zero open inbound ports for admin access
- JIT roles with 1-hour TTL and MFA enforcement — no standing privileges

### Network & Data Protection (Week 3)
- 3-tier VPC — public/private/database segmentation with VPC Flow Logs
- S3 encrypted with KMS CMK + TLS enforcement — data unreadable without key
- Amazon Macie — PII detection across S3
- Amazon Inspector — continuous CVE scanning (EC2, Lambda, containers)
- ECR with immutable tags — container image integrity
- Lambda least-privilege execution roles — minimal workload blast radius

### Detection & Response (Week 4)
- 11 CIS Section 4 CloudWatch alarms — real-time alerts on critical events
- Amazon GuardDuty — ML-powered threat detection across CloudTrail/Flow Logs/DNS
- Security Hub CNAPP with 5 integrations — unified risk dashboard
- STRIDE threat model — attack paths documented and mitigated
- EventBridge + Lambda SOAR — automatic S3 remediation in <30 seconds
- ScoutSuite assessment — independent external security review

---

## Portfolio Artefacts

| Artefact | Location | Description |
|---|---|---|
| Shared responsibility diagram | portfolio/week-1/ | Visual boundary map |
| Week 1 executive summary | portfolio/week-1/ | Foundations outcomes |
| IAM audit report | portfolio/week-2/ | Full IAM posture assessment |
| Architecture diagram | portfolio/week-3/ | Complete 3-tier + security overlay |
| GuardDuty response playbook | portfolio/week-4/ | Finding-by-finding response guide |
| STRIDE threat model | portfolio/week-4/ | Attack path analysis |
| Risk prioritisation matrix | portfolio/week-4/ | Business-contextualised findings |
| SOAR Lambda code | week-4/labs/ | Auto-remediation pipeline |
| CIS alarm script | week-4/labs/ | 11 CIS Section 4 alarms |
| VPC CloudFormation template | week-3/labs/ | IaC for 3-tier VPC |
| Checkov scan results | week-2/labs/ | IaC security baseline |

---

## Residual Risk and Gaps

The following items were identified but not fully addressed within the programme scope:

| Gap | Risk | Recommended Control | Priority |
|---|---|---|---|
| No AWS WAF | Application-layer attacks undetected | Enable WAF with managed rules | Medium |
| GuardDuty ML baseline not yet established | Anomaly detection limited for 2 weeks | Monitor for first 2 weeks | Low |
| KMS key costs $1/month | Minor ongoing cost | Acceptable | Low |

---

## Next Steps

- [ ] AWS Security Specialty (SCS-C02) certification exam
- [ ] WAF implementation for internet-facing workloads
- [ ] Multi-account setup with AWS Control Tower
- [ ] Expand SOAR coverage to GuardDuty credential findings
```

---

### Step 3 — Final Cleanup (45 min)

Run the complete final cleanup:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== Final 28-Day Cleanup ==="

# SOAR resources
echo "[1] Removing SOAR resources..."
aws events remove-targets --rule SecurityHub-S3-PublicAccess-Remediation \
  --ids SoarLambda 2>/dev/null || true
aws events delete-rule --name SecurityHub-S3-PublicAccess-Remediation 2>/dev/null || true
aws lambda delete-function --function-name soar-s3-remediation 2>/dev/null || true
aws iam delete-role-policy --role-name SOARRemediationRole \
  --policy-name SOARRemediationPolicy 2>/dev/null || true
aws iam delete-role --role-name SOARRemediationRole 2>/dev/null || true
echo "  ✅ SOAR resources removed"

# KMS key (schedule deletion — 7 day wait required)
echo "[2] Scheduling KMS key deletion (7-day window)..."
KEY_ID=$(aws kms describe-key --key-id alias/lab-s3-encryption-key \
  --query "KeyMetadata.KeyId" --output text 2>/dev/null || echo "not-found")
if [[ "$KEY_ID" != "not-found" ]]; then
  aws kms schedule-key-deletion --key-id "$KEY_ID" --pending-window-in-days 7
  echo "  ✅ KMS key scheduled for deletion in 7 days"
else
  echo "  ℹ️  KMS key not found"
fi

# S3 encrypted bucket
echo "[3] Emptying and deleting S3 bucket..."
BUCKET="lab-encrypted-data-${ACCOUNT_ID}"
aws s3 rm "s3://${BUCKET}" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "$BUCKET" 2>/dev/null || true
echo "  ✅ Bucket deleted"

# JIT role from Week 2
echo "[4] Removing JIT role..."
aws iam delete-role --role-name JIT-ReadOnly-1Hour 2>/dev/null || true
echo "  ✅ JIT role removed"

# Custom IAM policies from Week 2
echo "[5] Removing Week 2 IAM policies..."
for policy in S3ReadOnly-AppBucket EC2ReadOnly DenyNonEUWest1Region \
              SecretsReadRequireMFA DeveloperPolicy-NoIAM; do
  POLICY_ARN=$(aws iam list-policies --scope Local \
    --query "Policies[?PolicyName=='${policy}'].Arn" \
    --output text 2>/dev/null)
  if [[ -n "$POLICY_ARN" ]]; then
    aws iam delete-policy --policy-arn "$POLICY_ARN" 2>/dev/null || true
    echo "  ✅ Deleted: $policy"
  fi
done

# ECR repository
echo "[6] Deleting ECR repository..."
aws ecr delete-repository --repository-name lab-secure-app \
  --force 2>/dev/null || true
echo "  ✅ ECR repository deleted"

echo ""
echo "=== Keep running permanently ==="
echo "  ✅ AWS Config"
echo "  ✅ Security Hub (CIS + FSBP)"
echo "  ✅ CloudTrail"
echo "  ✅ GuardDuty"
echo "  ✅ Amazon Macie"
echo "  ✅ Amazon Inspector"
echo "  ✅ IAM Access Analyzer"
echo "  ✅ CIS CloudWatch Alarms (11 alarms)"
echo "  ✅ AWS Organizations + SCP"
echo "  ✅ EC2-SSM-Role"
echo ""
echo "=== Final cost check ==="
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost.Amount" \
  --output text 2>/dev/null || echo "Check https://console.aws.amazon.com/cost-management/home"
```

---

### Step 4 — Final GitHub Commit (20 min)

```bash
cd ~/cloud-security-mastery   # or your local path

# Add everything
git add .

# Final commit
git commit -m "Week 04 complete: 28-day programme finished — detection, SOAR, threat model, executive portfolio"

git push

# Tag the release
git tag -a v1.0.0 -m "28-Day Cloud Security Mastery Programme — complete"
git push origin v1.0.0
```

Update your `README.md` with a completion badge and final summary. Your repo is now a public portfolio demonstrating:
- 28 days of documented, reproducible cloud security work
- Infrastructure as Code (CloudFormation templates)
- Automation code (Bash scripts, Python Lambda)
- Portfolio documents (executive summaries, audit reports, threat model)
- A quiz suite with 40 questions and detailed answer keys

---

## ✅ Programme Final Checklist

**Week-by-week completion:**
- [ ] Week 1: CIS score >80%, CloudTrail, Config, Security Hub, Organizations
- [ ] Week 2: IAM audit, Access Analyzer, Secrets Manager, Session Manager, JIT
- [ ] Week 3: VPC, KMS, Macie, Inspector, ECR, Lambda roles
- [ ] Week 4: CIS alarms, GuardDuty, Security Hub CNAPP, SOAR, threat model, ScoutSuite

**Portfolio documents:**
- [ ] `portfolio/week-1/executive-summary.md`
- [ ] `portfolio/week-2/iam-audit-report.md`
- [ ] `portfolio/week-3/architecture-diagram.png`
- [ ] `portfolio/week-4/guardduty-response-playbook.md`
- [ ] `portfolio/week-4/threat-model.md`
- [ ] `portfolio/week-4/risk-prioritisation-matrix.md`
- [ ] `portfolio/executive-summary-28day.md`

**Code artefacts:**
- [ ] `week-1/labs/day-06-cloudtrail-alarm.sh`
- [ ] `week-2/labs/vpc-insecure.yaml` and `vpc-secure.yaml`
- [ ] `week-3/labs/vpc-3tier.yaml`
- [ ] `week-4/labs/cis-cloudwatch-alarms.sh`
- [ ] `week-4/labs/soar_remediation.py`

**Final numbers to record:**
- [ ] CIS score Day 1: ~35%  →  Day 28: ____%
- [ ] Total findings remediated: ____
- [ ] Controls implemented: 30+
- [ ] AWS spend total programme: $____

---

## 🏆 Programme Complete

You've built a cloud security programme that most organisations don't have. The controls implemented here are the same ones that protect real production environments at scale.

What makes this portfolio valuable isn't just the list of services enabled — it's the documented decisions: why each control exists, what attacker behaviour it defeats, how you prioritised, and what you'd do differently. That reasoning is what separates a practitioner from someone who followed a checklist.

**Certification:** → [AWS Security Specialty exam guide](https://aws.amazon.com/certification/certified-security-specialty/)  
**Continue learning:** → [resources/further-reading.md](../resources/further-reading.md)
