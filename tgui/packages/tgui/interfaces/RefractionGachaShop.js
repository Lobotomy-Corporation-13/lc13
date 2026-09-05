import { Component } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section } from '../components';
import { Window } from '../layouts';

// Stage names for the gacha state machine.
const STAGE_HOME = 'home';
const STAGE_CONFIRM = 'confirm';
const STAGE_CRACK_INTRO = 'crack_intro';
const STAGE_CRACK_BURST = 'crack_burst';
const STAGE_SHOWCASE = 'showcase';
const STAGE_RESULTS = 'results';

const CRACK_INTRO_CLICKS = 4;
const CRACK_BALL_CLICKS = 2;

// Chain length in px from ball center to fracture. The fracture
// sprite sits at this distance, the chain beam grows to match.
const CHAIN_LENGTH = 140;
// Fracture sprite size (rendered down from 96x96).
const FRACTURE_SIZE = 64;

// Animation durations (keep in sync with RefractionGachaShop.scss).
const CHAIN_EXTEND_MS = 500;
// Retract is 2 seconds total: 1s of "tug" (chain at full extension,
// shaking under tension) + 1s of reel-in (chain shrinks to the ball).
const CHAIN_RETRACT_MS = 2000;
// Per-chain mount stagger so the bunch doesn't snap into view all
// at once. Min + random ramp so subsequent runs feel slightly
// different / frantic.
const CHAIN_MOUNT_MIN_MS = 30;
const CHAIN_MOUNT_RAND_MS = 200;
// Bulk-pull stagger between consecutive retract starts.
const BULK_RETRACT_MIN_MS = 80;
const BULK_RETRACT_RAND_MS = 240;
// Per-click ball shake duration (matches the .gacha-ball-shake
// SCSS animation length).
const BALL_SHAKE_MS = 1500;

// After the burst stage first appears, the center ball is locked
// for this long so a player double-clicking on the cracking transition
// doesn't immediately bulk-pull every chain.
const BURST_BALL_COOLDOWN_MS = 1500;

// Stagger between consecutive result-tile fade-ins on the results
// screen. Each tile also fires the idResult SFX.
const RESULT_TILE_STAGGER_MS = 220;

// Fires a whitelisted UI sound via the console's play_sound act.
// Defined once so the trigger sites stay terse.
const playGachaSound = (act, name, volume) => {
  if (!act) return;
  const args = { name: name };
  if (volume !== undefined) args.volume = volume;
  act('play_sound', args);
};

const RARITY_COLOUR = {
  '0': '#7a7a7a',
  '00': '#c00000',
  '000': '#d4af37',
};

// Rarity → fracture-icon bucket name shipped from the DM side.
const FRACTURE_BUCKET = {
  '0': 'gray',
  '00': 'red',
  '000': 'gold',
};

// IMPORTANT: tgui's Box concatenates inline-style keys directly into
// a CSS string with no normalisation, so all multi-word style keys
// MUST be kebab-case strings (e.g. 'border-radius', 'min-height').
// camelCase keys are silently dropped by the browser.

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

// Full-screen preview overlay for a single card — used by both the
// banner inspector and the prefs picker. Renders the card large and
// centred, with click-anywhere-to-dismiss on the dimmed backdrop.
// Exported so the prefs picker can reuse the same look.
export const ZoomCard = props => {
  const { skin, onClose } = props;
  if (!skin) return null;
  const colour = RARITY_COLOUR[skin.rarity] || '#7a7a7a';
  return (
    <Box className="gacha-card-flash" onClick={onClose}>
      <Box
        style={{ 'text-align': 'center' }}
        onClick={e => e.stopPropagation()}>
        <Box
          style={{
            'width': '220px',
            'height': '300px',
            'border': '3px solid ' + colour,
            'background': skin.rarity === '000'
              ? 'linear-gradient(135deg, #d4af37 0%, '
                + '#5a4010 100%)'
              : 'linear-gradient(135deg, #303030 0%, '
                + '#101010 100%)',
            'border-radius': '10px',
            'box-shadow': '0 0 32px ' + colour,
            'margin': '0 auto',
            'display': 'flex',
            'align-items': 'center',
            'justify-content': 'center',
          }}>
          {skin.icon_data ? (
            <img
              src={'data:image/png;base64,' + skin.icon_data}
              style={{
                'width': '180px',
                'height': '180px',
                'image-rendering': 'pixelated',
              }}
            />
          ) : (
            <Box
              bold
              style={{
                'color': skin.rarity === '000' ? '#000' : '#fff',
                'font-size': '24px',
              }}>
              ID
            </Box>
          )}
        </Box>
        <Box
          mt={1}
          bold
          style={{ 'color': colour, 'font-size': '14px' }}>
          {skin.name}
        </Box>
        <Box mt={0.5}>
          <RarityBadge rarity={skin.rarity} />
        </Box>
        <Box
          mt={1.5}
          style={{ 'font-size': '10px' }}
          color="label"
          onClick={onClose}>
          Click anywhere to close.
        </Box>
      </Box>
    </Box>
  );
};

