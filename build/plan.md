# BMAD Build Phase — Aspire Starter App Deployment

## Objective
Deploy the .NET Aspire Starter App (from https://github.com/dotnet/aspire-samples) to Azure Container Apps using scripted automation.

## Application Components
- AspireStarterApp.Web — Frontend web app.
- AspireStarterApp.API — Backend API service.
- AspireStarterApp.Database — PostgreSQL database (local dev; optional Azure DB).

## Azure Infrastructure
| Resource | Name | Description |
|-----------|------|-------------|
| Resource Group | rg-aspire-demo | Container for all Azure resources |
| Region | westeurope | Deployment region |
| Container Apps Environment | env-aspire | Shared environment for all apps |
| Container Registry | acraspiredemo | Stores built Docker images |
| Log Analytics | log-aspire | Centralized logging |
| Container Apps | aspire-web, aspire-api | Deployed microservices |

## Networking
- Web ingress: External (port 8080)
- API ingress: Internal (port 8081)
- Communication: Web → API via internal DNS

## Constraints
- CLI-based deployment (no portal)
- Build locally or in CI/CD
- Must support parameterized re-deployment
- Future integration: Azure Key Vault for secrets
