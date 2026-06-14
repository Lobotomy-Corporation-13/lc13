import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Icon,
  Input,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';
import { MobCard, MobModal } from './RefractionMobCards';
import { HazardTape } from './common/HazardTape';
import { AchievementList } from './common/AchievementList';

const NODE_COLORS = {
  start: '#4ade80',
  combat: '#1b7ced',
  checkpoint: '#9ca3af',
  boss: '#ef4444',
  finish: '#fbbf24',
};

export const formatTime = ds => {
  if (ds === null || ds === undefined) return '--:--';
  const totalSeconds = ds / 10;
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = (totalSeconds - minutes * 60).toFixed(1);
  return `${minutes}:${seconds.padStart(4, '0')}`;
};

// Returns the Nth combat-or-boss node from the line's `combat_nodes`
// payload (1-based). Subway-map authors place combat/boss circles in the
// same order as their AddNode() calls, so a click on the Nth combat-style
// circle on the map maps cleanly to combat_nodes[N - 1].
const combatNodeForMapIndex = (line, combatIndex) => {
  if (!line || !line.combat_nodes) return null;
  return line.combat_nodes[combatIndex - 1] || null;
};

export const RecordSectorBreakdown = props => {
  const { sectors } = props;
  const list = sectors || [];
  if (!list.length) {
    return (
      <Box mt={0.5} color="label" fontSize="11px">
        No per-sector data recorded for this run.
      </Box>
    );
  }
  return (
    <Box mt={0.5}>
      {list.map(sector => (
        <Box
          key={sector.index}
          p={0.5}
          mb={0.5}
          backgroundColor="rgba(255, 255, 255, 0.06)"
          style={{ 'border-radius': '4px' }}>
          <Stack>
            <Stack.Item grow={1} bold>
              {`Sector ${sector.index}`}
            </Stack.Item>
            <Stack.Item color="good">
              {formatTime(sector.time_ds)}
            </Stack.Item>
          </Stack>
          {!!(sector.rooms || []).length && (
            <Box mt={0.3} ml={1}>
              {sector.rooms.map((room, ri) => (
                <Stack key={ri}>
                  <Stack.Item
                    grow={1}
                    fontSize="10px"
                    color="label">
                    {`└ ${room.name || room.room_id}`}
                  </Stack.Item>
                  <Stack.Item fontSize="10px" color="label">
                    {formatTime(room.time_ds)}
                  </Stack.Item>
                </Stack>
              ))}
            </Box>
          )}
          {(sector.players || []).map(p => (
            <Box key={p.ckey} mt={0.5}>
              <Stack>
                <Stack.Item grow={1} fontSize="11px">
                  {p.name || p.ckey}
                </Stack.Item>
                <Stack.Item>
                  <Stack>
                    {(p.loadout_icons || [null, null, null]).map(
                      (icon, i) => (
                        <Stack.Item key={i}>
                          {icon ? (
                            <img
                              src={`data:image/jpeg;base64,${icon}`}
                              style={{
                                'height': '24px',
                                'image-rendering': 'pixelated',
                              }}
                            />
                          ) : (
                            <Box
                              width="24px"
                              height="24px"
                              backgroundColor="rgba(255, 255, 255, 0.05)"
                              textAlign="center"
                              color="label"
                              fontSize="9px">
                              ?
                            </Box>
                          )}
                        </Stack.Item>
                      ))}
                  </Stack>
                </Stack.Item>
              </Stack>
            </Box>
          ))}
        </Box>
      ))}
    </Box>
  );
};

// Computes a stable group key for an entry: sorted, joined member
// ckeys. Solo runs land in a one-element group keyed by that ckey.
const recordGroupKey = entry => {
  const members
    = entry.members && entry.members.length
      ? entry.members.slice().sort()
      : [entry.ckey || ''];
  return members.join('|');
};

