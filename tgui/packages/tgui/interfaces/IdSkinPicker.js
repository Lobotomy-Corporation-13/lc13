import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section } from '../components';
import { Window } from '../layouts';
import { ZoomCard } from './RefractionGachaShop';

const RARITY_COLOUR = {
  '0': '#7a7a7a',
  '00': '#c00000',
  '000': '#d4af37',
};

const RarityBadge = props => {
  const { rarity } = props;
  return (
    <Box
      inline
      px={0.5}
      style={{
        'background': RARITY_COLOUR[rarity] || '#444',
        'color': rarity === '000' ? '#000' : '#fff',
        'font-weight': 'bold',
        'border-radius': '3px',
        'font-size': '10px',
      }}>
      {rarity}
    </Box>
  );
};

// One catalogue tile. Owned skins are click-to-equip with a small
// zoom-in icon button; unowned skins render as a completely black
// silhouette with a "???" name, are not clickable, and don't open
// the zoom view.
const SkinTile = (props, context) => {
  const { act } = useBackend(context);
  const { skin, equipped, isDefault, onZoom } = props;
  const owned = isDefault || (skin && skin.owned);
  const colour = isDefault
    ? '#888'
    : (RARITY_COLOUR[skin && skin.rarity] || '#7a7a7a');
  const id = isDefault ? null : skin.id;
  const onClick = () => {
    if (!owned) return;
    act('equip', { skin_id: id === null ? '' : id });
  };
  const onZoomClick = e => {
    if (e && e.stopPropagation) e.stopPropagation();
    if (!owned || isDefault) return;
    onZoom(skin);
  };
  return (
    <Box
      onClick={onClick}
      style={{
        'position': 'relative',
        'padding': '10px',
        'cursor': owned ? 'pointer' : 'default',
        'border': equipped
          ? '3px solid #d4af37'
          : '2px solid ' + colour,
        'border-radius': '6px',
        'background': equipped
          ? 'linear-gradient(135deg, '
            + '#3a3010 0%, #1a1208 100%)'
          : 'linear-gradient(135deg, '
            + '#1f1f1f 0%, #0a0a0a 100%)',
        'box-shadow': equipped
          ? '0 0 14px #d4af37'
          : '0 0 6px ' + colour + '40',
        'min-width': '120px',
        'text-align': 'center',
        'opacity': owned ? 1 : 0.7,
      }}>
      {!!equipped && (
        <Box
          style={{
            'position': 'absolute',
            'top': '-8px',
            'left': '50%',
            'transform': 'translateX(-50%)',
            'background': '#d4af37',
            'color': '#000',
            'font-weight': 'bold',
            'font-size': '10px',
            'padding': '2px 8px',
            'border-radius': '3px',
            'letter-spacing': '0.5px',
          }}>
          EQUIPPED
        </Box>
      )}
      {!isDefault && !!owned && (
        <Box
          style={{
            'position': 'absolute',
            'top': '4px',
            'right': '4px',
            'z-index': 2,
          }}>
          <Button
            compact
            icon="search-plus"
            tooltip="Zoom in"
            onClick={onZoomClick}
          />
        </Box>
      )}
      <Box mb={0.5} mt={1}>
        {isDefault ? (
          <Box
            style={{
              'width': '64px',
              'height': '64px',
              'margin': '0 auto',
              'border': '1px dashed #555',
              'border-radius': '4px',
              'display': 'flex',
              'align-items': 'center',
              'justify-content': 'center',
              'color': '#777',
              'font-size': '10px',
            }}>
            Default
          </Box>
        ) : (
          <img
            src={'data:image/png;base64,' + skin.icon_data}
            style={{
              'width': '64px',
              'height': '64px',
              'image-rendering': 'pixelated',
              // Mask unowned skins to a flat black silhouette so the
              // contents stay hidden until pulled.
              'filter': owned
                ? null
                : 'brightness(0)',
            }}
          />
        )}
      </Box>
      <Box bold style={{ 'color': owned ? colour : '#555' }}>
        {isDefault ? 'Default ID' : skin.name}
      </Box>
      {!isDefault && (
        <Box mt={0.5}>
          <RarityBadge rarity={skin.rarity} />
          {!!(owned && skin.copies > 1) && (
            <Box
              inline
              ml={0.5}
              color="good"
              style={{ 'font-size': '10px' }}>
              x{skin.copies}
            </Box>
          )}
        </Box>
      )}
    </Box>
  );
};

export const IdSkinPicker = (props, context) => {
  const { data } = useBackend(context);
  const skins = data.skins || [];
  const equipped = data.equipped;
  const equippedSkin = equipped
    ? skins.find(s => s.id === equipped)
    : null;
  const [zoomedSkin, setZoomedSkin]
    = useLocalState(context, 'zoomedSkin', null);
  const ownedCount = skins.filter(s => s.owned).length;
  return (
    <Window width={560} height={520} title="ID Card Skin">
      <Window.Content scrollable>
        <Section title="Currently Equipped">
          <Flex align="center">
            <Flex.Item mr={1}>
              {equippedSkin && equippedSkin.icon_data ? (
                <img
                  src={'data:image/png;base64,'
                    + equippedSkin.icon_data}
                  style={{
                    'width': '48px',
                    'height': '48px',
                    'image-rendering': 'pixelated',
                  }}
                />
              ) : (
                <Box
                  style={{
                    'width': '48px',
                    'height': '48px',
                    'border': '1px dashed #555',
                    'border-radius': '4px',
                    'display': 'flex',
                    'align-items': 'center',
                    'justify-content': 'center',
                    'color': '#777',
                    'font-size': '10px',
                  }}>
                  Default
                </Box>
              )}
            </Flex.Item>
            <Flex.Item grow={1}>
              <Box bold>
                {equippedSkin ? equippedSkin.name : 'Default ID'}
              </Box>
              {equippedSkin && (
                <Box mt={0.5}>
                  <RarityBadge rarity={equippedSkin.rarity} />
                </Box>
              )}
              <Box
                mt={0.5}
                color="label"
                style={{ 'font-size': '11px' }}>
                Worn on your spawned ID card. Cosmetic only —
                access and registered name are unchanged.
              </Box>
            </Flex.Item>
          </Flex>
        </Section>
        <Section
          title={'Catalogue (' + ownedCount + '/'
            + skins.length + ' unlocked)'}>
          <Box
            style={{
              'display': 'grid',
              'grid-template-columns': 'repeat(auto-fill, '
                + 'minmax(140px, 1fr))',
              'gap': '10px',
            }}>
            <SkinTile
              isDefault
              equipped={!equipped}
            />
            {skins.map(s => (
              <SkinTile
                key={s.id}
                skin={s}
                equipped={s.id === equipped}
                onZoom={z => setZoomedSkin(z)}
              />
            ))}
          </Box>
        </Section>
        {!!zoomedSkin && (
          <ZoomCard
            skin={zoomedSkin}
            onClose={() => setZoomedSkin(null)}
          />
        )}
      </Window.Content>
    </Window>
  );
};
