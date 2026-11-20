# Setup Ludus on Wittenberg

Run these steps **on the Wittenberg host** (SSH as root). Fresh Debian 12/13 box with nested virt if it is a VM, large disk, ~60 GB+ RAM.

## Templates GENEVA needs

| Template | Used for |
| --- | --- |
| `win2022-server-x64-template` | GOAD + winattack |
| `ubuntu-22.04-x64-server-template` | redirs, C2, teamshare, ansible (BSL source) |
| `kali-x64-desktop-template` | linattack1 |

Do **not** build every Packer template — only these three.

## Option A — helper script

```bash
cd /opt/ranges   # or wherever you synced this repo
chmod +x setup-wittenberg.sh

# 1) Install Ludus (interactive; set node name to wittenberg)
sudo ./setup-wittenberg.sh --install

# After reboot / when ready:
sudo ludus-install-status
# Copy the admin API key, then:
 export LUDUS_API_KEY='ADMIN-OR-ROOT-KEY'

# 2) Ubuntu from BSL + build the three templates
./setup-wittenberg.sh --templates
ludus templates logs -f

# 3) Create GENEVA user
./setup-wittenberg.sh --users
```

One shot after Ludus is installed and `LUDUS_API_KEY` is set:

```bash
./setup-wittenberg.sh --templates --users
```

## Option B — manual commands

### 1. Install Ludus

```bash
su -
apt update && apt install -y curl sudo ca-certificates jq
curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
# Accept EULA; set node name to wittenberg; fix public IP if prompted
# Reboot if asked, then:
ludus-install-status
 export LUDUS_API_KEY='…'
```

### 2. Templates

```bash
ludus source add ludus-source-bsl --templates ubuntu-22.04-x64-server-template
# if source id differs: ludus source list

ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
# Stuck DHCP?  ludus templates abort
# then: systemctl restart dnsmasq   (or the Ludus dnsmasq unit) and rebuild the stuck one
```

### 3. Create GENEVA user

```bash
ludus user add -n 'Geneva' -i GENEVA
# Save the API key
```

### 4. Deploy GENEVA (after templates show BUILT)

```bash
ludus --user GENEVA range config set -f /opt/ranges/geneva/range.yml
# or: -f geneva/range.yml from a checkout
ludus --user GENEVA range deploy
ludus --user GENEVA range logs -f
```

### 5. Stamp inventories + optional Ansible

```bash
cd /opt/ranges/geneva
RANGENUMBER=$(ludus --user GENEVA range list --json | jq -r '.rangeNumber // .[0].rangeNumber')
export RANGENUMBER
./stamp-range-number.sh

# optional Kali notes / SSH key:
ansible-playbook deploy-range.yml --limit linattack
```

## Verify

```bash
ludus templates list   # three templates BUILT
ludus user list        # GENEVA present
ludus --user GENEVA range list
free -h
```

## Creds (lab defaults)

| System | User | Pass |
| --- | --- | --- |
| Kali | kali | kali |
| Ubuntu | localuser | password |
| GOAD domainadmin | domainadmin | password |

Microsoft Defender Antivirus is **on** for GOAD Windows VMs. Cloud MDE console needs your tenant onboarding package separately.

## Docs

- [Install / Quick Start](https://docs.ludus.cloud/docs/category/quick-start/)
- [Build templates](https://docs.ludus.cloud/docs/quick-start/build-templates/)
- [Sources (2.2)](https://docs.ludus.cloud/docs/using-ludus/sources)
