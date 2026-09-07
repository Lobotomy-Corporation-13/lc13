import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Icon,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const ResurgenceCharacterSetup = (props, context) => {
  const { data } = useBackend(context);
  const {
    stat_point_pool = 6,
    stat_points_used = 0,
  } = data;

  const [currentTab, setCurrentTab] = useLocalState(
    context,
    'currentTab',
    'passions'
  );

  const statPointsRemaining = stat_point_pool - stat_points_used;

  return (
    <Window width={550} height={600}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs fluid>
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
          {stats.map(stat => (
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
          {stats.map(stat => {
            const allocated = stat_allocation[stat.id] || 0;
            const canIncrease
              = allocated < max_starting_stat && pointsRemaining > 0;
            const canDecrease = allocated > 0;

            return (
              <Stack key={stat.id} align="center" mb={1}>
                <Stack.Item basis="120px">
                  <Icon name={stat.icon} mr={1} />
                  {stat.name}
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="minus"
                    disabled={!canDecrease}
                    onClick={() => act('adjust_stat', {
                      stat: stat.id,
                      adjustment: -1,
                    })} />
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
                    onClick={() => act('adjust_stat', {
                      stat: stat.id,
                      adjustment: 1,
                    })} />
                </Stack.Item>
              </Stack>
            );
          })}
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