// Builds an ordered list of { key, entries[] } from a server-sorted
// (ascending by time_ds) row array. entries[0] of each group is the
// group's BEST run; subsequent entries are slower attempts of the
// same set of players.
export const buildRecordGroups = rows => {
  const map = {};
  const order = [];
  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const key = recordGroupKey(r);
    if (!map[key]) {
      map[key] = { key, entries: [], indices: [] };
      order.push(key);
    }
    map[key].entries.push(r);
    map[key].indices.push(i);
  }
  return order.map(k => map[k]);
};

// Case-insensitive substring match: returns true if any member ckey
// in any entry of the group contains the trimmed query.
export const groupMatchesQuery = (group, query) => {
  if (!query) return true;
  const needle = query.toLowerCase();
  for (const entry of group.entries) {
    const haystack = [entry.ckey, ...(entry.members || [])]
      .filter(Boolean)
      .map(s => String(s).toLowerCase());
    if (haystack.some(s => s.includes(needle))) {
      return true;
    }
  }
  return false;
};

// Single-row layout shared by the group's best run and its expanded
// slower-runs sublist. The caller supplies a rank label, a sector
// expand handler, and optionally a "show older runs" button.
export const RecordRow = props => {
  const {
    entry,
    rank,
    isSectorOpen,
    onToggleSector,
    olderCount,
    isGroupOpen,
    onToggleGroup,
    mini,
  } = props;
  const hasOlder = !mini && (olderCount || 0) > 0;
  return (
    <Box
      p={mini ? 0.5 : 1}
      mb={0.5}
      backgroundColor={
        mini
          ? 'rgba(255, 255, 255, 0.025)'
          : 'rgba(255, 255, 255, 0.04)'
      }
      style={{
        'border-radius': '4px',
        ...(mini && {
          'border-left': '3px solid rgba(255, 255, 255, 0.12)',
        }),
      }}>
      <Stack>
        <Stack.Item width="44px" bold>
          {rank}
        </Stack.Item>
        <Stack.Item width="80px" color="good" bold>
          {formatTime(entry.time_ds)}
        </Stack.Item>
        <Stack.Item grow={1}>
          {!mini && (
            <Box
              bold
              style={
                hasOlder
                  ? { cursor: 'pointer', 'user-select': 'none' }
                  : {}
              }
              onClick={hasOlder ? onToggleGroup : undefined}>
              {entry.ckey || entry.name || '???'}
              {hasOlder && (
                <Box
                  as="span"
                  ml={0.5}
                  color="label"
                  fontSize="11px">
                  <Icon
                    name={
                      isGroupOpen ? 'chevron-up' : 'chevron-down'
                    }
                  />
                  {' '}
                  {isGroupOpen
                    ? 'hide older'
                    : `+${olderCount} older`}
                </Box>
              )}
            </Box>
          )}
          <Box color="label" fontSize={mini ? '10px' : '11px'}>
            {(entry.members || []).join(', ')}
          </Box>
          {!!entry.timestamp_text && (
            <Box color="label" fontSize="10px" mt={0.2}>
              {entry.timestamp_text}
            </Box>
          )}
        </Stack.Item>
        <Stack.Item>
          <Button
            icon={isSectorOpen ? 'chevron-up' : 'chevron-down'}
            content={isSectorOpen ? 'Collapse' : 'Per-sector'}
            onClick={onToggleSector}
          />
        </Stack.Item>
      </Stack>
      {isSectorOpen && (
        <RecordSectorBreakdown sectors={entry.sectors} />
      )}
    </Box>
  );
};

