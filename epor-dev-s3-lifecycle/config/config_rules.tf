# -----------------------------------------------------------------------------
# File: config_rules.tf
# Purpose: Define AWS Config managed rules for S3 security/compliance and wire the custom dataset-retention rule.
# Owner: ZTMF (CMS)
# Notes:
#   - Requires AWS Config recorder & delivery channel to be enabled in the account/region
#   - Managed rules: SSE-KMS, TLS-only, public access prohibited, ACL prohibited, versioning, logging
#   - Invokes custom retention rule module (Lambda-backed)
#   - Last updated: 2025-09-18
# -----------------------------------------------------------------------------

# Managed AWS Config rules for S3 (scoped to S3 buckets)

resource "aws_config_config_rule" "sse_kms" {
  name = "s3-bucket-sse-kms-enabled"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}

resource "aws_config_config_rule" "tls_only" {
  name = "s3-bucket-tls-requests-only"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }
}

resource "aws_config_config_rule" "no_public_read" {
  name = "s3-bucket-public-read-prohibited"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "no_public_write" {
  name = "s3-bucket-public-write-prohibited"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
}

resource "aws_config_config_rule" "acl_prohibited" {
  name = "s3-bucket-acl-prohibited"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_ACL_PROHIBITED"
  }
}

resource "aws_config_config_rule" "versioning" {
  name = "s3-bucket-versioning-enabled"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }
}

# If you want to assert a specific logs bucket/prefix, you can pass parameters.
# Otherwise, leave the parameters block out entirely.
resource "aws_config_config_rule" "logging" {
  name = "s3-bucket-logging-enabled"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LOGGING_ENABLED"
  }

  # Optional parameters:
  # input_parameters = jsonencode({
  #   targetBucket = "your-central-logs-bucket"
  #   targetPrefix = "logs/"
  # })
}

# Custom rule that validates dataset-specific retention
module "custom_retention_rule" {
  source = "./custom_retention_rule"
}

# Backup / replication enabled (supports Data Availability)
resource "aws_config_config_rule" "replication_enabled" {
  name = "s3-bucket-replication-enabled"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_REPLICATION_ENABLED"
  }
}

# KMS key rotation enabled (crypto key lifecycle)
resource "aws_config_config_rule" "kms_key_rotation_enabled" {
  name = "kms-key-rotation-enabled"
  source {
    owner             = "AWS"
    source_identifier = "KMS_KEY_ROTATION_ENABLED"
  }
}
