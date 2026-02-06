// The Ring - Syndicate of Artists
// Corporist School - Utilizes interaction between human bones and muscles
// "Those who utilize the interaction between human bones and muscles, and the contraction and elongation thereof."

/obj/item/clothing/suit/armor/ego_gear/city/ring_maestro
	name = "corporist maestro garb"
	desc = "Draped white robes with a gilded trim worn by a Maestro of the Corporist school."
	icon_state = "ring_maestro"
	hat = /obj/item/clothing/head/ego_hat/ring_maestro
	armor = list(RED_DAMAGE = 60, WHITE_DAMAGE = 40, BLACK_DAMAGE = 50, PALE_DAMAGE = 60)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/obj/item/clothing/head/ego_hat/ring_maestro
	name = "corporist maestro hat"
	desc = "A large-brimmed hat featuring a litany of holes through its brim. A signature piece of a Corporist Maestro's attire."
	icon_state = "ring_maestro_hat"

/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice
	name = "iron maiden armor"
	desc = "Heavy white armor with bright yellow and golden highlights, featuring a faint iridescence. Spikes protrude from the lower dress-like half, and chains hang from thick bands at the elbows. Somewhat knightly in appearance."
	icon_state = "ring_apprentice"
	mask = /obj/item/clothing/mask/ego_mask/ring_apprentice
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 30, BLACK_DAMAGE = 30, PALE_DAMAGE = 40)
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 80,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 80
	)

/obj/item/clothing/mask/ego_mask/ring_apprentice
	name = "iron maiden mask"
	desc = "A mask with sharp golden eyes painted on and two white spikes on each side. Part of the Corporist apprentice's ensemble."
	icon_state = "ring_apprentice_mask"
	flags_inv = HIDEFACE|HIDESNOUT
