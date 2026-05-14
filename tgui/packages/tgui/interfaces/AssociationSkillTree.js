import {
  useBackend,
  useSharedState,
} from '../backend';
import {
  Box,
  Button,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const AssociationSkillTree = (
  props,
  context,
) => {
  const { act, data } = useBackend(context);
  const {
    association_name = 'Association',
    current_exp = 0,
    next_threshold = 0,
    skill_points_available = 0,
    skill_points_spent = 0,
    total_skill_points = 0,
    max_branches = 2,
    invested_branch_count = 0,
    branches = [],
  } = data;
  const [tab, setTab] = useSharedState(
    context, 'tab', 0,
  );
  const activeIdx = Math.min(
    tab,
    Math.max(branches.length - 1, 0),
  );
  const branch = branches[activeIdx];
  const isMaxed = next_threshold === 'MAX';
  const expRatio = isMaxed
    ? 1
    : (next_threshold > 0
      ? current_exp / next_threshold
      : 0);
  const expLabel = isMaxed
    ? current_exp + ' EXP (MAX)'
    : current_exp + ' / '
      + next_threshold + ' EXP';
  return (
    <Window
      title={
        association_name + ' Skill Tree'
      }
      width={480}
      height={520}>
      <Window.Content scrollable>
        <Section title="Progress">
          <ProgressBar
            value={expRatio}
            color="good">
            {expLabel}
          </ProgressBar>
          <Box mt={1} bold>
            {'Skill Points: '
              + skill_points_available}
          </Box>
          <Box
            fontSize="11px"
            color="label">
            {'Spent: '
              + skill_points_spent
              + ' | Total: '
              + total_skill_points}
          </Box>
          <Box
            fontSize="11px"
            color="label">
            {'Branches: '
              + invested_branch_count
              + ' / ' + max_branches}
          </Box>
        </Section>
        {branches.length === 0 && (
          <NoticeBox>
            No skills available yet.
          </NoticeBox>
        )}
        {branches.length > 0 && (
          <>
            <Tabs>
              {branches.map((b, i) => (
                <Tabs.Tab
                  key={b.name}
                  selected={
                    activeIdx === i
                  }
                  onClick={
                    () => setTab(i)
                  }>
                  {b.name}
                  {!!b.invested
                    && ' \u2713'}
                </Tabs.Tab>
              ))}
            </Tabs>
            {!!branch && (
              <BranchContent
                branch={branch}
                act={act}
              />
            )}
          </>
        )}
      </Window.Content>
    </Window>
  );
};

const BranchContent = props => {
  const { branch, act } = props;
  return (
    <>
      {branch.tiers.map(tier => (
        <Section
          key={tier.tier}
          title={
            'Tier ' + tier.tier
            + ' \u2014 Cost: '
            + tier.cost
          }>
          {tier.choices.length === 0
            && (
              <Box color="label" italic>
                No skills defined.
              </Box>
            )}
          {tier.choices.length > 0
            && (
              <Stack>
                {tier.choices.map(c => (
                  <Stack.Item
                    key={c.choice}
                    grow>
                    <SkillChoice
                      skill={c}
                      branchName={
                        branch.name
                      }
                      tierNum={
                        tier.tier
                      }
                      act={act}
                    />
                  </Stack.Item>
                ))}
              </Stack>
            )}
        </Section>
      ))}
    </>
  );
};

const SkillChoice = props => {
  const {
    skill,
    branchName,
    tierNum,
    act,
  } = props;
  let color;
  let icon;
  if (skill.selected) {
    color = 'good';
    icon = 'check';
  } else if (skill.excluded) {
    color = 'bad';
    icon = 'times';
  } else if (skill.locked) {
    icon = 'lock';
  }
  return (
    <Box>
      <Button
        fluid
        color={color}
        icon={icon}
        disabled={
          !skill.available
          && !skill.selected
        }
        onClick={() => act(
          'select_skill',
          {
            branch: branchName,
            tier: tierNum,
            choice: skill.choice,
          },
        )}>
        {skill.name}
      </Button>
      <Box
        fontSize="11px"
        color="label"
        mt={0.5}
        px={0.5}>
        {skill.desc}
      </Box>
    </Box>
  );
};
