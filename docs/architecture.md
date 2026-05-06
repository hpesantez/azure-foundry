# Architecture Documentation

## Design Principles

1. **Modular** - Each Azure service is a self-contained Terraform module
2. **Environment parity** - Same modules, different configs per environment
3. **Least privilege** - Managed identities, RBAC, no shared keys
4. **Observable** - Centralized logging and monitoring from day one
5. **Extensible** - Easy to add new AI services, connectors, and applications

## High-Level Architecture

### Landing Zone Components

```
┌─────────────────────────────────────────────────────────────────┐
│ Azure DevOps                                                     │
│  ├── Pipelines (CI/CD)                                          │
│  ├── Environments (Dev/Staging/Prod with approval gates)        │
│  └── Variable Groups (per environment)                          │
└─────────────────────────┬───────────────────────────────────────┘
                          │ Service Principal (OIDC)
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ Azure Subscription                                               │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Resource Group: rg-foundry-{env}                          │   │
│  │                                                            │   │
│  │  ┌─────────────────────┐  ┌─────────────────────────┐   │   │
│  │  │ AI Foundry Hub       │  │ Key Vault               │   │   │
│  │  │  ├── AI Project      │  │  └── Secrets/Keys       │   │   │
│  │  │  ├── Model Deploys   │  └─────────────────────────┘   │   │
│  │  │  ├── Connections     │                                  │   │
│  │  │  │   ├── Teams       │  ┌─────────────────────────┐   │   │
│  │  │  │   ├── Email       │  │ Storage Account         │   │   │
│  │  │  │   └── Custom      │  │  └── AI Data/Artifacts  │   │   │
│  │  │  └── Agent Framework │  └─────────────────────────┘   │   │
│  │  └─────────────────────┘                                  │   │
│  │                                                            │   │
│  │  ┌─────────────────────┐  ┌─────────────────────────┐   │   │
│  │  │ AI Services          │  │ Application Insights    │   │   │
│  │  │  ├── OpenAI          │  │  └── Monitoring/Traces  │   │   │
│  │  │  ├── AI Search       │  └─────────────────────────┘   │   │
│  │  │  └── Content Safety  │                                  │   │
│  │  └─────────────────────┘  ┌─────────────────────────┐   │   │
│  │                            │ Log Analytics Workspace │   │   │
│  │                            │  └── Diagnostics        │   │   │
│  │                            └─────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Resource Group: rg-foundry-state                          │   │
│  │  └── Storage Account (Terraform State)                    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Azure AI Foundry Components

### Hub & Project

- **AI Foundry Hub**: Central governance point, shared connections, policies
- **AI Project**: Workspace for agentic AI development and testing

### Agent Framework

The primary use case - testing agentic AI pipelines:

- **A2A (Agent-to-Agent)**: Multi-agent orchestration patterns
- **A2UI (Agent-to-UI)**: User-facing agent interactions
- **Connectors**: Teams, Email, custom APIs

### Supporting Services

| Service | Purpose |
|---------|---------|
| Azure OpenAI | LLM model hosting (GPT-4o, etc.) |
| AI Search | Knowledge retrieval for agents |
| Content Safety | Input/output filtering |
| Key Vault | Secret management |
| Storage Account | Data, artifacts, agent state |
| Application Insights | Tracing, monitoring |
| Log Analytics | Centralized logging |

## Network Architecture (Future)

Currently deployed with public endpoints for dev agility. Future iterations will add:

- Private Endpoints for all PaaS services
- VNet integration
- NSG rules
- Azure Firewall (if needed)

## Security Model

- **Authentication**: Managed Identities (system-assigned where possible)
- **Authorization**: Azure RBAC, least privilege
- **Secrets**: Key Vault, no hardcoded credentials
- **Data**: Encryption at rest (platform-managed keys initially)
- **Pipeline**: Service Principal with scoped permissions per environment

## CI/CD Flow

```
PR Created → Validate + Plan → Review Plan in PR Comment
    │
    ▼ (merge to main)
Deploy Dev (auto) → Deploy Staging (auto after Dev success)
                         │
                         ▼ (manual approval)
                    Deploy Prod
```

## Naming Convention

```
{resource-prefix}-{project}-{component}-{environment}
```

Examples:
- `rg-foundry-dev` (resource group)
- `kv-foundry-dev` (key vault)
- `st-foundry-dev` (storage, no hyphens)
- `aihub-foundry-dev` (AI Hub)
- `aiprj-foundry-dev` (AI Project)
