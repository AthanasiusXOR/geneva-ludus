#!/usr/bin/env bash
# Install Ludus on Wittenberg, pull/build Geneva range templates, create ATHANASIUS.
#
# ATHANASIUS = your day-to-day Ludus user (API key stands in for root/admin).
# After creating it, use THAT key as LUDUS_API_KEY for --templates and deploys.
set -euo pipefail

PARALLEL=1
DO_INSTALL=0
DO_TEMPLATES=0
DO_USERS=0

TEMPLATES="win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template"
BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"
LUDUS_USER_ID="ATHANASIUS"
LUDUS_USER_NAME="Athanasius"

usage() {
  cat <<'USAGE'
Usage: ./setup-wittenberg.sh [--install] [--templates] [--users] [--parallel N]

  --install     Run Ludus installer (interactive; node name: wittenberg)
  --templates   Install Packer defs from Sources into THIS user's catalog, then build
  --users       Create Ludus user ATHANASIUS (use its API key as your root alias)
  --parallel N  Packer concurrency (default 1)

IMPORTANT:
  Do NOT use sudo for --templates / --users (it drops LUDUS_API_KEY).
  Run as root login shell OR:  export LUDUS_API_KEY='…' && ./setup-wittenberg.sh --templates

  Templates are per-user. Prefer ATHANASIUS key (or initial admin), not ROOT,
  for --templates — ROOT often leaves `ludus templates list` empty for your range user.

Requires LUDUS_API_KEY for --templates / --users.
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
  echo " export LUDUS_API_KEY='…'  then re-run: ./setup-wittenberg.sh --users"
  echo "Then switch to ATHANASIUS key and: ./setup-wittenberg.sh --templates"
fi

need_key() {
  if [[ -z "${LUDUS_API_KEY:-}" ]]; then
    echo "ERROR: LUDUS_API_KEY is not set in this shell." >&2
    echo "  If you used sudo, the key was dropped. Run without sudo:" >&2
    echo "    export LUDUS_API_KEY='YOURKEY'" >&2
    echo "    ./setup-wittenberg.sh --templates" >&2
    exit 1
  fi
  command -v ludus >/dev/null || { echo "ludus CLI not on PATH" >&2; exit 1; }

  # Key format is USERID.secret — show which user this shell will act as
  local prefix="${LUDUS_API_KEY%%.*}"
  echo "==> LUDUS_API_KEY present (user prefix: ${prefix})"
  if [[ "$prefix" == "ROOT" ]]; then
    echo "WARNING: You are using the ROOT key. Templates are per-user."
    echo "  Create/use ATHANASIUS first, then export THAT key and re-run --templates."
  fi
}

resolve_bsl() {
  local list
  list="$(ludus source list 2>/dev/null || true)"
  if grep -Eqo 'ludus-source-bsl' <<<"$list"; then
    printf '%s\n' 'ludus-source-bsl'
    return
  fi
  # Try any id containing bsl
  local id
  id="$(awk '/bsl|badsectorlabs/ {for (i=1;i<=NF;i++) if ($i ~ /bsl|badsectorlabs/) {gsub(/[|+]/,"",$i); print $i; exit}}' <<<"$list")"
  if [[ -n "${id:-}" ]]; then
    printf '%s\n' "$id"
    return
  fi
  printf '%s\n' "$BSL_URL"
}

install_one_template() {
  local target="$1"
  local name="$2"
  echo "---- source add $target --templates $name"
  if ludus source add "$target" --templates "$name"; then
    return 0
  fi
  echo "     first target failed; trying URL $BSL_URL"
  ludus source add "$BSL_URL" --templates "$name"
}

if [[ $DO_USERS -eq 1 ]]; then
  need_key
  if ludus user list 2>/dev/null | grep -q "$LUDUS_USER_ID"; then
    echo "User $LUDUS_USER_ID already exists — export its API key for --templates:"
    echo "  LUDUS_API_KEY='ROOT…' ludus user apikey --user $LUDUS_USER_ID"
    echo "  export LUDUS_API_KEY='…'"
  else
    echo "==> Creating user $LUDUS_USER_ID (save the API key — this is your root alias)"
    # ROOT key talks to admin API on 8081; --admin so this user can build templates
    ludus user add \
      --name "$LUDUS_USER_NAME" \
      --userid "$LUDUS_USER_ID" \
      --admin \
      --url https://127.0.0.1:8081
    echo
    echo "Put the printed key in your shell:"
    echo "  export LUDUS_API_KEY='…'"
  fi
  ludus user list
fi

if [[ $DO_TEMPLATES -eq 1 ]]; then
  need_key

  echo "==> Sources:"
  ludus source list
  echo

  bsl_target="$(resolve_bsl)"
  echo "==> Installing Packer defs into catalog for this API key user from: $bsl_target"

  IFS=',' read -ra tmpl_arr <<< "$TEMPLATES"
  for t in "${tmpl_arr[@]}"; do
    t="${t// /}"
    if ludus templates list 2>/dev/null | grep -Fq "$t"; then
      echo "  already in catalog: $t"
      continue
    fi
    install_one_template "$bsl_target" "$t"
  done

  echo
  echo "==> Catalog after source add:"
  ludus templates list || true

  missing=0
  for t in "${tmpl_arr[@]}"; do
    t="${t// /}"
    if ! ludus templates list 2>/dev/null | grep -Fq "$t"; then
      echo "MISSING: $t" >&2
      missing=1
    fi
  done
  if [[ "$missing" -ne 0 ]]; then
    echo >&2
    echo "ERROR: source add did not populate templates list." >&2
    echo "Fix checklist:" >&2
    echo "  1) Same shell: echo \"\${LUDUS_API_KEY:0:20}…\"   # must show USERID. prefix" >&2
    echo "  2) Do not use sudo for this script" >&2
    echo "  3) Prefer ATHANASIUS key (not ROOT) for template installs" >&2
    echo "  4) Manual retry:" >&2
    echo "       ludus source add ludus-source-bsl --templates win2022-server-x64-template" >&2
    echo "       ludus source add ludus-source-bsl --templates ubuntu-22.04-x64-server-template" >&2
    echo "       ludus source add ludus-source-bsl --templates kali-x64-desktop-template" >&2
    echo "       ludus templates list" >&2
    exit 1
  fi

  echo
  echo "==> Building Packer images: $TEMPLATES (parallel=$PARALLEL)"
  if (( PARALLEL > 1 )); then
    ludus templates build -n "$TEMPLATES" --parallel "$PARALLEL"
  else
    ludus templates build -n "$TEMPLATES"
  fi
  echo "Follow with: ludus templates logs -f"
fi

echo "Done."
