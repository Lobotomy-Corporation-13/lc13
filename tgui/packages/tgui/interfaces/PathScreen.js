import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Flex,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

// Tree dimensions
const TREE_W = 400;
const TREE_H = 500;
const CX = TREE_W / 2; // center X = 200

// Node sizes
const SM = 22;  // small stat circles
const MED = 32; // bonus ability circles
const CORE = 48; // core ability icons

// Positions match HSR's vertical oval:
//
//       (s)-------(s)
//      / |         | \
//   (B1) |  [Pass] | (s)
//      \ |         | /
//       (s) [Ult][Skl] (s)
//      / |         | \
//   (B2) |         | (s)
//      \ | [Basic] | /
//       (s)-------(s)
//      / |           \
//   (B3) |           (s)
//        (s)
//
// Core = large rounded rect in center
// s = small stat circle on oval ring
// B = bonus ability (medium circle)
//
const NODE_POS = {
  // Core abilities (vertical stack, center)
  'core_passive':  { x: CX, y: 100 },
  'core_ultimate': { x: CX - 55, y: 200 },
  'core_burst':    { x: CX + 55, y: 200 },
  'core_basic':    { x: CX, y: 310 },

  // Stat + bonus nodes on oval ring
  // -- Top pair --
  'atk1': { x: CX - 70, y: 35 },
  'hp1':  { x: CX + 70, y: 35 },

  // -- Upper sides --
  'bonus_a2': { x: 30,         y: 115 },
  'atk2':     { x: TREE_W - 30, y: 115 },

  // -- Mid sides (widest point) --
  'def1': { x: 25,          y: 210 },
  'atk3': { x: TREE_W - 25, y: 210 },

  // -- Lower sides --
  'bonus_a4': { x: 30,         y: 305 },
  'hp2':      { x: TREE_W - 30, y: 305 },

  // -- Bottom pair --
  'atk4': { x: CX - 70, y: 395 },
  'def2': { x: CX + 70, y: 395 },

  // -- Lower outer --
  'bonus_a6': { x: 50,          y: 405 },
  'hp3':      { x: TREE_W - 50, y: 405 },

  // -- Very bottom --
  'atk5': { x: CX, y: 470 },
};

export const PathScreen = (props, context) => {
  const { data } = useBackend(context);
  const [tab, setTab] = useLocalState(
    context, 'tab', 0
  );
  return (
    <Window
      title={data.path_name || 'Path Screen'}
      width={700}
      height={650}>
      <Window.Content scrollable>
        <Tabs fluid>
          <Tabs.Tab
            selected={tab === 0}
            onClick={() => setTab(0)}>
            Details
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 1}
            onClick={() => setTab(1)}>
            Traces
          </Tabs.Tab>
        </Tabs>
        {tab === 0 && <DetailsTab />}
        {tab === 1 && <TracesTab />}
      </Window.Content>
    </Window>
  );
};

// ==============================
// Details Tab
// ==============================

