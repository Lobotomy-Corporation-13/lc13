import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, LabeledList, Section, Divider, Tab, Tabs, Input, Table, Slider, LabeledControls, BlockQuote } from '../components';
import { ButtonCheckbox } from '../components/Button';
import { FlexItem } from '../components/Flex';
import { TableCell, TableRow } from '../components/Table';
import { Window } from '../layouts';

// There's some issue with tooltips flickering every time the TGUI subsystem fires (calling try_update_ui), so this window's TGUI datum should have its autoupdate turned off. Its data shouldn't update anyway.
// I'm sorry this is my first TGUI interface

export const TestRangeEgoPrinter = (props, context) => {
  const { act, data } = useBackend(context);
  const { ego_weapon_datums, ego_armor_datums, all_tags } = data;
  /// Controls whether we're viewing Weapons or Armour
  const [tab, setTab] = useLocalState(context, 'tab', 1);

  /// Name search filter.
  const [nameSearchText, setNameSearchText] = useLocalState(context, "nameSearchText", "")
  /// Armour resistance filters. It's an object with the colours as keys and the minimum resistance rank from -10 to 10 as the value. Since we receive them as roman numerals, we need to decode them for comparison.
  const [armorResistanceFilters, setArmorResistanceFilters] = useLocalState(context, "armorResistanceFilters", { "red": -10, "white": -10, "black": -10, "pale": -10 })
  /// Threat class filters. It's an object; the keys are the threat classes: 1 is ZAYIN, 2 is TETH, 3 is HE, 4 is WAW, 5 is ALEPH. The values are whether EGO of that threat class should be visible.
  const [threatClassFilters, setThreatClassFilters] = useLocalState(context, "threatClassFilters", { 1: true, 2: true, 3: true, 4: true, 5: true })
  /// EGO Tag Filters. This is an array of EGO tag objects which are structured like {"tag_name": string:name, "tag_description:" string:description, "tag_checked": bool}. If "tag_checked" is true (by default it's false), only display EGO with that tag on it.
  const [egoTagList, setEgoTagList] = useLocalState(context, "egoTagList", all_tags)
  /// Weapon damage type filters. Either null or a string representing one of the colour damtypes.
  const [currentWeaponDamtypeFilter, setCurrentWeaponDamtypeFilter] = useLocalState(context, "currentWeaponDamtypeFilter", null)
  /// This holds either null (not viewing any EGO's details) or an EGO datum object. If it isn't null, we replace the EGO list with the datum's details.
  const [currentlyDetailedEgoDatum, setCurrentlyDetailedEgoDatum] = useLocalState(context, "currentlyDetailedEgoDatum", null)
  // This threat class stuff is hardcoded because THREAT_TO_COLOR and THREAT_TO_NAME defines are alists and I can't send them in TGUI data
  const threatclass_colors = { 1: "#008000", 2: "#0000FF", 3: "#C3630C", 4: "#800080", 5: "#FF0000" }
  const threatclass_names = { 1: "ZAYIN", 2: "TETH", 3: "HE", 4: "WAW", 5: "ALEPH" }
  // I'm not coding the roman numerical system, this saves me a lot of sanity
  const numerals_to_decimals = { "X": 10, "IX": 9, "VIII": 8, "VII": 7, "VI": 6, "V": 5, "IV": 4, "III": 3, "II": 2, "I": 1, "-": 0, "-I": -1, "-II": -2, "-III": -3, "-IV": -4, "-V": -5, "-VI": -6, "-VII": -7, "-VIII": -8, "-IX": -9, "-X": -10 }
  const decimals_to_numerals = Object.fromEntries(Object.entries(numerals_to_decimals).map(([key, value]) => [value, key]))
  // Regular expressions to match certain EGO types
  const regex_for_melee = /ego_weapon\//
  const regex_for_guns = /ego_weapon\/ranged\//
  const regex_for_shields = /ego_weapon\/shield\//
  const regex_for_armor = /clothing\/suit\/armor\/ego_gear\//

  const CheckThreatClassFilters = (datum) => {
    return threatClassFilters[datum.threatclass]
  }

  const DecodeProtectionClasses = (armor_list) => {
    var decoded_armor_list = { "red": 1, "white": 1, "black": 1, "pale": 1 }

    for (var string in armor_list) {
      if (!armor_list[string]) {
        decoded_armor_list[string] = 0
        continue
      }
      decoded_armor_list[string] *= numerals_to_decimals[armor_list[string]]
    }
    return decoded_armor_list
  }

  const CheckArmorResistanceFilters = (datum) => {
    const decodedProtectionClasses = DecodeProtectionClasses(datum.information.armor)
    for (var string in armorResistanceFilters) {
      if (decodedProtectionClasses[string] < armorResistanceFilters[string]) {
        return false
      }
    }

    return true;
  }

  const CheckNameSearchFilter = (datum) => {
    if (!nameSearchText) {
      return true
    }
    return datum.information.name.toLowerCase().includes(nameSearchText.toLowerCase())
  }


  const ChangeWeaponDamtypeFilter = (color) => {
    color === currentWeaponDamtypeFilter ? setCurrentWeaponDamtypeFilter(null) : setCurrentWeaponDamtypeFilter(color)
  }

  const CheckWeaponDamtypeFilters = (datum) => {
    if (!currentWeaponDamtypeFilter) {
      return true
    }

    if (datum.information.damtype_ranged && (datum.information.damtype_ranged === currentWeaponDamtypeFilter)) {
      return true
    }
    else if (datum.information.damtype_melee === currentWeaponDamtypeFilter) {
      return true
    }
    else
      return false
  }

  const CheckTagFilters = (datum) => {
    var should_show = false
    var filtering_tags = egoTagList.map(tag => {
      if (tag.tag_checked)
        return tag
      else
        return null
    })

    filtering_tags = filtering_tags.filter(tag => tag != null)
    if (filtering_tags.length < 1)
      return true

    for (var tag of filtering_tags) {
      if (datum.tags.includes(tag.tag_name)) { should_show = true }
      else { should_show = false; break; }
    }

    return should_show
  }

  const AllEgoTagCheckboxes = (props, context) => {

    const ChangeEgoTagFilters = (id) => {
      const newEgoTagList = egoTagList?.map(tag => {
        if (tag.tag_name === id) {
          tag.tag_checked = !tag.tag_checked
          return tag
        }
        else {
          return tag
        }
      })
      setEgoTagList(newEgoTagList)
    }

    return (
      egoTagList?.map(tag => (
        <FlexItem ml={0.5}>
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
    )
  }

  const AllWeaponDatums = (props, context) => {
    const { datum_list } = props;

    return (
      datum_list?.map(datum => (
        CheckNameSearchFilter(datum) && CheckThreatClassFilters(datum) && CheckWeaponDamtypeFilters(datum) && CheckTagFilters(datum) && <EgoDatumEntry datum={datum} type="weapon" />
      )
      )
    )
  }

  const AllArmorDatums = (props, context) => {
    const { act, data } = useBackend(context);
    const { datum_list } = props;

    return (
      datum_list?.map(datum => (
        CheckNameSearchFilter(datum) && CheckThreatClassFilters(datum) && CheckArmorResistanceFilters(datum) && CheckTagFilters(datum) && <EgoDatumEntry datum={datum} type="armor" />
      )
      )
    )
  }

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
                <Box bold color={threatclass_colors[datum.threatclass]}>{threatclass_names[datum.threatclass]}</Box>
              </FlexItem>
              <FlexItem maxWidth="6rem" textAlign="center">
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
    )
  }

  const AppropiateDescription = (props) => {
    const { datum, type } = props;

    var item_path = datum.path
    var common_path_eliminated_string = item_path.slice(10)
    if (type === "armor") {
      return (<ArmorEntryDescription datum={datum} />)
    }
    else {
      return (regex_for_guns.test(common_path_eliminated_string) ? <RangedWeaponEntryDescription datum={datum} /> : <MeleeWeaponEntryDescription datum={datum} />)
    }
  }

  const MeleeWeaponEntryDescription = (props, context) => {
    const { datum } = props;

    return (
      <FlexItem grow={1}>
        <Flex direction="column" align="center">
          <FlexItem grow={3} textAlign="center">
            Melee Damage: {datum.information.force_melee} {datum.information.damtype_melee}<br />
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
    )
  }
  const RangedWeaponEntryDescription = (props, context) => {
    const { datum } = props;

    return (
      <FlexItem grow={1}>
        <Flex direction="column" align="center">
          <FlexItem grow={3} textAlign="center">
            Projectile Damage: {datum.information.force_ranged} {datum.information.damtype_ranged}<br />
            Projectile Fire Rate: {datum.information.ranged_attack_speed} <br />
            Magazine Size: {datum.information.magazine_size === 0 ? "Unlimited" : datum.information.magazine_size} <br />
            <br />
            Melee Damage: {datum.information.force_melee} {datum.information.damtype_melee}
          </FlexItem>
          <FlexItem mt={3}>
            <Button
              content="View Details"
              onClick={() => setCurrentlyDetailedEgoDatum(datum)} />
          </FlexItem>
        </Flex>
      </FlexItem>
    )
  }

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
    )
  }

  const ArmorResistanceFilterSlider = (props, context) => {
    const { resistance_color, color } = props;

    const AdjustArmorResistanceFilter = (value) => {
      var newFilters = structuredClone(armorResistanceFilters)
      newFilters[resistance_color] = value
      setArmorResistanceFilters(newFilters)
    }

    return (
      <Slider
        width={"4rem"}
        color={color}
        step={1}
        stepPixelSize={6}
        value={armorResistanceFilters[resistance_color]}
        minValue={-10}
        maxValue={10}
        format={(value) => decimals_to_numerals[value]}
        onChange={(e, value) => AdjustArmorResistanceFilter(value)}
      />
    )
  }
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
        </Tabs>
        {tab === 1 && <AllWeaponDatums datum_list={ego_weapon_datums} />}
        {tab === 2 && <AllArmorDatums datum_list={ego_armor_datums} />}
      </Section>
    )
  }

