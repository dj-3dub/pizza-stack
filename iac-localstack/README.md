# Timlab

Local Infrastructure-as-Code lab using **Terraform** against **LocalStack** (AWS emulator).

## What’s here

- `docker-compose.yml` → LocalStack
- `terraform/` → Provider pinned to LocalStack and a baseline stack:
  - S3 bucket
  - DynamoDB table
- `scripts/` → Helper scripts (awslocal wrapper)
- `diagrams/` → Graphviz `.dot` diagram + Terraform graph
- `Makefile` → QoL: `make up`, `make tf-init`, `make tf-apply`, `make graph`

## Quick start

    cp .env.example .env
    make up               # start LocalStack
    make tf-init          # terraform init
    make tf-plan
    make tf-apply         # provisions into LocalStack
    make graph            # renders diagrams/terraform-graph.svg

## Clean up

    make tf-destroy
    make down
