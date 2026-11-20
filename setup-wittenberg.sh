#!/usr/bin/env bash
# Install Ludus on Wittenberg, build GENEVA templates, create GENEVA user.
set -euo pipefail

PARALLEL=1
DO_INSTALL=0
DO_TEMPLATES=0
DO_USERS=0

TEMPLATES="win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template"
BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"

usage() {
  cat <<'USAGE'
Usage: ./setup-wittenberg.sh [--install] [--templates] [--users] [--parallel N]

  --install     Run Ludus installer (interactive; node name: wittenberg)
  --templates   Add BSL ubuntu template + build the three GENEVA templates
  --users       Create Ludus user GENEVA
  --parallel N  Packer concurrency (default 1)

Requires LUDUS_API_KEY for --templates / --users (from ludus-install-status).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) DO_INSTALL=1; shift ;;
    --templates) DO_TEMPLATES=1; shift ;;
    --users) DO_USERS=1; shift ;;
    --parallel) PARALLEL="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ $DO_INSTALL -eq 0 && $DO_TEMPLATES -eq 0 && $DO_USERS -eq 0 ]]; then
  usage
  exit 1
fi

if [[ $DO_INSTALL -eq 1 ]]; then
  echo "==> Installing Ludus (set node name to wittenberg when prompted)"
  apt update
  apt install -y curl sudo ca-certificates jq
  curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
  echo "If reboot required, reboot, then: sudo ludus-install-status"
  echo " export LUDUS_API_KEY='…'  then re-run with --templates --users"
fi

need_key() {
  if [[ -z "${LUDUS_API_KEY:-}" ]]; then
    echo "Set LUDUS_API_KEY first (leading space hides from history):" >&2
    echo "  export LUDUS_API_KEY='…'" >&2
    exit 1
  fi
  command -v ludus >/dev/null || { echo "ludus CLI not on PATH" >&2; exit 1; }
}

if [[ $DO_TEMPLATES -eq 1 ]]; then
  need_key
  echo "==> Ensuring BSL ubuntu template is in catalog"
  if ! ludus templates list 2>/dev/null | grep -q 'ubuntu-22.04-x64-server-template'; then
    # Prefer registered source name; fall back to URL
    if ludus source list 2>/dev/null | grep -qi 'ludus-source-bsl\|badsectorlabs'; then
      ludus source add ludus-source-bsl --templates ubuntu-22.04-x64-server-template || \
        ludus source add "$BSL_URL" --templates ubuntu-22.04-x64-server-template
    else
      ludus source add "$BSL_URL" --templates ubuntu-22.04-x64-server-template
    fi
  else
    echo "ubuntu-22.04-x64-server-template already listed"
  fi

  echo "==> Building: $TEMPLATES (parallel=$PARALLEL)"
  ludus templates build -n "$TEMPLATES" --parallel "$PARALLEL" || \
    ludus templates build -n "$TEMPLATES"
  echo "Follow with: ludus templates logs -f"
fi

if [[ $DO_USERS -eq 1 ]]; then
  need_key
  if ludus user list 2>/dev/null | grep -q GENEVA; then
    echo "User GENEVA already exists"
  else
    echo "==> Creating user GENEVA"
    ludus user add -n 'Geneva' -i GENEVA
  fi
  ludus user list
fi

echo "Done."
