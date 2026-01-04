import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from '../components';
import { Window } from '../layouts';

export const ResurgenceCharacterSetup = (props, context) => {
  const { data } = useBackend(context);
  const {
    trait_point_pool = 4,
    stat_point_pool = 6,
    trait_points_used = 0,
    stat_points_used = 0,
  } = data;

  const [currentTab, setCurrentTab] = useLocalState(
    context,
    'currentTab',
    'traits'
  );

  const traitPointsRemaining = trait_point_pool - trait_points_used;
  const statPointsRemaining = stat_point_pool - stat_points_used;

  return (
    <Window width={550} height={600}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                selected={currentTab === 'traits'}
                onClick={() => setCurrentTab('traits')}>
                <Icon name="user-tag" mr={1} />
                Traits ({traitPointsRemaining}/{trait_point_pool})
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'passions'}
                onClick={() => setCurrentTab('passions')}>
                <Icon name="fire" mr={1} />
                Passion
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'stats'}
                onClick={() => setCurrentTab('stats')}>
                <Icon name="chart-bar" mr={1} />
                Stats ({statPointsRemaining}/{stat_point_pool})
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {currentTab === 'traits' && <TraitsTab />}
            {currentTab === 'passions' && <PassionsTab />}
            {currentTab === 'stats' && <StatsTab />}
          </Stack.Item>
          <Stack.Item>
            <ResetSection />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const TraitsTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    positive_traits = [],
    negative_traits = [],
    mixed_traits = [],
    selected_traits = [],
    trait_point_pool = 4,
    trait_points_used = 0,
  } = data;

  const pointsRemaining = trait_point_pool - trait_points_used;

  const isIncompatible = (trait, selectedList) => {
    if (!trait.incompatible) return false;
    for (const selected of selectedList) {
      if (trait.incompatible.includes(selected)) {
        return true;
      }
    }
    return false;
  };

  const canSelect = (trait, selectedList) => {
    if (selectedList.includes(trait.type)) return true;
    if (isIncompatible(trait, selectedList)) return false;
    if (trait.cost > pointsRemaining) return false;
    return true;
  };

  return (
    <Stack fill vertical>
      <Stack.Item>
        <NoticeBox info>
          Points: {pointsRemaining}/{trait_point_pool} remaining.
          Unspent points will be randomly assigned.
        </NoticeBox>
      </Stack.Item>
      <Stack.Item grow>
        <Stack fill>
          <Stack.Item grow basis={0}>
            <Section
              fill
              scrollable
              title={
                <Box>
                  <Icon name="plus" color="green" mr={1} />
                  Positive Traits
                </Box>
              }>
              {positive_traits.map((trait) => (
                <TraitButton
                  key={trait.type}
                  trait={trait}
                  selected={selected_traits.includes(trait.type)}
                  disabled={!canSelect(trait, selected_traits)}
                  incompatible={isIncompatible(trait, selected_traits)}
                  onClick={() =>
                    act('toggle_trait', { trait_type: trait.type })}
                />
              ))}
            </Section>
          </Stack.Item>
          <Stack.Item grow basis={0}>
            <Section
              fill
              scrollable
              title={
                <Box>
                  <Icon name="minus" color="red" mr={1} />
                  Negative Traits
                </Box>
              }>
              {negative_traits.map((trait) => (
                <TraitButton
                  key={trait.type}
                  trait={trait}
                  selected={selected_traits.includes(trait.type)}
                  disabled={!canSelect(trait, selected_traits)}
                  incompatible={isIncompatible(trait, selected_traits)}
                  onClick={() =>
                    act('toggle_trait', { trait_type: trait.type })}
                />
              ))}
              {mixed_traits.length > 0 && (
                <Box mt={2} mb={1} bold color="label">
                  Mixed Traits
                </Box>
              )}
              {mixed_traits.map((trait) => (
                <TraitButton
                  key={trait.type}
                  trait={trait}
                  selected={selected_traits.includes(trait.type)}
                  disabled={!canSelect(trait, selected_traits)}
                  incompatible={isIncompatible(trait, selected_traits)}
                  onClick={() =>
                    act('toggle_trait', { trait_type: trait.type })}
                  isMixed
                />
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Button
          fluid
          icon="eraser"
          color="bad"
          onClick={() => act('clear_traits')}>
          Clear All Traits
        </Button>
      </Stack.Item>
    </Stack>
  );
};

const TraitButton = (props) => {
  const {
    trait,
    selected,
    disabled,
    incompatible,
    onClick,
    isMixed,
  } = props;

  const costText = trait.cost > 0
    ? `-${trait.cost}`
    : `+${Math.abs(trait.cost)}`;
  const costColor = trait.cost > 0 ? 'red' : 'green';

  return (
    <Tooltip content={trait.desc} position="right">
      <Button
        fluid
        mb={0.5}
        selected={selected}
        disabled={disabled && !selected}
        color={incompatible ? 'grey' : (isMixed ? 'orange' : null)}
        onClick={onClick}>
        <Stack>
          <Stack.Item grow>
            {trait.name}
          </Stack.Item>
          <Stack.Item>
            <Box color={costColor} bold>
              {costText}
            </Box>
          </Stack.Item>
        </Stack>
      </Button>
    </Tooltip>
  );
};

const PassionsTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    stats = [],
    selected_passion = null,
    random_passion_count = 2,
  } = data;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <NoticeBox info>
          Choose ONE passion for +50% XP bonus.
          {random_passion_count} additional passions will be randomly
          assigned at spawn. If none selected, one will be randomly assigned.
        </NoticeBox>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill title="Choose Your Passion">
          {stats.map((stat) => (
            <Button
              key={stat.id}
              fluid
              mb={1}
              selected={selected_passion === stat.id}
              onClick={() => act('select_passion', { passion: stat.id })}>
              <Stack align="center">
                <Stack.Item>
                  <Icon name={stat.icon} size={1.5} mr={1} />
                </Stack.Item>
                <Stack.Item grow>
                  <Box bold>{stat.name}</Box>
                  <Box color="label" fontSize={0.9}>
                    +50% XP gain from {stat.name.toLowerCase()} activities
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  {selected_passion === stat.id && (
                    <Icon name="fire" color="orange" size={1.5} />
                  )}
                </Stack.Item>
              </Stack>
            </Button>
          ))}
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Button
          fluid
          icon="eraser"
          color="bad"
          onClick={() => act('select_passion', { passion: null })}>
          Clear Passion Selection
        </Button>
      </Stack.Item>
    </Stack>
  );
};

const StatsTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    stats = [],
    stat_allocation = {},
    stat_point_pool = 6,
    stat_points_used = 0,
    max_starting_stat = 4,
    max_total_starting_stat = 6,
    random_stat_bonus = 4,
  } = data;

  const pointsRemaining = stat_point_pool - stat_points_used;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <NoticeBox info>
          Allocate {stat_point_pool} points (max {max_starting_stat} per stat).
          {' '}{random_stat_bonus} additional levels will be randomly
          distributed (max {max_total_starting_stat} total per stat).
          Unspent points join the random pool.
        </NoticeBox>
      </Stack.Item>
      <Stack.Item>
        <Section title={`Points: ${pointsRemaining}/${stat_point_pool}`}>
          <ProgressBar
            value={stat_points_used}
            maxValue={stat_point_pool}
            color="blue"
          />
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill title="Allocate Starting Stats">
          <LabeledList>
            {stats.map((stat) => {
              const allocated = stat_allocation[stat.id] || 0;
              const canIncrease =
                allocated < max_starting_stat && pointsRemaining > 0;
              const canDecrease = allocated > 0;

              return (
                <LabeledList.Item
                  key={stat.id}
                  label={
                    <Box>
                      <Icon name={stat.icon} mr={1} />
                      {stat.name}
                    </Box>
                  }>
                  <Stack align="center">
                    <Stack.Item>
                      <Button
                        icon="minus"
                        disabled={!canDecrease}
                        onClick={() =>
                          act('adjust_stat', { stat: stat.id, adjustment: -1 })
                        }
                      />
                    </Stack.Item>
                    <Stack.Item basis="80px">
                      <ProgressBar
                        value={allocated}
                        maxValue={max_starting_stat}
                        color={allocated > 0 ? 'good' : 'average'}>
                        <Box textAlign="center">
                          {1 + allocated}
                          <Box as="span" color="label">
                            {' '}(+{allocated})
                          </Box>
                        </Box>
                      </ProgressBar>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="plus"
                        disabled={!canIncrease}
                        onClick={() =>
                          act('adjust_stat', { stat: stat.id, adjustment: 1 })
                        }
                      />
                    </Stack.Item>
                  </Stack>
                </LabeledList.Item>
              );
            })}
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Button
          fluid
          icon="eraser"
          color="bad"
          onClick={() => act('clear_stats')}>
          Clear All Stats
        </Button>
      </Stack.Item>
    </Stack>
  );
};

const ResetSection = (props, context) => {
  const { act } = useBackend(context);

  return (
    <Section>
      <Stack>
        <Stack.Item grow>
          <Button
            fluid
            icon="undo"
            color="bad"
            onClick={() => act('reset_all')}>
            Reset All
          </Button>
        </Stack.Item>
        <Stack.Item grow>
          <Button
            fluid
            icon="check"
            color="good"
            onClick={() => act('close')}>
            Done
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
