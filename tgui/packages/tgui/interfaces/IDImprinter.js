import { useBackend } from '../backend';
import { Button, Icon, Input, LabeledList, Section } from '../components';
import { Window } from '../layouts';

export const IDImprinter = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={375}
      height={480}>
      <Window.Content>
        <Section
          title="Information"
          backgroundColor="#261A2E">
          The New League of Nine Littérateurs' Identity Imprintation Matrix
          is a machine built to draw from the Mirror and pull Identities from Mirror Worlds,
          permanently forcing an Identity onto a person, and disrupting the Mirror World
          in the process. Identities pulled are random, though power levels are not changed.
          They are merely modified - such as an Association Veteran becoming a Young Brother.
          To operate - simply insert the person, close the door, and operate. Do note that
          the process causes extreme mental and physical harm to the subject.
        </Section>
        <Section
          title="Occupant Information"
          textAlign="center">
          <LabeledList>
            <LabeledList.Item label="Name">
              {data.occupant.name ? data.occupant.name : 'No Occupant'}
            </LabeledList.Item>
            {!!data.occupied && (
              <LabeledList.Item
                label="Status"
                color={data.occupant.stat === 0
                  ? 'good'
                  : data.occupant.stat === 1
                    ? 'average'
                    : 'bad'}>
                {data.occupant.stat === 0
                  ? 'Conscious'
                  : data.occupant.stat === 1
                    ? 'Unconcious'
                    : 'Dead'}
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        <Section
          title="Operations"
          textAlign="center">
          <LabeledList>
            <LabeledList.Item label="Door">
              <Button
                icon={data.open ? 'unlock' : 'lock'}
                color={data.open ? 'default' : 'red'}
                content={data.open ? 'Open' : 'Closed'}
                onClick={() => act('door')} />
            </LabeledList.Item>
            <LabeledList.Item label="Begin Imprinting">
              <Button
                icon="code-branch"
                content={data.imprinting
                  ? "Interrupt Imprinting"
                  : 'Begin Identity Imprinting'}
                onClick={() => act('imprint')} />
              {data.imprinting === 1 && (
                <Icon
                  name="cog"
                  color="orange"
                  spin />
              )}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
