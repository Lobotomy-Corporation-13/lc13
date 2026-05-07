/*
* Allows entities to exist on a word.
* If a entity has this applied to them
* then they are added to a list with that word
* if they are a send_tag then we check when they die
* but if they have a recieve tag they will die if the
* creature with the corrosponding send_tag is destroyed
* This was made because we had magic zombies that all
* would die off when the creator of the first zombie dies
* but stay alive if the first generation zombies are killed.
*/
/datum/element/soul_link
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH
	//The web connects the souls
	var/list/senders_list = list()
	var/list/recievers_list = list()

// The atom, the tag that this unit sends out on its demise, and the tag that kills this unit.
/datum/element/soul_link/Attach(atom/target, send_tag = 0, destroy_tag = 0)
	. = ..()
	if(!istype(target))
		return ELEMENT_INCOMPATIBLE
	if(!send_tag && !destroy_tag)
		return ELEMENT_INCOMPATIBLE

	if(send_tag)
		LAZYOR(senders_list,target)
		senders_list[target] = send_tag

	if(destroy_tag)
		LAZYOR(recievers_list,target)
		recievers_list[target] = destroy_tag

//Detach already checks if we are deleted.
/datum/element/soul_link/Detach(obj/target)
	. = ..()
	var/send_tag = senders_list[target]
	senders_list -= target
	if(target in senders_list)
		LAZYREMOVE(senders_list,target)
	if(target in recievers_list)
		LAZYREMOVE(recievers_list,target)
	/*
	* If 2 creatures have send and destroy tags
	* there will not be a loop because the first
	* destroyed creature will be removed from the
	* recievers list. -IP
	*/
	if(send_tag && length(recievers_list))
		for(var/i in recievers_list)
			if(recievers_list[i] == send_tag)
				LAZYREMOVE(recievers_list,i)
				if(isliving(i))
					var/mob/living/L = i
					L.dust(TRUE,TRUE,TRUE)
					continue
				qdel(i)
