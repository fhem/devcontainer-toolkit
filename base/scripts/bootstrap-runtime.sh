#!/bin/bash
set -euo pipefail

TARGET_ROOT="${FHEM_RUNTIME_ROOT:-/opt/fhem}"
DATA_ROOT="${FHEM_RUNTIME_DATA_ROOT:-/opt/fhem-dev-data}"
RUNTIME_STATE_DIR="${TARGET_ROOT}/.devcontainer/runtime-state"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${DATA_ROOT}/home-config}"

MODULE_REPO_ROOT="${MODULE_REPO_ROOT:-}"
if [[ -z "${MODULE_REPO_ROOT}" ]]; then
  echo "Missing MODULE_REPO_ROOT" >&2
  exit 1
fi

MODULE_OVERLAY_ROOT="${MODULE_OVERLAY_ROOT:-${MODULE_REPO_ROOT}}"
FHEM_SOURCE_ROOT="${FHEM_SOURCE_ROOT:-${MODULE_REPO_ROOT}/fhem}"

if [[ ! -f "${FHEM_SOURCE_ROOT}/fhem.pl" ]]; then
  echo "Missing FHEM source tree at ${FHEM_SOURCE_ROOT}" >&2
  exit 1
fi

echo "Bootstrapping FHEM runtime"
echo "  source:  ${FHEM_SOURCE_ROOT}"
echo "  overlay: ${MODULE_OVERLAY_ROOT}"

mkdir -p \
  "${TARGET_ROOT}" \
  "${TARGET_ROOT}/.devcontainer/config" \
  "${RUNTIME_STATE_DIR}/FHEM/FhemUtils" \
  "${XDG_CONFIG_HOME}/git" \
  "${DATA_ROOT}/log" \
  "${DATA_ROOT}/demolog"

find "${TARGET_ROOT}" -mindepth 1 -maxdepth 1 ! -name '.devcontainer' -exec rm -rf {} +

for path in "${FHEM_SOURCE_ROOT}"/*; do
  name="$(basename "${path}")"
  if [[ "${name}" == "log" || "${name}" == "demolog" ]]; then
    continue
  fi
  if [[ "${name}" == "FHEM" ]]; then
    continue
  fi
  ln -s "${path}" "${TARGET_ROOT}/${name}"
done

mkdir -p "${TARGET_ROOT}/FHEM" "${TARGET_ROOT}/FHEM/FhemUtils"

for path in "${FHEM_SOURCE_ROOT}/FHEM"/*; do
  name="$(basename "${path}")"
  if [[ "${name}" == "FhemUtils" ]]; then
    continue
  fi
  ln -s "${path}" "${TARGET_ROOT}/FHEM/${name}"
done

for path in "${FHEM_SOURCE_ROOT}/FHEM/FhemUtils"/*; do
  name="$(basename "${path}")"
  if [[ "${name}" == "uniqueID" ]]; then
    continue
  fi
  ln -s "${path}" "${TARGET_ROOT}/FHEM/FhemUtils/${name}"
done

ln -s "${RUNTIME_STATE_DIR}/FHEM/FhemUtils/uniqueID" "${TARGET_ROOT}/FHEM/FhemUtils/uniqueID"
ln -s "${DATA_ROOT}/log" "${TARGET_ROOT}/log"
ln -s "${DATA_ROOT}/demolog" "${TARGET_ROOT}/demolog"

overlay_specs=(
  "FHEM:${TARGET_ROOT}/FHEM"
  "lib:${TARGET_ROOT}/lib"
  "t:${TARGET_ROOT}/t"
  "contrib:${TARGET_ROOT}/contrib"
  "docs:${TARGET_ROOT}/docs"
  "www:${TARGET_ROOT}/www"
)

for spec in "${overlay_specs[@]}"; do
  src_rel="${spec%%:*}"
  target_dir="${spec#*:}"
  src_dir="${MODULE_OVERLAY_ROOT}/${src_rel}"

  if [[ ! -d "${src_dir}" ]]; then
    continue
  fi

  mkdir -p "${target_dir}"

  while IFS= read -r -d '' item; do
    rel_path="${item#${src_dir}/}"
    target_path="${target_dir}/${rel_path}"
    if [[ -d "${item}" && ! -L "${item}" ]]; then
      mkdir -p "${target_path}"
      continue
    fi

    mkdir -p "$(dirname "${target_path}")"
    rm -rf "${target_path}"
    ln -s "${item}" "${target_path}"
  done < <(find "${src_dir}" -mindepth 1 -print0 | sort -z)
done

config_source="${MODULE_REPO_ROOT}/.devcontainer/config/fhem.cfg"
if [[ -f "${config_source}" ]]; then
  cp "${config_source}" "${TARGET_ROOT}/.devcontainer/config/fhem.cfg"
fi
