import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section } from '../components';
import { Window } from '../layouts';

export const AchievementSpec = (props, context) => {
  const { act, data } = useBackend(context);
  const { chosen } = data;
  const achievements = data.achievements || [];
  const [sortMode, setSortMode] = useLocalState(
    context, 'sortMode', 'name');

  const sorted = [...achievements].sort((a, b) => {
    if (sortMode === 'difficulty'
      && b.difficulty_order !== a.difficulty_order) {
      return b.difficulty_order - a.difficulty_order;
    }
    return a.name.localeCompare(b.name);
  });

  return (
    <Window
      title="Achievement Specialization"
      width={520}
      height={640}>
      <Window.Content scrollable>
        <Section
          title="Select a Specialization"
          buttons={(
            <>
              <Button
                icon="sort-alpha-down"
                selected={sortMode === 'name'}
                onClick={() => setSortMode('name')}>
                Name
              </Button>
              <Button
                icon="signal"
                selected={sortMode === 'difficulty'}
                onClick={() => setSortMode('difficulty')}>
                Difficulty
              </Button>
              <Button
                icon="ban"
                color="bad"
                selected={!chosen}
                onClick={() => act('none')}>
                None
              </Button>
            </>
          )}>
          {sorted.length === 0 && (
            <Box color="label">
              You have no unlocked achievements.
            </Box>
          ) || (
            sorted.map(ach => (
              <AchievementCard
                key={ach.type}
                achievement={ach}
                selected={ach.type === chosen} />
            ))
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

const AchievementCard = (props, context) => {
  const { act } = useBackend(context);
  const { achievement, selected } = props;
  const {
    type,
    name,
    desc,
    title,
    difficulty,
    difficulty_color,
    icon_class,
  } = achievement;
  const borderColor = selected ? difficulty_color : 'transparent';
  return (
    <Box
      mb={1}
      p={1}
      backgroundColor="rgba(0, 0, 0, 0.25)"
      onClick={() => act('select', { type })}
      style={{
        'border': '2px solid ' + borderColor,
        'border-radius': '3px',
        'cursor': 'pointer',
      }}>
      <Flex align="center">
        <Flex.Item>
          <Box className={icon_class} />
        </Flex.Item>
        <Flex.Item grow={1} ml={1}>
          <Box bold fontSize="1.25rem" color={difficulty_color}>
            {name}
          </Box>
          <Box fontSize="0.8rem" color="label" mt={0.5}>
            {desc}
          </Box>
          <Box fontSize="1rem" mt={0.5} italic>
            {title}
          </Box>
        </Flex.Item>
        <Flex.Item color="label" ml={1}>
          {difficulty}
        </Flex.Item>
      </Flex>
    </Box>
  );
};
