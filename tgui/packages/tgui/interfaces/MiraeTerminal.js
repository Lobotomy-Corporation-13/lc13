import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Table,
} from '../components';
import { Window } from '../layouts';

const STATE_LABEL = {
  1: 'Active',
  2: 'In grace',
  3: 'Lapsed',
};

const STATE_COLOR = {
  1: 'good',
  2: 'average',
  3: 'bad',
};

const ADDON_LABEL = [
  [1, 'Death'],
  [2, 'Treatment'],
  [4, 'Surgery'],
];

// Deciseconds to m:ss. The backend counts in ticks and everything shown here
// is a countdown, so this is the only place that conversion happens.
const asClock = ds => {
  const total = Math.max(0, Math.round(ds / 10));
  const mins = Math.floor(total / 60);
  const secs = total % 60;
  return mins + ':' + (secs < 10 ? '0' : '') + secs;
};

// The named procedures a tier waives, priced at what they cost without it. Only
// the Surgery tier carries one; the others read as a flat promise and do not
// need itemising.
const CoveredList = props => {
  const { covers = [] } = props;
  if (!covers.length) {
    return null;
  }
  return (
    <Box mt={0.5} ml={1}>
      {covers.map(c => (
        <Box key={c.name} color="label" fontSize="0.9em">
          {c.name}
          <Box inline ml={1} color="good">
            {'free'}
          </Box>
          <Box inline ml={1}>
            {'(' + c.cost + ' ahn otherwise)'}
          </Box>
        </Box>
      ))}
    </Box>
  );
};

const coverList = held => {
  const names = ADDON_LABEL
    .filter(pair => (held & pair[0]) !== 0)
    .map(pair => pair[1]);
  return names.length ? names.join(', ') : 'None';
};

export const MiraeTerminal = (props, context) => {
  const { data } = useBackend(context);
  const { has_account, is_staff } = data;
  // Staff are shown the company's book instead of a shopfront. Nothing they
  // could buy is theirs to buy, so none of the customer panels are rendered.
  if (is_staff) {
    return (
      <Window title="Mirae Staff Terminal" width={560} height={660}>
        <Window.Content scrollable>
          <PriceListPanel />
          <RosterPanel />
        </Window.Content>
      </Window>
    );
  }
  return (
    <Window title="Mirae Policy Terminal" width={520} height={620}>
      <Window.Content scrollable>
        {!has_account && (
          <NoticeBox>
            No account is registered in your name. You may read the terms,
            but nothing here can charge you.
          </NoticeBox>
        )}
        <AccountPanel />
        <CoverPanel />
        <DebtPanel />
      </Window.Content>
    </Window>
  );
};

