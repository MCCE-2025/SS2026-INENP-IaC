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

Before provisioning the main infrastructure, the Terraform backend must be bootstrapped.
The bootstrap step creates the Google Cloud Storage bucket that will be used to store the Terraform remote state.

### Install Terraform

Install Terraform on macOS using Homebrew:

```bash
brew tap hashicorp/tap
```
```bash
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

Terraform will ask for the required `project_id`.

After entering the Google Cloud project ID and confirming the execution with:

```text
yes
```

Terraform will create a Google Cloud Storage bucket.
This bucket will be used as the remote backend for storing the Terraform state.

### Result

After the bootstrap step has completed successfully, the project is ready to use remote Terraform state stored in Google Cloud Storage.

