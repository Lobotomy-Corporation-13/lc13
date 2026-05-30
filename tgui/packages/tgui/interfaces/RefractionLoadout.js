import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Flex,
  Input,
  LabeledControls,
  Section,
  Slider,
  Stack,
  Table,
  Tabs,
} from '../components';
import { ButtonCheckbox } from '../components/Button';
import { FlexItem } from '../components/Flex';
import { TableCell, TableRow } from '../components/Table';
import { Window } from '../layouts';

const THREAT_COLORS = {
  1: '#008000',
  2: '#0000FF',
  3: '#C3630C',
  4: '#800080',
  5: '#FF0000',
};

const THREAT_NAMES = {
  1: 'ZAYIN',
  2: 'TETH',
  3: 'HE',
  4: 'WAW',
  5: 'ALEPH',
};

const REGEX_GUN = /ego_weapon\/ranged\//;
const REGEX_SHIELD = /ego_weapon\/shield\//;
const REGEX_ARMOR = /clothing\/suit\/armor\/ego_gear\//;

const classifyPath = path => {
  const tail = path?.slice(10) || '';
  if (REGEX_ARMOR.test(tail)) return 'armor';
  if (REGEX_GUN.test(tail)) return 'gun';
  if (REGEX_SHIELD.test(tail)) return 'shield';
  return 'melee';
};

const passesNameFilter = (entry, name) => {
  if (!name) return true;
  const hay = (entry.information && entry.information.name) || '';
  return hay.toLowerCase().includes(name.toLowerCase());
};

const passesThreatFilter = (entry, threats) => {
  const any = Object.values(threats).some(v => v);
  if (!any) return true;
  return !!threats[entry.threatclass];
};

const passesOriginFilter = (entry, origins) => {
  const any = Object.values(origins).some(v => v);
  if (!any) return true;
  return !!origins[entry.origin];
};

const passesTagFilter = (entry, tags) => {
  const enabled = Object.entries(tags)
    .filter(([_, v]) => v)
    .map(([k]) => k);
  if (!enabled.length) return true;
  if (!entry.tags || !entry.tags.length) return false;
  return enabled.every(t => entry.tags.includes(t));
};

const NUMERALS_TO_DECIMALS = {
  X: 10, IX: 9, VIII: 8, VII: 7, VI: 6, V: 5, IV: 4, III: 3, II: 2, I: 1,
  '-': 0,
  '-I': -1, '-II': -2, '-III': -3, '-IV': -4, '-V': -5,
  '-VI': -6, '-VII': -7, '-VIII': -8, '-IX': -9, '-X': -10,
};

const DECIMALS_TO_NUMERALS = Object.fromEntries(
  Object.entries(NUMERALS_TO_DECIMALS).map(([k, v]) => [v, k])
);

const ARMOR_KEYS = ['red', 'white', 'black', 'pale'];

const DAMTYPE_OPTIONS = [
  ['red', 'RED', 'red'],
  ['white', 'WHITE', 'white'],
  ['black', 'BLACK', 'violet'],
  ['pale', 'PALE', 'teal'],
];

const decodeArmor = info => {
  const a = (info && info.armor) || {};
  const out = {};
  ARMOR_KEYS.forEach(k => {
    out[k] = a[k] ? (NUMERALS_TO_DECIMALS[a[k]] ?? 0) : 0;
  });
  return out;
};

const passesWeaponDamtype = (entry, dmg) => {
  if (!dmg) return true;
  const info = entry.information || {};
  if (info.damtype_ranged && info.damtype_ranged === dmg) return true;
  return info.damtype_melee === dmg;
};

const passesArmorResist = (entry, mins) => {
  const dec = decodeArmor(entry.information);
  return ARMOR_KEYS.every(k => dec[k] >= mins[k]);
};

const Header = props => {
  const { briefing, sectorIndex } = props;
  if (!briefing || !briefing.name) {
    return (
      <Section>
        <Box color="label">
          Sector {sectorIndex} briefing unavailable.
        </Box>
      </Section>
    );
  }
  return (
    <Section>
      <Box bold fontSize="14px">
        Sector {sectorIndex}: {briefing.name}
      </Box>
    </Section>
  );
};

const SlotIndicators = props => {
  const { slots } = props;
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
            <Box fontSize="10px" mt={0.5}>
              {slot.name || ''}
            </Box>
          </Box>
        </Stack.Item>
      ))}
    </Stack>
  );
};

