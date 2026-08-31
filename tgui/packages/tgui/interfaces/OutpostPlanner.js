import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Flex, Icon, Input, Section, Stack, Tabs,
} from '../components';
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
              <Tabs.Tab
                icon="seedling"
                selected={mainTab === 'farming'}
                onClick={() => setMainTab('farming')}>
                Farming
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          {/* Tab Content */}
          <Stack.Item grow>
            {mainTab === 'blueprints' && <BlueprintTab />}
            {mainTab === 'rooms' && <RoomTab />}
            {mainTab === 'farming' && <FarmingTab />}
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
  ] = useLocalState(
    context,
    'activeCategory',
    selected_category || categories[0]?.name
  );

  const [searchText, setSearchText] = useLocalState(
    context,
    'blueprintSearch',
    ''
  );

  const currentCategory = categories.find(
    cat => cat.name === activeCategory
  )
    || categories[0];

  // Get all structures for searching, or current category's structures
  let structures = [];
  if (searchText) {
    // Search across all categories
    const search = searchText.toLowerCase();
    for (const cat of categories) {
      for (const struct of cat.structures || []) {
        if (struct.name.toLowerCase().includes(search)
            || struct.result_name?.toLowerCase().includes(search)) {
          structures.push(struct);
        }
      }
    }
  } else {
    structures = currentCategory?.structures || [];
  }

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
        {/* Search Bar */}
        <Stack.Item>
          <Flex align="center">
            <Flex.Item grow>
              <Input
                fluid
                placeholder="Search blueprints..."
                value={searchText}
                onInput={(e, value) => setSearchText(value)} />
            </Flex.Item>
            {searchText && (
              <Flex.Item ml={1}>
                <Button
                  icon="times"
                  tooltip="Clear search"
                  onClick={() => setSearchText('')} />
              </Flex.Item>
            )}
          </Flex>
        </Stack.Item>

        {/* Category Tabs (hidden when searching) */}
        {!searchText && (
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
        )}

        {/* Structure Grid */}
        <Stack.Item grow>
          <Section
            fill
            scrollable
            title={searchText
              ? `Search Results (${structures.length})`
              : activeCategory}>
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
                <Box
                  bold
                  textAlign="center"
                  style={{ textTransform: 'capitalize' }}>
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
  const isLocked = structure.is_locked;

  return (
    <Button
      fluid
      selected={selected && !isLocked}
      disabled={isLocked}
      style={{
        opacity: isLocked ? 0.5 : 1,
      }}
      onClick={() => act('select_structure', {
        name: structure.name,
        type: structure.type,
      })}>
      <Box>
        <Box bold mb={0.5}>
          {!!isLocked && <Icon name="lock" color="bad" mr={1} />}
          {structure.name}
        </Box>
        {isLocked ? (
          <Box fontSize="11px" color="bad">
            <Icon name="flask" mr={0.5} />
            Requires: {structure.lock_reason}
          </Box>
        ) : (
          <Box fontSize="11px" color="label">
            {structure.materials.map((mat, index) => (
              <Box key={index}>
                {mat.amount}x {mat.name}
              </Box>
            ))}
          </Box>
        )}
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
    room_size,
    room_walls,
    room_doors,
    room_beauty,
    room_beauty_avg,
    beauty_breakdown = [],
    user_ckey,
    user_has_bed,
    user_owns_bed_here,
    room_bed_count,
    is_barracks,
    can_designate,
    detected_size,
    detected_type,
    detected_valid_types = [],
    detected_walls,
    detected_doors,
    detected_is_cramped,
    in_use,
  } = data;

  const [showBreakdown, setShowBreakdown] = useLocalState(
    context,
    'showBeautyBreakdown',
    false
  );

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
                    <Box inline bold mr={1}>Size:</Box>
                    {room_size} tiles
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Boundary:</Box>
                    {room_walls} walls, {room_doors} doors
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Beauty:</Box>
                    <Box
                      inline
                      color={
                        room_beauty_avg > 0
                          ? 'good'
                          : room_beauty_avg < 0
                            ? 'bad'
                            : 'label'
                      }>
                      {room_beauty} total ({room_beauty_avg}/tile)
                    </Box>
                    <Button
                      ml={1}
                      icon={showBreakdown ? 'chevron-up' : 'chevron-down'}
                      tooltip="Show beauty breakdown"
                      onClick={() => setShowBreakdown(!showBreakdown)} />
                  </Box>
                  {showBreakdown && (
                    <BeautyBreakdown breakdown={beauty_breakdown} />
                  )}
                  {(room_type === 'Living Quarters'
                    || room_type === 'Barracks') && (
                    <Box>
                      <Box inline bold mr={1}>Sleepers:</Box>
                      <Box inline color={room_bed_count > 0 ? 'good' : 'label'}>
                        {room_bed_count}
                        {user_owns_bed_here && ' (You own one here)'}
                      </Box>
                    </Box>
                  )}
                </Box>
              </Section>
            </Stack.Item>

            <Stack.Item grow>
              <Section fill title="Actions">
                <Stack vertical>
                  {(room_type === 'Living Quarters'
                    || room_type === 'Barracks') && (
                    <Stack.Item>
                      <Box color="label" fontSize="12px" mb={1}>
                        <Icon name="bed" mr={1} />
                        To claim a sleeper, enter it and use the stats menu.
                        {room_type === 'Living Quarters'
                          && ' Grants +0.025 faith/tick when claimed.'}
                        {room_type === 'Barracks'
                          && ' Barracks sleepers remove the homeless penalty.'}
                      </Box>
                    </Stack.Item>
                  )}
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
                      icon="sync"
                      content="Recalculate Beauty"
                      disabled={in_use}
                      tooltip="Reset and recount all beauty in this room"
                      onClick={() => act('recalculate_beauty')} />
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
                  <Box mb={1}>
                    <Box bold mr={1}>
                      {detected_valid_types.length > 1
                        ? "Valid Room Types:"
                        : "Detected Type:"}
                    </Box>
                    {detected_valid_types.length > 1 ? (
                      <Box ml={1}>
                        {detected_valid_types.map((rtype, index) => (
                          <Box key={index} color="good">
                            <Icon name="check" mr={1} />
                            {rtype}
                          </Box>
                        ))}
                      </Box>
                    ) : (
                      <Box inline color="good">{detected_type}</Box>
                    )}
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Size:</Box>
                    {detected_size} tiles
                    {!!detected_is_cramped && (
                      <Box inline color="average" ml={1}>
                        (Cramped)
                      </Box>
                    )}
                  </Box>
                  <Box>
                    <Box inline bold mr={1}>Boundary:</Box>
                    {detected_walls} walls, {detected_doors} doors
                  </Box>
                  {!!detected_is_cramped && (
                    <Box color="average" mt={1} fontSize="11px">
                      <Icon name="compress-alt" mr={1} />
                      This space is cramped. Only Living Quarters and
                      Common Rooms can be designated here.
                    </Box>
                  )}
                </Box>
              </Section>
            </Stack.Item>

            <Stack.Item grow>
              <Section fill title="Designate Room">
                {detected_valid_types.length > 1 ? (
                  <Box mb={2} color="good">
                    <Icon name="list" mr={1} />
                    This room qualifies as multiple types! You will be
                    able to choose which type to designate.
                  </Box>
                ) : (
                  <Box mb={2}>
                    The room type is automatically determined by
                    the structures inside:
                  </Box>
                )}
                <RoomTypeGuide />
                <Button
                  fluid
                  icon="plus"
                  color="good"
                  content={detected_valid_types.length > 1
                    ? "Choose Room Type..."
                    : "Designate This Space"}
                  disabled={in_use}
                  onClick={() => act('designate_room')} />
              </Section>
            </Stack.Item>
          </>
        ) : detected_is_cramped ? (
          // Space is too cramped for any valid room type
          <>
            <Stack.Item>
              <Section title="Cramped Space">
                <Box textAlign="center">
                  <Icon name="compress-alt" size={3} color="average" />
                  <Box mt={1} bold fontSize="14px">
                    Space is too cramped
                  </Box>
                  <Box mt={1} color="label">
                    This enclosed space has {detected_size} tiles, which is
                    too small for the detected room type.
                  </Box>
                  <Box mt={1} color="label">
                    Most room types require more than 9 tiles and dimensions
                    of at least 3x3.
                  </Box>
                  <Box mt={1} color="good">
                    Only Living Quarters and Common Rooms can be cramped.
                    Add a bed for Living Quarters, or a table and chair
                    for a Common Room.
                  </Box>
                </Box>
              </Section>
            </Stack.Item>
            <Stack.Item grow>
              <Section fill scrollable title="Room Types Reference">
                <RoomTypeGuide />
              </Section>
            </Stack.Item>
          </>
        ) : (
          // Not in a room and cannot designate
          <>
            <Stack.Item>
              <Section title="No Enclosed Space">
                <Box textAlign="center">
                  <Icon name="times-circle" size={3} color="bad" />
                  <Box mt={1} bold fontSize="14px">
                    Not in an enclosed space
                  </Box>
                  <Box mt={1} color="label">
                    You must be standing in a fully enclosed area
                    with walls on all sides to designate a room.
                  </Box>
                  <Box mt={1} color="label">
                    Doors (wood, metal, etc.) count as valid walls.
                  </Box>
                </Box>
              </Section>
            </Stack.Item>
            <Stack.Item grow>
              <Section fill scrollable title="Room Types Reference">
                <RoomTypeGuide />
              </Section>
            </Stack.Item>
          </>
        )}
      </Stack>
    </Section>
  );
};

