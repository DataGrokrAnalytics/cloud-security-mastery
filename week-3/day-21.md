# Day 21 — Week 3 Review & Protection Portfolio

**Week 3: Network & Data Protection** | 4 hours | Difficulty: All levels

---

## 🎯 Objective

By the end of today you will have a complete Week 3 architecture diagram, a network and data protection portfolio, your lab infrastructure cleanly deleted, and a clear understanding of what Week 4's detection and response capabilities will be defending.

---

## 📖 Theory (2 hours)

### 1. Defence in Depth — What You've Built

Over the last 7 days you've implemented four overlapping defensive layers. This is defence in depth: no single control is assumed to be perfect, and multiple independent controls must all fail before an attacker reaches sensitive data.

```
Layer 1 — Network                    (Day 15)
  VPC segmentation: internet → public → private → database
  Security groups: each tier accepts only specific ports from specific tiers
  VPC Flow Logs: network audit trail feeding into GuardDuty (Week 4)

Layer 2 — Data at rest               (Days 16–17)
  KMS CMK encryption on S3
  TLS-enforced bucket policies
  Macie continuous PII scanning

Layer 3 — Vulnerability surface      (Days 18–19)
  Inspector continuous CVE scanning (EC2, Lambda, containers)
  ECR image scanning on push
  Immutable image tags

Layer 4 — Workload identity          (Day 20)
  Least-privilege Lambda execution roles
  EKS IRSA pattern (pods get scoped roles, not node permissions)
```

An attacker who bypasses Layer 1 (network) still faces Layer 2 (encrypted data). An attacker who finds a vulnerability (Layer 3) still faces the identity controls from Week 2. Each layer is independent, and each adds cost to the attacker.

---

### 2. What Week 3 Didn't Cover — and Why

A few topics are intentionally deferred:

**AWS WAF and Shield:** Web application firewall and DDoS protection. Valuable for internet-facing applications but adds cost and complexity beyond Free Tier. Worth knowing exists; not covered in depth here.

**AWS Network Firewall:** Stateful, managed firewall for VPC traffic inspection. Powerful but costs ~$65/month base — not Free Tier compatible.

**PrivateLink:** Connects AWS services to your VPC without traffic leaving the AWS backbone. Important for production environments processing sensitive data. Covered in the further reading.

These are real production controls worth learning after this program. They're excluded here not because they're unimportant, but because the foundations in Weeks 1–3 are prerequisites for using them correctly.

---

### 3. What Remains Unprotected Without Week 4

You now have strong preventative controls: identity, network, encryption, and vulnerability management. But you have limited visibility into what's actually happening in your environment right now.

If an attacker is actively working through your environment today, you wouldn't know:
- Which IAM credentials are being used from an unusual IP
- Whether any EC2 instance is communicating with a known malicious domain
- Whether someone is quietly exfiltrating data from your S3 buckets
- Whether a Lambda function is behaving in an anomalous way

Week 4 addresses this: CloudTrail analysis, GuardDuty threat detection, Security Hub CNAPP, and automated response. Detection turns your preventative controls into an active defence.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Security Reference Architecture | https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html |
| AWS Network Firewall | https://aws.amazon.com/network-firewall/ |
| AWS PrivateLink | https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html |

---

## 🛠️ Lab (1.5 hours)

### Step 1 — Draw Your Week 3 Architecture Diagram (45 min)

Create a diagram showing everything you've built across Weeks 1–3. Use draw.io (free at app.diagrams.net) or any diagramming tool.

Your diagram should include:

**Network layer:**
- VPC with CIDR block
- Three subnets (public/private/database) with CIDR blocks
- Security groups with the ports they allow between tiers
- Internet Gateway, route tables

**Data layer:**
- S3 bucket with KMS encryption and TLS-enforced policy
- KMS CMK with rotation enabled
- Macie scanning the bucket

**Compute layer:**
- EC2 instance (Inspector scanning target) in private subnet
- Lambda function with least-privilege execution role
- ECR repository with image scanning

**Identity layer (from Week 2):**
- IAM roles (EC2-SSM-Role, LambdaS3ReadRole, JIT-ReadOnly-1Hour)
- Access Analyzer monitoring

Save as `portfolio/week-3/architecture-diagram.png`.

---

### Step 2 — Write Your Week 3 Executive Summary (20 min)

Create `portfolio/week-3/executive-summary.md`:

