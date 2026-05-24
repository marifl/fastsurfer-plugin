---
name: fastsurfer-coordinates-3d
description: Use when the user is mapping FastSurfer/FreeSurfer outputs into a 3D engine (Three.js, React Three Fiber, WebGL, Babylon.js, Unity, Unreal, Blender), debugging Y-up vs Z-up issues, or converting between Scanner-RAS, tkRAS, LIA, and engine-specific coordinate frames. Triggers on "Three.js", "R3F", "react-three-fiber", "Y-up", "Z-up", "Blender import surface", "GLB from FastSurfer", "mesh wrong orientation in browser", "WebGL coordinate system", "convert tkRAS to Three.js", "FastSurfer surface to 3D engine".
---

# FastSurfer → 3D-Engines: Koordinatensystem-Konversion

Der grösste Fallstrick beim Import von FastSurfer-Outputs in 3D-Engines: **fünf verschiedene Koordinatenkonventionen** treffen aufeinander. Dieser Skill liefert die exakte Transform-Matrix für jede Kombination plus copy-paste-fähige Code-Snippets.

## Übersicht: Wer nutzt welches Frame?

| System | Axis-Konvention | Handedness | Anmerkung |
|--------|-----------------|------------|-----------|
| **Scanner-RAS** (NIfTI Default) | +X = Right, +Y = Anterior, +Z = Superior | right-handed | aus `vol.affine` (nibabel) |
| **FreeSurfer tkRAS** | wie RAS, aber Origin recentered | right-handed | aus `vol.header.get_vox2ras_tkr()` |
| **LIA Voxel-Order** | +i = Left, +j = Inferior, +k = Anterior | n/a (Voxel-Indizes) | interne Voxel-Reihenfolge in `orig.mgz` |
| **Three.js / WebGL** | +X = Right, +Y = **Up**, +Z = forward (out of screen) | right-handed | Three.js Default |
| **Blender** | +X = Right, +Y = forward, +Z = **Up** | right-handed | Blender Default |
| **Unity** | +X = Right, +Y = Up, +Z = forward | **left-handed** | Achtung: handedness Flip |
| **Unreal Engine** | +X = forward, +Y = Right, +Z = Up | **left-handed** | komplett umsortiert |

**Kerneinsicht:**

- **FreeSurfer-Welt** (RAS, tkRAS): **Y = anterior** (nach vorne aus dem Kopf raus).
- **Three.js / WebGL**: **Y = up** (nach oben). Anterior wird zu **Z** (oder **-Z**, je nach Konvention).
- Das ist eine **Rotation um die X-Achse** (90°), nicht nur ein Achsen-Swap.

## Die wichtigsten Konversionen

### A) FreeSurfer tkRAS → Three.js Y-up

Das ist der häufigste Fall: du hast `lh.pial` oder ein FastSurfer-aseg-Mesh exportiert und willst es in eine Three.js-Scene laden.

**Transform-Matrix (3x3 für Punkte):**

```
        FastSurfer-tkRAS         Three.js Y-up
          [x, y, z]                [x, z, -y]

Matrix:  [[ 1,  0,  0],         [x → x]
          [ 0,  0, -1],         [y → -z]
          [ 0,  1,  0]]         [z → y]
```

Das ist eine **Rotation um die X-Achse um -90°** (oder +90°, je nach Konvention).

#### Python (Vertices vor Export)

```python
import numpy as np
import nibabel.freesurfer as fs

verts, faces = fs.read_geometry("surf/lh.pial")  # verts shape: (N, 3) in tkRAS

# FastSurfer-tkRAS → Three.js Y-up
M = np.array([
    [1,  0,  0],
    [0,  0, -1],
    [0,  1,  0],
], dtype=np.float32)

verts_threejs = verts @ M.T   # (N, 3), wendet Rotation an

# Jetzt als GLB/glTF exportieren mit dem rotierten Vertex-Set.
```

#### Three.js (Mesh nach Import drehen)

Wenn du keine Möglichkeit hast die Vertices pre-export zu rotieren:

```javascript
import * as THREE from 'three';

const mesh = // your loaded FastSurfer mesh
mesh.rotation.x = -Math.PI / 2;   // -90° um X
mesh.updateMatrixWorld();
```

Oder als Group-Wrapper für mehrere Meshes:

```javascript
const fastSurferGroup = new THREE.Group();
fastSurferGroup.rotation.x = -Math.PI / 2;
fastSurferGroup.add(pialL, pialR, asegMesh);
scene.add(fastSurferGroup);
```

#### React Three Fiber

```jsx
<group rotation={[-Math.PI / 2, 0, 0]}>
  <Pial side="left" />
  <Pial side="right" />
  <AsegMesh />
</group>
```

