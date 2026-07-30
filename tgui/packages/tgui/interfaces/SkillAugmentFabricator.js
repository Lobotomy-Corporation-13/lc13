import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const SkillAugmentFabricator = (props, context) => {
  const { act, data } = useBackend(context);
  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 0);

  return (
    <Window width={1200} height={700}>
      <Window.Content scrollable>
        <Stack fill>
          <Stack.Item grow>
            <Stack vertical fill>
              <Stack.Item>
                <Tabs fluid>
                  <Tabs.Tab
                    selected={tabIndex === 0}
                    onClick={() => setTabIndex(0)}
                  >
                    Template Selection
                  </Tabs.Tab>
                  <Tabs.Tab
                    selected={tabIndex === 1}
                    onClick={() => setTabIndex(1)}
                  >
                    Skill Configuration
                  </Tabs.Tab>
                  <Tabs.Tab
                    selected={tabIndex === 2}
                    onClick={() => setTabIndex(2)}
                  >
                    Fabrication
                  </Tabs.Tab>
                </Tabs>
              </Stack.Item>
              <Stack.Item grow>
                {tabIndex === 0 && <TemplateSelection />}
                {tabIndex === 1 && <SkillConfiguration />}
                {tabIndex === 2 && <FabricationTab />}
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item basis="300px">
            <Stack vertical fill>
              <Stack.Item>
                <MaterialsDisplay />
              </Stack.Item>
              <Stack.Item grow>
                <CurrentDesign />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const TemplateSelection = (props, context) => {
  const { act, data } = useBackend(context);
  const { templates = [] } = data;

  return (
    <Section title="Select Body Modification Template" fill scrollable>
      <Stack vertical>
        {templates.map(template => (
          <Stack.Item key={template.name}>
            <Collapsible
              title={`${template.name} (Rank ${template.rank})`}
              color={template.can_afford ? 'good' : 'bad'}
            >
              <Box p={1}>
                <LabeledList>
                  <LabeledList.Item label="Rank">
                    {template.rank}
                  </LabeledList.Item>
                  <LabeledList.Item label="Slots">
                    {template.slots}
                  </LabeledList.Item>
                  <LabeledList.Item label="Max Charge">
                    {template.charge}
                  </LabeledList.Item>
                  <LabeledList.Item label="Materials Required">
                    {template.materials_needed}
                  </LabeledList.Item>
                </LabeledList>
                <Button
                  mt={1}
                  fluid
                  content="Select Template"
                  disabled={!template.can_afford}
                  onClick={() => act('select_template', {
                    template: template.name,
                  })}
                />
              </Box>
            </Collapsible>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const SkillConfiguration = (props, context) => {
  const { act, data } = useBackend(context);
  const [searchText, setSearchText] = useLocalState(context, 'skillSearch', '');
  const {
    current_rank,
    current_slots,
    total_slot_cost,
    available_skills = [],
    selected_skills = [],
  } = data;

  if (current_rank === 0) {
    return (
      <Section title="Skill Configuration" fill>
        <NoticeBox color="yellow">
          Please select a template from the Template Selection tab first!
        </NoticeBox>
      </Section>
    );
  }

  const remaining_slots = current_slots - total_slot_cost;

  // Filter skills based on search text
  const filteredSkills = available_skills.filter(skill =>
    skill.name.toLowerCase().includes(searchText.toLowerCase())
    || skill.desc.toLowerCase().includes(searchText.toLowerCase())
  );

  return (
    <Section title="Configure Skills" fill scrollable>
      <Stack vertical fill>
        <Stack.Item>
          <Box bold mb={1}>
            Slots Used: {total_slot_cost} / {current_slots} ({remaining_slots}{' '}
            remaining)
          </Box>
          <ProgressBar
            value={total_slot_cost}
            maxValue={current_slots}
            color={remaining_slots > 0 ? 'good' : 'bad'}
          />
        </Stack.Item>
        <Stack.Item grow>
          <Stack fill>
            <Stack.Item grow={3}>
              <Section title="Available Skills" fill scrollable>
                <Stack vertical fill>
                  <Stack.Item>
                    <Input
                      placeholder="Search skills..."
                      value={searchText}
                      onInput={(e, value) => setSearchText(value)}
                      fluid
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    {filteredSkills.length === 0 ? (
                      <Box color="gray" textAlign="center" p={2}>
                        {searchText ? 'No skills match your search' : 'No skills available for this rank'}
                      </Box>
                    ) : (
                      <Table compact>
                        <Table.Row header>
                          <Table.Cell>Skill</Table.Cell>
                          <Table.Cell>Description</Table.Cell>
                          <Table.Cell textAlign="center" width="8%">Level</Table.Cell>
                          <Table.Cell textAlign="center" width="8%">Slots</Table.Cell>
                          <Table.Cell textAlign="center" width="8%">Charge</Table.Cell>
                          <Table.Cell textAlign="center" width="10%">Action</Table.Cell>
                        </Table.Row>
                        {filteredSkills.map(skill => (
                          <Table.Row key={skill.type_path}>
                            <Table.Cell>
                              <Box
                                bold
                                color={skill.can_add ? 'white' : 'gray'}
                              >
                                {skill.name}
                              </Box>
                            </Table.Cell>
                            <Table.Cell>
                              <Box
                                fontSize="0.9em"
                                color={skill.can_add ? 'label' : 'gray'}
                              >
                                {skill.desc}
                              </Box>
                            </Table.Cell>
                            <Table.Cell textAlign="center">{skill.skill_level}</Table.Cell>
                            <Table.Cell textAlign="center">{skill.slot_cost}</Table.Cell>
                            <Table.Cell textAlign="center">{skill.charge_cost}</Table.Cell>
                            <Table.Cell textAlign="center">
                              <Button
                                content="Add"
                                color="good"
                                fluid
                                disabled={!skill.can_add}
                                onClick={() => act('add_skill', {
                                  skill_type: skill.type_path,
                                })}
                              />
                            </Table.Cell>
                          </Table.Row>
                        ))}
                      </Table>
                    )}
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
            <Stack.Item grow={1}>
              <Section title="Selected Skills" fill>
                {selected_skills.length === 0 ? (
                  <Box color="gray" textAlign="center" p={2}>
                    No skills selected
                  </Box>
                ) : (
                  <Stack vertical>
                    {selected_skills.map(skill => (
                      <Stack.Item key={skill.type_path}>
                        <Flex align="center" p={1}>
                          <Flex.Item grow>
                            <Box fontSize="0.9em">
                              <Box bold>{skill.name}</Box>
                              <Box color="gray">
                                {skill.slot_cost} slots,{' '}
                                {skill.charge_cost} charge
                              </Box>
                            </Box>
                          </Flex.Item>
                          <Flex.Item>
                            <Button
                              content="Remove"
                              icon="times"
                              color="bad"
                              size={0.8}
                              onClick={() => act('remove_skill', {
                                skill_type: skill.type_path,
                              })}
                            />
                          </Flex.Item>
                        </Flex>
                      </Stack.Item>
                    ))}
                  </Stack>
                )}
              </Section>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const FabricationTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    current_rank,
    current_slots,
    current_charge,
    selected_skills = [],
    busy,
  } = data;

  const canFabricate
    = current_rank > 0 && selected_skills.length > 0 && !busy;

  return (
    <Section title="Fabrication" fill>
      <Stack vertical fill>
        <Stack.Item>
          <Section title="Design Summary">
            <LabeledList>
              <LabeledList.Item label="Rank">{current_rank}</LabeledList.Item>
              <LabeledList.Item label="Total Slots">
                {current_slots}
              </LabeledList.Item>
              <LabeledList.Item label="Max Charge">
                {current_charge}
              </LabeledList.Item>
              <LabeledList.Item label="Attached Skills">
                {selected_skills.length}
              </LabeledList.Item>
            </LabeledList>
          </Section>
        </Stack.Item>
        <Stack.Item>
          <Section title="Selected Skills">
            {selected_skills.length === 0 ? (
              <Box color="gray">No skills selected</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Skill</Table.Cell>
                  <Table.Cell>Slot Cost</Table.Cell>
                  <Table.Cell>Charge Cost</Table.Cell>
                </Table.Row>
                {selected_skills.map(skill => (
                  <Table.Row key={skill.type_path}>
                    <Table.Cell>{skill.name}</Table.Cell>
                    <Table.Cell>{skill.slot_cost}</Table.Cell>
                    <Table.Cell>{skill.charge_cost}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        </Stack.Item>
        <Stack.Item grow />
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Button
                fluid
                content="Clear Design"
                color="bad"
                disabled={busy}
                onClick={() => act('clear_design')}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                content={busy ? 'Fabricating...' : 'Fabricate Body Modification'}
                color="good"
                disabled={!canFabricate}
                onClick={() => act('fabricate')}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const MaterialsDisplay = (props, context) => {
  const { act, data } = useBackend(context);
  const { total_materials = 0 } = data;

  return (
    <Section title="Stored Materials">
      <LabeledList>
        <LabeledList.Item label="Total Material">
          <Box bold fontSize="1.2em" color={total_materials > 0 ? 'good' : 'gray'}>
            {total_materials}
          </Box>
        </LabeledList.Item>
      </LabeledList>
      <Box mt={1} fontSize="0.9em" color="label">
        Insert any tresmetal to add materials
      </Box>
    </Section>
  );
};

const CurrentDesign = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    current_rank,
    current_slots,
    current_charge,
    total_slot_cost,
    selected_skills = [],
  } = data;

  return (
    <Section title="Current Design" fill>
      <Stack vertical fill>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Rank">
              {current_rank || 'None'}
            </LabeledList.Item>
            <LabeledList.Item label="Slots">
              {total_slot_cost} / {current_slots}
            </LabeledList.Item>
            <LabeledList.Item label="Max Charge">
              {current_charge}
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item grow>
          <Section title="Skills" fill scrollable>
            {selected_skills.length === 0 ? (
              <Box color="gray">No skills</Box>
            ) : (
              <Stack vertical>
                {selected_skills.map(skill => (
                  <Stack.Item key={skill.type_path}>
                    <Box fontSize="0.9em">
                      • {skill.name} ({skill.slot_cost}s/{skill.charge_cost}c)
                    </Box>
                  </Stack.Item>
                ))}
              </Stack>
            )}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

