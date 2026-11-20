# Implant Testing Range (Geneva slim)

EDR implant test range sized for a **~60 GB** Ludus host (Geneva), plus a **no-rail Ollama** box on the attack VLAN.

Falcon cells, Ubuntu MDE targets, and attack2–5 fleets from the full diagram are **out of scope** for this slim profile. Re-add them later on bigger hardware.

## What changed vs the old pack

| Item | Old | Slim |
| --- | --- | --- |
| Windows DC/WK RAM | 8 GB | **4 GB** |
| Attack / C2 / ansible | 2–8 GB | **1–6 GB** |
| Attack fleet | lin/win 1–5 | **attack1 only** |
| Ollama | none | **`ollama-rt` 12 GB** (VLAN 30 `.50`) |
| Snapshots | RAM+disk | **disk only** |
| Ansible | range-4 hostnames (`LIN01`, `domain_one_ad`, …) | **matches this `range.yml`** |

### RAM budget

| Set | Approx RAM |
| --- | --- |
| All VMs defined (do not power all) | ~64 GB |
| **Recommended on:** attack stack + ollama + ONE target cell | **~40 GB** |

## Templates required

Build these before deploy:

```bash
ludus templates build -n win2022-server-x64-template,win11-22h2-x64-enterprise-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template,debian-13-x64-server-template
ludus templates logs -f
```

## Deploy Ludus range

```bash
cd implant-testing-range
ludus range config set -f range.yml
ludus range deploy
ludus range logs -f
```

### Power only what fits

After deploy, leave extra target cells **off**:

```bash
# Example: attack + ollama + NONE-NOINT only
ludus power on -n teamshare,linattack1,winattack1,c2server0,c2server1,redir-e1-0,redir-w1-0,ansible,ollama-rt,D-NONE-NOINT,W-NONE-NOINT

# Keep other cells off
ludus power off -n D-NONE-INT,W-NONE-INT,D-EDR-NOINT,W-EDR-NOINT,D-EDR-INT,W-EDR-INT
```

Switch cells by powering one pair down and another up (still ~+8 GB).

## Ansible post-config

On the ansible box (or any host that can reach range VLANs):

```bash
# Stamp your range number into inventories
export RANGENUMBER=$(ludus range list --json | jq -r '.rangeNumber // .[0].rangeNumber // empty')
sed -i "s/RANGE_NUMBER/${RANGENUMBER}/g" inventory.yml red-infra-inventory.yml

ansible-galaxy collection install -r requirements.yml
ansible-playbook deploy-range.yml
```

If only one cell is powered:

```bash
ansible-playbook deploy-range.yml --limit 'attack_space:redirectors:ansible_ctrl:D-NONE-NOINT:W-NONE-NOINT'
```

### Playbooks

| File | Purpose |
| --- | --- |
| `deploy-range.yml` | Imports everything |
| `deploy-teamshare.yml` | `/mnt/share/network-data/<domain>/watchlog.md` for all 4 cells |
| `deploy-lin.yml` | Operator SSH key + notes on **linattack1** (no Linux targets in slim) |
| `deploy-win.yml` | AD verify, placeholder implant, cohab listeners |
| `deploy-ollama.yml` | Install Ollama, pull abliterated Dolphin, create `rt-assist` |

## Ollama (red team / low refusal)

- Host: `ollama-rt` → `10.<RANGE>.30.50:11434`
- Model: `rt-assist` (from `huihui_ai/dolphin3-abliterated`)

```bash
curl http://10.<RANGE>.30.50:11434/api/generate -d '{
  "model": "rt-assist",
  "prompt": "Summarize a lab Kerberoasting workflow.",
  "stream": false
}'
```

## Layout

```
implant-testing-range/
  range.yml                 # Ludus config (slim)
  inventory.yml             # Ansible inventory (targets + attack)
  red-infra-inventory.yml   # Operator/C2 inventory
  group_vars/all.yml
  deploy-*.yml
  tasks/
  templates/
  files/                    # tcp_listener.exe, lin_key(+.pub)
  ansible.cfg
  requirements.yml
```

## Intentionally deferred (full diagram)

- Falcon (FALC) cells
- Ubuntu MDE targets (`FOX-U-MDE-*`)
- `linattack2–5` / `winattack2–5`

Add those only after more host RAM or when running as a second powered-off catalog.
