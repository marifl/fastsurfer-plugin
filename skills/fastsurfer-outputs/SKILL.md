---
name: fastsurfer-outputs
description: Use when the user asks what files FastSurfer produces, where to find a specific output, what a `.mgz` / `.stats` / `.annot` / `.surf` file contains, or wants to validate an expected output set. Triggers on filenames like "aparc.DKTatlas+aseg", "aseg.mgz", "orig.mgz", "orig_nu.mgz", "lh.pial", "rh.thickness", "aseg.stats", "wmparc", "cerebellum.CerebNet", "hypothalamus.HypVINN", "callosum.CC", or generic "FastSurfer output", "subject directory layout".
---

# FastSurfer — Output-Layout-Referenz

Jede FastSurfer-Run erzeugt im Subject-Verzeichnis `$SUBJECTS_DIR/$SID/` eine FreeSurfer-kompatible Struktur mit zusätzlichen DL-spezifischen Files.

## Globales Verzeichnis-Layout

```
$SUBJECTS_DIR/$SID/
├── mri/                      Volumetrische Daten (.mgz / .nii.gz)
│   ├── orig/                 Original-Input (vor Konformierung): 001.mgz
│   └── transforms/           Linear-Transforms (.lta) inkl. talairach
├── surf/                     Cortical Surfaces + per-Vertex-Overlays
├── label/                    Cortical Parcellation Annotations
├── stats/                    Tabellarische Summary-Stats
├── scripts/                  Logs (deep-seg.log, recon-all.log)
└── qc_snapshots/             optional bei --qc_snap (cc, hypothal)
```

## SEGMENTATION-Outputs

### asegdkt (FastSurferVINN) — IMMER aktiv ausser `--no_asegdkt`

| Pfad | Beschreibung |
|------|--------------|
| `mri/aparc.DKTatlas+aseg.deep.mgz` | 95-Klassen Cortex+Subcortex-Seg (Primary Output) |
| `mri/aseg.auto_noCCseg.mgz` | Vereinfachte Subcortex-Seg ohne Corpus Callosum-Labels |
| `mri/mask.mgz` | Brainmask |
| `mri/orig.mgz` | Konformiertes Image (Default 1mm isotropic LIA) |
| `mri/orig_nu.mgz` | Biasfield-korrigiertes Image |
| `mri/orig/001.mgz` | Original-Input vor Konformierung |
| `scripts/deep-seg.log` | Segmentation-Logfile |
| `stats/aseg+DKT.stats` | Volume-Stats inkl. PV-Korrektur (wenn `--no_biasfield` nicht gesetzt) |

### cc (Corpus Callosum / FastSurfer-CC)

| Pfad | Beschreibung |
|------|--------------|
| `mri/callosum.CC.upright.mgz` | CC-Seg in upright (AC/PC-aligned) Space |
| `mri/callosum.CC.orig.mgz` | CC-Seg in conformed-Image-Orientation |
| `mri/callosum.CC.soft.mgz` | CC soft-labels (upright) |
| `mri/fornix.CC.soft.mgz` | Fornix soft-labels |
| `mri/background.CC.soft.mgz` | Background soft-labels |
| `mri/upright_volume.mgz` | Conformed-Image in upright-Space (nur bei `fastsurfer_cc.py --upright_volume`) |
| `mri/transforms/cc_up.lta` | Transform conformed → upright |
| `mri/transforms/orient_volume.lta` | Standardisierungs-Transform (AC/PC) |
| `stats/callosum.CC.midslice.json` | Mid-sagittal Landmarks, Area, Thickness etc. |
| `stats/callosum.CC.all_slices.json` | Per-Slice Analyse |
| `surf/callosum.surf` | 3D-Mesh (FreeSurfer-Format, freeview) |
| `surf/callosum.thickness.w` | Thickness-Overlay für `callosum.surf` |
| `surf/callosum.vtk` | 3D-Mesh (VTK-Format) |
| `qc_snapshots/callosum.png` | CC-Kontur + AC/PC + Thickness (nur `--qc_snap`) |
| `qc_snapshots/callosum.thickness.png` | 3D-Thickness-Vis (nur `--qc_snap`) |
| `qc_snapshots/corpus_callosum.html` | Interaktiver 3D-Mesh-Viewer (nur `--qc_snap`) |

### cereb (CerebNet)

| Pfad | Beschreibung |
|------|--------------|
| `mri/cerebellum.CerebNet.nii.gz` | Cerebellum-Subsegmentation, **immer 1mm isotropic** |
| `stats/cerebellum.CerebNet.stats` | Volume-Stats Cerebellum |

Hinweis: Wenn das conformed Image nicht 1mm ist, wird zusätzlich ein 1mm-Conformed mit Suffix `.1mm` geschrieben (z.B. `orig.1mm.mgz`).

### hypothal (HypVINN)

