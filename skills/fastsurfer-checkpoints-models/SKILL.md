---
name: fastsurfer-checkpoints-models
description: Use when the user asks about FastSurfer model checkpoints, checkpoint download, where weights are stored, checkpoint integrity, or how to use download_checkpoints.py / generate_hdf5.py / run_model.py for custom training or inference. Triggers on "checkpoint", "model weights", "download_checkpoints", "fastsurfer weights", "generate_hdf5", "run_model.py", "train FastSurfer", "custom training", "ONNX export", "checkpoint hash".
---

# FastSurfer — Checkpoints & Modell-Management

## Wo Checkpoints leben

Default-Pfad innerhalb des FastSurfer-Repos: `$FASTSURFER_HOME/checkpoints/` (wird beim ersten Run angelegt). In Docker-Images sind die Checkpoints unter `/fastsurfer/checkpoints/` (im Image gebaked).

Konkrete Checkpoint-Files (Auswahl):

```
checkpoints/
├── aparc_vinn_axial_v2.0.0.pkl       FastSurferVINN Axial-View
├── aparc_vinn_coronal_v2.0.0.pkl     FastSurferVINN Coronal-View
├── aparc_vinn_sagittal_v2.0.0.pkl    FastSurferVINN Sagittal-View
├── cerebnet_axial_v1.0.0.pkl         CerebNet Axial
├── cerebnet_coronal_v1.0.0.pkl
├── cerebnet_sagittal_v1.0.0.pkl
├── hypvinn_axial_v1.0.0.pkl          HypVINN Axial
├── hypvinn_coronal_v1.0.0.pkl
├── hypvinn_sagittal_v1.0.0.pkl
├── cc_*.pkl                          Corpus-Callosum Networks
└── lit_*.pkl                         LIT (wenn LIT installiert)
```

Versionsschemata können sich zwischen FastSurfer-Releases ändern — die `download_checkpoints.py` verwaltet das.

## download_checkpoints.py

**Code:** `FastSurferCNN/download_checkpoints.py`

CLI-Aufruf:

```bash
cd $FASTSURFER_HOME
python3 FastSurferCNN/download_checkpoints.py --help
python3 FastSurferCNN/download_checkpoints.py        # lädt alle nötigen Checkpoints
```

Was passiert:
1. Liest die Checkpoint-Konfiguration (welche Files für welches Modul nötig sind).
2. Lädt fehlende oder veraltete Checkpoints von der Deep-MI-Server-URL.
3. Verifiziert via Hash (MD5 oder SHA256).

In Containern wird das normalerweise beim Image-Build gemacht. Bei nativer Installation läuft der Download lazily beim ersten Run oder manuell vorab.

## Checkpoint-Hashes prüfen

```bash
# Aktuelle Version + alle Checkpoint-Hashes
bash $FASTSURFER_HOME/run_fastsurfer.sh --version +checkpoints
```

Output zeigt jeden installierten Checkpoint mit seinem Hash. Praktisch um zu prüfen ob ein Container die richtigen Weights enthält.

## Modell-Loading-Pfad im Code

Inferenz-Entry-Points laden Checkpoints via Config:

| Modul | Code | Config |
|-------|------|--------|
| asegdkt | `FastSurferCNN/run_prediction.py` | `FastSurferCNN/config/*.yaml` |
| cereb | `CerebNet/run_prediction.py` | `CerebNet/config/*.yaml` |
| hypothal | `HypVINN/run_prediction.py` | `HypVINN/config/*.yaml` |
| cc | `CorpusCallosum/fastsurfer_cc.py` | `CorpusCallosum/config/*.yaml` |

Configs definieren:
- Network-Architecture (welche Klasse aus `models/`)
- Input-Channels, Output-Klassen
- Checkpoint-Pfad (relativ zu `$FASTSURFER_HOME`)
- Pre-/Post-Processing-Parameter

## Custom-Checkpoints verwenden

Wenn du eigene Weights (z.B. domain-adapted für pediatric Brains) verwenden willst:

1. Lege deine Checkpoints in `checkpoints/` ab oder in einem custom-Verzeichnis.
2. Editiere die relevante YAML-Config in `*/config/`:
   - Setze `checkpoint:` auf deinen Pfad.
