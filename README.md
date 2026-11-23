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

# 3) Add ubuntu-22.04 if missing + build ALL catalog templates
./setup-wittenberg.sh --templates
ludus templates logs -f
ludus templates list                 # all BUILT before deploy

# 4) Deploy Geneva
./setup-wittenberg.sh --deploy
ludus range logs -f
```

`range.yml` needs: `win2022-server-x64-template`, `ubuntu-22.04-x64-server-template`, `kali-x64-desktop-template` (plus any other standards `--templates` builds).

Docs: [Proxmox install](https://docs.ludus.cloud/docs/deployment-options/proxmox) · [Build templates](https://docs.ludus.cloud/docs/quick-start/build-templates/)
