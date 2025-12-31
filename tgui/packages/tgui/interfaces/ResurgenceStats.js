import { useBackend } from '../backend';
import { Box, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';

export const ResurgenceStats = (props, context) => {
  const { data } = useBackend(context);
  const {
    construction_level = 1,
    construction_xp = 0,
    construction_xp_needed = 100,
    construction_speed = 1.5,
    construction_beauty = -2,
    crafting_level = 1,
    crafting_xp = 0,
    crafting_xp_needed = 100,
    crafting_speed = 1.5,
    crafting_beauty = -2,
    gathering_level = 1,
    gathering_xp = 0,
    gathering_xp_needed = 100,
    gathering_speed = 1.5,
    gathering_yield = 0.5,
    max_level = 20,
  } = data;

  return (
    <Window width={420} height={380}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Box italic color="label" textAlign="center" mb={1}>
              Rest in your room to view your progress.
            </Box>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Construction">
              <StatDisplay
                level={construction_level}
                xp={construction_xp}
                xpNeeded={construction_xp_needed}
                maxLevel={max_level}
                effects={[
                  `Build Speed: ${construction_speed.toFixed(2)}x`,
                  `Beauty Bonus: ${construction_beauty >= 0 ? '+' : ''}${construction_beauty}`,
                ]}
              />
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Crafting">
              <StatDisplay
                level={crafting_level}
                xp={crafting_xp}
                xpNeeded={crafting_xp_needed}
                maxLevel={max_level}
                effects={[
                  `Craft Speed: ${crafting_speed.toFixed(2)}x`,
                  `Beauty Bonus: ${crafting_beauty >= 0 ? '+' : ''}${crafting_beauty}`,
                ]}
              />
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Gathering">
              <StatDisplay
                level={gathering_level}
                xp={gathering_xp}
                xpNeeded={gathering_xp_needed}
                maxLevel={max_level}
                effects={[
                  `Gather Speed: ${gathering_speed.toFixed(2)}x`,
                  `Yield: ${gathering_yield.toFixed(2)}x`,
                ]}
              />
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const StatDisplay = (props) => {
  const { level, xp, xpNeeded, maxLevel, effects } = props;
  const isMaxed = level >= maxLevel;
  const progress = isMaxed ? 1 : xp / xpNeeded;

  return (
    <Stack vertical>
      <Stack.Item>
        <Box bold>
          Level {level}
          {isMaxed && (
            <Box as="span" color="good" ml={1}>
              (MAX)
            </Box>
          )}
        </Box>
      </Stack.Item>
      <Stack.Item>
        <ProgressBar value={progress} color={isMaxed ? 'good' : 'default'}>
          {isMaxed ? 'Mastered' : `${xp} / ${xpNeeded} XP`}
        </ProgressBar>
      </Stack.Item>
      <Stack.Item>
        <Box color="label" fontSize="11px">
          {effects.map((effect, i) => (
            <Box key={i}>{effect}</Box>
          ))}
        </Box>
      </Stack.Item>
    </Stack>
  );
};
