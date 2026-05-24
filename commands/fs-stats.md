---
description: Liest, druckt und vergleicht FastSurfer .stats Files (aseg, aparc, wmparc, cerebellum, hypothalamus, CC).
allowed-tools: Bash, Read
argument-hint: "<sid> [<stat-file>|--compare <sid2>|--measure <name>|--export-csv <path>|--list]"
---

Liefere strukturierte Stats-Information für `$ARGUMENTS`.

Erwartete Arg-Patterns:

1. `<sid>` allein → Liste aller verfuegbaren Stats-Files + tabellarische Uebersicht von `aseg.stats`
2. `<sid> <file>` → Pretty-Print einer konkreten Datei (z.B. `lh.aparc.DKTatlas.mapped.stats`)
3. `<sid> --compare <sid2>` → Side-by-Side Vergleich der wichtigsten Measures (volumes, thickness)
4. `<sid> --measure <name>` → Nur ein konkreter Measure (z.B. `Hippocampus`, `Brain-Segmented-Volume`)
5. `<sid> --export-csv <path>` → Exportiert aseg+aparc-Stats als flat CSV
6. `<sid> --list` → Nur die File-Liste, kein Print

## Pre-Flight

```bash
SID="<sid-from-args>"
SD="${SUBJECTS_DIR_OVERRIDE:-$SUBJECTS_DIR}"
STATS_DIR="$SD/$SID/stats"

[ -d "$STATS_DIR" ] || { echo "FAIL: $STATS_DIR existiert nicht"; exit 1; }

echo "Subject: $SID"
echo "Stats-Dir: $STATS_DIR"
echo ""
```

## Mode 1 — Default (Liste + Uebersicht)

```bash
echo "=== Verfuegbare Stats-Files ==="
ls -lh "$STATS_DIR" | grep -E "\.(stats|json)$" | awk '{printf "  %-50s %s\n", $9, $5}'

echo ""
echo "=== aseg.stats Hauptwerte (Whole-Brain) ==="
if [ -f "$STATS_DIR/aseg.stats" ]; then
  grep "^# Measure" "$STATS_DIR/aseg.stats" | \
    sed 's/^# Measure //' | \
    awk -F', ' '{printf "  %-45s %15s %s\n", $2, $4, $5}'
fi
```

Wenn `aseg.stats` nicht existiert (nur `--seg_only` lief), fallback auf `aseg+DKT.stats`.

## Mode 2 — Pretty-Print einer Datei

Bei Arg `<sid> <file>`:

```bash
FILE="<file-from-arg>"
TARGET="$STATS_DIR/$FILE"
[ -f "$TARGET" ] || { echo "FAIL: $TARGET nicht gefunden"; exit 1; }

if [[ "$FILE" == *.json ]]; then
  # JSON pretty-print
  python3 -m json.tool "$TARGET" | head -200
else
  # FreeSurfer .stats Format
  echo "=== Measures (Header) ==="
  grep "^# Measure" "$TARGET" | sed 's/^# Measure //' | column -t -s ','
  echo ""
  echo "=== Tabular Data ==="
  # ColHeaders extrahieren + Tabular formatieren
  python3 - "$TARGET" <<'PY'
import sys, pandas as pd
path = sys.argv[1]
col_line = None
data_lines = []
with open(path) as f:
    for line in f:
        if line.startswith('# ColHeaders'):
            col_line = line.replace('# ColHeaders', '').split()
        elif not line.startswith('#') and line.strip():
            data_lines.append(line.split())
if col_line and data_lines:
    df = pd.DataFrame(data_lines, columns=col_line)
    print(df.to_string(index=False, max_rows=80))
else:
    print('  (keine Tabular-Daten — nur Header-Measures)')
PY
fi
```

## Mode 3 — Compare zwei Subjects

Bei Arg `<sid1> --compare <sid2>`:

```bash
SID2="<sid2-from-arg>"

python3 - "$SD/$SID/stats" "$SD/$SID2/stats" "$SID" "$SID2" <<'PY'
import sys, re
from pathlib import Path

s1, s2, n1, n2 = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], sys.argv[4]

def measures(stats_dir):
    out = {}
    for f in ['aseg.stats', 'aseg+DKT.stats']:
        p = stats_dir / f
        if p.exists():
            for line in p.read_text().splitlines():
                if line.startswith('# Measure'):
                    parts = [x.strip() for x in line.replace('# Measure', '').split(',')]
                    if len(parts) >= 4:
                        out[parts[0]] = (parts[1], parts[2], parts[3])
            break
    return out

m1, m2 = measures(s1), measures(s2)
keys = sorted(set(m1) | set(m2))

print(f"{'Measure':<35} {n1:>15} {n2:>15} {'Diff':>15} {'Unit':>10}")
print('-' * 95)
for k in keys:
    v1 = m1.get(k, ('-', '-', '-'))
    v2 = m2.get(k, ('-', '-', '-'))
    try:
        f1, f2 = float(v1[2]), float(v2[2])
        diff = f2 - f1
        diff_str = f"{diff:+.2f}"
    except (ValueError, TypeError):
        diff_str = '-'
    unit = v1[0] if v1[0] != '-' else v2[0]
    print(f"{k:<35} {v1[2]:>15} {v2[2]:>15} {diff_str:>15} {unit:>10}")
PY
```

