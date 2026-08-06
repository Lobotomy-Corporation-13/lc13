// Areas for the LCE labs, replacing the five facility_hallway areas laboratory.dmm used.
//
// parent_type rather than a /area/facility_hallway/lce path, because the map already carries 966
// references to /area/lce/*. This is what actually inherits the facility behaviour: requires_power
// = FALSE, forced dynamic lighting, the Big Bird light suppression, and the abnormality alert in
// RefreshLights().

/area/lce
	parent_type = /area/facility_hallway
	name = "Limbus Company Extraction"
	icon_state = "lce_hall_central"

/*			CONTAINMENT			*/

// Now that /area/lce inherits from facility_hallway, every area here is in subtypesof() and so in
// GLOB.allowed_random_drop_areas. get_safe_random_station_turf() only picks turfs in areas with
// VALID_TERRITORY, so dropping the flag here is what keeps random arrivals - and cult summons,
// ninjas and dragon rifts - out of the cells. Do not put it back.
/area/lce/containment
	name = "Containment"
	icon_state = "lce_light_block"
	area_flags = BLOBS_ALLOWED | UNIQUE_AREA | CULT_PERMITTED
	sound_environment = SOUND_AREA_TUNNEL_ENCLOSED

/area/lce/containment/light
	name = "Light Containment"
	icon_state = "lce_light_block"

/area/lce/containment/light/one
	name = "Light Containment Unit 1"
	icon_state = "lce_light_1"

/area/lce/containment/light/two
	name = "Light Containment Unit 2"
	icon_state = "lce_light_2"

/area/lce/containment/light/three
	name = "Light Containment Unit 3"
	icon_state = "lce_light_3"

/area/lce/containment/light/four
	name = "Light Containment Unit 4"
	icon_state = "lce_light_4"

// One booth per column, serving the unit above and the unit below through separate poddoor banks.
/area/lce/containment/light/control_west
	name = "Light Containment Control, West"
	icon_state = "lce_light_ctrl_w"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/containment/light/control_east
	name = "Light Containment Control, East"
	icon_state = "lce_light_ctrl_e"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/containment/light/approach
	name = "Light Containment Approach"
	icon_state = "lce_light_block"

/area/lce/containment/heavy
	name = "Heavy Containment"
	icon_state = "lce_heavy_block"

/area/lce/containment/heavy/one
	name = "Heavy Containment Unit 1"
	icon_state = "lce_heavy_1"

/area/lce/containment/heavy/two
	name = "Heavy Containment Unit 2"
	icon_state = "lce_heavy_2"

/area/lce/containment/heavy/control_one
	name = "Heavy Containment Control 1"
	icon_state = "lce_heavy_ctrl_1"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/containment/heavy/control_two
	name = "Heavy Containment Control 2"
	icon_state = "lce_heavy_ctrl_2"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/containment/heavy/approach
	name = "Heavy Containment Approach"
	icon_state = "lce_heavy_block"

/*			RESEARCH			*/

/area/lce/research
	name = "Research"
	icon_state = "lce_records"
	sound_environment = SOUND_AREA_SMALL_SOFTFLOOR

/area/lce/research/records
	name = "Records Office"
	icon_state = "lce_records"

/area/lce/research/reagent
	name = "Reagent Laboratory"
	icon_state = "lce_reagent"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/research/director
	name = "Research Director's Office"
	icon_state = "lce_rd_office"

/*			MEDICAL			*/

/area/lce/medical
	name = "Medical"
	icon_state = "lce_medbay"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/medical/bay
	name = "Medical Bay"
	icon_state = "lce_medbay"

/area/lce/medical/morgue
	name = "Morgue"
	icon_state = "lce_morgue"
	sound_environment = SOUND_AREA_TUNNEL_ENCLOSED

/area/lce/medical/surgery
	name = "Surgery and Augmentation"
	icon_state = "lce_surgery"

/area/lce/medical/office
	name = "Chief Medical Officer's Office"
	icon_state = "lce_cmo_office"
	sound_environment = SOUND_AREA_SMALL_SOFTFLOOR

