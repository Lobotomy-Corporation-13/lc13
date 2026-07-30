/// Violently spins the target with ragdoll animation
/datum/smite/ragdoll_spin
	name = "Ragdoll Spin"

/datum/smite/ragdoll_spin/effect(client/user, mob/living/target)
	. = ..()

	if(!isliving(target))
		return

	to_chat(target, span_userdanger("Reality itself rejects your existence, twisting you violently!"), confidential = TRUE)
	playsound(get_turf(target), 'sound/abnormalities/dinner_chair/ragdoll_effect.ogg', 75, TRUE)

	// Start the violent spinning
	INVOKE_ASYNC(src, PROC_REF(violent_spin), target)

/datum/smite/ragdoll_spin/proc/violent_spin(mob/living/M)
	if(!M || QDELETED(M))
		return

	var/matrix/initial_matrix = matrix(M.transform)

	// 12 seconds of violent spinning
	for(var/i in 1 to 120)
		if(!M || QDELETED(M))
			return

		// Violent rotation
		initial_matrix = matrix(M.transform)
		initial_matrix.Turn(rand(45, 180)) // Random violent turns

		// Extreme position changes
		var/x_shift = rand(-10, 10)
		var/y_shift = rand(-10, 10)
		initial_matrix.Translate(x_shift, y_shift)

		animate(M, transform = initial_matrix, time = 1, loop = 0, easing = pick(LINEAR_EASING, SINE_EASING, CIRCULAR_EASING))

		// Rapid direction changes
		M.setDir(pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))

		sleep(1)

	// Reset transformation
	animate(M, transform = null, time = 5, loop = 0)
	to_chat(M, span_notice("Reality stabilizes around you once more."), confidential = TRUE)
