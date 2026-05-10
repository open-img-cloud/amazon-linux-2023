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
#   - install qemu-guest-agent (not in upstream) and enable it
#   - sysprep cleanup of dnf caches
#
# Note: virt-customize's `--install` uses libguestfs OS inspection to
# pick dnf for AL2023, which works out of the box (AL2023 is properly
# detected as an Amazon Linux fork).

set -euo pipefail

QCOW2="${1:?usage: customize.sh <path-to-qcow2>}"

if [[ ! -f "$QCOW2" ]]; then
  echo "::error::qcow2 not found: $QCOW2" >&2
  exit 1
fi

echo "[customize] target: $QCOW2"

virt-customize -a "$QCOW2" \
  --install qemu-guest-agent \
  --run-command 'systemctl enable qemu-guest-agent.service' \
  --run-command 'rm -rf /var/cache/dnf /var/cache/yum /tmp/* /var/tmp/*'

echo "[customize] done"
