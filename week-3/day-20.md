# Day 20 — Serverless & EKS Security

**Week 3: Network & Data Protection** | 4 hours | Difficulty: Advanced

---

## 🎯 Objective

By the end of today you will understand the security model for serverless Lambda functions and EKS Kubernetes workloads, implement least-privilege Lambda execution roles, and know the specific security controls that matter most in each environment.

---

## 📖 Theory (2.5 hours)

### 1. Lambda Security — The Serverless Threat Model

Lambda functions are small, event-driven, and ephemeral — they run for milliseconds to minutes and then disappear. This changes the security model significantly compared to EC2:

**What you don't worry about with Lambda:**
- OS patching (AWS manages the runtime)
- Host-level intrusion detection
- SSH access or session management
- Network segmentation at the host level

**What you do worry about:**
- **Execution role permissions:** The Lambda's IAM role is its identity. Over-privileged roles are the primary attack surface.
- **Environment variables:** Secrets passed as env vars are visible in the console, in logs, and in any SDK call that reads the function configuration. Use Secrets Manager or Parameter Store instead.
- **Dependency vulnerabilities:** Your function's deployment package includes third-party libraries. Inspector can scan these.
- **Event injection:** Lambda functions process input from event sources (S3, SQS, API Gateway, DynamoDB streams). If that input isn't validated, it can trigger unexpected behaviour.
- **Function URL exposure:** Lambda function URLs bypass API Gateway and are publicly accessible by default. Any function with a URL needs explicit authentication.

---

### 2. Lambda Execution Role — Minimal Permissions

The execution role is the single most important security control for Lambda. Every Lambda function needs a role, and the permissions should be scoped precisely:

**Wrong:**
```json
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}
```

**Right — for a function that reads from DynamoDB and writes to SQS:**
```json
{
  "Effect": "Allow",
  "Action": ["dynamodb:GetItem", "dynamodb:Query"],
  "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/Orders"
},
{
  "Effect": "Allow",
  "Action": ["sqs:SendMessage"],
  "Resource": "arn:aws:sqs:us-east-1:123456789012:order-processing-queue"
},
{
  "Effect": "Allow",
  "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
  "Resource": "arn:aws:logs:*:123456789012:log-group:/aws/lambda/order-processor:*"
}
```

Every Lambda needs the CloudWatch Logs permissions (the last block) — without them you get no logs at all. Everything else should be scoped to the specific resources the function touches.

---

### 3. EKS Security — Kubernetes-Specific Controls

EKS runs Kubernetes, which introduces its own security layer on top of AWS IAM. Understanding the relationship between the two is essential:

**AWS IAM controls:**
- Who can call EKS API (create clusters, describe nodes, update nodegroups)
- What the worker node EC2 instances can do via their instance profiles
- What pods can do via IAM Roles for Service Accounts (IRSA)

**Kubernetes RBAC controls:**
- Who can call the Kubernetes API (kubectl get pods, kubectl exec, etc.)
- What namespaces and resources each identity can access inside the cluster

These two layers are independent but must be configured together. An engineer might have full AWS IAM permissions but be restricted from running `kubectl exec` by Kubernetes RBAC — or vice versa.

**The five most important EKS security controls:**

1. **IRSA (IAM Roles for Service Accounts)** — gives individual pods IAM permissions without giving the whole worker node the permissions. Each pod gets its own scoped role. Without IRSA, pods inherit the full permissions of the worker node's EC2 instance profile.

2. **Pod Security Standards** — enforce restrictions on what pods can do: no privileged containers, no host network access, no hostPath volume mounts, no running as root. Applied at the namespace level.

3. **Network policies** — Kubernetes network policies control east-west traffic between pods. Without them, any pod can reach any other pod in the cluster — no lateral movement boundary.

4. **Secrets encryption** — by default, Kubernetes secrets are stored base64-encoded in etcd (effectively plaintext). Enable KMS encryption for etcd to ensure secrets at rest are actually encrypted.

5. **Private API endpoint** — the Kubernetes API server should not be publicly accessible. Use the private endpoint and access it via VPN or Session Manager.

---

### 4. IRSA — The Key EKS Security Pattern

IRSA (IAM Roles for Service Accounts) solves the over-permission problem for Kubernetes pods. Without IRSA:

```
All pods on worker node
    → Inherit EC2 instance profile
    → Instance profile has S3 read, DynamoDB write, SQS access
    → Every pod has all these permissions whether it needs them or not
```

With IRSA:
```
Pod A (payment service)  → IAM role: DynamoDB write on payments table only
Pod B (notification svc) → IAM role: SES send email only
Pod C (analytics)        → IAM role: S3 read on logs bucket only
Worker node              → IAM role: Minimal (ECR pull, CloudWatch logs only)
```

IRSA works by associating a Kubernetes service account with an IAM role via OIDC. When a pod uses that service account, the AWS SDK automatically exchanges the Kubernetes token for temporary AWS credentials scoped to the associated IAM role.

---

