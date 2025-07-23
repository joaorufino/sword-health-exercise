.PHONY: diagram plan deploy

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