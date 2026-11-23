# Setup Ludus on Wittenberg

**Ludus user:** `administrator`  
**Shell alias:** `administrator` in `~/.bashrc` exports `LUDUS_API_KEY`.

Example bashrc line:

```bash
alias administrator="export LUDUS_API_KEY='administrator.…'"
```

## What is in this directory

| Path | Purpose |
| --- | --- |
| `setup-wittenberg.sh` | `--install` / `--templates` / `--deploy` |
| `geneva/range.yml` | **Full range**: GOAD AD + Kali + C2 + redirs + VLAN rules |
| `geneva/inventory.yml` | Ansible inventory (GOAD + attack) |
| `geneva/red-infra-inventory.yml` | Operator-focused inventory |
| `geneva/deploy-*.yml` | Optional Kali post-config |
| `pack-ranges.sh` | Tarball to copy onto Wittenberg |
| `install-all-templates.sh` | Optional: every Packer template (not required) |

Yes — GOAD and red-infra are **one** range file: `geneva/range.yml`.

## Chain (as `su -`)

```bash
su -
administrator                 # alias → LUDUS_API_KEY

cd /opt/ranges                # synced copy of this repo

# 1) Ludus (skip if already installed)
# ./setup-wittenberg.sh --install

# 2) Templates
./setup-wittenberg.sh --templates
ludus templates logs -f
ludus templates list          # win2022, ubuntu-22.04, kali = BUILT

# 3) Deploy GOAD + red infra
./setup-wittenberg.sh --deploy
ludus range logs -f
```

## Range contents (`--deploy`)

| VLAN | What |
| --- | --- |
| 10 | GOAD AD (5 Windows) — Defender ON |
| 20 | redir-e1-0, redir-w1-0 |
| 30 | linattack1 (Kali), winattack1, c2server0/1, teamshare |
| 40 | ansible |

Network: inter-VLAN default REJECT; ACCEPT ansible→10/20/30, GOAD→redirs, attack↔redirs, attack→GOAD.

C2 **software** is not installed by Ludus — VMs + plumbing only.