const EGODetails = (props, context) => {
    const { detailed_datum } = props;
    const section_title = ("E.G.O. Details - " + detailed_datum.information?.name)
    const common_path_eliminated_string = detailed_datum.path.slice(10)
    const what_are_we_dealing_with = (regex_for_armor.test(common_path_eliminated_string) ? "armor" :
    regex_for_guns.test(common_path_eliminated_string) ? "gun" :
    regex_for_shields.test(common_path_eliminated_string) ? "shield" :
    regex_for_melee.test(common_path_eliminated_string) ? "melee" : null);

    return (
      <Section scrollable fill title={section_title} buttons={[<Button
                  content="Print E.G.O."
                  color="green"
                  onClick={() => act('print_ego', {
                    chosen_ego: detailed_datum.path,
                  })} />, <ExitDetailsButton/>]}>
          {what_are_we_dealing_with === "armor" ? <ArmorDetails datum={detailed_datum}/> :
           what_are_we_dealing_with === "gun" ? <GunDetails datum={detailed_datum}/> :
           what_are_we_dealing_with === "shield" ? <ShieldDetails datum={detailed_datum}/> :
           what_are_we_dealing_with === "melee" ? <MeleeDetails datum={detailed_datum}/> :
           "Error: This datum's item path doesn't correspond to an armour or an EGO weapon."}
      </Section>
    )
  }

