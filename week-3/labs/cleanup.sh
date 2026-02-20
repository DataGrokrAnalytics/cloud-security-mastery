#!/bin/bash
# =============================================================================
# Week 3 Cleanup Script
# Cloud Security Mastery Program
#
# Run on Day 21 (Sunday) to remove temporary lab resources.
#
# What this script REMOVES:
#   - Inspector scan target EC2 instance (Day 18)
#   - Lambda function lab-s3-reader (Day 20)
#   - Lambda execution role LambdaS3ReadRole (Day 20)
#   - ECR images in lab-secure-app (Day 19)
#   - VPC CloudFormation stack lab-vpc-week3 (Day 15)
#
# What this script KEEPS:
#   - S3 encrypted bucket (lab-encrypted-data-*) — needed for Week 4
#   - KMS key lab-s3-encryption-key — needed for Week 4
#   - Amazon Macie — continuous bucket monitoring
#   - Amazon Inspector — continuous scanning
#   - ECR repository (empty) — lab-secure-app
#   - All Week 1 resources (Config, Security Hub, CloudTrail, Organizations)
#   - All Week 2 resources (IAM Access Analyzer, JIT role, SSM role)
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
echo " Week 3 Cleanup"
echo " Account: $ACCOUNT_ID | Region: $REGION"
echo "=============================================="
echo ""

# Step 1: Terminate Inspector scan target instance
echo "[1] Looking for inspector-scan-target instance..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=inspector-scan-target" \
            "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text 2>/dev/null || echo "None")

if [[ "$INSTANCE_ID" != "None" && "$INSTANCE_ID" != "null" ]]; then
  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" > /dev/null
  echo "  ✅ Terminating: $INSTANCE_ID"
else
  echo "  ℹ️  Not found (may already be terminated)"
fi

# Step 2: Delete Lambda function
echo "[2] Deleting Lambda function: lab-s3-reader"
if aws lambda get-function --function-name lab-s3-reader &>/dev/null; then
  aws lambda delete-function --function-name lab-s3-reader
  echo "  ✅ Lambda function deleted"
else
  echo "  ℹ️  Lambda function not found"
fi

# Step 3: Delete Lambda IAM role
echo "[3] Deleting Lambda execution role: LambdaS3ReadRole"
if aws iam get-role --role-name LambdaS3ReadRole &>/dev/null; then
  # Delete inline policies first
  aws iam delete-role-policy \
    --role-name LambdaS3ReadRole \
    --policy-name LambdaS3ReadPolicy 2>/dev/null || true
  aws iam delete-role --role-name LambdaS3ReadRole
  echo "  ✅ Role deleted"
else
  echo "  ℹ️  Role not found"
fi

# Step 4: Delete ECR images (keep repository)
echo "[4] Clearing ECR images from lab-secure-app..."
if aws ecr describe-repositories --repository-names lab-secure-app &>/dev/null; then
  IMAGES=$(aws ecr list-images \
    --repository-name lab-secure-app \
    --query "imageIds[*]" \
    --output json 2>/dev/null)
  if [[ "$IMAGES" != "[]" && -n "$IMAGES" ]]; then
    aws ecr batch-delete-image \
      --repository-name lab-secure-app \
      --image-ids "$IMAGES" > /dev/null 2>&1 || true
    echo "  ✅ ECR images deleted (repository kept)"
  else
    echo "  ℹ️  No images in repository"
  fi
else
  echo "  ℹ️  ECR repository not found"
fi

# Step 5: Delete VPC CloudFormation stack
echo "[5] Deleting VPC stack: lab-vpc-week3"
if aws cloudformation describe-stacks --stack-name lab-vpc-week3 &>/dev/null; then
  aws cloudformation delete-stack --stack-name lab-vpc-week3
  echo "  ✅ Stack deletion initiated (takes ~5 minutes)"
  echo "     Flow log S3 bucket will be deleted with the stack"
else
  echo "  ℹ️  Stack not found"
fi

# Step 6: Verify running resources
echo ""
echo "[6] Checking for any remaining running EC2 instances..."
RUNNING=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0]]" \
  --output text 2>/dev/null)
if [[ -z "$RUNNING" ]]; then
  echo "  ✅ No running instances"
else
  echo "  ⚠️  Found running instances — review:"
  echo "$RUNNING"
fi

# Step 7: Cost check
echo ""
echo "[7] Current month cost estimate:"
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query "ResultsByTime[0].Total.BlendedCost.Amount" \
  --output text 2>/dev/null || echo "  (Cost Explorer may take 24h to update)"

echo ""
echo "=============================================="
echo " Week 3 cleanup complete"
echo "=============================================="
echo ""
echo "  Resources still running (needed for Week 4):"
echo "    - S3 encrypted bucket: lab-encrypted-data-${ACCOUNT_ID}"
echo "    - KMS key: lab-s3-encryption-key (\$1/month)"
echo "    - Amazon Macie (continuous monitoring)"
echo "    - Amazon Inspector (continuous scanning)"
echo "    - All Week 1 resources"
echo "    - All Week 2 IAM resources"
echo ""
echo "  Next: verify at https://console.aws.amazon.com/cost-management/home"
echo "  Then: start Week 4 on Monday with week-4/day-22.md"
