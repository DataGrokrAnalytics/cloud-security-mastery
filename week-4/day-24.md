# Day 24 — Security Hub: CNAPP & Unified Risk Dashboard

**Week 4: Detection & Operations** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will have Security Hub operating as a true CNAPP — aggregating findings from Config, GuardDuty, Inspector, Macie, and Access Analyzer into a single prioritised risk dashboard, with custom insights that surface what matters most.

---

## 📖 Theory (2.5 hours)

### 1. From Point Tools to CNAPP

Over the past three weeks you've enabled multiple security services. Each one generates findings independently:

- **Config** — misconfiguration findings
- **GuardDuty** — threat detection findings
- **Inspector** — vulnerability findings
- **Macie** — data sensitivity findings
- **Access Analyzer** — excessive access findings

Without Security Hub, these findings live in separate consoles. A critical GuardDuty finding on the same resource as a critical Inspector CVE would require you to visit two different services to understand the combined risk. In a real environment with hundreds of findings across services, manually correlating this is impractical.

Security Hub solves this by being the aggregation layer — every integrated service sends findings to Security Hub in a standardised format (AWS Security Finding Format, or ASFF). You review one dashboard, query across all sources, and manage finding lifecycle (active, archived, resolved, suppressed) in one place.

This is what Gartner calls a CNAPP: Cloud-Native Application Protection Platform. It's not a new service — it's an architecture pattern where existing services feed a unified risk management layer.

---

### 2. AWS Security Finding Format (ASFF)

Every finding in Security Hub follows the same JSON structure regardless of which service generated it. Key fields:

```json
{
  "SchemaVersion": "2018-10-08",
  "Id": "arn:aws:guardduty:...:finding/abc123",
  "ProductArn": "arn:aws:securityhub:...:product/aws/guardduty",
  "GeneratorId": "arn:aws:guardduty:...",
  "AwsAccountId": "123456789012",
  "Types": ["TTPs/Command and Control/Backdoor:EC2-C&CActivity.B"],
  "Severity": {"Label": "HIGH", "Normalized": 70},
  "Title": "EC2 instance communicating with known command and control server",
  "Resources": [{"Type": "AwsEc2Instance", "Id": "i-0abc123..."}],
  "Workflow": {"Status": "NEW"},
  "RecordState": "ACTIVE"
}
```

The standardised format means you can write one query to find all HIGH severity findings across all sources, regardless of whether they came from GuardDuty, Inspector, or Macie.

---

### 3. Security Hub Insights

Insights are saved searches with aggregation — essentially dashboards within Security Hub. AWS provides 100+ built-in insights, but the most useful ones are custom-built for your environment.

**High-value custom insights to build:**

*"Resources with findings from multiple services"* — a resource appearing in both GuardDuty (active threat) and Inspector (known vulnerability) is higher priority than either finding alone. Combined signal = higher confidence and blast radius.

*"High severity findings open more than 7 days"* — findings that have been active without resolution for a week indicate process failures, not just security gaps. This is what a CISO asks about.

*"Findings on production-tagged resources"* — not all resources are equal. A Critical finding on a dev instance is lower priority than a Medium finding on your production payment processor.

---

### 4. Security Hub Scores and Compliance Coverage

Security Hub's summary page shows an overall security score (0–100) calculated from the percentage of controls that are passing. You've been tracking your CIS score since Day 3. By now, after six weeks of hardening, your score should reflect the work done.

More important than the overall number is understanding what each failing control means:

- A failing CIS control is a misconfiguration that deviates from the benchmark
- A failing FSBP (AWS Foundational Security Best Practice) control is an AWS-specific risk
- PCI DSS controls are the subset relevant to payment card environments

Use the Controls view to filter by standard and severity, and prioritise Critical and High failures over Medium and Low.

---

## 🔗 References

| Resource | URL |
|---|---|
| Security Hub User Guide | https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html |
| AWS Security Finding Format | https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-findings-format.html |
| Security Hub Insights | https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-insights.html |
| Gartner CNAPP | https://www.gartner.com/en/information-technology/glossary/cloud-native-application-protection-platform-cnapp |

---

## 🛠️ Lab (1 hour)

### Step 1 — Verify All Integrations Are Active (10 min)

```bash
# List all active Security Hub integrations
aws securityhub list-enabled-products-for-import \
  --query "ProductSubscriptions" \
  --output table
```

In the Security Hub console → **Integrations** tab, confirm these are enabled:
- AWS Config
- Amazon GuardDuty
- Amazon Inspector
- Amazon Macie
- IAM Access Analyzer

Enable any that are missing: find the integration → **Accept findings**.

---

### Step 2 — Review the Unified Findings Dashboard (15 min)

1. Security Hub → **Findings**
2. Group by **Severity** — note the breakdown of Critical / High / Medium / Low
3. Filter by **Record state: ACTIVE** and **Workflow status: NEW**
4. Sort by **Severity** → look at the top 10 findings across all services

For your top 5 findings, record in your portfolio:
- Which service generated it (product name)
- What resource is affected
- What the finding describes
- Whether you can remediate it today

---

### Step 3 — Create Three Custom Insights (25 min)

**Insight 1 — High severity findings open more than 7 days:**

1. Security Hub → **Insights** → **Create insight**
2. Add filter: **Severity label** is **CRITICAL** or **HIGH**
3. Add filter: **Created at** is before 7 days ago
4. Add filter: **Workflow status** is **NEW**
5. Group by: **Resource ID**
6. Name: `High-Severity Findings Open More Than 7 Days`
7. **Create insight**

**Insight 2 — Findings by source service:**

1. **Create insight**
2. Filter: **Record state** is **ACTIVE**
3. Filter: **Workflow status** is **NEW**
4. Group by: **Product name**
5. Name: `Active Findings by Source Service`
6. **Create insight**

**Insight 3 — Failed compliance controls (CIS only):**

1. **Create insight**
2. Filter: **Type** starts with `Software and Configuration Checks/Industry and Regulatory Standards/CIS`
3. Filter: **Compliance status** is **FAILED**
4. Group by: **Title**
5. Name: `CIS Benchmark Failing Controls`
6. **Create insight**

---

### Step 4 — Record Your Security Score (10 min)

1. Security Hub → **Summary** tab
2. Record your current scores:
   - CIS AWS Foundations Benchmark: ____%
   - AWS Foundational Security Best Practices: ____%
   - Overall Security Score: ____%

3. Screenshot the summary dashboard for your portfolio
4. Open the **Controls** view → filter to Critical/High failures → note the top 3 failing controls and what they require to fix

---

## ✅ Checklist

- [ ] All 5 integrations active (Config, GuardDuty, Inspector, Macie, Access Analyzer)
- [ ] Top 10 findings reviewed across all sources
- [ ] 3 custom insights created
- [ ] Security scores recorded (CIS, FSBP, overall)
- [ ] Top 3 failing controls identified
- [ ] Screenshot: Security Hub summary with scores
- [ ] Screenshot: Findings dashboard with integrated sources

**Portfolio commit:**
```bash
git add screenshots/day-24-*.png
git commit -m "Day 24: Security Hub CNAPP — 5 integrations active, 3 custom insights, scores recorded"
git push
```

---

## 📝 Quiz

→ [week-4/quiz/week-4-quiz.md](./quiz/week-4-quiz.md) — Question 5.

---

## 🧹 Cleanup

Keep Security Hub and all integrations running — this is your permanent risk dashboard.
