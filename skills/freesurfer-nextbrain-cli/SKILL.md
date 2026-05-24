---
name: freesurfer-nextbrain-cli
description: Use when the user wants to construct or debug a `mri_histo_atlas_segment_fireants` command, asks about specific NextBrain flags, output naming, GPU vs CPU choice, or memory-tuning. Triggers on "mri_histo_atlas_segment_fireants", "NextBrain flags", "--mode invivo", "--mode exvivo", "--side left", "--device cuda NextBrain", "skip 2 NextBrain", "bias field NextBrain", "yaml NextBrain", "FireANTs registration parameters".
---

# `mri_histo_atlas_segment_fireants` — CLI-Flag-Referenz

Vollstaendige Doku des NextBrain-Entry-Points aus FreeSurfer-dev (`mri_histo_util/mri_histo_atlas_segment_fireants`).

## Basic Usage

```bash
mri_histo_atlas_segment_fireants \
  --i INPUT_SCAN \
  --o OUTPUT_DIRECTORY \
  --device [cpu|cuda] \
  --side [left|right] \
  --mode [invivo|cerebrum|hemi|exvivo]
```

Alle 5 Args sind **Pflicht**.

## REQUIRED Flags

| Flag | Wert | Beschreibung |
|------|------|--------------|
| `--i` | absolute Pfad zu `.mgz` oder `.nii[.gz]` | Input T1-Scan |
| `--o` | Output-Directory (wird angelegt) | Ergebnis-Verzeichnis |
| `--device` | `cpu` / `cuda` | Inference-Device. GPU drastisch schneller. |
| `--side` | `left` / `right` | Pro Aufruf wird **eine** Hemisphere prozessiert. Fuer beide: zwei Calls. |
| `--mode` | `invivo` / `cerebrum` / `hemi` / `exvivo` | Scan-Typ |

### `--mode`-Optionen erklaert

| Mode | Wann |
|------|------|
| `invivo` | Standard in-vivo T1 (z.B. aus klinischer MRT) |
| `cerebrum` | Ex-vivo-Scan ohne Brainstem + Cerebellum |
| `hemi` | Ex-vivo Single-Hemisphere |
| `exvivo` | Vollstaendiger Ex-vivo-Brain-Scan |

**Caveat fuer `--mode exvivo|cerebrum|hemi`:** Input MUSS in **RAS-Orientation** sein. Falls dein Ex-vivo-Scan eine andere Orientation hat, vorher mit `mri_convert --in_orientation ... --out_orientation RAS input output` umorientieren.

## Output-Files

Im `--o` Output-Directory:

| File | Beschreibung |
|------|--------------|
| `seg.[left\|right].nii.gz` | Finale Segmentation (~333 ROIs pro Hemi) |
| `lut.txt` | Lookup-Table fuer FreeView-Visualisierung (Label-ID, RGB, Name) |
| `vols.[left\|right].csv` | Per-Region Volumes in CSV-Format |
| `SuperSynth/` | Pre-Stage Whole-Structure Foundation-Model-Output |

Plus optional je nach Flags: `bias_corrected.nii.gz`, `rgb_posterior.nii.gz`, `atlas_warped.nii.gz`, `field.nii.gz`, `jacobian.nii.gz`.

## OPTIONAL Flags — vollstaendig

### Bias-Field-Correction

| Flag | Default | Wirkung |
|------|---------|---------|
| `--bf_mode` | `dct` | Bias-Field-Basis-Funktion: `dct`, `polynomial`, `hybrid` |
| `--skip_bf` | aus | Bias-Field-Correction skippen. Sinnvoll wenn Input bereits korrigiert ist oder non-MRI-Modality |
| `--write_bias_corrected` | aus | Speichere `bias_corrected.nii.gz` als Side-Output |

### Output-Auflösung

| Flag | Default | Wirkung |
|------|---------|---------|
| `--resolution` | `0.4` (mm) | Output-Seg-Auflösung. Hoeher als Input meist (Anti-Aliasing). |
| `--smoothing_steps_HRmask` | `3` | Smoothing beim 1mm→HighRes-Mask-Upsampling. Mehr = weniger jagged, aber Accuracy-Verlust |

### Resource / Performance