| Pfad | Beschreibung |
|------|--------------|
| `mri/hypothalamus.HypVINN.nii.gz` | Hypothalamus-Subsegmentation |
| `mri/hypothalamus_mask.HypVINN.nii.gz` | Hypothalamus-Mask |
| `stats/hypothalamus.HypVINN.stats` | Volume-Stats Hypothalamus |

Wenn `--t2` gesetzt:

| Pfad | Beschreibung |
|------|--------------|
| `mri/T2_nu.mgz` | Biasfield-korrigiertes T2 |
| `mri/T2_nu_reg.mgz` | T2 → T1-koregistriert |

QC: `qc_snapshots/hypothalamus.png` (nur `--qc_snap`).

## SURFACE-Outputs

Läuft per Default; deaktiviert via `--seg_only`. Die Surface-Pipeline **überschreibt** einige Segmentation-Outputs mit verbesserten Versionen (PV-Korrektur via Surface, CC-Labels addiert).

### Updated Volumes (post-surf)

| Pfad | Beschreibung |
|------|--------------|
| `mri/aparc.DKTatlas+aseg.deep.withCC.mgz` | Seg + CC-Labels |
| `mri/aparc.DKTatlas+aseg.mapped.mgz` | Seg nach Surface-PV-Korrektur |
| `mri/aparc.DKTatlas+aseg.mgz` | **Symlink** → `aparc.DKTatlas+aseg.mapped.mgz` |
| `mri/aparc+aseg.mgz` | **Symlink** → `aparc.DKTatlas+aseg.mapped.mgz` |
| `mri/aseg.mgz` | Subcortex-Seg nach Surface-PV |
| `mri/wmparc.DKTatlas.mapped.mgz` | White-Matter-Parcellation |
| `mri/wmparc.mgz` | **Symlink** → `wmparc.DKTatlas.mapped.mgz` |

### Surfaces (`surf/`)

| Pattern | Beschreibung |
|---------|--------------|
| `{lh,rh}.pial` | Pial-Surface |
| `{lh,rh}.white` | White-Matter-Surface |
| `{lh,rh}.inflated` | Inflated-Surface |
| `{lh,rh}.area` | Surface-Area Overlay |
| `{lh,rh}.curv` | Curvature Overlay |
| `{lh,rh}.thickness` | Cortical-Thickness Overlay |
| `{lh,rh}.volume` | Gray-Matter-Volume Overlay |

### Labels (`label/`)

| Pattern | Beschreibung |
|---------|--------------|
| `{lh,rh}.aparc.DKTatlas.mapped.annot` | Cortical-Parcellation (von Seg auf Surface gemappt) |
| `{lh,rh}.aparc.DKTatlas.annot` | **Symlink** → `*.mapped.annot` |

### Stats (`stats/`)

| Pfad | Beschreibung |
|------|--------------|
| `stats/aseg.stats` | Cortex+Subcortex-Stats nach Surface-Run |
| `stats/{lh,rh}.aparc.DKTatlas.mapped.stats` | Cortical-Parcellation-Stats |
| `stats/{lh,rh}.curv.stats` | Curvature-Stats |
| `stats/wmparc.DKTatlas.mapped.stats` | WM-Parcellation-Stats |

### Logfile

| Pfad | Beschreibung |
|------|--------------|
| `scripts/recon-all.log` | Surface-Pipeline-Logfile (FreeSurfer-Style) |

## LIT-Outputs (nur bei `--lesion_mask`)

### Inpainting-Stage

| Pfad | Beschreibung |
|------|--------------|
| `mri/inpainted.lit.nii.gz` | Inpainted T1 (downstream Input) |
| `mri/mask.lit.nii.gz` | Lesion-Mask in FastSurfer-Space |
| `mri/orig/mask.lit.nii.gz` | Original-Lesion-Mask |
| `mri/orig/inpainting_original_image.lit.nii.gz` | LIT-internes Original |
| `mri/orig/inpainting_masked_image.lit.nii.gz` | LIT-internes Masked-Image |
| `scripts/inpainting_*.lit.png` | Inpainting-Preview-Bilder |

### Post-Lesion MRI (Primary überschrieben, `.lit` = Pre-Lesion-Backup)

| Pfad | Beschreibung |
|------|--------------|
| `mri/aparc.DKTatlas+aseg.deep.mgz` | Lesion-integrierte Whole-Brain-Seg |
| `mri/aparc.DKTatlas+aseg.deep.lit.mgz` | Pre-Lesion-Backup |
| `mri/aseg.auto_noCCseg.mgz` | Lesion-integrierte Subcortex-Seg |
| `mri/aseg.auto_noCCseg.lit.mgz` | Pre-Lesion-Backup |
| `mri/cerebellum.CerebNet.nii.gz` | Lesion-integrierte Cerebellum-Seg |
| `mri/cerebellum.CerebNet.lit.nii.gz` | Pre-Lesion-Backup |
| `mri/hypothalamus.HypVINN.nii.gz` | Lesion-integrierte Hypothal-Seg |
| `mri/hypothalamus.HypVINN.lit.nii.gz` | Pre-Lesion-Backup |

