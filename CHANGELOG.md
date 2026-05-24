# Changelog

All notable changes to the **fastsurfer-plugin** for Claude Code.

Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionierung folgt [Semantic Versioning](https://semver.org/lang/de/spec/v2.0.0.html).

---

## [Unreleased]

### Coming up

- Browser-Smoke nach echter Installation
- ggf. brain-app-Integration-Skill

---

## [0.4.2] — 2026-05-24

### Added

- **Danksagung & Upstream-Projekte** als prominente eigene Sektion im README (direkt nach Inhaltsverzeichnis). Dankt explizit:
  - **Deep-MI Lab / DZNE** (FastSurfer) — Martin Reuter + Team, mit namentlicher Nennung der (Co-)Erstautoren der Hauptpublikationen (Henschel, Kuegler, Estrada, Faber, Bahrami, Pollak, Diers)
  - **Laboratory for Computational Neuroimaging, MGH** (FreeSurfer) — Bruce Fischl + Team, inkl. Dale, Sereno, Desikan, Klein, Tourville
  - **UCL CMIC + MGH Martinos Center** (NextBrain) — Juan Eugenio Iglesias, Adria Casamitjana, Oula Puonti, Matteo Mancini und gesamtes BUNGEE-TOOLS-Team
  - Foundation-Modelle (BrainFM/Liu, FireANTs/Jena) + Tooling-Ecosystem (PyTorch, nibabel, etc.)
- **Direkte Repository-Links** zu allen Upstream-Quellen in der Danksagung (nicht versteckt in Footnotes).
- **Issue-Tracker-Link** im Disclaimer fuer Korrekturen / Verbesserungen.

### Changed

- README-Hero-Block: Disclaimer-Banner unter Badges hinzugefuegt mit Verweis auf Danksagung + Referenzen.
- README-Inhaltsverzeichnis erweitert um "Danksagung & Upstream-Projekte" als ersten Eintrag.
- **Lizenz-Sektion** strukturiert: Tabelle mit Lizenz-Status pro Komponente (Plugin / FastSurfer / FreeSurfer / NextBrain) + expliziter Hinweis zur kommerziellen-Nutzung-Frage.
- Footer-Disclaimer erweitert: explizite Nennung aller Upstream-Teams (Deep-MI/DZNE, FreeSurfer/MGH, UCL/NextBrain), Issue-Link, Anpassungs-Anbot fuer Upstream-Teams.
- Component-Badge auf aktuelle Counts aktualisiert (21 Skills + 15 Commands; war veraltet auf 16+12).
- NextBrain-Status-Badge im Hero hinzugefuegt.

### Why?

User-Feedback: "so eine Danksagung und Repoverlinkung sollte man anstandshalber in der README.md machen". Open-Source-Etikette gegenueber den Upstream-Teams: das Plugin ist eine Tooling-Hilfe rund um die jahrelange wissenschaftliche und Engineering-Arbeit anderer Teams. Diese Arbeit gehoert sichtbar gewuerdigt, nicht nur in einer Referenz-Liste am Ende versteckt.

---

## [0.4.1] — 2026-05-24

### Added

- **`CITATIONS.bib`** — Vollständige BibTeX-Einträge aller im Plugin referenzierten Publikationen (FastSurfer-Module, NextBrain-Stack, FreeSurfer-Foundation, Reference-Datasets, Software-Repos). Format: BibLaTeX-kompatibel.
- **`REFERENCES.md`** — Konsolidierte wissenschaftliche Referenz-Doku mit:
  - Vollständigen Autor-Listen, Journal-Bibliographie, DOIs
  - Strukturierung nach Tool/Modul (FastSurfer-Pipeline, NextBrain, FreeSurfer-Foundation, Reference-Datasets)
  - **"Wie zitieren?"-Sektion** mit Pflicht-/Optional-Citation-Listen für FastSurfer- und NextBrain-Workflows

### Changed

- README "Referenzen"-Sektion → "Wissenschaftliche Referenzen", verweist zentral auf REFERENCES.md und CITATIONS.bib (Single Source of Truth statt Inline-Duplikat).
- Inhaltsverzeichnis-Eintrag entsprechend angepasst.

### Why?

User-Feedback: "bitte noch sauber und wissenschaftlich referenzieren". Vorher waren Citations inline in README + Skills mit inkonsistentem Format (mal mit DOI, mal nur URL, mal nur Erstautor). Jetzt: ein zentraler Ort für alle Quellen, BibTeX-export für akademische User, klare How-to-cite-Anleitung.

---

## [0.4.0] — 2026-05-24

### Added

**Adjacent FreeSurfer-Ecosystem: NextBrain Integration**

- **Skill `freesurfer-nextbrain-overview`** — Was NextBrain ist (Casamitjana et al. Nature 2025), 333 ROIs Histology-Atlas, Setup, Hardware-Requirements, Lizenz-Status, sequential dual-hemi Strategie.
- **Skill `freesurfer-nextbrain-cli`** — Vollstaendige `mri_histo_atlas_segment_fireants` Flag-Referenz (5 Pflicht + 19 Optional), inkl. Memory-Tuning, FireANTs-Registration-Parameter, Custom-Label-Grouping via YAML, vollstaendige Beispiel-Aufrufe.
- **Skill `freesurfer-nextbrain-vs-fastsurfer`** — Decision-Guide mit 18-Achsen-Vergleichstabelle, Decision-Flow, Kombi-Workflow (FastSurfer + NextBrain on-top), Wann-NICHT-Listen.
- **Slash-Command `/fs-nextbrain`** — Run-Template mit auto-GPU-Detection, dual-hemi sequentiell, First-Run-Download-Hinweise, Memory-Tuning-Optionen, Output-Verification.

### Changed

- `plugin.json` description erweitert auf "FastSurfer und adjacent FreeSurfer-Ecosystem-Tools (NextBrain)".
- `/fs-help` listet NextBrain-Skills + `/fs-nextbrain` Command.
- Total jetzt: 21 Skills + 15 Slash-Commands.

### Why?

NextBrain (FreeSurfer-dev `mri_histo_util/mri_histo_atlas_segment_fireants`) ergaenzt FastSurfer um Hippocampus-Subfields, Brainstem-Nuclei, Thalamus-Subkerne und 200+ weitere Sub-Regionen — Use-Case-Adjacent fuer brain-app und andere neuroimaging-Pipelines. Outputs in tkRAS-Frame (gleich wie FastSurfer), daher direkt overlay-bar.

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
