import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Icon, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';

export const OutpostPlanner = (props, context) => {
  const { data } = useBackend(context);

  const [mainTab, setMainTab] = useLocalState(context, 'mainTab', 'blueprints');

  return (
    <Window
      width={480}
      height={520}>
      <Window.Content>
        <Stack fill vertical>
          {/* Main Tab Selection */}
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="drafting-compass"
                selected={mainTab === 'blueprints'}
                onClick={() => setMainTab('blueprints')}>
                Blueprints
              </Tabs.Tab>
              <Tabs.Tab
                icon="home"
                selected={mainTab === 'rooms'}
                onClick={() => setMainTab('rooms')}>
                Rooms
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          {/* Tab Content */}
          <Stack.Item grow>
            {mainTab === 'blueprints' ? (
              <BlueprintTab />
            ) : (
              <RoomTab />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// ===== Blueprint Tab =====
const BlueprintTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    categories = [],
    selected_category,
    selected_name,
    selected_direction,
  } = data;

  const [
    activeCategory,
    setActiveCategory,
  ] = useLocalState(context, 'activeCategory', selected_category || categories[0]?.name);

  const currentCategory = categories.find(cat => cat.name === activeCategory) || categories[0];
  const structures = currentCategory?.structures || [];

  return (
    <Section
      fill
      title="Blueprint Planner"
      buttons={(
        <Button
          icon="times"
          content="Clear"
          disabled={!selected_name}
          onClick={() => act('clear_selection')} />
      )}>
      <Stack fill vertical>
        {/* Category Tabs */}
        <Stack.Item>
          <Tabs fluid>
            {categories.map(category => (
              <Tabs.Tab
                key={category.name}
                selected={category.name === activeCategory}
                onClick={() => {
                  setActiveCategory(category.name);
                  act('select_category', { category: category.name });
                }}>
                {category.name}
              </Tabs.Tab>
            ))}
          </Tabs>
        </Stack.Item>

        {/* Structure Grid */}
        <Stack.Item grow>
          <Section
            fill
            scrollable
            title={activeCategory}>
            <Flex wrap="wrap" justify="flex-start">
              {structures.map(structure => (
                <Flex.Item
                  key={structure.name}
                  basis="48%"
                  mb={1}
                  mr={1}>
                  <StructureCard
                    structure={structure}
                    selected={selected_name === structure.name} />
                </Flex.Item>
              ))}
            </Flex>
          </Section>
        </Stack.Item>

        {/* Direction Selection */}
        <Stack.Item>
          <Section title="Facing Direction">
            <Flex justify="center" align="center">
              <Flex.Item>
                <Button
                  icon="arrow-up"
                  selected={selected_direction === "north"}
                  onClick={() => act('set_direction', { direction: 'north' })}
                  tooltip="North" />
              </Flex.Item>
            </Flex>
            <Flex justify="center" align="center">
              <Flex.Item>
                <Button
                  icon="arrow-left"
                  selected={selected_direction === "west"}
                  onClick={() => act('set_direction', { direction: 'west' })}
                  tooltip="West" />
              </Flex.Item>
              <Flex.Item mx={2}>
                <Box bold textAlign="center" style={{ textTransform: 'capitalize' }}>
                  {selected_direction || "south"}
                </Box>
              </Flex.Item>
              <Flex.Item>
                <Button
                  icon="arrow-right"
                  selected={selected_direction === "east"}
                  onClick={() => act('set_direction', { direction: 'east' })}
                  tooltip="East" />
              </Flex.Item>
            </Flex>
            <Flex justify="center" align="center">
              <Flex.Item>
                <Button
                  icon="arrow-down"
                  selected={selected_direction === "south"}
                  onClick={() => act('set_direction', { direction: 'south' })}
                  tooltip="South" />
              </Flex.Item>
            </Flex>
          </Section>
        </Stack.Item>

        {/* Selection Info */}
        <Stack.Item>
          <Section>
            {selected_name ? (
              <Box>
                <Box bold color="good" mb={1}>
                  <Icon name="check" mr={1} />
                  Selected: {selected_name}
                </Box>
                <Box color="label">
                  Click on the ground to place the blueprint.
                </Box>
              </Box>
            ) : (
              <Box color="label" italic>
                Select a structure above to begin.
              </Box>
            )}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const StructureCard = (props, context) => {
  const { act } = useBackend(context);
  const { structure, selected } = props;

  return (
    <Button
      fluid
      selected={selected}
      onClick={() => act('select_structure', {
        name: structure.name,
        type: structure.type,
      })}>
      <Box>
        <Box bold mb={0.5}>
          {structure.name}
        </Box>
        <Box fontSize="11px" color="label">
          {structure.materials.map((mat, index) => (
            <Box key={index}>
              {mat.amount}x {mat.name}
            </Box>
          ))}
        </Box>
      </Box>
    </Button>
  );
};

// ===== Room Tab =====
const RoomTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    in_room,
    room_name,
    room_type,
    room_faith_modifier,
    room_size,
    room_walls,
    room_doors,
    can_designate,
    detected_size,
    detected_type,
    detected_faith,
    detected_walls,
    detected_doors,
    in_use,
  } = data;

  return (
    <Section fill title="Room Management">
      <Stack fill vertical>
        {in_room ? (
          // Currently in a designated room
          <>
            <Stack.Item>
              <Section title="Current Room">
                <Box mb={1}>
                  <Box bold fontSize="16px" color="good" mb={1}>
                    <Icon name="home" mr={1} />
                    {room_name}
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Type:</Box>
                    {room_type}
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Faith Modifier:</Box>
                    <Box inline color={room_faith_modifier?.includes('+') ? 'good' : 'bad'}>
                      {room_faith_modifier}
                    </Box>
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Size:</Box>
                    {room_size} tiles
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Boundary:</Box>
                    {room_walls} walls, {room_doors} doors
                  </Box>
                </Box>
              </Section>
            </Stack.Item>

            <Stack.Item grow>
              <Section fill title="Actions">
                <Stack vertical>
                  <Stack.Item>
                    <Button
                      fluid
                      icon="eye"
                      content="Highlight Room"
                      disabled={in_use}
                      onClick={() => act('highlight_room')} />
                  </Stack.Item>
                  <Stack.Item mt={1}>
                    <Button
                      fluid
                      icon="trash"
                      color="bad"
                      content="Dissolve Room"
                      disabled={in_use}
                      onClick={() => act('dissolve_room')} />
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>

            <Stack.Item>
              <Section>
                <Box color="label" italic>
                  <Icon name="info-circle" mr={1} />
                  If any walls or doors forming the boundary are destroyed,
                  the room will automatically dissolve.
                </Box>
              </Section>
            </Stack.Item>
          </>
        ) : can_designate ? (
          // Not in a room, but can designate one
          <>
            <Stack.Item>
              <Section title="Detected Enclosed Space">
                <Box mb={1}>
                  <Box bold fontSize="14px" color="good" mb={1}>
                    <Icon name="check-circle" mr={1} />
                    Valid space detected!
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Detected Type:</Box>
                    {detected_type}
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Faith Modifier:</Box>
                    <Box inline color={detected_faith?.includes('+') ? 'good' : 'average'}>
                      {detected_faith}
                    </Box>
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Size:</Box>
                    {detected_size} tiles
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Boundary:</Box>
                    {detected_walls} walls, {detected_doors} doors
                  </Box>
                </Box>
              </Section>
            </Stack.Item>

            <Stack.Item grow>
              <Section fill title="Designate Room">
                <Box mb={2}>
                  The room type is automatically determined by the structures inside:
                </Box>
                <Box fontSize="12px" mb={2}>
                  <Box><b>Workshop</b>: Crafting stations (forge, loom, table)</Box>
                  <Box><b>Shrine</b>: Monuments or statues</Box>
                  <Box><b>Common Room</b>: Decorations, no production</Box>
                  <Box><b>Storage Room</b>: Only storage containers</Box>
                  <Box><b>Basic Room</b>: Enclosed with no special structures</Box>
                </Box>
                <Button
                  fluid
                  icon="plus"
                  color="good"
                  content="Designate This Space"
                  disabled={in_use}
                  onClick={() => act('designate_room')} />
              </Section>
            </Stack.Item>
          </>
        ) : (
          // Not in a room and cannot designate
          <Stack.Item grow>
            <Section fill title="No Enclosed Space">
              <Box textAlign="center" mt={4}>
                <Icon name="times-circle" size={4} color="bad" />
                <Box mt={2} bold fontSize="14px">
                  Not in an enclosed space
                </Box>
                <Box mt={1} color="label">
                  You must be standing in a fully enclosed area
                  with walls on all sides to designate a room.
                </Box>
                <Box mt={2} color="label">
                  Doors (wood, metal, etc.) count as valid walls.
                </Box>
              </Box>
            </Section>
          </Stack.Item>
        )}
      </Stack>
    </Section>
  );
};
