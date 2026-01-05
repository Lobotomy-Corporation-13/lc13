import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Flex, Icon, Section, Stack, Table,
} from '../components';
import { Window } from '../layouts';

const MAP_SIZE = 300;

export const GridCraftingStation = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    focus_x,
    focus_y,
    cores_used,
    selected_core,
    available_cores = [],
    nearby_items = [],
    craftable_items = [],
    last_crafted,
    stored_count = 0,
    max_stored = 50,
    max_revealed_tier = 1,
    debug_mode = false,
  } = data;

  // Zoom level: 1 = far out, 5 = close up
  const [zoom, setZoom] = useLocalState(context, 'zoom', 2);

  const zoomIn = () => setZoom(Math.min(zoom + 1, 5));
  const zoomOut = () => setZoom(Math.max(zoom - 1, 1));

  return (
    <Window
      width={700}
      height={650}>
      <Window.Content>
        <Stack fill>
          {/* Left Side - Map */}
          <Stack.Item basis="320px">
            <Stack vertical fill>
              {/* Map Display */}
              <Stack.Item grow>
                <Section
                  fill
                  title={(
                    <Box>
                      <Icon name="map" mr={1} />
                      Grid Map - ({focus_x}, {focus_y})
                    </Box>
                  )}
                  buttons={(
                    <Box>
                      <Button
                        icon="search-minus"
                        tooltip="Zoom Out"
                        disabled={zoom <= 1}
                        onClick={zoomOut} />
                      <Button
                        icon="search-plus"
                        tooltip="Zoom In"
                        disabled={zoom >= 5}
                        onClick={zoomIn} />
                      <Button
                        icon="undo"
                        content="Reset"
                        disabled={cores_used === 0}
                        onClick={() => act('reset')} />
                    </Box>
                  )}>
                  <GridMap
                    focus_x={focus_x}
                    focus_y={focus_y}
                    items={nearby_items}
                    craftable_items={craftable_items}
                    zoom={zoom}
                    max_revealed_tier={max_revealed_tier}
                    debug_mode={debug_mode} />
                </Section>
              </Stack.Item>

              {/* Movement Controls */}
              <Stack.Item>
                <Section title="Movement">
                  <MovementControls
                    selected_core={selected_core}
                    focus_x={focus_x}
                    focus_y={focus_y}
                    act={act} />
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          {/* Right Side - Cores and Items */}
          <Stack.Item grow>
            <Stack vertical fill>
              {/* Craftable Items Alert */}
              {craftable_items.length > 0 && (
                <Stack.Item>
                  <Section
                    title={(
                      <Box color="good">
                        <Icon name="check-circle" mr={1} />
                        Weapons In Range!
                      </Box>
                    )}>
                    <Stack vertical>
                      {craftable_items.map((item, index) => (
                        <Stack.Item key={index}>
                          <Flex align="center">
                            <Flex.Item grow>
                              <Box bold>
                                {getTierIcon(item.tier)} {item.name}
                              </Box>
                            </Flex.Item>
                            <Flex.Item>
                              <Button
                                icon="hammer"
                                color="good"
                                content="Craft"
                                onClick={() => act('craft', { id: item.id })} />
                            </Flex.Item>
                          </Flex>
                        </Stack.Item>
                      ))}
                    </Stack>
                  </Section>
                </Stack.Item>
              )}

              {/* Cores Section */}
              <Stack.Item grow>
                <Section
                  fill
                  scrollable
                  title={(
                    <Box>
                      <Icon name="gem" mr={1} />
                      Stored Cores ({stored_count}/{max_stored})
                    </Box>
                  )}>
                  <CoresSection
                    cores={available_cores}
                    selected_core={selected_core}
                    stored_count={stored_count}
                    max_stored={max_stored}
                    act={act} />
                </Section>
              </Stack.Item>

              {/* Nearby Items */}
              <Stack.Item grow>
                <Section
                  fill
                  scrollable
                  title={(
                    <Box>
                      <Icon name="crosshairs" mr={1} />
                      Nearby Weapons
                    </Box>
                  )}>
                  <NearbyItems items={nearby_items} />
                </Section>
              </Stack.Item>

              {/* Last Crafted */}
              {last_crafted && (
                <Stack.Item>
                  <Box color="good" textAlign="center" py={1}>
                    <Icon name="check" mr={1} />
                    Last Crafted: {last_crafted}
                  </Box>
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const GridMap = (props) => {
  const {
    focus_x,
    focus_y,
    items,
    craftable_items,
    zoom = 2,
    max_revealed_tier = 1,
    debug_mode = false,
  } = props;

  // Zoom scales: 1=0.5, 2=1.0, 3=2.0, 4=3.0, 5=5.0 pixels per unit
  const zoomScales = { 1: 0.5, 2: 1.0, 3: 2.0, 4: 3.0, 5: 5.0 };
  const MAP_SCALE = zoomScales[zoom] || 1.0;

  // Calculate view radius based on zoom (how far we can see)
  const viewRadius = (MAP_SIZE / 2) / MAP_SCALE + 20;
  const centerX = MAP_SIZE / 2;
  const centerY = MAP_SIZE / 2;

  // Convert world coords to screen coords
  const toScreenX = (x) => centerX + (x - focus_x) * MAP_SCALE;
  const toScreenY = (y) => centerY - (y - focus_y) * MAP_SCALE;

  // Filter items to show (within view radius)
  const visibleItems = items.filter(item => {
    const dist = Math.sqrt(
      Math.pow(item.x - focus_x, 2) + Math.pow(item.y - focus_y, 2)
    );
    return dist < viewRadius + item.radius;
  });

  return (
    <Box
      style={{
        position: 'relative',
        width: MAP_SIZE + 'px',
        height: MAP_SIZE + 'px',
        backgroundColor: '#1a1a2e',
        border: '2px solid #444',
        borderRadius: '4px',
        overflow: 'hidden',
      }}>
      {/* Grid lines */}
      <svg
        width={MAP_SIZE}
        height={MAP_SIZE}
        style={{ position: 'absolute', top: 0, left: 0 }}>
        {/* Grid spacing varies with zoom */}
        {(() => {
          // Adjust grid spacing based on zoom level
          const gridSpacing = zoom <= 2 ? 50 : (zoom <= 3 ? 25 : 10);
          const gridCount = Math.ceil(viewRadius / gridSpacing) * 2 + 2;
          const lines = [];

          // Vertical grid lines
          for (let i = 0; i < gridCount; i++) {
            const worldX = Math.round(focus_x / gridSpacing) * gridSpacing
              + (i - Math.floor(gridCount / 2)) * gridSpacing;
            const screenX = toScreenX(worldX);
            if (screenX >= -10 && screenX <= MAP_SIZE + 10) {
              lines.push(
                <line
                  key={`v${i}`}
                  x1={screenX}
                  y1={0}
                  x2={screenX}
                  y2={MAP_SIZE}
                  stroke={worldX === 0 ? '#555' : '#333'}
                  strokeWidth={worldX === 0 ? 2 : 1} />
              );
            }
          }

          // Horizontal grid lines
          for (let i = 0; i < gridCount; i++) {
            const worldY = Math.round(focus_y / gridSpacing) * gridSpacing
              + (i - Math.floor(gridCount / 2)) * gridSpacing;
            const screenY = toScreenY(worldY);
            if (screenY >= -10 && screenY <= MAP_SIZE + 10) {
              lines.push(
                <line
                  key={`h${i}`}
                  x1={0}
                  y1={screenY}
                  x2={MAP_SIZE}
                  y2={screenY}
                  stroke={worldY === 0 ? '#555' : '#333'}
                  strokeWidth={worldY === 0 ? 2 : 1} />
              );
            }
          }

          return lines;
        })()}

        {/* Weapon zones */}
        {visibleItems.map((item, index) => {
          const screenX = toScreenX(item.x);
          const screenY = toScreenY(item.y);
          const screenRadius = item.radius * MAP_SCALE;
          const isInRange = item.in_range;
          const tierColor = getTierColor(item.tier);

          return (
            <g key={index}>
              {/* Craft radius circle */}
              <circle
                cx={screenX}
                cy={screenY}
                r={screenRadius}
                fill={isInRange ? tierColor + '40' : tierColor + '20'}
                stroke={isInRange ? '#00ff00' : tierColor}
                strokeWidth={isInRange ? 2 : 1}
                strokeDasharray={isInRange ? '' : '4,4'} />
              {/* Center point */}
              <circle
                cx={screenX}
                cy={screenY}
                r={3}
                fill={tierColor} />
            </g>
          );
        })}

        {/* Focus point (player position) */}
        <circle
          cx={centerX}
          cy={centerY}
          r={6}
          fill="#00ff00"
          stroke="#ffffff"
          strokeWidth={2} />
        <circle
          cx={centerX}
          cy={centerY}
          r={10}
          fill="none"
          stroke="#00ff00"
          strokeWidth={1}
          strokeDasharray="2,2" />
      </svg>

      {/* Origin indicator */}
      {Math.abs(focus_x) < viewRadius && Math.abs(focus_y) < viewRadius && (
        <Box
          style={{
            position: 'absolute',
            left: toScreenX(0) - 10 + 'px',
            top: toScreenY(0) - 10 + 'px',
            color: '#666',
            fontSize: '10px',
          }}>
          (0,0)
        </Box>
      )}

      {/* Legend */}
      <Box
        style={{
          position: 'absolute',
          bottom: '4px',
          left: '4px',
          fontSize: '9px',
          color: '#888',
        }}>
        <Icon name="circle" color="#00ff00" /> You
        {' | '}
        Zoom: {zoom}x
        {' | '}
        Tier: {max_revealed_tier}
        {debug_mode && ' (DEBUG)'}
      </Box>
    </Box>
  );
};

const MovementControls = (props) => {
  const { selected_core, focus_x, focus_y, act } = props;

  const canMove = (dx, dy) => {
    if (!selected_core) {
      return false;
    }
    const mt = selected_core.movement_type;
    if (mt === 1) {
      return (dx === 0) !== (dy === 0);
    }
    if (mt === 2) {
      return dx !== 0 && dy !== 0;
    }
    if (mt === 3) {
      return dx !== 0 || dy !== 0;
    }
    if (mt === 4) {
      return true;
    }
    return false;
  };

  if (!selected_core) {
    return (
      <Box color="label" textAlign="center">
        <Icon name="exclamation-triangle" mr={1} />
        Select a core to move
      </Box>
    );
  }

  // Teleport controls for gold cores
  if (selected_core.movement_type === 4) {
    return (
      <TeleportControls
        focus_x={focus_x}
        focus_y={focus_y}
        max_range={selected_core.distance_range[1]}
        act={act} />
    );
  }

  // Direction buttons for other cores
  return (
    <Box>
      <Box fontSize="11px" color="label" mb={1}>
        {selected_core.movement_desc} | Range:{' '}
        {selected_core.distance_range[0]}-{selected_core.distance_range[1]}
      </Box>
      <Box textAlign="center">
        <DirBtn dir="NW" dx={-1} dy={1} enabled={canMove(-1, 1)} act={act} />
        <DirBtn dir="N" dx={0} dy={1} enabled={canMove(0, 1)} act={act} />
        <DirBtn dir="NE" dx={1} dy={1} enabled={canMove(1, 1)} act={act} />
      </Box>
      <Box textAlign="center">
        <DirBtn dir="W" dx={-1} dy={0} enabled={canMove(-1, 0)} act={act} />
        <Button width="50px" height="32px" disabled>
          <Icon name="crosshairs" />
        </Button>
        <DirBtn dir="E" dx={1} dy={0} enabled={canMove(1, 0)} act={act} />
      </Box>
      <Box textAlign="center">
        <DirBtn dir="SW" dx={-1} dy={-1} enabled={canMove(-1, -1)} act={act} />
        <DirBtn dir="S" dx={0} dy={-1} enabled={canMove(0, -1)} act={act} />
        <DirBtn dir="SE" dx={1} dy={-1} enabled={canMove(1, -1)} act={act} />
      </Box>
    </Box>
  );
};

const DirBtn = (props) => {
  const { dir, dx, dy, enabled, act } = props;
  const arrows = {
    N: 'arrow-up', S: 'arrow-down', E: 'arrow-right', W: 'arrow-left',
    NE: 'arrow-up', NW: 'arrow-up', SE: 'arrow-down', SW: 'arrow-down',
  };

  return (
    <Button
      width="50px"
      height="32px"
      disabled={!enabled}
      onClick={() => act('move', { x: dx, y: dy })}>
      <Icon name={arrows[dir]} />
    </Button>
  );
};

const TeleportControls = (props, context) => {
  const { focus_x, focus_y, max_range, act } = props;
  const [targetX, setTargetX] = useLocalState(context, 'teleportX', focus_x);
  const [targetY, setTargetY] = useLocalState(context, 'teleportY', focus_y);

  const distance = Math.sqrt(
    Math.pow(targetX - focus_x, 2) + Math.pow(targetY - focus_y, 2)
  );
  const inRange = distance <= max_range;

  return (
    <Box>
      <Box fontSize="11px" color="label" mb={1}>
        Teleport anywhere within {max_range} units
      </Box>
      <Flex mb={1}>
        <Flex.Item basis="30px">X:</Flex.Item>
        <Flex.Item>
          <Button icon="minus" onClick={() => setTargetX(targetX - 5)} />
        </Flex.Item>
        <Flex.Item basis="40px" textAlign="center">{targetX}</Flex.Item>
        <Flex.Item>
          <Button icon="plus" onClick={() => setTargetX(targetX + 5)} />
        </Flex.Item>
        <Flex.Item grow />
        <Flex.Item basis="30px">Y:</Flex.Item>
        <Flex.Item>
          <Button icon="minus" onClick={() => setTargetY(targetY - 5)} />
        </Flex.Item>
        <Flex.Item basis="40px" textAlign="center">{targetY}</Flex.Item>
        <Flex.Item>
          <Button icon="plus" onClick={() => setTargetY(targetY + 5)} />
        </Flex.Item>
      </Flex>
      <Button
        fluid
        icon="bolt"
        color={inRange ? 'good' : 'bad'}
        disabled={!inRange}
        content={`Teleport (${distance.toFixed(0)}/${max_range})`}
        onClick={() => act('teleport', { x: targetX, y: targetY })} />
    </Box>
  );
};

const CoresSection = (props) => {
  const { cores, selected_core, act, stored_count, max_stored } = props;

  if (cores.length === 0) {
    return (
      <Box textAlign="center" color="label">
        <Icon name="gem" size={2} mb={1} />
        <Box>No cores in storage</Box>
        <Box fontSize="11px">Insert cores by using them on the machine</Box>
      </Box>
    );
  }

  return (
    <Stack vertical>
      {cores.map((core, index) => {
        const isSelected = selected_core && selected_core.name === core.name;
        return (
          <Stack.Item key={index}>
            <Flex align="center">
              <Flex.Item grow>
                <Button
                  fluid
                  selected={isSelected}
                  onClick={() => act('select_core', { ref: core.ref })}>
                  <Flex align="center">
                    <Flex.Item>
                      <Icon
                        name="gem"
                        color={getCoreColor(core.ore_type)}
                        mr={1} />
                    </Flex.Item>
                    <Flex.Item grow>
                      {core.gilded
                        && <Icon name="star" color="gold" mr={1} />}
                      {core.name}
                    </Flex.Item>
                    <Flex.Item color="label" fontSize="11px">
                      {getMovementShort(core.movement_type)}
                    </Flex.Item>
                  </Flex>
                </Button>
              </Flex.Item>
              <Flex.Item ml={1}>
                <Button
                  icon="eject"
                  tooltip="Retrieve"
                  onClick={() => act('retrieve_core', { ref: core.ref })} />
              </Flex.Item>
            </Flex>
          </Stack.Item>
        );
      })}
    </Stack>
  );
};

const NearbyItems = (props) => {
  const { items } = props;

  if (items.length === 0) {
    return (
      <Box textAlign="center" color="label">
        No weapons nearby
      </Box>
    );
  }

  return (
    <Stack vertical>
      {items.slice(0, 8).map((item, index) => (
        <Stack.Item key={index}>
          <Flex align="center">
            <Flex.Item grow>
              <Box
                bold={item.in_range}
                color={item.in_range ? 'good' : 'default'}>
                {getTierIcon(item.tier)} {item.name}
              </Box>
            </Flex.Item>
            <Flex.Item color="label" fontSize="11px">
              {item.distance.toFixed(0)}u
              {item.in_range && <Icon name="check" color="good" ml={1} />}
            </Flex.Item>
          </Flex>
        </Stack.Item>
      ))}
    </Stack>
  );
};

const getCoreColor = (oreType) => {
  const colors = {
    iron: '#8B5A2B',
    silver: '#C0C0C0',
    alloy: '#808080',
    gold: '#FFD700',
  };
  return colors[oreType] || 'white';
};

const getTierColor = (tier) => {
  // Tier colors: 0=gray, 1=green, 2=blue, 3=purple, 4=gold
  const colors = ['#666666', '#22cc44', '#4488ff', '#cc44ff', '#ffcc00'];
  return colors[tier] || '#666666';
};

const getMovementShort = (movementType) => {
  const names = { 1: 'Cardinal', 2: 'Diagonal', 3: '8-Dir', 4: 'Teleport' };
  return names[movementType] || '?';
};

const getTierIcon = (tier) => {
  const icons = ['circle', 'star', 'star', 'crown', 'crown'];
  const colors = ['label', 'average', 'good', 'blue', 'gold'];
  return (
    <Icon
      name={icons[tier] || 'circle'}
      color={colors[tier] || 'label'}
      mr={1} />
  );
};
