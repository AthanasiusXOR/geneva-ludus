# Geneva range

Ludus host: **wittenberg**  
Ludus user: **administrator** (bashrc alias `administrator` exports `LUDUS_API_KEY`)

Single config: **`range.yml`** — GOAD AD + red infra (Kali, C2s, redirs, teamshare, ansible).

| VLAN | Contents |
| --- | --- |
| 10 | GOAD (kingslanding, winterfell, castelblack, meereen, braavos) — Defender ON |
| 20 | Redirectors |
| 30 | Kali, winattack, C2s, teamshare |
| 40 | Ansible |

GOAD VM names: `administrator-DC01`, etc.

```bash
administrator
ludus range config set -f range.yml
ludus range deploy
# or from repo root: ./setup-wittenberg.sh --deploy
```