export const RecordsModal = (props, context) => {
  const { lineId, lineName, leaderboard, onClose } = props;
  const rows = leaderboard || [];
  const [expandedIdx, setExpandedIdx] = useLocalState(
    context,
    'recordsExpanded',
    null
  );
  const [expandedGroups, setExpandedGroups] = useLocalState(
    context,
    'recordsGroupExpanded',
    {}
  );
  const [search, setSearch] = useLocalState(
    context,
    'recordsSearch',
    ''
  );
  const trimmed = (search || '').trim();
  const allGroups = buildRecordGroups(rows);
  const groups = allGroups.filter(
    g => groupMatchesQuery(g, trimmed));
  const toggleGroup = key => {
    setExpandedGroups({
      ...expandedGroups,
      [key]: !expandedGroups[key],
    });
  };
  return (
    <Box
      position="fixed"
      top={0}
      left={0}
      right={0}
      bottom={0}
      backgroundColor="rgba(0, 0, 0, 0.75)"
      style={{ 'z-index': 50 }}
      onClick={onClose}>
      <Box
        position="fixed"
        top="20px"
        left="50%"
        width="680px"
        style={{
          'transform': 'translate(-50%, 0)',
          'max-height': 'calc(100vh - 40px)',
        }}
        onClick={e => e.stopPropagation()}>
        <Section
          title={`Records: ${lineName || lineId}`}
          buttons={
            <Button icon="times" content="Close" onClick={onClose} />
          }
          style={{ 'max-height': 'calc(100vh - 40px)' }}>
          <Box mb={1}>
            <Input
              fluid
              value={search}
              placeholder="Search by player name..."
              onInput={(_, value) => setSearch(value)}
            />
            <Box color="label" fontSize="10px" mt={0.3}>
              {`${groups.length} group${
                groups.length === 1 ? '' : 's'} · ${rows.length} `
              + `run${rows.length === 1 ? '' : 's'} total`}
            </Box>
          </Box>
          <Box
            style={{
              'overflow-y': 'auto',
              'max-height': 'calc(100vh - 180px)',
              'padding-right': '4px',
            }}>
            {rows.length === 0 && (
              <Box color="label">No records yet for this line.</Box>
            )}
            {rows.length > 0 && groups.length === 0 && (
              <Box color="label" mt={1}>
                No records match the search.
              </Box>
            )}
            {groups.map((group, groupIdx) => {
              const bestIdx = group.indices[0];
              const bestEntry = group.entries[0];
              const olderCount = group.entries.length - 1;
              const isGroupOpen = !!expandedGroups[group.key];
              return (
                <Box key={group.key}>
                  <RecordRow
                    entry={bestEntry}
                    rank={`#${groupIdx + 1}`}
                    isSectorOpen={expandedIdx === bestIdx}
                    onToggleSector={() =>
                      setExpandedIdx(
                        expandedIdx === bestIdx ? null : bestIdx)}
                    olderCount={olderCount}
                    isGroupOpen={isGroupOpen}
                    onToggleGroup={() => toggleGroup(group.key)}
                  />
                  {isGroupOpen && olderCount > 0 && (
                    <Box ml={2} mb={0.5}>
                      {group.entries.slice(1).map((entry, k) => {
                        const idx = group.indices[k + 1];
                        return (
                          <RecordRow
                            key={idx}
                            entry={entry}
                            rank={`P#${k + 2}`}
                            isSectorOpen={expandedIdx === idx}
                            onToggleSector={() =>
                              setExpandedIdx(
                                expandedIdx === idx ? null : idx)}
                            mini
                          />
                        );
                      })}
                    </Box>
                  )}
                </Box>
              );
            })}
          </Box>
        </Section>
      </Box>
    </Box>
  );
};

// Modal panel that shows every mob in a single combat / boss node, using
// the shared MobCard component. Click a card to drill into the full
// datasheet (or silhouette if the player hasn't fought it yet).
const NodeMobsModal = (props, context) => {
  const { node, onClose } = props;
  const { data } = useBackend(context);
  const [modalMob, setModalMob] = useLocalState(
    context, 'nodeModalMob', null);
  if (!node) return null;
  return (
    <Box
      position="absolute"
      top={0}
      left={0}
      right={0}
      bottom={0}
      backgroundColor="rgba(0, 0, 0, 0.75)"
      style={{ 'z-index': 40 }}
      onClick={onClose}>
      <Box
        position="absolute"
        top="50%"
        left="50%"
        width="640px"
        style={{ transform: 'translate(-50%, -50%)' }}
        onClick={e => e.stopPropagation()}>
        <Section
          title={node.name + (node.is_boss ? ' (Boss)' : '')}
          buttons={<Button icon="times" onClick={() => {
            setModalMob(null);
            onClose();
          }} />}>
          {node.locked ? (
            <Box p={1} color="bad">
              Restricted — encounter not yet authored.
            </Box>
          ) : (
            <>
              {node.description && (
                <Box mb={1} color="label">{node.description}</Box>
              )}
              <Stack wrap>
                {(node.mobs || []).map((mob, j) => (
                  <Stack.Item key={j}>
                    <MobCard mob={mob} onClick={() => setModalMob(mob)} />
                  </Stack.Item>
                ))}
              </Stack>
              <AchievementList achievements={node.achievements} />
            </>
          )}
        </Section>
        {modalMob && (
          <MobModal
            mob={modalMob}
            onClose={() => setModalMob(null)}
            glossary={data.status_glossary}
          />
        )}
      </Box>
    </Box>
  );
};

