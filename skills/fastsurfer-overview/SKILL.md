---
name: fastsurfer-overview
description: Use when the user asks about FastSurfer at a high level — what it does, which modules it contains, module dependencies, default pipeline behavior, expected runtime, or how the pieces fit together. Triggers on "FastSurfer", "asegdkt", "CerebNet", "HypVINN", "Corpus Callosum module", "FastSurferVINN", "recon-surf pipeline", or comparisons to FreeSurfer's recon-all.
---

# FastSurfer — Pipeline-Übersicht

FastSurfer ist eine Deep-Learning-basierte Neuroimaging-Pipeline, die als drop-in-Alternative für FreeSurfer-`recon-all` dient. Sie produziert kompatible Subject-Directories und ist in zwei Sub-Pipelines geteilt: **Segmentation** (~5 Min auf GPU) und **Surface** (~60-90 Min).

Entry-Point ist immer `run_fastsurfer.sh`. Per Default laufen beide Sub-Pipelines.

## Module-Map (Default-Reihenfolge)

```
SEGMENTATION (--seg_only)
├── asegdkt   FastSurferVINN: 95-Klassen Whole-Brain + DKT-Cortex-Parcellation
│             → mri/aparc.DKTatlas+aseg.deep.mgz  + stats/aseg+DKT.stats
│             Deaktivieren: --no_asegdkt
│
├── cc        Corpus Callosum Segmentation + Shape-Analyse (FastSurfer-CC)
│             Benötigt: asegdkt-Output (orig.mgz + Segmentation)
│             → mri/callosum.CC.*, stats/callosum.CC.*.json, surf/callosum.{surf,vtk}
│             Deaktivieren: --no_cc
│             Optional: --qc_snap für QC-PNGs + HTML-3D-Viewer
│
├── cereb     CerebNet: detaillierte Cerebellum-Subsegmentierung (WM/GM)
│             Benötigt: asegdkt-Output (Localisation)
│             Resamplet IMMER auf 1mm isotropic
│             → mri/cerebellum.CerebNet.nii.gz + stats/cerebellum.CerebNet.stats
│             Deaktivieren: --no_cereb
│
└── hypothal  HypVINN: Hypothalamus + 3. Ventrikel + Corpora mamillaria + Fornix + Tractus opticus
              Hochaufgelöst (bis 0.7mm), optional T2 via --t2 <path> + --reg_mode
              → mri/hypothalamus.HypVINN.nii.gz + stats/hypothalamus.HypVINN.stats
              Deaktivieren: --no_hypothal

SURFACE (--surf_only)  ── benötigt asegdkt + cc als Prerequisite
└── recon-surf  Cortical Surfaces (pial, white, inflated), Thickness, DKT-Parcellation
                Nutzt intern FreeSurfer-Binaries → FreeSurfer-Lizenz Pflicht
                Parallel-Hemis bei --threads >= 2
                → surf/{lh,rh}.{pial,white,inflated,thickness,area,curv,volume}
                  label/{lh,rh}.aparc.DKTatlas.mapped.annot
                  stats/aseg.stats, stats/{lh,rh}.aparc.DKTatlas.mapped.stats

EXTENSION (optional)
└── lit         Lesion Inpainting Tool (experimentell)
                Aktivieren via --lesion_mask <path>
                Inpaintet Läsion → läuft Pipeline → mapt Läsion zurück
                Pre-Lesion-Outputs bleiben als *.lit.<ext> Backups
```

## Module-Dependencies (kritisch)

- `cc`, `cereb`, `hypothal` benötigen alle die `asegdkt`-Outputs als Input. Wenn du `asegdkt` deaktivierst (`--no_asegdkt`), muss `--asegdkt_segfile <path>` auf eine existierende Segmentation zeigen.
- `surf` benötigt `asegdkt` UND `cc` als Vorbedingung. Beim isolierten Surface-Run (`--surf_only`) müssen diese Outputs im Subject-Dir bereits existieren.
- `lit` ist **nicht** mit `--surf_only` kompatibel (siehe LIT-Modul-Doc).

## Standard-Aufruf

```bash
run_fastsurfer.sh \
  --t1 <ABSOLUTE_PATH_TO_T1.nii.gz> \
  --sid <SUBJECT_ID> \
  --sd <ABSOLUTE_SUBJECTS_DIR> \
  --fs_license <ABSOLUTE_LICENSE.txt> \
  --3T \
  --threads 4
```

- `--t1`, `--sd`, `--fs_license` müssen **absolute Pfade** sein.
- `--3T` schaltet das 3T-Atlas für Talairach-Registration (bessere eTIV bei 3T-Daten; Default ist 1.5T-Atlas).
- `--threads >= 2` aktiviert parallele L/R-Hemisphären-Verarbeitung in der Surface-Pipeline.

## Wann welche Sub-Pipeline

| Use-Case | Flag-Kombination |
|----------|------------------|
| Volle Pipeline (Volumes + Surfaces) | Default, nur `--t1` + `--sid` + `--sd` + `--fs_license` |
| Nur Segmentation (kein FreeSurfer-License nötig) | `--seg_only` |
| Quick aseg+DKT (keine Sub-Module) | `--seg_only --no_cereb --no_hypothal` (~1 Min) |
| Nur Surface | `--surf_only` (Segs müssen existieren) |
| Hi-Res | `--vox_size <0.7-1>` oder `--vox_size min` |
| Native Geometrie | `--keepgeom` (impliziert `--vox_size keep`; nicht mit Surface kompatibel) |
| Batch | `brun_fastsurfer.sh --subject_list <file>` + restliche Flags |
| Longitudinal | `long_fastsurfer.sh` (separater Entry-Point) |
| SLURM | `srun_fastsurfer.sh` (separater Entry-Point) |

## Output-Hauptpfade

```
$SUBJECTS_DIR/$SID/
├── mri/          → segmentations, intermediates, transforms
├── surf/         → pial/white/inflated/thickness Surfaces
├── label/        → cortical parcellation annot files
├── stats/        → tabular summary stats (.stats, .json)
├── scripts/      → deep-seg.log, recon-all.log
├── qc_snapshots/ → wenn --qc_snap aktiv (cc, hypothal)
└── mri/orig/     → original (pre-conform) Image: 001.mgz
```

Details pro Modul siehe Skill `fastsurfer-outputs`.

## Versionen

Aktuelle Repo-Version (am Plugin-Build-Datum): **FastSurfer 2.6.0-dev**. Versions-Info abrufbar via `run_fastsurfer.sh --version +git +checkpoints +pip`.

## Verwandte Skills

- Flag-Details: `fastsurfer-cli-flags`
- Output-Layout: `fastsurfer-outputs`
- Conform-Space-Semantik: `fastsurfer-conform-space`
- Code-Layout im Repo: `fastsurfer-internals`
- Modul-Internals: `fastsurfer-segmentation`, `fastsurfer-surface-recon`
- Container/Batch/SLURM: `fastsurfer-container`, `fastsurfer-batch-slurm`
