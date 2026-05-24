#!/usr/bin/env bash
# install.sh — automatische Installation des fastsurfer-plugin
#
# Nutzt die offizielle `claude plugin` CLI (Claude Code).
# Editiert KEINE settings.json oder andere System-Files manuell —
# alle Aenderungen laufen ueber die supportete CLI.
#
# Usage:
#   bash install.sh                  # Installiert als user-scope (default)
#   bash install.sh --scope project  # Installiert in .claude/settings.json des aktuellen Repos
#   bash install.sh --scope local    # Installiert in .claude/settings.local.json
#   bash install.sh --force          # Skip Confirmations, ueberschreibt existierende Installation
#   bash install.sh --help

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="fastsurfer"
MARKETPLACE_NAME="fastsurfer-dev"
SCOPE="user"
FORCE=0

# ---------- Arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --help|-h)
      sed -n '2,14p' "$0"
      exit 0
      ;;
    *)
      echo "Unbekannte Option: $1" >&2
      exit 2
      ;;
  esac
done

case "$SCOPE" in
  user|project|local) ;;
  *)
    echo "FEHLER: --scope muss user|project|local sein (war: $SCOPE)" >&2
    exit 2
    ;;
esac

# ---------- Helpers ----------
log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

confirm() {
  [[ $FORCE -eq 1 ]] && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[yY]$ ]]
}

# ---------- Pre-Flight ----------
log "Pre-Flight Checks"

if ! command -v claude >/dev/null 2>&1; then
  err "claude CLI nicht im PATH gefunden."
  err "Install: https://docs.claude.com/en/docs/claude-code/setup"
  exit 1
fi
ok "claude CLI: $(claude --version 2>&1 | head -1)"

if ! command -v git >/dev/null 2>&1; then
  err "git nicht im PATH (wird fuer claude plugin marketplace add benoetigt)."
  exit 1
fi
ok "git: $(git --version)"

if [[ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]] || \
   [[ ! -f "$PLUGIN_DIR/.claude-plugin/marketplace.json" ]]; then
  err "Plugin-Manifeste nicht gefunden in $PLUGIN_DIR/.claude-plugin/"
  err "Erwarte plugin.json + marketplace.json."
  exit 1
fi
ok "Plugin-Manifeste vorhanden in $PLUGIN_DIR"

# ---------- Validation ----------
log "Validiere Plugin- und Marketplace-Manifeste"
if ! claude plugin validate "$PLUGIN_DIR" 2>&1 | tee /tmp/fastsurfer-plugin-validate.log; then
  err "Validation fehlgeschlagen — siehe Output oben."
  exit 1
fi
ok "Manifeste valide"

# ---------- Marketplace add ----------
log "Pruefe ob Marketplace '$MARKETPLACE_NAME' bereits registriert ist"
if claude plugin marketplace list 2>/dev/null | grep -qE "^[[:space:]]*${MARKETPLACE_NAME}[[:space:]]"; then
  warn "Marketplace '$MARKETPLACE_NAME' ist bereits registriert."
  if confirm "Update via 'claude plugin marketplace update $MARKETPLACE_NAME'?"; then
    claude plugin marketplace update "$MARKETPLACE_NAME"
    ok "Marketplace aktualisiert"
  fi
else
  log "Registriere Marketplace via 'claude plugin marketplace add $PLUGIN_DIR --scope $SCOPE'"
  claude plugin marketplace add "$PLUGIN_DIR" --scope "$SCOPE"
  ok "Marketplace '$MARKETPLACE_NAME' registriert (scope=$SCOPE)"
fi

# ---------- Plugin install ----------
log "Pruefe ob Plugin '$PLUGIN_NAME' bereits installiert ist"
if claude plugin list 2>/dev/null | grep -qE "^[[:space:]]*${PLUGIN_NAME}[[:space:]]"; then
  warn "Plugin '$PLUGIN_NAME' ist bereits installiert."
  if confirm "Re-Install via uninstall + install?"; then
    claude plugin uninstall "$PLUGIN_NAME" || true
    claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}" --scope "$SCOPE"
    ok "Plugin re-installiert"
  fi
else
  log "Installiere Plugin via 'claude plugin install ${PLUGIN_NAME}@${MARKETPLACE_NAME} --scope $SCOPE'"
  claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}" --scope "$SCOPE"
  ok "Plugin '$PLUGIN_NAME' installiert"
fi

# ---------- Post-Install Verify ----------
log "Verifiziere Installation"
echo ""
echo "=== Installed Plugins ==="
claude plugin list 2>&1 | grep -E "fastsurfer|^$" | head -20 || claude plugin list 2>&1 | head -20
echo ""
echo "=== Plugin Details ==="
claude plugin details "$PLUGIN_NAME" 2>&1 | head -40 || true

# ---------- Hinweise ----------
echo ""
ok "Installation abgeschlossen."
echo ""
echo "Naechste Schritte:"
echo "  1. In einer laufenden Claude-Code-Session: /reload-plugins"
echo "     ODER: Claude Code neu starten."
echo "  2. Smoke-Test: in Claude Code '/fs-check' eingeben."
echo "  3. Skills + Commands sollten auto-triggern bei FastSurfer-Fragen."
echo ""
echo "Update spaeter: bash update.sh"
echo "Uninstall:     claude plugin uninstall $PLUGIN_NAME"
echo "               claude plugin marketplace remove $MARKETPLACE_NAME"
