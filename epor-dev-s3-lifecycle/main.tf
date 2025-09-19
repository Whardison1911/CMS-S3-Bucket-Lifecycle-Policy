# -----------------------------------------------------------------------------
# File: main.tf
# Purpose: Root module that wires S3 lifecycle module and AWS Config rules for EPOR DEV.
# Owner: ZTMF (CMS)
# Notes:
#   - Calls module "s3" to create buckets, lifecycle, encryption, and policies
#   - Calls module "config" to register AWS Config managed and custom rules
#   - Ensures Config rules are created after S3 resources via depends_on
#   - Inputs provided via variables/terraform.tfvars (region, logs bucket, KMS key, suffix)
#   - Last updated: 2025-09-17
# -----------------------------------------------------------------------------

module "s3" {
  source           = "./module"
  region           = var.region
  logs_bucket_name = var.logs_bucket_name
  kms_key_arn      = var.kms_key_arn
  suffix           = var.suffix

  owner               = var.owner
  business_unit       = var.business_unit
  cost_center         = var.cost_center
  data_classification = var.data_classification
}

module "config" {
  source = "./config"
  depends_on = [module.s3]
}

output "bucket_names" { value = module.s3.bucket_names }
output "kms_key_arn"  { value = module.s3.kms_key_arn }
