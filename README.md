# Geneva range (Wittenberg)

No hardcoded Ludus userid. Whoever’s key you export owns the range.

Install Ludus per [Proxmox deployment docs](https://docs.ludus.cloud/docs/deployment-options/proxmox):

```bash
./setup-wittenberg.sh --install
# → curl -s https://ludus.cloud/install | bash
```

Then Quick Start (create user) → templates → deploy:

```bash
export LUDUS_API_KEY='YOURUSER.…'
./setup-wittenberg.sh --templates
ludus templates logs -f
./setup-wittenberg.sh --deploy
ludus range logs -f
```

`range.yml` uses `{{ range_id }}` → VMs are `<USERID>-DC01`, etc.

`--templates` / `--users` / `--deploy` need the key. `--install` does not.
