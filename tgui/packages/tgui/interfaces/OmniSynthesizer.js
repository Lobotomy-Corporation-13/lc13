import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Flex,
  Icon,
  NoticeBox,
  NumberInput,
  Section,
  Slider,
  Stack,
} from '../components';
import { Window } from '../layouts';

const RARITY = ['#8a94a6', '#3fbf5f', '#3f8fdf', '#a95fdf'];

const matImg = (icon, size) => (
  <img
    src={'data:image/png;base64,' + icon}
    style={{
      'width': size + 'px',
      'height': size + 'px',
      'image-rendering': 'pixelated',
      'vertical-align': 'middle',
    }}
  />
);

const tierColor = tier => RARITY[tier] || RARITY[0];
const tierLabel = tier => 'T' + tier + ' (' + (tier + 1) + '-star)';

export const OmniSynthesizer = (props, context) => {
  const { data } = useBackend(context);
  const [mode, setMode] = useLocalState(context, 'omni_mode', 'convert');
  const modes = [
    { id: 'convert', name: 'Convert', icon: 'exchange-alt' },
    { id: 'refine', name: 'Refine', icon: 'flask' },
    { id: 'storage', name: 'Storage', icon: 'box-open' },
    { id: 'shop', name: 'Requisition', icon: 'shopping-cart' },
  ];
  const cur = modes.find(m => m.id === mode) || modes[0];
  return (
    <Window title="Omni-Synthesizer" width={780} height={560}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section>
              <Flex align="center">
                <Flex.Item grow>
                  <Box fontSize="0.85em" color="label">Omni-Synthesizer</Box>
                  <Box fontSize="1.2em" bold>{cur.name}</Box>
                </Flex.Item>
                <Flex.Item>
                  {modes.map(m => (
                    <Button
                      key={m.id}
                      icon={m.icon}
                      content={m.name}
                      selected={m.id === mode}
                      onClick={() => setMode(m.id)}
                    />
                  ))}
                </Flex.Item>
                <Flex.Item ml={2}>
                  <Icon name="gem" color="#a95fdf" />
                  {' '}
                  <Box inline bold>{data.player_ahn}</Box>
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            {mode === 'convert' && <ConvertGroup />}
            {mode === 'refine' && <RefineGroup />}
            {mode === 'storage' && <StorageView />}
            {mode === 'shop' && <ShopView />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// A light segmented row of buttons for switching between related sub-views.
const SubTabs = (props, context) => {
  const { value, setValue, options } = props;
  return (
    <Section>
      {options.map(o => (
        <Button
          key={o.id}
          icon={o.icon}
          content={o.name}
          selected={o.id === value}
          onClick={() => setValue(o.id)}
        />
      ))}
    </Section>
  );
};

// Convert tab: reshape materials (synthesize up a tier, or trade families).
const ConvertGroup = (props, context) => {
  const [sub, setSub] = useLocalState(context, 'omni_convert_sub', 'synth');
  return (
    <Stack fill vertical>
      <Stack.Item>
        <SubTabs
          value={sub}
          setValue={setSub}
          options={[
            { id: 'synth', name: 'Synthesize', icon: 'flask' },
            { id: 'exchange', name: 'Exchange', icon: 'exchange-alt' },
          ]}
        />
      </Stack.Item>
      <Stack.Item grow>
        <ConvertView mode={sub} />
      </Stack.Item>
    </Stack>
  );
};

// Refine tab: turn materials into outputs (path EXP books, or base chems/PE).
const RefineGroup = (props, context) => {
  const [sub, setSub] = useLocalState(context, 'omni_refine_sub', 'exp');
  return (
    <Stack fill vertical>
      <Stack.Item>
        <SubTabs
          value={sub}
          setValue={setSub}
          options={[
            { id: 'exp', name: 'EXP Books', icon: 'book' },
            { id: 'base', name: 'Base Ops', icon: 'vial' },
          ]}
        />
      </Stack.Item>
      <Stack.Item grow>
        {sub === 'exp' && <ExpView />}
        {sub === 'base' && <BaseView />}
      </Stack.Item>
    </Stack>
  );
};

// Category accent colors, used to label path vs trace throughout.
const PATH_COLOR = '#e0b060';
const TRACE_COLOR = '#7fd0ff';
const catColor = cat => (cat === 'trace' ? TRACE_COLOR : PATH_COLOR);
const catLabel = cat => (cat === 'trace' ? 'Trace' : 'Path');

const ConvertView = ({ mode }, context) => {
  const { data } = useBackend(context);
  const { catalog = [], synth_cost, exchange_cost } = data;
  // Synth needs a higher tier to make; exchange works on any tier/category.
  const list = catalog.filter(m =>
    mode === 'synth' ? m.tier < 3 : true);
  const [selRef, setSelRef] = useLocalState(
    context, 'omni_sel_' + mode, null);
  const selected = list.find(m => m.ref === selRef) || list[0];
  if (!selected) {
    return (
      <NoticeBox>
        No eligible materials. Bank materials by clicking the synthesizer
        with a material stack or a cosmic material pouch.
      </NoticeBox>
    );
  }
  const need = mode === 'synth' ? synth_cost : exchange_cost;
  return (
    <Flex fill>
      <Flex.Item basis="240px">
        <Section fill scrollable title="Materials">
          <MatGroup
            label="Path Materials"
            color={PATH_COLOR}
            mats={list.filter(m => m.cat === 'path')}
            selRef={selected.ref}
            onSelect={setSelRef}
          />
          <MatGroup
            label="Trace Materials"
            color={TRACE_COLOR}
            mats={list.filter(m => m.cat === 'trace')}
            selRef={selected.ref}
            onSelect={setSelRef}
          />
        </Section>
      </Flex.Item>
      <Flex.Item grow ml={1}>
        <CenterPanel mode={mode} selected={selected} need={need} />
      </Flex.Item>
    </Flex>
  );
};

// A labeled group of material cells (Path or Trace).
const MatGroup = props => {
  const { label, color, mats, selRef, onSelect } = props;
  if (!mats.length) {
    return null;
  }
  return (
    <Box mb={1}>
      <Box
        bold
        style={{
          'color': color,
          'border-bottom': '1px solid ' + color,
          'margin-bottom': '4px',
        }}>
        {label}
      </Box>
      <Flex wrap>
        {mats.map(m => (
          <Flex.Item key={m.ref} m={0.5}>
            <MatCell
              mat={m}
              selected={m.ref === selRef}
              onClick={() => onSelect(m.ref)}
            />
          </Flex.Item>
        ))}
      </Flex>
    </Box>
  );
};

// A material cell: rarity-bordered icon with owned count and a category
// accent stripe on top so path vs trace reads at a glance.
const MatCell = props => {
  const { mat, selected, onClick } = props;
  return (
    <Box
      onClick={onClick}
      textAlign="center"
      width="64px"
      style={{
        'padding': '2px',
        'border': (selected ? '2px' : '1px') + ' solid '
          + (selected ? '#ffb400' : tierColor(mat.tier)),
        'border-top': '3px solid ' + catColor(mat.cat),
        'border-radius': '4px',
        'cursor': 'pointer',
      }}>
      {matImg(mat.icon, 40)}
      <Box bold color={mat.owned ? 'good' : 'label'}>{mat.owned}</Box>
    </Box>
  );
};

const CenterPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { mode, selected, need } = props;
  const {
    catalog = [], path_families = [], trace_families = [],
  } = data;
  // Exchange only swaps within the same category (path<->path, trace<->trace).
  const families = selected.cat === 'trace' ? trace_families : path_families;
  const others = families.filter(p => p.key !== selected.key);
  const [target, setTarget] = useLocalState(
    context, 'omni_tgt', others.length ? others[0].key : null);
  const tgtKey = mode === 'exchange'
    ? (others.find(p => p.key === target) ? target : others[0]?.key)
    : selected.key;
  const result = mode === 'synth'
    ? catalog.find(c => c.cat === selected.cat
        && c.key === selected.key && c.tier === selected.tier + 1)
    : catalog.find(c => c.cat === selected.cat
        && c.key === tgtKey && c.tier === selected.tier);
  const maxQty = Math.floor(selected.owned / need) || 0;
  const [qty, setQty] = useLocalState(context, 'omni_qty_' + mode, 1);
  const q = Math.max(1, Math.min(qty, maxQty || 1));
  const totalNeed = need * q;
  const enough = selected.owned >= totalNeed && maxQty >= 1 && result;
  return (
    <Section fill>
      <Flex direction="column" align="center" height="100%">
        <Flex.Item>
          <Box
            inline
            px={1}
            bold
            style={{
              'background': catColor(selected.cat),
              'color': '#111',
              'border-radius': '3px',
            }}>
            {catLabel(selected.cat)} Material
          </Box>
          {' '}
          <Box inline color="label">{selected.name}</Box>
        </Flex.Item>
        <Flex.Item mt={1} color="label">
          Currently Owned: {result ? result.owned : 0}
        </Flex.Item>
        <Flex.Item mt={1}>
          <Box
            style={{
              'border': '3px solid '
                + (result ? tierColor(result.tier) : '#555'),
              'border-radius': '50%',
              'padding': '10px',
            }}>
            {result ? matImg(result.icon, 56) : matImg(selected.icon, 56)}
          </Box>
        </Flex.Item>
        <Flex.Item mt={1}>
          <Icon name="arrow-up" color="#ffb400" size={1.5} />
        </Flex.Item>
        <Flex.Item mt={1} bold>Materials Needed</Flex.Item>
        <Flex.Item mt={1} textAlign="center">
          {matImg(selected.icon, 40)}
          <Box color={enough ? 'good' : 'bad'}>
            {selected.owned}/{totalNeed}
          </Box>
          {mode === 'exchange' && others.length ? (
            <Box mt={1}>
              <Box fontSize="0.8em" color="label">Exchange into:</Box>
              <Flex justify="center" wrap>
                {others.map(p => {
                  const oc = catalog.find(c => c.cat === selected.cat
                    && c.key === p.key && c.tier === selected.tier);
                  const sel = p.key === tgtKey;
                  return (
                    <Flex.Item key={p.key} m={0.5}>
                      <Box
                        onClick={() => setTarget(p.key)}
                        tooltip={p.name}
                        textAlign="center"
                        style={{
                          'border': (sel ? '2px' : '1px') + ' solid '
                            + (sel ? '#ffb400' : '#555'),
                          'border-radius': '4px',
                          'padding': '2px',
                          'cursor': 'pointer',
                        }}>
                        {oc ? matImg(oc.icon, 28) : null}
                      </Box>
                    </Flex.Item>
                  );
                })}
              </Flex>
            </Box>
          ) : null}
        </Flex.Item>
        <Flex.Item mt={2}>
          <Flex align="center">
            <Flex.Item>
              <Button
                icon="minus"
                disabled={q <= 1}
                onClick={() => setQty(q - 1)}
              />
            </Flex.Item>
            <Flex.Item grow mx={1} width="180px">
              <Box textAlign="center" color="label">Quantity: {q}</Box>
              <Slider
                value={q}
                minValue={1}
                maxValue={maxQty || 1}
                step={1}
                onDrag={(e, val) => setQty(val)}
              />
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="plus"
                disabled={q >= maxQty}
                onClick={() => setQty(q + 1)}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item mt={2}>
          <Button
            fluid
            textAlign="center"
            color="good"
            disabled={!enough}
            content={mode === 'synth' ? 'Synthesize' : 'Exchange'}
            onClick={() => act(mode === 'synth' ? 'synthesize' : 'exchange', {
              ref: selected.ref,
              amount: q,
              target: tgtKey,
            })}
          />
        </Flex.Item>
        <Flex.Item mt={1}>
          <Button
            icon="hand-holding"
            content={'Withdraw ' + selected.name + ' (' + selected.owned + ')'}
            disabled={!selected.owned}
            onClick={() => act('withdraw', { ref: selected.ref })}
          />
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const ShopView = (props, context) => {
  const { act, data } = useBackend(context);
  const { shop = [] } = data;
  return (
    <Section fill scrollable title="Requisition (spend ahn)">
      {shop.map(item => (
        <Box key={item.id} mb={1}>
          <Flex align="center">
            <Flex.Item grow>
              <Box bold>{item.name}</Box>
              <Box fontSize="0.9em" color="label">{item.desc}</Box>
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="shopping-cart"
                content={item.cost + ' ahn'}
                disabled={!item.affordable}
                onClick={() => act('buy', { item: item.id })}
              />
            </Flex.Item>
          </Flex>
        </Box>
      ))}
    </Section>
  );
};

const StoreRow = (props, context) => {
  const { act } = useBackend(context);
  const { mat } = props;
  return (
    <Flex align="center" mb={0.5}>
      <Flex.Item>{matImg(mat.icon, 28)}</Flex.Item>
      <Flex.Item grow ml={1}>
        <Box>{mat.name}</Box>
        <Box fontSize="0.8em" color="label">{tierLabel(mat.tier)}</Box>
      </Flex.Item>
      <Flex.Item mr={1} bold>x{mat.owned}</Flex.Item>
      <Flex.Item>
        <Button
          icon="hand-holding"
          content="Withdraw"
          onClick={() => act('withdraw', { ref: mat.ref })}
        />
      </Flex.Item>
    </Flex>
  );
};

const BookRow = (props, context) => {
  const { act } = useBackend(context);
  const { book } = props;
  return (
    <Flex align="center" mb={0.5}>
      <Flex.Item>{matImg(book.icon, 28)}</Flex.Item>
      <Flex.Item grow ml={1}>{book.name}</Flex.Item>
      <Flex.Item mr={1} bold>x{book.count}</Flex.Item>
      <Flex.Item>
        <Button
          icon="hand-holding"
          content="Withdraw"
          onClick={() => act('withdraw', { ref: book.ref })}
        />
      </Flex.Item>
    </Flex>
  );
};

const StorageView = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    catalog = [],
    banked_books = [],
    enk_banked = 0,
    enk_ref,
    enk_icon,
  } = data;
  const owned = catalog.filter(m => m.owned > 0);
  const path = owned.filter(m => m.cat === 'path');
  const trace = owned.filter(m => m.cat === 'trace');
  const empty = !owned.length && !banked_books.length && !enk_banked;
  return (
    <Section fill scrollable title="Banked Materials">
      {empty && (
        <NoticeBox>
          Nothing banked yet. Click the synthesizer with a material stack, a
          cosmic material pouch, or an EXP book to store it inside.
        </NoticeBox>
      )}
      {path.length > 0 && (
        <Box mb={1}>
          <Box
            bold
            style={{
              'color': PATH_COLOR,
              'border-bottom': '1px solid ' + PATH_COLOR,
              'margin-bottom': '4px',
            }}>
            Path Materials
          </Box>
          {path.map(m => <StoreRow key={m.ref} mat={m} />)}
        </Box>
      )}
      {trace.length > 0 && (
        <Box mb={1}>
          <Box
            bold
            style={{
              'color': TRACE_COLOR,
              'border-bottom': '1px solid ' + TRACE_COLOR,
              'margin-bottom': '4px',
            }}>
            Trace Materials
          </Box>
          {trace.map(m => <StoreRow key={m.ref} mat={m} />)}
        </Box>
      )}
      {banked_books.length > 0 && (
        <Box>
          <Box
            bold
            style={{
              'color': '#e0c060',
              'border-bottom': '1px solid #e0c060',
              'margin-bottom': '4px',
            }}>
            EXP Books
          </Box>
          {banked_books.map(b => <BookRow key={b.ref} book={b} />)}
        </Box>
      )}
      {enk_banked > 0 && (
        <Box mt={1}>
          <Box
            bold
            style={{
              'color': '#e0a038',
              'border-bottom': '1px solid #e0a038',
              'margin-bottom': '4px',
            }}>
            Compacted Enkephalin
          </Box>
          <Flex align="center" mb={0.5}>
            <Flex.Item>{matImg(enk_icon, 28)}</Flex.Item>
            <Flex.Item grow ml={1}>compacted enkephalin</Flex.Item>
            <Flex.Item mr={1} bold>x{enk_banked}</Flex.Item>
            <Flex.Item>
              <Button
                icon="hand-holding"
                content="Withdraw"
                onClick={() => act('withdraw', { ref: enk_ref })}
              />
            </Flex.Item>
          </Flex>
        </Box>
      )}
    </Section>
  );
};

const ExpView = (props, context) => {
  const { act, data } = useBackend(context);
  const { exp_recipes = [] } = data;
  return (
    <Section fill scrollable title="EXP Refinery">
      <Box fontSize="0.85em" color="label" mb={1}>
        Refine the T1 book from banked T1 materials (Path is cheaper than
        Trace), then combine 3 of a tier into the next.
      </Box>
      {exp_recipes.map(r => (
        <Box key={r.id} mb={1}>
          <Flex align="center">
            <Flex.Item>{matImg(r.icon, 32)}</Flex.Item>
            <Flex.Item grow ml={1}>
              <Box bold>{r.name}</Box>
              <Box fontSize="0.85em" color="label">
                +{r.exp} path EXP
              </Box>
            </Flex.Item>
            {r.main_cost > 0 && (
              <Flex.Item>
                <Button
                  icon="gem"
                  content={'Path x' + r.main_cost}
                  disabled={r.main_have < r.main_cost}
                  tooltip={'Uses ' + r.main_cost + ' path T' + r.tier
                    + ' (' + r.main_have + ' banked)'}
                  onClick={() =>
                    act('craft_exp', { id: r.id, source: 'main' })}
                />
              </Flex.Item>
            )}
            {r.trace_cost > 0 && (
              <Flex.Item ml={0.5}>
                <Button
                  icon="atom"
                  content={'Trace x' + r.trace_cost}
                  disabled={r.trace_have < r.trace_cost}
                  tooltip={'Uses ' + r.trace_cost + ' trace T' + r.tier
                    + ' (' + r.trace_have + ' banked)'}
                  onClick={() =>
                    act('craft_exp', { id: r.id, source: 'trace' })}
                />
              </Flex.Item>
            )}
            {r.combine_cost > 0 && (
              <Flex.Item ml={0.5}>
                <Button
                  icon="layer-group"
                  content={'Combine x' + r.combine_cost}
                  disabled={r.lower_have < r.combine_cost}
                  tooltip={'Fuse ' + r.combine_cost + ' ' + r.lower_name
                    + ' (' + r.lower_have + ' held)'}
                  onClick={() =>
                    act('craft_exp', { id: r.id, source: 'combine' })}
                />
              </Flex.Item>
            )}
          </Flex>
        </Box>
      ))}
    </Section>
  );
};

// ---- Base Conversion tab: chems + PE from materials ----

const swatch = color => (
  <Box
    inline
    mr={0.5}
    style={{
      'display': 'inline-block',
      'width': '10px',
      'height': '10px',
      'border-radius': '2px',
      'vertical-align': 'middle',
      'background': color,
    }}
  />
);

const BeakerPanel = (props, context) => {
  const { act } = useBackend(context);
  const b = props.beaker || {};
  if (!b.loaded) {
    return (
      <Section title="Container" fill>
        <NoticeBox>
          Insert an open reagent container (a beaker, bottle, jug...)
          to read its contents and pour ground chemicals into it.
        </NoticeBox>
      </Section>
    );
  }
  const contents = b.contents || [];
  return (
    <Section
      title={b.name || 'Container'}
      fill
      scrollable
      buttons={
        <Button
          icon="eject"
          content="Eject"
          onClick={() => act('eject_beaker')}
        />
      }>
      <Box mb={1} color="label">
        {b.current} / {b.max} units
      </Box>
      {contents.length === 0 && (
        <Box color="label">Empty.</Box>
      )}
      {contents.map(r => (
        <Box key={r.name} mb={1}>
          <Box fontSize="0.85em">
            {swatch(r.color)}
            {r.name} ({r.volume}u)
          </Box>
          <Box
            style={{
              'height': '12px',
              'border-radius': '2px',
              'overflow': 'hidden',
              'background': 'rgba(0,0,0,0.35)',
            }}>
            <Box
              style={{
                'height': '12px',
                'background': r.color,
                'width':
                  Math.min(100, (r.volume / (b.max || 1)) * 100) + '%',
              }}
            />
          </Box>
        </Box>
      ))}
    </Section>
  );
};

const GrindRow = (props, context) => {
  const { act } = useBackend(context);
  const { fam, points, cost, loaded } = props;
  const [amt, setAmt] = useLocalState(context, 'omni_grind_' + fam.key, 1);
  const owned = [fam.t1, fam.t2, fam.t3];
  return (
    <Flex align="center" mb="3px">
      <Flex.Item width="9em">
        {swatch(fam.color)}
        {fam.name}
      </Flex.Item>
      <Flex.Item>
        <NumberInput
          value={amt}
          minValue={1}
          maxValue={99}
          width="3.5em"
          onChange={(e, v) => setAmt(v)}
        />
      </Flex.Item>
      {[1, 2, 3].map(t => {
        const have = owned[t - 1];
        const out = Math.floor((amt * points[t - 1]) / cost);
        return (
          <Flex.Item key={t} ml="3px">
            <Button
              content={'T' + t + ' (' + have + ')'}
              disabled={!loaded || have < amt || out < 1}
              tooltip={'Grind ' + amt + ' -> ' + out + 'u ' + fam.chem}
              onClick={() =>
                act('grind_chem', { key: fam.key, tier: t, amount: amt })}
            />
          </Flex.Item>
        );
      })}
    </Flex>
  );
};

const CompactRow = (props, context) => {
  const { act } = useBackend(context);
  const { fam, points, cost } = props;
  const [amt, setAmt] = useLocalState(context, 'omni_comp_' + fam.key, 1);
  const owned = [fam.t1, fam.t2, fam.t3];
  return (
    <Flex align="center" mb="3px">
      <Flex.Item width="9em">{fam.name}</Flex.Item>
      <Flex.Item>
        <NumberInput
          value={amt}
          minValue={1}
          maxValue={99}
          width="3.5em"
          onChange={(e, v) => setAmt(v)}
        />
      </Flex.Item>
      {[1, 2, 3].map(t => {
        const have = owned[t - 1];
        const out = Math.floor((amt * points[t - 1]) / cost);
        return (
          <Flex.Item key={t} ml="3px">
            <Button
              content={'T' + t + ' (' + have + ')'}
              disabled={have < amt || out < 1}
              tooltip={'Compact ' + amt + ' -> ' + out + ' enkephalin'}
              onClick={() =>
                act('compact_trace', { key: fam.key, tier: t, amount: amt })}
            />
          </Flex.Item>
        );
      })}
    </Flex>
  );
};

const BaseView = (props, context) => {
  const { act, data } = useBackend(context);
  const beaker = data.beaker || {};
  const points = data.mat_points || [2, 6, 18];
  const chemCost = data.chem_point_cost || 9;
  const enkCost = data.enk_point_cost || 2;
  const banked = data.enk_banked || 0;
  const need = data.enk_refine_cost || 50;
  return (
    <Stack fill>
      <Stack.Item width="33%">
        <BeakerPanel beaker={beaker} />
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable>
          <Box bold mb={1}>
            Grind Path Materials into Sin Chemicals
          </Box>
          <Box fontSize="0.8em" color="label" mb={1}>
            Pours the chosen tier into the inserted container.{' '}
            {chemCost} points make 1 unit (top-tier = 2 units).
          </Box>
          {(data.grind_families || []).map(f => (
            <GrindRow
              key={f.key}
              fam={f}
              points={points}
              cost={chemCost}
              loaded={beaker.loaded}
            />
          ))}
          <Box bold mt={2} mb={1}>
            Compact Trace Materials into Enkephalin
          </Box>
          {(data.compact_families || []).map(f => (
            <CompactRow
              key={f.key}
              fam={f}
              points={points}
              cost={enkCost}
            />
          ))}
          <Box mt={2}>
            Banked enkephalin: <b>{banked}</b>
            {' '}
            <Button
              icon="box"
              content={'Refine ' + need + ' -> Refined PE Box'}
              disabled={banked < need}
              tooltip="Bank compacted enkephalin here, then fuse them."
              onClick={() => act('refine_pe')}
            />
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
