// Pathstrider screen readouts: turn gem, AP pips, Ultimate charge.
//
// Turn state, AP and energy used to live behind an examine or the Path Screen,
// so players could not tell when they could act. These three sit in the column
// left of the vitals, one row per element.
//
// They are private to their owner. The objects go into the owner's own
// hud_used.infodisplay and client.screen, which are per-client, so nobody else
// ever receives them. This is the opposite of the ally indicator in
// associations/skills/_designate_ally.dm, which deliberately pushes images into
// OTHER clients; nothing here does that.

/atom/movable/screen/path_hud
	icon = 'ModularLobotomy/_Lobotomyicons/path_hud.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_HUD_LAYER
	plane = ABOVE_HUD_PLANE

/atom/movable/screen/path_hud/turn
	name = "turn"
	desc = "Lit when you can attack or use your Skill."
	icon_state = "turn_ready"
	screen_loc = ui_path_turn

/atom/movable/screen/path_hud/ap
	name = "action points"
	desc = "Spent to use your Skill."
	icon_state = "ap_0"
	screen_loc = ui_path_ap

/atom/movable/screen/path_hud/energy
	name = "ultimate charge"
	desc = "Fills as you fight. Your Ultimate unlocks when it is full."
	icon_state = "energy_0"
	screen_loc = ui_path_energy

/datum/path
	var/atom/movable/screen/path_hud/turn/hud_turn
	var/atom/movable/screen/path_hud/ap/hud_ap
	var/atom/movable/screen/path_hud/energy/hud_energy
	/// Repeating timer that ticks the turn countdown text.
	var/hud_timer_id

/// Builds the three readouts and shows them to the owner.
/datum/path/proc/CreateHud()
	if(!owner || hud_turn)
		return
	hud_turn = new()
	hud_ap = new()
	hud_energy = new()
	AttachHud()
	RegisterSignal(owner, COMSIG_MOB_LOGIN, PROC_REF(OnOwnerLogin))
	hud_timer_id = addtimer(CALLBACK(src, PROC_REF(UpdateTurnHud)), 1 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)
	UpdateHud()

/// Puts the readouts into the owner's HUD and screen. Safe to call again.
/datum/path/proc/AttachHud()
	if(!owner || !hud_turn)
		return
	var/list/elements = list(hud_turn, hud_ap, hud_energy)
	if(owner.hud_used)
		owner.hud_used.infodisplay |= elements
	// infodisplay is only pushed to the screen when the HUD is (re)shown, so add
	// them directly for the case where the HUD is already up.
	if(owner.client)
		owner.client.screen |= elements

/datum/path/proc/OnOwnerLogin(datum/source)
	SIGNAL_HANDLER
	AttachHud()

/// Tears the readouts down. Called from Remove().
/datum/path/proc/DestroyHud()
	if(hud_timer_id)
		deltimer(hud_timer_id)
		hud_timer_id = null
	if(owner)
		UnregisterSignal(owner, COMSIG_MOB_LOGIN)
		var/list/elements = list(hud_turn, hud_ap, hud_energy)
		if(owner.hud_used)
			owner.hud_used.infodisplay -= elements
		if(owner.client)
			owner.client.screen -= elements
	QDEL_NULL(hud_turn)
	QDEL_NULL(hud_ap)
	QDEL_NULL(hud_energy)

/// Refreshes every readout. Cheap enough to call from resource changes.
/datum/path/proc/UpdateHud()
	UpdateTurnHud()
	UpdateApHud()
	UpdateEnergyHud()

/// Turn gem plus a countdown to the next turn. Ticked once a second.
/datum/path/proc/UpdateTurnHud()
	if(!hud_turn)
		return
	if(turn_state == PATH_TURN_READY)
		hud_turn.icon_state = "turn_ready"
		hud_turn.maptext = null
		return
	hud_turn.icon_state = "turn_spent"
	var/remaining = max(next_turn_time - world.time, 0) / 10
	hud_turn.maptext = MAPTEXT("<div align='center' style='position:relative; top:9px'><font color='#9aa0b5'>[round(remaining, 0.1)]</font></div>")

/datum/path/proc/UpdateApHud()
	if(!hud_ap)
		return
	hud_ap.icon_state = "ap_[clamp(action_points, 0, 5)]"

/datum/path/proc/UpdateEnergyHud()
	if(!hud_energy)
		return
	var/tenths = 0
	if(max_energy > 0)
		tenths = clamp(round(energy / max_energy * 10), 0, 10)
	hud_energy.icon_state = "energy_[tenths]"