### B) FreeSurfer tkRAS → Blender Z-up

Blender ist auch +Z-up — aber +Y = **forward** (nicht anterior). Bei FreeSurfer ist +Y anterior, was im Blender-Frame nach forward zeigt. Glück gehabt: **keine Rotation nötig**, FreeSurfer und Blender sind nahezu identisch.

```python
# In Blender Python:
import bpy
import numpy as np
import nibabel.freesurfer as fs

verts, faces = fs.read_geometry("surf/lh.pial")
# verts können direkt verwendet werden, kein Transform nötig.
```

**Caveat:** Wenn dein Blender-File später als GLB/glTF exportiert wird, macht Blender automatisch das Z-up→Y-up Convert (glTF-Standard ist Y-up). Dann ist der Mesh im Three.js wieder Y-up-konform.

### C) FreeSurfer tkRAS → glTF / GLB Standard

glTF nutzt **Y-up, right-handed** (gleicher Frame wie Three.js):

- Wenn du in **Blender** baust und als GLB exportierst → Blender macht den Convert automatisch (oder du setzt im Export-Dialog `+Y Up`).
- Wenn du **direkt via pygltflib** oder ähnlich aus Python exportierst → musst du selbst rotieren (siehe Konversion A).

### D) Scanner-RAS → FreeSurfer-tkRAS

Innerhalb der FreeSurfer-Welt: Scanner-RAS (NIfTI-`affine`) zu tkRAS (FreeSurfer-internal).

```python
import nibabel as nib
import numpy as np

vol = nib.load("mri/aseg.mgz")
affine = vol.affine                        # Scanner-RAS
tkras  = vol.header.get_vox2ras_tkr()      # tkRAS

# Wenn du einen Punkt im Scanner-RAS hast und nach tkRAS willst:
# point_tkras = tkras @ inv(affine) @ point_scanner_homog
M = tkras @ np.linalg.inv(affine)

# Wenn du Voxel-Indizes hast: direkt mit tkras multiplizieren
voxel = np.array([100, 120, 130, 1])
point_tkras = tkras @ voxel        # (4,) homogeneous, nimm [:3]

# Vertices aus surf/* sind BEREITS in tkRAS — kein affine-Convert nötig.
```

### E) LIA-Voxel-Order → tkRAS

Conformed Volumes (`mri/orig.mgz` etc.) sind 256³ in LIA-Voxel-Order:

- Voxel-Index `(i, j, k)`: +i = Left, +j = Inferior, +k = Anterior.
- Physische Position in tkRAS: `(x, y, z) = tkras @ (i, j, k, 1)`.

In der Praxis musst du das selten manuell machen — `nibabel`'s `vol.dataobj[i, j, k]` liest direkt aus dem Voxel-Grid, und `vol.header.get_vox2ras_tkr()` liefert dir die richtige Transform-Matrix zur physischen Welt.

## Vollständige Konversion-Tabelle

| Von ↓ / Nach → | Scanner-RAS | tkRAS | Three.js Y-up | Blender Z-up | glTF Y-up |
|---|---|---|---|---|---|
| **Scanner-RAS** | identity | `tkras @ inv(affine)` | `R_x(-90°) @ tkras @ inv(affine)` | `tkras @ inv(affine)` | wie Three.js |
| **tkRAS** | `affine @ inv(tkras)` | identity | `R_x(-90°)` | identity | wie Three.js |
| **Three.js Y-up** | `affine @ inv(tkras) @ R_x(+90°)` | `R_x(+90°)` | identity | `R_x(+90°)` | identity |
| **Blender Z-up** | wie tkRAS | identity | `R_x(-90°)` | identity | `R_x(-90°)` |
| **glTF Y-up** | wie Three.js | wie Three.js | identity | `R_x(+90°)` | identity |

`R_x(θ)` = Rotation um X-Achse:

```
R_x(θ) = [[1,         0,          0],
          [0,  cos(θ), -sin(θ)],
          [0,  sin(θ),  cos(θ)]]
```

`R_x(-90°)` (tkRAS → Three.js):
```
[[1,  0,  0],
 [0,  0,  1],
 [0, -1,  0]]
```

Auf homogene 4×4-Matrizen erweitern für Affine-Composition:

```python
def Rx(deg):
    import numpy as np
    rad = np.radians(deg)
    c, s = np.cos(rad), np.sin(rad)
    return np.array([
        [1, 0,  0, 0],
        [0, c, -s, 0],
        [0, s,  c, 0],
        [0, 0,  0, 1],
    ], dtype=np.float32)
```

## Common Bugs und Symptome

### Mesh ist "auf dem Bauch liegend" in Three.js

**Symptom:** FastSurfer-Mesh sieht aus als hätte das Hirn sich nach vorne gelegt — Top of head zeigt nach forward statt up.

