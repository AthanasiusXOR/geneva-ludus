# Setup Ludus on Wittenberg

**Ludus user:** `admin`  
**Shell:** bashrc alias `admin` exports `LUDUS_API_KEY` — run it before every Ludus step.

## What the chain builds

| Step | Command | Result |
| --- | --- | --- |
| 1 | `./setup-wittenberg.sh --install` | Ludus on Wittenberg |
| 2 | `admin` then `--templates` | Packer: win2022, ubuntu-22.04, kali |
| 3 | `admin` then `--deploy` | **Geneva range** from `geneva/range.yml` |

### Geneva range contents (`--deploy`)

| VLAN | What |
| --- | --- |
| **10** | **GOAD AD** — kingslanding, winterfell, castelblack, meereen, braavos (Defender ON) |
| **20** | Redirectors `redir-e1-0`, `redir-w1-0` |
| **30** | Kali `linattack1`, `winattack1`, `c2server0/1`, `teamshare` |
| **40** | `ansible` |

### Network rules (in `range.yml`)

Default inter-VLAN: **REJECT**. Explicit ACCEPT:

- 40 → 30, 20, 10 (ansible → attack / redirs / GOAD)
- 10 → 20 (GOAD → redirs)
- 30 ↔ 20 (attack ↔ redirs) — C2 path through redirectors
- 30 → 10 (attack → GOAD)

WireGuard → VLANs: ACCEPT. Blocks `192.168.0.0/24` and `192.168.1.0/24`.

`--deploy` does **not** install Cobalt/Sliver/etc. on the C2 boxes — it builds the VMs and plumbing. You put the C2 software on later.

## Test chain (as `su -`)

```bash
su -
# ensure bashrc alias exists, e.g.:
#   alias admin="export LUDUS_API_KEY='admin.…'"

admin
cd /opt/ranges     # synced copy of this repo

# A) Ludus already installed? skip --install
# ./setup-wittenberg.sh --install

# B) Templates
./setup-wittenberg.sh --templates
ludus templates logs -f
ludus templates list    # all three BUILT / TRUE

# C) Range
./setup-wittenberg.sh --deploy
ludus range logs -f
```
