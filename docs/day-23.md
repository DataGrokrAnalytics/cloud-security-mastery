# Day 23 — GuardDuty: Threat Intelligence & Behavioural Detection

**Week 4: Detection & Operations** | 4 hours | Difficulty: Intermediate

---

## 🎯 Objective

By the end of today you will have GuardDuty fully configured with threat intelligence feeds active, understand how it correlates CloudTrail, VPC Flow Logs, and DNS logs to detect attacker behaviour, and know how to interpret and respond to each finding type.

---

## 📖 Theory (2.5 hours)

### 1. What GuardDuty Actually Does

CloudTrail tells you what happened. GuardDuty tells you what it means.

GuardDuty is a managed threat detection service that continuously analyses three data sources using a combination of threat intelligence feeds and machine learning behavioural models:

- **CloudTrail management events** — API calls and console actions
- **VPC Flow Logs** — network connection metadata
- **Route 53 DNS query logs** — domain lookups from resources in your VPC

It correlates signals across all three to identify attacker behaviour patterns that no single source would reveal alone. An EC2 instance querying a known malicious domain (DNS) and then making outbound connections to an unusual IP (Flow Logs) while generating API calls that don't match its historical pattern (CloudTrail) — that combination is a GuardDuty finding.

---

### 2. GuardDuty Finding Categories

GuardDuty findings are organised into categories that map to MITRE ATT&CK:

**Backdoor** — Instance or container communicating with known command-and-control infrastructure. Example: `Backdoor:EC2/C&CActivity.B` — instance querying a domain associated with a botnet.

**CryptoCurrency** — Resource being used to mine cryptocurrency without authorisation. Example: `CryptoCurrency:EC2/BitcoinTool.B!DNS` — instance querying cryptocurrency mining pool domains.

**Pentest** — Activity that looks like security testing tools. Example: `PenTest:IAMUser/KaliLinux` — API calls made from a Kali Linux machine (detected by user-agent string).

**Persistence** — Attacker maintaining access. Example: `Persistence:IAMUser/UserCreation` — IAM user created by a principal that doesn't normally create users.

**Policy** — Security policy violation. Example: `Policy:S3/BucketPublicAccessGranted` — S3 bucket made public.

**Recon** — Discovery activity. Example: `Recon:EC2/PortProbeUnprotectedPort` — unusual port scanning against your instance.

**Stealth** — Attacker hiding their tracks. Example: `Stealth:IAMUser/CloudTrailLoggingDisabled` — CloudTrail logging stopped.

**Trojan** — Malware-related behaviour. Example: `Trojan:EC2/PhishingDomainRequest!DNS` — instance querying a known phishing domain.

**UnauthorizedAccess** — Credentials used unexpectedly. Example: `UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B` — console login from an unusual geography.

---

### 3. How GuardDuty Builds Behavioural Baselines

For ML-based detections, GuardDuty needs time to learn what "normal" looks like for your environment. It takes approximately 2 weeks to establish a baseline. During this period:

- It won't generate anomaly-based findings (no baseline to compare against)
- Threat-intelligence-based findings (known malicious IPs, domains) work immediately
- CIS-style rule-based findings work immediately

This is important for understanding finding absence: if GuardDuty is newly enabled and not generating findings, it doesn't mean your environment is secure — it may mean the baseline isn't established yet.

---

### 4. Responding to GuardDuty Findings

Every GuardDuty finding has a standard response workflow:

**Step 1 — Triage:** Is this a true positive or false positive? Review the finding details — the affected resource, the specific behaviour observed, timestamps, and the source/destination IPs or domains involved.

**Step 2 — Contain:** If a true positive, isolate the affected resource immediately. For EC2: move to an isolation security group with no inbound or outbound rules except to your forensics systems. For IAM: disable the credentials immediately.

**Step 3 — Investigate:** Use CloudTrail Logs Insights to reconstruct what happened before, during, and after the finding. What did the compromised identity access? What data was read or exfiltrated?

**Step 4 — Eradicate:** Remove the attacker's access and persistence mechanisms. Rotate all credentials that may have been exposed.

**Step 5 — Recover:** Restore normal operations from known-good state. Patch the vulnerability that allowed initial access.

**Step 6 — Document:** Write an incident report. What happened, what you did, and what you're changing to prevent recurrence.

---

### 5. GuardDuty Sample Findings

GuardDuty has a built-in feature to generate sample findings — synthetic examples of every finding type. This is the standard way to test your response pipelines without waiting for a real attack.

---

## 🔗 References

| Resource | URL |
|---|---|
| Amazon GuardDuty User Guide | https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html |
| GuardDuty Finding Types | https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-active.html |
| GuardDuty and MITRE ATT&CK | https://docs.aws.amazon.com/guardduty/latest/ug/guardduty-attack-sequences.html |
| NIST 800-61 Incident Response | https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final |

