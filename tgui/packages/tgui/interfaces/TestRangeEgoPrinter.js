import { map } from '../../common/collections';
import { useBackend } from '../backend';
import { Button, LabeledList, Section } from '../components';
import { LabeledListDivider, LabeledListItem } from '../components/LabeledList';
import { Window } from '../layouts';

export const TestRangeEgoPrinter = (props, context) => {
	const { act, data } = useBackend(context);
	const { ego_datums } = data;

	return (
		<Window
      width={600}
      height={700}>
			<Window.Content scrollable>
				<Section title="E.G.O. List">
					<LabeledList>

            <LabeledListItem label="Egolist">
            {
              ego_datums?.map(datum => (
                <LabeledList>
                  <LabeledListItem label="Name">{datum.path}</LabeledListItem>
                  <LabeledListItem label="Button">
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


            <LabeledListItem label="Test-Object">{ego_datums}</LabeledListItem>
            <LabeledListItem label="Test-Stringified">{ego_datums ? JSON.stringify(ego_datums) : null}</LabeledListItem>
					</LabeledList>
				</Section>
			</Window.Content>
		</Window>
	);
};
