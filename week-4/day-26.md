# Day 26 — Lambda SOAR: Automated Incident Response

**Week 4: Detection & Operations** | 4 hours | Difficulty: Advanced

---

## 🎯 Objective

By the end of today you will have a working serverless SOAR pipeline — EventBridge routing Security Hub findings to a Lambda function that automatically remediates a public S3 bucket and sends an alert — going from detection to remediation in under 30 seconds.

---

## 📖 Theory (2.5 hours)

### 1. SOAR — Security Orchestration, Automation and Response

Manual incident response has a fundamental scaling problem. A security team receiving 500 findings per day cannot meaningfully triage each one. Most findings are noise, some are real but low-priority, and a few are critical — but by the time a human reviews the queue, hours have passed.

SOAR (Security Orchestration, Automation and Response) addresses this by automating the response to well-understood, high-confidence finding types. The philosophy:

**Automate the obvious.** A public S3 bucket should never exist in a production account. If Config or Security Hub finds one, the correct action is always the same: make it private, notify the team, create a ticket. This requires no human judgement — automate it completely.

**Accelerate the complex.** A GuardDuty finding suggesting credential compromise requires human investigation — you can't automate the full response. But you can automate the first containment step: disable the credentials, capture the session data, create a high-priority ticket. The analyst starts an investigation, not a firefighting exercise.

**Measure what you automate.** Track Mean Time to Detect (MTTD) and Mean Time to Respond (MTTR) separately for automated vs. manual responses. Automation should drive MTTR from hours to seconds for the covered finding types.

---

### 2. The EventBridge → Lambda Pattern

The core AWS SOAR pattern is:

```
Security Service (GuardDuty / Security Hub / Config)
        │
        │ generates finding
        ▼
EventBridge (event bus)
        │
        │ rule matches finding type/severity
        ▼
Lambda Function (remediation logic)
        │
        ├── Remediate the resource (make S3 private, disable IAM key, etc.)
        ├── Send SNS notification (Slack, email, PagerDuty)
        └── Update Security Hub finding workflow status to "NOTIFIED" or "RESOLVED"
```

EventBridge is the routing layer. You write rules that match specific event patterns — "GuardDuty finding with severity >= 7" or "Config rule compliance change to NON_COMPLIANT for S3.1" — and route them to the appropriate Lambda function.

Lambda is the execution layer. Each Lambda function handles one type of finding and contains the remediation logic, the notification logic, and the evidence logging.

---

### 3. Idempotency — Critical for Automation

Automated remediation functions must be idempotent: running the same function twice on the same resource should produce the same result as running it once, with no error.

Why this matters: EventBridge can deliver the same event more than once (at-least-once delivery). Your Lambda might execute twice for the same finding. If the first execution already made the S3 bucket private, the second execution should check the current state and exit cleanly rather than failing or creating noise.

Pattern for idempotent remediation:

```python
def make_bucket_private(bucket_name):
    # Check current state first
    current_config = s3.get_public_access_block(Bucket=bucket_name)
    if all([
        current_config['BlockPublicAcls'],
        current_config['BlockPublicPolicy'],
        current_config['IgnorePublicAcls'],
        current_config['RestrictPublicBuckets']
    ]):
        print(f"Bucket {bucket_name} is already private — no action needed")
        return  # idempotent exit
    
    # Only remediate if actually needed
    s3.put_public_access_block(...)
    print(f"Remediated: {bucket_name} made private")
```

---

### 4. What to Automate vs. What to Gate

Not everything should be fully automated. A decision framework:

| Finding Type | Automation Level | Reason |
|---|---|---|
| Public S3 bucket | Full auto-remediation | Always wrong in production — zero false positives |
| Unencrypted S3 bucket | Auto-notify + ticket | Might have a business reason — needs human review |
| GuardDuty credential compromise | Auto-contain (disable key) + escalate | Contains blast radius, then human investigates |
| Root account usage | Auto-alert only | Root usage might be legitimate (rare but valid) |
| New admin IAM user | Auto-alert + require approval | Could be legitimate new hire |
| CloudTrail disabled | Auto-re-enable + page oncall | Attackers cover tracks — respond aggressively |

The general rule: automate when there are no legitimate false positives. Gate when there might be a valid business reason that automation can't distinguish.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS EventBridge User Guide | https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html |
| Security Hub EventBridge Integration | https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cloudwatch-events.html |
| AWS Lambda Idempotency | https://docs.aws.amazon.com/lambda/latest/dg/invocation-retries.html |
| NIST 800-61 — Containment Strategies | https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final |

---

## 🛠️ Lab (1 hour)

### Step 1 — Deploy the Remediation Lambda (25 min)

This Lambda function responds to Security Hub findings for `S3.2` (S3 buckets with public read access) and automatically enables block public access.

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

# Create the Lambda execution role
aws iam create-role \
  --role-name SOARRemediationRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' \
  --description "SOAR remediation role — S3 public access + Security Hub + SNS"

