import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  ButtonCheckbox,
  Input,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

const THREAT_TIERS = ['ZAYIN', 'TETH', 'HE', 'WAW', 'ALEPH'];

const THREAT_COLOR = {
  ZAYIN: '#16a34a',
  TETH: '#0ea5e9',
  HE: '#facc15',
  WAW: '#a855f7',
  ALEPH: '#f43f5e',
};

const Header = props => {
  const { briefing, sectorIndex } = props;
  if (!briefing || !briefing.name) {
    return (
      <Box p={1} color="label">
        Sector {sectorIndex} briefing unavailable.
      </Box>
    );
  }
  return (
    <Box p={1} backgroundColor="rgba(27, 124, 237, 0.12)">
      <Stack>
        <Stack.Item grow={1}>
          <Box bold>{briefing.name}</Box>
          <Box color="label" fontSize="11px">
            {briefing.faction}
          </Box>
        </Stack.Item>
        <Stack.Item color="average">{briefing.damage_hints}</Stack.Item>
      </Stack>
      {briefing.is_boss && (
        <Box mt={0.5} color="bad" bold>
          FINAL SECTOR &mdash; boss encounter ahead.
        </Box>
      )}
    </Box>
  );
};

const SlotIndicators = (props, context) => {
  const { current } = props;
  const slots = [
    { label: 'W1', icon: current[0] },
    { label: 'W2', icon: current[1] },
    { label: 'Armor', icon: current[2] },
  ];
  return (
    <Stack mb={1}>
      {slots.map((slot, i) => (
        <Stack.Item key={i} grow={1}>
          <Box
            p={0.5}
            textAlign="center"
            backgroundColor="rgba(255, 255, 255, 0.04)">
            <Box color="label" fontSize="10px">{slot.label}</Box>
            {slot.icon ? (
              <img
                src={`data:image/jpeg;base64,${slot.icon}`}
                style={{ height: '32px' }}
              />
            ) : (
              <Box color="bad">empty</Box>
            )}
          </Box>
        </Stack.Item>
      ))}
    </Stack>
  );
};

const FilterBar = props => {
  const {
    name,
    setName,
    threats,
    setThreats,
    origins,
    setOrigins,
  } = props;
  return (
    <Box mb={1}>
      <Stack>
        <Stack.Item grow={1}>
          <Input
            placeholder="Search..."
            value={name}
            onInput={(_, value) => setName(value)}
            fluid
          />
        </Stack.Item>
      </Stack>
      <Stack mt={0.5}>
        {THREAT_TIERS.map(tier => (
          <Stack.Item key={tier}>
            <ButtonCheckbox
              checked={threats[tier]}
              onClick={() =>
                setThreats({ ...threats, [tier]: !threats[tier] })
              }>
              <Box style={{ color: THREAT_COLOR[tier] }} bold>
                {tier}
              </Box>
            </ButtonCheckbox>
          </Stack.Item>
        ))}
      </Stack>
      <Stack mt={0.5}>
        {['LC13', 'Branch12', 'City'].map(o => (
          <Stack.Item key={o}>
            <ButtonCheckbox
              checked={origins[o]}
              onClick={() =>
                setOrigins({ ...origins, [o]: !origins[o] })
              }>
              {o}
            </ButtonCheckbox>
          </Stack.Item>
        ))}
      </Stack>
    </Box>
  );
};

const passesFilter = (entry, name, threats, origins) => {
  if (name && name.length > 0) {
    const haystack = (entry.information && entry.information.name) || '';
    if (!haystack.toLowerCase().includes(name.toLowerCase())) return false;
  }
  const anyThreat = Object.values(threats).some(v => v);
  if (anyThreat && !threats[entry.threatclass]) return false;
  const anyOrigin = Object.values(origins).some(v => v);
  if (anyOrigin && !origins[entry.origin]) return false;
  return true;
};