// Inspector window for one banner — opens off the magnifying-glass
// button. Tiles for every highlight on the banner, click-to-zoom by
// default, plus a "Claim" button on each tile when the banner's pity
// has capped out.
const InspectorOverlay = (props, context) => {
  const { act } = useBackend(context);
  const {
    banner,
    pity,
    pityThreshold,
    onClose,
    onZoom,
    onClaim,
  } = props;
  const skins = banner.skins || [];
  const canClaim = pity >= pityThreshold;
  return (
    <Box
      position="fixed"
      top={0}
      left={0}
      right={0}
      bottom={0}
      backgroundColor="rgba(0, 0, 0, 0.7)"
      style={{ 'z-index': 40 }}
      onClick={onClose}>
      <Box
        position="fixed"
        top="50%"
        left="50%"
        width="560px"
        style={{
          'transform': 'translate(-50%, -50%)',
          'background': 'linear-gradient(180deg, '
            + '#1a1a1a 0%, #0a0a0a 100%)',
          'border': '2px solid ' + (banner.color || '#555'),
          'border-radius': '8px',
          'padding': '14px',
          'max-height': '80vh',
          'overflow-y': 'auto',
          'box-shadow': '0 0 32px rgba(0, 0, 0, 0.8)',
        }}
        onClick={e => e.stopPropagation()}>
        <Box
          mb={1}
          bold
          style={{
            'font-size': '14px',
            'text-align': 'center',
            'color': banner.color || '#fff',
          }}>
          {banner.name} — Featured Skins
        </Box>
        <Box
          mb={1}
          style={{ 'text-align': 'center', 'font-size': '11px' }}
          color={canClaim ? 'good' : 'label'}>
          Pity: {pity}/{pityThreshold}
          {!!canClaim && (
            <Box inline ml={0.5} bold>
              — Claim a featured skin for free.
            </Box>
          )}
        </Box>
        <Box
          style={{
            'display': 'grid',
            'grid-template-columns':
              'repeat(auto-fill, minmax(150px, 1fr))',
            'gap': '10px',
          }}>
          {skins.map(s => {
            const colour = RARITY_COLOUR[s.rarity] || '#7a7a7a';
            return (
              <Box
                key={s.id}
                onClick={() => onZoom(s)}
                style={{
                  'position': 'relative',
                  'padding': '8px',
                  'border': '2px solid ' + colour,
                  'border-radius': '6px',
                  'background': 'linear-gradient(135deg, '
                    + '#1f1f1f 0%, #0a0a0a 100%)',
                  'cursor': 'pointer',
                  'text-align': 'center',
                  'box-shadow': '0 0 6px ' + colour + '40',
                }}>
                {s.icon_data && (
                  <Box mb={0.5}>
                    <img
                      src={'data:image/png;base64,' + s.icon_data}
                      style={{
                        'width': '64px',
                        'height': '64px',
                        'image-rendering': 'pixelated',
                      }}
                    />
                  </Box>
                )}
                <Box bold style={{ 'color': colour }}>
                  {s.name}
                </Box>
                <Box mt={0.5}>
                  <RarityBadge rarity={s.rarity} />
                  <Box
                    inline
                    ml={0.5}
                    bold
                    color={s.owned ? 'good' : 'label'}>
                    {s.owned ? 'Owned' : 'Missing'}
                  </Box>
                </Box>
                {!!canClaim && (
                  <Box mt={0.5}>
                    <Button
                      fluid
                      color="good"
                      icon="gift"
                      content="Claim"
                      onClick={e => {
                        if (e && e.stopPropagation) e.stopPropagation();
                        onClaim(s);
                      }}
                    />
                  </Box>
                )}
              </Box>
            );
          })}
        </Box>
        <Flex justify="center" mt={1}>
          <Flex.Item>
            <Button
              icon="times"
              content="Close"
              onClick={onClose}
            />
          </Flex.Item>
        </Flex>
      </Box>
    </Box>
  );
};

// ---------- Home / banner select ----------
const HomeView = (props, context) => {
  const { act, data } = useBackend(context);
  const balance = data.balance || 0;
  const banners = data.banners || [];
  const pull_costs = data.pull_costs || { single: 50, ten: 500 };
  const pity = data.pity || {};
  const pityThreshold = data.pity_threshold || 100;
  const [selectedBannerIdx, setSelectedBannerIdx]
    = useLocalState(context, 'banner', 0);
  const [, setStage] = useLocalState(context, 'stage', STAGE_HOME);
  const [, setPendingCount]
    = useLocalState(context, 'pendingCount', 1);
  const [, setConfirmReturn]
    = useLocalState(context, 'confirmReturn', STAGE_HOME);
  const [inspectorOpen, setInspectorOpen]
    = useLocalState(context, 'inspectorOpen', false);
  const [zoomedSkin, setZoomedSkin]
    = useLocalState(context, 'zoomedSkin', null);
  const banner = banners[selectedBannerIdx] || banners[0];
  if (!banner) {
    return (
      <Section>
        <Box color="label">No banners available.</Box>
      </Section>
    );
  }
  const skins = banner.skins || [];
  const cantOne = balance < pull_costs.single;
  const cantTen = balance < pull_costs.ten;
  const bannerPity = pity[banner.id] || 0;
  const pityFull = bannerPity >= pityThreshold;
  const startPull = count => {
    setPendingCount(count);
    setConfirmReturn(STAGE_HOME);
    setStage(STAGE_CONFIRM);
  };
  const claimSkin = s => {
    act('redeem_pity', { banner_id: banner.id, skin_id: s.id });
    setInspectorOpen(false);
    setZoomedSkin(null);
    setPendingCount(1);
    setStage(STAGE_RESULTS);
  };
  return (
    <Flex>
      <Flex.Item style={{ 'min-width': '200px' }}>
        <Section title="Banners">
          {banners.map((b, idx) => (
            <Box
              key={b.id}
              p={1}
              mb={0.5}
              onClick={() => setSelectedBannerIdx(idx)}
              style={{
                'cursor': 'pointer',
                'border-left': '4px solid ' + (b.color || '#888'),
                'background': idx === selectedBannerIdx
                  ? 'rgba(255,255,255,0.08)'
                  : 'rgba(255,255,255,0.02)',
                'border-radius': '4px',
              }}>
              <Box bold>{b.name}</Box>
              <Box
                style={{ 'font-size': '10px' }}
                color="label">
                {(b.skins || []).length} skin
                {(b.skins || []).length === 1 ? '' : 's'}
              </Box>
            </Box>
          ))}
        </Section>
      </Flex.Item>
      <Flex.Item grow={1} ml={1}>
        <Section
          title={banner.name}
          buttons={
            <Button
              icon="search-plus"
              content="Inspect"
              tooltip="Browse highlight skins / claim pity"
              onClick={() => setInspectorOpen(true)}
            />
          }>
          {/* Chain ball with the banner's skins orbiting around it. */}
          <Box
            mb={1}
            style={{
              'width': '100%',
              'height': '260px',
              'background': 'radial-gradient('
                + 'circle at center, #3a1a14 0%, '
                + '#0d0303 70%, #000 100%)',
              'border-radius': '6px',
              'position': 'relative',
              'overflow': 'hidden',
            }}>
            {/* Centred ball. Outer wrapper handles centering so the
                breath animation only owns scale. */}
            <Box
              style={{
                'position': 'absolute',
                'top': '50%',
                'left': '50%',
                'transform': 'translate(-50%, -50%)',
              }}>
              <Box
                className="gacha-ball-breathe"
                style={{
                  'width': '110px',
                  'height': '110px',
                  'border-radius': '50%',
                  'background': 'radial-gradient(circle, '
                    + (banner.color || '#c04020') + ' 0%, '
                    + '#5a1810 55%, #1a0808 100%)',
                  'box-shadow': '0 0 28px '
                    + (banner.color || '#c04020'),
                }}
              />
            </Box>
            {/* Orbit wrapper rotates the children; each inner image
                counter-rotates so icons stay upright. */}
            <Box className="gacha-orbit">
              {skins.map((s, i) => {
                const angle = (i / skins.length) * Math.PI * 2
                  - Math.PI / 2;
                const radius = 90;
                const x = Math.round(Math.cos(angle) * radius);
                const y = Math.round(Math.sin(angle) * radius);
                return (
                  <Box
                    key={s.id}
                    className="gacha-orbit-slot"
                    style={{
                      'left': x + 'px',
                      'top': y + 'px',
                      'border': '1px solid '
                        + (RARITY_COLOUR[s.rarity] || '#888'),
                      'box-shadow': '0 0 10px '
                        + (RARITY_COLOUR[s.rarity] || '#444'),
                    }}>
                    {s.icon_data ? (
                      <img
                        className="gacha-orbit-img"
                        src={'data:image/png;base64,'
                          + s.icon_data}
                      />
                    ) : (
                      <Box
                        style={{
                          'width': '20px',
                          'height': '20px',
                          'background': RARITY_COLOUR[s.rarity]
                            || '#888',
                          'border-radius': '3px',
                        }}
                      />
                    )}
                  </Box>
                );
              })}
            </Box>
          </Box>
          <Box
            mb={1}
            style={{ 'font-size': '11px' }}
            color="label">
            Featured skins — every 000 you pull here is one of these;
            lower tiers get a 2x rate-up on top of the base pool.
          </Box>
          <Box mb={1}>
            {skins.map(s => (
              <Box
                key={s.id}
                inline
                p={0.5}
                mr={0.5}
                style={{
                  'border': '1px solid '
                    + (RARITY_COLOUR[s.rarity] || '#888'),
                  'border-radius': '3px',
                  'opacity': s.owned ? 1 : 0.55,
                }}>
                <RarityBadge rarity={s.rarity} />
                <Box inline ml={0.5}>{s.name}</Box>
                <Box
                  inline
                  ml={0.5}
                  bold
                  color={s.owned ? 'good' : 'label'}>
                  {s.owned ? 'Owned' : 'Missing'}
                </Box>
              </Box>
            ))}
          </Box>
          <Flex>
            <Flex.Item grow={1} mr={0.5}>
              <Button
                fluid
                disabled={cantOne}
                color={cantOne ? null : 'average'}
                content={'Extract 1 (' + pull_costs.single + ')'}
                onClick={() => startPull(1)}
              />
            </Flex.Item>
            <Flex.Item grow={1}>
              <Button
                fluid
                disabled={cantTen}
                color={cantTen ? null : 'good'}
                content={'Extract 10 (' + pull_costs.ten + ')'}
                onClick={() => startPull(10)}
              />
            </Flex.Item>
          </Flex>
          {/* Pity meter — flips bright + actionable when capped. */}
          <Box
            mt={1}
            style={{
              'text-align': 'center',
              'font-size': '11px',
              'padding': '4px',
              'border-radius': '3px',
              'background': pityFull
                ? 'rgba(34, 197, 94, 0.15)'
                : 'rgba(255, 255, 255, 0.04)',
            }}
            color={pityFull ? 'good' : 'label'}>
            Pity: <b>{bannerPity}/{pityThreshold}</b>
            {!!pityFull && (
              <Box inline ml={0.5} bold>
                — open Inspect to claim a featured skin.
              </Box>
            )}
          </Box>
        </Section>
      </Flex.Item>
      {!!inspectorOpen && (
        <InspectorOverlay
          banner={banner}
          pity={bannerPity}
          pityThreshold={pityThreshold}
          onClose={() => setInspectorOpen(false)}
          onZoom={s => setZoomedSkin(s)}
          onClaim={claimSkin}
        />
      )}
      {!!zoomedSkin && (
        <ZoomCard
          skin={zoomedSkin}
          onClose={() => setZoomedSkin(null)}
        />
      )}
    </Flex>
  );
};

