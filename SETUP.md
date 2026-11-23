# Setup Ludus on Wittenberg

| | |
| --- | --- |
| Ludus **userid** | `AD` (API key prefix) |
| Shell **alias** | `administrator` → `export LUDUS_API_KEY='AD.…'` |

```bash
alias administrator="export LUDUS_API_KEY='AD.…'"
```

The alias name and the Ludus userid are **not** the same thing. Scripts check the key prefix is `AD`.

## If install hit “username administrator already exists”

```bash
rm -f /opt/ludus/install/initial-admin.yml
systemctl restart ludus-admin
ludus-install-status
 export LUDUS_API_KEY='ROOT.…'
ludus user add --name 'Lab Admin' --userid AD --admin --url https://127.0.0.1:8081
```

## Chain

```bash
su -
administrator
cd /opt/ranges

./setup-wittenberg.sh --templates
ludus templates logs -f

./setup-wittenberg.sh --deploy
ludus range logs -f
```

`geneva/range.yml` = GOAD AD + Kali + C2 + redirs + VLAN rules.
