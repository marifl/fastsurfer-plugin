---
name: fastsurfer-stats-parsing
description: Use when the user wants to parse FastSurfer/FreeSurfer `.stats` files programmatically — extracting measures into pandas DataFrames, comparing across subjects, batch-aggregating for studies, or converting to CSV/Excel/JSON. Triggers on "parse aseg.stats", "FreeSurfer stats format", "load stats Python", "aparc DataFrame", "compare subjects FastSurfer", "batch stats", "stats CSV", "stats2table".
---

# FastSurfer/FreeSurfer `.stats`-Files — Format & Parsing

FastSurfer erzeugt FreeSurfer-kompatible `.stats`-Files. Sie sind **text-basiert** mit zwei Sektionen: **Header-Measures** und **Tabular-Data**. Plus zwei JSON-Files vom CC-Modul.

## Format-Aufbau (.stats)

```
# Title Segmentation Statistics
# generating_program mri_segstats
# cvs_version $Id: mri_segstats.c,v 1.121 ...
# cmdline mri_segstats ...
# sysname Linux
# subjectname sub01
# annot lh aparc.DKTatlas.annot
# anatomy_type volume
#
# Measure BrainSeg, BrainSegVol, Brain Segmentation Volume, 1234567.0, mm^3
# Measure BrainSegNotVent, BrainSegVolNotVent, Brain Segmentation Volume Without Ventricles, 1200000.0, mm^3
# Measure eTIV, eTIV, Estimated Total Intracranial Volume, 1500000.0, mm^3
# ... (mehr Measures)
#
# NTableCols 10
# ColHeaders Index SegId NVoxels Volume_mm3 StructName normMean normStdDev normMin normMax normRange
  1  4   4500   4500.0  Left-Lateral-Ventricle      35.2  10.1  10  85  75
  2  5    200    200.0  Left-Inf-Lat-Vent           38.5  11.3  12  82  70
  3  7  15000  15000.0  Left-Cerebellum-White-Matter 85.3   8.1  60 110  50
  ... (mehr Strukturen)
```

### Zwei Daten-Typen

1. **Header-Measures** (Zeilen die mit `# Measure` beginnen):
   - Format: `# Measure <ShortName>, <LongName>, <Description>, <Value>, <Unit>`
   - Typische Measures: `BrainSeg`, `BrainSegNotVent`, `eTIV`, `BrainSegVol-to-eTIV`, `CortexVol`, `SubCortGrayVol`, etc.

2. **Tabular-Data** (alles nach `# ColHeaders`):
   - Whitespace-separated.
   - Spalten variieren je nach Stats-Typ (siehe unten).

### Spalten-Schemata pro Stats-Typ

#### `aseg.stats` (Subcortex + ROI volumes)

```
Index SegId NVoxels Volume_mm3 StructName normMean normStdDev normMin normMax normRange
```

- `SegId`: FreeSurfer-Label-ID (siehe `FreeSurferColorLUT.txt`)
- `NVoxels`, `Volume_mm3`: Anzahl Voxel und Volumen (mm³)
- `StructName`: Region-Name (z.B. `Left-Hippocampus`)
- `normMean`–`normRange`: Intensitäts-Stats des normalized T1 in dieser Region

#### `{lh,rh}.aparc.DKTatlas.mapped.stats` (Cortical Parcellation per Hemi)

```
StructName NumVert SurfArea GrayVol ThickAvg ThickStd MeanCurv GausCurv FoldInd CurvInd
```

- `StructName`: DKT-Region (z.B. `caudalanteriorcingulate`, `entorhinal`)
- `NumVert`: Vertex-Count
- `SurfArea`: Cortex-Surface-Area (mm²)
- `GrayVol`: Gray-Matter-Volume (mm³)
- `ThickAvg`, `ThickStd`: Cortical-Thickness (mm)
- `MeanCurv`, `GausCurv`: Surface-Curvature
- `FoldInd`, `CurvInd`: Folding/Curvature-Indices

#### `aseg+DKT.stats` (FastSurferVINN VINN-Stats, post-Seg)

Gleiche Spalten wie `aseg.stats`, aber direkt aus der VINN-Segmentation (ohne Surface-PV-Korrektur). Wird durch `aseg.stats` nach Surface-Run "ersetzt" (Surface-Stats sind genauer).

#### `cerebellum.CerebNet.stats`