const FilterBar = props => {
  const {
    name, setName,
    threats, setThreats,
    origins, setOrigins,
    tagOptions, tags, setTags,
    tabIsArmor,
    weaponDamtype, setWeaponDamtype,
    armorResist, setArmorResist,
  } = props;
  return (
    <Section title="Filters" scrollable fill>
      <Flex direction="column">
        <FlexItem mb={2}>
          <Box mb={1} color="label">Name Search</Box>
          <Flex>
            <FlexItem grow={1}>
              <Input
                placeholder="Search..."
                value={name}
                onInput={(_, value) => setName(value)}
                fluid
              />
            </FlexItem>
            <FlexItem ml={1}>
              <Button
                icon="trash"
                color="red"
                content="Clear"
                onClick={() => setName('')}
              />
            </FlexItem>
          </Flex>
        </FlexItem>

        <FlexItem mb={2}>
          <Box mb={1} color="label">Threat Class</Box>
          <Flex wrap>
            {Object.keys(THREAT_NAMES).map(k => (
              <FlexItem key={k} mr={0.5} mb={0.5}>
                <ButtonCheckbox
                  checked={threats[k]}
                  onClick={() =>
                    setThreats({ ...threats, [k]: !threats[k] })}>
                  <Box style={{ color: THREAT_COLORS[k] }} bold>
                    {THREAT_NAMES[k]}
                  </Box>
                </ButtonCheckbox>
              </FlexItem>
            ))}
            <FlexItem mb={0.5}>
              <Button
                icon="sync"
                color="red"
                content="Reset"
                onClick={() => setThreats({})}
              />
            </FlexItem>
          </Flex>
        </FlexItem>

        <FlexItem mb={2}>
          <Box mb={1} color="label">Origin</Box>
          <Flex wrap>
            {['LC13', 'Branch 12', 'City'].map(o => (
              <FlexItem key={o} mr={0.5} mb={0.5}>
                <ButtonCheckbox
                  checked={origins[o]}
                  onClick={() =>
                    setOrigins({ ...origins, [o]: !origins[o] })}>
                  {o}
                </ButtonCheckbox>
              </FlexItem>
            ))}
            <FlexItem mb={0.5}>
              <Button
                icon="sync"
                color="red"
                content="Reset"
                onClick={() => setOrigins({ LC13: true })}
              />
            </FlexItem>
          </Flex>
        </FlexItem>

        {!tabIsArmor && (
          <FlexItem mb={2}>
            <Box mb={1} color="label">Weapon Damage Type</Box>
            <Flex wrap>
              {DAMTYPE_OPTIONS.map(([key, label, col]) => (
                <FlexItem key={key} mr={0.5} mb={0.5}>
                  <Button
                    content={label}
                    color={
                      weaponDamtype && weaponDamtype !== key
                        ? 'transparent'
                        : col
                    }
                    onClick={() =>
                      setWeaponDamtype(weaponDamtype === key ? null : key)}
                  />
                </FlexItem>
              ))}
            </Flex>
          </FlexItem>
        )}

        {tabIsArmor && (
          <FlexItem mb={2}>
            <Box mb={1} color="label">Min. Resistance</Box>
            <LabeledControls>
              {DAMTYPE_OPTIONS.map(([key, label, col]) => (
                <LabeledControls.Item key={key} label={label}>
                  <Slider
                    width="5rem"
                    color={col}
                    step={1}
                    stepPixelSize={5}
                    value={armorResist[key]}
                    minValue={-10}
                    maxValue={10}
                    format={v => DECIMALS_TO_NUMERALS[v]}
                    onChange={(e, v) =>
                      setArmorResist({ ...armorResist, [key]: v })}
                  />
                </LabeledControls.Item>
              ))}
            </LabeledControls>
            <Box mt={1}>
              <Button
                icon="sync"
                color="red"
                content="Reset"
                onClick={() =>
                  setArmorResist({
                    red: -10, white: -10, black: -10, pale: -10,
                  })}
              />
            </Box>
          </FlexItem>
        )}

        {!!tagOptions.length && (
          <FlexItem>
            <Box mb={1} color="label">Tags</Box>
            <Flex direction="column">
              {tagOptions.map(tag => (
                <FlexItem key={tag.tag_name} mb={0.5}>
                  <ButtonCheckbox
                    checked={!!tags[tag.tag_name]}
                    tooltip={tag.tag_description}
                    tooltipPosition="left"
                    onClick={() =>
                      setTags({
                        ...tags,
                        [tag.tag_name]: !tags[tag.tag_name],
                      })}>
                    {tag.tag_name}
                  </ButtonCheckbox>
                </FlexItem>
              ))}
            </Flex>
          </FlexItem>
        )}
      </Flex>
    </Section>
  );
};

