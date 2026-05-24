---
name: fastsurfer-container
description: Use when the user wants to run FastSurfer in Docker or Singularity/Apptainer, asks about container flags, volume mounting, GPU passthrough, image variants, or troubleshooting container-specific issues. Triggers on "fastsurfer docker", "fastsurfer singularity", "fastsurfer container", "deepmi/fastsurfer", "apptainer", "container GPU", "--gpus", "-v", "-B", "user permissions container".
---

# FastSurfer — Container-Workflows (Docker + Singularity)

Offizielle Images sind auf DockerHub unter `deepmi/fastsurfer`. Singularity-Images werden meist aus Docker-Images konvertiert.

## Image-Varianten

| Tag | Inhalt |
|-----|--------|
| `deepmi/fastsurfer:latest` | GPU (CUDA) + alles drin (FreeSurfer-Binaries, Checkpoints, Python-Env) |
| `deepmi/fastsurfer:cpu-latest` | Kleinere CPU-only Variante (kein CUDA-Stack) |
| `deepmi/fastsurfer:gpu-latest` | Explizit GPU |
| `deepmi/fastsurfer:cc-latest` | Mit FastSurfer-CC-Spezialdependencies |
| Spezifische Versionen | z.B. `deepmi/fastsurfer:v2.4.0` |

Liste aller Tags: https://hub.docker.com/r/deepmi/fastsurfer/tags

## Docker

### Standard-Run (GPU)

```bash
docker run --gpus all \
  -v $HOME/my_mri_data:$HOME/my_mri_data \
  -v $HOME/my_fastsurfer_analysis:$HOME/my_fastsurfer_analysis \
  -v $HOME/my_fs_license.txt:$HOME/my_fs_license.txt \
  --rm --user $(id -u):$(id -g) \
  deepmi/fastsurfer:latest \
    --fs_license $HOME/my_fs_license.txt \
    --t1 $HOME/my_mri_data/subjectX/t1.nii.gz \
    --sid subjectX \
    --sd $HOME/my_fastsurfer_analysis \
    --3T --threads 4
```

### Docker-Flags-Cheatsheet

| Flag | Wirkung |
|------|---------|
| `--gpus all` | Alle GPUs durchreichen |
| `--gpus device=0` | Nur GPU 0 |
| `--gpus 'device=0,1,3'` | Mehrere spezifische GPUs |
| (kein `--gpus`) | CPU-only Mode |
| `-v <host>:<container>` | Volume-Mount; identischer Pfad innerhalb/ausserhalb empfohlen |
| `--rm` | Container nach Run löschen |
| `--user $(id -u):$(id -g)` | Run als Host-User (Output-Files gehören dir, nicht root) |
| `--entrypoint <cmd>` | Override Default-Entrypoint (z.B. für `brun_fastsurfer.sh`) |

### CPU-Only-Run

```bash
docker run \
  -v $HOME/my_mri_data:$HOME/my_mri_data \
  -v $HOME/my_fastsurfer_analysis:$HOME/my_fastsurfer_analysis \
  -v $HOME/my_fs_license.txt:$HOME/my_fs_license.txt \
  --rm --user $(id -u):$(id -g) \
  deepmi/fastsurfer:cpu-latest \
    --fs_license $HOME/my_fs_license.txt \
    --t1 $HOME/my_mri_data/subjectX/t1.nii.gz \
    --sid subjectX --sd $HOME/my_fastsurfer_analysis \
    --device cpu --viewagg_device cpu --threads max
```

### Batch via Docker

`brun_fastsurfer.sh` braucht eigenen Entrypoint:

```bash
docker run --gpus all \
  -v $HOME/my_mri_data:/data \
  -v $HOME/my_fastsurfer_analysis:/output \
  -v $HOME/my_fs_license_dir:/fs_license \
  --entrypoint "/fastsurfer/brun_fastsurfer.sh" \
  --rm --user $(id -u):$(id -g) \
  deepmi/fastsurfer:latest \
    --fs_license /fs_license/license.txt \
    --sd /output --subject_list /data/subjects_list.txt \
    --3T --threads 4
```

Subject-list-Format (one per line):

```
subject1=/data/sub1/t1.nii.gz
subject2=/data/sub2/t1.nii.gz
```

Pfade müssen **container-internal** sein (also unter den `-v <host>:<container>` Mappings).

## Singularity / Apptainer

### Image bauen

```bash
# Aus Docker-Image
singularity build fastsurfer-gpu.sif docker://deepmi/fastsurfer:latest
singularity build fastsurfer-cpu.sif docker://deepmi/fastsurfer:cpu-latest
```

### Standard-Run (GPU)

