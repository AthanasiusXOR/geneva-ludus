# Geneva range (Wittenberg)

Ludus **userid / deploy user:** `AD` (whatever prefix is on `LUDUS_API_KEY`)  
Shell alias can be anything — the **key prefix** is the range owner.

| File | Purpose |
| --- | --- |
| `range.yml` | GOAD + red infra + VLAN rules |
| `inventory.yml` | Ansible (set `RANGE_NUMBER` after deploy) |
| `setup-wittenberg.sh` | `--templates` / `--users` / `--deploy` |

```bash
export LUDUS_API_KEY='AD.…'    # this user owns the range
./setup-wittenberg.sh --templates
ludus templates logs -f
./setup-wittenberg.sh --deploy
ludus range logs -f
```

`--templates`, `--users`, and `--deploy` need the key. `--install` does not.
