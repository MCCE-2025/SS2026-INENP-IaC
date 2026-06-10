#!/usr/bin/env bash

platform_init() {
  local script_dir project_id state_bucket

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "${script_dir}"

  project_id="$(gcloud config get-value project 2>/dev/null || true)"
  if [[ -z "${project_id}" ]]; then
    echo "error: no active gcloud project; run: gcloud config set project <project-id>" >&2
    return 1
  fi

  export TF_VAR_project_id="${project_id}"
  state_bucket="terraform-state-${TF_VAR_project_id}"

  echo "Using project: ${TF_VAR_project_id}"
  echo "State bucket:  ${state_bucket}"
  terraform init -backend-config="bucket=${state_bucket}"

  local missing_vars=()
  [[ -z "${TF_VAR_github_app_id:-}" ]] && missing_vars+=("TF_VAR_github_app_id")
  [[ -z "${TF_VAR_github_app_installation_id:-}" ]] && missing_vars+=("TF_VAR_github_app_installation_id")

  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo
    echo "Note: the following GitHub App variables are not set (${missing_vars[*]})."
    echo "Export them before terraform apply (see README, GitHub App for Argo CD):"
    echo "  export TF_VAR_github_app_id=\"<app-id>\""
    echo "  export TF_VAR_github_app_installation_id=\"<installation-id>\""
  fi

  echo
  echo "Note: upload the GitHub App private key to Secret Manager after apply (see README):"
  echo "  gcloud secrets versions add argocd-github-app-private-key --data-file=/path/to/argocd-app.private-key.pem"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  platform_init
  echo
  echo "Note: TF_VAR_project_id is not set in your shell when running this script directly."
  echo "Source it instead so terraform apply can use the same project:"
  echo "  source ./init.sh"
else
  platform_init || return
fi
