# Wittenberg Ludus + GENEVA range

| Name | What |
| --- | --- |
| **wittenberg** | Debian Ludus host (Proxmox node) |
| **GENEVA** | Ludus user / range — GOAD + red-team infra, Defender ON |

Ollama / old implant NONE·EDR packs are gone. Source of truth is this repo — sync onto wittenberg when you deploy.

| Path | Purpose |
| --- | --- |
| [`SETUP.md`](SETUP.md) / [`setup-wittenberg.sh`](setup-wittenberg.sh) | Install Ludus + templates + GENEVA user |
| [`geneva/`](geneva/) | Range pack (`range.yml`) |
| [`pack-ranges.sh`](pack-ranges.sh) | Tarball for off-box copy |
| [`install-all-templates.sh`](install-all-templates.sh) | Optional: install *every* Packer template |

## Sync onto the host

```bash
rsync -av ./geneva/ ./SETUP.md ./setup-wittenberg.sh ./install-all-templates.sh \
  root@wittenberg:/opt/ranges/
```

## Deploy (templates must be BUILT)

```bash
ludus --user GENEVA range config set -f /opt/ranges/geneva/range.yml
ludus --user GENEVA range deploy
ludus --user GENEVA range logs -f
```
