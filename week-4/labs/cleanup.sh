#!/bin/bash
# =============================================================================
# Week 4 / Final Cleanup Script
# Cloud Security Mastery Program
#
# Run on Day 28 after completing the programme.
#
# What this script REMOVES:
#   - SOAR Lambda function and execution role (Day 26)
#   - EventBridge SOAR rule (Day 26)
#   - KMS key (scheduled for deletion — 7-day wait) (Day 16)
#   - S3 encrypted data bucket (Day 16)
#   - JIT IAM role (Day 13)
#   - Week 2 custom IAM policies (Day 08)
#   - ECR repository (Day 19)
#
# What this script KEEPS (permanent security controls):
#   - AWS Config + all rules
#   - Security Hub + all standards
#   - CloudTrail trail + CloudWatch Logs
#   - 11 CIS CloudWatch alarms
#   - GuardDuty
#   - Amazon Macie
#   - Amazon Inspector
#   - IAM Access Analyzer (account + org level)
#   - AWS Organizations + SCP
#   - EC2-SSM-Role
#   - IAM admin user and group
#   - AWS Budgets alert
#
# Usage:
#   chmod +x cleanup.sh
#   ./cleanup.sh
# =============================================================================

set -euo pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")

echo ""
echo "=============================================="
echo " Final 28-Day Programme Cleanup"
echo " Account: $ACCOUNT_ID | Region: $REGION"
echo "=============================================="
echo ""

# ── SOAR Resources (Day 26) ───────────────────────────────────────────────────
echo "[1] Removing SOAR resources..."

aws events remove-targets \
  --rule SecurityHub-S3-PublicAccess-Remediation \
  --ids SoarLambda 2>/dev/null && echo "  ✅ EventBridge target removed" || echo "  ℹ️  EventBridge target not found"

aws events delete-rule \
  --name SecurityHub-S3-PublicAccess-Remediation 2>/dev/null \
  && echo "  ✅ EventBridge rule deleted" || echo "  ℹ️  EventBridge rule not found"

aws lambda delete-function \
  --function-name soar-s3-remediation 2>/dev/null \
  && echo "  ✅ SOAR Lambda deleted" || echo "  ℹ️  Lambda not found"

aws iam delete-role-policy \
  --role-name SOARRemediationRole \
  --policy-name SOARRemediationPolicy 2>/dev/null || true

aws iam delete-role \
  --role-name SOARRemediationRole 2>/dev/null \
  && echo "  ✅ SOAR IAM role deleted" || echo "  ℹ️  Role not found"

# ── KMS Key (Day 16) ──────────────────────────────────────────────────────────
echo ""
echo "[2] Scheduling KMS key deletion (7-day window)..."
KEY_ID=$(aws kms describe-key --key-id alias/lab-s3-encryption-key \
  --query "KeyMetadata.KeyId" --output text 2>/dev/null || echo "not-found")

if [[ "$KEY_ID" != "not-found" && "$KEY_ID" != "None" ]]; then
  # Check if already scheduled
  KEY_STATE=$(aws kms describe-key --key-id "$KEY_ID" \
    --query "KeyMetadata.KeyState" --output text 2>/dev/null || echo "Unknown")
  if [[ "$KEY_STATE" == "PendingDeletion" ]]; then
    echo "  ℹ️  KMS key already scheduled for deletion"
  else
    aws kms schedule-key-deletion --key-id "$KEY_ID" --pending-window-in-days 7
    echo "  ✅ KMS key scheduled for deletion in 7 days"
  fi
else
  echo "  ℹ️  KMS key not found"
fi

