# Day 18 — Amazon Inspector: Vulnerability Management

**Week 3: Network & Data Protection** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will have Amazon Inspector continuously scanning your EC2 instances and container images for known vulnerabilities, understand CVE scoring and remediation prioritisation, and have a vulnerability management process you can document for auditors.

---

## 📖 Theory (2.5 hours)

### 1. The Vulnerability Management Lifecycle

Vulnerability management is the continuous process of identifying, prioritising, and remediating known software vulnerabilities. "Known" is the key word — Inspector finds vulnerabilities that have a published CVE, meaning the vulnerability is publicly documented and has a known fix.

The lifecycle has four stages:

**Discover:** Inspector continuously scans running EC2 instances, Lambda functions, and ECR container images. It doesn't require agents — it uses the SSM Agent (already installed from Day 12) to read installed package lists.

**Prioritise:** Not all vulnerabilities are equal. Inspector scores each finding using CVSS (0–10) and also factors in whether a public exploit exists. A CVSS 7.5 vulnerability with a known exploit in the wild is more urgent than a CVSS 9.0 with no known exploit.

**Remediate:** The fix is almost always "update the package." Inspector provides the specific package version that fixes each CVE, the command to run it, and the affected instances. No ambiguity.

**Verify:** After patching, Inspector re-evaluates the finding. If the fix is confirmed, the finding closes automatically.

---

### 2. CVSS Scoring — Reading the Numbers

CVSS (Common Vulnerability Scoring System) rates vulnerabilities from 0 to 10:

| Score Range | Severity | Typical SLA |
|---|---|---|
| 9.0 – 10.0 | Critical | Patch within 15 days |
| 7.0 – 8.9 | High | Patch within 30 days |
| 4.0 – 6.9 | Medium | Patch within 90 days |
| 0.1 – 3.9 | Low | Patch within 180 days or at next cycle |

These SLAs come from NIST 800-40 and are widely adopted as an industry baseline. Your organisation might tighten them — many security teams target 7 days for Critical in production.

**Inspector adds a layer on top of CVSS: Exploit Prediction Scoring System (EPSS).** EPSS estimates the probability that a given CVE will be exploited in the wild within the next 30 days, based on characteristics of the vulnerability and real-world data. A Critical CVE with EPSS 0.02 (2% exploitation probability) is lower priority than a High CVE with EPSS 0.85 (85% probability).

Inspector's risk score combines CVSS + EPSS + network reachability, giving you a single prioritised list rather than hundreds of equally-weighted CVE numbers.

---

### 3. What Inspector Scans

**EC2 instances:** Scans the list of installed OS packages against the NVD (National Vulnerability Database) and vendor security advisories. Supports Amazon Linux, Ubuntu, Debian, RHEL, CentOS, Windows Server. Requires the SSM Agent.

**ECR container images:** Scans images when pushed and continuously re-evaluates them as new CVEs are published. An image that passed yesterday's scan might fail today if a new vulnerability is disclosed against one of its packages.

**Lambda functions:** Scans the function's deployment package and Lambda layers for vulnerable library versions.

---

### 4. The Cost of Not Patching

When discussing vulnerability management priorities with non-security stakeholders, the conversation often stalls on patching effort vs. business disruption. A useful framing:

- **Patch during scheduled maintenance:** planned, tested, 2-hour window
- **Patch in response to active exploitation:** emergency change, 3am call, potential customer impact
- **Don't patch and get breached:** incident response, forensics, breach notification, regulatory fines, reputational damage

The cost of the third option is always higher than the first. Inspector's findings are the evidence you need to make that conversation quantifiable — "we have 3 Critical CVEs on production instances, EPSS scores above 0.6, SLA is 15 days."

---

## 🔗 References

| Resource | URL |
|---|---|
| Amazon Inspector User Guide | https://docs.aws.amazon.com/inspector/latest/user/getting_started_tutorial.html |
| Inspector Finding Types | https://docs.aws.amazon.com/inspector/latest/user/findings-understanding.html |
| CVSS Calculator | https://www.first.org/cvss/calculator/3.1 |
| NIST 800-40 Patch Management | https://csrc.nist.gov/publications/detail/sp/800-40/rev-4/final |

