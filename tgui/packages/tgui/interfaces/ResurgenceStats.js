import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Icon,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const ResurgenceStats = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    // Bed ownership
    bed_owner,
    is_owner,
    can_claim,
    room_type,
    in_valid_room,
    // Stats
    crafting_level = 1,
    crafting_xp = 0,
    crafting_xp_needed = 100,
    crafting_work_bonus = 0,
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
    cooking_speed = 1.0,
    cooking_quality = -2,
    analysis_level = 1,
    analysis_xp = 0,
    analysis_xp_needed = 100,
    social_level = 1,
    social_xp = 0,
    social_xp_needed = 100,
    max_level = 20,
    active_events = [],
  } = data;

  const [currentTab, setCurrentTab] = useLocalState(
    context,
    'currentTab',
    'overview'
  );

  return (
    <Window width={420} height={520}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                selected={currentTab === 'overview'}
                onClick={() => setCurrentTab('overview')}>
                <Icon name="home" mr={1} />
                Overview
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'crafting'}
                onClick={() => setCurrentTab('crafting')}>
                <Icon name="hammer" mr={1} />
                Crafting
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'mining'}
                onClick={() => setCurrentTab('mining')}>
                <Icon name="gem" mr={1} />
                Mining
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'harvesting'}
                onClick={() => setCurrentTab('harvesting')}>
                <Icon name="seedling" mr={1} />
                Harvesting
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'cooking'}
                onClick={() => setCurrentTab('cooking')}>
                <Icon name="utensils" mr={1} />
                Cooking
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'analysis'}
                onClick={() => setCurrentTab('analysis')}>
                <Icon name="microscope" mr={1} />
                Analysis
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'social'}
                onClick={() => setCurrentTab('social')}>
                <Icon name="comments" mr={1} />
                Social
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === 'events'}
                onClick={() => setCurrentTab('events')}>
                <Icon name="bolt" mr={1} />
                Events
                {active_events.length > 0 && (
                  <Box inline ml={1} color="good">
                    ({active_events.length})
                  </Box>
                )}
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          <Stack.Item grow>
            {currentTab === 'overview' && (
              <OverviewTab
                data={data}
                act={act}
                bed_owner={bed_owner}
                is_owner={is_owner}
                can_claim={can_claim}
                room_type={room_type}
                in_valid_room={in_valid_room}
              />
            )}
            {currentTab === 'crafting' && (
              <StatPage
                title="Crafting"
                icon="hammer"
                level={crafting_level}
                xp={crafting_xp}
                xpNeeded={crafting_xp_needed}
                maxLevel={max_level}
                effects={[
                  {
                    label: 'Work Bonus',
                    value: `+${crafting_work_bonus.toFixed(1)} per tick`,
                    desc: 'Extra work done per crafting interval',
                  },
                  {
                    label: 'Beauty Bonus',
                    value: (crafting_beauty >= 0 ? '+' : '')
                      + crafting_beauty,
                    desc: 'Bonus to crafted item beauty/quality',
                  },
                ]}
                description={
                  'Crafting skill affects how quickly you work at '
                  + 'crafting tables, forges, and looms. Higher levels '
                  + 'also improve the quality of items you create.'
                }
              />
            )}
            {currentTab === 'mining' && (
              <StatPage
                title="Mining"
                icon="gem"
                level={mining_level}
                xp={mining_xp}
                xpNeeded={mining_xp_needed}
                maxLevel={max_level}
                effects={[
                  {
                    label: 'Work Bonus',
                    value: `+${mining_work_bonus} per tick`,
                    desc: 'Extra work done per mining tick',
                  },
                  {
                    label: 'Yield Multiplier',
                    value: `${mining_yield.toFixed(2)}x`,
                    desc: 'Multiplier to ore yield when mining',
                  },
                ]}
                description={
                  'Mining skill affects how quickly you break through '
                  + 'rock and ore deposits. Higher levels increase the '
                  + 'amount of ore you extract from each deposit.'
                }
              />
            )}
            {currentTab === 'harvesting' && (
              <StatPage
                title="Harvesting"
                icon="seedling"
                level={harvesting_level}
                xp={harvesting_xp}
                xpNeeded={harvesting_xp_needed}
                maxLevel={max_level}
                effects={[
                  {
                    label: 'Work Bonus',
                    value: `+${harvesting_work_bonus} per tick`,
                    desc: 'Extra work done per harvest tick',
                  },
                  {
                    label: 'Yield Bonus',
                    value: `+${harvesting_yield}`,
                    desc: 'Extra items per harvest',
                  },
                ]}
                description={
                  'Harvesting skill affects how quickly you gather '
                  + 'crops, cotton, and wild plants. Higher levels '
                  + 'increase the amount of resources you collect.'
                }
              />
            )}
            {currentTab === 'cooking' && (
              <StatPage
                title="Cooking"
                icon="utensils"
                level={cooking_level}
                xp={cooking_xp}
                xpNeeded={cooking_xp_needed}
                maxLevel={max_level}
                effects={[
                  {
                    label: 'Speed Bonus',
                    value: `+${Math.round((1 - cooking_speed) * 100)}%`,
                    desc: 'Faster cooking time',
                  },
                  {
                    label: 'Quality Bonus',
                    value: (cooking_quality >= 0 ? '+' : '')
                      + cooking_quality,
                    desc: 'Bonus to food quality tier',
                  },
                ]}
                description={
                  'Cooking skill affects how quickly you prepare '
                  + 'food and the quality of meals you create. Higher '
                  + 'quality food provides better faith bonuses when eaten.'
                }
              />
            )}
            {currentTab === 'analysis' && (
              <StatPage
                title="Analysis"
                icon="microscope"
                level={analysis_level}
                xp={analysis_xp}
                xpNeeded={analysis_xp_needed}
                maxLevel={max_level}
                effects={[
                  {
                    label: 'Research Speed',
                    value: `+${(analysis_level - 1) * 5}%`,
                    desc: 'Faster research and analysis tasks',
                  },
                ]}
                description={
                  'Analysis skill affects your ability to research '
                  + 'and study various subjects. Higher levels allow '
                  + 'faster research and unlock advanced discoveries.'
                }
              />
            )}
            {currentTab === 'social' && (
              <StatPage
                title="Social"
                icon="comments"
                level={social_level}
                xp={social_xp}
                xpNeeded={social_xp_needed}
                maxLevel={max_level}
                effects={[
                  {
                    label: 'Buy Discount',
                    value: `-${(social_level - 1) * 2}%`,
                    desc: 'Reduces prices when buying from traders',
                  },
                  {
                    label: 'Sell Bonus',
                    value: `+${(social_level - 1) * 2}%`,
                    desc: 'Increases prices when selling to traders',
                  },
                ]}
                description={
                  'Social skill affects your trading ability. Higher '
                  + 'levels give better prices when buying and selling '
                  + 'goods at the Comms Console.'
                }
              />
            )}
            {currentTab === 'events' && (
              <EventsTab active_events={active_events} />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const OverviewTab = props => {
  const {
    data,
    act,
    bed_owner,
    is_owner,
    can_claim,
    room_type,
    in_valid_room,
  } = props;

  const {
    crafting_level,
    mining_level,
    harvesting_level,
    cooking_level,
    analysis_level,
    social_level,
    crafting_xp,
    mining_xp,
    harvesting_xp,
    cooking_xp,
    analysis_xp,
    social_xp,
    crafting_xp_needed,
    mining_xp_needed,
    harvesting_xp_needed,
    cooking_xp_needed,
    analysis_xp_needed,
    social_xp_needed,
    max_level,
  } = data;

  return (
    <Stack fill vertical>
      {/* Sleeper Ownership Section */}
      <Stack.Item>
        <Section title="Sleeper Ownership">
          <Stack vertical>
            <Stack.Item>
              <Box color="label">
                <Icon name="bed" mr={1} />
                Room Type: <Box inline bold color="white">{room_type}</Box>
              </Box>
            </Stack.Item>
            <Stack.Item>
              {is_owner ? (
                <Box color="good">
                  <Icon name="check" mr={1} />
                  This is your sleeper.
                  {room_type === 'Living Quarters' && (
                    <Box color="label" fontSize="11px" mt={0.5}>
                      +0.025 faith per tick while owned
                    </Box>
                  )}
                </Box>
              ) : bed_owner ? (
                <Box color="bad">
                  <Icon name="times" mr={1} />
                  This sleeper belongs to someone else.
                </Box>
              ) : in_valid_room ? (
                <Box color="average">
                  <Icon name="question" mr={1} />
                  This sleeper is unclaimed.
                </Box>
              ) : (
                <Box color="bad">
                  <Icon name="exclamation-triangle" mr={1} />
                  Sleeper must be in Living Quarters or Barracks.
                </Box>
              )}
            </Stack.Item>
            <Stack.Item mt={1}>
              {!!can_claim && (
                <Button
                  fluid
                  icon="hand-paper"
                  color="good"
                  content="Claim This Sleeper"
                  onClick={() => act('claim_bed')}
                />
              )}
              {!!is_owner && (
                <Button
                  fluid
                  icon="sign-out-alt"
                  color="bad"
                  content="Give Up Ownership"
                  onClick={() => act('unclaim_bed')}
                />
              )}
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      {/* Stats Overview */}
      <Stack.Item grow>
        <Section fill title="Skills Overview">
          <Stack vertical fill>
            <Stack.Item>
              <MiniStatBar
                name="Crafting"
                icon="hammer"
                level={crafting_level}
                xp={crafting_xp}
                xpNeeded={crafting_xp_needed}
                maxLevel={max_level}
              />
            </Stack.Item>
            <Stack.Item>
              <MiniStatBar
                name="Mining"
                icon="gem"
                level={mining_level}
                xp={mining_xp}
                xpNeeded={mining_xp_needed}
                maxLevel={max_level}
              />
            </Stack.Item>
            <Stack.Item>
              <MiniStatBar
                name="Harvesting"
                icon="seedling"
                level={harvesting_level}
                xp={harvesting_xp}
                xpNeeded={harvesting_xp_needed}
                maxLevel={max_level}
              />
            </Stack.Item>
            <Stack.Item>
              <MiniStatBar
                name="Cooking"
                icon="utensils"
                level={cooking_level}
                xp={cooking_xp}
                xpNeeded={cooking_xp_needed}
                maxLevel={max_level}
              />
            </Stack.Item>
            <Stack.Item>
              <MiniStatBar
                name="Analysis"
                icon="microscope"
                level={analysis_level}
                xp={analysis_xp}
                xpNeeded={analysis_xp_needed}
                maxLevel={max_level}
              />
            </Stack.Item>
            <Stack.Item>
              <MiniStatBar
                name="Social"
                icon="comments"
                level={social_level}
                xp={social_xp}
                xpNeeded={social_xp_needed}
                maxLevel={max_level}
              />
            </Stack.Item>
            <Stack.Item>
              <Box color="label" fontSize="11px" textAlign="center" mt={1}>
                Click a tab above for detailed stat info.
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const MiniStatBar = props => {
  const { name, icon, level, xp, xpNeeded, maxLevel } = props;
  const isMaxed = level >= maxLevel;
  const progress = isMaxed ? 1 : xp / xpNeeded;

  return (
    <Box mb={1}>
      <Box>
        <Icon name={icon} mr={1} />
        <Box inline bold>
          {name}
        </Box>
        <Box inline color="label" ml={1}>
          Level {level}
          {isMaxed && (
            <Box as="span" color="good" ml={0.5}>
              (MAX)
            </Box>
          )}
        </Box>
      </Box>
      <ProgressBar
        value={progress}
        color={isMaxed ? 'good' : 'default'}
        mt={0.5}>
        {isMaxed ? 'Mastered' : `${xp} / ${xpNeeded} XP`}
      </ProgressBar>
    </Box>
  );
};

const StatPage = props => {
  const {
    title,
    icon,
    level,
    xp,
    xpNeeded,
    maxLevel,
    effects,
    description,
  } = props;

  const isMaxed = level >= maxLevel;
  const progress = isMaxed ? 1 : xp / xpNeeded;

  return (
    <Section
      fill
      title={(
        <>
          <Icon name={icon} mr={1} />
          {title}
        </>
      )}>
      <Stack vertical fill>
        {/* Level Display */}
        <Stack.Item>
          <Box fontSize="18px" bold textAlign="center">
            Level {level}
            {isMaxed && (
              <Box as="span" color="good" ml={1}>
                (MAX)
              </Box>
            )}
          </Box>
        </Stack.Item>

        {/* XP Progress */}
        <Stack.Item>
          <ProgressBar
            value={progress}
            color={isMaxed ? 'good' : 'default'}>
            {isMaxed ? 'Mastered' : `${xp} / ${xpNeeded} XP`}
          </ProgressBar>
        </Stack.Item>

        {/* Effects */}
        <Stack.Item mt={2}>
          <Box bold mb={1}>Current Bonuses:</Box>
          {effects.map((effect, i) => (
            <Box key={i} mb={1}>
              <Box>
                <Icon name="arrow-right" color="good" mr={1} />
                <Box inline bold>{effect.label}:</Box>
                <Box inline ml={1} color="good">{effect.value}</Box>
              </Box>
              <Box color="label" fontSize="11px" ml={2}>
                {effect.desc}
              </Box>
            </Box>
          ))}
        </Stack.Item>

        {/* Description */}
        <Stack.Item grow>
          <Box
            color="label"
            fontSize="12px"
            mt={2}
            p={1}
            style={{
              background: 'rgba(0,0,0,0.2)',
              borderRadius: '3px',
            }}>
            {description}
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const EventsTab = props => {
  const { active_events = [] } = props;

  const getCategoryInfo = category => {
    switch (category) {
      case 1: // EVENT_POSITIVE
        return { color: 'good', icon: 'arrow-up', label: 'Positive' };
      case 2: // EVENT_NEGATIVE
        return { color: 'bad', icon: 'arrow-down', label: 'Negative' };
      default: // EVENT_NEUTRAL
        return { color: 'average', icon: 'minus', label: 'Neutral' };
    }
  };

  return (
    <Section fill title="Active Events">
      <Stack vertical fill>
        {active_events.length === 0 ? (
          <Stack.Item>
            <Box color="label" textAlign="center" mt={2}>
              <Icon name="clock" size={2} mb={1} />
              <Box>No events currently active.</Box>
              <Box fontSize="11px" mt={1}>
                Events occur randomly throughout the round.
              </Box>
            </Box>
          </Stack.Item>
        ) : (
          active_events.map((event, i) => {
            const catInfo = getCategoryInfo(event.category);
            return (
              <Stack.Item key={i}>
                <Box
                  p={1}
                  mb={1}
                  style={{
                    background: 'rgba(0,0,0,0.3)',
                    borderRadius: '3px',
                    borderLeft: `3px solid`,
                    borderColor: catInfo.color === 'good' ? '#5f5'
                      : catInfo.color === 'bad' ? '#f55' : '#ff5',
                  }}>
                  <Stack>
                    <Stack.Item grow>
                      <Box bold>
                        <Icon
                          name={catInfo.icon}
                          color={catInfo.color}
                          mr={1}
                        />
                        {event.name}
                      </Box>
                      <Box color="label" fontSize="11px" mt={0.5}>
                        {event.desc}
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      <Box
                        color={catInfo.color}
                        bold
                        textAlign="right">
                        <Icon name="clock" mr={1} />
                        {event.remaining_text}
                      </Box>
                    </Stack.Item>
                  </Stack>
                </Box>
              </Stack.Item>
            );
          })
        )}
        <Stack.Item grow />
        <Stack.Item>
          <Box
            color="label"
            fontSize="11px"
            textAlign="center"
            p={1}
            style={{
              background: 'rgba(0,0,0,0.2)',
              borderRadius: '3px',
            }}>
            Events modify outpost conditions. Positive events help,
            negative events hinder, and neutral events (like weather)
            have mixed effects.
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
