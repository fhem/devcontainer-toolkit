#!/bin/bash
set -euo pipefail

MODULE_REPO_ROOT="${MODULE_REPO_ROOT:?MODULE_REPO_ROOT must be set}"
SVN_ROOT="${FHEM_SVN_ROOT:-/workspace/fhem-svn/fhem}"
MANIFEST_FILE="${FHEM_SVN_MANIFEST:-${MODULE_REPO_ROOT}/.devcontainer/svn-manifest.txt}"

if ! svn info "${SVN_ROOT}" >/dev/null 2>&1; then
  echo "Missing SVN working copy at ${SVN_ROOT}" >&2
  echo "Create it first, for example: svn co svn+ssh://svn.fhem.de/trunk/fhem ${SVN_ROOT}" >&2
  exit 1
fi

if [[ ! -f "${MANIFEST_FILE}" ]]; then
  echo "Missing SVN manifest at ${MANIFEST_FILE}" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

awk 'NF && $1 !~ /^#/' "${MANIFEST_FILE}" > "${tmpdir}/manifest.list"

if [[ ! -s "${tmpdir}/manifest.list" ]]; then
  echo "SVN manifest is empty: ${MANIFEST_FILE}" >&2
  exit 1
fi

while IFS= read -r rel_path; do
  src_path="${MODULE_REPO_ROOT}/${rel_path}"
  dst_path="${SVN_ROOT}/${rel_path}"

  if [[ ! -e "${src_path}" && ! -L "${src_path}" ]]; then
    if [[ -e "${dst_path}" || -L "${dst_path}" ]]; then
      svn rm --force "${dst_path}" >/dev/null 2>&1 || rm -rf "${dst_path}"
    fi
    continue
  fi

  mkdir -p "$(dirname "${dst_path}")"

  if [[ -d "${src_path}" && ! -L "${src_path}" ]]; then
    mkdir -p "${dst_path}"
    continue
  fi

  if [[ -L "${src_path}" ]]; then
    link_target="$(readlink "${src_path}")"
    rm -rf "${dst_path}"
    ln -s "${link_target}" "${dst_path}"
    continue
  fi

  if [[ ! -f "${dst_path}" ]] || ! cmp -s "${src_path}" "${dst_path}"; then
    cp -p "${src_path}" "${dst_path}"
  fi
done < "${tmpdir}/manifest.list"

svn add --force "${SVN_ROOT}" >/dev/null

echo "Module -> SVN sync complete."
echo
svn status "${SVN_ROOT}"
