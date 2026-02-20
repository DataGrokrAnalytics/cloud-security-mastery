#!/bin/bash
# =============================================================================
# Day 06 Lab — CloudTrail + Root Account Usage Alarm
# Cloud Security Mastery Program
#
# What this script does:
#   1. Creates a multi-region CloudTrail trail
#   2. Creates a CloudWatch log group for CloudTrail
#   3. Creates a metric filter for root account usage (CIS 4.3)
#   4. Creates a CloudWatch alarm on that metric
#   5. Creates an SNS topic and subscribes your email
#
# Usage:
#   chmod +x day-06-cloudtrail-alarm.sh
#   ./day-06-cloudtrail-alarm.sh your@email.com
#
# Prerequisites:
#   - AWS CLI v2 configured (aws configure)
#   - IAM permissions: CloudTrail, CloudWatch, SNS, S3, IAM
# =============================================================================

set -euo pipefail

EMAIL="${1:-}"
if [[ -z "$EMAIL" ]]; then
  echo "Usage: $0 your@email.com"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")
TRAIL_NAME="management-trail"
BUCKET_NAME="cloudtrail-logs-${ACCOUNT_ID}-${REGION}"
LOG_GROUP="CloudTrail/ManagementEvents"
SNS_TOPIC="RootAccountUsageAlert"
ALARM_NAME="CIS-4.3-RootAccountUsage"

echo ""
echo "=============================================="
echo " Day 06 — CloudTrail + Root Alarm Setup"
echo "=============================================="
echo "Account : $ACCOUNT_ID"
echo "Region  : $REGION"
echo "Email   : $EMAIL"
echo ""

# Step 1: Create S3 bucket for CloudTrail logs
echo "[1/6] Creating S3 bucket for CloudTrail logs: $BUCKET_NAME"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "      Bucket already exists — skipping"
else
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "      ✅ Bucket created"
fi

# Attach required bucket policy for CloudTrail
echo "      Attaching CloudTrail bucket policy..."
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Sid\": \"AWSCloudTrailAclCheck\",
      \"Effect\": \"Allow\",
      \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"},
      \"Action\": \"s3:GetBucketAcl\",
      \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}\"
    },
    {
      \"Sid\": \"AWSCloudTrailWrite\",
      \"Effect\": \"Allow\",
      \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"},
      \"Action\": \"s3:PutObject\",
      \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/AWSLogs/${ACCOUNT_ID}/*\",
      \"Condition\": {\"StringEquals\": {\"s3:x-amz-acl\": \"bucket-owner-full-control\"}}
    }
  ]
}"
echo "      ✅ Bucket policy attached"

# Step 2: Create CloudWatch Log Group
echo "[2/6] Creating CloudWatch log group: $LOG_GROUP"
if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" \
  --query "logGroups[?logGroupName=='$LOG_GROUP']" --output text | grep -q "$LOG_GROUP"; then
  echo "      Log group already exists — skipping"
else
  aws logs create-log-group --log-group-name "$LOG_GROUP"
  aws logs put-retention-policy --log-group-name "$LOG_GROUP" --retention-in-days 90
  echo "      ✅ Log group created (90-day retention)"
fi

# Step 3: Create CloudTrail trail
echo "[3/6] Creating CloudTrail trail: $TRAIL_NAME"

# Create IAM role for CloudTrail → CloudWatch Logs
ROLE_NAME="CloudTrailCloudWatchLogsRole"
POLICY_NAME="CloudTrailCloudWatchLogsPolicy"
LOG_GROUP_ARN="arn:aws:logs:${REGION}:${ACCOUNT_ID}:log-group:${LOG_GROUP}:*"

if ! aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
  aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "cloudtrail.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' > /dev/null

  aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" \
    --policy-document "{
      \"Version\": \"2012-10-17\",
      \"Statement\": [{
        \"Effect\": \"Allow\",
        \"Action\": [\"logs:CreateLogStream\", \"logs:PutLogEvents\"],
        \"Resource\": \"${LOG_GROUP_ARN}\"
      }]
    }"
  echo "      ✅ IAM role created for CloudTrail"
  sleep 10  # allow IAM propagation
fi

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

if aws cloudtrail describe-trails --query "trailList[?Name=='$TRAIL_NAME']" \
  --output text | grep -q "$TRAIL_NAME"; then
  echo "      Trail already exists — skipping creation"
else
  aws cloudtrail create-trail \
    --name "$TRAIL_NAME" \
    --s3-bucket-name "$BUCKET_NAME" \
    --is-multi-region-trail \
    --enable-log-file-validation \
    --cloud-watch-logs-log-group-arn "arn:aws:logs:${REGION}:${ACCOUNT_ID}:log-group:${LOG_GROUP}" \
    --cloud-watch-logs-role-arn "$ROLE_ARN" > /dev/null
  aws cloudtrail start-logging --name "$TRAIL_NAME"
  echo "      ✅ Multi-region trail created and logging started"
fi

# Step 4: Create metric filter for root account usage
echo "[4/6] Creating metric filter: RootAccountUsage"
aws logs put-metric-filter \
  --log-group-name "$LOG_GROUP" \
  --filter-name "RootAccountUsage" \
  --filter-pattern '{ $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }' \
  --metric-transformations \
    metricName=RootAccountUsageCount,metricNamespace=CISBenchmark,metricValue=1,defaultValue=0
echo "      ✅ Metric filter created"

# Step 5: Create SNS topic and subscribe email
echo "[5/6] Creating SNS topic and subscribing $EMAIL"
TOPIC_ARN=$(aws sns create-topic --name "$SNS_TOPIC" --query TopicArn --output text)
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol email --notification-endpoint "$EMAIL" > /dev/null
echo "      ✅ SNS topic created: $TOPIC_ARN"
echo "      ⚠️  Check your email and confirm the SNS subscription"

# Step 6: Create CloudWatch alarm
echo "[6/6] Creating CloudWatch alarm: $ALARM_NAME"
aws cloudwatch put-metric-alarm \
  --alarm-name "$ALARM_NAME" \
  --alarm-description "CIS 4.3 — Fires when root account credentials are used" \
  --metric-name "RootAccountUsageCount" \
  --namespace "CISBenchmark" \
  --statistic "Sum" \
  --period 300 \
  --threshold 1 \
  --comparison-operator "GreaterThanOrEqualToThreshold" \
  --evaluation-periods 1 \
  --alarm-actions "$TOPIC_ARN" \
  --treat-missing-data "notBreaching"
echo "      ✅ Alarm created"

echo ""
echo "=============================================="
echo " Setup complete"
echo "=============================================="
echo ""
echo "  CloudTrail trail : $TRAIL_NAME (multi-region, log validation on)"
echo "  CloudWatch logs  : $LOG_GROUP"
echo "  Metric filter    : RootAccountUsage"
echo "  Alarm            : $ALARM_NAME"
echo "  SNS topic        : $TOPIC_ARN"
echo ""
echo "  ⚠️  ACTION REQUIRED: Confirm your SNS email subscription"
echo "     Check inbox for email from AWS Notifications and click Confirm"
echo ""
echo "  To verify the alarm works: log in as root and perform any action."
echo "  The alarm should fire within 5 minutes."