---

## 🛠️ Lab (1 hour)

### Step 1 — Enable GuardDuty (10 min)

1. AWS Console → **GuardDuty** → **Get started** → **Enable GuardDuty**
2. GuardDuty automatically begins ingesting CloudTrail, VPC Flow Logs, and DNS logs — no additional configuration needed for the core data sources.

Enable additional protection plans (some have cost):
- **S3 Protection** → **Enable** (free for 30 days, then charged per GB) — monitors S3 data plane events
- **EKS Protection** → skip unless you're running EKS
- **Malware Protection** → skip (scans EBS volumes — cost per GB)

```bash
# Confirm GuardDuty is enabled and note the detector ID
DETECTOR_ID=$(aws guardduty list-detectors --query "DetectorIds[0]" --output text)
echo "GuardDuty Detector ID: $DETECTOR_ID"

aws guardduty get-detector --detector-id "$DETECTOR_ID" \
  --query "[Status, FindingPublishingFrequency, UpdatedAt]" \
  --output table
```

---

### Step 2 — Generate Sample Findings (15 min)

Generate the full set of sample findings to understand what real findings look like:

```bash
DETECTOR_ID=$(aws guardduty list-detectors --query "DetectorIds[0]" --output text)

aws guardduty create-sample-findings \
  --detector-id "$DETECTOR_ID" \
  --finding-types \
    "Backdoor:EC2/C&CActivity.B" \
    "CryptoCurrency:EC2/BitcoinTool.B!DNS" \
    "Recon:EC2/PortProbeUnprotectedPort" \
    "UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B" \
    "Stealth:IAMUser/CloudTrailLoggingDisabled" \
    "Policy:S3/BucketPublicAccessGranted" \
    "Persistence:IAMUser/UserCreation"

echo "✅ Sample findings generated — check GuardDuty console in 1-2 minutes"
```

---

### Step 3 — Analyse Findings and Build a Response Table (35 min)

1. GuardDuty Console → **Findings**
2. Notice the **[SAMPLE]** prefix on each finding — these are synthetic
3. For each finding type, click in and record:
   - Finding type and severity
   - What the finding detected
   - Which resource is affected
   - The recommended action

Build your response playbook table in `portfolio/week-4/guardduty-response-playbook.md`:

```markdown
# GuardDuty Response Playbook

| Finding Type | Severity | What It Means | Immediate Action | Investigation Steps |
|---|---|---|---|---|
| Backdoor:EC2/C&CActivity.B | HIGH | Instance communicating with C2 infrastructure | Isolate instance (move to quarantine SG) | Review Flow Logs for data exfiltration, CloudTrail for lateral movement |
| CryptoCurrency:EC2/BitcoinTool.B!DNS | MEDIUM | Instance used for crypto mining | Terminate instance, check for persistence | Review when instance launched, who launched it, IAM role attached |
| Stealth:IAMUser/CloudTrailLoggingDisabled | HIGH | Attacker disabling audit trail | Re-enable CloudTrail immediately | Review who made the change, what else they did before disabling |
| UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B | MEDIUM | Login from unusual geography | Review session activity, rotate credentials | Check all actions taken during session |
| Policy:S3/BucketPublicAccessGranted | HIGH | S3 bucket exposed publicly | Make bucket private immediately | Identify what data was exposed, for how long |
| Persistence:IAMUser/UserCreation | MEDIUM | Suspicious IAM user creation | Review and delete if unauthorised | Check what permissions were granted |
| Recon:EC2/PortProbeUnprotectedPort | LOW | Port scanning against your instance | Check security group rules | Identify source IP, block if persistent |
```

4. Archive all sample findings after reviewing:
   - GuardDuty → select all findings → **Actions** → **Archive**

---

## ✅ Checklist

- [ ] GuardDuty enabled with S3 Protection active
- [ ] Detector ID noted
- [ ] 7 sample findings generated and reviewed
- [ ] Response playbook table created in portfolio
- [ ] Sample findings archived (not deleted — archived)
- [ ] Screenshot: GuardDuty findings dashboard with sample findings
- [ ] Screenshot: Individual finding detail (any one of the 7)

**Portfolio commit:**
```bash
git add portfolio/week-4/guardduty-response-playbook.md screenshots/day-23-*.png
git commit -m "Day 23: GuardDuty enabled, sample findings generated and analysed, response playbook created"
git push
```

---

## 📝 Quiz

→ [week-4/quiz/week-4-quiz.md](./quiz/week-4-quiz.md) — Questions 3 & 4.

---

## 🧹 Cleanup

Keep GuardDuty running — it's your primary runtime threat detection service and costs scale with data volume (typically <$5/month for a learning account). Disable it only if cost becomes a concern.
