---
description: Starte die vollständige FastSurfer-Pipeline (Segmentation + Surface) für einen Subject.
allowed-tools: Bash, Read
argument-hint: "<t1_path> <sid> [<extra-flags>]"
---

Hilf dem User die vollständige FastSurfer-Pipeline zu starten. Args: `$ARGUMENTS`.

Erwartetes Pattern: erste zwei Args sind T1-Pfad und Subject-ID; optionale weitere Args werden direkt an `run_fastsurfer.sh` durchgereicht.

## Pre-Flight-Checks (vorher Bash)

1. Prüfe FastSurfer-Repo-Verfügbarkeit:
   ```bash
   FASTSURFER_HOME="${FASTSURFER_HOME:-/Users/marcusifland/prj/fastsurfer}"
   [ -x "$FASTSURFER_HOME/run_fastsurfer.sh" ] && echo "OK: $FASTSURFER_HOME" || echo "MISSING: $FASTSURFER_HOME/run_fastsurfer.sh"
   ```

2. Prüfe FreeSurfer-License-Pfad. Wenn User keine `--fs_license` mitgegeben hat, nach `$FS_LICENSE` env-var oder `$HOME/freesurfer_license.txt` fragen.

3. Prüfe ob T1-Pfad absolut + lesbar ist.

4. Prüfe ob `$SUBJECTS_DIR` gesetzt ist oder ob User `--sd <path>` mitgeben muss.

## Run-Aufruf

Konstruktion:

```bash
"$FASTSURFER_HOME/run_fastsurfer.sh" \
  --t1 <absolute-path-to-T1> \
  --sid <SID> \
  --sd "$SUBJECTS_DIR" \
  --fs_license "$FS_LICENSE" \
  --3T --threads 4 \
  <user-extra-flags>
```

**Wichtig:**
- Alle Pfad-Argumente müssen absolut sein.
- Default-Flags `--3T --threads 4` einbauen ausser User überschreibt.
- Auf Apple Silicon (macOS arm64): zusätzlich `--device cpu --viewagg_device cpu` empfehlen.

## Wenn Pre-Flight failed

Bei fehlenden Vorbedingungen NICHT blind starten. Sondern strukturiert auflisten was fehlt und User um Klärung bitten.

## Erwartete Laufzeit

- GPU: ~50-90 Min
- CPU (Apple Silicon): ~3-6h

Vor dem Start dem User die erwartete Laufzeit nennen und ob er run_in_background nutzen möchte.

## Nach Abschluss

Verify-Aufruf:
```bash
ls "$SUBJECTS_DIR/<SID>/mri/aparc.DKTatlas+aseg.deep.mgz" \
   "$SUBJECTS_DIR/<SID>/surf/lh.pial" \
   "$SUBJECTS_DIR/<SID>/stats/aseg.stats" 2>&1 | tail -10
```

Bei Fehlern: Skill `fastsurfer-debug-outputs` referenzieren.

## Cross-Reference

Für andere Pipeline-Varianten: `/fs-seg`, `/fs-surf`, `/fs-quick`, `/fs-batch`, `/fs-long`, `/fs-slurm`, `/fs-docker`.
