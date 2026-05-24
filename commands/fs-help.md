---
description: Listet alle /fs-* Slash-Commands des fastsurfer-plugin mit Synopsis, Use-Case und Cross-Reference zu Skills.
allowed-tools: Read
argument-hint: "[<command-name>]   # optional: Details zu einem konkreten Command"
---

Gib eine strukturierte Uebersicht aller fastsurfer-plugin Components aus.

Args: `$ARGUMENTS`. Wenn leer → Full-Uebersicht. Wenn z.B. `run` oder `fs-run` → Details zu diesem Command.

## Full-Uebersicht (default)

Strukturiere die Ausgabe wie folgt:

### Slash-Commands (12)

```
PIPELINE-RUNS
  /fs-run <t1> <sid>          Volle Pipeline (Seg + Surf, ~60-90 Min GPU)
  /fs-seg <t1> <sid>          Nur Segmentation (~5-10 Min GPU)
  /fs-surf <sid>              Nur Surface-Reconstruction (~45-90 Min)
  /fs-quick <t1> <sid>        Minimal asegdkt (~1 Min GPU)

MULTI-SUBJECT / HPC
  /fs-batch <subject_list>            brun_fastsurfer.sh fuer mehrere Subjects
  /fs-long <tid> <t1s> <tpids>        long_fastsurfer.sh longitudinal
  /fs-slurm <data_dir> <pattern>      srun_fastsurfer.sh HPC-Cluster

CONTAINER
  /fs-docker <t1> <sid>       Docker-Wrapper (deepmi/fastsurfer)

DIAGNOSTIK / VALIDATION
  /fs-check                   Setup-Smoke-Test (Install, License, GPU, ...)
  /fs-outputs <sid>           Output-Validation (was wurde wirklich erzeugt?)
  /fs-logs <sid>              Tail deep-seg.log + recon-all.log
  /fs-freeview <sid>          Oeffne FreeView mit Subject

META
  /fs-help [<command>]        Diese Hilfe
```

### Skills (16, auto-getriggert)

```
KNOWLEDGE (Fundamentals)
  fastsurfer-overview          Pipeline-Map, Module, Defaults
  fastsurfer-cli-flags         Alle run_fastsurfer.sh Flags
  fastsurfer-outputs           Output-Layout pro Modul
  fastsurfer-conform-space     Conform-Space, tkRAS, AC/PC
  fastsurfer-internals         Repo-Layout, "Wo ist X?"

MODULE-DEEP-DIVE
  fastsurfer-segmentation      asegdkt + cc + cereb + hypothal Architektur
  fastsurfer-surface-recon     recon-surf-Pipeline (11 Schritte)
  fastsurfer-checkpoints-models Checkpoints, Custom-Training

WORKFLOWS
  fastsurfer-container         Docker + Singularity
  fastsurfer-batch-slurm       brun + srun
  fastsurfer-longitudinal      long_fastsurfer + Template
  fastsurfer-lit               Lesion-Inpainting

DEBUG
  fastsurfer-debug-license     FreeSurfer-License-Probleme
  fastsurfer-debug-outputs     Output fehlt / unvollstaendig
  fastsurfer-debug-conform-tkras  Alignment-Bugs, 17.5mm-Offset
  fastsurfer-debug-gpu-memory  GPU-OOM, Performance

3D / COORDS
  fastsurfer-coordinates-3d    Scanner-RAS / tkRAS / LIA / Three.js Y-up / Blender Z-up
                               (siehe /fs-help coordinates-3d)
```

### Plugin-Verwaltung (claude-CLI)

```
claude plugin list                                  Installed Plugins
claude plugin details fastsurfer                    Components + Token-Cost
claude plugin marketplace list                      Registered Marketplaces
claude plugin update fastsurfer                     Update Plugin
claude plugin uninstall fastsurfer                  Remove Plugin
```

Oder via Scripts im Plugin-Repo:

```
bash install.sh                Install (CLI-basiert, keine System-File-Bastelei)
bash update.sh                 Update + auto Version-Bump
bash uninstall.sh              Cleanup
```

## Detail-Modus (wenn Arg gegeben)

Wenn User z.B. `/fs-help run` oder `/fs-help fs-batch` schreibt: zeige Detail zu DIESEM Command.

Strip ggf. `fs-` prefix vom Arg. Mappe auf File:
- `run`     → commands/fs-run.md
- `seg`     → commands/fs-seg.md
- `surf`    → commands/fs-surf.md
- `quick`   → commands/fs-quick.md
- `batch`   → commands/fs-batch.md
- `long`    → commands/fs-long.md
- `slurm`   → commands/fs-slurm.md
- `docker`  → commands/fs-docker.md
- `check`   → commands/fs-check.md
- `outputs` → commands/fs-outputs.md
- `logs`    → commands/fs-logs.md
- `freeview` → commands/fs-freeview.md
- `help`    → commands/fs-help.md (this file)

Lies die Datei via Read-Tool aus dem Plugin-Cache (Pfad typisch: `~/.claude/plugins/cache/fastsurfer-dev/fastsurfer/commands/fs-<name>.md`) und gib den vollen Inhalt formatiert aus.

Wenn der Pfad nicht eindeutig ist: probiere zuerst Plugin-Cache-Pfad, fallback auf alternativen (z.B. `${CLAUDE_PLUGIN_ROOT}/commands/` bzw. lokales `commands/`).

Falls Command nicht existiert: liste verfuegbare Commands aus dem Full-Uebersicht-Modus.

## Tipp

Bei FastSurfer-Fragen einfach direkt fragen (Claude triggert automatisch die richtige Skill). `/fs-help` ist Meta — nur zum Auflisten / Detail-Lookup.
