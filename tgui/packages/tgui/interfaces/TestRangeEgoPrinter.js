import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, LabeledList, Section, Divider, Tab, Tabs, Input, Table, Knob, LabeledControls } from '../components';
import { ButtonCheckbox } from '../components/Button';
import { FlexItem } from '../components/Flex';
import { TableCell, TableRow } from '../components/Table';
import { Window } from '../layouts';
// Alright so I can't leave any comments in the below part for some reason
// 1. Yes the threatclass stuff is hardcoded, sadly the defines THREAT_TO_COLOR and THREAT_TO_NAME are alists and apparently TGUI doesn't like beaming those into the data
// 2. There's some issue with tooltips flickering every time the TGUI subsystem fires (calling try_update_ui)
// 3. I'm not coding the roman numerical system here, it's getting hardcoded
// 4. I'm sorry this is my first TGUI interface

export const TestRangeEgoPrinter = (props, context) => {
  const { act, data } = useBackend(context);
  const { ego_weapon_datums, ego_armor_datums, all_tags } = data;
  const [tab, setTab] = useLocalState(context, 'tab', 1);
  const [nameSearchText, setNameSearchText] = useLocalState(context, "nameSearchText", "")
  const [armorResistanceFilters, setArmorResistanceFilters] = useLocalState(context, "armorResistanceFilters", {"red": -10, "white": -10, "black": -10, "pale": -10})
  const [threatClassFilters, setThreatClassFilters] = useLocalState(context, "threatClassFilters", {1: true, 2: true, 3: true, 4: true, 5: true})
  const [egoTagList, setEgoTagList] = useLocalState(context, "egoTagList", all_tags)
  const [currentWeaponDamtypeFilter, setCurrentWeaponDamtypeFilter] = useLocalState(context, "currentWeaponDamtypeFilter", null)
  const threatclass_colors = {1: "#008000", 2: "#0000FF", 3: "#C3630C", 4: "#800080", 5: "#FF0000"}
  const threatclass_names = {1: "ZAYIN", 2: "TETH", 3: "HE", 4: "WAW", 5: "ALEPH"}
  const numerals_to_decimal = {"X": 10, "IX": 9, "VIII": 8, "VII": 7, "VI": 6, "V": 5, "IV": 4, "III": 3, "II": 2, "I": 1}

  const CheckThreatClassFilters = (datum) => {
    return threatClassFilters[datum.threatclass]
  }

  const DecodeProtectionClasses = (armor_list) => {
    var decoded_armor_list = {"red": 1, "white": 1, "black": 1, "pale": 1}

    for(var string in armor_list){
      if(!armor_list[string]){
        decoded_armor_list[string] = 0
        continue
      }
      var final_string = armor_list[string]
      if(final_string.at(0) == "-"){
        decoded_armor_list[string] *= -1
        final_string = final_string.substring(1)
      }
      decoded_armor_list[string] *= numerals_to_decimal[final_string]
    }
    return decoded_armor_list
  }

  const CheckArmorResistanceFilters = (datum) => {
    const decodedProtectionClasses = DecodeProtectionClasses(datum.information.armor)
    for(var string in armorResistanceFilters){
      if(decodedProtectionClasses[string] < armorResistanceFilters[string]){
        return false
      }
    }

    return true;
  }

  const CheckNameSearchFilter = (datum) => {
    if(!nameSearchText){
      return true
    }
    return datum.information.name.toLowerCase().includes(nameSearchText.toLowerCase())
  }


  const ChangeWeaponDamtypeFilter = (color) => {
    color === currentWeaponDamtypeFilter ? setCurrentWeaponDamtypeFilter(null) : setCurrentWeaponDamtypeFilter(color)
  }

  const CheckWeaponDamtypeFilters = (datum) => {
    if(!currentWeaponDamtypeFilter){
      return true
    }

    if(datum.information.damtype_ranged && (datum.information.damtype_ranged === currentWeaponDamtypeFilter)){
      return true
    }
    else if (datum.information.damtype_melee === currentWeaponDamtypeFilter){
      return true
    }
    else
      return false
  }

  const CheckTagFilters = (datum) => {
    var should_show = false
    var filtering_tags = egoTagList.map(tag => {
      if(tag.tag_checked)
        return tag
      else
        return null
    })

    filtering_tags = filtering_tags.filter(tag => tag != null)
    if(filtering_tags.length < 1)
      return true

    for(var tag of filtering_tags){
      if(datum.tags.includes(tag.tag_name)){should_show = true}
      else{should_show = false; break;}
    }

    return should_show
  }

  const AllEgoTagCheckboxes = (props, context) => {

    const ChangeEgoTagFilters = (id) => {
      const newEgoTagList = egoTagList?.map(tag => {
        if(tag.tag_name === id){
          tag.tag_checked = !tag.tag_checked
          return tag
        }
        else
        {
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
  var regex_for_guns = /ego_weapon\/ranged\//
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
          Melee Damage: {datum.information.force_melee} {datum.information.damtype_melee}<br/>
          Melee Attack Speed: {datum.information.attack_speed}<br/>
          Melee Reach: {datum.information.reach} tiles
        </FlexItem>
        <FlexItem mt={3}>
          <Button
            content="View Details"
            onClick={() => act('request_ego_details', {
              chosen_ego: datum.path,
            })} />
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
          Projectile Damage: {datum.information.force_ranged} {datum.information.damtype_ranged}<br/>
          Projectile Fire Rate: {datum.information.attack_speed} <br/>
          Magazine Size: {datum.information.magazine_size === 0 ? "Unlimited" : datum.information.magazine_size} <br />
          <br/>
          Melee Damage: {datum.information.force_melee} {datum.information.damtype_melee}
        </FlexItem>
        <FlexItem mt={3}>
          <Button
            content="View Details"
            onClick={() => act('request_ego_details', {
              chosen_ego: datum.path,
            })} />
        </FlexItem>
      </Flex>
    </FlexItem>
  )
}



const ArmorResistanceFilterKnob = (props, context) =>{
  const { resistance_color, color } = props;

   const AdjustArmorResistanceFilter = (value) => {
    var newFilters = structuredClone(armorResistanceFilters)
    newFilters[resistance_color] = value
    setArmorResistanceFilters(newFilters)
  }

  return (
    <Knob
      color={color}
      size={1}
      step={1}
      stepPixelSize={50}
      value={armorResistanceFilters[resistance_color]}
      minValue={-10}
      maxValue={10}
      onChange={(e, value) => AdjustArmorResistanceFilter(value)}
    />
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
            onClick={() => act('request_ego_details', {
              chosen_ego: datum.path,
            })} />
        </FlexItem>
      </Flex>
    </FlexItem>
  )
}

  return (
    <Window
      width={1000}
      height={900}
    >
      <Window.Content>
        <Flex>
          <FlexItem grow={3}>
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
          </FlexItem>
          <Flex.Item>
            <Divider vertical />
          </Flex.Item>
          <FlexItem >
            <Section title="Filters">
              <Flex direction="column">
                <Flex.Item grow={1} my={1}>
                  E.G.O. Name Search Filter
                  <Input mt={1}
                    placeholder="Search..."
                    autoFocus
					          value={nameSearchText}
                    onInput={(_, value) => setNameSearchText(value)}
                    fluid
                  />
                </Flex.Item>

                <Flex.Item grow={1}>
                  E.G.O. Threat Class Filter
                  <Flex my={2}>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[1]}
                        content={"ZAYIN"}
                        onClick={() => {setThreatClassFilters({...threatClassFilters, 1: !threatClassFilters[1]})}}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[2]}
                        content={"TETH"}
                        onClick={() => {setThreatClassFilters({...threatClassFilters, 2: !threatClassFilters[2]})}}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[3]}
                        content={"HE"}
                        onClick={() => {setThreatClassFilters({...threatClassFilters, 3: !threatClassFilters[3]})}}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[4]}
                        content={"WAW"}
                        onClick={() => {setThreatClassFilters({...threatClassFilters, 4: !threatClassFilters[4]})}}
                      />
                    </FlexItem>
                    <FlexItem ml={0.5}>
                      <ButtonCheckbox
                        checked={threatClassFilters[5]}
                        content={"ALEPH"}
                        onClick={() => {setThreatClassFilters({...threatClassFilters, 5: !threatClassFilters[5]})}}
                      />
                    </FlexItem>
                    <FlexItem ml={2}>
                      <Button icon="sync" color="red" content="Reset" onClick={() => {setThreatClassFilters({1: true, 2: true, 3: true, 4: true, 5: true})}}/>
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

                  <Flex direction="row" wrap maxWidth="24rem" justify="center" mt={1}>
                    <LabeledControls>
                      <LabeledControls.Item label="Min. RED" ml={2}>
                        <ArmorResistanceFilterKnob color="red" resistance_color="red"/>
                      </LabeledControls.Item>
                      <LabeledControls.Item label="Min. WHITE" ml={2}>
                        <ArmorResistanceFilterKnob color="white" resistance_color="white"/>
                      </LabeledControls.Item>
                      <LabeledControls.Item label="Min. BLACK" ml={2}>
                        <ArmorResistanceFilterKnob color="violet" resistance_color="black"/>
                      </LabeledControls.Item>
                      <LabeledControls.Item label="Min. PALE" ml={2}>
                        <ArmorResistanceFilterKnob color="teal" resistance_color="pale"/>
                      </LabeledControls.Item>
                      <LabeledControls.Item ml={2}>
                        <Button icon="sync" color="red" content="Reset" onClick={() => {setArmorResistanceFilters({"red": -10, "white": -10, "black": -10, "pale": -10})}}/>
                      </LabeledControls.Item>
                    </LabeledControls>
                  </Flex>
                </FlexItem>}

                <FlexItem my={2}>
                  E.G.O. Tag Filters
                  <Flex nowrap direction="column" maxWidth="18rem">
                    <AllEgoTagCheckboxes/>
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







