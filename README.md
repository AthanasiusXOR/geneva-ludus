# Wittenberg Ludus + Geneva range

| Name | What |
| --- | --- |
| **wittenberg** | Debian Ludus host |
| **admin** | Ludus user; bashrc alias `admin` exports `LUDUS_API_KEY` |
| **geneva/** | GOAD + Kali/C2/redirs, Defender ON, VLAN rules for C2 path |

```bash
su -
admin
./setup-wittenberg.sh --templates    # wait until BUILT
./setup-wittenberg.sh --deploy       # GOAD + attack infra
ludus range logs -f
```

Details: [`SETUP.md`](SETUP.md).