```markdown
# Week 3 Executive Summary — Network & Data Protection

**Period:** [dates]
**Author:** [your name]

## What We Did
[2–3 sentences]

## Controls Implemented

| Control | Day | Standard Satisfied |
|---|---|---|
| 3-tier VPC with network segmentation | Day 15 | CIS 5.x, NIST AC-4 |
| VPC Flow Logs | Day 15 | CIS 3.9, SOC2 CC7.2 |
| S3 encryption with KMS CMK | Day 16 | CIS 2.1.1, PCI DSS 3.5 |
| TLS enforcement via bucket policy | Day 16 | CIS 2.1.2, PCI DSS 4.2 |
| Amazon Macie PII scanning | Day 17 | SOC2 P5, GDPR Art 32 |
| Amazon Inspector CVE scanning | Day 18 | CIS 6.x, NIST SI-2 |
| ECR image scanning + immutable tags | Day 19 | NIST SI-2 |
| Lambda least-privilege execution role | Day 20 | CIS 1.x, SOC2 CC6.1 |

## Security Metrics

| Metric | Value |
|---|---|
| Network tiers segmented | 3 (public / private / database) |
| S3 buckets without encryption | 0 |
| Critical CVEs unpatched >15 days | [count] |
| Inspector coverage | [%] |
| Macie PII findings reviewed | ✅ |

## Remaining Gaps
[CloudTrail deep analysis (Day 22), GuardDuty (Day 23), automated response (Day 26)]

## Next Week
Week 4 adds detection and response on top of these preventative controls.
```

---

### Step 3 — Full Cleanup (25 min)

Run the cleanup script, then verify:

```bash
# Terminate the Inspector scan target from Day 18
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=inspector-scan-target" \
            "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

[ "$INSTANCE_ID" != "None" ] && \
  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" && \
  echo "✅ Terminated: $INSTANCE_ID"

# Delete the Lambda function
aws lambda delete-function --function-name lab-s3-reader && \
  echo "✅ Lambda deleted"

# Delete the LambdaS3ReadRole
aws iam delete-role-policy --role-name LambdaS3ReadRole --policy-name LambdaS3ReadPolicy
aws iam delete-role --role-name LambdaS3ReadRole && \
  echo "✅ Lambda role deleted"

# Delete the ECR image (keep the repo)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
aws ecr batch-delete-image \
  --repository-name lab-secure-app \
  --image-ids imageTag=v1.0.0 2>/dev/null || true

# Delete the VPC stack — CloudFormation handles all VPC resources
aws cloudformation delete-stack --stack-name lab-vpc-week3 && \
  echo "✅ VPC stack deletion initiated (takes ~5 min)"

echo ""
echo "Keep running:"
echo "  - S3 encrypted bucket (lab-encrypted-data-*)"
echo "  - KMS key (lab-s3-encryption-key) — referenced in Week 4"
echo "  - Macie (continuous bucket monitoring)"
echo "  - Inspector (continuous scanning)"
echo "  - All Week 1 resources (Config, Security Hub, CloudTrail)"
echo "  - All Week 2 IAM resources"
```

**Verify spend:**
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost.Amount" \
  --output text
```

---

## ✅ Week 3 Final Checklist

**Day-by-day verification:**
- [ ] Day 15: 3-tier VPC deployed with flow logs active
- [ ] Day 16: S3 bucket with KMS CMK and TLS-enforced bucket policy
- [ ] Day 17: Macie enabled, PII classification job completed
- [ ] Day 18: Inspector enabled, CVE findings reviewed and prioritised
- [ ] Day 19: ECR with immutable tags, image scan reviewed
- [ ] Day 20: Least-privilege Lambda role and function deployed

**Portfolio artifacts:**
- [ ] `portfolio/week-3/architecture-diagram.png`
- [ ] `portfolio/week-3/executive-summary.md`
- [ ] `week-3/labs/vpc-3tier.yaml` (CloudFormation template)
- [ ] Screenshots from each day

**Final metrics:**
- [ ] S3 buckets without encryption: 0
- [ ] Active Access Analyzer findings: 0
- [ ] AWS spend this week: $____ (target: <$1)

**Final portfolio commit:**
```bash
git add .
git commit -m "Week 03 complete: Network & Data Protection — VPC, KMS, Macie, Inspector, containers, serverless"
git push
```

---

## 📝 Quiz

→ [week-3/quiz/week-3-quiz.md](./quiz/week-3-quiz.md) — Complete all 10 questions before starting Week 4.

---

## 🔜 Week 4 Preview

Week 4 activates the detection layer. Everything you've built — CloudTrail from Day 6, VPC Flow Logs from Day 15, Inspector findings from Day 18 — feeds into GuardDuty and Security Hub to give you a real-time threat picture.

You'll also build your first automated response: a Lambda function that detects a public S3 bucket and automatically makes it private, alerting the team — from detection to remediation in under 30 seconds.

The key mindset shift for Week 4: **assume breach**. Your preventative controls are good, but not perfect. Detection and response is what limits the damage when something gets through.

→ Start Week 4: [week-4/day-22.md](../week-4/day-22.md)
