# fastsurfer-plugin

> Vollständiges Claude-Code-Plugin für [FastSurfer](https://github.com/Deep-MI/FastSurfer) — die Deep-Learning-basierte Neuroimaging-Pipeline für volumetrische Hirnsegmentierung und Surface-Reconstruction.

Das Plugin verschafft Claude umfassendes operationales Verständnis aller FastSurfer-Komponenten und bietet kuratierte Slash-Commands für die typischen Workflows.

[![Plugin: 16 Skills + 12 Commands](https://img.shields.io/badge/components-16%20skills%20%2B%2012%20commands-blue)](#-components)
[![FastSurfer 2.6.0-dev](https://img.shields.io/badge/fastsurfer-2.6.0--dev-green)](#-versions--kompatibilit%C3%A4t)
[![Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-orange)](LICENSE)

---

## Inhaltsverzeichnis

- [Warum dieses Plugin?](#warum-dieses-plugin)
- [Quick-Start (in 3 Minuten)](#quick-start-in-3-minuten)
- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
- [Update](#update)
- [Uninstall](#uninstall)
- [Components](#-components)
- [Typische Workflows](#typische-workflows)
- [Architektur](#architektur)
- [Versions & Kompatibilität](#-versions--kompatibilit%C3%A4t)
- [Designprinzipien](#designprinzipien)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Entwicklung & Beitragen](#entwicklung--beitragen)
- [Referenzen](#referenzen)
- [Lizenz](#lizenz)

---

## Warum dieses Plugin?

FastSurfer ist mächtig, aber die CLI-Oberfläche, die Output-Struktur und das Conform-Space-Konzept sind tief und voller Fallstricke. Ohne das Plugin muss Claude bei jeder FastSurfer-Frage erst das Repo durchsuchen oder raten.

Mit dem Plugin:

- Claude **erkennt automatisch** FastSurfer-Themen (asegdkt, CerebNet, HypVINN, recon-surf, Conform-Space, tkRAS-Bugs etc.) und greift auf die richtigen Skills zu.
- Slash-Commands wie `/fs-run`, `/fs-quick`, `/fs-batch` liefern **getestete Templates** mit Pre-Flight-Checks und Default-Flags.
- Debug-Skills decken die häufigsten Failure-Modi ab (License-Probleme, GPU-OOM, Frame-Verwechslungen, fehlende Outputs).
- Container- und HPC-Workflows (Docker, Singularity, SLURM) sind first-class — kein OS-Bias.

---

## Quick-Start (in 3 Minuten)

```bash
# 1) Plugin installieren
bash ~/prj/fastsurfer-plugin/install.sh

# 2) Claude Code neu starten oder /reload-plugins

# 3) Setup verifizieren
#    In Claude Code eingeben:
/fs-check
```

Erster echter Run:

```bash
# 4) In Claude Code (mit T1-Image + FreeSurfer-License vorhanden):
/fs-run /abs/path/to/t1.nii.gz subjectX
```

Claude konstruiert den passenden `run_fastsurfer.sh`-Aufruf, führt Pre-Flight-Checks aus (License, Pfade, GPU) und startet die Pipeline. Nach Abschluss:

```bash
/fs-outputs subjectX     # Listet alle erzeugten Files mit Status
/fs-freeview subjectX    # Öffnet FreeView mit sinnvollen Layern
```

Bei Problemen:

```bash
/fs-logs subjectX --errors-only
```

---

## Voraussetzungen

### Pflicht

| Komponente | Version / Hinweis |
|------------|-------------------|
| **Claude Code** | aktuell (`claude --version` zeigt eine Version mit `plugin`-Subcommand) |
| **FastSurfer-Repo** lokal verfügbar | Default-Pfad: `$HOME/prj/fastsurfer` — anpassbar via `$FASTSURFER_HOME` env-var |
| **Git** | für `claude plugin marketplace add` |

### Pflicht für Surface-Pipeline

| Komponente | Version / Hinweis |
|------------|-------------------|
| **FreeSurfer-Lizenz** | kostenlos registrieren: https://surfer.nmr.mgh.harvard.edu/registration.html |
| **FreeSurfer** (native install) | typisch 7.3.x / 7.4.x; oder Docker-Image nutzen (siehe Workflow "Container") |
| **Python 3.10–3.13** | mit FastSurfer-Dependencies (siehe `pyproject.toml` im FastSurfer-Repo) |

### Optional

| Komponente | Wofür |
|------------|-------|
| **CUDA-fähige GPU** | beschleunigt asegdkt + Sub-Modules dramatisch (~5 Min statt ~60 Min) |
| **Docker** | Container-Workflows (`/fs-docker`) |
| **Singularity / Apptainer** | HPC-Workflows |
| **SLURM** | Cluster-Orchestrierung (`/fs-slurm`) |

### Plattform-Hinweise

- **macOS Apple Silicon (M-Serie):** kein CUDA — Inferenz läuft auf CPU (Faktor 3-5× langsamer als RTX 3090). Im Plugin werden entsprechende CPU-Defaults vorgeschlagen.
- **macOS Intel:** GPU-Passthrough in Docker nicht unterstützt; native install oder CPU-Mode.
- **Linux mit NVIDIA-GPU:** Idealfall, alles geht.
- **Windows:** ungetestet; FastSurfer offiziell nur via Docker/WSL2 supportet.

---

## Installation

### Automatisch via `install.sh` (empfohlen)

```bash
cd ~/prj/fastsurfer-plugin
bash install.sh
```

Das Script führt diese Schritte aus:

1. **Pre-Flight Checks** — `claude` CLI verfügbar? `git` verfügbar? Plugin-Manifeste vorhanden?
2. **Validation** — `claude plugin validate <plugin-dir>` prüft `plugin.json` + `marketplace.json` gegen das offizielle Schema.
3. **Marketplace registrieren** — `claude plugin marketplace add <plugin-dir> --scope <user|project|local>`.
4. **Plugin installieren** — `claude plugin install fastsurfer@fastsurfer-dev --scope <scope>`.
5. **Verify** — listet das frisch installierte Plugin + Details.

#### Scope-Optionen

| Scope | Datei (Storage) | Reichweite |
|-------|-----------------|------------|
| `user` (Default) | `~/.claude/settings.json` | Dein Account — cross-project auf dieser Maschine |
| `project` | `<repo>/.claude/settings.json` | Aktuelles Repo, committed in git |
| `local` | `<repo>/.claude/settings.local.json` | Aktuelles Repo, nicht committed (per-Maschine-Override) |

```bash
bash install.sh --scope user      # Default
bash install.sh --scope project   # für ein konkretes Repo, mit git committen
bash install.sh --scope local     # nur diese Maschine, dieses Repo
bash install.sh --force           # Skip Confirmations + re-install bei existierender Installation
bash install.sh --help
```

> **Wichtig:** Das Script editiert **nicht** manuell in `~/.claude/settings.json` oder anderen System-Dateien. Alle Änderungen laufen über die offizielle `claude plugin` CLI.

#### Manuell (alternativ, in einer Claude-Code-Session)

Wenn du das Script nicht nutzen willst:

```
/plugin marketplace add ~/prj/fastsurfer-plugin
/plugin install fastsurfer@fastsurfer-dev
```

Danach `/reload-plugins` oder Claude Code neu starten.

#### Mit `FASTSURFER_HOME` an einem anderen Pfad

Wenn dein FastSurfer-Repo nicht unter `$HOME/prj/fastsurfer` liegt:

```bash
export FASTSURFER_HOME=/path/to/your/fastsurfer
bash install.sh
```

Die Slash-Commands (`/fs-run`, `/fs-seg`, etc.) lesen `$FASTSURFER_HOME` zur Laufzeit; das Plugin selbst ist unabhängig vom FastSurfer-Repo-Pfad.

### Verifikation nach Installation

```
/reload-plugins
/fs-check
```

`/fs-check` führt einen kompletten Setup-Smoke-Test durch (FastSurfer-Repo, Python-Env, GPU, FreeSurfer-Env, License, SUBJECTS_DIR, Disk).

`/plugin` listet alle installierten Plugins — `fastsurfer` sollte aufgeführt sein.

---

## Update

### Automatisch via `update.sh`

```bash
cd ~/prj/fastsurfer-plugin
bash update.sh
```

Das Script:

1. **`git pull --ff-only`** (skip mit `--no-pull` falls kein Remote oder lokale Änderungen).
2. **Version-Bump** in `plugin.json` + `marketplace.json` (Default: `patch`, z.B. `0.1.0 → 0.1.1`). **Kritisch:** ohne Version-Bump ignoriert Claude Code den Plugin-Cache und übernimmt deine Änderungen nicht. Skip mit `--no-bump` (nur wenn du den Bump manuell vorab gemacht hast).
3. **Manifest-Validation** neu (`claude plugin validate`).
4. **Auto-Commit** des Version-Bumps (skip mit `--no-commit`).
5. **`claude plugin marketplace update fastsurfer-dev`** — refresht den Marketplace-Cache.
6. **`claude plugin update fastsurfer`** — updated das Plugin im Cache.
7. **Verify** via `claude plugin list` + `claude plugin details fastsurfer`.

#### Optionen

```bash
bash update.sh                    # Default: patch-bump + auto-commit
bash update.sh --bump minor       # 0.1.0 → 0.2.0
bash update.sh --bump major       # 0.1.0 → 1.0.0
bash update.sh --version 0.5.0    # exakte Version setzen
bash update.sh --no-bump          # Skip Version-Bump
bash update.sh --no-pull          # Skip git pull
bash update.sh --no-commit        # Skip auto-commit
bash update.sh --tag              # Zusätzlich git-Tag v<version> setzen
bash update.sh --force            # Skip Confirmations
bash update.sh --help
```

#### Wann welches `--bump`-Level?

| Änderungstyp | Bump | Beispiel |
|--------------|------|----------|
| Typo-Fix, Skill-Description-Verbesserung, Doku | `patch` (Default) | `0.1.0 → 0.1.1` |
| Neue Skill, neuer Slash-Command | `minor` | `0.1.0 → 0.2.0` |
| Breaking-Change an Command-Argumenten oder Skill-Trigger | `major` | `0.1.0 → 1.0.0` |

Nach Update: `/reload-plugins` in Claude Code oder neu starten.

### Warum ist der Version-Bump wichtig?

Claude Code cached installierte Plugins unter `~/.claude/plugins/cache/`. Beim `claude plugin update` wird der Cache **nur dann** wirklich neu befüllt, wenn die neue Version `> alte Version` ist (SemVer-Vergleich). Ohne Bump ignoriert Claude Code deine Plugin-Änderungen — du wunderst dich, warum neue Skills nicht triggern oder geänderte Commands die alte Version zeigen.

`update.sh` bumped daher per Default, schreibt den neuen Wert in **beide** Manifeste (`plugin.json` + `marketplace.json` müssen sync sein), und commited den Bump optional als saubere Audit-Trail.

### Manuell

```
/plugin marketplace update fastsurfer-dev
/plugin update fastsurfer
```

Manuell solltest du vorher selbst die Version in beiden Manifesten erhöhen, sonst greift der Cache nicht.

---

## Uninstall

```bash
claude plugin uninstall fastsurfer
claude plugin marketplace remove fastsurfer-dev
```

Oder via Slash-Commands in Claude Code:

```
/plugin uninstall fastsurfer
/plugin marketplace remove fastsurfer-dev
```

Das Plugin-Repo unter `~/prj/fastsurfer-plugin/` bleibt unberührt — du kannst es jederzeit erneut installieren.

---

## 🧰 Components

Das Plugin besteht aus zwei Component-Typen:

### Skills (16) — auto-trigger bei passendem Kontext

Skills werden von Claude automatisch geladen, wenn ein Trigger-Wort in der User-Nachricht oder im Kontext erscheint. Du musst sie **nicht** explizit aufrufen.

#### Knowledge-Skills (Fundamentals)

| Skill | Trigger | Inhalt |
|-------|---------|--------|
| `fastsurfer-overview` | "FastSurfer", "asegdkt", "CerebNet", "Pipeline overview" | Modul-Map, Reihenfolge, Default-Flags, Standard-Aufruf |
| `fastsurfer-cli-flags` | jeder konkrete Flag-Name (z.B. `--vox_size`, `--keepgeom`) | Vollständige Flag-Referenz, Wert-Bereiche, Interaktionen, Beispiel-Kombinationen |
| `fastsurfer-outputs` | "FastSurfer output", "aseg.mgz", "lh.pial", "subject directory" | Datei-für-Datei Output-Layout pro Modul, Validation-Snippets |
| `fastsurfer-conform-space` | "conformed", "vox_size", "tkRAS", "scanner-RAS", "LIA orientation" | Conform-Space, vox_size-Semantik, AC/PC-Alignment, Symlink-Trap |
| `fastsurfer-internals` | "FastSurfer source", "where is X implemented", "FastSurferCNN module" | Repo-Layout, "Wo ist X?"-Tabellen, Datenfluss-Diagramm |

#### Module-Skills (Deep-Dive)

| Skill | Trigger | Inhalt |
|-------|---------|--------|
| `fastsurfer-segmentation` | "VINN architecture", "view aggregation", "DKT classes", "soft labels" | Architektur asegdkt + cc + cereb + hypothal, T1+T2-Workflow |
| `fastsurfer-surface-recon` | "recon-surf", "pial surface", "qsphere", "FreeSurfer license" | 11-Step-Pipeline, Algorithmen-Switches, Highres-Mode, Edits |
| `fastsurfer-checkpoints-models` | "checkpoint", "download_checkpoints", "custom training", "ONNX" | Checkpoint-Layout, Custom-Weights via Volume-Mount, Training-Pipeline |

#### Workflow-Skills

| Skill | Trigger | Inhalt |
|-------|---------|--------|
| `fastsurfer-container` | "Docker", "Singularity", "deepmi/fastsurfer", "container GPU" | Docker- + Singularity-Templates, Image-Varianten, Mount-Patterns |
| `fastsurfer-batch-slurm` | "brun_fastsurfer", "subject_list", "FastSurfer SLURM", "parallel" | `brun_fastsurfer.sh` + `srun_fastsurfer.sh`, Parallelisierungs-Strategien |
| `fastsurfer-longitudinal` | "longitudinal", "long_fastsurfer", "template", "time points" | `long_fastsurfer.sh`, Stage-System, Within-Subject-Template-Konzept |
| `fastsurfer-lit` | "lesion_mask", "lesion inpainting", "FastSurfer LIT" | LIT-Pipeline, Lesion-Backup-Schema, Impact-Reports |

#### Debug-Skills (Troubleshooting)

| Skill | Trigger | Inhalt |
|-------|---------|--------|
| `fastsurfer-debug-license` | "FreeSurfer license", "license invalid", "fs_license" | License-Format, Container-Mount-Patterns, häufige Errors |
| `fastsurfer-debug-outputs` | "output missing", "incomplete output", "FastSurfer crashed" | 4-Schritt-Diagnose, Step-Marker im Log, File-Validation |
| `fastsurfer-debug-conform-tkras` | "alignment off", "17.5mm offset", "tkRAS bug", "90° rotation" | 6 Standard-Bugs mit Diagnose-Code, Quick-Test-Script |
| `fastsurfer-debug-gpu-memory` | "CUDA out of memory", "OOM", "GPU not detected", "viewagg" | 4 Strategien gegen OOM, Memory pro Modul, CPU-Only Best-Practices |

### Slash-Commands (12) — explizit aufrufen

| Command | Synopsis | Wofür |
|---------|----------|-------|
| `/fs-run <t1> <sid>` | volle Pipeline (seg + surf) | Standard-Workflow für ein neues Subject |
| `/fs-seg <t1> <sid>` | nur Segmentation (`--seg_only`) | Schnelle Volumetrik, kein FreeSurfer-License nötig |
| `/fs-surf <sid>` | nur Surface (`--surf_only`) | Surface nachholen nach `/fs-seg` |
| `/fs-quick <t1> <sid>` | minimal: nur asegdkt | ~1 Min auf GPU, nur aseg+DKT |
| `/fs-batch <list>` | `brun_fastsurfer.sh` mit Subject-Liste | Multi-Subject parallel |
| `/fs-long <tid> <t1s> <tpids>` | `long_fastsurfer.sh` longitudinal | Multiple Time-Points eines Subjects |
| `/fs-slurm <data> <pattern>` | `srun_fastsurfer.sh` | HPC-Cluster mit GPU+CPU-Partitionen |
| `/fs-docker <t1> <sid>` | Docker-Wrapper | `deepmi/fastsurfer` Image |
| `/fs-check` | Setup-Smoke-Test | FastSurfer + Python + GPU + FreeSurfer + License |
| `/fs-outputs <sid>` | Output-Validation | Tabelle erwarteter Files mit Status |
| `/fs-logs <sid>` | Log-Tail | `deep-seg.log` + `recon-all.log` |
| `/fs-freeview <sid>` | öffne FreeView | `minimal` / `standard` / `full` Presets |

---

## Typische Workflows

### 1. Erster Cross-Sectional-Run auf einer Workstation

```
# In Claude Code:
/fs-check                                          # Setup verifizieren
/fs-run /data/sub01/t1.nii.gz sub01                # Full Pipeline (~60-90 Min auf GPU)
/fs-outputs sub01                                  # Output-Vollständigkeit prüfen
/fs-freeview sub01                                 # Visual-QC
```

Bei Crash:

```
/fs-logs sub01 --errors-only                       # Errors aus beiden Logs extrahieren
# → Claude triggert automatisch passenden Debug-Skill
#   (fastsurfer-debug-license, -outputs, -gpu-memory, -conform-tkras)
```

### 2. Quick aseg+DKT für eine Studie

Wenn du nur Cortex-Parcellation + Subcortex-Volumes brauchst (keine Surfaces, keine Sub-Module):

```
/fs-quick /data/sub01/t1.nii.gz sub01              # ~1 Min auf GPU
```

Output: `mri/aparc.DKTatlas+aseg.deep.mgz` + `stats/aseg+DKT.stats`.

### 3. Batch über 50 Subjects

```bash
# Subject-Liste vorbereiten
cat > /data/subjects.txt <<EOF
sub01=/data/raw/sub01/t1.nii.gz
sub02=/data/raw/sub02/t1.nii.gz
sub03=/data/raw/sub03/t1.nii.gz --vox_size 0.8
EOF
```

```
# In Claude Code:
/fs-batch /data/subjects.txt
```

Claude konstruiert `brun_fastsurfer.sh` mit sinnvollen Parallelisierungs-Defaults (`--parallel_seg 2 --parallel_surf 4`), Status-File, und Verify-Step.

### 4. Longitudinal-Analyse (1 Subject, 3 Zeitpunkte)

```
/fs-long sub01_template \
         /data/sub01_y0.nii.gz,/data/sub01_y1.nii.gz,/data/sub01_y2.nii.gz \
         sub01_y0,sub01_y1,sub01_y2
```

Within-Subject-Template + per-TP Outputs (siehe `fastsurfer-longitudinal` Skill).

### 5. SLURM-Cluster mit 200 Subjects

```
/fs-slurm /data/raw "*/t1.nii.gz"
```

Claude generiert `srun_fastsurfer.sh`-Aufruf mit GPU/CPU-Partitionen, Time-/Memory-Limits, Work-Dir auf NVMe, Singularity-Image. Empfiehlt vor dem echten Submit `--dry --debug`.

### 6. macOS-Workflow (Apple Silicon, kein GPU)

```
# fs-check zeigt: "No GPU - CPU mode only"
/fs-run /data/sub01/t1.nii.gz sub01 --device cpu --viewagg_device cpu --threads max
```

Erwartete Laufzeit auf M-Serie: 3-6h für full Pipeline.

### 7. Debugging: "Outputs sehen verschoben aus"

```
# In Claude Code:
"Mein eigenes Mesh sitzt 17.5mm zu weit anterior gegenüber aseg.mgz"
# → Claude triggert automatisch fastsurfer-debug-conform-tkras
# → liefert Diagnose-Code + Fix (get_vox2ras_tkr statt affine)
```

### 8. Custom-Training auf eigenen Daten

```
"Ich will FastSurferVINN auf meinen pediatric MRI Daten neu trainieren"
# → Claude triggert fastsurfer-checkpoints-models
# → erklärt generate_hdf5 → train.py → run_model.py Workflow
#   inkl. Config-Files und View-spezifischem Training
```

---

## Architektur

### Repo-Layout

```
fastsurfer-plugin/
├── .claude-plugin/
│   ├── plugin.json              Plugin-Manifest (name, version, paths)
│   └── marketplace.json         Dev-Marketplace (für lokale Installation)
├── skills/                      Auto-getriggerte Knowledge + Debug Skills
│   ├── fastsurfer-overview/SKILL.md
│   ├── fastsurfer-cli-flags/SKILL.md
│   ├── fastsurfer-outputs/SKILL.md
│   ├── fastsurfer-conform-space/SKILL.md
│   ├── fastsurfer-internals/SKILL.md
│   ├── fastsurfer-segmentation/SKILL.md
│   ├── fastsurfer-surface-recon/SKILL.md
│   ├── fastsurfer-checkpoints-models/SKILL.md
│   ├── fastsurfer-container/SKILL.md
│   ├── fastsurfer-batch-slurm/SKILL.md
│   ├── fastsurfer-longitudinal/SKILL.md
│   ├── fastsurfer-lit/SKILL.md
│   ├── fastsurfer-debug-license/SKILL.md
│   ├── fastsurfer-debug-outputs/SKILL.md
│   ├── fastsurfer-debug-conform-tkras/SKILL.md
│   └── fastsurfer-debug-gpu-memory/SKILL.md
├── commands/                    Explizit aufrufbare Slash-Commands
│   ├── fs-run.md
│   ├── fs-seg.md
│   ├── fs-surf.md
│   ├── fs-quick.md
│   ├── fs-batch.md
│   ├── fs-long.md
│   ├── fs-slurm.md
│   ├── fs-docker.md
│   ├── fs-check.md
│   ├── fs-outputs.md
│   ├── fs-logs.md
│   └── fs-freeview.md
├── install.sh                   CLI-basierte Auto-Installation
├── update.sh                    CLI-basiertes Auto-Update
├── README.md                    dieses File
├── LICENSE                      Apache-2.0
└── .gitignore
```

### Skill-Format

Jede Skill ist eine SKILL.md mit YAML-Frontmatter:

```yaml
---
name: fastsurfer-conform-space
description: Use when the user asks about FastSurfer voxel space, conformed vs native geometry, `--vox_size`, ...
---

# FastSurfer — Conform-Space, Voxel-Geometrie, tkRAS

[Skill body in Markdown ...]
```

Claude lädt eine Skill nur dann in den Kontext, wenn die User-Nachricht oder der Kontext zu der `description` passt — das schont Context-Window-Budget.

### Slash-Command-Format

Jeder Command ist ein .md-File mit YAML-Frontmatter:

```yaml
---
description: Vollständige FastSurfer-Pipeline starten
allowed-tools: Bash, Read
argument-hint: "<t1_path> <sid> [<extra-flags>]"
---

[Command-Body als Prompt-Template mit $ARGUMENTS]
```

Wenn User `/fs-run /path/t1.nii.gz sub01` schreibt, expandiert Claude den Body und ersetzt `$ARGUMENTS` durch die User-Args.

### Marketplace-Mechanik

Der lokale Dev-Marketplace `marketplace.json` deklariert das Plugin als `source: "./"` (= dieses Verzeichnis). `claude plugin install fastsurfer@fastsurfer-dev` legt einen Eintrag in `~/.claude/settings.json` (oder `.claude/settings.json` je nach Scope) an und cached das Plugin unter `~/.claude/plugins/cache/`.

---

## 🔢 Versions & Kompatibilität

| Komponente | Getestet mit | Notizen |
|------------|--------------|---------|
| **fastsurfer-plugin** | 0.1.0 | initial release |
| **Claude Code** | aktuell mit `plugin`-CLI | erfordert moderne Version |
| **FastSurfer** | 2.6.0-dev (Commit `30497c6`) | ältere 2.x-Versionen kompatibel; 1.x nicht getestet |
| **FreeSurfer** | 7.3.x / 7.4.x | für Surface-Pipeline |
| **Python** | 3.10 / 3.11 / 3.12 / 3.13 | FastSurfer-Constraint |
| **PyTorch** | 2.x mit CUDA 11.8 / 12.x | für GPU-Inferenz |
| **macOS** | 13+ (Apple Silicon getestet) | CPU-only |
| **Linux** | Ubuntu 20.04 / 22.04 / 24.04 | offiziell von FastSurfer supportet |

### Bei FastSurfer-Updates

Wenn FastSurfer in einer neuen Version Flags ändert oder neue Module hinzufügt: erstelle ein Issue oder PR. Skills sind versioned gegen die jeweils aktuell verifizierte FastSurfer-Version (siehe `description`-Felder).

---

## Designprinzipien

1. **Vollständigkeit über Knappheit.** Skills decken die volle FastSurfer-CLI- und Code-Fläche ab, nicht nur Happy-Paths. Edge-Cases, Failure-Modi und obskure Flags sind dokumentiert.
2. **Code-Modifikations-Tiefe.** Skills referenzieren konkrete Module unter `FastSurferCNN/`, `CerebNet/`, `HypVINN/`, `CorpusCallosum/`, `recon_surf/` und `tools/`, sodass Claude beim Forken oder Patchen direkt weiss, wo zu schauen ist.
3. **Container + Native + HPC parallel.** Kein OS-Bias — gleiche Konzepte über Docker, Singularity, native und SLURM.
4. **Verifizierbarkeit.** Jedes Output-, Flag- und Pfad-Statement ist gegen FastSurfer 2.6.0-dev Repo-Quelle geprüft (siehe Git-Log).
5. **Evidence-First Debugging.** Debug-Skills geben **konkreten Diagnose-Code** mit konkreten erwarteten Output-Patterns, nicht nur abstrakte Tipps.
6. **Keine System-File-Bastelei.** Install/Update läuft ausschliesslich über die offizielle `claude plugin` CLI — kein `cat >> ~/.claude/settings.json` oder ähnliches.

---

## Troubleshooting

### Install / Update

#### `install.sh` schlägt fehl mit "claude CLI nicht im PATH"

```bash
which claude
# → /opt/homebrew/bin/claude  (macOS) oder /usr/local/bin/claude (Linux)
```

Wenn leer: Claude Code ist nicht im PATH. Reinstall via `npm install -g @anthropic-ai/claude-code` oder über die offizielle Install-Methode (https://docs.claude.com/en/docs/claude-code/setup).

#### `claude plugin validate` schlägt fehl

Symptom: `install.sh` bricht im Validation-Step ab.

```bash
claude plugin validate ~/prj/fastsurfer-plugin
```

zeigt die Detail-Fehler. Häufige Ursachen:
- Manuell editierte `marketplace.json` ohne Pflichtfelder.
- Skill-Frontmatter ohne `name:` oder `description:`.

#### Marketplace `fastsurfer-dev` already exists

Du hast den Marketplace bereits einmal registriert. `install.sh` erkennt das und fragt vor Re-Install. Mit `--force` einfach überschreiben:

```bash
bash install.sh --force
```

#### `git pull` failed mit "uncommitted changes"

Du hast lokal das Plugin-Repo modifiziert (z.B. eigene Skills hinzugefügt). `update.sh` fragt nach Bestätigung. Optionen:

```bash
bash update.sh --no-pull    # nur Plugin-CLI-Update, kein git pull
# ODER
cd ~/prj/fastsurfer-plugin && git stash && bash update.sh
```

### Runtime

#### Slash-Commands erscheinen nach Install nicht

```
/reload-plugins
```

Wenn das nicht hilft: Claude Code vollständig neu starten. Wenn das auch nicht hilft:

```bash
claude plugin list
# Prüfe ob "fastsurfer" gelistet ist
claude plugin details fastsurfer
# Prüfe ob "commands" + "skills" zählen >0
```

#### Skill triggert nicht obwohl Thema passt

Skills triggern auf das `description`-Feld. Wenn dein Wording sehr ungewöhnlich ist (z.B. fremde Sprache, internes Akronym), kann Claude die Skill verpassen.

Workaround: explizit ein Triggerwort nutzen, z.B. "Schau in den fastsurfer-overview Skill: ...".

#### Plugin findet `FASTSURFER_HOME` nicht

```bash
echo $FASTSURFER_HOME
# Wenn leer: setzen
export FASTSURFER_HOME=/path/to/fastsurfer
# Persistent in ~/.zshrc oder ~/.bashrc
```

Slash-Commands fallen sonst auf den Default `$HOME/prj/fastsurfer` zurück.

### FastSurfer selbst

Alle FastSurfer-Runtime-Probleme sind durch die Debug-Skills abgedeckt:

- License-Fehler → `fastsurfer-debug-license`
- Output fehlt / unvollständig → `fastsurfer-debug-outputs`
- Alignment-Bugs → `fastsurfer-debug-conform-tkras`
- GPU-OOM / langsam → `fastsurfer-debug-gpu-memory`
- Surface-Pipeline crasht → `fastsurfer-surface-recon` (Sektion "Wenn Surface-Pipeline crasht")
- Container-Probleme → `fastsurfer-container` (Sektion "Common Container-Errors")

Frag Claude einfach mit dem Symptom — die passende Skill triggert automatisch.

---

## FAQ

### Brauche ich das Plugin um FastSurfer zu nutzen?

Nein. FastSurfer läuft standalone. Das Plugin macht Claude zu einem **Co-Piloten** für FastSurfer-Arbeit — schneller, weniger Fehler, weniger Doku-Wälzen.

### Funktioniert das Plugin auch ohne lokales FastSurfer-Repo?

Die **Knowledge-Skills** ja — Claude kann FastSurfer-Konzepte erklären auch ohne lokales Repo. Die **Slash-Commands** brauchen aber `$FASTSURFER_HOME` um den `run_fastsurfer.sh`-Pfad zu kennen. Setze die env-var auf den Repo-Pfad oder editiere die Defaults in den Commands.

### Kann ich eigene Skills hinzufügen?

Ja — siehe Sektion [Entwicklung & Beitragen](#entwicklung--beitragen). Nach Hinzufügen: `bash update.sh` damit Claude die neue Skill registriert.

### Was ist mit FastSurfer 3.x?

Aktuell verifiziert gegen 2.6.0-dev. Bei 3.x: Skills werden vermutlich grösstenteils funktionieren, aber Flag-Beschreibungen ggf. veraltet. Bug-Reports willkommen.

### Funktioniert es mit Codex / GPT-Plugins / anderen LLM-CLIs?

Aktuell nur Claude Code. Skills + Commands sind im Claude-Code-Plugin-Format (siehe https://docs.claude.com/en/docs/claude-code/plugins-reference). Theoretisch portierbar zu Codex via dem `superpowers`-Style Skill-Format, aber nicht implementiert.

### Wie aktualisiere ich auf eine neue Plugin-Version?

```bash
bash update.sh
```

Wenn Plugin-Repo geclont von einem Remote: `git pull --ff-only` läuft automatisch. Lokal entwickelt: `bash update.sh --no-pull`.

### Greift das Plugin auf meine Daten zu?

Nein. Das Plugin enthält nur Text (Skills + Command-Templates). Claude nutzt diese als Kontext beim Generieren von Antworten / Bash-Commands. Die FastSurfer-Pipeline selbst läuft auf deiner Maschine ohne Cloud-Verbindung.

### Wo werden Skills + Commands gespeichert?

Nach `claude plugin install` cached Claude Code das Plugin unter:

```
~/.claude/plugins/cache/fastsurfer-dev/fastsurfer/
```

Bei Updates wird dieser Cache neu befüllt.

### Wie deinstalliere ich vollständig?

```bash
claude plugin uninstall fastsurfer
claude plugin marketplace remove fastsurfer-dev
rm -rf ~/prj/fastsurfer-plugin     # nur wenn du das Repo nicht mehr willst
```

---

## Entwicklung & Beitragen

### Eigene Skill hinzufügen

1. Neues Verzeichnis: `skills/fastsurfer-<your-topic>/`
2. SKILL.md anlegen:

   ```yaml
   ---
   name: fastsurfer-your-topic
   description: Use when the user asks about <triggers>. Triggers on "<keyword1>", "<keyword2>".
   ---

   # FastSurfer — Your Topic

   [Skill-Body in Markdown...]
   ```

3. Lokal validieren:

   ```bash
   claude plugin validate ~/prj/fastsurfer-plugin
   ```

4. Plugin updaten:

   ```bash
   bash update.sh --no-pull
   ```

5. In Claude Code `/reload-plugins`, dann triggern mit einem Match-Keyword.

### Eigenen Slash-Command hinzufügen

1. Neue Datei: `commands/fs-<your-command>.md`
2. Format:

   ```yaml
   ---
   description: Was der Command macht
   allowed-tools: Bash, Read
   argument-hint: "<arg1> <arg2>"
   ---

   [Command-Body als Prompt-Template; $ARGUMENTS wird vom User gepasst]
   ```

3. Update + `/reload-plugins` wie oben.

### Skill-Trigger optimieren

Wenn deine Skill nicht zuverlässig triggert:

- **Erweitere die `description`** mit mehr konkreten Keywords (Code-Snippets, Datei-Namen, Fehler-Meldungen).
- **Vermeide zu generische Trigger** wie "use when discussing FastSurfer" — überlappt mit allen anderen Skills.

### Marketplace-Schema validieren

```bash
claude plugin validate .
```

Liefert detaillierte Fehlerbeschreibungen wenn ein Manifest ungültig ist.

### Tests

Aktuell keine automatisierten Tests im Repo. Manuelle Validation-Steps:

1. `claude plugin validate` (Schema)
2. `bash install.sh --force` (Install läuft durch)
3. `claude plugin list` + `claude plugin details fastsurfer` (Komponenten geladen)
4. `/fs-check` in Claude-Code-Session (Setup-Smoke)
5. Stichproben-Trigger: frage Claude zu Themen die Skills triggern sollen

### Repository-Workflow

```bash
# Branch erstellen
cd ~/prj/fastsurfer-plugin
git checkout -b feature/your-feature

# Änderungen machen + committen
git add .
git commit -m "feat: <description>"

# Lokal testen
bash install.sh --force

# Bei Wunsch mergen
git checkout master && git merge feature/your-feature
```

Wenn du das als public Marketplace verteilen willst: Repo auf GitHub pushen, dann Users adden via:

```
/plugin marketplace add <your-org>/fastsurfer-plugin
/plugin install fastsurfer@fastsurfer-dev
```

### Versionierung

SemVer in `plugin.json` + `marketplace.json`. Beide werden von `update.sh` automatisch sync gehalten.

- Patch (0.1.0 → 0.1.1): Bugfixes, Typo-Corrections in Skills.
- Minor (0.1.0 → 0.2.0): neue Skills oder Commands.
- Major (0.1.0 → 1.0.0): breaking Changes an Command-Argumenten oder Skill-Trigger-Schema.

`update.sh --bump <type>` macht das automatisch + auto-commit. Mit `--tag` zusätzlich git-Tag setzen:

```bash
bash update.sh --bump minor --tag
# Bumped 0.1.0 → 0.2.0, commited, tagged v0.2.0
```

Tag pushen (wenn Remote vorhanden):

```bash
git push origin v0.2.0
git push          # Push der Commits
```

---

## Referenzen

### FastSurfer

- **Repo:** https://github.com/Deep-MI/FastSurfer
- **Docs:** https://deep-mi.org/FastSurfer/
- **Singularity-Docs:** https://github.com/Deep-MI/FastSurfer/blob/stable/doc/overview/SINGULARITY.md
- **Docker-Hub:** https://hub.docker.com/r/deepmi/fastsurfer

### Papers

- **FastSurfer (original):** Henschel L, Conjeti S, Estrada S, Diers K, Fischl B, Reuter M. *FastSurfer — A fast and accurate deep learning based neuroimaging pipeline.* NeuroImage 219 (2020), 117012. https://doi.org/10.1016/j.neuroimage.2020.117012
- **FastSurferVINN:** Henschel L\*, Kuegler D\*, Reuter M. *FastSurferVINN: Building Resolution-Independence into Deep Learning Segmentation Methods — A Solution for HighRes Brain MRI.* NeuroImage 251 (2022), 118933. http://dx.doi.org/10.1016/j.neuroimage.2022.118933
- **CerebNet:** Faber J\*, Kuegler D\*, Bahrami E\*, et al. *CerebNet: A fast and reliable deep-learning pipeline for detailed cerebellum sub-segmentation.* NeuroImage 264 (2022), 119703. https://doi.org/10.1016/j.neuroimage.2022.119703
- **HypVINN:** Estrada S, Kuegler D, Bahrami E, Xu P, Mousa D, Breteler MMB, Aziz NA, Reuter M. *FastSurfer-HypVINN: Automated sub-segmentation of the hypothalamus and adjacent structures on high-resolutional brain MRI.* Imaging Neuroscience 2023; 1 1–32. https://doi.org/10.1162/imag_a_00034
- **FastSurfer-CC:** Pollak C, Diers K, Estrada S, Kuegler D, Reuter M. *FastSurfer-CC: A robust, accurate, and comprehensive framework for corpus callosum morphometry.* arXiv:2511.16471. https://doi.org/10.48550/arXiv.2511.16471
- **Longitudinal:** Reuter M, Schmansky NJ, Rosas HD, Fischl B. *Within-subject template estimation for unbiased longitudinal image analysis.* NeuroImage 61:4 (2012). https://doi.org/10.1016/j.neuroimage.2012.02.084

### FreeSurfer

- **Website:** https://freesurfer.net/
- **Lizenz registrieren:** https://surfer.nmr.mgh.harvard.edu/registration.html
- **FreeView-Guide:** https://surfer.nmr.mgh.harvard.edu/fswiki/FreeviewGuide

### Claude Code

- **Plugin-Docs:** https://docs.claude.com/en/docs/claude-code/plugins
- **Plugin-Reference:** https://docs.claude.com/en/docs/claude-code/plugins-reference
- **Marketplace-Docs:** https://docs.claude.com/en/docs/claude-code/plugin-marketplaces
- **Setup:** https://docs.claude.com/en/docs/claude-code/setup

---

## Lizenz

**Apache-2.0** (siehe [LICENSE](LICENSE)).

Dieses Plugin wrappt und dokumentiert FastSurfer (ebenfalls Apache-2.0). FastSurfer selbst nutzt FreeSurfer-Binaries für die Surface-Pipeline — FreeSurfer hat eine eigene Non-Commercial-Lizenz, siehe https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSoftwareLicense.

---

## Autor

**Marcus Ifland** — `marcus@banfa.studio`

Plugin entwickelt im Rahmen der Arbeit am SS26 Modul "Kognitive Neurowissenschaften" für eine interaktive Hirn-Visualisierungs-App (brain-app).

---

> **Hinweis:** Dieses Plugin wurde mit hoher Sorgfalt gegen die FastSurfer 2.6.0-dev Repo-Quelle erstellt, ist aber nicht offiziell von Deep-MI / dem FastSurfer-Team endorsed.
