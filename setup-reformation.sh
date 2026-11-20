#!/usr/bin/env bash
# Setup Ludus on host "reformation" + build only the templates needed for
# Wittenberg (implant range) and Geneva (Ollama range).
#
# Run this ON reformation (the Ludus host), not from your laptop alone —
# Packer builds execute on the Ludus server.
#
# Usage:
#   chmod +x setup-reformation.sh
#   sudo ./setup-reformation.sh              # full: check install → templates → users
#   sudo ./setup-reformation.sh --install    # print/run Ludus installer only
#   ./setup-reformation.sh --templates      # install+build templates (needs LUDUS_API_KEY)
#   ./setup-reformation.sh --users          # create WITTENBERG + GENEVA users
#   ./setup-reformation.sh --templates --parallel 2
#
set -euo pipefail

PARALLEL=1
DO_INSTALL=0
DO_TEMPLATES=0
DO_USERS=0
DO_ALL=1

BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"

# Templates required by wittenberg/range.yml + geneva/range.yml
NEEDED_TEMPLATES=(
  debian-13-x64-server-template
  win2022-server-x64-template
  win11-22h2-x64-enterprise-template
  ubuntu-22.04-x64-server-template
  kali-x64-desktop-template
)

# ubuntu-22.04 is usually NOT in the default built-in set — pull from BSL source
BSL_TEMPLATES=(
  ubuntu-22.04-x64-server-template
)

