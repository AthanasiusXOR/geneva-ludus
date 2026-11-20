# Wittenberg Ludus + Geneva range

| Name | What |
| --- | --- |
| **wittenberg** | Debian Ludus host (Proxmox node) |
| **ATHANASIUS** | Ludus user — API key is your root/admin alias; owns the Geneva range |
| **geneva/** | Range pack — GOAD + red-team infra, Defender ON |

| Path | Purpose |
| --- | --- |
| [`SETUP.md`](SETUP.md) / [`setup-wittenberg.sh`](setup-wittenberg.sh) | Install Ludus + **template download/build** + ATHANASIUS |
| [`geneva/`](geneva/) | Range pack (`range.yml`) |
| [`pack-ranges.sh`](pack-ranges.sh) | Tarball for off-box copy |
| [`install-all-templates.sh`](install-all-templates.sh) | Optional: every Packer template |

## Sync onto the host

```bash
rsync -av ./geneva/ ./SETUP.md ./setup-wittenberg.sh ./install-all-templates.sh \
  root@wittenberg:/opt/ranges/
```

## Deploy (templates must be BUILT; use ATHANASIUS API key)

```bash
 export LUDUS_API_KEY='…'   # ATHANASIUS key
ludus --user ATHANASIUS range config set -f /opt/ranges/geneva/range.yml
ludus --user ATHANASIUS range deploy
ludus --user ATHANASIUS range logs -f
```
