#!/bin/bash
# =============================================================================
# Day 01 Lab — IAM Admin User Setup
# Cloud Security Mastery Program
#
# What this script does:
#   1. Creates an IAM group "Administrators" with AdministratorAccess
#   2. Creates an IAM user and adds them to the group
#   3. Creates console login credentials for that user
#   4. Outputs the sign-in URL and a temporary password
#
# Prerequisites:
#   - AWS CLI v2 installed and configured (run: aws configure)
#   - Credentials used must have IAM write permissions
#   - Run AFTER enabling root MFA manually (Step 2 in day-01.md)
#
# Usage:
#   chmod +x day-01-iam-hardening.sh
#   ./day-01-iam-hardening.sh
#
# NOTE: MFA cannot be enabled programmatically without a physical device.
# After running this script, enable MFA on the new user manually in the
# console (Step 4 of the lab in day-01.md).
# =============================================================================

set -euo pipefail

# ---- Configuration — edit these if needed ----
USERNAME="admin"
GROUP_NAME="Administrators"
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"
# ----------------------------------------------

echo ""
echo "=============================================="
echo " Day 01 — IAM Admin User Setup"
echo "=============================================="
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"
echo ""

# Step 1: Create the Administrators group
echo "[1/4] Creating IAM group: $GROUP_NAME"
if aws iam get-group --group-name "$GROUP_NAME" &>/dev/null; then
  echo "      Group already exists — skipping"
else
  aws iam create-group --group-name "$GROUP_NAME"
  echo "      ✅ Group created"
fi

# Step 2: Attach AdministratorAccess to the group
echo "[2/4] Attaching AdministratorAccess to $GROUP_NAME"
aws iam attach-group-policy \
  --group-name "$GROUP_NAME" \
  --policy-arn "$POLICY_ARN"
echo "      ✅ Policy attached"

# Step 3: Create the IAM user and add to group
echo "[3/4] Creating IAM user: $USERNAME"
if aws iam get-user --user-name "$USERNAME" &>/dev/null; then
  echo "      User already exists — skipping creation"
else
  aws iam create-user --user-name "$USERNAME"
  echo "      ✅ User created"
fi

aws iam add-user-to-group \
  --user-name "$USERNAME" \
  --group-name "$GROUP_NAME"
echo "      ✅ User added to $GROUP_NAME"

# Step 4: Create console login profile with a temp password
echo "[4/4] Creating console login profile"
TEMP_PASSWORD="TempPass-$(openssl rand -base64 8 | tr -dc 'A-Za-z0-9' | head -c 12)!"

if aws iam get-login-profile --user-name "$USERNAME" &>/dev/null; then
  echo "      Login profile already exists — skipping"
else
  aws iam create-login-profile \
    --user-name "$USERNAME" \
    --password "$TEMP_PASSWORD" \
    --password-reset-required
  echo "      ✅ Login profile created"
fi

# Output
echo ""
echo "=============================================="
echo " Setup complete. Save these credentials:"
echo "=============================================="
echo ""
echo "  Sign-in URL   : https://${ACCOUNT_ID}.signin.aws.amazon.com/console"
echo "  Username      : $USERNAME"
echo "  Temp password : $TEMP_PASSWORD"
echo "                  (you will be prompted to change this on first login)"
echo ""
echo "  ⚠️  Next steps (must be done in the console, not here):"
echo "  1. Log in using the credentials above"
echo "  2. Change your password when prompted"
echo "  3. IAM → Users → $USERNAME → Security credentials → Assign MFA device"
echo "  4. From this point on, use this user — not root"
echo ""

# Verification
echo "--- Verification ---"
echo "Policies on $GROUP_NAME:"
aws iam list-attached-group-policies \
  --group-name "$GROUP_NAME" \
  --query 'AttachedPolicies[*].PolicyName' \
  --output table

echo ""
echo "Groups for $USERNAME:"
aws iam list-groups-for-user \
  --user-name "$USERNAME" \
  --query 'Groups[*].GroupName' \
  --output table

echo ""
echo "✅ Done. Continue with Step 4 of day-01.md."
