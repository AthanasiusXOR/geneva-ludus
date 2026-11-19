# Ludus: install all templates (2.2 Sources)

Ludus **2.2** replaced the old “clone repo + `ludus templates add -d …`” flow with **Sources**. Templates live in a source catalog; you **install** them from the source, then **build** Packer images separately.

## TL;DR — install everything from Bad Sector Labs

On your Ludus client (API key set):

```bash
# Keep the leading space so most shells skip history
 export LUDUS_API_KEY='YOUR-KEY'

# Skip the picker; install every blueprint, template, role, and collection
ludus source add https://github.com/badsectorlabs/ludus-source-bsl --all

# Or, if the default BSL source is already registered:
ludus source add ludus-source-bsl --all

# Build every installed template (hours; lots of disk)
ludus templates build
ludus templates logs -f
```

Or run the helper in this repo:

```bash
chmod +x ./install-all-templates.sh
./install-all-templates.sh                  # BSL --all, then build
./install-all-templates.sh --parallel 2     # concurrent builds if hardware allows
./install-all-templates.sh --community      # also pull ludus-source-community
./install-all-templates.sh --install-only   # register only; build later
```

## What changed

| Old (pre-2.2) | New (2.2 Sources) |
| --- | --- |
| `git clone …/ludus` / template repos | `ludus source add <url\|sourceID>` |
| `ludus templates add -d path/to/template` | `ludus source add … --templates name` or `--all` |
| `ludus templates build` | Unchanged — still builds installed templates |

Fresh hosts auto-register the Bad Sector Labs source. **Registering ≠ installing.** Open the picker (or use `--all`) to put templates on your user, then build.

## Useful commands

```bash
ludus source list
ludus source list ludus-source-bsl --catalog

# Install only specific templates (comma-separated)
ludus source add ludus-source-bsl --templates win2019-server-x64-template,debian-11-x64-server-template

# Analyst VMs also need their companion roles
ludus source add https://github.com/badsectorlabs/ludus-source-bsl \
  --templates commando-vm-template,flare-vm-template,remnux-template \
  --source-roles ludus_commandovm,ludus_flarevm,ludus_remnux

ludus templates list
ludus templates build -n debian-13-x64-server-template
ludus templates build --parallel 2
ludus templates logs -f
ludus templates status
```

Web UI: **Sources** → pick the source → check templates → **Install**, then **Templates** to build.

## Built-in vs source templates

A fresh install already lists a small default set (e.g. debian-12/13, kali, win11-22h2, win2022). Those only need `ludus templates build`. Everything else (older Windows, Ubuntu/Rocky variants, Commando/FLARE/REMnux, no-Defender Win11, etc.) comes from **ludus-source-bsl** after `source add … --all` (or a selective `--templates` list).

BSL ships ~21 Packer templates. Full names: [templates/README.md](https://github.com/badsectorlabs/ludus-source-bsl/blob/main/templates/README.md).

## Notes

- **Disk / time:** building *all* images is large and slow. Prefer `--templates` for what you actually need, or build in batches.
- **`--parallel`:** faster on strong hosts; parallel builds often suppress per-template logs.
- **Community content:** `ludus source add https://github.com/badsectorlabs/ludus-source-community --all`
- Docs: [Sources](https://docs.ludus.cloud/docs/using-ludus/sources), [Build templates](https://docs.ludus.cloud/docs/quick-start/build-templates/), [2.2.0 changelog](https://ludus.cloud/changelog/2.2.0)

This repo is a helper you run against an existing Ludus host. It does not install Ludus itself.