## 🔗 References

| Resource | URL |
|---|---|
| Lambda Security Best Practices | https://docs.aws.amazon.com/lambda/latest/dg/lambda-security.html |
| EKS Best Practices Guide — Security | https://aws.github.io/aws-eks-best-practices/security/docs/ |
| IRSA Documentation | https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html |
| Kubernetes Pod Security Standards | https://kubernetes.io/docs/concepts/security/pod-security-standards/ |

---

## 🛠️ Lab (1 hour)

### Step 1 — Create a Least-Privilege Lambda Execution Role (15 min)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
BUCKET_NAME="lab-encrypted-data-${ACCOUNT_ID}"

# Create the execution role
aws iam create-role \
  --role-name LambdaS3ReadRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' \
  --description "Least-privilege Lambda role — S3 read + CloudWatch logs only"

# Attach CloudWatch Logs permission (every Lambda needs this)
aws iam put-role-policy \
  --role-name LambdaS3ReadRole \
  --policy-name LambdaS3ReadPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowS3ReadSpecificBucket",
        "Effect": "Allow",
        "Action": ["s3:GetObject", "s3:ListBucket"],
        "Resource": [
          "arn:aws:s3:::'"$BUCKET_NAME"'",
          "arn:aws:s3:::'"$BUCKET_NAME"'/*"
        ]
      },
      {
        "Sid": "AllowCloudWatchLogs",
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:'"$ACCOUNT_ID"':log-group:/aws/lambda/*"
      }
    ]
  }'

echo "✅ LambdaS3ReadRole created"
```

---

### Step 2 — Deploy a Lambda Function with the Role (25 min)

```bash
# Create the Lambda function code
cat > /tmp/lambda_function.py << 'EOF'
import boto3
import json
import os

s3 = boto3.client('s3')
BUCKET = os.environ['BUCKET_NAME']

def lambda_handler(event, context):
    """
    Lists objects in the configured S3 bucket.
    Demonstrates least-privilege: can list and read, cannot write or delete.
    """
    try:
        response = s3.list_objects_v2(Bucket=BUCKET, MaxKeys=10)
        objects = [obj['Key'] for obj in response.get('Contents', [])]
        return {
            'statusCode': 200,
            'body': json.dumps({
                'bucket': BUCKET,
                'objects': objects,
                'count': len(objects)
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
EOF

# Package it
cd /tmp && zip lambda_function.zip lambda_function.py

# Deploy
aws lambda create-function \
  --function-name lab-s3-reader \
  --runtime python3.12 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/LambdaS3ReadRole" \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda_function.zip \
  --environment "Variables={BUCKET_NAME=$BUCKET_NAME}" \
  --description "Day 20 lab — demonstrates least-privilege Lambda execution role" \
  --timeout 10 \
  --memory-size 128

echo "✅ Lambda function deployed"
```

---

### Step 3 — Invoke and Verify (20 min)

```bash
# Invoke the function
aws lambda invoke \
  --function-name lab-s3-reader \
  --payload '{}' \
  /tmp/lambda-output.json

cat /tmp/lambda-output.json
```

**Verify least privilege is enforced — test that write fails:**
```bash
# Attempt a write operation — should fail with AccessDenied
cat > /tmp/test_write.py << 'EOF'
import boto3, json, os
s3 = boto3.client('s3')
def lambda_handler(event, context):
    try:
        s3.put_object(Bucket=os.environ['BUCKET_NAME'],
                      Key='test.txt', Body=b'test')
        return {'statusCode': 200, 'body': 'Write succeeded (BAD)'}
    except Exception as e:
        return {'statusCode': 403, 'body': f'Write denied: {str(e)} (GOOD)'}
EOF
```

Note in your portfolio: the same role that successfully reads from S3 correctly denies write operations — least privilege confirmed.

**Review the Lambda in Security Hub:**
Security Hub → Findings → filter by Resource type: AWS::Lambda::Function — Inspector and Security Hub both evaluate Lambda function configurations.

---

## ✅ Checklist

- [ ] `LambdaS3ReadRole` created with S3 read + CloudWatch logs only
- [ ] Lambda function deployed with the least-privilege role
- [ ] Function invocation successful — returns object list
- [ ] Write operation confirmed as denied (AccessDenied)
- [ ] IRSA concept documented in portfolio (what it solves for EKS)
- [ ] Screenshot: Lambda function configuration showing execution role
- [ ] Screenshot: Successful invocation output

**Portfolio commit:**
```bash
git add screenshots/day-20-*.png
git commit -m "Day 20: Least-privilege Lambda role, function deployed and verified, EKS IRSA pattern documented"
git push
```

---

## 📝 Quiz

→ [week-3/quiz/week-3-quiz.md](./quiz/week-3-quiz.md) — Question 8.

---

## 🧹 Cleanup

Keep the Lambda function — you'll reference it on Day 26 (SOAR automation).

The function itself costs nothing unless invoked — Lambda's free tier covers 1 million invocations per month.