// The suture and medipen caches sitting outside each containment block.
/area/lce/medical/aid_light
	name = "Light Containment Aid Post"
	icon_state = "lce_aid_light"

/area/lce/medical/aid_heavy
	name = "Heavy Containment Aid Post"
	icon_state = "lce_aid_heavy"

/*			SERVICE			*/

/area/lce/service
	name = "Service"
	icon_state = "lce_canteen"

/area/lce/service/kitchen
	name = "Kitchen"
	icon_state = "lce_kitchen"

/area/lce/service/dining
	name = "Cafeteria"
	icon_state = "lce_canteen"
	sound_environment = SOUND_AREA_LARGE_ENCLOSED

/area/lce/service/lounge
	name = "Recreation Floor"
	icon_state = "lce_rec"
	sound_environment = SOUND_AREA_LARGE_SOFTFLOOR

/area/lce/service/washroom
	name = "Washroom"
	icon_state = "lce_wash"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/service/laundry
	name = "Laundry"
	icon_state = "lce_laundry"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/service/cryo
	name = "Cryogenic Storage"
	icon_state = "lce_cryo"

/area/lce/service/dorms
	name = "Dormitories"
	icon_state = "lce_dorms"
	sound_environment = SOUND_AREA_SMALL_SOFTFLOOR

/area/lce/service/quarters
	name = "Senior Quarters"
	icon_state = "lce_quarters"
	sound_environment = SOUND_AREA_SMALL_SOFTFLOOR

/area/lce/service/gym
	name = "Fitness Room"
	icon_state = "lce_gym"

/area/lce/service/memorial
	name = "Memorial Garden"
	icon_state = "lce_memorial"
	outdoors = TRUE
	sound_environment = SOUND_AREA_STANDARD_STATION

/*			SECURITY			*/

/area/lce/security
	name = "Security"
	icon_state = "lce_checkpoint"

/area/lce/security/checkpoint
	name = "Security Checkpoint"
	icon_state = "lce_checkpoint"

/area/lce/security/armoury
	name = "Armoury"
	icon_state = "lce_armoury"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/security/udjat_armoury
	name = "Udjat Armoury"
	icon_state = "lce_udjat_arms"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/security/udjat_quarters
	name = "Udjat Leader's Quarters"
	icon_state = "lce_udjat_room"
	sound_environment = SOUND_AREA_SMALL_SOFTFLOOR

/*			COMMAND			*/

/area/lce/command
	name = "Command"
	icon_state = "lce_manager"
	sound_environment = SOUND_AREA_SMALL_SOFTFLOOR

/area/lce/command/manager
	name = "Manager's Office"
	icon_state = "lce_manager"

/area/lce/command/briefing
	name = "Briefing Room"
	icon_state = "lce_briefing"

/area/lce/command/lounge
	name = "Executive Lounge"
	icon_state = "lce_exec"

/*			SUPPORT AND OUTDOORS			*/

/area/lce/support
	name = "Support"
	icon_state = "lce_telecomms"

/area/lce/support/telecomms
	name = "Telecommunications"
	icon_state = "lce_telecomms"
	sound_environment = SOUND_AREA_SMALL_ENCLOSED

/area/lce/outdoors
	name = "Grounds"
	icon_state = "lce_garden_west"
	outdoors = TRUE
	sound_environment = SOUND_AREA_STANDARD_STATION

/area/lce/outdoors/west_garden
	name = "West Garden"
	icon_state = "lce_garden_west"

/area/lce/outdoors/north_garden
	name = "North Garden"
	icon_state = "lce_garden_north"

/*			HALLWAYS			*/

/area/lce/hallway
	name = "Hallway"
	icon_state = "lce_hall_central"

/area/lce/hallway/central
	name = "Central Hallway"
	icon_state = "lce_hall_central"

/area/lce/hallway/north
	name = "North Hallway"
	icon_state = "lce_hall_north"

/area/lce/hallway/south
	name = "South Hallway"
	icon_state = "lce_hall_south"

/area/lce/hallway/west
	name = "West Hallway"
	icon_state = "lce_hall_west"

/area/lce/hallway/service
	name = "Service Corridor"
	icon_state = "lce_hall_service"
