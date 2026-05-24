#!/usr/bin/env bash
# update.sh — Update des fastsurfer-plugin auf neueste Version
#
# Holt Repo-Aenderungen (git pull falls Remote vorhanden), bumped die
# Plugin-Version in plugin.json + marketplace.json (sonst ignoriert
# Claude Code Cache-Updates!), commited den Bump optional, refresht
# den Marketplace und updated das Plugin via claude CLI.
#
# Usage:
#   bash update.sh                    # patch-bump (0.1.0 -> 0.1.1)
#   bash update.sh --bump minor       # 0.1.0 -> 0.2.0
#   bash update.sh --bump major       # 0.1.0 -> 1.0.0
#   bash update.sh --version 0.5.0    # exakte Version setzen
#   bash update.sh --no-bump          # Skip Version-Bump (z.B. wenn schon manuell gemacht)
#   bash update.sh --no-pull          # Skip git pull
#   bash update.sh --no-commit        # Skip auto-commit des Bumps
#   bash update.sh --tag              # Zusaetzlich git-Tag v<version> setzen
#   bash update.sh --force            # Skip Confirmations
#   bash update.sh --help

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="fastsurfer"
MARKETPLACE_NAME="fastsurfer-dev"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$PLUGIN_DIR/.claude-plugin/marketplace.json"

DO_PULL=1
DO_BUMP=1
DO_COMMIT=1
DO_TAG=0
FORCE=0
BUMP_TYPE="patch"
EXACT_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bump)
      BUMP_TYPE="$2"
      shift 2
      ;;
    --version)
      EXACT_VERSION="$2"
      shift 2
      ;;
    --no-bump)   DO_BUMP=0;   shift ;;
    --no-pull)   DO_PULL=0;   shift ;;
    --no-commit) DO_COMMIT=0; shift ;;
    --tag)       DO_TAG=1;    shift ;;
    --force)     FORCE=1;     shift ;;
    --help|-h)   sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unbekannte Option: $1" >&2; exit 2 ;;
  esac
done

case "$BUMP_TYPE" in
  major|minor|patch) ;;
  *)
    echo "FEHLER: --bump muss major|minor|patch sein (war: $BUMP_TYPE)" >&2
    exit 2
    ;;
esac

