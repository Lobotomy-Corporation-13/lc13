/datum/reagent/abnormality/fish
	name = "Fish Juice"
	description = "The juices of an abnormal fish."
	health_restore = -20
	sanity_restore = 10 // Drinking raw fish juice is obviously a sane thing to do
	metabolization_rate = 2 * REAGENTS_METABOLISM

/datum/reagent/abnormality/fish/New()
	. = ..()

	color = "#" + random_color()

/datum/reagent/abnormality/fish/onefish
	name = "One Fish Juice"
	health_restore = 0
	sanity_restore = 0
	stat_changes = list(0, 10, 0, 0)
