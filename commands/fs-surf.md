---
description: FastSurfer Surface-only (`--surf_only`). Segmentation muss bereits existieren.
allowed-tools: Bash, Read
argument-hint: "<sid> [<extra-flags>]"
---

Starte FastSurfer Surface-Pipeline für `$ARGUMENTS`. Erwartet existierende Segmentation-Outputs.

## Pre-Flight

Prüfe ob Seg-Outputs vorhanden:

```bash
SID="<sid-from-args>"
[ -f "$SUBJECTS_DIR/$SID/mri/aparc.DKTatlas+aseg.deep.mgz" ] || {
  echo "FAIL: Segmentation fehlt. Erst /fs-seg laufen lassen."
  exit 1
}
[ -f "$SUBJECTS_DIR/$SID/mri/orig.mgz" ] && [ -f "$SUBJECTS_DIR/$SID/mri/mask.mgz" ] || {
  echo "FAIL: orig.mgz oder mask.mgz fehlen."
  exit 1
}
```

Optional check ob `mri/callosum.CC.upright.mgz` existiert (cc-Modul). Surface kann ohne CC laufen aber Stats werden anders.

## FreeSurfer-License zwingend

Surface braucht `--fs_license`. Wenn User keine setzt → nach `$FS_LICENSE` env-var fragen.

## Aufruf-Pattern

```bash
FASTSURFER_HOME="${FASTSURFER_HOME:-/Users/marcusifland/prj/fastsurfer}"

"$FASTSURFER_HOME/run_fastsurfer.sh" \
  --sid <SID> \
  --sd "$SUBJECTS_DIR" \
  --fs_license "$FS_LICENSE" \
  --surf_only \
  --3T \
  --threads 4 \
  <user-extra-flags>
```

`--threads >= 2` aktiviert parallele L/R-Hemisphären-Verarbeitung.

## Erwartete Laufzeit

- ~45-90 Min mit `--threads 4` (GPU/CPU spielt für Surface keine grosse Rolle, da FreeSurfer-Binaries CPU-bound sind)

## Erwartete Outputs

```
surf/{lh,rh}.{pial,white,inflated,thickness,area,curv,volume,sphere,sphere.reg}
label/{lh,rh}.aparc.DKTatlas.mapped.annot
label/{lh,rh}.aparc.DKTatlas.annot              (symlink)
mri/aseg.mgz                                     (post-surf)
mri/aparc.DKTatlas+aseg.mapped.mgz               (post-surf)
mri/aparc.DKTatlas+aseg.mgz                      (symlink)
mri/wmparc.DKTatlas.mapped.mgz
mri/wmparc.mgz                                   (symlink)
stats/aseg.stats
stats/{lh,rh}.aparc.DKTatlas.mapped.stats
stats/{lh,rh}.curv.stats
stats/wmparc.DKTatlas.mapped.stats
scripts/recon-all.log
```

## Bei Crash

`scripts/recon-all.log` tailen:

```bash
tail -50 "$SUBJECTS_DIR/$SID/scripts/recon-all.log"
grep -iE "error|fail" "$SUBJECTS_DIR/$SID/scripts/recon-all.log"
```

Häufige Probleme:
- License-Fehler → Skill `fastsurfer-debug-license`
- Output-Validation → Skill `fastsurfer-debug-outputs`
- Surface-Algorithmen → Skill `fastsurfer-surface-recon`

## Cross-Reference

- Volle Pipeline: `/fs-run`
- Wenn Talairach failt: `--ignore_fs_version`, dann erneut starten
- Bei Edits: `--edits` Flag
