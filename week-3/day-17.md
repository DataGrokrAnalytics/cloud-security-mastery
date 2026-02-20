# Day 17 — Amazon Macie: Data Loss Prevention

**Week 3: Network & Data Protection** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will have Amazon Macie scanning your S3 buckets for PII and sensitive data, understand how to interpret findings, and be able to build an automated response that acts when sensitive data is found in the wrong place.

---

## 📖 Theory (2.5 hours)

### 1. The Data Classification Problem

Before you can protect data, you need to know where it is. In most organisations, sensitive data ends up in unexpected places:

- A developer dumps a production database table into an S3 bucket for "quick analysis"
- A customer support tool exports conversation logs — containing names, emails, phone numbers — to a shared S3 bucket
- A data pipeline writes processed records to a staging bucket that was meant to hold only aggregate statistics
- Test data gets populated with real customer records because "it's just the dev environment"

These situations are common. They're rarely malicious — they're the result of speed and convenience winning over process. The problem is that the data is now somewhere it shouldn't be, and no one knows it's there.

Amazon Macie solves this through continuous, automated discovery. Rather than relying on humans to track where sensitive data travels, Macie scans your S3 inventory using machine learning and regular expressions to find PII, PHI, financial data, and credentials wherever they land.

---

### 2. What Macie Detects

Macie identifies two categories of sensitive data:

**Managed data identifiers** — built by AWS, continuously updated. Cover:
- PII: names, addresses, passport numbers, driver's licence numbers, SSNs, tax IDs
- Financial: credit card numbers, bank account numbers, SWIFT codes
- Healthcare (PHI): ICD codes, drug names, health plan beneficiary numbers
- Credentials: AWS access keys, private keys, OAuth tokens, passwords
- Network data: IP addresses, MAC addresses

**Custom data identifiers** — regular expressions you write for organisation-specific patterns. Examples:
- Your internal employee ID format (`EMP-\d{6}`)
- Your proprietary account number format
- Document classification markers (`CONFIDENTIAL`, `INTERNAL ONLY`)

Macie also provides **bucket-level findings** that don't require scanning file contents:
- Buckets with public access enabled
- Buckets without default encryption
- Buckets that are publicly accessible via ACLs
- Buckets shared with external AWS accounts

---

### 3. Finding Severity and False Positives

Macie findings have three severity levels:

| Severity | What It Means |
|---|---|
| **High** | Multiple instances of sensitive data, or high-confidence detection of critical data (SSNs, credentials) |
| **Medium** | Fewer instances, or lower-confidence detection |
| **Low** | Potential match that requires human review to confirm |

Macie's false positive rate for managed identifiers is around 10–20% depending on data type. Common false positive patterns:

- Test data with realistic-looking but fake SSNs
- Documentation containing example credit card numbers
- Log files containing IP addresses that match PII patterns

The correct handling is the same as Config and Security Hub: suppress with documentation, not ignore. A suppressed finding says "we reviewed this, it's not a real risk." An ignored finding says nothing.

---

### 4. Automated Response with EventBridge

Macie integrates with Amazon EventBridge, which means you can trigger automated actions when a finding is generated:

```
Macie finding (SSN detected in unexpected bucket)
    ↓
EventBridge rule matches finding severity = HIGH
    ↓
Lambda function triggered:
    - Tags the object with "sensitive=true"
    - Moves object to a quarantine bucket
    - Sends alert to security Slack channel
    - Creates a Security Hub finding for tracking
```

This pattern — Macie → EventBridge → Lambda — is the foundation of data-aware automated response. We build the Lambda version of this in Week 4; today you'll see the EventBridge rule side.

---

## 🔗 References

| Resource | URL |
|---|---|
| Amazon Macie User Guide | https://docs.aws.amazon.com/macie/latest/user/what-is-macie.html |
| Macie Managed Data Identifiers | https://docs.aws.amazon.com/macie/latest/user/managed-data-identifiers.html |
| Macie Custom Data Identifiers | https://docs.aws.amazon.com/macie/latest/user/custom-data-identifiers.html |
| GDPR Article 32 | https://gdpr-info.eu/art-32-gdpr/ |

---

## 🛠️ Lab (1 hour)

### Step 1 — Enable Amazon Macie (5 min)

