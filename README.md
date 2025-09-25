# CMS-S3-Bucket-Lifecycle-Policy Repository

## 📋 Overview

This educational repository provides a comprehensive set of Terraform configurations that **standardize S3 buckets in EPOR DEV**. It implements **data lifecycle (per dataset), encryption, access guardrails, naming/tagging**, and **continuous compliance** with AWS Config—so buckets are created correctly and stay compliant.

### Key Features

* **🗂️ Dataset-Based Retention**: APS (**1d**), OnePILov/eSMD/MDP (**30d**), Preclusion List (**90d**), HETS (**180d**)
* **🔐 Encryption by Default**: SSE-KMS with bucket keys; TLS-only access; ACLs disabled (BucketOwnerEnforced)
* **📜 Policy-as-Code**: Bucket policies that deny non-TLS and non-KMS uploads and enforce the correct CMK
* **📦 Versioning & Logging**: Versioning enabled; server access logs shipped to a central logs bucket
* **🏷️ Naming & Tags**: `epor-dev-<dataset>-<hdt|haa>-<suffix>`; consistent required tags for ownership/compliance
* **🧭 Continuous Compliance**: AWS Config managed rules + a custom rule to validate dataset-specific retention
* **⚙️ Centralized Configuration**: Terraform locals define datasets, identifiers (`hdt`, `haa`), and transitions


## 🔄 New Checks Added

- **Backup/Replication**: Enforced with AWS Config `S3_BUCKET_REPLICATION_ENABLED`.
- **KMS Key Rotation**: Enforced with AWS Config `KMS_KEY_ROTATION_ENABLED` (rotate at least annually).
- **Historical Data**: Placeholder definition surfaced by the custom rule annotation (`HISTORICAL_DATA_DEFINITION`).
- **Data Category Tags**: Optional, disabled by default; enable via `CHECK_DATA_CATEGORY_TAGS` and configure `DATA_CATEGORY_TAG_KEYS`.
## 🏗️ Repository Structure

```
.
├── module/
│   ├── main.tf                 # Buckets, policies, lifecycle rules
│   ├── locals.tf               # Datasets, identifiers, transitions, naming docs
│   ├── variables.tf            # Inputs (region, logs_bucket, owner, etc.)
│   └── outputs.tf              # Useful exports (kms_key_arn, bucket_names, ...)
├── config/
│   ├── config_rules.tf         # AWS Config managed rules
│   └── custom_retention_rule/  # Lambda for DEV dataset retention validation
│       ├── index.py
│       └── terraform.tf
├── docs/
│   ├── EPOR-APS-1day-RetentionPolicy.png
│   ├── epor-dev-onepilov-30dayRetentionPolicy.png
│   └── epor-dev-preclusion-90DayRetentionPolicy.png
└── Makefile                    # Development workflow automation
```

