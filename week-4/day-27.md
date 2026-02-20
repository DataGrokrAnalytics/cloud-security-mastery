# Day 27 — Advanced Operations: ScoutSuite & Risk Prioritisation

**Week 4: Detection & Operations** | 4 hours | Difficulty: Advanced

---

## 🎯 Objective

By the end of today you will have run a ScoutSuite assessment against your account to get an independent, outside-in view of your security posture, built a risk prioritisation matrix that maps findings to business impact, and practised the threat hunting workflow using CloudWatch Logs Insights.

---

## 📖 Theory (2.5 hours)

### 1. Why an External Assessment Tool Matters

AWS-native tools — Config, Security Hub, GuardDuty — are excellent but they have a shared characteristic: they're operated by the same team that built and configured the environment. When a misconfiguration exists, the native tools may be configured to suppress or ignore it.

An external assessment tool like ScoutSuite runs independently of your AWS console configuration. It makes direct API calls to enumerate your resources and checks them against a comprehensive security ruleset. It finds things that:

- Were suppressed in Security Hub but are still real issues
- Exist in services not covered by your active Config rules
- Are security concerns that AWS doesn't flag as non-compliant (but the security community considers risky)

ScoutSuite is open-source, maintained by NCC Group, and widely used in penetration testing and security assessments. Running it periodically gives you the perspective of an external assessor.

---

### 2. Risk Prioritisation — The Business Layer

Technical findings without business context are incomplete. A Critical CVE on a development instance that holds no sensitive data is objectively lower priority than a Medium misconfiguration on your payment processing service.

Risk prioritisation adds two dimensions to finding severity:

**Asset criticality** — how important is the affected resource to the business?
- Tier 1: Production services handling customer data or payments
- Tier 2: Production services with no customer data
- Tier 3: Staging and pre-production
- Tier 4: Development and sandbox

**Exploitability in your environment** — given your specific network configuration, IAM controls, and monitoring, how difficult would exploitation actually be?

The combination produces an **adjusted risk score**:

```
Adjusted Risk = Finding Severity × Asset Criticality × Exploitability Factor
```

A Critical finding on a Tier 4 dev instance with no internet access has a lower adjusted risk than a Medium finding on a Tier 1 production service with unrestricted outbound access.

This is the conversation security teams have with engineering and business leadership — not "we have 300 findings" but "we have 3 findings on Tier 1 services that an attacker could reach from the internet."

---

### 3. Threat Hunting — Proactive Detection

Threat hunting is the practice of proactively searching for attacker behaviour that automated detection hasn't flagged. It's the difference between waiting for GuardDuty to alert you and actively looking for signs of compromise.

A threat hunt has a hypothesis: "I think an attacker might be using IAM credentials from an unusual location." You then query your logs to either confirm or rule it out.

**Common threat hunting hypotheses for AWS:**

*"Are there IAM credentials being used from unusual source IPs?"*
```
fields eventTime, eventName, userIdentity.arn, sourceIPAddress
| filter not sourceIPAddress like /^10\./ 
    and not sourceIPAddress like /^172\.(1[6-9]|2[0-9]|3[01])\./
    and not sourceIPAddress like /^192\.168\./
| stats count(*) by sourceIPAddress, userIdentity.arn
| sort count desc
```

*"Is any resource making an unusually high number of API calls?"*
```
fields userIdentity.arn, eventName
| stats count(*) as callCount by userIdentity.arn
| sort callCount desc
| limit 20
```

*"Were any IAM changes made outside business hours?"*
```
fields eventTime, eventName, userIdentity.arn
| filter eventSource = "iam.amazonaws.com"
    and (ispresent(errorCode) = 0)
| parse eventTime /(?<hour>\d{2}):\d{2}:\d{2}/
| filter hour < 8 or hour > 18
| sort eventTime desc
```

Threat hunting is most effective when you have a clear hypothesis and a defined scope. Fishing through logs without a hypothesis produces noise, not signal.

---

### 4. Metrics That Matter to a CISO

By the time you brief security posture to a CISO or leadership, you need to translate technical findings into business metrics. The ones that matter most:

| Metric | What It Measures | Target |
|---|---|---|
| Mean Time to Detect (MTTD) | Average time from breach start to first alert | <1 hour for HIGH findings |
| Mean Time to Respond (MTTR) | Average time from alert to containment | <4 hours for HIGH, <15 min for SOAR-covered |
| Patch SLA compliance | % of CVEs patched within SLA window | >95% |
| Open critical findings >7 days | Findings that breached SLA | 0 |
| CIS compliance score | Benchmark posture | >85% |
| Automated remediation rate | % of findings auto-remediated | Track trend |

These six numbers tell a CISO more about security operations maturity than a 300-item finding list.

---

## 🔗 References

| Resource | URL |
|---|---|
| ScoutSuite GitHub | https://github.com/nccgroup/ScoutSuite |
| ScoutSuite Documentation | https://github.com/nccgroup/ScoutSuite/wiki |
| CloudWatch Logs Insights Examples | https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax-examples.html |
| MITRE ATT&CK Cloud Matrix | https://attack.mitre.org/matrices/enterprise/cloud/ |

