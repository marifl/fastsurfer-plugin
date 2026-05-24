---
name: fastsurfer-batch-slurm
description: Use when the user wants to run FastSurfer on many subjects, in parallel, or on an HPC cluster. Triggers on "brun_fastsurfer", "brun", "subject_list", "FastSurfer batch", "FastSurfer parallel", "FastSurfer SLURM", "srun_fastsurfer", "HPC FastSurfer", "FastSurfer cluster", "process many subjects", "FastSurfer job array".
---

# FastSurfer — Batch (brun) und SLURM (srun) Workflows

Zwei dedizierte Wrapper-Scripts neben `run_fastsurfer.sh`:

- **`brun_fastsurfer.sh`** — Multi-Subject parallel/seriell auf einer Maschine.
- **`srun_fastsurfer.sh`** — SLURM-Cluster-Orchestrierung mit getrennten GPU/CPU-Partitionen.

Beide leben im FastSurfer-Repo-Root. Beide akzeptieren fast alle `run_fastsurfer.sh`-Flags weiter.

## brun_fastsurfer.sh

### Subject-Listen-Format

Eine Zeile pro Subject; Felder durch `=` getrennt (anpassbar):

```
subject1=/abs/path/to/subject1/t1.nii.gz
subject2=/abs/path/to/subject2/t1.nii.gz
subject3=/abs/path/to/subject3/t1.nii.gz [--vox_size 0.8]
```

Subject-spezifische Parameter werden hinter dem Pfad mit Whitespace getrennt; sie überschreiben die globalen Flags für diesen Subject.

### Drei Wege Subjects zu definieren

1. **`--subject_list <file>`**: Pfad zur Datei im obigen Format.
2. **`--subjects sub1=path1 sub2=path2 ...`**: direkt CLI (keine subject-specific params).
3. **Stdin** (`--`): subject-list über stdin pipen (Ctrl-D zum Beenden).

### Parallelisierung

| Flag | Wirkung |
|------|---------|
| `--parallel <n>\|max` | n parallele Subjects, jeder macht Seg+Surf nacheinander |
| `--parallel_seg <n>\|max` | n parallele Seg-Processes (separater Pool) |
| `--parallel_surf <m>\|max` | m parallele Surf-Processes (separater Pool) |

**Modus 1 — full-parallel:** `--parallel N` → N Pipelines komplett parallel. Total = N × (1 GPU-Job + 1 CPU-Job).

**Modus 2 — split-queues:** `--parallel_seg N --parallel_surf M` → Seg-Queue mit N parallel, danach Surf-Queue mit M parallel. Subjects wandern Seg → Surf. Max = M+N parallel processes.

Empfohlen für Cluster: split-queues weil GPU (Seg) und CPU (Surf) unterschiedliche Ressourcen-Profile haben.

### Status-Tracking

```bash
brun_fastsurfer.sh ... --statusfile /path/to/status.txt
```

Schreibt Erfolg/Failure pro Subject. Wird auch genutzt um Surface-Recon zu skippen wenn Seg gefailed hat.

### Beispiel: 10 Subjects, 4 parallel, native

```bash
./brun_fastsurfer.sh \
  --subject_list subjects.txt \
  --sd $HOME/my_fastsurfer_analysis \
  --fs_license $HOME/my_fs_license.txt \
  --parallel_seg 2 --parallel_surf 4 \
  --threads_seg 8 --threads_surf 4 \
  --3T
```

### Run via Container

`brun_fastsurfer.sh` selbst kann den eigentlichen `run_fastsurfer.sh`-Call in einen Container delegieren via:

```bash
brun_fastsurfer.sh \
  --subject_list subjects.txt \
  --sd /output \
  --run_fastsurfer "singularity exec --nv --no-mount home,cwd -e \
                     -B /data:/data -B /output:/output -B /fs_license:/fs_license \
                     /path/fastsurfer.sif /fastsurfer/run_fastsurfer.sh" \
  --fs_license /fs_license/license.txt \
  --parallel 4 --threads 4
```

Praktisch wenn du brun lokal aufrufen willst aber jeden Subject in einem isolierten Container-Run laufen lassen möchtest.

### SLURM-Array-Awareness

`brun_fastsurfer.sh` erkennt automatisch wenn es in einem SLURM-Job-Array läuft (`$SLURM_ARRAY_TASK_ID` / `$SLURM_ARRAY_TASK_COUNT`) und teilt die Subject-Liste entsprechend auf. Manuelles Override via `--batch <i>/<n>`.

## srun_fastsurfer.sh

Höher-level SLURM-Orchestrator. Submittet **drei dependent Jobs**:

1. **Seg-Job** (GPU-Partition).
2. **Surf-Job** (CPU-Partition), abhängig von Seg-Job-Success.
3. **Cleanup-Job**, kopiert Outputs vom Work-Directory ins finale Subjects-Dir.

### Standard-Aufruf

