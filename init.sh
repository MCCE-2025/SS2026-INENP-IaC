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

  printf '\n
Note: upload GitHub App credentials to Secret Manager after apply (see README):

  export APP_ID="<app-id>"
  export INSTALLATION_ID="<installation-id>"
  export PRIVATE_KEY_FILE="/path/to/argocd-app.private-key.pem"

  gcloud secrets versions add argocd-github-app-id --data-file=<(printf "$APP_ID")
  gcloud secrets versions add argocd-github-app-installation-id --data-file=<(printf "$INSTALLATION_ID")
  gcloud secrets versions add argocd-github-app-private-key --data-file="$PRIVATE_KEY_FILE"
'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  platform_init
  printf '\n
Note: TF_VAR_project_id is not set in your shell when running this script directly.\n
Source it instead so terraform apply can use the same project:\n
  source ./init.sh\n
'
else
  platform_init || return
fi
