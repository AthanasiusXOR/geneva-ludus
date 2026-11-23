# Geneva range — Wittenberg (Ludus)

Fresh Debian → Ludus → templates → deploy GOAD + red infra.

| File | Purpose |
| --- | --- |
| `setup-wittenberg.sh` | `--install` / `--users` / `--templates` / `--deploy` |
| `range.yml` | GOAD + Kali/C2/redirs + VLAN rules (`{{ range_id }}`) |
| `inventory.yml` | Ansible (`RANGE_ID` / `RANGE_NUMBER` stamped on deploy) |

## From scratch

```bash
su -
cd /opt/ranges          # this directory on the box
chmod +x setup-wittenberg.sh

# 1) Ludus (node name: wittenberg when prompted)
./setup-wittenberg.sh --install
# reboot if asked, then:
ludus-install-status
export LUDUS_API_KEY='YOURUSER.…'    # initial admin key (not ROOT)

# 2) Optional extra user
./setup-wittenberg.sh --users

# 3) Ensure ubuntu + numbered list (Enter = build all standards; or pick 1 2 3…)
./setup-wittenberg.sh --templates
ludus templates logs -f
ludus templates list                 # needed ones BUILT before deploy

# 4) Deploy Geneva (installs GOAD roles for your API-key user, then config + deploy)
./setup-wittenberg.sh --deploy
ludus range logs -f
```

`--deploy` installs (per Ludus user):

```bash
ludus ansible collection add badsectorlabs.ludus_windows_utils
ludus ansible role add badsectorlabs.ludus_adcs
ludus ansible role add badsectorlabs.ludus_mssql
```

`range.yml` needs: `win2022-server-x64-template`, `ubuntu-22.04-x64-server-template`, `kali-x64-desktop-template` (plus any other standards `--templates` builds).

Docs: [Proxmox install](https://docs.ludus.cloud/docs/deployment-options/proxmox) · [Roles](https://docs.ludus.cloud/docs/using-ludus/roles/) · [Build templates](https://docs.ludus.cloud/docs/quick-start/build-templates/)
