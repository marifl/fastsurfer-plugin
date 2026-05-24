---
name: fastsurfer-debug-outputs
description: Use when a FastSurfer run finished but outputs are missing, incomplete, or look wrong — or when the user wants to validate output completeness, check label sets, or trace which pipeline step produced a given file. Triggers on "FastSurfer output missing", "aseg.mgz missing", "expected files", "validate FastSurfer subject", "incomplete output", "FastSurfer crashed mid-run", "no surfaces produced", "stats file empty".
---

# FastSurfer — Output-Validation und Debug

Wenn ein Run "fertig" sagt aber Files fehlen oder kaputt sind, geh strukturiert vor:

1. **Was hat die Pipeline tatsächlich gemacht?** → Logfiles inspizieren.
2. **Welche Files erwartet vs vorhanden?** → Soll-/Ist-Vergleich.
3. **Sind die vorhandenen Files valide?** → Header + Dimensions + Labels prüfen.
4. **Wo ist es genau abgebrochen?** → letzten Schritt im Log identifizieren.

## Schritt 1 — Logfiles

```bash
SUBJECT_DIR=$SUBJECTS_DIR/$SID

# Segmentation
tail -50 $SUBJECT_DIR/scripts/deep-seg.log
grep -iE "error|fail|abort" $SUBJECT_DIR/scripts/deep-seg.log

# Surface
tail -50 $SUBJECT_DIR/scripts/recon-all.log
grep -iE "error|fail|abort" $SUBJECT_DIR/scripts/recon-all.log
```

**Wonach suchen:**

| Pattern | Bedeutung |
|---------|-----------|
| `CUDA out of memory` | GPU-OOM → `--viewagg_device cpu` oder kleinerer `--batch` |
| `ImportError: No module named X` | Python-Env unvollständig |
| `License invalid` / `License not found` | siehe `fastsurfer-debug-license` |
| `FREESURFER_HOME not set` | FreeSurfer-Env nicht gesourced |
| `mri_coreg failed` | T1/T2-Registration-Fehler (HypVINN mit `--t2`) |
| `Talairach failed` | Image-Quality-Problem oder Atlas-Mismatch |
| `Could not find checkpoint` | Checkpoint fehlt → `download_checkpoints.py` |
| `No GPU detected` | `--device` mismatch oder NVIDIA-Driver-Problem |

## Schritt 2 — Erwartete Files

### Vollständiger Run (Seg + Surf, alle Module)

```bash
SUBJECT_DIR=$SUBJECTS_DIR/$SID
EXPECTED=(
  # asegdkt + post-surf-updated
  mri/aparc.DKTatlas+aseg.deep.mgz
  mri/aparc.DKTatlas+aseg.mgz             # symlink post-surf
  mri/aseg.mgz                            # post-surf
  mri/orig.mgz
  mri/orig_nu.mgz
  mri/mask.mgz
  mri/wmparc.mgz
  # cereb
  mri/cerebellum.CerebNet.nii.gz
  stats/cerebellum.CerebNet.stats
  # hypothal
  mri/hypothalamus.HypVINN.nii.gz
  stats/hypothalamus.HypVINN.stats
  # cc
  mri/callosum.CC.upright.mgz
  stats/callosum.CC.midslice.json
  # surf
  surf/lh.pial surf/rh.pial
  surf/lh.white surf/rh.white
  surf/lh.thickness surf/rh.thickness
  surf/lh.inflated surf/rh.inflated
  label/lh.aparc.DKTatlas.annot
  label/rh.aparc.DKTatlas.annot
  # stats
  stats/aseg.stats
  stats/lh.aparc.DKTatlas.mapped.stats
  stats/rh.aparc.DKTatlas.mapped.stats
)
for f in "${EXPECTED[@]}"; do
  [ -e "$SUBJECT_DIR/$f" ] || echo "MISSING: $f"
done
```

### Nur Seg (`--seg_only`)

