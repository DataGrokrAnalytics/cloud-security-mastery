# Day 11 — IaC Security Scanning with Checkov

**Week 2: Zero Trust Identity** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will understand Policy-as-Code, be able to scan Infrastructure as Code templates for security misconfigurations before they're deployed, and have a CloudFormation template that passes Checkov's security checks.

---

## 📖 Theory (2.5 hours)

### 1. The Problem with Fixing Security After Deployment

The Days 2–6 workflow — deploy infrastructure, scan with Config, remediate findings — works. But it has a fundamental flaw: the misconfiguration exists in production for some window of time before it's detected and fixed. In a busy environment with frequent deployments, that window can be hours or longer.

**Shift-left security** is the practice of moving security checks earlier in the development lifecycle — from post-deployment scanning to pre-deployment scanning. The further left you catch a problem, the cheaper it is to fix:

```
Cost to fix:

Developer's   Code      Pull    Staging   Production  Production
laptop     →  review  → Request → test   → deploy   → breach
$1            $5        $20       $100      $1,000     $1,000,000+
```

IaC security scanning catches misconfigurations at the template level — before a single resource is created.

---

### 2. CloudFormation Basics

AWS CloudFormation is AWS's native Infrastructure as Code service. You write a template (JSON or YAML) describing your desired resources, and CloudFormation creates, updates, or deletes them to match.

A basic CloudFormation template structure:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: What this stack creates

Parameters:
  Environment:
    Type: String
    Default: dev

Resources:
  MyBucket:               # Logical name (your reference)
    Type: AWS::S3::Bucket # Resource type
    Properties:
      BucketName: !Sub '${Environment}-my-app-bucket'
      VersioningConfiguration:
        Status: Enabled

Outputs:
  BucketName:
    Value: !Ref MyBucket
```

CloudFormation is the tooling used throughout this program — all lab infrastructure is defined as templates so you can deploy consistently and clean up reliably.

---

### 3. Checkov — IaC Security Scanner

Checkov is an open-source static analysis tool that scans CloudFormation, Terraform, Kubernetes manifests, Docker files, and more for security misconfigurations. It runs locally or in CI/CD pipelines.

Checkov maps its checks to real compliance frameworks — CIS, NIST, PCI DSS, SOC 2. When it flags a resource, it tells you which framework control is violated and how to fix it.

**Common Checkov checks for CloudFormation:**

| Check ID | What It Checks |
|---|---|
| CKV_AWS_18 | S3 bucket has access logging enabled |
| CKV_AWS_19 | S3 bucket has default encryption enabled |
| CKV_AWS_21 | S3 bucket has versioning enabled |
| CKV_AWS_53 | S3 bucket has block public access enabled |
| CKV_AWS_23 | All ingress ports in a security group are specified |
| CKV_AWS_25 | Security group does not allow unrestricted ingress |
| CKV_AWS_7 | KMS key rotation is enabled |
| CKV_AWS_111 | IAM policy does not allow write access to all resources |

---

### 4. Integrating Checkov into a CI/CD Pipeline

Running Checkov locally is useful during development. The real value is running it automatically on every pull request, blocking merges until security checks pass.

A basic GitHub Actions step for Checkov:

```yaml
- name: Run Checkov
  uses: bridgecrewio/checkov-action@master
  with:
    directory: infrastructure/
    framework: cloudformation
    soft_fail: false   # fail the PR if checks fail
