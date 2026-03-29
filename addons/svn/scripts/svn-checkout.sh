#!/bin/bash
set -euo pipefail

SVN_PARENT="${FHEM_SVN_PARENT:-/workspace/fhem-svn}"
SVN_TARGET="${FHEM_SVN_ROOT:-${SVN_PARENT}/fhem}"
SVN_URL="${FHEM_SVN_URL:-svn+ssh://svn.fhem.de/trunk/fhem}"
SVN_USER_HINT="${FHEM_SVN_USER_HINT:-the container user}"

if [[ ! -d "${SVN_PARENT}" ]]; then
  echo "ERROR: ${SVN_PARENT} does not exist." >&2
  echo "This is a host-mounted directory. Create it on the host before running SVN tasks." >&2
  exit 1
fi

if [[ ! -w "${SVN_PARENT}" ]]; then
  echo "ERROR: ${SVN_PARENT} is not writable for ${SVN_USER_HINT}." >&2
  echo "This is a host/mount permission problem, not an SVN problem." >&2
  exit 1
fi

if [[ -e "${SVN_TARGET}" ]]; then
  echo "ERROR: ${SVN_TARGET} already exists." >&2
  echo "Refusing to overwrite an existing SVN working copy or directory." >&2
  exit 1
fi

svn checkout "${SVN_URL}" "${SVN_TARGET}"