---

## 🛠️ Lab (1 hour)

### Step 1 — Enable Amazon Inspector (5 min)

1. AWS Console → **Amazon Inspector** → **Get started** → **Enable Inspector**
2. On the accounts page, confirm your account is listed → **Enable**
3. Inspector immediately begins scanning:
   - EC2 instances (if any are running)
   - ECR repositories (if any exist)
   - Lambda functions (if any exist)

Inspector uses the SSM Agent installed on Day 12. If no instances are running, findings will appear once you launch one.

---

### Step 2 — Launch a Scan Target Instance (15 min)

Launch a deliberately unpatched Amazon Linux instance to give Inspector something to find:

```bash
# Get the latest Amazon Linux 2 AMI (older than 2023 — more likely to have findings)
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" \
            "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)

echo "Using AMI: $AMI_ID"

# Get the private subnet ID from your Day 15 VPC
PRIVATE_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=lab-private-subnet" \
  --query "Subnets[0].SubnetId" --output text)

# Get the private security group ID
PRIVATE_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=lab-private-sg" \
  --query "SecurityGroups[0].GroupId" --output text)

# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --subnet-id "$PRIVATE_SUBNET_ID" \
  --security-group-ids "$PRIVATE_SG_ID" \
  --iam-instance-profile Name=EC2-SSM-Role \
  --no-associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=inspector-scan-target}]' \
  --query "Instances[0].InstanceId" \
  --output text)

echo "✅ Instance launched: $INSTANCE_ID"
echo "   Waiting for Inspector to discover and scan (10–20 minutes)..."
```

---

### Step 3 — Review Inspector Findings (25 min)

After 10–20 minutes, Inspector will have initial findings:

1. Inspector Console → **Findings** tab
2. Sort by **Inspector score** (highest first)
3. Filter by **Resource type: EC2 instance**
4. Click into your top 3 findings and for each, note:
   - CVE ID
   - CVSS score and severity
   - EPSS score (exploitation probability)
   - Affected package and version
   - Fixed version (what to update to)
   - Remediation command

**Build your remediation tracking table:**
```
| CVE ID | Severity | CVSS | EPSS | Package | Fix Available | SLA (days) |
|---|---|---|---|---|---|---|
| CVE-XXXX-XXXXX | HIGH | 7.8 | 0.12 | openssl-1.0.x | Yes - 1.1.x | 30 |
```

5. Inspector → **Dashboard** → note:
   - Total findings count
   - Critical and High count
   - Coverage percentage (% of resources scanned)

---

### Step 4 — Review ECR Scanning (15 min)

Inspector also scans ECR images. Even if you don't have container images yet, configure the integration:

1. Inspector → left menu → **ECR repositories**
2. If no repositories exist, go to ECR → **Create repository**
   - Name: `lab-test-repo`
   - Image scanning: **Enable scan on push**
3. Back in Inspector → confirm ECR scanning is active

Container image scanning becomes more relevant on Days 19–20. For now, confirm it's configured.

---

## ✅ Checklist

- [ ] Amazon Inspector enabled
- [ ] EC2 instance launched in private subnet for scan target
- [ ] Inspector findings visible (allow 10–20 min for initial scan)
- [ ] Top 3 findings reviewed with CVE, CVSS, EPSS, and fix documented
- [ ] Remediation tracking table created
- [ ] Inspector Dashboard screenshot showing coverage and finding counts
- [ ] ECR scanning confirmed active
- [ ] Screenshot: Inspector findings sorted by score
- [ ] Screenshot: Individual finding detail showing CVE and remediation

**Portfolio commit:**
```bash
git add screenshots/day-18-*.png
git commit -m "Day 18: Inspector enabled, EC2 vulnerability scan, CVE findings prioritised by CVSS+EPSS"
git push
```

---

## 📝 Quiz

→ [week-3/quiz/week-3-quiz.md](./quiz/week-3-quiz.md) — Question 6.

---

## 🧹 Cleanup

Stop (don't terminate) the scan target instance — you'll use it on Day 19 for container context.

```bash
aws ec2 stop-instances --instance-ids "$INSTANCE_ID"
```

Terminate it on Day 21's cleanup.
