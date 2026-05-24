---
name: fastsurfer-longitudinal
description: Use when the user wants to run longitudinal FastSurfer analysis (same subject, multiple time points), build within-subject templates, or asks about long_fastsurfer.sh, --base, --long, or template-based processing. Triggers on "longitudinal FastSurfer", "long_fastsurfer", "within-subject template", "time points", "base template", "templateID", "long_prepare_template", "Reuter longitudinal".
---

# FastSurfer — Longitudinal Processing (long_fastsurfer.sh)

Longitudinal Processing erlaubt **innersubjektliche** Konsistenz wenn mehrere MRTs derselben Person über die Zeit prozessiert werden (Kohorten-/Verlaufs-Studien).

**Code:** `long_fastsurfer.sh` (Top-Level) + `recon_surf/long_prepare_template.sh`.
**Methodik:** Reuter et al., NeuroImage 61:4 (2012) — "Within-subject template estimation for unbiased longitudinal image analysis."

## Konzept

```
Time Point 1 (T1_1)
Time Point 2 (T1_2)    →   Within-Subject-Template (templateID)   →   Long Time Point Outputs
Time Point 3 (T1_3)
        ...                 │                                          │
                            ▼                                          ▼
                    $SUBJECTS_DIR/<templateID>/             $SUBJECTS_DIR/<tID_n>/
                    (Zwischenstufe, normal nicht analysiert)   (Finale Per-TP Outputs)
```

Vorteile:
- Subject-spezifisches Template reduziert Bias.
- Konsistente Surfaces/Parcellation über TPs → präzisere Atrophy-Schätzungen.
- Pial/White-Surfaces sind across-TP topologisch konsistent.

## CLI

```bash
long_fastsurfer.sh \
  --tid <templateID> \
  --t1s <T1_1> <T1_2> <T1_3> ... \
  --tpids <tID1> <tID2> <tID3> ... \
  --sd <subjects_dir> \
  --fs_license <license> \
  [other run_fastsurfer.sh flags except --t1, --t2, --sid, --seg_only, --surf_only]
```

### Args

| Flag | Wert |
|------|------|
| `--tid <id>` | Template-ID (wird als `$SUBJECTS_DIR/<id>/` erzeugt) |
| `--t1s <T1_1> <T1_2> ...` | Liste der T1-Inputs (absolute Pfade), gleiche Reihenfolge wie `--tpids` |
| `--tpids <tID1> <tID2> ...` | Liste der per-TP Subject-IDs (werden später erzeugt) |
| `--sd <dir>` | Subjects-Dir |
| `--fs_license <file>` | FreeSurfer-Lizenz |

Plus alle `run_fastsurfer.sh`-Flags **ausser** `--t1`, `--t2`, `--sid`, `--seg_only`, `--surf_only`.

## Stages

Default `--stage all` läuft die volle Pipeline. Mit `--stage <name>` kannst du einzelne Stufen ansteuern (multiple Stages = multiple Flags):

| Stage | Was passiert | Abhängigkeit |
|-------|--------------|--------------|
| `prepare` | Bereitet Template-Dir vor (`long_prepare_template.sh`). Robust-template + Voxel-Konformierung. | keine (braucht `--t1s` + `--tpids`) |
| `template_seg` | Asegdkt-Seg auf dem Template | `prepare` |
| `template_surf` | Surface-Reconstruction auf dem Template | `prepare` + `template_seg` |
| `long_seg` | Per-TP Segmentation (initialisiert vom Template) | `prepare` |
| `long_surf` | Per-TP Surface (initialisiert vom Template, viele Steps skipped) | `prepare` + `template_seg` + `template_surf` + `long_seg` |
| `all` | Default — alle obigen | — |

Stage-Dependencies sind streng. Wenn du z.B. nur `long_seg` haben willst, müssen die vorherigen Stages bereits Outputs produziert haben.

## Parallelisierung

```
--parallel <n>|max         für Seg+Surf
--parallel_seg <n>|max     nur Seg
--parallel_surf <m>|max    nur Surf (Default: 1)
```

