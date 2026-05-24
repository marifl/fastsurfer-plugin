---
name: fastsurfer-debug-license
description: Use when FastSurfer fails with FreeSurfer license errors, when the user asks how to install/test/troubleshoot the FreeSurfer license, or when the surface pipeline aborts early. Triggers on "FreeSurfer license", "license file not found", "license.txt", "FreeSurferLicense", "ERROR registering FreeSurfer", "fs_license", "surfer.nmr.mgh.harvard.edu", "license invalid".
---

# FastSurfer — FreeSurfer-Lizenz-Debug

Die **Surface-Pipeline** benötigt zwingend eine gültige FreeSurfer-Lizenz, weil sie FreeSurfer-Binaries (`mri_convert`, `mri_coreg`, `mri_mc`, `mri_tessellate`, `recon-all`-Steps) intern nutzt. Die **Segmentation-Pipeline** kann ohne Lizenz laufen — `--seg_only` ohne `--fs_license` ist OK.

## License besorgen

1. Registrieren unter: https://surfer.nmr.mgh.harvard.edu/registration.html (kostenlos, akademisch).
2. Per E-Mail erhältst du eine `license.txt`-Datei.
3. Lokal speichern, **absoluter Pfad** notieren.

Format der `license.txt` (4 Zeilen):

```
your-email@example.com
12345                     ← Subject-ID
*Ab1Cd2Ef3=               ← Key
FSh1jK2Lm3pQ              ← Hash
```

## Lizenz an FastSurfer geben

```bash
run_fastsurfer.sh ... --fs_license /abs/path/to/license.txt
```

Oder via Environment-Variable:

```bash
export FS_LICENSE=/abs/path/to/license.txt
run_fastsurfer.sh ...
```

`--fs_license` Flag überschreibt die Env-Var.

## Häufige Errors

### "ERROR: FreeSurfer license file not found"

**Diagnose:**

```bash
ls -la /abs/path/to/license.txt
file /abs/path/to/license.txt
```

**Häufige Ursachen:**
1. **Relativer Pfad** statt absoluter Pfad an `--fs_license`. → Pfad absolut machen.
2. **Datei existiert nicht** oder falscher Pfad. → `ls -la` checken.
3. **In Container nicht gemountet.** → `-v /host/path:/container/path` UND identischer Pfad bei `--fs_license`.

### "License is invalid"

**Diagnose:**

```bash
# Prüfe Inhalt der License
cat /abs/path/to/license.txt
```

Sollte 4 Zeilen sein (Email, Subject-ID, Key, Hash). Wenn weniger oder zusätzliche Whitespace/Umbrüche: License re-downloaden.

**Häufige Ursachen:**
1. **License-File via Email als HTML angekommen** und nicht als Plain-Text gespeichert. → re-downloaden von der Mail als Attachment.
2. **Line-Endings** (`\r\n` vs `\n`). → `dos2unix license.txt` oder neu mit `vi`/`nano` schreiben.
3. **License-Server hat dich blockiert** (zu viele Requests). → `support@nmr.mgh.harvard.edu` kontaktieren.

### "Could not find a copy of recon-all"

**Diagnose:**

```bash
echo $FREESURFER_HOME
ls $FREESURFER_HOME/bin/recon-all
which recon-all
```

**Häufige Ursachen:**
1. **FreeSurfer nicht installiert** (im nativen Workflow). → FreeSurfer von https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall installieren.
2. **FreeSurfer nicht gesourced.** → `source $FREESURFER_HOME/SetUpFreeSurfer.sh` vor dem FastSurfer-Call.
3. **Im Container fehlt FreeSurfer.** → Default `deepmi/fastsurfer:latest` hat FreeSurfer drin; eigenes Image-Build verifizieren.

### "FreeSurfer version not supported"

**Diagnose:**

```bash
cat $FREESURFER_HOME/build-stamp.txt   # zeigt installierte Version
grep -i "support" $FASTSURFER_HOME/recon_surf/recon-surf.sh | head -5
```

FastSurfer prüft die FreeSurfer-Version. Wenn deine Version zu alt/neu:
- **Upgrade/Downgrade** FreeSurfer auf supported Version (typisch 7.3.x oder 7.4.x).
- ODER **`--ignore_fs_version`** beim FastSurfer-Call setzen (auf eigene Gefahr).

### "Permission denied" auf License-File

Wenn die License nicht lesbar ist:

```bash
chmod 644 /abs/path/to/license.txt
```

In Container-Setups: User-Mismatch zwischen Host-Owner und Container-User. Fix: `--user $(id -u):$(id -g)` (Docker) oder License via root-readable Pfad ablegen.

## Container-Spezifika

### Docker

```bash
docker run --gpus all \
  -v /host/path/license.txt:/host/path/license.txt \   # identische Pfade
  ... \
  --fs_license /host/path/license.txt
```

ODER mit Conventional-Mount:

```bash
docker run --gpus all \
  -v /host/license_dir:/fs_license \
  ... \
  --fs_license /fs_license/license.txt
```

### Singularity

```bash
singularity exec --nv \
  -B /host/path/license.txt:/host/path/license.txt \
  fastsurfer.sif \
  /fastsurfer/run_fastsurfer.sh \
    --fs_license /host/path/license.txt ...
```

Beide Mount-Patterns funktionieren — wichtig ist dass der `--fs_license`-Pfad **container-intern** auf die gemountete Datei zeigt.

## Test-Aufruf (ohne FastSurfer)

Du kannst die License standalone testen indem du eine FreeSurfer-Binary direkt aufrufst:

```bash
source $FREESURFER_HOME/SetUpFreeSurfer.sh   # native
mri_convert --version
# Wenn das ohne License-Error läuft, ist die License ok.
```

Im Container:

```bash
docker run --rm \
  -v /host/license.txt:/host/license.txt \
  deepmi/fastsurfer:latest \
  bash -c "export FS_LICENSE=/host/license.txt; \
           source /opt/freesurfer/SetUpFreeSurfer.sh; \
           mri_convert --version"
```

## License-Probleme die NICHT an der License liegen

Manchmal wirkt ein Error wie ein License-Problem, ist aber etwas anderes:

- **"Could not write to /tmp/fs-XXX"**: Disk full oder Permissions auf /tmp. → `df -h /tmp`, `chmod 1777 /tmp`.
- **"DISPLAY not set"**: ein FreeSurfer-Step versucht GUI-Init. → meistens harmlos, manchmal `export DISPLAY=` setzen.
- **"talairach.xfm not found"**: Talairach-Step failed. → meistens nicht License-Issue sondern Image-Quality-Problem.

## Cross-Reference

- Wenn Surface-Pipeline crasht aber License OK: `fastsurfer-surface-recon` Sektion "Wenn Surface-Pipeline crasht"
- Container-Setup für License: `fastsurfer-container`
- Allgemeine Output-Validation: `fastsurfer-debug-outputs`
