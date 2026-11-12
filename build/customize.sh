#!/usr/bin/env bash
# Customize hook called by the build-libguestfs-image reusable workflow.
# Receives the qcow2 path as $1. Runs inside the stackopshq builder
# container with /dev/kvm exposed.
#
# Amazon Linux 2023 cloud images (the `al2023-kvm-*.xfs.gpt.qcow2`
# variant) ship with cloud-init, openssh-server, GRUB2 with serial
# console already wired, and the `ec2-user` default user pre-configured.
# The org-wide cloud-init policy drop-in (datasource_list,
# disable_root, ssh_pwauth, mount_default_fields) is injected by the
# reusable workflow AFTER this script runs, so we don't need to ship
# any cloud.cfg.d/ override here.
#
# Customisation reduces to:
#   - qemu-guest-agent (filesystem freeze for snapshots, IP reporting)
#   - dnf cache cleanup so the published qcow2 is smaller
#
# qemu-guest-agent comes from the AL2023 repositories (snapshot of the
# image release). An earlier attempt failed with "No match" because the
# builder had no network then (passt under Docker, fixed in builder 2.1.1).

set -euo pipefail

QCOW2="${1:?usage: customize.sh <path-to-qcow2>}"

if [[ ! -f "$QCOW2" ]]; then
  echo "::error::qcow2 not found: $QCOW2" >&2
  exit 1
fi

echo "[customize] target: $QCOW2"

virt-customize -a "$QCOW2" \
  --run-command 'dnf install -y qemu-guest-agent' \
  --run-command 'rpm -q qemu-guest-agent' \
  --run-command 'rm -rf /var/cache/dnf /var/cache/yum /tmp/* /var/tmp/*'

echo "[customize] done"
