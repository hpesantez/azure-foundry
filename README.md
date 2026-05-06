# Azure AI Foundry - Infrastructure as Code

## Overview

This project deploys Azure AI Foundry infrastructure via Terraform, orchestrated through Azure DevOps CI/CD pipelines. The goal is to provide a landing zone for testing agentic AI pipelines, including:

- **Agent-to-Agent (A2A)** communication patterns
- **Agent-to-UI** interaction frameworks
- **Azure AI Agent Framework** deployments
- **Connectors**: Microsoft Teams, Email, and other integrations

## Architecture

See [docs/architecture.md](docs/architecture.md) for detailed architecture documentation.
See [diagrams/architecture.drawio](diagrams/architecture.drawio) for visual architecture diagram.

## Project Structure

```
azure-foundry/
├── docs/                       # Documentation
│   ├── architecture.md         # Architecture decisions and design
│   └── runbooks/               # Operational runbooks
├── diagrams/                   # DrawIO architecture diagrams
├── infra/
│   ├── backend/                # Terraform state backend setup
│   ├── modules/                # Reusable Terraform modules
│   └── environments/
│       ├── dev/                # Development environment
│       ├── staging/            # Staging environment
│       └── prod/               # Production environment
├── pipelines/                  # Azure DevOps pipeline definitions
│   └── .templates/             # Reusable pipeline templates
├── scripts/                    # Helper scripts
└── CLAUDE.md                   # AI assistant conventions
```

## Environments

| Environment | Purpose | Approval Gate |
|-------------|---------|---------------|
| Dev | Rapid iteration, feature testing | None (auto-deploy on PR merge) |
| Staging | Integration testing, validation | Dev deploy success |
| Prod | Stable baseline | Manual approval required |

## Getting Started

### Prerequisites

- Azure CLI (`az`) authenticated
- Terraform >= 1.5
- Azure DevOps organization with project created
- Service Principal with Contributor + User Access Administrator on target subscriptions

### Bootstrap State Backend

```bash
cd infra/backend
terraform init
terraform apply
```

### Deploy an Environment

```bash
cd infra/environments/dev
terraform init -backend-config=backend.tfvars
terraform plan -out=tfplan
terraform apply tfplan
```

## CI/CD Pipeline

The Azure DevOps pipeline handles:

1. **Validate** - `terraform fmt -check` + `terraform validate`
2. **Plan** - Generate execution plan, publish as artifact
3. **Apply (Dev)** - Auto-apply on main branch merge
4. **Apply (Staging)** - Apply after Dev success + environment approval
5. **Apply (Prod)** - Apply after manual approval gate

## Adding Infrastructure

This project is designed for ad-hoc infrastructure additions. To add new resources:

1. Create or update a module in `infra/modules/`
2. Reference it in the appropriate environment
3. Submit a PR - the pipeline validates and plans automatically
4. After merge, deployment progresses through environments
