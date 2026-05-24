---
name: fastsurfer-segmentation
description: Use when the user asks deep questions about FastSurfer's segmentation modules — FastSurferVINN architecture, how asegdkt produces its 95 classes, how CerebNet sub-segments cerebellum, how HypVINN handles T1+T2, how Corpus Callosum module works, or label sets / class indices. Triggers on "VINN architecture", "view aggregation", "asegdkt labels", "DKT classes", "CerebNet network", "HypVINN multi-view", "FastSurfer-CC", "corpus callosum thickness", "soft labels".
---

# FastSurfer — Segmentation-Module im Detail

Vier Segmentation-Module: `asegdkt`, `cc`, `cereb`, `hypothal`. Alle laufen per Default ausser explizit deaktiviert.

## asegdkt (FastSurferVINN)

**Code:** `FastSurferCNN/run_prediction.py` + `FastSurferCNN/models/`
**Paper:** Henschel et al., NeuroImage 251 (2022), 118933 — "FastSurferVINN: Building Resolution-Independence into Deep Learning Segmentation Methods"

### Architektur

FastSurferVINN ist eine **Voxel-Size-Invariant Network**-Architektur, die die ursprüngliche FastSurferCNN-Architektur um Auflösungs-Unabhängigkeit erweitert.

- **2.5D Multi-View Approach**: drei separate Networks für Coronal, Axial, Sagittal Slices.
- **View-Aggregation**: drei Vorhersagen werden zu einem 3D-Volume kombiniert (gewichtet, mit Confidence-Maps).
- **Sliding-Window-Inference**: Bilder werden in Patches überlappend prozessiert.
- **95 Klassen**: aseg-Subcortex-Labels + DKT-Cortex-Parcellation, äquivalent zu FreeSurfer's `aparc.DKTatlas+aseg.mgz`.

### Auflösungs-Unabhängigkeit (VINN)

Die VINN-Architektur lernt Voxel-Grössen-Information implizit via einen **Voxel-Size-Embedding** in den Convolutional Layers. Konkret: ein zusätzlicher Channel kodiert die effective Voxelgrösse (mm pro Voxel), den das Network mit-lernt. Dadurch kann ein einziges Network 1mm-, 0.8mm-, 0.7mm-Volumes verarbeiten ohne separates Training.

### View-Aggregation-Device

`--viewagg_device` steuert wo die 3D-Aggregation läuft:

- `auto` (Default): Memory-Check, fällt auf CPU wenn nicht genug GPU-RAM.
- `cuda` / `cuda:N`: zwingend auf GPU.
- `cpu`: zwingend auf CPU (langsamer aber sicher).

Bei kleinen GPUs (<8GB) explizit `--viewagg_device cpu` setzen.

### Output-Labels

Voll-Set der DKT-Labels: siehe `FastSurferCNN/config/` oder die FreeSurfer `FreeSurferColorLUT.txt`. Die Labels sind 1:1 kompatibel mit `aparc.DKTatlas+aseg.mgz` aus FreeSurfer.

### Stats

`stats/aseg+DKT.stats` enthält Volume-Stats inkl. **Partial-Volume-Correction** (deaktivierbar via `--no_biasfield`). Format identisch zu FreeSurfer's `aseg.stats`.

## cc (Corpus Callosum / FastSurfer-CC)

**Code:** `CorpusCallosum/` (Entry: `fastsurfer_cc.py`)
**Paper:** Pollak et al., arXiv:2511.16471 — "FastSurfer-CC: A robust, accurate, and comprehensive framework for corpus callosum morphometry"

### Pipeline

1. **AC/PC-Standardisierung** — `mri/transforms/orient_volume.lta` wird berechnet aus asegdkt-Output.
2. **Upright-Resampling** — Conformed-Image wird in upright-Space gemappt (AC/PC-aligned). Transform `mri/transforms/cc_up.lta`.
3. **CC-Segmentation** — DL-basierte Segmentation auf mid-sagittaler Slice (und benachbarte Slices).
4. **Soft-Labels** — Probabilistische Maps für CC, Fornix und Background.
5. **Shape-Analyse** — Thickness-Profile, Area, Landmarks. Output als JSON.
6. **Mesh-Generation** — 3D-Mesh (FreeSurfer-Surface + VTK).
7. **QC-Snapshots** — optional bei `--qc_snap`: PNG-Contours + interaktive HTML-3D-View.

### Wichtige Outputs

| Output | Zweck |
|--------|-------|
| `callosum.CC.upright.mgz` | Primary-Seg in upright-Space (zum Analysieren) |
| `callosum.CC.orig.mgz` | Seg zurückgemappt in conformed-Space (für Overlays mit aseg etc.) |
| `callosum.CC.midslice.json` | Mid-sagittal Measurements: Area, Thickness-Profile, Landmarks |
| `callosum.CC.all_slices.json` | Per-Slice Analyse |
| `surf/callosum.{surf,vtk}` | 3D-Mesh für Visualization |
| `surf/callosum.thickness.w` | Thickness-Overlay für FreeSurfer's `callosum.surf` |

### Standalone

`fastsurfer_cc.py` ist auch standalone aufrufbar — z.B. wenn man nur CC-Analyse auf einem bereits segmentierten Subject machen will. Optional-Flag `--upright_volume` erzeugt zusätzlich `mri/upright_volume.mgz` (das resampled Image im upright-Space, nicht nur die Seg).

