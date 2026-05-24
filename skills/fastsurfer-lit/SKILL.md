---
name: fastsurfer-lit
description: Use when the user wants to use FastSurfer with lesion inpainting (LIT extension), asks about `--lesion_mask`, tumor/cavity handling, lesion impact reports, or `.lit` backup files. Triggers on "lesion_mask", "lesion inpainting", "FastSurfer LIT", "tumor segmentation", "neurolit", "inpainted", "lesion_impact_summary", ".lit backup", "post-stroke FastSurfer".
---

# FastSurfer-LIT — Lesion Inpainting Tool (Experimentell)

LIT wrappt die FastSurfer-Segmentation- und Surface-Pipelines mit einem **Inpainting-Schritt**: Lesion-Regionen (Tumor, Operations-Kavität, Schlaganfall-Areale, MS-Plaques) werden vor der Segmentation rekonstruiert, sodass die DL-Networks "gesundes" Tissue sehen. Danach werden Outputs mit der ursprünglichen Lesion zurückgemappt und Reports erstellt.

**Status:** Experimentell. LIT-modifizierte Outputs vor downstream-Analysen prüfen.
**Doku im Repo:** `doc/overview/modules/LIT.md`.

## Aktivierung

```bash
run_fastsurfer.sh \
  --t1 /abs/path/t1.nii.gz \
  --lesion_mask /abs/path/lesion_mask.nii.gz \
  --sid subjectX --sd /output \
  --fs_license /path/license.txt \
  --3T --threads 4
```

`--lesion_mask` aktiviert die LIT-Pipeline. Maske muss:
- absolute Pfade haben (wie alle FastSurfer-Input-Pfade).
- binary oder probabilistic sein (Voxel > 0 = Lesion).
- im **Input-T1-Space** (nicht conformed). Wird intern in den FastSurfer-Image-Space gemappt.

Mask-Requirements im Detail: `doc/overview/modules/LIT.md#lesion-mask-requirements`.

## Pipeline-Schritte (LIT)

```
1. Input: T1 + Lesion-Mask
   ↓
2. Conform + Pre-process Lesion-Mask
   ↓
3. Inpaint Lesion-Region                 → mri/inpainted.lit.nii.gz
                                          → mri/mask.lit.nii.gz (processed Mask)
   ↓
4. Run FastSurfer-Pipeline auf inpainted Image
   (asegdkt + cc + cereb + hypothal + optional surf)
   ↓
5. Map Lesion zurück in alle Output-Segs
   - Lesion-Voxel überschreiben mit Lesion-Label
   - Stats werden re-computed mit Lesion-Korrektur
   - Pre-Lesion-Versions bleiben als *.lit.<ext> Backups
   ↓
6. Generiere Reports:
   - stats/lesion_impact_summary.yaml
   - stats/aparc.DKTatlas+aseg.lesion_report.txt
   - stats/aseg.lesion_report.txt
   - stats/{lh,rh}.aparc.DKTatlas.anatomy_report.txt (wenn Surf läuft)
```

## Inkompatibilitäten

- **Nicht mit `--surf_only` kompatibel.** LIT muss vor der Segmentation laufen — wenn die Seg schon existiert, kann sie nicht nachträglich "ge-inpainted" werden.
- **Im longitudinal Stream** ist Verhalten unklar; LIT-Doc konsultieren.

## Backup-Schema (.lit Files)

LIT überschreibt die primary FastSurfer-Outputs mit Lesion-integrierten Versionen und behält die Pre-Lesion-Versionen als `.lit`-Backups.

### MRI-Backups (in `mri/`)

| Primary (Lesion-integriert) | Backup (Pre-Lesion) |
|---|---|
| `aparc.DKTatlas+aseg.deep.mgz` | `aparc.DKTatlas+aseg.deep.lit.mgz` |
| `aseg.auto_noCCseg.mgz` | `aseg.auto_noCCseg.lit.mgz` |
| `cerebellum.CerebNet.nii.gz` | `cerebellum.CerebNet.lit.nii.gz` |
| `hypothalamus.HypVINN.nii.gz` | `hypothalamus.HypVINN.lit.nii.gz` |

