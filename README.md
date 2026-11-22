# Wittenberg Ludus + Geneva range

| Name | What |
| --- | --- |
| **wittenberg** | Debian Ludus host |
| **admin** | Ludus user / `LUDUS_API_KEY=admin.…` |
| **geneva/** | GOAD + red infra, Defender ON |

```bash
su -
export LUDUS_API_KEY='admin.…'
./setup-wittenberg.sh --templates
ludus templates logs -f
```

See [`SETUP.md`](SETUP.md).
