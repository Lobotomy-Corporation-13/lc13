import { useBackend } from '../backend';
import {
  Box,
  Button,
  Icon,
  LabeledList,
  Section,
} from '../components';
import { Window } from '../layouts';

const distColor = category => {
  switch (category) {
    case 'here':
      return 'green';
    case 'close':
      return 'green';
    case 'medium':
      return 'average';
    case 'far':
      return 'bad';
    default:
      return 'label';
  }
};

const dirIcon = dir => {
  switch (dir) {
    case 'north':
      return 'arrow-up';
    case 'south':
      return 'arrow-down';
    case 'east':
      return 'arrow-right';
    case 'west':
      return 'arrow-left';
    case 'northeast':
      return 'arrow-up';
    case 'northwest':
      return 'arrow-up';
    case 'southeast':
      return 'arrow-down';
    case 'southwest':
      return 'arrow-down';
    case 'here':
      return 'crosshairs';
    default:
      return 'question';
  }
};

export const SevenReceiver = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    recorders = [],
    feed = [],
    has_tuned,
    canprint,
  } = data;
  return (
    <Window
      width={460}
      height={500}>
      <Window.Content scrollable>
        <Section title={
          'Active Recorders ('
          + recorders.length + '/5)'
        }>
          {recorders.length === 0 && (
            <Box color="average">
              No active recorders deployed.
            </Box>
          )}
          {recorders.map(rec => (
            <Section
              key={rec.ref}
              level={2}
              title={rec.disguised
                ? rec.name
                  + ' (disguised)'
                : 'Recorder'}
              buttons={(
                <>
                  <Button
                    content={rec.tuned
                      ? 'Tuned In'
                      : 'Tune In'}
                    selected={rec.tuned}
                    onClick={() => act(
                      rec.tuned
                        ? 'untune'
                        : 'tune',
                      { ref: rec.ref }
                    )} />
                  <Button
                    content="Print"
                    icon="print"
                    disabled={!canprint
                      || !rec.messages}
                    onClick={() => act(
                      'print_transcript',
                      { ref: rec.ref }
                    )} />
                  <Button
                    content="Clear"
                    icon="eraser"
                    disabled={!rec.messages}
                    onClick={() => act(
                      'clear_messages',
                      { ref: rec.ref }
                    )} />
                  <Button
                    content="Retrieve (2000 Ahn)"
                    icon="hand-paper"
                    color="bad"
                    onClick={() => act(
                      'retrieve',
                      { ref: rec.ref }
                    )} />
                </>
              )}>
              <LabeledList>
                <LabeledList.Item
                  label="Area">
                  {rec.area}
                </LabeledList.Item>
                {!!rec.attached_to && (
                  <LabeledList.Item
                    label="Attached To">
                    {rec.attached_to}
                  </LabeledList.Item>
                )}
                <LabeledList.Item
                  label="Location">
                  <Box inline color={
                    distColor(
                      rec.dist_category)
                  }>
                    <Icon
                      name={dirIcon(
                        rec.direction
                      )}
                      mr={1} />
                    {rec.direction}
                    {' - '}
                    {rec.distance}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item
                  label="Messages">
                  {rec.messages}/300
                </LabeledList.Item>
              </LabeledList>
            </Section>
          ))}
        </Section>
        {has_tuned && (
          <Section title="Live Feed">
            {feed.length === 0 && (
              <Box color="label">
                No messages captured yet.
              </Box>
            )}
            {feed.map((msg, i) => (
              <Box key={i} mb={0.5}>
                <Box
                  inline
                  color="label"
                  mr={1}>
                  [{msg.time}]
                </Box>
                <Box inline bold mr={1}>
                  {msg.speaker}:
                </Box>
                <Box inline>
                  {msg.message}
                </Box>
              </Box>
            ))}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
