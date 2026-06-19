import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Flex, Icon, ProgressBar, Section, Stack,
} from '../components';
import { Window } from '../layouts';

const MAP_SIZE = 300;
const GRID_ZONE_CELL_SIZE = 10;

export const EnkephalinGridStation = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    focus_x,
    focus_y,
    selected_core,
    available_cores = [],
    nearby_items = [],
    craftable_items = [],
    last_crafted,
    stored_count = 0,
    max_stored = 50,
    shuffle_counter = 0,
    shuffle_threshold = 10,
    debug_mode,
    highlighted_item_id,
    crafted_item_ids = [],
    max_accessible_tier = 0,
    ordeal_tier = 0,
    viewing_armor = false,
    zones = [],
    current_zones = [],
    last_movement_type = 3,
    last_dir_x = 0,
    last_dir_y = 0,
    has_previous_move = false,
  } = data;

  const [zoom, setZoom] = useLocalState(context, 'zoom', 2);
  const [hoveredDir, setHoveredDir] = useLocalState(
    context, 'hoveredDir', null
  );

  const zoomIn = () => setZoom(Math.min(zoom + 1, 5));
  const zoomOut = () => setZoom(Math.max(zoom - 1, 1));

  const highlightedItem = highlighted_item_id
    ? nearby_items.find(item => item.id === highlighted_item_id)
    : null;

  const shuffleProgress = shuffle_threshold > 0
    ? shuffle_counter / shuffle_threshold
    : 0;

  let zoneDistMult = 1.0;
  const blockedMovements = [];
  current_zones.forEach(zone => {
    if (zone.type === 1) {
      zoneDistMult *= 1.5;
    }
    if (zone.type === 2) {
      zoneDistMult *= 0.5;
    }
    if (zone.type === 4 && zone.blocked_movements) {
      zone.blocked_movements.forEach(name => {
        if (!blockedMovements.includes(name)) {
          blockedMovements.push(name);
        }
      });
    }
  });

  return (
    <Window
      width={750}
      height={700}>
      <Window.Content>
        <Stack fill>
          <Stack.Item basis="340px">
            <Stack vertical fill>
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
                    </Box>
                  )}>
                  <GridMap
                    focus_x={focus_x}
                    focus_y={focus_y}
                    items={nearby_items}
                    zones={zones}
                    zoom={zoom}
                    debug_mode={debug_mode}
                    highlightedItem={highlightedItem}
                    selected_core={selected_core}
                    hoveredDir={hoveredDir}
                    zoneDistMult={zoneDistMult}
                    last_movement_type={last_movement_type}
                    last_dir_x={last_dir_x}
                    last_dir_y={last_dir_y}
                    has_previous_move={has_previous_move} />
                </Section>
              </Stack.Item>

              <Stack.Item>
                <Section title="Shuffle Progress">
                  <ProgressBar
                    value={shuffleProgress}
                    color={shuffleProgress > 0.8 ? 'bad' : 'good'}>
                    {shuffle_counter} / {shuffle_threshold} crafts
                  </ProgressBar>
                  <Box fontSize="11px" color="label" mt={1}>
                    Item positions shuffle after threshold
                  </Box>
                </Section>
              </Stack.Item>

              {current_zones.length > 0 && (
                <Stack.Item>
                  <Section title="Active Zones">
                    {current_zones.map((zone, i) => (
                      <Box key={i} mb={0.5}>
                        <Icon
                          name="square"
                          color={getZoneColor(zone.type)}
                          mr={1} />
                        <Box inline bold>
                          {zone.name}
                        </Box>
                        {zone.blocked_movements
                          && zone.blocked_movements.length > 0
                          && (
                            <Box
                              fontSize="10px"
                              color="bad"
                              ml={2}>
                              Blocked:{' '}
                              {zone.blocked_movements.join(
                                ', '
                              )}
                            </Box>
                          )}
                      </Box>
                    ))}
                  </Section>
                </Stack.Item>
              )}

              <Stack.Item>
                <Section title="Tier Access (Ordeals)">
                  <Flex align="center">
                    <Flex.Item grow>
                      <Box bold>
                        Unlocked: Tier {ordeal_tier}
                      </Box>
                    </Flex.Item>
                    <Flex.Item>
                      {[0, 1, 2, 3, 4].map(t => (
                        <Icon
                          key={t}
                          name={t <= ordeal_tier ? 'star' : 'star-half'}
                          color={t <= ordeal_tier ? 'good' : 'label'}
                          ml={0.5} />
                      ))}
                    </Flex.Item>
                  </Flex>
                  <Box fontSize="11px" color="label" mt={1}>
                    Complete ordeals to unlock higher tiers
                  </Box>
                </Section>
              </Stack.Item>

              <Stack.Item>
                <Section title="Movement">
                  <MovementControls
                    selected_core={selected_core}
                    focus_x={focus_x}
                    focus_y={focus_y}
                    zoneDistMult={zoneDistMult}
                    act={act}
                    context={context}
                    setHoveredDir={setHoveredDir} />
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item grow>
            <Stack vertical fill>
              <Stack.Item>
                <Section>
                  <Flex align="center" justify="center">
                    <Flex.Item>
                      <Box
                        bold
                        color={!viewing_armor
                          ? 'good' : 'label'}
                        mr={1}>
                        Weapons
                      </Box>
                    </Flex.Item>
                    <Flex.Item>
                      <Button
                        icon="sync-alt"
                        content="Flip"
                        color="average"
                        onClick={() => act('flip')} />
                    </Flex.Item>
                    <Flex.Item>
                      <Box
                        bold
                        color={viewing_armor
                          ? 'good' : 'label'}
                        ml={1}>
                        Armor
                      </Box>
                    </Flex.Item>
                  </Flex>
                </Section>
              </Stack.Item>

              {craftable_items.length > 0 && (
                <Stack.Item>
                  <Section
                    title={(
                      <Box color="good">
                        <Icon name="check-circle" mr={1} />
                        {viewing_armor
                          ? 'Armor' : 'Weapons'}
                        {' In Range!'}
                      </Box>
                    )}>
                    <Stack vertical>
                      {craftable_items.map((item, index) => (
                        <Stack.Item key={index}>
                          <Flex align="center">
                            <Flex.Item grow>
                              <Box
                                bold
                                color={item.locked ? 'bad' : 'default'}>
                                {item.locked
                                  ? <Icon name="lock" color="bad" mr={1} />
                                  : getTierIcon(item.tier)}
                                {item.name}
                                {item.locked && (
                                  <Box
                                    inline
                                    fontSize="10px"
                                    color="label"
                                    ml={1}>
                                    (Tier {item.tier} - Locked)
                                  </Box>
                                )}
                              </Box>
                            </Flex.Item>
                            <Flex.Item>
                              <Button
                                icon={item.locked ? 'lock' : 'hammer'}
                                color={item.locked ? 'bad' : 'good'}
                                disabled={item.locked}
                                tooltip={item.locked
                                  ? 'Complete higher ordeals to unlock'
                                  : null}
                                content={item.locked ? 'Locked' : 'Craft'}
                                onClick={() => act('craft',
                                  { id: item.id })} />
                            </Flex.Item>
                          </Flex>
                        </Stack.Item>
                      ))}
                    </Stack>
                  </Section>
                </Stack.Item>
              )}

              <Stack.Item grow>
                <Section
                  fill
                  scrollable
                  title={(
                    <Box>
                      <Icon name="gem" mr={1} />
                      Navigation Cores ({stored_count}/{max_stored})
                    </Box>
                  )}>
                  <CoresSection
                    cores={available_cores}
                    selected_core={selected_core}
                    blockedMovements={blockedMovements}
                    zoneDistMult={zoneDistMult}
                    current_zones={current_zones}
                    act={act} />
                </Section>
              </Stack.Item>

              <Stack.Item grow>
                <Section
                  fill
                  scrollable
                  title={(
                    <Box>
                      <Icon name="crosshairs" mr={1} />
                      Nearby {viewing_armor
                        ? 'Armor' : 'Weapons'}
                      {highlighted_item_id && (
                        <Button
                          ml={1}
                          icon="times"
                          color="transparent"
                          tooltip="Clear highlight"
                          onClick={() => act('clear_highlight')} />
                      )}
                    </Box>
                  )}>
                  <NearbyItems
                    items={nearby_items}
                    highlighted_item_id={highlighted_item_id}
                    crafted_item_ids={crafted_item_ids}
                    act={act} />
                </Section>
              </Stack.Item>

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

