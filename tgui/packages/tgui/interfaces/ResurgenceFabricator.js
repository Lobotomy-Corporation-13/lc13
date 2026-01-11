import { useBackend } from '../backend';
import {
  Box, Button, Flex, Icon, ProgressBar, Section, Stack,
} from '../components';
import { Window } from '../layouts';

export const ResurgenceFabricator = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    open,
    animating,
    stored_protein,
    max_protein,
    revive_cost,
    purge_cost,
    has_occupant,
    is_resurgence_machine,
    occupant_name,
    occupant_stat,
    occupant_stat_state,
    occupant_health,
    occupant_max_health,
    occupant_brute,
    occupant_burn,
    occupant_tox,
    occupant_oxy,
    faith,
    max_faith,
    faith_rate,
    faith_level,
    faith_events = [],
    occupant_reagents = [],
    stomach_reagents = [],
    can_revive,
    can_purge,
    stored_limbs = [],
    max_limbs,
    limb_operating,
    missing_limbs = [],
    removable_limbs = [],
  } = data;

  return (
    <Window
      width={450}
      height={650}>
      <Window.Content>
        <Stack fill vertical>
          {/* Status Header */}
          <Stack.Item>
            <Section
              title="Fabricator Status"
              buttons={(
                <Button
                  icon={open ? "door-closed" : "door-open"}
                  content={open ? "Close" : "Open"}
                  disabled={animating}
                  onClick={() => act(open ? 'close' : 'open')} />
              )}>
              <Flex>
                <Flex.Item grow>
                  <Box>
                    <Box inline bold mr={1}>Status:</Box>
                    <Box
                      inline
                      color={open ? "good" : "average"}>
                      {animating ? "Cycling..." : (open ? "Open" : "Closed")}
                    </Box>
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Box>
                    <Box inline bold mr={1}>Protein:</Box>
                    <Box
                      inline
                      color={
                        stored_protein >= revive_cost
                          ? "good"
                          : stored_protein > 0
                            ? "average"
                            : "bad"
                      }>
                      {stored_protein}/{max_protein}
                    </Box>
                  </Box>
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>

          {/* Occupant Info */}
          <Stack.Item grow>
            {has_occupant ? (
              <Section fill scrollable title={`Occupant: ${occupant_name}`}>
                <Stack vertical>
                  {/* Health Status */}
                  <Stack.Item>
                    <Box mb={1}>
                      <Box inline bold mr={1}>Status:</Box>
                      <Box inline color={occupant_stat_state}>
                        {occupant_stat}
                      </Box>
                    </Box>
                    <ProgressBar
                      value={occupant_health / occupant_max_health}
                      ranges={{
                        good: [0.5, Infinity],
                        average: [0.2, 0.5],
                        bad: [-Infinity, 0.2],
                      }}>
                      Health: {Math.round(occupant_health)}
                      /{occupant_max_health}
                    </ProgressBar>
                  </Stack.Item>

                  {/* Damage Breakdown */}
                  <Stack.Item>
                    <Flex>
                      <Flex.Item grow basis="25%">
                        <Box color="red">
                          <Icon name="tint" mr={1} />
                          Brute: {Math.round(occupant_brute)}
                        </Box>
                      </Flex.Item>
                      <Flex.Item grow basis="25%">
                        <Box color="orange">
                          <Icon name="fire" mr={1} />
                          Burn: {Math.round(occupant_burn)}
                        </Box>
                      </Flex.Item>
                      <Flex.Item grow basis="25%">
                        <Box color="green">
                          <Icon name="biohazard" mr={1} />
                          Tox: {Math.round(occupant_tox)}
                        </Box>
                      </Flex.Item>
                      <Flex.Item grow basis="25%">
                        <Box color="blue">
                          <Icon name="lungs" mr={1} />
                          Oxy: {Math.round(occupant_oxy)}
                        </Box>
                      </Flex.Item>
                    </Flex>
                  </Stack.Item>

                  {/* Faith Info (Resurgence Machines Only) */}
                  {is_resurgence_machine && (
                    <>
                      <Stack.Item>
                        <Box bold mt={1}>Faith Status</Box>
                        <ProgressBar
                          value={faith / max_faith}
                          ranges={{
                            good: [0.6, Infinity],
                            average: [0.3, 0.6],
                            bad: [-Infinity, 0.3],
                          }}>
                          {faith_level}: {Math.round(faith)}/{max_faith}
                          {faith_rate !== 0 && (
                            <Box
                              inline
                              ml={1}
                              color={faith_rate > 0 ? "good" : "bad"}>
                              ({faith_rate > 0 ? "+" : ""}{faith_rate}/5s)
                            </Box>
                          )}
                        </ProgressBar>
                      </Stack.Item>

                      {/* Faith Events */}
                      {faith_events.length > 0 && (
                        <Stack.Item>
                          <Box bold mt={1}>Active Faith Events</Box>
                          {faith_events.map((event, index) => (
                            <Box key={index} fontSize="11px" mt={0.5}>
                              <Box
                                inline
                                color={event.change > 0 ? "good" : "bad"}>
                                [{event.change > 0 ? "+" : ""}{event.change}]
                              </Box>
                              {" "}{event.description}
                              {event.time_remaining !== null && (
                                <Box inline color="label" ml={1}>
                                  ({formatTime(event.time_remaining)})
                                </Box>
                              )}
                            </Box>
                          ))}
                        </Stack.Item>
                      )}
                    </>
                  )}

                  {/* Chemicals */}
                  {(occupant_reagents.length > 0
                    || stomach_reagents.length > 0) && (
                    <Stack.Item>
                      <Box bold mt={1}>Chemicals Detected</Box>
                      {occupant_reagents.length > 0 && (
                        <Box fontSize="11px" mt={0.5}>
                          <Box color="label">Blood:</Box>
                          {occupant_reagents.map((reagent, index) => (
                            <Box key={index} ml={1}>
                              {reagent.volume}u {reagent.name}
                            </Box>
                          ))}
                        </Box>
                      )}
                      {stomach_reagents.length > 0 && (
                        <Box fontSize="11px" mt={0.5}>
                          <Box color="label">Stomach:</Box>
                          {stomach_reagents.map((reagent, index) => (
                            <Box key={index} ml={1}>
                              {reagent.volume}u {reagent.name}
                            </Box>
                          ))}
                        </Box>
                      )}
                    </Stack.Item>
                  )}
                </Stack>
              </Section>
            ) : (
              <Section fill title="Occupant">
                <Box textAlign="center" color="label" mt={4}>
                  <Icon name="user-slash" size={3} mb={2} />
                  <Box>No occupant</Box>
                  <Box mt={1}>Drag a resurgence machine into the open pod.</Box>
                </Box>
              </Section>
            )}
          </Stack.Item>

          {/* Actions */}
          {!!has_occupant && !!is_resurgence_machine && (
            <Stack.Item>
              <Section title="Actions">
                <Stack>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="heart-pulse"
                      color={can_revive ? "good" : "bad"}
                      disabled={!can_revive}
                      tooltip={
                        occupant_stat !== "Dead"
                          ? "Occupant is not dead"
                          : stored_protein < revive_cost
                            ? `Need ${revive_cost} protein`
                            : `Revive (costs ${revive_cost} protein)`
                      }
                      onClick={() => act('revive')}>
                      Revive ({revive_cost} Protein)
                    </Button>
                  </Stack.Item>
                  <Stack.Item grow>
                    <Button
                      fluid
                      icon="syringe"
                      color={can_purge ? "average" : "bad"}
                      disabled={!can_purge}
                      tooltip={
                        occupant_reagents.length === 0
                          && stomach_reagents.length === 0
                          ? "No chemicals to purge"
                          : `Purge chemicals (costs ${purge_cost} faith)`
                      }
                      onClick={() => act('purge')}>
                      Purge Chems ({purge_cost} Faith)
                    </Button>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {/* Limb Management */}
          <Stack.Item>
            <Section
              title={`Limb Storage (${stored_limbs.length}/${max_limbs})`}>
              {stored_limbs.length > 0 ? (
                <Box>
                  {stored_limbs.map((limb, index) => (
                    <Box key={index} mb={0.5}>
                      <Flex align="center">
                        <Flex.Item grow>
                          <Icon name="hand" mr={1} />
                          {limb.name}
                        </Flex.Item>
                        {has_occupant
                          && is_resurgence_machine
                          && missing_limbs.some(
                            m => m.zone === limb.zone
                          ) && (
                          <Flex.Item>
                            <Button
                              icon="plus"
                              color="good"
                              disabled={limb_operating}
                              tooltip="Attach to occupant"
                              onClick={() => act('attach_limb', {
                                limb_index: limb.index,
                              })} />
                          </Flex.Item>
                        )}
                        <Flex.Item>
                          <Button
                            icon="eject"
                            disabled={limb_operating}
                            tooltip="Eject limb"
                            onClick={() => act('eject_limb', {
                              limb_index: limb.index,
                            })} />
                        </Flex.Item>
                      </Flex>
                    </Box>
                  ))}
                </Box>
              ) : (
                <Box color="label" textAlign="center">
                  No limbs stored. Insert bodyparts to store them.
                </Box>
              )}
            </Section>
          </Stack.Item>

          {/* Limb Removal (Resurgence Machine Only) */}
          {!!has_occupant && !!is_resurgence_machine
            && removable_limbs.length > 0 && (
            <Stack.Item>
              <Section title="Remove Limbs">
                <Box fontSize="11px" color="label" mb={1}>
                  Warning: Limb removal takes 10 seconds.
                </Box>
                <Flex wrap="wrap">
                  {removable_limbs.map((limb, index) => (
                    <Flex.Item key={index} mr={1} mb={0.5}>
                      <Button
                        icon="scissors"
                        color="bad"
                        disabled={limb_operating}
                        onClick={() => act('remove_limb', {
                          limb_zone: limb.zone,
                        })}>
                        {limb.name}
                      </Button>
                    </Flex.Item>
                  ))}
                </Flex>
              </Section>
            </Stack.Item>
          )}

          {/* Non-Machine Warning */}
          {!!has_occupant && !is_resurgence_machine && (
            <Stack.Item>
              <Section>
                <Box color="average" textAlign="center">
                  <Icon name="exclamation-triangle" mr={1} />
                  This fabricator only works with resurgence machines.
                </Box>
              </Section>
            </Stack.Item>
          )}

          {/* Info Footer */}
          <Stack.Item>
            <Section>
              <Box color="label" fontSize="11px">
                <Icon name="info-circle" mr={1} />
                Feed protein-rich food to the fabricator to charge it.
                Revival sets faith to 25 and causes temporary existential dread.
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const formatTime = seconds => {
  if (seconds === null) {
    return "permanent";
  }
  if (seconds >= 60) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}m ${secs}s`;
  }
  return `${seconds}s`;
};