Erwarte:
- `mri/aparc.DKTatlas+aseg.deep.mgz` (asegdkt)
- `mri/orig.mgz`, `mri/orig_nu.mgz`, `mri/mask.mgz`
- `mri/cerebellum.CerebNet.nii.gz` (wenn nicht `--no_cereb`)
- `mri/hypothalamus.HypVINN.nii.gz` (wenn nicht `--no_hypothal`)
- `mri/callosum.CC.upright.mgz` (wenn nicht `--no_cc`)
- `stats/aseg+DKT.stats`
- KEINE `surf/`, `label/`, `stats/aseg.stats` Files.

### Nur Surf (`--surf_only`)

Erwarte:
- Vorher müssen Seg-Outputs existieren (vor allem `aparc.DKTatlas+aseg.deep.mgz` und CC-Outputs).
- Erzeugt: alle `surf/`, `label/`, `mri/aseg.mgz`, post-surf `mri/aparc...mgz`-Symlinks, `stats/`-Files.

## Schritt 3 — File-Validation

### MGZ / NIfTI Header

```bash
# Mit FreeSurfer
mri_info $SUBJECT_DIR/mri/aseg.mgz

# Mit nibabel (Python)
python3 -c "
import nibabel as nib
vol = nib.load('$SUBJECT_DIR/mri/aseg.mgz')
print('shape:', vol.shape)
print('zooms:', vol.header.get_zooms())
print('affine:')
print(vol.affine)
"
```

**Sanity-Checks:**

- Conformed-Output sollte 256³ (oder 320³ bei 0.7mm) sein.
- Voxel-Zooms sollten den `--vox_size`-Wert reflektieren (default 1mm isotropic).
- `aseg.mgz`-Range sollte ungefähr [0, 5001] sein (FreeSurfer-Label-IDs).

### Labels in Seg-Files

```python
import nibabel as nib
import numpy as np

vol = nib.load("mri/aparc.DKTatlas+aseg.deep.mgz")
data = np.asanyarray(vol.dataobj)
labels = np.unique(data)
print(f"N labels: {len(labels)}")
print(f"Label range: {labels.min()} – {labels.max()}")
print(f"All labels: {labels.tolist()}")
```

Erwartete Labelzahl asegdkt: ~95 Klassen (inkl. background = 0).

Wenn nur wenige Labels → Network hat wahrscheinlich nichts vernünftig segmentiert (Image-Quality oder Pre-processing Problem).

### Surface-Validation

```bash
# Mit FreeSurfer
mris_info $SUBJECT_DIR/surf/lh.pial

# Mit Python (nibabel)
python3 -c "
import nibabel as nib
import nibabel.freesurfer as fs
verts, faces = fs.read_geometry('$SUBJECT_DIR/surf/lh.pial')
print('vertices:', verts.shape[0])
print('faces:', faces.shape[0])
print('bbox:', verts.min(0), verts.max(0))
"
```

Sanity:
- Typische Vertex-Counts: 100k–200k pro Hemisphäre (default), höher bei Highres.
- BBox sollte ~Hirn-Dimensionen sein (ca. ±90mm in jeder Achse).

### Stats-File-Plausibilität

```bash
head -30 $SUBJECT_DIR/stats/aseg.stats
```

Sollte FreeSurfer-Format sein (Header mit `# Measure`-Zeilen + Tabular-Data). Wenn leer oder nur Header: Stats-Computation ist abgebrochen.

```bash
# Volume-Summen sanity check
grep "Brain " $SUBJECT_DIR/stats/aseg.stats   # eTIV, BrainSeg, etc.
```

Total Brain Volume sollte typisch 1.1–1.6 Liter (1.1e6–1.6e6 mm³) bei Erwachsenen sein.

## Schritt 4 — "Wo ist es abgebrochen?"

Approximative Schritt-Map vs Output-Files:

