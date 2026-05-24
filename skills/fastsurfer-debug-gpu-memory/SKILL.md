---
name: fastsurfer-debug-gpu-memory
description: Use when FastSurfer crashes with CUDA-OOM, GPU not detected, slow inference, or the user wants to tune device/threads/batch settings for performance. Triggers on "CUDA out of memory", "OOM", "GPU not detected", "FastSurfer slow", "viewagg_device", "batch size", "thread tuning", "--device cuda", "torch CUDA error", "memory error".
---

# FastSurfer — GPU / Memory / Device Debug

FastSurfer ist GPU-optimiert aber kann auf CPU laufen. Performance- und Memory-Probleme sind meist mit `--device`, `--viewagg_device`, `--batch`, `--threads*` lösbar.

## "GPU not detected"

```bash
# Was sieht PyTorch?
python3 -c "import torch; print('cuda?', torch.cuda.is_available(), 'devs:', torch.cuda.device_count())"

# Was sieht die Shell?
nvidia-smi
```

**Wenn `nvidia-smi` läuft aber PyTorch sagt nein:** CUDA-Version mismatch zwischen NVIDIA-Driver und PyTorch-Build.

```bash
nvidia-smi | head -5            # zeigt Driver + max CUDA-Version
python3 -c "import torch; print(torch.version.cuda)"   # zeigt PyTorch-CUDA-Version
```

PyTorch braucht eine CUDA-Version ≤ Driver-Max. Fix:
- Driver upgraden, oder
- PyTorch mit niedrigerer CUDA-Version installieren (z.B. `pip install torch --index-url https://download.pytorch.org/whl/cu118`).

**Wenn weder `nvidia-smi` noch PyTorch GPU sehen:**
- NVIDIA-Driver nicht installiert.
- macOS: keine CUDA-GPUs → muss CPU nutzen.
- AMD: kein offizieller Support (ROCm theoretisch, aber nicht standard).

**Im Container:**
- Docker: `--gpus all` Flag vergessen.
- Singularity: `--nv` Flag vergessen.
- NVIDIA-Container-Toolkit nicht installiert.

## CUDA Out of Memory

```
RuntimeError: CUDA out of memory. Tried to allocate X.XX GiB...
```

### Strategie 1 — View-Aggregation auf CPU

```bash
run_fastsurfer.sh ... --viewagg_device cpu
```

View-Aggregation kombiniert die drei Multi-View-Predictions (Coronal+Axial+Sagittal) zu einem 3D-Volume. Das braucht viel Memory wenn auf GPU. Mit `--viewagg_device cpu` wird's auf CPU gemacht — etwas langsamer, aber sicher.

Default ist `auto` — FastSurfer prüft den Memory und fällt automatisch auf CPU wenn nicht genug GPU-RAM. Wenn das nicht greift (false-positive Memory-Check), explizit setzen.

### Strategie 2 — Kleinere Batch-Size

```bash
run_fastsurfer.sh ... --batch 1
```

Default ist bereits 1. Wenn du höher gesetzt hattest → zurück auf 1.

### Strategie 3 — Spezifische GPU mit mehr Memory

```bash
run_fastsurfer.sh ... --device cuda:1   # GPU 1 statt 0
```

Wenn du mehrere GPUs hast, schau mit `nvidia-smi` welche mehr freien Memory hat.

### Strategie 4 — CPU-only Fallback

```bash
run_fastsurfer.sh ... --device cpu --viewagg_device cpu --threads max
```

Deutlich langsamer (Faktor 10-20×) aber funktioniert garantiert. Sinnvoll für single-subject Debugging.

## "Inference ist sehr langsam"

Erwartete Timings auf moderner GPU (z.B. RTX 3090 / A100):

| Workload | Zeit |
|----------|------|
| asegdkt full | ~3-5 Min |
| asegdkt + cereb + hypothal + cc | ~5-8 Min |
| Surf (mit `--threads 4`) | ~45-90 Min |
| Full Pipeline | ~50-100 Min |

Wenn deutlich langsamer:

### Check 1 — Läuft wirklich GPU?

```bash
# Während Inference in einem zweiten Terminal:
nvidia-smi
# Wenn Memory-Usage da hochgeht und ein Python-Process listed wird → GPU läuft.
# Wenn nicht → falsche --device Auswahl oder PyTorch-CUDA-Bug.
```

### Check 2 — View-Aggregation auf CPU?

