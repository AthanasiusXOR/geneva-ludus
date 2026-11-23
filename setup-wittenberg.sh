#!/usr/bin/env bash
# Wittenberg bootstrap for Ludus user: admin
#
# Standing key: Ludus user "admin". Your ~/.bashrc alias `admin` exports LUDUS_API_KEY.
#
#   su -
#   admin                          # alias → export LUDUS_API_KEY
#   ./setup-wittenberg.sh --templates
#
# Do NOT sudo the script for --templates (sudo drops the env unless -E).
set -euo pipefail

PARALLEL=1
DO_INSTALL=0
DO_TEMPLATES=0
DO_USERS=0
DO_DEPLOY=0

# Fixed Ludus user for this lab
LUDUS_USER="admin"

NEEDED="win2022-server-x64-template,ubuntu-22.04-x64-server-template,kali-x64-desktop-template"
BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RANGE_YML="${RANGE_YML:-$SCRIPT_DIR/geneva/range.yml}"

usage() {
  cat <<USAGE
Usage: ./setup-wittenberg.sh [--install] [--templates] [--users] [--deploy] [--parallel N]

  Ludus user: ${LUDUS_USER}
  Run bashrc alias \`admin\` first (exports LUDUS_API_KEY).

  --install     Ludus installer (node name: wittenberg)
  --templates   source add + Packer build (win2022, ubuntu-22.04, kali)
  --users       Verify ${LUDUS_USER} exists
  --deploy      Set geneva/range.yml + range GOAD + attack infra (needs BUILT templates)
  --parallel N  Packer concurrency (default 1)

Full chain after Ludus is up:
  admin
  ./setup-wittenberg.sh --templates
  ludus templates logs -f          # wait until BUILT
  ./setup-wittenberg.sh --deploy
  ludus range logs -f
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

if [[ $DO_INSTALL -eq 1 ]]; then
  log "Installing Ludus (set node name to wittenberg; admin user should be: ${LUDUS_USER})"
  apt update
  apt install -y curl sudo ca-certificates jq
  curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash
  echo
  echo "Next (as su -):"
  echo "  ludus-install-status   # confirm admin user / key once"
  echo "  admin                  # bashrc alias exports LUDUS_API_KEY"
  echo "  ./setup-wittenberg.sh --templates"
fi

need_admin_key() {
  command -v ludus >/dev/null || die "ludus not on PATH"
  if [[ -z "${LUDUS_API_KEY:-}" ]]; then
    die "LUDUS_API_KEY unset.

Run your bashrc alias first, then the script:
  admin
  ./setup-wittenberg.sh --templates"
  fi

  local prefix="${LUDUS_API_KEY%%.*}"
  log "LUDUS_API_KEY prefix: ${prefix} (expected Ludus user: ${LUDUS_USER})"

  if [[ "${prefix}" == "ROOT" ]]; then
    die "ROOT key will not populate templates. Run: admin   # then retry"
  fi

  # Case-insensitive match for admin
  local want lower
  want="$(printf '%s' "$LUDUS_USER" | tr '[:upper:]' '[:lower:]')"
  lower="$(printf '%s' "$prefix" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower" != "$want" ]]; then
    die "Expected key for Ludus user '${LUDUS_USER}', got '${prefix}'.
Run: admin   # bashrc alias that exports the admin LUDUS_API_KEY"
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
  echo "When all three show BUILT:"
  echo "  ./setup-wittenberg.sh --deploy"
fi

if [[ $DO_DEPLOY -eq 1 ]]; then
  need_admin_key
  [[ -f "$RANGE_YML" ]] || die "Missing range config: $RANGE_YML"

  log "Checking needed templates are BUILT"
  list="$(ludus templates list 2>/dev/null || true)"
  echo "$list"
  for t in win2022-server-x64-template ubuntu-22.04-x64-server-template kali-x64-desktop-template; do
    echo "$list" | grep -Fq "$t" || die "Template not in catalog: $t — run --templates first"
  done
  # Accept TRUE / BUILT / ✅ depending on Ludus version table
  if ! echo "$list" | grep -E 'win2022-server-x64-template' | grep -Eqi 'TRUE|BUILT|✔|✅'; then
    echo "WARNING: win2022 may not be BUILT yet — deploy will fail if Packer is still running."
    echo "Continue anyway in 5s (Ctrl-C to abort)…"
    sleep 5
  fi

  log "range config set -f $RANGE_YML"
  ludus range config set -f "$RANGE_YML"
  log "range deploy (GOAD VLAN10 + redirs20 + kali/c2/teamshare/winattack30 + ansible40)"
  ludus range deploy
  echo
  echo "Watch:  ludus range logs -f"
  echo "Status: ludus range list"
fi

echo "Done."
