---
name: fastsurfer-debug-conform-tkras
description: Use when user has alignment issues between FastSurfer outputs and other neuroimaging data — Mesh sits in wrong location, fixed 17.5mm offset, 90° rotation, voxel-grid mismatches, or NIfTI-vs-MGZ-affine confusion. Triggers on "alignment off", "17.5mm offset", "tkRAS bug", "scanner-RAS vs tkRAS", "FastSurfer mesh in wrong place", "vox2ras_tkr", "voxel grid mismatch", "cerebellum 1mm vs orig 0.7mm", "FastSurfer vs FSL alignment".
---

# FastSurfer — Conform-Space + tkRAS Debug

Häufigste Fehlerklasse bei FastSurfer-Integrationen: **Koordinaten-Frame-Verwechslung** zwischen Scanner-RAS (NIfTI-Standard) und tkRAS (FreeSurfer-Standard). Symptome:

- Mesh sitzt 17.5mm zu weit anterior/posterior gegenüber FastSurfer-Outputs.
- Eigenes Volume ist 90° rotiert gegenüber `aseg.mgz`.
- FSL- oder ANTs-Outputs aligntern nicht mit FastSurfer.
- Cerebellum-Voxel passen nicht zur Cortex-Segmentation.

## Diagnose-Cheatsheet

### Step 1 — Verifiziere welche Affine gelesen wurde

```python
import nibabel as nib

# Lade das Original-MGZ
vol = nib.load("mri/aseg.mgz")

# Drei verschiedene "Affinen":
affine        = vol.affine                          # Scanner-RAS (NIfTI-style)
vox2ras_scanner = vol.header.get_vox2ras()          # alias zu affine
vox2ras_tkr   = vol.header.get_vox2ras_tkr()        # FreeSurfer tkRAS

print("Scanner-RAS:\n", affine)
print("tkRAS:\n", vox2ras_tkr)
print("Differenz:\n", vox2ras_tkr - affine)
```

Wenn die Translation-Komponente (4. Spalte) sich um >1mm unterscheidet → du bist im falschen Frame wenn du `affine` benutzt.

### Step 2 — Verifiziere ob FastSurfer-Outputs in tkRAS sind

**Alle FastSurfer/FreeSurfer-Volumes (`*.mgz`)** sind im konformierten Image-Grid (typisch 256³ 1mm LIA-orientiert). Ihre **physische Position** definiert sich über die tkRAS-Matrix, nicht über die Scanner-Affine.

**FastSurfer-Surfaces (`*.pial`, `*.white`)** haben Vertices direkt in **tkRAS-Koordinaten**.

```python
import nibabel.freesurfer as fs
verts, faces = fs.read_geometry("surf/lh.pial")
# verts sind bereits tkRAS-XYZ, kein Voxel-Index
print("Bbox tkRAS:", verts.min(0), verts.max(0))
# Erwartung: bbox ist ~ [-90, -120, -100] bis [+90, +90, +100]
```

Wenn deine Bbox da nicht passt, hast du sehr wahrscheinlich Scanner-RAS verwechselt.

## Standard-Bugs

### Bug 1 — "17.5mm Y-Offset"

**Symptom:** Eigenes Mesh sitzt 17.5mm zu weit anterior gegenüber FastSurfer-aseg.

**Ursache:** Verwendung von `vol.affine` statt `get_vox2ras_tkr()` für ein 256³ 1mm conformed Volume. Der konkrete Offset von ~17.5mm ist die Differenz zwischen Scanner-RAS-Origin und tkRAS-Origin für ein typisches conformed Volume.

**Fix:**

```python
# FALSCH
voxel_to_world = vol.affine

# RICHTIG für FastSurfer-Outputs
voxel_to_world = vol.header.get_vox2ras_tkr()
```

### Bug 2 — "90° Y-Rotation" bei eigenen Meshes

