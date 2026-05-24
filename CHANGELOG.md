# Changelog

All notable changes to the **fastsurfer-plugin** for Claude Code.

Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionierung folgt [Semantic Versioning](https://semver.org/lang/de/spec/v2.0.0.html).

---

## [Unreleased]

### Coming up

- Browser-Smoke nach echter Installation
- ggf. brain-app-Integration-Skill

---

## [0.3.0] — 2026-05-24

### Added

- **Skill `fastsurfer-stats-parsing`** — Vollstaendige Doku des FreeSurfer `.stats`-Formats (Header-Measures + Tabular-Data + ColHeaders). Python-Parser-Recipes fuer pandas-DataFrame-Conversion, Multi-Subject-Aggregation, eTIV-Normalisierung, Longitudinal-Trajectories, Excel/JSON-Export, FreeSurfer-LUT-Parsing. Plus Pitfalls und Default-ColHeaders-Fallback.
- **Slash-Command `/fs-stats`** — Liest/druckt/vergleicht/exportiert Stats-Files:
  - `/fs-stats <sid>` — Liste + aseg-Hauptmeasures
  - `/fs-stats <sid> <file>` — Pretty-Print (mit pandas-DataFrame fuer Tabular)
  - `/fs-stats <sid> --compare <sid2>` — Side-by-Side Vergleich
  - `/fs-stats <sid> --measure <name>` — Grep nach Measure (z.B. Hippocampus)
  - `/fs-stats <sid> --export-csv <path>` — Flat-CSV fuer pandas/R
  - `/fs-stats <sid> --list` — nur Filenames

### Changed

- `/fs-help` listet jetzt `/fs-stats` und Skill `fastsurfer-stats-parsing`.

---

## [0.2.0] — 2026-05-24

### Added

- **Skill `fastsurfer-coordinates-3d`** — Vollstaendige Konversion zwischen Scanner-RAS, FreeSurfer-tkRAS, LIA-Voxel-Order, Three.js Y-up, WebGL und Blender Z-up. Inkl. konkreter Transform-Matrizen, nibabel-Python-Code und Three.js-Snippets fuer den Import von FastSurfer-Surfaces.
- **Slash-Command `/fs-help`** — Meta-Command, listet alle `/fs-*` Commands + Skills. Mit Argument (z.B. `/fs-help batch`) zeigt es Details zu einem konkreten Command.
- **`uninstall.sh`** — Symmetrisches Cleanup-Script: `claude plugin uninstall` + `claude plugin marketplace remove`. Optional `--purge-cache` und `--keep-marketplace`.

### Changed

- README auf ~600 Zeilen erweitert (Inhaltsverzeichnis, Quick-Start, Architektur, FAQ, Troubleshooting, Entwickler-Workflow).

---

## [0.1.0] — 2026-05-24

Initial Release.

### Added

#### Plugin-Scaffold

- `.claude-plugin/plugin.json` und `.claude-plugin/marketplace.json` fuer lokales Dev-Install.
- Apache-2.0 LICENSE.
- README mit Components-Tabellen.

#### 16 Skills (Knowledge + Module + Workflow + Debug)

**Knowledge:**
- `fastsurfer-overview` — Pipeline-Map, Modul-Reihenfolge, Default-Aufruf
- `fastsurfer-cli-flags` — Vollstaendige CLI-Flag-Referenz (`run_fastsurfer.sh`)
- `fastsurfer-outputs` — Output-Layout pro Modul, Validation-Snippets
- `fastsurfer-conform-space` — Conform-Space, vox_size, keepgeom, tkRAS, AC/PC
- `fastsurfer-internals` — Repo-Layout, "Wo ist X?"-Tabellen, Datenfluss

**Module-Deep-Dive:**
- `fastsurfer-segmentation` — asegdkt (FastSurferVINN) + cc + cereb + hypothal Architektur
- `fastsurfer-surface-recon` — recon-surf 11-Step-Pipeline, FreeSurfer-Bridge
- `fastsurfer-checkpoints-models` — Checkpoint-Layout, Custom-Training, generate_hdf5

**Workflow:**
- `fastsurfer-container` — Docker + Singularity Templates
- `fastsurfer-batch-slurm` — brun_fastsurfer.sh + srun_fastsurfer.sh
- `fastsurfer-longitudinal` — long_fastsurfer.sh + Within-Subject-Template
- `fastsurfer-lit` — Lesion-Inpainting-Tool, Backup-Schema

**Debug:**
- `fastsurfer-debug-license` — FreeSurfer-License-Probleme
- `fastsurfer-debug-outputs` — 4-Schritt-Diagnose bei fehlenden/unvollstaendigen Outputs
- `fastsurfer-debug-conform-tkras` — Standard-Frame-Bugs (17.5mm-Offset, 90°-Rotation, cras)
- `fastsurfer-debug-gpu-memory` — GPU-OOM-Strategien, Memory pro Modul, CPU-Only

#### 12 Slash-Commands

- `/fs-run`, `/fs-seg`, `/fs-surf`, `/fs-quick` — Pipeline-Runs
- `/fs-batch`, `/fs-long`, `/fs-slurm` — Multi-Subject / HPC
- `/fs-docker` — Container-Wrapper
- `/fs-check` — Setup-Smoke-Test
- `/fs-outputs`, `/fs-logs`, `/fs-freeview` — Diagnostik

#### Automation-Scripts

- **`install.sh`** — Vollautomatische Installation via `claude plugin` CLI. Scopes `user|project|local`, `--force`, `--help`. Keine System-File-Bastelei.
- **`update.sh`** — Auto-Update mit:
  - `git pull --ff-only` (skip via `--no-pull`)
  - Auto-Version-Bump in `plugin.json` + `marketplace.json` (Default `patch`, `--bump minor|major`, `--version X.Y.Z`)
  - Auto-Commit (skip via `--no-commit`)
  - `--tag` fuer git-Tag
  - `claude plugin marketplace update` + `claude plugin update`

### Verified gegen

- FastSurfer 2.6.0-dev (Commit `30497c6`)
- Claude Code CLI mit `plugin`-Subcommand
- macOS Apple Silicon (CPU-Only Tests)

---

[Unreleased]: https://github.com/marifl/fastsurfer-plugin/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/marifl/fastsurfer-plugin/releases/tag/v0.2.0
[0.1.0]: https://github.com/marifl/fastsurfer-plugin/releases/tag/v0.1.0
