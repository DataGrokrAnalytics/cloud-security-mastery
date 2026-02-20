#!/bin/bash
# =============================================================================
# Week 1 Cleanup Script
# Cloud Security Mastery Program
#
# Run this every Sunday to remove temporary lab resources and verify $0 spend.
#
# What this script REMOVES:
#   - Any test S3 buckets you created manually during labs
#   - CloudWatch log groups older than 90 days (handled by retention policy)
#
# What this script KEEPS (intentionally — needed for later weeks):
#   - AWS Config and all rules
#   - Security Hub
#   - CloudTrail trail and CloudWatch alarm
#   - AWS Organizations and SCPs
#   - IAM admin user and Administrators group
#   - KMS keys
#
# Usage:
#   chmod +x cleanup.sh
#   ./cleanup.sh
# =============================================================================

set -euo pipefail

echo ""
echo "=============================================="
echo " Week 1 Cleanup"
echo "=============================================="
echo ""

# Step 1: List S3 buckets for review
echo "[1] Your S3 buckets (review for any test buckets to delete manually):"
aws s3 ls | sort
echo ""
echo "  To delete a test bucket: aws s3 rb s3://BUCKET-NAME --force"
echo "  Do NOT delete: cloudtrail-logs-* or config-* buckets"
echo ""

# Step 2: Check for running EC2 instances
echo "[2] Running EC2 instances (should be none at this stage):"
INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key=='Name'].Value|[0]]" \
  --output text)
if [[ -z "$INSTANCES" ]]; then
  echo "  ✅ No running instances"
else
  echo "  ⚠️  Found running instances — review and stop if not needed:"
  echo "$INSTANCES"
fi
echo ""

# Step 3: Check AWS Budgets spend
echo "[3] Current month cost estimate:"
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost.Amount" \
  --output text 2>/dev/null || echo "  (Cost Explorer data may take 24h to update)"
echo ""

# Step 4: Verify key Week 1 resources are still active
echo "[4] Verifying Week 1 resources are active:"

# Config
CONFIG=$(aws configservice describe-configuration-recorders \
  --query "ConfigurationRecorders[0].name" --output text 2>/dev/null || echo "NONE")
[[ "$CONFIG" != "NONE" && "$CONFIG" != "None" ]] \
  && echo "  ✅ AWS Config: active ($CONFIG)" \
  || echo "  ❌ AWS Config: NOT FOUND — re-enable in the console"

# CloudTrail
TRAIL=$(aws cloudtrail describe-trails \
  --query "trailList[0].Name" --output text 2>/dev/null || echo "NONE")
[[ "$TRAIL" != "NONE" && "$TRAIL" != "None" ]] \
  && echo "  ✅ CloudTrail: active ($TRAIL)" \
  || echo "  ❌ CloudTrail: NOT FOUND — re-create using day-06 lab script"

# Root usage alarm
ALARM=$(aws cloudwatch describe-alarms \
  --alarm-names "CIS-4.3-RootAccountUsage" \
  --query "MetricAlarms[0].AlarmName" --output text 2>/dev/null || echo "NONE")
[[ "$ALARM" != "NONE" && "$ALARM" != "None" ]] \
  && echo "  ✅ Root usage alarm: active" \
  || echo "  ❌ Root usage alarm: NOT FOUND — re-create using day-06 lab script"

echo ""
echo "=============================================="
echo " Cleanup complete"
echo "=============================================="
echo ""
echo "  Next: verify spend at https://console.aws.amazon.com/cost-management/home"
echo "  Then: start Week 2 on Monday with week-2/day-08.md"