---

## 🛠️ Lab (1 hour)

### Step 1 — Install and Run ScoutSuite (25 min)

```bash
# Install ScoutSuite
pip3 install scoutsuite --break-system-packages

# Verify installation
scout --version

# Run assessment against your AWS account
# Uses your current AWS CLI credentials
scout aws \
  --report-dir /tmp/scoutsuite-report \
  --no-browser

echo "✅ ScoutSuite assessment complete"
echo "   Report: /tmp/scoutsuite-report/scoutsuite-results/scoutsuite_results_aws-*.json"
```

The assessment takes 5–15 minutes. ScoutSuite queries 200+ checks across IAM, S3, EC2, RDS, CloudTrail, Config, Lambda, and more.

After it completes:
```bash
# List the findings summary
ls /tmp/scoutsuite-report/scoutsuite-results/
```

Open the HTML report in your browser:
```bash
# The HTML report is self-contained
open /tmp/scoutsuite-report/scoutsuite-results/scoutsuite_results_aws-*.html
# Or on Linux:
xdg-open /tmp/scoutsuite-report/scoutsuite-results/scoutsuite_results_aws-*.html
```

Navigate the report:
1. Dashboard → note the service-by-service risk breakdown
2. Click into **IAM** → review findings
3. Click into **S3** → review findings
4. Click into **CloudTrail** → confirm your trail appears as compliant

---

### Step 2 — Build a Risk Prioritisation Matrix (20 min)

Create `portfolio/week-4/risk-prioritisation-matrix.md`. Take your top 10 findings from ScoutSuite + Security Hub and add business context:

```markdown
# Risk Prioritisation Matrix
**Date:** [today]
**Account:** [your account ID]

## Scoring Key
- Severity: Critical=4, High=3, Medium=2, Low=1
- Asset Criticality: Tier1=4, Tier2=3, Tier3=2, Tier4=1
- Adjusted Score = Severity × Asset Criticality

| Finding | Source | Severity | Affected Resource | Asset Tier | Adj. Score | Action | Owner | Due |
|---|---|---|---|---|---|---|---|---|
| S3 public access block not set | ScoutSuite | High | [bucket] | Tier 2 | 9 | Enable block public access | You | Today |
| IAM user with no MFA | Security Hub | High | [user] | Tier 1 | 12 | Enable MFA | You | Today |
| CloudTrail not validating logs | ScoutSuite | Medium | [trail] | Tier 1 | 8 | Enable log validation | You | Week |
| ... | | | | | | | | |

## Top 3 Priority Actions This Week
1. [Highest adjusted score finding]
2. [Second highest]
3. [Third highest]

## Security Metrics Snapshot

| Metric | Value | Target | Trend |
|---|---|---|---|
| CIS Compliance Score | [%] | >85% | ↑ |
| Open Critical Findings | [count] | 0 | |
| Open High Findings >7 days | [count] | 0 | |
| Automated Remediation Coverage | [%] | >30% | |
```

---

### Step 3 — Run Two Threat Hunting Queries (15 min)

1. CloudWatch → **Logs Insights** → log group `CloudTrail/ManagementEvents`

**Hunt 1 — Unusual source IPs for IAM actions:**
```
fields eventTime, userIdentity.arn, eventName, sourceIPAddress
| filter eventSource = "iam.amazonaws.com"
    and not sourceIPAddress like /AWS Internal/
| stats count(*) as callCount by sourceIPAddress, userIdentity.arn
| sort callCount desc
| limit 15
```

**Hunt 2 — API calls generating errors (potential recon):**
```
fields eventTime, userIdentity.arn, eventName, errorCode, sourceIPAddress
| filter ispresent(errorCode)
    and errorCode != "NoSuchEntityException"
| stats count(*) as errorCount by sourceIPAddress, errorCode
| sort errorCount desc
| limit 15
```

Screenshot both query results. Note any unexpected source IPs or error patterns.

---

## ✅ Checklist

- [ ] ScoutSuite installed and run successfully
- [ ] HTML report opened and reviewed — top 5 findings noted
- [ ] Risk prioritisation matrix created with 10 findings and business context
- [ ] Two threat hunting queries run and results reviewed
- [ ] CISO metrics snapshot completed in portfolio
- [ ] Screenshot: ScoutSuite dashboard showing service risk breakdown
- [ ] Screenshot: Threat hunting query results

**Portfolio commit:**
```bash
git add portfolio/week-4/risk-prioritisation-matrix.md screenshots/day-27-*.png
git commit -m "Day 27: ScoutSuite assessment, risk prioritisation matrix, threat hunting queries"
git push
```

---

## 📝 Quiz

→ [week-4/quiz/week-4-quiz.md](./quiz/week-4-quiz.md) — Questions 9 & 10.

---

## 🧹 Cleanup

No persistent AWS resources created today. ScoutSuite ran read-only API calls — nothing was deployed.

The ScoutSuite report at `/tmp/scoutsuite-report/` is local only. Copy it to your portfolio folder if you want to keep it:
```bash
cp -r /tmp/scoutsuite-report/ ~/cloud-security-mastery/portfolio/week-4/scoutsuite-report/
```
