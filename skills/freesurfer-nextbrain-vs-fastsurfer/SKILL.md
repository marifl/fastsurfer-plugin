---
name: freesurfer-nextbrain-vs-fastsurfer
description: Use when the user has to choose between FastSurfer and NextBrain for a specific brain-segmentation use-case, asks about pros/cons, wants to combine both, or compare them on metrics like runtime, ROI-count, accuracy, or supported regions. Triggers on "FastSurfer vs NextBrain", "which segmentation tool", "more detailed than aseg", "Hippocampus subfields FastSurfer", "Brainstem nuclei segmentation", "combine FastSurfer NextBrain", "333 ROIs vs 95 classes".
---

# FastSurfer vs NextBrain — Decision-Guide

Beide produzieren Brain-Volumetric-Segmentations in FreeSurfer-Subject-Dir-Format (tkRAS). Aber sie haben sehr unterschiedliche Trade-Offs.

## Vergleichs-Tabelle

| Achse | FastSurfer (FastSurferVINN) | NextBrain (mri_histo_atlas_segment_fireants) |
|-------|------------------------------|-----------------------------------------------|
| **Anzahl ROIs** | ~95 (aseg + DKT-Atlas) | ~333 (Histology-derived) |
| **Methode** | 2.5D CNN/VINN, multi-view aggregation | Bayesian-Segmentation + FireANTs Atlas-Registration |
| **Training-Daten** | Hunderte manuell-segmentierte MRTs | 5 Hemispheres mit Serial-Histology |
| **Runtime (in-vivo, GPU)** | ~5 Min (asegdkt only) — ~10 Min (alle Module) | ~30 Min pro Hemisphere |
| **Runtime (CPU)** | ~15-30 Min asegdkt | ~1-2h pro Hemisphere |
| **Surfaces (pial, white, thickness)** | **Ja** via recon-surf | **Nein** — nur Volume-Seg |
| **Hippocampus-Subfields** | Nein (nur "Hippocampus" als Blob) | **Ja** (CA1, CA2/3, CA4, DG, subiculum) |
| **Brainstem-Subnuclei** | Nein (nur "Brain-Stem" als Blob) | **Ja** (mehrere Substrukturen) |
| **Hypothalamus** | HypVINN-Modul (4 Sub-Strukturen) | **Ja** (mehrere Subkerne) |
| **Cerebellum** | CerebNet (Lobuli + WM/GM) | **Ja** (Lobuli + Nuclei) |
| **Corpus Callosum** | Eigenes CC-Modul (Shape-Analysis) | Part der 333 ROIs (kein separater Shape-Output) |
| **Hardware-Memory** | 4-8 GB VRAM (GPU) | 8-12 GB VRAM (GPU) |
| **Stabilitaet** | Production-ready (v2.6.0-dev, lange in Use) | FreeSurfer-dev-Branch (eher recent) |
| **Lizenz** | Apache-2.0 + FreeSurfer fuer Surface | FreeSurfer (Non-Commercial) |
| **Surface-Compatibility** | Subject-Dir-Layout, ready fuer FreeSurfer downstream | Standalone-Output, kein Subject-Dir-Layout (separate Output-Dir) |
| **Ex-vivo Support** | Nein | **Ja** (`--mode exvivo|cerebrum|hemi`) |
| **Output-Modes** | beide Hemis automatisch | eine Hemi pro Aufruf (sequentiell ratsam) |

## Decision-Flow

```
Brauchst du Cortical Surfaces (Pial, White, Thickness)?
├── Ja → FastSurfer (kein Weg drum rum, NextBrain hat keine Surfaces)
└── Nein → weiter

Brauchst du Hippocampus-Subfields, Brainstem-Nuclei, Thalamus-Subkerne?
├── Ja → NextBrain (FastSurfer hat das nicht)
└── Nein → weiter

Reicht aparc+aseg (95 Klassen)?
├── Ja → FastSurfer (10× schneller, gut etabliert)
└── Nein → NextBrain

Ex-vivo-Brain-Scan?
├── Ja → NextBrain (FastSurfer ist auf in-vivo trainiert)
└── Nein → FastSurfer

Brauchst du Volumetrics von ueber 200 ROIs?
├── Ja → NextBrain
└── Nein → FastSurfer

Strenge Time-Budget pro Subject (z.B. <10 Min)?
├── Ja → FastSurfer
└── Nein → freie Wahl
```

## Kombi-Workflow (oft optimal)

Beide nutzen und ergaenzen:

```bash
# 1) FastSurfer fuer Surfaces + aseg+DKT (95 Klassen, plus Cortical Surfaces):
run_fastsurfer.sh \
  --t1 /data/sub01/t1.nii.gz \
  --sid sub01 \
  --sd /subjects \
  --fs_license /opt/license.txt \
  --3T --threads 4

# 2) NextBrain on-top fuer Sub-Region-Volumes (333 ROIs):
mri_histo_atlas_segment_fireants \
  --i /data/sub01/t1.nii.gz \
  --o /subjects/sub01/nextbrain/ \
  --device cuda --side left --mode invivo

mri_histo_atlas_segment_fireants \
  --i /data/sub01/t1.nii.gz \
  --o /subjects/sub01/nextbrain/ \
  --device cuda --side right --mode invivo
```

Ergebnis:
- `$SUBJECTS_DIR/sub01/mri/` — FastSurfer-aseg + aparc + Surfaces (downstream-ready)
- `$SUBJECTS_DIR/sub01/nextbrain/` — 333-ROI-Volumes pro Hemi (zusaetzliche Detail-Analyse)

Beide in tkRAS, beide in FreeView gleichzeitig overlay-bar.

## Wann NICHT NextBrain?

- **Du brauchst nur Standard-Aparc+Aseg-Volumes**: FastSurfer ist 10× schneller und unterscheidet sich nur marginal in den Standard-Regionen.
- **Du hast keine GPU**: NextBrain CPU-only ist 1-2h pro Subject pro Hemi — selten praktisch fuer Batch.
- **Du brauchst Cortical Surfaces**: NextBrain hat keine.
- **Production-Pipeline ohne extensive Validation**: NextBrain ist neu (Nature 2025), FastSurfer ist seit Jahren in use.

## Wann NICHT FastSurfer?

- **Du brauchst Hippocampus-Subfields**: FastSurfer kann das nicht. NextBrain ja, oder klassisches FreeSurfer `segmentHA_T1.sh`.
- **Du brauchst Brainstem-Subnuclei (PAG, LC, Raphe, etc.)**: FastSurfer's aseg hat "Brain-Stem" als ein Blob. NextBrain segmentiert detaillierter.
- **Du arbeitest mit Ex-vivo-Scans**: FastSurfer ist nicht darauf trainiert. NextBrain hat dedizierte Modes.
- **Du brauchst ueber 200 ROIs fuer Detail-Analyse**: NextBrain.

## Output-Vergleich am Beispiel

| Struktur | FastSurfer-aseg-Label | NextBrain-Coverage |
|----------|------------------------|---------------------|
| Hippocampus | 1 Label ("Left/Right-Hippocampus") | 5-7 Subfields (CA1, CA2/3, CA4, DG, subiculum, etc.) |
| Amygdala | 1 Label | Subkerne (basolateral, central, etc.) |
| Brain-Stem | 1 Label | Mehrere (Mesencephalon, Pons, Medulla + Subnuclei) |
| Thalamus | 2 Labels (L/R) | Subkerne (Pulvinar, MD, VA, VL, etc.) |
| Cerebellum-Cortex | 2 Labels (L/R) | Lobuli I-X + Vermis |
| Cerebellum-WM | 2 Labels (L/R) | Mit Nuclei (Dentate, Interpositus, Fastigial) |
| Hypothalamus | (via HypVINN: 4 Substrukturen) | Mehrere Subkerne |

## Stats-Vergleich

| Tool | Stats-Format | Vergleich-Tool |
|------|--------------|----------------|
| FastSurfer | `stats/aseg.stats` (FreeSurfer-Format) | `asegstats2table`, `/fs-stats` |
| NextBrain | `vols.[side].csv` (Standard-CSV) | Direkt mit pandas |

Beide direkt importierbar in Python/R fuer Group-Level-Analysen.

## Lizenz-Implikationen

| Tool | Lizenz | Commercial Use |
|------|--------|----------------|
| FastSurfer | Apache-2.0 (Code) | Erlaubt |
| FastSurfer Surface-Pipeline | benötigt FreeSurfer-License | nur Non-Commercial standard |
| NextBrain | FreeSurfer-Lizenz | nur Non-Commercial standard |

Fuer kommerzielle Nutzung: in beiden Faellen ggf. mit MGH/FreeSurfer-Team kontaktieren.

## Cross-Reference

- NextBrain CLI-Flags: Skill `freesurfer-nextbrain-cli`
- NextBrain Setup + Output: Skill `freesurfer-nextbrain-overview`
- FastSurfer Module: Skill `fastsurfer-segmentation`
- FastSurfer Pipeline: Skill `fastsurfer-overview`
- Slash-Commands: `/fs-run` (FastSurfer), `/fs-nextbrain` (NextBrain)