```
Index SegId NVoxels Volume_mm3 StructName normMean normStdDev normMin normMax normRange
```

Gleiches Schema wie aseg, aber für CerebNet-Subregionen (Lobuli I–X, Vermis, Cerebellum-WM, Cerebellum-Cortex per Hemi).

#### `hypothalamus.HypVINN.stats`

Gleiches Schema, für Hypothalamus-Subregionen (Hypothalamus L/R, 3. Ventrikel, Corpora mamillaria, Fornix, Tractus opticus).

#### `wmparc.DKTatlas.mapped.stats`

Gleiches Schema wie aseg, aber für White-Matter unter den jeweiligen Cortex-Parcellation-Regionen.

#### `{lh,rh}.curv.stats`

```
StructName NumVert SurfArea CurvAvg CurvStd CurvMin CurvMax CurvRange
```

Curvature-Statistiken per cortical Region.

#### `callosum.CC.midslice.json` / `callosum.CC.all_slices.json`

Standard JSON, NICHT FreeSurfer-Format. Format:

```json
{
  "subject_id": "sub01",
  "midslice": {
    "area_mm2": 642.3,
    "thickness_profile": [0.0, 1.2, 2.4, ...],
    "landmarks": {
      "AC": [128, 125, 130],
      "PC": [128, 95, 138]
    }
  }
}
```

Parsen mit `json.load(open(path))`.

## Python-Parser

### Quick-Load aller Measures aus aseg.stats

```python
def parse_measures(stats_path):
    """Returns dict: short_name -> (long_name, description, value, unit)"""
    measures = {}
    with open(stats_path) as f:
        for line in f:
            if line.startswith('# Measure'):
                parts = [x.strip() for x in line.replace('# Measure', '').split(',')]
                if len(parts) >= 5:
                    short, long_name, desc, val, unit = parts[0], parts[1], parts[2], parts[3], parts[4]
                    measures[short] = {
                        'long_name': long_name,
                        'description': desc,
                        'value': float(val),
                        'unit': unit,
                    }
    return measures

m = parse_measures('subject_dir/stats/aseg.stats')
print(m['BrainSeg']['value'], m['BrainSeg']['unit'])
# 1234567.0 mm^3
```

### Quick-Load Tabular-Data als pandas DataFrame

```python
import pandas as pd

def parse_table(stats_path):
    """Returns DataFrame of tabular data."""
    col_line = None
    data_lines = []
    with open(stats_path) as f:
        for line in f:
            if line.startswith('# ColHeaders'):
                col_line = line.replace('# ColHeaders', '').split()
            elif not line.startswith('#') and line.strip():
                data_lines.append(line.split())
    df = pd.DataFrame(data_lines, columns=col_line)
    # Auto-convert numeric columns
    for col in df.columns:
        try:
            df[col] = pd.to_numeric(df[col])
        except (ValueError, TypeError):
            pass   # keep as string
    return df

df = parse_table('subject_dir/stats/aseg.stats')
print(df.head())
print(df[df['StructName'] == 'Left-Hippocampus']['Volume_mm3'].values)
```

### Beide kombiniert (Measures + Table)

```python
def load_stats(stats_path):
    return {
        'measures': parse_measures(stats_path),
        'table': parse_table(stats_path),
    }

data = load_stats('sub01/stats/aseg.stats')
```

### Multi-Subject Aggregation

```python
import pandas as pd
from pathlib import Path

def aggregate_aseg(subjects_dir, sids, stats_file='aseg.stats'):
    """Returns wide DataFrame: rows=subjects, cols=structures."""
    rows = []
    for sid in sids:
        path = Path(subjects_dir) / sid / 'stats' / stats_file
        if not path.exists():
            print(f'WARN: {path} fehlt')
            continue
        df = parse_table(path)
        # StructName als Index, Volume_mm3 als Wert
        sub_row = df.set_index('StructName')['Volume_mm3'].to_dict()
        sub_row['_sid'] = sid
        rows.append(sub_row)
    return pd.DataFrame(rows).set_index('_sid')

sids = ['sub01', 'sub02', 'sub03']
df = aggregate_aseg('/subjects', sids)
print(df[['Left-Hippocampus', 'Right-Hippocampus']])
# rows = sids, cols = struct-name, values = volumes
```

### Cortical-Aparc Aggregation (per-Hemi)

