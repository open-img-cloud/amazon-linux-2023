#!/usr/bin/env bash
# Prints the latest upstream Amazon Linux 2023 cloud-image version on stdout.
#
# AL2023 publishes versioned cloud images at
#   https://cdn.amazonlinux.com/al2023/os-images/<version>/kvm/al2023-kvm-<version>-kernel-6.1-x86_64.xfs.gpt.qcow2
# The CDN exposes a `/latest/` symlink that 302-redirects to the current
# stable directory — we follow the redirect and extract the version
# segment from the resulting URL. Format: YYYY.M.YYYYMMDD.N.
#
# Runs in the upstream-watch reusable workflow (no KVM needed) — keep
# it portable bash + curl only.

set -euo pipefail

URL='https://cdn.amazonlinux.com/al2023/os-images/latest/'

# Follow the redirect with -I (HEAD) -L (follow), but capture the location
# header from the FIRST response so we get the canonical resolved URL.
location=$(curl -fsI "$URL" | awk -F': ' 'tolower($1)=="location"{sub(/\r$/,"",$2); print $2; exit}')
if [[ -z "${location:-}" ]]; then
  echo "::error::no Location header on $URL — upstream may have changed the layout" >&2
  exit 1
fi

# Expected: https://cdn.amazonlinux.com/al2023/os-images/<VERSION>/
version=$(printf '%s' "$location" | sed -E 's|.*/os-images/([^/]+)/.*|\1|')
if [[ -z "$version" || "$version" == "$location" ]]; then
  echo "::error::could not extract version from redirect target: $location" >&2
  exit 1
fi

printf '%s\n' "$version"
