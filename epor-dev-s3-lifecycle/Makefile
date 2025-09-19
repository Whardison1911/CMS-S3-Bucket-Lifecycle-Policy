.PHONY: help fmt validate security test tools install clean

help:
@echo "make fmt        - Format Terraform"
@echo "make validate   - Terraform validate"
@echo "make security   - Run tfsec and checkov (if installed)"
@echo "make test       - Run fmt, validate, security"
@echo "make tools      - Check installed tools"
@echo "make install    - Show install instructions"
@echo "make clean      - Remove local build artifacts"

fmt:
terraform fmt -recursive

validate:
terraform validate

security:
@if command -v tfsec >/dev/null 2>&1; then tfsec .; else echo "tfsec not installed"; fi
@if command -v checkov >/dev/null 2>&1; then checkov -d .; else echo "checkov not installed"; fi

test: fmt validate security

tools:
@echo "Terraform version:" && terraform version || true
@echo "tfsec version:" && tfsec --version || true
@echo "checkov version:" && checkov --version || true

install:
@echo "Install Terraform: https://developer.hashicorp.com/terraform/downloads"
@echo "Install tfsec: https://github.com/aquasecurity/tfsec"
@echo "Install Checkov: pip install checkov"

clean:
rm -f ./config/custom_retention_rule/lambda.zip
