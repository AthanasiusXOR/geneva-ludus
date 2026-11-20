#!/usr/bin/env bash
# Replace RANGE_NUMBER placeholders in Wittenberg inventories.
set -euo pipefail
cd "$(dirname "$0")"

USER_FLAG=(--user WITTENBERG)

if [[ -n "${RANGENUMBER:-}" ]]; then
  n="$RANGENUMBER"
elif command -v ludus >/dev/null 2>&1; then
  n="$(ludus "${USER_FLAG[@]}" range list --json 2>/dev/null | jq -r '.rangeNumber // .[0].rangeNumber // empty' || true)"
  if [[ -z "$n" || "$n" == "null" ]]; then
    n="$(ludus range list --json 2>/dev/null | jq -r '.rangeNumber // .[0].rangeNumber // empty' || true)"
  fi
else
  echo "Set RANGENUMBER=… or export LUDUS_API_KEY and have ludus+jq available" >&2
  exit 1
fi

[[ -n "$n" && "$n" != "null" ]] || { echo "Could not determine Wittenberg range number" >&2; exit 1; }

for f in inventory.yml red-infra-inventory.yml; do
  sed -i "s/RANGE_NUMBER/${n}/g" "$f"
  echo "Stamped $f → Wittenberg range ${n}"
done
