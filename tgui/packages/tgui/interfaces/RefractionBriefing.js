import { useBackend, useLocalState } from '../backend';
import { Box, Section, Stack } from '../components';
import { Window } from '../layouts';
import { MobCard, MobModal } from './RefractionMobCards';

export const RefractionBriefing = (props, context) => {
  const { data } = useBackend(context);
  const sector = data.sector;
  const sectorIndex = data.sector_index || 1;
  const nodes = data.nodes || [];
  const [modalMob, setModalMob] = useLocalState(context, 'modalMob', null);
  if (data.finished) {
    return (
      <Window width={640} height={300} theme="syndicate">
        <Window.Content>
          <Section title="Briefing">
            <Box color="good">All sectors cleared. Return to the hub.</Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }
  return (
    <Window width={760} height={640} theme="syndicate">
      <Window.Content scrollable>
        <Section title={sector ? sector.name : `Sector ${sectorIndex}`}>
          {sector && sector.description && (
            <Box mb={1} color="label">{sector.description}</Box>
          )}
          {nodes.map((node, i) => (
            <Section
              key={i}
              title={node.name}
              level={2}>
              {node.locked ? (
                <Box p={1} color="bad">
                  Restricted — encounter not yet authored.
                </Box>
              ) : (
                <>
                  {node.description && (
                    <Box mb={0.5} color="label">{node.description}</Box>
                  )}
                  <Stack wrap>
                    {(node.mobs || []).map((mob, j) => (
                      <Stack.Item key={j}>
                        <MobCard
                          mob={mob}
                          onClick={() => setModalMob(mob)}
                        />
                      </Stack.Item>
                    ))}
                  </Stack>
                </>
              )}
            </Section>
          ))}
        </Section>
        {modalMob && (
          <MobModal
            mob={modalMob}
            onClose={() => setModalMob(null)}
            glossary={data.status_glossary}
          />
        )}
      </Window.Content>
    </Window>
  );
};
