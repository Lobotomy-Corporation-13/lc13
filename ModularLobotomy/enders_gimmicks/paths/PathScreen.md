# PathScreen.js - React TGUI Interface

## Purpose
The player-facing UI for viewing path details, stats, abilities, and the skill tree. Two tabs inspired by Honkai: Star Rail's character screen.

## Codebase Pattern Reference
Follows patterns from existing TGUI interfaces:
- `useBackend` / `useLocalState` from `'../backend'`
- Components: `Box`, `Button`, `Flex`, `LabeledList`, `ProgressBar`, `Section`, `Stack`, `Tabs` from `'../components'`
- `Window` from `'../layouts'`
- Tabs pattern from `SkillAugmentCatalogue.js`
- Max 80 chars per line (CLAUDE.md lint rule)

## Window
- Title: `"Path Screen"` (or dynamic path name)
- Size: `900 x 650`

---

## Tab 1: Details

Shows character stats, abilities, and resources.

### Layout
```
+-----------------------------------------------+
| [Details] [Skill Tree]          <- Tab bar     |
+-----------------------------------------------+
| Path Name: Destruction                         |
| "Focuses on dealing massive damage."           |
+-----------------------------+-----------------+|
| Abilities                   | Stats           ||
|                             |                 ||
| [icon] Basic Attack  Lv.2  | HP:   163       ||
| [icon] Burst Action  Lv.1  | ATK:  94        ||
| [icon] Ultimate      Lv.1  | DEF:  62        ||
| [icon] Passive       Lv.1  | CRIT Rate: 5%   ||
|                             | CRIT DMG: 50%   ||
|                             |                 ||
|                             | [More Stats v]  ||
|                             | Max Energy: 120 ||
|                             | Regen Rate: 100 ||
+-----------------------------+-----------------+|
| Energy: [====75/120=========]                  |
| AP: [*] [*] [*] [ ] [ ]   (3/5)              |
+-----------------------------+-----------------+|
| LC13 Attributes                                |
| FOR: 45 | PRU: 32 | TEM: 28 | JUS: 51        |
+-----------------------------------------------+
```

### Components
- **Path header**: `Section` with `title={path_name}`
- **Abilities panel**: `Section` with `LabeledList` showing 4 abilities with level
- **Stats panel**: `Section` with `LabeledList`, plus `Collapsible` for "More Stats"
- **Energy bar**: `ProgressBar` with `value={energy}` `maxValue={max_energy}`
- **AP display**: Row of `Box` elements styled as filled/empty pips
- **LC13 Attributes**: `LabeledList` at bottom for reference

---

## Tab 2: Skill Tree

Visual node graph for unlocking nodes.

### Layout
```
+-----------------------------------------------+
| [Details] [Skill Tree]          <- Tab bar     |
+-----------------------------------------------+
| Skill Points: 3                                |
+-----------------------------------------------+
|                                                |
|        [ATK+10]---[ATK+20]                     |
|            |                                   |
|       [Basic Lv2]---[Basic Lv3]                |
|            |                                   |
|        [DEF+5]    [CRT+2]---[CRT+3]           |
|            |          |                        |
|       [Burst Lv2] [Passive Lv2]               |
|                                                |
+-----------------------------------------------+
| Selected: ATK +20                              |
| "Increases ATK by 20."                         |
| Cost: 1 SP | Requires: ATK +10                |
| [Unlock]                                       |
+-----------------------------------------------+
```

### Implementation Approach
- Nodes positioned on a grid using `tree_x` and `tree_y` values
- Render nodes in a container with relative positioning
- Each node is a `Button` with conditional styling:
  - **Unlocked**: highlighted color (green/gold)
  - **Available** (prereqs met, has SP): normal color
  - **Locked** (prereqs not met): grayed out, dimmed
- Connections drawn between nodes using a simple approach:
  - For each node's `connections` list, draw a line element
  - Use CSS borders or a simple `Box` with background color
  - Alternatively, render connection lines as thin styled divs
- Selected node details shown in a panel below the tree
- `useLocalState` for `selectedNode` tracking

### Node Rendering (pseudo-JSX)
```jsx
{nodes.map(node => (
  <Button
    key={node.id}
    style={{
      position: 'absolute',
      left: (node.tree_x * GRID_SIZE) + 'px',
      top: (node.tree_y * GRID_SIZE) + 'px',
    }}
    color={node.unlocked ? 'green' : canUnlock(node) ? '' : 'grey'}
    selected={selectedNode === node.id}
    onClick={() => setSelectedNode(node.id)}
  >
    {node.name}
  </Button>
))}
```

### Selected Node Detail Panel
```jsx
{selectedNodeData && (
  <Section title={selectedNodeData.name}>
    <Box>{selectedNodeData.desc}</Box>
    <Box>Cost: {selectedNodeData.cost} SP</Box>
    {selectedNodeData.prerequisites.length > 0 && (
      <Box>Requires: {prereqNames.join(', ')}</Box>
    )}
    <Button
      content="Unlock"
      disabled={!canAffordAndUnlock}
      onClick={() => act('unlock_node', {
        node_id: selectedNodeData.id,
      })}
    />
  </Section>
)}
```

---

## Helper Functions

### `canUnlock(node, nodes, skillPoints)`
Client-side check: returns true if all prerequisites are in unlocked set and player has enough SP. Used for visual styling only; server validates on `ui_act`.

---

## Line Length Compliance
All lines must be <= 80 characters. Long JSX props should be broken across lines. Use short variable names where needed. Run lint check:
```bash
awk 'length > 80 {print NR": "length" chars: "$0}' PathScreen.js
```