3. Run normal — Pipeline lädt jetzt deine Weights.

Alternativ Container-Approach:

```bash
docker run --gpus all \
  -v /path/to/my/weights:/fastsurfer/checkpoints \
  ...
```

(siehe `--extra_singularity_options "-B /path-to-weights:/fastsurfer/checkpoints"` in `srun_fastsurfer.sh`).

## Custom-Training

**Code:** `FastSurferCNN/train.py` (asegdkt). Andere Module haben äquivalente Training-Scripts.

Workflow:

1. **Daten preparieren:** `FastSurferCNN/generate_hdf5.py` konvertiert NIfTI/MGZ-Volumes + Labels in HDF5-Datasets pro View (Coronal, Axial, Sagittal).

   ```bash
   python3 FastSurferCNN/generate_hdf5.py \
     --hdf5_name training_data_coronal.hdf5 \
     --plane coronal \
     --image_list_train /path/to/train_image_paths.txt \
     --label_list_train /path/to/train_label_paths.txt \
     ...
   ```

2. **Training starten:**

   ```bash
   python3 FastSurferCNN/train.py \
     --cfg FastSurferCNN/config/FastSurferVINN_coronal.yaml \
     OUTPUT_DIR /path/to/runs/coronal/
   ```

   Drei separate Trainings für die drei Views.

3. **Evaluation:**

   ```bash
   python3 FastSurferCNN/run_model.py \
     --cfg FastSurferCNN/config/FastSurferVINN_coronal.yaml \
     --plane coronal \
     ...
   ```

   `run_model.py` ist der lower-level-Entry-Point für reines Network-Inference (im Gegensatz zu `run_prediction.py`, das End-to-End-Conform+Inference+Aggregation macht).

Vollständige Trainings-Docs: `doc/scripts/fastsurfercnn.run_model.rst`, `doc/scripts/fastsurfercnn.generate_hdf5.rst`.

## Network-Architekturen

| Network | Datei | Beschreibung |
|---------|-------|--------------|
| FastSurferVINN (aktuell) | `FastSurferCNN/models/vinn.py` (oder ähnlich) | Voxel-Size-Invariant 2.5D U-Net mit Voxel-Embedding |
| FastSurferCNN (legacy) | `FastSurferCNN/models/networks.py` | Original 2.5D U-Net |
| CerebNet | `CerebNet/models/sub_module.py` (oder ähnlich) | 2.5D U-Net mit Localisation-Crop |
| HypVINN | `HypVINN/models/networks.py` | VINN-Variant mit Multi-Modal-Input |
| CC-Net | `CorpusCallosum/segmentation/` | Custom-Network für CC-Segmentation |

Exakte Klassennamen via:

```bash
rg "^class " $FASTSURFER_HOME/FastSurferCNN/models/
rg "^class " $FASTSURFER_HOME/CerebNet/models/
```

## Checkpoint-Persistierung in Containern

- **Docker-Image** `deepmi/fastsurfer:latest`: Checkpoints sind im Image gebaked.
- **Singularity-Image**: ebenfalls gebaked.
- **Native Install**: Lazy-Download beim ersten Run oder via `download_checkpoints.py`.

Wenn du Custom-Weights via Volume-Mount injizierst, überschreibst du die Image-Defaults — was du normalerweise willst.

## ONNX / Deployment

Aktuell **kein offizielles ONNX-Export** im Repo. Wenn du das brauchst, müsstest du selbst:

1. PyTorch-Model laden (über die Config-Loading-Logic).
2. `torch.onnx.export(model, dummy_input, "fastsurfer_vinn.onnx", ...)`.
3. Beachten: die View-Aggregation und Voxel-Size-Embedding sind in der Bash+Python-Pipeline orchestriert, nicht im PyTorch-Modul selbst — du müsstest die Aggregation in deiner Deployment-Pipeline rekonstruieren.

## Cross-Reference

- Wie Inferenz orchestriert: `fastsurfer-segmentation`
- Welche CLI-Flags Inferenz steuern: `fastsurfer-cli-flags`
- Code-Layout der Models: `fastsurfer-internals`
