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
const TREE_W = 550;
const TREE_H = 530;
const CX = TREE_W / 2;

// Node sizes (circles — equal width and height)
const STAT_W = 30;
const STAT_H = 30;
const BONUS_W = 36;
const BONUS_H = 36;
const CORE_W = 44;
const CORE_H = 44;

// Layout matches 3-branch tree:
//
//  [s]       [s]  [s]       [s]
//   |         \  /           |
//  [s]       [Bonus]       [s]
//   |           |           |
//  [s]       [Ult]        [s]
//   |           |           |
// [Bonus]   [Pass]      [Bonus]
//     \      / | \       /
//    [Basic]  [s] [Skill]
//
const NODE_POS = {
  // Bottom stat (below Passive)
  'stat_bottom': { x: CX, y: 490 },

  // Core abilities (bottom row)
  'core_basic':
    { x: 155, y: 400 },
  'core_passive':
    { x: CX, y: 400 },
  'core_burst':
    { x: 395, y: 400 },

  // Middle row
  'bonus_a6':
    { x: 68, y: 325 },
  'core_ultimate':
    { x: CX, y: 290 },
  'bonus_a4':
    { x: 478, y: 325 },

  // Left branch (up from bonus_a6)
  'stat_l1': { x: 55, y: 248 },
  'stat_l2': { x: 48, y: 175 },
  'stat_l3': { x: 68, y: 78 },

  // Center branch (up from bonus_a2)
  'bonus_a2':
    { x: CX, y: 195 },
  'stat_c1': { x: CX, y: 115 },
  'stat_c2': { x: 210, y: 40 },
  'stat_c3': { x: 340, y: 40 },

  // Right branch (up from bonus_a4)
  'stat_r1': { x: 462, y: 248 },
  'stat_r2': { x: 468, y: 175 },
  'stat_r3': { x: 478, y: 78 },
};