```bash
srun_fastsurfer.sh \
  --partition seg=GPU_Partition \
  --partition surf=CPU_Partition \
  --sd $HOME/my_fastsurfer_analysis \
  --data $HOME/my_mri_data \
  --pattern "*/t1-weighted.nii.gz" \
  --remove_suffix /t1-weighted.nii.gz \
  --singularity_image $HOME/images/fastsurfer-singularity.sif \
  --fs_license $HOME/my_fs_license.txt \
  --3T
```

### Data-Spec

Zwei Wege Subjects zu definieren:

1. **`--data <root> --pattern <glob>`**: scant `<root>` mit Glob.
   ```
   --data /data/raw --pattern "*/anat/t1.nii.gz"
   ```
   Subject-IDs werden automatisch aus Pfaden gebildet.

2. **`--subject_list <file>`**: explizite Liste (Format: `subject_id=path` per default; anpassbar via `--subject_list_delim`, `--subject_list_awk_code_sid`, `--subject_list_awk_code_args`).

   Erweitertes Beispiel mit CSV-Format:
   ```
   --subject_list_delim ","
   --subject_list_awk_code_args '$2 " --vox_size " $4'
   ```
   Verarbeitet Zeilen wie:
   ```
   subject-101,raw/T1w-101A.nii.gz,study-1,0.9
   ```
   → `--sid subject-101 --t1 <data>/raw/T1w-101A.nii.gz --vox_size 0.9`

### Work-Directory

```
--work <fast-IO-directory>
```

Default: `$HPCWORK/fastsurfer-processing/<YYMMDD-HHMMSS>`. Alle IO läuft hier; nach Erfolg wird kopiert in `--sd` und Work-Dir gelöscht. Wichtig auf Clustern mit Lustre/GPFS — Work-Dir auf NVMe oder Node-Local für Performance.

### Resource-Specs

| Flag | Wirkung |
|------|---------|
| `--partition seg=<p>` | SLURM-Partition für Seg-Job |
| `--partition surf=<p>` | SLURM-Partition für Surf-Job |
| `--partition <p>` | Für beide identisch |
| `--time_seg <hh:mm:ss>` | Timelimit Seg |
| `--time_surf <hh:mm:ss>` | Timelimit Surf |
| `--mem_seg <int>` | Memory in GB für Seg |
| `--mem_surf <int>` | Memory in GB für Surf |
| `--num_cpus_per_task <n>` | CPUs allocation pro Task |
| `--num_cases_per_task <n>` | Wieviele Subjects ein Array-Task verarbeitet |
| `--cpu_only` | Kein GPU, alles auf CPU |
| `--slurm_jobarray <spec>` | Manueller JobArray-Spec, z.B. `1-100%10` |

### Singularity-Optionen

```
--singularity_image <path>           Default: $HOME/singularity-images/fastsurfer.sif
--extra_singularity_options "..."    extra für beide Jobs
--extra_singularity_options_seg "..."  extra nur Seg
--extra_singularity_options_surf "..." extra nur Surf
```

Beispiel um Custom-Checkpoints einzubinden:

```bash
--extra_singularity_options "-B /shared/custom_weights:/fastsurfer/checkpoints"
```

### Dry-Run + Debug

```bash
srun_fastsurfer.sh ... --dry --debug
```

`--dry`: macht alles ausser tatsächlich `sbatch`. Gut zum Inspect der generierten Scripts.
`--debug`: viel mehr Output.

Generierte SLURM-Scripts und Logs landen in `$SUBJECTS_DIR/slurm/scripts/` und `$SUBJECTS_DIR/slurm/logs/`.

### Email-Notification

```bash
srun_fastsurfer.sh ... --email user@example.com
```

SLURM-Mail-Notification bei Job-Completion/Failure.

### Skip-Cleanup

```bash
srun_fastsurfer.sh ... --skip_cleanup
```

Lässt das Work-Directory intakt — nützlich zum Debuggen oder wenn du selber kopieren möchtest.

## Wann brun vs srun

| Szenario | Tool |
|----------|------|
| 1-10 Subjects, eine Workstation | `brun_fastsurfer.sh --parallel N` |
| 10-50 Subjects, eine Workstation mit mehreren GPUs | `brun_fastsurfer.sh --parallel_seg N --parallel_surf M` |
| 50+ Subjects, HPC-Cluster | `srun_fastsurfer.sh` |
| Single-Subject im Container | `run_fastsurfer.sh` direkt |
| Cluster ohne SLURM (z.B. PBS, SGE) | `brun_fastsurfer.sh` in einem eigenen Submit-Script |

## Cross-Reference

- Container-Wrapping-Details: `fastsurfer-container`
- Welche Flags weitergereicht werden: `fastsurfer-cli-flags`
- Longitudinal-Workflow: `fastsurfer-longitudinal`
- Wenn ein Subject failt: `fastsurfer-debug-outputs`
