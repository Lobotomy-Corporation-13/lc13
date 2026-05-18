/*
 * Shared mob-card components used by both the in-run briefing display
 * (RefractionBriefing.js) and the hub subway-map node preview
 * (RefractionRailway.js). The server payload shape is built by
 * SSrefraction_railway.BuildMobCardPayload — keep this file's expectations
 * in sync with that proc.
 *
 * Each mob has either:
 *   revealed = TRUE  -> full datasheet (name, hp, melee/ranged, resistances,
 *                       move delay, optional tip)
 *   revealed = FALSE -> silhouette + dealt damage type + derived weakness
 *                       label (HP, exact damage, attack speed all hidden)
 */

import { Box, Button, Icon, LabeledList, Section, Stack } from '../components';

// Banner color + warning-icon count per severity tier. Authors set
// `severity` on a passive entry server-side; the renderer picks both
// from this table so all the visual tiers stay consistent across mobs.
const SEVERITY_PRESETS = {
  info: { banner: '#8b6f3f', icons: 0 },
  low: { banner: '#ca8a04', icons: 1 },
  medium: { banner: '#ea580c', icons: 2 },
  high: { banner: '#dc2626', icons: 3 },
};

const passivePreset = severity =>
  SEVERITY_PRESETS[severity] || SEVERITY_PRESETS.info;

const damageTypeColor = type => {
  switch (type) {
    case 'RED_DAMAGE':
    case 'red':
      return '#ef4444';
    case 'WHITE_DAMAGE':
    case 'white':
      return '#cbd5e1';
    case 'BLACK_DAMAGE':
    case 'black':
      return '#a855f7';
    case 'PALE_DAMAGE':
    case 'pale':
      return '#38bdf8';
    default:
      return '#9ca3af';
  }
};

const cadenceFromMob = mob => {
  if (mob.attack_cooldown) {
    return `${(mob.attack_cooldown / 10).toFixed(1)}s`;
  }
  if (mob.rapid_melee && mob.rapid_melee > 1) {
    return `${mob.rapid_melee}x rapid`;
  }
  return '1.0s';
};

const tilesPerSecond = moveDelay => {
  if (!moveDelay || moveDelay <= 0) return '?';
  return (10 / moveDelay).toFixed(2);
};

const escapeRegex = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Underlines any status name found in card text and shows that status's
// glossary blurb on hover. `glossary` is [{ name, desc }] from the server
// (data.status_glossary). Names are matched longest-first so "RED Fragile"
// wins over "Fragile".
const GlossaryText = props => {
  const { text, glossary } = props;
  if (text === null || text === undefined || text === '') {
    return text || null;
  }
  if (!glossary || !glossary.length) {
    return text;
  }
  const meta = {};
  glossary.forEach(g => {
    meta[g.name.toLowerCase()] = g;
  });
  const names = glossary
    .map(g => g.name)
    .sort((a, b) => b.length - a.length)
    .map(escapeRegex);
  const re = new RegExp('(' + names.join('|') + ')', 'gi');
  return String(text).split(re).map((part, i) => {
    const g = meta[(part || '').toLowerCase()];
    if (!g) {
      return part;
    }
    return (
      <Box
        key={i}
        as="span"
        inline
        tooltip={g.desc}
        tooltipPosition="bottom"
        style={{
          'text-decoration': 'underline dotted',
          'cursor': 'help',
        }}>
        {g.icon && (
          <img
            src={`data:image/png;base64,${g.icon}`}
            style={{
              'height': '1em',
              'vertical-align': 'middle',
              'image-rendering': 'pixelated',
              'margin-right': '2px',
            }}
          />
        )}
        {part}
      </Box>
    );
  });
};

export const MobCardSilhouette = props => {
  const { mob, large } = props;
  const size = large ? '160px' : '64px';
  return (
    <Box>
      {mob.icon && (
        <img
          src={`data:image/jpeg;base64,${mob.icon}`}
          style={{
            'height': size,
            'filter': 'brightness(0)',
            'image-rendering': 'pixelated',
          }}
        />
      )}
    </Box>
  );
};

export const MobCardIcon = props => {
  const { mob, large } = props;
  const size = large ? '160px' : '64px';
  return (
    <Box>
      {mob.icon && (
        <img
          src={`data:image/jpeg;base64,${mob.icon}`}
          style={{
            'height': size,
            'image-rendering': 'pixelated',
          }}
        />
      )}
    </Box>
  );
};

