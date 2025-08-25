
//Announcement machines
/obj/item/records_broadcast
	name = "l-corp records logger"
	desc = "A device used by L-Corporation records officers to log information to their systems."
	icon = 'icons/obj/device.dmi'
	icon_state = "adv_spectrometer"

/obj/item/records_broadcast/attack_self(mob/living/user)
	..()
	var/input = stripped_input(user,"What do you want announce?", ,"Begin Log")
	send2chat("Records Log from RO [user.name]: [input]", CONFIG_GET(string/chat_announce_new_game))