const Edge = props => {
  const { edge, nodes, defaultColor } = props;
  const from = nodes[edge.from - 1];
  const to = nodes[edge.to - 1];
  if (!from || !to) return null;
  const color = edge.color || defaultColor;
  const thickness = edge.thickness || 4;
  const dash = edge.dashed ? '6 4' : null;
  const shape = edge.shape || 'line';
  if (shape === 'elbow_h') {
    const points = `${from.x},${from.y} ${to.x},${from.y} ${to.x},${to.y}`;
    return (
      <polyline
        points={points}
        fill="none"
        stroke={color}
        strokeWidth={thickness}
        strokeDasharray={dash}
      />
    );
  }
  if (shape === 'elbow_v') {
    const points = `${from.x},${from.y} ${from.x},${to.y} ${to.x},${to.y}`;
    return (
      <polyline
        points={points}
        fill="none"
        stroke={color}
        strokeWidth={thickness}
        strokeDasharray={dash}
      />
    );
  }
  if (shape === 'curve') {
    const midX = (from.x + to.x) / 2;
    const midY = Math.min(from.y, to.y) - 40;
    const d = `M ${from.x} ${from.y} Q ${midX} ${midY} ${to.x} ${to.y}`;
    return (
      <path
        d={d}
        fill="none"
        stroke={color}
        strokeWidth={thickness}
        strokeDasharray={dash}
      />
    );
  }
  return (
    <line
      x1={from.x}
      y1={from.y}
      x2={to.x}
      y2={to.y}
      stroke={color}
      strokeWidth={thickness}
      strokeDasharray={dash}
    />
  );
};

