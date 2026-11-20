# Geneva range

Ludus host: **wittenberg**  
Ludus user: **ATHANASIUS** (API key = root/admin alias)

Red-team attack infra + **GOAD**, Microsoft Defender Antivirus **on**.

| VLAN | Contents |
| --- | --- |
| 10 | GOAD (kingslanding, winterfell, castelblack, meereen, braavos) |
| 20 | Redirectors |
| 30 | Kali, winattack, C2s, teamshare |
| 40 | Ansible |

Config: **`range.yml`** — GOAD VMs name as `ATHANASIUS-DC01`, etc.

From-scratch: [`../SETUP.md`](../SETUP.md).

## Creds

| Host | User | Pass |
| --- | --- | --- |
| Kali (`linattack1`) | kali | kali |
| Debian/Ubuntu | localuser / debian | password / debian |
| GOAD domainadmin | domainadmin | password |

## After Ludus deploy

```bash
 export LUDUS_API_KEY='…'   # ATHANASIUS
cd geneva
RANGENUMBER=$(ludus --user ATHANASIUS range list --json | jq -r '.rangeNumber // .[0].rangeNumber')
./stamp-range-number.sh
ansible-playbook deploy-range.yml --limit linattack   # optional
```