| Flag | Default | Wirkung |
|------|---------|---------|
| `--device_registration` | wie `--device` | Separates Device fuer Registration. Praktisch wenn GPU-Memory knapp → `--device cuda --device_registration cpu` |
| `--threads` | `-1` (alle Cores) | CPU-Threads. Bei Multi-User-System ggf. limitieren |
| `--skip` | `1` (kein Skipping) | Downsampling-Factor fuer Parameter-Estimation. `--skip 2` halbiert Memory, leicht weniger Accuracy |

### FireANTs-Registration-Tuning

| Flag | Default | Wirkung |
|------|---------|---------|
| `--smooth_grad_sigma` | `1.0` | Gradient-Field-Smoothing fuer nonlinear Reg. Hoeher → regulaerere Deformation |
| `--smooth_warp_sigma` | `0.25` | Warp-Field-Smoothing. Hoeher → glatter |
| `--optimizer_lr` | `0.5` | Learning-Rate fuer Reg-Optimizer |
| `--cc_kernel_size` | `7` | Cross-Correlation Window-Size fuer Reg-Metric |
| `--rel_weight_labeldiff` | `2.5` | Gewicht der Dice-Loss vs CC-Loss bei nonlin Reg |

**Tuning-Hinweis:** Defaults `smooth_grad_sigma=1, smooth_warp_sigma=0.25` sind liberal (handle Hip-CT mit massiven Deformationen). Bei normalen in-vivo-Scans **ohne starke Atrophy** kann man beide Werte ×2-3 setzen → regulaerere Atlas-Deformation. `--save_jacobian` verwenden um die resultierende Deformation zu inspizieren.

### Diagnose-Outputs

| Flag | Wirkung |
|------|---------|
| `--write_rgb` | Speichere RGB-Image der Posterior-Probabilities |
| `--save_atlas_nonlinear_reg` | Speichere den nonlinear-registrierten Atlas |
| `--save_field` | Speichere die Deformation-Field |
| `--save_jacobian` | Speichere Jacobian-Determinant (log10) der Deformation |

### Custom-Label-Grouping

| Flag | Wert | Wirkung |
|------|------|---------|
| `--yaml_path` | Pfad zu Custom-YAML-Files | Override Default-Label-Grouping |

Die ROI-Grouping wird durch drei YAML-Files in `mri_histo_util/data_simplified/` gesteuert:
- `combined_atlas_labels_fireants.yaml` — definiert Atlas-Label-Klassen
- `gmm_components_fireants.yaml` — Gaussian-Mixture-Components pro Klasse
- `recipe_intensities_cheating_image_fireants.yaml` — Intensity-Recipes fuer Registration

**Beispiel — Globus-Pallidus-Internal-Segment (Label 206) als eigene Klasse:**

1. In `combined_atlas_labels_fireants.yaml`: neue Klasse `Internal Segment Pallidum`, Label 206 dazu (entfernen aus `Pallidum`).
2. In `gmm_components_fireants.yaml`: gleiche Klasse mit Anzahl Gaussians.
3. In `recipe_intensities_cheating_image_fireants.yaml`: gleiche Klasse mit Intensity-Recipe (siehe File fuer Beispiele).

Dann run mit `--yaml_path /path/to/your/yaml_dir`.

## Vollstaendige Beispiele

### Standard in-vivo, GPU

```bash
mri_histo_atlas_segment_fireants \
  --i /data/sub01/t1.nii.gz \
  --o /out/sub01_nextbrain/ \
  --device cuda \
  --side left \
  --mode invivo

# Dann rechte Hemi (reuses SuperSynth):
mri_histo_atlas_segment_fireants \
  --i /data/sub01/t1.nii.gz \
  --o /out/sub01_nextbrain/ \
  --device cuda \
  --side right \
  --mode invivo
```

### CPU-only, Memory-Constrained

```bash
mri_histo_atlas_segment_fireants \
  --i /data/sub01/t1.nii.gz \
  --o /out/sub01_nextbrain/ \
  --device cpu \
  --side left \
  --mode invivo \
  --skip 2 \
  --threads 8
```

### GPU-Hybrid (Inference auf GPU, Registration auf CPU fuer Memory)

