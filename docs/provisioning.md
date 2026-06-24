# Provisioning Steps

This document describes the provisioning flow end to end.

The platform is intentionally split into a bootstrap phase and a main infrastructure phase.

## Prerequisites

| Tool / input | Purpose |
| --- | --- |
| Google Cloud SDK | Authentication, project selection, secret uploads, cluster credentials |
| Terraform `>= 1.5.0` | Infrastructure provisioning |
| `kubectl` | Cluster verification and Argo CD access |
| GitHub App for Argo CD | Read-only repository access for GitOps, frontend, and backend repositories |
| Existing Cloud DNS managed zone | DNS automation for ExternalDNS and cert-manager |
| AVWX token | Backend METAR / nearest-airport API access |

## Step 1 - Authenticate with Google Cloud

Log in and select the target project:

```bash
gcloud auth login
gcloud auth application-default login
gcloud projects list
gcloud config set project <your-project-id>
```

Terraform reads the active project through the init scripts and exports it as `TF_VAR_project_id`.

## Step 2 - Bootstrap the Terraform state bucket

The main Terraform configuration uses a GCS backend.

Because the backend bucket must exist before Terraform can use it, `bootstrap/` creates it first with
local state.

```bash
cd bootstrap
source ./init.sh
terraform apply
```

What happens:

| Action | File |
| --- | --- |
| Reads active `gcloud` project and exports `TF_VAR_project_id` | `bootstrap/init.sh` |
| Initializes Terraform with local backend | `bootstrap/main.tf` |
| Creates `terraform-state-<project-id>` GCS bucket | `bootstrap/state-bucket.tf` |
| Enables bucket versioning and uniform access | `bootstrap/state-bucket.tf` |
| Grants configured team users object admin access | `bootstrap/state-bucket.tf` |

## Step 3 - Create the GitHub App for Argo CD

Argo CD uses a GitHub App instead of a long-lived personal access token.

Create the app in the `MCCE-2025` organization:

| Setting | Value |
| --- | --- |
| Webhook | disabled |
| Repository permissions | `Contents: Read-only`, `Metadata: Read-only` |
| Installation scope | selected repositories |
| Repositories | `SS2026-INENP-GitOps`, plus app repositories if needed by Argo CD repository secrets |

Record:

```text
APP_ID
INSTALLATION_ID
PRIVATE_KEY_FILE
```

The private key must never be committed.

## Step 4 - Initialize main Terraform

Return to the repository root and initialize the remote backend:

```bash
cd ..
export TF_VAR_dns_managed_zone_name="<managed-zone-resource-name>"
source ./init.sh
```

What happens:

| Action | File |
| --- | --- |
| Reads active `gcloud` project | `init.sh` |
| Exports `TF_VAR_project_id` | `init.sh` |
| Derives state bucket name `terraform-state-<project-id>` | `init.sh` |
| Runs `terraform init -backend-config="bucket=..."` | `init.sh`, `backend.tf` |

Use the Cloud DNS managed zone **resource name**, not the DNS domain. See [external-dns.md](./external-dns.md).

## Step 5 - Apply main infrastructure

Run:

```bash
terraform apply
```

This creates the base platform:

| Step | What Terraform creates | Key files |
| --- | --- | --- |
| 5.1 | GCP provider setup and required Terraform providers | `provider.tf`, `terraform.tf` |
| 5.2 | VPC and subnet | `vpc.tf` |
| 5.3 | GKE cluster with Workload Identity and advanced datapath | `cluster.tf` |
| 5.4 | Node pool and node service account | `node_pool.tf` |
| 5.5 | Argo CD Helm release | `argo.tf` |
| 5.6 | Argo CD AppProjects for platform and apps | `argocd-project.tf` |
| 5.7 | Secret Manager API and empty GitHub App secret containers | `secret-manager.tf` |
| 5.8 | External Secrets Operator and ClusterSecretStore | `external-secrets.tf` |
| 5.9 | Argo CD repository ExternalSecrets | `external-secrets.tf` |
| 5.10 | Argo CD root app pointing to GitOps `argocd/applications` | `argocd-root-app.tf`, `charts/argocd-root-app/` |
| 5.11 | GitHub Actions OIDC / WIF for frontend/backend image pushes | `ci-image-push.tf` |
| 5.12 | ExternalDNS Cloud DNS IAM binding | `external-dns.tf` |
| 5.13 | cert-manager DNS-01 service account and IAM | `cert-manager.tf` |
| 5.14 | Backend Cloud SQL service account and Workload Identity | `backend-cloudsql.tf` |
| 5.15 | Cloud SQL API and app password Secret Manager value | `cloud-sql-networking.tf`, `cloud-sql-secrets.tf` |
| 5.16 | Crossplane provider service accounts and IAM | `crossplane.tf`, `crossplane-sql.tf`, `crossplane-storage.tf` |
| 5.17 | Kargo admin and token signing secrets | `kargo-secret.tf` |
| 5.18 | Dynatrace secret containers and optional DynaKube CR | `dynatrace.tf` |
| 5.19 | AVWX Secret Manager container | `avwx-secret.tf` |

## Step 6 - Upload GitHub App credentials

Terraform creates the Secret Manager containers.

The sensitive values are uploaded manually so they do not enter Terraform state.

```bash
export APP_ID="<app-id>"
export INSTALLATION_ID="<installation-id>"
export PRIVATE_KEY_FILE="/path/to/argocd-app.private-key.pem"

gcloud secrets versions add argocd-github-app-id --data-file=<(printf "$APP_ID")
gcloud secrets versions add argocd-github-app-installation-id --data-file=<(printf "$INSTALLATION_ID")
gcloud secrets versions add argocd-github-app-private-key --data-file="$PRIVATE_KEY_FILE"
```

External Secrets Operator syncs these into Argo CD repository secrets:

| Kubernetes Secret | Purpose |
| --- | --- |
| `argocd/gitops-repo` | GitOps repository access |
| `argocd/backend-repo` | Backend repository access |
| `argocd/frontend-repo` | Frontend repository access |

## Step 7 - Upload the AVWX token

The backend needs AVWX access for METAR / nearest-airport data.

```bash
printf 'Token <your-avwx-token>' \
  | gcloud secrets versions add avwx-api-key --data-file=-
```

The value must include the `Token` prefix followed by a space because the backend sends it as the HTTP
`Authorization` header.

## Step 8 - Optional Dynatrace activation

Terraform creates empty Secret Manager containers for Dynatrace tokens.

Upload token values when Dynatrace should be activated:

```bash
printf '<OPERATOR_API_TOKEN>' \
  | gcloud secrets versions add dynatrace-api-token --data-file=-
printf '<DATA_INGEST_TOKEN>' \
  | gcloud secrets versions add dynatrace-data-ingest-token --data-file=-
```

The environment API URL is not a secret and is not a Terraform variable. Set it in the GitOps repo:

```yaml
# SS2026-INENP-GitOps/platform/dynatrace/dynakube.yaml
spec:
  apiUrl: https://<env-id>.live.dynatrace.com/api
```

After the tokens are uploaded and `apiUrl` is set, Argo CD applies the Dynatrace Operator and DynaKube CR.

## Step 9 - Configure kubectl and verify

```bash
gcloud container clusters get-credentials platform-gke-cluster \
  --region europe-west3 \
  --project "$(gcloud config get-value project)"

kubectl get nodes
kubectl get pods -n argocd
kubectl get externalsecrets -A
```

Read the Argo CD initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

## Step 10 - Let GitOps reconcile

Terraform installs the root app. The root app points Argo CD at:

```text
SS2026-INENP-GitOps/argocd/applications
```

Argo CD then reconciles platform services, applications, Crossplane resources, and tenants from the GitOps repository.

## Step 11 - Configure app repository variables

Use Terraform outputs in the frontend and backend GitHub Actions variables:

```bash
terraform output ci_wif_provider
terraform output ci_image_push_service_account
```

These values are used by release workflows to push container images to Google Artifact Registry without
service account keys.
