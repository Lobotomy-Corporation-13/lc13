import { useBackend, useLocalState } from '../backend';
import { Box, Button, Icon, Section, Stack } from '../components';
import { Window } from '../layouts';

const GOLD = '#d9bd7c';
const GOLD_DIM = '#8d7a4e';
const INK = '#f0e4c4';

// Where each category sits on the chart, as a percentage of the panel, plus
// how large its emblem reads. Loosely the arrangement of the reference art:
// Characters largest and near the middle, the rest strung around it.
const NODES = {
  'Enemy Creatures': { icon: 'dragon', x: 31, y: 25, size: 60 },
  'Aeons': { icon: 'sun', x: 46, y: 52, size: 52 },
  'Characters': { icon: 'users', x: 64, y: 36, size: 74 },
  'Terms': { icon: 'comment-dots', x: 85, y: 27, size: 50 },
  'Factions': { icon: 'shield-alt', x: 22, y: 68, size: 56 },
};

// Decorative orbits. Circles that are rotated and stretched, which reads as
// elliptical arcs without needing any artwork.
const ORBITS = [
  { x: 46, y: 44, w: 74, h: 78, rot: -18, o: 0.18 },
  { x: 54, y: 52, w: 112, h: 94, rot: 14, o: 0.11 },
  { x: 36, y: 54, w: 56, h: 64, rot: 34, o: 0.14 },
  { x: 68, y: 40, w: 42, h: 48, rot: -6, o: 0.16 },
];

// A fixed pseudo-random field, generated once, so the stars hold still
// between renders instead of dancing on every update.
const seeded = seed => {
  let s = seed;
  return () => {
    s = (s * 1103515245 + 12345) % 2147483648;
    return s / 2147483648;
  };
};

const STARS = (() => {
  const next = seeded(20250725);
  const out = [];
  for (let i = 0; i < 110; i++) {
    out.push({
      x: next() * 100,
      y: next() * 100,
      size: next() > 0.85 ? 2 : 1,
      alpha: 0.2 + next() * 0.65,
    });
  }
  return out;
})();

const Backdrop = () => (
  <Box
    style={{
      'position': 'absolute',
      'top': 0,
      'left': 0,
      'right': 0,
      'bottom': 0,
      'overflow': 'hidden',
      'background':
        'radial-gradient(ellipse at 62% 34%, #1d3358 0%, #101d3a 45%,'
        + ' #070c1c 100%)',
    }}>
    {STARS.map((s, i) => (
      <Box
        key={i}
        style={{
          'position': 'absolute',
          'left': s.x + '%',
          'top': s.y + '%',
          'width': s.size + 'px',
          'height': s.size + 'px',
          'border-radius': '50%',
          'background': '#ffffff',
          'opacity': s.alpha,
        }}
      />
    ))}
    {ORBITS.map((o, i) => (
      <Box
        key={i}
        style={{
          'position': 'absolute',
          'left': o.x + '%',
          'top': o.y + '%',
          'width': o.w + '%',
          'height': o.h + '%',
          'margin-left': -o.w / 2 + '%',
          'margin-top': -o.h / 2 + '%',
          'border': '1px solid rgba(217, 189, 124, ' + o.o + ')',
          'border-radius': '50%',
          'transform': 'rotate(' + o.rot + 'deg)',
        }}
      />
    ))}
  </Box>
);

