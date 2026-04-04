#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.devcontainer/scripts/test-lib.sh
source "${SCRIPT_DIR}/test-lib.sh"

MODULE_REPO_ROOT="$(get_module_repo_root)"
TEST_ROOT="$(get_test_root "${MODULE_REPO_ROOT}")"
RUN_ROOT="$(get_run_root "${MODULE_REPO_ROOT}")"

mapfile -t fhem_tests < <(find_tests_by_kind "${TEST_ROOT}" fhem | sort)
mapfile -t perl_tests < <(find_tests_by_kind "${TEST_ROOT}" perl | sort)

if [[ ${#fhem_tests[@]} -eq 0 && ${#perl_tests[@]} -eq 0 ]]; then
  echo "No .t tests found under ${TEST_ROOT}" >&2
  exit 1
fi

status=0

if [[ ${#fhem_tests[@]} -gt 0 ]]; then
  run_tests fhem "${RUN_ROOT}" "${fhem_tests[@]}" || status=$?
fi

if [[ ${#perl_tests[@]} -gt 0 ]]; then
  run_tests perl "${RUN_ROOT}" "${perl_tests[@]}" || status=$?
fi

exit "${status}"
