#!/usr/bin/env bash
# Pack GENEVA range + Wittenberg setup helpers into a tarball.
set -euo pipefail
cd "$(dirname "$0")"
stamp="$(date +%Y%m%d)"
out="wittenberg-geneva-${stamp}.tar.gz"

tar -czf "$out" \
  --exclude='geneva/inventory.yml.bak' \
  --exclude='*/__pycache__' \
  --exclude='*.retry' \
  --exclude='wittenberg-geneva-*.tar.gz' \
  --exclude='reformation-ranges-*.tar.gz' \
  README.md SETUP.md \
  setup-wittenberg.sh install-all-templates.sh pack-ranges.sh \
  geneva

echo "Wrote $(pwd)/$out"
ls -lh "$out"
echo
echo "Copy off Ludus, e.g.:"
echo "  scp $(pwd)/$out you@laptop:~/"