**Symptom:** Eigener Mesh ist um 90° um die Y-Achse rotiert gegenüber FastSurfer-Surfaces im 3D-Viewer.

**Ursache:** Falsche Achsen-Konvention. FastSurfer/FreeSurfer nutzen **LIA** (Left-Inferior-Anterior) Voxel-Reihenfolge im conformed Image. Wenn du Voxel-Indizes direkt als XYZ interpretierst ohne via tkRAS zu mappen, gibt's eine 90°-Rotation.

**Fix:** Konsequent `get_vox2ras_tkr()` benutzen um Voxel-Indizes in tkRAS-Welt zu mappen.

```python
import numpy as np
import nibabel as nib

vol = nib.load("mri/aseg.mgz")
tkras = vol.header.get_vox2ras_tkr()

# Für ein Voxel-Index (i, j, k):
voxel = np.array([100, 120, 130, 1])
world_xyz = tkras @ voxel
print(world_xyz[:3])   # tkRAS-Koordinaten
```

### Bug 3 — "cras-Offset bei MNI152 NLin2009cAsym"

**Symptom:** Du arbeitest mit dem MNI152 NLin2009c-Asym-Template als Subject-Anatomy. Nach Konformierung ergibt sich ein `cras = [0.5, -17.5, 18.5]` (oder ähnlich). FastSurfer-Outputs alignieren nicht mit deinen MNI152-Atlanten.

**Ursache:** Das 2009c-Template hat ein intrinsisches Y-Offset, das beim Conformen zu einem nicht-null cras führt. Das ist **kein Bug**, sondern by-design.

**Fix:**
- Wenn du in tkRAS rendern willst: nutze `get_vox2ras_tkr()` direkt — das berücksichtigt den cras-Offset bereits.
- Wenn du Outputs zurück in MNI152-Welt willst: addiere den cras-Offset zu den tkRAS-Koordinaten:
  ```python
  cras = vol.header.get_zooms()  # ... oder via mri_info "c_(r, a, s)"
  # mri_info-Befehl: mri_info <vol>.mgz | grep "c_(r,a,s)"
  ```

### Bug 4 — "CerebNet ist 1mm, Cortex ist 0.7mm"

**Symptom:** Du arbeitest mit Highres-Input (0.7mm) und willst Cortex (`aseg.mgz`) mit CerebNet-Output (`cerebellum.CerebNet.nii.gz`) overlayen. Die Volumes haben unterschiedliche Voxel-Grössen.

**Ursache:** CerebNet läuft IMMER auf 1mm — siehe Skill `fastsurfer-segmentation`.

**Fix:**

Option A — CerebNet-Seg zurück auf 0.7mm resamplen (linear/nearest):

```bash
mri_convert -rl mri/orig.mgz mri/cerebellum.CerebNet.nii.gz mri/cerebellum.CerebNet.0.7mm.mgz -rt nearest
```

Option B — Cortex-Seg auf 1mm resamplen mit nearest-neighbour:

```bash
mri_convert -rl mri/orig.1mm.mgz mri/aparc.DKTatlas+aseg.deep.mgz mri/aparc.DKTatlas+aseg.deep.1mm.mgz -rt nearest
```

Option C — beide auf eine gemeinsame 1mm-Referenz mappen.

### Bug 5 — Symlinks vs Real-Files

**Symptom:** Du kopierst ein Subject-Dir zu einer anderen Maschine; danach sind FastSurfer-Outputs unvollständig.

**Ursache:** Nach erfolgreichem Surf-Run sind viele "primary" Filenamen **Symlinks** (z.B. `mri/wmparc.mgz` → `mri/wmparc.DKTatlas.mapped.mgz`). Ein `cp -r` ohne `-L` oder `-a` führt zu Broken-Symlinks.

**Fix:**

