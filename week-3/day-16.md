# Day 16 — Data Protection: S3 Encryption & KMS Customer Keys

**Week 3: Network & Data Protection** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will understand the difference between AWS-managed and customer-managed encryption, have S3 buckets encrypted with KMS Customer Managed Keys, and be able to implement an encryption policy that satisfies SOC 2 and PCI DSS requirements.

---

## 📖 Theory (2.5 hours)

### 1. Encryption — The Last Line of Defence

If every other control fails — if an attacker bypasses your network segmentation, compromises an IAM role, and gains access to your S3 bucket — encryption is what makes the data useless to them. An encrypted file without the key is noise.

This is why encryption at rest is a baseline requirement in every compliance framework. SOC 2 CC6.7, PCI DSS Requirement 3.5, and HIPAA §164.312(a)(2)(iv) all require it. AWS makes it easy — the question is whether you're using it correctly.

---

### 2. The Three S3 Encryption Options

**SSE-S3 (Server-Side Encryption with S3-Managed Keys)**
AWS generates and manages the encryption keys entirely. Keys are never visible to you. Simple to enable, zero additional cost. Provides encryption at rest but gives you no control over key lifecycle, rotation, or access.

**SSE-KMS (Server-Side Encryption with KMS Keys)**
AWS KMS manages the keys. Two sub-options:
- **AWS Managed Key (aws/s3):** AWS creates and manages the key automatically. Free. Limited control.
- **Customer Managed Key (CMK):** You create the key in KMS. You control the key policy, rotation schedule, and can revoke access. Costs $1/month per key plus $0.03 per 10,000 API calls.

**SSE-C (Server-Side Encryption with Customer-Provided Keys)**
You manage the keys entirely outside AWS and provide them with each request. Most control, most operational complexity. Not covered in this program.

**For compliance purposes:** SSE-KMS with a Customer Managed Key is the preferred option because it gives you:
- Key usage audit logs in CloudTrail (every encrypt/decrypt call is logged)
- Ability to immediately revoke access by disabling the key
- Evidence of key rotation for auditors
- Key policies that restrict which services and identities can use the key

---

### 3. KMS Key Policies — Controlling Who Can Use a Key

Every KMS CMK has a key policy — a resource-based policy similar to an S3 bucket policy. It defines who can use the key for cryptographic operations and who can administer the key.

A well-designed key policy separates two roles:

**Key administrators** — can manage the key (rotate, schedule deletion, update policy) but cannot use it to encrypt/decrypt data. Typically security team or operations.

**Key users** — can use the key for cryptographic operations (encrypt, decrypt, generate data key) but cannot modify the key. Typically the application roles and S3 service.

```json
{
  "Statement": [
    {
      "Sid": "AllowKeyAdministration",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::ACCOUNT:role/SecurityAdmin"},
      "Action": ["kms:Create*", "kms:Describe*", "kms:Enable*",
                 "kms:List*", "kms:Put*", "kms:Update*",
                 "kms:Revoke*", "kms:Disable*", "kms:Get*",
                 "kms:Delete*", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion"],
      "Resource": "*"
    },
    {
      "Sid": "AllowKeyUsageByS3",
      "Effect": "Allow",
      "Principal": {"Service": "s3.amazonaws.com"},
      "Action": ["kms:GenerateDataKey", "kms:Decrypt"],
      "Resource": "*"
    }
  ]
}
```

---

### 4. S3 Bucket Policies — Enforcing Encryption in Transit

Encryption at rest protects stored data. Encryption in transit (TLS) protects data while it moves between clients and S3. A bucket policy can enforce that all requests use HTTPS:

```json
{
  "Statement": [{
    "Sid": "DenyNonTLS",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": [
      "arn:aws:s3:::your-bucket",
      "arn:aws:s3:::your-bucket/*"
    ],
    "Condition": {
      "Bool": {"aws:SecureTransport": "false"}
    }
  }]
}
```

Any request that doesn't use TLS (HTTP instead of HTTPS) is denied. This is a CIS and FSBP requirement (S3.5) and takes one bucket policy statement to enforce.

---

## 🔗 References

