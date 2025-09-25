# POC: EPOR DEV S3 Lifecycle & Compliance

This proof of concept shows how to deploy the EPOR DEV S3 lifecycle stack and AWS Config rules with minimal inputs.

## Prereqs
- Terraform >= 1.5, AWS provider >= 5.0
- An existing KMS CMK (ARN) and a central logs bucket
- AWS Config recorder + delivery channel enabled in the account/region

## Usage
```bash
cd epor-dev-s3-lifecycle/poc
terraform init
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your values
terraform plan
terraform apply
```

## Notes
- Buckets are created following `epor-dev-<dataset>-<hdt|haa>-<suffix>`
- Lifecycle retention is dataset-specific (APS=1d; OnePILov/eSMD/MDP=30d; Preclusion=90d; HETS=180d)
- Config managed rules include SSE-KMS, TLS-only, no public access, versioning, logging, replication (backup), and KMS rotation
- The custom rule validates dataset retention and appends an informational note re: historical data definition and optional data category tags
