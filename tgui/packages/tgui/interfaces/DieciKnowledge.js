import { useBackend } from '../backend';
import {
  Box,
  Button,
  Section,
  Stack,
  Table,
} from '../components';
import { Window } from '../layouts';

const KNOWLEDGE_TYPES = [
  'Behavioral',
  'Medical',
  'Spiritual',
];

export const DieciKnowledge = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    active_knowledge = [],
    max_knowledge = 20,
    synthesis_cost = 3,
  } = data;

  const groups = {};
  active_knowledge.forEach(entry => {
    const key = entry.type + '_' + entry.level;
    if (!groups[key]) {
      groups[key] = {
        type: entry.type,
        level: entry.level,
        count: 0,
      };
    }
    groups[key].count++;
  });
  const groupList = Object.values(groups);

  return (
    <Window width={440} height={420}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Active Knowledge">
              <Box mb={1}>
                {'Entries: '}
                {active_knowledge.length}
                {'/' + max_knowledge}
              </Box>
              {active_knowledge.length === 0 && (
                <Box color="label" italic>
                  No active knowledge.
                  Use your Tome to gather
                  knowledge.
                </Box>
              )}
              {active_knowledge.length > 0 && (
                <Table>
                  {active_knowledge.map(
                    (entry, i) => (
                      <Table.Row key={i}>
                        <Table.Cell>
                          <Box bold>
                            {entry.type
                              + ' L'
                              + entry.level}
                          </Box>
                        </Table.Cell>
                        <Table.Cell>
                          <Box
                            color="label"
                            fontSize="11px"
                          >
                            {entry.flavor}
                          </Box>
                          {!!entry.source && (
                            <Box
                              color="average"
                              fontSize="10px"
                              italic
                            >
                              {entry.source}
                            </Box>
                          )}
                        </Table.Cell>
                        <Table.Cell>
                          {!!entry.recorded && (
                            <Box
                              color="good"
                              fontSize="11px"
                            >
                              Recorded
                            </Box>
                          )}
                        </Table.Cell>
                      </Table.Row>
                    )
                  )}
                </Table>
              )}
            </Section>
          </Stack.Item>
          {groupList.length > 0 && (
            <Stack.Item>
              <Section title="Synthesis">
                <Box color="label" mb={1}>
                  {'Combine '}
                  {synthesis_cost}
                  {' same type+level entries'}
                  {' into 1 higher level.'}
                </Box>
                <Stack wrap>
                  {groupList.map((g, i) => (
                    <Stack.Item
                      key={i}
                      mr={1}
                      mb={1}
                    >
                      <Button
                        content={
                          g.type
                          + ' L'
                          + g.level
                          + ' ('
                          + g.count
                          + ')'
                        }
                        disabled={
                          g.count
                            < synthesis_cost
                          || g.level >= 5
                        }
                        onClick={() => act(
                          'synthesize',
                          {
                            type: g.type,
                            level: g.level,
                          }
                        )}
                      />
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
