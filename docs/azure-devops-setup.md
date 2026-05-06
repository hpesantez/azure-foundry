# Azure DevOps Setup Guide

## Prerequisites

1. Azure DevOps organization and project
2. Azure subscription(s) for each environment
3. Permissions to create Service Connections and Environments
4. Microsoft-hosted Ubuntu agent or self-hosted agent with `bash`, `az`, and network access to install Terraform

### Pipeline Task Compatibility

This repository uses built-in Azure DevOps tasks (`AzureCLI@2`, `PublishPipelineArtifact@1`, and `DownloadPipelineArtifact@2`) plus Terraform CLI commands.

No Terraform marketplace extension is required.

## Step 1: Create Service Connections

Create an ARM service connection for each environment:

| Name | Subscription | Purpose |
|------|--------------|---------|
| `sc-foundry-dev` | Dev subscription | Dev deployments |
| `sc-foundry-staging` | Staging subscription | Staging deployments |
| `sc-foundry-prod` | Prod subscription | Prod deployments |

**Recommended**: Use Workload Identity Federation (OIDC) instead of secrets.

Navigate to: Project Settings > Service Connections > New > Azure Resource Manager > Workload Identity Federation

## Step 2: Create Environments with Approval Gates

Create these environments in Azure DevOps:

### foundry-dev
- No approval gates (auto-deploy)

### foundry-staging
- Approval gate: Auto after `foundry-dev` deploys successfully

### foundry-prod
- **Manual approval required**
- Add approvers: Platform team leads
- Timeout: 72 hours

Navigate to: Pipelines > Environments > New Environment

For each environment, add checks:
- Approvals and Checks > Approvals > Add approvers

## Step 3: Create Variable Groups

Terraform variables are passed via `TF_VAR_` environment variables from Azure DevOps variable groups. **No `terraform.tfvars` files are committed.**

### `foundry-common` (shared across all environments)

| Variable | Value | Secret? |
|----------|-------|---------|
| `TF_VAR_project_name` | `foundry` | No |
| `TF_VAR_location` | `eastus2` | No |

### `foundry-dev`

| Variable | Value | Secret? |
|----------|-------|---------|
| `TF_VAR_subscription_id` | `<your-dev-subscription-id>` | Yes |
| `TF_VAR_environment` | `dev` | No |

### `foundry-staging`

| Variable | Value | Secret? |
|----------|-------|---------|
| `TF_VAR_subscription_id` | `<your-staging-subscription-id>` | Yes |
| `TF_VAR_environment` | `staging` | No |

### `foundry-prod`

| Variable | Value | Secret? |
|----------|-------|---------|
| `TF_VAR_subscription_id` | `<your-prod-subscription-id>` | Yes |
| `TF_VAR_environment` | `prod` | No |

Navigate to: Pipelines > Library > + Variable group

## Step 4: Create Pipelines

1. Go to Pipelines > New Pipeline
2. Select your repository
3. Choose "Existing Azure Pipelines YAML file"
4. Create two pipelines:
   - **CI Pipeline**: Select `pipelines/ci.yml`
   - **CD Pipeline**: Select `pipelines/cd.yml`

These pipelines install Terraform on the agent when needed and execute `terraform init/validate/plan/apply` via Azure CLI-authenticated bash steps.

## Step 5: Branch Policies

Set up branch policies on `main`:

1. Go to Repos > Branches > main > Branch policies
2. Enable:
   - Require a minimum number of reviewers (1+)
   - Check for linked work items
   - Build validation: Add CI pipeline
   - Require comment resolution

## Service Principal Permissions

Each service principal needs these roles on its target subscription:

- **Contributor** - For resource provisioning
- **User Access Administrator** - For RBAC assignments
- **Key Vault Administrator** - For Key Vault operations
- **Cognitive Services Contributor** - For AI services
