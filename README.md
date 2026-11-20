# Reformation Ludus ranges

Ludus host: **reformation**

| Path | Ludus user | Purpose |
| --- | --- | --- |
| [`SETUP.md`](SETUP.md) / [`setup-reformation.sh`](setup-reformation.sh) | — | **Install Ludus + the 5 templates these ranges need** |
| [`wittenberg/`](wittenberg/) | `WITTENBERG` | Implant / EDR test range (slim) |
| [`geneva/`](geneva/) | `GENEVA` | Red-team Ollama (`rt-assist`) |
| `install-all-templates.sh` | — | Optional: install/build *all* BSL templates (heavy) |

## First time on reformation

SSH in as root, copy this repo over, then follow **[SETUP.md](SETUP.md)**. Short version:

```bash
chmod +x setup-reformation.sh
sudo ./setup-reformation.sh --install          # interactive Ludus installer
# after install + reboot:
 export LUDUS_API_KEY='…'                      # from ludus-install-status
./setup-reformation.sh --templates --users
ludus templates logs -f                        # wait until the five are BUILT
```

## Deploy ranges

```bash
ludus --user WITTENBERG range config set -f wittenberg/range.yml
ludus --user WITTENBERG range deploy

ludus --user GENEVA range config set -f geneva/range.yml
ludus --user GENEVA range deploy
```

On ~60 GB RAM: keep Wittenberg on **one target cell** while Geneva’s 16 GB Ollama box is up. Details in each directory’s README.
