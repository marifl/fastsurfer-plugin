# fastsurfer-plugin

Vollständiges Claude-Code-Plugin für [FastSurfer](https://github.com/Deep-MI/FastSurfer) — die Deep-Learning-basierte Neuroimaging-Pipeline für volumetrische Segmentierung und Surface-Reconstruction des Gehirns.

Das Plugin verschafft Claude umfassendes operationales Verständnis aller FastSurfer-Komponenten: `asegdkt` (FastSurferVINN), `cc` (Corpus Callosum), `cereb` (CerebNet), `hypothal` (HypVINN), `recon-surf` sowie die experimentelle LIT-Lesion-Inpainting-Erweiterung. Inkludiert sind Skills für CLI-Flags, Output-Layout, Conform-Space-Semantik, Checkpoints/Models, Container- und SLURM-Workflows sowie typische Debugging-Pfade.

## Features

- **16 Knowledge- und Debug-Skills** — Pipeline-Übersicht, jede Modul-Internals, Outputs, Conform-Space, Container, Batch/SLURM, longitudinal, LIT, Debugging.
- **12 Slash-Commands** — kuratierte Templates für `run`, `seg`, `surf`, `quick`, `batch`, `long`, `slurm`, `docker`, `check`, `outputs`, `logs`, `freeview`.
- **Cross-Plattform** — macOS native, Docker und SLURM-Workflows abgedeckt.
- **Evidence-First** — alle Skills referenzieren konkrete Datei-/Flag-/Output-Namen aus dem FastSurfer-Repo (Version 2.6.0-dev verifiziert).

## Voraussetzungen

- **FastSurfer-Repo lokal verfügbar.** Default-Annahme: `/Users/marcusifland/prj/fastsurfer` (anpassbar via `$FASTSURFER_HOME`).
- **FreeSurfer-Lizenz** für die Surface-Pipeline. Registrierung kostenlos unter https://surfer.nmr.mgh.harvard.edu/registration.html.
- **Python 3.10+** mit den FastSurfer-Dependencies (siehe `pyproject.toml` im FastSurfer-Repo).
- Optional: Docker / Apptainer / SLURM für Container- bzw. HPC-Workflows.

## Installation

### Automatisch via `install.sh` (empfohlen)

```bash
cd /Users/marcusifland/prj/fastsurfer-plugin
bash install.sh
```

Das Script:

1. Prüft `claude` CLI + `git` Verfügbarkeit
2. Validiert die Plugin- und Marketplace-Manifeste via `claude plugin validate`
3. Registriert den Marketplace via `claude plugin marketplace add`
4. Installiert das Plugin via `claude plugin install fastsurfer@fastsurfer-dev`
5. Verifiziert die Installation via `claude plugin list`

Optionen:

```bash
bash install.sh --scope user      # Default: ~/.claude/settings.json
bash install.sh --scope project   # Nur für das aktuelle Projekt-Repo
bash install.sh --scope local     # Per-Maschine-Override (nicht committed)
bash install.sh --force           # Skip Confirmations + re-install
bash install.sh --help
```

**Wichtig:** Das Script editiert NICHT manuell in `~/.claude/settings.json`. Alle Änderungen laufen über die offizielle `claude plugin` CLI.

### Update via `update.sh`

```bash
cd /Users/marcusifland/prj/fastsurfer-plugin
bash update.sh
```

Das Script:

1. `git pull --ff-only` (wenn Remote vorhanden; skip mit `--no-pull`)
2. Validiert Manifeste neu
3. Refresht den Marketplace via `claude plugin marketplace update`
4. Updated das Plugin via `claude plugin update`

### Manuell (alternativ, in einer Claude-Code-Session)

```
/plugin marketplace add /Users/marcusifland/prj/fastsurfer-plugin
/plugin install fastsurfer@fastsurfer-dev
```

### Verifikation

Nach Install/Update in Claude Code:

```
/reload-plugins        # bzw. Claude Code neu starten
/fs-check              # Smoke-Test der Installation
```

`/plugin` listet alle installierten Plugins (sollte `fastsurfer` enthalten).

### Uninstall

```bash
claude plugin uninstall fastsurfer
claude plugin marketplace remove fastsurfer-dev
```

## Skills (auto-trigger bei passendem Kontext)

| Skill | Wann triggert er |
|-------|------------------|
| `fastsurfer-overview` | Übersicht der Pipeline, Modul-Reihenfolge, Default-Verhalten |
| `fastsurfer-cli-flags` | Flag-Semantik aller `run_fastsurfer.sh`-Optionen |
| `fastsurfer-outputs` | Was-wird-wo-geschrieben Referenz (mri/, surf/, stats/, label/) |
| `fastsurfer-conform-space` | Conform-Space, `--vox_size`, `--keepgeom`, tkRAS-Bugs |
| `fastsurfer-internals` | Repo-Layout, wo Code für welche Funktion liegt |
| `fastsurfer-segmentation` | asegdkt / cc / cereb / hypothal Architektur + VINN |
| `fastsurfer-surface-recon` | recon-surf-Schritte, FreeSurfer-Bridge |
| `fastsurfer-checkpoints-models` | Modell-Checkpoints, Download, generate_hdf5, run_model |
| `fastsurfer-container` | Docker & Singularity Wrapper-Pattern |
| `fastsurfer-batch-slurm` | brun_fastsurfer.sh und srun_fastsurfer.sh |
| `fastsurfer-longitudinal` | long_fastsurfer.sh, Template+Time-Point Workflow |
| `fastsurfer-lit` | Lesion-Inpainting-Tool, `--lesion_mask`, Backup-Schema |
| `fastsurfer-debug-license` | FreeSurfer-Lizenz-Fehler, häufige Fehlermeldungen |
| `fastsurfer-debug-outputs` | Output-Validierung, Label-Sets, expected Files |
| `fastsurfer-debug-conform-tkras` | Native-vs-Conformed Mismatches, tkRAS-Offset-Bugs |
| `fastsurfer-debug-gpu-memory` | OOM, Device-Auswahl, viewagg, batch-Size |

## Slash-Commands

| Command | Wofür |
|---------|-------|
| `/fs-run` | Vollständige FastSurfer-Pipeline (seg + surf) |
| `/fs-seg` | Nur Segmentierungs-Pipeline (`--seg_only`) |
| `/fs-surf` | Nur Surface-Pipeline (`--surf_only`) |
| `/fs-quick` | Schnellster Modus: nur asegdkt, ~1 Min auf GPU |
| `/fs-batch` | `brun_fastsurfer.sh` für Subject-Listen |
| `/fs-long` | `long_fastsurfer.sh` longitudinale Verarbeitung |
| `/fs-slurm` | `srun_fastsurfer.sh` HPC-Orchestrierung |
| `/fs-docker` | Docker-Wrapper für `deepmi/fastsurfer` |
| `/fs-check` | Install-/Lizenz-/GPU-/Checkpoint-Diagnostik |
| `/fs-outputs` | Listet erwartete Subject-Output-Files mit Beschreibung |
| `/fs-logs` | Tailed `deep-seg.log` und `recon-all.log` |
| `/fs-freeview` | Öffnet Subject in FreeView mit sinnvollen Layern |

## Designprinzipien

- **Vollständigkeit über Knappheit.** Skills decken die volle FastSurfer-Code- und CLI-Fläche ab, nicht nur Happy-Paths.
- **Code-Modifikations-Tiefe.** Skills referenzieren konkrete Module unter `FastSurferCNN/`, `CerebNet/`, `HypVINN/`, `CorpusCallosum/`, `recon_surf/` und `tools/`, sodass Claude beim Forken/Patchen direkt weiß, wo zu schauen ist.
- **Container + Native + HPC parallel.** Kein OS-Bias — gleiche Konzepte über alle drei Install-Wege.
- **Verifizierbarkeit.** Jedes Output-/Flag-Statement ist gegen FastSurfer 2.6.0-dev Repo-Quelle geprüft.

## Referenzen

- FastSurfer: https://github.com/Deep-MI/FastSurfer
- FastSurferVINN-Paper: Henschel et al., NeuroImage 251 (2022), 118933
- CerebNet-Paper: Faber et al., NeuroImage 264 (2022), 119703
- HypVINN-Paper: Estrada et al., Imaging Neuroscience 2023; 1 1–32
- FreeSurfer: https://freesurfer.net/

## Lizenz

Apache-2.0 (siehe `LICENSE`). Wrappt FastSurfer (Apache-2.0). FreeSurfer hat eigene Non-Commercial-Lizenz.
