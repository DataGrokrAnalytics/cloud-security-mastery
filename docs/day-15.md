# Day 15 — VPC Network Foundation

**Week 3: Network & Data Protection** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will have a production-grade 3-tier VPC running in your account — public, private, and database subnets, properly segmented with security groups and NACLs — and understand how each layer defends against lateral movement.

---

## 📖 Theory (2.5 hours)

### 1. Why Network Segmentation Still Matters in Cloud

Week 2 established that identity is the primary security boundary in cloud. That's true — but it doesn't mean networking is irrelevant. Network segmentation is a defence-in-depth layer: if an attacker compromises a frontend instance, segmentation limits how far they can move from there.

Without segmentation, a compromised web server has network-level access to your database. With segmentation, a compromised web server can only reach services it's explicitly permitted to reach — and your database sits in a subnet with no route to the internet at all.

The goal is to make lateral movement expensive. Every additional barrier an attacker has to cross increases the chance of detection and the time needed to reach sensitive data.

---

### 2. VPC Architecture — The 3-Tier Model

The standard production VPC pattern separates resources into three tiers by trust level:

```
Internet
    │
    ▼
┌─────────────────────────────────────────────┐
│  PUBLIC SUBNET (10.0.1.0/24)                │
│  • Load balancers, NAT Gateway              │
│  • Has route to Internet Gateway            │
│  • Minimum resources here                  │
└─────────────────────┬───────────────────────┘
                      │ (restricted ports only)
┌─────────────────────▼───────────────────────┐
│  PRIVATE SUBNET (10.0.2.0/24)               │
│  • Application servers, Lambda, ECS         │
│  • Route to internet via NAT Gateway only   │
│  • No inbound from internet                 │
└─────────────────────┬───────────────────────┘
                      │ (DB port only)
┌─────────────────────▼───────────────────────┐
│  DATABASE SUBNET (10.0.3.0/24)              │
│  • RDS, ElastiCache, OpenSearch             │
│  • No route to internet at all              │
│  • Only reachable from private subnet       │
└─────────────────────────────────────────────┘
```

Each tier has a purpose, and the security group rules enforce the intended communication paths between them.

---

### 3. Security Groups vs. NACLs

Both control network traffic in a VPC, but they work differently and serve different purposes:

| | Security Groups | NACLs |
|---|---|---|
| Attachment | Resource (ENI level) | Subnet level |
| State | **Stateful** — return traffic allowed automatically | **Stateless** — must explicitly allow both directions |
| Rules | Allow only (implicit deny all) | Allow and Deny |
| Evaluation | All rules evaluated | Rules evaluated in order (lowest number first) |
| Best for | Primary resource-level firewall | Subnet-level emergency blocks |

**Security groups are your primary control.** They're stateful, easy to reason about, and apply at the resource level. Use them to define exactly which ports each tier accepts from which other tier.

**NACLs are your secondary control.** Because they're stateless, they're more complex — you must explicitly allow both the inbound request and the outbound response. They're most useful for emergency broad blocks (e.g., blocking a specific IP range that's attacking you) or adding a subnet-level defence in regulated environments.

---

### 4. The Flow Log — Your Network Audit Trail

VPC Flow Logs capture metadata about every network connection in your VPC: source IP, destination IP, port, protocol, bytes transferred, and whether the packet was accepted or rejected.

Flow logs don't capture packet content — they're connection metadata, not a full packet capture. But for security analysis this is usually sufficient: you can answer "did this resource make a connection to an unusual IP?" and "how many bytes were transferred?" without reading the data itself.

Flow logs feed into GuardDuty (Week 4) which uses machine learning to detect unusual connection patterns. Without flow logs, GuardDuty has no network visibility.

---

### 5. MITRE ATT&CK — Lateral Movement (TA0008)

MITRE ATT&CK's Lateral Movement tactic covers how attackers move through a network after gaining initial access. In cloud environments, the most common techniques are:

- **T1021.004 — Remote Services: SSH:** Attacker uses compromised credentials to SSH from one instance to another
- **T1550.001 — Use Alternate Authentication Material:** Attacker uses a stolen IAM role to access other services
- **T1210 — Exploitation of Remote Services:** Attacker exploits a vulnerability in a service reachable from the compromised instance

Network segmentation directly addresses T1021 and T1210 — if the compromised instance can't reach other services on those ports, these techniques fail at the network layer.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS VPC User Guide | https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html |
| VPC Security Best Practices | https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html |
| VPC Flow Logs | https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html |
| MITRE ATT&CK Lateral Movement | https://attack.mitre.org/tactics/TA0008/ |

---

## 🛠️ Lab (1 hour)

### Step 1 — Deploy the VPC via CloudFormation (20 min)

Create `week-3/labs/vpc-3tier.yaml` and deploy it. This template creates the full 3-tier VPC with flow logs enabled.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 3-tier production VPC with flow logs — Week 3 Day 15

Parameters:
  VpcCidr:
    Type: String
    Default: 10.0.0.0/16