// ---------- Confirm modal (overlay on top of the underlying view) --
const ConfirmOverlay = (props, context) => {
  const { act, data } = useBackend(context);
  const balance = data.balance || 0;
  const banners = data.banners || [];
  const pull_costs = data.pull_costs || { single: 50, ten: 500 };
  const [selectedBannerIdx]
    = useLocalState(context, 'banner', 0);
  const [pendingCount]
    = useLocalState(context, 'pendingCount', 1);
  const [, setStage] = useLocalState(context, 'stage', STAGE_HOME);
  const [confirmReturn]
    = useLocalState(context, 'confirmReturn', STAGE_HOME);
  const [, setClicks] = useLocalState(context, 'crackClicks', 0);
  const [, setRevealed]
    = useLocalState(context, 'revealed', []);
  const [, setBallClicks]
    = useLocalState(context, 'ballClicks', 0);
  const [, setShowcaseIdx]
    = useLocalState(context, 'showcaseIdx', 0);
  const [, setShowcaseIndices]
    = useLocalState(context, 'showcaseIndices', null);
  const banner = banners[selectedBannerIdx] || banners[0];
  if (!banner) return null;
  const cost = pendingCount === 10
    ? pull_costs.ten
    : pull_costs.single;
  const insufficient = balance < cost;
  const cancel = () => setStage(confirmReturn);
  const confirm = () => {
    if (confirmReturn === STAGE_RESULTS) {
      act('ack_pull');
    }
    setClicks(0);
    setRevealed([]);
    setBallClicks(0);
    setShowcaseIdx(0);
    setShowcaseIndices(null);
    act('pull', {
      banner_id: banner.id,
      count: pendingCount,
    });
    setStage(STAGE_CRACK_INTRO);
  };
  return (
    <Box
      position="fixed"
      top={0}
      left={0}
      right={0}
      bottom={0}
      backgroundColor="rgba(0, 0, 0, 0.7)"
      style={{ 'z-index': 50 }}
      onClick={cancel}>
      <Box
        position="fixed"
        top="50%"
        left="50%"
        width="420px"
        style={{
          'transform': 'translate(-50%, -50%)',
          'background': 'linear-gradient(180deg, '
            + '#1a1a1a 0%, #0a0a0a 100%)',
          'border': '2px solid #555',
          'border-radius': '8px',
          'padding': '18px',
          'box-shadow': '0 0 32px rgba(0, 0, 0, 0.8)',
        }}
        onClick={e => e.stopPropagation()}>
        <Box
          mb={1}
          bold
          style={{
            'font-size': '14px',
            'text-align': 'center',
            'color': '#d4af37',
          }}>
          Proceeding with Extraction
        </Box>
        <Box mb={1} style={{ 'text-align': 'center' }}>
          Spend <b>{cost} Starlight</b> to do an Extract
          {' '}{pendingCount} on <b>{banner.name}</b>?
        </Box>
        {!!insufficient && (
          <Box
            mb={1}
            color="bad"
            bold
            style={{ 'text-align': 'center' }}>
            Insufficient Starlight (need {cost}, have {balance}).
          </Box>
        )}
        <Flex mt={1}>
          <Flex.Item grow={1} mr={0.5}>
            <Button
              fluid
              icon="times"
              content="Cancel"
              onClick={cancel}
            />
          </Flex.Item>
          <Flex.Item grow={1}>
            <Button
              fluid
              icon="check"
              color="good"
              disabled={insufficient}
              content="Confirm"
              onClick={confirm}
            />
          </Flex.Item>
        </Flex>
      </Box>
    </Box>
  );
};