Wirkt sich aus auf Template-Seg und Template-Surf sowie Per-TP-Seg/Surf-Loops.

## Beispiel

```bash
./long_fastsurfer.sh \
  --tid sub01_template \
  --t1s /data/sub01/t1_year0.nii.gz \
        /data/sub01/t1_year1.nii.gz \
        /data/sub01/t1_year2.nii.gz \
  --tpids sub01_y0 sub01_y1 sub01_y2 \
  --sd /output/longitudinal \
  --fs_license /opt/fs_license.txt \
  --3T \
  --threads 4 \
  --parallel_seg 2 --parallel_surf 2
```

Ergebnis:

```
/output/longitudinal/
├── sub01_template/    ← Zwischenstufe (Template-Outputs, meist nicht analysiert)
├── sub01_y0/          ← Final-Outputs TP1
├── sub01_y1/          ← Final-Outputs TP2
└── sub01_y2/          ← Final-Outputs TP3
```

Jeder TP-Subject hat die normale FreeSurfer-Subject-Struktur (`mri/`, `surf/`, `label/`, `stats/`).

## Direct `--base` / `--long` Flags

Für Power-User: `run_fastsurfer.sh` selbst kennt `--base` und `--long <baseid>` Flags. Damit lassen sich Stages manuell aufrufen. Beispiel:

```bash
# Template-Processing
run_fastsurfer.sh --base --sid sub01_template --sd /output ...

# Per-TP-Processing
run_fastsurfer.sh --long sub01_template --sid sub01_y0 --sd /output ...
run_fastsurfer.sh --long sub01_template --sid sub01_y1 --sd /output ...
```

Voraussetzung: Template-Vorbereitung mit `recon_surf/long_prepare_template.sh` muss vorher gelaufen sein.

`long_fastsurfer.sh` macht das alles für dich orchestriert — nutze die direkte API nur wenn du Custom-Stages willst.

## Was unterscheidet sich von Cross-Sectional?

- **Seg:** initialisiert von Template-Seg → konsistentere Labels über TPs.
- **Surf:** viele Steps werden vom Template initialisiert → Surfaces sind topologisch konsistent (vertex-correspondence über TPs).
- **Talairach:** wird einmal auf dem Template berechnet, nicht per-TP.
- **Stats:** Per-TP gerechnet aber mit Template-Korrektur.

Im Default-Mode (per `long_fastsurfer.sh`) sind nur asegdkt + Surfaces longitudinal aktiv. CerebNet/HypVINN/CC laufen klassisch per-TP ohne longitudinal-Initialisierung (zumindest in der aktuellen Implementation).

## Output-Struktur

Per-TP-Subject-Dirs sind 1:1 wie ein normaler `run_fastsurfer.sh`-Run (siehe Skill `fastsurfer-outputs`).

Template-Subject-Dir (`<templateID>`) enthält **nicht alle** Files — nur die, die für die Template-Estimation gebraucht werden. Wird normalerweise nicht direkt analysiert.

## Wann lohnt Longitudinal?

- Mehr als ein TP pro Subject.
- Atrophy / Volume-Change / Cortical-Thinning Analyse.
- Pre-/Post-Treatment Vergleiche.

Bei nur einem TP pro Subject: kein Bedarf, klassisches `run_fastsurfer.sh` reicht.

## Restrictions

- **Kein `--t2`** im longitudinal-Stream.
- **Kein `--seg_only` oder `--surf_only`** — Long-Pipeline orchestriert beide.
- **`--lesion_mask`**: Verhalten in longitudinal-Stream nicht spezifiziert; LIT-Doc konsultieren.

## Cross-Reference

- Welche Stages welche Outputs erzeugen: `fastsurfer-outputs`
- Surface-Pipeline-Details (für `template_surf`/`long_surf`): `fastsurfer-surface-recon`
- Parallelisierung von Multi-Subject longitudinal: `fastsurfer-batch-slurm`
