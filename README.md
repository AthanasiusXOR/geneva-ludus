# Wittenberg Ludus + Geneva range

| Name | What |
| --- | --- |
| **wittenberg** | Debian Ludus host |
| **admin** | Ludus user; bashrc alias `admin` exports `LUDUS_API_KEY` |
| **geneva/** | GOAD + red infra, Defender ON |

```bash
su -
admin
./setup-wittenberg.sh --templates
ludus templates logs -f
```

See [`SETUP.md`](SETUP.md).
