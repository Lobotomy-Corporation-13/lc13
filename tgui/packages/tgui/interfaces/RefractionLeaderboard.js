import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';
import { formatTime, RecordSectorBreakdown } from './RefractionRailway';

// Standalone read-only leaderboard browser. Pairs with
// /obj/machinery/computer/refraction_railway_console/leaderboard. No lobby
// actions, no map — just pick a line on the left, read its top runs on the
// right.

const LineSidebar = props => {
  const { lines, selectedId, onSelect } = props;
  return (
    <Section fill title="Lines">
      {lines.length === 0 && (
        <Box color="label">No lines available.</Box>
      )}
      {lines.map(line => {
        const isSelected = line.id === selectedId;
        const accent = line.display_color || '#1b7ced';
        return (
          <Box
            key={line.id}
            p={1}
            mb={0.5}
            backgroundColor={isSelected
              ? 'rgba(255, 255, 255, 0.10)'
              : 'rgba(255, 255, 255, 0.04)'}
            style={{
              'border-radius': '4px',
              'border-left': `4px solid ${accent}`,
              'cursor': 'pointer',
            }}
            onClick={() => onSelect(line.id)}>
            <Box bold>{line.name}</Box>
            {line.description && (
              <Box mt={0.5} color="label" fontSize="11px">
                {line.description}
              </Box>
            )}
          </Box>
        );
      })}
    </Section>
  );
};

const LeaderboardPane = (props, context) => {
  const { line, rows } = props;
  const [expandedIdx, setExpandedIdx] = useLocalState(
    context,
    'leaderboardExpandedIdx',
    null
  );
  if (!line) {
    return (
      <Section fill title="Records">
        <Box color="label">Select a line on the left to view records.</Box>
      </Section>
    );
  }
  return (
    <Section
      fill
      scrollable
      title={`Records: ${line.name}`}>
      {rows.length === 0 && (
        <Box color="label">No records yet for this line.</Box>
      )}
      {rows.map((row, i) => {
        const isOpen = expandedIdx === i;
        return (
          <Box
            key={i}
            p={1}
            mb={0.5}
            backgroundColor="rgba(255, 255, 255, 0.04)"
            style={{ 'border-radius': '4px' }}>
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
              <Stack.Item>
                <Button
                  icon={isOpen ? 'chevron-up' : 'chevron-down'}
                  content={isOpen ? 'Collapse' : 'Per-sector'}
                  onClick={() => setExpandedIdx(isOpen ? null : i)}
                />
              </Stack.Item>
            </Stack>
            {isOpen && (
              <RecordSectorBreakdown sectors={row.sectors} />
            )}
          </Box>
        );
      })}
    </Section>
  );
};

export const RefractionLeaderboard = (props, context) => {
  const { data } = useBackend(context);
  const lines = data.lines || [];
  const leaderboards = data.leaderboards || {};
  const [selectedId, setSelectedId] = useLocalState(
    context,
    'leaderboardSelectedLine',
    lines[0] ? lines[0].id : null
  );
  // Re-sync the selection if the previously-selected line disappears or no
  // selection exists yet but lines have arrived.
  const hasSelected = lines.some(l => l.id === selectedId);
  const activeId = hasSelected
    ? selectedId
    : (lines[0] ? lines[0].id : null);
  const selectedLine = lines.find(l => l.id === activeId) || null;
  const rows = (selectedLine && leaderboards[selectedLine.id]) || [];
  return (
    <Window width={900} height={600} theme="syndicate">
      <Window.Content>
        <Stack fill>
          <Stack.Item width="240px">
            <LineSidebar
              lines={lines}
              selectedId={activeId}
              onSelect={setSelectedId}
            />
          </Stack.Item>
          <Stack.Item grow={1}>
            <LeaderboardPane line={selectedLine} rows={rows} />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
