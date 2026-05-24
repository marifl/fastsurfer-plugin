---
description: Starte NextBrain Bayesian-Segmentation (mri_histo_atlas_segment_fireants) fuer einen Subject. 333 ROIs, FreeSurfer-dev.
allowed-tools: Bash, Read
argument-hint: "<t1_path> <output_dir> [<side>=both] [<mode>=invivo] [<extra-flags>]"
---

Starte NextBrain-Segmentation fuer `$ARGUMENTS` via `mri_histo_atlas_segment_fireants`.

Default: beide Hemispheres (sequentiell), in-vivo Mode, automatische GPU-Detection.

## Pre-Flight

```bash
T1="<absolute-T1-path>"
OUT="<output-dir>"
SIDE="<side|both>"   # left, right, both
MODE="<mode|invivo>" # invivo, cerebrum, hemi, exvivo

# Validate T1
[ -f "$T1" ] || { echo "FAIL: $T1 nicht gefunden"; exit 1; }
[[ "$T1" = /* ]] || { echo "FAIL: $T1 muss absoluter Pfad sein"; exit 1; }

# Output dir vorbereiten
mkdir -p "$OUT"
[ -w "$OUT" ] || { echo "FAIL: $OUT nicht writable"; exit 1; }

# mri_histo_atlas_segment_fireants verfügbar?
command -v mri_histo_atlas_segment_fireants >/dev/null 2>&1 || {
  echo "FAIL: mri_histo_atlas_segment_fireants nicht im PATH."
  echo "      Brauchst du FreeSurfer-DEV (nicht stable). Source dein FreeSurfer-dev Environment."
  echo "      Repo: https://github.com/freesurfer/freesurfer/tree/dev/mri_histo_util"
  exit 1
}

# GPU verfügbar?
if python3 -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
  DEVICE="cuda"
  echo "GPU detected — using --device cuda"
else
  DEVICE="cpu"
  echo "No GPU — falling back to --device cpu (will be slow: 1-2h per hemisphere)"
fi

# Mode-Check fuer ex-vivo: braucht RAS-Orientation
if [[ "$MODE" =~ exvivo|cerebrum|hemi ]]; then
  echo "WARN: Mode '$MODE' erwartet RAS-Orientation."
  echo "      Falls dein Scan nicht RAS ist: erst 'mri_convert --out_orientation RAS ...' machen."
fi

# Ex-vivo-Mode-Check
```

## Aufruf-Pattern (single side)

```bash
mri_histo_atlas_segment_fireants \
  --i "$T1" \
  --o "$OUT" \
  --device "$DEVICE" \
  --side "$SIDE" \
  --mode "$MODE" \
  <user-extra-flags>
```

## Aufruf-Pattern (beide Hemis, sequentiell)

Wenn `--side both` (Default):

```bash
# Linke Hemi zuerst (SuperSynth wird gecached)
mri_histo_atlas_segment_fireants \
  --i "$T1" --o "$OUT" \
  --device "$DEVICE" --side left --mode "$MODE" \
  <user-extra-flags>

# Rechte Hemi (reuse SuperSynth-Cache, ~30% schneller)
mri_histo_atlas_segment_fireants \
  --i "$T1" --o "$OUT" \
  --device "$DEVICE" --side right --mode "$MODE" \
  <user-extra-flags>
```

**Wichtig:** sequentiell, NICHT parallel. NextBrain reuses SuperSynth-Stage-Outputs aus dem `$OUT/SuperSynth/`-Cache.

## Memory-Tuning bei GPU-OOM

Frag den User wenn GPU < 12 GB ist:

| Strategy | Flag |
|----------|------|
| Schrittweise downsamplen | `--skip 2` (oder `--skip 3`) |
| Registration auf CPU lagern | `--device cuda --device_registration cpu` |
| Komplett CPU-only | `--device cpu` |

## First-Run-Hinweis

Wenn NextBrain noch nie auf dieser Machine lief:

```
WARN: Erster Run triggert Downloads:
      - NextBrain Atlas-Files (~mehrere GB)
      - BrainFM mri_super_synth Model
      Beide werden in $FREESURFER_HOME gecached.
      User wird interaktiv via Prompt gefragt — bestaetigen mit y.
      Download-Zeit: 5-20 Min je nach Bandbreite.
```

## Erwartete Outputs

Im `$OUT/`:

```
seg.left.nii.gz                Segmentation links (~333 ROIs)
seg.right.nii.gz               Segmentation rechts
lut.txt                        Lookup-Table fuer FreeView-Visualisierung
vols.left.csv                  Volumetric-Stats links
vols.right.csv                 Volumetric-Stats rechts
SuperSynth/                    Pre-Stage Whole-Structure-Foundation-Model-Output
```

Plus optional je nach Flags: `bias_corrected.nii.gz`, `field.nii.gz`, `jacobian.nii.gz`, `atlas_warped.nii.gz`.

## Erwartete Laufzeit

| Setup | Pro Hemisphere |
|-------|----------------|
| GPU (CUDA), default | ~30 Min |
| GPU + `--skip 2` | ~15-20 Min |
| GPU + `--device_registration cpu` | ~40-50 Min |
| CPU only | ~1-2h |
| Ex-vivo 0.25mm CPU | ~2h |

Beide Hemis: ~50-90 Min auf GPU, ~2-4h auf CPU.

**Tipp:** Bei langen Runs `run_in_background: true` setzen.

## Visualization nach Abschluss

```bash
freeview \
  -v "$T1" \
  -v "$OUT/seg.left.nii.gz:colormap=lut:lut=$OUT/lut.txt:opacity=0.5" \
  -v "$OUT/seg.right.nii.gz:colormap=lut:lut=$OUT/lut.txt:opacity=0.5" &
```

## Volumetrics-Inspection

```bash
echo "=== Top 20 Volumes (left) ==="
sort -t, -k2 -n -r "$OUT/vols.left.csv" | head -20

# In Python:
python3 -c "
import pandas as pd
df_l = pd.read_csv('$OUT/vols.left.csv')
df_r = pd.read_csv('$OUT/vols.right.csv')
print('Left top 10:'); print(df_l.head(10))
print('Right top 10:'); print(df_r.head(10))
"
```

## Beispiele

```
# Standard in-vivo, beide Hemis (Default)
/fs-nextbrain /data/sub01/t1.nii.gz /out/sub01_nb

# Nur linke Hemi
/fs-nextbrain /data/sub01/t1.nii.gz /out/sub01_nb left

# Ex-vivo Single-Hemi, Custom-Auflösung
/fs-nextbrain /data/exvivo/sub.nii.gz /out/exvivo hemi exvivo --resolution 0.25

# CPU-only mit Skip
/fs-nextbrain /data/sub01/t1.nii.gz /out/sub01_nb both invivo --device cpu --skip 2
```

## Cross-Reference

- Was NextBrain ist + 333 ROIs: Skill `freesurfer-nextbrain-overview`
- Vollstaendige CLI-Flag-Doku: Skill `freesurfer-nextbrain-cli`
- Decision-Guide vs FastSurfer: Skill `freesurfer-nextbrain-vs-fastsurfer`
- Coord-Frame der Outputs: Skill `fastsurfer-coordinates-3d`