aws iam put-role-policy \
  --role-name SOARRemediationRole \
  --policy-name SOARRemediationPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "S3Remediation",
        "Effect": "Allow",
        "Action": [
          "s3:GetBucketPublicAccessBlock",
          "s3:PutPublicAccessBlock",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl"
        ],
        "Resource": "*"
      },
      {
        "Sid": "SecurityHubUpdate",
        "Effect": "Allow",
        "Action": ["securityhub:BatchUpdateFindings"],
        "Resource": "*"
      },
      {
        "Sid": "SNSAlert",
        "Effect": "Allow",
        "Action": ["sns:Publish"],
        "Resource": "*"
      },
      {
        "Sid": "CloudWatchLogs",
        "Effect": "Allow",
        "Action": ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
        "Resource": "arn:aws:logs:*:'"$ACCOUNT_ID"':log-group:/aws/lambda/*"
      }
    ]
  }'
```

Create the Lambda function code:

```bash
cat > /tmp/soar_remediation.py << 'PYTHON'
"""
SOAR Auto-Remediation: S3 Public Access
Triggered by: Security Hub finding for S3.2 (public S3 bucket)
Actions:
  1. Enable block public access on the affected bucket
  2. Update Security Hub finding to RESOLVED
  3. Send SNS notification with remediation details
"""

import boto3
import json
import os
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')
securityhub = boto3.client('securityhub')
sns = boto3.client('sns')

SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    # Security Hub sends findings in detail array
    findings = event.get('detail', {}).get('findings', [])
    if not findings:
        logger.warning("No findings in event — nothing to process")
        return {'statusCode': 200, 'body': 'No findings'}

    results = []
    for finding in findings:
        result = process_finding(finding)
        results.append(result)

    return {'statusCode': 200, 'body': json.dumps(results)}


def process_finding(finding):
    finding_id = finding.get('Id', 'unknown')
    product_arn = finding.get('ProductArn', '')
    resources = finding.get('Resources', [])

    logger.info("Processing finding: %s", finding_id)

    # Extract S3 bucket name from the affected resource
    bucket_name = None
    for resource in resources:
        if resource.get('Type') == 'AwsS3Bucket':
            # Resource ID format: arn:aws:s3:::bucket-name
            arn = resource.get('Id', '')
            bucket_name = arn.split(':::')[-1]
            break

    if not bucket_name:
        logger.warning("No S3 bucket found in finding resources")
        return {'finding_id': finding_id, 'status': 'skipped', 'reason': 'no S3 resource'}

    # --- Remediation (idempotent) ---
    remediated = False
    try:
        current = s3.get_public_access_block(Bucket=bucket_name)
        cfg = current.get('PublicAccessBlockConfiguration', {})
        already_private = all([
            cfg.get('BlockPublicAcls', False),
            cfg.get('BlockPublicPolicy', False),
            cfg.get('IgnorePublicAcls', False),
            cfg.get('RestrictPublicBuckets', False),
        ])

        if already_private:
            logger.info("Bucket %s already private — idempotent exit", bucket_name)
        else:
            s3.put_public_access_block(
                Bucket=bucket_name,
                PublicAccessBlockConfiguration={
                    'BlockPublicAcls': True,
                    'IgnorePublicAcls': True,
                    'BlockPublicPolicy': True,
                    'RestrictPublicBuckets': True,
                }
            )
            logger.info("✅ Remediated: %s — block public access enabled", bucket_name)
            remediated = True

    except s3.exceptions.NoSuchPublicAccessBlockConfiguration:
        # Bucket exists but has no block public access config — apply it
        s3.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True,
            }
        )
        remediated = True
        logger.info("✅ Remediated: %s — block public access applied", bucket_name)

    except Exception as e:
        logger.error("Failed to remediate %s: %s", bucket_name, str(e))
        return {'finding_id': finding_id, 'bucket': bucket_name,
                'status': 'error', 'error': str(e)}

    # --- Update Security Hub finding ---
    try:
        securityhub.batch_update_findings(
            FindingIdentifiers=[{
                'Id': finding_id,
                'ProductArn': product_arn
            }],
            Workflow={'Status': 'RESOLVED' if remediated else 'NOTIFIED'},
            Note={
                'Text': f'Auto-remediated by SOAR Lambda at {datetime.now(timezone.utc).isoformat()}. '
                        f'Block public access enabled on {bucket_name}.',
                'UpdatedBy': 'SOARRemediationLambda'
            }
        )
        logger.info("Security Hub finding updated to RESOLVED")
    except Exception as e:
        logger.warning("Could not update Security Hub finding: %s", str(e))

    # --- SNS Notification ---
    if SNS_TOPIC_ARN and remediated:
        message = {
            'subject': f'🔒 SOAR Auto-Remediation: S3 Bucket Made Private',
            'bucket': bucket_name,
            'finding_id': finding_id,
            'action': 'Block public access enabled automatically',
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'next_steps': 'Review who made the bucket public and why — see CloudTrail for S3 PutBucketPublicAccessBlock changes.'
        }
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject='SOAR Auto-Remediation: S3 bucket made private',
            Message=json.dumps(message, indent=2)
        )
        logger.info("SNS notification sent")

    return {
        'finding_id': finding_id,
        'bucket': bucket_name,
        'status': 'remediated' if remediated else 'already_compliant'
    }
