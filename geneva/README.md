# Geneva — red-team Ollama range

Ludus host: **reformation**  
Ludus user / range: **GENEVA**  
Implant lab: [`../wittenberg/`](../wittenberg/)

Keep this directory in git / on your laptop. `/opt/ranges/geneva` on reformation is only a working copy.

## Deploy

```bash
ludus users add -n 'Geneva' -i GENEVA   # once; save password + API key

ludus --user GENEVA range config set -f range.yml
ludus --user GENEVA range deploy
ludus --user GENEVA range logs -f
```

Template required: `debian-13-x64-server-template`.

## Ansible post-config

```bash
./stamp-range-number.sh
ansible-galaxy collection install -r requirements.yml
ansible-playbook deploy-range.yml
```

API: `http://10.<GENEVA_RANGE#>.10.10:11434` — model `rt-assist`  
Creds on the VM: Ludus Debian default `debian` / `debian` (or `localuser` / `password` if your image uses that — check with `ludus` docs / console).

Update `wittenberg/group_vars/all.yml` → `geneva_ollama_url` after you know the Geneva range number.
