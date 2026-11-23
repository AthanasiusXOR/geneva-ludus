#!/usr/bin/env bash
# Wittenberg helper — range owner = whoever owns LUDUS_API_KEY (no hardcoded userid)
#
#   export LUDUS_API_KEY='CH.…'    # or AD.… / whatever you created at install
#   ./setup-wittenberg.sh --templates
#   ./setup-wittenberg.sh --deploy
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
  range.yml uses {{ range_id }} so VMs become <USERID>-DC01, etc.

  --install     Install Ludus (no API key)
  --templates   source add + Packer build (needs LUDUS_API_KEY)
  --users       Show current key's user / user list (needs LUDUS_API_KEY)
  --deploy      Deploy range.yml as that key's user (needs LUDUS_API_KEY)
  --parallel N  Packer concurrency (default 1)

  export LUDUS_API_KEY='YOURUSER.…'
  ./setup-wittenberg.sh --templates
  ludus templates logs -f
  ./setup-wittenberg.sh --deploy
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

Export the Ludus user key you want to own this range, then re-run:
  export LUDUS_API_KEY='YOURUSER.…'
  ./setup-wittenberg.sh $*"
  fi
  command -v ludus >/dev/null || die "ludus CLI not on PATH"
  local u
  u="$(ludus_user_from_key)"
  [[ -n "$u" ]] || die "Could not parse userid from LUDUS_API_KEY"
  if [[ "$u" == "ROOT" ]]; then
    die "Do not use the ROOT key for templates/deploy. Export a normal Ludus user key."
  fi
  log "Range owner (from API key): $u"
}

stamp_inventory() {
  local u="$1"
  [[ -f "$INVENTORY" ]] || return 0
  # inventory uses RANGE_ID placeholder for GOAD VM names
  if grep -q 'RANGE_ID' "$INVENTORY" 2>/dev/null; then
    sed -i "s/RANGE_ID/${u}/g" "$INVENTORY"
    log "Stamped inventory.yml RANGE_ID → ${u}"
  fi
}

if [[ $DO_INSTALL -eq 1 ]]; then
  log "Installing Ludus (node name: wittenberg)"
  apt update
  apt install -y curl sudo ca-certificates jq
  curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
  echo "Create/pick your Ludus user, then:"
  echo "  export LUDUS_API_KEY='YOURUSER.…'"
  echo "  ./setup-wittenberg.sh --templates"
fi

if [[ $DO_USERS -eq 1 ]]; then
  need_api_key --users
  log "This shell will deploy as: $(ludus_user_from_key)"
  ludus user list
fi

resolve_bsl() {
  if ludus source list 2>/dev/null | grep -Eqo 'ludus-source-bsl'; then
    printf '%s\n' 'ludus-source-bsl'
  else
    printf '%s\n' "$BSL_URL"
  fi
}

if [[ $DO_TEMPLATES -eq 1 ]]; then
  need_api_key --templates
  bsl="$(resolve_bsl)"
  log "source add from $bsl"
  set +e
  ludus source add "$bsl" --templates "$NEEDED"
  rc=$?
  [[ $rc -eq 0 ]] || ludus source add "$BSL_URL" --templates "$NEEDED"
  rc=$?
  [[ $rc -eq 0 ]] || { ludus source add "$bsl" --all || ludus source add "$BSL_URL" --all; rc=$?; }
  set -e
  [[ $rc -eq 0 ]] || die "source add failed"

  ludus templates list
  IFS=',' read -ra arr <<< "$NEEDED"
  for t in "${arr[@]}"; do
    t="${t// /}"
    ludus templates list 2>/dev/null | grep -Fq "$t" || die "Missing: $t"
  done

  log "templates build"
  if (( PARALLEL > 1 )); then
    ludus templates build -n "$NEEDED" --parallel "$PARALLEL"
  else
    ludus templates build -n "$NEEDED"
  fi
  echo "Watch: ludus templates logs -f"
fi

if [[ $DO_DEPLOY -eq 1 ]]; then
  need_api_key --deploy
  [[ -f "$RANGE_YML" ]] || die "Missing $RANGE_YML"
  u="$(ludus_user_from_key)"
  stamp_inventory "$u"
  log "Deploying range.yml as user $u (VMs: ${u}-DC01, …)"
  ludus range config set -f "$RANGE_YML"
  ludus range deploy
  echo "Watch: ludus range logs -f"
fi

echo "Done."