// ===== Beauty Breakdown Component =====
const BeautyBreakdown = props => {
  const { breakdown = [] } = props;

  if (breakdown.length === 0) {
    return (
      <Box color="label" fontSize="11px" mt={1} ml={2}>
        No beauty contributors found.
      </Box>
    );
  }

  // Group items by name and sum their beauty values
  const grouped = {};
  for (const item of breakdown) {
    const key = item.name + '|' + item.type;
    if (grouped[key]) {
      grouped[key].count += 1;
      grouped[key].totalBeauty += item.beauty;
    } else {
      grouped[key] = {
        name: item.name,
        type: item.type,
        beauty: item.beauty,
        count: 1,
        totalBeauty: item.beauty,
      };
    }
  }

  // Convert to array and sort by absolute total beauty
  const items = Object.values(grouped).sort(
    (a, b) => Math.abs(b.totalBeauty) - Math.abs(a.totalBeauty)
  );

  // Get icon for source type
  const getIcon = type => {
    switch (type) {
      case 'turf':
        return 'square';
      case 'structure':
        return 'cube';
      case 'machine':
        return 'cog';
      case 'mob':
        return 'user';
      case 'item':
        return 'box';
      default:
        return 'question';
    }
  };

  return (
    <Box
      mt={1}
      ml={2}
      p={1}
      style={{
        background: 'rgba(0, 0, 0, 0.2)',
        borderRadius: '3px',
        maxHeight: '120px',
        overflowY: 'auto',
      }}>
      <Box fontSize="10px" color="label" mb={0.5}>
        Beauty Contributors:
      </Box>
      {items.map((item, index) => (
        <Flex key={index} fontSize="11px" mb={0.25}>
          <Flex.Item basis="15px">
            <Icon name={getIcon(item.type)} color="label" />
          </Flex.Item>
          <Flex.Item grow>
            {item.name}
            {item.count > 1 && ` (x${item.count})`}
          </Flex.Item>
          <Flex.Item basis="50px" textAlign="right">
            <Box
              inline
              bold
              color={item.totalBeauty > 0
                ? 'good'
                : item.totalBeauty < 0
                  ? 'bad'
                  : 'label'}>
              {item.totalBeauty > 0 ? '+' : ''}{item.totalBeauty}
            </Box>
          </Flex.Item>
        </Flex>
      ))}
    </Box>
  );
};