```bash
singularity exec --nv \
  --no-mount home,cwd -e \
  -B $HOME/my_mri_data:$HOME/my_mri_data \
  -B $HOME/my_fastsurfer_analysis:$HOME/my_fastsurfer_analysis \
  -B $HOME/my_fs_license.txt:$HOME/my_fs_license.txt \
  ./fastsurfer-gpu.sif \
    /fastsurfer/run_fastsurfer.sh \
      --fs_license $HOME/my_fs_license.txt \
      --t1 $HOME/my_mri_data/subjectX/t1.nii.gz \
      --sid subjectX \
      --sd $HOME/my_fastsurfer_analysis \
      --3T --threads 4
```

### Singularity-Flags-Cheatsheet

| Flag | Wirkung |
|------|---------|
| `--nv` | GPU-Passthrough (NVIDIA) |
| `--no-mount home,cwd` | Verhindert automatisches Mount von $HOME und cwd |
| `-e` / `--cleanenv` | Saubere Environment (kein Host-env-leakage) |
| `-B <host>:<container>` | Bind-Mount |
| `--rocm` | AMD-GPU statt NVIDIA |

`singularity run ./fastsurfer.sif --t1 ... --sid ...` ist eine Kurzform die den default-Entrypoint `run_fastsurfer.sh` nutzt.

### Batch via Singularity

```bash
singularity exec --nv --no-home \
  -B $HOME/my_mri_data:/data \
  -B $HOME/my_fastsurfer_analysis:/output \
  -B $HOME/my_fs_license_dir:/fs_license \
  ./fastsurfer-gpu.sif \
    /fastsurfer/brun_fastsurfer.sh \
      --fs_license /fs_license/license.txt \
      --sd /output --subject_list /data/subjects_list.txt \
      --3T --threads 4
```

## Pfad-Konventionen (kritisch)

Zwei Schulen für Volume-Mounting:

1. **Identische Pfade host↔container** (empfohlen für Mac/Dev):
   ```
   -v $HOME/foo:$HOME/foo
   --t1 $HOME/foo/sub/t1.nii.gz
   ```
   Vorteil: kein Pfad-Übersetzen nötig.

2. **Konventional-Mounts** (empfohlen für Container-Cluster):
   ```
   -v $HOME/foo:/data
   --t1 /data/sub/t1.nii.gz
   ```
   Vorteil: Subject-Listen können konstante Pfade enthalten.

Pfade in `--t1`, `--sd`, `--fs_license`, etc. müssen IMMER **container-intern** sein.

## User-Permission-Problem (Docker)

Ohne `--user $(id -u):$(id -g)` laufen Container als root → Output-Files gehören root, du kannst sie nicht löschen ohne `sudo`.

Mit `--user $(id -u):$(id -g)`: Output-Files gehören dir.

Singularity erbt per Default die User-ID des Aufrufers — kein `--user`-Flag nötig.

## macOS-Spezifika

- **Docker Desktop auf macOS:** funktioniert für CPU-Workflows. GPU-Passthrough wird auf macOS **nicht** unterstützt (Apple Silicon hat keine CUDA-GPUs; Intel-Macs mit eGPU sind nicht offiziell supportet).
- **macOS native install** (alternativ): siehe Skill `fastsurfer-overview`-Sektion zu Install + `doc/overview/MACOS.md` im FastSurfer-Repo.
- **Apple Silicon (M-Serie):** läuft auf CPU. MPS (Metal Performance Shaders) wird derzeit nicht vom FastSurfer-PyTorch-Code als Backend unterstützt — `--device cpu` ist die richtige Wahl.

## Common Container-Errors

| Error | Ursache | Fix |
|-------|---------|-----|
| `permission denied` beim Output | Container läuft als root | `--user $(id -u):$(id -g)` (Docker) |
| `nvidia-container-cli: requirement error` | NVIDIA-Container-Toolkit fehlt | NVIDIA-Container-Toolkit installieren |
| `No CUDA-capable device` | `--gpus all` fehlt oder GPU nicht durchgereicht | `--gpus all` (Docker), `--nv` (Singularity) |
| `FreeSurfer license file not found` | License nicht gemountet oder falscher Pfad | `-v <license>:<license>` und gleichen Pfad in `--fs_license` nutzen |
| `Path is not absolute` | Relative Pfade an FastSurfer | alle Pfad-Flags absolut machen |
| Image-Pull-Timeout | Slow Network / Rate-Limit auf DockerHub | manuell `docker pull deepmi/fastsurfer:latest` vorher |

## Cross-Reference

- Batch + SLURM-Wrapper: `fastsurfer-batch-slurm`
- License-Probleme im Detail: `fastsurfer-debug-license`
- GPU-/Memory-Issues: `fastsurfer-debug-gpu-memory`
- CLI-Flags die im Container weitergegeben werden: `fastsurfer-cli-flags`