const DetailsTab = (props, context) => {
  const { data } = useBackend(context);
  const {
    path_name = '', path_desc = '',
    element_type = '',
    energy = 0, max_energy = 100,
    action_points = 0,
    max_action_points = 5,
    path_level = 1, ascension_phase = 0,
    turn_state = 0,
    turn_duration = 5,
    turn_remaining = 0,
    stats = {},
    abilities = [],
    lc13_attributes = {},
    player_ahn = 0,
  } = data;
  const turnNames = [
    'READY', 'ATTACKED', 'SKILLED',
  ];
  const [subTab, setSubTab] = useLocalState(
    context, 'detailSub', 0
  );
  const primary = ['HP', 'ATK', 'DEF', 'SPD'];
  const secondary = Object.keys(stats).filter(
    s => !primary.includes(s)
  );
  return (
    <Stack vertical>
      <Stack.Item>
        <Section>
          <Stack>
            <Stack.Item grow>
              <Box fontSize="18px" bold>
                {path_name}
              </Box>
              <Box color="label" mt={0.5}>
                Lv. {path_level}
                {' / A'}{ascension_phase}
                {' \u2022 '}{element_type}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box color="label"
                textAlign="right">
                Ahn: {player_ahn}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Tabs fluid>
          <Tabs.Tab
            selected={subTab === 0}
            onClick={() => setSubTab(0)}>
            Stats
          </Tabs.Tab>
          <Tabs.Tab
            selected={subTab === 1}
            onClick={() => setSubTab(1)}>
            Abilities
          </Tabs.Tab>
        </Tabs>
      </Stack.Item>
      {subTab === 0 && (
        <Stack.Item>
          <Section>
            <LabeledList>
              {primary.map(s => (
                <LabeledList.Item
                  key={s} label={s}>
                  <Box inline bold>
                    {stats[s] || 0}
                  </Box>
                </LabeledList.Item>
              ))}
            </LabeledList>
            {secondary.length > 0 && (
              <Collapsible title="More Stats">
                <LabeledList>
                  {secondary.map(s => (
                    <LabeledList.Item
                      key={s} label={s}>
                      {stats[s] || 0}
                      {(s.includes('Rate')
                        || s.includes('DMG'))
                        ? '%' : ''}
                    </LabeledList.Item>
                  ))}
                </LabeledList>
              </Collapsible>
            )}
          </Section>
        </Stack.Item>
      )}
      {subTab === 1 && (
        <Stack.Item>
          <Section>
            {abilities.map(a => (
              <Box key={a.type} mb={1}>
                <Box bold>
                  {a.name}
                  <Box inline color="label"
                    ml={1}>
                    Lv.{a.level}/{a.max_level}
                  </Box>
                </Box>
                <Box color="grey"
                  fontSize="12px" mt={0.3}>
                  {a.desc}
                </Box>
              </Box>
            ))}
          </Section>
        </Stack.Item>
      )}
      <Stack.Item>
        <Section>
          <Box mb={0.5}>
            <ProgressBar
              value={energy}
              maxValue={max_energy}
              color="blue">
              Energy {energy}/{max_energy}
            </ProgressBar>
          </Box>
          <Flex align="center">
            <Flex.Item grow>
              AP:{' '}
              {Array.from(
                { length: max_action_points },
                (_, i) => (
                  <Box key={i} inline mr={0.3}
                    color={i < action_points
                      ? 'green' : 'grey'}
                    bold>
                    {i < action_points
                      ? '\u25C9' : '\u25CB'}
                  </Box>
                )
              )}
            </Flex.Item>
            <Flex.Item>
              <Box
                color={turn_state === 0
                  ? 'green' : 'average'}
                fontSize="12px">
                {turnNames[turn_state] || '?'}
                {turn_remaining > 0
                  && (' ' + turn_remaining
                    + 's')}
              </Box>
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="LC13 Attributes">
          <Flex>
            {Object.keys(lc13_attributes).map(
              a => (
                <Flex.Item
                  key={a} grow basis={0}>
                  <Box inline color="label">
                    {a.substring(0, 3)}:
                  </Box>
                  {' '}{lc13_attributes[a]}
                </Flex.Item>
              )
            )}
          </Flex>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

// ==============================
// Traces Tab
// ==============================

const canUnlock = (node, data) => {
  if (node.unlocked) return false;
  const {
    nodes, player_ahn,
    ascension_phase, path_level,
  } = data;
  if (node.required_ascension > 0
    && ascension_phase
      < node.required_ascension) {
    return false;
  }
  if (node.required_level > 0
    && path_level < node.required_level) {
    return false;
  }
  if (player_ahn < node.ahn_cost) {
    return false;
  }
  for (const pid of node.prerequisites) {
    const pn = nodes.find(n => n.id === pid);
    if (pn && !pn.unlocked) return false;
  }
  return true;
};

const TracesTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    nodes = [], player_ahn = 0,
  } = data;
  const [selId, setSelId] = useLocalState(
    context, 'selNode', null
  );
  const sel = nodes.find(n => n.id === selId);

  return (
    <Stack fill>
      <Stack.Item grow>
        <Stack vertical fill>
          <Stack.Item>
            <Section>
              <Flex justify="space-between">
                <Flex.Item bold>
                  Traces
                </Flex.Item>
                <Flex.Item color="label">
                  Ahn: {player_ahn}
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill>
              <Box
                position="relative"
                style={{
                  width: TREE_W + 'px',
                  height: TREE_H + 'px',
                  margin: '0 auto',
                }}>
                <TreeLines nodes={nodes} />
                {nodes.map(n => {
                  const pos = NODE_POS[n.id];
                  if (!pos) return null;
                  return (
                    <TraceNode
                      key={n.id}
                      node={n}
                      x={pos.x}
                      y={pos.y}
                      data={data}
                      selected={
                        selId === n.id
                      }
                      onSelect={
                        () => setSelId(n.id)
                      }
                    />
                  );
                })}
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      {sel && (
        <Stack.Item basis="220px">
          <NodeDetail
            node={sel}
            data={data}
            onUnlock={() => act(
              'unlock_node',
              { node_id: sel.id }
            )}
            onClose={
              () => setSelId(null)
            }
          />
        </Stack.Item>
      )}
    </Stack>
  );
};

