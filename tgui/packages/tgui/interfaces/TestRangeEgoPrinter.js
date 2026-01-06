import { map } from '../../common/collections';
import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section } from '../components';
import { LabeledListDivider, LabeledListItem } from '../components/LabeledList';
import { Window } from '../layouts';

export const TestRangeEgoPrinter = (props, context) => {
  const { act, data } = useBackend(context);
  const { ego_datums } = data;

  return (
    <Window
    width={600}
    height={800}
    >
      <Window.Content scrollable>
        <Section title="E.G.O. List">
          <LabeledList>

            <LabeledListItem label="Egolist">
              {
                ego_datums?.map(datum => (
                  <LabeledList>
                    <Section
                      fill
                      textAlign="center">
                      <Box
                        as="img"
                        m={0}
                        src={`data:image/jpeg;base64,${datum.icon}`}
                        height="32px"
                        width="32px"
                        style={{
                          '-ms-interpolation-mode': 'nearest-neighbor',
                        }} />
                    </Section>
                    <LabeledListItem label="Name">{datum.information.name}</LabeledListItem>
                    <LabeledListItem>
                      <Button
                        content="Print E.G.O."
                        onClick={() => act('print_ego', {
                          chosen_ego: datum.path,
                        })}
                      />
                    </LabeledListItem>
                    <LabeledList.Divider />
                  </LabeledList>
                )
                )
              }
            </LabeledListItem>

          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
