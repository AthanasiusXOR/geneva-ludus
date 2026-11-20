# Wittenberg — red team + GOAD + Defender

Ludus host: **reformation** · User: **WITTENBERG**

**Preferred config now:** [`range-goad.yml`](range-goad.yml) — see [`GOAD-DEFENDER.md`](GOAD-DEFENDER.md).

| File | Purpose |
| --- | --- |
| `range-goad.yml` | **Use this** — GOAD targets + attack stack, Defender AV on |
| `range.yml` | Old NONE/EDR matrix (legacy) |
| `GOAD-DEFENDER.md` | Deploy steps + MDE onboarding notes |

- Attack: kali, winattack, C2s, redirs, teamshare, ansible  
- Targets: GOAD (sevenkingdoms / north / essos)  
- Microsoft Defender Antivirus: **enabled** (no `disable_defender` GPO)  
- Park Geneva while deploying: `ludus --user GENEVA power off -n all`

## Credentials (Ludus defaults)

| Hosts | User | Password |
| --- | --- | --- |
| Domain Windows | `domainadmin` | `password` |
| Ubuntu / Debian attack infra | `localuser` | `password` |
| **Kali `linattack1`** | **`kali`** | **`kali`** |

## Create Ludus user (once)

```bash
ludus users add -n 'Wittenberg' -i WITTENBERG
# set WebUI/Proxmox password + email; save API key
```

## Deploy Ludus range

```bash
ludus --user WITTENBERG range config set -f range.yml
ludus --user WITTENBERG range deploy
ludus --user WITTENBERG range logs -f
ludus --user WITTENBERG range status
```

Power one target cell at a time on a ~60 GB host.

## Ansible post-config (after Ludus deploy)

Ludus does **not** run these playbooks automatically.

```bash
cd wittenberg
# Stamp range number into inventories (needs API key or RANGENUMBER=)
./stamp-range-number.sh

ansible-galaxy collection install -r requirements.yml
ansible-playbook deploy-range.yml

# One cell only (example):
ansible-playbook deploy-range.yml --limit 'attack_space:redirectors:ansible_ctrl:D-NONE-NOINT:W-NONE-NOINT'
```

| Playbook | Purpose |
| --- | --- |
| `deploy-range.yml` | Imports all post-config |
| `deploy-teamshare.yml` | Watchlogs under `/mnt/share/network-data/` |
| `deploy-lin.yml` | SSH key + notes on Kali |
| `deploy-win.yml` | AD verify, placeholder implant, cohab |

### Known fixes already in this repo

1. Kali = `kali`/`kali` (not `localuser`/`password`)  
2. Teamshare template `src: watchlog.md.j2` (not `templates/watchlog.md.j2`)  
3. Do not set `geneva_ollama_url: "{{ geneva_ollama_url }}"` in task vars (recursive loop)

## Layout

```
wittenberg/
  range.yml
  inventory.yml              # keep RANGE_NUMBER here; stamp on deploy host
  red-infra-inventory.yml
  group_vars/all.yml
  deploy-*.yml
  tasks/ templates/ files/
  stamp-range-number.sh
```
