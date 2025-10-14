import { useBackend, useSharedState } from '../backend';
import {
  AnimatedNumber,
  Box,
  Button,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Table,
  TextArea,
} from '../components';
import { Window } from '../layouts';

const isValidHex = color => /^#([0-9A-F]{3}){1,2}$/i.test(color);

export const AugmentCatalogue = (props, context) => {
  const { data = {} } = useBackend(context);
  const [page, setPage] = useSharedState(context, 'page', 'template');
  const hasLoaded = data && data.forms && Array.isArray(data.forms);

  return (
    <Window
      title="Augment Catalogue"
      width={700}
      height={650}>
      <Window.Content scrollable>
        {!hasLoaded ? (<NoticeBox>Loading configuration...</NoticeBox>) : (
          <>
            {page === 'template' && <TemplatePage setPage={setPage} context={context} />}
            {page === 'effects' && <EffectsPage setPage={setPage} context={context} />}
          </>
        )}
      </Window.Content>
    </Window>
  );
};

// Page 1: Template & Customization
const TemplatePage = (props, context) => {
  const { setPage } = props;
  const { act, data } = useBackend(context);

  // Shared state for UI (persists across re-renders)
  const [selectedFormId, setSelectedFormId] = useSharedState(context, 'selectedFormId', null);
  const [selectedRank, setSelectedRank] = useSharedState(context, 'selectedRank', 1);
  const [augName, setAugName] = useSharedState(context, 'augName', '');
  const [augDesc, setAugDesc] = useSharedState(context, 'augDesc', '');
  const [primaryColor, setPrimaryColor] = useSharedState(context, 'primaryColor', '#FFFFFF');
  const [secondaryColor, setSecondaryColor] = useSharedState(context, 'secondaryColor', '#CCCCCC');

  const {
    forms = [],
    maxRank = 5,
    rankAttributeReqs = [],
    currencySymbol = 'ahn',
    busy = false,
  } = data;

  // Find selected form
  const selectedForm = forms.find(f => f.id === selectedFormId) || null;
  const currentRank = selectedRank || 1;

  // Calculate costs
  const baseCost = selectedForm
    ? (selectedForm.base_cost || 0) * currentRank : 0;
  const baseEp = selectedForm
    ? (selectedForm.base_ep || 0) + (currentRank - 1) * 2 : 0;
  const rankReq = (rankAttributeReqs?.length > currentRank - 1)
    ? (rankAttributeReqs[currentRank - 1] || 0) : 0;

  // Handlers
  const handleFormSelect = newFormId => {
    setSelectedFormId(newFormId);
    act('select_form', { formId: newFormId, rank: currentRank });
  };

  const handleRankChange = (e, value) => {
    const newRank = Math.max(1, Math.min(value || 1, maxRank || 5));
    setSelectedRank(newRank);
    act('set_rank', { rank: newRank });
  };

  const handleNameChange = (e, value) => {
    setAugName(value);
    act('set_name', { name: value });
  };

  const handleDescChange = (e, value) => {
    setAugDesc(value);
    act('set_description', { description: value });
  };

  const handleColorChange = () => {
    act('set_colors', {
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    });
  };

  return (
    <Box>
      {/* Info Banner */}
      <NoticeBox info>
        Design your augment here. The ticket can be fabricated by
        authorized personnel.
      </NoticeBox>

      {/* Template Selection Section */}
      <Section title="Template Selection">
        <LabeledList>
          <LabeledList.Item label="Form">
            {forms.length === 0 ? (
              <Box color="label">No forms available.</Box>
            ) : forms.map(f => {
              if (!f || !f.id) return null;
              const formName = f.name || 'Unnamed Form';
              const formDesc = f.desc || formName;
              const formCost = f.base_cost || 0;
              const formEP = f.base_ep || 0;
              const formStats = `(${formCost} ${currencySymbol}, ${formEP} EP)`;
              return (
                <Button
                  key={f.id}
                  selected={selectedFormId === f.id}
                  onClick={() => handleFormSelect(f.id)}
                  mr={1}
                  content={`${formName} ${formStats}`}
                  tooltip={formDesc} />
              );
            })}
          </LabeledList.Item>
          <LabeledList.Item label="Rank">
            <NumberInput
              value={currentRank}
              minValue={1}
              maxValue={maxRank}
              step={1}
              width="50px"
              onChange={handleRankChange} />
            <Box inline ml={2}>
              {rankReq > 0 && `(Req: ${rankReq}+ Attr)`}
            </Box>
          </LabeledList.Item>
        </LabeledList>
        {selectedForm && (
          <Box mt={1}>
            <Box
              borderBottom={1}
              borderColor="rgba(255, 255, 255, 0.1)"
              my={1} />
            <Box mt={1}>
              Base Cost: {Number(baseCost) || 0} {currencySymbol}
            </Box>
            <Box>Base EP: {Number(baseEp) || 0}</Box>
            <Box color="label" fontSize="small">
              {selectedForm.desc || 'No description.'}
            </Box>
          </Box>
        )}
      </Section>

      {/* Customization Section */}
      <Section title="Customization">
        <LabeledList>
          <LabeledList.Item label="Augment Name">
            <Input
              value={augName}
              onInput={handleNameChange}
              width="100%"
              maxLength={64}
              placeholder="E.g., 'My Custom Augment'"
              onBlur={handleColorChange} />
          </LabeledList.Item>
          <LabeledList.Item label="Description">
            <TextArea
              value={augDesc}
              onInput={handleDescChange}
              width="100%"
              height="60px"
              maxLength={256}
              placeholder="A brief description..."
              onBlur={handleColorChange} />
          </LabeledList.Item>
          <LabeledList.Item label="Primary Color">
            <Input
              value={primaryColor}
              onInput={(e, value) => {
                const newColor = value && value.length > 0
                  && !value.startsWith('#') ? '#' + value : value;
                setPrimaryColor(newColor);
              }}
              onBlur={handleColorChange}
              width="100px"
              placeholder="#RRGGBB"
              maxLength={7}
              style={{
                borderLeft: `5px solid ${isValidHex(primaryColor)
                  ? primaryColor : 'red'}`,
              }} />
            <Box
              inline
              width="20px"
              height="20px"
              ml={1}
              backgroundColor={isValidHex(primaryColor)
                ? primaryColor : 'transparent'}
              style={{
                border: '1px solid grey',
                verticalAlign: 'middle',
              }} />
            {!isValidHex(primaryColor) && primaryColor
              && primaryColor.length > 0 && (
              <Box inline ml={1} color="bad">Invalid Hex</Box>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Secondary Color">
            <Input
              value={secondaryColor}
              onInput={(e, value) => {
                const newColor = value && value.length > 0
                  && !value.startsWith('#') ? '#' + value : value;
                setSecondaryColor(newColor);
              }}
              onBlur={handleColorChange}
              width="100px"
              placeholder="#RRGGBB"
              maxLength={7}
              style={{
                borderLeft: `5px solid ${isValidHex(secondaryColor)
                  ? secondaryColor : 'red'}`,
              }} />
            <Box
              inline
              width="20px"
              height="20px"
              ml={1}
              backgroundColor={isValidHex(secondaryColor)
                ? secondaryColor : 'transparent'}
              style={{
                border: '1px solid grey',
                verticalAlign: 'middle',
              }} />
            {!isValidHex(secondaryColor) && secondaryColor
              && secondaryColor.length > 0 && (
              <Box inline ml={1} color="bad">Invalid Hex</Box>
            )}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      {/* Navigation Button */}
      <Box
        borderTop={1}
        borderColor="rgba(255, 255, 255, 0.1)"
        mt={2}
        pt={1}
        textAlign="right">
        <Button
          icon="arrow-right"
          content="Select Effects"
          onClick={() => setPage('effects')} />
      </Box>
    </Box>
  );
};

// Page 2: Effects Selection
const EffectsPage = (props, context) => {
  const { setPage } = props;
  const { act, data } = useBackend(context);

  // Read shared state
  const [selectedFormId] = useSharedState(context, 'selectedFormId', null);
  const [selectedRank] = useSharedState(context, 'selectedRank', 1);
  const [augName] = useSharedState(context, 'augName', '');
  const [augDesc] = useSharedState(context, 'augDesc', '');
  const [primaryColor] = useSharedState(context, 'primaryColor', '#FFFFFF');
  const [secondaryColor] = useSharedState(context, 'secondaryColor', '#CCCCCC');
  const [selectedEffects, setSelectedEffects] = useSharedState(context, 'selectedEffects', []);
  const [searchQuery, setSearchQuery] = useSharedState(context, 'searchQuery', '');

  const {
    forms = [],
    effects = [],
    currencySymbol = 'ahn',
    busy = false,
  } = data;

  // Find selected form
  const selectedForm = forms.find(f => f.id === selectedFormId) || null;
  const baseCost = selectedForm
    ? (selectedForm.base_cost || 0) * selectedRank : 0;
  const baseEp = selectedForm
    ? (selectedForm.base_ep || 0) + (selectedRank - 1) * 2 : 0;

  // Calculate selected effects data
  const selectedCounts = selectedEffects.reduce((counts, effectId) => {
    counts[effectId] = (counts[effectId] || 0) + 1;
    return counts;
  }, {});

  const selectedEffectsData = selectedEffects.map(effectId => {
    return effects.find(e => e.id === effectId);
  }).filter(e => e);

  const currentEpCost = selectedEffectsData.reduce((sum, effect) =>
    sum + (effect?.ep_cost || 0), 0);
  const currentNegEpCost = selectedEffectsData.reduce((sum, effect) =>
    sum + (effect?.ep_cost < 0 ? effect?.ep_cost : 0), 0);
  const currentEffectsCost = selectedEffectsData.reduce((sum, effect) =>
    sum + (effect?.current_ahn_cost || 0), 0);
  const remainingEp = baseEp - currentEpCost;
  const remainingNegEp = baseEp + currentNegEpCost;
  const totalCost = baseCost + currentEffectsCost;

  // Filter effects based on search
  const filteredEffects = effects.filter(effect => {
    if (!searchQuery) return true;
    const query = searchQuery.toLowerCase();
    const name = (effect?.name || '').toLowerCase();
    const desc = (effect?.desc || '').toLowerCase();
    return name.includes(query) || desc.includes(query);
  });

  // Handlers
  const handleAddEffect = effectToAdd => {
    if (!effectToAdd) return;
    if ((effectToAdd.ep_cost > 0 && effectToAdd.ep_cost <= remainingEp)
      || (effectToAdd.ep_cost < 0 && -effectToAdd.ep_cost <= remainingNegEp)) {
      const newEffects = [...selectedEffects, effectToAdd.id];
      setSelectedEffects(newEffects);
      act('add_effect', { effectId: effectToAdd.id });
    }
  };

  const handleRemoveEffect = indexToRemove => {
    const newEffects = selectedEffects.filter(
      (_, index) => index !== indexToRemove
    );
    setSelectedEffects(newEffects);
    act('remove_effect', { index: indexToRemove + 1 }); // DM uses 1-based indexing
  };

  const handleCreateTicket = () => {
    if (!selectedFormId || remainingEp < 0) {
      alert('Please ensure a Form is selected and you have non-negative remaining EP.');
      return;
    }
    if (!isValidHex(primaryColor) || !isValidHex(secondaryColor)) {
      alert('Please ensure Primary and Secondary colors are valid hex codes.');
      return;
    }
    if (selectedEffects.length === 0) {
      alert('Please select at least one effect.');
      return;
    }
    act('create_ticket');
  };

  return (
    <Box>
      {/* Top Info Bar */}
      <Section>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Box>
            Total Cost: <AnimatedNumber value={totalCost} /> {currencySymbol}
          </Box>
          <Box textAlign="right">
            <Box color={remainingEp < 0 ? 'bad' : 'good'}>
              EP: <AnimatedNumber value={remainingEp} /> / {baseEp}
            </Box>
          </Box>
        </Box>
      </Section>
      <Box borderBottom={1} borderColor="rgba(255, 255, 255, 0.1)" my={1} />

      {/* Main Content Area */}
      <Box display="flex" height="calc(100% - 120px)">
        {/* Available Effects Column */}
        <Box flexBasis="50%" pr={1} overflowY="auto" mr={1}>
          <Section title="Available Effects">
            {/* Search Bar */}
            <Box mb={1}>
              <Input
                fluid
                placeholder="Search effects by name or description..."
                value={searchQuery}
                onInput={(e, value) => setSearchQuery(value)}
              />
              {searchQuery && (
                <Box mt={0.5} color="label" fontSize="small">
                  Showing {filteredEffects.length} of {effects.length} effects
                </Box>
              )}
            </Box>
            <Table>
              <Table.Row header>
                <Table.Cell>Effect</Table.Cell>
                <Table.Cell collapsing>Properties</Table.Cell>
                <Table.Cell collapsing textAlign="right">Cost</Table.Cell>
                <Table.Cell collapsing textAlign="right">EP</Table.Cell>
                <Table.Cell collapsing>Action</Table.Cell>
              </Table.Row>
              {!effects || effects.length === 0 ? (
                <Table.Row>
                  <Table.Cell colSpan={5}>No effects available.</Table.Cell>
                </Table.Row>
              ) : filteredEffects.length === 0 ? (
                <Table.Row>
                  <Table.Cell colSpan={5}>
                    No effects match your search query.
                  </Table.Cell>
                </Table.Row>
              ) : (
                filteredEffects.map(effect => {
                  if (!effect || !effect.id || !effect.name) {
                    return null;
                  }

                  const isNegative = effect.ep_cost < 0;
                  const maxRepeats = Number(effect.repeatable) || 0;
                  const isRepeatable = maxRepeats > 0;
                  const currentCount = selectedCounts[effect.id] || 0;
                  const remainingRepeats = maxRepeats - currentCount;

                  const canAfford = (effect.ep_cost > 0
                    && effect.ep_cost <= remainingEp)
                    || (effect.ep_cost < 0
                      && -effect.ep_cost <= remainingNegEp);
                  const maxReached = isRepeatable && remainingRepeats <= 0;
                  const alreadyAddedNonRepeatable = !isRepeatable
                    && currentCount > 0;

                  const formRestricted = selectedForm?.negative_immune
                    && isNegative;

                  const isDisabled = !canAfford || maxReached
                    || alreadyAddedNonRepeatable || formRestricted;

                  let buttonTitle = 'Add Effect';
                  if (isDisabled) {
                    if (formRestricted) {
                      buttonTitle = `Form '${selectedForm?.name}' `
                        + `cannot take negative effects`;
                    }
                    else if (!canAfford) buttonTitle = 'Not enough EP';
                    else if (maxReached) {
                      buttonTitle = `Max repetitions (${maxRepeats}) reached`;
                    }
                    else if (alreadyAddedNonRepeatable) {
                      buttonTitle = 'Cannot add again';
                    }
                  }

                  const baseCostVal = effect.ahn_cost || 0;
                  const currentCost = effect.current_ahn_cost || baseCostVal;
                  const isOnSale = effect.sale_percent > 0;
                  const isMarkedUp = effect.markup_percent > 0;

                  return (
                    <Table.Row
                      key={effect.id}
                      style={{
                        borderBottom: '1px solid rgba(255, 255, 255, 0.05)',
                      }}>
                      <Table.Cell py={1}>
                        <Box fontSize="medium" title={effect.desc || ''}>
                          {effect.name}
                          {isOnSale && (
                            <Box
                              inline ml={1} px={0.5}
                              backgroundColor="green" color="white"
                              fontSize="tiny"
                              style={{ borderRadius: '3px' }}>
                              SALE
                            </Box>
                          )}
                          {isMarkedUp && (
                            <Box
                              inline ml={1} px={0.5}
                              backgroundColor="red" color="white"
                              fontSize="tiny"
                              style={{ borderRadius: '3px' }}>
                              UP
                            </Box>
                          )}
                        </Box>
                        <Box color="label" fontSize="small" mt={0.5}>
                          {effect.desc || 'No description.'}
                        </Box>
                      </Table.Cell>
                      <Table.Cell collapsing>
                        {isRepeatable && (
                          <Box
                            color="good"
                            title={`Can be applied up to ${maxRepeats} times.`}>
                            Repeatable ({remainingRepeats} left)
                          </Box>
                        )}
                        {isNegative && (
                          <Box
                            color={formRestricted ? 'grey' : 'bad'}
                            title={formRestricted
                              ? `Blocked by form '${selectedForm?.name}'`
                              : 'Grants EP but may have downsides.'}>
                            Negative
                          </Box>
                        )}
                        {!isRepeatable && !isNegative && (
                          <Box color="label">-</Box>
                        )}
                      </Table.Cell>
                      <Table.Cell collapsing textAlign="right">
                        <Box
                          color={isOnSale
                            ? 'good' : (isMarkedUp ? 'bad' : 'label')}>
                          {currentCost} {currencySymbol}
                        </Box>
                        {(isOnSale || isMarkedUp)
                          && baseCostVal !== currentCost && (
                          <Box
                            color="label" fontSize="tiny"
                            style={{ textDecoration: 'line-through' }}>
                            ({baseCostVal})
                          </Box>
                        )}
                        {isOnSale && (
                          <Box color="good" fontSize="tiny">
                            ({effect.sale_percent}% off)
                          </Box>
                        )}
                        {isMarkedUp && (
                          <Box color="bad" fontSize="tiny">
                            (+{effect.markup_percent}%)
                          </Box>
                        )}
                      </Table.Cell>
                      <Table.Cell
                        collapsing textAlign="right"
                        color={effect.ep_cost > 0
                          ? 'bad' : (isNegative ? 'good' : 'label')}>
                        {effect.ep_cost > 0
                          ? `-${effect.ep_cost}`
                          : (isNegative
                            ? `+${Math.abs(effect.ep_cost)}` : '0')}
                      </Table.Cell>
                      <Table.Cell collapsing>
                        <Button
                          icon="plus"
                          title={buttonTitle}
                          disabled={isDisabled}
                          onClick={() => handleAddEffect(effect)} />
                      </Table.Cell>
                    </Table.Row>
                  );
                })
              )}
            </Table>
          </Section>
        </Box>

        {/* Selected Effects Column */}
        <Box flexBasis="50%" pl={1} overflowY="auto" ml={1}>
          <Section title="Selected Effects">
            {selectedEffects.length === 0 ? (
              <Box color="label" textAlign="center" mt={2}>
                No effects added yet.
              </Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Effect</Table.Cell>
                  <Table.Cell collapsing textAlign="right">EP</Table.Cell>
                  <Table.Cell collapsing>Action</Table.Cell>
                </Table.Row>
                {selectedEffects.map((effectId, index) => {
                  const effect = effects.find(e => e.id === effectId);
                  if (!effect) {
                    return (
                      <Table.Row key={`missing-${index}-${effectId}`}>
                        <Table.Cell colSpan={3} color="bad">
                          Error: Effect data missing for ID {effectId}
                        </Table.Cell>
                      </Table.Row>
                    );
                  }
                  const isNegative = effect.ep_cost < 0;
                  return (
                    <Table.Row key={`${effectId}-${index}`}>
                      <Table.Cell>{effect.name}</Table.Cell>
                      <Table.Cell
                        collapsing textAlign="right"
                        color={effect.ep_cost > 0
                          ? 'bad' : (isNegative ? 'good' : 'label')}>
                        {effect.ep_cost > 0
                          ? `-${effect.ep_cost}`
                          : (isNegative
                            ? `+${Math.abs(effect.ep_cost)}` : '0')}
                      </Table.Cell>
                      <Table.Cell collapsing>
                        <Button
                          icon="minus"
                          title="Remove Effect"
                          onClick={() => handleRemoveEffect(index)}
                          color="bad"
                          compact />
                      </Table.Cell>
                    </Table.Row>
                  );
                })}
              </Table>
            )}
          </Section>
        </Box>
      </Box>

      {/* Bottom Buttons */}
      <Box
        borderTop={1}
        borderColor="rgba(255, 255, 255, 0.1)"
        mt={1}
        pt={1}
        display="flex"
        justifyContent="space-between">
        <Button
          icon="arrow-left"
          content="Back to Template"
          onClick={() => setPage('template')} />
        <Button
          icon="ticket-alt"
          content="Create Ticket"
          color="good"
          disabled={busy || remainingEp < 0 || !selectedFormId
            || !isValidHex(primaryColor) || !isValidHex(secondaryColor)
            || selectedEffects.length === 0}
          onClick={handleCreateTicket} />
      </Box>
    </Box>
  );
};
