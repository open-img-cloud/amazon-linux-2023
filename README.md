<div id="top"></div>

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPL-2.0 License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">

<h3 align="center">Amazon Linux 2023 Cloud Images</h3>

  <p align="center">
    Cloud-init-ready, signed Amazon Linux 2023 images for OpenStack and Proxmox
    <br />
    <br />
    <a href="https://github.com/open-img-cloud/amazon-linux-2023/issues">Report a bug</a>
    ·
    <a href="https://github.com/open-img-cloud/amazon-linux-2023/issues">Request a feature</a>
  </p>
</div>

## About

This repo builds [Amazon Linux 2023][al2023] cloud images on top of the
upstream `al2023-kvm-*-kernel-6.1-x86_64.xfs.gpt.qcow2` artifact
published at
[cdn.amazonlinux.com/al2023/os-images/latest/kvm/][upstream] and
republishes it through the openimages.cloud signed-release pipeline.

The build pipeline is shared with the rest of [`open-img-cloud`][org]:
this repo only ships the `VERSION`, `customize.sh`, `detect-upstream.sh`,
and two thin caller workflows that delegate to the reusable workflows
in [`open-img-cloud/.github`][shared] (`@main`).

Customisations applied to the upstream rootfs:

- **qemu-guest-agent** added (not in the upstream image) and enabled
  at boot via systemd
- **Org-wide cloud-init policy drop-in** (`99_oic-policy.cfg`) injected
  by the reusable workflow into `/etc/cloud/cloud.cfg.d/`, pinning
  `datasource_list: [OpenStack, ConfigDrive, NoCloud, None]` and
  `disable_root: true` / `ssh_pwauth: false`
- **`virt-sysprep`** to clean transient state, then `virt-sparsify --compress`

The upstream AL2023 image already ships cloud-init, openssh-server,
GRUB2 with serial console wired (`console=tty0 console=ttyS0,115200`),
and the `ec2-user` default user — we don't override any of that.

Each release publishes:

- `al2023-<version>-x86_64.qcow2`
- `*.sha256`, `*.sha1`, `*.md5` per-file
- `*.bundle` cosign sigstore-bundle (signature + cert + Rekor proof)
- `MANIFEST.json` (build metadata, including the builder image digest)
- `index.html` directory listing

## Where to download

Public CDN, served via Cloudflare in front of an R2 bucket (mirror of
the source-of-truth Garage):

| URL pattern                                                                             | Cache policy                  |
|-----------------------------------------------------------------------------------------|-------------------------------|
| `https://images.openimages.cloud/amazon-linux-2023/<version>/<filename>`                | `max-age=31536000, immutable` |
| `https://images.openimages.cloud/amazon-linux-2023/latest/<filename>`                   | `max-age=300`                 |

Browse: [images.openimages.cloud/amazon-linux-2023/latest/][latest]

## Verify before deploy

cosign 3.x:

```sh
sha256sum -c <filename>.sha256                    # integrity
cosign verify-blob \
    --bundle <filename>.bundle \
    --new-bundle-format \
    --certificate-identity-regexp '^https://github.com/open-img-cloud/\.github/\.github/workflows/build-libguestfs-image\.yml@' \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com \
    <filename>                                     # provenance
```

The certificate identity points at the **reusable** build workflow in
`open-img-cloud/.github` — that's where GitHub's OIDC binds the SAN for
keyless signing, regardless of which caller repo invoked it. To tie the
artifact back to *this* repo's commit, also check `MANIFEST.json`: it
pins the caller `commit` SHA, the workflow run URL, and the builder
image digest.

## How to use

### OpenStack

```sh
# Pull the qcow2 (replace <V> with the desired version, e.g. 2023.11.20260509.0)
curl -fLO https://images.openimages.cloud/amazon-linux-2023/<V>/al2023-<V>-x86_64.qcow2

openstack image create \
    --disk-format qcow2 --container-format bare \
    --min-disk 25 \
    --file al2023-<V>-x86_64.qcow2 \
    'Amazon Linux 2023 <V>'
```

