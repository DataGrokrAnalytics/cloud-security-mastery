# Day 12 — Privileged Access: Bastion Hosts & Session Manager

**Week 2: Zero Trust Identity** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will understand why traditional SSH bastion hosts are a security liability, have AWS Systems Manager Session Manager configured as a secure replacement, and understand the Privileged Access Workstation (PAW) model for protecting administrative access.

---

## 📖 Theory (2.5 hours)

### 1. The Problem with Traditional SSH Bastion Hosts

A bastion host is an EC2 instance placed in a public subnet that developers SSH into as a jumping point to reach instances in private subnets. It's been the standard pattern for years.

The problem is that this model has significant security weaknesses:

**SSH key management is a nightmare at scale.** Each developer has a key pair. Keys get copied to laptops, shared via Slack, forgotten on old machines, never rotated. When someone leaves the team, their key often remains active. There's no central audit log of who connected when and what they did.

**The bastion itself is an internet-facing attack surface.** Port 22 must be open to the internet (or to a VPN). Brute-force attacks are constant. If the bastion is misconfigured — wrong AMI, unpatched OS, overly broad security group — it becomes the entry point for a breach.

**There's no session recording.** You know someone SSH'd in, but you have no record of what commands they ran.

---

### 2. AWS Systems Manager Session Manager

Session Manager solves every one of these problems:

| Problem | Session Manager Solution |
|---|---|
| SSH key management | No SSH keys required — access via IAM identity |
| Open port 22 | No inbound ports required on the instance |
| Bastion attack surface | No bastion host required |
| No session recording | All sessions logged to CloudTrail + optional S3/CloudWatch |
| Access revocation | Revoke IAM permission instantly |

**How it works:**
The SSM Agent runs on your EC2 instance (pre-installed on AWS AMIs). It maintains an outbound connection to the SSM service. When you start a session, SSM proxies your connection through that outbound channel — no inbound ports needed.

Access is controlled entirely by IAM: attach the `AmazonSSMManagedInstanceCore` policy to the instance's IAM role, and grant `ssm:StartSession` to the user's IAM policy. Start and end of every session is recorded in CloudTrail.

---

### 3. The Privileged Access Workstation (PAW) Model

A Privileged Access Workstation is a dedicated device used exclusively for sensitive administrative tasks. The principle: your daily-use laptop (email, Slack, web browsing) is constantly exposed to phishing, malware, and credential theft. Using that same device to administer production infrastructure is a significant risk.

The PAW model separates these concerns:

```
Daily-use device     →  Email, Slack, browsing, development
                         (compromised frequently)

Privileged device    →  AWS console admin actions, production SSH/SSM
                         (hardened, isolated, rarely compromised)
```

In practice, not every team can justify a dedicated physical PAW for every admin. A pragmatic alternative for smaller teams:

- Use a dedicated browser profile for AWS console work (separate from your daily browsing)
- Use MFA for every console session
- Never do admin work from a device that doesn't have endpoint security (AV, EDR)
- Never store AWS credentials in your browser or in plaintext files

Session Manager + IAM MFA enforcement is the AWS-native implementation of PAW principles — it ensures admin access always requires a verified identity with MFA, regardless of what device is being used.

---

### 4. Enforcing MFA for Session Manager

You can require MFA before any Session Manager session is allowed using an IAM condition:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ssm:StartSession",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```

With this policy, a user without MFA on their session cannot start a Session Manager session — even if they have valid AWS credentials.

---

## 🔗 References

| Resource | URL |
|---|---|
| AWS Systems Manager Session Manager | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html |
| Session Manager Prerequisites | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-prerequisites.html |
| Session Manager CloudTrail Logging | https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-auditing.html |
| IAM MFA Conditions | https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_configure-api-require.html |

---

## 🛠️ Lab (1 hour)

### Step 1 — Create an IAM Role for SSM-Managed EC2 (10 min)

1. IAM → **Roles** → **Create role**
2. Trusted entity: **AWS service** → **EC2**
3. Attach policy: `AmazonSSMManagedInstanceCore`
4. Role name: `EC2-SSM-Role`
5. **Create role**

This role gives EC2 instances permission to communicate with the SSM service — the prerequisite for Session Manager.

---

### Step 2 — Launch an EC2 Instance with the SSM Role (20 min)

1. EC2 → **Launch instance**
2. Name: `ssm-lab-instance`
3. AMI: **Amazon Linux 2023** (SSM Agent pre-installed)
4. Instance type: `t2.micro` (Free Tier)
5. **Key pair**: Select **Proceed without a key pair** — you won't need SSH
6. Network settings:
   - VPC: default VPC
   - Subnet: any public subnet
   - Auto-assign public IP: **Disable** (you don't need a public IP for SSM)
   - Security group: Create a new security group with **no inbound rules**
     - Name: `ssm-no-inbound`
     - Remove the default SSH rule — leave it completely empty
7. Advanced details → IAM instance profile: **EC2-SSM-Role**
8. **Launch instance**

Wait 2–3 minutes for the instance to initialise and register with SSM.

---

### Step 3 — Connect via Session Manager (15 min)

1. EC2 → Instances → select `ssm-lab-instance` → **Connect**
2. Choose **Session Manager** tab → **Connect**
3. A browser-based terminal opens — no SSH key, no open port 22

Run a few commands to confirm it works:
```bash
whoami
pwd
cat /etc/os-release
```

4. Check CloudTrail to confirm the session was logged:
   - CloudTrail → **Event history** → filter by **Event name: StartSession**
   - You should see your session start event with your IAM identity

---

### Step 4 — Compare Security Group (5 min)

Go to EC2 → Security Groups → find `ssm-no-inbound`. Confirm:
- **Inbound rules:** Empty — no rules at all
- **Outbound rules:** Default (allow all outbound)

Screenshot this alongside your active Session Manager connection. This is the key portfolio artifact: proof that you're connected to an instance with **zero open inbound ports**.

---

## ✅ Checklist

- [ ] `EC2-SSM-Role` IAM role created with `AmazonSSMManagedInstanceCore`
- [ ] EC2 instance launched with no key pair and no inbound security group rules
- [ ] Session Manager connection successful (browser terminal works)
- [ ] CloudTrail shows StartSession event with your IAM identity
- [ ] Screenshot: Security group with zero inbound rules + active Session Manager session
- [ ] Screenshot: CloudTrail StartSession event

**Portfolio commit:**
```bash
git add screenshots/day-12-*.png
git commit -m "Day 12: Session Manager configured — EC2 access with zero open ports, session logged to CloudTrail"
git push
```

---

## 📝 Quiz

→ [week-2/quiz/week-2-quiz.md](./quiz/week-2-quiz.md) — Question 8.

---

## 🧹 Cleanup

Stop the EC2 instance after the lab — a stopped t2.micro doesn't incur compute charges (only EBS storage, which is within Free Tier).

```bash
aws ec2 stop-instances --instance-ids YOUR-INSTANCE-ID
```

You'll terminate it on Day 14's cleanup.