// Trace node (stat, bonus, or core ability)
const TraceNode = props => {
  const {
    node, x, y, data,
    selected, onSelect,
  } = props;
  const isBonus = node.node_type === 'passive';
  const isCore = node.node_type === 'ability';
  const sz = isCore ? CORE
    : (isBonus ? MED : SM);
  const unlockable = canUnlock(node, data);

  // Styling by type
  let bg, brd;
  if (isCore) {
    bg = 'rgba(30,50,90,0.85)';
    brd = '2px solid rgba(80,130,220,0.7)';
  } else if (node.unlocked) {
    bg = 'rgba(40,160,40,0.8)';
    brd = '2px solid rgba(80,220,80,0.9)';
  } else if (unlockable) {
    bg = 'rgba(50,50,70,0.9)';
    brd = '2px solid rgba(120,160,255,0.7)';
  } else {
    bg = isBonus
      ? 'rgba(70,70,70,0.7)'
      : 'rgba(90,90,90,0.6)';
    brd = '2px solid rgba(100,100,100,0.5)';
  }
  if (selected) {
    brd = '2px solid rgba(255,220,60,1)';
  }

  // Label by type
  let label = '';
  let fontSize = '7px';
  if (isCore) {
    // Find matching ability for level
    const ab = (data.abilities || []).find(
      a => node.ability_target === a.type
    );
    label = node.name.length > 11
      ? node.name.substring(0, 10) + '.'
      : node.name;
    if (ab) {
      label += '\nLv.' + ab.level;
    }
    fontSize = '9px';
  } else if (isBonus) {
    label = node.name.length > 8
      ? node.name.substring(0, 7) + '.'
      : node.name;
    fontSize = '8px';
  } else if (node.stat_bonuses) {
    const k = Object.keys(
      node.stat_bonuses
    );
    if (k.length > 0) {
      label = k[0].substring(0, 3);
    }
  }

  return (
    <Box
      style={{
        position: 'absolute',
        left: (x - sz / 2) + 'px',
        top: (y - sz / 2) + 'px',
        width: sz + 'px',
        height: sz + 'px',
        background: bg,
        border: brd,
        borderRadius: isCore
          ? '12px' : '50%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        fontSize: fontSize,
        color: 'white',
        textAlign: 'center',
        lineHeight: '1.2',
        userSelect: 'none',
        whiteSpace: 'pre-line',
      }}
      onClick={onSelect}>
      {label}
    </Box>
  );
};

// Connection lines between trace nodes
// SVG-based connection lines for clean
// rendering at any angle
const TreeLines = props => {
  const { nodes } = props;
  const svgLines = [];
  nodes.forEach(n => {
    if (!n.connections) return;
    const p1 = NODE_POS[n.id];
    if (!p1) return;
    n.connections.forEach(cid => {
      const p2 = NODE_POS[cid];
      if (!p2) return;
      const t = nodes.find(
        nd => nd.id === cid
      );
      const both = n.unlocked
        && t && t.unlocked;
      const col = both
        ? 'rgba(80,220,80,0.6)'
        : 'rgba(140,140,140,0.35)';
      svgLines.push(
        <line
          key={n.id + '_' + cid}
          x1={p1.x}
          y1={p1.y}
          x2={p2.x}
          y2={p2.y}
          stroke={col}
          strokeWidth="2"
        />
      );
    });
  });
  return (
    <svg
      style={{
        position: 'absolute',
        left: 0,
        top: 0,
        width: TREE_W + 'px',
        height: TREE_H + 'px',
        pointerEvents: 'none',
      }}>
      {svgLines}
    </svg>
  );
};

