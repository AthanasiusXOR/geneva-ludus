#!/usr/bin/env bash
# Wittenberg bootstrap. Keep this dumb and loud — Ludus 2.2 Sources are picky.
#
# Templates are PER-USER and bound to LUDUS_API_KEY.
# Use the initial admin key from `ludus-install-status` (or ATHANASIUS after --users).
# NEVER use the ROOT key for templates. NEVER sudo this for --templates/--users.
set -euo pipefail

PARALLEL=1
DO_INSTALL=0
DO_TEMPLATES=0
DO_USERS=0

NEEDED="win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template"
BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"

usage() {
  cat <<'USAGE'
Usage: ./setup-wittenberg.sh [--install] [--users] [--templates] [--parallel N]

  --install     Ludus installer only (node name: wittenberg)
  --users       Create ATHANASIUS --admin (needs ROOT or admin key + admin API URL)
  --templates   source add BSL templates into THIS key's catalog, then Packer build
  --parallel N  Packer concurrency (default 1)

Order that works:
  1) --install → ludus-install-status → export INITIAL ADMIN key (not ROOT)
  2) --templates   (or do templates as ATHANASIUS after --users + key switch)
  3) optional --users if you want ATHANASIUS as a second admin

No sudo for --users / --templates.
USAGE
}

die() { echo "ERROR: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) DO_INSTALL=1; shift ;;
    --templates) DO_TEMPLATES=1; shift ;;
    --users) DO_USERS=1; shift ;;
    --parallel) PARALLEL="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown: $1" ;;
  esac
done

[[ $DO_INSTALL -eq 1 || $DO_TEMPLATES -eq 1 || $DO_USERS -eq 1 ]] || { usage; exit 1; }

if [[ $DO_INSTALL -eq 1 ]]; then
  echo "==> Installing Ludus (node name: wittenberg)"
  apt update
  apt install -y curl sudo ca-certificates jq
  curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
  echo
  echo "Next:"
  echo "  sudo ludus-install-status"
  echo "  # copy the INITIAL ADMIN API key (userID.…), NOT the ROOT key"
  echo "  export LUDUS_API_KEY='…'"
  echo "  ./setup-wittenberg.sh --templates"
fi

need_cli_key() {
  command -v ludus >/dev/null || die "ludus not on PATH"
  [[ -n "${LUDUS_API_KEY:-}" ]] || die "LUDUS_API_KEY unset. export it in THIS shell (no sudo)."
  local prefix="${LUDUS_API_KEY%%.*}"
  echo "==> Acting as Ludus user prefix: ${prefix}"
  if [[ "$prefix" == "ROOT" ]]; then
    die "ROOT key cannot own a template catalog. Use the initial admin key from ludus-install-status, or ATHANASIUS after --users."
  fi
}

if [[ $DO_USERS -eq 1 ]]; then
  need_cli_key
  if ludus user list 2>/dev/null | grep -q ATHANASIUS; then
    echo "ATHANASIUS already exists"
    ludus user list
  else
    echo "==> Creating ATHANASIUS (admin)"
    set +e
    out="$(ludus user add --name 'Athanasius' --userid ATHANASIUS --admin --url https://127.0.0.1:8081 2>&1)"
    rc=$?
    set -e
    echo "$out"
    [[ $rc -eq 0 ]] || die "user add failed (rc=$rc). Are you using an admin/ROOT-capable key?"
    echo
    echo "Export the ATHANASIUS API key from the table above, then run --templates with THAT key."
  fi
fi

if [[ $DO_TEMPLATES -eq 1 ]]; then
  need_cli_key

  echo "==> source list"
  ludus source list || true
  echo

  # Prefer short id if present; else URL. Fresh hosts auto-register BSL for admins.
  bsl="ludus-source-bsl"
  if ! ludus source list 2>/dev/null | grep -Eq 'ludus-source-bsl'; then
    # user-prefixed id, e.g. JD-badsectorlabs-ludus-source-bsl
    alt="$(ludus source list 2>/dev/null | awk '/ludus-source-bsl|badsectorlabs/ {for(i=1;i<=NF;i++) if($i~/ludus-source-bsl|badsectorlabs/){gsub(/[|+]/,"",$i); print $i; exit}}' || true)"
    if [[ -n "${alt:-}" ]]; then
      bsl="$alt"
    else
      bsl="$BSL_URL"
    fi
  fi

  echo "==> Installing template defs into THIS user's catalog"
  echo "    target: $bsl"
  echo "    names:  $NEEDED"
  # Comma-separated --templates is supported by Ludus Sources CLI
  set +e
  ludus source add "$bsl" --templates "$NEEDED"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "short-id/path failed (rc=$rc); trying GitHub URL + --templates"
    ludus source add "$BSL_URL" --templates "$NEEDED"
    rc=$?
  fi
  if [[ $rc -ne 0 ]]; then
    echo "specific templates failed; falling back to --all from BSL"
    ludus source add "$bsl" --all || ludus source add "$BSL_URL" --all
    rc=$?
  fi
  set -e
  [[ $rc -eq 0 ]] || die "source add failed completely"

  echo
  echo "==> templates list (must be non-empty)"
  ludus templates list
  if ! ludus templates list 2>/dev/null | grep -Eq 'win2022|kali|ubuntu-22.04'; then
    die "Catalog still empty/missing needed templates. Paste output of: ludus source list ; ludus templates list ; echo key=\${LUDUS_API_KEY%%.*}"
  fi

  # Ensure ubuntu is present even if --all defaults omitted it somehow
  if ! ludus templates list 2>/dev/null | grep -Fq 'ubuntu-22.04-x64-server-template'; then
    echo "==> ubuntu-22.04 missing from catalog; adding explicitly"
    ludus source add "$bsl" --templates ubuntu-22.04-x64-server-template \
      || ludus source add "$BSL_URL" --templates ubuntu-22.04-x64-server-template
  fi

  echo
  echo "==> Packer build: $NEEDED"
  if (( PARALLEL > 1 )); then
    ludus templates build -n "$NEEDED" --parallel "$PARALLEL"
  else
    ludus templates build -n "$NEEDED"
  fi
  echo
  echo "Watch:  ludus templates logs -f"
  echo "Status: ludus templates list"
fi

echo "Done."