# ---------- Helpers ----------
log()  { printf '\033[1;34m[update]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

confirm() {
  [[ $FORCE -eq 1 ]] && return 0
  read -r -p "$1 [y/N] " ans
  [[ "$ans" =~ ^[yY]$ ]]
}

read_version() {
  python3 -c "import json; print(json.load(open('$1'))['version'])"
}

write_version() {
  # write_version <file> <new_version>
  python3 - "$1" "$2" <<'PY'
import json, sys
path, new_version = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
data['version'] = new_version
# Wenn marketplace.json: auch in plugins[0].version
if 'plugins' in data and isinstance(data['plugins'], list):
    for plugin in data['plugins']:
        if plugin.get('name') == 'fastsurfer':
            plugin['version'] = new_version
with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
PY
}

bump_version() {
  # bump_version <current> <bump_type>  -> echoes new version
  python3 - "$1" "$2" <<'PY'
import sys, re
current, bump_type = sys.argv[1], sys.argv[2]
m = re.match(r'^(\d+)\.(\d+)\.(\d+)(.*)$', current)
if not m:
    print(f"FEHLER: Version '{current}' folgt nicht SemVer X.Y.Z", file=sys.stderr)
    sys.exit(1)
major, minor, patch = int(m.group(1)), int(m.group(2)), int(m.group(3))
if bump_type == 'major':
    major, minor, patch = major + 1, 0, 0
elif bump_type == 'minor':
    minor, patch = minor + 1, 0
else:  # patch
    patch += 1
print(f"{major}.{minor}.{patch}")
PY
}

# ---------- Pre-Flight ----------
if ! command -v claude >/dev/null 2>&1; then
  err "claude CLI nicht im PATH."; exit 1
fi
ok "claude CLI: $(claude --version 2>&1 | head -1)"

if ! command -v python3 >/dev/null 2>&1; then
  err "python3 nicht im PATH (fuer Version-Bump benoetigt)."; exit 1
fi

[[ -f "$PLUGIN_JSON" ]]      || { err "$PLUGIN_JSON fehlt"; exit 1; }
[[ -f "$MARKETPLACE_JSON" ]] || { err "$MARKETPLACE_JSON fehlt"; exit 1; }

cd "$PLUGIN_DIR"

# ---------- Git Pull (optional) ----------
if [[ $DO_PULL -eq 1 ]]; then
  if [[ ! -d .git ]]; then
    warn "Kein git-Repo in $PLUGIN_DIR — skip pull"
  elif ! git remote -v | grep -q .; then
    warn "Kein Remote konfiguriert — skip pull"
  else
    log "git pull --ff-only"
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

# ---------- Version-Bump ----------
CURRENT_VERSION="$(read_version "$PLUGIN_JSON")"
MARKETPLACE_VERSION_PLUGIN="$(python3 -c "import json; data=json.load(open('$MARKETPLACE_JSON')); print(next((p['version'] for p in data.get('plugins',[]) if p.get('name')=='$PLUGIN_NAME' and 'version' in p), '<none>'))")"

log "Aktuelle plugin.json Version:               $CURRENT_VERSION"
log "Aktuelle marketplace.json (plugin entry):  $MARKETPLACE_VERSION_PLUGIN"

if [[ "$CURRENT_VERSION" != "$MARKETPLACE_VERSION_PLUGIN" ]] && [[ "$MARKETPLACE_VERSION_PLUGIN" != "<none>" ]]; then
  warn "Versions in plugin.json und marketplace.json sind nicht sync!"
  warn "  plugin.json:      $CURRENT_VERSION"
  warn "  marketplace.json: $MARKETPLACE_VERSION_PLUGIN"
  warn "Wird jetzt synchronisiert."
fi

if [[ $DO_BUMP -eq 1 ]]; then
  if [[ -n "$EXACT_VERSION" ]]; then
    NEW_VERSION="$EXACT_VERSION"
    log "Setze Version exakt auf: $NEW_VERSION"
  else
    NEW_VERSION="$(bump_version "$CURRENT_VERSION" "$BUMP_TYPE")"
    log "Bump ($BUMP_TYPE):  $CURRENT_VERSION -> $NEW_VERSION"
  fi

  if confirm "Version-Bump durchfuehren?"; then
    write_version "$PLUGIN_JSON" "$NEW_VERSION"
    write_version "$MARKETPLACE_JSON" "$NEW_VERSION"
    ok "Version in plugin.json + marketplace.json gesetzt auf $NEW_VERSION"
  else
    warn "Version-Bump skipped. Achtung: Claude Code ignoriert ggf. den Cache!"
    NEW_VERSION="$CURRENT_VERSION"
  fi
else
  NEW_VERSION="$CURRENT_VERSION"
  warn "--no-bump aktiv. Verbleibe auf Version $NEW_VERSION."
  warn "Cache-Refresh ist nicht garantiert — Claude erkennt Plugin-Aenderungen meist nur bei Versions-Bump."
fi

# ---------- Validation ----------
log "Validiere Plugin- und Marketplace-Manifeste"
if ! claude plugin validate "$PLUGIN_DIR" 2>&1 | tee /tmp/fastsurfer-plugin-validate.log; then
  err "Validation fehlgeschlagen — siehe Output oben."
  exit 1
fi
ok "Manifeste valide"

# ---------- Auto-Commit + Tag ----------
if [[ $DO_BUMP -eq 1 ]] && [[ $DO_COMMIT -eq 1 ]] && [[ -d .git ]]; then
  if ! git diff --quiet "$PLUGIN_JSON" "$MARKETPLACE_JSON"; then
    log "Commit Version-Bump"
    if confirm "git add + commit der Version-Bump-Aenderungen?"; then
      git add "$PLUGIN_JSON" "$MARKETPLACE_JSON"
      git -c user.email="$(git config user.email || echo plugin@local)" \
          -c user.name="$(git config user.name || echo "fastsurfer-plugin updater")" \
          commit -m "chore(release): bump version to $NEW_VERSION"
      ok "Commit erstellt: $(git log --oneline -1)"

      if [[ $DO_TAG -eq 1 ]]; then
        TAG="v$NEW_VERSION"
        if git rev-parse "$TAG" >/dev/null 2>&1; then
          warn "Tag $TAG existiert bereits — skip"
        else
          git tag "$TAG"
          ok "Tag $TAG gesetzt"
        fi
      fi
    fi
  else
    log "Keine Aenderungen an plugin.json/marketplace.json (Version war schon $NEW_VERSION)"
  fi
fi

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
  ok "Plugin aktualisiert auf Version $NEW_VERSION"
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
echo "=== Plugin Details ==="
claude plugin details "$PLUGIN_NAME" 2>&1 | head -10 || true
echo ""

ok "Update auf Version $NEW_VERSION abgeschlossen."
echo ""
echo "Naechste Schritte:"
echo "  1. In einer laufenden Claude-Code-Session: /reload-plugins"
echo "     ODER: Claude Code neu starten."
echo "  2. Pruefe ob neue Skills/Commands verfuegbar."
if [[ $DO_TAG -eq 0 ]] && [[ $DO_BUMP -eq 1 ]]; then
  echo "  3. (optional) Tag setzen: git -C $PLUGIN_DIR tag v$NEW_VERSION"
fi