const RailwayMap = props => {
  const { line, onCombatNodeClick } = props;
  if (!line) return null;
  const vb = line.map_viewbox || { w: 600, h: 360 };
  const nodes = line.nodes || [];
  const edges = line.edges || [];
  const tierLines = line.recommended_tier_lines || [];
  const tierOffset = line.recommended_tier_offset || { x: 40, y: -60 };
  const startNode = nodes.find(n => n.kind === 'start') || nodes[0];
  const tierAnchor = startNode
    ? { x: startNode.x + tierOffset.x, y: startNode.y + tierOffset.y }
    : null;
  // Track combat/boss circles in render order so a click maps cleanly back
  // to the Nth combat node in the line's combat_nodes payload.
  let combatIndex = 0;
  return (
    <svg
      viewBox={`0 0 ${vb.w} ${vb.h}`}
      style={{
        'width': '100%',
        'height': '100%',
        'background': 'radial-gradient(circle at 50% 50%,'
          + ' #18213d 0%, #07091a 90%)',
      }}>
      {edges.map((edge, i) => (
        <Edge
          key={i}
          edge={edge}
          nodes={nodes}
          defaultColor={line.display_color}
        />
      ))}
      {nodes.map((node, i) => {
        const radius = node.radius || 14;
        const fill = NODE_COLORS[node.kind] || line.display_color;
        const isClickable = node.kind === 'combat' || node.kind === 'boss';
        const myCombatIndex = isClickable ? ++combatIndex : 0;
        const combatNode = isClickable
          ? combatNodeForMapIndex(line, myCombatIndex)
          : null;
        const isLocked = !!(combatNode && combatNode.locked);
        const handleClick = isClickable && !isLocked && onCombatNodeClick
          ? () => onCombatNodeClick(myCombatIndex)
          : null;
        const renderFill = isLocked ? '#5a5a5a' : fill;
        return (
          <g
            key={i}
            style={{ cursor: handleClick ? 'pointer' : 'default' }}
            onClick={handleClick || undefined}>
            <circle
              cx={node.x}
              cy={node.y}
              r={radius}
              fill="#0a0e1f"
              stroke={renderFill}
              strokeWidth={2}
              opacity={isLocked ? 0.55 : 1}
            />
            <circle
              cx={node.x}
              cy={node.y}
              r={radius - 5}
              fill={renderFill}
              opacity={isLocked ? 0.55 : 1}
            />
            {isLocked ? (
              <text
                x={node.x}
                y={node.y + 4}
                fill="#ffd400"
                fontSize="14"
                fontWeight="bold"
                textAnchor="middle"
                style={{ 'pointer-events': 'none' }}>
                ✕
              </text>
            ) : null}
          </g>
        );
      })}
      {tierAnchor && tierLines.length > 0 && (
        <g>
          <text
            x={tierAnchor.x}
            y={tierAnchor.y}
            fill={line.display_color}
            fontSize="14"
            fontWeight="bold">
            Recommended Level &amp; Tier
          </text>
          {tierLines.map((text, i) => (
            <text
              key={i}
              x={tierAnchor.x}
              y={tierAnchor.y + 18 + i * 14}
              fill="#cbd5e1"
              fontSize="12">
              {text}
            </text>
          ))}
        </g>
      )}
    </svg>
  );
};

const CompensationsPanel = props => {
  const { compensations, selectedId } = props;
  if (!selectedId || !compensations || !compensations.length) {
    return null;
  }
  const visible = compensations.filter(
    c => c.line_id === selectedId && c.enabled);
  if (!visible.length) {
    return null;
  }
  return (
    <Section title="Party Scaling Effects">
      <Box color="label" fontSize="10px" mb={0.5}>
        Active scaling rules for this line. Most effects scale UP for
        larger parties; pens compensate smaller parties.
      </Box>
      <Box
        maxHeight="140px"
        style={{ 'overflow-y': 'auto' }}>
        {visible.map((c, i) => (
          <Box
            key={i}
            p={0.5}
            mb={0.25}
            style={{ 'border-radius': '3px' }}
            backgroundColor="rgba(34, 197, 94, 0.08)">
            <Box bold fontSize="11px">{c.name}</Box>
            <Box color="label" fontSize="10px">
              {c.description}
            </Box>
          </Box>
        ))}
      </Box>
    </Section>
  );
};

// The "Lines" tab: the line picker plus the party-scaling readout.
const LinesTab = props => {
  const { lines, selectedId, onSelect, compensations } = props;
  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Lines">
          <Box
            maxHeight="180px"
            style={{ 'overflow-y': 'auto' }}>
            {(lines || []).map(line => {
              const isSelected = line.id === selectedId;
              return (
                <Box
                  key={line.id}
                  p={1}
                  mb={0.5}
                  backgroundColor={
                    isSelected
                      ? 'rgba(27, 124, 237, 0.25)'
                      : 'rgba(255, 255, 255, 0.04)'
                  }
                  style={{
                    'cursor': 'pointer',
                    'border-radius': '4px',
                    'position': 'relative',
                    'overflow': 'hidden',
                  }}
                  onClick={() => onSelect(line.id)}>
                  <Box bold style={{ color: line.display_color }}>
                    {line.name}
                  </Box>
                  <Box color="label" fontSize="11px">
                    {line.description}
                  </Box>
                  {line.locked ? (
                    <HazardTape count={3} />
                  ) : null}
                </Box>
              );
            })}
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <CompensationsPanel
          compensations={compensations}
          selectedId={selectedId}
        />
      </Stack.Item>
    </Stack>
  );
};