const CommonDetails = (props, context) => {
    const { detailed_datum } = props;

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
          <Box bold color={threatclass_colors[detailed_datum.threatclass]}>{threatclass_names[detailed_datum.threatclass]}</Box>
        </FlexItem>

        <FlexItem>
          <b>Cost</b>: {detailed_datum.cost} PE Boxes
        </FlexItem>

        <FlexItem>
          <b>Type:</b> {detailed_datum.path}
        </FlexItem>

        <FlexItem my={2}>
          <Table>
            <TableRow>
              <TableCell backgroundColor="red" px={1}>Fortitude</TableCell><TableCell backgroundColor="white" color="black" px={1}>Prudence</TableCell><TableCell backgroundColor="violet" px={1}>Temperance</TableCell><TableCell backgroundColor="teal" px={1}>Justice</TableCell>
            </TableRow>
            <TableRow textAlign="center">
              <TableCell backgroundColor="red" textAlign="center">{detailed_datum.information.attribute_requirements.Fortitude?? "-"}</TableCell><TableCell backgroundColor="white" color="black" textAlign="center">{detailed_datum.information.attribute_requirements.Prudence?? "-"}</TableCell><TableCell backgroundColor="violet" textAlign="center">{detailed_datum.information.attribute_requirements.Temperance?? "-"}</TableCell><TableCell backgroundColor="teal" textAlign="center">{detailed_datum.information.attribute_requirements.Justice?? "-"}</TableCell>
            </TableRow>
          </Table>
        </FlexItem>

        <FlexItem textAlign="center">
          Tags:
          {detailed_datum.tags[0] ? <BlockQuote>{detailed_datum.tags.toString().replaceAll(",", ", ")}</BlockQuote> : " None"}
        </FlexItem>

        <FlexItem minWidth={"100%"} mt={1} mb={3}>
          <Divider/>
        </FlexItem>

        <FlexItem align="start" mb={3}>
          <b>Description:</b>
          <BlockQuote mt={1}>{detailed_datum.information.description?? "This E.G.O. has no description."}</BlockQuote>
        </FlexItem>
        <FlexItem align="start" mb={3}>
          <b>Special Information:</b>
          <BlockQuote mt={1}>{detailed_datum.information.special?? "This E.G.O. doesn't have any Special Information."}</BlockQuote>
        </FlexItem>

        <FlexItem minWidth={"100%"} mt={1} mb={2}>
          <Divider/>
        </FlexItem>
      </Flex>
    )
  }

  const ArmorDetails = (props, context) => {
    const { datum } = props;

    return (
      <Flex align="stretch" justify="center" direction="column">
        <CommonDetails detailed_datum={datum}/>
      </Flex>

    )
  }
  const GunDetails = (props, context) => {
    const { datum } = props;
    const damtype_cell_background_color = (damage_type) => {return damage_type === "red" ? "red" :
    damage_type === "white" ? "white" :
    damage_type === "black" ? "violet" :
    damage_type === "pale" ? "teal" :
    "grey"}

    return (
      <Flex align="stretch" justify="center" direction="column">
        <FlexItem>
          <CommonDetails detailed_datum={datum}/>
        </FlexItem>
        <FlexItem>
          <Flex direction="column" align="center" mb={3}>
        <FlexItem mb={2} align="start">
          <b>Base Ranged Stats:</b>
        </FlexItem>
        <FlexItem mb={4}>
          <Table>
            <TableRow header>
              <TableCell color="label" textAlign="center" px={1}>Damage</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Damage Type</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Fire Delay</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Projectile Amount</TableCell>
            </TableRow>
            <TableRow>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111" textAlign="center" px={1}>{datum.information.force_ranged}</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} color="black" backgroundColor={damtype_cell_background_color(datum.information.damtype_ranged)} textAlign="center" px={1}><b>{datum.information.damtype_ranged.toUpperCase()}</b></TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111"textAlign="center" px={1}>{datum.information.numeric_ranged_attack_speed}ds ({datum.information.ranged_attack_speed})</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111"textAlign="center" px={1}>{datum.information.pellets}</TableCell>
            </TableRow>
          </Table>
        </FlexItem>
        <FlexItem minWidth={"100%"} mt={2}>
          <Divider/>
        </FlexItem>
        <FlexItem>
          <BaseMeleeStatsTable datum={datum}/>
        </FlexItem>
      </Flex>
        </FlexItem>

      </Flex>
    )
  }
  const ShieldDetails = (props, context) => {
    const { datum } = props;

    return (
      <Flex align="stretch" justify="center" direction="column">
        <FlexItem>
          <CommonDetails detailed_datum={datum}/>
        </FlexItem>
        <FlexItem>
          <BaseMeleeStatsTable datum={datum}/>
        </FlexItem>
        <FlexItem>
          <ShieldWeaponResistancesTable datum={datum}/>
        </FlexItem>
      </Flex>
    )
  }
  const MeleeDetails = (props, context) => {
    const { datum } = props;
    const damtype_cell_background_color = datum.information.damtype_melee === "red" ? "red" :
    datum.information.damtype_melee === "white" ? "white" :
    datum.information.damtype_melee === "black" ? "violet" :
    datum.information.damtype_melee === "pale" ? "teal" :
    "grey"

    return (
      <Flex align="stretch" justify="center" direction="column">
        <FlexItem>
          <CommonDetails detailed_datum={datum}/>
        </FlexItem>
        <FlexItem>
          <BaseMeleeStatsTable datum={datum}/>
        </FlexItem>
      </Flex>
    )
  }

  const BaseMeleeStatsTable = (props, context) => {
    const { datum } = props;
    const damtype_cell_background_color = datum.information.damtype_melee === "red" ? "red" :
    datum.information.damtype_melee === "white" ? "white" :
    datum.information.damtype_melee === "black" ? "violet" :
    datum.information.damtype_melee === "pale" ? "teal" :
    "grey"

    return (
      <Flex direction="column" align="center" mb={3}>
        <FlexItem mb={2} align="start">
          <b>Base Melee Stats:</b>
        </FlexItem>
        <FlexItem mb={4}>
          <Table>
            <TableRow header>
              <TableCell color="label" textAlign="center" px={1}>Force</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Throwforce</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Damage Type</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Attack Speed</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Reach</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Self-Stun</TableCell>
            </TableRow>
            <TableRow>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111" textAlign="center" px={1}>{datum.information.force_melee}</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111"textAlign="center" px={1}>{datum.information.throwforce}</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} color="black" backgroundColor={damtype_cell_background_color} textAlign="center" px={1}><b>{datum.information.damtype_melee.toUpperCase()}</b></TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111"textAlign="center" px={1}>{datum.information.numeric_melee_attack_speed} ({datum.information.melee_attack_speed})</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111"textAlign="center" px={1}>{datum.information.reach} tiles</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111"textAlign="center" px={1}>{datum.information.stuntime ? datum.information.stuntime + " deciseconds" : "None"}</TableCell>
            </TableRow>
          </Table>
        </FlexItem>
        <FlexItem italic color="#FDFDFD">
          Please note that these values will not always be accurate, since many E.G.O. have effects that cannot be processed by this catalog.<br/><br/>
          Force and Attack Speed, especially on Combo or Split Damage E.G.O. weapons, may ultimately be significantly higher or lower than listed in practice.
        </FlexItem>
        <FlexItem minWidth={"100%"} mt={2}>
          <Divider/>
        </FlexItem>
      </Flex>
    )
  }

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
              <TableCell color="label" textAlign="center" px={1}>Guard Duration</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Guard Cooldown</TableCell>
              <TableCell color="label" textAlign="center" px={1}>Debuff Duration</TableCell>
            </TableRow>
            <TableRow>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111" textAlign="center" px={1}>{datum.information.guard_duration} deciseconds</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111"textAlign="center" px={1}>{datum.information.guard_cooldown} deciseconds</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="#111111"textAlign="center" px={1}>{datum.information.guard_debuff_duration} deciseconds</TableCell>
              </TableRow>
          </Table>

          <Table mt={3}>
            <TableRow header>
              <TableCell color="label" textAlign="center" px={1}>RED</TableCell>
              <TableCell color="label" textAlign="center" px={1}>WHITE</TableCell>
              <TableCell color="label" textAlign="center" px={1}>BLACK</TableCell>
              <TableCell color="label" textAlign="center" px={1}>PALE</TableCell>
            </TableRow>
            <TableRow>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="red" textAlign="center" px={1}>{decimals_to_numerals[datum.information.guard_resistances?.red]}</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} color="black" backgroundColor="white"textAlign="center" px={1}>{decimals_to_numerals[datum.information.guard_resistances?.white]}</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="violet" textAlign="center" px={1}>{decimals_to_numerals[datum.information.guard_resistances?.black]}</TableCell>
              <TableCell style={{ border: '2px solid rgb(8, 8, 8)' }} backgroundColor="teal"textAlign="center" px={1}>{decimals_to_numerals[datum.information.guard_resistances?.pale]}</TableCell>
            </TableRow>
          </Table>
        </FlexItem>
        <i>'Debuff Duration' refers to the length of time during which you will become more vulnerable as a result of a failed guard.</i>
        <FlexItem minWidth={"100%"} mt={1}>
          <Divider/>
        </FlexItem>
      </Flex>
    )
  }

  const ExitDetailsButton = (props, context) => {
    return (<Button mx={1} icon="arrow-left" color="red" content="Back" onClick={() => { setCurrentlyDetailedEgoDatum(null) }} />)
  }
  return (
    <Window
      width={1000}
      height={900}
    >
      <Window.Content scrollable>
        <Flex>
          <FlexItem grow={3}>
            {currentlyDetailedEgoDatum === null ?
            <EGOList ego_weapon_datums={ego_weapon_datums} ego_armor_datums={ego_armor_datums}/>
            :
            <EGODetails detailed_datum={currentlyDetailedEgoDatum}/>}
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
                      <Button icon="trash" color="red" content="Clear" onClick={() => { setNameSearchText(null) }} />
                    </FlexItem>
                  </Flex>
                </FlexItem>

                <Flex.Item grow={1}>
                  E.G.O. Threat Class Filter
                  <Flex my={2}>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[1]}
                        content={"ZAYIN"}
                        onClick={() => { setThreatClassFilters({ ...threatClassFilters, 1: !threatClassFilters[1] }) }}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[2]}
                        content={"TETH"}
                        onClick={() => { setThreatClassFilters({ ...threatClassFilters, 2: !threatClassFilters[2] }) }}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[3]}
                        content={"HE"}
                        onClick={() => { setThreatClassFilters({ ...threatClassFilters, 3: !threatClassFilters[3] }) }}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[4]}
                        content={"WAW"}
                        onClick={() => { setThreatClassFilters({ ...threatClassFilters, 4: !threatClassFilters[4] }) }}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[5]}
                        content={"ALEPH"}
                        onClick={() => { setThreatClassFilters({ ...threatClassFilters, 5: !threatClassFilters[5] }) }}
                      />
                    </FlexItem>
                    <FlexItem ml={2}>
                      <Button icon="sync" color="red" content="Reset" onClick={() => { setThreatClassFilters({ 1: true, 2: true, 3: true, 4: true, 5: true }) }} />
                    </FlexItem>

                  </Flex>
                  <FlexItem ml={0.5}>


                  </FlexItem>
                </Flex.Item>

                {tab === 1 && <FlexItem my={2}>
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
                </FlexItem>}

                {tab === 2 && <FlexItem my={2}>
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
                        <Button icon="sync" color="red" content="Reset" onClick={() => { setArmorResistanceFilters({ "red": -10, "white": -10, "black": -10, "pale": -10 }) }} />
                      </LabeledControls.Item>
                    </LabeledControls>
                  </Flex>
                </FlexItem>}

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







