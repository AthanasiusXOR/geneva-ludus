# Geneva range (Wittenberg)

Commands match Ludus docs:

| Flag | Docs | What the script runs |
| --- | --- | --- |
| `--install` | [Proxmox](https://docs.ludus.cloud/docs/deployment-options/proxmox) | `curl -s https://ludus.cloud/install \| bash` |
| `--users` | [Create a User](https://docs.ludus.cloud/docs/quick-start/create-a-user/) | `ludus user list` + optional `ludus user add --name … --userid … --email …` |
| `--templates` | [Build Templates](https://docs.ludus.cloud/docs/quick-start/build-templates/) + [Sources](https://docs.ludus.cloud/docs/using-ludus/sources) | `source add --templates …` then `templates build -n …` |
| `--deploy` | [Deploy a range](https://docs.ludus.cloud/docs/category/quick-start/) | `range config set` + `range deploy` |

Range owner = prefix of `LUDUS_API_KEY` (not hardcoded).

```bash
./setup-wittenberg.sh --install
# ludus-install-status → export initial admin key
export LUDUS_API_KEY='YOURUSER.…'
./setup-wittenberg.sh --users          # optional extra user
./setup-wittenberg.sh --templates
ludus templates logs -f
./setup-wittenberg.sh --deploy
ludus range logs -f
```
