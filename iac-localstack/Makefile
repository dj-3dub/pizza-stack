SHELL := /bin/bash
export $(shell sed -e 's/#.*//' -e 's/\r$//' .env 2>/dev/null | xargs -0)

.DEFAULT_GOAL := help

help:
	@echo "Targets:"
	@echo "  make up           - start LocalStack"
	@echo "  make down         - stop LocalStack"
	@echo "  make tf-init      - terraform init"
	@echo "  make tf-plan      - terraform plan"
	@echo "  make tf-apply     - terraform apply"
	@echo "  make tf-destroy   - terraform destroy"
	@echo "  make graph        - render Terraform dependency graph"

up:
	docker compose up -d

down:
	docker compose down

tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply -auto-approve

tf-destroy:
	cd terraform && terraform destroy -auto-approve

fmt:
	cd terraform && terraform fmt -recursive

graph:
	cd terraform && terraform graph -type=plan | dot -Tsvg > ../diagrams/terraform-graph.svg || \
	( echo '[i] No plan graph available, generating full graph...'; \
	  terraform graph | dot -Tsvg > ../diagrams/terraform-graph.svg )
	@echo 'Wrote diagrams/terraform-graph.svg'