// The same tiers the customer screen sells, with the buttons taken off. Staff
// are the ones talking a client into a policy, so they need the prices to hand
// even though the terminal will not let them buy one.
const PriceListPanel = (props, context) => {
  const { data } = useBackend(context);
  const { tiers = [], period = 0 } = data;
  return (
    <Section title="Cover We Sell">
      <Box color="label" mb={1}>
        {'Every policy renews for its full price every '
          + asClock(period)
          + '. Nothing is drafted - the client pays at a terminal or lapses.'}
      </Box>
      <Table>
        <Table.Row header>
          <Table.Cell>Cover</Table.Cell>
          <Table.Cell collapsing>Price</Table.Cell>
          <Table.Cell collapsing>Renewal</Table.Cell>
        </Table.Row>
        {tiers.map(tier => (
          <Table.Row key={tier.flag}>
            <Table.Cell>
              <Box bold>{tier.name}</Box>
              <Box color="label" fontSize="0.9em">
                {tier.desc}
              </Box>
              <CoveredList covers={tier.covers} />
            </Table.Cell>
            <Table.Cell collapsing>
              {tier.cost} ahn
            </Table.Cell>
            <Table.Cell collapsing color="label">
              {tier.premium} / period
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

const RosterPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { clients = [], is_director } = data;
  return (
    <Section title="Client Register">
      {clients.length === 0 && (
        <Box color="label" italic>
          Nobody has signed up yet.
        </Box>
      )}
      {clients.length > 0 && (
        <Table>
          <Table.Row header>
            <Table.Cell>Client</Table.Cell>
            <Table.Cell>Cover</Table.Cell>
            <Table.Cell collapsing>Standing</Table.Cell>
            <Table.Cell collapsing>Due in</Table.Cell>
            <Table.Cell collapsing>Owed</Table.Cell>
            {!!is_director && <Table.Cell collapsing />}
          </Table.Row>
          {clients.map(c => (
            <Table.Row key={c.ref}>
              <Table.Cell>{c.name}</Table.Cell>
              <Table.Cell color="label">
                {coverList(c.held)}
              </Table.Cell>
              <Table.Cell collapsing>
                {c.state ? (
                  <Box color={STATE_COLOR[c.state]}>
                    {STATE_LABEL[c.state]}
                  </Box>
                ) : (
                  <Box color="label">Uninsured</Box>
                )}
              </Table.Cell>
              <Table.Cell collapsing>
                {c.state ? (
                  <Box color={c.cancelled ? 'bad' : 'label'}>
                    {asClock(c.due)}
                    {c.cancelled ? ' (ending)' : ''}
                  </Box>
                ) : (
                  <Box color="label">-</Box>
                )}
              </Table.Cell>
              <Table.Cell
                collapsing
                color={c.debt > 0 ? 'bad' : 'label'}>
                {c.debt}
              </Table.Cell>
              {!!is_director && (
                <Table.Cell collapsing>
                  <Button
                    icon="eraser"
                    color="bad"
                    disabled={c.debt <= 0}
                    onClick={() => act('writeoff', { ref: c.ref })}>
                    Write off
                  </Button>
                </Table.Cell>
              )}
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const AccountPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    balance = 0,
    debt = 0,
    policy_state = 0,
    premium = 0,
    covered_left = 0,
    held = 0,
    due = 0,
    cancelled,
  } = data;
  return (
    <Section title="Account">
      <LabeledList>
        <LabeledList.Item label="Balance">
          {balance} ahn
        </LabeledList.Item>
        <LabeledList.Item label="Outstanding">
          <Box color={debt > 0 ? 'bad' : 'good'}>
            {debt} ahn
          </Box>
        </LabeledList.Item>
        <LabeledList.Item label="Policy">
          {policy_state ? (
            <Box color={STATE_COLOR[policy_state]}>
              {STATE_LABEL[policy_state]}
            </Box>
          ) : (
            <Box color="label">None held</Box>
          )}
        </LabeledList.Item>
        {!!policy_state && (
          <LabeledList.Item label="Renewal">
            {premium} ahn
            <Button
              ml={1}
              icon="coins"
              disabled={balance < premium || cancelled}
              onClick={() => act('renew')}>
              Pay now
            </Button>
          </LabeledList.Item>
        )}
        {!!policy_state && (
          <LabeledList.Item label="Due in">
            <Box color={due < 3000 ? 'bad' : 'good'} inline>
              {asClock(due)}
            </Box>
            <Box color="label" inline ml={1}>
              {cancelled
                ? '- cover ends here, nothing further is charged'
                : '- nothing is taken automatically'}
            </Box>
          </LabeledList.Item>
        )}
        {!!policy_state && (
          <LabeledList.Item label="Cancel">
            <Button
              icon={cancelled ? 'undo' : 'ban'}
              color={cancelled ? null : 'bad'}
              onClick={() => act('cancel')}>
              {cancelled ? 'Resume policy' : 'Cancel policy'}
            </Button>
          </LabeledList.Item>
        )}
        {!!(held & 2) && (
          <LabeledList.Item label="Treatments left">
            {covered_left} this period
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};

const CoverPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { tiers = [], held = 0, balance = 0, has_card } = data;
  return (
    <Section title="Cover">
      {!has_card && (
        <NoticeBox mb={1}>
          Opening an account needs a registered ID card in hand. Renewals
          afterwards do not.
        </NoticeBox>
      )}
      {tiers.map(tier => {
        const owned = (held & tier.flag) !== 0;
        const afford = balance >= tier.cost;
        return (
          <Box key={tier.flag} mb={1.5}>
            <Box bold>
              {tier.name}
              <Button
                ml={1}
                icon={owned ? 'check' : 'file-signature'}
                color={owned ? 'good' : null}
                disabled={owned || !afford || !has_card}
                onClick={() => act('buy', { flags: tier.flag })}>
                {owned ? 'Held' : tier.cost + ' ahn'}
              </Button>
            </Box>
            <Box color="label" fontSize="0.9em">
              {tier.desc}
            </Box>
            <CoveredList covers={tier.covers} />
            <Box color="label" fontSize="0.9em">
              {'Renews at ' + tier.premium + ' ahn, paid at a terminal.'}
            </Box>
          </Box>
        );
      })}
    </Section>
  );
};

const DebtPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { debt = 0, balance = 0 } = data;
  if (!debt) {
    return null;
  }
  return (
    <Section title="Settlement">
      <Box mb={1}>
        Mirae Life Insurance is owed {debt} ahn.
      </Box>
      <Button
        icon="hand-holding-usd"
        disabled={balance <= 0}
        onClick={() => act('settle', { amount: debt })}>
        Settle in full
      </Button>
      <Button
        ml={1}
        icon="coins"
        disabled={balance <= 0}
        onClick={() => act('settle', { amount: Math.floor(debt / 2) })}>
        Pay half
      </Button>
    </Section>
  );
};
