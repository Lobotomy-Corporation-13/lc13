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

const SCHOOL_COLORS = {
  terremoto: '#8b6914',
  incendio: '#c44536',
  eleganza: '#5b7c99',
  fondamenti: '#8b8b8b',
};

export const PalermitanSkillTree = (props, context) => {
  const { act, data } = useBackend(context);
  const [selectedSchool, setSelectedSchool]
    = useLocalState(
      context,
      'selectedSchool',
      'terremoto'
    );

  const {
    exp = 0,
    next_threshold = 20,
    skill_points = 0,
    skill_points_spent = 0,
    schools_invested = [],
    schools = [],
    max_schools = 2,
    gear_tier = 1,
    all_passives = [],
  } = data;

  const currentSchool = schools.find(
    s => s.id === selectedSchool
  );
  const canInvest
    = schools_invested.length < max_schools
    || schools_invested.includes(selectedSchool);

  return (
    <Window
      width={700}
      height={580}
      title="Palermitan Style">
      <Window.Content scrollable>
        <Section
          title="Palermitan Style"
          buttons={
            <Box inline color="label">
              {'Points: '}
              <Box inline color="good" bold>
                {skill_points}
              </Box>
              {' | Schools: '}
              <Box inline color="label">
                {schools_invested.length}
                {'/'}
                {max_schools}
              </Box>
            </Box>
          }>
          <Box italic color="label" mb={1}>
            {'Renowned for relentlessly focusing '
              + 'on a single prey during a hunt, '
              + 'concluded with a Coup de '
              + 'Gr\u00e2ce.'}
          </Box>
          <ProgressBar
            value={exp}
            maxValue={next_threshold}
            color="#8b0000">
            {'EXP: ' + exp + ' / '
              + next_threshold}
          </ProgressBar>
          <Box mt={1}>
            <Box inline bold color="label">
              {'Gear Tier: '}
            </Box>
            <Box inline bold color="good">
              {gear_tier}
              {' / 4'}
            </Box>
          </Box>
        </Section>
        <Tabs>
          <Tabs.Tab
            selected={
              selectedSchool === 'lessons'
            }
            color="#9e7c0c"
            onClick={() => setSelectedSchool(
              'lessons'
            )}>
            Lessons Learned
          </Tabs.Tab>
          {schools.map(school => (
            <Tabs.Tab
              key={school.id}
              selected={
                selectedSchool === school.id
              }
              color={SCHOOL_COLORS[school.id]}
              onClick={() => setSelectedSchool(
                school.id
              )}>
              {school.name}
            </Tabs.Tab>
          ))}
        </Tabs>
        {selectedSchool === 'lessons'
          ? (
            <LessonsDisplay
              passives={all_passives}
            />
          )
          : currentSchool
            ? (
              <SchoolDisplay
                school={currentSchool}
                canInvest={canInvest}
                schoolsInvested={
                schools_invested
                }
                act={act}
                skillPoints={skill_points}
              />
            )
            : (
              <NoticeBox>
                Select a school above.
              </NoticeBox>
            )}
      </Window.Content>
    </Window>
  );
};

const SchoolDisplay = props => {
  const {
    school,
    canInvest,
    schoolsInvested,
    act,
    skillPoints,
  } = props;
  const color = SCHOOL_COLORS[school.id]
    || '#888';
  const invested = schoolsInvested.includes(
    school.id
  );

  return (
    <Section
      title={school.name}
      style={{
        borderTop: '2px solid ' + color,
      }}>
      <Box color="label" mb={1}>
        {school.desc}
      </Box>
      <Box
        italic
        color={color}
        fontSize={0.9}
        mb={1}>
        {school.theme}
      </Box>
      {!canInvest && !invested
        ? (
          <NoticeBox danger>
            {'Max schools reached. '
              + 'Cannot invest here.'}
          </NoticeBox>
        )
        : null}
      {(school.tiers || []).map(tier => (
        <TierDisplay
          key={tier.tier}
          tier={tier}
          school={school}
          act={act}
          skillPoints={skillPoints}
        />
      ))}
    </Section>
  );
};

const TierDisplay = props => {
  const { tier, school, act, skillPoints }
    = props;
  const { choices = [] } = tier;
  const completed = choices.some(
    c => c.selected
  );
  const locked = choices.length > 0
    && choices[0].locked;

  return (
    <Section
      title={
        <Flex align="center" inline>
          <Flex.Item>
            {locked
              ? (
                <Icon
                  name="lock"
                  color="bad"
                  mr={1}
                />
              )
              : completed
                ? (
                  <Icon
                    name="check"
                    color="good"
                    mr={1}
                  />
                )
                : (
                  <Icon
                    name="circle"
                    color="label"
                    mr={1}
                  />
                )}
          </Flex.Item>
          <Flex.Item>
            {'Tier ' + tier.tier}
          </Flex.Item>
          <Flex.Item grow={1} />
          <Flex.Item>
            <Box
              inline
              color="label"
              fontSize={0.9}>
              {'Cost: ' + tier.cost}
              {tier.cost > 1
                ? ' points'
                : ' point'}
            </Box>
          </Flex.Item>
        </Flex>
      }>
      <Flex>
        {choices.map(choice => (
          <Flex.Item
            key={choice.id}
            grow={1}
            mr={1}>
            <SkillChoice
              choice={choice}
              tier={tier}
              school={school}
              act={act}
            />
          </Flex.Item>
        ))}
      </Flex>
    </Section>
  );
};