// ---------- Crack intro (click ball to crack) ----------
const CrackIntroView = (props, context) => {
  const { act, data } = useBackend(context);
  const pending_pull = data.pending_pull || [];
  const [, setStage] = useLocalState(context, 'stage', STAGE_HOME);
  const waiting = pending_pull.length === 0;
  const visibleGoldRoll = pending_pull.some(
    p => p.rarity === '000' && !p.stealth_lucky);
  return (
    <CrackIntroCanvas
      act={act}
      waiting={waiting}
      visibleGoldRoll={visibleGoldRoll}
      onCrack={() => setStage(STAGE_CRACK_BURST)}
    />
  );
};

class CrackIntroCanvas extends Component {
  constructor(props) {
    super(props);
    this.state = {
      clicks: 0,
      shaking: false,
    };
    this.shakeTimer = null;
    this.handleClick = this.handleClick.bind(this);
  }
  componentDidMount() {
    // First-ball-appears moment when the player has just spent SL.
    playGachaSound(this.props.act, 'start');
  }
  componentWillUnmount() {
    if (this.shakeTimer) clearTimeout(this.shakeTimer);
    this.shakeTimer = null;
  }
  handleClick() {
    if (this.props.waiting) return;
    let next;
    let willCrack = false;
    this.setState(s => {
      next = s.clicks + 1;
      if (next >= CRACK_INTRO_CLICKS) {
        willCrack = true;
        return null;
      }
      return { clicks: next, shaking: true };
    });
    if (willCrack) {
      playGachaSound(this.props.act, 'coreBoom');
      this.props.onCrack();
      return;
    }
    playGachaSound(this.props.act, 'coreClick');
    if (this.shakeTimer) clearTimeout(this.shakeTimer);
    this.shakeTimer = setTimeout(() => {
      this.setState({ shaking: false });
      this.shakeTimer = null;
    }, BALL_SHAKE_MS);
  }
  render() {
    const { waiting, visibleGoldRoll } = this.props;
    const { clicks, shaking } = this.state;
    // Use a key bound to the click count so each press tears down
    // the outer wrapper and restarts the shake animation from frame
    // zero — otherwise a second click during an existing shake
    // wouldn't visibly re-shake.
    const shakeKey = 'shake-' + clicks;
    return (
      <Box
        className="gacha-enter"
        style={{
          'width': '100%',
          'min-height': '500px',
          'background': visibleGoldRoll
            ? 'radial-gradient(circle at center, '
              + '#5a4a10 0%, #1a1208 70%, #000 100%)'
            : 'radial-gradient(circle at center, '
              + '#5a1810 0%, #1a0808 70%, #000 100%)',
          'position': 'relative',
          'cursor': waiting ? 'wait' : 'pointer',
        }}
        onClick={this.handleClick}>
        <Box
          key={shakeKey}
          className={shaking ? 'gacha-ball-shake' : ''}
          style={{
            'position': 'absolute',
            'top': '50%',
            'left': '50%',
            'transform': 'translate(-50%, -50%)',
          }}>
          <Box
            style={{
              'width': '180px',
              'height': '180px',
              'border-radius': '50%',
              'background': visibleGoldRoll
                ? 'radial-gradient(circle, #d4af37 0%, '
                  + '#5a4010 50%, #1a1208 100%)'
                : 'radial-gradient(circle, #c04020 0%, '
                  + '#5a1810 50%, #1a0808 100%)',
              'box-shadow': visibleGoldRoll
                ? '0 0 40px #d4af37'
                : '0 0 24px #c04020',
            }}
          />
        </Box>
      </Box>
    );
  }
}

// ---------- Crack burst (interact with fractures) ----------
// Wrapper functional component reads ui_data + drives stage
// transitions. The actual chain state machine lives in the inner
// class component so we can use setTimeout + componentWillUnmount
// for proper timer cleanup and stable state-updater semantics.
const CrackBurstView = (props, context) => {
  const { act, data } = useBackend(context);
  const pending_pull = data.pending_pull || [];
  const fracture_icons = data.fracture_icons || {};
  const [, setStage] = useLocalState(context, 'stage', STAGE_HOME);
  const [, setShowcaseIndices]
    = useLocalState(context, 'showcaseIndices', null);
  const visibleGoldRoll = pending_pull.some(
    p => p.rarity === '000' && !p.stealth_lucky);
  const onFinish = bulkRetractedIndices => {
    // Showcase plays only the chains the user pulled via the ball;
    // individually-clicked chains were already flashed inline. If
    // every chain was individually clicked, the bulk list is empty
    // and the showcase has nothing left to show → jump straight to
    // the results screen.
    if (!bulkRetractedIndices || !bulkRetractedIndices.length) {
      setShowcaseIndices([]);
      setStage(STAGE_RESULTS);
      return;
    }
    setShowcaseIndices(bulkRetractedIndices.slice());
    setStage(STAGE_SHOWCASE);
  };
  return (
    <CrackBurstCanvas
      act={act}
      pending_pull={pending_pull}
      fracture_icons={fracture_icons}
      visibleGoldRoll={visibleGoldRoll}
      onFinish={onFinish}
    />
  );
};