```python
def aggregate_aparc(subjects_dir, sids, hemi='lh', metric='ThickAvg'):
    """metric: ThickAvg, GrayVol, SurfArea, NumVert, ..."""
    rows = []
    for sid in sids:
        path = Path(subjects_dir) / sid / 'stats' / f'{hemi}.aparc.DKTatlas.mapped.stats'
        if not path.exists():
            continue
        df = parse_table(path)
        sub_row = df.set_index('StructName')[metric].to_dict()
        sub_row['_sid'] = sid
        rows.append(sub_row)
    return pd.DataFrame(rows).set_index('_sid')

thick_lh = aggregate_aparc('/subjects', sids, hemi='lh', metric='ThickAvg')
thick_rh = aggregate_aparc('/subjects', sids, hemi='rh', metric='ThickAvg')
```

### eTIV-Normalisierung

Wichtig fuer Volume-Vergleiche: Volumes werden meist als Verhältnis zu eTIV (estimated Total Intracranial Volume) berichtet.

```python
def get_etiv(stats_path):
    m = parse_measures(stats_path)
    return m.get('eTIV', {}).get('value', None)

def normalize_to_etiv(subjects_dir, sids):
    rows = []
    for sid in sids:
        sd = Path(subjects_dir) / sid / 'stats'
        etiv = get_etiv(sd / 'aseg.stats')
        if etiv is None:
            continue
        df = parse_table(sd / 'aseg.stats')
        df['Volume_pct_eTIV'] = df['Volume_mm3'] / etiv * 100
        df['_sid'] = sid
        rows.append(df)
    return pd.concat(rows, ignore_index=True)
```

## FreeSurfer-CLI: `asegstats2table` / `aparcstats2table`

FreeSurfer hat Standard-Tools dafuer. Wenn du `FREESURFER_HOME` gesourced hast:

```bash
# aseg-Volumes als CSV/TSV
asegstats2table --subjects sub01 sub02 sub03 \
                --tablefile aseg_volumes.tsv \
                --meas volume

# aparc per-Hemi
aparcstats2table --subjects sub01 sub02 sub03 \
                 --hemi lh \
                 --meas thickness \
                 --tablefile lh_thickness.tsv

# Verfuegbare Meas: volume (Default), thickness, area, ...
```

Wenn FreeSurfer nicht installiert ist (Container-Only oder reine Python-Pipeline): nutze die Python-Parser oben.

## Diff zwischen Subjects

```python
def diff_subjects(sd, sid1, sid2):
    """Returns DataFrame mit Volume-Diff fuer alle Strukturen."""
    df1 = parse_table(Path(sd) / sid1 / 'stats' / 'aseg.stats')
    df2 = parse_table(Path(sd) / sid2 / 'stats' / 'aseg.stats')
    merged = df1.merge(df2, on='StructName', suffixes=(f'_{sid1}', f'_{sid2}'))
    merged['diff_mm3'] = merged[f'Volume_mm3_{sid2}'] - merged[f'Volume_mm3_{sid1}']
    merged['diff_pct'] = merged['diff_mm3'] / merged[f'Volume_mm3_{sid1}'] * 100
    return merged[['StructName', f'Volume_mm3_{sid1}', f'Volume_mm3_{sid2}', 'diff_mm3', 'diff_pct']]

diff = diff_subjects('/subjects', 'sub01_pre', 'sub01_post')
print(diff.sort_values('diff_pct').head(10))    # Strukturen mit groesster Atrophy
```

## Longitudinal-Tracking

Wenn du `long_fastsurfer.sh` gefahren hast: jeder TP-Subject hat seine eigenen stats. Aggregate ueber Zeitpunkte:

```python
def longitudinal_trajectory(sd, template_id, tpids, struct_name):
    """Returns DataFrame: timepoint, volume_mm3"""
    rows = []
    for i, tpid in enumerate(tpids):
        df = parse_table(Path(sd) / tpid / 'stats' / 'aseg.stats')
        match = df[df['StructName'] == struct_name]
        if len(match):
            rows.append({
                'timepoint': i,
                'tpid': tpid,
                'volume_mm3': match['Volume_mm3'].iloc[0],
            })
    return pd.DataFrame(rows)

traj = longitudinal_trajectory('/subjects', 'sub01_template',
                               ['sub01_y0', 'sub01_y1', 'sub01_y2'],
                               'Left-Hippocampus')
# Plotten z.B. mit matplotlib: traj.plot(x='timepoint', y='volume_mm3')
```

