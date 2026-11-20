#!/usr/bin/env bash
# Pack Wittenberg + Geneva (+ setup helpers) into a tarball for an off-Ludus copy.
set -euo pipefail
cd "$(dirname "$0")"
stamp="$(date +%Y%m%d)"
out="reformation-ranges-${stamp}.tar.gz"

tar -czf "$out" \
  README.md SETUP.md \
  setup-reformation.sh install-all-templates.sh pack-ranges.sh \
  wittenberg geneva \
  --exclude='wittenberg/inventory.yml.bak' \
  --exclude='*/__pycache__' \
  --exclude='*.retry'

echo "Wrote $out"
echo "Copy somewhere safe (laptop, git remote), then:"
echo "  scp $out you@laptop:~/"
echo "  # or: git push  (preferred)"
ls -lh "$out"