const StatLine = props => {
  const { entry, type } = props;
  const info = entry.information || {};
  if (type === 'armor') {
    const a = info.armor || {};
    return (
      <Box fontSize="11px" color="label">
        <Table>
          <TableRow color="#020202" bold>
            <TableCell
              textAlign="center"
              backgroundColor="#d11616">RED
            </TableCell>
            <TableCell
              textAlign="center"
              backgroundColor="#dad6d6">WHITE
            </TableCell>
            <TableCell
              textAlign="center"
              backgroundColor="#3a0b77">BLACK
            </TableCell>
            <TableCell
              textAlign="center"
              backgroundColor="#4baac2">PALE
            </TableCell>
          </TableRow>
          <TableRow>
            <TableCell textAlign="center">{a.red ?? '-'}</TableCell>
            <TableCell textAlign="center">{a.white ?? '-'}</TableCell>
            <TableCell textAlign="center">{a.black ?? '-'}</TableCell>
            <TableCell textAlign="center">{a.pale ?? '-'}</TableCell>
          </TableRow>
        </Table>
      </Box>
    );
  }
  if (type === 'gun') {
    return (
      <Box fontSize="11px">
        Projectile: <b>{info.force_ranged}</b> {info.damtype_ranged}
        <br />
        Fire Rate: {info.ranged_attack_speed}
        {' • '}
        Mag: {info.magazine_size === 0 ? '∞' : info.magazine_size}
        <br />
        Melee: {info.force_melee} {info.damtype_melee}
      </Box>
    );
  }
  return (
    <Box fontSize="11px">
      Damage: <b>{info.force_melee}</b> {info.damtype_melee}
      <br />
      Speed: {info.melee_attack_speed}
      {' • '}
      Reach: {info.reach}
    </Box>
  );
};

const AttributeReqs = props => {
  const { entry } = props;
  const reqs = (entry.information && entry.information.attribute_requirements)
    || {};
  return (
    <Table>
      <TableRow>
        <TableCell backgroundColor="red" px={1}>FOR</TableCell>
        <TableCell backgroundColor="white" color="black" px={1}>PRU</TableCell>
        <TableCell backgroundColor="violet" px={1}>TEM</TableCell>
        <TableCell backgroundColor="teal" px={1}>JUS</TableCell>
      </TableRow>
      <TableRow textAlign="center">
        <TableCell backgroundColor="red">{reqs.Fortitude ?? '-'}</TableCell>
        <TableCell backgroundColor="white" color="black">
          {reqs.Prudence ?? '-'}
        </TableCell>
        <TableCell backgroundColor="violet">
          {reqs.Temperance ?? '-'}
        </TableCell>
        <TableCell backgroundColor="teal">{reqs.Justice ?? '-'}</TableCell>
      </TableRow>
    </Table>
  );
};

