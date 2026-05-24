---
description: Öffnet FreeView mit FastSurfer-Outputs eines Subjects (Volume + Seg + Surfaces).
allowed-tools: Bash, Read
argument-hint: "<sid> [--preset minimal|standard|full]"
---

Öffne FreeView für Subject `$ARGUMENTS` mit sinnvollen Layern.

## Pre-Flight

```bash
SID="<sid-from-args>"
SD="${SUBJECTS_DIR_OVERRIDE:-$SUBJECTS_DIR}"
PRESET="${PRESET:-standard}"

[ -d "$SD/$SID" ] || { echo "FAIL: $SD/$SID existiert nicht"; exit 1; }
command -v freeview >/dev/null 2>&1 || { echo "FAIL: freeview nicht im PATH (FreeSurfer-Env nicht gesourced?)"; exit 1; }
```

## Presets

### `minimal` — nur Volume + aseg

```bash
freeview \
  -v "$SD/$SID/mri/orig.mgz" \
  -v "$SD/$SID/mri/aseg.mgz:colormap=lut:opacity=0.5" &
```

### `standard` (Default) — Volume + Seg + Pial-Surfaces

```bash
freeview \
  -v "$SD/$SID/mri/orig.mgz" \
  -v "$SD/$SID/mri/aparc.DKTatlas+aseg.deep.mgz:colormap=lut:opacity=0.4" \
  -f "$SD/$SID/surf/lh.pial:edgecolor=red" \
     "$SD/$SID/surf/rh.pial:edgecolor=red" \
     "$SD/$SID/surf/lh.white:edgecolor=yellow" \
     "$SD/$SID/surf/rh.white:edgecolor=yellow" \
  &
```

### `full` — alles inklusive Sub-Modules

```bash
freeview \
  -v "$SD/$SID/mri/orig.mgz" \
  -v "$SD/$SID/mri/orig_nu.mgz:visible=0" \
  -v "$SD/$SID/mri/aparc.DKTatlas+aseg.deep.mgz:colormap=lut:opacity=0.4" \
  -v "$SD/$SID/mri/cerebellum.CerebNet.nii.gz:colormap=lut:opacity=0.7:visible=0" \
  -v "$SD/$SID/mri/hypothalamus.HypVINN.nii.gz:colormap=lut:opacity=0.7:visible=0" \
  -v "$SD/$SID/mri/callosum.CC.upright.mgz:colormap=heat:opacity=0.6:visible=0" \
  -f "$SD/$SID/surf/lh.pial:edgecolor=red" \
     "$SD/$SID/surf/rh.pial:edgecolor=red" \
     "$SD/$SID/surf/lh.white:edgecolor=yellow:visible=0" \
     "$SD/$SID/surf/rh.white:edgecolor=yellow:visible=0" \
     "$SD/$SID/surf/lh.inflated:overlay=$SD/$SID/surf/lh.thickness:overlay_threshold=0.1,5:visible=0" \
     "$SD/$SID/surf/rh.inflated:overlay=$SD/$SID/surf/rh.thickness:overlay_threshold=0.1,5:visible=0" \
  --annotation "$SD/$SID/label/lh.aparc.DKTatlas.annot" \
                "$SD/$SID/label/rh.aparc.DKTatlas.annot" \
  &
```

## Customizing

User-Hint: FreeView-Layer-Sichtbarkeit kann live im UI getoggelt werden. Defaults oben setzen einige Layer auf `visible=0` damit das Initial-Display nicht überladen ist.

## Wenn FreeView nicht installiert

FreeView kommt mit FreeSurfer. Falls FreeSurfer nicht installiert:

- macOS: https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall
- Linux: gleiche URL.
- Im Docker-Container `deepmi/fastsurfer:latest` ist FreeView drin, aber GUI-Forwarding nötig (X11/XQuartz). Komplex.

Alternative GUI-Viewer:
- **ITK-SNAP** — Multi-Volume + Multi-Seg, kostenlos, läuft auch ohne FreeSurfer.
- **mrview** (MRtrix3) — sehr schnell, Volumes + Tractography.
- **3D Slicer** — eigenes Plug-in-System, FreeSurfer-Import möglich.

## Cross-Reference

- Output-Layout für Layer-Auswahl: Skill `fastsurfer-outputs`
- Wenn Layer falsch sitzen (Frame-Bug): Skill `fastsurfer-debug-conform-tkras`
