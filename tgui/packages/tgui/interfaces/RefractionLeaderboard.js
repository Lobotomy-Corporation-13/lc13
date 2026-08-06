import { useBackend, useLocalState } from '../backend';
import { Box, Input, Section, Stack } from '../components';
import { Window } from '../layouts';
import {
  buildRecordGroups,
  groupMatchesQuery,
  RecordRow,
} from './RefractionRailway';

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
  const { line, rows, cutoff } = props;
  const [expandedIdx, setExpandedIdx] = useLocalState(
    context,
    'leaderboardExpandedIdx',
    null
  );
  const [expandedGroups, setExpandedGroups] = useLocalState(
    context,
    'leaderboardGroupExpanded',
    {}
  );
  const [search, setSearch] = useLocalState(
    context,
    'leaderboardSearch',
    ''
  );
  if (!line) {
    return (
      <Section fill title="Records">
        <Box color="label">Select a line on the left to view records.</Box>
      </Section>
    );
  }
  const trimmed = (search || '').trim();
  const allGroups = buildRecordGroups(rows);
  const groups = allGroups.filter(g => groupMatchesQuery(g, trimmed));
  const toggleGroup = key => {
    setExpandedGroups({
      ...expandedGroups,
      [key]: !expandedGroups[key],
    });
  };
  return (
    <Section
      fill
      scrollable
      title={`Records: ${line.name}`}>
      {!!cutoff && (
        <Box
          mb={1}
          p={1}
          color="label"
          fontSize="11px"
          backgroundColor="rgba(255, 200, 60, 0.08)"
          style={{ 'border-radius': '4px' }}>
          Records set before <b>{cutoff}</b> are no longer shown.
          Pre-cutoff runs sat under different balance — station
          traits, ordeals, and meltdowns could distort their timing,
          so they aren&apos;t meaningfully comparable with current
          results.
        </Box>
      )}
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
                setExpandedIdx(expandedIdx === bestIdx ? null : bestIdx)}
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
                        setExpandedIdx(expandedIdx === idx ? null : idx)}
                      mini
                    />
                  );
                })}
              </Box>
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
            <LeaderboardPane
              line={selectedLine}
              rows={rows}
              cutoff={data.leaderboard_cutoff}
            />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
