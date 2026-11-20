#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ -n "${RANGENUMBER:-}" ]]; then
  n="$RANGENUMBER"
elif command -v ludus >/dev/null 2>&1; then
  n="$(ludus --user GENEVA range list --json 2>/dev/null | jq -r '.rangeNumber // .[0].rangeNumber // empty' || true)"
else
  echo "Set RANGENUMBER=N  (e.g. RANGENUMBER=1 ./stamp-range-number.sh)" >&2
  exit 1
fi

[[ -n "$n" && "$n" != "null" ]] || { echo "Could not determine range number" >&2; exit 1; }

for f in inventory.yml red-infra-inventory.yml; do
  [[ -f "$f" ]] || continue
  sed -i "s/RANGE_NUMBER/${n}/g" "$f"
  echo "Stamped $f → ${n}"
done

echo "GOAD DC01: 10.${n}.10.10"
echo "Kali:      10.${n}.30.21"