## 🚀 Quick Start

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd epor-dev-s3-lifecycle
   ```

2. **Customize your configuration** by editing `module/locals.tf`:

   ```hcl
   # Example locals (abbrev.)
   locals {
     datasets = {
       APS            = { retention = 1,   diagram = "EPOR-APS-1day-RetentionPolicy.png" }
       OnePILov       = { retention = 30,  diagram = "epor-dev-onepilov-30dayRetentionPolicy.png" }
       eSMD           = { retention = 30,  diagram = "epor-dev-onepilov-30dayRetentionPolicy.png" }
       MDP            = { retention = 30,  diagram = "epor-dev-onepilov-30dayRetentionPolicy.png" }
       PreclusionList = { retention = 90,  diagram = "epor-dev-preclusion-90DayRetentionPolicy.png" }
       HETS           = { retention = 180, diagram = "" }
     }

     identifiers   = ["hdt", "haa"]  # Both identifiers are required per dataset
     transition_map = {
       1   = []
       30  = [{ days = 7,  class = "STANDARD_IA" }]
       90  = [{ days = 30, class = "STANDARD_IA" }, { days = 60, class = "GLACIER_IR" }]
       180 = [{ days = 30, class = "STANDARD_IA" }, { days = 90, class = "GLACIER_IR" }]
     }
   }
   ```

3. **Validate and deploy**:

   ```bash
   make test              # Run all validation checks
   terraform init         # Initialize Terraform
   terraform plan         # Review planned changes
   terraform apply        # Deploy the infrastructure
   ```

## 🛠️ Using the Makefile

The included Makefile provides a standardized development workflow that works across Windows, macOS, and Linux:

### Basic Commands

| Command         | Description                                            |
| --------------- | ------------------------------------------------------ |
| `make help`     | Display all available commands                         |
| `make fmt`      | Format all Terraform files to canonical style          |
| `make validate` | Validate Terraform syntax and configuration            |
| `make lint`     | Run TFLint for best practices checking                 |
| `make security` | Run security scanners (tfsec, Checkov)                 |
| `make test`     | Run all quality checks (fmt, validate, lint, security) |
| `make clean`    | Remove temporary files and directories                 |

### Tool Management

| Command        | Description                                       |
| -------------- | ------------------------------------------------- |
| `make tools`   | Check which tools are installed                   |
| `make install` | Show installation instructions for required tools |

### Example Workflow

```bash
# Check your environment
make tools

# Format and validate your code
make fmt
make validate

# Run security checks
make security

# Run all checks at once
make test
```

The Makefile automatically:

* Detects your operating system (Windows/macOS/Linux)
* Checks if required tools are installed before running commands
* Provides helpful error messages if tools are missing
* Works in Git Bash, WSL, and native terminals

## 🔧 Understanding Locals

The `locals.tf` file centralizes configuration values, making the solution **easy to customize** without editing multiple files. This follows Terraform best practices for configuration management.

### Key Configuration Areas

1. **Datasets & Retention**

   ```hcl
   datasets = {
     APS = { retention = 1 }, OnePILov = { retention = 30 }, eSMD = { retention = 30 },
     MDP = { retention = 30 }, PreclusionList = { retention = 90 }, HETS = { retention = 180 }
   }
   ```

   Controls how long objects live before expiration (current and non-current versions).

2. **Identifiers (Bucket Variants)**

   ```hcl
   identifiers = ["hdt", "haa"]
   ```

   Both variants are created for each dataset to satisfy EPOR DEV naming requirements.

3. **Transitions (Cost Optimization)**

   ```hcl
   transition_map = {
     1 = []
     30  = [{ days = 7,  class = "STANDARD_IA" }]
     90  = [{ days = 30, class = "STANDARD_IA" }, { days = 60, class = "GLACIER_IR" }]
     180 = [{ days = 30, class = "STANDARD_IA" }, { days = 90, class = "GLACIER_IR" }]
   }
   ```

   Defines storage-class transitions prior to expiration.

4. **Naming Convention**
   Buckets must follow:

   ```
   epor-dev-<dataset>-<hdt|haa>-<suffix>
   # example: epor-dev-aps-hdt-001
   ```

5. **Common Tags** (typically set via provider default\_tags and resource tags)

   ```hcl
   # Example
   {
     Environment       = "DEV"
     System            = "EPOR"
     Dataset           = "<APS|OnePILov|eSMD|MDP|PreclusionList|HETS>"
     Identifier        = "<hdt|haa>"
     RetentionDays     = "<1|30|90|180>"
     Owner             = "team-epor"
     BusinessUnit      = "apps"
     CostCenter        = "12345"
     DataClassification= "Internal"
   }
   ```

### How Locals Are Used

Throughout the module, locals are referenced with `local.` and transformed for iteration:

```hcl
# Build dataset × identifier combos
locals {
  combos = flatten([
    for d, cfg in local.datasets : [
      for id in local.identifiers : {
        key        = lower("${d}-${id}")
        dataset    = d
        identifier = id
        retention  = cfg.retention
      }
    ]
  ])
}

