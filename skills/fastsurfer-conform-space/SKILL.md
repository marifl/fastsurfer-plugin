---
name: fastsurfer-conform-space
description: Use when the user asks about FastSurfer voxel space, conformed vs native geometry, `--vox_size`, `--keepgeom`, `--native_image`, the `orig.mgz` file, RAS vs tkRAS coordinates, AC/PC alignment, or when debugging alignment/offset bugs between FastSurfer outputs and original images. Triggers on "conform", "conformed", "orig.mgz", "vox_size", "keepgeom", "tkRAS", "scanner-RAS", "LIA orientation", "voxel grid mismatch", "alignment off by 17.5mm".
---

# FastSurfer — Conform-Space, Voxel-Geometrie, tkRAS

## Was ist "conformed"?

FastSurfer konformiert standardmässig das Input-T1 in einen einheitlichen Voxel-Raum: **isotrope Voxel in LIA-Orientation** (Left-Inferior-Anterior axis-order). Per Default 1mm, optional kleiner via `--vox_size`. Das ist exakt das Format das auch FreeSurfer's `recon-all` voraussetzt — daher Drop-In-Kompatibilität.

Conformed-Image: `mri/orig.mgz` (Pfad anpassbar via `--conformed_name <abs_path>`).
Original-Image (pre-conform): `mri/orig/001.mgz`.

## `--vox_size` Semantik (komplett)

| Wert | Verhalten |
|------|-----------|
| `min` (Default) | Liest kleinste Voxel-Kantenlänge aus T1. `> 0.98mm` → 1mm. `≤ 0.98mm` → exakt diese Voxelgrösse. |
| `0.7`–`1.0` | Konformiert auf exakt diese isotrope Voxelgrösse |
| `< 0.7` | Experimentell; nicht garantiert stabil |
| `keep` | Native Voxelgrösse erhalten. **Nur mit `--seg_only` kompatibel.** Anisotrope Voxel experimentell. |

Die effektive Voxelgrösse triggert automatisch den **Highres-Mode** in der Surface-Pipeline wenn `< 1mm` — andere Algorithmus-Parameter werden gewählt.

## `--keepgeom` / `--native_image`

Beide Flags sind Aliase. Effekt:

- Output-Images bleiben in nativer Voxel-Geometrie (Voxelgrösse, Dimensionen, Orientation).
- Impliziert `--vox_size keep`.
- **Inkompatibel mit der Surface-Pipeline** — nur `--seg_only`.
- Mit `--seg_only --keepgeom` läuft auch das Corpus-Callosum-Modul mit nativer Geometrie (nur Intensity-Scaling + Dtype-Conversion).

Nützlich für Anwendungen, die outputs direkt im Scanner-Space brauchen ohne Resampling-Verluste.

## RAS vs tkRAS — kritische Unterscheidung

FastSurfer (= FreeSurfer-Welt) operiert in **tkRAS-Koordinaten**, nicht in Scanner-RAS. Das ist der häufigste Bug bei Pipeline-Integrationen.

| | Scanner-RAS (nibabel `affine`) | tkRAS (FreeSurfer-Convention) |
|---|---|---|
| Origin | physical scanner | image-center based (tkr/tkregister) |
| Bekommt man via | `vol.affine` | `vol.header.get_vox2ras_tkr()` |
| Offset zu tkRAS | variabel, abhängig vom Scan | — |
| Wo verwendet | NIfTI-konsistente Pipelines | alles FastSurfer/FreeSurfer: aseg, surf, label, atlases |

**Faustregel:** Wenn du FastSurfer-Output (`aseg.mgz`, `aparc+aseg.mgz`, `wmparc.mgz`, surfaces) mit eigener Pipeline kombinierst, **immer `get_vox2ras_tkr()` verwenden**, nicht `affine`.

```python
import nibabel as nib

vol = nib.load("mri/aseg.mgz")

# FALSCH (Scanner-RAS):
affine = vol.affine

# RICHTIG (tkRAS — was FastSurfer-Outputs leben):
tkras = vol.header.get_vox2ras_tkr()
```

