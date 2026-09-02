# Brief: Self-Monitoring, Self-Triaging Demo App

> **Read this entire document before writing any code or provisioning any resource.**
> This is written so an agent starting from a blank context can pick this up and execute
> it without needing to re-derive decisions already made. If something here is ambiguous
> or missing, stop and ask — don't guess on anything involving cost, security, or
> destructive actions.

## 1. Overall goal

Prove out a repeatable pattern: deploy a real AI agent app on top of the existing Azure
AI Foundry landing zone, monitor it automatically, and when it breaks, have an agent
investigate the failure and open a Pull Request with a proposed fix (or flag it as
non-code-fixable) — with a human always reviewing before merge. This is a proof of
concept; once validated, the same pattern gets applied to real A2A / A2UI production
agents.

This is **not** part of the `azure-foundry` landing zone repo itself — it's a separate
initiative that *consumes* resources from that landing zone. See §3 for the repo/infra
boundary rationale.

## 2. What already exists (do not re-provision these)

Repo: `azure-foundry` (owner `hpesantez`), the shared Azure AI Foundry landing zone.
Only the `dev` environment is deployed. Full details live in that repo's
[`PROJECT_NOTES.md`](../../PROJECT_NOTES.md) and [`BACKLOG.md`](../../BACKLOG.md) —
read those too if you have access to that repo.

**Live resources today (subscription: "Visual Studio Professional Subscription", verified 2026-09-02):**

| Resource | Name | Notes |
|---|---|---|
| Resource group | `rg-foundry-dev` | region `eastus2` |
| Azure OpenAI | `oai-foundry-dev` | custom subdomain `oai-foundry-dev-baa8` |
| AI Search | `srch-foundry-dev-baa8` | region `eastus` (capacity constraint, differs from main region) |
| Key Vault | `kv-foundry-dev-baa8` | RBAC-authorized, purge protection **disabled** |
| Storage Account | `stfoundrydevbaa8` | LRS |
| Log Analytics | `log-foundry-dev` | 30-day retention |
| Application Insights | `appi-foundry-dev` | linked to the Log Analytics workspace above |
| AI Foundry Hub | `aihub-foundry-dev` | |
| AI Foundry Project | `aiprj-foundry-dev` | |

**Terraform remote state for the above** (verified real values — do not trust the
example values in `azure-foundry/docs/azure-devops-setup.md`, they're wrong):
- Backend resource group: `rg-foundry-state`
- Backend storage account: `stfoundryterraformstate`
- Backend container: `tfstate-dev`
- State key: `dev.terraform.tfstate`

Read the live endpoint/ID values via Terraform outputs from that state (don't hardcode
secrets, and don't re-derive them by calling Azure APIs unnecessarily — a
`terraform_remote_state` data source against the above backend is the correct way to
consume `openai_endpoint`, `key_vault_uri`, `search_service_name`, `ai_hub_id`,
`ai_project_id` — see `azure-foundry/infra/environments/dev/outputs.tf`).

**Not yet deployed**: staging/prod environments of the landing zone. Irrelevant to this
initiative — build against `dev` only.

## 3. Repo & infra boundary (decision — do not relitigate without asking the user)

- `azure-foundry` stays **shared platform only**. Do not add app-specific resources
  there.
- This initiative gets its **own new GitHub repo** (name/URL: **not yet decided — ask
  the user**, do not invent one) containing:
  - The app code (forked/vendored sample, see §4)
  - Its own `infra/` Terraform root, with its **own Terraform state**, separate from
    the landing zone's state (do not reuse `dev.terraform.tfstate`)
  - That Terraform provisions everything this initiative owns inside **one dedicated
    resource group**, suggested name `rg-foundry-a2ui-demo-dev` (confirm naming with
    the user — it should follow the `{prefix}-{project}-{environment}` convention from
    `CLAUDE.md`, adapted for a sub-project)
- The app repo's Terraform reads shared values (OpenAI endpoint, Search endpoint, Log
  Analytics workspace ID) via `terraform_remote_state` pointed at the backend in §2 —
  never redeclares/duplicates those resources.
- **Decommissioning**: because everything this initiative owns lives in one resource
  group under one Terraform state, cleanup is `terraform destroy` in the app repo (or
  `az group delete -n <that-resource-group>` as an emergency fallback). Document this in
  the new repo's own README once created.

## 4. The application