const ItemRow = props => {
  const {
    entry, type, isSelected, atCap, onToggle, onDetails,
  } = props;
  const blocked = !!entry.blocked;
  const blockedStyle = blocked
    ? { 'text-decoration': 'line-through', opacity: 0.55 }
    : {};
  return (
    <Box
      p={1}
      mb={0.5}
      style={{ 'border-radius': '4px' }}
      backgroundColor={
        isSelected
          ? 'rgba(34, 197, 94, 0.18)'
          : blocked
            ? 'rgba(120, 0, 0, 0.16)'
            : 'rgba(255, 255, 255, 0.04)'
      }>
      <Flex>
        <FlexItem>
          <Flex direction="column" align="center" minWidth="80px">
            {entry.icon && (
              <Box
                as="img"
                src={`data:image/jpeg;base64,${entry.icon}`}
                style={{
                  height: '32px',
                  width: '32px',
                  ...(blocked && { filter: 'grayscale(1)', opacity: 0.5 }),
                }}
              />
            )}
            <Box
              bold
              mt={0.5}
              style={{
                color: THREAT_COLORS[entry.threatclass],
                ...blockedStyle,
              }}>
              {THREAT_NAMES[entry.threatclass]}
            </Box>
            <Box color="label" fontSize="10px" style={blockedStyle}>
              {entry.origin}
            </Box>
          </Flex>
        </FlexItem>
        <FlexItem grow={1} ml={1}>
          <Box bold style={blockedStyle}>{entry.information?.name}</Box>
          <Box mt={0.5} style={blockedStyle}>
            <StatLine entry={entry} type={type} />
          </Box>
          {!!entry.tags?.length && (
            <Box mt={0.5} fontSize="10px" color="label" style={blockedStyle}>
              {entry.tags.join(' • ')}
            </Box>
          )}
          {blocked && (
            <Box mt={0.5} fontSize="10px" color="bad" bold>
              Already used this run
            </Box>
          )}
        </FlexItem>
        <FlexItem ml={1}>
          <Stack vertical>
            <Stack.Item>
              <Button
                fluid
                color={isSelected ? 'good' : null}
                disabled={blocked || (atCap && !isSelected)}
                content={
                  blocked
                    ? 'Used'
                    : isSelected ? 'Selected' : 'Select'
                }
                onClick={() => !blocked && onToggle(entry.path)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                content="Details"
                onClick={() => onDetails(entry)}
              />
            </Stack.Item>
          </Stack>
        </FlexItem>
      </Flex>
    </Box>
  );
};

const DetailsView = props => {
  const {
    entry, type, isSelected, atCap, onToggle, onBack,
  } = props;
  const info = entry.information || {};
  const blocked = !!entry.blocked;
  return (
    <Section
      title={
        `Details — ${info.name}`
        + (blocked ? ' (already used this run)' : '')
      }
      buttons={
        <>
          <Button
            color={isSelected ? 'bad' : 'good'}
            disabled={blocked || (atCap && !isSelected)}
            content={
              blocked
                ? 'Used'
                : isSelected ? 'Deselect' : 'Select'
            }
            onClick={() => !blocked && onToggle(entry.path)}
          />
          <Button content="Back" onClick={onBack} />
        </>
      }
      scrollable
      fill>
      <Flex direction="column" align="center" mt={2}>
        {entry.icon && (
          <FlexItem>
            <Box
              as="img"
              mb={1}
              src={`data:image/jpeg;base64,${entry.icon}`}
              style={{ height: '32px', width: '32px' }}
            />
          </FlexItem>
        )}
        <FlexItem>
          <Box bold fontSize="14px">{info.name}</Box>
        </FlexItem>
        <FlexItem mb={1}>
          <Box bold style={{ color: THREAT_COLORS[entry.threatclass] }}>
            {THREAT_NAMES[entry.threatclass]} • {entry.origin}
          </Box>
        </FlexItem>
        <FlexItem my={1}>
          <AttributeReqs entry={entry} />
        </FlexItem>
        <FlexItem mt={1} mb={1}>
          <StatLine entry={entry} type={type} />
        </FlexItem>
        {info.attack_info && (
          <FlexItem color="label" textAlign="center">
            {info.attack_info}
          </FlexItem>
        )}
        {info.description && (
          <FlexItem mt={1} textAlign="center">
            {info.description}
          </FlexItem>
        )}
        {info.special && (
          <FlexItem mt={1} textAlign="center" color="average">
            {info.special}
          </FlexItem>
        )}
        {!!entry.tags?.length && (
          <FlexItem mt={1} fontSize="11px" color="label">
            Tags: {entry.tags.join(', ')}
          </FlexItem>
        )}
        <FlexItem mt={1} fontSize="10px" color="label">
          {entry.path}
        </FlexItem>
      </Flex>
    </Section>
  );
};

export const RefractionLoadout = (props, context) => {
  const { act, data } = useBackend(context);
  const weapons = data.weapons || [];
  const armor = data.armor || [];
  const briefing = data.briefing_header || {};
  const sectorIndex = data.sector_index || 1;
  const current = data.current_loadout || [];
  const allTags = data.all_tags || [];

  const [tab, setTab] = useLocalState(context, 'tab', 'weapons');
  const [name, setName] = useLocalState(context, 'name', '');
  const [threats, setThreats] = useLocalState(context, 'threats', {});
  const [origins, setOrigins] = useLocalState(context, 'origins', {
    LC13: true,
  });
  const [tags, setTags] = useLocalState(context, 'tags', {});
  const [weaponDamtype, setWeaponDamtype]
    = useLocalState(context, 'weaponDamtype', null);
  const [armorResist, setArmorResist] = useLocalState(
    context,
    'armorResist',
    { red: -10, white: -10, black: -10, pale: -10 }
  );
  const [detailed, setDetailed] = useLocalState(context, 'detailed', null);
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

  const canConfirm = pickedWeapons.length === 2 && !!pickedArmor;

  const matchesAll = e =>
    passesNameFilter(e, name)
    && passesThreatFilter(e, threats)
    && passesOriginFilter(e, origins)
    && passesTagFilter(e, tags);

  const filteredWeapons = weapons.filter(
    e => matchesAll(e) && passesWeaponDamtype(e, weaponDamtype)
  );
  const filteredArmor = armor.filter(
    e => matchesAll(e) && passesArmorResist(e, armorResist)
  );

  const findEntry = path =>
    weapons.find(w => w.path === path) || armor.find(a => a.path === path);

  const w1 = findEntry(pickedWeapons[0]);
  const w2 = findEntry(pickedWeapons[1]);
  const aSel = findEntry(pickedArmor);
  const slots = [
    { label: 'W1', icon: w1?.icon, name: w1?.information?.name },
    { label: 'W2', icon: w2?.icon, name: w2?.information?.name },
    { label: 'Armor', icon: aSel?.icon, name: aSel?.information?.name },
  ];

  const tabIsArmor = tab === 'armor';
  const entries = tabIsArmor ? filteredArmor : filteredWeapons;
  const entryType = entry => {
    if (tabIsArmor) return 'armor';
    return classifyPath(entry.path);
  };
  const isPicked = entry => tabIsArmor
    ? pickedArmor === entry.path
    : pickedWeapons.includes(entry.path);
  const atCapWeapons = pickedWeapons.length >= 2;
  const atCapArmor = !!pickedArmor;
  const onToggle = path => {
    if (tabIsArmor) toggleArmor(path);
    else toggleWeapon(path);
  };

  return (
    <Window width={940} height={720} theme="syndicate">
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Header briefing={briefing} sectorIndex={sectorIndex} />
          </Stack.Item>
          <Stack.Item>
            <Section title="Selected Loadout">
              <SlotIndicators slots={slots} />
              <Stack>
                <Stack.Item grow={1}>
                  <Tabs>
                    <Tabs.Tab
                      selected={tab === 'weapons'}
                      onClick={() => {
                        setTab('weapons');
                        setDetailed(null);
                      }}>
                      Weapons ({pickedWeapons.length}/2)
                    </Tabs.Tab>
                    <Tabs.Tab
                      selected={tab === 'armor'}
                      onClick={() => {
                        setTab('armor');
                        setDetailed(null);
                      }}>
                      Armor ({pickedArmor ? 1 : 0}/1)
                    </Tabs.Tab>
                  </Tabs>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="good"
                    icon="check"
                    content="Confirm Loadout"
                    disabled={!canConfirm}
                    onClick={() =>
                      act('confirm_loadout', {
                        weapons: pickedWeapons,
                        armor: pickedArmor,
                      })}
                  />
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow={1}>
            <Stack fill>
              <Stack.Item grow={3}>
                {detailed ? (
                  <DetailsView
                    entry={detailed}
                    type={entryType(detailed)}
                    isSelected={isPicked(detailed)}
                    atCap={tabIsArmor ? atCapArmor : atCapWeapons}
                    onToggle={onToggle}
                    onBack={() => setDetailed(null)}
                  />
                ) : (
                  <Section
                    title={
                      tabIsArmor ? 'Available Armor' : 'Available Weapons'
                    }
                    scrollable
                    fill>
                    {entries.map(entry => (
                      <ItemRow
                        key={entry.path}
                        entry={entry}
                        type={entryType(entry)}
                        isSelected={isPicked(entry)}
                        atCap={tabIsArmor ? atCapArmor : atCapWeapons}
                        onToggle={onToggle}
                        onDetails={setDetailed}
                      />
                    ))}
                    {entries.length === 0 && (
                      <Box color="label" p={1}>
                        No items match the current filter.
                      </Box>
                    )}
                  </Section>
                )}
              </Stack.Item>
              <Stack.Item width="22rem">
                <FilterBar
                  name={name} setName={setName}
                  threats={threats} setThreats={setThreats}
                  origins={origins} setOrigins={setOrigins}
                  tagOptions={allTags} tags={tags} setTags={setTags}
                  tabIsArmor={tabIsArmor}
                  weaponDamtype={weaponDamtype}
                  setWeaponDamtype={setWeaponDamtype}
                  armorResist={armorResist}
                  setArmorResist={setArmorResist}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