// Left column: a tab strip switching between the line picker (Lines) and the
// lobby controls (Lobby), so a growing line list can't push the lobby —
// and its Start button — off the bottom of the window.
const LineSidebar = (props, context) => {
  const { act } = useBackend(context);
  const {
    lines, selectedId, onSelect, myRun, openLobbies, compensations,
  } = props;
  const selectedLine = (lines || []).find(l => l.id === selectedId) || null;
  const selectedLineLocked = !!(selectedLine && selectedLine.locked);
  const [sidebarTab, setSidebarTab] = useLocalState(
    context, 'sidebarTab', myRun ? 'lobby' : 'lines');
  return (
    <Stack vertical fill>
      <Stack.Item>
        <Tabs fluid>
          <Tabs.Tab
            selected={sidebarTab === 'lines'}
            onClick={() => setSidebarTab('lines')}>
            Lines
          </Tabs.Tab>
          <Tabs.Tab
            selected={sidebarTab === 'lobby'}
            icon={myRun ? 'play' : undefined}
            onClick={() => setSidebarTab('lobby')}>
            Lobby
          </Tabs.Tab>
        </Tabs>
      </Stack.Item>
      <Stack.Item grow={1}>
        <Box height="100%" style={{ 'overflow-y': 'auto' }}>
          {sidebarTab === 'lines' ? (
            <LinesTab
              lines={lines}
              selectedId={selectedId}
              onSelect={onSelect}
              compensations={compensations}
            />
          ) : (
            <LobbyPanel
              selectedId={selectedId}
              selectedLineLocked={selectedLineLocked}
              myRun={myRun}
              openLobbies={openLobbies}
              act={act}
            />
          )}
        </Box>
      </Stack.Item>
    </Stack>
  );
};

const LobbyPanel = props => {
  const { selectedId, selectedLineLocked, myRun, openLobbies, act } = props;
  if (myRun) {
    const isStarting = myRun.lobby_state === 'lobby_starting';
    return (
      <Section title={`Lobby: ${myRun.line_id}`}>
        {isStarting && (
          <Box
            p={1}
            mb={1}
            backgroundColor="rgba(251, 191, 36, 0.12)"
            color="average">
            <Box bold>Loading new Z-level…</Box>
            <Box fontSize="11px">
              The line&apos;s map is being built. Lobby actions are paused until
              the load finishes.
            </Box>
          </Box>
        )}
        <Box mb={1}>
          {(myRun.members || []).map(m => (
            <Box key={m.ckey} p={0.5}>
              <Stack>
                <Stack.Item grow={1}>
                  {m.name}
                  {m.ckey === myRun.lobby_owner && ' (owner)'}
                </Stack.Item>
                {myRun.is_owner && m.ckey !== myRun.lobby_owner && (
                  <Stack.Item>
                    <Button
                      icon="times"
                      color="bad"
                      disabled={isStarting}
                      tooltip={isStarting
                        ? 'Locked while the new Z-level is loading.'
                        : null}
                      onClick={() =>
                        act('kick_member', { ckey: m.ckey })}
                    />
                  </Stack.Item>
                )}
              </Stack>
            </Box>
          ))}
        </Box>
        {myRun.is_owner && myRun.lobby_state === 'lobby_open' && (
          <Button
            fluid
            color="good"
            icon="play"
            content="Start"
            disabled={(myRun.members || []).length < 1}
            onClick={() => act('start_run')}
          />
        )}
        {isStarting && (
          <Button
            fluid
            color="good"
            icon="hourglass-half"
            content="Loading Z-level…"
            disabled
            tooltip={'A new Z-level is being assembled for this lobby.'
              + ' Start is locked until it finishes.'}
          />
        )}
        <Button
          fluid
          mt={0.5}
          icon="sign-out-alt"
          content="Leave"
          disabled={isStarting}
          tooltip={isStarting
            ? 'You can\'t leave while the new Z-level is loading.'
            : null}
          onClick={() => act('leave_lobby')}
        />
      </Section>
    );
  }
  if (!selectedId) {
    return (
      <Section title="Lobby">
        <Box color="label">Select a line to create or join a lobby.</Box>
      </Section>
    );
  }
  const sameLineLobbies = (openLobbies || [])
    .filter(l => l.line_id === selectedId);
  return (
    <Section title="Lobby">
      <Button
        fluid
        color={selectedLineLocked ? null : 'good'}
        icon={selectedLineLocked ? 'lock' : 'plus'}
        content={selectedLineLocked
          ? 'Under Construction'
          : 'Create Lobby'}
        disabled={selectedLineLocked}
        tooltip={selectedLineLocked
          ? 'This line is locked — no lobbies until it ships.'
          : null}
        onClick={() => !selectedLineLocked
          && act('create_lobby', { line_id: selectedId })}
      />
      {sameLineLobbies.length > 0 && (
        <Box mt={1}>
          <Box bold mb={0.5}>Open lobbies:</Box>
          {sameLineLobbies.map(l => (
            <Stack key={l.run_uid} p={0.5}>
              <Stack.Item grow={1}>
                <Box>{l.owner_name}</Box>
                <Box color="label" fontSize="11px">
                  {l.member_count}/{l.max_lobby_size}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="sign-in-alt"
                  content="Join"
                  disabled={l.member_count >= l.max_lobby_size}
                  onClick={() =>
                    act('join_lobby', { run_uid: l.run_uid })}
                />
              </Stack.Item>
            </Stack>
          ))}
        </Box>
      )}
    </Section>
  );
};

