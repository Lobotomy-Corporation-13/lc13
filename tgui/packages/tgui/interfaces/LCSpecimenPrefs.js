import { useBackend } from '../backend';
import { Box, Button, Flex, Section, Stack } from '../components';
import { Window } from '../layouts';

// Priority levels, matching the JP_* defines on the DM side. Buttons share a
// neutral look; the currently selected level is highlighted green.
const LEVELS = [
  { level: 3, label: 'High' },
  { level: 2, label: 'Medium' },
  { level: 1, label: 'Low' },
  { level: 0, label: 'Never' },
];

export const LCSpecimenPrefs = (props, context) => {
  const { data } = useBackend(context);
  const { cards = [], portraits = {} } = data;
  return (
    <Window title="LC Specimen Preferences" width={640} height={700}>
      <Window.Content scrollable>
        <Section title="Specimen Preferences">
          Assign each specimen a priority. When you spawn as an LC
          Specimen you are given your highest-priority available pick.
          Specimens set to Never are never assigned.
        </Section>
        {cards.map(card => (
          <SpecimenCard
            key={card.path}
            card={card}
            portrait={portraits[card.path]} />
        ))}
      </Window.Content>
    </Window>
  );
};

const SpecimenCard = (props, context) => {
  const { act } = useBackend(context);
  const { card, portrait } = props;
  const secColor = card.sec === 'highsec' ? 'red' : 'label';
  return (
    <Section>
      <Flex align="center">
        <Flex.Item mr={1}>
          <Box
            width="64px"
            height="64px"
            style={{
              'display': 'flex',
              'align-items': 'center',
              'justify-content': 'center',
            }}>
            <Box
              as="img"
              src={`data:image/png;base64,${portrait}`}
              style={{
                'max-width': '64px',
                'max-height': '64px',
                'object-fit': 'contain',
                '-ms-interpolation-mode': 'nearest-neighbor',
              }} />
          </Box>
        </Flex.Item>
        <Flex.Item grow={1}>
          <Box bold>
            {card.name}
            <Box inline ml={1} fontSize="0.8rem" color={secColor}>
              [{card.sec}]
            </Box>
          </Box>
          <Box color="label">{card.desc}</Box>
          {!!card.blurb && (
            <Box mt={1} fontSize="0.9rem" italic color="label">
              {card.blurb}
            </Box>
          )}
        </Flex.Item>
        <Flex.Item ml={1}>
          <Stack vertical>
            {LEVELS.map(opt => (
              <Stack.Item key={opt.level}>
                <Button
                  fluid
                  color={card.level === opt.level ? 'green' : 'grey'}
                  onClick={() =>
                    act('set_priority', {
                      path: card.path,
                      level: opt.level,
                    })}>
                  {opt.label}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Flex.Item>
      </Flex>
    </Section>
  );
};
