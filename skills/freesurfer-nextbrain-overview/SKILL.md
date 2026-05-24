---
name: freesurfer-nextbrain-overview
description: Use when the user asks about NextBrain, the histological atlas-based brain segmentation tool from FreeSurfer (mri_histo_atlas_segment_fireants), what it does, how it differs from FastSurfer, what the 333 ROIs cover, when to use it instead of FastSurferVINN, or general questions about Casamitjana et al. Nature 2025 paper. Triggers on "NextBrain", "mri_histo_atlas_segment_fireants", "HistoAtlasSegmentation", "histological atlas brain", "333 ROIs FreeSurfer", "Casamitjana Nature 2025", "BUNGEE-TOOLS", "Iglesias atlas", "Puonti fast segmentation", "FireANTs registration".
---

# NextBrain — Histological-Atlas-basierte Hirnsegmentierung (FreeSurfer dev)

**Achtung Scope:** NextBrain ist Teil von **FreeSurfer-dev**, nicht von FastSurfer. Dieser Plugin deckt es ab weil es typischerweise im selben Workflow wie FastSurfer genutzt wird (gleicher Subject-Dir-Output, gleiches tkRAS-Frame, ergaenzende Segmentation).

## Was ist NextBrain?

NextBrain ist ein **probabilistischer histologischer Atlas** des menschlichen Hirns, gebaut aus 5 ex-vivo-Hemispharen mit serienweiser Histologie. Daraus entstand ein DL-basiertes Segmentations-Tool das **333 ROIs** in T1w-MRT-Scans annotiert — deutlich feiner als die ~95 Klassen von FastSurfer/FreeSurfer-aparc+aseg.

**Paper:**
- **Atlas-Construction:** Casamitjana et al. *A probabilistic histological atlas of the human brain for MRI segmentation.* Nature 2025. https://www.nature.com/articles/s41586-025-09708-2
- **Fast-Inference-Methode:** Puonti et al. *Fast segmentation with the NextBrain histological atlas.* Imaging Neuroscience 2026 (accepted). https://www.biorxiv.org/content/10.1101/2025.09.22.673638v1
- **Foundation-Modell (BrainFM):** Liu et al. *A Modality-agnostic Multi-task Foundation Model for Human Brain Imaging.* (under revision)
- **Registration-Backend (FireANTs):** Jena et al. *FireANTs: Adaptive Riemannian Optimization for Multi-Scale Diffeomorphic Registration.* (under revision)

## Was deckt NextBrain ab?

Die **333 ROIs** sind Histology-derived und decken Strukturen ab, die in klassischen Atlanten (Desikan, Destrieux, DKT) fehlen oder zu grob sind:

| Bereich | NextBrain-Coverage |
|---------|---------------------|
| **Cortex** | feinere Parcellation als DKT (~Brodmann-aehnlich aber histologisch verifiziert) |
| **Subcortex** | inkl. Thalamus-Subkerne, Striatum-Subdivisionen, Globus-Pallidus-Segmente |
| **Hippocampus** | Subfelder (CA1, CA2/3, CA4, DG, subiculum, etc.) — vergleichbar zu FreeSurfer-Hippocampal-Subfields |
| **Amygdala** | Subkerne (basolateral, central, etc.) |
| **Brainstem** | Mehrere Substrukturen (Mesencephalon, Pons, Medulla, + Subnuclei wie SN, RN, PAG, LC, Raphe — abhaengig vom finalen Label-Set) |
| **Cerebellum** | Lobuli + Nuclei (Dentate, Interpositus, Fastigial) |
| **Hypothalamus** | Mehrere Subkerne |
| **Diencephalon** | LGN, MGN, etc. |
| **Brainstem-Cranial-Nerve-Origins** | grosse Hirnnerven-Kerne (zu pruefen via finaler LUT) |

**Wichtig:** Die genaue 333-Label-Liste haengt von der finalen `lut.txt` ab, die NextBrain beim ersten Run runterlaedt. Vor Pipeline-Integration: LUT downloaden und gegen die eigene Bedarfsliste abgleichen.

## Wann NextBrain vs FastSurfer?

