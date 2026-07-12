import { Component, createRef } from 'inferno';
import {
  useBackend,
  useSharedState,
} from '../backend';
import {
  Box,
  Button,
  Dropdown,
  LabeledList,
  NoticeBox,
  Section,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

const WP_COLOR = '#d4a017';
const WP_RADIUS = 9;
const VP_SIZE = 20;
const CELL_PX = 25;
const CANVAS_PX = VP_SIZE * CELL_PX;

export const ContractTerminal = (
  props,
  context,
) => {
  const { act, data } = useBackend(context);
  const [tab, setTab] = useSharedState(
    context, 'termTab', 0,
  );
  return (
    <Window
      title="Contract Terminal"
      width={780}
      height={680}>
      <Window.Content scrollable>
        <Tabs>
          <Tabs.Tab
            selected={tab === 0}
            onClick={() => setTab(0)}>
            Contracts
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 1}
            onClick={() => setTab(1)}>
            City Map
          </Tabs.Tab>
        </Tabs>
        {tab === 0 && (
          <ContractsView
            act={act}
            data={data}
            ctx={context}
          />
        )}
        {tab === 1 && (
          <CityMapView
            act={act}
            data={data}
            ctx={context}
          />
        )}
      </Window.Content>
    </Window>
  );
};

const ContractsView = props => {
  const { act, data, ctx } = props;
  const {
    is_fixer = false,
    user_balance = 0,
    is_hana = false,
    has_account = false,
    can_view_contracts = false,
    contract_types = [],
    active_contracts = [],
    targets = [],
    waypoint_count = 0,
    patrol_cost = 0,
  } = data;
  return (
    <>
      {is_fixer && (
        <NoticeBox danger>
          Association members cannot
          create contracts.
        </NoticeBox>
      )}
      {!is_fixer && (
        <CreatePanel
          act={act}
          balance={user_balance}
          isHana={is_hana}
          hasAccount={has_account}
          types={contract_types}
          targets={targets}
          ctx={ctx}
          wpCount={waypoint_count}
          patrolCost={patrol_cost}
        />
      )}
      {!!can_view_contracts && (
        <ActivePanel
          act={act}
          contracts={active_contracts}
          isFixer={is_fixer}
        />
      )}
    </>
  );
};

const CreatePanel = props => {
  const {
    act,
    balance,
    isHana,
    hasAccount,
    types,
    targets,
    ctx,
    wpCount,
    patrolCost,
  } = props;
  const [selType, setSelType]
    = useSharedState(
      ctx, 'selType', '',
    );
  const [selTier, setSelTier]
    = useSharedState(
      ctx, 'selTier', 0,
    );
  const [selTarget, setSelTarget]
    = useSharedState(
      ctx, 'selTarget', '',
    );
  const typeDef = types.find(
    t => t.type === selType,
  );
  const needsTarget = typeDef
    && typeDef.needs_target;
  const isPatrol = typeDef
    && typeDef.uses_waypoints;
  const isSingleWP = typeDef
    && typeDef.single_waypoint;
  const tiers = typeDef
    ? typeDef.tiers
    : [];
  const tierIdx = Math.min(
    selTier, Math.max(tiers.length - 1, 0),
  );
  const tierDef = tiers[tierIdx];
  const cost = tierDef ? tierDef.cost : 0;
  const effectiveCost = isPatrol
    ? patrolCost : cost;
  const canAfford = isHana
    || (hasAccount
      && balance >= effectiveCost);
  const balText = isHana
    ? 'Unlimited (Hana)'
    : balance + ' Ahn';
  const typeNames = types.map(
    t => t.name,
  );
  const targetNames = targets.map(
    t => t.name,
  );
  const selTargetObj = targets.find(
    t => t.ref === selTarget,
  );
  const hasTarget = !needsTarget
    || !!selTargetObj;
  return (
    <Section title="Create Contract">
      <LabeledList>
        <LabeledList.Item
          label="Balance">
          {balText}
        </LabeledList.Item>
        <LabeledList.Item
          label="Contract">
          <Dropdown
            width="200px"
            options={typeNames}
            selected={
              typeDef
                ? typeDef.name
                : 'Select...'
            }
            onSelected={val => {
              const t = types.find(
                x => x.name === val,
              );
              setSelType(
                t ? t.type : '',
              );
              setSelTier(0);
              setSelTarget('');
            }}
          />
        </LabeledList.Item>
        {tiers.length > 1 && (
          <LabeledList.Item
            label="Duration">
            <Dropdown
              width="200px"
              options={tiers.map(
                t => t.tier_name,
              )}
              selected={
                tierDef
                  ? tierDef.tier_name
                  : 'Select...'
              }
              onSelected={val => {
                const i
                  = tiers.findIndex(
                    t => t.tier_name
                      === val,
                  );
                setSelTier(
                  i >= 0 ? i : 0,
                );
              }}
            />
          </LabeledList.Item>
        )}
        {!!needsTarget && (
          <LabeledList.Item
            label="Target">
            <Dropdown
              width="200px"
              options={targetNames}
              selected={
                selTargetObj
                  ? selTargetObj.name
                  : 'Select...'
              }
              onSelected={val => {
                const t = targets.find(
                  x => x.name === val,
                );
                setSelTarget(
                  t ? t.ref : '',
                );
              }}
            />
          </LabeledList.Item>
        )}
        {!!isPatrol && (
          <LabeledList.Item
            label="Waypoints">
            <Box bold>
              {isSingleWP
                ? (wpCount >= 1
                  ? '1 placed'
                  : '0 (need 1)')
                : wpCount + ' placed'}
            </Box>
          </LabeledList.Item>
        )}
        {!!typeDef && (
          <LabeledList.Item
            label="Cost">
            <Box
              bold
              color={
                canAfford
                  ? 'good'
                  : 'bad'
              }>
              {effectiveCost + ' Ahn'}
            </Box>
          </LabeledList.Item>
        )}
      </LabeledList>
      {!!typeDef && (
        <Box
          mt={1}
          italic
          color="label"
          fontSize="11px">
          {typeDef.desc}
        </Box>
      )}
      <Box mt={1}>
        <Button
          fluid
          icon="file-contract"
          disabled={
            !typeDef
            || !canAfford
            || !hasTarget
            || (!hasAccount && !isHana)
            || (isPatrol && isSingleWP
              && wpCount !== 1)
            || (isPatrol && !isSingleWP
              && !wpCount)
          }
          onClick={() => act(
            'create_contract',
            {
              contract_type: selType,
              tier_index: tierIdx + 1,
              target_ref: selTarget,
            },
          )}>
          Create Contract
        </Button>
      </Box>
    </Section>
  );
};