# Example: create buckets
resource "aws_s3_bucket" "dev" {
  for_each = { for c in local.combos : c.key => c }
  bucket   = "epor-dev-${lower(each.value.dataset)}-${each.value.identifier}-${var.suffix}"
  # ...
}

# Example: lifecycle transitions by retention
resource "aws_s3_bucket_lifecycle_configuration" "dev" {
  for_each = aws_s3_bucket.dev
  bucket   = each.value.id

  rule {
    id     = "retention-${each.value.tags.RetentionDays}d"
    status = "Enabled"

    expiration { days = tonumber(each.value.tags.RetentionDays) }
    noncurrent_version_expiration { noncurrent_days = tonumber(each.value.tags.RetentionDays) }

    dynamic "transition" {
      for_each = lookup(local.transition_map, tonumber(each.value.tags.RetentionDays), [])
      content {
        days          = transition.value.days
        storage_class = transition.value.class
      }
    }
  }
}
```

This provides:

* **Single source of truth** for retention/naming
* **Environment flexibility** across accounts
* **Reduced errors** and clearer documentation

## 📊 Policy & Compliance Matrix

| Control               | What It Does                                                       | AWS Config Rule                                                                                     | Terraform File(s)                          |
| --------------------- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| **Encryption**        | Ensures SSE-KMS is default for all objects                         | `S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED`                                                          | `module/main.tf`                           |
| **TLS Only**          | Deny requests without Secure Transport                             | `S3_BUCKET_SSL_REQUESTS_ONLY`                                                                       | `module/main.tf` (bucket policy)           |
| **No Public Access**  | Blocks public ACL/policy access                                    | `S3_BUCKET_PUBLIC_READ_PROHIBITED`, `S3_BUCKET_PUBLIC_WRITE_PROHIBITED`, `S3_BUCKET_ACL_PROHIBITED` | `config/config_rules.tf`, `module/main.tf` |
| **Versioning**        | Enables versioning for durability and recovery                     | `S3_BUCKET_VERSIONING_ENABLED`                                                                      | `module/main.tf`                           |
| **Access Logging**    | Ships server access logs to central bucket                         | `S3_BUCKET_LOGGING_ENABLED`                                                                         | `module/main.tf`                           |
| **Dataset Retention** | Validates APS=1d; OnePILov/eSMD/MDP=30d; Preclusion=90d; HETS=180d | **Custom** Lambda-backed rule                                                                       | `config/custom_retention_rule/`            |

## 📦 Prerequisites

* **Terraform**: ≥ 1.5
* **AWS Provider**: ≥ 5.0
* **AWS Resources Required**:

  * A central **S3 logs bucket** (destination for server access logs)
  * **AWS Config** recorder + delivery channel enabled
  * IAM permissions to create S3, KMS, Config, Lambda resources (if using the custom rule)

## 🔒 Security Considerations

1. **Bucket Policy Enforcement**: Denies non-TLS access, non-KMS uploads, and uploads not using the designated CMK
2. **CMK Access**: Ensure key policy/permissions allow intended principals to encrypt/decrypt
3. **Lifecycle Effects**: Expiration deletes current and non-current versions at the configured retention period
4. **Logging**: Confirm the logs bucket policy allows the source buckets to write access logs
5. **Custom Rule IAM**: Lambda for the custom Config rule needs `s3:GetLifecycleConfiguration` and `config:PutEvaluations`

## 🤝 Contributing

This is an educational repository designed to demonstrate S3 lifecycle and compliance patterns. Feel free to:

* Fork and customize for your organization
* Submit issues for bugs or improvements
* Share your own compliance guardrails and patterns

## 📄 License

This repository is provided for educational purposes. Please review and test thoroughly before using in production environments.

## 🏢 Owner

**EPOR (DEV)** — S3 Lifecycle & Protection (Terraform + AWS Config)

---

*Note: Remember to update `module/locals.tf`, `variables.tf`, and your **logs bucket name** before deployment.*

