# Wittenberg — implant / EDR test range

Ludus host: **reformation**  
Ludus user / range: **WITTENBERG**  
Ollama lives in the sibling range: [`../geneva/`](../geneva/)

This directory is the **source of truth** for the range config + post-deploy Ansible. Keep a copy outside Ludus (git clone / rsync). On reformation, `/opt/ranges/wittenberg` is just a working checkout — prefer pulling from this repo over hand-editing on the Ludus host.

## What’s in this range

- Targets: NONE + EDR cells (DC + Win11), internet / no-internet  
- Attack: `linattack1` (Kali), `winattack1`, C2s, redirs, teamshare, ansible  
- Not included: Ollama (Geneva)

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
