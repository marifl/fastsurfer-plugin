---
name: fastsurfer-surface-recon
description: Use when the user asks how FastSurfer's surface reconstruction works internally, how it interfaces with FreeSurfer binaries, what `recon-surf.sh` does step-by-step, surface registration details, Talairach registration, or wants to debug surface-pipeline errors. Triggers on "recon-surf", "recon-surf.sh", "surface pipeline", "pial surface", "white surface", "mri_mc", "mri_tesselate", "qsphere", "spectral spherical projection", "FreeSurfer license", "surface registration", "Talairach".
---

# FastSurfer — Surface-Pipeline (recon-surf)

Die Surface-Pipeline ist ein **partielles FreeSurfer-recon-all** mit DL-Pre-Computed-Inputs. Sie nutzt FreeSurfer-Binaries und benötigt daher eine **gültige FreeSurfer-Lizenz** (`--fs_license <abs_path>`).

**Code:** `recon_surf/recon-surf.sh` (+ `talairach-reg.sh`, `recon-surfreg.sh`, `long_prepare_template.sh`, `functions.sh`).

## Voraussetzungen

1. **Segmentations-Outputs** existieren bereits: `mri/aparc.DKTatlas+aseg.deep.mgz`, `mri/orig.mgz`, `mri/orig_nu.mgz`, `mri/mask.mgz`, sowie CC-Outputs.
2. **FreeSurfer-Environment** ist gesourced (`FREESURFER_HOME` env-var, `$FREESURFER_HOME/SetUpFreeSurfer.sh`).
3. **License** valide.

`recon-surf.sh` prüft die FreeSurfer-Version. Mit `--ignore_fs_version` lässt sich der Check umgehen (für Dev-Builds).

## High-Level-Schritte

Vereinfachte Pipeline-Reihenfolge:

```
1.  Talairach-Registration         talairach-reg.sh + neuroreg
                                   → mri/transforms/talairach.lta
                                   → mri/transforms/talairach.xfm
                                   (eTIV-Estimate; --3T für 3T-Atlas)

2.  Generate FreeSurfer-Standard-Volumes
                                   → mri/T1.mgz (skipped mit --no_fs_T1)
                                   → mri/brainmask.mgz
                                   → mri/norm.mgz, mri/nu.mgz

3.  Aseg-Cleanup + CC-Integration  → aseg.auto.mgz, aseg.presurf.mgz
                                   (mit Corpus-Callosum-Labels integriert)

4.  WM-Surface erzeugen
                                   mri_mc (Default) oder mri_tesselate (--fstess)
                                   → surf/{lh,rh}.orig
                                   → surf/{lh,rh}.smoothwm
                                   → surf/{lh,rh}.inflated
                                   → surf/{lh,rh}.white (final)

5.  Spherical-Projection           Spectral (Default) oder Iterative (--fsqsphere)
                                   → surf/{lh,rh}.sphere

6.  Surface-Registration           recon-surfreg.sh (cross-subject)
                                   → surf/{lh,rh}.sphere.reg
                                   Skipped mit --no_surfreg

7.  Pial-Surface-Generation        → surf/{lh,rh}.pial

8.  Cortical-Parcellation Mapping  DL-Seg → Annotation
                                   → label/{lh,rh}.aparc.DKTatlas.mapped.annot
                                   Optional --fsaparc: zusätzlich klassische FS-aparc

9.  Per-Vertex-Overlays            → surf/{lh,rh}.area, .curv, .thickness, .volume

10. Stats-Computation              → stats/aseg.stats
                                   → stats/{lh,rh}.aparc.DKTatlas.mapped.stats
                                   → stats/wmparc.DKTatlas.mapped.stats
                                   → stats/{lh,rh}.curv.stats

11. Symlink-Setup                  aparc+aseg.mgz → aparc.DKTatlas+aseg.mapped.mgz
                                   wmparc.mgz → wmparc.DKTatlas.mapped.mgz
                                   {lh,rh}.aparc.DKTatlas.annot → *.mapped.annot
```

Logfile aller Steps: `scripts/recon-all.log`.

## Parallel-Hemisphären (`--threads >= 2`)

Wenn `--threads_surf >= 2` (oder `--threads >= 2`), werden L- und R-Hemisphäre **parallel** prozessiert (Schritte 4–10 für jede Seite). Speedup ist nahe 2× wenn Cores vorhanden.

## DL-Annot-Mapping (Default vs `--fsaparc`)

**Default:** Die DKT-Parcellation aus `aparc.DKTatlas+aseg.deep.mgz` wird auf die Surface gemappt (`{lh,rh}.aparc.DKTatlas.mapped.annot`). Schnell und konsistent mit Volume-Seg.

