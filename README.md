# Ludus helpers (Geneva)

Two pieces for Charles’s Ludus host:

1. **`install-all-templates.sh`** — Ludus 2.2 Sources flow (`source add --all` → `templates build`)
2. **`implant-testing-range/`** — slim implant/EDR test range + Ansible + uncensored Ollama, sized for ~60 GB RAM

## Implant testing range (start here for the lab)

```bash
cd implant-testing-range
# read README.md for templates, deploy, power-on subset, and ansible
```

Slim profile keeps NONE + EDR cells (4 GB each), attack1 only, and `ollama-rt` (12 GB). Power **one target cell** at a time with the attack stack (~40 GB).

## Templates helper

```bash
 export LUDUS_API_KEY='YOUR-KEY'
./install-all-templates.sh --install-only   # or full build
```

See comments in the script and the older docs in git history if you only need Sources/`--all` reminders.
