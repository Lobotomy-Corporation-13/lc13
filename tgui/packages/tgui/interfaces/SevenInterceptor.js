import { useBackend } from '../backend';
import {
  Box,
  Button,
  Section,
  Table,
} from '../components';
import { Window } from '../layouts';

export const SevenInterceptor = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    active,
    messages = [],
    message_count,
    max_messages,
    id_count,
  } = data;
  return (
    <Window
      width={500}
      height={450}>
      <Window.Content scrollable>
        <Section
          title="Signal Interceptor"
          buttons={(
            <>
              <Button
                content={active
                  ? 'Connected'
                  : 'Disconnected'}
                selected={active}
                icon={active
                  ? 'wifi' : 'ban'}
                onClick={() => act('toggle')}
              />
              <Button
                content="Clear Log"
                icon="trash"
                disabled={!message_count}
                onClick={() => act('clear')}
              />
              <Button
                content="Reset IDs"
                icon="sync"
                disabled={!id_count}
                onClick={() => act(
                  'clear_ids'
                )}
              />
            </>
          )}>
          <Box color="label" mb={1}>
            {message_count}/{max_messages}
            {' messages'}
            {' | '}
            {id_count} identities tracked
          </Box>
          {!active && (
            <Box color="average" mb={1}>
              Interceptor is offline.
              Activate to monitor PDA
              traffic.
            </Box>
          )}
          {active && messages.length === 0
            && (
              <Box color="label">
                Listening for PDA messages...
              </Box>
            )}
          {messages.length > 0 && (
            <Table>
              <Table.Row header>
                <Table.Cell>Time</Table.Cell>
                <Table.Cell>From</Table.Cell>
                <Table.Cell>To</Table.Cell>
                <Table.Cell>Message</Table.Cell>
              </Table.Row>
              {messages.map((msg, i) => (
                <Table.Row key={i}>
                  <Table.Cell
                    color="label">
                    {msg.time}
                  </Table.Cell>
                  <Table.Cell
                    color="good"
                    bold>
                    {msg.sender}
                  </Table.Cell>
                  <Table.Cell
                    color="average"
                    bold>
                    {msg.recipient}
                  </Table.Cell>
                  <Table.Cell>
                    {msg.message}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
