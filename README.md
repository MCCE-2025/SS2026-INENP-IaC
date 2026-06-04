# Infrastructure as Code Repository

This repository contains the Infrastructure as Code (IaC) configuration files
and related resources for the project infrastructure.

## Group G

| Name | Email |
| --- | --- |
| Michael Lang | <2510781033@hochschule-burgenland.at> |
| Nemanja Filipović | <2510781028@hochschule-burgenland.at> |
| Andreas Werschlan | <2510781034@hochschule-burgenland.at> |

## Local Linting

Install the required linters on macOS using Homebrew:

```bash
brew install yamllint markdownlint-cli2 trivy
```

Run YAML linting for the whole repository:

```bash
yamllint .
```

Run Markdown linting for the whole repository:

```bash
markdownlint-cli2 "**/*.md"
```

Run Trivy configuration check:

```bash
trivy config .
```

## Infrastructure Provisioning

This repository uses Terraform to provision the required cloud infrastructure.

Before provisioning the main infrastructure, the Terraform backend must be
bootstrapped. The bootstrap step creates a Google Cloud Storage bucket for
Terraform remote state.

### Install Terraform

Install Terraform on macOS using Homebrew:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Verify the installation:

```bash
terraform version
```

### Bootstrap Terraform Backend

Navigate to the bootstrap directory:

```bash
cd bootstrap
```

Initialize Terraform:

```bash
terraform init
```

Apply the bootstrap configuration:

```bash
terraform apply
```

Confirm the execution with:

```text
yes
```

Terraform will create a Google Cloud Storage bucket.
This bucket will be used as the remote backend for storing the Terraform state.

### GitHub Fine-Grained Token (Argo CD)

Argo CD needs read access to the GitOps repository
(`MCCE-2025/SS2026-INENP-GitOps`). Create a fine-grained personal access token:

1. Open GitHub → **Settings** → **Developer settings** →
   **Personal access tokens** → **Fine-grained tokens**
2. Click **Generate new token**
3. Configure the token:
   - **Token name:** `github_token_argocd`
   - **Expiration:** choose an expiry (e.g. 90 days or custom)
   - **Resource owner:** `MCCE-2025` (organization) or your user account
   - **Repository access:** **Only select repositories** →
     `SS2026-INENP-GitOps`
   - **Permissions:**
     - **Contents:** Read-only
     - **Metadata:** Read-only
4. Click **Generate token** and copy the token (`github_pat_...`)

### Result

After the bootstrap step has completed successfully, the project is ready to use
remote Terraform state stored in Google Cloud Storage.

### Provision Main Infrastructure

After bootstrapping (creating the storage bucket for Terraform state), go to the
repository root directory, set the GitHub token, and run Terraform:

```bash
cd ..
export TF_VAR_github_token_argocd="github_pat_..."
terraform init
terraform apply
```

Review the planned changes, then type `yes` to confirm and provision the
infrastructure (GKE cluster, Argo CD, and GitOps repository connection).
