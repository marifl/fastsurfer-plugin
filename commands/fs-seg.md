---
description: FastSurfer Segmentation-only (`--seg_only`). Keine Surface, kein FreeSurfer-License nötig.
allowed-tools: Bash, Read
argument-hint: "<t1_path> <sid> [<extra-flags>]"
---

Starte nur die FastSurfer-Segmentation für $ARGUMENTS. Keine Surface-Pipeline.

## Vorteil vs Full-Run

- ~5-10 Min auf GPU (vs ~60-90 Min für Full)
- Kein FreeSurfer-License zwingend nötig (nur wenn `--tal_reg` aktiv)
- Output enthält trotzdem alle Modul-Segmentations (asegdkt + cc + cereb + hypothal)

## Aufruf-Pattern

```bash
FASTSURFER_HOME="${FASTSURFER_HOME:-$HOME/prj/fastsurfer}"

"$FASTSURFER_HOME/run_fastsurfer.sh" \
  --t1 <absolute-T1-path> \
  --sid <SID> \
  --sd "$SUBJECTS_DIR" \
  --seg_only \
  --3T \
  --threads 4 \
  <user-extra-flags>
```

## Wann zusätzlich `--fs_license`?

Wenn User auch `--tal_reg` will (Talairach in Seg-Stream für eTIV-Estimate): `--fs_license` Pflicht.

## Erwartete Outputs

```
$SUBJECTS_DIR/<SID>/mri/aparc.DKTatlas+aseg.deep.mgz
$SUBJECTS_DIR/<SID>/mri/orig.mgz
$SUBJECTS_DIR/<SID>/mri/orig_nu.mgz
$SUBJECTS_DIR/<SID>/mri/mask.mgz
$SUBJECTS_DIR/<SID>/mri/cerebellum.CerebNet.nii.gz   (wenn nicht --no_cereb)
$SUBJECTS_DIR/<SID>/mri/hypothalamus.HypVINN.nii.gz  (wenn nicht --no_hypothal)
$SUBJECTS_DIR/<SID>/mri/callosum.CC.upright.mgz       (wenn nicht --no_cc)
$SUBJECTS_DIR/<SID>/stats/aseg+DKT.stats
$SUBJECTS_DIR/<SID>/stats/cerebellum.CerebNet.stats
$SUBJECTS_DIR/<SID>/stats/hypothalamus.HypVINN.stats
$SUBJECTS_DIR/<SID>/stats/callosum.CC.midslice.json
$SUBJECTS_DIR/<SID>/scripts/deep-seg.log
```

KEINE `surf/`, `label/`, `stats/aseg.stats`.

## Cross-Reference

- Surface später nachholen: `/fs-surf`
- Noch schneller (nur asegdkt): `/fs-quick`
- Output-Validation: Skill `fastsurfer-debug-outputs`
