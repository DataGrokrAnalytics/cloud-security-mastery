"""
SOAR Auto-Remediation: S3 Public Access
========================================
Triggered by:  EventBridge rule matching Security Hub S3.2 findings
               (S3 buckets with public read or public ACL)

Actions:
  1. Enable block public access on the affected S3 bucket (idempotent)
  2. Update the Security Hub finding workflow status to RESOLVED
  3. Publish an SNS notification with remediation details

Environment variables required:
  SNS_TOPIC_ARN  — ARN of the SNS topic to notify (from Day 6 setup)

IAM permissions required (SOARRemediationRole):
  s3:GetBucketPublicAccessBlock
  s3:PutPublicAccessBlock
  securityhub:BatchUpdateFindings
  sns:Publish
  logs:CreateLogGroup / logs:CreateLogStream / logs:PutLogEvents

Design principles:
  - Idempotent: safe to run multiple times on the same resource
  - Least privilege: role scoped to only what this function needs
  - Observable: structured logging to CloudWatch, finding update in Security Hub
"""

import boto3
import json
import os
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')
securityhub = boto3.client('securityhub')
sns = boto3.client('sns')

SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    findings = event.get('detail', {}).get('findings', [])
    if not findings:
        logger.warning("No findings in event — nothing to process")
        return {'statusCode': 200, 'body': 'No findings'}

    results = []
    for finding in findings:
        result = process_finding(finding)
        results.append(result)

    return {'statusCode': 200, 'body': json.dumps(results)}


def process_finding(finding):
    finding_id = finding.get('Id', 'unknown')
    product_arn = finding.get('ProductArn', '')
    resources = finding.get('Resources', [])

    logger.info("Processing finding: %s", finding_id)

    # Extract S3 bucket name from the affected resource ARN
    bucket_name = None
    for resource in resources:
        if resource.get('Type') == 'AwsS3Bucket':
            arn = resource.get('Id', '')
            bucket_name = arn.split(':::')[-1]
            break

    if not bucket_name:
        logger.warning("No S3 bucket found in finding resources")
        return {'finding_id': finding_id, 'status': 'skipped', 'reason': 'no S3 resource'}

    # ── Remediation (idempotent) ──────────────────────────────────────────────
    remediated = False
    try:
        try:
            current = s3.get_public_access_block(Bucket=bucket_name)
            cfg = current.get('PublicAccessBlockConfiguration', {})
            already_private = all([
                cfg.get('BlockPublicAcls', False),
                cfg.get('BlockPublicPolicy', False),
                cfg.get('IgnorePublicAcls', False),
                cfg.get('RestrictPublicBuckets', False),
            ])
        except s3.exceptions.NoSuchPublicAccessBlockConfiguration:
            already_private = False

        if already_private:
            logger.info("Bucket %s is already private — idempotent exit", bucket_name)
        else:
            s3.put_public_access_block(
                Bucket=bucket_name,
                PublicAccessBlockConfiguration={
                    'BlockPublicAcls': True,
                    'IgnorePublicAcls': True,
                    'BlockPublicPolicy': True,
                    'RestrictPublicBuckets': True,
                }
            )
            logger.info("✅ Remediated: %s — block public access enabled", bucket_name)
            remediated = True

    except Exception as e:
        logger.error("Failed to remediate %s: %s", bucket_name, str(e))
        return {'finding_id': finding_id, 'bucket': bucket_name,
                'status': 'error', 'error': str(e)}

    # ── Update Security Hub finding ───────────────────────────────────────────
    try:
        securityhub.batch_update_findings(
            FindingIdentifiers=[{'Id': finding_id, 'ProductArn': product_arn}],
            Workflow={'Status': 'RESOLVED' if remediated else 'NOTIFIED'},
            Note={
                'Text': (
                    f'Auto-remediated by SOAR Lambda at '
                    f'{datetime.now(timezone.utc).isoformat()}. '
                    f'Block public access {"enabled on" if remediated else "already set on"} '
                    f'{bucket_name}.'
                ),
                'UpdatedBy': 'SOARRemediationLambda'
            }
        )
        logger.info("Security Hub finding updated")
    except Exception as e:
        logger.warning("Could not update Security Hub finding: %s", str(e))

    # ── SNS Notification ──────────────────────────────────────────────────────
    if SNS_TOPIC_ARN and remediated:
        message = {
            'subject': 'SOAR Auto-Remediation: S3 Bucket Made Private',
            'bucket': bucket_name,
            'finding_id': finding_id,
            'action': 'Block public access enabled automatically',
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'next_steps': (
                'Review who made the bucket public and why. '
                'Search CloudTrail for PutBucketPublicAccessBlock events on this bucket.'
            )
        }
        try:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject='SOAR Auto-Remediation: S3 bucket made private',
                Message=json.dumps(message, indent=2)
            )
            logger.info("SNS notification sent to %s", SNS_TOPIC_ARN)
        except Exception as e:
            logger.warning("Could not send SNS notification: %s", str(e))

    return {
        'finding_id': finding_id,
        'bucket': bucket_name,
        'status': 'remediated' if remediated else 'already_compliant'
    }
