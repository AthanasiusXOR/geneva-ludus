#!/usr/bin/env bash
# Wittenberg helper
#
# Deploy user = owner of LUDUS_API_KEY (your key prefix is AD).
#   export LUDUS_API_KEY='AD.…'
#   ./setup-wittenberg.sh --templates
#   ./setup-wittenberg.sh --deploy
#
# --install does not need a key. --templates / --users / --deploy do.
set -euo pipefail

PARALLEL=1
DO_INSTALL=0
DO_TEMPLATES=0
DO_USERS=0
DO_DEPLOY=0

LUDUS_USER="AD"
NEEDED="win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template"
BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RANGE_YML="${RANGE_YML:-$SCRIPT_DIR/range.yml}"

usage() {
  cat <<USAGE
Usage: ./setup-wittenberg.sh [--install] [--templates] [--users] [--deploy] [--parallel N]

  Ludus range owner (from your API key): ${LUDUS_USER}
  GOAD VMs will be named ${LUDUS_USER}-DC01, etc.

  --install     Install Ludus (no API key)
  --templates   source add + Packer build (needs LUDUS_API_KEY)
  --users       Confirm user ${LUDUS_USER} exists (needs LUDUS_API_KEY)
  --deploy      Deploy range.yml as that key's user (needs LUDUS_API_KEY)
  --parallel N  Packer concurrency (default 1)

  export LUDUS_API_KEY='AD.…'
  ./setup-wittenberg.sh --templates
  ludus templates logs -f
  ./setup-wittenberg.sh --deploy
USAGE
}

die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo "==> $*"; }

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

Export your AD user key, then re-run:
  export LUDUS_API_KEY='AD.…'
  ./setup-wittenberg.sh $*"
  fi
  command -v ludus >/dev/null || die "ludus CLI not on PATH"
  local prefix="${LUDUS_API_KEY%%.*}"
  log "Using Ludus user from API key: ${prefix} (expected ${LUDUS_USER} for this range)"
  if [[ "${prefix}" == "ROOT" ]]; then
    die "Do not deploy/build templates with ROOT. Export the AD user key."
  fi
}

if [[ $DO_INSTALL -eq 1 ]]; then
  log "Installing Ludus (node name: wittenberg)"
  apt update
  apt install -y curl sudo ca-certificates jq
  curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
  echo "Then: ludus-install-status → export LUDUS_API_KEY='AD.…' → ./setup-wittenberg.sh --templates"
fi

if [[ $DO_USERS -eq 1 ]]; then
  need_api_key --users
  ludus user list
  if ludus user list 2>/dev/null | grep -qw "$LUDUS_USER"; then
    echo "OK: ${LUDUS_USER} exists — that is who owns the Geneva range / deploy"
  else
    die "${LUDUS_USER} not found. Create with an admin/ROOT key:
  ludus user add --name 'Lab Admin' --userid AD --admin --url https://127.0.0.1:8081"
  fi
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
  log "Deploying as API key user ${LUDUS_API_KEY%%.*} → range.yml"
  ludus range config set -f "$RANGE_YML"
  ludus range deploy
  echo "Watch: ludus range logs -f"
  echo "GOAD VMs: ${LUDUS_USER}-DC01 … (range_id = API key userid)"
fi

echo "Done."
