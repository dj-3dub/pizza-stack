🍕 Pizza Stack — Serverless on LocalStack with Terraform

🚀 A locally emulated AWS serverless stack built with Terraform and LocalStack — demonstrating cloud IaC, API Gateway + Lambda integration, DynamoDB, and S3 — all wrapped in a fun pizza theme.

✨ Overview

This project provisions a serverless application entirely on LocalStack using Terraform.
It simulates common AWS services without incurring real cloud costs, making it perfect for demos, prototyping, and learning.

What it builds:

S3 bucket — iac-localstack-demo-bucket

DynamoDB table — iac-localstack-demo-table

Lambda function — iac-localstack-hello

API Gateway REST API — routes:

GET /slice/health (check stack health)

POST /toppings (increment pizza toppings counter)

A Python smoke test validates the stack with clear ✅/❌ output.

🛠️ Tech Stack

Infrastructure as Code: Terraform

Cloud Emulation: LocalStack

Compute: AWS Lambda (Python)

Storage: S3, DynamoDB

API Gateway: REST endpoints

Automation: Makefile for repeatable workflows

Validation: Python (boto3, requests) smoke checker

CI/CD Ready: Local GitHub Actions workflow (make ci-local simulates full pipeline)

## 📂 Project Structure

```text
pizza-stack/
├── terraform/                  # Terraform IaC for S3, DynamoDB, Lambda, API Gateway
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── lambda/
│       ├── hello.py
│       └── build.sh
├── scripts/
│   ├── pizza_stack_check.py    # Python smoke test (✅/❌)
│   └── requirements.txt
├── docs/
│   ├── architecture.dot        # Graphviz diagram source (with legend)
│   ├── architecture.svg        # Rendered system diagram (used in README)
│   └── architecture.png        # PNG export (good for LinkedIn)
├── docker-compose.yml          # LocalStack container
├── Makefile                    # Automation (up, tf-apply, smoke, arch, ci-local, etc.)
└── README.md


🚀 Usage
1. Start LocalStack
make up

2. Build the Lambda
make lambda-build

3. Provision the stack
make tf-init
make tf-apply

4. Run smoke tests
make smoke


✅ LocalStack edge reachable
✅ S3 bucket exists
✅ DynamoDB table exists
✅ API Gateway routes responding

5. Full local CI run
make ci-local


Runs the complete pipeline: start LocalStack → build Lambda → Terraform apply → smoke checks → destroy → shutdown.

🖼️ Architecture Diagram

![Architecture](docs/architecture.svg)

🔑 Key Skills Demonstrated

Infrastructure as Code (Terraform)

AWS serverless design (Lambda, API Gateway, DynamoDB, S3)

Cloud emulation with LocalStack

Automated validation with Python (boto3, requests)

Build automation with Makefile

CI/CD workflow design

