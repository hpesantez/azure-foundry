# Azure DevOps Setup Guide

## Prerequisites

1. Azure DevOps organization and project
2. Azure subscription(s) for each environment
3. Permissions to create Service Connections and Environments

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

## Step 3: Create Variable Group

Create a variable group named `foundry-common`:

| Variable | Value | Secret? |
|----------|-------|---------|
| `TF_VERSION` | `1.5.0` | No |

Per-environment variables are managed in `terraform.tfvars` files (not in DevOps).

## Step 4: Create Pipelines

1. Go to Pipelines > New Pipeline
2. Select your repository
3. Choose "Existing Azure Pipelines YAML file"
4. Create two pipelines:
   - **CI Pipeline**: Select `pipelines/ci.yml`
   - **CD Pipeline**: Select `pipelines/cd.yml`

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
