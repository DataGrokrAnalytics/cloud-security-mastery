# Week 4 Quiz — Detection & Operations

Answer from memory first. The answer key is at the bottom — no peeking until you've tried all 10.

---

## Questions

**Q1.** CloudTrail is enabled in your account. An attacker compromises an IAM user, performs several actions, then deletes the CloudTrail trail to cover their tracks. CIS alarm 4.5 fires immediately. What does this tell you about your log integrity, and what should you do first?

- A) Log integrity is compromised — all logs from before the deletion are unreliable
- B) Log integrity is intact — log file validation generates signed digests independently of the trail; the attacker's actions are preserved. First action: re-enable CloudTrail immediately
- C) Log integrity is unknown — you must contact AWS Support to retrieve the deleted logs
- D) Log integrity is intact, but only if the S3 bucket was also deleted

---

**Q2.** You have a CloudWatch metric filter that fires when CloudTrail detects `ConsoleLogin` events without MFA. You receive 40 alerts in 10 minutes all from the same IAM user. What is the most likely explanation and correct immediate action?

- A) The user is attempting to log in without MFA — send a reminder email about MFA policy
- B) This looks like a credential stuffing or brute-force attack — disable the user's credentials immediately and investigate the source IPs
- C) CloudWatch is generating false positives — adjust the threshold to reduce noise
- D) The user has a broken MFA device — reset their MFA configuration

---

**Q3.** GuardDuty generates a `Stealth:IAMUser/CloudTrailLoggingDisabled` finding at 2:47 AM. What is the significance of the timing, and what does the finding tell you?

- A) The timing is not significant — GuardDuty fires at random intervals
- B) After-hours activity on a sensitive action (disabling your audit trail) is a strong indicator of an attacker covering their tracks — treat this as a likely true positive and respond immediately
- C) This is almost certainly a scheduled maintenance task — investigate during business hours
- D) GuardDuty generates this finding whenever CloudTrail experiences any error

---

**Q4.** GuardDuty has been enabled for 3 days and is generating zero findings. What is the most likely reason, and what should you verify?

- A) Your environment is secure — zero findings means zero threats
- B) GuardDuty needs approximately 2 weeks to establish ML baselines for anomaly detection. Verify that threat-intelligence findings are working by generating sample findings
- C) GuardDuty requires manual configuration to start scanning — check if data sources are enabled
- D) Zero findings after 3 days indicates GuardDuty is not receiving data — re-enable it

---

**Q5.** Security Hub shows a finding from GuardDuty and a separate finding from Inspector on the same EC2 instance. The GuardDuty finding is MEDIUM severity (unusual network connection) and the Inspector finding is HIGH (critical CVE with known exploit). How should you prioritise?

- A) GuardDuty MEDIUM first — active threat takes priority over a potential vulnerability
- B) Inspector HIGH first — a known CVE is more actionable than a behavioural finding
- C) Treat them as a combined signal requiring urgent response — an instance with a known exploitable CVE that is also behaving anomalously is likely already compromised
- D) Escalate both to the vendor since Security Hub can't resolve findings itself

---

**Q6.** You're applying STRIDE to an API Gateway endpoint that accepts customer orders. Which STRIDE threat is most directly addressed by requiring a JWT token with a 1-hour expiry for every request?

- A) Tampering — JWTs prevent request modification
- B) Repudiation — JWTs log who made each request
- C) Spoofing — JWTs verify the identity of the requester and expire quickly to limit stolen token reuse
- D) Denial of Service — JWTs limit the number of requests per user

---

**Q7.** In your threat model, you identify that a compromised EC2 instance in the private subnet could reach your database on port 5432. Your current control is the database security group allowing port 5432 only from the private subnet's security group. A colleague suggests this residual risk is acceptable. What argument supports their position?

- A) Network controls are sufficient — there is no residual risk
- B) The attacker still needs valid database credentials (a separate control layer), and any connection attempt would appear in VPC Flow Logs and potentially trigger GuardDuty — the residual risk is mitigated by compensating controls
- C) Databases are always low risk because they are not internet-facing
- D) Security groups are managed by AWS, so the risk is on AWS's side of the responsibility model

---

**Q8.** Your SOAR Lambda is triggered by EventBridge when Security Hub generates an S3.2 finding (public bucket). The Lambda runs twice within 30 seconds for the same finding (EventBridge at-least-once delivery). What prevents the second execution from causing an error or double-remediation?

- A) EventBridge deduplicates events — the Lambda only runs once
- B) Lambda automatically detects duplicate invocations using the request ID
- C) The Lambda checks the current bucket state before acting — if the bucket is already private (from the first execution), it exits cleanly without error
- D) Security Hub marks the finding as RESOLVED after the first execution, which prevents EventBridge from routing it again

---

**Q9.** A ScoutSuite assessment identifies that an S3 bucket has server access logging disabled. This finding doesn't appear in Security Hub. What is the most likely explanation?

- A) ScoutSuite is incorrect — Security Hub would always detect this
- B) Security Hub has a Config rule for this finding but it hasn't evaluated yet
- C) ScoutSuite checks security properties that don't map to active Config rules or Security Hub controls in your configuration — external tools often surface findings that native tooling misses
- D) The S3 bucket is in a different region where Security Hub is not enabled

