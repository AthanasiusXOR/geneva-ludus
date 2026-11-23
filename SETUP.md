# Setup Ludus on Wittenberg

**Ludus userid:** `administrator` (API key prefix / bashrc alias)  
**Display name:** use something else (e.g. `Lab Admin`) — Linux already has user `administrator`.

```bash
alias administrator="export LUDUS_API_KEY='administrator.…'"
```

## If `--install` ended with: username administrator already exists

Ludus is on disk; only initial-admin failed. **Do not re-run --install.** Fix:

```bash
su -
rm -f /opt/ludus/install/initial-admin.yml
systemctl restart ludus-admin
ludus-install-status
 export LUDUS_API_KEY='ROOT.…'

ludus user add --name 'Lab Admin' --userid administrator --admin --url https://127.0.0.1:8081
# copy administrator.… key into bashrc alias, then:
administrator
ludus user list
```

## What is in this directory

| Path | Purpose |
| --- | --- |
| `setup-wittenberg.sh` | `--install` / `--templates` / `--deploy` |
| `geneva/range.yml` | GOAD AD + Kali + C2 + redirs + VLAN rules |
| `geneva/inventory.yml` | Ansible inventory |
| `pack-ranges.sh` | Tarball for the Ludus box |

## Chain after the fix above

```bash
su -
administrator
cd /opt/ranges

./setup-wittenberg.sh --templates
ludus templates logs -f
ludus templates list          # win2022, ubuntu-22.04, kali = BUILT

./setup-wittenberg.sh --deploy
ludus range logs -f
```

Or fully manual templates + deploy — same commands as in the README.
