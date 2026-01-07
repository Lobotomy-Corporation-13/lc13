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
    outpost_x,
    outpost_y,
    selected_x,
    selected_y,
    selected_tile,
    planned_route = [],
    route_cost = 0,
    generated = false,
  } = data;

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
                </Box>
              }>
              {generated ? (
                <WorldMapGrid
                  width={map_width}
                  height={map_height}
                  tiles={tiles}
                  factions={factions}
                  outpost_x={outpost_x}
                  outpost_y={outpost_y}
                  selected_x={selected_x}
                  selected_y={selected_y}
                  planned_route={planned_route}
                  act={act}
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
                      {selected_tile ? selected_tile.terrain_name : 'No Selection'}
                    </Box>
                  }
                  buttons={
                    selected_x > 0 && (
                      <Button
                        icon="times"
                        tooltip="Clear Selection"
                        onClick={() => act('clear_selection')}
                      />
                    )
                  }>
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
                    />
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

const WorldMapGrid = (props) => {
  const {
    width,
    height,
    tiles,
    factions,
    outpost_x,
    outpost_y,
    selected_x,
    selected_y,
    planned_route,
    act,
  } = props;

  const mapPixelWidth = width * TILE_SIZE + MAP_PADDING * 2;
  const mapPixelHeight = height * TILE_SIZE + MAP_PADDING * 2;

  // Build a lookup for tiles by coordinates
  const tileMap = {};
  tiles.forEach((tile) => {
    tileMap[`${tile.x},${tile.y}`] = tile;
  });

  // Build a set of route coordinates for highlighting
  const routeSet = new Set();
  planned_route.forEach((point) => {
    routeSet.add(`${point.x},${point.y}`);
  });

  // Convert grid coords to pixel coords
  const toPixelX = (x) => MAP_PADDING + (x - 1) * TILE_SIZE;
  const toPixelY = (y) => MAP_PADDING + (height - y) * TILE_SIZE;

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

          return (
            <g
              key={index}
              style={{ cursor: tile.discovered ? 'pointer' : 'default' }}
              onClick={() => {
                if (tile.discovered) {
                  act('select_tile', { x: tile.x, y: tile.y });
                }
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
              {!tile.discovered && (
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
              {tile.faction_id && !isOutpost && tile.discovered && (
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
      </svg>
    </Box>
  );
};

const TileInfo = (props) => {
  const { tile } = props;

  if (!tile.discovered) {
    return (
      <Box color="label" textAlign="center">
        <Icon name="question" size={2} mb={1} />
        <Box>Unexplored Territory</Box>
        <Box fontSize="11px">Send an expedition to discover this area.</Box>
      </Box>
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

const RouteInfo = (props) => {
  const { route, cost, act } = props;

  const travelTime = Math.round(cost * 30);
  const minutes = Math.floor(travelTime / 60);
  const seconds = travelTime % 60;

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
      <Stack.Item mt={1}>
        <Button
          fluid
          icon="hiking"
          color="good"
          content="Plan Expedition"
          onClick={() => act('plan_expedition')}
        />
      </Stack.Item>
    </Stack>
  );
};

const TerrainLegend = () => {
  const terrains = [
    { name: 'Plains', color: '#4a7c3f' },
    { name: 'Forest', color: '#2d5a27' },
    { name: 'Mountain', color: '#8b8b8b' },
    { name: 'Desert', color: '#c2b280' },
    { name: 'Ruins', color: '#6b5b4f' },
    { name: 'Outpost', color: '#3366cc' },
    { name: 'Faction', color: '#cc9933' },
  ];

  return (
    <Flex wrap="wrap">
      {terrains.map((t, i) => (
        <Flex.Item key={i} basis="50%" mb={0.5}>
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
          <Box as="span" fontSize="11px">
            {t.name}
          </Box>
        </Flex.Item>
      ))}
    </Flex>
  );
};

const getFactionColor = (factionId) => {
  const colors = {
    resurgence_clan: '#66aaff',
    jiajia_ren: '#ffaa44',
    santata_factory: '#aa44aa',
    cloud_town: '#44cc44',
    insurgence_clan: '#cc4444',
  };
  return colors[factionId] || '#cc9933';
};

const getFactionLetter = (factionId) => {
  const letters = {
    resurgence_clan: 'R',
    jiajia_ren: 'J',
    santata_factory: 'S',
    cloud_town: 'C',
    insurgence_clan: 'X',
  };
  return letters[factionId] || '?';
};

const getFactionName = (factionId) => {
  const names = {
    resurgence_clan: 'Resurgence Clan Village',
    jiajia_ren: 'Jiajia-ren Village',
    santata_factory: "Santata's Gift Factory",
    cloud_town: 'Cloud Town',
    insurgence_clan: 'Insurgence Clan Territory',
  };
  return names[factionId] || 'Unknown Faction';
};
