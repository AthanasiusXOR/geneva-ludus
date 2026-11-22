# Setup Ludus on Wittenberg

**Ludus user / API key:** `admin`  
(`export LUDUS_API_KEY='admin.…'` from `ludus-install-status` — **not** ROOT)

## Templates (run as `su -`)

```bash
su -
export LUDUS_API_KEY='admin.…'    # leading space optional to skip history

cd /opt/ranges    # or your checkout
./setup-wittenberg.sh --templates
ludus templates logs -f
```

Manual equivalent if the script still fails:

```bash
export LUDUS_API_KEY='admin.…'
echo "acting as: ${LUDUS_API_KEY%%.*}"   # must print: admin

ludus source add ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates list
ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
```

## Deploy Geneva (after BUILT)

```bash
export LUDUS_API_KEY='admin.…'
ludus range config set -f /opt/ranges/geneva/range.yml
ludus range deploy
ludus range logs -f
```

GOAD VMs will be named `admin-DC01`, etc.