Bei NIfTI-Files, die kein FreeSurfer-Header tragen (`.nii.gz`), kann man die tkRAS-Matrix aus einem benachbarten `.mgz` leihen (z.B. `aseg.mgz`).

## Häufige Offset-Bugs

### "17.5mm Y-Offset"

Symptom: Eigenes Mesh sitzt 17.5mm zu weit anterior/posterior gegenüber FastSurfer-aseg.

Ursache: Verwendung von `vol.affine` statt `get_vox2ras_tkr()` bei einem 256³ 1mm conformed Volume. Der Offset entsteht durch unterschiedliche Origin-Konventionen.

Fix: Konsequent `get_vox2ras_tkr()` für alle FastSurfer-Outputs.

### "Cras-Offset" für 2009c-konforme Volumes

Wenn du mit MNI152 NLin2009cAsym arbeitest und FreeSurfer-conformed Volumes erzeugst, kann ein `cras = [0.5, -17.5, 18.5]` (oder ähnlich) auftreten. Das ist **kein Bug**, sondern ein intrinsisches Property des 2009c-Templates wenn es conformed wird. tkRAS-Math ist trotzdem korrekt; die `cras`-Offset-Korrektur muss in nachgelagerten Bake-Scripten berücksichtigt werden.

### "Mein Mesh ist 90° rotiert"

Wenn du `surfaces.pial` aus FreeSurfer/FastSurfer in eine 3D-Engine importierst und das Mesh um 90° um die Y-Achse rotiert ist: Du hast wahrscheinlich Surface-Vertices in tkRAS aber Voxel-Indizes wurden via `affine` (Scanner-RAS) konvertiert. Beide müssen im gleichen Frame stehen.

## Voxel-Grid-Mismatches (CerebNet)

CerebNet-Output (`cerebellum.CerebNet.nii.gz`) ist **immer 1mm isotropic**, egal was die Input-Voxelgrösse war. Wenn dein Input z.B. 0.7mm war:

- `mri/orig.mgz` ist 0.7mm.
- `mri/cerebellum.CerebNet.nii.gz` ist 1mm.
- Zusätzlich wird `mri/orig.1mm.mgz` (oder dein `--conformed_name` mit Suffix `.1mm`) geschrieben für die Cerebellum-Localisation.

Beim Mergen oder Overlay musst du resamplen oder die 1mm-Variante als Referenz nehmen.

## AC/PC-Alignment beim Corpus-Callosum-Modul

Das CC-Modul produziert eine "upright" Variante (`callosum.CC.upright.mgz`) plus eine Transformation `cc_up.lta` (conformed → upright). Die upright-Orientation richtet sich nach AC/PC-Landmarks und ist nicht identisch mit der Conformed-LIA-Orientation. Wenn du CC-Output mit anderen FastSurfer-Files überlagerst, **die Variante in der richtigen Space wählen** (`callosum.CC.orig.mgz` für conformed-Space-Overlays, `callosum.CC.upright.mgz` für upright-Space-Analysen).

Zusätzlich existiert `mri/transforms/orient_volume.lta` als generelle Standardisierung (AC/PC-Landmarks).

## Symlink-Trap

Nach erfolgreichem Surface-Run sind viele "primary" Filenamen tatsächlich Symlinks:

- `mri/aparc.DKTatlas+aseg.mgz` → `aparc.DKTatlas+aseg.mapped.mgz`
- `mri/aparc+aseg.mgz` → `aparc.DKTatlas+aseg.mapped.mgz`
- `mri/wmparc.mgz` → `wmparc.DKTatlas.mapped.mgz`
- `label/{lh,rh}.aparc.DKTatlas.annot` → `label/{lh,rh}.aparc.DKTatlas.mapped.annot`

Beim Kopieren/Movieren von Subject-Dirs musst du `cp -L` (dereferenzieren) oder `cp -a` (symlinks beibehalten + alle Files mitnehmen) konsequent nutzen, sonst brichst du downstream Tools.

## Cross-Reference

- Welche Flags Conformed-Space betreffen: `fastsurfer-cli-flags`
- Wo conformed Files landen: `fastsurfer-outputs`
- Wenn Outputs nicht stimmen: `fastsurfer-debug-conform-tkras`
