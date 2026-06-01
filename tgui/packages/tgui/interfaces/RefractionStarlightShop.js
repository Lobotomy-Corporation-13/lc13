import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';
import { HazardTape } from './common/HazardTape';

const SORT_MODES = [
  { value: 'cost_asc', label: 'Cost: Low → High' },
  { value: 'cost_desc', label: 'Cost: High → Low' },
  { value: 'name', label: 'Name (A → Z)' },
];

const sortQuirks = (list, mode) => {
  const arr = list.slice();
  if (mode === 'cost_asc') {
    arr.sort((a, b) => (a.cost || 0) - (b.cost || 0));
  } else if (mode === 'cost_desc') {
    arr.sort((a, b) => (b.cost || 0) - (a.cost || 0));
  } else if (mode === 'name') {
    arr.sort((a, b) =>
      String(a.name).localeCompare(String(b.name)));
  }
  return arr;
};

const QuirkRow = props => {
  const { entry, balance, onBuy } = props;
  const unlocked = !!entry.unlocked;
  const lineLocked = !!entry.line_locked;
  const lineGated
    = !!entry.line_required && !entry.line_done;
  const tooPoor = !unlocked && !lineGated && !lineLocked
    && balance < entry.cost;
  const accent = entry.line_color || null;

  let label = `Buy (${entry.cost} ★)`;
  let color = null;
  let disabled = false;
  if (unlocked) {
    label = 'Owned';
    color = 'good';
    disabled = true;
  } else if (lineLocked) {
    label = 'Under Construction';
    disabled = true;
  } else if (lineGated) {
    label = 'Locked';
    disabled = true;
  } else if (tooPoor) {
    disabled = true;
  }

  const bgColor = unlocked
    ? 'rgba(34, 197, 94, 0.14)'
    : lineGated
      ? 'rgba(120, 0, 120, 0.14)'
      : 'rgba(255, 255, 255, 0.035)';

  const borderLeft = accent
    ? `4px solid ${accent}`
    : '4px solid rgba(255, 255, 255, 0.08)';

  return (
    <Box
      p={1}
      mb={0.5}
      style={{
        'border-radius': '6px',
        'border-left': borderLeft,
        'position': 'relative',
        'overflow': 'hidden',
        opacity: unlocked || lineGated ? 0.75 : 1,
      }}
      backgroundColor={bgColor}>
      <Flex>
        <Flex.Item grow={1}>
          <Box bold>{entry.name}</Box>
          <Box mt={0.5} fontSize="11px" color="label">
            {entry.desc}
          </Box>
          {!!entry.line_required && (
            <Box
              mt={0.5}
              fontSize="10px"
              style={{ color: accent || '#888' }}>
              Line tie-in:{' '}
              {entry.line_name || entry.line_required}
              {!entry.line_done && ' (not yet cleared)'}
            </Box>
          )}
        </Flex.Item>
        <Flex.Item ml={1} style={{ 'min-width': '190px' }}>
          <Stack vertical>
            <Stack.Item textAlign="right" color="label">
              Cost: {entry.cost} ★
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                color={color}
                disabled={disabled}
                content={label}
                onClick={() => !disabled && onBuy(entry.name)}
              />
            </Stack.Item>
          </Stack>
        </Flex.Item>
      </Flex>
      {lineLocked ? (
        <HazardTape count={3} />
      ) : null}
    </Box>
  );
};

const Category = props => {
  const { title, accent, list, balance, onBuy } = props;
  if (!list || !list.length) {
    return null;
  }
  return (
    <Section
      title={title}
      style={accent
        ? { 'border-left': `3px solid ${accent}` }
        : {}}>
      {list.map(entry => (
        <QuirkRow
          key={entry.name}
          entry={entry}
          balance={balance}
          onBuy={onBuy}
        />
      ))}
    </Section>
  );
};

const GENERAL_KEY = '__general__';

export const RefractionStarlightShop = (props, context) => {
  const { act, data } = useBackend(context);
  const balance = data.balance || 0;
  const quirks = data.quirks || [];
  const [sortMode, setSortMode] = useLocalState(
    context,
    'starlightSortMode',
    'cost_asc',
  );

  const groups = {};
  const groupOrder = [];
  const lineColor = {};
  const lineName = {};
  for (let i = 0; i < quirks.length; i++) {
    const q = quirks[i];
    const key = q.line_required || GENERAL_KEY;
    if (!groups[key]) {
      groups[key] = [];
      groupOrder.push(key);
      if (key !== GENERAL_KEY) {
        lineColor[key] = q.line_color || null;
        lineName[key] = q.line_name || q.line_required;
      }
    }
    groups[key].push(q);
  }
  groupOrder.sort((a, b) => {
    if (a === GENERAL_KEY) {
      return -1;
    }
    if (b === GENERAL_KEY) {
      return 1;
    }
    return String(lineName[a] || a)
      .localeCompare(String(lineName[b] || b));
  });

  const sortLabel = (SORT_MODES.find(m => m.value === sortMode)
    || SORT_MODES[0]).label;

  return (
    <Window width={700} height={680}>
      <Window.Content scrollable>
        <Section>
          <Flex align="center" justify="space-between">
            <Flex.Item>
              <Box bold fontSize="14px">
                Starlight Balance:{' '}
                <Box
                  as="span"
                  style={{ color: '#ffd86b' }}>
                  {balance} ★
                </Box>
              </Box>
              <Box mt={0.3} fontSize="11px" color="label">
                Permanent unlocks. Quirks remain in your
                character setup once purchased.
              </Box>
            </Flex.Item>
            <Flex.Item>
              <Stack align="center">
                <Stack.Item color="label">Sort by:</Stack.Item>
                <Stack.Item>
                  <Dropdown
                    width="170px"
                    selected={sortMode}
                    displayText={sortLabel}
                    options={SORT_MODES.map(m => m.value)}
                    onSelected={setSortMode}
                  />
                </Stack.Item>
              </Stack>
            </Flex.Item>
          </Flex>
        </Section>
        {quirks.length === 0 ? (
          <Section>
            <Box color="label" textAlign="center" mt={2}>
              No Starlight quirks have been authored yet.
            </Box>
          </Section>
        ) : (
          groupOrder.map(key => (
            <Category
              key={key}
              title={
                key === GENERAL_KEY
                  ? 'General'
                  : (lineName[key] || key)
              }
              accent={
                key === GENERAL_KEY ? null : lineColor[key]
              }
              list={sortQuirks(groups[key], sortMode)}
              balance={balance}
              onBuy={name => act('purchase', { name })}
            />
          ))
        )}
      </Window.Content>
    </Window>
  );
};