| Wenn fehlt … | … dann ist Pipeline gestoppt nach: |
|---|---|
| `mri/orig.mgz` | Conform-Step (ganz am Anfang) |
| `mri/aparc.DKTatlas+aseg.deep.mgz` | asegdkt-Inference |
| `mri/cerebellum.CerebNet.nii.gz` | CerebNet (asegdkt war OK) |
| `mri/hypothalamus.HypVINN.nii.gz` | HypVINN |
| `mri/callosum.CC.upright.mgz` | CC-Modul |
| `mri/wm.mgz` (existiert nicht aber surfaces fehlen) | Pre-Surface-WM-Generation |
| `surf/lh.orig` | Marching-Cubes/Tesselate |
| `surf/lh.white` | WM-Surface-Generation |
| `surf/lh.pial` | Pial-Surface-Generation |
| `surf/lh.sphere` | Spherical-Projection |
| `label/lh.aparc.DKTatlas.mapped.annot` | DL-Annot-Mapping |
| `stats/aseg.stats` | Final-Stats-Computation |

Im `recon-all.log` nach dem letzten erfolgreichen Step grepen:

```bash
grep "@#@" $SUBJECT_DIR/scripts/recon-all.log   # FreeSurfer-Style Step-Marker
```

## Häufige "Output sieht falsch aus"-Probleme

### Segmentation hat falsche Hemisphären (rechts/links vertauscht)

Ursache: Input-Image hat eine Orientation die FastSurfer nicht erwartet (z.B. RPI statt LPI/LIA), und die Konformierungs-Heuristik hat es nicht korrekt umgedreht.

Fix:
1. `mri_info <input.nii.gz>` → schau auf "voxel_to_ras transform" Sektion.
2. Ggf. mit `mri_convert --in_orientation LPI input.nii.gz output.nii.gz` umorientieren.
3. Oder direkt durch FreeSurfer/FSL pre-konformieren bevor FastSurfer aufgerufen wird.

### Surfaces haben Holes oder Spikes

Ursache: WM-Segmentation hatte Holes, was sich in Surface-Marching durchschlägt.

Fix:
- Mit `--fstess` statt `--fsmc` versuchen (klassische Tesselation kann robuster sein).
- Image-Quality prüfen: zu starkes Rauschen, Motion-Artefakte?
- Manuell editieren mit `tkmedit` oder `freeview` → `--edits` flag im re-run.

### Stats-Volumes sind absurd niedrig/hoch

Ursache: meist Skull-Stripping oder Biasfield-Problem.

Fix:
- `mri/mask.mgz` visualisieren → schau ob Brain-Region korrekt erfasst ist.
- `mri/orig_nu.mgz` visualisieren → schau ob Biasfield-Correction realistisch ist.
- Ggf. `--no_biasfield` testen (entfernt PV-Korrektur, aber zeigt ob das Biasfield das Problem war).

### CerebNet Output hat falsche Voxel-Grösse

Erwartet: CerebNet ist immer 1mm. Wenn dein Conformed-Image nicht 1mm war, wird zusätzlich `orig.1mm.mgz` erzeugt. Wenn dein Workflow das nicht erwartet hat: das ist by-design.

## Wenn du komplett re-runnen willst

```bash
rm -rf $SUBJECTS_DIR/$SID
# dann run_fastsurfer.sh erneut
```

Wenn du nur die Surface neu rechnen willst aber Seg behalten:

```bash
rm -rf $SUBJECTS_DIR/$SID/surf $SUBJECTS_DIR/$SID/label
rm $SUBJECTS_DIR/$SID/mri/aseg.mgz   # post-surf-version löschen
rm $SUBJECTS_DIR/$SID/mri/aparc.DKTatlas+aseg.mapped.mgz
run_fastsurfer.sh --surf_only --sid $SID --sd $SUBJECTS_DIR ...
```

## Cross-Reference

- Volle Output-Referenz: `fastsurfer-outputs`
- Conformed-Space-Bugs: `fastsurfer-debug-conform-tkras`
- GPU-/Memory-Issues: `fastsurfer-debug-gpu-memory`
- License-Probleme: `fastsurfer-debug-license`