## Excel/JSON-Export

```python
# Excel
df.to_excel('subjects_stats.xlsx', index=False)

# JSON (long format)
df.to_json('subjects_stats.json', orient='records', indent=2)

# JSON (nested per subject)
import json
nested = {sid: parse_table(...).to_dict('records') for sid in sids}
with open('nested.json', 'w') as f:
    json.dump(nested, f, indent=2)
```

## Common Pitfalls

### "Volumes sehen anders aus als FreeSurfer-recon-all"

FastSurfer 95-Klassen-Output (`aparc.DKTatlas+aseg.deep.mgz`) ist DL-basiert, FreeSurfer-recon-all ist Atlas-+Surface-basiert. Die Volumes sind **nicht identisch**, aber hoch-korreliert (>0.95 in den meisten Regionen). Nicht "richtig" oder "falsch" — verschiedene Methoden.

Nach erfolgreichem Surface-Run werden die FastSurfer-Stats fein-justiert (PV-Korrektur via Surface) — Post-Surface-Stats sind näher an FreeSurfer-recon-all.

### "Welcher aseg.stats ist der richtige?"

Wenn beide existieren:
- `aseg+DKT.stats`: post-Seg, **rohe VINN-Stats** ohne Surface-PV-Korrektur.
- `aseg.stats`: post-Surf, **fein-justiert** durch Surface-Pipeline. Empfohlen fuer downstream Analysen.

Wenn `--seg_only` lief, gibt's nur `aseg+DKT.stats`.

### "ColHeaders fehlen"

Sehr alte oder modifizierte stats-Files können den `# ColHeaders` Marker fehlen lassen. Workaround:

```python
DEFAULT_COLS = {
    'aseg': ['Index', 'SegId', 'NVoxels', 'Volume_mm3', 'StructName',
             'normMean', 'normStdDev', 'normMin', 'normMax', 'normRange'],
    'aparc': ['StructName', 'NumVert', 'SurfArea', 'GrayVol',
              'ThickAvg', 'ThickStd', 'MeanCurv', 'GausCurv', 'FoldInd', 'CurvInd'],
}

def parse_table_with_fallback(path, table_type='aseg'):
    cols = None
    rows = []
    with open(path) as f:
        for line in f:
            if line.startswith('# ColHeaders'):
                cols = line.replace('# ColHeaders', '').split()
            elif not line.startswith('#') and line.strip():
                rows.append(line.split())
    if cols is None:
        cols = DEFAULT_COLS.get(table_type, [f'col_{i}' for i in range(len(rows[0]))])
    return pd.DataFrame(rows, columns=cols[:len(rows[0])])
```

### "NaN-Volumes / 0-Volumes"

Bei FastSurfer ohne `--no_biasfield` werden PV-corrected Stats berechnet, was extreme Werte glättet. Mit `--no_biasfield` können Edge-Strukturen 0-Volume haben (Voxel zu klein für Heuristik). Manuell prüfen.

## FreeSurfer-Label-LUT

FastSurfer-Stats nutzen die Standard-FreeSurfer-Label-IDs aus `FreeSurferColorLUT.txt`. Im FreeSurfer-Repo unter `$FREESURFER_HOME/FreeSurferColorLUT.txt`.

```python
def parse_lut(lut_path):
    """Returns dict: seg_id -> (name, r, g, b, a)"""
    lut = {}
    with open(lut_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split()
            if len(parts) >= 5:
                seg_id = int(parts[0])
                lut[seg_id] = (parts[1], int(parts[2]), int(parts[3]), int(parts[4]),
                               int(parts[5]) if len(parts) > 5 else 0)
    return lut

lut = parse_lut('/opt/freesurfer/FreeSurferColorLUT.txt')
print(lut[17])   # ('Left-Hippocampus', 220, 216, 20, 0)
```

## Cross-Reference

- Welche Stats wann erzeugt werden: Skill `fastsurfer-outputs`
- Slash-Command zum schnellen Browsen: `/fs-stats <sid>`
- Stats-Generation-Code: Skill `fastsurfer-internals` (`mri_segstats.py`, `segstats.py`)
- Custom-Training auf eigenen Stats-Labels: Skill `fastsurfer-checkpoints-models`
