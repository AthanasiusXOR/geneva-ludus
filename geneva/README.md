# Geneva range

Ludus host: **wittenberg**  
Ludus user: **admin** (`LUDUS_API_KEY=admin.…`)

GOAD VMs: `admin-DC01` … · Attack stack on VLANs 20/30/40 · Defender ON

```bash
export LUDUS_API_KEY='admin.…'
ludus range config set -f range.yml
ludus range deploy
```
