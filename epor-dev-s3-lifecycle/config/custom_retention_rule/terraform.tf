# -----------------------------------------------------------------------------
# File: terraform.tf
# Purpose: Provision IAM + package & deploy Lambda for a custom AWS Config rule.
# Owner: ZTMF (CMS)
# Notes:
#   - Defines IAM role(s) and policy for execution
#   - Packages Lambda code (index.py) and deploys the function
#   - Uses archive_file to zip the Lambda payload
#   - Registers an AWS Config rule to evaluate compliance
#   - Grants AWS Config permission to invoke the Lambda
#   - Expects variables to be provided via terraform.tfvars or caller module
#   - Assumes AWS provider is configured in the root module
#   - Last updated: 2025-09-19
# -----------------------------------------------------------------------------

# IAM role for Lambda
resource "aws_iam_role" "retention_lambda_exec" {
  name = "epor-dev-retention-custom-rule-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "retention_lambda_policy" {
  name = "epor-dev-retention-custom-rule-policy"
  role = aws_iam_role.retention_lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: ["s3:GetLifecycleConfiguration","s3:GetBucketTagging"],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: ["kms:DescribeKey", "kms:GetKeyRotationStatus"],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: ["config:PutEvaluations"],
        Resource: "*"
      }
    ]
  })
}

# Package the Lambda from local index.py
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "retention_rule" {
  function_name    = "epor-dev-custom-retention-validator"
  role             = aws_iam_role.retention_lambda_exec.arn
  runtime          = "python3.11"
  handler          = "index.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  memory_size      = 256
  environment {
    variables = {
      EXPECTED = jsonencode({
        APS = 1, OnePILov = 30, eSMD = 30, MDP = 30, PreclusionList = 90, HETS = 180
      })
      # Generic profiles decouple project names from retention days
      RETENTION_PROFILES = jsonencode({
        SHORT = 1, STANDARD = 30, EXTENDED = 90, LONG = 180
      })
      # Map datasets to generic profiles (override EXPECTED as the new source of truth)
      DATASET_TO_PROFILE = jsonencode({
        APS = "SHORT", ONEPILOV = "STANDARD", ESMD = "STANDARD", MDP = "STANDARD", PRECLUSIONLIST = "EXTENDED", HETS = "LONG"
      })
      # Placeholder: free-text description of what qualifies as "historical data" in this context
      HISTORICAL_DATA_DEFINITION = "TBD: Define what constitutes historical data for retention exceptions"
      # Scaffold: when true, enable Data Category tag checks inside the Lambda (disabled until categories are defined)
      CHECK_DATA_CATEGORY_TAGS   = "false"
      # Comma-separated tag keys to look for when CHECK_DATA_CATEGORY_TAGS = true
      DATA_CATEGORY_TAG_KEYS     = "DataCategory,DataSensitivity"
    }
  }
}

# Allow AWS Config to invoke Lambda
resource "aws_lambda_permission" "allow_config" {
  statement_id  = "AllowConfigInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retention_rule.function_name
  principal     = "config.amazonaws.com"
}

# Custom AWS Config rule referencing the Lambda
resource "aws_config_config_rule" "dataset_retention_rule" {
  name = "epor-dev-dataset-retention-check"
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.retention_rule.arn
  }
}
