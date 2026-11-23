# Setup Ludus on Wittenberg

**Ludus user:** `admin`  
**Shell:** `admin` in `~/.bashrc` exports `LUDUS_API_KEY` — run that alias before any `ludus` command.

## Templates

```bash
su -
admin                    # bashrc alias → sets LUDUS_API_KEY
cd /opt/ranges
./setup-wittenberg.sh --templates
ludus templates logs -f
```

Manual equivalent:

```bash
admin
ludus source add ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates list
ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
```

## Deploy Geneva (after BUILT)

```bash
admin
ludus range config set -f /opt/ranges/geneva/range.yml
ludus range deploy
ludus range logs -f
```

GOAD VMs name as `admin-DC01`, etc.
