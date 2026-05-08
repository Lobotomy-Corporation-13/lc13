import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';

const NODE_COLORS = {
  start: '#4ade80',
  combat: '#1b7ced',
  checkpoint: '#9ca3af',
  boss: '#ef4444',
  finish: '#fbbf24',
};

const formatTime = ds => {
  if (ds == null) return '--:--';
  const totalSeconds = ds / 10;
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = (totalSeconds - minutes * 60).toFixed(1);
  return `${minutes}:${seconds.padStart(4, '0')}`;
};

export const RecordsModal = (props, context) => {
  const { lineId, lineName, leaderboard, onClose } = props;
  const rows = leaderboard || [];
  return (
    <Box
      position="absolute"
      top={0}
      left={0}
      right={0}
      bottom={0}
      backgroundColor="rgba(0, 0, 0, 0.75)"
      style={{ 'z-index': 50 }}>
      <Box
        position="absolute"
        top="50%"
        left="50%"
        width="640px"
        style={{ transform: 'translate(-50%, -50%)' }}>
        <Section
          title={`Records: ${lineName || lineId}`}
          buttons={<Button icon="times" onClick={onClose} />}>
          {rows.length === 0 && (
            <Box color="label">No records yet for this line.</Box>
          )}
          {rows.map((row, i) => (
            <Box
              key={i}
              p={1}
              mb={0.5}
              backgroundColor="rgba(255, 255, 255, 0.04)">
              <Stack>
                <Stack.Item width="32px" bold>
                  #{i + 1}
                </Stack.Item>
                <Stack.Item width="80px" color="good" bold>
                  {formatTime(row.time_ds)}
                </Stack.Item>
                <Stack.Item grow={1}>
                  <Box bold>{row.ckey || row.name || '???'}</Box>
                  <Box color="label">
                    {(row.members || []).join(', ')}
                  </Box>
                </Stack.Item>
              </Stack>
            </Box>
          ))}
        </Section>
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
  const { line, selected, onSelect } = props;
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
        const isSelected = selected;
        return (
          <g
            key={i}
            style={{ cursor: 'pointer' }}
            onClick={() => onSelect && onSelect(line.id)}>
            <circle
              cx={node.x}
              cy={node.y}
              r={radius + (isSelected ? 4 : 0)}
              fill="#0a0e1f"
              stroke={fill}
              strokeWidth={isSelected ? 4 : 2}
            />
            <circle cx={node.x} cy={node.y} r={radius - 5} fill={fill} />
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

const LineSidebar = (props, context) => {
  const { act } = useBackend(context);
  const { lines, selectedId, onSelect, myRun, openLobbies } = props;
  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Lines">
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
                style={{ cursor: 'pointer', 'border-radius': '4px' }}
                onClick={() => onSelect(line.id)}>
                <Box bold style={{ color: line.display_color }}>
                  {line.name}
                </Box>
                <Box color="label" fontSize="11px">
                  {line.description}
                </Box>
              </Box>
            );
          })}
        </Section>
      </Stack.Item>
      <Stack.Item grow={1}>
        <LobbyPanel
          selectedId={selectedId}
          myRun={myRun}
          openLobbies={openLobbies}
          act={act}
        />
      </Stack.Item>
    </Stack>
  );
};

const LobbyPanel = props => {
  const { selectedId, myRun, openLobbies, act } = props;
  if (myRun) {
    return (
      <Section title={`Lobby: ${myRun.line_id}`}>
        <Box mb={1}>
          {(myRun.member_ckeys || []).map(ckey => (
            <Box key={ckey} p={0.5}>
              <Stack>
                <Stack.Item grow={1}>
                  {ckey}
                  {ckey === myRun.lobby_owner && ' (owner)'}
                </Stack.Item>
                {myRun.is_owner && ckey !== myRun.lobby_owner && (
                  <Stack.Item>
                    <Button
                      icon="times"
                      color="bad"
                      onClick={() => act('kick_member', { ckey })}
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
            disabled={(myRun.member_ckeys || []).length < 1}
            onClick={() => act('start_run')}
          />
        )}
        <Button
          fluid
          mt={0.5}
          icon="sign-out-alt"
          content="Leave"
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
        color="good"
        icon="plus"
        content="Create Lobby"
        onClick={() => act('create_lobby', { line_id: selectedId })}
      />
      {sameLineLobbies.length > 0 && (
        <Box mt={1}>
          <Box bold mb={0.5}>Open lobbies:</Box>
          {sameLineLobbies.map(l => (
            <Stack key={l.run_uid} p={0.5}>
              <Stack.Item grow={1}>
                <Box>{l.owner_ckey}</Box>
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
                    act('join_lobby', { run_uid: l.run_uid })
                  }
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
              onSelect={setSelectedId}
              myRun={myRun}
              openLobbies={openLobbies}
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
              buttons={
                selectedLine && (
                  <Button
                    icon="trophy"
                    content="Records"
                    onClick={() => setRecordsLineId(selectedLine.id)}
                  />
                )
              }>
              <RailwayMap
                line={selectedLine}
                selected
                onSelect={setSelectedId}
              />
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
      </Window.Content>
    </Window>
  );
};