// ===== Room Type Guide =====
const RoomTypeGuide = () => {
  const roomTypes = [
    {
      name: 'Living Quarters',
      requirements: 'Wooden Sleeper (personal room)',
      canBeCramped: true,
    },
    {
      name: 'Barracks',
      requirements: '2+ Wooden Sleepers (shared, no faith bonus)',
      canBeCramped: false,
    },
    {
      name: 'Common Room',
      requirements: 'Table + Chair',
      canBeCramped: true,
    },
    {
      name: 'Workshop',
      requirements: 'Crafting Table, Forge, or Loom',
      canBeCramped: false,
    },
    {
      name: 'Kitchen',
      requirements: 'Stove or Fridge',
      canBeCramped: false,
    },
    {
      name: 'Storage Room',
      requirements: 'Crates/closets',
      canBeCramped: false,
    },
    {
      name: 'Export Warehouse',
      requirements: 'Resources Recorder',
      canBeCramped: false,
    },
    {
      name: 'Basic Room',
      requirements: 'Any enclosed space',
      canBeCramped: false,
    },
  ];

  return (
    <Box fontSize="11px" mb={2}>
      {roomTypes.map((room, index) => (
        <Flex key={index} mb={0.5} align="center">
          <Flex.Item basis="35%">
            <Box bold>{room.name}</Box>
          </Flex.Item>
          <Flex.Item grow>
            <Box color="label">{room.requirements}</Box>
          </Flex.Item>
          <Flex.Item basis="12%">
            {room.canBeCramped ? (
              <Box color="good" textAlign="right">
                <Icon name="compress-alt" />
              </Box>
            ) : (
              <Box color="bad" textAlign="right">
                <Icon name="expand-alt" />
              </Box>
            )}
          </Flex.Item>
        </Flex>
      ))}
      <Box color="label" mt={1} fontSize="10px">
        <Icon name="compress-alt" color="good" mr={1} />
        Can be cramped
        <Box inline ml={2}>
          <Icon name="expand-alt" color="bad" mr={1} />
          Requires {'>'}9 tiles, 3x3 min
        </Box>
      </Box>
    </Box>
  );
};