log()  { printf '\n[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die()  { printf '[x] %s\n' "$*" >&2; exit 1; }

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) DO_INSTALL=1; DO_ALL=0; shift ;;
    --templates) DO_TEMPLATES=1; DO_ALL=0; shift ;;
    --users) DO_USERS=1; DO_ALL=0; shift ;;
    --parallel)
      [[ $# -ge 2 ]] || die "--parallel needs a number"
      PARALLEL="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

if (( DO_ALL )); then
  DO_INSTALL=1
  DO_TEMPLATES=1
  DO_USERS=1
fi

need_api_key() {
  [[ -n "${LUDUS_API_KEY:-}" ]] || die "Set LUDUS_API_KEY first.
  As root on reformation:  ludus-install-status
  Then:   export LUDUS_API_KEY='…'   # leading space keeps it out of history"
  command -v ludus >/dev/null 2>&1 || die "ludus CLI not on PATH"
}

# ─── 1. Install Ludus ────────────────────────────────────────────────────────
phase_install() {
  log "=== Ludus install (host: reformation) ==="

  if command -v ludus >/dev/null 2>&1 && [[ -f /opt/ludus/config.yml ]]; then
    log "Ludus already looks installed (/opt/ludus/config.yml present)."
    if [[ -x /usr/local/bin/ludus-install-status ]] || command -v ludus-install-status >/dev/null 2>&1; then
      ludus-install-status || true
    fi
    return 0
  fi

  warn "Ludus is NOT installed yet. It will take over this machine (Proxmox + Ludus)."
  warn "Requirements: dedicated Debian 12/13 host, nested virt if VM, lots of disk, ~60GB+ RAM."
  warn "Interactive installer — answer prompts carefully; set node name to 'reformation'."

  if [[ "$(id -u)" -ne 0 ]]; then
    die "Ludus install must run as root (sudo -i)"
  fi

  apt-get update
  apt-get install -y curl sudo ca-certificates jq

  log "Starting official installer…"
  curl --proto '=https' --tlsv1.2 -sSf https://ludus.cloud/install | bash

  log "If the host rebooted, SSH back in as root and run: ludus-install-status"
  log "When install finishes, copy the admin/ROOT API key, then re-run:"
  log "  export LUDUS_API_KEY='…'"
  log "  $0 --templates --users"
}

# ─── 2. Templates ────────────────────────────────────────────────────────────
find_bsl_source() {
  local list
  list="$(ludus source list 2>/dev/null || true)"
  if grep -Eqi 'ludus-source-bsl|badsectorlabs-ludus-source-bsl' <<<"$list"; then
    if grep -Eow 'ludus-source-bsl' <<<"$list" >/dev/null; then
      printf '%s\n' 'ludus-source-bsl'
      return
    fi
    awk '
      /ludus-source-bsl|badsectorlabs-ludus-source-bsl/ {
        for (i = 1; i <= NF; i++) {
          if ($i ~ /ludus-source-bsl|badsectorlabs-ludus-source-bsl/) {
            gsub(/[|+]/, "", $i); print $i; exit
          }
        }
      }' <<<"$list"
    return
  fi
  printf '%s\n' "$BSL_URL"
}

phase_templates() {
  log "=== Templates for Wittenberg + Geneva ==="
  need_api_key

  log "Current template status:"
  ludus templates list || true

  local bsl
  bsl="$(find_bsl_source)"
  log "Installing BSL templates (ubuntu-22.04 + any missing): $bsl"
  # Comma-separated list for --templates
  local joined
  joined="$(IFS=,; echo "${BSL_TEMPLATES[*]}")"
  ludus source add "$bsl" --templates "$joined" || {
    warn "source add with specific templates failed; trying --all for BSL (safe, additive)"
    ludus source add "$bsl" --all
  }

  log "Installed catalog:"
  ludus templates list || true

  local missing=()
  local built_list
  built_list="$(ludus templates list 2>/dev/null || true)"
  local t
  for t in "${NEEDED_TEMPLATES[@]}"; do
    if ! grep -q "$t" <<<"$built_list"; then
      missing+=("$t")
    fi
  done
  if ((${#missing[@]})); then
    warn "These templates are not in 'ludus templates list' yet: ${missing[*]}"
    warn "Install them from the BSL source catalog, e.g.:"
    warn "  ludus source add $bsl --templates ${missing[0]}"
    warn "Or: ludus source add $bsl --all"
  fi

  local names
  names="$(IFS=,; echo "${NEEDED_TEMPLATES[*]}")"
  log "Building ONLY required templates: $names"
  warn "This takes hours. Follow with: ludus templates logs -f"
  warn "Abort a stuck build with: ludus templates abort"

  if (( PARALLEL > 1 )); then
    ludus templates build -n "$names" --parallel "$PARALLEL"
  else
    ludus templates build -n "$names"
  fi

  log "Build kicked off. Monitor:"
  echo "  ludus templates logs -f"
  echo "  ludus templates status"
  echo "  ludus templates list"
}

# ─── 3. Range users ──────────────────────────────────────────────────────────
phase_users() {
  log "=== Create Wittenberg + Geneva Ludus users ==="
  need_api_key

  if ! ludus user list 2>/dev/null | grep -qw WITTENBERG; then
    log "Creating user WITTENBERG…"
    ludus user add -n 'Wittenberg' -i WITTENBERG
  else
    log "User WITTENBERG already exists"
  fi

  if ! ludus user list 2>/dev/null | grep -qw GENEVA; then
    log "Creating user GENEVA…"
    ludus user add -n 'Geneva' -i GENEVA
  else
    log "User GENEVA already exists"
  fi

  log "Save each user's API key from the output above (shown once)."
  log "Next:"
  echo "  ludus --user WITTENBERG range config set -f wittenberg/range.yml"
  echo "  ludus --user WITTENBERG range deploy"
  echo "  ludus --user GENEVA range config set -f geneva/range.yml"
  echo "  ludus --user GENEVA range deploy"
}

# ─── run ─────────────────────────────────────────────────────────────────────
log "Reformation setup — Wittenberg + Geneva"
echo "  install=$DO_INSTALL templates=$DO_TEMPLATES users=$DO_USERS parallel=$PARALLEL"

(( DO_INSTALL )) && phase_install
(( DO_TEMPLATES )) && phase_templates
(( DO_USERS )) && phase_users

log "Done with requested phases."
