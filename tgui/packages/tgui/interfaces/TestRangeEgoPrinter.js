import { map } from '../../common/collections';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, LabeledList, Section, Divider, Tab, Tabs, Input, Table } from '../components';
import { ButtonCheckbox } from '../components/Button';
import { FlexItem } from '../components/Flex';
import { LabeledListDivider, LabeledListItem } from '../components/LabeledList';
import { TableCell, TableRow } from '../components/Table';
import { Window } from '../layouts';

export const TestRangeEgoPrinter = (props, context) => {
  const { act, data } = useBackend(context);
  const { ego_weapon_datums, ego_armor_datums } = data;
  const [tab, setTab] = useLocalState(context, 'tab', 1);

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
                {tab === 1 && <AllWeaponDatums datum_list={ego_weapon_datums}/>}
                {tab === 2 && <AllArmorDatums datum_list={ego_armor_datums}/>}
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
                                fluid
                                 />
                  </Flex.Item>

                  <FlexItem>
                      The fog<br/>
                      The fog<br/>
                      The fog<br/>
                  </FlexItem>

                  <FlexItem>
                      <ButtonCheckbox>
                        EGO Tag example 1
                      </ButtonCheckbox>
                      <ButtonCheckbox>
                        EGO Tag example 2
                      </ButtonCheckbox>
                      <ButtonCheckbox>
                        EGO Tag example 3
                      </ButtonCheckbox>
                  </FlexItem>
                </Flex>


              </Section>
            </FlexItem>
          </Flex>

      </Window.Content>
    </Window>
  );
};

const AllWeaponDatums = (props, context) => {
  const { act, data } = useBackend(context);
  const { datum_list } = props;

  return(
    datum_list?.map(datum => (
                  <EgoDatumEntry datum={datum} type="weapon"/>
                )
                )
  )
}

const AllArmorDatums = (props, context) => {
  const { act, data } = useBackend(context);
  const { datum_list } = props;

  return(
    datum_list?.map(datum => (
                  <EgoDatumEntry datum={datum} type="armor"/>
                )
                )
  )
}

const EgoDatumEntry = (props, context) => {
  const { act, data } = useBackend(context);
  const { datum, type } = props;

  return(
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
                <Box bold color={datum.threatclass_color}>{datum.threatclass_name}</Box>
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
                })}/>
            </FlexItem>

          </Flex>
      </FlexItem>

        <FlexItem>
          <Divider vertical/>
        </FlexItem>

        <AppropiateDescription datum={datum} type={type}/>

      </Flex>
    <Divider/>
    </Box>
  )
}

const AppropiateDescription = (props) => {
  const { datum, type } = props;

  var item_path = datum.path
  var common_path_eliminated_string = item_path.slice(10)
  var regex_for_guns = /ego_weapon\/ranged\//
  if(type === "armor"){
    return(<ArmorEntryDescription datum={datum}/>)
  }
  else {
    return(regex_for_guns.test(common_path_eliminated_string) ? <RangedWeaponEntryDescription datum={datum}/> : <MeleeWeaponEntryDescription datum={datum}/>)
  }
}

const MeleeWeaponEntryDescription = (props, context) => {
  const { act, data } = useBackend(context);
  const { datum } = props;

  return(
  <FlexItem grow={1}>
    <Flex direction="column" align="center">
      <FlexItem grow={3} textAlign="center">
        It deals {datum.information.force_melee} {datum.information.damtype_melee} damage.<br/>
        It can hit up to {datum.information.reach} tiles away.
      </FlexItem>
      <FlexItem mt={3}>
        <Button
          content="View Details"
          onClick={() => act('request_ego_details', {
            chosen_ego: datum.path,
          })}/>
      </FlexItem>
    </Flex>
  </FlexItem>
  )
}
const RangedWeaponEntryDescription = (props, context) => {
  const { act, data } = useBackend(context);
  const { datum } = props;

  return(
  <FlexItem grow={1}>
    <Flex direction="column" align="center">
      <FlexItem grow={3} textAlign="center">
        Its bullets deal {datum.information.force_ranged} {datum.information.damtype_ranged} damage.<br/>
        It deals {datum.information.force_melee} {datum.information.damtype_melee} damage in melee.
      </FlexItem>
      <FlexItem mt={3}>
        <Button
          content="View Details"
          onClick={() => act('request_ego_details', {
            chosen_ego: datum.path,
          })}/>
      </FlexItem>
    </Flex>
  </FlexItem>
  )
}

const ArmorEntryDescription = (props, context) => {
  const { act, data } = useBackend(context);
  const { datum } = props;

  return(
  <FlexItem grow={1}>
    <Flex direction="column" align="center">
      <FlexItem grow={3} textAlign="center">
        Resistances
        <Table mt={3}>
          <TableRow color="#020202" bold><TableCell textAlign="center" backgroundColor="#d11616">RED</TableCell><TableCell textAlign="center" backgroundColor="#dad6d6">WHITE</TableCell><TableCell textAlign="center" backgroundColor="#3a0b77">BLACK</TableCell><TableCell textAlign="center" backgroundColor="#4baac2">PALE</TableCell></TableRow>
          <TableRow><TableCell textAlign="center">{datum.information?.armor?.red?? "-"}</TableCell><TableCell textAlign="center">{datum.information?.armor?.white?? "-"}</TableCell ><TableCell textAlign="center">{datum.information?.armor?.black?? "-"}</TableCell><TableCell textAlign="center">{datum.information?.armor?.pale?? "-"}</TableCell></TableRow>
        </Table>
      </FlexItem>
      <FlexItem mt={3}>
        <Button
          content="View Details"
          onClick={() => act('request_ego_details', {
            chosen_ego: datum.path,
          })}/>
      </FlexItem>
    </Flex>
  </FlexItem>
  )
}
