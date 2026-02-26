# Day 19 — Container Security: ECR & ECS Fargate

**Week 3: Network & Data Protection** | 4 hours | Difficulty: Advanced

---

## 🎯 Objective

By the end of today you will understand the container security threat model, have an ECR repository with image scanning configured, and know how Fargate's architecture eliminates an entire class of container escape vulnerabilities.

---

## 📖 Theory (2.5 hours)

### 1. The Container Security Threat Model

Containers introduce security considerations that don't exist with traditional EC2 instances. The threat model has three layers:

**Image layer — what's baked into the container:**
- Vulnerable base image packages (covered by Inspector/Trivy scanning)
- Secrets hardcoded in the image (credentials, API keys left by developers)
- Unnecessary packages increasing attack surface
- Running as root inside the container (escalation risk if a breakout occurs)

**Runtime layer — what happens when the container runs:**
- Container escape: attacker breaks out of the container namespace into the host
- Privilege escalation: process inside container gains capabilities it shouldn't have
- Lateral movement: compromised container reaches other containers or the metadata service

**Orchestration layer — how containers are managed:**
- RBAC misconfigurations in ECS task roles or EKS RBAC
- Overly permissive task execution roles
- Secrets passed as environment variables instead of via Secrets Manager

---

### 2. Fargate vs. EC2 Launch Type

ECS can run containers in two modes:

**EC2 launch type:** You manage the EC2 instances that containers run on. You're responsible for patching the host OS, securing the container runtime, and managing the container agent. A container escape vulnerability could allow an attacker to reach the underlying EC2 instance and then pivot to other services.

**Fargate launch type:** AWS manages the underlying infrastructure entirely. You define the task (CPU, memory, image, networking) and AWS runs it on ephemeral, single-tenant microVMs. Key security properties:
- No host OS to patch — AWS handles it
- Each task runs on its own dedicated kernel (Firecracker microVM)
- No SSH access to the underlying host — no lateral movement path from container to host
- Immutable infrastructure — each task deployment is a fresh start

For this reason, Fargate is the preferred launch type for workloads where the application team doesn't want to manage container host security. The tradeoff is slightly less control and slightly higher cost per workload.

---

### 3. ECR Security Features

Amazon ECR (Elastic Container Registry) provides several security controls:

**Image scanning:**
- **Basic scanning:** Uses open-source Clair scanner, scans on push
- **Enhanced scanning:** Uses Amazon Inspector, continuous re-evaluation as new CVEs emerge

**Lifecycle policies:** Automatically delete old or untagged images, reducing the attack surface from vulnerable legacy images sitting in your registry.

**Immutable tags:** Once an image is pushed with a tag (e.g., `v1.2.3`), that tag cannot be overwritten. Prevents tag hijacking where an attacker replaces a trusted image tag with a malicious one.

**Cross-account access:** Repository policies control which AWS accounts can push or pull images. Use resource-based policies to restrict access to your own accounts only.

---

### 4. ECS Task Roles — Least Privilege for Containers

Every ECS task can have an IAM role (the task role) that defines what AWS services the container can access. This is the IAM for containers equivalent of the EC2 instance profile.

Common mistakes:
- Using the task execution role (which handles ECR pull and CloudWatch logs) as the task role — gives the application unnecessary permissions
- Attaching AdministratorAccess to the task role "to make it easier"
- Sharing one task role across multiple applications with different permission needs

The correct pattern: one task role per application with only the specific permissions that application needs. An order processing container needs DynamoDB read/write on the orders table. It doesn't need S3, SQS, or any other service.

---

## 🔗 References

| Resource | URL |
|---|---|
| Amazon ECR User Guide | https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html |
| Amazon ECS Security | https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/security.html |
| AWS Fargate Security | https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/security-fargate.html |
| Docker Security Best Practices | https://docs.docker.com/develop/security-best-practices/ |

---

## 🛠️ Lab (1 hour)

