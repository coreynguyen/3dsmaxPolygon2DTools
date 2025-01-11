# Godot Polygon2D & Skeleton2D Import/Export Maxscript

A Maxscript utility that helps **import** and **export** [Godot Engine 4.x](https://godotengine.org/) `.tscn` files containing **Polygon2D** and **Skeleton2D** data. This script is especially useful for:
- Converting 2D mesh data (with bones and weights) from a Godot `.tscn` into 3ds Max geometry and bone objects.
- Exporting polygon meshes with their corresponding bone weights from 3ds Max back into `.tscn` files for Godot.

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Functions](#functions)
   - [File I/O](#file-io-structure)
   - [TSCN Parsing](#tscn-parsing)
   - [TSCN Writing](#tscn-writing)
   - [Import Process](#import-process)
   - [Export Process](#export-process)
   - [Assorted Utility Functions](#assorted-utility-functions)
6. [Notes & Limitations](#notes--limitations)

---

## Overview
Godot’s `.tscn` (text-based scene) format can store 2D node hierarchies, including `Polygon2D`, `Skeleton2D`, and `Bone2D` structures. This script reads (or writes) those structures so you can:

- **Import** a `.tscn` into 3ds Max:
  - Generate 3D geometry out of 2D polygons (mapped into 3D coordinates).
  - Create bones and skeleton rigs based on `Skeleton2D` and `Bone2D` data.
  - Convert transforms and (optionally) apply UV transforms.
  - Apply 2D skeleton vertex weights to the new polygon objects as a Skin modifier.

- **Export** from 3ds Max to `.tscn`:
  - Collect any `Editable_Poly` or `Editable_Mesh` objects to generate `Polygon2D` data.
  - Gather bone and weight information from the Skin modifier and transform them into the text-based skeleton rig for Godot.
  - Output node transforms, rotation, bone angles, etc. in a `.tscn` format that Godot 4.x can read.

These workflows can be helpful if you want to:
- Quickly prototype 2D characters or levels in 3ds Max, then send them to Godot.
- Roundtrip from Godot to 3ds Max for more detailed editing of your 2D polygons or rigs.

---

## Features
- **Open / Save Buttons** in a custom rollout dialog for quick `.tscn` file manipulation.
- **Clear on Open** option to delete existing scene objects before importing.
- **Polygon2D Support**: Imports polygon data, UVs, and bone weights into 3ds Max. Exports them as well.
- **Skeleton2D / Bone2D Support**: Creates bone objects in 3ds Max, captures transforms, and exports them back to `.tscn`.
- **Automatic Parenting**: Reconstructs node hierarchy from the `.tscn` file in 3ds Max.
- **Geometry Reordering** for 2D engines: Offers methods to reorder or detect border vertices.
- **User Properties**: Stores relevant node information (e.g., texture paths, skeleton references) as 3ds Max User Properties for easy debugging.

---

## Installation
1. **Download or copy** the Maxscript (`.ms` or `.mcr`) file.
2. **Open 3ds Max**, then go to **Scripting > Run Script...** and choose the file.
3. A rollout/dialog named **“2D Mesh Tool”** should appear. Optionally, you can create a toolbar button or hotkey if you turn this into a MacroScript.

---

## Usage
1. **Click "Open .tscn"** to load a Godot text scene file:
   - Select a `.tscn` in the file dialog.
   - If **Clear on Open** is checked, it will delete all 3ds Max objects in your scene first.
   - The script parses the `.tscn` and reconstructs 2D polygons, skeletons, and bones in 3ds Max.

2. **Edit** or **Manipulate** objects in 3ds Max:
   - Move, rotate, or scale them.
   - Edit geometry, adjust weights via the Skin modifier, rename bones, etc.

3. **Click "Save .tscn"** to export:
   - By default, it tries to save to a `_new.tscn` file next to your last opened `.tscn`.
   - You can pick a new path in the file dialog.
   - The resulting `.tscn` includes all nodes, polygons, skeletons, and bone weights.

---

## Functions

### File I/O Structure
- **`open <file>`**  
  Reads a `.tscn` file into memory, populating the `entries` array with relevant nodes, parameters, and values.

- **`save <file>`**  
  Writes the current 3ds Max data (nodes, polygons, skeleton, etc.) out to `.tscn`.

### TSCN Parsing
- **`tscn.read f`**  
  Takes an open file stream and reads line-by-line. Creates data structures for each `[key param=...]` block or key-value pair.

- **`tscn.select <key>`**  
  Finds a key in the parsed data, sets it as `currentKeyIndex`.

- **`tscn.getValue <valueName>`**  
  Returns the value data from the current key’s entry. Particularly used to fetch `Polygon2D` attributes like `polygon`, `uv`, `bones`, etc.

- **`tscn.getParam <paramName>`**  
  Returns any parameter specified in the `[...]` bracket for a node—for instance, the `type` or `parent`.

### TSCN Writing
- **`tscn.write f`**  
  Iterates through the stored entries and writes them back into the `.tscn` text format.

- **`tscn.setKey <keyName>`**  
  Inserts (or moves to) a new `[keyName]` in the structure.

- **`tscn.setValue <keyName, valueName, newValue>`**  
  Adds or updates a key-value pair (like `rotation = 2.5`).

- **`tscn.setParam <keyName, paramName, newValue>`**  
  Adds or updates parameters for a `[keyName paramName=...]` bracket line.

### Import Process
- **`fn import()`**  
  - Clears the scene (if the checkbox is on).  
  - Loops over each parsed node in the `.tscn`.
  - If it’s a `Polygon2D`, creates a polygon object in 3ds Max:
    - Applies vertices, faces, and UV data.
    - Applies a Skin modifier if bone weight data is found.
    - Reconstructs transforms (position, rotation).
  - If it’s a `Skeleton2D`, creates a Dummy or other 3ds Max object to represent it.
  - If it’s a `Bone2D`, creates a Bone object in 3ds Max:
    - Sets length, rotation, position from Godot’s data.
  - Establishes hierarchy to match the Godot node’s `parent` structure.

### Export Process
- **`fn export()`**
  - Builds a fresh TSCN data structure (`tscn = f_TSCN()`).
  - Adds standard headers for `gd_scene`.
  - Collects external resources (like a texture) and assigns an `ext_resource` reference.
  - Examines each mesh (`Editable_Poly` or `Editable_Mesh`) in the scene:
    - Extracts geometry, UVs, Skin bones, and weights.
    - Reorders data for Godot’s 2D usage (border vertices first, internal last).
    - Outputs `[node ...]` entries with polygon data, uv, polygons, and bone weight arrays.
  - Collects bone data from any `BoneGeometry`, re-creates them as `Bone2D` entries with transforms.

### Assorted Utility Functions
- **`selectOuterBorderVertices obj threshold`**  
  Detects border edges in a mesh, sorts them, and returns a list to help reorder polygons (a typical operation for 2D polygon geometry).

- **`reorderMeshDataFor2DEngine_simple(...)`**  
  A simpler approach to sorting vertices so borders appear first—helpful for 2D shape engines.

- **`reorderMeshDataFor2DEngine(...)`**  
  More advanced method that tries to find and reorder border vertices according to a sorted path.

---

## Notes & Limitations
1. **Assumes Triangulated Polygons**: The importer expects polygons, but it’s easiest if your geometry is triangulated, especially if you rely on consistent indexing.
2. **One Texture**: The script primarily references a single texture in the `export` function (`Assets/atlas.png`). You may need to expand if you have multiple textures.
3. **Bone Parenting**: If your rig is complex, confirm the hierarchical approach is as expected in Godot. Sometimes multiple children or custom transform combos require manual tweaking.
4. **Transforms**: Rotation is handled via Y-axis rotation logic. Some 2D transformations or negative scales may cause unexpected flips; you might need to adapt them to your pipeline.

---

**Enjoy your 3ds Max–Godot 4.x pipeline!**