## Mode 4 — Einzelner Measure

Bei `<sid> --measure <name>`:

```bash
MEASURE="<measure-from-arg>"

echo "=== '$MEASURE' across all stats files ==="
for f in "$STATS_DIR"/*.stats; do
  match=$(grep -i "$MEASURE" "$f" 2>/dev/null | head -3)
  if [ -n "$match" ]; then
    echo ""
    echo "--- $(basename $f) ---"
    echo "$match"
  fi
done
```

## Mode 5 — CSV-Export

Bei `<sid> --export-csv <path>`:

```bash
CSV_PATH="<csv-path-from-arg>"

python3 - "$STATS_DIR" "$CSV_PATH" "$SID" <<'PY'
import sys, csv
from pathlib import Path

stats_dir, csv_path, sid = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]

rows = [['source', 'category', 'measure_or_struct', 'value', 'unit', 'description']]

# Header-Measures aus aseg/aseg+DKT
for f in ['aseg.stats', 'aseg+DKT.stats', 'cerebellum.CerebNet.stats',
          'hypothalamus.HypVINN.stats', 'wmparc.DKTatlas.mapped.stats']:
    p = stats_dir / f
    if not p.exists():
        continue
    for line in p.read_text().splitlines():
        if line.startswith('# Measure'):
            parts = [x.strip() for x in line.replace('# Measure', '').split(',')]
            if len(parts) >= 4:
                rows.append([f, 'measure', parts[0], parts[2], parts[3] if len(parts)>3 else '', parts[1]])
        elif not line.startswith('#') and line.strip():
            cols = line.split()
            if len(cols) >= 5:
                # aseg: Index SegId NVoxels Volume_mm3 StructName ...
                rows.append([f, 'struct', cols[4] if len(cols)>4 else '?', cols[3], 'mm3', f'segId={cols[1]}'])

# Aparc per-hemi
for hemi in ['lh', 'rh']:
    p = stats_dir / f'{hemi}.aparc.DKTatlas.mapped.stats'
    if not p.exists():
        continue
    for line in p.read_text().splitlines():
        if not line.startswith('#') and line.strip():
            cols = line.split()
            if len(cols) >= 5:
                # aparc: StructName NumVert SurfArea GrayVol ThickAvg ...
                rows.append([p.name, 'cortex', f'{hemi}.{cols[0]}', cols[3], 'mm3', f'GrayVol'])
                rows.append([p.name, 'cortex', f'{hemi}.{cols[0]}', cols[4], 'mm', f'ThickAvg'])

csv_path.write_text('')
with csv_path.open('w', newline='') as f:
    csv.writer(f).writerows(rows)
print(f'Exported {len(rows)-1} rows -> {csv_path}')
PY
```

## Mode 6 — Nur Liste

Bei `<sid> --list`:

```bash
ls "$STATS_DIR" | grep -E "\.(stats|json)$"
```

## Wichtige Stats-Files (Cross-Reference)

| Datei | Inhalt | Erzeugt von |
|-------|--------|-------------|
| `aseg.stats` | post-Surf Subcortex+Cortex Volumes | recon-surf |
| `aseg+DKT.stats` | post-Seg VINN-Stats | asegdkt-Modul |
| `{lh,rh}.aparc.DKTatlas.mapped.stats` | Cortical-Parcellation per-Hemi | recon-surf |
| `{lh,rh}.curv.stats` | Curvature per-Hemi | recon-surf |
| `wmparc.DKTatlas.mapped.stats` | White-Matter-Parcellation | recon-surf |
| `cerebellum.CerebNet.stats` | Cerebellum-Subregionen | CerebNet |
| `hypothalamus.HypVINN.stats` | Hypothalamus-Subregionen | HypVINN |
| `callosum.CC.midslice.json` | CC mid-sagittal Metrics | CC |
| `callosum.CC.all_slices.json` | CC per-Slice | CC |

## Beispiele

```
/fs-stats sub01                              # Liste + aseg-Uebersicht
/fs-stats sub01 lh.aparc.DKTatlas.mapped.stats
/fs-stats sub01 --measure "Brain-Segmented-Volume"
/fs-stats sub01 --measure Hippocampus        # findet sowohl Left- als Right-Hippocampus
/fs-stats sub01 --compare sub02              # Side-by-Side Hauptmeasures
/fs-stats sub01 --export-csv /tmp/sub01.csv  # CSV fuer pandas/R
/fs-stats sub01 --list                       # nur Filename-Liste
```

## Cross-Reference

- Format-Details der `.stats`-Files: Skill `fastsurfer-stats-parsing`
- Welche Stats wann erzeugt werden: Skill `fastsurfer-outputs`
- Stats-Computation-Code: Skill `fastsurfer-internals` (`mri_segstats.py`, `segstats.py`)
