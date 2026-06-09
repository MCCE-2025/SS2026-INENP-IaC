# ExternalDNS (GitOps repo)

This repository grants Cloud DNS access to ExternalDNS via GKE Workload
Identity Federation (direct IAM binding to the Kubernetes service account
principal). No GCP service account or `iam.gke.io/gcp-service-account`
annotation is required.

The ExternalDNS deployment itself lives in the GitOps repository
(`MCCE-2025/SS2026-INENP-GitOps`) and is synced by Argo CD.

## Terraform variable

Set the existing Cloud DNS managed zone **resource name** when applying
(required for ExternalDNS Workload Identity):

```bash
export TF_VAR_dns_managed_zone_name="your-managed-zone-name"
```

Use the value in the **NAME** column from `gcloud dns managed-zones list`, not
the **DNS_NAME** (domain). For example, a zone with `NAME` `my-zone` and
`DNS_NAME` `example.example.com.` must be passed as `my-zone`. Using the domain
(`example.example.com`) causes a 404 during `terraform plan`.

```bash
gcloud dns managed-zones list --format="table(name,dnsName)"
```

The **DNS_NAME** is exposed after apply via `terraform output external_dns_dns_name`
and is used in GitOps as ExternalDNS `--domain-filter` (without the trailing dot).

## Prerequisites (this repo)

After `terraform apply`, note these outputs:

```bash
terraform output external_dns_principal
terraform output external_dns_dns_name
terraform output project_id
```

The Kubernetes service account name and namespace in GitOps must match the
Terraform variables `external_dns_ksa` (default: `external-dns`) and
`external_dns_namespace` (default: `external-dns`).

## Argo CD Application (GitOps repo)

Add an Argo CD `Application` similar to:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-dns
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://kubernetes-sigs.github.io/external-dns/
    chart: external-dns
    targetRevision: 1.21.*
    helm:
      values: |
        provider:
          name: google
        extraArgs:
          - --google-project=<project_id>
          - --domain-filter=<zone dns_name without trailing dot>
        serviceAccount:
          create: true
          name: external-dns
        policy: upsert-only
  destination:
    server: https://kubernetes.default.svc
    namespace: external-dns
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Replace `<project_id>` with your GCP project ID and `<zone dns_name without
trailing dot>` with the value from `terraform output external_dns_dns_name`
(without the trailing dot).

## Least-privilege alternative

The default binding uses project-level `roles/dns.admin` because ExternalDNS
lists managed zones before editing records. For tighter scope, use project-level
`roles/dns.reader` plus a zone-scoped `roles/dns.admin` binding on the managed
zone instead.

## Verification

1. Confirm Terraform created the IAM binding:

   ```bash
   terraform plan
   ```

2. After Argo CD syncs ExternalDNS, check pod logs:

   ```bash
   kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns
   ```

3. Confirm DNS record changes in Cloud DNS (use the managed zone **resource
   name**, same value as `TF_VAR_dns_managed_zone_name`):

   ```bash
   gcloud dns record-sets list --zone=<your-managed-zone-name>
   ```