**`--fsaparc`:** Zusätzlich wird die klassische FreeSurfer-aparc-Methode gefahren (Spherical-Registration + Atlas-Mapping). Output: zusätzliche `{lh,rh}.aparc.annot` Files. Brauchst du nur für strikt-FreeSurfer-kompatible Pipelines.

## Talairach-Registration (`--tal_reg`, `--3T`)

- Default: Talairach läuft als Teil der Surface-Pipeline.
- `--tal_reg`: Talairach läuft **bereits in der Seg-Pipeline** (für eTIV im `--seg_only` Output).
- `--3T`: nutzt 3T-Atlas statt 1.5T-Atlas. Bei 3T-Daten gibt das deutlich bessere eTIV-Schätzungen.

Talairach wird via `neuroreg` berechnet (FastSurfer-Dependency).

## Surface-Algorithmen-Switches

| Flag | Wirkung | Default-Verhalten |
|------|---------|-------------------|
| `--fstess` | `mri_tesselate` (FreeSurfer klassisch) | `mri_mc` (Marching Cubes, schneller) |
| `--fsqsphere` | Iterative Inflation für qsphere (FreeSurfer klassisch) | Spectral-Spherical-Projection (schneller) |
| `--no_fs_T1` | Skip `mri/T1.mgz`-Generation (~1:30 Min Speedup) | T1.mgz wird erzeugt |
| `--no_surfreg` | Skip Surface-Registration (nicht empfohlen ausser nur Stats) | Reg läuft |
| `--fsaparc` | Zusätzlich klassische FS-aparc | nur DL-mapped |
| `--ignore_fs_version` | Skip FreeSurfer-Version-Check | Check ist an |

## Highres-Mode

Wenn die effective Voxelgrösse `< 1mm` ist (aus `--vox_size` oder auto-detected), schaltet die Surface-Pipeline automatisch in **Highres-Modus**. Andere Parameter für Surface-Smoothing, Inflation, etc. werden verwendet. Höherer Memory-Verbrauch.

## Edits (`--edits`)

Mit `--edits` werden:
- Existierende `recon-surf.sh`-Runs nicht erneut geprüft (kein Skip-by-Hash).
- Manuelle Edits berücksichtigt: `mri/wm.mgz.manedit.mgz`, `mri/brain.finalsurfs.mgz.manedit.mgz`.
- FreeSurfer-Style WM-Control-Points respektiert.

Manuelle Talairach-Registrations werden mit `--edits` nicht ersetzt.

## Surface-Files: Anatomy

Pro Hemisphäre (`{lh,rh}`):

| File | Was |
|------|------|
| `*.orig` | Initial Surface aus Marching Cubes / Tesselate |
| `*.smoothwm` | Geglättete WM-Surface |
| `*.white` | Finale WM-Surface (nach Korrekturen) |
| `*.pial` | Pial-Surface (GM-Oberfläche) |
| `*.inflated` | Inflated für 2D-Visualization |
| `*.sphere` | Spherical-Projection |
| `*.sphere.reg` | Cross-Subject-Reg auf fsaverage |
| `*.thickness` | Per-Vertex Pial↔White Thickness (mm) |
| `*.area`, `*.curv`, `*.volume` | Per-Vertex Overlays |

## Annot-Files (`label/`)

`*.annot` sind FreeSurfer-Annotation-Files. Jeder Vertex hat ein Label aus der DKT-Atlas-LUT (31 cortical regions × 2 hemispheres).

```python
import nibabel.freesurfer as nfs
labels, ctab, names = nfs.read_annot("label/lh.aparc.DKTatlas.mapped.annot")
# labels: array (n_vertices,) mit Region-IDs
# ctab: color-table
# names: list of region-names (bytes)
```

## Wenn Surface-Pipeline crasht

Häufigste Ursachen (mehr Details: Skill `fastsurfer-debug-license`):

1. **FreeSurfer-Lizenz fehlt/ungültig** → "ERROR: FreeSurfer license file not found"
2. **FreeSurfer-Environment nicht gesourced** → fehlende Binaries wie `mri_convert`
3. **Falscher FreeSurfer-Version** → `--ignore_fs_version` ggf. nötig
4. **Out-of-Memory** in Marching-Cubes oder Talairach → mehr RAM / weniger threads
5. **Manuelle Edits korrumpiert** → `--edits` rauslassen oder Manedits checken

Logfile inspizieren:

```bash
tail -100 $SUBJECTS_DIR/$SID/scripts/recon-all.log
grep -i "error\|fail" $SUBJECTS_DIR/$SID/scripts/recon-all.log
```

## Cross-Reference

- Welche Outputs landen wo: `fastsurfer-outputs`
- Lizenz-Probleme: `fastsurfer-debug-license`
- Surface-Output-Conformed-Space: `fastsurfer-conform-space`
- Wenn die Pipeline für viele Subjects laufen soll: `fastsurfer-batch-slurm`