## cereb (CerebNet)

**Code:** `CerebNet/run_prediction.py` + `CerebNet/models/`
**Paper:** Faber et al., NeuroImage 264 (2022), 119703 — "CerebNet: A fast and reliable deep-learning pipeline for detailed cerebellum sub-segmentation"

### Architektur

- **2.5D U-Net-Variant** trainiert auf manuell segmentierten Cerebellum-Daten.
- **Lokalisations-Cropping**: nutzt asegdkt's grobes Cerebellum-Label um eine Bounding-Box zu bestimmen → Network sieht nur den relevanten Crop (effizienter, präziser).
- **Detaillierte WM/GM-Delineation** der Lobuli + Tonsils + Vermis + Hemisphere-Bereiche.

### Auflösung

CerebNet läuft **immer auf 1mm isotropic**. Wenn `mri/orig.mgz` nicht bereits 1mm ist, wird ein zusätzliches `orig.1mm.mgz` (oder `<conformed_name>.1mm`) erzeugt für die Inference.

Output `mri/cerebellum.CerebNet.nii.gz` ist daher auch immer 1mm.

### Label-Set

Detaillierte Cerebellum-Sub-Labels (Lobuli I-X für linke/rechte Hemisphäre, Vermis-Lobuli, Cerebellum-WM links/rechts, Cerebellum-Cortex links/rechts).

### Stats

`stats/cerebellum.CerebNet.stats` — FreeSurfer-Stats-kompatibles Format mit Volumes pro Sub-Region. PV-Correction wenn nicht `--no_biasfield`.

## hypothal (HypVINN)

**Code:** `HypVINN/run_prediction.py` + `HypVINN/models/`
**Paper:** Estrada et al., Imaging Neuroscience 2023; 1 1–32 — "FastSurfer-HypVINN: Automated sub-segmentation of the hypothalamus and adjacent structures on high-resolutional brain MRI"

### Architektur

- **VINN-basiert** wie asegdkt — auflösungs-unabhängig (bis 0.7mm, experimentell darüber).
- **Multi-View Aggregation** über Coronal+Axial+Sagittal.
- **Optional Multi-Modal**: T2-Input verbessert die Segmentation in T1-low-contrast Regionen (3. Ventrikel, kleine Nuclei).

### T1+T2-Workflow

Wenn `--t2 <path>` gepasst wird:

1. T2 wird biasfield-korrigiert (`mri/T2_nu.mgz`).
2. T2 wird zu T1 co-registriert (`mri/T2_nu_reg.mgz`). Methode via `--reg_mode`:
   - `coreg` (Default): `mri_coreg` (FreeSurfer).
   - `robust`: `mri_robust_register` (robuster bei pathologischen Hirnen).
   - `none`: skip Registration — erwartet dass T1+T2 bereits extern co-registriert sind.
3. Network sieht stacked T1+T2-Input.

### Output-Strukturen

HypVINN segmentiert:
- Hypothalamus selbst (linke + rechte Hemisphere)
- 3. Ventrikel
- Corpora mamillaria
- Fornix
- Tractus opticus

Output `mri/hypothalamus.HypVINN.nii.gz` enthält alle Sub-Labels. `mri/hypothalamus_mask.HypVINN.nii.gz` ist eine binary Mask der gesamten Region.

### Stats

`stats/hypothalamus.HypVINN.stats` — Volumes pro Sub-Region. Basis: biasfield-korrigiertes T1 (skipped bei `--no_biasfield`).

### QC

Mit `--qc_snap` werden visuelle QC-Snapshots in `qc_snapshots/` erzeugt.

## Modul-Reihenfolge & Dependencies

```
asegdkt (FastSurferVINN)
    ├── liefert mri/aparc.DKTatlas+aseg.deep.mgz + mri/orig.mgz + mri/orig_nu.mgz + mri/mask.mgz
    │
    ├──▶ cc          (benötigt asegdkt + orig.mgz)
    ├──▶ cereb       (benötigt asegdkt für Localisation)
    └──▶ hypothal    (benötigt orig.mgz; optional T2)
```

Wenn `--no_asegdkt`, müssen `cc`/`cereb`/`hypothal` einen existing `--asegdkt_segfile` referenzieren.

## "Stats vorher vs nachher Surface"

Die Segmentation-Module produzieren initiale Stats (`aseg+DKT.stats`). Nach erfolgreichem Surface-Run werden viele Stats und Volumes **fein-justiert**:

- `mri/aseg.mgz` — neue Version mit Surface-PV-Korrektur
- `mri/aparc.DKTatlas+aseg.mapped.mgz` — neu mit Surface-PV-Korrektur
- `mri/aparc.DKTatlas+aseg.deep.withCC.mgz` — original-DL-Seg + CC-Labels addiert
- `stats/aseg.stats` — neue Version (nach Surface-Run)

Für downstream-Analysen die Post-Surface-Stats nutzen (`stats/aseg.stats`, `stats/{lh,rh}.aparc.DKTatlas.mapped.stats`).

## Cross-Reference

- Surface-Pipeline: `fastsurfer-surface-recon`
- Output-Pfade aller Module: `fastsurfer-outputs`
- Conformed-Space-Implikationen: `fastsurfer-conform-space`
- Code-Layout: `fastsurfer-internals`
- Checkpoint-Loading: `fastsurfer-checkpoints-models`
