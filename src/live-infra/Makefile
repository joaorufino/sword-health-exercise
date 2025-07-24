.PHONY: diagram plan deploy infra-cost infra-cost-breakdown

diagram:
	@mkdir -p diagrams
	@cd dev/eu-central-1 && terragrunt dag graph > ../../diagrams/terragrunt-dag.dot
	@dot -Tpng diagrams/terragrunt-dag.dot -o diagrams/terragrunt-dag.png
	@echo "Diagram generated: diagrams/terragrunt-dag.png"

plan:
	@echo "Planning infrastructure changes..."
	@cd dev/eu-central-1 && terragrunt run-all plan

deploy:
	@echo "Deploying infrastructure..."
	@cd dev/eu-central-1 && terragrunt run-all apply

infra-cost:
	@echo "Generating cost estimate for infrastructure changes..."
	@cd dev/eu-central-1 && infracost breakdown --path .