# ── S3 Encrypted Bucket (Day 16) ──────────────────────────────────────────────
echo ""
echo "[3] Deleting S3 encrypted data bucket..."
BUCKET="lab-encrypted-data-${ACCOUNT_ID}"

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  # Remove all objects (including versions)
  aws s3 rm "s3://${BUCKET}" --recursive 2>/dev/null || true
  # Remove any object versions if versioning was enabled
  VERSIONS=$(aws s3api list-object-versions --bucket "$BUCKET" \
    --query "[Versions,DeleteMarkers]" --output json 2>/dev/null || echo "[]")
  if [[ "$VERSIONS" != "[[],null]" && "$VERSIONS" != "[null,null]" ]]; then
    echo "  Removing versioned objects..."
    aws s3api list-object-versions --bucket "$BUCKET" \
      --query 'Versions[*].{Key:Key,VersionId:VersionId}' \
      --output text 2>/dev/null | while read -r key vid; do
        aws s3api delete-object --bucket "$BUCKET" --key "$key" \
          --version-id "$vid" 2>/dev/null || true
      done
  fi
  aws s3api delete-bucket --bucket "$BUCKET" 2>/dev/null \
    && echo "  ✅ Bucket deleted: $BUCKET" || echo "  ⚠️  Bucket deletion failed — may have objects remaining"
else
  echo "  ℹ️  Bucket not found: $BUCKET"
fi

# ── JIT IAM Role (Day 13) ─────────────────────────────────────────────────────
echo ""
echo "[4] Removing JIT IAM role..."
aws iam delete-role --role-name JIT-ReadOnly-1Hour 2>/dev/null \
  && echo "  ✅ JIT role deleted" || echo "  ℹ️  JIT role not found"

# ── Week 2 Custom IAM Policies (Day 08) ───────────────────────────────────────
echo ""
echo "[5] Removing Week 2 custom IAM policies..."
POLICIES=("S3ReadOnly-AppBucket" "EC2ReadOnly" "DenyNonEUWest1Region" \
           "SecretsReadRequireMFA" "DeveloperPolicy-NoIAM")

for policy in "${POLICIES[@]}"; do
  POLICY_ARN=$(aws iam list-policies --scope Local \
    --query "Policies[?PolicyName=='${policy}'].Arn" \
    --output text 2>/dev/null)
  if [[ -n "$POLICY_ARN" && "$POLICY_ARN" != "None" ]]; then
    aws iam delete-policy --policy-arn "$POLICY_ARN" 2>/dev/null \
      && echo "  ✅ Deleted: $policy" || echo "  ⚠️  Could not delete: $policy (may be attached)"
  else
    echo "  ℹ️  Not found: $policy"
  fi
done

# ── ECR Repository (Day 19) ───────────────────────────────────────────────────
echo ""
echo "[6] Deleting ECR repository..."
aws ecr delete-repository --repository-name lab-secure-app --force 2>/dev/null \
  && echo "  ✅ ECR repository deleted" || echo "  ℹ️  ECR repository not found"

# ── Running Instances Check ───────────────────────────────────────────────────
echo ""
echo "[7] Checking for any running EC2 instances..."
RUNNING=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0]]" \
  --output text 2>/dev/null)

if [[ -z "$RUNNING" ]]; then
  echo "  ✅ No running EC2 instances"
else
  echo "  ⚠️  Found running instances — terminate if not needed:"
  echo "$RUNNING"
fi

# ── Final Cost Check ──────────────────────────────────────────────────────────
echo ""
echo "[8] Programme cost summary:"
COST=$(aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost.Amount" \
  --output text 2>/dev/null || echo "unavailable")
echo "  This month so far: \$$COST"
echo "  Full programme: verify at https://console.aws.amazon.com/cost-management/home"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=============================================="
echo " Programme cleanup complete"
echo "=============================================="
echo ""
echo "  Permanent security controls still running:"
echo "    ✅ AWS Config              (continuous misconfiguration detection)"
echo "    ✅ Security Hub            (unified risk dashboard)"
echo "    ✅ CloudTrail              (audit trail)"
echo "    ✅ 11 CIS CloudWatch alarms (real-time alerting)"
echo "    ✅ GuardDuty               (threat detection)"
echo "    ✅ Amazon Macie            (PII monitoring)"
echo "    ✅ Amazon Inspector        (CVE scanning)"
echo "    ✅ IAM Access Analyzer     (external access monitoring)"
echo "    ✅ AWS Organizations + SCP (governance)"
echo ""
echo "  Next steps:"
echo "    → AWS Security Specialty exam: https://aws.amazon.com/certification/certified-security-specialty/"
echo "    → Further reading: resources/further-reading.md"
echo "    → Portfolio: https://github.com/$(git config --global user.name 2>/dev/null || echo 'your-username')/cloud-security-mastery"
echo ""
echo "  🏆 28-day programme complete."
