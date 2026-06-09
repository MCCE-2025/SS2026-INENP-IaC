# Infrastructure as Code Repository

This repository contains the Infrastructure as Code (IaC) configuration files
and related resources for the project infrastructure.

## Group G

| Name | Email |
| --- | --- |
| Michael Lang | <2510781033@hochschule-burgenland.at> |
| Nemanja Filipović | <2510781028@hochschule-burgenland.at> |
| Andreas Werschlan | <2510781034@hochschule-burgenland.at> |

## Quickstart

Prerequisites:

- [Google Cloud SDK](#authenticate-with-google-cloud)
- [Terraform](#install-terraform)
- [GitHub token for Argo CD](#github-fine-grained-token-argo-cd).

```bash
# 1. Log in to Google Cloud and select your project
gcloud auth login
gcloud auth application-default login
# list available projects
gcloud projects list
# configure the project you want to deploy to
gcloud config set project <your-project-id>

# 2. Bootstrap the Terraform state bucket
cd bootstrap
source ./init.sh
terraform apply

# 3. Provision the platform (from the repository root)
cd ..
# see Prerequisites for how to create the PAT for ArgoCD
export TF_VAR_github_token_argocd="github_pat_..."
source ./init.sh
terraform apply
```

Confirm each `terraform apply` with `yes`. See [Infrastructure Provisioning](#infrastructure-provisioning)
for detailed steps and explanations.

## Local Linting

Install the required linters.

**macOS (Homebrew):**

```bash
brew install yamllint markdownlint-cli2 trivy
```

**Linux (Debian/Ubuntu):**

```bash
sudo apt-get update
sudo apt-get install -y yamllint

# markdownlint-cli2 (requires Node.js)
npm install -g markdownlint-cli2

# Trivy
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
  https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy
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

### Authenticate with Google Cloud

Install the Google Cloud SDK.

**macOS (Homebrew):**

```bash
brew install --cask google-cloud-sdk
```

**Linux (Debian/Ubuntu):**

```bash
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
  https://packages.cloud.google.com/apt cloud-sdk main" \
  | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install -y google-cloud-cli
```

Alternatively, use the interactive installer (works on most Linux distributions):

```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

Log in with your Google account and configure Application Default Credentials
(used by Terraform):

```bash
gcloud auth login
gcloud auth application-default login
```

Set the active project (required for `init.sh`, `bootstrap/init.sh`, and Terraform):

```bash
gcloud config set project <your-project-id>
```

Verify the configuration:

```bash
gcloud config get-value project
gcloud auth list
```

Alternatively, set `GOOGLE_APPLICATION_CREDENTIALS` to a service account key
file path (see `provider.tf`).

### Install Terraform

Install Terraform.

**macOS (Homebrew):**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Linux (Debian/Ubuntu):**

```bash
wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform
```

Verify the installation:

```bash
terraform version
```

### Bootstrap Terraform Backend

Navigate to the bootstrap directory, source the init script, and apply:

```bash
cd bootstrap
source ./init.sh
```

The init script reads the active gcloud project, exports `TF_VAR_project_id`
into your shell, and runs `terraform init`. No project ID is hardcoded. Use
`source` (not `./init.sh`) so the variable is available for `terraform apply`.

To initialize manually instead:

```bash
export TF_VAR_project_id="$(gcloud config get-value project)"
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
repository root directory, set the GitHub token, source the init script, and
apply:

```bash
cd ..
export TF_VAR_github_token_argocd="github_pat_..."
source ./init.sh
```

The init script reads the active gcloud project, exports `TF_VAR_project_id`
into your shell, and runs `terraform init` with the matching state bucket
(`terraform-state-<project_id>`). Use `source` (not `./init.sh`) so the variable
is available for `terraform apply`.

To initialize manually instead:

```bash
export TF_VAR_project_id="$(gcloud config get-value project)"
export TF_VAR_github_token_argocd="github_pat_..."
terraform init -backend-config="bucket=terraform-state-${TF_VAR_project_id}"
```

Apply the platform configuration:

```bash
terraform apply
```

The state bucket name is derived from the active project instead of being
hardcoded. Terraform `backend` blocks cannot reference variables, so the bucket
is supplied at init time via partial backend configuration. The name matches the
bucket created during bootstrap (`terraform-state-<project_id>`).

Review the planned changes, then type `yes` to confirm and provision the
infrastructure (GKE cluster, Argo CD, and GitOps repository connection).