const GridMap = props => {
  const {
    focus_x,
    focus_y,
    items,
    zones = [],
    zoom = 2,
    debug_mode,
    zoneDistMult = 1.0,
    highlightedItem,
    selected_core,
    hoveredDir,
    last_movement_type,
    last_dir_x,
    last_dir_y,
    has_previous_move,
  } = props;

  const zoomScales = { 1: 0.5, 2: 1.0, 3: 2.0, 4: 3.0, 5: 5.0 };
  const MAP_SCALE = zoomScales[zoom] || 1.0;

  const viewRadius = (MAP_SIZE / 2) / MAP_SCALE + 20;
  const centerX = MAP_SIZE / 2;
  const centerY = MAP_SIZE / 2;

  const toScreenX = x => centerX + (x - focus_x) * MAP_SCALE;
  const toScreenY = y => centerY - (y - focus_y) * MAP_SCALE;

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
      <svg
        width={MAP_SIZE}
        height={MAP_SIZE}
        style={{ position: 'absolute', top: 0, left: 0 }}>
        <defs>
          <style>
            {`
              @keyframes prediction-flash {
                0%, 100% { opacity: 0.25; }
                50% { opacity: 0.5; }
              }
              .prediction-zone {
                animation: prediction-flash 1s ease-in-out infinite;
              }
            `}
          </style>
        </defs>
        {(() => {
          const gridSpacing = zoom <= 2 ? 50 : (zoom <= 3 ? 25 : 10);
          const gridCount = Math.ceil(viewRadius / gridSpacing) * 2 + 2;
          const lines = [];

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

        {zones.map((zone, zi) => {
          const color = getZoneColor(zone.type);
          return (zone.cells || []).map((cell, ci) => {
            const sx = toScreenX(cell[0]);
            const sy = toScreenY(
              cell[1] + GRID_ZONE_CELL_SIZE
            );
            const size = GRID_ZONE_CELL_SIZE * MAP_SCALE;
            if (sx + size < 0 || sx > MAP_SIZE
              || sy + size < 0 || sy > MAP_SIZE) {
              return null;
            }
            return (
              <rect
                key={`z${zi}c${ci}`}
                x={sx}
                y={sy}
                width={size}
                height={size}
                fill={color}
                fillOpacity={0.15}
                stroke={color}
                strokeOpacity={0.3}
                strokeWidth={0.5} />
            );
          });
        })}

        <MovementPrediction
          selected_core={selected_core}
          hoveredDir={hoveredDir}
          centerX={centerX}
          centerY={centerY}
          MAP_SCALE={MAP_SCALE}
          items={items}
          highlightedItem={highlightedItem}
          focus_x={focus_x}
          focus_y={focus_y}
          toScreenX={toScreenX}
          toScreenY={toScreenY}
          zoneDistMult={zoneDistMult}
          last_movement_type={last_movement_type}
          last_dir_x={last_dir_x}
          last_dir_y={last_dir_y}
          has_previous_move={has_previous_move} />

        {highlightedItem && (
          <line
            x1={centerX}
            y1={centerY}
            x2={toScreenX(highlightedItem.x)}
            y2={toScreenY(highlightedItem.y)}
            stroke="#ffcc00"
            strokeWidth={2}
            strokeDasharray="5,3" />
        )}

        {visibleItems.map((item, index) => {
          const screenX = toScreenX(item.x);
          const screenY = toScreenY(item.y);
          const screenRadius = item.radius * MAP_SCALE;
          const isInRange = item.in_range;
          const isHighlighted = highlightedItem
            && highlightedItem.id === item.id;
          const tierColor = getTierColor(item.tier);
          const strokeColor = isHighlighted
            ? '#ffcc00'
            : (isInRange ? '#00ff00' : tierColor);

          return (
            <g key={index}>
              <circle
                cx={screenX}
                cy={screenY}
                r={screenRadius}
                fill={isInRange ? tierColor + '40' : tierColor + '20'}
                stroke={strokeColor}
                strokeWidth={isHighlighted ? 3 : (isInRange ? 2 : 1)}
                strokeDasharray={isInRange ? '' : '4,4'} />
              <circle
                cx={screenX}
                cy={screenY}
                r={isHighlighted ? 5 : 3}
                fill={isHighlighted ? '#ffcc00' : tierColor} />
            </g>
          );
        })}

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
        {debug_mode && ' (DEBUG)'}
        <br />
        <Icon name="square" color="#4488ff" /> Tailwind
        {' '}
        <Icon name="square" color="#ff4444" /> Drag
        {' '}
        <Icon name="square" color="#44cc44" /> Resonance
        {' '}
        <Icon name="square" color="#ff8800" /> Exclusion
      </Box>
    </Box>
  );
};

const MovementPrediction = props => {
  const {
    selected_core,
    hoveredDir,
    centerX,
    centerY,
    MAP_SCALE,
    items,
    highlightedItem,
    focus_x,
    focus_y,
    toScreenX,
    toScreenY,
    zoneDistMult = 1.0,
    last_movement_type,
    last_dir_x,
    last_dir_y,
    has_previous_move,
  } = props;

  if (!selected_core || !hoveredDir) {
    return null;
  }

  const mt = selected_core.movement_type;
  const minDist = selected_core.min_distance * zoneDistMult;
  const maxDist = selected_core.max_distance * zoneDistMult;
  const color = getSinColor(mt);
  const { dx, dy } = hoveredDir;

  // Charge (1): Straight line in cardinal direction
  if (mt === 1) {
    const endMinX = centerX + dx * minDist * MAP_SCALE;
    const endMinY = centerY - dy * minDist * MAP_SCALE;
    const endMaxX = centerX + dx * maxDist * MAP_SCALE;
    const endMaxY = centerY - dy * maxDist * MAP_SCALE;

    return (
      <g>
        {/* Flashing landing zone between min and max */}
        <line
          x1={endMinX}
          y1={endMinY}
          x2={endMaxX}
          y2={endMaxY}
          stroke={color}
          strokeWidth={8}
          strokeLinecap="round"
          className="prediction-zone" />
        <line
          x1={centerX}
          y1={centerY}
          x2={endMaxX}
          y2={endMaxY}
          stroke={color}
          strokeWidth={2}
          strokeDasharray="8,4"
          opacity={0.6} />
        <circle
          cx={endMinX}
          cy={endMinY}
          r={4}
          fill={color}
          opacity={0.7} />
        <circle
          cx={endMaxX}
          cy={endMaxY}
          r={6}
          fill="none"
          stroke={color}
          strokeWidth={2}
          opacity={0.7} />
      </g>
    );
  }

  // Attract (2): Arrow toward highlighted or nearest item
  if (mt === 2) {
    const attractDist = maxDist * 0.6;
    let target = null;

    if (highlightedItem) {
      const dist = Math.sqrt(
        Math.pow(highlightedItem.x - focus_x, 2)
        + Math.pow(highlightedItem.y - focus_y, 2)
      );
      if (dist > 0) {
        target = { item: highlightedItem, dist };
      }
    }

    if (!target) {
      target = items.reduce((best, item) => {
        const dist = Math.sqrt(
          Math.pow(item.x - focus_x, 2)
          + Math.pow(item.y - focus_y, 2)
        );
        if (!best || (dist > 0 && dist < best.dist)) {
          return { item, dist };
        }
        return best;
      }, null);
    }

    if (target && target.dist > 0) {
      const tX = toScreenX(target.item.x);
      const tY = toScreenY(target.item.y);
      const moveDist = Math.min(
        attractDist, target.dist
      );
      const ratio = moveDist / target.dist;
      const endX = centerX
        + (tX - centerX) * ratio;
      const endY = centerY
        + (tY - centerY) * ratio;

      return (
        <g>
          <line
            x1={centerX}
            y1={centerY}
            x2={endX}
            y2={endY}
            stroke={color}
            strokeWidth={3}
            strokeDasharray="6,3"
            opacity={0.7} />
          <circle
            cx={endX}
            cy={endY}
            r={8}
            fill={color}
            opacity={0.3} />
        </g>
      );
    }
  }

  // Shuffle (3): Full 360 degree donut
  if (mt === 3) {
    const innerR = minDist * 0.5 * MAP_SCALE;
    const outerR = maxDist * MAP_SCALE;

    return (
      <g>
        <circle
          cx={centerX}
          cy={centerY}
          r={outerR}
          fill={color}
          opacity={0.15} />
        <circle
          cx={centerX}
          cy={centerY}
          r={outerR}
          fill="none"
          stroke={color}
          strokeWidth={2}
          strokeDasharray="6,4"
          opacity={0.5} />
        <circle
          cx={centerX}
          cy={centerY}
          r={innerR}
          fill="#1a1a2e"
          opacity={0.8} />
      </g>
    );
  }

  // Expand (4): 8-directional line with arc
  if (mt === 4) {
    const isDiagonal = dx !== 0 && dy !== 0;
    const distMod = isDiagonal ? (1 / Math.sqrt(2)) : 1;
    const endMinX = centerX + dx * minDist * distMod * MAP_SCALE;
    const endMinY = centerY - dy * minDist * distMod * MAP_SCALE;
    const endMaxX = centerX + dx * maxDist * distMod * MAP_SCALE;
    const endMaxY = centerY - dy * maxDist * distMod * MAP_SCALE;

    return (
      <g>
        {/* Flashing landing zone between min and max */}
        <line
          x1={endMinX}
          y1={endMinY}
          x2={endMaxX}
          y2={endMaxY}
          stroke={color}
          strokeWidth={8}
          strokeLinecap="round"
          className="prediction-zone" />
        <line
          x1={centerX}
          y1={centerY}
          x2={endMaxX}
          y2={endMaxY}
          stroke={color}
          strokeWidth={2}
          strokeDasharray="8,4"
          opacity={0.6} />
        <circle
          cx={endMinX}
          cy={endMinY}
          r={4}
          fill={color}
          opacity={0.7} />
        <circle
          cx={endMaxX}
          cy={endMaxY}
          r={6}
          fill="none"
          stroke={color}
          strokeWidth={2}
          opacity={0.7} />
      </g>
    );
  }

  // Drift (5): Cardinal line with perpendicular spread zone
  if (mt === 5) {
    const endX = centerX + dx * maxDist * MAP_SCALE;
    const endY = centerY - dy * maxDist * MAP_SCALE;
    const spreadMax = maxDist * 1.0 * MAP_SCALE;

    // Calculate perpendicular direction
    const perpX = dy !== 0 ? 1 : 0;
    const perpY = dx !== 0 ? 1 : 0;

    // Create spread zone polygon points
    const p1x = endX - perpX * spreadMax;
    const p1y = endY + perpY * spreadMax;
    const p2x = endX + perpX * spreadMax;
    const p2y = endY - perpY * spreadMax;

    return (
      <g>
        {/* Flashing spread zone polygon */}
        <polygon
          points={`${centerX},${centerY} ${p1x},${p1y} ${p2x},${p2y}`}
          fill={color}
          className="prediction-zone" />
        <line
          x1={centerX}
          y1={centerY}
          x2={endX}
          y2={endY}
          stroke={color}
          strokeWidth={2}
          strokeDasharray="8,4"
          opacity={0.6} />
        <line
          x1={p1x}
          y1={p1y}
          x2={p2x}
          y2={p2y}
          stroke={color}
          strokeWidth={2}
          strokeDasharray="4,3"
          opacity={0.6} />
      </g>
    );
  }

  // Teleport (6): Show range circle and target marker
  if (mt === 6) {
    const teleport = hoveredDir.teleport;
    const targetScreenX = teleport ? toScreenX(teleport.x) : centerX;
    const targetScreenY = teleport ? toScreenY(teleport.y) : centerY;
    const hasTarget = teleport
      && (teleport.x !== focus_x || teleport.y !== focus_y);

    return (
      <g>
        <circle
          cx={centerX}
          cy={centerY}
          r={maxDist * MAP_SCALE}
          fill="none"
          stroke={color}
          strokeWidth={2}
          strokeDasharray="10,5"
          opacity={0.5} />
        {hasTarget && (
          <g>
            <line
              x1={centerX}
              y1={centerY}
              x2={targetScreenX}
              y2={targetScreenY}
              stroke={teleport.inRange ? color : '#ff4444'}
              strokeWidth={2}
              strokeDasharray="6,3"
              opacity={0.7} />
            <circle
              cx={targetScreenX}
              cy={targetScreenY}
              r={8}
              fill={teleport.inRange ? color : '#ff4444'}
              opacity={0.4} />
            <circle
              cx={targetScreenX}
              cy={targetScreenY}
              r={4}
              fill={teleport.inRange ? '#ffffff' : '#ff4444'} />
          </g>
        )}
      </g>
    );
  }

  // Mirror (7): Show same prediction as last movement but in purple
  if (mt === 7) {
    const purpleColor = '#703794';

    // If no previous move, show generic indicator
    if (!has_previous_move) {
      return (
        <g>
          <circle
            cx={centerX}
            cy={centerY}
            r={maxDist * MAP_SCALE}
            fill={purpleColor}
            className="prediction-zone" />
          <circle
            cx={centerX}
            cy={centerY}
            r={minDist * MAP_SCALE}
            fill="none"
            stroke={purpleColor}
            strokeWidth={2}
            strokeDasharray="4,4"
            opacity={0.5} />
          <text
            x={centerX}
            y={centerY + 5}
            textAnchor="middle"
            fill={purpleColor}
            fontSize="14"
            fontWeight="bold"
            opacity={0.8}>
            ?
          </text>
        </g>
      );
    }

    // Mimic last movement type visualization in purple
    const lastDx = last_dir_x || dx;
    const lastDy = last_dir_y || dy;

    // Charge-like (last was type 1)
    if (last_movement_type === 1) {
      const endMinX = centerX + lastDx * minDist * MAP_SCALE;
      const endMinY = centerY - lastDy * minDist * MAP_SCALE;
      const endMaxX = centerX + lastDx * maxDist * MAP_SCALE;
      const endMaxY = centerY - lastDy * maxDist * MAP_SCALE;
      return (
        <g>
          <line
            x1={endMinX}
            y1={endMinY}
            x2={endMaxX}
            y2={endMaxY}
            stroke={purpleColor}
            strokeWidth={8}
            strokeLinecap="round"
            className="prediction-zone" />
          <line
            x1={centerX}
            y1={centerY}
            x2={endMaxX}
            y2={endMaxY}
            stroke={purpleColor}
            strokeWidth={2}
            strokeDasharray="8,4"
            opacity={0.6} />
          <circle cx={endMinX} cy={endMinY} r={4} fill={purpleColor}
            opacity={0.7} />
          <circle cx={endMaxX} cy={endMaxY} r={6} fill="none"
            stroke={purpleColor} strokeWidth={2} opacity={0.7} />
        </g>
      );
    }

    // Expand-like (last was type 4)
    if (last_movement_type === 4) {
      const isDiag = lastDx !== 0 && lastDy !== 0;
      const distMod = isDiag ? (1 / Math.sqrt(2)) : 1;
      const endMinX = centerX + lastDx * minDist * distMod * MAP_SCALE;
      const endMinY = centerY - lastDy * minDist * distMod * MAP_SCALE;
      const endMaxX = centerX + lastDx * maxDist * distMod * MAP_SCALE;
      const endMaxY = centerY - lastDy * maxDist * distMod * MAP_SCALE;
      return (
        <g>
          <line
            x1={endMinX}
            y1={endMinY}
            x2={endMaxX}
            y2={endMaxY}
            stroke={purpleColor}
            strokeWidth={8}
            strokeLinecap="round"
            className="prediction-zone" />
          <line
            x1={centerX}
            y1={centerY}
            x2={endMaxX}
            y2={endMaxY}
            stroke={purpleColor}
            strokeWidth={2}
            strokeDasharray="8,4"
            opacity={0.6} />
          <circle cx={endMinX} cy={endMinY} r={4} fill={purpleColor}
            opacity={0.7} />
          <circle cx={endMaxX} cy={endMaxY} r={6} fill="none"
            stroke={purpleColor} strokeWidth={2} opacity={0.7} />
        </g>
      );
    }

    // Drift-like (last was type 5)
    if (last_movement_type === 5) {
      const endX = centerX + lastDx * maxDist * MAP_SCALE;
      const endY = centerY - lastDy * maxDist * MAP_SCALE;
      const spreadMax = maxDist * 1.0 * MAP_SCALE;
      const perpX = lastDy !== 0 ? 1 : 0;
      const perpY = lastDx !== 0 ? 1 : 0;
      const p1x = endX - perpX * spreadMax;
      const p1y = endY + perpY * spreadMax;
      const p2x = endX + perpX * spreadMax;
      const p2y = endY - perpY * spreadMax;
      return (
        <g>
          <polygon
            points={`${centerX},${centerY} ${p1x},${p1y} ${p2x},${p2y}`}
            fill={purpleColor}
            className="prediction-zone" />
          <line
            x1={centerX}
            y1={centerY}
            x2={endX}
            y2={endY}
            stroke={purpleColor}
            strokeWidth={2}
            strokeDasharray="8,4"
            opacity={0.6} />
          <line
            x1={p1x}
            y1={p1y}
            x2={p2x}
            y2={p2y}
            stroke={purpleColor}
            strokeWidth={2}
            strokeDasharray="4,3"
            opacity={0.6} />
        </g>
      );
    }

    // Default fallback for other types (2, 3, 6) - show generic purple circle
    return (
      <g>
        <circle
          cx={centerX}
          cy={centerY}
          r={maxDist * MAP_SCALE}
          fill={purpleColor}
          className="prediction-zone" />
        <circle
          cx={centerX}
          cy={centerY}
          r={minDist * MAP_SCALE}
          fill="none"
          stroke={purpleColor}
          strokeWidth={2}
          strokeDasharray="4,4"
          opacity={0.5} />
      </g>
    );
  }

  return null;
};

const MovementControls = props => {
  const {
    selected_core, focus_x, focus_y, zoneDistMult = 1.0,
    act, context, setHoveredDir,
  } = props;

  if (!selected_core) {
    return (
      <Box color="label" textAlign="center">
        <Icon name="exclamation-triangle" mr={1} />
        Select a core to move
      </Box>
    );
  }

  const mt = selected_core.movement_type;

  return (
    <Box>
      <Box fontSize="11px" color="label" mb={1}>
        <b>{selected_core.movement_name}</b> ({selected_core.sin_name})
        {' | Range: '}
        {selected_core.min_distance}-{selected_core.max_distance}
      </Box>
      {selected_core.diminishing_mod < 100 && (
        <Box fontSize="11px" color="bad" mb={1}>
          <Icon name="exclamation-triangle" mr={1} />
          {selected_core.sin_name} overuse:
          {' -'}{100 - selected_core.diminishing_mod}% range
          {' (use other sins to reduce)'}
        </Box>
      )}

      {mt === 6 ? (
        <TeleportControls
          max_range={selected_core.max_distance
            * selected_core.diminishing_mod / 100
            * zoneDistMult}
          focus_x={focus_x}
          focus_y={focus_y}
          act={act}
          context={context}
          setHoveredDir={setHoveredDir} />
      ) : mt === 2 || mt === 3 || mt === 7 ? (
        <Box textAlign="center">
          <Button
            icon="arrow-right"
            content={getMovementButtonText(mt)}
            onMouseEnter={() => setHoveredDir({ dx: 1, dy: 0 })}
            onMouseLeave={() => setHoveredDir(null)}
            onClick={() => act('move', { x: 1, y: 0 })} />
          <Box fontSize="11px" color="label" mt={1}>
            {getMovementDescription(mt)}
          </Box>
        </Box>
      ) : (
        <DirectionControls
          mt={mt}
          act={act}
          setHoveredDir={setHoveredDir} />
      )}
    </Box>
  );
};

const DirectionControls = props => {
  const { mt, act, setHoveredDir } = props;

  const canMove = (dx, dy) => {
    // Charge (1) and Drift (5): Cardinal only
    if (mt === 1 || mt === 5) {
      return (dx === 0) !== (dy === 0);
    }
    // Expand (4): All 8 directions
    if (mt === 4) {
      return dx !== 0 || dy !== 0;
    }
    return false;
  };

  return (
    <Box textAlign="center">
      <DirBtn
        dir="NW" dx={-1} dy={1}
        enabled={canMove(-1, 1)}
        act={act}
        setHoveredDir={setHoveredDir} />
      <DirBtn
        dir="N" dx={0} dy={1}
        enabled={canMove(0, 1)}
        act={act}
        setHoveredDir={setHoveredDir} />
      <DirBtn
        dir="NE" dx={1} dy={1}
        enabled={canMove(1, 1)}
        act={act}
        setHoveredDir={setHoveredDir} />
      <br />
      <DirBtn
        dir="W" dx={-1} dy={0}
        enabled={canMove(-1, 0)}
        act={act}
        setHoveredDir={setHoveredDir} />
      <Button width="50px" height="32px" disabled>
        <Icon name="crosshairs" />
      </Button>
      <DirBtn
        dir="E" dx={1} dy={0}
        enabled={canMove(1, 0)}
        act={act}
        setHoveredDir={setHoveredDir} />
      <br />
      <DirBtn
        dir="SW" dx={-1} dy={-1}
        enabled={canMove(-1, -1)}
        act={act}
        setHoveredDir={setHoveredDir} />
      <DirBtn
        dir="S" dx={0} dy={-1}
        enabled={canMove(0, -1)}
        act={act}
        setHoveredDir={setHoveredDir} />
      <DirBtn
        dir="SE" dx={1} dy={-1}
        enabled={canMove(1, -1)}
        act={act}
        setHoveredDir={setHoveredDir} />
    </Box>
  );
};

const DirBtn = props => {
  const { dir, dx, dy, enabled, act, setHoveredDir } = props;
  const arrows = {
    N: 'arrow-up', S: 'arrow-down', E: 'arrow-right', W: 'arrow-left',
    NE: 'arrow-up', NW: 'arrow-up', SE: 'arrow-down', SW: 'arrow-down',
  };

  return (
    <Button
      width="50px"
      height="32px"
      disabled={!enabled}
      onMouseEnter={() => enabled && setHoveredDir({ dx, dy })}
      onMouseLeave={() => setHoveredDir(null)}
      onClick={() => act('move', { x: dx, y: dy })}>
      <Icon name={arrows[dir]} />
    </Button>
  );
};

const TeleportControls = props => {
  const { max_range, focus_x, focus_y, act, context, setHoveredDir } = props;
  const [targetX, setTargetX] = useLocalState(context, 'teleportX', focus_x);
  const [targetY, setTargetY] = useLocalState(context, 'teleportY', focus_y);

  const distance = Math.sqrt(
    Math.pow(targetX - focus_x, 2) + Math.pow(targetY - focus_y, 2)
  );
  const inRange = distance <= max_range;

  // Pass teleport target to map for visualization
  const teleportTarget = { x: targetX, y: targetY, inRange };

  return (
    <Box
      onMouseEnter={() => setHoveredDir({
        dx: 0, dy: 0, teleport: teleportTarget,
      })}
      onMouseLeave={() => setHoveredDir(null)}>
      <Stack vertical>
        <Stack.Item>
          <Flex align="center">
            <Flex.Item basis="20px">X:</Flex.Item>
            <Flex.Item>
              <Button
                icon="angle-double-left"
                tooltip="-5"
                onClick={() => setTargetX(targetX - 5)} />
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="angle-left"
                tooltip="-1"
                onClick={() => setTargetX(targetX - 1)} />
            </Flex.Item>
            <Flex.Item basis="45px" textAlign="center" bold>
              {targetX}
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="angle-right"
                tooltip="+1"
                onClick={() => setTargetX(targetX + 1)} />
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="angle-double-right"
                tooltip="+5"
                onClick={() => setTargetX(targetX + 5)} />
            </Flex.Item>
          </Flex>
        </Stack.Item>
        <Stack.Item>
          <Flex align="center">
            <Flex.Item basis="20px">Y:</Flex.Item>
            <Flex.Item>
              <Button
                icon="angle-double-left"
                tooltip="-5"
                onClick={() => setTargetY(targetY - 5)} />
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="angle-left"
                tooltip="-1"
                onClick={() => setTargetY(targetY - 1)} />
            </Flex.Item>
            <Flex.Item basis="45px" textAlign="center" bold>
              {targetY}
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="angle-right"
                tooltip="+1"
                onClick={() => setTargetY(targetY + 1)} />
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="angle-double-right"
                tooltip="+5"
                onClick={() => setTargetY(targetY + 5)} />
            </Flex.Item>
          </Flex>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            icon="bolt"
            color={inRange ? 'good' : 'bad'}
            disabled={!inRange}
            content={`Teleport (${Math.round(distance)}/${max_range})`}
            onClick={() => act('teleport', { x: targetX, y: targetY })} />
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const CoresSection = props => {
  const {
    cores,
    selected_core,
    blockedMovements = [],
    zoneDistMult = 1.0,
    current_zones = [],
    act,
  } = props;

  if (cores.length === 0) {
    return (
      <Box textAlign="center" color="label">
        <Icon name="gem" size={2} mb={1} />
        <Box>No cores in storage</Box>
        <Box fontSize="11px">
          Insert cores by using them on the machine
        </Box>
      </Box>
    );
  }

  const inResonance = current_zones.some(
    z => z.type === 3
  );

  return (
    <Stack vertical>
      {cores.map((core, index) => {
        const isSelected = selected_core
          && selected_core.movement_type
            === core.movement_type;
        const isBlocked = blockedMovements.includes(
          core.movement_name
        );
        const isBoosted = zoneDistMult > 1.0;
        const isSlowed = zoneDistMult < 1.0;

        let zoneTag = null;
        if (isBlocked) {
          zoneTag = (
            <Box
              inline
              color="bad"
              fontSize="10px"
              ml={1}>
              <Icon name="ban" mr={0.5} />
              Blocked
            </Box>
          );
        } else if (isBoosted) {
          zoneTag = (
            <Box
              inline
              color="#4488ff"
              fontSize="10px"
              ml={1}>
              <Icon name="arrow-up" mr={0.5} />
              +{Math.round((zoneDistMult - 1) * 100)}%
            </Box>
          );
        } else if (isSlowed) {
          zoneTag = (
            <Box
              inline
              color="bad"
              fontSize="10px"
              ml={1}>
              <Icon name="arrow-down" mr={0.5} />
              {Math.round((1 - zoneDistMult) * 100)}%
            </Box>
          );
        }
        if (!isBlocked && inResonance) {
          zoneTag = (
            <Box inline>
              {zoneTag}
              <Box
                inline
                color="#44cc44"
                fontSize="10px"
                ml={1}>
                <Icon name="sync" mr={0.5} />
                Reset
              </Box>
            </Box>
          );
        }

        return (
          <Stack.Item key={index}>
            <Flex align="center">
              <Flex.Item grow>
                <Button
                  fluid
                  selected={isSelected}
                  disabled={isBlocked}
                  color={isBlocked
                    ? 'bad' : undefined}
                  onClick={() => act(
                    'select_core',
                    { ref: core.ref }
                  )}>
                  <Flex align="center">
                    <Flex.Item>
                      <Icon
                        name={isBlocked
                          ? 'ban' : 'gem'}
                        color={isBlocked
                          ? 'bad'
                          : getSinColor(
                            core.movement_type
                        )}
                        mr={1} />
                    </Flex.Item>
                    <Flex.Item grow>
                      {core.name}
                      {zoneTag}
                    </Flex.Item>
                    <Flex.Item
                      color="label"
                      fontSize="11px">
                      T{core.max_tier}
                    </Flex.Item>
                  </Flex>
                </Button>
              </Flex.Item>
              <Flex.Item ml={1}>
                <Button
                  icon="eject"
                  tooltip="Retrieve"
                  onClick={() => act(
                    'retrieve_core',
                    { ref: core.ref }
                  )} />
              </Flex.Item>
            </Flex>
          </Stack.Item>
        );
      })}
    </Stack>
  );
};

const NearbyItems = props => {
  const { items, highlighted_item_id, crafted_item_ids, act } = props;

  if (items.length === 0) {
    return (
      <Box textAlign="center" color="label">
        No weapons nearby
      </Box>
    );
  }

  return (
    <Stack vertical>
      {items.slice(0, 10).map((item, index) => {
        const isHighlighted = highlighted_item_id === item.id;
        const isCrafted = crafted_item_ids.includes(item.id);
        const isLocked = item.locked;
        return (
          <Stack.Item key={index}>
            <Flex align="center">
              <Flex.Item grow>
                <Button
                  fluid
                  color={isHighlighted ? 'yellow' : 'transparent'}
                  onClick={() => act('highlight_item', { id: item.id })}>
                  <Box
                    inline
                    bold={item.in_range && !isLocked}
                    color={isLocked
                      ? 'bad'
                      : (item.in_range ? 'good' : 'default')}
                    style={isLocked ? { opacity: 0.7 } : {}}>
                    {isLocked
                      ? <Icon name="lock" color="bad" mr={1} />
                      : getTierIcon(item.tier)}
                    {isCrafted && <Icon name="check" color="good" mr={1} />}
                    {item.name}
                  </Box>
                </Button>
              </Flex.Item>
              <Flex.Item color="label" fontSize="11px" ml={1}>
                {Math.round(item.distance)}u
                {item.in_range && !isLocked && (
                  <Icon name="check" color="good" ml={1} />
                )}
                {item.in_range && isLocked && (
                  <Icon name="lock" color="bad" ml={1} />
                )}
              </Flex.Item>
            </Flex>
          </Stack.Item>
        );
      })}
    </Stack>
  );
};

const getSinColor = movementType => {
  const colors = {
    1: '#821c15', // Wrath
    2: '#d67c0d', // Lust
    3: '#ad8d23', // Sloth
    4: '#59b53f', // Gluttony
    5: '#509799', // Gloom
    6: '#1f2278', // Pride
    7: '#703794', // Envy
  };
  return colors[movementType] || 'white';
};

const getTierColor = tier => {
  const colors = ['#666666', '#22cc44', '#4488ff', '#cc44ff', '#ffcc00'];
  return colors[tier] || '#666666';
};

const getTierIcon = tier => {
  const icons = ['circle', 'star', 'star', 'crown', 'crown'];
  const colors = ['label', 'average', 'good', 'blue', 'gold'];
  return (
    <Icon
      name={icons[tier] || 'circle'}
      color={colors[tier] || 'label'}
      mr={1} />
  );
};

const getZoneColor = type => {
  const colors = {
    1: '#4488ff',
    2: '#ff4444',
    3: '#44cc44',
    4: '#ff8800',
  };
  return colors[type] || '#888888';
};

const getMovementName = mt => {
  const names = {
    1: 'Charge',
    2: 'Attract',
    3: 'Shuffle',
    4: 'Expand',
    5: 'Drift',
    6: 'Teleport',
    7: 'Mirror',
  };
  return names[mt] || 'Unknown';
};

const getMovementButtonText = mt => {
  if (mt === 2) {
    return 'Attract';
  }
  if (mt === 3) {
    return 'Shuffle';
  }
  if (mt === 7) {
    return 'Mirror';
  }
  return 'Move';
};

const getMovementDescription = mt => {
  if (mt === 2) {
    return 'Moves toward nearest weapon';
  }
  if (mt === 3) {
    return 'Random direction and distance';
  }
  if (mt === 7) {
    return 'Mimics previous movement type';
  }
  return '';
};