**Ursache:** Vergessen, von tkRAS (Y=anterior) zu Three.js (Y=up) zu rotieren.

**Fix:** Konversion A anwenden (`R_x(-90°)`).

### Mesh ist gespiegelt (links/rechts vertauscht)

**Symptom:** Links-Hemisphäre erscheint rechts und umgekehrt.

**Ursache:** Eine versehentliche **left-handed** Konvention im Mix. Z.B.:
- Three.js `mesh.scale.x = -1` (Mirror).
- Unity-Import via FBX ohne Achsen-Konversion (Unity ist left-handed).
- glTF-Exporter mit falscher Handedness-Setting.

**Diagnose:**

```javascript
// Three.js: prüfe ob irgendwo negativ skaliert ist
console.log(mesh.matrixWorld.elements);
// Determinante < 0 = gespiegelt
import * as THREE from 'three';
const m = new THREE.Matrix3().setFromMatrix4(mesh.matrixWorld);
console.log('determinant:', m.determinant());   // sollte +1 sein
```

**Fix:** Skala-Korrektur entfernen oder einen Mirror-Transform addieren falls intended.

### Mesh ist 90° rotiert um Y oder Z

**Symptom:** Hirn zeigt seitlich statt nach forward.

**Ursache:** Falsche Rotation-Achse verwendet (z.B. `R_y(-90°)` statt `R_x(-90°)`).

**Fix:** Schau dir die Bounding-Box-Extents an:

```python
# Erwartete bbox in tkRAS (typischer Erwachsener):
# x: ca. -80 bis +80    (Left/Right)
# y: ca. -120 bis +90   (Posterior/Anterior)
# z: ca. -100 bis +100  (Inferior/Superior)
print(verts.min(0), verts.max(0))

# In Three.js-Y-up sollte gelten:
# x: ca. -80 bis +80    (Left/Right)
# y: ca. -100 bis +100  (Inferior/Superior → jetzt up/down)
# z: ca. -90 bis +120   (Anterior → forward, neg = back of head)
print(verts_threejs.min(0), verts_threejs.max(0))
```

Wenn z.B. die y-Range in Three.js -120 bis +90 ist statt -100 bis +100, dann hast du **nicht** rotiert.

### Mesh-Bbox geht durch die Decke

**Symptom:** Mesh fliegt 17.5mm zu weit anterior gegenüber anderen Layern.

**Ursache:** `vol.affine` (Scanner-RAS) statt `get_vox2ras_tkr()` benutzt. Siehe Skill `fastsurfer-debug-conform-tkras`.

**Fix:** Konsequent tkRAS verwenden für FastSurfer-Outputs.

## Three.js-spezifische Snippets

### FastSurfer-Surface direkt aus `.pial` (kein GLB-Roundtrip)

```javascript
import * as THREE from 'three';

async function loadFreeSurferSurface(url) {
  // Parse FreeSurfer Binary Format (custom, nicht built-in)
  // Idealerweise vorher zu glTF konvertieren via nibabel + pygltflib oder Blender.
  // Hier: Annahme du hast bereits Vertices + Faces als TypedArrays.
  const { verts, faces } = await parsePialBinary(url);

  // verts ist Float32Array in tkRAS. Rotate auf Y-up:
  const versThreejs = new Float32Array(verts.length);
  for (let i = 0; i < verts.length; i += 3) {
    versThreejs[i + 0] =  verts[i + 0];   // x → x
    versThreejs[i + 1] =  verts[i + 2];   // z → y  (vorher inferior/superior)
    versThreejs[i + 2] = -verts[i + 1];   // -y → z (vorher anterior/posterior)
  }

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.BufferAttribute(versThreejs, 3));
  geometry.setIndex(new THREE.BufferAttribute(faces, 1));
  geometry.computeVertexNormals();

  return new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ color: 0xc4a8aa }));
}
```

### Multi-Layer-Overlay (Pial + aseg-Volume)

```javascript
// Beide Layer brauchen den gleichen tkRAS → Y-up Transform.
// Daher: wrap in eine Group, einmal rotieren.
const fastSurferGroup = new THREE.Group();
fastSurferGroup.rotation.x = -Math.PI / 2;
fastSurferGroup.add(pialMesh, asegVolumeRenderer, ...);
scene.add(fastSurferGroup);
```

### Camera-Pose für coronal/sagittal/axial Views

In tkRAS bedeutet:
- **Coronal:** Camera entlang +Y (anterior) blickt nach -Y.
- **Sagittal:** Camera entlang +X (right) blickt nach -X.
- **Axial:** Camera entlang +Z (superior) blickt nach -Z.

