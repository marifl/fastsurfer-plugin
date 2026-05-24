---
name: fastsurfer-cli-flags
description: Use when the user asks about specific FastSurfer CLI flags, what a flag does, default values, flag interactions, or wants help constructing a run_fastsurfer.sh invocation. Triggers on flag names like "--seg_only", "--surf_only", "--vox_size", "--keepgeom", "--3T", "--fs_license", "--device", "--viewagg_device", "--threads", "--batch", "--edits", "--no_biasfield", "--tal_reg", or general "run_fastsurfer flags" / "FastSurfer options".
---

# FastSurfer — CLI-Flag-Referenz (run_fastsurfer.sh)

Vollständige Flag-Liste aus `run_fastsurfer.sh --help` für FastSurfer 2.6.0-dev. Strukturiert nach Sektion.

**Hard rule:** Pfad-Argumente (`--t1`, `--sd`, `--fs_license`, `--asegdkt_segfile`, `--conformed_name`, `--norm_name`, `--lesion_mask`, `--t2`, `--cereb_segfile`) müssen **absolute Pfade** sein, sonst bricht das Skript ab.

## REQUIRED

| Flag | Wert | Notizen |
|------|------|---------|
| `--sid <id>` | Subject-ID | Output-Verzeichnisname |
| `--sd <dir>` | Subjects-Dir (absolut) | Alternativ via `$SUBJECTS_DIR` env-var |
| `--t1 <file>` | T1w-Image (absolut) | NIfTI oder MGZ; full-head, nicht skull-stripped |
| `--fs_license <file>` | FreeSurfer-License (absolut) | Pflicht für Surface; bei `--seg_only` oft entbehrlich |

## PIPELINE-Auswahl

| Flag | Wirkung |
|------|---------|
| (kein Flag) | Default: Segmentation + Surface |
| `--seg_only` | Nur Segmentation, kein Surface |
| `--surf_only` | Nur Surface; setzt voraus dass `asegdkt`+`cc`-Outputs existieren |

## SEGMENTATION-Optionen

| Flag | Wirkung | Default |
|------|---------|---------|
| `--seg_log <file>` | Custom-Logfile-Pfad | `$SUBJECTS_DIR/$sid/scripts/deep-seg.log` |
| `--conformed_name <file>` | Output-Pfad konformiertes Image (absolut) | `$SUBJECTS_DIR/$sid/mri/orig.mgz` |
| `--no_biasfield` | Deaktiviert Biasfield-Correction + PV-corrected Stats | aktiv |
| `--norm_name <file>` | Output-Pfad biasfield-korrigiertes Image (absolut) | `$SUBJECTS_DIR/$sid/mri/orig_nu.mgz` |
| `--tal_reg` | Talairach-Registration für eTIV im `--seg_only`-Stream | aus |
| `--native_image` / `--keepgeom` | Output in nativer Voxel-Geometrie (impliziert `--vox_size keep`) | aus; **nicht mit Surface-Pipeline kompatibel** |
| `--vox_size <0.7-1\|min\|keep>` | Voxelgrösse für Konformierung | `min` (= adaptive nach Input) |
| `--edits` | Manuelle Edits einlesen (`*.manedit.<ext>`) | aus |
| `--lesion_mask <file>` | LIT-Lesion-Inpainting aktivieren (absolut) | aus; experimentell, siehe `fastsurfer-lit` Skill |

### Vox-Size-Semantik (`--vox_size`)

- `0.7`–`1.0`: T1 wird auf exakt diese isotrope Voxelgrösse konformiert. Werte unter `0.7` sind experimentell.
- `min` (Default): Pipeline liest die kleinste Voxel-Kantenlänge aus dem T1:
  - Wenn > 0.98mm → konformiert auf 1mm isotropic.
  - Wenn ≤ 0.98mm → konformiert auf diese Voxelgrösse.
- `keep`: Native Voxelgrösse bleibt erhalten. Experimentell, nur mit `--seg_only` kompatibel.

Die effektive Voxelgrösse steuert auch, ob die Surface-Pipeline mit Highres-Optionen läuft (Surfaces im Highres-Modus bei < 1mm).

## MODUL-Toggles

| Modul | Skip-Flag | Notizen |
|-------|-----------|---------|
| asegdkt (FastSurferVINN) | `--no_asegdkt` | Wenn skipped, `--asegdkt_segfile` muss auf existierende Seg zeigen |
| cc (Corpus Callosum) | `--no_cc` | `--qc_snap` für QC-Snapshots |
| cereb (CerebNet) | `--no_cereb` | Output ist immer 1mm isotropic |
| hypothal (HypVINN) | `--no_hypothal` | Optional `--t2 <file>` + `--reg_mode <none\|coreg\|robust>`; `--qc_snap` für QC |

### Asegdkt-spezifisch

| Flag | Wirkung |
|------|---------|
| `--asegdkt_segfile <file>` | Output-Pfad der `aparc.DKTatlas+aseg.deep.mgz` (absolut) |

### Cerebellum-spezifisch

