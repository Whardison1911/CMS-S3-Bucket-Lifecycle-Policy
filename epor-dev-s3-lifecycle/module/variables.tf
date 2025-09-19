# -----------------------------------------------------------------------------
# File: variables.tf
# Purpose: Define input variables and defaults for the EPOR DEV S3 Lifecycle stack.
# Owner: ZTMF (CMS)
# Notes:
#   - Inputs: region, logs_bucket_name, kms_key_arn, suffix, owner, business_unit, cost_center, data_classification
#   - Consumed by providers and modules (root and ./module)
#   - Update descriptions/defaults to reflect organizational standards
#   - Last updated: 2025-09-18
# -----------------------------------------------------------------------------

variable "region"           { type = string }
variable "logs_bucket_name" { type = string }
variable "kms_key_arn"      { type = string }
variable "suffix"           { type = string }

variable "owner"            { type = string }
variable "business_unit"    { type = string }
variable "cost_center"      { type = string }
variable "data_classification" { type = string }
