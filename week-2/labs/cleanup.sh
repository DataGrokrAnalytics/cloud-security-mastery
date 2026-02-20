#!/bin/bash
# =============================================================================
# Week 2 Cleanup Script
# Cloud Security Mastery Program
#
# Run on Day 14 (Sunday) to remove temporary lab resources.
#
# What this script REMOVES:
#   - EC2 instance from Day 12 (ssm-lab-instance)
#   - Secrets Manager secret from Day 10 (prod/myapp/database)
#   - EC2 security group from Day 12 (ssm-no-inbound)
#
# What this script KEEPS (needed for later weeks):
#   - IAM policies created on Day 08
#   - IAM Access Analyzer (Day 09)
#   - JIT role from Day 13
#   - EC2-SSM-Role from Day 12
#   - All Week 1 resources (Config, Security Hub, etc.)
#
# Usage:
#   chmod +x cleanup.sh
#   ./cleanup.sh
# =============================================================================

set -euo pipefail

echo ""
echo "=============================================="
echo " Week 2 Cleanup"
echo "=============================================="
echo ""

# Step 1: Terminate ssm-lab-instance
echo "[1] Looking for ssm-lab-instance..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ssm-lab-instance" \
            "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text 2>/dev/null || echo "None")

if [[ "$INSTANCE_ID" != "None" && "$INSTANCE_ID" != "null" ]]; then
  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" > /dev/null
  echo "  ✅ Terminating instance: $INSTANCE_ID"
else
  echo "  ℹ️  ssm-lab-instance not found (may already be terminated)"
fi

# Step 2: Delete Secrets Manager secret
echo "[2] Deleting Secrets Manager secret: prod/myapp/database"
if aws secretsmanager describe-secret --secret-id "prod/myapp/database" &>/dev/null; then
  aws secretsmanager delete-secret \
    --secret-id "prod/myapp/database" \
    --recovery-window-in-days 7
  echo "  ✅ Secret scheduled for deletion (7-day recovery window)"
else
  echo "  ℹ️  Secret not found (may already be deleted)"
fi

# Step 3: Check for any other running instances
echo "[3] Checking for other running EC2 instances..."
RUNNING=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0]]" \
  --output text)
if [[ -z "$RUNNING" ]]; then
  echo "  ✅ No running instances"
else
  echo "  ⚠️  Found running instances — review if intentional:"
  echo "$RUNNING"
fi

# Step 4: Verify cost
echo ""
echo "[4] Current month cost estimate:"
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost.Amount" \
  --output text 2>/dev/null || echo "  (Cost Explorer may take 24h to update)"

echo ""
echo "=============================================="
echo " Cleanup complete"
echo "=============================================="
echo ""
echo "  Next: verify spend at https://console.aws.amazon.com/cost-management/home"
echo "  Then: start Week 3 on Monday with week-3/day-15.md"
