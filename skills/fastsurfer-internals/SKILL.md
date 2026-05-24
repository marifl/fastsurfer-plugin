---
name: fastsurfer-internals
description: Use when the user wants to understand FastSurfer's code layout, where specific functionality lives in the repository, which file implements a given module, or wants to modify/fork/extend FastSurfer internals. Triggers on "FastSurfer source", "FastSurferCNN module", "run_prediction.py", "CerebNet code", "HypVINN code", "recon-surf.sh", "where is X implemented", or general code-spelunking questions about the FastSurfer repo.
---

# FastSurfer — Repository-Layout & Code-Internals

Default-Annahme: FastSurfer lebt unter `$FASTSURFER_HOME` (z.B. `/Users/marcusifland/prj/fastsurfer`). Alle Pfade in diesem Skill sind **relativ** zum FastSurfer-Repo-Root.

## Top-Level

```
fastsurfer/
├── run_fastsurfer.sh           Haupt-Entry-Point (Bash-Orchestrator)
├── brun_fastsurfer.sh          Batch-Wrapper (mehrere Subjects, parallel)
├── long_fastsurfer.sh          Longitudinal-Wrapper (Template + Time-Points)
├── srun_fastsurfer.sh          SLURM-Cluster-Wrapper
├── stools.sh                   Shared Bash-Funktionen (von brun/srun benutzt)
│
├── FastSurferCNN/              asegdkt-Modul + ML-Infrastructure (Python)
├── CerebNet/                   Cerebellum-Modul (Python, Modell + Inference)
├── HypVINN/                    Hypothalamus-Modul (Python)
├── CorpusCallosum/             CC-Modul (Python, Segmentation + Shape)
├── recon_surf/                 Surface-Pipeline (Bash + Python Helpers)
│
├── doc/                        Vollständige Sphinx-Doku
├── Documentation/              Legacy-/Zusatz-Docs
├── Tutorial/                   Jupyter-Tutorials (Colab-fähig)
├── env/                        Conda-/uv-Environments
├── tools/                      Build, Docker, Hooks, MacOS-Build-Tools
├── test/                       Quicktest-Suite + Image-Tests
├── pyproject.toml              Python-Package-Definition
├── requirements.txt            Pip-Requirements
└── stools.sh                   shared Bash-Helpers
```

## `FastSurferCNN/` — asegdkt + ML-Foundation

Zentrale Module:

| File | Funktion |
|------|----------|
| `run_prediction.py` | Inference-Entry-Point für asegdkt; wird von `run_fastsurfer.sh` aufgerufen |
| `inference.py` | Inference-Core (Sliding-Window, View-Aggregation) |
| `run_model.py` | Training-Entry-Point |
| `train.py` | Training-Loop |
| `generate_hdf5.py` | Konvertiert Trainings-Daten in HDF5 |
| `download_checkpoints.py` | Lädt Model-Checkpoints |
| `quick_qc.py` | QC-Check für asegdkt-Outputs |
| `reduce_to_aseg.py` | Erzeugt vereinfachte aseg ohne CC-Labels |
| `mri_segstats.py` | Stats-Computation (FastSurfer-Replacement für FreeSurfer's mri_segstats) |
| `mri_brainvol_stats.py` | Whole-Brain-Volume-Stats |
| `segstats.py` | Stats-Helpers |
| `version.py` | Version-Reporting |

Subdirs:

| Dir | Inhalt |
|-----|--------|
| `models/` | Network-Architecturen (FastSurferVINN, FastSurferCNN-Klassisch) |
| `data_loader/` | Custom Dataloader + Augmentations |
| `utils/` | Shared utilities (logging, parser, etc.) |
| `config/` | YAML-Config-Files für Models |

## `CerebNet/` — Cerebellum-Subsegmentation

```
CerebNet/
├── run_prediction.py           Inference-Entry-Point
├── models/                     CerebNet-Network
├── data_loader/                Loader (1mm-resampling)
├── utils/                      Helpers
└── config/                     YAML-Configs
```

Wichtige Eigenschaft: CerebNet resampled IMMER auf 1mm isotropic, egal was das Input-Image hat. Output ist daher auch immer 1mm.

## `HypVINN/` — Hypothalamus-Sub-Segmentation

```
HypVINN/
├── run_prediction.py           Inference-Entry-Point (optional T2-Input)
├── models/                     HypVINN-Network (Multi-View VINN)
├── data_loader/                Loader inkl. T1+T2-Handling
├── utils/                      T1/T2-Registration, Biasfield-Wrapper
└── config/                     YAML-Configs
```

T1+T2-Registration läuft via `mri_coreg` (FreeSurfer) oder `mri_robust_register` je nach `--reg_mode`.

## `CorpusCallosum/` — FastSurfer-CC

```
CorpusCallosum/
├── fastsurfer_cc.py            Entry-Point (kann auch standalone laufen)
├── segmentation/               CC-Segmentation-Network + Inference
├── shape/                      Shape-Analyse, Thickness-Profile
├── registration/               AC/PC-Standardisierung (upright-Space)
├── transforms/                 Transform-Helpers (.lta-Writing)
├── localization/               Mid-Sagittal-Slice-Detection
├── data/                       Mitgelieferte Reference-Daten
├── utils/                      Helpers
└── config/                     YAML-Configs
```

Standalone-Run möglich, z.B. mit `--upright_volume` für Zusatz-Output `mri/upright_volume.mgz`.

## `recon_surf/` — Surface-Pipeline

```
recon_surf/
├── recon-surf.sh               Haupt-Surface-Pipeline (Bash, orchestriert FreeSurfer-Binaries)
├── recon-surfreg.sh            Surface-Registration (cross-subject correspondence)
├── talairach-reg.sh            Talairach-Registration
├── long_prepare_template.sh    Vorbereitung des Longitudinal-Templates
├── functions.sh                Shared Bash-Funktionen
├── *.py                        Diverse Helper-Scripts (Surface-Mapping, Annot-Generation)
```

Surface-Pipeline benötigt sourced FreeSurfer-Environment. `recon-surf.sh` prüft FreeSurfer-Version (Skip mit `--ignore_fs_version`).

## `tools/`

| Subdir | Inhalt |
|--------|--------|
| `tools/Docker/` | Dockerfiles (CPU, GPU, CC, Latest) |
| `tools/git-hooks/` | Pre-Commit + Pre-Push Hooks (für Entwickler) |
| `tools/build/` | Wheel-Build-Scripts |
| `tools/macos_build/` | macOS-Package-Build (`pkg`) |

## `test/`

| Subdir | Inhalt |
|--------|--------|
| `test/quicktest/` | Schnelle Sanity-Tests (Pytest) |
| `test/image/` | Image-basierte Tests (FastSurfer-Smoke) |

## `env/`

Mehrere Environment-Definitionen:
- `environment.yml` — Conda
- `requirements.txt` — pip (im Root)

Python 3.10–3.13 unterstützt. Wichtigste Dependencies (aus `pyproject.toml`):

- `torch>=2.x` (PyTorch)
- `nibabel>=5.4.0`
- `numpy>=1.25`
- `monai>=1.4.0` (für CC)
- `lapy>=1.5.0` (Surface-Math)
- `meshpy>=2025.1.1` (CC)
- `neuroreg>=0.6.1` (Talairach-Registration / eTIV)
- `scikit-image>=0.19.3`, `scipy`, `h5py`, `matplotlib`, `pandas`, `pyrr`, `requests`, `pyyaml`

## Datenfluss (vereinfacht)

```
T1.nii.gz (input)
    │
    ▼ run_fastsurfer.sh
    │  (conforming, biasfield)
    ▼
FastSurferCNN/run_prediction.py
    │  (asegdkt)
    ▼
mri/aparc.DKTatlas+aseg.deep.mgz  +  mri/orig.mgz  +  mri/orig_nu.mgz  +  mri/mask.mgz
    │
    ├──▶ CorpusCallosum/fastsurfer_cc.py
    │      ▼
    │      mri/callosum.CC.*.mgz + stats/callosum.CC.*.json + surf/callosum.{surf,vtk}
    │
    ├──▶ CerebNet/run_prediction.py
    │      ▼
    │      mri/cerebellum.CerebNet.nii.gz + stats/cerebellum.CerebNet.stats
    │
    ├──▶ HypVINN/run_prediction.py (optional T2-input)
    │      ▼
    │      mri/hypothalamus.HypVINN.nii.gz + stats/hypothalamus.HypVINN.stats
    │
    └──▶ recon_surf/recon-surf.sh    (only if NOT --seg_only)
           │  (FreeSurfer-Binaries für Surface-Reconstruction)
           ▼
           surf/{lh,rh}.{pial,white,inflated,thickness,...}
           label/{lh,rh}.aparc.DKTatlas.mapped.annot
           stats/aseg.stats, stats/{lh,rh}.aparc.DKTatlas.mapped.stats
           PLUS Überschreiben einiger mri/-Files (PV-corrected)
```

## "Wo ist X?"

| Frage | Pfad |
|-------|------|
| Wo wird die Voxel-Konformierung gemacht? | `FastSurferCNN/data_loader/conform.py` (oder `utils/`) |
| Wo wird das Biasfield gerechnet? | Innerhalb `run_prediction.py` + `utils/`; Output via `--norm_name` |
| Wo werden Stats gerechnet? | `FastSurferCNN/mri_segstats.py` + `FastSurferCNN/segstats.py` |
| Wo Stats nach Surface-Run kommen? | `recon_surf/` Bash + FreeSurfer-Binaries |
| Wo wird das Talairach-Transform berechnet? | `recon_surf/talairach-reg.sh` (oder `--tal_reg` im Seg-Stream) |
| Wo download_checkpoints lebt? | `FastSurferCNN/download_checkpoints.py` |
| Wo Modelle definiert sind? | `FastSurferCNN/models/`, `CerebNet/models/`, `HypVINN/models/`, `CorpusCallosum/segmentation/` |
| Wo Tests sind? | `test/quicktest/`, `test/image/` |
| Wo Docker-Images definiert sind? | `tools/Docker/` |

## Versions-Identifikation

```bash
# Aktuelle Version + Git-Status + Checkpoints + Pip-Pakete
bash $FASTSURFER_HOME/run_fastsurfer.sh --version +git+checkpoints+pip
```

Plus direkt aus Python:

```python
from FastSurferCNN.version import __version__
```

## Cross-Reference

- Was die einzelnen Module funktional tun: `fastsurfer-segmentation`, `fastsurfer-surface-recon`
- Wie die CLI orchestriert: `fastsurfer-cli-flags`
- Wie Checkpoints geladen werden: `fastsurfer-checkpoints-models`
