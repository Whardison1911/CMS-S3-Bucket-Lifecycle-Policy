# -----------------------------------------------------------------------------
# File: providers.tf
# Purpose: Configure AWS provider settings and organization-wide default tags.
# Owner: ZTMF (CMS)
# Notes:
#   - Applies organization-wide default tags to all managed resources
#   - Supports AWS named profile selection via variable
#   - Optionally assumes a cross-account role when configured
#   - Ignores specific tag keys to avoid drift with org taggers
#   - Can reference current Account ID for tagging or logic
#   - Region is provided via variable input
#   - Last updated: 2025-09-18
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment        = "DEV"
      System             = "EPOR"
      Owner              = var.owner
      BusinessUnit       = var.business_unit
      CostCenter         = var.cost_center
      DataClassification = var.data_classification
      ManagedBy          = "Terraform"
      Project            = "EPOR-DEV-S3-Lifecycle"
    }
  }
}
