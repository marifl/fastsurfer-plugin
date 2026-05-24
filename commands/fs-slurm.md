---
description: SLURM-Cluster-Orchestrierung via `srun_fastsurfer.sh`. Submittet dependent GPU+CPU+Cleanup-Jobs.
allowed-tools: Bash, Read
argument-hint: "<data_dir> <pattern> [<extra-flags>]"
---

SLURM-Cluster-Run für $ARGUMENTS via `srun_fastsurfer.sh`.

## Pre-Flight

```bash
# SLURM verfügbar?
command -v sbatch >/dev/null 2>&1 || { echo "FAIL: sbatch nicht im PATH (kein SLURM-System?)"; exit 1; }
command -v squeue >/dev/null 2>&1 || { echo "FAIL: squeue nicht im PATH"; exit 1; }

# Partitions checken
sinfo -o "%P" 2>/dev/null

# HPCWORK-Var gesetzt?
[ -n "$HPCWORK" ] || echo "WARN: \$HPCWORK nicht gesetzt — explizit --work nötig"

# Singularity-Image?
[ -f "$SINGULARITY_IMAGE" ] || echo "INFO: Singularity-Image-Pfad muss via --singularity_image gesetzt werden"
```

## Aufruf-Pattern (Data-Pattern-Mode)

```bash
FASTSURFER_HOME="${FASTSURFER_HOME:-$HOME/prj/fastsurfer}"

"$FASTSURFER_HOME/srun_fastsurfer.sh" \
  --data "<data-root>" \
  --pattern "<glob-pattern>" \
  --sd "$SUBJECTS_DIR" \
  --partition seg="$GPU_PARTITION" \
  --partition surf="$CPU_PARTITION" \
  --time_seg 02:00:00 \
  --time_surf 06:00:00 \
  --mem_seg 24 \
  --mem_surf 16 \
  --num_cpus_per_task 8 \
  --singularity_image "$SINGULARITY_IMAGE" \
  --fs_license "$FS_LICENSE" \
  --3T \
  --email "$USER@example.com" \
  <user-extra-flags>
```

## Aufruf-Pattern (Subject-List-Mode)

```bash
"$FASTSURFER_HOME/srun_fastsurfer.sh" \
  --subject_list <path/to/subject_list.txt> \
  --sd "$SUBJECTS_DIR" \
  --partition seg="$GPU_PARTITION" \
  --partition surf="$CPU_PARTITION" \
  ...
```

Für CSV-Listen mit Per-Subject-Parametern:

```bash
... --subject_list_delim "," \
    --subject_list_awk_code_args '$2 " --vox_size " $4' \
    ...
```

## Immer empfohlen: `--dry --debug` zuerst

Vor dem echten Submit:

```bash
"$FASTSURFER_HOME/srun_fastsurfer.sh" \
  --data "<data>" --pattern "<glob>" \
  --sd "$SUBJECTS_DIR" \
  --partition seg="..." --partition surf="..." \
  --singularity_image "$SINGULARITY_IMAGE" \
  --fs_license "$FS_LICENSE" \
  --dry --debug \
  <other-flags>
```

`--dry` macht alles **ausser** dem tatsächlichen `sbatch` — du siehst was submitted würde. `--debug` gibt detailliertes Output.

## Resource-Faustregeln

| Anzahl Subjects | Empfehlung |
|-----------------|------------|
| 10-50 | `--num_cases_per_task 1` (1 Subject pro SLURM-Task) |
| 50-200 | `--num_cases_per_task 5-10` (Batching pro Task) |
| 200+ | `--num_cases_per_task 10-20` + `--slurm_jobarray 1-100%20` |

Memory:
- `--mem_seg 24` (GB) — sicher für asegdkt+CerebNet+HypVINN+CC
- `--mem_surf 16` (GB) — sicher für recon-surf mit `--threads_surf 4`

Time:
- `--time_seg 02:00:00` — für asegdkt+sub-modules + Margin
- `--time_surf 06:00:00` — für full Surface mit `--threads_surf 4` + Margin

## Work-Directory

`--work <fast-IO-dir>` ist KRITISCH für Cluster-Performance:

```bash
--work "/scratch/$USER/fastsurfer-$(date +%Y%m%d-%H%M%S)"
```

Default ist `$HPCWORK/fastsurfer-processing/<timestamp>`. Alle IO läuft hier; nach Erfolg wird kopiert in `--sd` und Work-Dir gelöscht.

## Nach Submit

```bash
squeue -u $USER                                          # eigene Jobs
sacct -j <jobid> --format=JobID,JobName,State,Elapsed   # Job-Status
ls "$SUBJECTS_DIR/slurm/logs/"                           # Logs einsehen
ls "$SUBJECTS_DIR/slurm/scripts/"                        # generierte Submit-Scripts
```

## Cross-Reference

- Volle Flag-Doku: Skill `fastsurfer-batch-slurm`
- Container-Setup: `fastsurfer-container`
- Single-Maschine-Batch ohne SLURM: `/fs-batch`
