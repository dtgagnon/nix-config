---
name: obsidian-canvas
description: Create and manipulate Obsidian Canvas (.canvas) files using the JSON Canvas spec
argument-hint: <vault-name> [canvas description or path]
model: sonnet
---

# Obsidian Canvas - JSON Canvas Spec Reference

Create and edit `.canvas` files (JSON Canvas v1.0) for spatial thinking, flowcharts, mind maps, and knowledge graphs.

## Vault Resolution

Vaults root: `~/Apps/Obsidian/`

The first argument (`$ARGUMENTS`) identifies the vault. Extract the vault name from the first word/token — it is a subdirectory of the vaults root. The remaining arguments describe what to create or which canvas to modify.

- **Resolve the vault path**: `~/Apps/Obsidian/<vault-name>/`
- **List available vaults**: `ls ~/Apps/Obsidian/` if the user's vault name doesn't match
- **Canvas files** live anywhere inside the vault (commonly at the root or in a subfolder). Use glob search to find existing `.canvas` files when editing.
- **File node paths** in canvas JSON are vault-relative (e.g., `"Notes/topic.md"` not absolute paths).

## Top-Level Structure

```json
{
  "nodes": [],
  "edges": []
}
```

Both arrays are optional. An empty `{}` is valid. Nodes are ordered by ascending z-index (first = bottom, last = top).

## Node Types

### Universal Properties (all nodes)

| Property | Type    | Required | Description                        |
|----------|---------|----------|------------------------------------|
| `id`     | string  | yes      | Unique identifier (16-char hex)    |
| `type`   | string  | yes      | `"text"`, `"file"`, `"link"`, `"group"` |
| `x`      | integer | yes      | X position in pixels               |
| `y`      | integer | yes      | Y position in pixels               |
| `width`  | integer | yes      | Width in pixels                    |
| `height` | integer | yes      | Height in pixels                   |
| `color`  | string  | no       | Preset `"1"`-`"6"` or hex `"#RRGGBB"` |

### Text Node

```json
{
  "id": "a1b2c3d4e5f6a7b8",
  "type": "text",
  "x": 0, "y": 0, "width": 400, "height": 200,
  "text": "# Heading\n\nMarkdown content with **bold** and *italic*."
}
```

Additional: `text` (string, required) — Markdown-formatted content.

### File Node

```json
{
  "id": "b2c3d4e5f6a7b8c9",
  "type": "file",
  "x": 500, "y": 0, "width": 400, "height": 300,
  "file": "Notes/my-note.md",
  "subpath": "#Section Name"
}
```

Additional: `file` (string, required) — vault-relative path. `subpath` (string, optional) — heading/block link, starts with `#`.

### Link Node

```json
{
  "id": "c3d4e5f6a7b8c9d0",
  "type": "link",
  "x": 0, "y": 300, "width": 400, "height": 200,
  "url": "https://example.com"
}
```

Additional: `url` (string, required) — external URL.

### Group Node

```json
{
  "id": "d4e5f6a7b8c9d0e1",
  "type": "group",
  "x": -50, "y": -50, "width": 1000, "height": 600,
  "label": "Phase 1",
  "background": "assets/texture.png",
  "backgroundStyle": "cover"
}
```

Additional: `label` (string, optional), `background` (string, optional — image path), `backgroundStyle` (string, optional — `"cover"`, `"ratio"`, or `"repeat"`).

Group membership is implicit via spatial containment — no parent/children properties. Place groups before their contained nodes in the array (lower z-index).

## Edges

| Property   | Type   | Required | Description                              |
|------------|--------|----------|------------------------------------------|
| `id`       | string | yes      | Unique identifier (16-char hex)          |
| `fromNode` | string | yes      | Source node ID                           |
| `fromSide` | string | no       | `"top"`, `"right"`, `"bottom"`, `"left"` |
| `fromEnd`  | string | no       | `"none"` (default) or `"arrow"`          |
| `toNode`   | string | yes      | Target node ID                           |
| `toSide`   | string | no       | `"top"`, `"right"`, `"bottom"`, `"left"` |
| `toEnd`    | string | no       | `"arrow"` (default) or `"none"`          |
| `color`    | string | no       | Same color format as nodes               |
| `label`    | string | no       | Text displayed along the edge            |

Default: one-way arrow (fromEnd=none, toEnd=arrow). Set both to `"arrow"` for bidirectional, both to `"none"` for plain line.

```json
{
  "id": "e5f6a7b8c9d0e1f2",
  "fromNode": "a1b2c3d4e5f6a7b8",
  "fromSide": "right",
  "toNode": "b2c3d4e5f6a7b8c9",
  "toSide": "left",
  "label": "relates to"
}
```

## Color Presets

| Value | Color  |
|-------|--------|
| `"1"` | Red    |
| `"2"` | Orange |
| `"3"` | Yellow |
| `"4"` | Green  |
| `"5"` | Cyan   |
| `"6"` | Purple |

