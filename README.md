# Geneva range (Wittenberg)

No hardcoded Ludus userid. Whoever’s key you export owns the range.

`range.yml` uses `{{ range_id }}` → VMs are `<USERID>-DC01`, etc.

```bash
export LUDUS_API_KEY='CH.…'    # or AD.… / any user you created
./setup-wittenberg.sh --templates
ludus templates logs -f
./setup-wittenberg.sh --deploy
ludus range logs -f
```

`--templates` / `--users` / `--deploy` need the key. `--install` does not.
