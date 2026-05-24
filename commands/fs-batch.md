---
description: Mehrere Subjects parallel/seriell mit `brun_fastsurfer.sh`. Benötigt subject-list-File.
allowed-tools: Bash, Read
argument-hint: "<subject_list_file> [<extra-flags>]"
---

Batch-Run mehrerer Subjects via `brun_fastsurfer.sh` für $ARGUMENTS.

## Subject-Liste vorbereiten

Format der Liste (eine Zeile pro Subject, `=` separated):

```
subject1=/abs/path/sub1/t1.nii.gz
subject2=/abs/path/sub2/t1.nii.gz
subject3=/abs/path/sub3/t1.nii.gz --vox_size 0.8
```

Subject-spezifische Flags hinter dem Pfad, whitespace-separated.

## Pre-Flight

```bash
SUBJECT_LIST="<path-from-args>"

[ -f "$SUBJECT_LIST" ] || { echo "FAIL: $SUBJECT_LIST nicht gefunden."; exit 1; }

echo "Subject-Count:"
wc -l < "$SUBJECT_LIST"

echo "Erste 5 Subjects:"
head -5 "$SUBJECT_LIST"
```

Prüfe ob T1-Pfade in der Liste existieren (mindestens stichprobenartig).

## Aufruf-Pattern

```bash
FASTSURFER_HOME="${FASTSURFER_HOME:-/Users/marcusifland/prj/fastsurfer}"

"$FASTSURFER_HOME/brun_fastsurfer.sh" \
  --subject_list "$SUBJECT_LIST" \
  --sd "$SUBJECTS_DIR" \
  --fs_license "$FS_LICENSE" \
  --parallel_seg 2 --parallel_surf 4 \
  --threads_seg 8 --threads_surf 4 \
  --statusfile "$SUBJECTS_DIR/batch_status.txt" \
  --3T \
  <user-extra-flags>
```

## Parallelisierungs-Strategie wählen

Frag den User wenn unklar:

| Szenario | Empfehlung |
|----------|-----------|
| Single GPU, single CPU-Cluster | `--parallel 1` (seriell, langsam aber konservativ) |
| Single GPU, 8+ Cores | `--parallel_seg 1 --parallel_surf 4` |
| 2 GPUs, 16+ Cores | `--parallel_seg 2 --parallel_surf 4` |
| Workstation 24GB-GPU, 16 Cores | `--parallel_seg 2 --parallel_surf 4` |
| Cluster-Node mit 4 GPUs + 32 Cores | `--parallel_seg 4 --parallel_surf 8` |

Speicher-Faustregel: pro paralleler Seg-Process etwa 4-6 GB VRAM (asegdkt-VINN), pro paralleler Surf-Process etwa 4 GB RAM.

## Status-File

`--statusfile <path>` schreibt Erfolg/Failure pro Subject:

```
subject1 SUCCESS
subject2 SUCCESS
subject3 FAILED_SEG
```

Wird auch genutzt um Surface zu skippen wenn Seg gefailed hat.

## Erwartete Laufzeit (Beispiel)

10 Subjects, `--parallel_seg 2 --parallel_surf 4`:
- Seg-Phase: ~5 Subjects × ~5 Min / 2 parallel = ~12.5 Min total
- Surf-Phase: ~10 Subjects × ~60 Min / 4 parallel = ~150 Min total
- Total: ~3h

Empfehle dem User `run_in_background: true` und einen `tail -f` auf das Statusfile.

## Cross-Reference

- Container-Wrapping für Subjects: Skill `fastsurfer-batch-slurm` Sektion "Run via Container"
- HPC-Cluster: `/fs-slurm` statt `/fs-batch`
- Single-Subject: `/fs-run`
- Full Flag-Doku: Skill `fastsurfer-batch-slurm`