### Proxmox VE

```sh
scp al2023-<V>-x86_64.qcow2 root@proxmox:/var/lib/vz/template/iso/

qm create <VMID> --name al2023-template --memory 1024 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk <VMID> al2023-<V>-x86_64.qcow2 <STORAGE>
qm set <VMID> --scsihw virtio-scsi-pci --scsi0 <STORAGE>:vm-<VMID>-disk-0
qm set <VMID> --boot c --bootdisk scsi0
qm set <VMID> --ide2 <STORAGE>:cloudinit
qm set <VMID> --serial0 socket --vga serial0
qm set <VMID> --ciuser ec2-user --sshkeys ~/.ssh/authorized_keys --ipconfig0 ip=dhcp
```

## Release flow

1. **`watch.yml`** runs daily 06:29 UTC, calls `build/detect-upstream.sh`
   which follows the `latest/` 302 redirect to extract the version
   segment from the resolved CDN URL.
2. If the version differs from the current `VERSION`, the workflow opens
   (or updates) a PR `auto/upstream-bump`.
3. Merging the PR + pushing a `v<VERSION>` tag fires `release.yml`,
   which calls the shared `build-libguestfs-image.yml@main` reusable
   workflow.
4. Each build downloads the upstream qcow2, runs `customize.sh`,
   sysprep, sparsify, signs, and uploads to Garage + R2 under
   `s3://amazon-linux-2023/<version>/`. The `latest/` alias is replaced
   and Cloudflare cache for `latest/` is purged.

## Repository layout

```
VERSION                          single line, e.g. "2023.11.20260509.0"
build/
  customize.sh                   virt-customize hook (qcow2 path as $1)
  detect-upstream.sh             prints latest upstream version (follow latest/ 302)
.github/workflows/
  release.yml                    calls build-libguestfs-image.yml on tag push
  watch.yml                      daily cron, calls upstream-watch.yml
.gitignore                       repo-local override for global build/ exclusion
LICENSE                          GPL-2.0
```

## Contributing

Fork, branch, PR. Keep changes focused; the customize hook in particular
is consumed by the shared pipeline so backward-compatible tweaks are
preferred over rewrites.

## License

Distributed under the GPL-2.0 License. See `LICENSE`.

## Contact

Kevin Allioli — kevin@stackops.ch · [@stackopshq](https://twitter.com/stackopshq)

Project: [open-img-cloud/amazon-linux-2023](https://github.com/open-img-cloud/amazon-linux-2023)

[al2023]: https://aws.amazon.com/linux/amazon-linux-2023/
[upstream]: https://cdn.amazonlinux.com/al2023/os-images/latest/kvm/
[org]: https://github.com/open-img-cloud
[shared]: https://github.com/open-img-cloud/.github
[latest]: https://images.openimages.cloud/amazon-linux-2023/latest/

<!-- shields -->
[contributors-shield]: https://img.shields.io/github/contributors/open-img-cloud/amazon-linux-2023.svg?style=for-the-badge
[contributors-url]: https://github.com/open-img-cloud/amazon-linux-2023/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/open-img-cloud/amazon-linux-2023.svg?style=for-the-badge
[forks-url]: https://github.com/open-img-cloud/amazon-linux-2023/network/members
[stars-shield]: https://img.shields.io/github/stars/open-img-cloud/amazon-linux-2023.svg?style=for-the-badge
[stars-url]: https://github.com/open-img-cloud/amazon-linux-2023/stargazers
[issues-shield]: https://img.shields.io/github/issues/open-img-cloud/amazon-linux-2023.svg?style=for-the-badge
[issues-url]: https://github.com/open-img-cloud/amazon-linux-2023/issues
[license-shield]: https://img.shields.io/github/license/open-img-cloud/amazon-linux-2023.svg?style=for-the-badge
[license-url]: https://github.com/open-img-cloud/amazon-linux-2023/blob/main/LICENSE
