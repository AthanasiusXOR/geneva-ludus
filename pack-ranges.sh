#!/usr/bin/env bash
# Pack Wittenberg + Geneva (+ setup helpers) into a tarball for an off-Ludus copy.
set -euo pipefail
cd "$(dirname "$0")"
stamp="$(date +%Y%m%d)"
out="reformation-ranges-${stamp}.tar.gz"

tar -czf "$out" \
  --exclude='wittenberg/inventory.yml.bak' \
  --exclude='*/__pycache__' \
  --exclude='*.retry' \
  --exclude='reformation-ranges-*.tar.gz' \
  README.md SETUP.md \
  setup-reformation.sh install-all-templates.sh pack-ranges.sh \
  wittenberg geneva

echo "Wrote $(pwd)/$out"
ls -lh "$out"
echo
echo "Copy off Ludus, e.g.:"
echo "  scp $(pwd)/$out you@laptop:~/"