`--viewagg_device cpu` ist langsamer als GPU. Wenn du genug VRAM hast, expliziet `--viewagg_device cuda` setzen.

### Check 3 — Threads zu niedrig

```bash
run_fastsurfer.sh ... --threads max
```

`--threads max` nutzt alle verfügbaren Cores. Bei 8-Core+Hyperthreading wird das 16. Speziell für die Surface-Pipeline ist das wichtig.

Granularer:

| Flag | Wo aktiv |
|------|---------|
| `--threads <n>` | global |
| `--threads_seg <n>` | nur Segmentation |
| `--threads_surf <n>` | nur Surface; ≥2 parallel-Hemis |

### Check 4 — Storage IO

Wenn `$SUBJECTS_DIR` auf langsamen Storage liegt (Netzwerk-Mount, slow HDD): IO wird zum Bottleneck. Fix:
- `$SUBJECTS_DIR` auf SSD/NVMe legen.
- Auf Clustern: Work-Dir auf Node-local (siehe `srun_fastsurfer.sh --work`).

### Check 5 — Image-Resolution

Hi-Res-Inputs (0.7mm) sind deutlich langsamer als 1mm. Wenn du nicht zwingend Hi-Res brauchst, `--vox_size 1.0` setzen.

## Memory-Tuning per Modul

| Modul | VRAM (typisch) | Notizen |
|-------|---------------|---------|
| asegdkt (FastSurferVINN) | 4-6 GB pro View | View-Aggregation kann zusätzlich 3-4 GB brauchen |
| CerebNet | 2-3 GB | Crop-basiert, kleinerer Footprint |
| HypVINN | 3-4 GB | Multi-View, +T2-Channel wenn aktiv |
| CC | 1-2 GB | kleinster Input-Crop |
| Surface | CPU-only | kein GPU-Bedarf |

Für 8GB GPUs:
- `--viewagg_device cpu` Pflicht.
- `--batch 1`.
- HypVINN ggf. ohne T2 (`--no_hypothal` oder ohne `--t2`).

Für 4GB GPUs:
- `--device cpu` empfohlen — Skipping zwischen Modulen kann sonst flaky werden.

Für 24GB+ GPUs:
- Alles auf GPU (`--viewagg_device cuda`).
- Kann mehrere Subjects parallel: `brun_fastsurfer.sh --parallel 2 --device cuda:0` (für 2 Subjects auf einer 24GB-GPU, vorsichtig).

## "torch CUDA error" am Pipeline-Start

```
torch.cuda.OutOfMemoryError: CUDA out of memory.
```

direkt am Start (vor jeder Inference) deutet auf:
- Andere Processes nutzen die GPU (z.B. Browser mit GPU-Acceleration). → `nvidia-smi` checken, andere processes killen.
- CUDA-Cache nicht freigegeben von vorherigem Crash. → reboot oder `python3 -c "import torch; torch.cuda.empty_cache()"`.

## CPU-only-Mode optimal nutzen

```bash
run_fastsurfer.sh \
  --device cpu --viewagg_device cpu \
  --threads max \
  --threads_seg max \
  --threads_surf max \
  --batch 1 \
  ...
```

Auf macOS Apple Silicon: das ist der einzige Mode. `--threads max` auf einem M3 Pro/Max gibt brauchbare Performance (Faktor 3-5× langsamer als RTX 3090 GPU).

Wenn du Apple-MPS (Metal Performance Shaders) für PyTorch versuchen willst: aktuell **nicht offiziell von FastSurfer supportet**. Theoretisch via `--device mps` setzbar wenn PyTorch MPS-Backend aktiv ist, aber Result-Konsistenz nicht garantiert.

## Disk-Memory

Pro Subject Disk-Verbrauch:

| Pipeline-Subset | Disk |
|-----------------|------|
| `--seg_only` only asegdkt | ~50 MB |
| `--seg_only` alle Module | ~150 MB |
| Full Pipeline | ~500-800 MB |
| Full Pipeline + LIT | ~700-1000 MB |
| Highres (0.7mm) | etwa 2× |
| Longitudinal (Template + 3 TPs) | ~2-3 GB |

Auf Cluster-Storage immer Subject-Counts × diese Werte planen.

## Cross-Reference

- Welche Flags Device/Threads steuern: `fastsurfer-cli-flags`
- Container-spezifische GPU-Probleme: `fastsurfer-container`
- Output fehlt nach Crash: `fastsurfer-debug-outputs`
- License-bezogene Crashes: `fastsurfer-debug-license`
