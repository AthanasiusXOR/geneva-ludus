# Reformation Ludus ranges

**Source of truth for Wittenberg + Geneva.** Keep this repo on your laptop (or any non-Ludus machine). Copy/sync onto reformation when you deploy — don’t treat `/opt/ranges` as the only copy.

| Path | Ludus user | Purpose |
| --- | --- | --- |
| [`SETUP.md`](SETUP.md) / [`setup-reformation.sh`](setup-reformation.sh) | — | Install Ludus + required templates |
| [`wittenberg/`](wittenberg/) | `WITTENBERG` | Red infra + **GOAD** (`range-goad.yml`) — Defender ON |
| [`wittenberg/GOAD-DEFENDER.md`](wittenberg/GOAD-DEFENDER.md) | — | **Start here** for GOAD + Defender |
| [`geneva/`](geneva/) | `GENEVA` | Ollama (optional / park it) |
| [`pack-ranges.sh`](pack-ranges.sh) | — | Make a tarball to copy off-box |

## Get a clean copy (not only on Ludus)

```bash
# From this git remote / Cursor project — clone or pull on your laptop:
git clone <your-remote-url> reformation-ranges
cd reformation-ranges

# Or pack from a machine that has the repo:
./pack-ranges.sh
# → reformation-ranges-YYYYMMDD.tar.gz
```

Sync onto reformation:

```bash
rsync -av --delete ./wittenberg/ ./geneva/ ./SETUP.md ./setup-reformation.sh \
  root@reformation:/opt/ranges/
# then on reformation, inventories still need ./stamp-range-number.sh
```

## Deploy (after templates are BUILT)

```bash
ludus --user WITTENBERG range config set -f wittenberg/range.yml
ludus --user WITTENBERG range deploy

ludus --user GENEVA range config set -f geneva/range.yml
ludus --user GENEVA range deploy
```

Then Ansible post-config inside each folder (see each README). Wittenberg: one target cell + attack stack while Geneva’s 16 GB Ollama is up.