| Flag | Wirkung |
|------|---------|
| `--cereb_segfile <file>` | Output-Pfad der CerebNet-Seg (absolut) |

Hinweis: Wenn das konformierte Image nicht bereits 1mm ist, wird ein zusätzliches 1mm-Conformed mit Suffix `.1mm` geschrieben (z.B. `orig.1mm.mgz`).

### Hypothalamus-spezifisch

| Flag | Wirkung |
|------|---------|
| `--t2 <file>` | T2w-Input (absolut). Empfohlen aber optional |
| `--reg_mode <mode>` | `none` / `coreg` (Default = `mri_coreg`) / `robust` (= `mri_robust_register`) |
| `--no_biasfield` | Erwartet biasfield-korrigierte Inputs extern |

## SURFACE-Optionen

| Flag | Wirkung | Notizen |
|------|---------|---------|
| `--3T` | 3T-Atlas für Talairach (bessere eTIV bei 3T) | Default ist 1.5T-Atlas |
| `--no_fs_T1` | Skip `T1.mgz`-Generation; spart ~1:30 Min | brainmask aus norm.mgz statt T1.mgz |
| `--no_surfreg` | Skip cross-subject Surface-Registration | Nicht empfohlen ausser nur Stats relevant |
| `--fsaparc` | Zusätzlich klassische FS-aparc Segs + Ribbon | Default aus (DL-Prediction reicht meist) |
| `--fstess` | `mri_tesselate` statt `mri_mc` für Surface-Creation | Default ist `mri_mc` |
| `--fsqsphere` | FreeSurfer-iterative-Inflation für qsphere | Default ist spectral-spherical |
| `--ignore_fs_version` | Skip FreeSurfer-Version-Check | für Dev-FreeSurfer-Builds |

## LIT (experimentell)

| Flag | Wirkung |
|------|---------|
| `--lesion_mask <file>` | Aktiviert LIT-Lesion-Inpainting (absolut) |

Pre-Lesion-Outputs bleiben als `.lit`-Backups; siehe `fastsurfer-lit` Skill.

## RESOURCE-Optionen

| Flag | Wert | Notizen |
|------|------|---------|
| `--device` | `cpu` / `cuda` / `cuda:1` / etc. | Default: Auto-Detect GPU → fallback CPU |
| `--viewagg_device` | `auto` / `cpu` / `cuda` / specific | Default: prüft Memory, fallt auf cpu wenn nicht genug |
| `--threads <int\|max>` | OpenMP + ITK threads global |  |
| `--threads_seg <int\|max>` | Threads für Segmentation |  |
| `--threads_surf <int\|max>` | Threads für Surface; ≥2 aktiviert parallele Hemis | Default: 1 |
| `--batch <int>` | Batch-Size für Inference | Default: 1 |
| `--py <cmd>` | Python-Command | Default: `python3 -s` (`-s` skipped user-site-packages) |
| `--allow_root` | Erlaubt Root-User | per Default verboten |

## LONGITUDINAL-Flags (Power-User)

Für sequentielle Verarbeitung lieber `long_fastsurfer.sh` nutzen. Direkte Flags:

| Flag | Wirkung |
|------|---------|
| `--base` | Template-Processing; benötigt `long_prepare_template.sh`-Output |
| `--long <baseid>` | Time-Point-Processing; benötigt existierendes Base-Template unter `<baseid>` |

Bei `--base` und `--long` wird `--t1` nicht explizit gepasst (wird aus Template-Dir gezogen), und `--t2` ist nicht erlaubt.

## VERSION / HELP

| Flag | Wirkung |
|------|---------|
| `--version` | Nur Versions-Nummer |
| `--version +git` | + Git-Status |
| `--version +git_branch` | + aktueller Branch |
| `--version +checkpoints` | + Checkpoint-Hashes |
| `--version +pip` | + installierte Pip-Pakete |
| `-h` / `--help` | Help-Output |

Kombinierbar: `--version +git+checkpoints+pip`.

## Häufige Flag-Kombinationen

```bash
# Quick aseg+DKT (ca. 1 Min auf GPU)
--seg_only --no_cereb --no_hypothal --threads 4

# Quick ohne Biasfield (noch schneller, ohne PV-Stats)
--seg_only --no_cereb --no_hypothal --no_biasfield --threads 4

# Hi-Res (0.8mm input)
--vox_size 0.8 --3T --threads 4

# Native Geometrie behalten (nur Seg, kein Surface)
--seg_only --keepgeom

# CPU-only (kein GPU verfügbar)
--device cpu --viewagg_device cpu --threads max

# Mit T2 für HypVINN
--t2 /abs/path/t2.nii.gz --reg_mode coreg --qc_snap

# Lesion inpainting
--lesion_mask /abs/path/lesion.nii.gz --threads 4
```

## Cross-Reference

- Welcher Flag was im Output erzeugt: `fastsurfer-outputs`
- Conform-Space-Implikationen von `--vox_size`/`--keepgeom`: `fastsurfer-conform-space`
- Batch-/SLURM-Wrapper akzeptieren fast alle diese Flags weiter: `fastsurfer-batch-slurm`