Or use hex: `"#FF6B6B"`. Omit `color` for the default/neutral color.

## ID Generation

Use 16-character random lowercase hex strings: `"a1b2c3d4e5f6a7b8"`. Each ID must be unique within the canvas. Generate fresh IDs for every node and edge.

## Layout Guidelines

### Recommended Node Sizes

| Content Type       | Width | Height |
|--------------------|-------|--------|
| Short text card    | 250   | 120    |
| Standard text node | 400   | 200    |
| Detailed text node | 500   | 300    |
| File embed         | 400   | 300    |
| Link preview       | 350   | 200    |
| Small group        | 600   | 400    |
| Large group        | 1200  | 800    |

### Spacing

- **Gap between nodes**: 80-120px
- **Gap between rows**: 100-150px
- **Group padding**: 50px on each side beyond contained nodes
- **Starting position**: (0, 0) for the first node, expand outward

### Layout Patterns

**Horizontal flow (left to right)**:
```
x: 0      x: 520    x: 1040
y: 0      y: 0      y: 0
[Node A] --> [Node B] --> [Node C]
```

**Vertical flow (top to bottom)**:
```
x: 0, y: 0      [Node A]
x: 0, y: 320    [Node B]
x: 0, y: 640    [Node C]
```

**Grid (rows and columns)**:
```
(0,0)    (520,0)    (1040,0)
(0,320)  (520,320)  (1040,320)
```

**Radial (center + surrounding)**:
Place the central node at (0, 0), then arrange related nodes in a circle at radius ~400px.

## Common Canvas Patterns

### Flowchart

Horizontal or vertical sequence of text nodes connected by edges. Use `fromSide`/`toSide` to control routing. Color-code by status or category.

### Mind Map

Central topic node with radiating branches. Use group nodes to cluster related branches. Edges from center outward, no `fromSide`/`toSide` needed (auto-routed).

### Knowledge Graph

Mix of file nodes (existing notes) and text nodes (annotations) with labeled edges describing relationships. Use color to distinguish node roles.

### Project Board

Columns as group nodes side by side. Task cards as text nodes inside each group. Move cards between groups by updating x/y coordinates.

```json
{
  "nodes": [
    {"id": "g1", "type": "group", "x": 0, "y": 0, "width": 300, "height": 600, "label": "To Do", "color": "1"},
    {"id": "g2", "type": "group", "x": 380, "y": 0, "width": 300, "height": 600, "label": "In Progress", "color": "3"},
    {"id": "g3", "type": "group", "x": 760, "y": 0, "width": 300, "height": 600, "label": "Done", "color": "4"},
    {"id": "t1", "type": "text", "x": 25, "y": 50, "width": 250, "height": 100, "text": "Task one"},
    {"id": "t2", "type": "text", "x": 405, "y": 50, "width": 250, "height": 100, "text": "Task two"}
  ],
  "edges": []
}
```

## Complete Example

```json
{
  "nodes": [
    {
      "id": "d4e5f6a7b8c9d0e1",
      "type": "group",
      "x": -50,
      "y": -50,
      "width": 1100,
      "height": 500,
      "label": "Research",
      "color": "5"
    },
    {
      "id": "a1b2c3d4e5f6a7b8",
      "type": "text",
      "x": 0,
      "y": 0,
      "width": 400,
      "height": 200,
      "color": "4",
      "text": "# Overview\n\nStarting point for the research project."
    },
    {
      "id": "b2c3d4e5f6a7b8c9",
      "type": "file",
      "x": 520,
      "y": 0,
      "width": 400,
      "height": 300,
      "file": "Notes/literature-review.md",
      "subpath": "#Key Findings"
    },
    {
      "id": "c3d4e5f6a7b8c9d0",
      "type": "link",
      "x": 0,
      "y": 300,
      "width": 350,
      "height": 200,
      "url": "https://arxiv.org/abs/example"
    }
  ],
  "edges": [
    {
      "id": "e5f6a7b8c9d0e1f2",
      "fromNode": "a1b2c3d4e5f6a7b8",
      "fromSide": "right",
      "toNode": "b2c3d4e5f6a7b8c9",
      "toSide": "left",
      "label": "see also"
    },
    {
      "id": "f6a7b8c9d0e1f2a3",
      "fromNode": "a1b2c3d4e5f6a7b8",
      "fromSide": "bottom",
      "toNode": "c3d4e5f6a7b8c9d0",
      "toSide": "top",
      "fromEnd": "arrow",
      "toEnd": "arrow"
    }
  ]
}
```

## Tips

- Coordinates can be negative — the canvas is infinite in all directions
- Omit `fromSide`/`toSide` on edges to let Obsidian auto-route them
- Keep text node content concise; link to full notes with file nodes instead
- When editing an existing canvas, preserve all existing IDs and unknown properties
- Groups must appear before their contained nodes in the array for correct z-ordering