### Step 1 — Create a Hardened ECR Repository (10 min)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

aws ecr create-repository \
  --repository-name lab-secure-app \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability IMMUTABLE \
  --encryption-configuration encryptionType=KMS \
  --region "$REGION"

echo "✅ ECR repository created with:"
echo "   - Scan on push: enabled"
echo "   - Immutable tags: enabled"
echo "   - Encryption: KMS"
```

---

### Step 2 — Build and Scan a Container Image (30 min)

Create a minimal application Dockerfile:

```bash
mkdir -p /tmp/lab-app
cat > /tmp/lab-app/Dockerfile << 'EOF'
# Use a specific pinned version — never use :latest in production
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# Run as non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Install only what's needed
RUN yum update -y && \
    yum install -y python3 && \
    yum clean all && \
    rm -rf /var/cache/yum

WORKDIR /app

# Copy application files
COPY app.py .

# Set ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose specific port only
EXPOSE 8080

CMD ["python3", "app.py"]
EOF

cat > /tmp/lab-app/app.py << 'EOF'
# Minimal Python HTTP server — lab demo only
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"status": "ok"}).encode())
    def log_message(self, format, *args):
        pass  # suppress access logs in demo

if __name__ == '__main__':
    HTTPServer(('0.0.0.0', 8080), Handler).serve_forever()
EOF
```

Build and push the image:
```bash
cd /tmp/lab-app

# Authenticate Docker to ECR
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS \
  --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Build the image
docker build -t lab-secure-app .

# Tag and push
docker tag lab-secure-app:latest \
  "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/lab-secure-app:v1.0.0"

docker push \
  "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/lab-secure-app:v1.0.0"

echo "✅ Image pushed — Inspector will scan automatically"
```

> **Note:** Docker must be installed locally for this step. If Docker isn't available, go straight to Step 3 and review the scan results for the `lab-test-repo` image from Day 18 instead.

---

### Step 3 — Review Image Scan Results (20 min)

1. ECR Console → **Repositories** → `lab-secure-app` → **Images**
2. Click the image → **Vulnerabilities** tab
3. Review findings by severity — note:
   - Total count by severity
   - Any Critical or High CVEs
   - Which packages the vulnerabilities are in

4. Inspector Console → **Findings** → filter by **Resource type: ECR container image**
5. Compare the finding counts and scores against your EC2 findings from Day 18

**Document the security decisions in your Dockerfile:**

| Decision | Security Reason |
|---|---|
| Pinned base image version | Prevents unexpected changes from `:latest` tag |
| Non-root user | Limits blast radius if container is compromised |
| `yum clean all` | Reduces image size and removes package manager cache |
| Specific EXPOSE port | Documents intended network exposure |

---

## ✅ Checklist

- [ ] ECR repository created with scan-on-push, immutable tags, KMS encryption
- [ ] Dockerfile created with non-root user and pinned base image
- [ ] Image built and pushed to ECR
- [ ] Image scan results reviewed (or Day 18 repo scan reviewed if Docker unavailable)
- [ ] Security decisions in Dockerfile documented
- [ ] Screenshot: ECR repository settings (immutable tags, scan on push)
- [ ] Screenshot: Image vulnerability scan results

**Portfolio commit:**
```bash
git add screenshots/day-19-*.png
git commit -m "Day 19: ECR with immutable tags + KMS, Dockerfile with non-root user, image scan results reviewed"
git push
```

---

## 📝 Quiz

→ [week-3/quiz/week-3-quiz.md](./quiz/week-3-quiz.md) — Question 7.

---

## 🧹 Cleanup

The ECR repository has a small storage cost ($0.10/GB/month). Delete the image after the lab if you want to minimise cost:

```bash
aws ecr batch-delete-image \
  --repository-name lab-secure-app \
  --image-ids imageTag=v1.0.0
```

Keep the repository itself — Day 20 references it for EKS context.