// Side panel for selected node
const NodeDetail = props => {
  const {
    node, data, onUnlock, onClose,
  } = props;
  const unlockable = canUnlock(node, data);

  let typeLabel = 'Stat Boost';
  let isRepeatable = false;
  if (node.node_type === 'passive') {
    typeLabel = 'Bonus Ability';
  } else if (node.node_type === 'ability') {
    typeLabel = 'Ability Upgrade';
    isRepeatable = true;
  }
  // Find ability level for core nodes
  let abilityInfo = null;
  if (node.node_type === 'ability'
    && node.ability_target) {
    const ab = (data.abilities || []).find(
      a => a.type === node.ability_target
    );
    if (ab) {
      abilityInfo = ab;
    }
  }

  // Effect text
  let effectText = node.desc;
  if (node.node_type === 'stat'
    && node.stat_bonuses) {
    const parts = [];
    for (const s in node.stat_bonuses) {
      const v = node.stat_bonuses[s];
      parts.push(
        s + ' +'
        + v + (node.stat_percent ? '%' : '')
      );
    }
    effectText = parts.join(', ');
  }

  // Requirements
  const reqs = [];
  if (node.required_ascension > 0) {
    reqs.push(
      'Ascension '
      + node.required_ascension
    );
  }
  if (node.required_level > 0) {
    reqs.push(
      'Level ' + node.required_level
    );
  }
  if (node.prerequisites
    && node.prerequisites.length > 0) {
    const names = node.prerequisites.map(
      pid => {
        const pn = data.nodes.find(
          n => n.id === pid
        );
        return pn ? pn.name : pid;
      }
    );
    reqs.push(
      'Unlock: ' + names.join(', ')
    );
  }

  return (
    <Section
      title={node.name}
      fill
      buttons={
        <Button
          icon="times"
          onClick={onClose}
        />
      }>
      <Stack vertical>
        <Stack.Item>
          <Box color="label"
            fontSize="11px" mb={1}>
            {typeLabel}
            {isRepeatable
              && ' \u2022 Repeatable'}
          </Box>
          {abilityInfo && (
            <Box mb={1}>
              <Box bold color="label"
                fontSize="11px">
                Current Level
              </Box>
              <Box fontSize="14px" bold>
                Lv.{abilityInfo.level}
                /{abilityInfo.max_level}
              </Box>
              {abilityInfo.level
                >= abilityInfo.max_level && (
                <Box color="green"
                  fontSize="11px">
                  MAX LEVEL
                </Box>
              )}
            </Box>
          )}
        </Stack.Item>
        <Stack.Item>
          <Box bold mb={0.5}>Effect</Box>
          <Box fontSize="13px">
            {effectText}
          </Box>
        </Stack.Item>
        <Stack.Item mt={1}>
          <Box bold mb={0.5}>Cost</Box>
          <Box
            color={
              data.player_ahn >= node.ahn_cost
                ? 'green' : 'bad'
            }
            fontSize="13px">
            {node.ahn_cost} Ahn
          </Box>
          <Box color="label" fontSize="11px">
            You have: {data.player_ahn}
          </Box>
        </Stack.Item>
        {reqs.length > 0 && (
          <Stack.Item mt={1}>
            <Box bold mb={0.5}>
              Requirements
            </Box>
            {reqs.map((r, i) => (
              <Box key={i} color="label"
                fontSize="12px">
                \u2022 {r}
              </Box>
            ))}
          </Stack.Item>
        )}
        <Stack.Item mt={1.5}>
          {node.unlocked ? (
            <Box textAlign="center"
              color="green" bold
              fontSize="14px">
              \u2713 Unlocked
            </Box>
          ) : (
            <Button
              fluid
              textAlign="center"
              content="Unlock"
              disabled={!unlockable}
              color={unlockable
                ? 'green' : 'grey'}
              onClick={onUnlock}
            />
          )}
        </Stack.Item>
        {!unlockable && !node.unlocked && (
          <Stack.Item mt={0.5}>
            <Box color="bad"
              fontSize="11px"
              textAlign="center">
              {data.player_ahn
                < node.ahn_cost
                ? 'Not enough Ahn'
                : 'Requirements not met'}
            </Box>
          </Stack.Item>
        )}
      </Stack>
    </Section>
  );
};