| Resource | URL |
|---|---|
| S3 Server-Side Encryption | https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html |
| KMS Key Policies | https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html |
| KMS Best Practices | https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html |
| S3 Bucket Policy Examples | https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html |

---

## 🛠️ Lab (1 hour)

### Step 1 — Create a Customer Managed KMS Key (15 min)

1. AWS Console → **KMS** → **Customer managed keys** → **Create key**
2. Key type: **Symmetric** | Key usage: **Encrypt and decrypt**
3. **Next**
4. Alias: `lab-s3-encryption-key`
5. Description: `CMK for S3 bucket encryption — Week 3 Day 16 lab`
6. **Next**
7. Key administrators: add your IAM admin user
8. Key users: add your IAM admin user (for the lab)
9. **Next** → review the key policy JSON → **Finish**
10. On the key detail page → **Key rotation** tab → **Edit** → enable annual rotation → **Save**

---

### Step 2 — Create an Encrypted S3 Bucket (20 min)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
BUCKET_NAME="lab-encrypted-data-${ACCOUNT_ID}"
KEY_ARN=$(aws kms describe-key \
  --key-id alias/lab-s3-encryption-key \
  --query KeyMetadata.Arn --output text)

# Create the bucket
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  $([ "$REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$REGION")

# Block all public access
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable default SSE-KMS encryption with your CMK
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "'"$KEY_ARN"'"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "✅ Bucket created: $BUCKET_NAME"
echo "✅ Encrypted with CMK: $KEY_ARN"
```

---

### Step 3 — Enforce TLS with a Bucket Policy (10 min)

```bash
aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "DenyNonTLS",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:*",
        "Resource": [
          "arn:aws:s3:::'"$BUCKET_NAME"'",
          "arn:aws:s3:::'"$BUCKET_NAME"'/*"
        ],
        "Condition": {
          "Bool": {"aws:SecureTransport": "false"}
        }
      },
      {
        "Sid": "DenyNonKMSEncryption",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::'"$BUCKET_NAME"'/*",
        "Condition": {
          "StringNotEquals": {
            "s3:x-amz-server-side-encryption": "aws:kms"
          }
        }
      }
    ]
  }'
echo "✅ Bucket policy applied — TLS and KMS encryption enforced"
```

---

### Step 4 — Verify Encryption in CloudTrail (15 min)

Upload a test file and verify the KMS encryption call appears in CloudTrail:

```bash
echo "This is sensitive test data" > /tmp/test-data.txt
aws s3 cp /tmp/test-data.txt "s3://$BUCKET_NAME/test-data.txt"
```

In the AWS Console:
1. CloudTrail → **Event history** → filter by **Event name: GenerateDataKey**
2. You should see a KMS `GenerateDataKey` call triggered by the S3 upload
3. Click the event → note the `requestParameters` showing the key ARN

This is the audit trail that proves encryption is operating correctly — valuable for SOC 2 and PCI DSS evidence.

---

## ✅ Checklist

- [ ] KMS CMK created with alias `lab-s3-encryption-key`
- [ ] Annual key rotation enabled on CMK
- [ ] S3 bucket created with SSE-KMS using the CMK
- [ ] Bucket public access block enabled on all 4 settings
- [ ] Bucket versioning enabled
- [ ] Bucket policy denying non-TLS requests applied
- [ ] Bucket policy denying non-KMS uploads applied
- [ ] Test file uploaded and KMS `GenerateDataKey` visible in CloudTrail
- [ ] Screenshot: S3 bucket encryption settings showing CMK ARN
- [ ] Screenshot: CloudTrail showing GenerateDataKey event

**Portfolio commit:**
```bash
git add screenshots/day-16-*.png
git commit -m "Day 16: S3 encrypted with KMS CMK, TLS enforced via bucket policy, CloudTrail evidence captured"
git push
```

---

## 📝 Quiz

→ [week-3/quiz/week-3-quiz.md](./quiz/week-3-quiz.md) — Questions 3 & 4.

---

## 🧹 Cleanup

Keep the bucket and KMS key — you'll use them on Day 17 (Macie scan). Note the KMS key costs $1/month after Free Tier — delete it on Day 21's cleanup if you don't plan to keep it.
