# Wittenberg — manual Ludus commands (user AD already exists)

Shell alias `administrator` exports `LUDUS_API_KEY='AD.…'`.  
Range pack: `/opt/ranges/geneva/` (this repo’s `geneva/`).

---

## 0) Key + sync

```bash
su -
administrator
echo "${LUDUS_API_KEY%%.*}"    # must print: AD
cd /opt/ranges/geneva
```

---

## 1) Install template defs into AD’s catalog

```bash
ludus source list
ludus source add ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
```

If that fails:

```bash
ludus source add https://github.com/badsectorlabs/ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
```

Check:

```bash
ludus templates list
```

You must see `win2022-server-x64-template`, `ubuntu-22.04-x64-server-template`, `kali-x64-desktop-template`.

---

## 2) Build Packer images

```bash
ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
```

Ctrl-C to stop following logs (build keeps running). Recheck:

```bash
ludus templates list
```

All three must show **BUILT** / **TRUE** before deploy.

Stuck DHCP?

```bash
ludus templates abort
systemctl restart dnsmasq
ludus templates build -n <the-stuck-template-name>
ludus templates logs -f
```

---

## 3) Deploy Geneva (GOAD + red infra)

```bash
cd /opt/ranges
ludus range config set -f geneva/range.yml
ludus range deploy
ludus range logs -f
```

Status:

```bash
ludus range list
ludus range status
```

---

## 4) Optional — stamp inventories + Kali notes

```bash
cd /opt/ranges/geneva
RANGENUMBER=$(ludus range list --json | jq -r '.rangeNumber // .[0].rangeNumber')
export RANGENUMBER
./stamp-range-number.sh
# optional:
ansible-playbook deploy-range.yml --limit linattack
```

---

## What `geneva/range.yml` builds

| VLAN | VMs |
| --- | --- |
| 10 | GOAD: AD-DC01…AD-SRV03 (Defender ON) |
| 20 | redir-e1-0, redir-w1-0 |
| 30 | linattack1 (Kali), winattack1, c2server0, c2server1, teamshare |
| 40 | ansible |

VLAN rules: attack↔redirs, attack→GOAD, GOAD→redirs, ansible→10/20/30.  
C2 **software** you install yourself on the C2 VMs.
