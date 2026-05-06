# CLAUDE.md - Project Conventions

## Project Overview

Azure AI Foundry landing zone deployed via Terraform and Azure DevOps CI/CD.

## Project Structure

- `infra/backend/` - Terraform state backend (bootstrap once manually)
- `infra/environments/{dev,staging,prod}/` - Per-environment Terraform configs
- `infra/modules/` - Reusable Terraform modules
- `pipelines/` - Azure DevOps YAML pipelines
- `pipelines/.templates/` - Reusable pipeline step templates
- `docs/` - Architecture and setup documentation
- `diagrams/` - DrawIO architecture diagrams

## Conventions

### Terraform

- Provider version: `azurerm ~> 4.0`
- Required Terraform version: `>= 1.5.0`
- Backend: Azure Storage Account (`stfoundrytfstate` / `tfstate` container)
- State key pattern: `{environment}.terraform.tfstate`
- Naming convention: `{prefix}-{project}-{environment}` (e.g., `rg-foundry-dev`)
- Storage accounts omit hyphens: `st{project}{env}` (e.g., `stfoundrydev`)
- Tags: always include `environment`, `project`, `managed_by`
- Variables go in `variables.tf`, resources in `resources.tf`, outputs in `outputs.tf`
- Never hardcode secrets - use Key Vault references or managed identities

### Azure DevOps

- Service connection naming: `sc-foundry-{env}`
- Environment naming: `foundry-{env}`
- Variable group: `foundry-common`
- Pipeline templates in `pipelines/.templates/`

### Environments

| Environment | Auto Deploy | Approval Gate |
|-------------|-------------|---------------|
| dev | Yes (on merge to main) | None |
| staging | Yes (after dev success) | None |
| prod | No | Manual approval |

### Adding New Infrastructure

1. Create module in `infra/modules/{module-name}/`
2. Reference module in each environment's `resources.tf`
3. Use environment-specific variables for sizing/SKUs
4. PR triggers CI pipeline (validate + plan)
5. Merge triggers CD pipeline (deploy through environments)

## Commands

```bash
# Format check
terraform fmt -check -recursive infra/

# Init a specific environment
cd infra/environments/dev
terraform init -backend-config=backend.tfvars

# Plan
terraform plan -var-file=terraform.tfvars -out=tfplan

# Apply
terraform apply tfplan
```