class CrackBurstCanvas extends Component {
  constructor(props) {
    super(props);
    const total = (props.pending_pull || []).length;
    this.state = {
      // 'extending' | 'present' | 'retracting' | 'revealed'
      chainStates: new Array(total).fill('extending'),
      // indices that the ball-bulk-pull retracted (drives showcase).
      bulkRetractedIndices: [],
      // FIFO queue of chain indices whose cards still need to be
      // flashed. The render shows queue[0] as the current overlay;
      // dismissing pops the head. Clicking multiple chains while
      // one is retracting just appends; each new card surfaces in
      // click order after the player dismisses the prior one.
      flashQueue: [],
      hoverIdx: null,
      ballClicks: 0,
      // Counter for the ball-click shake animation. Bumped on each
      // press; bound to a `key` prop so React restarts the animation
      // from frame zero even when consecutive clicks land inside
      // the previous shake window.
      ballShakeId: 0,
      ballShaking: false,
      // Mount cooldown — the center ball ignores clicks for the
      // first BURST_BALL_COOLDOWN_MS so the player can't immediately
      // bulk-pull on the same press that cracked the intro ball.
      ballLocked: true,
      finished: false,
    };
    this.ballShakeTimer = null;
    this.ballLockTimer = null;
    // Per-chain stagger delays so the burst doesn't snap in all at
    // once; lightly randomised for a frantic feel.
    this.extendDelays = [];
    for (let i = 0; i < total; i++) {
      this.extendDelays.push(
        CHAIN_MOUNT_MIN_MS + Math.random() * CHAIN_MOUNT_RAND_MS);
    }
    this.timers = [];
    this.handleBallClick = this.handleBallClick.bind(this);
    this.handleCardClick = this.handleCardClick.bind(this);
  }
  componentDidMount() {
    this.state.chainStates.forEach((_, i) => {
      const t = setTimeout(() => {
        let transitioned = false;
        this.setState(s => {
          if (s.chainStates[i] !== 'extending') return null;
          transitioned = true;
          const next = s.chainStates.slice();
          next[i] = 'present';
          return { chainStates: next };
        });
        // Fracture lands → play the per-fracture SFX. Skip if the
        // state had already moved on (component teardown race).
        if (transitioned) {
          playGachaSound(this.props.act, 'makeFracture');
        }
      }, this.extendDelays[i] + CHAIN_EXTEND_MS);
      this.timers.push(t);
    });
    // Cooldown the center ball for the post-mount window.
    this.ballLockTimer = setTimeout(() => {
      this.setState({ ballLocked: false });
      this.ballLockTimer = null;
    }, BURST_BALL_COOLDOWN_MS);
  }
  componentWillUnmount() {
    this.timers.forEach(t => clearTimeout(t));
    this.timers = [];
    if (this.ballShakeTimer) clearTimeout(this.ballShakeTimer);
    this.ballShakeTimer = null;
    if (this.ballLockTimer) clearTimeout(this.ballLockTimer);
    this.ballLockTimer = null;
  }
  triggerBallShake() {
    this.setState(s => ({
      ballShakeId: s.ballShakeId + 1,
      ballShaking: true,
    }));
    if (this.ballShakeTimer) clearTimeout(this.ballShakeTimer);
    this.ballShakeTimer = setTimeout(() => {
      this.setState({ ballShaking: false });
      this.ballShakeTimer = null;
    }, BALL_SHAKE_MS);
  }
  retractChain(idx, isFromBulk) {
    let started = false;
    this.setState(s => {
      if (s.chainStates[idx] !== 'present') return null;
      started = true;
      const next = s.chainStates.slice();
      next[idx] = 'retracting';
      return { chainStates: next };
    });
    if (!started) return;
    // Chain begins its 1s tug + 1s reel — fire the pullback SFX now
    // so the audio lines up with the start of the tug.
    playGachaSound(this.props.act, 'chainPullback');
    const t = setTimeout(() => {
      this.setState(s => {
        const next = s.chainStates.slice();
        next[idx] = 'revealed';
        const upd = { chainStates: next };
        if (isFromBulk) {
          upd.bulkRetractedIndices
            = s.bulkRetractedIndices.concat([idx]);
        } else {
          // Append to the flash queue — clicking more chains while
          // one was being pulled back simply appends them in click
          // order, and the player works through the stack one card
          // at a time.
          upd.flashQueue = s.flashQueue.concat([idx]);
        }
        return upd;
      });
      // 000 reveal trumpet — only on individual reveals here; the
      // showcase fires its own 000 sound when bulk-pulled cards roll
      // through the parade.
      if (!isFromBulk) {
        const p = this.props.pending_pull[idx];
        if (p && p.rarity === '000') {
          playGachaSound(this.props.act, 'got_000', 80);
        }
      }
    }, CHAIN_RETRACT_MS);
    this.timers.push(t);
  }
  handleChainClick(idx) {
    // Multiple chains can be in flight simultaneously — each click
    // just starts that chain's retract; the flash queue serialises
    // the resulting cards after the player dismisses each one.
    if (this.state.chainStates[idx] !== 'present') return;
    this.retractChain(idx, false);
  }
  handleBallClick() {
    if (this.state.ballLocked) return;
    if (this.state.flashQueue.length > 0) return;
    if (this.state.finished) return;
    playGachaSound(this.props.act, 'coreClick');
    this.triggerBallShake();
    let newBC;
    this.setState(s => {
      newBC = s.ballClicks + 1;
      return { ballClicks: newBC };
    });
    if (newBC < CRACK_BALL_CLICKS) return;
    const presentIndices = this.state.chainStates
      .map((s, i) => (s === 'present' ? i : -1))
      .filter(i => i !== -1);
    if (!presentIndices.length) {
      this.finish();
      return;
    }
    let cumulative = 0;
    presentIndices.forEach(i => {
      cumulative
        += BULK_RETRACT_MIN_MS + Math.random() * BULK_RETRACT_RAND_MS;
      const t = setTimeout(() => {
        this.retractChain(i, true);
      }, cumulative);
      this.timers.push(t);
    });
    const tailMs = cumulative + CHAIN_RETRACT_MS + 220;
    const t = setTimeout(() => this.finish(), tailMs);
    this.timers.push(t);
  }
  handleCardClick() {
    this.setState(s => ({ flashQueue: s.flashQueue.slice(1) }), () => {
      // After the head pops, if the queue is empty AND every chain
      // has been revealed (no remaining work for the player), fall
      // through to the wrapper's "no bulk pulls → skip showcase"
      // path. Otherwise the next queued flash renders automatically.
      if (this.state.flashQueue.length === 0
          && this.state.chainStates.every(st => st === 'revealed')) {
        this.finish();
      }
    });
  }
  setHover(idx) {
    if (this.state.hoverIdx !== idx) {
      this.setState({ hoverIdx: idx });
    }
  }
  finish() {
    if (this.state.finished) return;
    this.setState({ finished: true });
    this.props.onFinish(this.state.bulkRetractedIndices);
  }
  render() {
    const {
      pending_pull,
      fracture_icons,
      visibleGoldRoll,
    } = this.props;
    const {
      chainStates,
      flashQueue,
      hoverIdx,
      ballShakeId,
      ballShaking,
      ballLocked,
    } = this.state;
    const flashIdx = flashQueue.length > 0 ? flashQueue[0] : null;
    const total = pending_pull.length;
    const displayRarity = p => (
      p.rarity === '000' && p.stealth_lucky ? '0' : p.rarity
    );
    const angleFor = idx => (
      (idx / total) * 2 * Math.PI - Math.PI / 2
    );
    return (
      <Box
        className="gacha-enter"
        style={{
          'width': '100%',
          'min-height': '500px',
          'background': visibleGoldRoll
            ? 'radial-gradient(circle, #5a4a10 0%, '
              + '#1a1208 70%, #000 100%)'
            : 'radial-gradient(circle, #5a1810 0%, '
              + '#1a0808 70%, #000 100%)',
          'position': 'relative',
        }}>
        {/* Chain beams underneath the ball + fractures. */}
        {pending_pull.map((p, idx) => {
          const state = chainStates[idx];
          if (state === 'revealed') return null;
          const angle = angleFor(idx);
          const angleDeg = (angle * 180 / Math.PI).toFixed(2);
          const r = displayRarity(p);
          const colour = RARITY_COLOUR[r] || '#7a7a7a';
          let cls = 'gacha-chain-beam';
          if (state === 'extending') cls += ' gacha-chain-extend';
          else if (state === 'retracting') cls += ' gacha-chain-retract';
          else if (state === 'present') cls += ' gacha-chain-present';
          if (state === 'present' && hoverIdx === idx) {
            cls += ' gacha-chain-shake';
          }
          const inlineStyle = {
            'width': CHAIN_LENGTH + 'px',
            'background': 'linear-gradient(90deg, '
              + colour + ' 0%, '
              + colour + '88 60%, '
              + 'transparent 100%)',
            'box-shadow': '0 0 6px ' + colour,
            '--chain-angle': angleDeg + 'deg',
          };
          if (state === 'extending') {
            inlineStyle['animation-delay']
              = this.extendDelays[idx].toFixed(0) + 'ms';
          }
          return (
            <Box key={'beam-' + idx} className={cls} style={inlineStyle} />
          );
        })}
        {/* Centre ball — click to bulk-pull remaining chains. The
            `key` on the wrapper restarts the SCSS shake on each
            press; the inner ball carries the visual styling.
            `ballLocked` greys out the cursor for the post-mount
            cooldown so the player can't accidentally double-click
            into a bulk pull on the same press that cracked the
            intro ball. */}
        <Box
          key={'ball-' + ballShakeId}
          className={ballShaking ? 'gacha-ball-shake' : ''}
          onClick={this.handleBallClick}
          style={{
            'position': 'absolute',
            'top': '50%',
            'left': '50%',
            'transform': 'translate(-50%, -50%)',
            'z-index': 3,
            'cursor': ballLocked ? 'wait' : 'pointer',
          }}>
          <Box
            style={{
              'width': '140px',
              'height': '140px',
              'border-radius': '50%',
              'background': visibleGoldRoll
                ? 'radial-gradient(circle, #d4af37 0%, '
                  + '#5a4010 50%, #1a1208 100%)'
                : 'radial-gradient(circle, #c04020 0%, '
                  + '#5a1810 50%, #1a0808 100%)',
              'box-shadow': visibleGoldRoll
                ? '0 0 32px #d4af37'
                : '0 0 24px #c04020',
            }}
          />
        </Box>
        {/* Fracture sprites at the end of each chain. */}
        {pending_pull.map((p, idx) => {
          const state = chainStates[idx];
          if (state === 'extending' || state === 'revealed') return null;
          const angle = angleFor(idx);
          const x = Math.cos(angle) * CHAIN_LENGTH;
          const y = Math.sin(angle) * CHAIN_LENGTH;
          const r = displayRarity(p);
          const bucket = FRACTURE_BUCKET[r] || 'gray';
          const sprite = fracture_icons[bucket];
          const colour = RARITY_COLOUR[r] || '#7a7a7a';
          const hovered = hoverIdx === idx;
          let cls = 'gacha-fracture-box';
          if (state === 'present') cls += ' gacha-fracture-pop';
          else if (state === 'retracting') {
            cls += ' gacha-fracture-retracting';
          }
          return (
            <Box
              key={'frac-' + idx}
              className={cls}
              onClick={() => this.handleChainClick(idx)}
              onMouseEnter={() => this.setHover(idx)}
              onMouseLeave={() => this.setHover(null)}
              style={{
                'position': 'absolute',
                'top': 'calc(50% + ' + y.toFixed(2) + 'px)',
                'left': 'calc(50% + ' + x.toFixed(2) + 'px)',
                'transform': 'translate(-50%, -50%)'
                  + (hovered ? ' scale(1.08)' : ''),
                'width': FRACTURE_SIZE + 'px',
                'height': FRACTURE_SIZE + 'px',
                'cursor': state === 'present' ? 'pointer' : 'default',
                'z-index': 2,
                'box-shadow': hovered
                  ? '0 0 24px ' + colour + ', 0 0 8px #fff'
                  : '0 0 10px ' + colour,
              }}>
              {sprite ? (
                <img
                  src={'data:image/png;base64,' + sprite}
                  style={{
                    'width': '100%',
                    'height': '100%',
                    'image-rendering': 'pixelated',
                  }}
                />
              ) : (
                <Box
                  style={{
                    'width': '100%',
                    'height': '100%',
                    'border-radius': '50%',
                    'background': 'radial-gradient(circle, '
                      + colour + ' 0%, #000 100%)',
                  }}
                />
              )}
            </Box>
          );
        })}
        {flashIdx !== null && pending_pull[flashIdx] && (
          <FlashCard
            p={pending_pull[flashIdx]}
            onClick={this.handleCardClick}
          />
        )}
      </Box>
    );
  }
}

