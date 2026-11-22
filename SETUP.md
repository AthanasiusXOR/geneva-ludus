# Setup Ludus on Wittenberg

## Stop — if templates are empty right now

The helper script is optional. Do this **by hand** with the **initial admin** key (the one user you already see in `ludus user list`), **not ROOT**, **no sudo**:

```bash
su -
ludus-install-status
# Copy "API key for user <ADMIN>:"  →  looks like  ADMINID.xxxxx
# Do NOT use the ROOT key for templates.

exit   # back to a normal shell is fine if that shell has the key
 export LUDUS_API_KEY='ADMINID.…'     # leading space = no shell history

# Sanity
echo "acting as: ${LUDUS_API_KEY%%.*}"
ludus user list
ludus source list
ludus templates list
```

### If `templates list` already shows win2022 / kali / debian rows

Skip install — just build:

```bash
ludus source add ludus-source-bsl --templates ubuntu-22.04-x64-server-template
ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
```

### If `templates list` is empty

Install defs into **this** user’s catalog, then build:

```bash
ludus source list
# Use the BSL id you see (often ludus-source-bsl). If missing, use the URL.

ludus source add ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
# if that errors:
ludus source add https://github.com/badsectorlabs/ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
# nuclear option (installs everything in BSL):
# ludus source add ludus-source-bsl --all

ludus templates list    # must show the three names
ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
```

### Why ROOT / sudo / ATHANASIUS-without-catalog fail

| Mistake | Result |
| --- | --- |
| `LUDUS_API_KEY=ROOT.…` | Empty or useless template catalog |
| `sudo ./setup-…` | Key not passed → silent/no-op |
| Created ATHANASIUS but never `source add` under **that** key | Empty list for ATHANASIUS |

Built Packer images are shared host-wide by name; **defs** in `templates list` are per API-key user.

---

## Optional: ATHANASIUS as second admin

Only after you can `templates list` as the install admin (or you accept building under ATHANASIUS after a fresh `source add`):

```bash
# Needs a key that can hit admin API (ROOT or existing admin):
ludus user add --name 'Athanasius' --userid ATHANASIUS --admin --url https://127.0.0.1:8081
 export LUDUS_API_KEY='ATHANASIUS.…'
ludus source add ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
```

Geneva range deploy (after templates show BUILT):

```bash
ludus --user ATHANASIUS range config set -f /opt/ranges/geneva/range.yml
# or without --user if LUDUS_API_KEY is already ATHANASIUS:
ludus range config set -f /opt/ranges/geneva/range.yml
ludus range deploy
ludus range logs -f
```

## Templates Geneva needs

| Template |
| --- |
| `win2022-server-x64-template` |
| `ubuntu-22.04-x64-server-template` |
| `kali-x64-desktop-template` |
