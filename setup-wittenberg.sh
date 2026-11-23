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
  --templates   ensure ubuntu + show numbered list; Enter=build all, or pick numbers (needs API key)
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
  # Range number (second octet) if Ludus already assigned one
  if grep -q 'RANGE_NUMBER' "$INVENTORY" 2>/dev/null && command -v jq >/dev/null; then
    local n
    n="$(ludus range list --json 2>/dev/null | jq -r '.rangeNumber // .[0].rangeNumber // empty' || true)"
    if [[ -n "$n" && "$n" != "null" ]]; then
      sed -i "s/RANGE_NUMBER/${n}/g" "$INVENTORY"
      log "Stamped inventory.yml RANGE_NUMBER → ${n}"
    else
      log "RANGE_NUMBER left for later (sed after deploy if needed)"
    fi
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
#
# Always ensure ubuntu-22.04 (Geneva). Show numbered catalog.
# Enter = build ALL in catalog (standards + ubuntu). Numbers = build only those.
if [[ $DO_TEMPLATES -eq 1 ]]; then
  need_api_key --templates

  bsl="$(resolve_bsl)"
  EXTRA="ubuntu-22.04-x64-server-template"

  log "templates list (before)"
  ludus templates list || true

  # Geneva needs ubuntu; not always in the default catalog
  if ! ludus templates list 2>/dev/null | grep -Fq "$EXTRA"; then
    log "Adding Geneva required: $EXTRA from $bsl"
    set +e
    ludus source add "$bsl" --templates "$EXTRA"
    rc=$?
    [[ $rc -eq 0 ]] || ludus source add "$BSL_URL" --templates "$EXTRA"
    rc=$?
    set -e
    [[ $rc -eq 0 ]] || die "Failed to source add $EXTRA"
  else
    log "$EXTRA already in catalog"
  fi

  # Numbered list: installed templates + source catalog names
  mapfile -t CATALOG < <(
    {
      ludus templates list 2>/dev/null || true
      ludus source list "$bsl" --catalog 2>/dev/null || true
      ludus source list ludus-source-bsl --catalog 2>/dev/null || true
    } | grep -Eo '[A-Za-z0-9._+-]+-template' | sort -u
  )
  if [[ ${#CATALOG[@]} -eq 0 ]]; then
    CATALOG=(
      debian-12-x64-server-template
      debian-13-x64-server-template
      kali-x64-desktop-template
      ubuntu-22.04-x64-server-template
      win11-22h2-x64-enterprise-template
      win2022-server-x64-template
    )
  fi

  echo
  echo "Available templates:"
  for i in "${!CATALOG[@]}"; do
    mark=""
    case "${CATALOG[$i]}" in
      win2022-server-x64-template|ubuntu-22.04-x64-server-template|kali-x64-desktop-template) mark="  [Geneva]" ;;
    esac
    printf "  %2d) %s%s\n" "$((i + 1))" "${CATALOG[$i]}" "$mark"
  done
  echo
  echo "Enter = build ALL templates currently in the catalog (standard + ubuntu)."
  echo "Or pick numbers to build only those (e.g. 3 5 10) — will source-add if needed:"
  read -r -p "> " selection

  BUILD_ALL=0
  SELECTED=()
  if [[ -z "${selection// /}" ]]; then
    BUILD_ALL=1
    log "Building ALL templates in catalog (standard defaults + ubuntu)"
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
    # dedupe
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
    log "source add selected: $NEEDED_CSV"
    set +e
    ludus source add "$bsl" --templates "$NEEDED_CSV"
    rc=$?
    [[ $rc -eq 0 ]] || ludus source add "$BSL_URL" --templates "$NEEDED_CSV"
    rc=$?
    set -e
    [[ $rc -eq 0 ]] || die "source add failed for selection"
  fi

  ludus templates list

  # Packer DHCP — restart dnsmasq before builds
  if systemctl list-unit-files dnsmasq.service >/dev/null 2>&1; then
    log "systemctl restart dnsmasq (Packer DHCP)"
    systemctl restart dnsmasq
    systemctl is-active --quiet dnsmasq || die "dnsmasq failed to start — fix before building templates"
  else
    log "dnsmasq.service not found — skipping restart"
  fi

  if [[ "$BUILD_ALL" -eq 1 ]]; then
    log "ludus templates build (all)"
    if (( PARALLEL > 1 )); then
      ludus templates build --parallel "$PARALLEL"
    else
      ludus templates build
    fi
  else
    NEEDED_CSV="$(IFS=,; echo "${SELECTED[*]}")"
    log "ludus templates build -n $NEEDED_CSV"
    if (( PARALLEL > 1 )); then
      ludus templates build -n "$NEEDED_CSV" --parallel "$PARALLEL"
    else
      ludus templates build -n "$NEEDED_CSV"
    fi
  fi

  echo
  echo "Watch: ludus templates logs -f"
  echo "If a build hangs on DHCP/SSH: ludus templates abort ; systemctl restart dnsmasq ; rebuild that template"
  echo "When needed templates show BUILT/TRUE, run: ./setup-wittenberg.sh --deploy"
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