// Card overlay shown when a single chain is pulled back. Click
// anywhere on the dimmed backdrop to dismiss it.
const FlashCard = props => {
  const { p, onClick } = props;
  const colour = RARITY_COLOUR[p.rarity] || '#7a7a7a';
  const isGoldenSparkle = p.rarity === '000' && p.stealth_lucky;
  return (
    <Box className="gacha-card-flash" onClick={onClick}>
      <Box style={{ 'text-align': 'center' }}>
        <Box
          style={{
            'width': '180px',
            'height': '240px',
            'border': '3px solid ' + colour,
            'background': p.rarity === '000'
              ? 'linear-gradient(135deg, #d4af37 0%, '
                + '#5a4010 100%)'
              : 'linear-gradient(135deg, #303030 0%, '
                + '#101010 100%)',
            'border-radius': '8px',
            'box-shadow': '0 0 24px ' + colour,
            'margin': '0 auto',
            'display': 'flex',
            'align-items': 'center',
            'justify-content': 'center',
          }}>
          {p.icon_data ? (
            <img
              src={'data:image/png;base64,' + p.icon_data}
              style={{
                'width': '128px',
                'height': '128px',
                'image-rendering': 'pixelated',
              }}
            />
          ) : (
            <Box
              bold
              style={{
                'color': p.rarity === '000' ? '#000' : '#fff',
                'font-size': '20px',
              }}>
              ID
            </Box>
          )}
        </Box>
        <Box mt={1} bold style={{ 'color': colour }}>
          {p.name || p.skin_id}
        </Box>
        <Box>
          <RarityBadge rarity={p.rarity} />
          {!!isGoldenSparkle && (
            <Box inline ml={0.5} color="good" bold>
              Stealth!
            </Box>
          )}
          {!!p.was_duplicate && (
            <Box inline ml={0.5} color="label">
              (duplicate, +{p.dupe_refund})
            </Box>
          )}
        </Box>
        <Box
          mt={2}
          style={{ 'font-size': '10px' }}
          color="label">
          Click anywhere to dismiss.
        </Box>
      </Box>
    </Box>
  );
};

