import { useBackend } from '../backend';
import { Button, Section, Stack, Box } from '../components';
import { Window } from '../layouts';

const QuestContract = (props) => {
  const { quest, onAccept, canAccept } = props;

  const typeColors = {
    hunt: 'red',
    collect: '#b8860b',
    info: 'blue',
    picture: 'purple',
    distortion: 'orange',
  };

  const typeIcons = {
    hunt: '🗡️',
    collect: '📦',
    info: '📋',
    picture: '📷',
    distortion: '⚠️',
  };

  return (
    <Box
      backgroundColor="#ffffff"
      style={{
        position: 'relative',
        width: '180px',
        minHeight: '220px',
        border: '1px solid #8b7355',
        boxShadow: '1px 1px 3px rgba(0,0,0,0.3)',
        padding: '12px',
        cursor: 'pointer',
        opacity: 1,
      }}>
      <Box
        style={{
          position: 'absolute',
          top: '-10px',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '20px',
          height: '20px',
          backgroundColor: '#a0522d',
          borderRadius: '50%',
          border: '2px solid #654321',
          boxShadow: '0 2px 4px rgba(0,0,0,0.5)',
        }}
      />
      <Box
        style={{
          textAlign: 'center',
          marginBottom: '8px',
          fontSize: '20px',
        }}>
        {typeIcons[quest.type] || '📄'}
      </Box>
      <Box
        bold
        style={{
          fontSize: '14px',
          textAlign: 'center',
          marginBottom: '8px',
          color: '#1a0f08',
          borderBottom: '1px solid #8b7355',
          paddingBottom: '4px',
        }}>
        {quest.name}
      </Box>
      <Box
        style={{
          fontSize: '11px',
          marginBottom: '8px',
          fontStyle: 'italic',
          color: '#4a3426',
        }}>
        {quest.desc}
      </Box>
      <Box
        style={{
          fontSize: '12px',
          marginBottom: '4px',
          color: typeColors[quest.type] || 'black',
          fontWeight: 'bold',
        }}>
        Type: {quest.type}
      </Box>
      <Box
        style={{
          fontSize: '14px',
          marginBottom: '8px',
          color: '#2a5f2a',
          fontWeight: 'bold',
        }}>
        Reward: {quest.reward} Ahn
      </Box>
      {quest.target_names && quest.target_names.length > 0 && (
        <Box
          style={{
            fontSize: '10px',
            marginBottom: '8px',
            color: '#5a4a3a',
          }}>
          Targets: {quest.target_names.join(', ')}
        </Box>
      )}
      {quest.grade_lock > 0 && (
        <Box
          style={{
            fontSize: '11px',
            marginBottom: '4px',
            color: '#8b0000',
            fontWeight: 'bold',
          }}>
          Grade {quest.grade_lock}+ Required
        </Box>
      )}
      {quest.office_lock && (
        <Box
          style={{
            fontSize: '11px',
            marginBottom: '4px',
            color: '#4a148c',
            fontWeight: 'bold',
          }}>
          Office Members Only
        </Box>
      )}
      <Button
        fluid
        color="default"
        content="Accept Contract"
        disabled={!canAccept || !quest.can_accept}
        onClick={e => {
          e.stopPropagation();
          onAccept();
        }}
      />
    </Box>
  );
};

export const QuestBoard = (props, context) => {
  const { act, data } = useBackend(context);
  const { available_quests = [], can_accept_quest, next_refresh } = data;

  return (
    <Window width={800} height={600}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section
              title="City Contract Board"
              textAlign="center"
              style={{
                backgroundColor: '#3d2914',
                color: '#f4e6d7',
              }}>
              <Box inline>Next refresh in: </Box>
              <Box inline bold color="good">
                {next_refresh}s
              </Box>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section
              title={`Available Contracts (${available_quests.length})`}
              fill
              scrollable
              style={{
                backgroundColor: '#8b6f47',
                backgroundImage:
                  'repeating-linear-gradient('
                  + '45deg, #8b6f47, #8b6f47 10px, #7d6340 10px, #7d6340 20px'
                  + ')',
                padding: '8px',
              }}>
              <Box
                style={{
                  display: 'grid',
                  'grid-template-columns':
                    'repeat(auto-fill, minmax(180px, 1fr))',
                  gap: '16px',
                  'min-height': '400px',
                  padding: '8px',
                  'justify-content': 'center',
                  width: '100%',
                }}>
                {available_quests.length === 0 ? (
                  <Box
                    style={{
                      position: 'absolute',
                      top: '50%',
                      left: '50%',
                      transform: 'translate(-50%, -50%)',
                      fontSize: '18px',
                      color: '#f4e6d7',
                      textShadow: '2px 2px 4px rgba(0,0,0,0.5)',
                    }}>
                    No contracts available at the moment.
                  </Box>
                ) : (
                  available_quests.map(quest => (
                    <QuestContract
                      key={quest.id}
                      quest={quest}
                      canAccept={can_accept_quest}
                      onAccept={() => act('accept', { quest_id: quest.id })}
                      act={act}
                    />
                  ))
                )}
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
