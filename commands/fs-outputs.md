---
description: Listet alle erwarteten FastSurfer-Output-Files eines Subjects mit Status (vorhanden/fehlend) und Beschreibung.
allowed-tools: Bash, Read
argument-hint: "<sid> [--subjects-dir <path>]"
---

Validiere die Output-Vollständigkeit für Subject `$ARGUMENTS`.

## Pre-Flight

```bash
SID="<sid-from-args>"
SD="${SUBJECTS_DIR_OVERRIDE:-$SUBJECTS_DIR}"

[ -d "$SD/$SID" ] || { echo "FAIL: $SD/$SID existiert nicht"; exit 1; }

echo "Subject: $SID"
echo "Path: $SD/$SID"
echo "Disk usage: $(du -sh $SD/$SID 2>/dev/null | cut -f1)"
```

## Check-Liste

Strukturiere als Markdown-Tabelle. Pro Datei: Pfad, Status (✓/✗), Erwartete-Grösse, Beschreibung.

### Segmentation (asegdkt + sub-modules)

```bash
SEG_FILES=(
  "mri/aparc.DKTatlas+aseg.deep.mgz|asegdkt 95-Klassen Seg|10-20 MB"
  "mri/aseg.auto_noCCseg.mgz|Vereinfachte Subcortex-Seg|5-10 MB"
  "mri/orig.mgz|Conformed Input|10-20 MB"
  "mri/orig_nu.mgz|Biasfield-corrected|10-20 MB"
  "mri/mask.mgz|Brainmask|5-10 MB"
  "mri/orig/001.mgz|Original Input|5-50 MB"
  "scripts/deep-seg.log|Segmentation-Log|10-50 KB"
  "stats/aseg+DKT.stats|Volume-Stats|10-30 KB"
)
```

### Sub-Modules

```bash
SUB_FILES=(
  "mri/cerebellum.CerebNet.nii.gz|Cerebellum-Subsegmentation (1mm)|5-10 MB"
  "stats/cerebellum.CerebNet.stats|Cerebellum-Stats|5-15 KB"
  "mri/hypothalamus.HypVINN.nii.gz|Hypothalamus-Seg|2-5 MB"
  "mri/hypothalamus_mask.HypVINN.nii.gz|Hypothalamus-Mask|1-3 MB"
  "stats/hypothalamus.HypVINN.stats|Hypothalamus-Stats|3-10 KB"
  "mri/callosum.CC.upright.mgz|CC-Seg upright-Space|2-5 MB"
  "mri/callosum.CC.orig.mgz|CC-Seg conformed-Space|2-5 MB"
  "stats/callosum.CC.midslice.json|CC-Midslice-Stats|10-30 KB"
  "stats/callosum.CC.all_slices.json|CC-All-Slices-Stats|50-200 KB"
  "surf/callosum.surf|CC-3D-Mesh|1-3 MB"
  "surf/callosum.vtk|CC-VTK-Mesh|1-3 MB"
  "mri/transforms/orient_volume.lta|AC/PC-Transform|1-2 KB"
  "mri/transforms/cc_up.lta|CC-Upright-Transform|1-2 KB"
)
```

### Surface (post-surf only)

```bash
SURF_FILES=(
  "surf/lh.pial|Pial-Surface Links|3-8 MB"
  "surf/rh.pial|Pial-Surface Rechts|3-8 MB"
  "surf/lh.white|White-Matter-Surface Links|3-8 MB"
  "surf/rh.white|White-Matter-Surface Rechts|3-8 MB"
  "surf/lh.inflated|Inflated Links|3-8 MB"
  "surf/rh.inflated|Inflated Rechts|3-8 MB"
  "surf/lh.sphere|Spherical-Projection Links|3-8 MB"
  "surf/rh.sphere|Spherical-Projection Rechts|3-8 MB"
  "surf/lh.thickness|Thickness-Overlay Links|500 KB-1.5 MB"
  "surf/rh.thickness|Thickness-Overlay Rechts|500 KB-1.5 MB"
  "surf/lh.area|Area-Overlay Links|500 KB-1.5 MB"
  "surf/rh.area|Area-Overlay Rechts|500 KB-1.5 MB"
  "surf/lh.curv|Curvature Links|500 KB-1.5 MB"
  "surf/rh.curv|Curvature Rechts|500 KB-1.5 MB"
  "surf/lh.volume|GM-Volume Links|500 KB-1.5 MB"
  "surf/rh.volume|GM-Volume Rechts|500 KB-1.5 MB"
  "label/lh.aparc.DKTatlas.mapped.annot|Cortical-Annot Links|100-300 KB"
  "label/rh.aparc.DKTatlas.mapped.annot|Cortical-Annot Rechts|100-300 KB"
  "mri/aseg.mgz|Post-Surf Subcortex-Seg|5-10 MB"
  "mri/aparc.DKTatlas+aseg.mapped.mgz|Post-Surf Whole-Brain-Seg|10-20 MB"
  "mri/wmparc.DKTatlas.mapped.mgz|WM-Parcellation|10-20 MB"
  "stats/aseg.stats|Post-Surf aseg-Stats|10-30 KB"
  "stats/lh.aparc.DKTatlas.mapped.stats|Cortical-Stats Links|5-15 KB"
  "stats/rh.aparc.DKTatlas.mapped.stats|Cortical-Stats Rechts|5-15 KB"
  "stats/wmparc.DKTatlas.mapped.stats|WM-Stats|5-15 KB"
  "scripts/recon-all.log|Surface-Log|100 KB-1 MB"
)
```

### LIT (wenn aktiv)

Prüfe ob `mri/inpainted.lit.nii.gz` existiert. Wenn ja, zusätzliche Liste:

```bash
LIT_FILES=(
  "mri/inpainted.lit.nii.gz|Inpainted T1"
  "mri/mask.lit.nii.gz|Processed Lesion-Mask"
  "stats/lesion_impact_summary.yaml|Lesion-Impact Summary"
  "stats/aseg.lesion_report.txt|Lesion-Impact Report"
  # ... siehe Skill fastsurfer-outputs für volle Liste
)
```

## Aggregation

Pro File: `[ -e "$SD/$SID/$FILE" ] && echo "✓ $FILE ($SIZE)" || echo "✗ $FILE — MISSING"`.

Am Ende:

```
Summary
-------
  Segmentation:   X / Y vorhanden
  Sub-Modules:    X / Y vorhanden
  Surface:        X / Y vorhanden
  LIT (optional): X / Y vorhanden
```

Wenn alles vorhanden: "Pipeline-Run vollständig."

Wenn einige Surface-Files fehlen aber Seg vollständig: "Pipeline lief nur als `--seg_only` — Surface kann via `/fs-surf <SID>` nachgeholt werden."

## Cross-Reference

- Volle Output-Referenz: Skill `fastsurfer-outputs`
- Bei missing files: Skill `fastsurfer-debug-outputs`
- Bei LIT-spezifischen Outputs: Skill `fastsurfer-lit`
