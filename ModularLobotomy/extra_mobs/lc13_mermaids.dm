// ==========================================================
// Porous Hand Mermaids - Sinking-focused mob pack
// ==========================================================

/// Porous Hand Mermaid - Applies sinking stacks on targets without active sinking.
/// When attacking a target with active sinking, switches to PALE damage at 90% force.
/// On death, damages nearby mermaids for 2% maxHP BRUTE and grants them Damage Up.
/mob/living/simple_animal/hostile/porous_mermaid
	name = "porous hand mermaid"
	desc = "A creature resembling krill, with giant black eyes and an abyssal blue colour. Strands trail from its body, connecting back to its origin."
	icon = 'ModularLobotomy/_Lobotomyicons/sea_terrors64x64.dmi'
	icon_state = "merm"
	icon_living = "merm"
	pixel_x = -16
	base_pixel_x = -16
	faction = list("porous_hand")
	gender = NEUTER
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1)
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	del_on_death = TRUE
	maxHealth = 600
	health = 600
	melee_damage_lower = 15
	melee_damage_upper = 20
	move_to_delay = 3
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	/// Base sinking stacks applied per hit
	var/sinking_stacks = 3
	/// PALE damage force penalty when target has active sinking
	var/pale_penalty = 0.9

/mob/living/simple_animal/hostile/porous_mermaid/AttackingTarget(atom/attacked_target)
	if(!isliving(attacked_target))
		return ..()
	var/mob/living/target = attacked_target
	var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
	var/has_active_sinking = S && S.activated
	// Switch to PALE at reduced force when target has active sinking
	if(has_active_sinking)
		icon_state = "merm_tongue"
		melee_damage_type = PALE_DAMAGE
		melee_damage_lower = round(initial(melee_damage_lower) * pale_penalty)
		melee_damage_upper = round(initial(melee_damage_upper) * pale_penalty)
	else
		icon_state = "merm_open"
	. = ..()
	// Reset damage type immediately, delay icon reset so the attack state is visible
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	addtimer(CALLBACK(src, PROC_REF(reset_icon)), 5)
	if(!.)
		return
	// Apply sinking only if target does NOT have active sinking
	if(!has_active_sinking)
		target.apply_lc_sinking(sinking_stacks)

/// Resets icon_state back to idle after attack animation
/mob/living/simple_animal/hostile/porous_mermaid/proc/reset_icon()
	if(!QDELETED(src) && stat != DEAD)
		icon_state = icon_living

/mob/living/simple_animal/hostile/porous_mermaid/death(gibbed)
	// Damage nearby mermaids and grant Damage Up
	var/brute_damage = maxHealth * 0.02
	for(var/mob/living/simple_animal/hostile/porous_mermaid/M in view(7, src))
		if(M == src || M.stat == DEAD)
			continue
		M.adjustBruteLoss(brute_damage)
		// Grant Damage Up: current + 2, max 6
		var/datum/status_effect/stacking/damage_up/D = M.has_status_effect(/datum/status_effect/stacking/damage_up)
		var/current_stacks = D ? D.stacks : 0
		var/new_stacks = min(current_stacks + 2, 6)
		if(new_stacks > current_stacks)
			if(D)
				qdel(D)
			M.apply_lc_strength(new_stacks)
	return ..()
