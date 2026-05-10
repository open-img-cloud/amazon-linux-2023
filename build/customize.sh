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
#   - dnf cache cleanup so the published qcow2 is smaller
#
# Originally we wanted to install qemu-guest-agent here too, but the
# upstream AL2023 repos at the snapshot URL pinned by the cloud image
# return "No match for argument: qemu-guest-agent" even with --refresh.
# Tracking that as a follow-up — when we resolve the right package name
# / repo enablement, add it back. For v1 we ship without qemu-ga;
# users who need it can `dnf install qemu-guest-agent` post-deploy
# after pointing the system at a fresh dnf snapshot.

set -euo pipefail

QCOW2="${1:?usage: customize.sh <path-to-qcow2>}"

if [[ ! -f "$QCOW2" ]]; then
  echo "::error::qcow2 not found: $QCOW2" >&2
  exit 1
fi

echo "[customize] target: $QCOW2"

virt-customize -a "$QCOW2" \
  --run-command 'rm -rf /var/cache/dnf /var/cache/yum /tmp/* /var/tmp/*'

echo "[customize] done"
