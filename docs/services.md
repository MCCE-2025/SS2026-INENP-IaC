# Infrastructure Services

This document defines the infrastructure services and responsibilities managed by this repository.

## Core Infrastructure

| Service | Files | Purpose |
|---|---|---|
| Terraform state bucket | `bootstrap/state-bucket.tf` | Creates `terraform-state-<project-id>` for remote Terraform state. |
| GCP provider setup | `provider.tf`, `terraform.tf`, `variables.tf` | Configures project, region, zone, providers, and input variables. |
| Remote backend | `backend.tf`, `init.sh` | Uses the bootstrap-created GCS bucket for platform Terraform state. |
| VPC and subnet | `vpc.tf` | Creates the network and subnet for the GKE cluster. |
| GKE cluster | `cluster.tf` | Creates `platform-gke-cluster` with Workload Identity and advanced datapath. |
| Node pool | `node_pool.tf` | Creates autoscaled worker nodes and node service account. |
| Kubernetes/Helm providers | `k8s-providers.tf` | Configures Terraform providers against the created GKE cluster. |

## Argo CD Bootstrap

| Service | Files | Purpose |
|---|---|---|
| Argo CD | `argo.tf` | Installs Argo CD through the official Helm chart. |
| Argo CD AppProjects | `argocd-project.tf` | Creates `platform` and `apps` projects with allowed repositories and destinations. |
| Argo CD root app | `argocd-root-app.tf`, `charts/argocd-root-app/` | Installs the app-of-apps root Application that syncs GitOps `argocd/applications`. |
| Repository credentials | `external-secrets.tf`, `secret-manager.tf` | Syncs GitHub App credentials from Secret Manager into Argo CD repository secrets. |

## Secrets

| Service | Files | Purpose |
|---|---|---|
| Secret Manager API | `secret-manager.tf` | Enables Secret Manager. |
| GitHub App secret containers | `secret-manager.tf` | Creates empty containers for Argo CD GitHub App credentials. Values are uploaded manually. |
| External Secrets Operator | `external-secrets.tf` | Installs ESO and configures access to GCP Secret Manager. |
| ClusterSecretStore | `external-secrets.tf` | Defines `gcp-secret-manager` as the cluster-wide secret source. |
| AVWX API token container | `avwx-secret.tf` | Creates the Secret Manager container for the backend AVWX token. |
| Cloud SQL app password | `cloud-sql-secrets.tf` | Generates and stores the backend database password. |
| Kargo secrets | `kargo-secret.tf` | Generates Kargo admin password hash and token signing key, then syncs them to the cluster. |
| Dynatrace token containers | `dynatrace.tf` | Creates Secret Manager containers for Dynatrace operator/data-ingest tokens. |

## Identity and IAM

| Service | Files | Purpose |
|---|---|---|
| External Secrets Workload Identity | `secret-manager.tf`, `external-secrets.tf` | Lets ESO read Secret Manager without static keys. |
| GitHub Actions OIDC | `ci-image-push.tf` | Allows frontend/backend release workflows to push images to GAR without service account keys. |
| Backend Cloud SQL identity | `backend-cloudsql.tf` | Lets backend pods use Cloud SQL Auth Proxy via Workload Identity. |
| ExternalDNS DNS permissions | `external-dns.tf` | Grants Cloud DNS access to the ExternalDNS Kubernetes service account principal. |
| cert-manager DNS permissions | `cert-manager.tf` | Lets cert-manager solve DNS-01 challenges in Cloud DNS. |
| Crossplane GAR identity | `crossplane.tf` | Lets Crossplane manage Artifact Registry resources. |
| Crossplane SQL identity | `crossplane-sql.tf` | Lets Crossplane manage Cloud SQL resources. |
| Crossplane Storage identity | `crossplane-storage.tf` | Lets Crossplane manage the frontend GCS hosting bucket. |
| OpenBao KMS identity | `openbao-autounseal.tf` | Lets OpenBao use Cloud KMS for auto-unseal. |

## Application Support

| Service | Files | Purpose |
|---|---|---|
| CI image push service account | `ci-image-push.tf` | Service account used by frontend/backend GitHub Actions to push release images. |
| Artifact Registry reader for nodes | `crossplane.tf` | Lets GKE nodes pull images from GAR. |
| Backend runtime service account | `backend-cloudsql.tf` | GCP service account annotated on backend Kubernetes service accounts. |
| Cloud SQL password secret | `cloud-sql-secrets.tf` | Shared backend DB password synced to workloads by GitOps/ESO. |
| Tenant Workload Identity bindings | `backend-cloudsql.tf` | Discovers tenant namespaces from the GitOps repo and grants backend Workload Identity access. |

## Optional / Operational Services

| Service | Files | Purpose |
|---|---|---|
| Kargo | `kargo-secret.tf` | Prepares credentials consumed by the GitOps Kargo Helm deployment. |
| Dynatrace | `dynatrace.tf` | Prepares token sync and optional DynaKube resource for observability/APM. |
| OpenBao | `openbao-autounseal.tf` | Creates KMS key and identity for OpenBao auto-unseal. |

## CI and Local Quality Checks

| Service | Files | Purpose |
|---|---|---|
| Conventional commits | `.github/workflows/conventional-commits.yaml` | Checks commit message format. |
| Markdown lint | `.github/workflows/markdown-lint.yaml`, `.markdownlint-cli2.yaml` | Checks Markdown files. |
| YAML lint | `.github/workflows/yaml-lint.yaml`, `.yamllint` | Checks YAML files. |
| Trivy config scan | `.github/workflows/trivy-config-scan.yaml` | Scans IaC/configuration for security findings. |
| Local hooks | `.githooks/` | Runs local lint/config checks before commit. |

## Boundary with GitOps

This repository creates identities and bootstrap resources. The GitOps repository consumes them.

| IaC creates | GitOps consumes |
|---|---|
| GKE cluster and Argo CD | Argo CD Applications |
| Argo CD root app | `argocd/applications/*` |
| Workload Identity bindings | Kubernetes service accounts and Helm values |
| Secret Manager containers | ExternalSecrets in platform and tenant namespaces |
| Crossplane provider identities | Crossplane providers and managed resources |
| GitHub Actions WIF provider | Frontend/backend release workflows |