// ---------- One-by-one showcase ----------
// Wrapper resolves the order list + handles stage transitions; the
// inner class runs componentDidMount so the initial card can fire
// got_000 too (covers the edge case where the very first showcase
// card is a 000 — e.g. an all-000 bulk pull).
const ShowcaseView = (props, context) => {
  const { act, data } = useBackend(context);
  const pending_pull = data.pending_pull || [];
  const [idx, setIdx]
    = useLocalState(context, 'showcaseIdx', 0);
  const [showcaseIndices]
    = useLocalState(context, 'showcaseIndices', null);
  const [, setStage] = useLocalState(context, 'stage', STAGE_HOME);
  // showcaseIndices is set by the burst stage to the list of chains
  // pulled via the ball (skipping the ones the user already saw via
  // single-click flashes). Null means "no burst happened yet" — fall
  // back to showing the entire pull.
  const baseIndices = (showcaseIndices && showcaseIndices.length)
    ? showcaseIndices
    : pending_pull.map((_, i) => i);
  const order = baseIndices
    .map(i => ({ p: pending_pull[i], i: i }))
    .filter(o => o.p)
    .sort((a, b) => {
      const ra = a.p.rarity === '000' ? 1 : 0;
      const rb = b.p.rarity === '000' ? 1 : 0;
      return ra - rb;
    });
  const safeIdx = Math.min(Math.max(idx, 0), order.length - 1);
  const current = order[safeIdx];
  if (!current) {
    return (
      <Section>
        <Box color="label">Loading extraction results...</Box>
      </Section>
    );
  }
  const onAdvance = () => {
    if (safeIdx + 1 >= order.length) {
      setStage(STAGE_RESULTS);
    } else {
      const nextIdx = safeIdx + 1;
      const nextCard = order[nextIdx] && order[nextIdx].p;
      if (nextCard && nextCard.rarity === '000') {
        playGachaSound(act, 'got_000', 80);
      }
      setIdx(nextIdx);
    }
  };
  return (
    <ShowcaseCanvas
      act={act}
      current={current}
      total={order.length}
      currentIdx={safeIdx}
      onAdvance={onAdvance}
    />
  );
};

class ShowcaseCanvas extends Component {
  componentDidMount() {
    // First card the player sees in the showcase. If it's a 000,
    // fire the trumpet — onAdvance handles all subsequent 000s.
    const { current } = this.props;
    if (current && current.p && current.p.rarity === '000') {
      playGachaSound(this.props.act, 'got_000', 80);
    }
  }
  render() {
    const { current, total, currentIdx, onAdvance } = this.props;
    const p = current.p;
    const colour = RARITY_COLOUR[p.rarity] || '#7a7a7a';
    const isGoldenSparkle = p.rarity === '000' && p.stealth_lucky;
    return (
      <Box
        className="gacha-enter"
        onClick={onAdvance}
        style={{
          'width': '100%',
          'min-height': '500px',
          'background': p.rarity === '000'
            ? 'radial-gradient(circle, #5a4a10 0%, '
              + '#1a1208 70%, #000 100%)'
            : 'radial-gradient(circle, #2a1810 0%, '
              + '#0a0808 70%, #000 100%)',
          'position': 'relative',
          'cursor': 'pointer',
        }}>
        <Box
          style={{
            'position': 'absolute',
            'top': '50%',
            'left': '50%',
            'transform': 'translate(-50%, -50%)',
            'text-align': 'center',
          }}>
          <Box
            style={{
              'width': '180px',
              'height': '240px',
              'border': '3px solid ' + colour,
              'background': p.rarity === '000'
                ? 'linear-gradient(135deg, #d4af37 0%, '
                  + '#5a4010 100%)'
                : 'linear-gradient(135deg, #303030 0%, '
                  + '#101010 100%)',
              'border-radius': '8px',
              'box-shadow': '0 0 24px ' + colour,
              'margin': '0 auto',
              'display': 'flex',
              'align-items': 'center',
              'justify-content': 'center',
            }}>
            {p.icon_data ? (
              <img
                src={'data:image/png;base64,' + p.icon_data}
                style={{
                  'width': '128px',
                  'height': '128px',
                  'image-rendering': 'pixelated',
                }}
              />
            ) : (
              <Box
                bold
                style={{
                  'color': p.rarity === '000' ? '#000' : '#fff',
                  'font-size': '20px',
                }}>
                ID
              </Box>
            )}
          </Box>
          <Box mt={1} bold style={{ 'color': colour }}>
            {p.name || p.skin_id}
          </Box>
          <Box>
            <RarityBadge rarity={p.rarity} />
            {!!isGoldenSparkle && (
              <Box inline ml={0.5} color="good" bold>
                Stealth!
              </Box>
            )}
            {!!p.was_duplicate && (
              <Box inline ml={0.5} color="label">
                (duplicate, +{p.dupe_refund})
              </Box>
            )}
          </Box>
          <Box
            mt={2}
            style={{ 'font-size': '10px' }}
            color="label">
            Click anywhere to continue ({currentIdx + 1}/{total})
          </Box>
        </Box>
      </Box>
    );
  }
}

// ---------- Results tile ----------
// One pulled-card cell. The "NEW" badge is anchored top-left
// (relative to the tile) for fresh unlocks; was_duplicate pulls
// suppress the badge and show the refund amount instead.
const ResultTile = props => {
  const { p } = props;
  const colour = RARITY_COLOUR[p.rarity] || '#7a7a7a';
  return (
    <Box
      className="gacha-result-fadein"
      style={{
        'position': 'relative',
        'padding': '8px',
        'border': '2px solid ' + colour,
        'border-radius': '6px',
        'background': p.rarity === '000'
          ? 'linear-gradient(135deg, '
            + '#3a3010 0%, #1a1208 100%)'
          : 'linear-gradient(135deg, '
            + '#202020 0%, #0a0a0a 100%)',
        'text-align': 'center',
        'box-shadow': '0 0 8px ' + colour + '40',
      }}>
      {!p.was_duplicate && (
        <Box className="gacha-new-badge">NEW</Box>
      )}
      {p.icon_data && (
        <Box mb={0.5}>
          <img
            src={'data:image/png;base64,' + p.icon_data}
            style={{
              'width': '64px',
              'height': '64px',
              'image-rendering': 'pixelated',
            }}
          />
        </Box>
      )}
      <Box bold style={{ 'color': colour }}>
        {p.name || p.skin_id}
      </Box>
      <Box mt={0.5}>
        <RarityBadge rarity={p.rarity} />
      </Box>
      {!!p.was_duplicate && (
        <Box
          mt={0.5}
          color="label"
          style={{ 'font-size': '10px' }}>
          duplicate, +{p.dupe_refund}
        </Box>
      )}
    </Box>
  );
};

