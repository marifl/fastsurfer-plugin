---
description: Longitudinal Processing via `long_fastsurfer.sh` für einen Subject mit mehreren Time-Points.
allowed-tools: Bash, Read
argument-hint: "<template_id> <t1_1>,<t1_2>,... <tpid_1>,<tpid_2>,... [<extra-flags>]"
---

Longitudinal FastSurfer-Pipeline für $ARGUMENTS — innerhalb-Subject Konsistenz über mehrere Time-Points.

## Args-Parsing

Erwarte vom User:
1. **Template-ID** — eindeutiger Identifier für das innerhalb-Subject-Template (z.B. `sub01_template`)
2. **Komma-getrennte T1-Pfade** (absolut) — z.B. `/data/sub01/t1_y0.nii.gz,/data/sub01/t1_y1.nii.gz`
3. **Komma-getrennte TP-IDs** in derselben Reihenfolge — z.B. `sub01_y0,sub01_y1`
4. Optionale weitere Flags

Bei Unklarheit User nach Format fragen.

## Pre-Flight

```bash
TEMPLATE_ID="..."
T1_LIST="$(echo '<t1-arg>' | tr ',' ' ')"
TPID_LIST="$(echo '<tpid-arg>' | tr ',' ' ')"

# Anzahl T1s == Anzahl TPIDs?
N_T1=$(echo $T1_LIST | wc -w)
N_TPID=$(echo $TPID_LIST | wc -w)
[ "$N_T1" -eq "$N_TPID" ] || { echo "FAIL: T1-Count ($N_T1) != TPID-Count ($N_TPID)"; exit 1; }

# Alle T1s existieren?
for t1 in $T1_LIST; do
  [ -f "$t1" ] || { echo "MISSING: $t1"; exit 1; }
done
```

## Aufruf-Pattern

```bash
FASTSURFER_HOME="${FASTSURFER_HOME:-$HOME/prj/fastsurfer}"

"$FASTSURFER_HOME/long_fastsurfer.sh" \
  --tid <TEMPLATE_ID> \
  --t1s <T1_1> <T1_2> ... \
  --tpids <TPID_1> <TPID_2> ... \
  --sd "$SUBJECTS_DIR" \
  --fs_license "$FS_LICENSE" \
  --3T \
  --threads 4 \
  --parallel_seg 2 --parallel_surf 2 \
  <user-extra-flags>
```

## Restrictions

- **Kein** `--t2`, `--t1`, `--sid`, `--seg_only`, `--surf_only` — alle werden von long_fastsurfer.sh selber gemanaged.
- FreeSurfer-License Pflicht.
- Template-ID muss neu sein (Dir wird angelegt) — bei Re-Run vorher löschen.

## Stage-Control (optional)

Mit `--stage <name>` kannst du nur bestimmte Phasen laufen lassen:

| Stage | Was passiert |
|-------|--------------|
| `prepare` | Template-Dir vorbereiten |
| `template_seg` | Seg auf Template |
| `template_surf` | Surf auf Template |
| `long_seg` | Per-TP Seg |
| `long_surf` | Per-TP Surf |
| `all` (default) | Alles |

Mehrere Stages: `--stage prepare --stage template_seg`.

## Erwartete Outputs

```
$SUBJECTS_DIR/
├── <TEMPLATE_ID>/        ← Zwischenstufe, normalerweise nicht analysiert
├── <TPID_1>/             ← Final-Outputs TP1 (volle Struktur)
├── <TPID_2>/             ← Final-Outputs TP2
└── ...
```

Jeder TP-Subject hat die normale FreeSurfer-Subject-Struktur (`mri/`, `surf/`, `label/`, `stats/`).

## Erwartete Laufzeit (typisch)

Für 3 TPs mit `--parallel_seg 2 --parallel_surf 2`:
- Template-Prep + Template-Seg + Template-Surf: ~90 Min
- Per-TP-Seg (3 TPs, 2 parallel): ~10 Min
- Per-TP-Surf (3 TPs, 2 parallel): ~120 Min
- Total: ~3.5-4h

## Cross-Reference

- Theorie + Stage-Map: Skill `fastsurfer-longitudinal`
- Methoden-Paper: Reuter et al., NeuroImage 61:4 (2012)
- Single-Subject Cross-Sectional: `/fs-run`
