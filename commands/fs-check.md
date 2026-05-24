---
description: Diagnose-Smoke-Test für FastSurfer-Setup — Install, License, GPU, Checkpoints, FreeSurfer-Env.
allowed-tools: Bash, Read
---

Führt einen vollständigen Smoke-Test des FastSurfer-Setups aus. Args: ggf. `--full` für Tiefen-Test inkl. Tutorial-Image.

## Checks

Führe alle parallel aus, fasse Ergebnisse strukturiert zusammen.

### 1. FastSurfer-Repo

```bash
FASTSURFER_HOME="${FASTSURFER_HOME:-/Users/marcusifland/prj/fastsurfer}"
echo "FASTSURFER_HOME=$FASTSURFER_HOME"

[ -d "$FASTSURFER_HOME" ] && echo "  [OK] Verzeichnis existiert" || echo "  [FAIL] Verzeichnis fehlt"
[ -x "$FASTSURFER_HOME/run_fastsurfer.sh" ] && echo "  [OK] run_fastsurfer.sh ausführbar" || echo "  [FAIL] run_fastsurfer.sh fehlt/nicht ausführbar"
[ -x "$FASTSURFER_HOME/brun_fastsurfer.sh" ] && echo "  [OK] brun_fastsurfer.sh" || echo "  [WARN] brun_fastsurfer.sh"
[ -x "$FASTSURFER_HOME/long_fastsurfer.sh" ] && echo "  [OK] long_fastsurfer.sh" || echo "  [WARN] long_fastsurfer.sh"
[ -x "$FASTSURFER_HOME/srun_fastsurfer.sh" ] && echo "  [OK] srun_fastsurfer.sh" || echo "  [WARN] srun_fastsurfer.sh"
```

### 2. Version + Checkpoints

```bash
bash "$FASTSURFER_HOME/run_fastsurfer.sh" --version +git+checkpoints 2>&1 | head -30
```

### 3. Python-Environment

```bash
python3 -c "
import sys
print(f'  Python: {sys.version.split()[0]}')
modules = ['torch', 'nibabel', 'numpy', 'monai', 'lapy', 'h5py', 'scipy', 'skimage']
for m in modules:
    try:
        mod = __import__(m)
        v = getattr(mod, '__version__', '?')
        print(f'  [OK] {m} {v}')
    except ImportError as e:
        print(f'  [FAIL] {m}: {e}')
"
```

### 4. GPU / CUDA

```bash
python3 -c "
import torch
print(f'  PyTorch: {torch.__version__}')
print(f'  CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'  CUDA version: {torch.version.cuda}')
    print(f'  Device count: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'    GPU {i}: {torch.cuda.get_device_name(i)} ({torch.cuda.get_device_properties(i).total_memory / 1e9:.1f} GB)')
else:
    print('  Mode will fall back to CPU')
"

command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null
```

### 5. FreeSurfer-Environment (für Surface-Pipeline)

```bash
echo "FREESURFER_HOME=${FREESURFER_HOME:-<not set>}"
if [ -n "$FREESURFER_HOME" ]; then
  [ -d "$FREESURFER_HOME" ] && echo "  [OK] FREESURFER_HOME existiert" || echo "  [FAIL] FREESURFER_HOME existiert nicht"
  [ -x "$FREESURFER_HOME/bin/recon-all" ] && echo "  [OK] recon-all ausführbar" || echo "  [FAIL] recon-all fehlt"
  [ -f "$FREESURFER_HOME/build-stamp.txt" ] && echo "  Version: $(cat $FREESURFER_HOME/build-stamp.txt)"
else
  echo "  [INFO] Nicht gesetzt — Surface-Pipeline funktioniert nicht ohne 'source SetUpFreeSurfer.sh'"
fi
```

### 6. FreeSurfer-License

```bash
FS_LICENSE_PATH="${FS_LICENSE:-$HOME/freesurfer_license.txt}"
echo "FS_LICENSE=$FS_LICENSE_PATH"
if [ -f "$FS_LICENSE_PATH" ]; then
  echo "  [OK] License-File existiert"
  echo "  Lines: $(wc -l < $FS_LICENSE_PATH)"
  echo "  Erste Zeile: $(head -1 $FS_LICENSE_PATH | cut -c1-30)..."
else
  echo "  [FAIL] License-File nicht gefunden"
  echo "  Register: https://surfer.nmr.mgh.harvard.edu/registration.html"
fi
```

### 7. SUBJECTS_DIR

```bash
echo "SUBJECTS_DIR=${SUBJECTS_DIR:-<not set>}"
[ -n "$SUBJECTS_DIR" ] && [ -w "$SUBJECTS_DIR" ] && echo "  [OK] writable" || echo "  [WARN] nicht gesetzt oder nicht writable"
```

### 8. Disk-Space

```bash
df -h "${SUBJECTS_DIR:-$HOME}" | tail -1
```

Subject braucht ~500-800 MB. Bei <10 GB free → WARN.

### 9. (optional `--full`) Test-Run

Wenn User `--full` mitgegeben hat, lade Tutorial-Image und führe Quick-Run aus:

```bash
TUTORIAL_T1="${FASTSURFER_HOME}/test/image/test.nii.gz"
if [ -f "$TUTORIAL_T1" ]; then
  TEST_SID="fs_check_test_$(date +%s)"
  bash "$FASTSURFER_HOME/run_fastsurfer.sh" \
    --t1 "$TUTORIAL_T1" \
    --sid "$TEST_SID" \
    --sd "/tmp/fs_check" \
    --seg_only --no_cereb --no_hypothal --no_cc \
    --threads 4 \
    2>&1 | tail -50
  ls "/tmp/fs_check/$TEST_SID/mri/" 2>/dev/null | head -5
  # Cleanup
  rm -rf "/tmp/fs_check/$TEST_SID"
fi
```

## Output-Format

Strukturiere Ergebnis als Markdown-Tabelle:

```
| Check | Status | Detail |
|-------|--------|--------|
| FastSurfer-Repo | OK | /Users/.../fastsurfer @ v2.6.0-dev |
| Python-Env | OK | torch 2.x, nibabel 5.4 |
| GPU | WARN | No CUDA — CPU mode only |
| FreeSurfer-Env | FAIL | $FREESURFER_HOME not set |
| License | OK | ~/freesurfer_license.txt |
| SUBJECTS_DIR | OK | /Volumes/data/subjects |
| Disk | OK | 240 GB free |
```

Bei FAIL/WARN → kurzer Fix-Hint mit Verweis auf passenden Debug-Skill.

## Cross-Reference

- License-Probleme: `fastsurfer-debug-license`
- GPU-Probleme: `fastsurfer-debug-gpu-memory`
- Container-Setup: `fastsurfer-container`