```bash
mri_histo_atlas_segment_fireants \
  --i /data/sub01/t1.nii.gz \
  --o /out/sub01_nextbrain/ \
  --device cuda \
  --device_registration cpu \
  --side left \
  --mode invivo
```

### Ex-vivo Single-Hemisphere mit Custom-Output-Auflösung

```bash
# Vorher RAS-Orientation sicherstellen:
mri_convert --out_orientation RAS input_exvivo.nii.gz input_exvivo_ras.nii.gz

mri_histo_atlas_segment_fireants \
  --i input_exvivo_ras.nii.gz \
  --o /out/exvivo_hemi/ \
  --device cuda \
  --side left \
  --mode hemi \
  --resolution 0.25 \
  --save_field \
  --save_jacobian
```

### Mit Diagnose-Outputs fuer Reg-Inspection

```bash
mri_histo_atlas_segment_fireants \
  --i T1.nii.gz \
  --o out/ \
  --device cuda --side left --mode invivo \
  --save_atlas_nonlinear_reg \
  --save_field \
  --save_jacobian \
  --write_rgb \
  --write_bias_corrected
```

## Runtime-Erwartungen

| Hardware | Mode | Runtime (pro Hemi) |
|----------|------|---------------------|
| GPU (CUDA) mit `--threads >=4` | invivo | ~30 Min |
| GPU + `--skip 2` | invivo | ~15-20 Min |
| CPU only mit `--threads max` | invivo | ~1-2h |
| CPU only, ex-vivo 0.25mm | exvivo | ~2h |

Bei beiden Hemispharen: zweiter Run ~30% schneller wegen SuperSynth-Cache.

## Memory-Faustregeln

| Setting | VRAM | RAM |
|---------|------|-----|
| `--device cuda` default | ~10-12 GB | ~16 GB |
| `--device cuda --skip 2` | ~6-8 GB | ~12 GB |
| `--device cuda --device_registration cpu` | ~4-6 GB | ~24 GB |
| `--device cpu` | — | ~16-32 GB |

Wenn GPU-OOM: erst `--skip 2`, dann `--device_registration cpu`, dann ganz `--device cpu`.

## Visualisierung

```bash
freeview -v /out/sub01_nextbrain/seg.left.nii.gz:colormap=lut:lut=/out/sub01_nextbrain/lut.txt \
         -v /data/sub01/t1.nii.gz
```

Oder fuer beide Hemis overlayed:

```bash
freeview \
  -v /data/sub01/t1.nii.gz \
  -v /out/sub01_nextbrain/seg.left.nii.gz:colormap=lut:lut=/out/sub01_nextbrain/lut.txt:opacity=0.5 \
  -v /out/sub01_nextbrain/seg.right.nii.gz:colormap=lut:lut=/out/sub01_nextbrain/lut.txt:opacity=0.5
```

## Volumetrics-Auswertung

`vols.[left|right].csv` ist Standard-CSV mit Region-Name + Volume-in-mm³ Spalten. Direkt mit pandas:

```python
import pandas as pd
df = pd.read_csv('/out/sub01_nextbrain/vols.left.csv')
print(df.head())
# Plus diff zwischen Hemis:
df_l = pd.read_csv('/out/sub01_nextbrain/vols.left.csv')
df_r = pd.read_csv('/out/sub01_nextbrain/vols.right.csv')
```

(Siehe Skill `fastsurfer-stats-parsing` fuer allgemeinere Stats-Workflows.)

## First-Run-Behavior

Beim ersten Aufruf:
1. Prompt fragt nach Download des NextBrain-Atlas (mehrere GB) → bestaetigen.
2. Wenn `mri_super_synth` noch nie genutzt wurde: weiterer Download-Prompt fuer BrainFM-Modell.

Beide werden in `$FREESURFER_HOME` gecached. Bei Container-Setups: Volume-Mount der Cache-Pfade fuer Persistenz.

## Cross-Reference

- Was NextBrain ueberhaupt ist: Skill `freesurfer-nextbrain-overview`
- Wann vs FastSurfer: Skill `freesurfer-nextbrain-vs-fastsurfer`
- Slash-Command: `/fs-nextbrain <t1> <output_dir> [--side both]`
