import { useBackend } from '../backend';
import {
  Box,
  Button,
  Flex,
  LabeledList,
  Section,
} from '../components';
import { Window } from '../layouts';

export const MiddleStampCard = (
  props,
  context,
) => {
  const { data } = useBackend(context);
  const { party_active } = data;
  return (
    <Window
      title="Stamp Card"
      width={480}
      height={600}>
      <Window.Content scrollable>
        <StampCollection />
        <PartyLocations />
        {!!party_active && <ActiveParty />}
      </Window.Content>
    </Window>
  );
};

const StampCollection = (props, context) => {
  const { data } = useBackend(context);
  const {
    stamps = [],
    stamp_count = 0,
  } = data;
  return (
    <Section
      title={'Stamps (' + stamp_count + ')'}>
      {stamp_count === 0
        ? (
          <Box color="label" italic>
            No stamps yet. Throw a party!
          </Box>
        )
        : (
          <Flex wrap>
            {stamps.map((name, i) => (
              <Flex.Item
                key={i}
                basis="30%"
                mb={0.5}
                mr={0.5}>
                <Box
                  p={0.5}
                  backgroundColor="rgba(153,50,204,0.2)"
                  textAlign="center">
                  {name}
                </Box>
              </Flex.Item>
            ))}
          </Flex>
        )}
    </Section>
  );
};

const PartyLocations = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    locations = [],
    party_active,
    current_area_type,
  } = data;
  const tiers = [
    { num: 1, label: 'Tier 1 \u2014 Safe' },
    { num: 2, label: 'Tier 2 \u2014 Moderate' },
    { num: 3, label: 'Tier 3 \u2014 High Risk' },
  ];
  return (
    <Section title="Party Locations">
      {tiers.map(tier => {
        const tierLocs = locations.filter(
          l => l.tier === tier.num,
        );
        if (!tierLocs.length) {
          return null;
        }
        return (
          <Section
            key={tier.num}
            title={tier.label}
            level={2}>
            {tierLocs.map(loc => {
              const isCurrent
                = loc.area_type
                === current_area_type;
              const canStart
                = loc.unlocked
                && isCurrent
                && !party_active;
              return (
                <Box
                  key={loc.name}
                  p={0.5}
                  mb={0.5}
                  backgroundColor={
                    isCurrent
                      ? 'rgba(153,50,204,0.15)'
                      : 'transparent'
                  }>
                  <Flex
                    align="center"
                    justify="space-between">
                    <Flex.Item grow>
                      <Box bold>
                        {loc.name}
                        {isCurrent
                          && ' \u2190 You are here'}
                      </Box>
                      <Box
                        color="label"
                        fontSize="11px">
                        {loc.flavor}
                      </Box>
                      <Box
                        color="good"
                        fontSize="11px"
                        mt={0.25}>
                        {loc.buff_name
                          + ': '
                          + loc.buff_desc}
                      </Box>
                      {!loc.unlocked && (
                        <Box
                          color="bad"
                          fontSize="11px">
                          {'Locked: '
                            + loc.unlock_text}
                        </Box>
                      )}
                    </Flex.Item>
                    <Flex.Item>
                      <Button
                        content="Start Party"
                        disabled={!canStart}
                        color="purple"
                        onClick={() => act(
                          'start_party',
                          {
                            area_type:
                              loc.area_type,
                          },
                        )} />
                    </Flex.Item>
                  </Flex>
                </Box>
              );
            })}
          </Section>
        );
      })}
    </Section>
  );
};

const ActiveParty = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    party_time_elapsed = 0,
    party_can_end,
    party_attendees = 0,
    party_location_name = '',
    player_ahn = 0,
    items = [],
  } = data;
  const mins = Math.floor(
    party_time_elapsed / 60,
  );
  const secs = party_time_elapsed % 60;
  const timeStr
    = mins + ':'
    + (secs < 10 ? '0' : '') + secs;
  const categories = {};
  items.forEach(item => {
    if (!categories[item.category]) {
      categories[item.category] = [];
    }
    categories[item.category].push(item);
  });
  return (
    <Section
      title={
        'Active Party: '
        + party_location_name
      }>
      <LabeledList>
        <LabeledList.Item label="Time">
          {timeStr}
          {!party_can_end
            && ' (5:00 minimum)'}
        </LabeledList.Item>
        <LabeledList.Item label="Attendees">
          {party_attendees}
        </LabeledList.Item>
        <LabeledList.Item label="Your Ahn">
          {player_ahn}
        </LabeledList.Item>
      </LabeledList>
      <Box mt={1}>
        <Button
          content="End Party"
          disabled={!party_can_end}
          color="good"
          onClick={() => act('end_party')} />
      </Box>
      <Section
        title="Spawn Items"
        level={2}
        mt={1}>
        {Object.keys(categories).map(
          cat => (
            <Section
              key={cat}
              title={cat}
              level={3}>
              <Flex wrap>
                {categories[cat].map(
                  item => (
                    <Flex.Item
                      key={item.name}
                      basis="48%"
                      mb={0.5}
                      mr="1%">
                      <Button
                        fluid
                        disabled={
                          player_ahn
                          < item.cost
                        }
                        onClick={() => act(
                          'spawn_item',
                          {
                            item_type:
                              item.type,
                          },
                        )}>
                        {item.name
                          + ' ('
                          + item.cost
                          + ')'}
                      </Button>
                      <Box
                        color="label"
                        fontSize="10px">
                        {item.desc}
                      </Box>
                    </Flex.Item>
                  ),
                )}
              </Flex>
            </Section>
          ),
        )}
      </Section>
    </Section>
  );
};