export const PathScreen = (props, context) => {
  const { data } = useBackend(context);
  const [tab, setTab] = useLocalState(
    context, 'tab', 0
  );
  return (
    <Window
      title={data.path_name || 'Path Screen'}
      width={820}
      height={680}>
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
    path_exp = 0,
    exp_at_level = 0, exp_to_next = 0,
    turn_state = 0,
    turn_duration = 5,
    turn_remaining = 0,
    stats = {},
    abilities = [],
    lc13_attributes = {},
    player_ahn = 0,
    allies = [],
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
      && s !== 'DMG Reduction'
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
                {' - '}{element_type}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box color="label"
                textAlign="right">
                Ahn: {player_ahn}
              </Box>
            </Stack.Item>
          </Stack>
          {path_level < 80 ? (
            <Box mt={0.5}>
              <ProgressBar
                value={
                  path_exp - exp_at_level
                }
                maxValue={
                  exp_to_next || 1
                }
                color="purple">
                EXP{' '}
                {path_exp - exp_at_level}
                /{exp_to_next}
              </ProgressBar>
            </Box>
          ) : (
            <Box mt={0.5}>
              <ProgressBar
                value={1}
                maxValue={1}
                color="gold">
                MAX LEVEL
              </ProgressBar>
            </Box>
          )}
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
                  {s === 'DEF'
                    && stats['DMG Reduction']
                    !== undefined && (
                    <Box inline color="label"
                      ml={1}
                      fontSize="12px">
                      ({stats['DMG Reduction']}
                      % reduction)
                    </Box>
                  )}
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
                        || s.includes('DMG')
                        || s.includes('Boost'))
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
              <Box key={a.type} mb={1.5}>
                <Box bold>
                  {a.name}
                  <Box inline color="label"
                    ml={1}>
                    Lv.{a.level}
                    /{a.max_level}
                  </Box>
                </Box>
                <Box color="grey"
                  fontSize="12px" mt={0.3}>
                  {a.desc}
                </Box>
                {a.scaling
                  && Object.keys(
                    a.scaling
                  ).length > 0 && (
                  <Box mt={0.5}
                    fontSize="12px"
                    style={{
                      background:
                        'rgba(0,0,0,0.15)',
                      padding: '4px 6px',
                      borderRadius: '4px',
                    }}>
                    {Object.keys(
                      a.scaling
                    ).map(k => (
                      <Box key={k}>
                        <Box inline
                          color="label">
                          {k}:
                        </Box>
                        {' '}
                        <Box inline bold>
                          {a.scaling[k]}
                        </Box>
                      </Box>
                    ))}
                  </Box>
                )}
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
      <Stack.Item>
        <Section title="Designated Allies">
          {allies.length === 0 ? (
            <Box color="label" fontSize="11px">
              None designated. Use the
              Designate Ally action to add
              nearby players.
            </Box>
          ) : (
            <Box>
              {allies.map((a, i) => (
                <Box key={i}
                  fontSize="12px" mb={0.3}>
                  <Box inline bold>
                    {a.name}
                  </Box>
                  {a.dead && (
                    <Box inline color="bad"
                      ml={0.5}
                      fontSize="10px">
                      (dead)
                    </Box>
                  )}
                  {a.has_path ? (
                    <Box inline color="green"
                      ml={0.5}>
                      — Path of {a.path_name}
                    </Box>
                  ) : (
                    <Box inline color="label"
                      ml={0.5}>
                      — non-path agent
                    </Box>
                  )}
                  {a.has_path && a.mutual && (
                    <Box inline color="good"
                      bold ml={0.5}
                      fontSize="10px">
                      [AP linked]
                    </Box>
                  )}
                  {a.has_path && !a.mutual && (
                    <Box inline color="label"
                      ml={0.5} fontSize="10px"
                      style={{
                        fontStyle: 'italic',
                      }}>
                      (one-way — they must
                      designate you back to
                      share AP)
                    </Box>
                  )}
                </Box>
              ))}
              <Box mt={0.5} color="label"
                fontSize="10px"
                style={{ fontStyle: 'italic' }}>
                Mutual path-allies share an
                AP pool: gains and spends
                affect both.
              </Box>
            </Box>
          )}
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
  const nw = isCore ? CORE_W
    : (isBonus ? BONUS_W : STAT_W);
  const nh = isCore ? CORE_H
    : (isBonus ? BONUS_H : STAT_H);
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
  } else if (isBonus) {
    bg = 'rgba(70,60,30,0.8)';
    brd = '2px solid rgba(220,180,60,0.8)';
  } else {
    bg = 'rgba(90,90,90,0.6)';
    brd = '2px solid rgba(100,100,100,0.5)';
  }
  if (selected) {
    brd = '2px solid rgba(255,220,60,1)';
  }

  // Find the right base64 icon + tint
  let iconB64 = null;
  let levelText = null;
  let tintColor = null;
  const imgSz = Math.min(nw, nh) - 6;

  if (isCore) {
    const ab = (data.abilities || []).find(
      a => node.ability_target === a.type
    );
    if (ab) {
      levelText = 'Lv.' + ab.level;
      iconB64 = ab.icon_base64;
    }
  } else if (node.stat_bonuses) {
    const k = Object.keys(
      node.stat_bonuses
    );
    if (k.length > 0 && data.stat_icons) {
      iconB64 = data.stat_icons[k[0]];
      if (data.stat_colors
        && data.stat_colors[k[0]]) {
        tintColor = data.stat_colors[k[0]];
      }
    }
  }
  // Bonus abilities: use ATK icon
  if (isBonus && data.stat_icons) {
    iconB64 = data.stat_icons['ATK'];
  }

  return (
    <Box
      style={{
        position: 'absolute',
        left: (x - nw / 2) + 'px',
        top: (y - nh / 2) + 'px',
        width: nw + 'px',
        userSelect: 'none',
        textAlign: 'center',
      }}
      onClick={onSelect}>
      <Box
        style={{
          width: nw + 'px',
          height: nh + 'px',
          background: bg,
          border: tintColor
            ? ('2px solid ' + tintColor)
            : brd,
          borderRadius: '50%',
          cursor: 'pointer',
          overflow: 'hidden',
          boxShadow: tintColor
            ? ('inset 0 0 8px '
              + tintColor + '88')
            : 'none',
        }}>
        {iconB64 && (
          <img
            src={
              'data:image/png;base64,'
              + iconB64
            }
            style={{
              width: imgSz + 'px',
              height: imgSz + 'px',
              imageRendering: 'pixelated',
              marginTop:
                ((nh - imgSz) / 2)
                + 'px',
            }}
          />
        )}
      </Box>
      {levelText && (
        <Box
          fontSize="8px"
          color="label"
          mt={0.2}>
          {levelText}
        </Box>
      )}
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

  // Effect text + stat preview
  let effectText = node.desc;
  let statPreview = null;
  if (node.node_type === 'stat'
    && node.stat_bonuses) {
    const parts = [];
    const previews = [];
    for (const s in node.stat_bonuses) {
      const v = node.stat_bonuses[s];
      const pct = node.stat_percent
        ? '%' : '';
      parts.push(s + ' +' + v + pct);
      const cur = data.stats[s] || 0;
      if (node.stat_percent) {
        const base = Math.round(
          cur / (1 + v / 100)
        );
        const added = cur - base;
        const newVal = cur
          + Math.round(base * v / 100);
        previews.push({
          stat: s,
          current: cur,
          next: node.unlocked
            ? cur : newVal,
          bonus: '+' + v + pct,
        });
      } else {
        previews.push({
          stat: s,
          current: cur,
          next: node.unlocked
            ? cur : cur + v,
          bonus: '+' + v,
        });
      }
    }
    effectText = parts.join(', ');
    if (!node.unlocked) {
      statPreview = previews;
    }
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
              && ' - Repeatable'}
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
          {statPreview && (
            <Box mt={0.5}
              fontSize="12px"
              style={{
                background:
                  'rgba(0,0,0,0.15)',
                padding: '4px 6px',
                borderRadius: '4px',
              }}>
              {statPreview.map(p => (
                <Box key={p.stat}>
                  <Box inline
                    color="label">
                    {p.stat}:
                  </Box>
                  {' '}
                  {p.current}
                  {' \u2192 '}
                  <Box inline bold
                    color="green">
                    {p.next}
                  </Box>
                  <Box inline color="label"
                    ml={0.5}>
                    ({p.bonus})
                  </Box>
                </Box>
              ))}
            </Box>
          )}
          {abilityInfo
            && abilityInfo.scaling
            && Object.keys(
              abilityInfo.scaling
            ).length > 0 && (
            <Box mt={0.5}
              fontSize="12px"
              style={{
                background:
                  'rgba(0,0,0,0.15)',
                padding: '4px 6px',
                borderRadius: '4px',
              }}>
              {Object.keys(
                abilityInfo.scaling
              ).map(k => (
                <Box key={k}>
                  <Box inline
                    color="label">
                    {k}:
                  </Box>
                  {' '}
                  <Box inline bold>
                    {abilityInfo.scaling[k]}
                  </Box>
                </Box>
              ))}
            </Box>
          )}
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
                - {r}
              </Box>
            ))}
          </Stack.Item>
        )}
        {node.node_type === 'ability'
          && abilityInfo && (
          <Stack.Item mt={1}>
            {(() => {
              const at = node.ability_target;
              const targets = data.pvp_targets
                || {};
              const tgt = targets[at];
              const table = abilityInfo.raw_scaling;
              if (!tgt || !table
                || !table.length) {
                return (
                  <Box>
                    <Box bold mb={0.5}>
                      PvP
                    </Box>
                    <Box color="label"
                      fontSize="11px">
                      Support ability — no
                      direct PvP damage scaling.
                    </Box>
                  </Box>
                );
              }
              const lv = abilityInfo.level;
              const max = table.length;
              const tIdx = Math.max(1,
                Math.min(max, tgt)) - 1;
              const aIdx = Math.max(1,
                Math.min(max, lv)) - 1;
              const tS = table[tIdx] || 0;
              const aS = table[aIdx] || 0;
              const factor = tS > 0
                ? aS / tS : 1;
              const factorColor = factor >= 1
                ? 'green'
                : factor >= 0.75
                  ? 'yellow' : 'bad';
              const atk = (data.stats
                && data.stats.ATK) || 0;
              const ownerHp = (data.stats
                && data.stats.HP) || 1;
              // Per-target damage:
              //   ATK × factor × actual%/100
              //   × 1.025 × 0.8 × HP / ownerHP
              const baseMult = atk * (aS / 100)
                * factor * 1.025 * 0.8;
              const hps = [180, 200, 220,
                300, 500];
              return (
                <Box>
                  <Box bold mb={0.5}>
                    PvP Scaling
                  </Box>
                  <Box fontSize="12px"
                    mb={0.5}>
                    <Box inline color="label">
                      Target L{tgt} — at L{lv}:
                    </Box>
                    {' '}
                    <Box inline bold
                      color={factorColor}>
                      {factor.toFixed(2)}×
                    </Box>
                  </Box>
                  <Box mt={0.5}
                    fontSize="11px"
                    style={{
                      background:
                        'rgba(0,0,0,0.15)',
                      padding: '4px 6px',
                      borderRadius: '4px',
                    }}>
                    <Box>
                      <Box inline bold
                        color="label"
                        width="70px">
                        Target HP
                      </Box>
                      <Box inline bold
                        color="label">
                        Per-hit dmg
                      </Box>
                    </Box>
                    {hps.map(hp => (
                      <Box key={hp}>
                        <Box inline width="70px">
                          {hp}
                        </Box>
                        <Box inline>
                          {(baseMult * hp
                            / ownerHp)
                            .toFixed(1)}
                        </Box>
                      </Box>
                    ))}
                  </Box>
                  <Box mt={0.5}
                    color="label"
                    fontSize="10px"
                    style={{
                      fontStyle: 'italic',
                    }}>
                    Path damage is reduced by
                    the average of the
                    target&apos;s RED/WHITE/
                    BLACK/PALE armor
                    resistances. Numbers above
                    are pre-armor.
                  </Box>
                  <Box mt={0.5} color="label"
                    fontSize="10px">
                    Trace upgrades scale your
                    PvP damage from default
                    toward and slightly past
                    the design baseline.
                  </Box>
                </Box>
              );
            })()}
          </Stack.Item>
        )}
        {node.node_type === 'ability' && abilityInfo
          && abilityInfo.raw_scaling && (
          <Stack.Item mt={1}>
            {(() => {
              const table = abilityInfo.raw_scaling;
              const lv = abilityInfo.level;
              const max = table.length;
              const aIdx = Math.max(1,
                Math.min(max, lv)) - 1;
              const aS = table[aIdx] || 0;
              const atk = (data.stats
                && data.stats.ATK) || 0;
              const pathLv = data.path_level || 1;
              const sampleHps = [80, 400,
                2200, 7500, 15000];
              const enemyLv = hp => {
                if (hp >= 8000) return 80;
                if (hp >= 3000) return 65;
                if (hp >= 2000) return 50;
                if (hp >= 1000) return 35;
                if (hp >= 400) return 20;
                return 10;
              };
              const dmgVs = hp => {
                const eLv = enemyLv(hp);
                const ld = Math.max(0.8,
                  Math.min(1.2,
                    1 + (pathLv - eLv) * 0.005));
                return atk * (aS / 100)
                  * 1.025 * ld * 0.8;
              };
              return (
                <Box>
                  <Box bold mb={0.5}>
                    PvE Damage
                  </Box>
                  <Box fontSize="11px"
                    color="label" mb={0.5}>
                    Per-hit dmg vs simple mobs
                    (avg coeff 1.0):
                  </Box>
                  <Box mt={0.5}
                    fontSize="11px"
                    style={{
                      background:
                        'rgba(0,0,0,0.15)',
                      padding: '4px 6px',
                      borderRadius: '4px',
                    }}>
                    <Box>
                      <Box inline bold
                        color="label"
                        width="80px">
                        Mob HP
                      </Box>
                      <Box inline bold
                        color="label">
                        Per-hit dmg
                      </Box>
                    </Box>
                    {sampleHps.map(hp => (
                      <Box key={hp}>
                        <Box inline width="80px">
                          ~{hp}
                        </Box>
                        <Box inline>
                          {dmgVs(hp).toFixed(1)}
                        </Box>
                      </Box>
                    ))}
                  </Box>
                  <Box mt={0.5} color="label"
                    fontSize="10px">
                    Formula: ATK ({atk})
                    × scaling ({aS}%)
                    × crit avg (1.025)
                    × level-diff (varies)
                    × RES (0.8)
                    × mob.avg_coeff.
                  </Box>
                  <Box mt={0.5} color="label"
                    fontSize="10px"
                    style={{
                      fontStyle: 'italic',
                    }}>
                    Real damage scales with
                    the mob&apos;s avg of
                    RED/WHITE/BLACK/PALE
                    coeffs. Basic follow-up
                    swings deal 10% of full.
                  </Box>
                </Box>
              );
            })()}
          </Stack.Item>
        )}
        {node.node_type === 'stat' && (
          <Stack.Item mt={1}>
            <Box bold mb={0.5}>PvP</Box>
            <Box color="label" fontSize="11px">
              Stat bonuses apply in full both
              PvE and PvP.
            </Box>
          </Stack.Item>
        )}
        {node.node_type === 'passive' && (
          <Stack.Item mt={1}>
            <Box bold mb={0.5}>PvP</Box>
            <Box color="label" fontSize="11px">
              Passive effect applies in full
              both PvE and PvP.
            </Box>
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
