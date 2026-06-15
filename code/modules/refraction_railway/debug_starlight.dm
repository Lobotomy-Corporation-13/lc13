/*
 * Debug tool — admin-spawn only. Use in hand to prompt for an amount,
 * then bank that many Starlight onto the user's ckey via the standard
 * SSrefraction_railway.AwardStarlight path (signed: negative numbers
 * deduct, clamped to ≥ 0 by the subsystem).
 *
 * Not gold-core spawnable, not part of any quirk or shop. Intended for
 * admin VV / spawn-item testing of the Starlight shop + quirk gates.
 */

/obj/item/refraction_starlight_debug
	name = "starlight debug terminal"
	desc = "A handheld diagnostic for the Starlight ledger. Use in hand to write an amount to your balance. Admin-only."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	inhand_icon_state = "multitool"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/refraction_starlight_debug/attack_self(mob/user)
	if(!user?.ckey)
		return
	var/amount = input(user, "Starlight to grant (negative deducts, balance is clamped to zero):", "Starlight Debug", 100) as num|null
	if(isnull(amount) || amount == 0)
		return
	SSrefraction_railway.AwardStarlight(user.ckey, amount)
	var/new_balance = SSrefraction_railway.GetStarlight(user.ckey)
	if(amount > 0)
		to_chat(user, span_nicegreen("Granted [amount] Starlight. Balance: [new_balance] ★"))
	else
		to_chat(user, span_warning("Deducted [-amount] Starlight. Balance: [new_balance] ★"))
