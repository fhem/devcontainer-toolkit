#!/usr/bin/env bash
set -euo pipefail

cd "${FHEM_TEST_ROOT:?FHEM_TEST_ROOT must be set}"

PERL5LIB="${FHEM_PERL5LIB:-/usr/src/app/core/lib/perl5}${PERL5LIB:+:$PERL5LIB}"
export PERL5LIB

mapfile -t tests < <(find . -name '*.t' | sort)

if [[ ${#tests[@]} -eq 0 ]]; then
  echo "No .t tests found under $(pwd)" >&2
  exit 1
fi

PS3="Select a test to run: "
select test in "${tests[@]}"; do
  if [[ -n "${test:-}" ]]; then
    exec perl fhem.pl -t "$test"
  fi

  echo "Invalid selection" >&2
done
