#!/usr/bin/env bash
set -euo pipefail

get_module_repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  printf '%s\n' "${MODULE_REPO_ROOT:-$(cd "${script_dir}/../.." && pwd)}"
}

get_test_root() {
  local module_repo_root="$1"

  if [[ -n "${FHEM_TEST_ROOT:-}" ]]; then
    printf '%s\n' "${FHEM_TEST_ROOT}"
    return
  fi

  if [[ -d "${module_repo_root}/t" ]]; then
    printf '%s\n' "${module_repo_root}/t"
    return
  fi

  printf '%s\n' "${module_repo_root}/fhem/t"
}

get_run_root() {
  local module_repo_root="$1"

  if [[ -f "${FHEM_RUNTIME_ROOT:-/opt/fhem}/fhem.pl" ]]; then
    printf '%s\n' "${FHEM_RUNTIME_ROOT:-/opt/fhem}"
    return
  fi

  if [[ -f "${module_repo_root}/fhem/fhem.pl" ]]; then
    printf '%s\n' "${FHEM_SOURCE_ROOT:-${module_repo_root}/fhem}"
    return
  fi

  printf '%s\n' "${FHEM_SOURCE_ROOT:?FHEM_SOURCE_ROOT must point to a full FHEM source tree or a bootstrapped runtime}"
}

setup_perl_env() {
  local run_root="$1"

  PERL5LIB="${run_root}/lib:${FHEM_PERL5LIB:-/usr/src/app/core/lib/perl5}${PERL5LIB:+:$PERL5LIB}"
  export PERL5LIB
}

split_prove_options() {
  if [[ -z "${FHEM_PROVE_OPTIONS:-}" ]]; then
    return
  fi

  # shellcheck disable=SC2206
  PROVE_OPTIONS=( ${FHEM_PROVE_OPTIONS} )
}

is_fhem_module_test() {
  local test_root="$1"
  local test_file="$2"
  local rel_path

  rel_path="$(realpath --relative-to="${test_root}" "${test_file}")"
  [[ "${rel_path}" =~ ^FHEM/[0-9][0-9][^/]*/ ]]
}

normalize_test_args() {
  local module_repo_root="$1"
  local test_root="$2"
  shift 2

  local arg
  local candidate

  for arg in "$@"; do
    if [[ "${arg}" = /* ]]; then
      candidate="${arg}"
    elif [[ -f "${module_repo_root}/${arg}" ]]; then
      candidate="${module_repo_root}/${arg}"
    else
      candidate="${test_root}/${arg}"
    fi

    if [[ ! -f "${candidate}" ]]; then
      echo "Missing test file: ${candidate}" >&2
      exit 1
    fi

    printf '%s\n' "${candidate}"
  done
}

find_tests_by_kind() {
  local test_root="$1"
  local kind="$2"
  local test_file

  if [[ "${kind}" == "fhem" ]]; then
    [[ -d "${test_root}/FHEM" ]] || return

    while IFS= read -r test_file; do
      if is_fhem_module_test "${test_root}" "${test_file}"; then
        printf '%s\n' "${test_file}"
      fi
    done < <(find "${test_root}/FHEM" -type f -name '*.t' | sort)
    return
  fi

  while IFS= read -r test_file; do
    if ! is_fhem_module_test "${test_root}" "${test_file}"; then
      printf '%s\n' "${test_file}"
    fi
  done < <(find "${test_root}" -type f -name '*.t' | sort)
}

run_tests() {
  local kind="$1"
  local run_root="$2"
  shift 2

  local -a tests=( "$@" )
  local -a cmd=( prove )
  local -a PROVE_OPTIONS=()
  local -a PROVE_ARGS=()
  local prove_exec=""

  split_prove_options
  if [[ ${#PROVE_OPTIONS[@]} -gt 0 ]]; then
    cmd+=( "${PROVE_OPTIONS[@]}" )
  fi

  if [[ -n "${FHEM_PROVE_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    PROVE_ARGS=( ${FHEM_PROVE_ARGS} )
    cmd+=( "${PROVE_ARGS[@]}" )
  elif [[ "${kind}" == "fhem" ]]; then
    cmd+=( -I FHEM -r )
  else
    cmd+=( -r )
  fi

  if [[ -n "${FHEM_PROVE_EXEC:-}" ]]; then
    prove_exec="${FHEM_PROVE_EXEC}"
  elif [[ "${kind}" == "fhem" ]]; then
    prove_exec="perl fhem.pl -t"
  else
    prove_exec="perl -I lib -I FHEM"
  fi

  if [[ -n "${prove_exec}" ]]; then
    cmd+=( --exec "${prove_exec}" )
  fi

  cmd+=( "${tests[@]}" )

  cd "${run_root}"
  setup_perl_env "${run_root}"
  "${cmd[@]}"
}
