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
    conserve_knowledge = false,
  } = data;

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
                <Button
                  ml={2}
                  icon={
                    conserve_knowledge
                      ? 'lock'
                      : 'lock-open'
                  }
                  color={
                    conserve_knowledge
                      ? 'caution'
                      : 'default'
                  }
                  content={
                    conserve_knowledge
                      ? 'Conserving'
                      : 'Consuming'
                  }
                  tooltip={
                    conserve_knowledge
                      ? 'Skills will NOT'
                        + ' consume knowledge'
                      : 'Skills will consume'
                        + ' knowledge on hit'
                  }
                  onClick={() => act(
                    'toggle_conserve'
                  )}
                />
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
                        <Table.Cell
                          collapsing
                        >
                          <Button
                            icon="times"
                            color="bad"
                            onClick={() =>
                              act('remove_active',
                                { index: i + 1 })}
                          />
                        </Table.Cell>
                      </Table.Row>
                    )
                  )}
                </Table>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
