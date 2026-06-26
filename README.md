# INENP Infrastructure as Code

This repository bootstraps and provisions the cloud infrastructure for the INENP Weather App platform
(WS2026).

It creates the Terraform state backend, GKE cluster, Argo CD bootstrap, platform identities,
Secret Manager containers, Workload Identity bindings, and supporting GCP resources.

## Documentation

- **Project overview and repository structure:** [docs/overview.md](docs/overview.md)
- **Provisioning steps:** [docs/provisioning.md](docs/provisioning.md)
- **Infrastructure services and responsibilities:** [docs/services.md](docs/services.md)
- **ExternalDNS details:** [docs/external-dns.md](docs/external-dns.md)

Related repositories:

| Repository | Role |
| --- | --- |
| [SS2026-INENP-GitOps](https://github.com/MCCE-2025/SS2026-INENP-GitOps) | GitOps config |
| [SS2026-INENP-backend](https://github.com/MCCE-2025/SS2026-INENP-backend) | Backend source |
| [SS2026-INENP-frontend](https://github.com/MCCE-2025/SS2026-INENP-frontend) | Frontend source |

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

---------------------------------------------------------------------------------

## Project costs (GCP)

Recalculated run-rate after configuration changes (status as of 23 June 2026).
Source: GCP Billing export, 24 June 2026.

### Summary

| | Planned | Actual |
| --- | ---: | ---: |
| Daily run-rate (total) | €7.00 / day | €12.81 / day |
| June spend (1–23 Jun) | — | €122.16 |
| Estimated monthly run-rate | — | ~€385 (€12.81 × 30) |
| June forecast (actual + 7 days remaining) | — | ~€212 |

Requested budget for June: **$290**. Forecast ~€212 (~$229 at €1 = $1.08) — within budget.

### Daily cost by service

| Service | Planned / day | Actual / day |
| --- | ---: | ---: |
| Compute Engine | €3.36 | €6.97 |
| Cloud SQL | €0.68 | €3.46 |
| Kubernetes Engine (GKE) | €2.22 | €1.82 |
| Networking + DNS | €0.74 | €0.56 |
| **Total** | **€7.00** | **€12.81** |

### Why actual costs are higher than planned

1. **Cloud SQL** — instance went live on 22 June (was not running for the full billing period before that).
2. **Compute Engine / GKE nodes** — node pool upgraded from `e2-medium` to `e2-standard-2` after CPU bottlenecks on the cluster.

GKE management cost alone is slightly below plan; the increase comes mainly from Compute Engine and Cloud SQL.

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

We used AI tools (**Cursor** and **ChatGPT**) as support throughout the project.
They did not replace review and ownership. They helped draft:

- GitHub issues
- Pull request descriptions
- Terraform configuration
- GitOps bootstrap configuration
- Workload Identity and Secret Manager wiring
- Documentation (including this repo's `docs/`)

All AI-generated content was reviewed, adapted, and validated by the team before merge.
