import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Flex,
  Icon,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

// School color themes
const SCHOOL_COLORS = {
  fauvist: '#c44536',
  pointillist: '#4a7c59',
  cubist: '#5b7c99',
  corporist: '#8b4513',
};

export const RingSkillTree = (props, context) => {
  const { act, data } = useBackend(context);
  const [selectedSchool, setSelectedSchool] = useLocalState(
    context,
    'selectedSchool',
    'fauvist'
  );

  const {
    exp = 0,
    next_threshold = 50,
    skill_points = 0,
    skill_points_spent = 0,
    schools_invested = [],
    schools = [],
    main_school = null,
    max_schools = 2,
  } = data;

  const availablePoints = skill_points;
  const currentSchool = schools.find(s => s.id === selectedSchool);
  const canInvestInSchool
    = schools_invested.length < max_schools
    || schools_invested.includes(selectedSchool);

  // Get the display name for a school
  const getSchoolDisplayName = id => {
    const schoolNames = {
      fauvist: 'Fauvist',
      pointillist: 'Pointillist',
      cubist: 'Cubist',
      corporist: 'Corporist',
    };
    return schoolNames[id] || id;
  };

  return (
    <Window width={700} height={550} title="Ring Skill Tree">
      <Window.Content>
        <Stack vertical fill>
          {/* Header with EXP and Points */}
          <Stack.Item>
            <Section>
              <Stack>
                <Stack.Item grow>
                  <Box bold>Artistic EXP</Box>
                  <ProgressBar
                    value={exp}
                    maxValue={next_threshold}
                    color="purple"
                  >
                    {exp} / {next_threshold}
                  </ProgressBar>
                </Stack.Item>
                <Stack.Item basis="200px">
                  <Box bold>Skill Points</Box>
                  <Box fontSize="1.5em" textAlign="center" color="gold">
                    {availablePoints} available
                    <Box fontSize="0.6em" color="gray">
                      ({skill_points_spent} spent)
                    </Box>
                  </Box>
                </Stack.Item>
              </Stack>
              {schools_invested.length > 0 && (
                <Box mt={1} fontSize="0.9em" color="gray">
                  Schools invested:{' '}
                  {schools_invested.map(s => getSchoolDisplayName(s))
                    .join(', ')}
                  {schools_invested.length >= max_schools && (
                    <Box as="span" color="orange" ml={1}>
                      (Maximum reached)
                    </Box>
                  )}
                </Box>
              )}
              {schools_invested.length > 0 && (
                <Box mt={1}>
                  <Box as="span" fontSize="0.9em" color="gray" mr={1}>
                    Main School:
                  </Box>
                  {schools_invested.map(school => (
                    <Button
                      key={school}
                      selected={main_school === school}
                      color={main_school === school
                        ? SCHOOL_COLORS[school]
                        : 'default'}
                      onClick={() => act('set_main_school', { school })}
                    >
                      {getSchoolDisplayName(school)}
                    </Button>
                  ))}
                  {main_school && (
                    <Box
                      as="span"
                      ml={1}
                      fontSize="0.85em"
                      color="label"
                      italic
                    >
                      (Visible when examined)
                    </Box>
                  )}
                </Box>
              )}
            </Section>
          </Stack.Item>

          {/* School Tabs */}
          <Stack.Item>
            <Tabs fluid>
              {schools.map(school => (
                <Tabs.Tab
                  key={school.id}
                  selected={selectedSchool === school.id}
                  onClick={() => setSelectedSchool(school.id)}
                  color={
                    selectedSchool === school.id
                      ? SCHOOL_COLORS[school.id]
                      : null
                  }
                >
                  {school.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>

          {/* School Content */}
          <Stack.Item grow>
            {currentSchool ? (
              <SchoolDisplay
                school={currentSchool}
                canInvest={canInvestInSchool}
                availablePoints={availablePoints}
              />
            ) : (
              <NoticeBox color="red">No school data available</NoticeBox>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const SchoolDisplay = (props, context) => {
  const { school, canInvest, availablePoints } = props;
  const schoolColor = SCHOOL_COLORS[school.id] || 'white';

  return (
    <Section
      fill
      scrollable
      title={
        <Box inline>
          <Box as="span" color={schoolColor} bold>
            {school.name}
          </Box>
          <Box as="span" color="gray" ml={2} fontSize="0.9em">
            {school.theme}
          </Box>
        </Box>
      }
    >
      <Box mb={2} color="label" italic>
        {school.desc}
      </Box>

      {!canInvest && (
        <NoticeBox color="orange" mb={2}>
          You have already invested in your maximum number of schools. You
          cannot learn skills from this school.
        </NoticeBox>
      )}

      <Stack vertical>
        {school.tiers.map(tier => (
          <Stack.Item key={tier.tier}>
            <TierDisplay
              tier={tier}
              schoolId={school.id}
              schoolColor={schoolColor}
              canInvest={canInvest}
              availablePoints={availablePoints}
            />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const TierDisplay = (props, context) => {
  const { tier, schoolId, schoolColor, canInvest, availablePoints } = props;
  const { act } = useBackend(context);

  const tierLocked = tier.choices.some(c => c.locked);
  const tierCompleted = tier.choices.some(c => c.selected);
  const tierBorder = tierCompleted
    ? schoolColor
    : tierLocked ? '#444' : '#666';

  return (
    <Box
      mb={2}
      p={1}
      style={{
        border: `1px solid ${tierBorder}`,
        borderRadius: '4px',
        backgroundColor: tierLocked ? 'rgba(0,0,0,0.3)' : 'transparent',
      }}
    >
      <Flex align="center" mb={1}>
        <Flex.Item>
          <Box bold color={tierLocked ? 'gray' : schoolColor}>
            Tier {tier.tier}
          </Box>
        </Flex.Item>
        <Flex.Item grow />
        <Flex.Item>
          <Box color={tierLocked ? 'gray' : 'gold'} fontSize="0.9em">
            Cost: {tier.cost} point{tier.cost > 1 ? 's' : ''}
          </Box>
        </Flex.Item>
        {tierLocked && (
          <Flex.Item ml={1}>
            <Icon name="lock" color="gray" />
          </Flex.Item>
        )}
        {tierCompleted && (
          <Flex.Item ml={1}>
            <Icon name="check" color="green" />
          </Flex.Item>
        )}
      </Flex>

      <Stack>
        {tier.choices.map(choice => (
          <Stack.Item key={choice.id} grow basis={0}>
            <SkillChoice
              choice={choice}
              schoolId={schoolId}
              tier={tier.tier}
              schoolColor={schoolColor}
              canInvest={canInvest}
              availablePoints={availablePoints}
            />
          </Stack.Item>
        ))}
      </Stack>
    </Box>
  );
};

const SkillChoice = (props, context) => {
  const {
    choice,
    schoolId,
    tier,
    schoolColor,
    canInvest,
    availablePoints,
  } = props;
  const { act } = useBackend(context);

  // Determine the visual state
  let borderColor = '#555';
  let bgColor = 'transparent';
  let textColor = 'white';
  let statusIcon = null;
  let statusColor = null;

  if (choice.selected) {
    borderColor = schoolColor;
    bgColor = 'rgba(255,255,255,0.1)';
    statusIcon = 'check-circle';
    statusColor = 'green';
  } else if (choice.excluded) {
    borderColor = '#333';
    bgColor = 'rgba(0,0,0,0.3)';
    textColor = 'gray';
    statusIcon = 'times-circle';
    statusColor = 'red';
  } else if (choice.locked) {
    borderColor = '#333';
    bgColor = 'rgba(0,0,0,0.2)';
    textColor = 'gray';
    statusIcon = 'lock';
    statusColor = 'gray';
  } else if (choice.available && canInvest && availablePoints >= tier) {
    borderColor = 'gold';
    statusIcon = 'plus-circle';
    statusColor = 'gold';
  }

  const canSelect
    = choice.available
    && canInvest
    && availablePoints >= tier
    && !choice.selected
    && !choice.excluded;

  return (
    <Box
      p={1}
      m={0.5}
      style={{
        border: `1px solid ${borderColor}`,
        borderRadius: '4px',
        backgroundColor: bgColor,
        cursor: canSelect ? 'pointer' : 'default',
        transition: 'all 0.2s',
      }}
      onClick={() => {
        if (canSelect) {
          act('select_skill', {
            skill_type: choice.type,
            school: schoolId,
            tier: tier,
          });
        }
      }}
    >
      <Flex align="center" mb={0.5}>
        <Flex.Item grow>
          <Box bold color={textColor} fontSize="1.1em">
            {choice.name}
          </Box>
        </Flex.Item>
        {statusIcon && (
          <Flex.Item>
            <Icon name={statusIcon} color={statusColor} size={1.2} />
          </Flex.Item>
        )}
      </Flex>
      <Box
        color={choice.locked || choice.excluded ? 'gray' : 'label'}
        fontSize="0.85em">
        {choice.desc}
      </Box>
      {canSelect && (
        <Button
          mt={1}
          fluid
          color="good"
          content="Learn Skill"
          onClick={e => {
            e.stopPropagation();
            act('select_skill', {
              skill_type: choice.type,
              school: schoolId,
              tier: tier,
            });
          }}
        />
      )}
    </Box>
  );
};
