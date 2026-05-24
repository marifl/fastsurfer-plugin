#!/usr/bin/env bash
# update.sh — Update des fastsurfer-plugin auf neueste Version
#
# Holt Repo-Aenderungen (git pull falls Remote vorhanden), refresht den
# Marketplace und updated das Plugin via claude CLI.
#
# Usage:
#   bash update.sh                # Standard-Update
#   bash update.sh --no-pull      # Skip git pull
#   bash update.sh --force        # Skip Confirmations
#   bash update.sh --help

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="fastsurfer"
MARKETPLACE_NAME="fastsurfer-dev"
DO_PULL=1
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pull) DO_PULL=0; shift ;;
    --force)   FORCE=1;   shift ;;
    --help|-h) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unbekannte Option: $1" >&2; exit 2 ;;
  esac
done

log()  { printf '\033[1;34m[update]\033[0m %s\n' "$*"; }
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
  err "claude CLI nicht im PATH."; exit 1
fi
ok "claude CLI: $(claude --version 2>&1 | head -1)"

cd "$PLUGIN_DIR"

# ---------- Git Pull (optional) ----------
if [[ $DO_PULL -eq 1 ]]; then
  if [[ ! -d .git ]]; then
    warn "Kein git-Repo in $PLUGIN_DIR — skip pull"
  else
    if ! git remote -v | grep -q .; then
      warn "Kein Remote konfiguriert — skip pull"
    else
      log "git pull"
      if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "Working tree hat uncommitted Changes."
        if ! confirm "Trotzdem 'git pull' versuchen?"; then
          err "Abgebrochen. Erst committen/stashen, dann erneut."
          exit 1
        fi
      fi
      git pull --ff-only
      ok "git pull abgeschlossen"
      log "Aktuelles HEAD: $(git log --oneline -1)"
    fi
  fi
fi

# ---------- Validation ----------
log "Validiere Plugin- und Marketplace-Manifeste"
if ! claude plugin validate "$PLUGIN_DIR" 2>&1 | tee /tmp/fastsurfer-plugin-validate.log; then
  err "Validation fehlgeschlagen — siehe Output oben."
  exit 1
fi
ok "Manifeste valide"

# ---------- Marketplace + Plugin Update ----------
log "Refresh Marketplace via 'claude plugin marketplace update $MARKETPLACE_NAME'"
if claude plugin marketplace list 2>/dev/null | grep -qE "^[[:space:]]*${MARKETPLACE_NAME}[[:space:]]"; then
  claude plugin marketplace update "$MARKETPLACE_NAME"
  ok "Marketplace aktualisiert"
else
  warn "Marketplace '$MARKETPLACE_NAME' ist nicht registriert."
  if confirm "Jetzt registrieren?"; then
    claude plugin marketplace add "$PLUGIN_DIR"
    ok "Marketplace registriert"
  else
    err "Update ohne registrierten Marketplace nicht moeglich. Erst install.sh laufen lassen."
    exit 1
  fi
fi

log "Update Plugin via 'claude plugin update $PLUGIN_NAME'"
if claude plugin list 2>/dev/null | grep -qE "^[[:space:]]*${PLUGIN_NAME}[[:space:]]"; then
  claude plugin update "$PLUGIN_NAME"
  ok "Plugin aktualisiert"
else
  warn "Plugin '$PLUGIN_NAME' ist nicht installiert."
  if confirm "Jetzt installieren?"; then
    claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}"
    ok "Plugin installiert"
  else
    err "Abgebrochen."
    exit 1
  fi
fi

# ---------- Verify ----------
log "Verifiziere Installation"
echo ""
echo "=== Installed Plugins ==="
claude plugin list 2>&1 | grep -E "fastsurfer|^$" | head -20 || claude plugin list 2>&1 | head -20
echo ""

ok "Update abgeschlossen."
echo ""
echo "Naechste Schritte:"
echo "  1. In einer laufenden Claude-Code-Session: /reload-plugins"
echo "     ODER: Claude Code neu starten."
echo "  2. Pruefe ob neue Skills/Commands verfuegbar."
