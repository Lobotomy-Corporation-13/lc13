import { useBackend } from '../backend';
import {
  Box,
  Button,
  Section,
  Stack,
  Table,
} from '../components';
import { formatMoney } from '../format';
import { Window } from '../layouts';

const TABS = ['knowledge', 'bestiary', 'shop', 'events'];

const TAB_LABELS = {
  knowledge: 'Knowledge',
  bestiary: 'Bestiary',
  shop: 'Shop',
  events: 'Events',
};

export const DieciTome = (props, context) => {
  const { act, data } = useBackend(context);
  const { tab = 'knowledge' } = data;

  return (
    <Window width={520} height={480}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section>
              <Stack>
                {TABS.map(t => (
                  <Stack.Item key={t}>
                    <Button
                      selected={tab === t}
                      content={TAB_LABELS[t]}
                      onClick={() => act('tab', {
                        tab: t,
                      })}
                    />
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            {tab === 'knowledge' && (
              <KnowledgeTab />
            )}
            {tab === 'bestiary' && (
              <BestiaryTab />
            )}
            {tab === 'shop' && (
              <ShopTab />
            )}
            {tab === 'events' && (
              <EventsTab />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const KnowledgeTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    stored_knowledge = [],
    stored_count = 0,
    observed_target = null,
    total_exp = 0,
    skill_points = 0,
  } = data;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Status">
          <Box>
            {'EXP: ' + total_exp}
            {' | SP: ' + skill_points}
          </Box>
          {observed_target && (
            <Box color="good">
              {'Observing: '}
              {observed_target}
            </Box>
          )}
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Tome Actions">
          <Box color="label" mb={1}>
            Record moves active knowledge
            into the tome. Re-read restores
            stored entries back to active.
          </Box>
          <Stack>
            <Stack.Item>
              <Button
                content="Record"
                icon="book"
                onClick={() => act('record')}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                content="Re-read"
                icon="book-open"
                disabled={stored_count === 0}
                onClick={() => act('reread')}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          title={
            'Stored Knowledge ('
            + stored_count + ')'
          }
          scrollable
          fill
        >
          {stored_count === 0 && (
            <Box color="label" italic>
              No stored knowledge.
              Record active entries to
              store them in the tome.
            </Box>
          )}
          {stored_count > 0 && (
            <Table>
              <Table.Row header>
                <Table.Cell>Entry</Table.Cell>
                <Table.Cell>Source</Table.Cell>
                <Table.Cell>Reads</Table.Cell>
              </Table.Row>
              {stored_knowledge.map(
                (entry, i) => (
                  <Table.Row key={i}>
                    <Table.Cell>
                      <Box bold>
                        {entry.type
                          + ' L'
                          + entry.level}
                      </Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Box
                        color="average"
                        fontSize="11px"
                      >
                        {entry.source
                          || 'Unknown'}
                      </Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Box
                        color="label"
                        fontSize="11px"
                      >
                        {entry
                          .rereads_remaining}
                      </Box>
                    </Table.Cell>
                  </Table.Row>
                )
              )}
            </Table>
          )}
        </Section>
      </Stack.Item>
      {observed_target && (
        <Stack.Item>
          <Section title="Observation">
            <Box mb={1}>
              {'Observing: '}
              {observed_target}
            </Box>
            <Button
              content="Stop Observing"
              color="bad"
              onClick={
                () => act('stop_observation')
              }
            />
          </Section>
        </Stack.Item>
      )}
    </Stack>
  );
};

const BestiaryTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    bestiary = [],
    bestiary_page = 1,
    bestiary_total = 0,
  } = data;

  if (bestiary_total === 0) {
    return (
      <Section title="Bestiary" fill>
        <Box color="label" italic>
          No creatures scanned yet.
          Use your Tome on hostile creatures
          to scan them.
        </Box>
      </Section>
    );
  }

  const entry = bestiary[bestiary_page - 1];
  if (!entry) {
    return (
      <Section title="Bestiary" fill>
        <Box color="bad">Invalid page.</Box>
      </Section>
    );
  }

  return (
    <Section title="Bestiary" fill>
      <Stack vertical>
        <Stack.Item>
          <Stack>
            <Stack.Item>
              <Button
                icon="arrow-left"
                disabled={bestiary_page <= 1}
                onClick={() => act('bestiary_page', {
                  page: bestiary_page - 1,
                })}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Box textAlign="center" bold>
                {'Page ' + bestiary_page}
                {' / ' + bestiary_total}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="arrow-right"
                disabled={
                  bestiary_page >= bestiary_total
                }
                onClick={() => act('bestiary_page', {
                  page: bestiary_page + 1,
                })}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Section
            title={entry.name}
            level={2}
          >
            <Box color="label" mb={1}>
              {entry.desc}
            </Box>
            <Table>
              <Table.Row>
                <Table.Cell bold>
                  Max Health
                </Table.Cell>
                <Table.Cell>
                  {entry.max_health}
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell bold>
                  Melee Damage
                </Table.Cell>
                <Table.Cell>
                  {entry.melee_damage}
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell bold>
                  Knowledge Level
                </Table.Cell>
                <Table.Cell>
                  {'L' + entry.knowledge_level}
                </Table.Cell>
              </Table.Row>
            </Table>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ShopTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    shop_items = [],
    balance = 0,
  } = data;

  return (
    <Section title="Dieci Supply Shop">
      <Box mb={1} bold>
        {'Balance: ' + formatMoney(balance) + ' Ahn'}
      </Box>
      <Table>
        <Table.Row header>
          <Table.Cell>Item</Table.Cell>
          <Table.Cell>Cost</Table.Cell>
          <Table.Cell />
        </Table.Row>
        {shop_items.map((item, i) => (
          <Table.Row key={i}>
            <Table.Cell>
              <Box bold>{item.name}</Box>
              <Box color="label" fontSize="11px">
                {item.desc}
              </Box>
            </Table.Cell>
            <Table.Cell>
              {formatMoney(item.cost) + ' Ahn'}
            </Table.Cell>
            <Table.Cell>
              <Button
                content="Buy"
                disabled={balance < item.cost}
                onClick={() => act('purchase', {
                  index: i + 1,
                })}
              />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

const AVAILABLE_EVENTS = [
  {
    key: 'book_reading',
    name: 'Book Reading',
    cost: 500,
    desc: '6 ticks, 40s apart. '
      + 'Attendees heal 17% SP per tick.',
  },
  {
    key: 'training_session',
    name: 'Training Session',
    cost: 1000,
    desc: '6 ticks, 50s apart. '
      + 'Attendees gain +4 all attributes.',
  },
  {
    key: 'charity_sermon',
    name: 'Charity Sermon',
    cost: 1800,
    desc: '7 ticks, 60s apart. '
      + '255 Ahn split among attendees.',
  },
];

const EventsTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    is_director = false,
    has_active_event = false,
    event_name = '',
    event_current_tick = 0,
    event_total_ticks = 0,
    event_can_tick = false,
    event_tick_cooldown = 0,
    event_on_cooldown = false,
    event_cooldown_left = 0,
    balance = 0,
  } = data;

  if (!is_director) {
    return (
      <Section title="Events" fill>
        <Box color="label" italic>
          Only the Director can host events.
        </Box>
      </Section>
    );
  }

  if (has_active_event) {
    return (
      <Section title={'Event: ' + event_name} fill>
        <Box mb={1} bold>
          {'Progress: ' + event_current_tick}
          {' / ' + event_total_ticks}
        </Box>
        {!event_can_tick
          && event_tick_cooldown > 0 && (
          <Box color="label" mb={1}>
            {'Next tick in: '}
            {event_tick_cooldown + 's'}
          </Box>
        )}
        <Stack>
          <Stack.Item>
            <Button
              content="Perform Tick"
              icon="book-open"
              disabled={!event_can_tick}
              onClick={() => act('event_tick')}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              content="Cancel Event"
              color="bad"
              icon="times"
              onClick={
                () => act('cancel_event')
              }
            />
          </Stack.Item>
        </Stack>
      </Section>
    );
  }

  return (
    <Section title="Host an Event" fill>
      {event_on_cooldown && (
        <Box color="bad" mb={1}>
          {'Cooldown: ' + event_cooldown_left}
          {'s remaining'}
        </Box>
      )}
      <Box mb={1} bold>
        {'Balance: ' + formatMoney(balance)}
        {' Ahn'}
      </Box>
      <Table>
        <Table.Row header>
          <Table.Cell>Event</Table.Cell>
          <Table.Cell>Cost</Table.Cell>
          <Table.Cell />
        </Table.Row>
        {AVAILABLE_EVENTS.map(ev => (
          <Table.Row key={ev.key}>
            <Table.Cell>
              <Box bold>{ev.name}</Box>
              <Box
                color="label"
                fontSize="11px"
              >
                {ev.desc}
              </Box>
            </Table.Cell>
            <Table.Cell>
              {formatMoney(ev.cost) + ' Ahn'}
            </Table.Cell>
            <Table.Cell>
              <Button
                content="Host"
                disabled={
                  balance < ev.cost
                  || event_on_cooldown
                }
                onClick={() => act(
                  'start_event',
                  { event_type: ev.key }
                )}
              />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};
