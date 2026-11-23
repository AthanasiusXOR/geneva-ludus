# Geneva range

Ludus host: **wittenberg**  
Ludus **userid:** `AD` (API key `AD.…`)  
Shell alias: `administrator` (exports that key)

Config: **`range.yml`** — GOAD + Kali/C2/redirs. GOAD VMs: `AD-DC01`, etc.

```bash
administrator
ludus range config set -f range.yml
ludus range deploy
```