const ItemGrid = props => {
  const { entries, selected, onToggle, maxSelect } = props;
  return (
    <Box>
      {entries.map(entry => {
        const isSelected = selected.includes(entry.path);
        const atCap = !isSelected && selected.length >= maxSelect;
        return (
          <Box
            key={entry.path}
            p={0.5}
            mb={0.5}
            style={{
              'cursor': atCap ? 'default' : 'pointer',
              'border-radius': '4px',
              'opacity': atCap ? 0.5 : 1,
            }}
            backgroundColor={
              isSelected
                ? 'rgba(34, 197, 94, 0.18)'
                : 'rgba(255, 255, 255, 0.04)'
            }
            onClick={() => !atCap && onToggle(entry.path)}>
            <Stack>
              <Stack.Item width="48px">
                {entry.icon && (
                  <img
                    src={`data:image/jpeg;base64,${entry.icon}`}
                    style={{ height: '40px' }}
                  />
                )}
              </Stack.Item>
              <Stack.Item grow={1}>
                <Box bold>
                  {entry.information && entry.information.name}
                </Box>
                <Box
                  color="label"
                  fontSize="11px"
                  style={{ color: THREAT_COLOR[entry.threatclass] }}>
                  {entry.threatclass} &bull; {entry.origin}
                </Box>
              </Stack.Item>
            </Stack>
          </Box>
        );
      })}
      {entries.length === 0 && (
        <Box color="label" p={1}>
          No items match the current filter.
        </Box>
      )}
    </Box>
  );
};

export const RefractionLoadout = (props, context) => {
  const { act, data } = useBackend(context);
  const weapons = data.weapons || [];
  const armor = data.armor || [];
  const briefing = data.briefing_header || {};
  const sectorIndex = data.sector_index || 1;
  const current = data.current_loadout || [];

  const [tab, setTab] = useLocalState(context, 'tab', 'weapons');
  const [name, setName] = useLocalState(context, 'name', '');
  const [threats, setThreats] = useLocalState(context, 'threats', {});
  const [origins, setOrigins] = useLocalState(context, 'origins', {});
  const [pickedWeapons, setPickedWeapons] = useLocalState(
    context,
    'pickedWeapons',
    current.slice(0, 2).filter(Boolean)
  );
  const [pickedArmor, setPickedArmor] = useLocalState(
    context,
    'pickedArmor',
    current[2] || null
  );

  const toggleWeapon = path => {
    if (pickedWeapons.includes(path)) {
      setPickedWeapons(pickedWeapons.filter(p => p !== path));
    } else if (pickedWeapons.length < 2) {
      setPickedWeapons([...pickedWeapons, path]);
    }
  };
  const toggleArmor = path => {
    setPickedArmor(pickedArmor === path ? null : path);
  };

  const canConfirm =
    pickedWeapons.length === 2 && !!pickedArmor;

  const filteredWeapons = weapons.filter(e =>
    passesFilter(e, name, threats, origins)
  );
  const filteredArmor = armor.filter(e =>
    passesFilter(e, name, threats, origins)
  );

  const indicatorIcons = [
    weapons.find(w => w.path === pickedWeapons[0])?.icon,
    weapons.find(w => w.path === pickedWeapons[1])?.icon,
    armor.find(a => a.path === pickedArmor)?.icon,
  ];

  return (
    <Window width={720} height={640} theme="syndicate">
      <Window.Content>
        <Header briefing={briefing} sectorIndex={sectorIndex} />
        <Section>
          <SlotIndicators current={indicatorIcons} />
          <Stack mb={1}>
            <Stack.Item grow={1}>
              <Button
                fluid
                color={tab === 'weapons' ? 'good' : null}
                content={`Weapons (${pickedWeapons.length}/2)`}
                onClick={() => setTab('weapons')}
              />
            </Stack.Item>
            <Stack.Item grow={1}>
              <Button
                fluid
                color={tab === 'armor' ? 'good' : null}
                content={`Armor (${pickedArmor ? 1 : 0}/1)`}
                onClick={() => setTab('armor')}
              />
            </Stack.Item>
          </Stack>
          <FilterBar
            name={name}
            setName={setName}
            threats={threats}
            setThreats={setThreats}
            origins={origins}
            setOrigins={setOrigins}
          />
          {tab === 'weapons' && (
            <ItemGrid
              entries={filteredWeapons}
              selected={pickedWeapons}
              onToggle={toggleWeapon}
              maxSelect={2}
            />
          )}
          {tab === 'armor' && (
            <ItemGrid
              entries={filteredArmor}
              selected={pickedArmor ? [pickedArmor] : []}
              onToggle={toggleArmor}
              maxSelect={1}
            />
          )}
          <Button
            fluid
            mt={1}
            color="good"
            icon="check"
            content="Confirm Loadout"
            disabled={!canConfirm}
            onClick={() =>
              act('confirm_loadout', {
                weapons: pickedWeapons,
                armor: pickedArmor,
              })
            }
          />
        </Section>
      </Window.Content>
    </Window>
  );
};
