# -----------------------------------------------------------------------------
# File: index.py
# Purpose: AWS Config custom rule Lambda to validate S3 dataset retention.
# Owner: ZTMF (CMS)
# Notes:
#   - This header was added programmatically per request.
#   - Ensure required AWS permissions/env vars exist before deployment.
#   - Last updated: 2025-09-17
# -----------------------------------------------------------------------------

import boto3, json, os

s3 = boto3.client("s3")
config = boto3.client("config")

def get_expected_days(bucket_name):
    # Expect mapping by dataset parsed from bucket naming: epor-dev-<dataset>-<id>-<suffix>
    expected_map = json.loads(os.environ.get("EXPECTED", "{}"))
    parts = bucket_name.split("-")
    # epor-dev-<dataset>-<identifier>-<suffix>
    dataset = parts[2].upper() if len(parts) >= 5 else None
    if dataset in expected_map:
        return int(expected_map[dataset])
    return None

def check_bucket_retention(bucket_name, expected_days):
    try:
        resp = s3.get_bucket_lifecycle_configuration(Bucket=bucket_name)
    except s3.exceptions.NoSuchLifecycleConfiguration:
        return False, "No lifecycle configuration"
    rules = resp.get("Rules", [])
    for r in rules:
        if r.get("Status") != "Enabled":
            continue
        exp = (r.get("Expiration") or {}).get("Days")
        nce = (r.get("NoncurrentVersionExpiration") or {}).get("NoncurrentDays")
        if exp == expected_days and nce == expected_days:
            return True, "Matching expiration and noncurrent retention"
    return False, "No matching rule found"

def lambda_handler(event, context):
    invoking_event = json.loads(event["invokingEvent"])
    ci = invoking_event.get("configurationItem")
    result_token = event.get("resultToken", "NoTokenProvided")

    if not ci:
        return {"status": "ignored"}

    resource_type = ci.get("resourceType")
    resource_id = ci.get("resourceId")  # bucket name
    compliance_type = "NOT_APPLICABLE"
    annotation = "Not an S3 bucket"

    if resource_type == "AWS::S3::Bucket":
        expected = get_expected_days(resource_id)
        if expected is None:
            compliance_type = "NON_COMPLIANT"
            annotation = "Dataset not recognized for expected retention"
        else:
            ok, note = check_bucket_retention(resource_id, expected)
            compliance_type = "COMPLIANT" if ok else "NON_COMPLIANT"
            annotation = note

    eval_result = {
        "ComplianceResourceType": resource_type,
        "ComplianceResourceId": resource_id,
        "ComplianceType": compliance_type,
        "Annotation": (annotation or "")[:256],
        "OrderingTimestamp": ci.get("configurationItemCaptureTime")
    }

    config.put_evaluations(Evaluations=[eval_result], ResultToken=result_token, TestMode=False)
    return {"status": "done", "compliance": compliance_type, "note": annotation}
