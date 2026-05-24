#!/usr/bin/env bash
# uninstall.sh — entfernt das fastsurfer-plugin sauber
#
# Symmetrisch zu install.sh. Nutzt ausschliesslich die offizielle
# `claude plugin` CLI - kein manuelles Editieren von settings.json.
#
# Usage:
#   bash uninstall.sh                # interaktiv mit Confirmations
#   bash uninstall.sh --force        # ohne Confirmations
#   bash uninstall.sh --keep-marketplace  # nur Plugin, Marketplace behalten
#   bash uninstall.sh --purge-cache  # zusaetzlich ~/.claude/plugins/cache/fastsurfer* loeschen
#   bash uninstall.sh --help

set -euo pipefail

PLUGIN_NAME="fastsurfer"
MARKETPLACE_NAME="fastsurfer-dev"
KEEP_MARKETPLACE=0
PURGE_CACHE=0
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-marketplace) KEEP_MARKETPLACE=1; shift ;;
    --purge-cache)      PURGE_CACHE=1;      shift ;;
    --force)            FORCE=1;            shift ;;
    --help|-h)          sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "Unbekannte Option: $1" >&2; exit 2 ;;
  esac
done

log()  { printf '\033[1;34m[uninstall]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

confirm() {
  [[ $FORCE -eq 1 ]] && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[yY]$ ]]
}

# ---------- Pre-Flight ----------
if ! command -v claude >/dev/null 2>&1; then
  err "claude CLI nicht im PATH."
  exit 1
fi
ok "claude CLI: $(claude --version 2>&1 | head -1)"

# ---------- Status ----------
log "Aktueller Status:"
PLUGIN_INSTALLED=0
MARKETPLACE_REGISTERED=0

if claude plugin list 2>/dev/null | grep -qE "^[[:space:]]*${PLUGIN_NAME}[[:space:]]"; then
  PLUGIN_INSTALLED=1
  echo "  Plugin '$PLUGIN_NAME':       installiert"
else
  echo "  Plugin '$PLUGIN_NAME':       nicht installiert"
fi

if claude plugin marketplace list 2>/dev/null | grep -qE "^[[:space:]]*${MARKETPLACE_NAME}[[:space:]]"; then
  MARKETPLACE_REGISTERED=1
  echo "  Marketplace '$MARKETPLACE_NAME': registriert"
else
  echo "  Marketplace '$MARKETPLACE_NAME': nicht registriert"
fi

if [[ $PLUGIN_INSTALLED -eq 0 ]] && [[ $MARKETPLACE_REGISTERED -eq 0 ]] && [[ $PURGE_CACHE -eq 0 ]]; then
  ok "Nichts zu tun — Plugin und Marketplace sind bereits entfernt."
  exit 0
fi

# ---------- Plugin uninstall ----------
if [[ $PLUGIN_INSTALLED -eq 1 ]]; then
  if confirm "Plugin '$PLUGIN_NAME' deinstallieren?"; then
    log "claude plugin uninstall $PLUGIN_NAME"
    claude plugin uninstall "$PLUGIN_NAME"
    ok "Plugin '$PLUGIN_NAME' deinstalliert"
  else
    warn "Plugin-Uninstall skipped"
  fi
fi

# ---------- Marketplace remove ----------
if [[ $MARKETPLACE_REGISTERED -eq 1 ]] && [[ $KEEP_MARKETPLACE -eq 0 ]]; then
  if confirm "Marketplace '$MARKETPLACE_NAME' entfernen?"; then
    log "claude plugin marketplace remove $MARKETPLACE_NAME"
    claude plugin marketplace remove "$MARKETPLACE_NAME"
    ok "Marketplace '$MARKETPLACE_NAME' entfernt"
  else
    warn "Marketplace-Remove skipped"
  fi
elif [[ $KEEP_MARKETPLACE -eq 1 ]]; then
  log "--keep-marketplace gesetzt — Marketplace bleibt registriert"
fi

# ---------- Cache purge (optional) ----------
if [[ $PURGE_CACHE -eq 1 ]]; then
  CACHE_DIRS=(
    "$HOME/.claude/plugins/cache/${MARKETPLACE_NAME}"
    "$HOME/.claude/plugins/cache/${PLUGIN_NAME}"
  )
  for cache_dir in "${CACHE_DIRS[@]}"; do
    if [[ -d "$cache_dir" ]]; then
      if confirm "Cache loeschen: $cache_dir"; then
        rm -rf "$cache_dir"
        ok "Cache geloescht: $cache_dir"
      fi
    fi
  done
fi

# ---------- Verify ----------
log "Verifiziere Cleanup"
echo ""
echo "=== Installed Plugins ==="
claude plugin list 2>&1 | head -20 || true
echo ""

ok "Uninstall abgeschlossen."
echo ""
echo "Naechste Schritte:"
echo "  1. In Claude Code: /reload-plugins (oder neu starten)"
echo "  2. Plugin-Repo unter $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) bleibt unangetastet."
echo "     Loeschen falls gewuenscht: rm -rf $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "  3. Re-Install jederzeit moeglich: bash install.sh"
