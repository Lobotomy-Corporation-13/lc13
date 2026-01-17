import { useBackend } from '../backend';
import { Button, Section, Stack, Box, ColorBox, Table } from '../components';
import { Window } from '../layouts';

export const OfficeManagement = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    offices = [],
    selected_office,
    user_office,
    user_is_director,
  } = data;

  return (
    <Window width={800} height={600}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width="300px">
            <Section title="Fixer Offices" fill scrollable>
              {offices.length === 0 ? (
                <Box color="label">No offices registered.</Box>
              ) : (
                offices.map(office => (
                  <Box
                    key={office.ref}
                    className="candystripe"
                    p={1}
                    mb={1}
                    onClick={() => act('select_office', { office_ref: office.ref })}>
                    <Stack align="center">
                      <Stack.Item>
                        <ColorBox color={office.color} />
                      </Stack.Item>
                      <Stack.Item grow>
                        <Box bold>{office.name}</Box>
                        <Box fontSize="11px" color="label">
                          Director: {office.director}
                        </Box>
                        <Box fontSize="11px">
                          Members: {office.members}/{office.max_members}
                        </Box>
                      </Stack.Item>
                    </Stack>
                  </Box>
                ))
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            {selected_office ? (
              <Section
                title={selected_office.name}
                buttons={
                  user_office === selected_office.ref && (
                    <>
                      {user_is_director && (
                        <Button
                          icon="palette"
                          content="Change Color"
                          onClick={() => act('change_color')}
                        />
                      )}
                      <Button
                        icon="sign-out-alt"
                        content="Leave Office"
                        color="bad"
                        onClick={() => act('leave_office')}
                      />
                    </>
                  )
                }>
                <Stack vertical>
                  <Stack.Item>
                    <Box>
                      <Box inline bold mr={1}>
                        Director:
                      </Box>
                      {selected_office.director}
                    </Box>
                    <Box>
                      <Box inline bold mr={1}>
                        Radio Frequency:
                      </Box>
                      {(selected_office.frequency / 10).toFixed(1)} kHz
                    </Box>
                    <Box>
                      <Box inline bold mr={1}>
                        Office Budget:
                      </Box>
                      {selected_office.budget} Ahn
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Section title="Members" level={2}>
                      <Table>
                        <Table.Row header>
                          <Table.Cell>Name</Table.Cell>
                          <Table.Cell>Role</Table.Cell>
                          {user_office === selected_office.ref
                            && user_is_director && <Table.Cell>Actions</Table.Cell>}
                        </Table.Row>
                        {selected_office.members.map(member => (
                          <Table.Row key={member.ref}>
                            <Table.Cell>
                              {member.name}
                              {member.is_director && (
                                <Box inline color="gold" ml={1}>
                                  (Director)
                                </Box>
                              )}
                            </Table.Cell>
                            <Table.Cell>
                              {member.is_director ? 'Director' : 'Member'}
                            </Table.Cell>
                            {user_office === selected_office.ref
                              && user_is_director && (
                              <Table.Cell>
                                {!member.is_director && (
                                  <>
                                    <Button
                                      icon="crown"
                                      content="Transfer"
                                      onClick={() =>
                                        act('transfer_leadership', {
                                          member_ref: member.ref,
                                        })
                                      }
                                    />
                                    <Button
                                      icon="times"
                                      content="Kick"
                                      color="bad"
                                      onClick={() =>
                                        act('kick_member', {
                                          member_ref: member.ref,
                                        })
                                      }
                                    />
                                  </>
                                )}
                              </Table.Cell>
                            )}
                          </Table.Row>
                        ))}
                      </Table>
                    </Section>
                  </Stack.Item>
                </Stack>
              </Section>
            ) : (
              <Section title="Select an Office" fill>
                <Box color="label">Select an office from the list to view details.</Box>
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
