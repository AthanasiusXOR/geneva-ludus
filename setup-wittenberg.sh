#!/usr/bin/env bash
# Wittenberg helper — range owner = prefix of LUDUS_API_KEY (not hardcoded)
#
# Docs:
#   Install:   https://docs.ludus.cloud/docs/deployment-options/proxmox
#   Users:     https://docs.ludus.cloud/docs/quick-start/create-a-user/
#   Templates: https://docs.ludus.cloud/docs/quick-start/build-templates/
#   Sources:   https://docs.ludus.cloud/docs/using-ludus/sources
#
set -euo pipefail

PARALLEL=1
DO_INSTALL=0
DO_TEMPLATES=0
DO_USERS=0
DO_DEPLOY=0

NEEDED="win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template"
BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RANGE_YML="${RANGE_YML:-$SCRIPT_DIR/range.yml}"
INVENTORY="${INVENTORY:-$SCRIPT_DIR/inventory.yml}"

usage() {
  cat <<'USAGE'
Usage: ./setup-wittenberg.sh [--install] [--templates] [--users] [--deploy] [--parallel N]

  Range owner = prefix of LUDUS_API_KEY (set before running).

  --install     curl -s https://ludus.cloud/install | bash  (no API key)
  --users       ludus user list; optional ludus user add (needs admin key)
  --templates   numbered menu → pick templates → source add + build (needs API key)
  --deploy      range config set + range (needs API key)
  --parallel N  Packer concurrency (default 1)
USAGE
}

die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo "==> $*"; }

ludus_user_from_key() {
  printf '%s\n' "${LUDUS_API_KEY%%.*}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) DO_INSTALL=1; shift ;;
    --templates) DO_TEMPLATES=1; shift ;;
    --users) DO_USERS=1; shift ;;
    --deploy) DO_DEPLOY=1; shift ;;
    --parallel) PARALLEL="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown: $1" ;;
  esac
done

[[ $DO_INSTALL -eq 1 || $DO_TEMPLATES -eq 1 || $DO_USERS -eq 1 || $DO_DEPLOY -eq 1 ]] || { usage; exit 1; }

need_api_key() {
  if [[ -z "${LUDUS_API_KEY:-}" ]]; then
    die "LUDUS_API_KEY is not set.

Export it, then re-run:
  export LUDUS_API_KEY='YOURUSER.…'
  ./setup-wittenberg.sh $*"
  fi
  command -v ludus >/dev/null || die "ludus CLI not on PATH"
  local u
  u="$(ludus_user_from_key)"
  [[ -n "$u" ]] || die "Could not parse userid from LUDUS_API_KEY"
  if [[ "$u" == "ROOT" ]]; then
    die "Do not use ROOT for templates/deploy. Export a normal Ludus user key."
  fi
  log "API key user: $u"
}

stamp_inventory() {
  local u="$1"
  [[ -f "$INVENTORY" ]] || return 0
  if grep -q 'RANGE_ID' "$INVENTORY" 2>/dev/null; then
    sed -i "s/RANGE_ID/${u}/g" "$INVENTORY"
    log "Stamped inventory.yml RANGE_ID → ${u}"
  fi
}

# --- --install ---
# https://docs.ludus.cloud/docs/deployment-options/proxmox
if [[ $DO_INSTALL -eq 1 ]]; then
  log "Installing Ludus"
  apt update
  apt install -y curl sudo ca-certificates jq
  curl -s https://ludus.cloud/install | bash
  echo
  echo "Next: ludus-install-status → export the initial admin API key"
  echo "Then Quick Start → Create a User / --users / --templates"
fi

# --- --users ---
# https://docs.ludus.cloud/docs/quick-start/create-a-user/
if [[ $DO_USERS -eq 1 ]]; then
  need_api_key --users
  ludus user list
  echo
  echo "Create an additional Ludus user? (Enter alone to skip)"
  read -r -p "  --name (e.g. Lab Admin): " uname
  if [[ -n "${uname}" ]]; then
    read -r -p "  --userid (1-20 alphanumeric, e.g. CH): " uid
    [[ -n "${uid}" ]] || die "--userid required"
    read -r -p "  --email (e.g. you@example.com): " uemail
    [[ -n "${uemail}" ]] || die "--email required"
    # Docs: ludus user add --name "…" --userid … --email …
    # Do not use a --name that already exists as a Linux user (lowercase, spaces→-)
    log "ludus user add --name \"${uname}\" --userid ${uid} --email ${uemail}"
    ludus user add --name "${uname}" --userid "${uid}" --email "${uemail}"
    echo
    echo "Save the API key from the table. To use that user for Geneva:"
    echo "  export LUDUS_API_KEY='${uid}.…'"
    ludus user list
  else
    echo "Skipped create (list only)."
  fi
