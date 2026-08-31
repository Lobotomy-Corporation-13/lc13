import { useBackend } from '../backend';
import {
  Box, Button, Flex, Icon, NumberInput, ProgressBar, Section, Stack,
} from '../components';
import { Window } from '../layouts';

export const OreRefiner = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    iron_count,
    silver_count,
    gold_count,
    coal_count,
    max_ore,
    max_coal,
    processing,
    total_ore,
    iron_pct,
    silver_pct,
    gold_pct,
    preview = {},
  } = data;

  return (
    <Window
      width={400}
      height={480}>
      <Window.Content>
        <Stack fill vertical>
          {/* Ore Hoppers */}
          <Stack.Item>
            <Section title="Primary Ore">
              <Stack vertical>
                <Stack.Item>
                  <OreRow
                    name="Iron"
                    count={iron_count}
                    max={max_ore}
                    pct={iron_pct}
                    color="#8B5A2B"
                    onEject={() => act('eject_iron')}
                    disabled={processing} />
                </Stack.Item>
                <Stack.Item>
                  <OreRow
                    name="Silver"
                    count={silver_count}
                    max={max_ore}
                    pct={silver_pct}
                    color="#C0C0C0"
                    onEject={() => act('eject_silver')}
                    disabled={processing} />
                </Stack.Item>
                <Stack.Item>
                  <OreRow
                    name="Gold"
                    count={gold_count}
                    max={max_ore}
                    pct={gold_pct}
                    color="#FFD700"
                    onEject={() => act('eject_gold')}
                    disabled={processing} />
                </Stack.Item>
              </Stack>
              {total_ore > 0 && (
                <Box mt={1} color="label" fontSize="11px">
                  Total Primary Ore: {total_ore}
                </Box>
              )}
            </Section>
          </Stack.Item>

          {/* Coal Fuel */}
          <Stack.Item>
            <Section title="Coal Fuel">
              <Flex align="center">
                <Flex.Item grow>
                  <ProgressBar
                    value={coal_count / max_coal}
                    color="black">
                    {coal_count} / {max_coal}
                  </ProgressBar>
                </Flex.Item>
                <Flex.Item ml={1}>
                  <Button
                    icon="eject"
                    disabled={processing || coal_count === 0}
                    onClick={() => act('eject_coal')} />
                </Flex.Item>
              </Flex>
              <Box mt={1} color="label" fontSize="11px">
                More coal = more distance.
                {total_ore > 0 && coal_count > 0 && (
                  <> Ratio: {(coal_count / total_ore).toFixed(1)}:1</>
                )}
              </Box>
            </Section>
          </Stack.Item>

          {/* Preview */}
          <Stack.Item grow>
            <Section fill title="Output Preview">
              {preview.valid ? (
                <Stack vertical>
                  <Stack.Item>
                    <Box bold fontSize="16px" textAlign="center">
                      {preview.display_name}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Flex mt={1}>
                      <Flex.Item grow basis="50%">
                        <Box color="label">Movement:</Box>
                        <Box>
                          {getMovementDesc(preview.core_type)}
                        </Box>
                      </Flex.Item>
                      <Flex.Item grow basis="50%">
                        <Box color="label">Fuel Level:</Box>
                        <Box color={getFuelColor(preview.fuel_level)}>
                          {preview.fuel_name}
                        </Box>
                      </Flex.Item>
                    </Flex>
                  </Stack.Item>
                  {preview.gilded && (
                    <Stack.Item>
                      <Box color="gold" mt={1}>
                        <Icon name="star" mr={1} />
                        Gilded (+{preview.gilded_gold ? '15' : '10'}% range)
                      </Box>
                    </Stack.Item>
                  )}
                  {preview.minor_ore_bonus && (
                    <Stack.Item>
                      <Box color="average" mt={1}>
                        <Icon name="plus" mr={1} />
                        Mixed Ore Bonus (+5% distance)
                      </Box>
                    </Stack.Item>
                  )}
                </Stack>
              ) : (
                <Box textAlign="center" color="label" mt={2}>
                  <Icon name="flask" size={2} mb={1} />
                  <Box>Load ore to see preview</Box>
                </Box>
              )}
            </Section>
          </Stack.Item>

          {/* Refine Button */}
          <Stack.Item>
            <Section>
              <Button
                fluid
                icon={processing ? "spinner" : "cogs"}
                iconSpin={processing}
                color={preview.valid ? "good" : "bad"}
                disabled={processing || !preview.valid}
                content={processing
                  ? "Processing..."
                  : "Refine Ore (0.25 Faith)"}
                onClick={() => act('refine')} />
            </Section>
          </Stack.Item>

          {/* Help */}
          <Stack.Item>
            <Box color="label" fontSize="11px" px={1}>
              <Icon name="info-circle" mr={1} />
              Insert ore to create cores. Ore ratio determines type,
              total ore determines level, coal determines fuel.
            </Box>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const OreRow = props => {
  const { name, count, max, pct, color, onEject, disabled } = props;

  return (
    <Flex align="center">
      <Flex.Item basis="60px">
        <Box bold color={color}>{name}</Box>
      </Flex.Item>
      <Flex.Item grow>
        <ProgressBar
          value={count / max}
          color={color}>
          {count > 0 ? `${count} (${pct}%)` : '-'}
        </ProgressBar>
      </Flex.Item>
      <Flex.Item ml={1}>
        <Button
          icon="eject"
          disabled={disabled || count === 0}
          onClick={onEject} />
      </Flex.Item>
    </Flex>
  );
};

const getMovementDesc = coreType => {
  switch (coreType) {
    case 'iron':
      return 'Cardinal (N/S/E/W)';
    case 'silver':
      return 'Diagonal (NE/NW/SE/SW)';
    case 'alloy':
      return '8-directional';
    case 'gold':
      return 'Teleport (choice)';
    default:
      return 'Unknown';
  }
};

const getFuelColor = fuelLevel => {
  switch (fuelLevel) {
    case 0:
      return 'bad';
    case 1:
      return 'average';
    case 2:
      return 'good';
    case 3:
      return 'good';
    case 4:
      return 'good';
    default:
      return 'label';
  }
};