Nach `R_x(-90°)` (tkRAS → Three.js Y-up):
- **Coronal:** Camera bei `(0, 0, -250)`, lookAt `(0, 0, 0)` (Z statt Y).
- **Sagittal:** Camera bei `(-250, 0, 0)`, lookAt `(0, 0, 0)` (X bleibt).
- **Axial:** Camera bei `(0, 250, 0)`, lookAt `(0, 0, 0)` (Y statt Z).

```javascript
const cameraPresets = {
  coronal:  { pos: [0, 0, -250], up: [0, 1, 0] },
  sagittal: { pos: [-250, 0, 0], up: [0, 1, 0] },
  axial:    { pos: [0, 250, 0],  up: [0, 0, -1] },
};

function setView(camera, preset) {
  camera.position.set(...cameraPresets[preset].pos);
  camera.up.set(...cameraPresets[preset].up);
  camera.lookAt(0, 0, 0);
}
```

### Diagnose: ist mein Mesh im richtigen Frame?

```javascript
// In Three.js dev-console
console.log('mesh bbox:', mesh.geometry.boundingBox);
mesh.geometry.computeBoundingBox();
const bb = mesh.geometry.boundingBox;
console.log('x range:', bb.min.x.toFixed(1), 'to', bb.max.x.toFixed(1));
console.log('y range:', bb.min.y.toFixed(1), 'to', bb.max.y.toFixed(1));
console.log('z range:', bb.min.z.toFixed(1), 'to', bb.max.z.toFixed(1));

// Erwartet (Three.js Y-up, typisch ein voller Hirn-Mesh):
// x: -80 bis +80
// y: -100 bis +100  (Y = up: vertex y=80 ist Top of Head)
// z: -90 bis +120   (Z = forward: vertex z=80 ist Vorderkopf/Stirn)
```

## Blender-spezifische Snippets

### FastSurfer-Surface in Blender importieren via Python

```python
import bpy
import bmesh
import numpy as np
import nibabel.freesurfer as fs

def import_fastsurfer_surface(path, name="pial"):
    verts, faces = fs.read_geometry(path)
    # Blender ist Z-up — gleicher Frame wie FreeSurfer (Y = forward für Blender,
    # Y = anterior für FreeSurfer → ist konsistent).
    # KEIN Transform nötig.

    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    bm_verts = [bm.verts.new(v) for v in verts]
    bm.verts.ensure_lookup_table()
    for face in faces:
        try:
            bm.faces.new([bm_verts[i] for i in face])
        except ValueError:
            pass   # duplicate face
    bm.to_mesh(mesh)
    bm.free()
    return obj

import_fastsurfer_surface("/path/to/lh.pial", "lh_pial")
import_fastsurfer_surface("/path/to/rh.pial", "rh_pial")
```

### Export aus Blender als GLB für Three.js

Standard glTF-Exporter macht den Z-up → Y-up Convert **automatisch** für gltf/glb:

```
File → Export → glTF 2.0 (.glb/.gltf)
  Transform → +Y Up ✓ (Default)
```

Resultat: GLB hat Vertices in Y-up Frame, kann direkt von Three.js geladen werden ohne weitere Rotation.

## Decision-Flow: welche Konversion brauche ich?

```
Hast du FastSurfer-Outputs (mgz, pial, etc.)?
├── Willst du sie in Three.js / WebGL / R3F?
│   └── tkRAS → Three.js Y-up:  R_x(-90°)
│       ├── Konversion vor Export in Python (verts @ M.T)?  ← empfohlen
│       ├── ODER nach Import: mesh.rotation.x = -Math.PI/2 ?
│       └── ODER: in Blender importieren + als GLB exportieren (auto Y-up)?
│
├── Willst du sie in Blender?
│   └── Direktimport, kein Transform nötig (Blender ist Z-up + Y=forward, kompatibel)
│
├── Willst du sie in Unity / Unreal?
│   └── Achtung: left-handed. Zusätzlich mirror eine Achse (Unity: Z; Unreal: Y).
│
└── Willst du sie nur in Python analysieren?
    └── Benutze tkRAS direkt (get_vox2ras_tkr).
        Wenn du Voxel-Indizes brauchst: voxel = inv(tkras) @ world_point.
```

## Cross-Reference

- tkRAS-vs-Scanner-RAS Bugs (17.5mm-Offset, 90°-Rotation): Skill `fastsurfer-debug-conform-tkras`
- Conformed-Space-Konzept (LIA, vox_size): Skill `fastsurfer-conform-space`
- Output-Files mit Frame-Annotation: Skill `fastsurfer-outputs`
- React Three Fiber Best-Practices: Skill `r3f-best-practices` (im superpowers-Plugin, falls installiert)
- glTF-Spec (Y-up Konvention): https://github.com/KhronosGroup/glTF/tree/main/specification/2.0
