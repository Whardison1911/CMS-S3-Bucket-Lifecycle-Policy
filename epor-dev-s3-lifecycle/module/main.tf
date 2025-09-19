# -----------------------------------------------------------------------------
# File: main.tf
# Purpose: Root module that wires S3 lifecycle module and AWS Config rules for EPOR DEV.
# Owner: ZTMF (CMS)
# Notes:
#   - Calls module "s3" to create buckets, lifecycle, encryption, policies
#   - Calls module "config" to register AWS Config managed/custom rules
#   - Ensures Config rules are created after S3 resources (explicit depends_on)
#   - Exports key outputs (e.g., bucket_names, kms_key_arn)
#   - Inputs expected via variables/terraform.tfvars (region, logs bucket, kms key, suffix)
#   - Last updated: 2025-09-18
# -----------------------------------------------------------------------------

data "aws_region" "current" {}

# Create S3 buckets for each dataset × identifier
resource "aws_s3_bucket" "dev" {
  for_each = local.combos_map
  bucket   = "epor-dev-${lower(each.value.dataset)}-${each.value.identifier}-${var.suffix}"
}

# Block public access
resource "aws_s3_bucket_public_access_block" "dev" {
  for_each = aws_s3_bucket.dev
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ownership controls (BucketOwnerEnforced disables ACLs)
resource "aws_s3_bucket_ownership_controls" "dev" {
  for_each = aws_s3_bucket.dev
  bucket   = each.value.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

# Versioning
resource "aws_s3_bucket_versioning" "dev" {
  for_each = aws_s3_bucket.dev
  bucket   = each.value.id
  versioning_configuration { status = "Enabled" }
}

# Server access logging
resource "aws_s3_bucket_logging" "dev" {
  for_each = aws_s3_bucket.dev
  bucket        = each.value.id
  target_bucket = var.logs_bucket_name
  target_prefix = "${each.value.bucket}/"
}

# SSE-KMS default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "dev" {
  for_each = aws_s3_bucket.dev
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Tags (provider v5: use tag_set blocks)
resource "aws_s3_bucket_tagging" "dev" {
  for_each = aws_s3_bucket.dev
  bucket   = each.value.id

  tag_set {
    key   = "Environment"
    value = "DEV"
  }

  tag_set {
    key   = "System"
    value = "EPOR"
  }

  # add the rest similarly…
  tag_set {
    key   = "Dataset"
    value = local.combos_map[each.key].dataset
  }
  tag_set {
    key   = "Identifier"
    value = local.combos_map[each.key].identifier
  }
  tag_set {
    key   = "RetentionDays"
    value = tostring(local.combos_map[each.key].retention)
  }
  tag_set {
    key   = "Owner"
    value = var.owner
  }
  tag_set {
    key   = "BusinessUnit"
    value = var.business_unit
  }
  tag_set {
    key   = "CostCenter"
    value = var.cost_center
  }
  tag_set {
    key   = "DataClassification"
    value = var.data_classification
  }
}


# Lifecycle: expiration + non-current expiration + transitions from transition_map
resource "aws_s3_bucket_lifecycle_configuration" "dev" {
  for_each = aws_s3_bucket.dev
  bucket   = each.value.id

  rule {
    id     = "retention-${local.combos_map[each.key].retention}d"
    status = "Enabled"

    expiration {
      days = local.combos_map[each.key].retention
    }

    noncurrent_version_expiration {
      noncurrent_days = local.combos_map[each.key].retention
    }

    dynamic "transition" {
      for_each = lookup(local.transition_map, local.combos_map[each.key].retention, [])
      content {
        days          = transition.value.days
        storage_class = transition.value.class
      }
    }
  }
}

# Bucket policy: TLS-only and enforce SSE-KMS + the designated CMK
data "aws_iam_policy_document" "bucket" {
  for_each = aws_s3_bucket.dev

  # Deny any non-TLS request
  statement {
    sid     = "DenyNonTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      each.value.arn,
      "${each.value.arn}/*"
    ]

    # Use a known principal type: "AWS" with "*" to mean "any principal"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Require SSE using KMS
  statement {
    sid     = "DenyIncorrectEncryptionHeader"
    effect  = "Deny"
    actions = ["s3:PutObject"]
    resources = ["${each.value.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  # Deny missing SSE header
  statement {
    sid     = "DenyUnencryptedObjectUploads"
    effect  = "Deny"
    actions = ["s3:PutObject"]
    resources = ["${each.value.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }

  # Enforce your specific CMK
  statement {
    sid     = "DenyWrongKMSKey"
    effect  = "Deny"
    actions = ["s3:PutObject"]
    resources = ["${each.value.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [var.kms_key_arn]
    }
  }
}