const ActivePanel = props => {
  const { act, contracts, isFixer } = props;
  return (
    <Section title="Active Contracts">
      {contracts.length === 0 && (
        <Box color="label" italic>
          No active contracts.
        </Box>
      )}
      {contracts.length > 0 && (
        <Table>
          <Table.Row header>
            <Table.Cell>
              Contract
            </Table.Cell>
            <Table.Cell>
              Source
            </Table.Cell>
            <Table.Cell>
              Status
            </Table.Cell>
            {!!isFixer && (
              <Table.Cell />
            )}
          </Table.Row>
          {contracts.map(c => (
            <Table.Row
              key={c.contract_id}>
              <Table.Cell>
                {c.contract_name}
              </Table.Cell>
              <Table.Cell>
                {c.source === 'civilian'
                  ? 'Civilian (2x)'
                  : 'Hana'}
              </Table.Cell>
              <Table.Cell>
                {c.status_text}
              </Table.Cell>
              {!!isFixer && (
                <Table.Cell>
                  <Button
                    icon="times"
                    color="bad"
                    onClick={() => act(
                      'cancel_contract',
                      {
                        contract_id:
                          c.contract_id,
                      }
                    )}
                  />
                </Table.Cell>
              )}
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

// Canvas-based city map viewport renderer
class CityMapCanvas extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.handleClick
      = this.handleClick.bind(this);
  }

  componentDidMount() {
    this.drawMap();
  }

  componentDidUpdate() {
    this.drawMap();
  }

  drawMap() {
    const canvas = this.canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const { mapGrid, waypoints }
      = this.props;
    ctx.fillStyle = '#111111';
    ctx.fillRect(
      0, 0, CANVAS_PX, CANVAS_PX,
    );
    if (!mapGrid || !mapGrid.length) {
      return;
    }
    const gw = mapGrid.length;
    const gh = mapGrid[0]
      ? mapGrid[0].length : 0;
    const groups = {};
    for (let x = 0; x < gw; x++) {
      for (let y = 0; y < gh; y++) {
        const color
          = mapGrid[x][gh - 1 - y];
        if (color
          && color !== '#000000') {
          if (!groups[color]) {
            groups[color] = [];
          }
          groups[color].push({ x, y });
        }
      }
    }
    for (const color in groups) {
      ctx.fillStyle = color;
      const cells = groups[color];
      for (
        let i = 0;
        i < cells.length;
        i++
      ) {
        const c = cells[i];
        ctx.fillRect(
          c.x * CELL_PX,
          c.y * CELL_PX,
          CELL_PX + 1,
          CELL_PX + 1,
        );
      }
    }
    if (!waypoints || !waypoints.length) {
      return;
    }
    const { viewWorldX, viewWorldY }
      = this.props;
    for (
      let i = 0;
      i < waypoints.length;
      i++
    ) {
      const wp = waypoints[i];
      const gx = wp.x - viewWorldX;
      const gy = wp.y - viewWorldY;
      if (gx < 0 || gx >= gw
        || gy < 0 || gy >= gh) {
        continue;
      }
      const px = (gx + 0.5) * CELL_PX;
      const py = CANVAS_PX
        - (gy + 0.5) * CELL_PX;
      ctx.fillStyle = WP_COLOR;
      ctx.beginPath();
      ctx.arc(
        px, py, WP_RADIUS,
        0, Math.PI * 2,
      );
      ctx.fill();
      ctx.fillStyle = '#000';
      ctx.font = 'bold 12px monospace';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(
        String(wp.order), px, py,
      );
    }
  }

  handleClick(event) {
    const canvas
      = this.canvasRef.current;
    if (!canvas) return;
    const rect
      = canvas.getBoundingClientRect();
    const cx
      = event.clientX - rect.left;
    const cy
      = event.clientY - rect.top;
    const gx
      = Math.floor(cx / CELL_PX);
    const gy = Math.floor(
      (CANVAS_PX - cy) / CELL_PX,
    );
    const {
      viewWorldX,
      viewWorldY,
      onPlaceWaypoint,
      disabled,
      waypoints = [],
    } = this.props;
    const wx = gx + viewWorldX;
    const wy = gy + viewWorldY;
    // Allow removing existing waypoints
    // even when at limit
    const isExisting = waypoints.some(
      wp => wp.x === wx && wp.y === wy,
    );
    if (disabled && !isExisting) {
      return;
    }
    if (onPlaceWaypoint) {
      onPlaceWaypoint(wx, wy);
    }
  }

  render() {
    return (
      <canvas
        ref={this.canvasRef}
        width={CANVAS_PX}
        height={CANVAS_PX}
        style={{
          cursor: 'crosshair',
        }}
        onClick={this.handleClick}
      />
    );
  }
}

const CityMapView = props => {
  const { act, data, ctx } = props;
  const {
    mapGrid,
    viewWorldX = 0,
    viewWorldY = 0,
    canMoveN = false,
    canMoveS = false,
    canMoveE = false,
    canMoveW = false,
    waypoints = [],
    contract_types = [],
    map_legend = [],
  } = data;
  const [selType] = useSharedState(
    ctx, 'selType', '',
  );
  const typeDef = contract_types.find(
    t => t.type === selType,
  );
  const isSingleWP = typeDef
    && typeDef.single_waypoint;
  const maxWP = isSingleWP ? 1 : 10;
  const atLimit = waypoints.length
    >= maxWP;

  if (!mapGrid) {
    return (
      <Section title="City Map">
        <NoticeBox>
          Map data not available.
        </NoticeBox>
      </Section>
    );
  }

  const move = dir => act(
    'move_viewport', { dir },
  );

  return (
    <Section title="City Map">
      <Box
        style={{
          display: 'flex',
          gap: '8px',
        }}>
        <Box>
          <Box textAlign="center">
            <Button
              icon="arrow-up"
              disabled={!canMoveN}
              onClick={
                () => move('north')
              }
            />
          </Box>
          <Box textAlign="center">
            <Box
              inline
              style={{
                verticalAlign:
                  'middle',
              }}>
              <Button
                icon="arrow-left"
                disabled={!canMoveW}
                onClick={
                  () => move('west')
                }
              />
            </Box>
            <Box
              inline
              mx={0.5}
              style={{
                border:
                  '1px solid #444',
                verticalAlign:
                  'middle',
              }}>
              <CityMapCanvas
                mapGrid={mapGrid}
                viewWorldX={viewWorldX}
                viewWorldY={viewWorldY}
                waypoints={waypoints}
                disabled={atLimit}
                onPlaceWaypoint={(wx, wy) =>
                  act('place_waypoint', {
                    world_x: wx,
                    world_y: wy,
                  })}
              />
            </Box>
            <Box
              inline
              style={{
                verticalAlign:
                  'middle',
              }}>
              <Button
                icon="arrow-right"
                disabled={!canMoveE}
                onClick={
                  () => move('east')
                }
              />
            </Box>
          </Box>
          <Box textAlign="center">
            <Button
              icon="arrow-down"
              disabled={!canMoveS}
              onClick={
                () => move('south')
              }
            />
          </Box>
          <Box
            mt={1}
            textAlign="center">
            <Button
              icon="trash"
              color="bad"
              onClick={() => act(
                'clear_waypoints',
              )}>
              Clear All
            </Button>
            <Box
              inline
              ml={1}
              color="label">
              {'Waypoints: '
                + waypoints.length
                + ' / ' + maxWP}
            </Box>
          </Box>
        </Box>
        <Box
          style={{
            flexShrink: 0,
            minWidth: '130px',
          }}>
          <MapLegend
            legend={map_legend}
          />
        </Box>
      </Box>
    </Section>
  );
};

const MapLegend = props => {
  const { legend = [] } = props;
  if (!legend.length) return null;
  return (
    <Section title="Legend">
      {legend.map(entry => (
        <Box
          key={entry.color}
          mb={0.5}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
          }}
          fontSize="11px"
          color="label">
          <Box
            inline
            style={{
              width: '10px',
              height: '10px',
              background: entry.color,
              flexShrink: 0,
            }}
          />
          {entry.name}
        </Box>
      ))}
    </Section>
  );
};
