<p align="center">
  <a href="https://openimages.cloud/images/amazon-linux-2023/">
    <img src="https://openimages.cloud/img/og/amazon-linux-2023.png" alt="Amazon Linux 2023 cloud image for OpenStack and Proxmox" width="720">
  </a>
</p>

<p align="center">
  <a href="https://openimages.cloud/images/amazon-linux-2023/"><img alt="Latest version" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fimages.openimages.cloud%2Famazon-linux-2023%2Flatest%2FMANIFEST.json&query=%24.version&label=latest&color=2459c4&cacheSeconds=3600"></a>
  <a href="https://github.com/open-img-cloud/amazon-linux-2023/actions/workflows/release.yml"><img alt="Release" src="https://github.com/open-img-cloud/amazon-linux-2023/actions/workflows/release.yml/badge.svg"></a>
  <a href="https://openimages.cloud/verify/"><img alt="Signed with Sigstore cosign" src="https://img.shields.io/badge/signed-Sigstore%20cosign-2459c4"></a>
  <a href="https://openimages.cloud/quality/"><img alt="Boot-tested on OpenStack" src="https://img.shields.io/badge/boot--tested-OpenStack-2459c4"></a>
  <a href="LICENSE"><img alt="License GPL-2.0" src="https://img.shields.io/badge/license-GPL--2.0-555"></a>
</p>

<p align="center">
  <a href="https://openimages.cloud/images/amazon-linux-2023/"><b>Catalog page</b></a> ·
  <a href="https://images.openimages.cloud/amazon-linux-2023/latest/">Download</a> ·
  <a href="https://openimages.cloud/verify/">Verify</a> ·
  <a href="https://github.com/open-img-cloud/docs">Documentation</a> ·
  <a href="https://github.com/open-img-cloud/amazon-linux-2023/issues">Report an issue</a>
</p>

Amazon Linux 2023 cloud image (qcow2) for **OpenStack** and **Proxmox**: the official AWS KVM
image with kernel 6.1, verified, made ready for both clouds with the same rules as every
[openimages.cloud](https://openimages.cloud) image, signed with Sigstore cosign and boot-tested
on a real OpenStack before it is published.

## At a glance

| | |
|---|---|
| **Upstream** | [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/) KVM image `al2023-kvm-<version>-kernel-6.1-x86_64.xfs.gpt.qcow2` from [cdn.amazonlinux.com](https://cdn.amazonlinux.com/al2023/os-images/latest/kvm/), checked against its `SHA256SUMS` |
| **Default user** | `ec2-user`, SSH key only, passwordless `sudo` |
| **Firmware** | BIOS |
| **Format** | qcow2, x86_64, root filesystem grown to the disk at first boot |
| **Disk** | the image declares a 25 GB virtual disk: use a flavor with at least a 25 GB root disk |
| **Version** | the upstream release, `2023.<minor>.<date>.<build>`, e.g. `2023.12.20261109.0` ([all versions](https://images.openimages.cloud/amazon-linux-2023/versions.json)) |
| **Support** | Amazon Linux 2023 is the successor of Amazon Linux 2, supported by AWS |

## Quick start

```sh
# Latest version and its file name, from the signed manifest
M=https://images.openimages.cloud/amazon-linux-2023/latest/MANIFEST.json
V=$(curl -fsS $M | jq -r .version); F=$(curl -fsS $M | jq -r .filename)
curl -fLO https://images.openimages.cloud/amazon-linux-2023/$V/$F
```

<details>
<summary><b>OpenStack</b></summary>

```sh
openstack image create --disk-format qcow2 --container-format bare \
  --min-disk 25 \
  --property os_distro=amzn --property os_version=2023 \
  --property os_admin_user=ec2-user \
  --file "$F" "Amazon Linux 2023"
```

The full property set is on the
[catalog page](https://openimages.cloud/images/amazon-linux-2023/) and in
[`index.json`](https://images.openimages.cloud/index.json). To keep images up to date
automatically, use [oic-sync](https://github.com/open-img-cloud/oic-sync).

</details>

<details>
<summary><b>Proxmox VE</b></summary>

The commands to create a cloud-init template from this image are on the
[catalog page](https://openimages.cloud/images/amazon-linux-2023/).

</details>

<details>
<summary><b>Verify the signature</b></summary>

```sh
curl -fLO https://images.openimages.cloud/amazon-linux-2023/$V/$F.bundle
cosign verify-blob "$F" --bundle "$F.bundle" \
  --certificate-identity-regexp '^https://github.com/open-img-cloud/\.github/\.github/workflows/build-(libguestfs|dib|nix-flake|freebsd)-image\.yml@' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

</details>

## What this image changes

On top of the official image, and nothing else:

- adds the openimages.cloud cloud-init policy: config drive read first, then the metadata
  service; no root login, no SSH password;
- cleans package caches and machine identity so every instance starts fresh.

The upstream image already ships cloud-init, OpenSSH, a serial console and the `ec2-user`
default user; they are left as they are. `qemu-guest-agent` is not included: the package is
missing from the dnf snapshot the upstream image points at. Install it after deployment
(`dnf install qemu-guest-agent`, against a current repository) if you need it.

Every release must pass the same [runtime contract](https://openimages.cloud/quality/) on
OpenStack: SSH with the injected key, cloud-init finished, DNS, hostname, root filesystem grown,
passwordless `sudo`, IPv6 address and egress.

## How releases happen

1. Every day at 06:29 UTC a watcher looks for a new upstream image and opens a pull request
   that bumps [`VERSION`](VERSION).
2. Merging it is all it takes: the release is tagged, built, signed, boot-tested and
   published, then `latest/` and the [catalog](https://openimages.cloud/images/) move to it.

This repository only holds what is specific to Amazon Linux 2023: [`VERSION`](VERSION),
[`build/customize.sh`](build/customize.sh), [`build/detect-upstream.sh`](build/detect-upstream.sh)
and thin workflows calling the shared pipeline in
[`open-img-cloud/.github`](https://github.com/open-img-cloud/.github).

## License

The build tooling in this repository is under [GPL-2.0](LICENSE). The image keeps the licensing
terms of Amazon Linux 2023 (each package under its own license). Amazon Linux is a trademark of
its owner; this project is not affiliated with Amazon Web Services.