const UnrevealedSummary = props => {
  const { mob } = props;
  return (
    <Box>
      <Stack>
        <Stack.Item>
          <Box
            color={damageTypeColor(mob.melee_damage_type)}
            fontSize="11px"
            bold>
            Melee: {(mob.melee_damage_type || '???').replace('_DAMAGE', '')}
          </Box>
          {mob.ranged_damage_type && (
            <Box
              color={damageTypeColor(mob.ranged_damage_type)}
              fontSize="11px"
              bold>
              Ranged: {mob.ranged_damage_type.replace('_DAMAGE', '')}
            </Box>
          )}
        </Stack.Item>
      </Stack>
      <Box mt={0.5} fontSize="11px" color="label">
        Weakness: <Box inline color="good">{mob.weakness}</Box>
      </Box>
      <Box mt={0.5} fontSize="11px" color="label">
        HP: ??? &bull; Speed: ???
      </Box>
    </Box>
  );
};

const RevealedSummary = props => {
  const { mob } = props;
  return (
    <Box fontSize="11px">
      <Box bold>{mob.name}</Box>
      <Box color="label">
        HP: {mob.max_health}
      </Box>
      <Box color={damageTypeColor(mob.melee_damage_type)}>
        Melee: {mob.melee_damage_lower}&ndash;{mob.melee_damage_upper}
        {' '}{(mob.melee_damage_type || '').replace('_DAMAGE', '')}
      </Box>
    </Box>
  );
};

const ResistanceRow = props => {
  const { resistances } = props;
  if (!resistances) return null;
  return (
    <Box fontSize="11px">
      <Box inline color="#ef4444" mr={1}>RED {resistances.red}</Box>
      <Box inline color="#cbd5e1" mr={1}>WHITE {resistances.white}</Box>
      <Box inline color="#a855f7" mr={1}>BLACK {resistances.black}</Box>
      <Box inline color="#38bdf8">PALE {resistances.pale}</Box>
    </Box>
  );
};

// One attack card. Neutral title bar (no severity), then a two-row
// damage/cooldown summary, then the body text. Mirrors the data shape
// produced by /datum/controller/subsystem/refraction_railway in the
// "attacks" payload (name / damage / cooldown / desc).
const AttackCard = props => {
  const { attack, glossary } = props;
  return (
    <Box
      mb={1}
      style={{
        'background': 'rgba(0, 0, 0, 0.45)',
        'border-radius': '3px',
      }}>
      <Box
        px={1}
        py={0.5}
        bold
        style={{
          'background': '#374151',
          'border-top-left-radius': '3px',
          'border-top-right-radius': '3px',
          'color': '#e5e7eb',
        }}>
        {attack.name}
      </Box>
      <Box p={1} fontSize="11px">
        <LabeledList>
          <LabeledList.Item label="Damage">
            <GlossaryText text={attack.damage} glossary={glossary} />
          </LabeledList.Item>
          <LabeledList.Item label="Cooldown">
            <GlossaryText text={attack.cooldown} glossary={glossary} />
          </LabeledList.Item>
        </LabeledList>
        <Box mt={0.5}>
          <GlossaryText text={attack.desc} glossary={glossary} />
        </Box>
      </Box>
    </Box>
  );
};

// "Attacks" header + list. Renders nothing if the mob has no attacks.
const Attacks = props => {
  const { attacks, glossary } = props;
  if (!attacks || attacks.length === 0) return null;
  return (
    <Box mt={1}>
      <Box bold mb={0.5}>Attacks</Box>
      {attacks.map((attack, i) => (
        <AttackCard key={i} attack={attack} glossary={glossary} />
      ))}
    </Box>
  );
};

// One passive card. Banner on the left with the title, warning icons
// on the right, body paragraph below. Banner color + warning-icon
// count both come from the severity preset.
const PassiveCard = props => {
  const { passive, glossary } = props;
  const preset = passivePreset(passive.severity);
  const icons = [];
  for (let i = 0; i < preset.icons; i++) {
    icons.push(
      <Icon
        key={i}
        name="triangle-exclamation"
        ml={0.25}
        style={{ color: preset.banner }}
      />
    );
  }
  return (
    <Box
      mb={1}
      style={{
        'background': 'rgba(0, 0, 0, 0.45)',
        'border-radius': '3px',
      }}>
      <Stack align="center">
        <Stack.Item>
          <Box
            px={1}
            py={0.5}
            bold
            style={{
              'background': preset.banner,
              'border-top-left-radius': '3px',
              'border-bottom-right-radius': '3px',
              'color': '#1c1810',
            }}>
            {passive.title}
          </Box>
        </Stack.Item>
        <Stack.Item grow={1} />
        {preset.icons > 0 && (
          <Stack.Item mr={1}>{icons}</Stack.Item>
        )}
      </Stack>
      <Box p={1} fontSize="11px">
        <GlossaryText text={passive.text} glossary={glossary} />
      </Box>
    </Box>
  );
};

// "Passives" header + list. Renders nothing if the mob has no passives.
const Passives = props => {
  const { passives, glossary } = props;
  if (!passives || passives.length === 0) return null;
  return (
    <Box mt={1}>
      <Box bold mb={0.5}>Passives</Box>
      {passives.map((passive, i) => (
        <PassiveCard key={i} passive={passive} glossary={glossary} />
      ))}
    </Box>
  );
};

