# Wissenschaftliche Referenzen

Vollständige bibliographische Quellen aller im **fastsurfer-plugin** referenzierten Tools und Methoden. BibTeX-Eintraege siehe [`CITATIONS.bib`](CITATIONS.bib).

> **Zitations-Hinweis:** Wer FastSurfer oder NextBrain in wissenschaftlichen Arbeiten nutzt, zitiert bitte **die jeweils relevanten Primaer-Quellen unten**, nicht dieses Plugin. Das Plugin ist eine Tooling-Hilfe, keine wissenschaftliche Beitrag.

---

## Inhaltsverzeichnis

- [FastSurfer (Hauptpipeline)](#fastsurfer-hauptpipeline)
  - [FastSurfer-Kernpipeline](#fastsurfer-kernpipeline)
  - [FastSurferVINN (asegdkt-Modul)](#fastsurfervinn-asegdkt-modul)
  - [CerebNet (cereb-Modul)](#cerebnet-cereb-modul)
  - [HypVINN (hypothal-Modul)](#hypvinn-hypothal-modul)
  - [FastSurfer-CC (cc-Modul)](#fastsurfer-cc-cc-modul)
  - [Longitudinal Processing](#longitudinal-processing)
- [NextBrain (FreeSurfer-dev Histo-Atlas-Segmentation)](#nextbrain-freesurfer-dev-histo-atlas-segmentation)
  - [NextBrain-Atlas](#nextbrain-atlas)
  - [Fast-Inference-Methode](#fast-inference-methode)
  - [BrainFM (Foundation-Modell)](#brainfm-foundation-modell)
  - [FireANTs (Registration-Backend)](#fireants-registration-backend)
- [FreeSurfer (Foundation)](#freesurfer-foundation)
  - [FreeSurfer-Hauptzitation](#freesurfer-hauptzitation)
  - [Cortical-Surface-Reconstruction](#cortical-surface-reconstruction)
  - [DKT-Atlas](#dkt-atlas)
- [Reference-Datensätze](#reference-datens%C3%A4tze)
- [Software-Repositories](#software-repositories)
- [Wie zitieren?](#wie-zitieren)

---

## FastSurfer (Hauptpipeline)

### FastSurfer-Kernpipeline

> **Henschel L., Conjeti S., Estrada S., Diers K., Fischl B., Reuter M.** *FastSurfer — A fast and accurate deep learning based neuroimaging pipeline.* **NeuroImage** 219 (2020), 117012.
> DOI: [10.1016/j.neuroimage.2020.117012](https://doi.org/10.1016/j.neuroimage.2020.117012)

Primaerpublikation zu FastSurfer als Drop-In-Alternative für FreeSurfer-recon-all. Beschreibt die 2.5D-CNN-Architektur, die View-Aggregation und die Surface-Pipeline.

### FastSurferVINN (asegdkt-Modul)

> **Henschel L.\*, Kuegler D.\*, Reuter M.** *FastSurferVINN: Building Resolution-Independence into Deep Learning Segmentation Methods — A Solution for HighRes Brain MRI.* **NeuroImage** 251 (2022), 118933. *(\* joint first authors)*
> DOI: [10.1016/j.neuroimage.2022.118933](https://doi.org/10.1016/j.neuroimage.2022.118933)

Beschreibt die Voxel-Size-Invariant Network (VINN) Architektur, die auflösungs-unabhängige Inferenz (1mm bis sub-mm) erlaubt. Aktive Architektur des `asegdkt`-Moduls.

### CerebNet (cereb-Modul)

> **Faber J.\*, Kuegler D.\*, Bahrami E.\*, Heinz L.-S., Timmann D., Ernst T.M., Deike-Hofmann K., Klockgether T., van de Warrenburg B., van Gaalen J., Reetz K., Estrada S., Reuter M.** *CerebNet: A fast and reliable deep-learning pipeline for detailed cerebellum sub-segmentation.* **NeuroImage** 264 (2022), 119703. *(\* joint first authors)*
> DOI: [10.1016/j.neuroimage.2022.119703](https://doi.org/10.1016/j.neuroimage.2022.119703)

Detaillierte Cerebellum-Subsegmentierung (Lobuli I–X, Vermis, Cerebellum-WM/GM links/rechts). Output immer 1mm isotropic.

### HypVINN (hypothal-Modul)

> **Estrada S., Kuegler D., Bahrami E., Xu P., Mousa D., Breteler M.M.B., Aziz N.A., Reuter M.** *FastSurfer-HypVINN: Automated sub-segmentation of the hypothalamus and adjacent structures on high-resolutional brain MRI.* **Imaging Neuroscience** 1 (2023), 1–32.
> DOI: [10.1162/imag_a_00034](https://doi.org/10.1162/imag_a_00034)

VINN-basiertes Multi-View-Modell für Hypothalamus, 3. Ventrikel, Corpora mamillaria, Fornix und Tractus opticus. Optionaler T2-Multi-Modal-Input.

### FastSurfer-CC (cc-Modul)

> **Pollak C., Diers K., Estrada S., Kuegler D., Reuter M.** *FastSurfer-CC: A robust, accurate, and comprehensive framework for corpus callosum morphometry.* **arXiv** preprint arXiv:2511.16471, 2025.
> DOI: [10.48550/arXiv.2511.16471](https://doi.org/10.48550/arXiv.2511.16471)

Corpus-Callosum-Segmentation in upright-Space (AC/PC-aligned), Thickness-Profile, 3D-Mesh-Output. Preprint-Status — finale Journal-Publikation wird hier nachgereicht.

### Longitudinal Processing

> **Reuter M., Schmansky N.J., Rosas H.D., Fischl B.** *Within-subject template estimation for unbiased longitudinal image analysis.* **NeuroImage** 61:4 (2012), 1402–1418.
> DOI: [10.1016/j.neuroimage.2012.02.084](https://doi.org/10.1016/j.neuroimage.2012.02.084)

Methodische Grundlage für `long_fastsurfer.sh`. Within-Subject-Template-Estimation reduziert Bias bei seriellen Volumen-/Surface-Analysen.

---

## NextBrain (FreeSurfer-dev Histo-Atlas-Segmentation)

### NextBrain-Atlas

> **Casamitjana A., Mancini M., Robinson E., Peter L., Annunziata R., Althonayan J., Crampsie S., Blackburn E., Billot B., Atzeni A., Puonti O., Hughes J., Schmidt P., Hutter J., Price A.N., Chouliaras L., Mortimer J., Fiford C., Sudre C., DeVita E., Thomas D.L., Modat M., Cardoso M.J., Holmes S., Wagstyl K., Fox N.C., Schott J.M., Battistella G., Lawrence A.J., Markus H.S., Annese J., Augustinack J., Yendiki A., Edlow B.L., Iglesias J.E.** *A probabilistic histological atlas of the human brain for MRI segmentation.* **Nature**, 2025.
> DOI: [10.1038/s41586-025-09708-2](https://www.nature.com/articles/s41586-025-09708-2)

333-ROI probabilistischer Atlas, gebaut aus 5 ex-vivo Hemispharen mit Serial-Histology. Grundlage für `mri_histo_atlas_segment_fireants`.

> **Hinweis zur Author-Reihenfolge:** Die Liste oben spiegelt unsere beste Rekonstruktion zum Plugin-Build-Zeitpunkt. Vor Verwendung in Submissions bitte gegen die finale Nature-Publikation verifizieren.

### Fast-Inference-Methode

> **Puonti O., Casamitjana A., Iglesias J.E.** *Fast segmentation with the NextBrain histological atlas.* **Imaging Neuroscience**, 2026 (accepted).
> Preprint: [bioRxiv 2025.09.22.673638](https://www.biorxiv.org/content/10.1101/2025.09.22.673638v1)

Beschreibt die approximative Bayesian-Inferenz, die NextBrain-Inferenz in ~30 Min (GPU) statt mehrerer Stunden möglich macht.

### BrainFM (Foundation-Modell)

> **Liu P., et al.** *A Modality-agnostic Multi-task Foundation Model for Human Brain Imaging.* Manuscript under revision, 2025.

Wird intern als `mri_super_synth` für die SuperSynth-Pre-Stage in NextBrain verwendet. Noch keine DOI verfügbar.

### FireANTs (Registration-Backend)

> **Jena R., et al.** *FireANTs: Adaptive Riemannian Optimization for Multi-Scale Diffeomorphic Registration.* Manuscript under revision, 2025.

Effizienter Registration-Algorithmus (University of Pennsylvania), genutzt für die nonlinear Atlas-Registration in NextBrain. Noch keine DOI verfügbar.

---

## FreeSurfer (Foundation)

FreeSurfer ist die Foundation für die FastSurfer-Surface-Pipeline (FreeSurfer-Binaries werden intern aufgerufen) sowie für NextBrain (NextBrain lebt im `dev`-Branch des FreeSurfer-Repos).

### FreeSurfer-Hauptzitation

> **Fischl B.** *FreeSurfer.* **NeuroImage** 62:2 (2012), 774–781.
> DOI: [10.1016/j.neuroimage.2012.01.021](https://doi.org/10.1016/j.neuroimage.2012.01.021)

Canonical-Zitation für FreeSurfer als Plattform.

### Cortical-Surface-Reconstruction

> **Dale A.M., Fischl B., Sereno M.I.** *Cortical surface-based analysis: I. Segmentation and surface reconstruction.* **NeuroImage** 9:2 (1999), 179–194.
> DOI: [10.1006/nimg.1998.0395](https://doi.org/10.1006/nimg.1998.0395)

> **Fischl B., Sereno M.I., Dale A.M.** *Cortical surface-based analysis: II. Inflation, flattening, and a surface-based coordinate system.* **NeuroImage** 9:2 (1999), 195–207.
> DOI: [10.1006/nimg.1998.0396](https://doi.org/10.1006/nimg.1998.0396)

Methodische Grundlage für die `recon-surf.sh`-Pipeline (Pial, White, Inflated, Spherical-Projection).

### DKT-Atlas

> **Desikan R.S., Ségonne F., Fischl B., Quinn B.T., Dickerson B.C., Blacker D., Buckner R.L., Dale A.M., Maguire R.P., Hyman B.T., Albert M.S., Killiany R.J.** *An automated labeling system for subdividing the human cerebral cortex on MRI scans into gyral based regions of interest.* **NeuroImage** 31:3 (2006), 968–980.
> DOI: [10.1016/j.neuroimage.2006.01.021](https://doi.org/10.1016/j.neuroimage.2006.01.021)

Desikan-Killiany Atlas — Grundlage für die DKT-Parcellation in FastSurfer.

> **Klein A., Tourville J.** *101 labeled brain images and a consistent human cortical labeling protocol.* **Frontiers in Neuroscience** 6 (2012), 171.
> DOI: [10.3389/fnins.2012.00171](https://doi.org/10.3389/fnins.2012.00171)

DKT-Labeling-Protokoll, das die finale Klasse-Liste in FastSurfer's `aparc.DKTatlas+aseg.deep.mgz` definiert.

---

## Reference-Datensätze

### BUNGEE-TOOLS (NextBrain-Raw-Daten)

> **Iglesias Gonzalez J.E., Casamitjana A., Atzeni A., Billot B., Thomas D., Blackburn E., Hughes J., Althonayan J., Peter L., Mancini M., Robinson N., Schmidt P., Crampsie S.** *Registered histology, MRI, and manual annotations of over 300 brain regions in 5 human hemispheres.* ERC Starting Grant 677697 (BUNGEE-TOOLS), 2024.
> Data-Repository: https://github-pages.ucl.ac.uk/NextBrain

Raw-Daten hinter dem NextBrain-Atlas: MRT-Scans + serielle Histology-Schnitte + manuelle ROI-Annotations für 5 menschliche Hemispharen.

### 100µm Ex-Vivo Reference-Scan

> **Edlow B.L., Mareyam A., Horn A., Polimeni J.R., Witzel T., Tisdall M.D., Augustinack J.C., Stockmann J.P., Diamond B.R., Stevens A., Tirrell L.S., Folkerth R.D., Wald L.L., Fischl B., van der Kouwe A.** *7 Tesla MRI of the ex vivo human brain at 100 micron resolution.* **Scientific Data** 6 (2019), 244.
> DOI: [10.1038/s41597-019-0254-8](https://doi.org/10.1038/s41597-019-0254-8)

200µm-isotrope Labeling des rechten Hemispheres dieses Ex-vivo-Scans wird im NextBrain-Workflow als Reference-Dataset bereitgestellt (Original-Scan, Manual-Segmentation, FreeView-LUT).

---

## Software-Repositories

| Software | Repository | Lizenz |
|----------|------------|--------|
| **FastSurfer** | https://github.com/Deep-MI/FastSurfer | Apache-2.0 |
| **FreeSurfer** | https://github.com/freesurfer/freesurfer | Non-Commercial ([License](https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSoftwareLicense)) |
| **NextBrain** (in FreeSurfer-dev) | https://github.com/freesurfer/freesurfer/tree/dev/mri_histo_util | Non-Commercial |
| **NextBrain Project Homepage** | https://github-pages.ucl.ac.uk/NextBrain | — |
| **fastsurfer-plugin** (this) | https://github.com/marifl/fastsurfer-plugin | Apache-2.0 |

---

## Wie zitieren?

### Wenn du FastSurfer in einer Publikation nutzt

Mindestens zitieren:

1. Henschel et al., **NeuroImage** 2020 (FastSurfer-Hauptpaper) — *immer*
2. Henschel, Kuegler, Reuter, **NeuroImage** 2022 (VINN-Architektur) — *immer*
3. **Plus modul-spezifisch:**
   - CerebNet: Faber, Kuegler, Bahrami et al., **NeuroImage** 2022
   - HypVINN: Estrada et al., **Imaging Neuroscience** 2023
   - CC: Pollak et al., arXiv 2025 (oder finale Journal-Publikation)
   - Longitudinal: Reuter et al., **NeuroImage** 2012
4. **Falls Surface-Pipeline genutzt:** Fischl, **NeuroImage** 2012 (FreeSurfer) + Dale et al. 1999 + Fischl et al. 1999

### Wenn du NextBrain in einer Publikation nutzt

Mindestens zitieren:

1. Casamitjana et al., **Nature** 2025 — *Atlas*
2. Puonti et al., **Imaging Neuroscience** 2026 — *Fast-Inference-Methode (`mri_histo_atlas_segment_fireants`)*
3. **Plus optional** (wenn relevant): Liu et al. (BrainFM), Jena et al. (FireANTs) — sobald public

### Plugin selbst zitieren?

Nicht notwendig. Wenn du es trotzdem im Methods-Teil als Tooling erwähnen willst (z.B. *"Pipeline-Setup via fastsurfer-plugin v0.4.0"*), reicht ein Link auf https://github.com/marifl/fastsurfer-plugin.

### BibTeX

Alle obigen Quellen als BibTeX in [`CITATIONS.bib`](CITATIONS.bib).
