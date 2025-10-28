import { useBackend } from '../backend';
import { Box, Section, Stack, LabeledList } from '../components';
import { Window } from '../layouts';

const getDamageTypeColor = type => {
  switch (type) {
    case 'RED_DAMAGE':
    case 'red':
      return 'red';
    case 'WHITE_DAMAGE':
    case 'white':
      return 'grey';
    case 'BLACK_DAMAGE':
    case 'black':
      return 'purple';
    case 'PALE_DAMAGE':
    case 'pale':
      return 'blue';
    default:
      return 'label';
  }
};

const getHealthDescription = maxHealth => {
  if (maxHealth <= 300) return 'Fragile';
  if (maxHealth <= 500) return 'Moderate';
  if (maxHealth <= 700) return 'Sturdy';
  if (maxHealth <= 900) return 'Tough';
  if (maxHealth <= 1100) return 'Very Tough';
  if (maxHealth <= 1500) return 'Extremely Tough';
  if (maxHealth <= 2000) return 'Incredibly Tough';
  return 'Legendary Toughness';
};

const getHealthColor = maxHealth => {
  if (maxHealth <= 300) return 'good';
  if (maxHealth <= 500) return 'average';
  if (maxHealth <= 700) return 'yellow';
  if (maxHealth <= 900) return 'orange';
  if (maxHealth <= 1100) return 'bad';
  if (maxHealth <= 1500) return 'red';
  if (maxHealth <= 2000) return 'purple';
  return 'pink';
};

const getDamageDescription = damage => {
  // Handle range values (e.g., "5-10")
  let maxDamage = damage;
  if (typeof damage === 'string' && damage.includes('-')) {
    maxDamage = parseInt(damage.split('-')[1], 10);
  } else if (typeof damage === 'string') {
    maxDamage = parseInt(damage, 10);
  }

  if (isNaN(maxDamage) || maxDamage === '?') return 'Unknown';
  if (maxDamage <= 8) return 'Very Low';
  if (maxDamage <= 15) return 'Low';
  if (maxDamage <= 20) return 'Moderate';
  if (maxDamage <= 28) return 'High';
  if (maxDamage <= 40) return 'Very High';
  if (maxDamage <= 50) return 'Extreme';
  return 'Devastating';
};

const getMeleeSpeedDescription = (rapidMelee, attackCooldown) => {
  if (rapidMelee > 1) {
    if (rapidMelee >= 8) return 'Lightning Fast';
    if (rapidMelee >= 4) return 'Very Fast';
    if (rapidMelee >= 2) return 'Fast';
  }
  if (attackCooldown > 0) {
    if (attackCooldown <= 10) return 'Very Fast'; // 1s or less
    if (attackCooldown <= 20) return 'Fast'; // 2s or less
    if (attackCooldown <= 30) return 'Moderate'; // 3s or less
    if (attackCooldown <= 50) return 'Slow'; // 5s or less
    return 'Very Slow';
  }
  return 'Normal';
};

const getRangedSpeedDescription = (cooldown, rapid) => {
  let desc = '';
  if (rapid > 0) {
    if (rapid >= 5) desc = 'Heavy Burst';
    else if (rapid >= 3) desc = 'Burst Fire';
    else desc = 'Double Tap';
  } else {
    desc = 'Single Shot';
  }

  if (cooldown) {
    if (cooldown <= 10) return desc + ' - Very Fast';
    if (cooldown <= 20) return desc + ' - Fast';
    if (cooldown <= 30) return desc + ' - Moderate';
    if (cooldown <= 50) return desc + ' - Slow';
    return desc + ' - Very Slow';
  }
  return desc;
};

const getResistanceLabel = value => {
  if (value === '?') return '?';
  const numValue = parseFloat(value);
  if (numValue < 0.5) return 'Resistant';
  if (numValue < 1.0) return 'Normal';
  if (numValue < 1.5) return 'Weak';
  if (numValue < 2.0) return 'Vulnerable';
  return 'Fatal';
};

const getResistanceColor = value => {
  if (value === '?') return 'label';
  const numValue = parseFloat(value);
  if (numValue < 0.5) return 'good';
  if (numValue < 1.0) return 'average';
  if (numValue < 1.5) return 'orange';
  if (numValue < 2.0) return 'bad';
  return 'red';
};

