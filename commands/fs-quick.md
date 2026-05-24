---
description: FastSurfer Quick-Mode — nur aseg+DKT, ~1 Min auf GPU. Skipped cereb, hypothal, cc, surf.
allowed-tools: Bash, Read
argument-hint: "<t1_path> <sid> [<extra-flags>]"
---

Schnellster FastSurfer-Modus für $ARGUMENTS. Nur aseg+DKT (asegdkt-Modul), keine Sub-Module, keine Surface.

## Use-Case

Wenn du nur die Whole-Brain-Segmentation + Cortex-Parcellation brauchst (95 Klassen) und KEINE:
- Detaillierte Cerebellum-Subregionen (CerebNet)
- Hypothalamus-Subsegmentation (HypVINN)
- Corpus-Callosum-Analyse (CC)
- Cortical Surfaces

## Aufruf-Pattern

```bash
FASTSURFER_HOME="${FASTSURFER_HOME:-/Users/marcusifland/prj/fastsurfer}"

"$FASTSURFER_HOME/run_fastsurfer.sh" \
  --t1 <absolute-T1-path> \
  --sid <SID> \
  --sd "$SUBJECTS_DIR" \
  --seg_only \
  --no_cereb --no_hypothal --no_cc \
  --threads 4 \
  <user-extra-flags>
```

## Noch schneller — ohne Biasfield

```bash
... --no_biasfield ...
```

Entfernt zusätzlich die PV-korrigierte Stats-Berechnung. Spart ein paar Sekunden, Stats werden ungenauer.

## Erwartete Outputs (Minimal)

```
$SUBJECTS_DIR/<SID>/mri/aparc.DKTatlas+aseg.deep.mgz
$SUBJECTS_DIR/<SID>/mri/orig.mgz
$SUBJECTS_DIR/<SID>/mri/orig_nu.mgz                  (wenn nicht --no_biasfield)
$SUBJECTS_DIR/<SID>/mri/mask.mgz
$SUBJECTS_DIR/<SID>/mri/aseg.auto_noCCseg.mgz
$SUBJECTS_DIR/<SID>/stats/aseg+DKT.stats              (wenn nicht --no_biasfield)
$SUBJECTS_DIR/<SID>/scripts/deep-seg.log
```

## Erwartete Laufzeit

- ~1 Min auf GPU (RTX 3090 / A100)
- ~5-10 Min auf Apple Silicon (CPU)
- ~15-30 Min auf älterer CPU

## Cross-Reference

- Mit Sub-Modulen + Surface: `/fs-run`
- Nur Seg mit Sub-Modulen: `/fs-seg`
- Wenn du Surfaces später willst: `/fs-surf` (nach `/fs-quick`-Run)