const CategoryNode = (props, context) => {
  const { entry, onClick } = props;
  const node = NODES[entry.name];
  const full = entry.total > 0 && entry.opened >= entry.total;
  return (
    <Box
      onClick={onClick}
      style={{
        'position': 'absolute',
        'left': node.x + '%',
        'top': node.y + '%',
        'transform': 'translate(-50%, -50%)',
        'text-align': 'center',
        'cursor': 'pointer',
      }}>
      <Box
        style={{
          'width': node.size + 'px',
          'height': node.size + 'px',
          'margin': '0 auto',
          'border': '2px solid ' + (full ? GOLD : GOLD_DIM),
          'border-radius': '50%',
          'background':
            'radial-gradient(circle, rgba(217,189,124,0.22) 0%,'
            + ' rgba(12,20,44,0.85) 72%)',
          'box-shadow': '0 0 12px rgba(217, 189, 124, 0.35)',
          'line-height': node.size + 'px',
        }}>
        <Icon
          name={node.icon}
          style={{
            'color': GOLD,
            'font-size': Math.round(node.size * 0.42) + 'px',
            'vertical-align': 'middle',
          }}
        />
      </Box>
      <Box
        mt={0.5}
        style={{
          'color': INK,
          'font-size': '13px',
          'font-weight': 'bold',
          'text-shadow': '0 1px 3px #000',
          'white-space': 'nowrap',
        }}>
        {entry.name}
      </Box>
      <Box
        style={{
          'color': GOLD,
          'font-size': '13px',
          'text-shadow': '0 1px 3px #000',
        }}>
        {entry.opened + '/' + entry.total}
      </Box>
    </Box>
  );
};

const Overview = (props, context) => {
  const { categories, onPick } = props;
  return (
    <Box
      style={{
        'position': 'absolute',
        'top': 0,
        'left': 0,
        'right': 0,
        'bottom': 0,
      }}>
      <Backdrop />
      <Box
        style={{
          'position': 'absolute',
          'top': '10px',
          'left': '12px',
          'color': INK,
          'font-size': '16px',
          'font-weight': 'bold',
          'text-shadow': '0 1px 3px #000',
        }}>
        <Icon name="compass" style={{ 'color': GOLD }} />
        {' Data Bank'}
      </Box>
      {categories
        .filter(c => NODES[c.name])
        .map(c => (
          <CategoryNode
            key={c.name}
            entry={c}
            onClick={() => onPick(c.name)}
          />
        ))}
    </Box>
  );
};

const Detail = (props, context) => {
  const { category, entries, picked, onPick, onBack } = props;
  const mine = entries
    .filter(e => e.cat === category)
    .sort((a, b) =>
      a.order !== b.order
        ? a.order - b.order
        : a.name.localeCompare(b.name));
  const shown = mine.find(e => e.id === picked);
  return (
    <Stack fill>
      <Stack.Item width="240px">
        <Section fill scrollable title={category}>
          <Button
            fluid
            icon="arrow-left"
            content="Back to the chart"
            onClick={onBack}
          />
          {mine.map(e => (
            <Button
              key={e.id}
              fluid
              mt={0.5}
              disabled={!e.open}
              icon={e.open ? 'file-alt' : 'lock'}
              selected={e.id === picked}
              content={e.name}
              onClick={() => onPick(e.id)}
            />
          ))}
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable>
          {(!shown && (
            <Box color="label">
              Select a record from the index.
            </Box>
          )) || (
            <Box>
              <Box bold fontSize="1.3em" style={{ 'color': GOLD }}>
                {shown.name}
              </Box>
              {!!shown.subtitle && (
                <Box color="label" mb={1}>
                  {shown.subtitle}
                </Box>
              )}
              <Box
                mt={1}
                style={{
                  'white-space': 'pre-wrap',
                  'line-height': '1.5',
                }}>
                {shown.lore}
              </Box>
            </Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const DataBank = (props, context) => {
  const { data } = useBackend(context);
  const { categories = [], entries = [] } = data;
  const [category, setCategory] = useLocalState(context, 'db_cat', null);
  const [picked, setPicked] = useLocalState(context, 'db_entry', null);
  const open = category && NODES[category];
  return (
    <Window title="Data Bank" width={900} height={620} theme="ntos">
      <Window.Content
        fitted={!open}
        style={open ? null : { 'background': '#070c1c' }}>
        {(open && (
          <Detail
            category={category}
            entries={entries}
            picked={picked}
            onPick={id => setPicked(id)}
            onBack={() => {
              setCategory(null);
              setPicked(null);
            }}
          />
        )) || (
          <Overview
            categories={categories}
            onPick={name => {
              setCategory(name);
              setPicked(null);
            }}
          />
        )}
      </Window.Content>
    </Window>
  );
};
