#!/usr/bin/env bash
# Pack everything needed on Wittenberg (setup + Geneva GOAD/red-infra).
set -euo pipefail
cd "$(dirname "$0")"
stamp="$(date +%Y%m%d)"
out="wittenberg-geneva-${stamp}.tar.gz"

tar -czf "$out" \
  --exclude='geneva/inventory.yml.bak' \
  --exclude='*/__pycache__' \
  --exclude='*.retry' \
  --exclude='wittenberg-geneva-*.tar.gz' \
  README.md SETUP.md \
  setup-wittenberg.sh install-all-templates.sh pack-ranges.sh \
  geneva

echo "Wrote $(pwd)/$out"
ls -lh "$out"
echo "Copy to Ludus:  scp $out root@wittenberg:/opt/"
echo "On box:  mkdir -p /opt/ranges && tar -xzf /opt/$out -C /opt/ranges"