### Post-Lesion Stats + Reports

| Pfad | Beschreibung |
|------|--------------|
| `stats/lesion_impact_summary.yaml` | Machine-readable Summary betroffener Regionen |
| `stats/aparc.DKTatlas+aseg.lesion_report.txt` | Volumetrische Report |
| `stats/aseg.lesion_report.txt` | FreeSurfer-aseg Report |
| `stats/aseg+DKT.VINN.stats` | Lesion-integrierte VINN-Stats |
| `stats/aseg+DKT.VINN.lit.stats` | Pre-Lesion-Backup |
| `stats/aseg.VINN.stats` | Lesion-integrierte Subcortex-VINN-Stats |
| `stats/aseg.VINN.lit.stats` | Pre-Lesion-Backup |
| `stats/cerebellum.CerebNet.stats` | Lesion-integrierte Cereb-Stats |
| `stats/cerebellum.CerebNet.lit.stats` | Pre-Lesion-Backup |
| `stats/hypothalamus.HypVINN.stats` | Lesion-integrierte HypVINN-Stats |
| `stats/hypothalamus.HypVINN.lit.stats` | Pre-Lesion-Backup |

### Post-Lesion Surface (wenn Surf läuft)

| Pfad | Beschreibung |
|------|--------------|
| `label/{lh,rh}.aparc.DKTatlas.annot` | Lesion-projizierte Parcellation (Symlink auf `.mapped.annot`) |
| `label/{lh,rh}.aparc.DKTatlas.lit.annot` | Pre-Lesion-Parcellation (Symlink auf `.mapped.lit.annot`) |
| `stats/{lh,rh}.aparc.DKTatlas.stats` | Lesion-integrierte Surface-Stats |
| `stats/{lh,rh}.aparc.DKTatlas.mapped.stats` | Pre-Lesion-Backup |
| `stats/{lh,rh}.aparc.DKTatlas.anatomy_report.txt` | Cortical-Lesion-Report |

## LONGITUDINAL

Bei `long_fastsurfer.sh` werden für jeden Time-Point dieselben Output-Files wie oben erzeugt. Zusätzlich existiert ein `templateID`-Subject-Dir für das within-subject Template — das ist eine Zwischenstufe und wird normalerweise nicht direkt analysiert.

## Validierung — Minimal-Set bei Vollständigem Run

Vollständiger Default-Run (Segmentation + Surface, alle Module aktiv) sollte mindestens diese Files erzeugen:

```bash
ls -1 $SUBJECTS_DIR/$SID/mri/aparc.DKTatlas+aseg.deep.mgz \
       $SUBJECTS_DIR/$SID/mri/aseg.mgz \
       $SUBJECTS_DIR/$SID/mri/orig.mgz \
       $SUBJECTS_DIR/$SID/mri/orig_nu.mgz \
       $SUBJECTS_DIR/$SID/mri/mask.mgz \
       $SUBJECTS_DIR/$SID/mri/cerebellum.CerebNet.nii.gz \
       $SUBJECTS_DIR/$SID/mri/hypothalamus.HypVINN.nii.gz \
       $SUBJECTS_DIR/$SID/mri/callosum.CC.upright.mgz \
       $SUBJECTS_DIR/$SID/mri/wmparc.mgz \
       $SUBJECTS_DIR/$SID/surf/lh.pial \
       $SUBJECTS_DIR/$SID/surf/rh.pial \
       $SUBJECTS_DIR/$SID/surf/lh.thickness \
       $SUBJECTS_DIR/$SID/surf/rh.thickness \
       $SUBJECTS_DIR/$SID/label/lh.aparc.DKTatlas.annot \
       $SUBJECTS_DIR/$SID/label/rh.aparc.DKTatlas.annot \
       $SUBJECTS_DIR/$SID/stats/aseg.stats \
       $SUBJECTS_DIR/$SID/stats/lh.aparc.DKTatlas.mapped.stats \
       $SUBJECTS_DIR/$SID/stats/rh.aparc.DKTatlas.mapped.stats \
       $SUBJECTS_DIR/$SID/stats/cerebellum.CerebNet.stats \
       $SUBJECTS_DIR/$SID/stats/hypothalamus.HypVINN.stats
```

Fehlende Files → siehe Skill `fastsurfer-debug-outputs`.

## Cross-Reference

- Wer welchen Output erzeugt: `fastsurfer-segmentation`, `fastsurfer-surface-recon`
- Conform-Space-Semantik der `.mgz`-Files: `fastsurfer-conform-space`
- LIT-Workflow im Detail: `fastsurfer-lit`
