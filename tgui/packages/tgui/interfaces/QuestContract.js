import { useBackend } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';

export const QuestContract = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    invalid,
    contract_type,
    quest_name,
    quest_desc,
    progress_text,
    reward,
    completed,
    current_progress,
    required_progress,
    progress_type,
  } = data;

  if (invalid) {
    return (
      <Window width={400} height={300}>
        <Window.Content>
          <Box
            style={{
              textAlign: 'center',
              padding: '50px',
              color: '#8b4513',
            }}>
            This contract is invalid or corrupted.
          </Box>
        </Window.Content>
      </Window>
    );
  }

  const typeNames = {
    hunt: 'ELIMINATION',
    collect: 'COLLECTION',
    info: 'INFORMATION',
    picture: 'PHOTOGRAPHY',
    distortion: 'DISTORTION',
  };

  const sealColors = {
    hunt: '#cc0000',
    collect: '#b8860b',
    info: '#0066cc',
    picture: '#cc00cc',
    distortion: '#cc6600',
  };

  return (
    <Window width={420} height={550}>
      <Window.Content>
        <Box
          fill
          backgroundColor="#f9f3e9"
          style={{
            position: 'relative',
            fontFamily: 'Georgia, serif',
            color: '#2a1810',
          }}>
          {/* Paper texture overlay */}
          <Box
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              opacity: 0.1,
              backgroundImage:
                'repeating-linear-gradient('
                + '45deg, transparent, transparent 10px, '
                + 'rgba(0,0,0,.03) 10px, rgba(0,0,0,.03) 20px'
                + ')',
              pointerEvents: 'none',
            }}
          />

          <Stack fill vertical>
            <Stack.Item>
              {/* Header with seal */}
              <Box
                style={{
                  textAlign: 'center',
                  padding: '20px 20px 10px 20px',
                  position: 'relative',
                }}>
                {/* Wax seal */}
                <Box
                  style={{
                    position: 'absolute',
                    top: '10px',
                    right: '20px',
                    width: '60px',
                    height: '60px',
                    backgroundColor: sealColors[contract_type] || '#8b4513',
                    borderRadius: '50%',
                    boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '24px',
                    fontWeight: 'bold',
                    color: '#ffffff',
                    textShadow: '1px 1px 2px rgba(0,0,0,0.5)',
                    transform: 'rotate(-15deg)',
                  }}>
                  {contract_type.charAt(0).toUpperCase()}
                </Box>

                <Box
                  style={{
                    fontSize: '24px',
                    fontWeight: 'bold',
                    textTransform: 'uppercase',
                    letterSpacing: '3px',
                    marginBottom: '5px',
                  }}>
                  City of District 23
                </Box>
                <Box
                  style={{
                    fontSize: '16px',
                    fontStyle: 'italic',
                    color: '#5a4a3a',
                  }}>
                  Official {typeNames[contract_type]} Contract
                </Box>
                <Box
                  style={{
                    width: '80%',
                    height: '2px',
                    backgroundColor: '#8b6f47',
                    margin: '10px auto',
                  }}
                />
              </Box>
            </Stack.Item>

            <Stack.Item grow>
              <Box style={{ padding: '0 30px' }}>
                {/* Contract details */}
                <Box style={{ marginBottom: '15px' }}>
                  <Box
                    style={{
                      fontSize: '12px',
                      color: '#5a4a3a',
                      marginBottom: '3px',
                    }}>
                    ASSIGNMENT:
                  </Box>
                  <Box
                    style={{
                      fontSize: '18px',
                      fontWeight: 'bold',
                      color: '#2a1810',
                    }}>
                    {quest_name}
                  </Box>
                </Box>

                <Box style={{ marginBottom: '20px' }}>
                  <Box
                    style={{
                      fontSize: '12px',
                      color: '#5a4a3a',
                      marginBottom: '3px',
                    }}>
                    CONTRACT DETAILS:
                  </Box>
                  <Box
                    style={{
                      fontSize: '14px',
                      lineHeight: '1.6',
                      textAlign: 'justify',
                      fontStyle: 'italic',
                    }}>
                    {quest_desc}
                  </Box>
                </Box>

                {data.target_names && data.target_names.length > 0 && (
                  <Box style={{ marginBottom: '15px' }}>
                    <Box
                      style={{
                        fontSize: '12px',
                        color: '#5a4a3a',
                        marginBottom: '3px',
                      }}>
                      {contract_type === 'hunt'
                        ? 'TARGETS TO ELIMINATE:'
                        : contract_type === 'collect'
                          ? 'ITEMS TO COLLECT:'
                          : contract_type === 'info'
                            ? 'ITEMS TO DOCUMENT:'
                            : contract_type === 'picture'
                              ? 'SUBJECTS TO PHOTOGRAPH:'
                              : 'ACCEPTED TARGETS:'}
                    </Box>
                    <Box style={{ fontSize: '12px' }}>
                      {data.target_names.join(', ')}
                    </Box>
                  </Box>
                )}

                {['collect', 'info', 'picture'].includes(contract_type)
                  && !completed && (
                  <Box
                    style={{
                      fontSize: '11px',
                      fontStyle: 'italic',
                      color: '#5a4a3a',
                      marginBottom: '10px',
                      padding: '8px',
                      border: '1px solid #8b6f47',
                    }}>
                    {contract_type === 'picture'
                      ? 'Submit photos by hitting the Quest Board with them.'
                      : contract_type === 'collect'
                        ? 'Submit items by hitting the Quest Board with them.'
                        : 'Show items by hitting the Quest Board with them.'}
                  </Box>
                )}

                {/* Progress section */}
                <Box
                  style={{
                    border: '1px dashed #8b6f47',
                    padding: '15px',
                    marginBottom: '20px',
                    backgroundColor: 'rgba(255,255,255,0.3)',
                  }}>
                  <Box
                    style={{
                      fontSize: '12px',
                      color: '#5a4a3a',
                      marginBottom: '5px',
                    }}>
                    PROGRESS REPORT:
                  </Box>
                  {progress_type && (
                    <Box
                      style={{
                        fontSize: '16px',
                        marginBottom: '5px',
                      }}>
                      {progress_type}: {current_progress}/{required_progress}
                    </Box>
                  )}
                  <Box
                    style={{
                      fontSize: '14px',
                      fontWeight: completed ? 'bold' : 'normal',
                      color: completed ? '#2d5016' : '#2a1810',
                    }}>
                    Status: {progress_text}
                  </Box>
                </Box>

                {/* Compensation */}
                <Box style={{ marginBottom: '20px' }}>
                  <Box
                    style={{
                      fontSize: '12px',
                      color: '#5a4a3a',
                      marginBottom: '3px',
                    }}>
                    COMPENSATION UPON COMPLETION:
                  </Box>
                  <Box
                    style={{
                      fontSize: '20px',
                      fontWeight: 'bold',
                      color: '#2d5016',
                    }}>
                    {reward} Ahn
                  </Box>
                </Box>

                {completed && (
                  <Box
                    style={{
                      textAlign: 'center',
                      fontSize: '18px',
                      fontWeight: 'bold',
                      color: '#2d5016',
                      padding: '10px',
                      border: '2px solid #2d5016',
                      marginBottom: '20px',
                    }}>
                    CONTRACT FULFILLED
                    <Box style={{ fontSize: '14px', fontWeight: 'normal' }}>
                      Report to City Job Board for payment
                    </Box>
                    <Box
                      style={{
                        fontSize: '12px',
                        fontWeight: 'normal',
                        fontStyle: 'italic',
                        marginTop: '8px',
                        color: '#5a4a3a',
                      }}>
                      Hit the Quest Board with this contract to claim reward.
                    </Box>
                  </Box>
                )}

                {!completed && (
                  <Box style={{ textAlign: 'center', marginTop: '20px' }}>
                    <Button
                      color="bad"
                      content="Cancel Contract"
                      onClick={() => act('cancel')}
                      style={{
                        fontSize: '14px',
                        padding: '8px 16px',
                      }}
                    />
                    <Box
                      style={{
                        fontSize: '11px',
                        color: '#8b6f47',
                        marginTop: '5px',
                        fontStyle: 'italic',
                      }}>
                      Warning: Cancelling forfeits all progress
                    </Box>
                  </Box>
                )}
              </Box>
            </Stack.Item>

            <Stack.Item>
              {/* Footer */}
              <Box
                style={{
                  padding: '10px 30px 20px 30px',
                  fontSize: '11px',
                  color: '#8b6f47',
                  fontStyle: 'italic',
                }}>
                <Box
                  style={{
                    borderTop: '1px solid #8b6f47',
                    paddingTop: '10px',
                    marginBottom: '5px',
                  }}>
                  This contract is legally binding under District 23
                  Municipal Code §7.
                </Box>
                <Box>
                  Contractor signature:
                  _________________________________
                </Box>
              </Box>
            </Stack.Item>
          </Stack>

          {/* Torn edge effect at bottom */}
          <Box
            style={{
              position: 'absolute',
              bottom: '-2px',
              left: 0,
              right: 0,
              height: '10px',
              background:
                'linear-gradient('
                + 'to right, '
                + 'transparent 0%, #f0e6d2 5%, #f0e6d2 10%, '
                + 'transparent 15%, #f0e6d2 20%, #f0e6d2 25%, '
                + 'transparent 30%, #f0e6d2 35%, #f0e6d2 45%, '
                + 'transparent 50%, #f0e6d2 55%, #f0e6d2 65%, '
                + 'transparent 70%, #f0e6d2 75%, #f0e6d2 85%, '
                + 'transparent 90%, #f0e6d2 95%, transparent 100%'
                + ')',
            }}
          />
        </Box>
      </Window.Content>
    </Window>
  );
};
