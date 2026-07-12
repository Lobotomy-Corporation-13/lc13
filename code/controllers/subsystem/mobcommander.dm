SUBSYSTEM_DEF(mobcommander)
	name = "Mob Commander"
	flags = SS_NO_FIRE | SS_NO_INIT
	var/list/leaders = list()
	var/list/follower_list = list()

//Called by component recruit
/datum/controller/subsystem/mobcommander/proc/RecruitFollower(follower)
	if(!follower)
		return FALSE
	LAZYOR(follower_list, follower)
	return TRUE

//Called when a follower is removed from component and list.
/datum/controller/subsystem/mobcommander/proc/DismissFollower(follower)
	if(!follower)
		return FALSE
	CheckLedger()
	follower_list -= follower
	return TRUE

//Registers leader into the system
/datum/controller/subsystem/mobcommander/proc/AddLeader(leader)
	if(LAZYFIND(leaders, leader))
		return FALSE
	CheckLedger()
	LAZYOR(leaders, leader)
	return TRUE

//Removes leader from the ledger
/datum/controller/subsystem/mobcommander/proc/RemoveLeader(leader, followers)
	CheckLedger()
	leaders -= leader
	for(var/minion in followers)
		DismissFollower(minion)

//Checks to find if recruit is already in the system
/datum/controller/subsystem/mobcommander/proc/FindRecruit(follower)
	if(LAZYFIND(follower_list, follower))
		return TRUE
	return FALSE

//Does technical fixes such as remove nulls
/datum/controller/subsystem/mobcommander/proc/CheckLedger()
	//Remove nulls.
	listclearnulls(leaders)
	listclearnulls(follower_list)
