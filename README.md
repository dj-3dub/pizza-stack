# 🍕 Pizza Stack — Serverless on LocalStack with Terraform

🚀 A locally emulated AWS serverless stack built with Terraform and LocalStack — demonstrating cloud IaC, API Gateway + Lambda integration, DynamoDB, and S3 — all wrapped in a fun pizza theme.

✨ **Overview**

This project provisions a **serverless application entirely on LocalStack using Terraform**. It simulates common AWS services without incurring real cloud costs, making it perfect for demos, prototyping, and learning.

**What it builds:**
- **S3 bucket** — `iac-localstack-demo-bucket`  
- **DynamoDB table** — `iac-localstack-demo-table`  
- **Lambda function** — `iac-localstack-hello`  
- **API Gateway REST API** — routes:  
  - `GET /slice/health` → check stack health  
  - `POST /toppings` → increment pizza toppings counter  

✅ A Python smoke test validates the stack with clear success/failure output.

🛠️ **Tech Stack**
- **Infrastructure as Code:** Terraform  
- **Cloud Emulation:** LocalStack  
- **Compute:** AWS Lambda (Python)  
- **Storage:** S3, DynamoDB  
- **API Gateway:** REST endpoints  
- **Automation:** Makefile for repeatable workflows  
- **Validation:** Python (`boto3`, `requests`) smoke checker  
- **CI/CD Ready:** GitHub Actions workflow (`make ci-local` simulates full pipeline)  

📊 **Architecture**

![Architecture](docs/architecture.svg)

---

## Why this matters
- **Zero-cost AWS prototyping:** Emulates common cloud services locally.  
- **IaC-first design:** Everything is reproducible with Terraform.  
- **Serverless experience:** Lambda + API Gateway integration mirrors production patterns.  
- **Automated validation:** Smoke tests + Makefile ensure reliability.  

---

## Elevator pitch (30 seconds)
“Pizza Stack shows I can design a cloud-native serverless stack with IaC and automation. It uses LocalStack to emulate AWS, Terraform for provisioning, and smoke tests to validate health. It’s cost-free, portable, and demonstrates how I approach building resilient, repeatable serverless architectures.”

---

## Quick start

```bash
git clone https://github.com/dj-3dub/pizza-stack.git
cd pizza-stack
make up      # terraform init & apply on LocalStack
make test    # run Python smoke tests
make down    # terraform destroy

Built by Tim Heverin (dj-3dub). If this project is useful, ⭐ the repo and say hi on GitHub.
