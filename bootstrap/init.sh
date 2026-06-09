#!/usr/bin/env bash

bootstrap_init() {
  local script_dir project_id

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "${script_dir}"

  project_id="$(gcloud config get-value project 2>/dev/null || true)"
  if [[ -z "${project_id}" ]]; then
    echo "error: no active gcloud project; run: gcloud config set project <project-id>" >&2
    return 1
  fi

  export TF_VAR_project_id="${project_id}"

  echo "Using project: ${TF_VAR_project_id}"
  terraform init
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  bootstrap_init
  echo
  echo "Note: TF_VAR_project_id is not set in your shell when running this script directly."
  echo "Source it instead so terraform apply can use the same project:"
  echo "  source ./init.sh"
else
  bootstrap_init || return
fi
