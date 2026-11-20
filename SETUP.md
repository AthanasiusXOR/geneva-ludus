# Setup Ludus on Reformation

You must run this **on the reformation host** (SSH as root). This environment cannot install Ludus for you remotely.

Ludus takes over the machine (Proxmox). Use a dedicated Debian 12/13 box with nested virtualization if it is a VM, plenty of disk, and your ~60 GB RAM.

## Templates these ranges need

| Template | Used by |
| --- | --- |
| `debian-13-x64-server-template` | Geneva (Ollama) |
| `win2022-server-x64-template` | Wittenberg |
| `win11-22h2-x64-enterprise-template` | Wittenberg |
| `ubuntu-22.04-x64-server-template` | Wittenberg (from BSL source) |
| `kali-x64-desktop-template` | Wittenberg |

Do **not** build all 27 templates — only these five.

## Option A — helper script (recommended)

Copy this repo onto reformation, then:

```bash
cd /path/to/this/repo
chmod +x setup-reformation.sh

# 1) Install Ludus (interactive; set node name to reformation)
sudo ./setup-reformation.sh --install

# After reboot / when ludus-install-status says ready:
sudo ludus-install-status
# Copy the admin API key, then:
 export LUDUS_API_KEY='ADMIN-OR-ROOT-KEY'

# 2) Install ubuntu from BSL source + build the five templates
./setup-reformation.sh --templates
# optional: ./setup-reformation.sh --templates --parallel 2
ludus templates logs -f

# 3) Create range users
./setup-reformation.sh --users
```

Or one shot after Ludus is already installed and `LUDUS_API_KEY` is set:

```bash
./setup-reformation.sh --templates --users
```

## Option B — manual commands

### 1. Install Ludus

```bash
su -
apt update && apt install -y curl sudo ca-certificates jq
curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
# Accept EULA; set node name to reformation; fix public IP if prompted
# Reboot if asked, then:
ludus-install-status
 export LUDUS_API_KEY='…'
```

### 2. Pull ubuntu template from Sources + build five

```bash
# BSL source is usually pre-registered; install ubuntu into your catalog
ludus source add ludus-source-bsl --templates ubuntu-22.04-x64-server-template
# if that source id differs:
# ludus source list
# ludus source add https://github.com/badsectorlabs/ludus-source-bsl --templates ubuntu-22.04-x64-server-template

ludus templates list

ludus templates build -n debian-13-x64-server-template,win2022-server-x64-template,win11-22h2-x64-enterprise-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template

ludus templates logs -f
# Stuck?  ludus templates abort
```

### 3. Create Wittenberg + Geneva users

```bash
ludus user add -n 'Wittenberg' -i WITTENBERG
ludus user add -n 'Geneva' -i GENEVA
# Save both API keys
```

### 4. Deploy ranges (after all five templates show BUILT)

```bash
ludus --user WITTENBERG range config set -f wittenberg/range.yml
ludus --user WITTENBERG range deploy
ludus --user WITTENBERG range logs -f

ludus --user GENEVA range config set -f geneva/range.yml
ludus --user GENEVA range deploy
ludus --user GENEVA range logs -f
```

Then Ansible post-config in each folder (`./stamp-range-number.sh` → `ansible-playbook deploy-range.yml`). See `wittenberg/README.md` and `geneva/README.md`.

## Verify

```bash
ludus templates list
# All five should show BUILT / TRUE

ludus user list
# WITTENBERG and GENEVA present

free -h   # leave headroom: Wittenberg one cell ~28G + Geneva ~16G
```

## Docs

- [Install / Quick Start](https://docs.ludus.cloud/docs/category/quick-start/)
- [Build templates](https://docs.ludus.cloud/docs/quick-start/build-templates/)
- [Sources (2.2)](https://docs.ludus.cloud/docs/using-ludus/sources)
