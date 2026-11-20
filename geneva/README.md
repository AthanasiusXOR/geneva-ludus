# Geneva — red-team Ollama range

Ludus host: **reformation** · User: **GENEVA** · Sibling: [`../wittenberg/`](../wittenberg/)

## After Ludus range deploy finishes

```bash
cd /opt/ranges/geneva   # or your checkout

 export LUDUS_API_KEY='GENEVA.…'   # or use ludus --user GENEVA …
./stamp-range-number.sh

ansible-galaxy collection install -r requirements.yml
ansible-playbook deploy-range.yml
# pulls model + creates rt-assist — can take a long time on CPU
```

Smoke test (from WireGuard / lab):

```bash
curl http://10.<GENEVA_RANGE#>.10.10:11434/api/tags
```

## Then cut it off from the internet

**1. Guest iptables lockdown** (blocks outbound from the VM):

```bash
ansible-playbook deploy-lockdown.yml
```

**2. Ludus router lockdown** (block_internet + reject external):

```bash
ludus --user GENEVA range config set -f range.lockdown.yml
ludus --user GENEVA range deploy
ludus --user GENEVA range logs -f
```

**3. Verify**

```bash
# On the ollama VM (console/SSH) — should FAIL:
curl -m 5 -I https://1.1.1.1

# From your WG client — should WORK:
curl http://10.<GENEVA_RANGE#>.10.10:11434/api/tags
```

WireGuard into Geneva still reaches `:11434`. Public internet from that VM should not.

Creds: Debian template `debian` / `debian`.  
Update `wittenberg/group_vars/all.yml` → `geneva_ollama_url` once you know the Geneva range number.
