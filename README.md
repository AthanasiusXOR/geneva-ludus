# Wittenberg Ludus + Geneva range

| | |
| --- | --- |
| **wittenberg** | Debian Ludus host |
| **AD** | Ludus userid / API key `AD.…` |
| **administrator** | bashrc alias that exports that key |
| **geneva/** | GOAD + red infra in `range.yml` |

```bash
su -
administrator
./setup-wittenberg.sh --templates
ludus templates logs -f
./setup-wittenberg.sh --deploy
ludus range logs -f
```

See [`SETUP.md`](SETUP.md).
