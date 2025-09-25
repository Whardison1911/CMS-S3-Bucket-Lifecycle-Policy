# POC: instantiate the EPOR DEV S3 lifecycle stack
module "epor_dev_s3" {
  source = "../.."

  region             = var.region
  logs_bucket_name   = var.logs_bucket_name
  kms_key_arn        = var.kms_key_arn
  suffix             = var.suffix

  owner              = var.owner
  business_unit      = var.business_unit
  cost_center        = var.cost_center
  data_classification= var.data_classification
}