PYTHON

cd /tmp && zip soar_remediation.zip soar_remediation.py

# Get SNS topic ARN from Day 6
SNS_ARN=$(aws sns list-topics \
  --query "Topics[?contains(TopicArn,'RootAccountUsageAlert')].TopicArn" \
  --output text)

aws lambda create-function \
  --function-name soar-s3-remediation \
  --runtime python3.12 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/SOARRemediationRole" \
  --handler soar_remediation.lambda_handler \
  --zip-file fileb://soar_remediation.zip \
  --environment "Variables={SNS_TOPIC_ARN=${SNS_ARN}}" \
  --description "SOAR: Auto-remediates public S3 buckets on Security Hub S3.2 findings" \
  --timeout 30 \
  --memory-size 128

echo "✅ SOAR Lambda deployed"
```

---

### Step 2 — Create the EventBridge Rule (20 min)

```bash
# Create the EventBridge rule matching Security Hub S3.2 findings
aws events put-rule \
  --name "SecurityHub-S3-PublicAccess-Remediation" \
  --description "Routes Security Hub S3.2 findings to SOAR Lambda" \
  --event-pattern '{
    "source": ["aws.securityhub"],
    "detail-type": ["Security Hub Findings - Imported"],
    "detail": {
      "findings": {
        "GeneratorId": ["aws-foundational-security-best-practices/v/1.0.0/S3.2"],
        "Workflow": {"Status": ["NEW"]},
        "RecordState": ["ACTIVE"]
      }
    }
  }' \
  --state ENABLED

# Get the rule ARN
RULE_ARN=$(aws events describe-rule \
  --name "SecurityHub-S3-PublicAccess-Remediation" \
  --query "Arn" --output text)

# Get the Lambda ARN
LAMBDA_ARN=$(aws lambda get-function \
  --function-name soar-s3-remediation \
  --query "Configuration.FunctionArn" --output text)

# Add Lambda as the target
aws events put-targets \
  --rule "SecurityHub-S3-PublicAccess-Remediation" \
  --targets "Id=SoarLambda,Arn=${LAMBDA_ARN}"

# Grant EventBridge permission to invoke Lambda
aws lambda add-permission \
  --function-name soar-s3-remediation \
  --statement-id EventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn "$RULE_ARN"

echo "✅ EventBridge rule created and Lambda target attached"
```

---

### Step 3 — Test the Pipeline End-to-End (15 min)

Invoke the Lambda directly with a synthetic Security Hub event to confirm the logic works:

```bash
cat > /tmp/test-event.json << EOF
{
  "detail": {
    "findings": [{
      "Id": "arn:aws:securityhub:${REGION}:${ACCOUNT_ID}:subscription/test/finding/test-001",
      "ProductArn": "arn:aws:securityhub:${REGION}::product/aws/securityhub",
      "GeneratorId": "aws-foundational-security-best-practices/v/1.0.0/S3.2",
      "Resources": [{
        "Type": "AwsS3Bucket",
        "Id": "arn:aws:s3:::lab-encrypted-data-${ACCOUNT_ID}"
      }],
      "Workflow": {"Status": "NEW"},
      "RecordState": "ACTIVE"
    }]
  }
}
EOF

aws lambda invoke \
  --function-name soar-s3-remediation \
  --payload file:///tmp/test-event.json \
  /tmp/soar-output.json

cat /tmp/soar-output.json
```

Check CloudWatch Logs for the Lambda:
```bash
aws logs tail /aws/lambda/soar-s3-remediation --since 5m
```

The output should confirm the bucket was already private (idempotent) or was remediated. Either result is correct.

---

## ✅ Checklist

- [ ] `SOARRemediationRole` created with least-privilege permissions
- [ ] `soar-s3-remediation` Lambda deployed
- [ ] EventBridge rule `SecurityHub-S3-PublicAccess-Remediation` created
- [ ] Lambda target attached to EventBridge rule
- [ ] End-to-end test successful — output shows `remediated` or `already_compliant`
- [ ] CloudWatch Logs show execution trace
- [ ] Screenshot: EventBridge rule with Lambda target
- [ ] Screenshot: Lambda execution output

**Portfolio commit:**
```bash
git add screenshots/day-26-*.png
git commit -m "Day 26: SOAR pipeline — EventBridge routes S3.2 findings to auto-remediation Lambda"
git push
```

---

## 📝 Quiz

→ [week-4/quiz/week-4-quiz.md](./quiz/week-4-quiz.md) — Question 8.

---

## 🧹 Cleanup

Keep the SOAR pipeline running — it's a live defence. The Lambda has no standing cost. The EventBridge rule has no cost when not firing.
