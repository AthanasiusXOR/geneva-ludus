# Reformation Ludus ranges

Ludus host: **reformation**

| Directory | Ludus user | Purpose |
| --- | --- | --- |
| [`wittenberg/`](wittenberg/) | `WITTENBERG` | Implant / EDR test range (slim) |
| [`geneva/`](geneva/) | `GENEVA` | Red-team Ollama (`rt-assist`) |
| `install-all-templates.sh` | — | Ludus 2.2 Sources helper |

Each Ludus **user owns one range**. Create both users once as admin, then deploy each folder’s `range.yml`.

```bash
ludus user add -n 'Wittenberg' -i WITTENBERG
ludus user add -n 'Geneva' -i GENEVA

# Wittenberg
ludus --user WITTENBERG range config set -f wittenberg/range.yml
ludus --user WITTENBERG range deploy

# Geneva
ludus --user GENEVA range config set -f geneva/range.yml
ludus --user GENEVA range deploy
```

On ~60 GB RAM: keep Wittenberg on **one target cell** while Geneva’s 16 GB Ollama box is up. Full steps are in each directory’s README.
