import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section, Divider, Tab, Tabs, Input, Table, Slider, LabeledControls, BlockQuote } from '../components';
import { ButtonCheckbox } from '../components/Button';
import { FlexItem } from '../components/Flex';
import { TableCell, TableRow } from '../components/Table';
import { Window } from '../layouts';

/* There's some issue with tooltips flickering every time the TGUI subsystem
fires (calling try_update_ui), so this window's TGUI datum should have its
autoupdate turned off. Its data shouldn't update anyway.
I'm sorry this is my first TGUI interface

Also, I wished to leave a lot more comments but since comment length is
capped at 80 in the linter, unfortunately I can't leave too many without
making this file look like a hot mess
*/
export const TestRangeEgoPrinter = (props, context) => {
  const { act, data } = useBackend(context);
  const { ego_weapon_datums, ego_armor_datums,
    ego_auxiliary_datums, all_tags } = data;

  /* ------------ React Hooks ------------*/

  const [tab, setTab] = useLocalState(context, 'tab', 1);
  const [nameSearchText, setNameSearchText] = useLocalState(context, "nameSearchText", "");
  const [armorResistanceFilters, setArmorResistanceFilters] = useLocalState(context, "armorResistanceFilters", { "red": -10, "white": -10, "black": -10, "pale": -10 });
  const [threatClassFilters, setThreatClassFilters] = useLocalState(context, "threatClassFilters", { 1: true, 2: true, 3: true, 4: true, 5: true });
  const [originFilters, setOriginFilters] = useLocalState(context, "originFilters", { "LC13": true, "Branch 12": false, "City": false });
  const [egoTagList, setEgoTagList] = useLocalState(context, "egoTagList", all_tags);
  const [currentWeaponDamtypeFilter, setCurrentWeaponDamtypeFilter] = useLocalState(context, "currentWeaponDamtypeFilter", null);
  const [currentlyDetailedEgoDatum, setCurrentlyDetailedEgoDatum] = useLocalState(context, "currentlyDetailedEgoDatum", null);

  /* ------------ Other Variables ------------*/

  // Hardcoded because THREAT_TO_X defines are alists, TGUI hates them
  const threatclass_colors = { 1: "#008000", 2: "#0000FF", 3: "#C3630C", 4: "#800080", 5: "#FF0000" };
  const threatclass_names = { 1: "ZAYIN", 2: "TETH", 3: "HE", 4: "WAW", 5: "ALEPH" };
  // I'm not coding the roman numerical system, this saves me a lot of sanity
  const numerals_to_decimals = { "X": 10, "IX": 9, "VIII": 8, "VII": 7, "VI": 6, "V": 5, "IV": 4, "III": 3, "II": 2, "I": 1, "-": 0, "-I": -1, "-II": -2, "-III": -3, "-IV": -4, "-V": -5, "-VI": -6, "-VII": -7, "-VIII": -8, "-IX": -9, "-X": -10 };
  const decimals_to_numerals
  = Object.fromEntries(Object.entries(numerals_to_decimals)
    .map(([key, value]) => [value, key]));
  // Regular expressions to match certain EGO types
  const regex_for_melee = /ego_weapon\//;
  const regex_for_guns = /ego_weapon\/ranged\//;
  const regex_for_shields = /ego_weapon\/shield\//;
  const regex_for_armor = /clothing\/suit\/armor\/ego_gear\//;

  /* ------------ Functions ------------*/

  // Checks whether a datum's origin is currently being filtered for.
  const CheckOriginFilters = datum => {
    return originFilters[datum.origin];
  };

  // Checks whether a datum's threat class is currently being filtered for.
  const CheckThreatClassFilters = datum => {
    return threatClassFilters[datum.threatclass];
  };

  // Converts an object of roman numeral strings into decimals.
  const DecodeProtectionClasses = armor_list => {
    let decoded_armor_list = { "red": 1, "white": 1, "black": 1, "pale": 1 };

    for (let string in armor_list) {
      if (!armor_list[string]) {
        decoded_armor_list[string] = 0;
        continue;
      }
      decoded_armor_list[string] *= numerals_to_decimals[armor_list[string]];
    }
    return decoded_armor_list;
  };

  const CheckArmorResistanceFilters = datum => {
    const decodedProtectionClasses
    = DecodeProtectionClasses(datum.information.armor);
    for (let string in armorResistanceFilters) {
      if (decodedProtectionClasses[string] < armorResistanceFilters[string]) {
        return false;
      }
    }
    return true;
  };

  const CheckNameSearchFilter = datum => {
    if (!nameSearchText) {
      return true;
    }
    return datum.information.name.toLowerCase()
      .includes(nameSearchText.toLowerCase());
  };

  const ChangeWeaponDamtypeFilter = color => {
    color === currentWeaponDamtypeFilter ? setCurrentWeaponDamtypeFilter(null)
      : setCurrentWeaponDamtypeFilter(color);
  };

  const CheckWeaponDamtypeFilters = datum => {
    if (!currentWeaponDamtypeFilter) {
      return true;
    }

    if (datum.information.damtype_ranged
      && datum.information.damtype_ranged === currentWeaponDamtypeFilter) {
      return true;
    }
    else if (datum.information.damtype_melee === currentWeaponDamtypeFilter) {
      return true;
    }
    else {
      return false;
    }
  };

  const CheckTagFilters = datum => {
    let should_show = false;
    let filtering_tags = egoTagList.map(tag => {
      if (tag.tag_checked) {
        return tag;
      }
      else {
        return null;
      }
    });

    filtering_tags = filtering_tags.filter(tag => tag !== null);
    if (filtering_tags.length < 1) {
      return true;
    }
    for (let tag of filtering_tags) {
      if (datum.tags.includes(tag.tag_name)) { should_show = true; }
      else { should_show = false; break; }
    }

    return should_show;
  };

  /* ------------ Functional Components ------------*/

  // A list of all the EGO tag filter checkboxes.
  const AllEgoTagCheckboxes = (props, context) => {
    const ChangeEgoTagFilters = id => {
      const newEgoTagList = egoTagList?.map(tag => {
        if (tag.tag_name === id) {
          tag.tag_checked = !tag.tag_checked;
          return tag;
        }
        else {
          return tag;
        }
      });
      setEgoTagList(newEgoTagList);
    };

    return (
      egoTagList?.map(tag => (
        <FlexItem ml={0.5} key={tag.tag_name}>
          <ButtonCheckbox
            checked={tag?.tag_checked}
            content={tag.tag_name}
            onClick={() => ChangeEgoTagFilters(tag.tag_name)}
            tooltip={tag.tag_description}
            tooltipPosition={"left"}
          />
        </FlexItem>
      )
      )
    );
  };

  // A list of all the weapon datums that pass the filter checks.
  const AllWeaponDatums = (props, context) => {
    const { datum_list } = props;

    return (
      datum_list?.map(datum => (
        CheckNameSearchFilter(datum) && CheckOriginFilters(datum) && CheckThreatClassFilters(datum) && CheckWeaponDamtypeFilters(datum) && CheckTagFilters(datum) && <EgoDatumEntry datum={datum} type="weapon" />
      )
      )
    );
  };

  // A list of all the armour datums that pass the filter checks.
  const AllArmorDatums = (props, context) => {
    const { act, data } = useBackend(context);
    const { datum_list } = props;

    return (
      datum_list?.map(datum => (
        CheckNameSearchFilter(datum) && CheckOriginFilters(datum) && CheckThreatClassFilters(datum) && CheckArmorResistanceFilters(datum) && CheckTagFilters(datum) && <EgoDatumEntry datum={datum} type="armor" />
      )
      )
    );
  };

  // A list of all the auxiliary datums that pass the filter checks.
  const AllAuxiliaryDatums = (props, context) => {
    const { act, data } = useBackend(context);
    const { datum_list } = props;

    return (
      datum_list?.map(datum => (
        CheckNameSearchFilter(datum) && CheckOriginFilters(datum) && CheckThreatClassFilters(datum) && CheckTagFilters(datum) && <EgoDatumEntry datum={datum} type="auxiliary" />
      )
      )
    );
  };

  /* An entry for an EGO datum. Consists of a preview image, a threat class,
  a name, the print button and a description.
  Passes the 'type' prop to <AppropiateDescription/> to generate an appropiate
  description.
  Print button sends out the 'print_ego' action to the backend with the datum's
  path as its payload.
  The preview image is a base64 string generated and cached in the backend.
  */
  const EgoDatumEntry = (props, context) => {
    const { datum, type } = props;

    return (
      <Box>
        <Flex>
          <FlexItem>
            <Flex wrap direction="column" align="center">
              <FlexItem>
                <Box
                  as="img"
                  m={0}
                  src={`data:image/jpeg;base64,${datum.icon}`}
                  height="32px"
                  width="32px"
                  style={{
                    '-ms-interpolation-mode': 'nearest-neighbor',
                  }} />
              </FlexItem>
              <FlexItem mt={1}>
                <Box bold color={threatclass_colors[datum.threatclass]}>
                  {threatclass_names[datum.threatclass]}
                </Box>
              </FlexItem>
              <FlexItem minWidth={"8rem"} maxWidth={"8rem"} textAlign="center">
                {datum.information.name}
              </FlexItem>
              <FlexItem>
                <Divider />
              </FlexItem>
              <FlexItem flex>
                <Button
                  content="Print E.G.O."
                  color="green"
                  onClick={() => act('print_ego', {
                    chosen_ego: datum.path,
                  })} />
              </FlexItem>

            </Flex>
          </FlexItem>

          <FlexItem>
            <Divider vertical />
          </FlexItem>

          <AppropiateDescription datum={datum} type={type} />

        </Flex>
        <Divider />
      </Box>
    );
  };

  /* Returns either an <ArmorEntryDescription/>,
  <RangedWeaponEntryDescription/> or a <MeleeWeaponEntryDescription/>
  based on the type passed to it and the result of a regex check on the path.
  */
  const AppropiateDescription = props => {
    const { datum, type } = props;

    let item_path = datum.path;
    let common_path_eliminated_string = item_path.slice(10);
    if (type === "armor") {
      return (<ArmorEntryDescription datum={datum} />);
    }
    else if (type === "weapon") {
      return (regex_for_guns.test(common_path_eliminated_string)
        ? <RangedWeaponEntryDescription datum={datum} />
        : <MeleeWeaponEntryDescription datum={datum} />);
    }
    else {
      return (<AuxiliaryEntryDescription datum={datum} />);
    }
  };

  // Basic description of the core stats of a melee weapon.
  const MeleeWeaponEntryDescription = (props, context) => {
    const { datum } = props;

    return (
      <FlexItem grow={1}>
        <Flex direction="column" align="center">
          <FlexItem grow={3} textAlign="center">
            Melee Damage: {datum.information.force_melee + " "}
            {datum.information.damtype_melee}<br />
            Melee Attack Speed: {datum.information.melee_attack_speed}<br />
            Melee Reach: {datum.information.reach} tiles
          </FlexItem>
          <FlexItem mt={3}>
            <Button
              content="View Details"
              onClick={() => setCurrentlyDetailedEgoDatum(datum)} />
          </FlexItem>
        </Flex>
      </FlexItem>
    );
  };

  // Basic description of the core stats of a ranged weapon.
  const RangedWeaponEntryDescription = (props, context) => {
    const { datum } = props;

    return (
      <FlexItem grow={1}>
        <Flex direction="column" align="center">
          <FlexItem grow={3} textAlign="center">
            Projectile Damage: {datum.information.force_ranged + " "}
            {datum.information.damtype_ranged}
            <br />
            Projectile Fire Rate: {datum.information.ranged_attack_speed}
            <br />
            Magazine Size: {datum.information.magazine_size === 0
              ? "Unlimited"
              : datum.information.magazine_size} <br />
            <br />
            Melee Damage: {datum.information.force_melee + " "}
            {datum.information.damtype_melee}
          </FlexItem>
          <FlexItem mt={3}>
            <Button
              content="View Details"
              onClick={() => setCurrentlyDetailedEgoDatum(datum)} />
          </FlexItem>
        </Flex>
      </FlexItem>
    );
  };

  // Basic description of the resistances of an armour.
  const ArmorEntryDescription = (props, context) => {
    const { datum } = props;

    return (
      <FlexItem grow={1}>
        <Flex direction="column" align="center">
          <FlexItem grow={3} textAlign="center">
            Resistances
            <Table mt={3}>
              <TableRow color="#020202" bold><TableCell textAlign="center" backgroundColor="#d11616" minWidth="25%">RED</TableCell><TableCell textAlign="center" backgroundColor="#dad6d6" minWidth="25%">WHITE</TableCell><TableCell textAlign="center" backgroundColor="#3a0b77" minWidth="25%">BLACK</TableCell><TableCell textAlign="center" backgroundColor="#4baac2" minWidth="25%">PALE</TableCell></TableRow>
              <TableRow><TableCell textAlign="center">{datum.information?.armor?.red ?? "-"}</TableCell><TableCell textAlign="center">{datum.information?.armor?.white ?? "-"}</TableCell ><TableCell textAlign="center">{datum.information?.armor?.black ?? "-"}</TableCell><TableCell textAlign="center">{datum.information?.armor?.pale ?? "-"}</TableCell></TableRow>
            </Table>
          </FlexItem>
          <FlexItem mt={3}>
            <Button
              content="View Details"
              onClick={() => setCurrentlyDetailedEgoDatum(datum)} />
          </FlexItem>
        </Flex>
      </FlexItem>
    );
  };

  // Basic description of the core stats of a melee weapon.
  const AuxiliaryEntryDescription = (props, context) => {
    const { datum } = props;

    return (
      <FlexItem grow={1}>
        <Flex direction="column" align="center">
          <FlexItem grow={3} textAlign="center">
            Category: {datum.category?? "No category found."}
          </FlexItem>
          <FlexItem mt={3}>
            <Button
              content="View Details"
              onClick={() => setCurrentlyDetailedEgoDatum(datum)} />
          </FlexItem>
        </Flex>
      </FlexItem>
    );
  };

  /* A slider that controls the minimum resistance of a certain damtype
  that an armour needs to have to be displayed in the EGO list.
  Holds numerical values [-10; 10] but displays in roman numeral format.
  */
  const ArmorResistanceFilterSlider = (props, context) => {
    const { resistance_color, color } = props;

    const AdjustArmorResistanceFilter = value => {
      let newFilters = { ...armorResistanceFilters };
      newFilters[resistance_color] = value;
      setArmorResistanceFilters(newFilters);
    };

    return (
      <Slider
        width={"4rem"}
        color={color}
        step={1}
        stepPixelSize={6}
        value={armorResistanceFilters[resistance_color]}
        minValue={-10}
        maxValue={10}
        format={value => decimals_to_numerals[value]}
        onChange={(e, value) => AdjustArmorResistanceFilter(value)}
      />
    );
  };

  // Holds either all the weapon or armour datums depending on which tab.
  const EGOList = (props, context) => {
    const { ego_weapon_datums, ego_armor_datums } = props;

    return (
      <Section scrollable fill title="E.G.O. List">
        <Tabs>
          <Tabs.Tab selected={tab === 1} onClick={() => setTab(1)}>
            Weapons
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 2} onClick={() => setTab(2)}>
            Armour
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 3} onClick={() => setTab(3)}>
            Auxiliary
          </Tabs.Tab>
        </Tabs>
        {tab === 1 && <AllWeaponDatums datum_list={ego_weapon_datums} />}
        {tab === 2 && <AllArmorDatums datum_list={ego_armor_datums} />}
        {tab === 3 && <AllAuxiliaryDatums datum_list={ego_auxiliary_datums} />}
      </Section>
    );
  };

  /* One of the big components of this interface.
  This is a detailed view of an EGO's properties, it should appear in place of
  the EGO list. It's a section + a details component based on the datum type.
  Runs a bunch of simple regex to figure out if the datum it gets passed is
  armour, a shield, a gun or a simple melee weapon.
  Has a 'back' button to return to the EGO list, and a 'print' button to print
  the EGO. The latter is because exiting to the EGO list will reset the scroll
  position, and I don't know how to avoid that.
  In theory you should just save the scroll position as a local state,
  but I don't really know how to access or modify it.
  */
  const EGODetails = (props, context) => {
    const { detailed_datum } = props;
    const section_title = ("E.G.O. Details - " + detailed_datum.information?.name);
    const common_path_eliminated_string = detailed_datum.path.slice(10);
    const what_are_we_dealing_with = (regex_for_armor.test(common_path_eliminated_string) ? "armor"
      : regex_for_guns.test(common_path_eliminated_string) ? "gun"
        : regex_for_shields.test(common_path_eliminated_string) ? "shield"
          : regex_for_melee.test(common_path_eliminated_string) ? "melee"
            : "auxiliary");

    return (
      <Section scrollable fill title={section_title} buttons={[<Button
        content="Print E.G.O."
        color="green"
        key="print"
        onClick={() => act('print_ego', {
          chosen_ego: detailed_datum.path,
        })} />, <ExitDetailsButton key="exit" />]}>
        {what_are_we_dealing_with === "armor" ? <ArmorDetails datum={detailed_datum} />
          : what_are_we_dealing_with === "gun" ? <GunDetails datum={detailed_datum} />
            : what_are_we_dealing_with === "shield" ? <ShieldDetails datum={detailed_datum} />
              : what_are_we_dealing_with === "melee" ? <MeleeDetails datum={detailed_datum} />
                : what_are_we_dealing_with === "auxiliary" ? <AuxiliaryDetails datum={detailed_datum} />
                  : "Error: This datum's item path doesn't correspond to an armour or an EGO weapon."}
      </Section>
    );
  };

  /* This part of the details page is shared by all EGO.
  Except armour which passes the 'hide_special' prop since armour
  doesn't have that let in the backend.
  Includes a preview image, name, threat class, PE cost, path, attribute
  requirements, description and special info.
  */
  const CommonDetails = (props, context) => {
    const { detailed_datum, hide_special, hide_attribute_requirements } = props;

    return (
      <Flex direction="column" align="center" mt={3}>
        <FlexItem>
          <Box
            as="img"
            mb={1}
            src={`data:image/jpeg;base64,${detailed_datum.icon}`}
            height="32px"
            width="32px"
            style={{
              '-ms-interpolation-mode': 'nearest-neighbor',
            }} />
        </FlexItem>

        <FlexItem>
          {detailed_datum.information.name}
        </FlexItem>

        <FlexItem mb={2}>
          <Box bold color={threatclass_colors[detailed_datum.threatclass]}>
            {threatclass_names[detailed_datum.threatclass]}
          </Box>
        </FlexItem>

        <FlexItem>
          <b>Cost</b>: {(detailed_datum.origin === "LC13" || detailed_datum.origin === "Branch 12") ? detailed_datum.cost + " Unique PE Boxes" : "???"}
        </FlexItem>

        <FlexItem>
          <b>Type:</b> {detailed_datum.path}
        </FlexItem>

        {!hide_attribute_requirements && (
          <FlexItem my={2}>
            <Table>
              <TableRow>
                <TableCell backgroundColor="red" px={1}>Fortitude</TableCell><TableCell backgroundColor="white" color="black" px={1}>Prudence</TableCell><TableCell backgroundColor="violet" px={1}>Temperance</TableCell><TableCell backgroundColor="teal" px={1}>Justice</TableCell>
              </TableRow>
              <TableRow textAlign="center">
                <TableCell backgroundColor="red" textAlign="center">{detailed_datum.information.attribute_requirements.Fortitude ?? "-"}</TableCell><TableCell backgroundColor="white" color="black" textAlign="center">{detailed_datum.information.attribute_requirements.Prudence ?? "-"}</TableCell><TableCell backgroundColor="violet" textAlign="center">{detailed_datum.information.attribute_requirements.Temperance ?? "-"}</TableCell><TableCell backgroundColor="teal" textAlign="center">{detailed_datum.information.attribute_requirements.Justice ?? "-"}</TableCell>
              </TableRow>
            </Table>
          </FlexItem>
        )}
        <FlexItem textAlign="center">
          Tags:
          {detailed_datum.tags[0] ? <BlockQuote>{detailed_datum.tags.toString().replaceAll(",", ", ")}</BlockQuote> : " None"}
        </FlexItem>

        <FlexItem minWidth={"100%"} mt={1} mb={3}>
          <Divider />
        </FlexItem>

        <FlexItem align="start" mb={3}>
          <b>Description:</b>
          <BlockQuote mt={1}>{detailed_datum.information.description ?? "This E.G.O. has no description."}</BlockQuote>
        </FlexItem>
        {!hide_special && <FlexItem align="start" mb={3}><b>Special Information:</b><BlockQuote mt={1}>{detailed_datum.information.special ?? "This E.G.O. doesn't have any Special Information."}</BlockQuote></FlexItem>}

        <FlexItem minWidth={"100%"} mt={1} mb={2}>
          <Divider />
        </FlexItem>
      </Flex>
    );
  };

  // Details specific to armour.
  const ArmorDetails = (props, context) => {
    const { datum } = props;

    return (
      <Flex align="stretch" justify="center" direction="column">
        <FlexItem>
          <CommonDetails detailed_datum={datum} hide_special />
        </FlexItem>
        <FlexItem mb={2} align="start">
          <b>Resistances:</b>
        </FlexItem>
        <FlexItem>
          <Table mt={1}>
            <TableRow color="#020202" bold><TableCell textAlign="center" backgroundColor="red" minWidth="25%">RED</TableCell><TableCell textAlign="center" backgroundColor="white" minWidth="25%">WHITE</TableCell><TableCell textAlign="center" backgroundColor="violet" minWidth="25%">BLACK</TableCell><TableCell textAlign="center" backgroundColor="teal" minWidth="25%">PALE</TableCell></TableRow>
            <TableRow><TableCell textAlign="center">{datum.information?.armor?.red ?? "-"}</TableCell><TableCell textAlign="center">{datum.information?.armor?.white ?? "-"}</TableCell ><TableCell textAlign="center">{datum.information?.armor?.black ?? "-"}</TableCell><TableCell textAlign="center">{datum.information?.armor?.pale ?? "-"}</TableCell></TableRow>
          </Table>
        </FlexItem>
        <FlexItem minWidth={"100%"} mt={3} mb={2}>
          <Divider />
        </FlexItem>
        {datum.information.ability ? <FlexItem><b>Realized Ability: {datum.information.ability?.name ?? "Un-named"}</b><br /><BlockQuote my={1}>{datum.information.ability?.desc ?? "ERROR: DESCRIPTION MISSING"}</BlockQuote>Cooldown: {datum.information.ability?.cooldown ? datum.information.ability.cooldown * 0.1 + " seconds" : "No cooldown listed."}</FlexItem> : null}
      </Flex>
    );
  };

  // Details specific to guns.
  const GunDetails = (props, context) => {
    const { datum } = props;
    const damtype_cell_background_color = damage_type => {
      return damage_type === "red" ? "red"
        : damage_type === "white" ? "white"
          : damage_type === "black" ? "violet"
            : damage_type === "pale" ? "teal"
              : "grey";
    };

    return (
      <Flex align="stretch" justify="center" direction="column">
        <FlexItem>
          <CommonDetails detailed_datum={datum} />
        </FlexItem>
        <FlexItem>
          <Flex direction="column" align="center" mb={3}>
            <FlexItem mb={2} align="start">
              <b>Base Ranged Stats:</b>
            </FlexItem>
            <FlexItem mb={4}>
              <Table>
                <TableRow header>
                  <TableCell color="label" textAlign="center" px={1}>
                    Damage
                  </TableCell>
                  <TableCell color="label" textAlign="center" px={1}>
                    Damage Type
                  </TableCell>
                  <TableCell color="label" textAlign="center" px={1}>
                    Fire Delay
                  </TableCell>
                  <TableCell color="label" textAlign="center" px={1}>
                    Projectile Amount
                  </TableCell>
                </TableRow>
                <TableRow>
                  <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                    backgroundColor="#111111" textAlign="center" px={1}>
                    {datum.information.force_ranged}
                  </TableCell>
                  <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                    color="black"
                    backgroundColor={damtype_cell_background_color(datum
                      .information.damtype_ranged)}
                    textAlign="center" px={1}>
                    <b>{datum.information.damtype_ranged.toUpperCase()}</b>
                  </TableCell>
                  <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                    backgroundColor="#111111" textAlign="center" px={1}>
                    {datum.information.numeric_ranged_attack_speed}ds
                    ({datum.information.ranged_attack_speed})
                  </TableCell>
                  <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                    backgroundColor="#111111" textAlign="center" px={1}>
                    {datum.information.pellets}
                  </TableCell>
                </TableRow>
              </Table>
            </FlexItem>
            <FlexItem minWidth={"100%"} mt={2}>
              <Divider />
            </FlexItem>
            <FlexItem>
              <BaseMeleeStatsTable datum={datum} />
            </FlexItem>
          </Flex>
        </FlexItem>

      </Flex>
    );
  };

  // Details specific to common melee weapons.
  const AuxiliaryDetails = (props, context) => {
    const { datum } = props;

    return (
      <Flex align="stretch" justify="center" direction="column">
        <FlexItem>
          <CommonDetails detailed_datum={datum} hide_attribute_requirements
            hide_special />
        </FlexItem>
      </Flex>
    );
  };

  // Details specific to shield weapons.
  const ShieldDetails = (props, context) => {
    const { datum } = props;

    return (
      <Flex align="stretch" justify="center" direction="column">
        <FlexItem>
          <CommonDetails detailed_datum={datum} />
        </FlexItem>
        <FlexItem>
          <BaseMeleeStatsTable datum={datum} />
        </FlexItem>
        <FlexItem>
          <ShieldWeaponResistancesTable datum={datum} />
        </FlexItem>
      </Flex>
    );
  };

  // Details specific to common melee weapons.
  const MeleeDetails = (props, context) => {
    const { datum } = props;

    return (
      <Flex align="stretch" justify="center" direction="column">
        <FlexItem>
          <CommonDetails detailed_datum={datum} />
        </FlexItem>
        <FlexItem>
          <BaseMeleeStatsTable datum={datum} />
        </FlexItem>
      </Flex>
    );
  };

  // This is a table of the melee properties of a weapon.
  const BaseMeleeStatsTable = (props, context) => {
    const { datum } = props;
    const damtype_cell_background_color = datum.information.damtype_melee === "red" ? "red"
      : datum.information.damtype_melee === "white" ? "white"
        : datum.information.damtype_melee === "black" ? "violet"
          : datum.information.damtype_melee === "pale" ? "teal"
            : "grey";

    return (
      <Flex direction="column" align="center" mb={3}>
        <FlexItem mb={2} align="start">
          <b>Base Melee Stats:</b>
        </FlexItem>
        <FlexItem mb={4}>
          <Table>
            <TableRow header>
              <TableCell color="label" textAlign="center" px={1}>
                Force
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                Throwforce
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                Damage Type
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                Attack Speed
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                Reach
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                Self-Stun
              </TableCell>
            </TableRow>
            <TableRow>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                backgroundColor="#111111" textAlign="center" px={1}>
                {datum.information.force_melee}
              </TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                backgroundColor="#111111" textAlign="center" px={1}>
                {datum.information.throwforce}
              </TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                color="black" backgroundColor={damtype_cell_background_color}
                textAlign="center" px={1}>
                <b>{datum.information.damtype_melee.toUpperCase()}</b>
              </TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                backgroundColor="#111111" textAlign="center" px={1}>
                {datum.information.numeric_melee_attack_speed + " "}
                ({datum.information.melee_attack_speed})
              </TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                backgroundColor="#111111" textAlign="center" px={1}>
                {datum.information.reach} tiles
              </TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }}
                backgroundColor="#111111" textAlign="center" px={1}>
                {datum.information.stuntime
                  ? datum.information.stuntime + " deciseconds" : "None"}
              </TableCell>
            </TableRow>
          </Table>
        </FlexItem>
        <FlexItem italic color="#FDFDFD">
          Please note that these values will
          not always be accurate,
          since many E.G.O. have effects that cannot
          be processed by this catalog.
          <br /><br />
          Force and Attack Speed, especially on Combo or Split Damage E.G.O.
          weapons, may ultimately be significantly higher or lower than listed
          in practice.
        </FlexItem>
        <FlexItem minWidth={"100%"} mt={2}>
          <Divider />
        </FlexItem>
      </Flex>
    );
  };

  // This is a table of resistances per damtype for a shield weapon.
  const ShieldWeaponResistancesTable = (props, context) => {
    const { datum } = props;

    return (
      <Flex direction="column" align="center">
        <FlexItem mb={2} align="start">
          <b>Guard Stats:</b>
        </FlexItem>
        <FlexItem mb={4}>
          <Table mb={1}>
            <TableRow header>
              <TableCell color="label" textAlign="center" px={1}>
                Guard Duration
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                Guard Cooldown
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                Debuff Duration
              </TableCell>
            </TableRow>
            <TableRow>
              <TableCell style={{ border: "2px solid rgb(8, 8, 8)" }}
                backgroundColor="#111111" textAlign="center" px={1}>
                {datum.information.guard_duration} deciseconds
              </TableCell>
              <TableCell style={{ border: "2px solid rgb(8, 8, 8)" }}
                backgroundColor="#111111" textAlign="center" px={1}>
                {datum.information.guard_cooldown} deciseconds
              </TableCell>
              <TableCell style={{ border: "2px solid rgb(8, 8, 8)" }}
                backgroundColor="#111111" textAlign="center" px={1}>
                {datum.information.guard_debuff_duration} deciseconds
              </TableCell>
            </TableRow>
          </Table>

          <Table mt={3}>
            <TableRow header>
              <TableCell color="label" textAlign="center" px={1}>
                RED
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                WHITE
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                BLACK
              </TableCell>
              <TableCell color="label" textAlign="center" px={1}>
                PALE
              </TableCell>
            </TableRow>
            <TableRow>
              <TableCell style={{ border: "2px solid rgb(8, 8, 8)" }}
                backgroundColor="red" textAlign="center" px={1}>
                {decimals_to_numerals[datum
                  .information.guard_resistances?.red]}
              </TableCell>
              <TableCell style={{ border: "2px solid rgb(8, 8, 8)" }}
                color="black" backgroundColor="white" textAlign="center" px={1}>
                {decimals_to_numerals[datum
                  .information.guard_resistances?.white]}
              </TableCell>
              <TableCell style={{ border: "2px solid rgb(8, 8, 8)" }}
                backgroundColor="violet" textAlign="center" px={1}>
                {decimals_to_numerals[datum
                  .information.guard_resistances?.black]}
              </TableCell>
              <TableCell style={{ border: "2px solid rgb(8, 8, 8)" }}
                backgroundColor="teal" textAlign="center" px={1}>
                {decimals_to_numerals[datum
                  .information.guard_resistances?.pale]}
              </TableCell>
            </TableRow>
          </Table>
        </FlexItem>
        <i>
          &apos;Debuff Duration&apos; refers to the
          length of time during which
          you will become more vulnerable as a result of a failed guard.
        </i>
        <FlexItem minWidth={"100%"} mt={1}>
          <Divider />
        </FlexItem>
      </Flex>
    );
  };

  // A button that exits out of the EGO details view.
  const ExitDetailsButton = (props, context) => {
    return (<Button mx={1} icon="arrow-left" color="red" content="Back"
      onClick={() => { setCurrentlyDetailedEgoDatum(null); }} />);
  };

  // The actual TestRangeEgoPrinter interface component.
  return (
    <Window
      width={1000}
      height={900}
    >
      <Window.Content scrollable>
        <Flex>
          <FlexItem grow={3}>
            {currentlyDetailedEgoDatum === null
              ? (
                <EGOList ego_weapon_datums={ego_weapon_datums}
                  ego_armor_datums={ego_armor_datums}
                  ego_auxiliary_datums={ego_auxiliary_datums} />)
              : (
                <EGODetails detailed_datum={currentlyDetailedEgoDatum} />)}
          </FlexItem>
          <Flex.Item>
            <Divider vertical />
          </Flex.Item>
          <FlexItem >
            <Section title="Filters">
              <Flex direction="column">
                <FlexItem>
                  <Flex direction="row">
                    <Flex.Item grow={1} my={1} mb={2}>
                      E.G.O. Name Search Filter
                      <Input mt={1}
                        placeholder="Search..."
                        autoFocus
                        value={nameSearchText}
                        onInput={(_, value) => setNameSearchText(value)}
                        fluid
                      />
                    </Flex.Item>
                    <FlexItem align="end" ml={1} mb={2}>
                      <Button icon="trash" color="red" content="Clear"
                        onClick={() => { setNameSearchText(null); }} />
                    </FlexItem>
                  </Flex>
                </FlexItem>

                <Flex.Item grow={1}>
                  E.G.O. Threat Class Filter
                  <Flex mt={1} mb={1}>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[1]}
                        content={"ZAYIN"}
                        onClick={() => { setThreatClassFilters(
                          { ...threatClassFilters,
                            1: !threatClassFilters[1] }); }}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[2]}
                        content={"TETH"}
                        onClick={() => { setThreatClassFilters(
                          { ...threatClassFilters,
                            2: !threatClassFilters[2] }); }}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[3]}
                        content={"HE"}
                        onClick={() => { setThreatClassFilters(
                          { ...threatClassFilters,
                            3: !threatClassFilters[3] }); }}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[4]}
                        content={"WAW"}
                        onClick={() => { setThreatClassFilters(
                          { ...threatClassFilters,
                            4: !threatClassFilters[4] }); }}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[5]}
                        content={"ALEPH"}
                        onClick={() => { setThreatClassFilters(
                          { ...threatClassFilters,
                            5: !threatClassFilters[5] }); }}
                      />
                    </FlexItem>
                    <FlexItem ml={2}>
                      <Button icon="sync" color="red" content="Reset"
                        onClick={() => { setThreatClassFilters(
                          { 1: true, 2: true, 3: true,
                            4: true, 5: true }); }} />
                    </FlexItem>
                  </Flex>
                </Flex.Item>

                <Flex.Item grow={1}>
                  E.G.O. Origin Filter
                  <Flex mt={1}>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={originFilters["LC13"]}
                        content={"LC13"}
                        onClick={() => { setOriginFilters({ ...originFilters, "LC13": !originFilters["LC13"] }); }}
                        tooltip={"E.G.O. which can be found in Lobotomy Corporation."}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={originFilters["Branch 12"]}
                        content={"Branch 12"}
                        onClick={() => { setOriginFilters({ ...originFilters, "Branch 12": !originFilters["Branch 12"] }); }}
                        tooltip={"E.G.O. which can be found in Branch 12."}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={originFilters["City"]}
                        content={"City"}
                        onClick={() => { setOriginFilters({ ...originFilters, "City": !originFilters["City"] }); }}
                        tooltip={"Weapons and armour originating from the Associations, Syndicates, Fixer Offices and other dwellers of the City. This is not true E.G.O. gear; threat class is an estimate."}
                      />
                    </FlexItem>

                    <FlexItem ml={2}>
                      <Button icon="sync" color="red" content="Reset"
                        onClick={() => { setOriginFilters({ "LC13": true, "Branch 12": false, "City": false }); }} />
                    </FlexItem>
                  </Flex>
                </Flex.Item>

                {tab === 1 && (
                  <FlexItem mt={2}>
                    E.G.O. Weapon Damage Type Filters
                    <Flex direction="row" wrap maxWidth="20rem" justify="center" mt={1}>
                      <FlexItem ml={2}>
                        <Button fluid
                          content={"RED"}
                          color={currentWeaponDamtypeFilter && currentWeaponDamtypeFilter !== "red" ? "transparent" : "red"}
                          onClick={() => (ChangeWeaponDamtypeFilter("red"))} />
                      </FlexItem>
                      <FlexItem ml={2}>
                        <Button fluid
                          content={"WHITE"}
                          color={currentWeaponDamtypeFilter && currentWeaponDamtypeFilter !== "white" ? "transparent" : "white"}
                          onClick={() => (ChangeWeaponDamtypeFilter("white"))} />
                      </FlexItem>
                      <FlexItem ml={2}>
                        <Button fluid
                          content={"BLACK"}
                          color={currentWeaponDamtypeFilter && currentWeaponDamtypeFilter !== "black" ? "transparent" : "violet"}
                          onClick={() => (ChangeWeaponDamtypeFilter("black"))} />
                      </FlexItem>
                      <FlexItem ml={2}>
                        <Button fluid
                          content={"PALE"}
                          color={currentWeaponDamtypeFilter && currentWeaponDamtypeFilter !== "pale" ? "transparent" : "teal"}
                          onClick={() => (ChangeWeaponDamtypeFilter("pale"))} />
                      </FlexItem>
                    </Flex>
                  </FlexItem>)}

                {tab === 2 && (
                  <FlexItem mt={2}>
                    E.G.O. Armour Resistance Filters
                    <Flex direction="row" wrap maxWidth="24rem" mt={1}>
                      <LabeledControls>
                        <LabeledControls.Item label="Min. RED" ml={2}>
                          <ArmorResistanceFilterSlider color="red" resistance_color="red" />
                        </LabeledControls.Item>
                        <LabeledControls.Item label="Min. WHITE" ml={2}>
                          <ArmorResistanceFilterSlider color="white" resistance_color="white" />
                        </LabeledControls.Item>
                        <LabeledControls.Item label="Min. BLACK" ml={2}>
                          <ArmorResistanceFilterSlider color="violet" resistance_color="black" />
                        </LabeledControls.Item>
                        <LabeledControls.Item label="Min. PALE" ml={2}>
                          <ArmorResistanceFilterSlider color="teal" resistance_color="pale" />
                        </LabeledControls.Item>
                        <LabeledControls.Item ml={2}>
                          <Button icon="sync" color="red" content="Reset" onClick={() => { setArmorResistanceFilters({ "red": -10, "white": -10, "black": -10, "pale": -10 }); }} />
                        </LabeledControls.Item>
                      </LabeledControls>
                    </Flex>
                  </FlexItem>)}

                <FlexItem my={2}>
                  E.G.O. Tag Filters
                  <Flex nowrap direction="column" maxWidth="18rem">
                    <AllEgoTagCheckboxes />
                  </Flex>
                </FlexItem>

              </Flex>


            </Section>
          </FlexItem>
        </Flex>

      </Window.Content>
    </Window>
  );
};