```

With `soft_fail: false`, a developer cannot merge a CloudFormation template with a CKV_AWS_53 (public S3) violation. The security check becomes part of the delivery process, not an afterthought.

---

## 🔗 References

| Resource | URL |
|---|---|
| Checkov Documentation | https://www.checkov.io/1.Welcome/What%20is%20Checkov.html |
| Checkov CloudFormation Checks | https://www.checkov.io/5.Policy%20Index/cloudformation.html |
| AWS CloudFormation User Guide | https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html |
| PCI DSS 4.0 Requirement 6.4.3 | https://www.pcisecuritystandards.org/document_library/ |

---

## 🛠️ Lab (1 hour)

### Step 1 — Install Checkov (5 min)

```bash
pip3 install checkov
checkov --version
```

---

### Step 2 — Create an Intentionally Insecure CloudFormation Template (15 min)

Create a file called `week-2/labs/vpc-insecure.yaml` with this content — intentionally missing several security configurations so Checkov has something to find:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Intentionally insecure VPC template for Checkov scanning lab

Resources:

  # VPC
  LabVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true

  # Public subnet
  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: 10.0.1.0/24
      MapPublicIpOnLaunch: true   # Security issue: auto-assigns public IPs

  # Security group — overly permissive
  WebServerSG:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Web server security group
      VpcId: !Ref LabVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0   # Security issue: SSH open to world
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: -1
          CidrIp: 0.0.0.0/0   # Security issue: all traffic open

  # S3 bucket — missing encryption and access logging
  AppBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'lab-app-bucket-${AWS::AccountId}'
      # Missing: BucketEncryption
      # Missing: LoggingConfiguration
      # Missing: VersioningConfiguration
      # Missing: PublicAccessBlockConfiguration
```

---

### Step 3 — Run Checkov and Review Findings (20 min)

```bash
cd week-2/labs
checkov -f vpc-insecure.yaml --framework cloudformation
```

Review the output. You should see failures including:
- `CKV_AWS_25` — unrestricted security group ingress
- `CKV_AWS_53` — S3 public access block not configured
- `CKV_AWS_19` — S3 default encryption not enabled
- `CKV_AWS_18` — S3 access logging not enabled
- `CKV_AWS_21` — S3 versioning not enabled

Note the check ID, the resource name, and the guideline URL Checkov provides for each failure.

---

### Step 4 — Fix the Template and Re-scan (20 min)

Create `week-2/labs/vpc-secure.yaml` with all findings resolved:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Security-hardened VPC template — passes Checkov checks

Resources:

  LabVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true

  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: 10.0.1.0/24
      MapPublicIpOnLaunch: false   # Fixed: no automatic public IPs

  WebServerSG:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Web server security group — port 80 only
      VpcId: !Ref LabVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0       # HTTP only — SSH removed
      SecurityGroupEgress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0       # HTTPS outbound only

  LoggingBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'lab-access-logs-${AWS::AccountId}'
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256

  AppBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'lab-app-bucket-${AWS::AccountId}'
      PublicAccessBlockConfiguration:        # Fixed
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      BucketEncryption:                      # Fixed
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      VersioningConfiguration:               # Fixed
        Status: Enabled
      LoggingConfiguration:                  # Fixed
        DestinationBucketName: !Ref LoggingBucket
        LogFilePrefix: app-bucket/
```

Re-run Checkov:
```bash
checkov -f vpc-secure.yaml --framework cloudformation
```

Target: zero failed checks. If any remain, read the Checkov output and fix them.

---

## ✅ Checklist

- [ ] Checkov installed and working (`checkov --version`)
- [ ] `vpc-insecure.yaml` created and scanned — findings documented
- [ ] `vpc-secure.yaml` created with all findings resolved
- [ ] Checkov passes clean on `vpc-secure.yaml`
- [ ] Screenshot: Checkov output showing failures on insecure template
- [ ] Screenshot: Checkov output showing all checks passed on secure template

**Portfolio commit:**
```bash
git add week-2/labs/vpc-insecure.yaml week-2/labs/vpc-secure.yaml screenshots/day-11-*.png
git commit -m "Day 11: Checkov IaC scanning — insecure template flagged, secure template passes all checks"
git push
```

---

## 📝 Quiz

→ [week-2/quiz/week-2-quiz.md](./quiz/week-2-quiz.md) — Question 7.

---

## 🧹 Cleanup

No AWS resources created today — the CloudFormation templates were only scanned locally, not deployed. Nothing to delete.
