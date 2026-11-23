# Wittenberg Ludus + Geneva range

Everything for Wittenberg lives here — including **GOAD AD** and **red infra** in `geneva/range.yml`.

| Name | What |
| --- | --- |
| **wittenberg** | Debian Ludus host |
| **administrator** | Ludus user; bashrc alias `administrator` → `LUDUS_API_KEY` |
| **geneva/** | GOAD + Kali/C2/redirs + VLAN rules |

```bash
su -
administrator
./setup-wittenberg.sh --templates
ludus templates logs -f
./setup-wittenberg.sh --deploy
ludus range logs -f
```

Copy to the Ludus box:

```bash
./pack-ranges.sh
# or: rsync -av ./ root@wittenberg:/opt/ranges/
```

See [`SETUP.md`](SETUP.md).
