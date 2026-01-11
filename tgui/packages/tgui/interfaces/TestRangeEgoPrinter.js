import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, LabeledList, Section, Divider, Tab, Tabs, Input, Table } from '../components';
import { ButtonCheckbox } from '../components/Button';
import { FlexItem } from '../components/Flex';
import { TableCell, TableRow } from '../components/Table';
import { Window } from '../layouts';

export const TestRangeEgoPrinter = (props, context) => {
  const { act, data } = useBackend(context);
  const { ego_weapon_datums, ego_armor_datums, all_tags } = data;
  const [tab, setTab] = useLocalState(context, 'tab', 1);
  const [nameSearchText, setNameSearchText] = useLocalState(context, "nameSearchText", "")
  const [egoTagList, setEgoTagList] = useLocalState(context, "egoTagList", all_tags)
  const [currentWeaponDamtypeFilter, setCurrentWeaponDamtypeFilter] = useLocalState(context, "currentWeaponDamtypeFilter", null)
  const threatclass_colors = {1: "#008000", 2: "#0000FF", 3: "#C3630C", 4: "#800080", 5: "#FF0000"}
  const threatclass_names = {1: "ZAYIN", 2: "TETH", 3: "HE", 4: "WAW", 5: "ALEPH"}

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
            tooltipPosition={"bottom"}
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
     CheckNameSearchFilter(datum) && CheckWeaponDamtypeFilters(datum) && CheckTagFilters(datum) && <EgoDatumEntry datum={datum} type="weapon" />
    )
    )
  )
}

const AllArmorDatums = (props, context) => {
  const { act, data } = useBackend(context);
  const { datum_list } = props;

  return (
    datum_list?.map(datum => (
      CheckNameSearchFilter(datum) && CheckTagFilters(datum) && <EgoDatumEntry datum={datum} type="armor" />
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
      width={700}
      height={900}
    >
      <Window.Content scrollable>
        <Flex>
          <FlexItem grow={3}>
            <Section title="E.G.O. List">
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
          <FlexItem grow={2}>
            <Section title="Filters">
              <Flex direction="column">
                <Flex.Item grow={1} my={1}>

                  <Input
                    placeholder="Search..."
                    autoFocus
					          value={nameSearchText}
                    onInput={(_, value) => setNameSearchText(value)}
                    fluid
                  />
                </Flex.Item>

                {tab === 1 && <FlexItem mt={2}>
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

                <FlexItem mt={2}>
                  E.G.O. Tag Filters
                  <Flex direction="row" wrap maxWidth="18rem">
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







