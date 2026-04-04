#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <test-file>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.devcontainer/scripts/test-lib.sh
source "${SCRIPT_DIR}/test-lib.sh"

MODULE_REPO_ROOT="$(get_module_repo_root)"
TEST_ARG="$1"
TEST_ROOT="$(get_test_root "${MODULE_REPO_ROOT}")"

if [[ "${TEST_ARG}" = /* ]]; then
  TEST_FILE="${TEST_ARG}"
else
  TEST_FILE="${TEST_ROOT}/${TEST_ARG}"
fi

if [[ ! -f "${TEST_FILE}" ]]; then
  echo "Missing test file: ${TEST_FILE}" >&2
  exit 1
fi

if is_fhem_module_test "${TEST_ROOT}" "${TEST_FILE}"; then
  KIND="fhem"
else
  KIND="perl"
fi

exec "${SCRIPT_DIR}/run-selected-tests.sh" "${KIND}" "${TEST_FILE}"
