# -----------------------------------------------------------------------------
# File: versions.tf
# Purpose: Pin Terraform and provider versions for reproducible builds.
# Owner: ZTMF (CMS)
# Notes:
#   - Terraform required_version: >= 1.5.0
#   - Required providers: aws >= 5.0, archive >= 2.4.0
#   - Update versions intentionally; run terraform init -upgrade to pick newer constraints when ready
#   - Last updated: 2025-09-19
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
  }
}
