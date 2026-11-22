# Wittenberg Ludus + Geneva range

| Name | What |
| --- | --- |
| **wittenberg** | Debian Ludus host |
| **geneva/** | Range pack — GOAD + red infra, Defender ON |
| **ATHANASIUS** | Optional second admin / range owner |

**Read [`SETUP.md`](SETUP.md) first.** Template installs are per API-key user. Use the **initial admin** key from `ludus-install-status`, not ROOT, and do not `sudo` template commands.

```bash
 export LUDUS_API_KEY='ADMINID.…'   # from ludus-install-status
ludus source add ludus-source-bsl --templates win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates list
ludus templates build -n win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template
ludus templates logs -f
```
