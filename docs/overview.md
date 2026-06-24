# IaC - Project Overview

Infrastructure as Code repository for the INENP Weather App platform (WS2026).

It creates the base Google Cloud and Kubernetes infrastructure. The GitOps repository then reconciles
the Kubernetes platform and application state continuously.

**Bootstrap layer:** this repository.

**Reconciliation layer:** [SS2026-INENP-GitOps](https://github.com/MCCE-2025/SS2026-INENP-GitOps).

## Scope & Status

| Area | Details |
| --- | --- |
| **Scope** | Terraform state, GKE, Argo CD, Secret Manager, IAM, WIF, CI OIDC, Cloud SQL, Crossplane identities |
| **Stack** | Terraform, Google Cloud, GKE, Helm provider, Kubernetes provider, kubectl provider |
| **Status** | Active - Terraform bootstraps the platform; Argo CD continues from the GitOps repository |

## Repository Structure

```text
.
|-- README.md
|-- docs/
|   |-- overview.md
|   |-- provisioning.md
|   |-- services.md
|   `-- external-dns.md
|-- bootstrap/
|   |-- init.sh
|   |-- main.tf
|   |-- state-bucket.tf
|   |-- variables.tf
|   `-- outputs.tf
|-- charts/
|   `-- argocd-root-app/
|       |-- Chart.yaml
|       |-- values.yaml
|       `-- templates/application.yaml
|-- .github/
|   |-- ISSUE_TEMPLATE/
|   `-- workflows/
|-- .githooks/
|-- init.sh
|-- terraform.tf
|-- backend.tf
|-- provider.tf
|-- variables.tf
|-- outputs.tf
|-- cluster.tf
|-- node_pool.tf
|-- vpc.tf
|-- argo.tf
|-- argocd-project.tf
|-- argocd-root-app.tf
|-- external-secrets.tf
|-- secret-manager.tf
|-- external-dns.tf
|-- ci-image-push.tf
|-- backend-cloudsql.tf
|-- cloud-sql-*.tf
|-- crossplane*.tf
|-- cert-manager.tf
|-- kargo-secret.tf
|-- dynatrace.tf
`-- avwx-secret.tf
```

## Directory Responsibilities

| Directory/File group | Purpose |
| --- | --- |
| `bootstrap/` | One-time local-state Terraform configuration that creates the GCS bucket for remote Terraform state. |
| `charts/argocd-root-app/` | Tiny Helm chart used by Terraform to install the Argo CD root app. |
| `.github/workflows/` | Repository checks for commits, Markdown, YAML, and Trivy. |
| `.githooks/` | Local pre-commit hooks for YAML, Markdown, and Trivy checks. |
| `cluster.tf`, `node_pool.tf`, `vpc.tf` | GKE cluster, node pool, service account, VPC, and subnet. |
| `argo.tf`, `argocd-*.tf` | Argo CD Helm installation, AppProjects, and root app. |
| `secret-manager.tf`, `external-secrets.tf` | Secret Manager, ESO, ClusterSecretStore, and Argo CD repo secrets. |
| `ci-image-push.tf` | GitHub Actions Workload Identity Federation for frontend/backend image pushes. |
| `backend-cloudsql.tf`, `cloud-sql-*.tf` | Backend Cloud SQL identity, SQL API, and app password secret. |
| `crossplane*.tf` | GCP service accounts and IAM bindings used by Crossplane providers in GitOps. |
| `external-dns.tf`, `cert-manager.tf` | DNS IAM permissions for ExternalDNS and cert-manager DNS-01. |
| `kargo-secret.tf`, `dynatrace.tf` | Optional platform service secrets and identities. |

## Repositories

| Repository | Role | Relevant configuration |
| --- | --- | --- |
| **[SS2026-INENP-IaC][iac]** *(this repo)* | Bootstrap | Terraform state, GKE, IAM, Argo CD |
| **[SS2026-INENP-GitOps][gitops]** | Reconciliation | Argo CD apps, platform, tenants |
| **[SS2026-INENP-frontend][frontend]** | Frontend | Uses IaC-provided CI identity |
| **[SS2026-INENP-backend][backend]** | Backend | Uses IaC-provided CI and Cloud SQL identities |

## Ownership Model

Terraform owns the base infrastructure and identity wiring. GitOps owns Kubernetes reconciliation after
bootstrap.

```text
Terraform
  -> state bucket
  -> GKE, VPC, node pool
  -> Argo CD installation
  -> Argo CD projects and root app
  -> Secret Manager containers
  -> External Secrets Operator
  -> Workload Identity and IAM
  -> CI OIDC federation

Argo CD / GitOps
  -> platform Applications
  -> frontend/backend Helm releases
  -> tenants
  -> Crossplane-managed cloud resources
```

## Main Outputs

| Output | Purpose |
| --- | --- |
| `project_id` | GCP project ID used for the deployment |
| `region` / `zone` | GCP location defaults |
| `kubernetes_cluster_name` | GKE cluster name |
| `kubernetes_cluster_gcloud_command` | Command to fetch cluster credentials |
| `argocd_root_app` | Root app summary |
| `external_dns_principal` | Workload Identity principal bound to Cloud DNS |
| `external_dns_dns_name` | Managed zone DNS name |
| `ci_wif_provider` | GitHub Actions OIDC provider for app release workflows |
| `ci_image_push_service_account` | CI service account for GAR pushes |
| `kargo_admin_password` | Sensitive Kargo admin password |

## AI-assisted development

We used AI tools (**Cursor** and **ChatGPT**) as support throughout the project.
They did not replace review and ownership. They helped draft:

- GitHub issues
- Pull request descriptions
- Terraform configuration
- Workload Identity and IAM bindings
- Secret Manager and ESO wiring
- Documentation (including this repo's `docs/`)

All AI-generated content was reviewed, adapted, and validated by the team before merge.

[backend]: https://github.com/MCCE-2025/SS2026-INENP-backend
[frontend]: https://github.com/MCCE-2025/SS2026-INENP-frontend
[gitops]: https://github.com/MCCE-2025/SS2026-INENP-GitOps
[iac]: https://github.com/MCCE-2025/SS2026-INENP-IaC
