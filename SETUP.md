# Setup Ludus on Wittenberg

Run on the **Wittenberg** host (SSH as root). Fresh Debian 12/13, nested virt if a VM, large disk, ~60 GB+ RAM.

**Ludus user:** `ATHANASIUS` — create it once, then use its API key as your standing alias for the root/admin key.

## Does `setup-wittenberg.sh` download templates?

**Yes, with `--templates`.** That flag:

1. **Installs** Packer template definitions from Ludus Sources (`source add` — pulls ubuntu-22.04 from BSL if missing).
2. **Builds** the three images via Packer (`templates build`) — Packer downloads ISOs and creates the templates. This is the long step; watch with `ludus templates logs -f`.

`--install` only installs Ludus. `--users` only creates ATHANASIUS. Neither of those builds templates by itself.

## Templates Geneva needs

| Template | Used for |
| --- | --- |
| `win2022-server-x64-template` | GOAD + winattack |
| `ubuntu-22.04-x64-server-template` | redirs, C2, teamshare, ansible (BSL source) |
| `kali-x64-desktop-template` | linattack1 |

Only these three — do not build the whole catalog unless you want to.

## Option A — helper script

```bash
cd /opt/ranges
chmod +x setup-wittenberg.sh

# 1) Install Ludus (node name: wittenberg)
sudo ./setup-wittenberg.sh --install
# reboot if asked
sudo ludus-install-status
 export LUDUS_API_KEY='…'   # install/root key for first bootstrap

# 2) Create ATHANASIUS (if install did not already), THEN switch keys
./setup-wittenberg.sh --users
 export LUDUS_API_KEY='…'   # ATHANASIUS key from user add (NOT ROOT, NOT sudo)

# 3) Install Packer defs into ATHANASIUS catalog + build
./setup-wittenberg.sh --templates
ludus templates logs -f
```

**Do not** `sudo ./setup-wittenberg.sh --templates` — sudo drops `LUDUS_API_KEY` and the script cannot talk to Ludus. Templates are also **per-user**; install them with the ATHANASIUS key so that user owns the catalog.


## Option B — manual

### 1. Install Ludus

```bash
su -
apt update && apt install -y curl sudo ca-certificates jq
curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
# node name: wittenberg
ludus-install-status
 export LUDUS_API_KEY='…'
```

### 2. Templates (install defs into your catalog, then Packer build)

`templates list` stays empty until you **source add** each template for the user behind `LUDUS_API_KEY`. Build alone does not populate the list.

```bash
# Confirm key + sources
echo "key set: ${LUDUS_API_KEY:+yes}"
ludus source list
ludus source list ludus-source-bsl --catalog | head

# Install defs (all three — not just ubuntu)
ludus source add ludus-source-bsl --templates win2022-server-x64-template
ludus source add ludus-source-bsl --templates ubuntu-22.04-x64-server-template
ludus source add ludus-source-bsl --templates kali-x64-desktop-template

ludus templates list   # should show three rows (BUILT=false until Packer finishes)

ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
# Stuck DHCP?  ludus templates abort ; restart dnsmasq; rebuild the stuck one
```

### 3. Create ATHANASIUS (root API alias)

```bash
ludus user add -n 'Athanasius' -i ATHANASIUS
# Save the API key — use it from now on instead of the install root key
 export LUDUS_API_KEY='…'
```

### 4. Deploy Geneva range

```bash
ludus --user ATHANASIUS range config set -f /opt/ranges/geneva/range.yml
ludus --user ATHANASIUS range deploy
ludus --user ATHANASIUS range logs -f
```

### 5. Stamp inventories + optional Ansible

```bash
cd /opt/ranges/geneva
RANGENUMBER=$(ludus --user ATHANASIUS range list --json | jq -r '.rangeNumber // .[0].rangeNumber')
export RANGENUMBER
./stamp-range-number.sh
ansible-playbook deploy-range.yml --limit linattack   # optional
```

## Verify

```bash
ludus templates list              # three BUILT
ludus user list                   # ATHANASIUS
ludus --user ATHANASIUS range list
free -h
```

## Creds (lab defaults)

| System | User | Pass |
| --- | --- | --- |
| Kali | kali | kali |
| Ubuntu | localuser | password |
| GOAD domainadmin | domainadmin | password |

Defender AV is on for GOAD Windows. Cloud MDE still needs your tenant onboarding package if you want the cloud console.