---

**Q10.** You're briefing your CISO on the security programme you've built. They ask: "What's our Mean Time to Respond to a public S3 bucket?" What is the correct answer given the SOAR pipeline you built on Day 26?

- A) Approximately 4 hours — the standard SLA for HIGH severity findings
- B) Under 30 seconds — the EventBridge rule routes the Security Hub finding to the Lambda within seconds, and the Lambda applies the fix automatically
- C) 15 minutes — the time for a human to review the GuardDuty finding and act
- D) 24 hours — Security Hub batches findings for daily review

---
---

# ✅ Answer Key

*Only read this after attempting all 10 questions.*

---

**Q1 — Answer: B**

CloudTrail log file validation generates SHA-256 hash digests for each hour of logs, stored in a separate S3 location with a hash chain linking them. Deleting the trail stops new logs from being written, but it does not delete or invalidate the existing digest files or log files already in S3. An investigator can still validate the integrity of all logs generated before the deletion. The first action is to re-enable CloudTrail immediately, then use the existing logs to reconstruct the attacker's actions before they went dark.

---

**Q2 — Answer: B**

40 failed or non-MFA console login attempts in 10 minutes from a single user is classic credential stuffing — an automated attack trying known username/password combinations from a breach database. The correct immediate response is containment first: disable the credentials to stop the attack. Then investigate the source IPs, determine whether any login succeeded, and check what actions were taken during any successful session. Sending a reminder email (A) is wildly inadequate for an active attack.

---

**Q3 — Answer: B**

After-hours activity is a meaningful signal when combined with a sensitive action. Disabling your audit trail is not a routine operation — there is almost no legitimate business reason to do this at 2:47 AM. The combination of unusual timing + audit trail disruption is a high-confidence indicator of an attacker attempting to cover their tracks. NIST 800-61 advises treating this as a Preparation/Containment priority — re-enable CloudTrail immediately, then begin incident investigation to understand what happened before the logging stopped.

---

**Q4 — Answer: B**

GuardDuty's ML-based detections require approximately 2 weeks of data to establish what "normal" looks like for your specific environment — API call patterns, connection behaviour, DNS queries. During this period, threat-intelligence-based findings (known malicious IPs and domains) still work immediately. The right validation step is to generate sample findings (as you did on Day 23) to confirm the pipeline is working end-to-end even if real anomaly findings aren't appearing yet.

---

**Q5 — Answer: C**

This is the most important insight in CNAPP thinking: correlated findings on the same resource create a combined signal that's greater than either finding alone. An EC2 instance with a known exploitable CVE (Inspector HIGH) that is also making unusual network connections (GuardDuty MEDIUM) is a strong indicator of active exploitation. The CVE is likely the entry point; the anomalous connection is the attacker's C2 or exfiltration traffic. Treat this as a likely active compromise — isolate the instance, begin investigation, rotate any credentials the instance had access to.

---

**Q6 — Answer: C**

Requiring authentication tokens directly addresses Spoofing — the threat that an attacker can impersonate a legitimate user. A JWT proves the requester's identity at the time of the request. The 1-hour expiry limits the window of usefulness if a token is stolen (compared to a long-lived API key that works indefinitely). Short-lived tokens are the JWT equivalent of JIT access for API requests.

---

**Q7 — Answer: B**

This is what defence in depth means in practice. The network control (security group) limits which instances can attempt a connection. But a successful attack still requires valid database credentials — which are stored in Secrets Manager, rotated automatically, and only accessible to specific IAM roles. Additionally, any connection attempt from a compromised instance would generate VPC Flow Log entries, and unusual connection patterns might trigger GuardDuty. The residual risk exists, but it's mitigated by multiple independent controls that must all fail for a breach to succeed.

---

**Q8 — Answer: C**

The Lambda is idempotent — it checks the current state of the bucket before taking any action. If the first execution already enabled block public access, the second execution checks the current state, finds it already compliant, logs "no action needed," and exits cleanly. This is the critical design principle for any automation that modifies infrastructure: always check current state, never assume the previous state. EventBridge (A) does not deduplicate. Lambda request ID (B) is not checked automatically by the runtime.

---

**Q9 — Answer: C**

This is exactly the value of external assessment tools like ScoutSuite. Native AWS security services check for compliance against their configured rules and standards. If you haven't enabled a specific Config rule, or if Security Hub doesn't have a control for a particular property, it won't flag it. ScoutSuite maintains its own independent ruleset based on security community best practices, which overlaps with but is not identical to AWS's native checks. Running external tools periodically catches the gaps in your native tooling coverage.

---

**Q10 — Answer: B**

The SOAR pipeline you built on Day 26 creates a direct path from finding to remediation with no human in the loop: Security Hub generates the S3.2 finding → EventBridge routes it to the Lambda within seconds → Lambda enables block public access → Lambda updates the Security Hub finding to RESOLVED. The total time from the public bucket existing to it being private is under 30 seconds. This is the metric to cite: "For this specific finding type, our MTTR is under 30 seconds — fully automated." This is the business value of SOAR expressed as a concrete number.
