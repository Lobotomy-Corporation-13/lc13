import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Flex, Icon, NumberInput, Section, Stack, Tabs,
} from '../components';
import { Window } from '../layouts';

export const GridDebugVendor = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    movement_types = [],
    grades = [],
  } = data;

  const [selectedMovement, setSelectedMovement] = useLocalState(
    context, 'movement', 1
  );
  const [selectedGrade, setSelectedGrade] = useLocalState(
    context, 'grade', 1
  );
  const [quantityMod, setQuantityMod] = useLocalState(
    context, 'quantity', 1.0
  );
  const [bypasses, setBypasses] = useLocalState(
    context, 'bypasses', false
  );

  const selectedGradeData = grades.find(g => g.id === selectedGrade) || {};

  return (
    <Window
      width={400}
      height={500}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section
              title={(
                <Box>
                  <Icon name="bug" mr={1} />
                  Debug Core Spawner
                </Box>
              )}>
              <Box color="bad" fontSize="11px" mb={1}>
                DEBUG TOOL - Creates free navigation cores
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Movement Type">
              <Tabs fluid>
                {movement_types.map(mt => (
                  <Tabs.Tab
                    key={mt.id}
                    selected={selectedMovement === mt.id}
                    onClick={() => setSelectedMovement(mt.id)}>
                    {mt.name.split(' ')[0]}
                  </Tabs.Tab>
                ))}
              </Tabs>
              <Box fontSize="11px" color="label" mt={1}>
                {movement_types.find(m => m.id === selectedMovement)?.name}
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Grade">
              <Tabs fluid>
                {grades.map(g => (
                  <Tabs.Tab
                    key={g.id}
                    selected={selectedGrade === g.id}
                    onClick={() => setSelectedGrade(g.id)}>
                    {g.name}
                  </Tabs.Tab>
                ))}
              </Tabs>
              <Box fontSize="11px" color="label" mt={1}>
                Dist: {selectedGradeData.min_dist}-{selectedGradeData.max_dist}
                {' | Max Tier: '}{selectedGradeData.max_tier}
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Quantity Modifier">
              <Flex align="center">
                <Flex.Item>
                  <Button
                    icon="minus"
                    onClick={() => setQuantityMod(
                      Math.max(0.5, quantityMod - 0.1)
                    )} />
                </Flex.Item>
                <Flex.Item grow textAlign="center">
                  <Box bold fontSize="16px">
                    {Math.round(quantityMod * 100)}%
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Button
                    icon="plus"
                    onClick={() => setQuantityMod(
                      Math.min(1.5, quantityMod + 0.1)
                    )} />
                </Flex.Item>
              </Flex>
              <Box fontSize="11px" color="label" mt={1}>
                50% = 5u chem | 100% = 15u | 150% = 25u
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Advanced Chem">
              <Button
                fluid
                icon={bypasses ? 'check-square' : 'square'}
                selected={bypasses}
                content={bypasses
                  ? 'Bypasses Quantity (Level 3+ chem)'
                  : 'Normal Quantity Rules'}
                onClick={() => setBypasses(!bypasses)} />
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Spawn">
              <Stack vertical fill>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="gem"
                    color="good"
                    content="Spawn Navigation Core"
                    onClick={() => act('spawn_core', {
                      movement_type: selectedMovement,
                      grade: selectedGrade,
                      quantity_mod: quantityMod,
                      bypasses: bypasses ? 1 : 0,
                    })} />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    fluid
                    icon="file"
                    content="Spawn Empty Template"
                    onClick={() => act('spawn_template', {
                      grade: selectedGrade,
                    })} />
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