| Use-Case | Empfehlung |
|----------|-----------|
| Standard volumetric Brain-Analysis (95 Klassen reicht) | **FastSurfer** (`/fs-quick`, `/fs-run`) — viel schneller |
| Detaillierte Sub-Region-Analyse (333 ROIs noetig) | **NextBrain** |
| Hippocampus-Subfields | FastSurfer hat das nicht standardmaessig → **NextBrain** (oder FreeSurfer-`segmentHA_T1.sh`) |
| Brainstem-Nuclei (PAG, LC, Raphe, etc.) | **NextBrain** (FastSurfer aseg hat nur "Brain-Stem" als ein Blob) |
| Cortical Surfaces (Pial, White, Thickness) | **FastSurfer** (NextBrain ist nur Volume-Seg) |
| Schnelle Inferenz (~5 Min) | **FastSurfer** |
| Wenig Compute, bereit zu warten (~30 Min - 2h) | **NextBrain** akzeptabel |
| Ex-vivo Brain Scans | **NextBrain** (`--mode exvivo|cerebrum|hemi`) — FastSurfer nicht trainiert dafuer |

**Kombinations-Strategie (oft sinnvoll):**
- FastSurfer fuer Surfaces + Standard-Volumes (`/fs-run`)
- NextBrain on-top fuer die feinen Sub-Strukturen die FastSurfer nicht hat

Beide Outputs landen im FreeSurfer-Subject-Dir-Format (tkRAS-Frame) und sind kompatibel — Overlay in FreeView oder downstream-Pipeline ist trivial.

## Setup & Dependencies

- **FreeSurfer DEV-Version** (nicht Stable!) — NextBrain lebt aktuell nur im `dev`-Branch.
- **Erster Run** triggert Downloads:
  - NextBrain-Atlas-Files (~mehrere GB)
  - `mri_super_synth`-Model-File (BrainFM Foundation-Model)
  - Beides interaktiv via Prompt.
- **Hardware:**
  - **GPU optional** aber empfohlen (CUDA): ~30 Min Runtime.
  - **CPU-only:** funktioniert, aber 2h+ fuer ex-vivo-0.25mm.
  - **Memory-constrained:** `--skip 2` setzen (halbiert internen Speicher, leichter Genauigkeitsverlust).

## Output

NextBrain schreibt in das Output-Verzeichnis:

- `seg.[left|right].nii.gz` — die finale Segmentation (333 ROIs) pro Hemisphere
- `lut.txt` — Lookup-Table fuer FreeView-Visualisierung (Label-ID → Region-Name + RGB)
- `vols.[left|right].csv` — Per-Region Volumetric-Stats als CSV
- `SuperSynth/` — Whole-Structure-Level-Seg vom Foundation-Modell (Pre-Stage-Output)
- Optional je nach Flags: `bias_corrected.nii.gz`, `rgb_posterior.nii.gz`, `field.nii.gz`, `jacobian.nii.gz`, `atlas_warped.nii.gz`

Frame: tkRAS (gleich wie FastSurfer) — siehe Skill `fastsurfer-coordinates-3d`.

## Sequential Processing fuer beide Hemispharen

`mri_histo_atlas_segment_fireants` verarbeitet **eine Hemisphere pro Aufruf**. Fuer beide:

```bash
mri_histo_atlas_segment_fireants --i T1.nii.gz --o out/ --side left  ...
mri_histo_atlas_segment_fireants --i T1.nii.gz --o out/ --side right ...
```

Empfehlung: **sequentiell** statt parallel — der SuperSynth-Pre-Processing-Output wird wiederverwendet, das spart Zeit beim zweiten Hemi.

## Lizenz-Status

NextBrain selbst (Atlas + Code) ist Teil von FreeSurfer und faellt unter dessen Lizenz (non-commercial). Bei kommerzieller Nutzung: Kontakt mit den Autoren bzw. FreeSurfer-Lizenzteam (https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSoftwareLicense).

## Datenquellen (Reference)

- **NextBrain Project Homepage:** https://github-pages.ucl.ac.uk/NextBrain
- **FreeSurfer-Wiki:** https://surfer.nmr.mgh.harvard.edu/fswiki/HistoAtlasSegmentation
- **Source-Code:** https://github.com/freesurfer/freesurfer/tree/dev/mri_histo_util
- **Raw Data (5 Hemispheres, MRI+Histology+Manual-Annotations):** UCL Data-Repository (siehe NextBrain-Homepage)
- **200um ex-vivo Reference-Scan (Edlow et al., 2019):** ebenfalls auf UCL-Repo verlinkt — nuetzlich als Reference fuer ex-vivo-Pipelines

## Cross-Reference

- CLI-Flags im Detail: Skill `freesurfer-nextbrain-cli`
- Decision-Guide FastSurfer vs NextBrain: Skill `freesurfer-nextbrain-vs-fastsurfer`
- Output-Frame (tkRAS): Skill `fastsurfer-conform-space`, `fastsurfer-coordinates-3d`
- Slash-Command zum Starten: `/fs-nextbrain`
