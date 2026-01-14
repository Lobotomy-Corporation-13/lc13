import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Icon, Section, Stack } from '../components';
import { Window } from '../layouts';

const TILE_SIZE = 28;
const MAP_PADDING = 10;

export const ResurgenceWorldMap = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    map_width = 15,
    map_height = 15,
    tiles = [],
    factions = [],
    caravans = [],
    raid_caravans = [],
    outpost_x,
    outpost_y,
    selected_x,
    selected_y,
    selected_tile,
    planned_route = [],
    route_cost = 0,
    generated = false,
    debug_mode = false,
    has_expedition = false,
    expedition = null,
    user_in_expedition = false,
    user_is_leader = false,
    // Portable device fields
    is_portable = false,
    on_expedition = false,
    expedition_state = '',
    current_x = 0,
    current_y = 0,
  } = data;

  const hasRaidCaravans = raid_caravans.length > 0;

  const mapPixelWidth = map_width * TILE_SIZE + MAP_PADDING * 2;
  const mapPixelHeight = map_height * TILE_SIZE + MAP_PADDING * 2;

  return (
    <Window width={750} height={600}>
      <Window.Content>
        <Stack fill>
          {/* Left Side - Map */}
          <Stack.Item>
            <Section
              title={
                <Box>
                  <Icon name="map" mr={1} />
                  World Map
                  {debug_mode && (
                    <Box as="span" ml={1} color="orange">
                      [DEBUG]
                    </Box>
                  )}
                </Box>
              }
              buttons={
                <Button
                  icon={debug_mode ? 'eye' : 'eye-slash'}
                  tooltip="Toggle Debug Mode (No Fog)"
                  selected={debug_mode}
                  onClick={() => act('toggle_debug')}
                />
              }>
              {/* Raid Warning Banner */}
              {hasRaidCaravans && (
                <Box
                  p={1}
                  mb={1}
                  textAlign="center"
                  bold
                  style={{
                    backgroundColor: '#660000',
                    border: '2px solid #ff0000',
                    borderRadius: '4px',
                    color: '#ff6666',
                    animation: 'pulse 1s infinite',
                  }}>
                  <Icon name="skull-crossbones" mr={1} />
                  RAID INCOMING - Hostile caravan approaching!
                  <Icon name="skull-crossbones" ml={1} />
                </Box>
              )}
              {generated ? (
                <WorldMapGrid
                  width={map_width}
                  height={map_height}
                  tiles={tiles}
                  factions={factions}
                  caravans={caravans}
                  raidCaravans={raid_caravans}
                  outpost_x={outpost_x}
                  outpost_y={outpost_y}
                  selected_x={selected_x}
                  selected_y={selected_y}
                  planned_route={planned_route}
                  debug_mode={debug_mode}
                  act={act}
                  current_x={current_x}
                  current_y={current_y}
                  is_portable={is_portable}
                />
              ) : (
                <Box textAlign="center" color="label" p={4}>
                  <Icon name="spinner" spin size={2} />
                  <Box mt={2}>Generating world map...</Box>
                </Box>
              )}
            </Section>
          </Stack.Item>

          {/* Right Side - Info Panel */}
          <Stack.Item grow>
            <Stack vertical fill>
              {/* Selected Tile Info */}
              <Stack.Item grow>
                <Section
                  fill
                  scrollable
                  title={
                    <Box>
                      <Icon name="crosshairs" mr={1} />
                      {selected_tile
                        ? selected_tile.terrain_name
                        : 'No Selection'}
                    </Box>
                  }
                  buttons={selected_x > 0 && (
                    <Button
                      icon="times"
                      tooltip="Clear Selection"
                      onClick={() => act('clear_selection')}
                    />
                  )}>
                  {selected_tile ? (
                    <TileInfo tile={selected_tile} />
                  ) : (
                    <Box color="label" textAlign="center" mt={2}>
                      <Icon name="mouse-pointer" size={2} mb={1} />
                      <Box>Click a tile to select it</Box>
                    </Box>
                  )}
                </Section>
              </Stack.Item>

              {/* Route Info */}
              {planned_route.length > 0 && (
                <Stack.Item>
                  <Section
                    title={
                      <Box>
                        <Icon name="route" mr={1} />
                        Planned Route
                      </Box>
                    }>
                    <RouteInfo
                      route={planned_route}
                      cost={route_cost}
                      act={act}
                      hasExpedition={has_expedition}
                      isPortable={is_portable}
                      onExpedition={on_expedition}
                      expeditionState={expedition_state}
                    />
                  </Section>
                </Stack.Item>
              )}

              {/* Portable Device Status */}
              {is_portable && on_expedition && (
                <Stack.Item>
                  <Section
                    title={
                      <Box>
                        <Icon name="location-arrow" mr={1} />
                        Expedition Status
                      </Box>
                    }>
                    <PortableStatus
                      expeditionState={expedition_state}
                      currentX={current_x}
                      currentY={current_y}
                      act={act}
                    />
                  </Section>
                </Stack.Item>
              )}

              {/* Expedition Panel */}
              {has_expedition && (
                <Stack.Item>
                  <Section
                    title={
                      <Box>
                        <Icon name="hiking" mr={1} />
                        Active Expedition
                      </Box>
                    }>
                    <ExpeditionPanel
                      expedition={expedition}
                      userInExpedition={user_in_expedition}
                      userIsLeader={user_is_leader}
                      act={act}
                    />
                  </Section>
                </Stack.Item>
              )}

              {/* Caravans Panel */}
              {caravans.length > 0 && (
                <Stack.Item>
                  <Section
                    title={
                      <Box>
                        <Icon name="truck" mr={1} />
                        Caravans ({caravans.length})
                      </Box>
                    }>
                    <CaravanList caravans={caravans} />
                  </Section>
                </Stack.Item>
              )}

              {/* Raid Caravans Panel */}
              {hasRaidCaravans && (
                <Stack.Item>
                  <Section
                    title={
                      <Box color="red">
                        <Icon name="skull-crossbones" mr={1} />
                        Hostile Raids ({raid_caravans.length})
                      </Box>
                    }>
                    <RaidCaravanList caravans={raid_caravans} />
                  </Section>
                </Stack.Item>
              )}

              {/* Legend */}
              <Stack.Item>
                <Section title="Legend">
                  <TerrainLegend />
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const WorldMapGrid = props => {
  const {
    width,
    height,
    tiles,
    factions,
    caravans = [],
    raidCaravans = [],
    outpost_x,
    outpost_y,
    selected_x,
    selected_y,
    planned_route,
    debug_mode,
    act,
    current_x = 0,
    current_y = 0,
    is_portable = false,
  } = props;

  const mapPixelWidth = width * TILE_SIZE + MAP_PADDING * 2;
  const mapPixelHeight = height * TILE_SIZE + MAP_PADDING * 2;

  // Build a lookup for tiles by coordinates
  const tileMap = {};
  tiles.forEach(tile => {
    tileMap[`${tile.x},${tile.y}`] = tile;
  });

  // Build a set of route coordinates for highlighting
  const routeSet = new Set();
  planned_route.forEach(point => {
    routeSet.add(`${point.x},${point.y}`);
  });

  // Build a lookup for caravans by position
  const caravanMap = {};
  caravans.forEach(caravan => {
    if (caravan.x && caravan.y) {
      const key = `${caravan.x},${caravan.y}`;
      if (!caravanMap[key]) {
        caravanMap[key] = [];
      }
      caravanMap[key].push(caravan);
    }
  });

  // Convert grid coords to pixel coords
  const toPixelX = x => MAP_PADDING + (x - 1) * TILE_SIZE;
  const toPixelY = y => MAP_PADDING + (height - y) * TILE_SIZE;

  return (
    <Box
      style={{
        position: 'relative',
        width: mapPixelWidth + 'px',
        height: mapPixelHeight + 'px',
        backgroundColor: '#1a1a2e',
        border: '2px solid #444',
        borderRadius: '4px',
        overflow: 'hidden',
      }}>
      <svg
        width={mapPixelWidth}
        height={mapPixelHeight}
        style={{ position: 'absolute', top: 0, left: 0 }}>
        {/* Render tiles */}
        {tiles.map((tile, index) => {
          const px = toPixelX(tile.x);
          const py = toPixelY(tile.y);
          const isSelected = tile.x === selected_x && tile.y === selected_y;
          const isOnRoute = routeSet.has(`${tile.x},${tile.y}`);
          const isOutpost = tile.x === outpost_x && tile.y === outpost_y;
          const isCurrent = is_portable
            && current_x > 0
            && tile.x === current_x
            && tile.y === current_y;

          return (
            <g
              key={index}
              style={{
                cursor: 'pointer',
              }}
              onClick={() => {
                act('select_tile', { x: tile.x, y: tile.y });
              }}>
              {/* Tile background */}
              <rect
                x={px}
                y={py}
                width={TILE_SIZE - 1}
                height={TILE_SIZE - 1}
                fill={tile.tile_color}
                stroke={
                  isSelected
                    ? '#ffffff'
                    : isOnRoute
                      ? '#00ff00'
                      : '#333333'
                }
                strokeWidth={isSelected ? 2 : isOnRoute ? 2 : 1}
                rx={2}
                ry={2}
              />

              {/* Fog of war overlay for undiscovered */}
              {!tile.discovered && !debug_mode && (
                <rect
                  x={px}
                  y={py}
                  width={TILE_SIZE - 1}
                  height={TILE_SIZE - 1}
                  fill="#000000"
                  fillOpacity={0.7}
                  rx={2}
                  ry={2}
                />
              )}

              {/* Outpost marker */}
              {isOutpost && (
                <g>
                  <circle
                    cx={px + TILE_SIZE / 2}
                    cy={py + TILE_SIZE / 2}
                    r={8}
                    fill="#3366cc"
                    stroke="#ffffff"
                    strokeWidth={2}
                  />
                  <text
                    x={px + TILE_SIZE / 2}
                    y={py + TILE_SIZE / 2 + 4}
                    textAnchor="middle"
                    fill="#ffffff"
                    fontSize="10"
                    fontWeight="bold">
                    H
                  </text>
                </g>
              )}

              {/* Faction marker */}
              {tile.faction_id
                && !isOutpost
                && (tile.discovered || debug_mode) && (
                <g>
                  <circle
                    cx={px + TILE_SIZE / 2}
                    cy={py + TILE_SIZE / 2}
                    r={8}
                    fill={getFactionColor(tile.faction_id)}
                    stroke="#ffffff"
                    strokeWidth={1}
                  />
                  <text
                    x={px + TILE_SIZE / 2}
                    y={py + TILE_SIZE / 2 + 3}
                    textAnchor="middle"
                    fill="#ffffff"
                    fontSize="8"
                    fontWeight="bold">
                    {getFactionLetter(tile.faction_id)}
                  </text>
                </g>
              )}

              {/* Current position marker (portable device) */}
              {isCurrent && (
                <g>
                  <circle
                    cx={px + TILE_SIZE / 2}
                    cy={py + TILE_SIZE / 2}
                    r={10}
                    fill="none"
                    stroke="#ff6600"
                    strokeWidth={3}
                  />
                  <circle
                    cx={px + TILE_SIZE / 2}
                    cy={py + TILE_SIZE / 2}
                    r={4}
                    fill="#ff6600"
                  />
                </g>
              )}
            </g>
          );
        })}

        {/* Route path lines */}
        {planned_route.length > 1 && (
          <g>
            {planned_route.map((point, index) => {
              if (index === 0) return null;
              const prev = planned_route[index - 1];
              const x1 = toPixelX(prev.x) + TILE_SIZE / 2;
              const y1 = toPixelY(prev.y) + TILE_SIZE / 2;
              const x2 = toPixelX(point.x) + TILE_SIZE / 2;
              const y2 = toPixelY(point.y) + TILE_SIZE / 2;

              return (
                <line
                  key={index}
                  x1={x1}
                  y1={y1}
                  x2={x2}
                  y2={y2}
                  stroke="#00ff00"
                  strokeWidth={3}
                  strokeLinecap="round"
                  strokeOpacity={0.8}
                />
              );
            })}
          </g>
        )}

        {/* Caravan markers */}
        {caravans.map((caravan, index) => {
          if (!caravan.x || !caravan.y) return null;
          const px = toPixelX(caravan.x);
          const py = toPixelY(caravan.y);
          const isHostile = caravan.is_patrol
            || caravan.faction_id === 'insurgence_clan';
          const isTraveling = caravan.state === 'traveling';

          return (
            <g key={`caravan-${caravan.caravan_id}`}>
              {/* Caravan wagon icon - diamond shape */}
              <g transform={`translate(${px + TILE_SIZE / 2},
                ${py + TILE_SIZE / 2})`}>
                {/* Pulsing ring for traveling caravans */}
                {isTraveling && (
                  <circle
                    r={10}
                    fill="none"
                    stroke={caravan.color || '#cc9933'}
                    strokeWidth={2}
                    opacity={0.6}>
                    <animate
                      attributeName="r"
                      values="6;12;6"
                      dur="2s"
                      repeatCount="indefinite"
                    />
                    <animate
                      attributeName="opacity"
                      values="0.8;0.2;0.8"
                      dur="2s"
                      repeatCount="indefinite"
                    />
                  </circle>
                )}
                {/* Diamond shape for caravan */}
                <polygon
                  points="0,-7 7,0 0,7 -7,0"
                  fill={caravan.color || '#cc9933'}
                  stroke={isHostile ? '#ff0000' : '#ffffff'}
                  strokeWidth={isHostile ? 2 : 1}
                />
                {/* Wagon wheel icon */}
                <circle
                  r={3}
                  fill={isHostile ? '#ff0000' : '#ffffff'}
                />
              </g>
            </g>
          );
        })}

        {/* Raid Caravan markers - hostile styling */}
        {raidCaravans.map((caravan, index) => {
          if (!caravan.x || !caravan.y) return null;
          const px = toPixelX(caravan.x);
          const py = toPixelY(caravan.y);

          return (
            <g key={`raid-caravan-${index}`}>
              <g transform={`translate(${px + TILE_SIZE / 2},
                ${py + TILE_SIZE / 2})`}>
                {/* Danger pulsing ring - red */}
                <circle
                  r={12}
                  fill="none"
                  stroke="#ff0000"
                  strokeWidth={2}
                  opacity={0.8}>
                  <animate
                    attributeName="r"
                    values="8;14;8"
                    dur="1s"
                    repeatCount="indefinite"
                  />
                  <animate
                    attributeName="opacity"
                    values="0.9;0.3;0.9"
                    dur="1s"
                    repeatCount="indefinite"
                  />
                </circle>
                {/* Dark red diamond */}
                <polygon
                  points="0,-8 8,0 0,8 -8,0"
                  fill="#990000"
                  stroke="#ff0000"
                  strokeWidth={2}
                />
                {/* Skull icon - simple representation */}
                <circle cx={0} cy={-1} r={3} fill="#ffffff" />
                <rect x={-2} y={2} width={4} height={3} fill="#ffffff" />
              </g>
            </g>
          );
        })}
      </svg>
    </Box>
  );
};

const TileInfo = props => {
  const { tile } = props;

  if (!tile.discovered) {
    return (
      <Stack vertical>
        <Stack.Item>
          <Box color="label" textAlign="center">
            <Icon name="question" size={2} mb={1} />
            <Box bold>Unexplored Territory</Box>
            <Box fontSize="11px" mb={1}>
              Send an expedition to discover this area.
            </Box>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Flex>
            <Flex.Item grow basis="50%">
              <Box color="label" fontSize="11px">
                Coordinates
              </Box>
              <Box>
                ({tile.x}, {tile.y})
              </Box>
            </Flex.Item>
            <Flex.Item grow basis="50%">
              <Box color="label" fontSize="11px">
                Status
              </Box>
              <Box color="average">
                <Icon name="eye-slash" mr={1} />
                Unknown
              </Box>
            </Flex.Item>
          </Flex>
        </Stack.Item>
      </Stack>
    );
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <Box bold fontSize="14px" mb={1}>
          {tile.terrain_name}
        </Box>
        <Box color="label" fontSize="12px" mb={2}>
          {tile.terrain_desc}
        </Box>
      </Stack.Item>

      <Stack.Item>
        <Flex>
          <Flex.Item grow basis="50%">
            <Box color="label" fontSize="11px">
              Coordinates
            </Box>
            <Box>
              ({tile.x}, {tile.y})
            </Box>
          </Flex.Item>
          <Flex.Item grow basis="50%">
            <Box color="label" fontSize="11px">
              Terrain
            </Box>
            <Box>
              <Box
                as="span"
                style={{
                  display: 'inline-block',
                  width: '12px',
                  height: '12px',
                  backgroundColor: tile.tile_color,
                  borderRadius: '2px',
                  marginRight: '4px',
                  verticalAlign: 'middle',
                }}
              />
              {tile.terrain_type}
            </Box>
          </Flex.Item>
        </Flex>
      </Stack.Item>

      {tile.travel_cost > 0 && (
        <Stack.Item mt={1}>
          <Flex>
            <Flex.Item grow basis="50%">
              <Box color="label" fontSize="11px">
                Travel Cost
              </Box>
              <Box>
                <Icon
                  name="walking"
                  mr={1}
                  color={tile.travel_cost > 1.5 ? 'bad' : 'good'}
                />
                {tile.travel_cost.toFixed(1)}x
              </Box>
            </Flex.Item>
            <Flex.Item grow basis="50%">
              <Box color="label" fontSize="11px">
                Event Chance
              </Box>
              <Box>
                <Icon
                  name="exclamation-triangle"
                  mr={1}
                  color={tile.event_chance > 1.5 ? 'bad' : 'average'}
                />
                {tile.event_chance.toFixed(1)}x
              </Box>
            </Flex.Item>
          </Flex>
        </Stack.Item>
      )}

      {tile.faction_id && (
        <Stack.Item mt={2}>
          <Box
            p={1}
            style={{
              backgroundColor: getFactionColor(tile.faction_id) + '40',
              borderRadius: '4px',
              border: '1px solid ' + getFactionColor(tile.faction_id),
            }}>
            <Icon name="landmark" mr={1} />
            <Box as="span" bold>
              {getFactionName(tile.faction_id)}
            </Box>
            <Box fontSize="11px" color="label" mt={1}>
              {tile.faction_id === 'insurgence_clan'
                ? 'Hostile territory - approach with caution!'
                : 'Trading settlement - visit to trade directly.'}
            </Box>
          </Box>
        </Stack.Item>
      )}
    </Stack>
  );
};

const RouteInfo = props => {
  const {
    route,
    cost,
    act,
    hasExpedition,
    isPortable = false,
    onExpedition = false,
    expeditionState = '',
  } = props;

  const travelTime = Math.round(cost * 30);
  const minutes = Math.floor(travelTime / 60);
  const seconds = travelTime % 60;

  // Portable device can only set destination when at a location
  const canSetDestination = isPortable
    && onExpedition
    && expeditionState === 'at_destination';

  return (
    <Stack vertical>
      <Stack.Item>
        <Flex>
          <Flex.Item grow>
            <Box color="label" fontSize="11px">
              Distance
            </Box>
            <Box>
              <Icon name="ruler" mr={1} />
              {route.length} tiles
            </Box>
          </Flex.Item>
          <Flex.Item grow>
            <Box color="label" fontSize="11px">
              Travel Time
            </Box>
            <Box>
              <Icon name="clock" mr={1} />
              {minutes}m {seconds}s
            </Box>
          </Flex.Item>
        </Flex>
      </Stack.Item>
      {/* Console: Plan new expedition */}
      {!isPortable && !hasExpedition && (
        <Stack.Item mt={1}>
          <Button
            fluid
            icon="hiking"
            color="good"
            content="Plan Expedition"
            onClick={() => act('plan_expedition')}
          />
        </Stack.Item>
      )}
      {/* Portable: Set new destination */}
      {canSetDestination && (
        <Stack.Item mt={1}>
          <Button
            fluid
            icon="map-marker-alt"
            color="good"
            content="Set New Destination"
            onClick={() => act('set_new_destination')}
          />
        </Stack.Item>
      )}
    </Stack>
  );
};

const PortableStatus = props => {
  const { expeditionState, currentX, currentY, act } = props;

  const stateLabels = {
    forming: 'Forming',
    departing: 'Departing',
    traveling: 'Traveling',
    at_destination: 'At Destination',
    returning: 'Returning',
    complete: 'Complete',
    failed: 'Failed',
  };

  const canReturn = expeditionState === 'at_destination';

  return (
    <Stack vertical>
      <Stack.Item>
        <Flex>
          <Flex.Item grow>
            <Box color="label" fontSize="11px">
              Status
            </Box>
            <Box>
              <Icon
                name={expeditionState === 'traveling' ? 'walking' : 'flag'}
                mr={1}
              />
              {stateLabels[expeditionState] || expeditionState}
            </Box>
          </Flex.Item>
          <Flex.Item grow>
            <Box color="label" fontSize="11px">
              Position
            </Box>
            <Box>
              <Icon name="map-pin" mr={1} color="orange" />
              ({currentX}, {currentY})
            </Box>
          </Flex.Item>
        </Flex>
      </Stack.Item>
      {canReturn && (
        <Stack.Item mt={1}>
          <Button
            fluid
            icon="home"
            color="average"
            content="Return to Outpost"
            onClick={() => act('return_to_outpost')}
          />
        </Stack.Item>
      )}
      {expeditionState === 'traveling' && (
        <Stack.Item mt={1}>
          <Box color="label" fontSize="11px" textAlign="center">
            <Icon name="info-circle" mr={1} />
            Reach destination to change route
          </Box>
        </Stack.Item>
      )}
    </Stack>
  );
};

const ExpeditionPanel = props => {
  const { expedition, userInExpedition, userIsLeader, act } = props;

  if (!expedition) {
    return null;
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <Box bold mb={1}>
          <Icon name="users" mr={1} />
          Expedition #{expedition.expedition_id}
        </Box>
        <Box color="label" fontSize="11px">
          Status: {expedition.state}
        </Box>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Box color="label" fontSize="11px">
          Destination
        </Box>
        <Box>
          {expedition.destination_name} ({expedition.destination_x},
          {expedition.destination_y})
        </Box>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Box color="label" fontSize="11px">
          Party ({expedition.member_count} members)
        </Box>
        {expedition.members
          && expedition.members.map((member, i) => (
            <Box key={i} fontSize="12px">
              {member.is_leader && <Icon name="crown" mr={1} color="gold" />}
              {member.name}
            </Box>
          ))}
      </Stack.Item>

      <Stack.Item mt={1}>
        <Box color="label" fontSize="11px">
          Est. Travel Time
        </Box>
        <Box>{expedition.estimated_time}</Box>
      </Stack.Item>

      {/* Tip about crates */}
      {userInExpedition && expedition.state === 'forming' && (
        <Stack.Item mt={1}>
          <Box
            fontSize="10px"
            color="label"
            italic
            style={{
              backgroundColor: 'rgba(50, 100, 50, 0.3)',
              padding: '4px 6px',
              borderRadius: '3px',
            }}>
            <Icon name="box" mr={1} />
            Tip: Place crates near this console before departing to bring
            goods for trading at faction hubs!
          </Box>
        </Stack.Item>
      )}

      <Stack.Item mt={2}>
        {!userInExpedition ? (
          <Button
            fluid
            icon="sign-in-alt"
            color="good"
            content="Join Expedition"
            onClick={() => act('join_expedition')}
          />
        ) : (
          <Stack vertical>
            {userIsLeader && (
              <Stack.Item>
                <Button
                  fluid
                  icon="play"
                  color="good"
                  content="Depart Now"
                  onClick={() => act('depart_expedition')}
                />
              </Stack.Item>
            )}
            <Stack.Item mt={1}>
              <Button
                fluid
                icon="sign-out-alt"
                color={userIsLeader ? 'bad' : 'average'}
                content={userIsLeader
                  ? 'Cancel Expedition'
                  : 'Leave Expedition'}
                onClick={() => act(userIsLeader
                  ? 'cancel_expedition'
                  : 'leave_expedition')}
              />
            </Stack.Item>
          </Stack>
        )}
      </Stack.Item>
    </Stack>
  );
};

const CaravanList = props => {
  const { caravans } = props;

  if (!caravans || caravans.length === 0) {
    return (
      <Box color="label" fontSize="11px">
        No caravans spotted.
      </Box>
    );
  }

  return (
    <Stack vertical>
      {caravans.map(caravan => {
        const isHostile = caravan.is_patrol
          || caravan.faction_id === 'insurgence_clan';
        const stateLabel = getCaravanStateLabel(caravan.state);

        return (
          <Stack.Item key={caravan.caravan_id} mb={0.5}>
            <Box
              p={0.5}
              style={{
                backgroundColor: (caravan.color || '#cc9933') + '30',
                borderRadius: '3px',
                borderLeft: `3px solid ${caravan.color || '#cc9933'}`,
              }}>
              <Flex align="center">
                <Flex.Item>
                  <Icon
                    name={isHostile ? 'skull' : 'truck'}
                    color={isHostile ? 'red' : 'label'}
                    mr={1}
                  />
                </Flex.Item>
                <Flex.Item grow>
                  <Box fontSize="11px" bold>
                    {caravan.name}
                  </Box>
                  <Box fontSize="10px" color="label">
                    ({caravan.x}, {caravan.y}) - {stateLabel}
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Box fontSize="10px" color="label">
                    <Icon name="users" mr={0.5} />
                    {caravan.guard_count}
                  </Box>
                </Flex.Item>
              </Flex>
            </Box>
          </Stack.Item>
        );
      })}
    </Stack>
  );
};

const getCaravanStateLabel = state => {
  const labels = {
    traveling: 'Traveling',
    stopped: 'Stopped',
    at_destination: 'At Destination',
    destroyed: 'Destroyed',
    complete: 'Complete',
  };
  return labels[state] || state;
};

const RaidCaravanList = props => {
  const { caravans } = props;

  if (!caravans || caravans.length === 0) {
    return (
      <Box color="label" fontSize="11px">
        No hostile caravans detected.
      </Box>
    );
  }

  return (
    <Stack vertical>
      {caravans.map((caravan, index) => {
        const stateLabel = getRaidStateLabel(caravan.state);
        const tilesRemaining = caravan.tiles_remaining || '?';
        const etaMinutes = tilesRemaining !== '?'
          ? tilesRemaining * 3
          : '?';

        return (
          <Stack.Item key={index} mb={0.5}>
            <Box
              p={0.5}
              style={{
                backgroundColor: '#990000' + '40',
                borderRadius: '3px',
                borderLeft: '3px solid #ff0000',
              }}>
              <Flex align="center">
                <Flex.Item>
                  <Icon name="skull-crossbones" color="red" mr={1} />
                </Flex.Item>
                <Flex.Item grow>
                  <Box fontSize="11px" bold color="red">
                    {caravan.name || 'Insurgence Raiders'}
                  </Box>
                  <Box fontSize="10px" color="label">
                    ({caravan.x}, {caravan.y}) - {stateLabel}
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Box fontSize="10px" color="average" textAlign="right">
                    <Icon name="clock" mr={0.5} />
                    ETA: ~{etaMinutes}m
                  </Box>
                  <Box fontSize="9px" color="label" textAlign="right">
                    {tilesRemaining} tiles
                  </Box>
                </Flex.Item>
              </Flex>
            </Box>
          </Stack.Item>
        );
      })}
      <Stack.Item>
        <Box fontSize="10px" color="average" italic mt={1}>
          <Icon name="exclamation-triangle" mr={1} />
          Intercept during expeditions or prepare defenses!
        </Box>
      </Stack.Item>
    </Stack>
  );
};

const getRaidStateLabel = state => {
  const labels = {
    traveling: 'Approaching',
    intercepted: 'Intercepted',
    arrived: 'Arrived!',
    destroyed: 'Destroyed',
  };
  return labels[state] || state;
};

const TerrainLegend = () => {
  const terrains = [
    { name: 'Plains', color: '#4a7c3f' },
    { name: 'Forest', color: '#2d5a27' },
    { name: 'Mountain', color: '#8b8b8b' },
    { name: 'Desert', color: '#c2b280' },
    { name: 'Ruins', color: '#6b5b4f' },
    { name: 'Snowfields', color: '#e8e8f0' },
    { name: 'Outpost', color: '#3366cc' },
    { name: 'Faction', color: '#cc9933' },
    { name: 'Caravan', color: '#cc9933', isCaravan: true },
    { name: 'Raid', color: '#990000', isRaid: true },
  ];

  return (
    <Flex wrap="wrap">
      {terrains.map((t, i) => (
        <Flex.Item key={i} basis="50%" mb={0.5}>
          {t.isRaid ? (
            <Box
              as="span"
              style={{
                display: 'inline-block',
                width: '12px',
                height: '12px',
                marginRight: '4px',
                verticalAlign: 'middle',
              }}>
              <svg width="12" height="12" viewBox="-7 -7 14 14">
                <polygon
                  points="0,-5 5,0 0,5 -5,0"
                  fill={t.color}
                  stroke="#ff0000"
                  strokeWidth={1}
                />
              </svg>
            </Box>
          ) : t.isCaravan ? (
            <Box
              as="span"
              style={{
                display: 'inline-block',
                width: '12px',
                height: '12px',
                marginRight: '4px',
                verticalAlign: 'middle',
              }}>
              <svg width="12" height="12" viewBox="-7 -7 14 14">
                <polygon
                  points="0,-5 5,0 0,5 -5,0"
                  fill={t.color}
                  stroke="#ffffff"
                  strokeWidth={1}
                />
              </svg>
            </Box>
          ) : (
            <Box
              as="span"
              style={{
                display: 'inline-block',
                width: '12px',
                height: '12px',
                backgroundColor: t.color,
                borderRadius: '2px',
                marginRight: '4px',
                verticalAlign: 'middle',
              }}
            />
          )}
          <Box as="span" fontSize="11px" color={t.isRaid ? 'red' : undefined}>
            {t.name}
          </Box>
        </Flex.Item>
      ))}
    </Flex>
  );
};

const getFactionColor = factionId => {
  const colors = {
    resurgence_clan: '#66aaff',
    jiajia_ren: '#ffaa44',
    santata_factory: '#aa44aa',
    cloud_town: '#44cc44',
    insurgence_clan: '#cc4444',
  };
  return colors[factionId] || '#cc9933';
};

const getFactionLetter = factionId => {
  const letters = {
    resurgence_clan: 'R',
    jiajia_ren: 'J',
    santata_factory: 'S',
    cloud_town: 'C',
    insurgence_clan: 'X',
  };
  return letters[factionId] || '?';
};

const getFactionName = factionId => {
  const names = {
    resurgence_clan: 'Resurgence Clan Village',
    jiajia_ren: 'Jiajia-ren Village',
    santata_factory: "Santata's Gift Factory",
    cloud_town: 'Cloud Town',
    insurgence_clan: 'Insurgence Clan Territory',
  };
  return names[factionId] || 'Unknown Faction';
};
