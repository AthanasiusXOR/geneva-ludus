# GENEVA range

Ludus host: **wittenberg** (Debian base)  
Ludus user: **GENEVA**

Red-team attack infra + **GOAD** targets, with **Microsoft Defender Antivirus enabled** (no `disable_defender` GPOs).

| VLAN | Contents |
| --- | --- |
| 10 | GOAD (kingslanding, winterfell, castelblack, meereen, braavos) |
| 20 | Redirectors |
| 30 | Kali, winattack, C2s, teamshare |
| 40 | Ansible |

Config: **`range.yml`**

From-scratch Ludus install + deploy: see [`../SETUP.md`](../SETUP.md).

## Creds (lab defaults)

| Host | User | Pass |
| --- | --- | --- |
| Kali (`linattack1`) | kali | kali |
| Debian/Ubuntu | localuser / debian | password / debian |
| GOAD domainadmin | domainadmin | password |

Cloud MDE (tenant EDR) still needs your onboarding package if you want cloud console — Defender AV is already on without it.

## After Ludus deploy

```bash
cd geneva
RANGENUMBER=$(ludus --user GENEVA range list --json | jq -r '.rangeNumber // .[0].rangeNumber')
./stamp-range-number.sh
# optional:
ansible-playbook deploy-range.yml --limit linattack
```
