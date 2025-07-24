# Terraform Infrastructure Modules - Linting and Security Scanning
# Best practices for Terraform code quality and security in 2024

.PHONY: help all format validate lint security-scan clean install-tools

# Default target
all: format validate lint security-scan

# Help command
help:
	@echo "Terraform Infrastructure Modules - Available Commands:"
	@echo ""
	@echo "  make install-tools    Install all required linting and scanning tools"
	@echo "  make format          Format all Terraform files"
	@echo "  make validate        Validate Terraform configuration"
	@echo "  make lint            Run TFLint on all modules"
	@echo "  make security-scan   Run all security scanners (tfsec, checkov, terrascan)"
	@echo "  make tfsec           Run tfsec security scanner"
	@echo "  make checkov         Run Checkov security scanner"
	@echo "  make terrascan       Run Terrascan security scanner"
	@echo "  make docs            Generate documentation for modules"
	@echo "  make pre-commit      Run all pre-commit checks"
	@echo "  make clean           Clean temporary files"
	@echo "  make all             Run format, validate, lint, and security-scan"

# Install required tools
install-tools:
	@echo "Installing Terraform linting and security tools..."
	@echo "Installing TFLint..."
	@curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash || \
		(echo "Please install TFLint manually: https://github.com/terraform-linters/tflint#installation")
	@echo "Installing tfsec..."
	@curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash || \
		(echo "Please install tfsec manually: https://github.com/aquasecurity/tfsec#installation")
	@echo "Installing Checkov..."
	@pip3 install checkov || \
		(echo "Please install Checkov manually: pip install checkov")
	@echo "Installing Terrascan..."
	@curl -L "https://github.com/tenable/terrascan/releases/latest/download/terrascan_Linux_x86_64.tar.gz" | tar -xzf - -C /usr/local/bin/ terrascan || \
		(echo "Please install Terrascan manually: https://github.com/tenable/terrascan#installation")
	@echo "Installing terraform-docs..."
	@go install github.com/terraform-docs/terraform-docs@latest || \
		(echo "Please install terraform-docs manually: https://terraform-docs.io/user-guide/installation/")
	@echo "All tools installed successfully!"

# Format all Terraform files
format:
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive .
	@echo "✓ Formatting complete"

# Validate Terraform configuration
validate:
	@echo "Validating Terraform configuration..."
	@for dir in $$(find . -type f -name "*.tf" -exec dirname {} \; | sort -u | grep -v ".terraform"); do \
		echo "Validating $$dir..."; \
		(cd $$dir && terraform init -backend=false >/dev/null 2>&1 && terraform validate) || exit 1; \
	done
	@echo "✓ Validation complete"

# Run TFLint
lint: .tflint.hcl
	@echo "Running TFLint..."
	@tflint --init || true
	@for dir in $$(find . -type f -name "*.tf" -exec dirname {} \; | sort -u | grep -v ".terraform"); do \
		echo "Linting $$dir..."; \
		(cd $$dir && tflint --config=$$(pwd)/.tflint.hcl) || exit 1; \
	done
	@echo "✓ Linting complete"

# Run all security scanners
security-scan: tfsec checkov terrascan
	@echo "✓ All security scans complete"

# Run tfsec
tfsec:
	@echo "Running tfsec security scan..."
	@tfsec . --no-color --soft-fail || true
	@echo "✓ tfsec scan complete"

# Run Checkov
checkov:
	@echo "Running Checkov security scan..."
	@checkov -d . --framework terraform --quiet --compact || true
	@echo "✓ Checkov scan complete"

# Run Terrascan
terrascan:
	@echo "Running Terrascan security scan..."
	@terrascan scan -t aws -i terraform -d . || true
	@echo "✓ Terrascan scan complete"

# Generate documentation
docs:
	@echo "Generating documentation for Terraform modules..."
	@for dir in $$(find . -type f -name "*.tf" -exec dirname {} \; | sort -u | grep -v ".terraform"); do \
		if [ -f "$$dir/variables.tf" ] || [ -f "$$dir/outputs.tf" ]; then \
			echo "Generating docs for $$dir..."; \
			terraform-docs markdown table $$dir > $$dir/README.md || true; \
		fi; \
	done
	@echo "✓ Documentation generation complete"

# Pre-commit checks (all checks that should run before committing)
pre-commit: format validate lint security-scan
	@echo "✓ All pre-commit checks passed!"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "*.tfplan" -exec rm -f {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate*" -exec rm -f {} + 2>/dev/null || true
	@echo "✓ Clean complete"

# Create default TFLint configuration if it doesn't exist
.tflint.hcl:
	@echo "Creating default TFLint configuration..."
	@cat > .tflint.hcl <<'EOF'
	plugin "terraform" {
	  enabled = true
	  preset  = "recommended"
	}
	
	plugin "aws" {
	  enabled = true
	  version = "0.27.0"
	  source  = "github.com/terraform-linters/tflint-ruleset-aws"
	}
	
	rule "terraform_required_version" {
	  enabled = true
	}
	
	rule "terraform_required_providers" {
	  enabled = true
	}
	
	rule "terraform_naming_convention" {
	  enabled = true
	  format  = "snake_case"
	}
	
	rule "terraform_typed_variables" {
	  enabled = true
	}
	
	rule "terraform_unused_declarations" {
	  enabled = true
	}
	
	rule "terraform_comment_syntax" {
	  enabled = true
	}
	
	rule "terraform_documented_outputs" {
	  enabled = true
	}
	
	rule "terraform_documented_variables" {
	  enabled = true
	}
	EOF

# Module-specific targets for focused testing
lint-module:
	@if [ -z "$(MODULE)" ]; then \
		echo "Error: MODULE variable not set. Usage: make lint-module MODULE=networking/vpc"; \
		exit 1; \
	fi
	@echo "Linting module: $(MODULE)..."
	@cd $(MODULE) && tflint

scan-module:
	@if [ -z "$(MODULE)" ]; then \
		echo "Error: MODULE variable not set. Usage: make scan-module MODULE=networking/vpc"; \
		exit 1; \
	fi
	@echo "Security scanning module: $(MODULE)..."
	@tfsec $(MODULE) --no-color
	@checkov -d $(MODULE) --framework terraform --quiet --compact
	@terrascan scan -t aws -i terraform -d $(MODULE)

# CI/CD specific targets with stricter settings
ci-lint:
	@echo "Running CI linting checks (strict mode)..."
	@terraform fmt -check -recursive .
	@$(MAKE) validate
	@$(MAKE) lint

ci-security:
	@echo "Running CI security checks (fail on issues)..."
	@tfsec . --no-color
	@checkov -d . --framework terraform --quiet --compact --hard-fail-on MEDIUM
	@terrascan scan -t aws -i terraform -d .