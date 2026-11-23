# Geneva range (Wittenberg / Ludus user AD)

| File | Purpose |
| --- | --- |
| `range.yml` | Ludus deploy — GOAD + red infra + VLAN forward rules |
| `inventory.yml` | Ansible hosts (set `RANGE_NUMBER` after deploy) |
| `deploy-range.yml` | Optional Kali SSH key post-config |

```bash
administrator
ludus source add ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f

ludus range config set -f range.yml
ludus range deploy
ludus range logs -f

sed -i "s/RANGE_NUMBER/$(ludus range list --json | jq -r '.rangeNumber // .[0].rangeNumber')/g" inventory.yml
```