export const RefractionRailway = (props, context) => {
  const { data } = useBackend(context);
  const lines = data.lines || [];
  const myRun = data.my_run;
  const openLobbies = data.open_lobbies || [];
  const leaderboards = data.leaderboards || {};
  const [selectedId, setSelectedId] = useLocalState(
    context,
    'selectedLine',
    lines[0] ? lines[0].id : null
  );
  const [recordsLineId, setRecordsLineId] = useLocalState(
    context,
    'recordsLineId',
    null
  );
  const [previewNode, setPreviewNode] = useLocalState(
    context,
    'previewNode',
    null
  );
  const selectedLine = lines.find(l => l.id === selectedId) || null;
  const recordsLine = lines.find(l => l.id === recordsLineId);
  return (
    <Window width={1000} height={600} theme="syndicate">
      <Window.Content>
        <Stack fill>
          <Stack.Item width="280px">
            <LineSidebar
              lines={lines}
              selectedId={selectedId}
              onSelect={id => {
                setSelectedId(id);
                setPreviewNode(null);
              }}
              myRun={myRun}
              openLobbies={openLobbies}
              compensations={data.compensations}
            />
          </Stack.Item>
          <Stack.Item grow={1}>
            <Section
              fill
              title={
                selectedLine
                  ? selectedLine.name
                  : '“What Line will you travel?”'
              }
              buttons={selectedLine && (
                <Button
                  icon="trophy"
                  content="Records"
                  onClick={() => setRecordsLineId(selectedLine.id)}
                />
              )}>
              <Box
                style={{
                  'position': 'relative',
                  'overflow': 'hidden',
                  'width': '100%',
                  'height': '100%',
                }}>
                <RailwayMap
                  line={selectedLine}
                  onCombatNodeClick={i => {
                    if (selectedLine && selectedLine.locked) {
                      return;
                    }
                    const node = combatNodeForMapIndex(selectedLine, i);
                    if (node && node.locked) {
                      return;
                    }
                    setPreviewNode(node);
                  }}
                />
                {selectedLine && selectedLine.locked ? (
                  <HazardTape count={5} />
                ) : null}
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
        {recordsLine && (
          <RecordsModal
            lineId={recordsLine.id}
            lineName={recordsLine.name}
            leaderboard={leaderboards[recordsLine.id]}
            onClose={() => setRecordsLineId(null)}
          />
        )}
        {previewNode && (
          <NodeMobsModal
            node={previewNode}
            onClose={() => setPreviewNode(null)}
          />
        )}
      </Window.Content>
    </Window>
  );
};
