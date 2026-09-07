import { useBackend } from '../backend';
import {
  Box,
  Button,
  Icon,
  LabeledList,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const ResurgenceEventDebug = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    manager_exists,
    manager_running,
    active_events = [],
    event_types = [],
    yield_modifier,
    growth_modifier,
    work_modifier,
    sell_modifier,
    buy_modifier,
    faith_regen_modifier,
    quality_bonus,
    durability_modifier,
  } = data;

  const getCategoryLabel = cat => {
    switch (cat) {
      case 1:
        return { text: 'Positive', color: 'good' };
      case 2:
        return { text: 'Negative', color: 'bad' };
      default:
        return { text: 'Neutral', color: 'average' };
    }
  };

  return (
    <Window width={500} height={600}>
      <Window.Content scrollable>
        <Stack vertical fill>
          {/* Manager Controls */}
          <Stack.Item>
            <Section title="Event Manager">
              <LabeledList>
                <LabeledList.Item label="Status">
                  {manager_exists ? (
                    manager_running ? (
                      <Box color="good">Running</Box>
                    ) : (
                      <Box color="average">Stopped</Box>
                    )
                  ) : (
                    <Box color="bad">Not Initialized</Box>
                  )}
                </LabeledList.Item>
              </LabeledList>
              <Stack mt={1}>
                <Stack.Item>
                  <Button
                    icon="play"
                    color="good"
                    content="Start"
                    disabled={manager_running}
                    onClick={() => act('start_manager')}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="stop"
                    color="bad"
                    content="Stop"
                    disabled={!manager_running}
                    onClick={() => act('stop_manager')}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="undo"
                    content="Reset Modifiers"
                    onClick={() => act('reset_modifiers')}
                  />
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          {/* Current Modifiers */}
          <Stack.Item>
            <Section title="Global Modifiers">
              <LabeledList>
                <LabeledList.Item label="Yield">
                  {formatMod(yield_modifier)}
                </LabeledList.Item>
                <LabeledList.Item label="Growth">
                  {formatMod(growth_modifier)}
                </LabeledList.Item>
                <LabeledList.Item label="Work">
                  {formatMod(work_modifier)}
                </LabeledList.Item>
                <LabeledList.Item label="Sell Price">
                  {formatMod(sell_modifier)}
                </LabeledList.Item>
                <LabeledList.Item label="Buy Price">
                  {formatMod(buy_modifier)}
                </LabeledList.Item>
                <LabeledList.Item label="Faith Regen">
                  {formatMod(faith_regen_modifier)}
                </LabeledList.Item>
                <LabeledList.Item label="Quality Bonus">
                  {quality_bonus >= 0 ? '+' : ''}{quality_bonus}
                </LabeledList.Item>
                <LabeledList.Item label="Durability">
                  {formatMod(durability_modifier)}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          {/* Active Events */}
          <Stack.Item>
            <Section
              title={`Active Events (${active_events.length})`}
              buttons={(
                <Button
                  icon="times"
                  color="bad"
                  content="End All"
                  disabled={active_events.length === 0}
                  onClick={() => act('end_all_events')}
                />
              )}>
              {active_events.length === 0 ? (
                <Box color="label">No active events.</Box>
              ) : (
                active_events.map((event, i) => {
                  const cat = getCategoryLabel(event.category);
                  return (
                    <Box key={i} mb={1}>
                      <Stack align="center">
                        <Stack.Item grow>
                          <Box bold color={cat.color}>
                            {event.name}
                          </Box>
                          <Box color="label" fontSize="11px">
                            {event.remaining_text} remaining
                          </Box>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            icon="stop"
                            color="bad"
                            onClick={() => act('end_event', {
                              name: event.name,
                            })}
                          />
                        </Stack.Item>
                      </Stack>
                    </Box>
                  );
                })
              )}
            </Section>
          </Stack.Item>

          {/* Trigger Events */}
          <Stack.Item grow>
            <Section fill scrollable title="Trigger Event">
              {event_types.map((event, i) => {
                const cat = getCategoryLabel(event.category);
                return (
                  <Box key={i} mb={0.5}>
                    <Button
                      fluid
                      icon="bolt"
                      color={cat.color}
                      content={event.name}
                      onClick={() => act('trigger_event', {
                        path: event.path,
                      })}
                    />
                  </Box>
                );
              })}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const formatMod = val => {
  if (!val) {
    return '1.00x';
  }
  const pct = ((val - 1) * 100).toFixed(0);
  const color = val > 1 ? 'good' : val < 1 ? 'bad' : 'white';
  return (
    <Box inline color={color}>
      {val.toFixed(2)}x ({pct >= 0 ? '+' : ''}{pct}%)
    </Box>
  );
};
