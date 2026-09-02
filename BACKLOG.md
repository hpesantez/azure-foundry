# Backlog

Tracks what's done, in progress, broken, and planned for the Azure AI Foundry landing zone.
Last reviewed: 2026-09-02 (code review + live Azure inventory of the dev subscription).

## ✅ Completed

- Terraform structure in place: `infra/backend` (state storage) + `infra/environments/{dev,staging,prod}` (parity configs) + `infra/modules` convention documented.
- `dev` environment is **live in Azure** (`rg-foundry-dev`): Log Analytics, Application Insights, Key Vault, Storage Account, Azure OpenAI, AI Search, AI Foundry Hub + Project — all match `infra/environments/dev/resources.tf`.
- Terraform state backend (`rg-foundry-state`) is live with a storage account (see naming drift bug below).
- CI (`pipelines/ci.yml`) validates formatting and plans the `dev` environment on PRs touching `infra/**`.
- CD (`pipelines/cd.yml`) wired for a 3-stage promotion (dev → staging → prod) with a manual approval gate modeled for prod.
- `name_suffix` variable added so globally-unique resources (Key Vault, Storage, Search) don't collide across environments.
- `search_location` split from `location` to work around AI Search regional capacity constraints.
- Variable-group-driven `TF_VAR_*` approach adopted — no committed `terraform.tfvars`.
- OIDC (`ARM_USE_OIDC`) wired into the `terraform-plan`/`terraform-apply` templates.

## 🔧 In Progress / Pending

- **Staging and Prod are not deployed** — only `rg-foundry-state` and `rg-foundry-dev` exist in Azure today.
- Network hardening (private endpoints, VNet, NSGs) — explicitly deferred in `docs/architecture.md`, still public endpoints everywhere.
- No resource locks (`CanNotDelete`) on any resource group — should exist before a real prod deploy.
- Key Vault purge protection is disabled (`enablePurgeProtection: null`) on the live dev vault — acceptable for dev, worth reconsidering for staging/prod.
- Storage accounts allow blob public access (`allowBlobPublicAccess: true`) by default; not explicitly locked down in Terraform.

## 🐛 Bugs / Known Issues

1. **Backend storage account name drift**: `infra/backend/state.tf` defines `st${project_name}tfstate` → `stfoundrytfstate`, but the real deployed account is `stfoundryterraformstate`. Running `terraform apply` in `infra/backend` today would not match/manage the real resource.
2. **Backend container name drift**: code defines container `tfstate`, but the real container in use is `tfstate-dev`. The example in `docs/azure-devops-setup.md` (`TF_BACKEND_CONTAINER`) doesn't match either.
3. **CD pipeline uses the wrong service connection for staging/prod**: `pipelines/cd.yml` hardcodes `sp-foundry-dev` for the staging and prod stages (flagged inline with `# Needs to change to staging/prod SP`). Running CD today would deploy staging/prod through the dev subscription's identity, not a scoped one.
4. **Naming convention mismatch**: `CLAUDE.md` / `docs/azure-devops-setup.md` describe service connections as `sc-foundry-{env}`, but the pipeline YAML actually references `sp-foundry-dev`.
5. `terraform-init.yml` authenticates with a storage account access key (`az storage account keys list`) while `terraform-plan.yml`/`terraform-apply.yml` use OIDC — two different auth models for the same pipeline run.
6. An auto-created "Failure Anomalies" smart detector alert rule exists in `rg-foundry-dev` but isn't managed by Terraform (cosmetic drift, not urgent).

## 📋 To Do / Continue

- [ ] Reconcile `infra/backend/*.tf` with the real backend resource names (rename in code to match reality, or import/rename the Azure resources).
- [ ] Create `sp-foundry-staging` / `sp-foundry-prod` service connections in Azure DevOps and update `cd.yml` + `ci.yml` accordingly.
- [ ] Standardize on OIDC for the Terraform init step too (drop the storage key retrieval).
- [ ] Add resource group locks ahead of first prod deploy.
- [ ] Decide on private networking scope for staging/prod.
- [ ] Deploy staging and prod environments once the service-connection bug is fixed.
- [ ] Revisit Key Vault purge protection policy per environment.

## 🆕 New Initiative: Self-Monitoring / Self-Triaging Demo App

Full spec/brief (read before starting): [docs/new-app/README.md](docs/new-app/README.md)

- [ ] Create new app repo (separate from this landing zone repo)
- [ ] Provision app-specific infra (Container App running `azure-search-openai-demo`, Container Apps Environment) in its own resource group, referencing this landing zone's dev outputs via remote state
- [ ] Add App Insights alert rules + Action Group for the new app
- [ ] Build the least-privilege triage Function (classifies real bug vs. external, opens PR or flags — never auto-merges)
- [ ] Validate the end-to-end loop with a deliberately broken change
- [ ] Document decommission steps (dedicated resource group + `terraform destroy`) in the new repo
