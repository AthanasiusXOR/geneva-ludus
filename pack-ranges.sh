#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
out="wittenberg-geneva-$(date +%Y%m%d).tar.gz"
tar -czf "$out" README.md SETUP.md pack-ranges.sh geneva
echo "Wrote $out"
ls -lh "$out"
