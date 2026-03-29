#!/bin/bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [target-repo-root]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_REPO="$(cd "${1:-$(pwd)}" && pwd)"
REPO_NAME="$(basename "${TARGET_REPO}")"
REPO_SLUG="$(printf %s "${REPO_NAME}" | tr "[:upper:]" "[:lower:]")"
WORKSPACE_DIR="/workspace/${REPO_NAME}"
TEMPLATE_ROOT="${TOOLKIT_ROOT}/scaffold/templates"

render_template() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "${dst}")"
  sed \
    -e "s|__REPO_NAME__|${REPO_NAME}|g" \
    -e "s|__WORKSPACE_DIR__|${WORKSPACE_DIR}|g" \
    -e "s|__REPO_SLUG__|${REPO_SLUG}|g" \
    "${src}" > "${dst}"
}

managed_files=(
  ".devcontainer/Dockerfile"
  ".devcontainer/compose.yml"
  ".devcontainer/compose.addon-svn.yml"
  ".devcontainer/compose.local.example.yml"
  ".devcontainer/.env.local.example"
  ".devcontainer/README.md"
  ".devcontainer/config/fhem.cfg"
  ".devcontainer/svn-manifest.txt"
  ".devcontainer/scripts/bootstrap-worktree.sh"
  ".devcontainer/scripts/pick-fhem-test.sh"
  ".devcontainer/scripts/run-all-tests.sh"
  ".devcontainer/scripts/run-single-test.sh"
  ".devcontainer/scripts/svn-checkout.sh"
  ".devcontainer/scripts/sync-module-to-svn.sh"
  ".devcontainer/default/compose.override.yml"
  ".devcontainer/default/devcontainer.json"
  ".vscode/tasks.json"
)

sync_gitignore() {
  local template_path="${TEMPLATE_ROOT}/.gitignore"
  local target_path="${TARGET_REPO}/.gitignore"

  if [[ ! -f "${target_path}" ]]; then
    cp "${template_path}" "${target_path}"
    return
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    if grep -Fqx -- "${line}" "${target_path}"; then
      continue
    fi
    printf '%s\n' "${line}" >> "${target_path}"
  done < "${template_path}"
}

for rel_path in "${managed_files[@]}"; do
  render_template "${TEMPLATE_ROOT}/${rel_path}" "${TARGET_REPO}/${rel_path}"
done

sync_gitignore

chmod +x \
  "${TARGET_REPO}/.devcontainer/scripts/bootstrap-worktree.sh" \
  "${TARGET_REPO}/.devcontainer/scripts/pick-fhem-test.sh" \
  "${TARGET_REPO}/.devcontainer/scripts/run-all-tests.sh" \
  "${TARGET_REPO}/.devcontainer/scripts/run-single-test.sh" \
  "${TARGET_REPO}/.devcontainer/scripts/svn-checkout.sh" \
  "${TARGET_REPO}/.devcontainer/scripts/sync-module-to-svn.sh"

echo "Toolkit sync complete for ${TARGET_REPO}"