const SkillChoice = props => {
  const { choice, tier, school, act } = props;
  const schoolColor
    = SCHOOL_COLORS[school.id] || '#888';

  let borderColor = 'rgba(255,255,255,0.1)';
  let bgColor = 'rgba(0,0,0,0.2)';
  let statusText = '';
  let statusColor = 'label';

  if (choice.selected) {
    borderColor = '#2d8c2d';
    bgColor = 'rgba(45,140,45,0.15)';
    statusText = 'LEARNED';
    statusColor = 'good';
  } else if (choice.excluded) {
    borderColor = '#8c2d2d';
    bgColor = 'rgba(140,45,45,0.1)';
    statusText = 'EXCLUDED';
    statusColor = 'bad';
  } else if (choice.locked) {
    borderColor = 'rgba(255,255,255,0.05)';
    bgColor = 'rgba(0,0,0,0.3)';
    statusText = 'LOCKED';
    statusColor = 'label';
  } else if (choice.available) {
    borderColor = schoolColor;
    bgColor = schoolColor + '26';
    statusText = 'AVAILABLE';
    statusColor = schoolColor;
  }

  return (
    <Box
      style={{
        border: '2px solid ' + borderColor,
        borderRadius: '4px',
        padding: '8px',
        background: bgColor,
        minHeight: '100px',
      }}>
      <Flex direction="column" height="100%">
        <Flex.Item>
          <Box bold color={statusColor} mb={0.5}>
            {choice.name}
          </Box>
          {statusText
            ? (
              <Box
                inline
                color={statusColor}
                fontSize={0.8}
                mb={0.5}>
                {'[' + statusText + ']'}
              </Box>
            )
            : null}
        </Flex.Item>
        <Flex.Item grow={1}>
          <Box color="label" fontSize={0.9}>
            {choice.desc}
          </Box>
        </Flex.Item>
        <Flex.Item mt={1}>
          {choice.available
            ? (
              <Button
                fluid
                color="red"
                content="Learn Skill"
                onClick={() => act(
                  'select_skill',
                  {
                    skill_type: choice.type,
                    school: school.id,
                    tier: tier.tier,
                  }
                )}
              />
            )
            : null}
        </Flex.Item>
      </Flex>
    </Box>
  );
};

const LessonsDisplay = props => {
  const { passives = [] } = props;

  const getNextTier = duels => {
    if (duels < 1) return '1';
    if (duels < 3) return '3';
    if (duels < 5) return '5';
    return 'MAX';
  };

  const getTierColor = tier => {
    if (tier >= 3) return '#c4a000';
    if (tier >= 2) return '#8ba86e';
    if (tier >= 1) return '#6e8ba8';
    return null;
  };

  return (
    <Section
      title="Lessons Learned"
      style={{
        borderTop: '2px solid #9e7c0c',
      }}>
      <Box color="label" italic mb={1}>
        {'Techniques absorbed from those '
          + 'you have dueled. Each opponent '
          + 'teaches you something new.'}
      </Box>
      {passives.map((p, i) => {
        const unlocked = p.tier > 0;
        const tierColor = getTierColor(
          p.tier
        );
        return (
          <Box
            key={i}
            mb={0.5}
            style={{
              border: '1px solid '
                + (unlocked
                  ? 'rgba(255,255,255,0.2)'
                  : 'rgba(255,255,255,0.05)'
                ),
              borderRadius: '3px',
              padding: '8px',
              background: unlocked
                ? 'rgba(255,255,255,0.05)'
                : 'rgba(0,0,0,0.3)',
              opacity: unlocked
                ? 1
                : 0.5,
            }}>
            <Flex align="center">
              <Flex.Item grow={1}>
                <Box
                  bold
                  color={unlocked
                    ? 'white'
                    : 'label'}>
                  {p.name}
                </Box>
                <Box
                  color="label"
                  fontSize={0.85}>
                  {'Duel: ' + p.source}
                </Box>
              </Flex.Item>
              <Flex.Item>
                {unlocked
                  ? (
                    <Box
                      bold
                      color={tierColor}>
                      {'Tier '
                        + p.tier
                        + '/3'}
                    </Box>
                  )
                  : (
                    <Box color="label">
                      {'Locked ('
                        + p.duels
                        + ' duels, '
                        + 'next: '
                        + getNextTier(
                          p.duels
                        )
                        + ')'}
                    </Box>
                  )}
              </Flex.Item>
            </Flex>
            <Box mt={0.5} fontSize={0.85}>
              <Box
                color={p.tier >= 1
                  ? '#6e8ba8'
                  : 'label'}
                style={{
                  opacity: p.tier >= 1
                    ? 1
                    : 0.6,
                }}>
                {'T1 (1 duel): '
                  + p.t1}
              </Box>
              <Box
                color={p.tier >= 2
                  ? '#8ba86e'
                  : 'label'}
                style={{
                  opacity: p.tier >= 2
                    ? 1
                    : 0.6,
                }}>
                {'T2 (3 duels): '
                  + p.t2}
              </Box>
              <Box
                color={p.tier >= 3
                  ? '#c4a000'
                  : 'label'}
                style={{
                  opacity: p.tier >= 3
                    ? 1
                    : 0.6,
                }}>
                {'T3 (5 duels): '
                  + p.t3}
              </Box>
            </Box>
          </Box>
        );
      })}
    </Section>
  );
};
