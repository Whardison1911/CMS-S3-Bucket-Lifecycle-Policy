# -----------------------------------------------------------------------------
# File: variables.tf
# Purpose: Define input variables and defaults for the EPOR DEV S3 Lifecycle stack.
# Owner: ZTMF (CMS)
# Notes:
#   - Inputs: region, suffix, logs_bucket_name, kms_key_arn, owner, business_unit, cost_center, data_classification
#   - Consumed by providers and modules (root and ./module)
#   - Update descriptions/defaults to reflect organizational standards
#   - Includes variable descriptions for clarity
#   - Includes sensible defaults where appropriate
#   - Last updated: 2025-09-18
# -----------------------------------------------------------------------------

variable "region" {
  type        = string
  description = "AWS region (e.g., us-east-1)"
}

variable "suffix" {
  type        = string
  description = "3-digit or org-defined suffix for bucket names (e.g., 001)"
}

variable "logs_bucket_name" {
  type        = string
  description = "Pre-existing central logs bucket name"
}

variable "kms_key_arn" {
  type        = string
  description = "CMK ARN used for SSE-KMS on buckets"
}

variable "owner" {
  type        = string
  default     = "team-epor"
  description = "Tag: Owner"
}

variable "business_unit" {
  type        = string
  default     = "apps"
  description = "Tag: Business unit"
}

variable "cost_center" {
  type        = string
  default     = "12345"
  description = "Tag: Cost center"
}

variable "data_classification" {
  type        = string
  default     = "Internal"
  description = "Tag: Data classification"
}
