# Wittenberg — implant / EDR test range

Ludus host: **reformation**  
Ludus user / range: **WITTENBERG**  
Ollama lives in the sibling range: [`../geneva/`](../geneva/)

Slim profile for a shared ~60 GB box: NONE + EDR cells, attack1 only. Falcon / Ubuntu MDE / attack2–5 deferred.

## Create the Ludus user (once, as admin on reformation)

```bash
# Use your admin API key
ludus user add -n 'Wittenberg' -i WITTENBERG
# Save the printed API key
```

## Templates required

```bash
ludus templates build -n win2022-server-x64-template,win11-22h2-x64-enterprise-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
```

## Deploy

```bash
cd wittenberg
 export LUDUS_API_KEY='WITTENBERG.…'   # or: ludus --user WITTENBERG …
ludus range config set -f range.yml
ludus range deploy
ludus range logs -f
```

Admin shortcut without switching keys:

```bash
ludus --user WITTENBERG range config set -f range.yml
ludus --user WITTENBERG range deploy
ludus --user WITTENBERG range logs -f
```

### Power only what fits (~28 GB without Geneva)

```bash
ludus --user WITTENBERG power on -n teamshare,linattack1,winattack1,c2server0,c2server1,redir-e1-0,redir-w1-0,ansible,D-NONE-NOINT,W-NONE-NOINT
ludus --user WITTENBERG power off -n D-NONE-INT,W-NONE-INT,D-EDR-NOINT,W-EDR-NOINT,D-EDR-INT,W-EDR-INT
```

Leave headroom if **GENEVA** (Ollama ~16 GB) is also running.

## Ansible post-config

```bash
# Stamp Wittenberg's range number into inventories
export LUDUS_API_KEY='WITTENBERG.…'
./stamp-range-number.sh

ansible-galaxy collection install -r requirements.yml
ansible-playbook deploy-range.yml

# One cell only:
ansible-playbook deploy-range.yml --limit 'attack_space:redirectors:ansible_ctrl:D-NONE-NOINT:W-NONE-NOINT'
```

| Playbook | Purpose |
| --- | --- |
| `deploy-range.yml` | Imports all Wittenberg post-config |
| `deploy-teamshare.yml` | Watchlogs for 4 domain cells |
| `deploy-lin.yml` | SSH key + notes on linattack1 |
| `deploy-win.yml` | AD verify, placeholder implant, cohab |

## RAM (this range alone)

| Set | Approx |
| --- | --- |
| All Wittenberg VMs defined | ~52 GB |
| Attack + one target cell | **~28 GB** |
| + Geneva Ollama (separate range) | **~44 GB** — still OK on reformation |

## Layout

```
wittenberg/
  range.yml
  inventory.yml
  red-infra-inventory.yml
  group_vars/all.yml
  deploy-*.yml
  tasks/ templates/ files/
```
