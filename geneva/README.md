# Geneva — red-team Ollama range

Ludus host: **reformation**  
Ludus user / range: **GENEVA**  
Implant lab is the sibling range: [`../wittenberg/`](../wittenberg/)

Single Debian 13 VM with uncensored Ollama (`rt-assist`), sized for CPU inference on a shared ~60 GB host.

## Create the Ludus user (once, as admin on reformation)

```bash
ludus user add -n 'Geneva' -i GENEVA
# Save the printed API key
```

## Template required

```bash
ludus templates build -n debian-13-x64-server-template
ludus templates logs -f
```

## Deploy

```bash
cd geneva
 export LUDUS_API_KEY='GENEVA.…'
ludus range config set -f range.yml
ludus range deploy
ludus range logs -f
```

Admin shortcut:

```bash
ludus --user GENEVA range config set -f range.yml
ludus --user GENEVA range deploy
ludus --user GENEVA range logs -f
```

## Ansible post-config (install Ollama + model)

From a host that can reach the Geneva WireGuard / range network:

```bash
export LUDUS_API_KEY='GENEVA.…'
./stamp-range-number.sh
ansible-galaxy collection install -r requirements.yml
ansible-playbook deploy-range.yml
```

Smoke test:

```bash
curl http://10.<GENEVA_RANGE#>.10.10:11434/api/tags
curl http://10.<GENEVA_RANGE#>.10.10:11434/api/generate -d '{
  "model": "rt-assist",
  "prompt": "Summarize a lab Kerberoasting workflow.",
  "stream": false
}'
```

## Reach Geneva from Wittenberg

Ludus ranges are per-user and isolated. From Wittenberg operators:

1. Connect to the **GENEVA** WireGuard config (`ludus --user GENEVA user wireguard`), or
2. Point tools at `http://10.<GENEVA_RANGE#>.10.10:11434` once on that network

Then set in `wittenberg/group_vars/all.yml`:

```yaml
geneva_ollama_url: "http://10.<GENEVA_RANGE#>.10.10:11434"
```

## Resources

| VM | RAM | vCPU | IP |
| --- | --- | --- | --- |
| ollama | 16 GB | 8 | `10.<n>.10.10` |

Leave Wittenberg on a single target cell if both ranges are powered (~28 + 16 ≈ 44 GB).
