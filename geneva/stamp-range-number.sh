#!/usr/bin/env bash
# Replace RANGE_NUMBER placeholders in Geneva inventory.
set -euo pipefail
cd "$(dirname "$0")"

USER_FLAG=(--user GENEVA)

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

[[ -n "$n" && "$n" != "null" ]] || { echo "Could not determine Geneva range number" >&2; exit 1; }

sed -i "s/RANGE_NUMBER/${n}/g" inventory.yml
echo "Stamped inventory.yml → Geneva range ${n}"
echo "Ollama URL: http://10.${n}.10.10:11434"
echo "Update wittenberg/group_vars/all.yml geneva_ollama_url to that URL when ready."