const FullDataSheet = props => {
  const { mob, onClose, glossary } = props;
  return (
    <Section
      title={mob.name || 'Unknown'}
      buttons={onClose && (
        <Button icon="times" content="Close" onClick={onClose} />
      )}>
      <Stack>
        <Stack.Item>
          <MobCardIcon mob={mob} large />
        </Stack.Item>
        <Stack.Item grow={1}>
          <LabeledList>
            <LabeledList.Item label="HP">
              {mob.max_health}
            </LabeledList.Item>
            <LabeledList.Item label="Move delay">
              {mob.move_to_delay} ({tilesPerSecond(mob.move_to_delay)} t/s)
            </LabeledList.Item>
            <LabeledList.Item label="Resistances">
              <ResistanceRow resistances={mob.resistances} />
            </LabeledList.Item>
            <LabeledList.Item label="Melee">
              <Box color={damageTypeColor(mob.melee_damage_type)}>
                {mob.melee_damage_lower}&ndash;{mob.melee_damage_upper}
                {' '}{(mob.melee_damage_type || '').replace('_DAMAGE', '')}
                , every {cadenceFromMob(mob)}
              </Box>
            </LabeledList.Item>
            {mob.is_ranged && (
              <LabeledList.Item label="Ranged">
                <Box color={damageTypeColor(mob.ranged_damage_type)}>
                  {mob.ranged_damage}{' '}
                  {(mob.ranged_damage_type || '').replace('_DAMAGE', '')}
                  , every {(mob.ranged_cooldown_time / 10).toFixed(1)}s
                </Box>
                {mob.rapid > 0 && (
                  <Box color="label">
                    Burst: {mob.rapid} shots @{' '}
                    {(mob.rapid_fire_delay / 10).toFixed(2)}s
                  </Box>
                )}
              </LabeledList.Item>
            )}
          </LabeledList>
          <Attacks attacks={mob.attacks} glossary={glossary} />
          <Passives passives={mob.passives} glossary={glossary} />
          {mob.tip && (
            <Box mt={1} p={1} backgroundColor="rgba(34, 197, 94, 0.1)">
              <Box bold color="good" fontSize="11px">Tip</Box>
              <Box fontSize="11px">{mob.tip}</Box>
            </Box>
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
};

export const MobCard = props => {
  const { mob, onClick } = props;
  return (
    <Box
      p={1}
      mr={0.5}
      mb={0.5}
      style={{
        'cursor': 'pointer',
        'border-radius': '4px',
        'min-width': '140px',
      }}
      backgroundColor="rgba(255, 255, 255, 0.05)"
      onClick={onClick}>
      {mob.revealed ? (
        <Stack vertical>
          <Stack.Item>
            <MobCardIcon mob={mob} />
          </Stack.Item>
          <Stack.Item>
            <RevealedSummary mob={mob} />
          </Stack.Item>
        </Stack>
      ) : (
        <Stack vertical>
          <Stack.Item>
            <MobCardSilhouette mob={mob} />
          </Stack.Item>
          <Stack.Item>
            <UnrevealedSummary mob={mob} />
          </Stack.Item>
        </Stack>
      )}
    </Box>
  );
};

export const MobModal = props => {
  const { mob, onClose, glossary } = props;
  // Fixed positioning so the dimmer covers the entire TGUI window viewport
  // even when the parent Window.Content is scrolled — otherwise the modal
  // gets stranded at the top of the scroll buffer and the bottom of the
  // page ends up uncovered.
  return (
    <Box
      position="fixed"
      top={0}
      left={0}
      right={0}
      bottom={0}
      backgroundColor="rgba(0, 0, 0, 0.85)"
      style={{ 'z-index': 50 }}
      onClick={onClose}>
      <Box
        position="fixed"
        top="50%"
        left="50%"
        width="520px"
        style={{
          'transform': 'translate(-50%, -50%)',
          'max-height': '90vh',
          'overflow-y': 'auto',
        }}
        onClick={e => e.stopPropagation()}>
        {mob.revealed ? (
          <FullDataSheet mob={mob} onClose={onClose} glossary={glossary} />
        ) : (
          <Section
            title="Unidentified Hostile"
            buttons={
              <Button icon="times" content="Close" onClick={onClose} />
            }>
            <Stack>
              <Stack.Item>
                <MobCardSilhouette mob={mob} large />
              </Stack.Item>
              <Stack.Item grow={1}>
                <UnrevealedSummary mob={mob} />
                <Box mt={1} color="label" fontSize="11px">
                  Engage this hostile in combat to reveal its full data.
                </Box>
              </Stack.Item>
            </Stack>
          </Section>
        )}
      </Box>
    </Box>
  );
};