fi

resolve_bsl() {
  if ludus source list 2>/dev/null | grep -Eqo 'ludus-source-bsl'; then
    printf '%s\n' 'ludus-source-bsl'
  else
    printf '%s\n' "$BSL_URL"
  fi
}

# --- --templates ---
# https://docs.ludus.cloud/docs/quick-start/build-templates/
# https://docs.ludus.cloud/docs/using-ludus/sources
# Interactive: numbered list → select 1,2,3 → source add + build
if [[ $DO_TEMPLATES -eq 1 ]]; then
  need_api_key --templates

  bsl="$(resolve_bsl)"
  log "Source: $bsl"
  log "templates list (already installed for this user)"
  ludus templates list || true
  echo

  # Build picker list from source catalog when possible
  mapfile -t CATALOG < <(
    {
      ludus source list "$bsl" --catalog 2>/dev/null || true
      ludus source list ludus-source-bsl --catalog 2>/dev/null || true
    } | grep -Eo '[A-Za-z0-9._+-]+-template' | sort -u
  )

  # Fallback known set if catalog parse empty
  if [[ ${#CATALOG[@]} -eq 0 ]]; then
    CATALOG=(
      debian-12-x64-server-template
      debian-13-x64-server-template
      kali-x64-desktop-template
      ubuntu-22.04-x64-server-template
      win11-22h2-x64-enterprise-template
      win2022-server-x64-template
    )
    log "Catalog empty/unparsed — using common template list"
  fi

  echo "Available templates:"
  for i in "${!CATALOG[@]}"; do
    printf "  %2d) %s\n" "$((i + 1))" "${CATALOG[$i]}"
  done
  echo
  echo "Geneva defaults: win2022 + ubuntu-22.04 + kali"
  echo "Enter numbers separated by spaces/commas (e.g. 3 4 6), or Enter for Geneva defaults:"
  read -r -p "> " selection

  SELECTED=()
  if [[ -z "${selection// /}" ]]; then
    # defaults by name
    for t in win2022-server-x64-template ubuntu-22.04-x64-server-template kali-x64-desktop-template; do
      SELECTED+=("$t")
    done
    log "Using Geneva defaults: ${SELECTED[*]}"
  else
    selection="${selection//,/ }"
    for n in $selection; do
      [[ "$n" =~ ^[0-9]+$ ]] || die "Not a number: $n"
      idx=$((n - 1))
      if [[ $idx -lt 0 || $idx -ge ${#CATALOG[@]} ]]; then
        die "Out of range: $n (1-${#CATALOG[@]})"
      fi
      SELECTED+=("${CATALOG[$idx]}")
    done
  fi

  # dedupe preserve order
  DEDUPED=()
  for t in "${SELECTED[@]}"; do
    skip=0
    for d in "${DEDUPED[@]+"${DEDUPED[@]}"}"; do
      [[ "$d" == "$t" ]] && { skip=1; break; }
    done
    [[ $skip -eq 1 ]] || DEDUPED+=("$t")
  done
  SELECTED=("${DEDUPED[@]}")
  [[ ${#SELECTED[@]} -gt 0 ]] || die "No templates selected"

  NEEDED_CSV="$(IFS=,; echo "${SELECTED[*]}")"
  log "Installing defs: $NEEDED_CSV"
  set +e
  ludus source add "$bsl" --templates "$NEEDED_CSV"
  rc=$?
  [[ $rc -eq 0 ]] || ludus source add "$BSL_URL" --templates "$NEEDED_CSV"
  rc=$?
  set -e
  [[ $rc -eq 0 ]] || die "source add failed"

  ludus templates list
  for t in "${SELECTED[@]}"; do
    ludus templates list 2>/dev/null | grep -Fq "$t" || die "Missing from catalog: $t"
  done

  log "ludus templates build -n $NEEDED_CSV"
  if (( PARALLEL > 1 )); then
    ludus templates build -n "$NEEDED_CSV" --parallel "$PARALLEL"
  else
    ludus templates build -n "$NEEDED_CSV"
  fi
  echo "Watch: ludus templates logs -f"
fi

# --- --deploy ---
if [[ $DO_DEPLOY -eq 1 ]]; then
  need_api_key --deploy
  [[ -f "$RANGE_YML" ]] || die "Missing $RANGE_YML"
  u="$(ludus_user_from_key)"
  stamp_inventory "$u"
  log "ludus range config set -f $RANGE_YML"
  ludus range config set -f "$RANGE_YML"
  log "ludus range deploy (as $u)"
  ludus range deploy
  echo "Watch: ludus range logs -f"
fi

echo "Done."
