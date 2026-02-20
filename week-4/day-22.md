# Day 22 — CloudTrail & SIEM Foundation

**Week 4: Detection & Operations** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will have a multi-region CloudTrail trail with log integrity validation enabled, CloudWatch Logs Insights queries that surface security-relevant events, and a working CloudWatch alarm on at least two critical security behaviours — turning your raw API logs into actionable signals.

---

## 📖 Theory (2.5 hours)

### 1. CloudTrail — The Security Audit Spine

Every meaningful action in AWS generates a CloudTrail event: an API call, a console login, a resource change, a policy modification. CloudTrail captures all of these as structured JSON log records. It is the single most important data source for security investigations in AWS.

Without CloudTrail, you can see the current state of your environment — which resources exist, what their configuration is — but you have no answer to "what happened and who did it?" With CloudTrail, you can reconstruct the sequence of events that led to any configuration state, identify the IAM identity that made each change, and provide that evidence to auditors.

CloudTrail has three event types:

**Management events** — control plane operations. Creating, modifying, or deleting AWS resources. Attaching IAM policies. Modifying security groups. These are free and enabled by default. This is what most security monitoring uses.

**Data events** — data plane operations. S3 object reads and writes, Lambda function invocations, DynamoDB item operations. These generate high volume and have a cost. Enable them selectively for sensitive resources.

**Insights events** — anomaly detection layer. CloudTrail analyses your management event patterns and alerts when API call rates deviate significantly from baseline. Useful for detecting credential stuffing and automated attacks.

---

### 2. What Makes a CloudTrail Trail Production-Grade

A default CloudTrail configuration has gaps. A production-grade trail requires:

**Multi-region:** By default, a trail in one region doesn't capture events from other regions. Multi-region trails capture everything — including global services like IAM, STS, and CloudFront — regardless of where the action was initiated.

**Log file validation:** CloudTrail can generate a digest file for each hour of logs, signed with a hash chain. If log files are tampered with or deleted, validation fails. This is the evidence integrity mechanism that makes your logs trustworthy for incident response and audits.

**S3 bucket hardening:** The bucket storing CloudTrail logs must not be publicly accessible, must have server-side encryption, and must have a bucket policy preventing even administrators from deleting logs (MFA delete or deny on `s3:DeleteObject`).

**CloudWatch Logs integration:** Streaming logs to CloudWatch Logs enables real-time alerting via metric filters and CloudWatch Alarms. Without this, you're doing forensics after the fact — not real-time detection.

---

### 3. CloudWatch Logs Insights — Querying Your Audit Trail

CloudWatch Logs Insights provides a query language for analysing log data. For CloudTrail, the most useful query patterns are:

**Find all actions by a specific identity:**
```
fields eventTime, eventName, sourceIPAddress, errorCode
| filter userIdentity.arn like "admin"
| sort eventTime desc
| limit 50
```

**Find failed API calls (access denied errors):**
```
fields eventTime, eventName, userIdentity.arn, errorCode, errorMessage
| filter errorCode = "AccessDenied" or errorCode = "UnauthorizedOperation"
| sort eventTime desc
| limit 100
```

**Find IAM policy changes:**
```
fields eventTime, eventName, userIdentity.arn, requestParameters
| filter eventSource = "iam.amazonaws.com"
  and (eventName like "Put" or eventName like "Attach"
       or eventName like "Detach" or eventName like "Delete")
| sort eventTime desc
```

**Find console logins (successful and failed):**
```
fields eventTime, userIdentity.userName, sourceIPAddress,
       responseElements.ConsoleLogin, additionalEventData.MFAUsed
| filter eventName = "ConsoleLogin"
| sort eventTime desc
```

These queries are the foundation of threat hunting — actively searching for anomalies rather than waiting for automated alerts to fire.

---

### 4. CIS Benchmark CloudWatch Alarms

CIS AWS Foundations Benchmark Section 4 defines 15 CloudWatch metric filters and alarms that should be active in every AWS account. These cover the most critical security events:

| CIS Control | Event | Why It Matters |
|---|---|---|
| 4.1 | Unauthorised API calls | Credentials being misused or tested |
| 4.2 | Console login without MFA | Non-compliant access or compromised account |
| 4.3 | Root account usage | High-risk activity — root should never be used |
| 4.4 | IAM policy changes | Potential privilege escalation |
| 4.5 | CloudTrail configuration changes | Attacker covering tracks |
| 4.6 | AWS console auth failures | Brute force or credential stuffing |
| 4.7 | KMS CMK disable/deletion | Data access disruption |
| 4.8 | S3 bucket policy changes | Data exfiltration setup |
| 4.9 | AWS Config changes | Disabling your detection capability |
| 4.11 | Route table changes | Network traffic rerouting |
| 4.14 | VPC changes | Network boundary modification |

You set up the root account alarm (4.3) on Day 6. Today you'll build the full set.

---

## 🔗 References

| Resource | URL |
|---|---|
| CloudTrail User Guide | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html |
| CloudWatch Logs Insights Query Syntax | https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html |
| CIS AWS Foundations Benchmark | https://www.cisecurity.org/benchmark/amazon_web_services |
| CloudTrail Log File Integrity Validation | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-validation-intro.html |

---

## 🛠️ Lab (1 hour)

### Step 1 — Verify Your CloudTrail Trail (10 min)

From Day 6, you should have a multi-region trail. Confirm it meets production standards:

```bash
# List all trails
aws cloudtrail describe-trails --query "trailList[*].[Name,IsMultiRegionTrail,LogFileValidationEnabled,HasCustomEventSelectors]" --output table

# Verify logging is active
aws cloudtrail get-trail-status --name management-trail \
  --query "[IsLogging, LatestDeliveryTime, LatestDeliveryError]" \
  --output table
```

If `IsMultiRegionTrail` is false or `LogFileValidationEnabled` is false, update the trail:
```bash
aws cloudtrail update-trail \
  --name management-trail \
  --is-multi-region-trail \
  --enable-log-file-validation
```

---

### Step 2 — Deploy the Full CIS CloudWatch Alarms (30 min)

This script creates all CIS Section 4 metric filters and alarms in one pass. It assumes your CloudTrail is already streaming to the `CloudTrail/ManagementEvents` log group (from Day 6).

Save as `week-4/labs/cis-cloudwatch-alarms.sh` and run it:

```bash
#!/bin/bash
# CIS AWS Foundations Benchmark — Section 4 CloudWatch Alarms
# Assumes CloudTrail log group: CloudTrail/ManagementEvents
# Assumes SNS topic already created from Day 6: RootAccountUsageAlert

set -euo pipefail

LOG_GROUP="CloudTrail/ManagementEvents"
NAMESPACE="CISBenchmark"
SNS_TOPIC_ARN=$(aws sns list-topics \
  --query "Topics[?contains(TopicArn,'RootAccountUsageAlert')].TopicArn" \
  --output text)

if [[ -z "$SNS_TOPIC_ARN" ]]; then
  echo "SNS topic not found. Creating..."
  SNS_TOPIC_ARN=$(aws sns create-topic --name RootAccountUsageAlert --query TopicArn --output text)
  echo "Created: $SNS_TOPIC_ARN"
  echo "⚠️  Subscribe your email: aws sns subscribe --topic-arn $SNS_TOPIC_ARN --protocol email --notification-endpoint your@email.com"
fi

create_alarm() {
  local filter_name="$1"
  local alarm_name="$2"
  local pattern="$3"
  local description="$4"

  aws logs put-metric-filter \
    --log-group-name "$LOG_GROUP" \
    --filter-name "$filter_name" \
    --filter-pattern "$pattern" \
    --metric-transformations \
      metricName="${filter_name}Count",metricNamespace="$NAMESPACE",metricValue=1,defaultValue=0

  aws cloudwatch put-metric-alarm \
    --alarm-name "$alarm_name" \
    --alarm-description "$description" \
    --metric-name "${filter_name}Count" \
    --namespace "$NAMESPACE" \
    --statistic Sum \
    --period 300 \
    --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --alarm-actions "$SNS_TOPIC_ARN" \
    --treat-missing-data notBreaching

  echo "  ✅ $alarm_name"
}

echo "Creating CIS Section 4 alarms..."

# CIS 4.1 — Unauthorised API calls
create_alarm "UnauthorizedAPICalls" "CIS-4.1-UnauthorizedAPICalls" \
  '{($.errorCode="*UnauthorizedAccess*") || ($.errorCode="AccessDenied*")}' \
  "CIS 4.1: Unauthorised API calls detected"

# CIS 4.2 — Console login without MFA
create_alarm "ConsoleSigninWithoutMFA" "CIS-4.2-ConsoleSigninWithoutMFA" \
  '{($.eventName="ConsoleLogin") && ($.additionalEventData.MFAUsed !="Yes") && ($.userIdentity.type="IAMUser") && ($.responseElements.ConsoleLogin="Success")}' \
  "CIS 4.2: Console login without MFA"

# CIS 4.3 — Root account usage (already from Day 6 — skip if exists)
aws cloudwatch describe-alarms --alarm-names "CIS-4.3-RootAccountUsage" \
  --query "MetricAlarms[0].AlarmName" --output text 2>/dev/null | grep -q "CIS" \
  && echo "  ✅ CIS-4.3-RootAccountUsage (already exists)" \
  || create_alarm "RootAccountUsage" "CIS-4.3-RootAccountUsage" \
    '{$.userIdentity.type="Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType !="AwsServiceEvent"}' \
    "CIS 4.3: Root account credentials used"

# CIS 4.4 — IAM policy changes
create_alarm "IAMPolicyChanges" "CIS-4.4-IAMPolicyChanges" \
  '{($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=SetDefaultPolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy)}' \
  "CIS 4.4: IAM policy changes detected"

# CIS 4.5 — CloudTrail configuration changes
create_alarm "CloudTrailChanges" "CIS-4.5-CloudTrailChanges" \
  '{($.eventName=CreateTrail) || ($.eventName=UpdateTrail) || ($.eventName=DeleteTrail) || ($.eventName=StartLogging) || ($.eventName=StopLogging)}' \
  "CIS 4.5: CloudTrail configuration changed"

# CIS 4.6 — Console auth failures
create_alarm "ConsoleAuthFailures" "CIS-4.6-ConsoleAuthFailures" \
  '{($.eventName=ConsoleLogin) && ($.responseElements.ConsoleLogin="Failure")}' \
  "CIS 4.6: Console authentication failures"

# CIS 4.7 — KMS CMK disable or deletion
create_alarm "KMSCMKDisableDeletion" "CIS-4.7-KMSCMKDisableDeletion" \
  '{($.eventSource=kms.amazonaws.com) && (($.eventName=DisableKey) || ($.eventName=ScheduleKeyDeletion))}' \
  "CIS 4.7: KMS CMK disabled or scheduled for deletion"

# CIS 4.8 — S3 bucket policy changes
create_alarm "S3BucketPolicyChanges" "CIS-4.8-S3BucketPolicyChanges" \
  '{($.eventSource=s3.amazonaws.com) && (($.eventName=PutBucketAcl) || ($.eventName=PutBucketPolicy) || ($.eventName=PutBucketCors) || ($.eventName=PutBucketLifecycle) || ($.eventName=PutBucketReplication) || ($.eventName=DeleteBucketPolicy) || ($.eventName=DeleteBucketCors) || ($.eventName=DeleteBucketLifecycle) || ($.eventName=DeleteBucketReplication))}' \
  "CIS 4.8: S3 bucket policy changes"

# CIS 4.9 — AWS Config changes
create_alarm "AWSConfigChanges" "CIS-4.9-AWSConfigChanges" \
  '{($.eventSource=config.amazonaws.com) && (($.eventName=StopConfigurationRecorder) || ($.eventName=DeleteDeliveryChannel) || ($.eventName=PutDeliveryChannel) || ($.eventName=PutConfigurationRecorder))}' \
  "CIS 4.9: AWS Config changes"

# CIS 4.11 — Route table changes
create_alarm "RouteTableChanges" "CIS-4.11-RouteTableChanges" \
  '{($.eventName=CreateRoute) || ($.eventName=CreateRouteTable) || ($.eventName=ReplaceRoute) || ($.eventName=ReplaceRouteTableAssociation) || ($.eventName=DeleteRouteTable) || ($.eventName=DeleteRoute) || ($.eventName=DisassociateRouteTable)}' \
  "CIS 4.11: Route table changes"

# CIS 4.14 — VPC changes
create_alarm "VPCChanges" "CIS-4.14-VPCChanges" \
  '{($.eventName=CreateVpc) || ($.eventName=DeleteVpc) || ($.eventName=ModifyVpcAttribute) || ($.eventName=AcceptVpcPeeringConnection) || ($.eventName=CreateVpcPeeringConnection) || ($.eventName=DeleteVpcPeeringConnection) || ($.eventName=RejectVpcPeeringConnection) || ($.eventName=AttachClassicLinkVpc) || ($.eventName=DetachClassicLinkVpc) || ($.eventName=DisableVpcClassicLink) || ($.eventName=EnableVpcClassicLink)}' \
  "CIS 4.14: VPC changes"

echo ""
echo "✅ All CIS Section 4 alarms created"
echo "   View in CloudWatch: https://console.aws.amazon.com/cloudwatch/home#alarmsV2:"
```

