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
| [icon] Skill (Z key) Lv.1  | ATK:  94        ||
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

## Tab 2: Traces (Skill Tree)

Visual node graph with branching diamond pattern. Nodes are unlocked with ahn.

### Layout
Mimics HSR's Traces layout — center column shows core abilities, branching lines connect stat boosts and bonus abilities on the sides.
```
+-----------------------------------------------+
| [Details] [Traces]            <- Tab bar       |
+-----------------------------------------------+
| Ahn: 5,000                                    |
+-----------------------------------------------+
|                                                |
|    [ATK+4%]----------[HP+4%]                   |
|       /                     \                  |
| [ReadyBattle]  [Basic Lv1]  [ATK+4%]          |
|       \        [Skill Lv1]  /                  |
|    [DEF+5%]----------[ATK+6%]                  |
|       /                     \                  |
| [Tenacity]     [Ult Lv1]    [HP+6%]           |
|       \        [Pass Lv1]   /                  |
|    [ATK+6%]----------[DEF+7.5%]               |
|       /                     \                  |
| [FightWill]                 [HP+8%]            |
|       \                     /                  |
|    [ATK+8%]                                    |
|                                                |
+-----------------------------------------------+
| Selected: ATK Boost                            |
| "ATK increases by 4%."                         |
| Cost: 200 Ahn | Requires: Ascension 2         |
| [Unlock]                                       |
+-----------------------------------------------+
```

### Implementation Approach
- Nodes positioned on a grid using `tree_x` and `tree_y`
- Render nodes with relative positioning in a container
- **Connection lines** drawn between nodes following the `connections` list:
  - Lines are thin styled divs or SVG paths connecting node centers
  - Lines follow the branching diamond pattern
- Core abilities shown in center column (non-interactive, just display level)
- Node styling:
  - **Unlocked**: highlighted color (green/gold)
  - **Available** (prereqs + ascension/level met, has ahn): normal color
  - **Locked** (prereqs not met or gate not reached): grayed out
  - **Bonus abilities**: larger icons than stat boosts
- Selected node details shown in panel below
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
      width: node.node_type === 'passive'
        ? LARGE_NODE + 'px' : SMALL_NODE + 'px',
    }}
    color={
      node.unlocked ? 'green'
        : canUnlock(node) ? '' : 'grey'
    }
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
    <Box>Cost: {selectedNodeData.ahn_cost} Ahn</Box>
    {selectedNodeData.required_ascension > 0 && (
      <Box>
        Requires: Ascension {selectedNodeData.required_ascension}
      </Box>
    )}
    {selectedNodeData.required_level > 0 && (
      <Box>
        Requires: Level {selectedNodeData.required_level}
      </Box>
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
