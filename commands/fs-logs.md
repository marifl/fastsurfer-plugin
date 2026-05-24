---
description: Tail FastSurfer-Logfiles (deep-seg.log + recon-all.log) eines Subjects, sucht nach Errors.
allowed-tools: Bash, Read
argument-hint: "<sid> [--lines N] [--errors-only]"
---

Tail Logs für Subject `$ARGUMENTS`. Erkennt Errors automatisch.

## Pre-Flight

```bash
SID="<sid-from-args>"
LINES="${LINES:-100}"
SD="${SUBJECTS_DIR_OVERRIDE:-$SUBJECTS_DIR}"

SEG_LOG="$SD/$SID/scripts/deep-seg.log"
SURF_LOG="$SD/$SID/scripts/recon-all.log"

[ -f "$SEG_LOG" ] || echo "Hinweis: $SEG_LOG fehlt (Seg lief nicht?)"
[ -f "$SURF_LOG" ] || echo "Hinweis: $SURF_LOG fehlt (Surf lief nicht?)"
```

## Modus 1 — Tail beide Logs

```bash
echo "=== Segmentation-Log (last $LINES) ==="
[ -f "$SEG_LOG" ] && tail -n $LINES "$SEG_LOG"

echo ""
echo "=== Surface-Log (last $LINES) ==="
[ -f "$SURF_LOG" ] && tail -n $LINES "$SURF_LOG"
```

## Modus 2 — Errors-Only

Wenn User `--errors-only` mitgegeben hat:

```bash
echo "=== Errors / Failures ==="
for log in "$SEG_LOG" "$SURF_LOG"; do
  [ -f "$log" ] || continue
  echo ""
  echo "--- $(basename $log) ---"
  grep -iEn "error|fail|abort|fatal|cannot|traceback|exception" "$log" | tail -30
done
```

## Modus 3 — Live-Tail (für laufende Runs)

Wenn User `--follow` will:

```bash
# nur seg während Seg läuft, beide während Surf läuft
for log in "$SEG_LOG" "$SURF_LOG"; do
  [ -f "$log" ] && multitail "$log" &
done
# oder einfacher:
tail -f "$SEG_LOG" "$SURF_LOG" 2>/dev/null
```

## Step-Marker im Surface-Log

FreeSurfer-recon-all setzt `@#@` Marker zu Step-Beginn. Zeigt den zuletzt erreichten Step:

```bash
echo "=== Letzter Surface-Step ==="
grep "@#@" "$SURF_LOG" | tail -5
```

Wenn der letzte Step **nicht** `STAGES COMPLETED` oder ähnlich → Pipeline ist noch in diesem Step (laufend) oder abgebrochen.

## Häufige Error-Patterns

| Pattern | Bedeutung |
|---------|-----------|
| `CUDA out of memory` | GPU-OOM → siehe `fastsurfer-debug-gpu-memory` |
| `License invalid` / `not found` | License-Issue → `fastsurfer-debug-license` |
| `Permission denied` | Filesystem-Permission |
| `talairach failed` | Image-Quality oder Atlas-Mismatch |
| `mri_mc` Crash | WM-Surface-Generation failed |
| `pial surface` Crash | Pial-Generation failed |
| `Traceback (most recent call last)` | Python-Exception (meist Seg-Pipeline) |

## Cross-Reference

- Output-Validation: `/fs-outputs <SID>`
- Detail-Debug: Skills `fastsurfer-debug-license`, `fastsurfer-debug-outputs`, `fastsurfer-debug-gpu-memory`
