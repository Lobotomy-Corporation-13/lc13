import { useBackend } from '../backend';
import { Box, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';

export const ResurgenceStats = (props, context) => {
  const { data } = useBackend(context);
  const {
    crafting_level = 1,
    crafting_xp = 0,
    crafting_xp_needed = 100,
    crafting_speed = 1.5,
    crafting_beauty = -2,
    mining_level = 1,
    mining_xp = 0,
    mining_xp_needed = 100,
    mining_work_bonus = 0,
    mining_yield = 1.0,
    harvesting_level = 1,
    harvesting_xp = 0,
    harvesting_xp_needed = 100,
    harvesting_work_bonus = 0,
    harvesting_yield = 0,
    cooking_level = 1,
    cooking_xp = 0,
    cooking_xp_needed = 100,
    cooking_speed = 1.5,
    cooking_quality = -2,
    max_level = 20,
  } = data;

  return (
    <Window width={420} height={480}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Box italic color="label" textAlign="center" mb={1}>
              Rest in your room to view your progress.
            </Box>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Crafting">
              <StatDisplay
                level={crafting_level}
                xp={crafting_xp}
                xpNeeded={crafting_xp_needed}
                maxLevel={max_level}
                effects={[
                  `Speed: +${Math.round((1 - crafting_speed) * 100)}%`,
                  `Beauty: ${(crafting_beauty >= 0 ? '+' : '')
                    + crafting_beauty}`,
                ]}
              />
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Mining">
              <StatDisplay
                level={mining_level}
                xp={mining_xp}
                xpNeeded={mining_xp_needed}
                maxLevel={max_level}
                effects={[
                  `Work Bonus: +${mining_work_bonus} per tick`,
                  `Yield: ${mining_yield.toFixed(2)}x`,
                ]}
              />
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Harvesting">
              <StatDisplay
                level={harvesting_level}
                xp={harvesting_xp}
                xpNeeded={harvesting_xp_needed}
                maxLevel={max_level}
                effects={[
                  `Work Bonus: +${harvesting_work_bonus} per tick`,
                  `Yield Bonus: +${harvesting_yield}`,
                ]}
              />
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Cooking">
              <StatDisplay
                level={cooking_level}
                xp={cooking_xp}
                xpNeeded={cooking_xp_needed}
                maxLevel={max_level}
                effects={[
                  `Speed: +${Math.round((1 - cooking_speed) * 100)}%`,
                  `Quality: ${(cooking_quality >= 0 ? '+' : '')
                    + cooking_quality}`,
                ]}
              />
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const StatDisplay = props => {
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
