#!/usr/bin/env bash
# Wittenberg bootstrap for Ludus user: admin
#
# Your standing API key is the install admin:
#   export LUDUS_API_KEY='admin.…'
#
# Run as:  su -   then export the key, then run this script.
# Do NOT sudo the script for --templates (sudo can drop the env var unless -E).
set -euo pipefail

PARALLEL=1
DO_INSTALL=0
DO_TEMPLATES=0
DO_USERS=0

# Fixed Ludus user for this lab
LUDUS_USER="admin"

NEEDED="win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template"
BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"

usage() {
  cat <<USAGE
Usage: ./setup-wittenberg.sh [--install] [--templates] [--users] [--parallel N]

  Ludus user hardcoded: ${LUDUS_USER}
  export LUDUS_API_KEY='${LUDUS_USER}.…'   # from ludus-install-status

  --install     Ludus installer (node name: wittenberg)
  --templates   source add the three Geneva templates into admin's catalog, then Packer build
  --users       Verify ${LUDUS_USER} exists (does not create ATHANASIUS)
  --parallel N  Packer concurrency (default 1)

As root login shell:
  su -
  export LUDUS_API_KEY='admin.…'
  cd /opt/ranges   # or wherever this repo is
  ./setup-wittenberg.sh --templates
USAGE
}

die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo "==> $*"; }

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
  log "Installing Ludus (set node name to wittenberg; admin user should be: ${LUDUS_USER})"
  apt update
  apt install -y curl sudo ca-certificates jq
  curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
  echo
  echo "Next (as su -):"
  echo "  ludus-install-status"
  echo "  export LUDUS_API_KEY='admin.…'   # the admin user key, NOT ROOT"
  echo "  ./setup-wittenberg.sh --templates"
fi

need_admin_key() {
  command -v ludus >/dev/null || die "ludus not on PATH"
  if [[ -z "${LUDUS_API_KEY:-}" ]]; then
    die "LUDUS_API_KEY unset.

As su -:
  export LUDUS_API_KEY='admin.…'    # from ludus-install-status
  ./setup-wittenberg.sh --templates"
  fi

  local prefix="${LUDUS_API_KEY%%.*}"
  log "LUDUS_API_KEY prefix: ${prefix} (required: ${LUDUS_USER})"

  if [[ "${prefix}" == "ROOT" ]]; then
    die "ROOT key will not populate templates. Use: export LUDUS_API_KEY='admin.…'"
  fi

  # Case-insensitive match for admin
  local want lower
  want="$(printf '%s' "$LUDUS_USER" | tr '[:upper:]' '[:lower:]')"
  lower="$(printf '%s' "$prefix" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower" != "$want" ]]; then
    die "Expected key for user '${LUDUS_USER}', got '${prefix}'.
  export LUDUS_API_KEY='admin.…'"
  fi
}

if [[ $DO_USERS -eq 1 ]]; then
  need_admin_key
  log "Checking Ludus users (expect ${LUDUS_USER})"
  ludus user list
  if ! ludus user list 2>/dev/null | grep -qi "$LUDUS_USER"; then
    die "User ${LUDUS_USER} not in ludus user list. Create during install or:
  LUDUS_API_KEY='ROOT.…' ludus user add --name Admin --userid admin --admin --url https://127.0.0.1:8081"
  fi
  echo "OK: ${LUDUS_USER} present"
fi

resolve_bsl() {
  if ludus source list 2>/dev/null | grep -Eqo 'ludus-source-bsl'; then
    printf '%s\n' 'ludus-source-bsl'
    return
  fi
  local alt
  alt="$(ludus source list 2>/dev/null | awk '/ludus-source-bsl|badsectorlabs/ {
    for (i = 1; i <= NF; i++) {
      if ($i ~ /ludus-source-bsl|badsectorlabs/) {
        gsub(/[|+]/, "", $i)
        print $i
        exit
      }
    }
  }' || true)"
  if [[ -n "${alt:-}" ]]; then
    printf '%s\n' "$alt"
  else
    printf '%s\n' "$BSL_URL"
  fi
}

if [[ $DO_TEMPLATES -eq 1 ]]; then
  need_admin_key

  log "source list"
  ludus source list || true
  echo

  bsl="$(resolve_bsl)"
  log "Installing into ${LUDUS_USER} catalog from: $bsl"
  log "Templates: $NEEDED"

  set +e
  echo "---- ludus source add $bsl --templates $NEEDED"
  ludus source add "$bsl" --templates "$NEEDED"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "---- retry via URL"
    ludus source add "$BSL_URL" --templates "$NEEDED"
    rc=$?
  fi
  if [[ $rc -ne 0 ]]; then
    echo "---- fallback: source add --all"
    ludus source add "$bsl" --all || ludus source add "$BSL_URL" --all
    rc=$?
  fi
  set -e
  [[ $rc -eq 0 ]] || die "source add failed (rc=$rc). Paste: ludus source list ; ludus templates list"

  echo
  log "templates list"
  ludus templates list

  missing=0
  IFS=',' read -ra arr <<< "$NEEDED"
  for t in "${arr[@]}"; do
    t="${t// /}"
    if ! ludus templates list 2>/dev/null | grep -Fq "$t"; then
      echo "MISSING after source add: $t" >&2
      missing=1
    fi
  done
  if [[ "$missing" -ne 0 ]]; then
    # one-by-one last resort
    log "Retrying each template individually"
    for t in "${arr[@]}"; do
      t="${t// /}"
      ludus templates list 2>/dev/null | grep -Fq "$t" && continue
      ludus source add "$bsl" --templates "$t" || ludus source add "$BSL_URL" --templates "$t" || true
    done
    ludus templates list
    for t in "${arr[@]}"; do
      t="${t// /}"
      ludus templates list 2>/dev/null | grep -Fq "$t" || die "Still missing: $t"
    done
  fi

  log "Packer build: $NEEDED (parallel=$PARALLEL)"
  if (( PARALLEL > 1 )); then
    ludus templates build -n "$NEEDED" --parallel "$PARALLEL"
  else
    ludus templates build -n "$NEEDED"
  fi

  echo
  echo "Watch build:"
  echo "  ludus templates logs -f"
  echo "  ludus templates list"
fi

echo "Done."