// ---------- Results screen ----------
// Wrapper reads ui_data + manages stage transitions; the inner class
// component owns the staggered fade-in timeline and the per-tile
// idResult sound triggers.
const ResultsView = (props, context) => {
  const { act, data } = useBackend(context);
  const balance = data.balance || 0;
  const pending_pull = data.pending_pull || [];
  const banners = data.banners || [];
  const pull_costs = data.pull_costs || { single: 50, ten: 500 };
  const [selectedBannerIdx]
    = useLocalState(context, 'banner', 0);
  const [pendingCount]
    = useLocalState(context, 'pendingCount', 1);
  const [, setStage] = useLocalState(context, 'stage', STAGE_HOME);
  const [, setClicks] = useLocalState(context, 'crackClicks', 0);
  const [, setRevealed] = useLocalState(context, 'revealed', []);
  const [, setBallClicks] = useLocalState(context, 'ballClicks', 0);
  const [, setShowcaseIdx]
    = useLocalState(context, 'showcaseIdx', 0);
  const [, setShowcaseIndices]
    = useLocalState(context, 'showcaseIndices', null);
  const [, setConfirmReturn]
    = useLocalState(context, 'confirmReturn', STAGE_HOME);
  const banner = banners[selectedBannerIdx] || banners[0];
  let totalRefund = 0;
  for (let i = 0; i < pending_pull.length; i++) {
    totalRefund += pending_pull[i].dupe_refund || 0;
  }
  const cost = pendingCount === 10
    ? pull_costs.ten
    : pull_costs.single;
  const insufficient = balance < cost;
  const resetClient = () => {
    setClicks(0);
    setRevealed([]);
    setBallClicks(0);
    setShowcaseIdx(0);
    setShowcaseIndices(null);
  };
  const goHome = () => {
    act('ack_pull');
    resetClient();
    setStage(STAGE_HOME);
  };
  const extractAgain = () => {
    if (!banner) return;
    setConfirmReturn(STAGE_RESULTS);
    setStage(STAGE_CONFIRM);
  };
  const hasGold = pending_pull.some(p => p.rarity === '000');
  // Re-mount the canvas when the pull payload changes shape — this
  // matters for pity claims, where the player lands on RESULTS before
  // the back end has finished stashing the single-card result. Once
  // pending_pull arrives, the key flips and ResultsCanvas re-runs its
  // staggered fade-in timers with the correct data.
  return (
    <ResultsCanvas
      key={'results-' + pending_pull.length}
      act={act}
      pending_pull={pending_pull}
      balance={balance}
      pendingCount={pendingCount}
      cost={cost}
      insufficient={insufficient}
      totalRefund={totalRefund}
      hasGold={hasGold}
      onReturn={goHome}
      onExtractAgain={extractAgain}
    />
  );
};

class ResultsCanvas extends Component {
  constructor(props) {
    super(props);
    this.state = {
      visibleCount: 0,
    };
    this.timers = [];
  }
  componentDidMount() {
    const total = this.props.pending_pull.length;
    for (let i = 0; i < total; i++) {
      const delay = i * RESULT_TILE_STAGGER_MS;
      const t = setTimeout(() => {
        this.setState(s => ({ visibleCount: s.visibleCount + 1 }));
        playGachaSound(this.props.act, 'idResult');
      }, delay);
      this.timers.push(t);
    }
  }
  componentWillUnmount() {
    this.timers.forEach(t => clearTimeout(t));
    this.timers = [];
  }
  render() {
    const {
      pending_pull,
      balance,
      pendingCount,
      cost,
      insufficient,
      totalRefund,
      hasGold,
      onReturn,
      onExtractAgain,
    } = this.props;
    const { visibleCount } = this.state;
    const isTenPull = pending_pull.length > 1;
    return (
      <Box
        className="gacha-enter"
        style={{
          'width': '100%',
          'min-height': '500px',
          // Persistent backdrop so the results screen doesn't drop
          // back to the plain tgui window background when the
          // showcase exits.
          'background': hasGold
            ? 'radial-gradient(circle at center, '
              + '#5a4a10 0%, #1a1208 70%, #000 100%)'
            : 'radial-gradient(circle at center, '
              + '#2a1810 0%, #0a0808 70%, #000 100%)',
          'padding': '12px',
        }}>
        <Section title="Extraction Results">
          {isTenPull ? (
            <Box
              mb={1}
              style={{
                'display': 'grid',
                'grid-template-columns': 'repeat(5, 1fr)',
                'gap': '10px',
              }}>
              {pending_pull.map((p, i) => (
                i < visibleCount
                  ? <ResultTile key={i} p={p} />
                  : (
                    <Box key={i} style={{ 'visibility': 'hidden' }}>
                      <ResultTile p={p} />
                    </Box>
                  )
              ))}
            </Box>
          ) : (
            <Flex justify="center" mb={1}>
              <Flex.Item style={{ 'min-width': '160px' }}>
                {pending_pull[0] && visibleCount > 0 && (
                  <ResultTile p={pending_pull[0]} />
                )}
              </Flex.Item>
            </Flex>
          )}
          {totalRefund > 0 && (
            <Box
              mb={1}
              color="good"
              style={{ 'text-align': 'center' }}>
              Duplicate refund: <b>+{totalRefund} Starlight</b>
            </Box>
          )}
          <Box mb={1} style={{ 'text-align': 'center' }}>
            Balance: <b>{balance} Starlight</b>
          </Box>
          {!!insufficient && (
            <Box
              mb={1}
              color="bad"
              bold
              style={{ 'text-align': 'center' }}>
              Insufficient Starlight to Extract {pendingCount}{' '}
              again (need {cost}, have {balance}).
            </Box>
          )}
          <Flex justify="center" mt={2}>
            <Flex.Item mr={1} style={{ 'min-width': '180px' }}>
              <Button
                fluid
                content="Return"
                onClick={onReturn}
              />
            </Flex.Item>
            <Flex.Item style={{ 'min-width': '180px' }}>
              <Button
                fluid
                color="good"
                disabled={insufficient}
                content={'Extract ' + pendingCount + ' Again'}
                onClick={onExtractAgain}
              />
            </Flex.Item>
          </Flex>
        </Section>
      </Box>
    );
  }
}

// ---------- Top-level wrapper ----------
export const RefractionGachaShop = (props, context) => {
  const { data } = useBackend(context);
  const balance = data.balance || 0;
  const [stage] = useLocalState(context, 'stage', STAGE_HOME);
  const [confirmReturn]
    = useLocalState(context, 'confirmReturn', STAGE_HOME);
  const underlyingStage = stage === STAGE_CONFIRM
    ? confirmReturn
    : stage;
  return (
    <Window width={760} height={620}>
      <Window.Content scrollable>
        <Section>
          <Flex align="center" justify="space-between">
            <Flex.Item
              bold
              style={{ 'font-size': '14px' }}>
              Balance:
              {' '}
              <Box inline style={{ 'color': '#ffd86b' }}>
                {balance} Starlight
              </Box>
            </Flex.Item>
            <Flex.Item
              style={{ 'font-size': '11px' }}
              color="label">
              Rates: 0 - 83.0%, 00 - 12.8%, 000 - 2.9%
            </Flex.Item>
          </Flex>
        </Section>
        {underlyingStage === STAGE_HOME && <HomeView />}
        {underlyingStage === STAGE_CRACK_INTRO && <CrackIntroView />}
        {underlyingStage === STAGE_CRACK_BURST && <CrackBurstView />}
        {underlyingStage === STAGE_SHOWCASE && <ShowcaseView />}
        {underlyingStage === STAGE_RESULTS && <ResultsView />}
        {stage === STAGE_CONFIRM && <ConfirmOverlay />}
      </Window.Content>
    </Window>
  );
};
