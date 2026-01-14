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

export const SkillAugmentCatalogue = (props, context) => {
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
                    Create Order
                  </Tabs.Tab>
                  <Tabs.Tab
                    selected={tabIndex === 3}
                    onClick={() => setTabIndex(3)}
                  >
                    Services
                  </Tabs.Tab>
                </Tabs>
              </Stack.Item>
              <Stack.Item grow>
                {tabIndex === 0 && <TemplateSelection />}
                {tabIndex === 1 && <SkillConfiguration />}
                {tabIndex === 2 && <CreateOrderTab />}
                {tabIndex === 3 && <ServicesTab />}
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item basis="300px">
            <Stack vertical fill>
              <Stack.Item>
                <CatalogueInfo />
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
              color="good"
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
                  <LabeledList.Item label="Material Cost">
                    {template.materials_needed}
                  </LabeledList.Item>
                </LabeledList>
                <Button
                  mt={1}
                  fluid
                  content="Select Template"
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

const CreateOrderTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    current_rank,
    current_slots,
    current_charge,
    selected_skills = [],
    material_cost,
    busy,
  } = data;

  const canCreateTicket
    = current_rank > 0 && selected_skills.length > 0 && !busy;

  return (
    <Section title="Create Order Ticket" fill>
      <Stack vertical fill>
        <Stack.Item>
          <NoticeBox color="blue">
            This machine creates order tickets that can be processed by
            authorized staff at the Body Modification Fabricator.
          </NoticeBox>
        </Stack.Item>
        <Stack.Item>
          <Section title="Order Summary">
            <LabeledList>
              <LabeledList.Item label="Template">
                {current_rank > 0 ? `Rank ${current_rank}` : 'None selected'}
              </LabeledList.Item>
              <LabeledList.Item label="Total Slots">
                {current_slots}
              </LabeledList.Item>
              <LabeledList.Item label="Max Charge">
                {current_charge}
              </LabeledList.Item>
              <LabeledList.Item label="Material Cost">
                {material_cost || 0}
              </LabeledList.Item>
              <LabeledList.Item label="Selected Skills">
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
                content={busy ? 'Creating Ticket...' : 'Create Order Ticket'}
                color="good"
                disabled={!canCreateTicket}
                onClick={() => act('create_ticket')}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const CatalogueInfo = (props, context) => {
  const { act, data } = useBackend(context);

  return (
    <Section title="Catalogue Information">
      <Box fontSize="0.9em">
        <Box mb={1}>
          <Box bold color="blue">Free Design Tool</Box>
          <Box>
            Design modifications without materials. Created tickets can be
            processed by authorized staff.
          </Box>
        </Box>
        <Box mb={1}>
          <Box bold color="green">Authorized Staff:</Box>
          <Box fontSize="0.8em">
            Prosthetics Surgeon, Office Director, Office Fixer,
            Doctor, Fixer, Workshop Attendant
          </Box>
        </Box>
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
    material_cost,
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
            <LabeledList.Item label="Cost">
              {material_cost || 0} material
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

const ServicesTab = (props, context) => {
  const { act, data } = useBackend(context);
  const { scan_cost, removal_cost, busy } = data;

  return (
    <Section title="Body Modification Services" fill>
      <Stack vertical>
        <Stack.Item>
          <Section title="Scanning Service">
            <Stack>
              <Stack.Item grow>
                <Box>
                  Scan your current body modifications and stat compatibility.
                  Shows your maximum compatible rank and installed skills.
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="search"
                  content={`Scan (${scan_cost} Ahn)`}
                  disabled={busy}
                  onClick={() => act('scan_user')}
                />
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Section title="Removal Service">
            <Stack>
              <Stack.Item grow>
                <Box>
                  Safely remove your current body modification.
                  This process is irreversible and will destroy the
                  modification.
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="trash"
                  content={`Remove (${removal_cost} Ahn)`}
                  disabled={busy}
                  onClick={() => act('remove_modification')}
                  color="bad"
                />
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <NoticeBox>
            <Box>
              <b>Note:</b> Both services require sufficient Ahn in your bank
              account.
              Payment is automatically deducted upon service
              completion.
            </Box>
          </NoticeBox>
        </Stack.Item>
      </Stack>
    </Section>
  );
};