// ===== Farming Tab =====
const FarmingTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    farming_mode,
    farming_selection,
    farming_max,
    existing_zones = [],
    fertilizer_count = 0,
  } = data;

  return (
    <Section fill title="Farming Zones">
      <Stack fill vertical>
        {/* Zone Creation */}
        <Stack.Item>
          <Section title="Create New Zone">
            <Box mb={1}>
              Select up to {farming_max} tiles to create a farming zone.
              Each plot requires 1 fertilizer to create.
            </Box>
            <Box mb={1} color={fertilizer_count > 0 ? "good" : "bad"}>
              <Icon name="seedling" mr={1} />
              Fertilizer available: {fertilizer_count}
            </Box>
            <Box mb={1} color="label" fontSize="11px">
              <Icon name="fire" mr={1} />
              Fertilizer is crafted from coal at a Crafting Table.
            </Box>
            <Button
              fluid
              icon={farming_mode ? "times" : "seedling"}
              color={farming_mode ? "bad" : "good"}
              content={
                farming_mode ? "Cancel Selection" : "Start Selecting Tiles"
              }
              disabled={fertilizer_count < 1 && !farming_mode}
              onClick={() => act('toggle_farming_mode')} />
            {!!farming_mode && (
              <Box mt={1}>
                <Box bold mb={1}>
                  <Icon name="hand-pointer" mr={1} />
                  Click tiles on the ground to select them.
                </Box>
                <Box
                  bold
                  color={
                    farming_selection <= fertilizer_count ? "good" : "bad"
                  }
                  mb={1}>
                  Selected: {farming_selection} / {farming_max}
                  {farming_selection > fertilizer_count && (
                    <Box color="bad">
                      (Need {farming_selection} fertilizer,
                      have {fertilizer_count})
                    </Box>
                  )}
                </Box>
                <Stack>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="check"
                      color="good"
                      disabled={
                        farming_selection < 1
                        || farming_selection > fertilizer_count
                      }
                      content="Create Zone"
                      onClick={() => act('confirm_farming_zone')} />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="eraser"
                      disabled={farming_selection < 1}
                      content="Clear Selection"
                      onClick={() => act('clear_farming_selection')} />
                  </Stack.Item>
                </Stack>
              </Box>
            )}
          </Section>
        </Stack.Item>

        {/* Existing Zones */}
        <Stack.Item grow>
          <Section fill scrollable title="Existing Zones">
            {existing_zones.length > 0 ? (
              <Stack vertical>
                {existing_zones.map(zone => (
                  <Stack.Item key={zone.id}>
                    <FarmingZoneCard zone={zone} />
                  </Stack.Item>
                ))}
              </Stack>
            ) : (
              <Box italic color="label" textAlign="center" mt={2}>
                <Icon name="seedling" size={2} mb={1} />
                <Box>No farming zones created yet.</Box>
                <Box mt={1}>Create a zone to start growing crops!</Box>
              </Box>
            )}
          </Section>
        </Stack.Item>

        {/* Info */}
        <Stack.Item>
          <Section>
            <Box color="label" fontSize="12px">
              <Icon name="info-circle" mr={1} />
              Plant seeds in plots and water them regularly.
              Crops will grow over time and can be harvested when ready.
            </Box>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const FarmingZoneCard = (props, context) => {
  const { act, data } = useBackend(context);
  const { zone } = props;
  const { fertilizer_count = 0 } = data;

  const hasMissingPlots = zone.missing_count > 0;
  const canRegenerate = hasMissingPlots
    && fertilizer_count >= zone.missing_count;

  return (
    <Section
      title={(
        <Box inline>
          <Icon name="seedling" mr={1} color="good" />
          {zone.name}
        </Box>
      )}
      buttons={(
        <>
          {hasMissingPlots && (
            <Button
              icon="sync"
              color={canRegenerate ? "good" : "bad"}
              tooltip={canRegenerate
                ? `Regenerate ${zone.missing_count} missing plots`
                : `Need ${zone.missing_count} fertilizer`}
              onClick={() => act('regenerate_plots', { id: zone.id })} />
          )}
          <Button
            icon="eye"
            tooltip="Highlight Zone"
            onClick={() => act('highlight_zone', { id: zone.id })} />
          <Button
            icon="trash"
            color="bad"
            tooltip="Dissolve Zone"
            onClick={() => act('dissolve_zone', { id: zone.id })} />
        </>
      )}>
      <Flex>
        <Flex.Item grow>
          <Box color={hasMissingPlots ? "bad" : "label"}>
            <Icon name="th" mr={1} />
            Plots: {zone.plot_count}/{zone.total_turfs}
            {hasMissingPlots && ` (${zone.missing_count} missing)`}
          </Box>
        </Flex.Item>
        <Flex.Item grow>
          <Box color={zone.ready_count > 0 ? "good" : "label"}>
            <Icon name="check-circle" mr={1} />
            Ready: {zone.ready_count}
          </Box>
        </Flex.Item>
        <Flex.Item grow>
          <Box
            color={
              zone.avg_water < 20
                ? "bad"
                : zone.avg_water < 50
                  ? "average"
                  : "good"
            }>
            <Icon name="tint" mr={1} />
            Water: {zone.avg_water}%
          </Box>
        </Flex.Item>
      </Flex>
    </Section>
  );
};