Run it:
```bash
chmod +x week-4/labs/cis-cloudwatch-alarms.sh
./week-4/labs/cis-cloudwatch-alarms.sh
```

---

### Step 3 — Run a Logs Insights Query (20 min)

1. CloudWatch → **Logs Insights**
2. Select log group: `CloudTrail/ManagementEvents`
3. Set time range: **Last 7 days**
4. Run this query to see all IAM-related activity since you started the program:

```
fields eventTime, eventName, userIdentity.arn, sourceIPAddress
| filter eventSource = "iam.amazonaws.com"
| sort eventTime desc
| limit 50
```

5. Review the results — you should see entries from your own IAM work in Weeks 1–3.
6. Run a second query to find any access denied errors:

```
fields eventTime, eventName, userIdentity.arn, errorCode
| filter errorCode like "Denied" or errorCode like "Unauthorized"
| sort eventTime desc
| limit 20
```

Screenshot both query results for your portfolio.

---

## ✅ Checklist

- [ ] CloudTrail trail confirmed as multi-region with log file validation enabled
- [ ] `cis-cloudwatch-alarms.sh` script saved to `week-4/labs/`
- [ ] All 11 CIS Section 4 alarms created and visible in CloudWatch
- [ ] Logs Insights query run — IAM activity visible
- [ ] Access Denied query run — results reviewed
- [ ] Screenshot: CloudWatch Alarms dashboard showing all CIS alarms
- [ ] Screenshot: Logs Insights query results

**Portfolio commit:**
```bash
git add week-4/labs/cis-cloudwatch-alarms.sh screenshots/day-22-*.png
git commit -m "Day 22: CloudTrail validated, 11 CIS Section 4 alarms deployed, Logs Insights queries run"
git push
```

---

## 📝 Quiz

→ [week-4/quiz/week-4-quiz.md](./quiz/week-4-quiz.md) — Questions 1 & 2.

---

## 🧹 Cleanup

Keep all alarms and the CloudTrail trail — they're core infrastructure that should run permanently. No cost beyond the existing CloudWatch and CloudTrail setup.
