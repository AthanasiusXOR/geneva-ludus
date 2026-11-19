#!/usr/bin/env bash
# Install every Packer template from Ludus sources, then kick off builds.
#
# Ludus 2.2+ replaced `ludus templates add -d ...` with Sources.
# This script does the new flow: source add --all → templates build.
#
# Usage (on a machine with the Ludus CLI + API key):
#   export LUDUS_API_KEY='YOUR-KEY'   # leading space keeps it out of shell history
#   ./install-all-templates.sh
#   ./install-all-templates.sh --parallel 2
#   ./install-all-templates.sh --community
#   ./install-all-templates.sh --install-only   # skip the Packer build step
#   ./install-all-templates.sh --build-only     # skip source install; just build

set -euo pipefail

PARALLEL=1
WITH_COMMUNITY=0
INSTALL_ONLY=0
BUILD_ONLY=0
FORCE=0

BSL_URL="https://github.com/badsectorlabs/ludus-source-bsl"
COMMUNITY_URL="https://github.com/badsectorlabs/ludus-source-community"

usage() {
  cat <<'EOF'
Install all Ludus templates from official (and optional community) sources.

Options:
  --parallel N      Build N templates at once (default: 1). Needs strong hardware.
  --community       Also register + install ludus-source-community
  --install-only    Register/install templates only; do not build images
  --build-only      Skip source install; build every already-installed template
  --force           Pass --force to source add (overwrite installed templates)
  -h, --help        Show this help

Requires:
  - Ludus CLI on PATH
  - LUDUS_API_KEY set (from `ludus-install-status` as root, or `ludus user apikey`)
EOF
}

log()  { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die()  { printf '[x] %s\n' "$*" >&2; exit 1; }

need_cli() {
  command -v ludus >/dev/null 2>&1 || die "ludus CLI not found on PATH"
  [[ -n "${LUDUS_API_KEY:-}" ]] || die "Set LUDUS_API_KEY first (ludus-install-status as root)"
}

# Prefer an already-registered BSL sourceID; fall back to the public URL.
find_bsl_source() {
  local list
  list="$(ludus source list 2>/dev/null || true)"
  if grep -Eqi 'ludus-source-bsl|badsectorlabs-ludus-source-bsl' <<<"$list"; then
    # Prefer short id when present (ROOT auto-register), else first matching id.
    if grep -Eow 'ludus-source-bsl' <<<"$list" >/dev/null; then
      printf '%s\n' 'ludus-source-bsl'
      return
    fi
    # Column layouts vary; grab the first token that looks like a BSL source id.
    awk '
      /ludus-source-bsl|badsectorlabs-ludus-source-bsl/ {
        for (i = 1; i <= NF; i++) {
          if ($i ~ /ludus-source-bsl|badsectorlabs-ludus-source-bsl/) {
            gsub(/[|+]/, "", $i)
            print $i
            exit
          }
        }
      }
    ' <<<"$list"
    return
  fi
  printf '%s\n' "$BSL_URL"
}

install_source_all() {
  local target="$1"
  local -a args=(source add "$target" --all)
  if (( FORCE )); then
    args+=(--force)
  fi
  log "Installing everything from: $target"
  ludus "${args[@]}"
}

build_all() {
  log "Starting Packer builds for every installed template (parallel=$PARALLEL)"
  warn "This can take hours and needs a lot of disk. Follow with: ludus templates logs -f"
  if (( PARALLEL > 1 )); then
    ludus templates build --parallel "$PARALLEL"
  else
    ludus templates build
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --parallel)
      [[ $# -ge 2 ]] || die "--parallel needs a number"
      PARALLEL="$2"
      shift 2
      ;;
    --community) WITH_COMMUNITY=1; shift ;;
    --install-only) INSTALL_ONLY=1; shift ;;
    --build-only) BUILD_ONLY=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

need_cli

if (( INSTALL_ONLY && BUILD_ONLY )); then
  die "Use only one of --install-only / --build-only"
fi

log "Current sources:"
ludus source list || true
echo

if (( ! BUILD_ONLY )); then
  bsl_target="$(find_bsl_source)"
  install_source_all "$bsl_target"

  if (( WITH_COMMUNITY )); then
    install_source_all "$COMMUNITY_URL"
  fi

  log "Installed templates (built or not):"
  ludus templates list || true
  echo
fi

if (( ! INSTALL_ONLY )); then
  build_all
  log "Build kicked off. Monitor with:"
  echo "  ludus templates logs -f"
  echo "  ludus templates status"
  echo "  ludus templates list"
fi

log "Done."