1. AWS Console → **Amazon Macie** → **Get started** → **Enable Macie**

Macie immediately begins an inventory of all S3 buckets in your account. The bucket-level findings (public access, encryption status) appear within minutes. Object-level findings (PII scanning) require running a classification job.

---

### Step 2 — Create a Test Dataset with Synthetic PII (10 min)

Create a CSV file with synthetic (fake) PII to give Macie something to find. Use only made-up data — never use real personal information in a lab.

```bash
cat > /tmp/synthetic-pii.csv << 'EOF'
first_name,last_name,ssn,email,credit_card,phone
Alice,Johnson,123-45-6789,alice.j@example.com,4111111111111111,555-867-5309
Bob,Smith,987-65-4321,bob.smith@example.com,5500005555555559,555-234-5678
Carol,Williams,456-78-9012,carol.w@example.com,378282246310005,555-345-6789
EOF

# Upload to your encrypted bucket from Day 16
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="lab-encrypted-data-${ACCOUNT_ID}"

aws s3 cp /tmp/synthetic-pii.csv "s3://$BUCKET_NAME/test-data/synthetic-pii.csv"
echo "✅ Test file uploaded"
```

> **Note:** The SSNs, credit card numbers, and phone numbers above are synthetic test values commonly used in security tooling documentation. They follow the correct formats so Macie can detect them, but they don't correspond to real people.

---

### Step 3 — Create and Run a Macie Classification Job (25 min)

1. Macie Console → **S3 classification jobs** → **Create job**
2. Select S3 buckets → check your `lab-encrypted-data-*` bucket → **Next**
3. Scheduling: **One-time job** (for the lab) → **Next**
4. Managed data identifiers: **All managed data identifiers** → **Next**
5. Custom data identifiers: skip for now → **Next**
6. Job name: `lab-pii-discovery-day17`
7. **Submit**

The job will take 5–15 minutes. While waiting, explore:
- Macie → **Summary** → review the bucket inventory findings
- Note which buckets show as unencrypted or publicly accessible

---

### Step 4 — Review Findings (20 min)

When the job completes:

1. Macie → **Findings** → review the findings from your job
2. Click into a finding → read the full detail:
   - **Finding type** — what category of data was found?
   - **Severity** — HIGH, MEDIUM, or LOW?
   - **Occurrences** — how many instances were detected?
   - **Sample records** — which records triggered the finding?
3. Note the affected object's S3 URI and the line numbers of the matches

**Create a custom data identifier (bonus):**
1. Macie → **Custom data identifiers** → **Create**
2. Name: `InternalEmployeeID`
3. Regular expression: `EMP-\d{6}`
4. Test string: `EMP-123456`
5. **Submit** — if the test shows a match, your regex is correct
6. **Create**

This custom identifier would fire if Macie finds any string matching `EMP-123456` format in your S3 objects.

---

## ✅ Checklist

- [ ] Amazon Macie enabled
- [ ] Bucket inventory visible in Macie Summary
- [ ] Synthetic PII file uploaded to encrypted bucket
- [ ] Classification job created and completed
- [ ] At least one finding reviewed in detail (SSN or credit card detection)
- [ ] Custom data identifier created (`InternalEmployeeID`)
- [ ] Screenshot: Macie findings showing PII detection in test file
- [ ] Screenshot: Macie bucket inventory showing encryption and access status

**Portfolio commit:**
```bash
git add screenshots/day-17-*.png
git commit -m "Day 17: Macie enabled, PII classification job run, synthetic SSN/CC findings reviewed"
git push
```

---

## 📝 Quiz

→ [week-3/quiz/week-3-quiz.md](./quiz/week-3-quiz.md) — Question 5.

---

## 🧹 Cleanup

Delete the synthetic PII file after the lab — no reason to keep test data around:
```bash
aws s3 rm "s3://$BUCKET_NAME/test-data/synthetic-pii.csv"
```

Keep Macie enabled — it provides continuous bucket-level monitoring at no ongoing cost unless you run classification jobs.

> **Cost note:** Macie charges for object evaluation during classification jobs ($1 per GB scanned after the first GB free). For this lab with a tiny test file, the cost is effectively $0. Full account scans on large S3 environments can be expensive — always check estimated cost before running jobs in production.
