SHELL := /bin/bash

# --- Python venv settings ---
VENV := .venv
PY   := $(VENV)/bin/python
PIP  := $(VENV)/bin/pip

.DEFAULT_GOAL := help

.PHONY: help up down tf-init tf-plan tf-apply tf-destroy fmt graph arch lambda-build venv deps smoke clean venv-clean ci-local

help:
	@echo "Targets:"
	@echo "  up             - start LocalStack (docker compose up -d)"
	@echo "  down           - stop LocalStack (docker compose down)"
	@echo "  tf-init        - terraform init"
	@echo "  tf-plan        - terraform plan"
	@echo "  tf-apply       - terraform apply -auto-approve"
	@echo "  tf-destroy     - terraform destroy -auto-approve"
	@echo "  fmt            - terraform fmt -recursive"
	@echo "  graph          - render Terraform graph -> diagrams/terraform-graph.svg"
	@echo "  arch           - render docs/architecture.svg (and .png)"
	@echo "  lambda-build   - zip the Lambda -> terraform/lambda/hello.zip"
	@echo "  venv           - create Python virtualenv in $(VENV)"
	@echo "  deps           - install Python deps into $(VENV)"
	@echo "  smoke          - run pizza stack sanity checks (✅/❌)"
	@echo "  ci-local       - run a local CI (start LS -> build/apply -> smoke -> destroy)"
	@echo "  clean          - wipe terraform state & LocalStack data (dangerous)"
	@echo "  venv-clean     - remove $(VENV)"

# --- LocalStack / Terraform basics ---
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
	@mkdir -p diagrams
	@{ cd terraform && terraform graph -type=plan 2>/dev/null || terraform graph; } | dot -Tsvg > diagrams/terraform-graph.svg
	@echo 'Wrote diagrams/terraform-graph.svg'

arch:
	@dot -Tsvg docs/architecture.dot > docs/architecture.svg
	@-dot -Tpng docs/architecture.dot > docs/architecture.png
	@echo 'Wrote docs/architecture.svg (and .png)'

lambda-build:
	@bash terraform/lambda/build.sh

# --- Python virtual environment & deps ---
venv:
	@test -d $(VENV) || ( \
		python3 -m venv $(VENV) || (echo "ERROR: Could not create venv. On Debian/Ubuntu: sudo apt-get install -y python3-venv" && exit 1); \
		echo "Created $(VENV)" \
	)

deps: venv
	@$(PIP) -q install --upgrade pip
	@$(PIP) -q install -r scripts/requirements.txt
	@echo "Python deps installed into $(VENV)"

smoke: deps
	@$(PY) scripts/pizza_stack_check.py

# --- Local CI runner (no GitHub, no act) ---
ci-local:
	@echo "[CI-LOCAL] Start LocalStack (compose)"
	@docker compose up -d localstack || docker compose up -d
	@echo "[CI-LOCAL] Health check"
	@for i in {1..60}; do curl -s http://localhost:4566/_localstack/health >/dev/null && break; sleep 2; done
	@echo "[CI-LOCAL] Build lambda"; $(MAKE) lambda-build
	@echo "[CI-LOCAL] Terraform init"; $(MAKE) tf-init
	@echo "[CI-LOCAL] Terraform plan"; $(MAKE) tf-plan
	@echo "[CI-LOCAL] Terraform apply"; $(MAKE) tf-apply
	@echo "[CI-LOCAL] Smoke"; $(MAKE) smoke
	@echo "[CI-LOCAL] Destroy (cleanup)"; $(MAKE) tf-destroy || true
	@echo "[CI-LOCAL] Stop LocalStack"; docker compose down || true
	@echo "[CI-LOCAL] Done"

# Danger: resets local terraform & LocalStack data
clean:
	@rm -rf ./.terraform terraform/.terraform terraform/.terraform.lock.hcl terraform/terraform.tfstate* ./.localstack $(VENV)
	@echo "Cleaned terraform state, LocalStack data, and venv"

venv-clean:
	@rm -rf $(VENV)
	@echo "Removed $(VENV)"