Use an existing open-source sample instead of writing one from scratch:
**[`Azure-Samples/azure-search-openai-demo`](https://github.com/Azure-Samples/azure-search-openai-demo)**
— a RAG chat app already built for Azure OpenAI + Azure AI Search + Application
Insights, ships a `Dockerfile`.

- Point it at the **existing dev** `oai-foundry-dev` and `srch-foundry-dev-baa8`
  resources (via remote state, §3) — do not provision new OpenAI/Search instances.
- Deploy it as a container on **Azure Container Apps**, using the **Consumption workload
  profile** (scales to zero when idle — cheapest option for a test/demo app).
- The Container Apps Environment should reuse `log-foundry-dev` (the existing Log
  Analytics workspace) rather than creating a new one — one less resource to manage/pay
  for, and keeps all telemetry queryable in one place.

## 5. Monitoring

Add, as part of the new app repo's Terraform (in its own resource group):
- Azure Monitor **alert rules** on the app's Application Insights telemetry:
  - Exception rate above a threshold (threshold: **not yet decided — ask the user**)
  - Dependency failures (calls to OpenAI/Search failing)
- An **Action Group** that these alert rules notify, which invokes the triage Function
  (§6).

"Status" for this app means: healthy (no open issues) vs. unhealthy (a list of active
issues, each linked either to an open PR with a suggested fix, or a flag saying "not
code-fixable, likely external" with the supporting evidence).

## 6. Triage agent (Azure Function)

Provisioned in the same new resource group. Triggered by the Action Group above.

**What it does when triggered:**
1. Reads the error details from Application Insights / Log Analytics (read-only query).
2. Looks at the app repo's recent commit history to see if the failing code path
   changed recently.
3. Classifies the issue:
   | Classification | Evidence | Action |
   |---|---|---|
   | **Code bug** | Stack trace points into app code; that code changed recently | Create a branch, write a suggested fix, open a PR with the error context attached |
   | **External/environmental** | Exception is a dependency failure (rate limit, timeout, auth expiry); no recent code change near the failure | Flag only (e.g. comment on a tracking issue) — **do not open a misleading PR** |
   | **Unclear** | Signals conflict or insufficient data | Flag for human triage, no automated action |
4. **Never auto-merges anything.** Branch protection on the app repo must require human
   review regardless of what the agent does.

**Hosting plan: Consumption (Y1).** This Function only runs when an alert fires — no
benefit from a warm/dedicated instance, and Consumption scales to zero (near-zero cost
when nothing's broken). Only move to Premium/Dedicated if you later need VNet
integration, no cold-starts, or executions longer than 10 minutes — none apply today.
The Consumption plan requires its own Storage Account for the Functions runtime —
create a small dedicated one inside this initiative's resource group, do **not** reuse
`stfoundrydevbaa8` from the landing zone, so it's destroyed along with everything else
on cleanup.

**Least privilege (required, not optional):**
- The Function's Azure identity: system-assigned managed identity, granted only
  `Monitoring Reader` on the app's resource group. No write access to any Azure
  resource.
- GitHub write access: a **GitHub App** (not a broad personal access token) installed
  only on the new app repo, permissions limited to `contents: write` and
  `pull_requests: write` — nothing else. Its private key lives in a Key Vault, fetched
  via the Function's managed identity — never hardcoded, never in chat, never committed.
- **Dedup/cooldown**: track an alert fingerprint (exception type + stack hash, e.g. in
  Table Storage) so a recurring error doesn't spam duplicate PRs — one open PR per
  fingerprint at a time.
- **Redact secrets** from stack traces/log excerpts before they're posted into any PR
  body or issue comment.

## 7. Build order

1. Create the new app repo (ask user for name if not already decided).
2. Add its `infra/` Terraform root: resource group, Container Apps Environment (reusing
   `log-foundry-dev`), Container App running `azure-search-openai-demo`, wired to the
   existing dev OpenAI/Search via remote state.
3. Add the alert rules + Action Group (still same Terraform root, same resource group).
4. Build the triage Function with the classification logic in §6, least-privilege
   identity, and a GitHub App scoped to that one repo.
5. Deliberately introduce a bug in the sample app and validate the full loop end-to-end
   (error appears in App Insights → alert fires → Function runs → correct
   classification → sensible PR or flag) before trusting it on anything else.

## 8. Open decisions — ask the user, do not assume

- [ ] New repo name/URL
- [ ] Exact resource group name for this initiative (suggested `rg-foundry-a2ui-demo-dev`)
- [ ] Alert thresholds (error rate %, latency, time window)
- [ ] Who/what should own creating the GitHub App and its installation
- [ ] Budget/cost expectations for the new Container App + Function (this is billable
      infra, confirm before deploying)
