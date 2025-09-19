# -----------------------------------------------------------------------------
# File: outputs.tf
# Purpose: Expose module outputs for downstream modules and automation.
# Owner: ZTMF (CMS)
# Notes:
#   - Exports: bucket_names, kms_key_arn
#   - Intended to be a stable interface; changing names may require consumers to update
#   - Last updated: 2025-09-18
# -----------------------------------------------------------------------------

output "bucket_names" { value = [for b in aws_s3_bucket.dev : b.bucket] }
output "kms_key_arn"  { value = var.kms_key_arn }
