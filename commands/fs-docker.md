---
description: FastSurfer Docker-Wrapper — auto-konstruiert `docker run`-Command mit GPU/Volume-Mounts.
allowed-tools: Bash, Read
argument-hint: "<t1_path> <sid> [<extra-flags>]"
---

Docker-basierter FastSurfer-Run für $ARGUMENTS. Wrappt `deepmi/fastsurfer:latest`.

## Pre-Flight

```bash
# Docker verfügbar?
command -v docker >/dev/null 2>&1 || { echo "FAIL: docker nicht im PATH"; exit 1; }
docker info >/dev/null 2>&1 || { echo "FAIL: Docker-Daemon läuft nicht"; exit 1; }

# Image vorhanden?
docker image inspect deepmi/fastsurfer:latest >/dev/null 2>&1 || {
  echo "Image nicht lokal — werde es bei Run automatisch pullen (~5-10 GB)."
}

# GPU verfügbar?
if docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
  GPU_FLAG="--gpus all"
  echo "GPU available — using GPU mode"
else
  GPU_FLAG=""
  IMAGE_TAG="cpu-latest"
  echo "No GPU — falling back to CPU image"
fi
```

## Aufruf-Pattern (GPU, identische Pfade)

```bash
T1="<absolute-T1>"
SID="<sid>"

docker run --gpus all \
  -v "$(dirname $T1)":"$(dirname $T1)" \
  -v "$SUBJECTS_DIR":"$SUBJECTS_DIR" \
  -v "$FS_LICENSE":"$FS_LICENSE" \
  --rm --user $(id -u):$(id -g) \
  deepmi/fastsurfer:latest \
    --fs_license "$FS_LICENSE" \
    --t1 "$T1" \
    --sid "$SID" \
    --sd "$SUBJECTS_DIR" \
    --3T --threads 4 \
    <user-extra-flags>
```

## Aufruf-Pattern (CPU)

```bash
docker run \
  -v "$(dirname $T1)":"$(dirname $T1)" \
  -v "$SUBJECTS_DIR":"$SUBJECTS_DIR" \
  -v "$FS_LICENSE":"$FS_LICENSE" \
  --rm --user $(id -u):$(id -g) \
  deepmi/fastsurfer:cpu-latest \
    --fs_license "$FS_LICENSE" \
    --t1 "$T1" \
    --sid "$SID" \
    --sd "$SUBJECTS_DIR" \
    --device cpu --viewagg_device cpu \
    --3T --threads max \
    <user-extra-flags>
```

## macOS-Spezifika

- **Apple Silicon (M-Serie):** kein GPU-Passthrough. Immer `cpu-latest`. PyTorch in dem Image nutzt CPU-Backend.
- **Docker Desktop Memory:** Default 8GB ist knapp. Im Docker-Desktop-Settings auf 16+ GB hochsetzen.
- **Volume-Performance:** macOS `osxfs` ist langsam. Wenn IO bottleneck: VirtioFS aktivieren (Docker Desktop Settings → File Sharing → VirtioFS).

## Batch via Docker

Wenn User mehrere Subjects will:

```bash
docker run --gpus all \
  -v "$DATA_DIR":/data \
  -v "$SUBJECTS_DIR":/output \
  -v "$FS_LICENSE":/fs_license/license.txt \
  --entrypoint "/fastsurfer/brun_fastsurfer.sh" \
  --rm --user $(id -u):$(id -g) \
  deepmi/fastsurfer:latest \
    --fs_license /fs_license/license.txt \
    --sd /output \
    --subject_list /data/subjects_list.txt \
    --3T --threads 4 \
    <user-extra-flags>
```

## Permission-Fix

Wenn vorherige Runs Files als `root` erzeugt haben:

```bash
sudo chown -R $(id -u):$(id -g) "$SUBJECTS_DIR/<SID>"
```

Für künftige Runs `--user $(id -u):$(id -g)` setzen.

## Cross-Reference

- Container-Details + Singularity: Skill `fastsurfer-container`
- macOS-Workflows: gleicher Skill, Sektion "macOS-Spezifika"
- Wenn Lizenz nicht findet: Skill `fastsurfer-debug-license`, Sektion "Container-Spezifika"
