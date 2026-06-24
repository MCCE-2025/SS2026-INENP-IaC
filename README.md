# INENP Infrastructure as Code

This repository bootstraps and provisions the cloud infrastructure for the INENP Weather App platform (WS2026). It creates the Terraform state backend, GKE cluster, Argo CD bootstrap, platform identities, Secret Manager containers, Workload Identity bindings, and supporting GCP resources used by the GitOps, frontend, and backend repositories.

## Documentation

- **Project overview and repository structure:** [docs/overview.md](docs/overview.md)
- **Provisioning steps:** [docs/provisioning.md](docs/provisioning.md)
- **Infrastructure services and responsibilities:** [docs/services.md](docs/services.md)
- **ExternalDNS details:** [docs/external-dns.md](docs/external-dns.md)

Related repositories:

| Repository | Role |
|---|---|
| [SS2026-INENP-GitOps](https://github.com/MCCE-2025/SS2026-INENP-GitOps) | Argo CD Applications, platform manifests, tenant configuration |
| [SS2026-INENP-backend](https://github.com/MCCE-2025/SS2026-INENP-backend) | Spring Boot backend source, Helm chart, backend release workflow |
| [SS2026-INENP-frontend](https://github.com/MCCE-2025/SS2026-INENP-frontend) | Quasar/Vue frontend source, Helm chart, frontend release workflow |

## Quickstart

```bash
# 1. Authenticate and select the target project
gcloud auth login
gcloud auth application-default login
gcloud config set project <your-project-id>

# 2. Bootstrap Terraform remote state
cd bootstrap
source ./init.sh
terraform apply

# 3. Provision the platform
cd ..
export TF_VAR_dns_managed_zone_name="<managed-zone-resource-name>"
source ./init.sh
terraform apply

# 4. Upload required out-of-band secret values after Terraform created the
#    Secret Manager containers.
gcloud secrets versions add argocd-github-app-id --data-file=<(printf "$APP_ID")
gcloud secrets versions add argocd-github-app-installation-id --data-file=<(printf "$INSTALLATION_ID")
gcloud secrets versions add argocd-github-app-private-key --data-file="$PRIVATE_KEY_FILE"
printf 'Token <your-avwx-token>' | gcloud secrets versions add avwx-api-key --data-file=-
```

See [docs/provisioning.md](docs/provisioning.md) for the full step-by-step flow.

## Access

After provisioning, configure `kubectl` for the cluster:

```bash
gcloud container clusters get-credentials platform-gke-cluster \
  --region europe-west3 \
  --project "$(gcloud config get-value project)"
```

Argo CD is later exposed through GitOps at:

```text
https://argocd.inenp.werschlan.at
```

The initial admin password can be read from the cluster:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

## Local Checks

Install and run the repository hooks:

```bash
brew install yamllint markdownlint-cli2 trivy
./.githooks/install
./.githooks/pre-commit
```

## AI-assisted development

We used AI tools (**Cursor** and **ChatGPT**) as support throughout the project - not as a replacement for review and ownership. They helped draft:

- GitHub issues
- Pull request descriptions
- Terraform configuration
- GitOps bootstrap configuration
- Workload Identity and Secret Manager wiring
- Documentation (including this repo's `docs/`)

All AI-generated content was reviewed, adapted, and validated by the team before merge.
