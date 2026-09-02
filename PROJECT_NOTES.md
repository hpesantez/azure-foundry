# Project Notes

**Read this file before doing anything else in this repo.** It captures verified facts,
commands, and gotchas discovered during real work sessions so we don't re-discover the
same things (or go in circles) every time. See [BACKLOG.md](BACKLOG.md) for what's done/pending/broken.

## Current Deployed State (verified 2026-09-02)

Subscription: "Visual Studio Professional Subscription".

| Resource Group | Status |
|---|---|
| `rg-foundry-state` | Live — Terraform state backend |
| `rg-foundry-dev` | Live — full stack (Log Analytics, App Insights, Key Vault, Storage, OpenAI, AI Search, AI Foundry Hub/Project) |
| `rg-foundry-staging` | **Not deployed** |
| `rg-foundry-prod` | **Not deployed** |

## ⚠️ Verified backend values (differ from what the code/docs imply!)

The real backend storage does **not** match `infra/backend/state.tf` or the examples in
`docs/azure-devops-setup.md`. Use these real values, not the doc examples:

- Backend resource group: `rg-foundry-state`
- Backend storage account: `stfoundryterraformstate` (code implies `stfoundrytfstate` — wrong)
- Backend container: `tfstate-dev` (code implies `tfstate` — wrong)
- State key pattern: `{environment}.terraform.tfstate`

See BACKLOG bug #1/#2 — this needs reconciling, don't "fix" one side without checking with the team first.

## Authenticating `az` CLI in this dev container

- `az login --use-device-code` is **blocked by tenant Conditional Access policy** (confirmed — sign-in succeeds but access is denied). Don't retry it, it won't work.
- Use a service principal instead:
  ```bash
  az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID"
  az account set --subscription "$AZURE_SUBSCRIPTION_ID"
  ```
- To create a **read-only** SP for review purposes (from Azure Cloud Shell, already authenticated via the portal):
  ```bash
  az ad sp create-for-rbac --name "sp-foundry-readonly" --role "Reader" --scopes "/subscriptions/<SUBSCRIPTION_ID>"
  ```
- Never paste client secrets into chat — export them directly in your own terminal.
- `az` and `terraform` are **not preinstalled** in this dev container. Install with:
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```

## Common Commands

```bash
# Format check (from repo root)
terraform fmt -check -recursive infra/

# Init dev (real backend values, see above)
cd infra/environments/dev
terraform init \
  -backend-config="resource_group_name=rg-foundry-state" \
  -backend-config="storage_account_name=stfoundryterraformstate" \
  -backend-config="container_name=tfstate-dev" \
  -backend-config="key=dev.terraform.tfstate"

# Plan / Apply
terraform plan -var="subscription_id=<sub-id>" -out=tfplan
terraform apply tfplan

# Inspect what's actually live (non-secret metadata only)
az resource list -g rg-foundry-dev -o table
```

## Gotchas

- `pipelines/cd.yml` staging/prod stages still point at the **dev** service connection (`sp-foundry-dev`) — do not run the CD pipeline for staging/prod until this is fixed (see BACKLOG bug #3).
- `dev`, `staging`, `prod` `resources.tf` files are intentionally identical (environment parity by design) — differences are meant to come from variables/SKUs, not duplicated code.
- No `.tfvars` files are committed on purpose — all `TF_VAR_*` values come from Azure DevOps variable groups (`foundry-common`, `foundry-dev`, `foundry-staging`, `foundry-prod`).

## Where Things Live

- Terraform environments: `infra/environments/{dev,staging,prod}`
- Terraform state backend: `infra/backend`
- Pipeline definitions: `pipelines/ci.yml`, `pipelines/cd.yml`
- Reusable pipeline steps: `pipelines/.templates`
- Architecture reference: [docs/architecture.md](docs/architecture.md)
- Azure DevOps setup guide: [docs/azure-devops-setup.md](docs/azure-devops-setup.md)
- Repo-wide conventions: [CLAUDE.md](CLAUDE.md)