### Stats-Backups (in `stats/`)

| Primary | Backup |
|---|---|
| `aseg+DKT.VINN.stats` | `aseg+DKT.VINN.lit.stats` |
| `aseg.VINN.stats` | `aseg.VINN.lit.stats` |
| `cerebellum.CerebNet.stats` | `cerebellum.CerebNet.lit.stats` |
| `hypothalamus.HypVINN.stats` | `hypothalamus.HypVINN.lit.stats` |

### Surface-Backups (in `label/`, `stats/`)

| Primary | Backup |
|---|---|
| `label/{lh,rh}.aparc.DKTatlas.annot` (symlink) | `label/{lh,rh}.aparc.DKTatlas.lit.annot` (symlink) |
| `stats/{lh,rh}.aparc.DKTatlas.stats` | `stats/{lh,rh}.aparc.DKTatlas.mapped.stats` |

## Reports

### lesion_impact_summary.yaml

Machine-readable YAML mit:

```yaml
lesion:
  volume_voxels: <int>
  volume_mm3: <float>
  hemisphere: <left|right|bilateral>
affected_regions:
  - region_name: <str>
    region_label: <int>
    voxels_affected: <int>
    pct_of_region: <float>
  - ...
```

Praktisch für automatische Pipelines die nur Subjects mit Lesion in spezifischen Regionen analysieren wollen.

### Textreports

- `aparc.DKTatlas+aseg.lesion_report.txt` — volumetrische Subregionen.
- `aseg.lesion_report.txt` — FreeSurfer-aseg-Sicht.
- `{lh,rh}.aparc.DKTatlas.anatomy_report.txt` — cortikale Surface-Sicht (nur wenn Surf läuft).

Beide enthalten Per-Region: Region-Name, %-Coverage durch Lesion, gemessenes vs erwartetes Volumen.

## LIT-Inpainting-Intermediates

Falls du das LIT-Modell debuggen oder die Inpaint-Qualität prüfen willst:

| File | Was |
|------|------|
| `mri/inpainted.lit.nii.gz` | Inpainted T1 (was die FastSurfer-Pipeline tatsächlich gesehen hat) |
| `mri/mask.lit.nii.gz` | Lesion-Mask in FastSurfer-Image-Space (post-conformation) |
| `mri/orig/mask.lit.nii.gz` | Original Lesion-Mask (vom User gepasst) |
| `mri/orig/inpainting_original_image.lit.nii.gz` | LIT-internes "Vorher" |
| `mri/orig/inpainting_masked_image.lit.nii.gz` | LIT-internes "Mit-Maske" |
| `scripts/inpainting_*.lit.png` | Preview-Bilder vom Inpainting-Process |

Vergleich `inpainted.lit.nii.gz` vs originales T1 mit FreeView oder `mrview` zeigt direkt die Inpaint-Qualität.

## Best-Practices

1. **Mask immer in T1-Space passen**, nicht conformed.
2. **Inpainted Image visualisieren** bevor du Stats interpretierst — wenn das Inpainting unrealistisch aussieht (z.B. helle Artefakte), sind alle downstream Stats fragwürdig.
3. **`lesion_impact_summary.yaml` immer prüfen** — wenn eine Region zu >50% von der Lesion betroffen ist, ist deren Volume-Schätzung unzuverlässig.
4. **`.lit`-Backups behalten** — sie zeigen "was wäre wenn keine Lesion da war" und sind für Sensitivity-Analyses wertvoll.

## Verwandte Skills

- Output-Layout aller `.lit`-Files: `fastsurfer-outputs`
- Conformed-Space-Implikationen (Mask-Mapping): `fastsurfer-conform-space`
- Surface-Pipeline-Verhalten mit Lesion: `fastsurfer-surface-recon`