Resources:

  # ── VPC ────────────────────────────────────────────────────────────────────
  LabVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: lab-vpc

  # ── Internet Gateway ───────────────────────────────────────────────────────
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: lab-igw

  IGWAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref LabVPC
      InternetGatewayId: !Ref InternetGateway

  # ── Subnets ────────────────────────────────────────────────────────────────
  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: lab-public-subnet

  PrivateSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: lab-private-subnet

  DatabaseSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref LabVPC
      CidrBlock: 10.0.3.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: lab-database-subnet

  # ── Route Tables ───────────────────────────────────────────────────────────
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: lab-public-rt

  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: IGWAttachment
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnetRTAssoc:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet
      RouteTableId: !Ref PublicRouteTable

  PrivateRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: lab-private-rt

  PrivateSubnetRTAssoc:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PrivateSubnet
      RouteTableId: !Ref PrivateRouteTable

  DatabaseRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref LabVPC
      Tags:
        - Key: Name
          Value: lab-database-rt

  DatabaseSubnetRTAssoc:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref DatabaseSubnet
      RouteTableId: !Ref DatabaseRouteTable

  # ── Security Groups ────────────────────────────────────────────────────────
  PublicSG:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Public tier — HTTPS inbound from internet only
      VpcId: !Ref LabVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
          Description: HTTPS from internet
      SecurityGroupEgress:
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          DestinationSecurityGroupId: !Ref PrivateSG
          Description: Forward to app tier
      Tags:
        - Key: Name
          Value: lab-public-sg

  PrivateSG:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Private tier — port 8080 from public tier only
      VpcId: !Ref LabVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          SourceSecurityGroupId: !Ref PublicSG
          Description: From public tier only
      SecurityGroupEgress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          DestinationSecurityGroupId: !Ref DatabaseSG
          Description: PostgreSQL to database tier
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
          Description: HTTPS outbound for AWS API calls
      Tags:
        - Key: Name
          Value: lab-private-sg

  DatabaseSG:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Database tier — PostgreSQL from private tier only
      VpcId: !Ref LabVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref PrivateSG
          Description: PostgreSQL from app tier only
      Tags:
        - Key: Name
          Value: lab-database-sg

  # ── VPC Flow Logs ──────────────────────────────────────────────────────────
  FlowLogBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'vpc-flow-logs-${AWS::AccountId}-${AWS::Region}'
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      LifecycleConfiguration:
        Rules:
          - Id: DeleteOldLogs
            Status: Enabled
            ExpirationInDays: 90

  VPCFlowLog:
    Type: AWS::EC2::FlowLog
    Properties:
      ResourceId: !Ref LabVPC
      ResourceType: VPC
      TrafficType: ALL
      LogDestinationType: s3
      LogDestination: !GetAtt FlowLogBucket.Arn
      Tags:
        - Key: Name
          Value: lab-vpc-flowlog

Outputs:
  VPCId:
    Value: !Ref LabVPC
    Description: VPC ID
  PublicSubnetId:
    Value: !Ref PublicSubnet
  PrivateSubnetId:
    Value: !Ref PrivateSubnet
  DatabaseSubnetId:
    Value: !Ref DatabaseSubnet
```

Deploy it:
```bash
aws cloudformation deploy \
  --template-file week-3/labs/vpc-3tier.yaml \
  --stack-name lab-vpc-week3 \
  --capabilities CAPABILITY_IAM
```

---

### Step 2 — Verify the Architecture (25 min)

1. VPC Console → **Your VPCs** → confirm `lab-vpc` exists
2. **Subnets** → confirm all 3 subnets (public, private, database)
3. **Route Tables** → verify:
   - Public RT has route `0.0.0.0/0 → igw-xxx`
   - Private RT has no internet route (only local)
   - Database RT has no internet route (only local)
4. **Security Groups** → click `lab-database-sg` → **Inbound rules**
   - Confirm: only port 5432 from `lab-private-sg` — no internet access at all
5. **Flow Logs** → VPC → your VPC → **Flow logs** tab → confirm status Active

---

### Step 3 — Run Checkov on the Template (15 min)

```bash
checkov -f week-3/labs/vpc-3tier.yaml --framework cloudformation
```

Review any findings and note them in your portfolio. Some findings (like requiring a NAT Gateway for private subnet internet access) are valid for production but skipped here to stay in Free Tier.

---

## ✅ Checklist

- [ ] `vpc-3tier.yaml` CloudFormation template created
- [ ] Stack deployed successfully
- [ ] All 3 subnets visible in VPC console
- [ ] Database security group has zero internet-facing rules
- [ ] VPC Flow Logs active and writing to S3
- [ ] Checkov output reviewed
- [ ] Screenshot: Route table showing database subnet has no internet route
- [ ] Screenshot: Database SG inbound rules (port 5432 from private SG only)

**Portfolio commit:**
```bash
git add week-3/labs/vpc-3tier.yaml screenshots/day-15-*.png
git commit -m "Day 15: 3-tier VPC deployed — public/private/database segmentation with flow logs"
git push
```

---

## 📝 Quiz

→ [week-3/quiz/week-3-quiz.md](./quiz/week-3-quiz.md) — Questions 1 & 2.

---

## 🧹 Cleanup

Keep the VPC stack running — you'll use it on Days 16, 17, and 18. It costs nothing while empty (no NAT Gateway deployed).
