/**
 * Inline list of refraction-railway achievements for a node card.
 *
 * Props:
 *   - `achievements`: array of `{ id, name, desc, reward, kind }`.
 *     `kind === "avoid"` for default-pass achievements (the failure
 *     condition); `kind === "earn"` for default-fail (the success
 *     condition).
 *
 * Renders nothing when the array is empty / missing. The server only
 * populates the list once the viewing ckey has completed the line at
 * least once, so the component itself is the "veteran-gated" surface.
 */
import { Box, Section, Stack } from '../../components';

const rowStyle = kind => ({
  'border-radius': '4px',
  'border-left': kind === 'earn'
    ? '4px solid #4ade80'
    : '4px solid #fbbf24',
  'background-color': 'rgba(255, 255, 255, 0.035)',
  'padding': '6px',
  'margin-bottom': '4px',
});

const kindLabel = kind =>
  kind === 'earn' ? 'GOAL' : 'AVOID';

const kindColor = kind =>
  kind === 'earn' ? '#4ade80' : '#fbbf24';

export const AchievementList = props => {
  const { achievements } = props;
  if (!achievements || !achievements.length) {
    return null;
  }
  return (
    <Section
      title="Achievements"
      mt={1}>
      <Box color="label" fontSize="10px" mb={0.5}>
        Per-encounter challenges. Listed here once you have cleared the
        line at least once.
      </Box>
      {achievements.map(a => (
        <Box key={a.id} style={rowStyle(a.kind)}>
          <Stack align="center">
            <Stack.Item
              width="44px"
              bold
              fontSize="10px"
              style={{ color: kindColor(a.kind) }}>
              {kindLabel(a.kind)}
            </Stack.Item>
            <Stack.Item grow={1}>
              <Box bold>{a.name}</Box>
              <Box color="label" fontSize="11px">{a.desc}</Box>
            </Stack.Item>
            <Stack.Item
              ml={1}
              style={{ color: '#ffd86b' }}
              bold>
              +{a.reward} ★
            </Stack.Item>
          </Stack>
        </Box>
      ))}
    </Section>
  );
};