export const CreatureReport = (props, context) => {
  const { data } = useBackend(context);
  const { creature } = data;

  if (!creature) {
    return (
      <Window width={500} height={400}>
        <Window.Content>
          <Section title="Creature Report">
            <Box italic color="label">
              No creature data available.
            </Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={500} height={600}>
      <Window.Content scrollable>
        <Section title={`${creature.name} Report`}>
          <Stack vertical>
            <Stack.Item>
              <Section title="Visual Data">
                <Box textAlign="center">
                  <img
                    src={`data:image/png;base64,${creature.icon}`}
                    height="64px"
                    width="64px"
                    style={{
                      'vertical-align': 'middle',
                      'image-rendering': 'pixelated',
                      '-ms-interpolation-mode': 'nearest-neighbor',
                    }}
                  />
                </Box>
              </Section>
            </Stack.Item>

            <Stack.Item>
              <Section title="Vital Statistics">
                <LabeledList>
                  <LabeledList.Item label="Health">
                    <Box color={getHealthColor(creature.max_health)}>
                      {getHealthDescription(creature.max_health)}
                    </Box>
                    <Box inline color="label" ml={1}>
                      ({Math.round(
                        (creature.health / creature.max_health) * 100
                      )}% when scanned)
                    </Box>
                  </LabeledList.Item>
                  <LabeledList.Item label="Movement Speed">
                    {creature.move_to_delay <= 2
                      ? 'Very Fast'
                      : creature.move_to_delay <= 3
                        ? 'Fast'
                        : creature.move_to_delay <= 4
                          ? 'Normal'
                          : creature.move_to_delay <= 6
                            ? 'Slow'
                            : 'Very Slow'}
                  </LabeledList.Item>
                  <LabeledList.Item label="Melee Damage">
                    {getDamageDescription(
                      creature.melee_damage_lower !== '?'
                        ? `${creature.melee_damage_lower}-${
                          creature.melee_damage_upper}`
                        : '?'
                    )}
                    {creature.melee_damage_type !== '?'
                      && (
                        <Box
                          inline
                          ml={1}
                          color={getDamageTypeColor(
                            creature.melee_damage_type
                          )}>
                          [{creature.melee_damage_type}]
                        </Box>
                      )}
                  </LabeledList.Item>
                  <LabeledList.Item label="Melee Speed">
                    {getMeleeSpeedDescription(
                      creature.rapid_melee,
                      creature.attack_cooldown
                    )}
                  </LabeledList.Item>
                  {!!creature.is_ranged && creature.ranged_damage && (
                    <>
                      <LabeledList.Item label="Ranged Damage">
                        {getDamageDescription(creature.ranged_damage)}
                        {creature.ranged_damage_type && (
                          <Box
                            inline
                            ml={1}
                            color={getDamageTypeColor(
                              creature.ranged_damage_type
                            )}>
                            [{creature.ranged_damage_type}]
                          </Box>
                        )}
                      </LabeledList.Item>
                      <LabeledList.Item label="Fire Rate">
                        {getRangedSpeedDescription(
                          creature.ranged_cooldown_time,
                          creature.rapid
                        )}
                      </LabeledList.Item>
                    </>
                  )}
                  <LabeledList.Item label="Combat Type">
                    {creature.is_ranged ? 'Ranged' : 'Melee Only'}
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            </Stack.Item>

            <Stack.Item>
              <Section title="Damage Resistances">
                <LabeledList>
                  <LabeledList.Item label="Red">
                    <Box color={getResistanceColor(creature.resistances.red)}>
                      {getResistanceLabel(creature.resistances.red)}
                      {creature.resistances.red !== '?'
                        && ` (×${creature.resistances.red})`}
                    </Box>
                  </LabeledList.Item>
                  <LabeledList.Item label="White">
                    <Box color={getResistanceColor(creature.resistances.white)}>
                      {getResistanceLabel(creature.resistances.white)}
                      {creature.resistances.white !== '?'
                        && ` (×${creature.resistances.white})`}
                    </Box>
                  </LabeledList.Item>
                  <LabeledList.Item label="Black">
                    <Box color={getResistanceColor(creature.resistances.black)}>
                      {getResistanceLabel(creature.resistances.black)}
                      {creature.resistances.black !== '?'
                        && ` (×${creature.resistances.black})`}
                    </Box>
                  </LabeledList.Item>
                  <LabeledList.Item label="Pale">
                    <Box color={getResistanceColor(creature.resistances.pale)}>
                      {getResistanceLabel(creature.resistances.pale)}
                      {creature.resistances.pale !== '?'
                        && ` (×${creature.resistances.pale})`}
                    </Box>
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            </Stack.Item>

            {creature.notes && (
              <Stack.Item>
                <Section title="Field Notes">
                  <Box preserveWhitespace>
                    {creature.notes}
                  </Box>
                </Section>
              </Stack.Item>
            )}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};