```bash
# Kopiere mit Symlinks beibehalten (alle Files mitnehmen):
cp -a $SUBJECTS_DIR/$SID /dest/path/

# ODER: dereferenziere alle Symlinks (mehr Disk-Space, aber portabel):
cp -rL $SUBJECTS_DIR/$SID /dest/path/

# ODER: rsync (Standard ist symlink-preserving):
rsync -a $SUBJECTS_DIR/$SID /dest/path/
```

### Bug 6 — Native-Geometry vs Conformed-Mismatch

**Symptom:** Du hast mit `--keepgeom` segmentiert (native Voxel-Geometrie). Eigene Pipeline erwartet aber conformed Volumes.

**Ursache:** `--keepgeom` (= `--native_image`) skipped die Conformation. Outputs sind in nativer Geometrie. **Nicht mit Surface-Pipeline kompatibel** — Surfaces brauchen conformed.

**Fix:**
- Wenn du Surface willst: `--keepgeom` weglassen, normal konformieren.
- Wenn du native bleiben willst: nur `--seg_only`, und downstream-Pipeline auf native Geometrie anpassen.

## Tools für Sanity-Checks

### FreeSurfer

```bash
# Header-Info inkl. tkRAS-Matrix
mri_info mri/aseg.mgz

# Voxel-Grid + Origin
mri_info mri/aseg.mgz | grep -E "voxel sizes|c_\(r,a,s\)|TR"
```

### nibabel

```python
import nibabel as nib
vol = nib.load("mri/aseg.mgz")
print(vol.header)                            # Voller Header
print(vol.header.get_zooms())                # Voxel-Grösse
print(vol.affine)                            # Scanner-RAS
print(vol.header.get_vox2ras_tkr())          # tkRAS
print(vol.header.get_data_shape())           # Dimensionen
```

### FreeView (visueller Cross-Check)

```bash
freeview \
  -v mri/orig.mgz \
  -v mri/aparc.DKTatlas+aseg.deep.mgz:colormap=lut \
  -v mri/cerebellum.CerebNet.nii.gz:colormap=lut \
  -f surf/lh.pial:edgecolor=red surf/rh.pial:edgecolor=red
```

Wenn alle Layer im FreeView konsistent sitzen, sind die Outputs intern konsistent. Wenn dein eigenes Mesh/Volume daneben sitzt, dann ist der Bug in deinem Code (= Frame-Verwechslung), nicht in FastSurfer.

## Quick-Test: bist du im falschen Frame?

```python
import nibabel as nib
import nibabel.freesurfer as fs
import numpy as np

vol = nib.load("mri/aseg.mgz")
verts, _ = fs.read_geometry("surf/lh.pial")

# Surface-Vertices sind in tkRAS.
# Wir transformieren sie INVERS zurück in Voxel-Indizes mit beiden Methoden.

tkras_inv = np.linalg.inv(vol.header.get_vox2ras_tkr())
scanner_inv = np.linalg.inv(vol.affine)

v_h = np.hstack([verts, np.ones((verts.shape[0], 1))])
voxels_tkr = (tkras_inv @ v_h.T).T[:, :3]
voxels_scanner = (scanner_inv @ v_h.T).T[:, :3]

# Erwartung: voxels_tkr liegt innerhalb [0, 256] für ein 256³ Volume.
# voxels_scanner kann ausserhalb liegen wenn cras-Offset existiert.
print("tkRAS Voxel-Range:", voxels_tkr.min(0), voxels_tkr.max(0))
print("Scanner Voxel-Range:", voxels_scanner.min(0), voxels_scanner.max(0))
```

Wenn `voxels_tkr` schön innerhalb der Volume-Dimensionen liegt aber `voxels_scanner` weit ausserhalb: du musst tkRAS nutzen.

## Cross-Reference

- Conformed-Space-Konzepte: `fastsurfer-conform-space`
- Output-Layout (Symlinks etc.): `fastsurfer-outputs`
- Wenn Outputs ganz fehlen: `fastsurfer-debug-outputs`
