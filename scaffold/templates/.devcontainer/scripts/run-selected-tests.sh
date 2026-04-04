#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <fhem|perl> [test-file ...]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.devcontainer/scripts/test-lib.sh
source "${SCRIPT_DIR}/test-lib.sh"

KIND="$1"
shift

if [[ "${KIND}" != "fhem" && "${KIND}" != "perl" ]]; then
  echo "Unknown test kind: ${KIND}" >&2
  exit 1
fi

MODULE_REPO_ROOT="$(get_module_repo_root)"
TEST_ROOT="$(get_test_root "${MODULE_REPO_ROOT}")"
RUN_ROOT="$(get_run_root "${MODULE_REPO_ROOT}")"

if [[ $# -eq 0 ]]; then
  mapfile -t tests < <(find_tests_by_kind "${TEST_ROOT}" "${KIND}")
else
  mapfile -t tests < <(normalize_test_args "${MODULE_REPO_ROOT}" "${TEST_ROOT}" "$@")
fi

if [[ ${#tests[@]} -eq 0 ]]; then
  echo "No ${KIND} tests found under ${TEST_ROOT}" >&2
  exit 1
fi

run_tests "${KIND}" "${RUN_ROOT}" "${tests[@]}"
