# Adding a city faction

A faction is one leader job plus any number of member jobs. By default the
member jobs only open if a player actually took the leader slot, at roundstart
or on latejoin. A faction can opt out with `requires_leader = FALSE`.

Three major and five minor factions are drawn at random each round
(`CITY_FACTION_MAJOR_COUNT` / `CITY_FACTION_MINOR_COUNT` in
`code/__DEFINES/jobs.dm`). Undrawn factions sit at zero slots and never appear.

## Folder layout

	city/
	  clinic/          always active, never drawn
	  major_factions/  one folder per faction
	  minor_factions/  one folder per faction
	  old_jobs/        disabled, pending rework

## 1. Write the jobs

One file per job, in your faction's folder. Every job needs `maptype`,
`total_positions = 0`, `spawn_positions = 0`, and the faction vars. The system
sets the live counts from `faction_positions`, so the authored positions stay 0.

The leader, `major_factions/thumb/sottocapo.dm`:

	/datum/job/sottocapo
		title = "Thumb Sottocapo"
		outfit = /datum/outfit/job/sottocapo
		faction = "Station"
		maptype = list("city")
		total_positions = 0
		spawn_positions = 0
		leader = /datum/job/sottocapo <--- Make sure to add that
		faction_positions = 1
		trusted_only = TRUE
		access = list("thumb_south", "thumb_south_leader") <--- Make sure to update that
		minimal_access = list("thumb_south", "thumb_south_leader") <--- Make sure to update that
		radio_channel_name = "Thumb South" <--- Make sure to add that
		radio_channel_color = "#8b0000" <--- Make sure to add that
		departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
		display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD

A member, `major_factions/thumb/soldato.dm`. Same shape, minus `trusted_only`
and the leader access:

	/datum/job/soldato
		title = "Thumb Soldato"
		outfit = /datum/outfit/job/soldato
		faction = "Station"
		maptype = list("city")
		total_positions = 0
		spawn_positions = 0
		leader = /datum/job/sottocapo <--- Make sure to add that
		faction_positions = 4
		access = list("thumb_south") <--- Make sure to update that
		minimal_access = list("thumb_south") <--- Make sure to update that
		radio_channel_name = "Thumb South" <--- Make sure to add that
		radio_channel_color = "#8b0000" <--- Make sure to add that
		departments = DEPARTMENT_CITY_ANTAGONIST
		display_order = JOB_DISPLAY_ORDER_SYNDICATEGOON

`leader` is what joins a job to a faction. The leader points at itself; members
point at the leader.

`trusted_only = TRUE` on major leaders, `FALSE` on minor leaders.

## 2. Register the faction

Add one block to `code/modules/jobs/city_factions/factions.dm`. Do not list
members here, they are found from their `leader`.

	/datum/city_faction/thumb_south
		name = "the Thumb South"
		category = CITY_FACTION_MAJOR
		leader_job = /datum/job/sottocapo
		requires_leader = TRUE

`category` is `CITY_FACTION_MAJOR`, `CITY_FACTION_MINOR` or
`CITY_FACTION_ALWAYS`. ALWAYS skips the draw and is on every round.

`requires_leader` is the leader lock. Left `TRUE`, members only spawn if a
player took the leader slot, and latejoiners are refused until someone does.
Set it `FALSE` for a faction whose members should spawn regardless - the leader
job still exists and still has its slot, it just stops gating anyone.

`name` is used in the latejoin refusal, so it reads best with an article:
"the Thumb South has no leader this round."

## 3. Access

Access is a plain string, so `code/__DEFINES/access.dm` never needs editing.
Put it in both `access` and `minimal_access` - the game picks one or the other
depending on player count, and a string in only one silently vanishes on the
other kind of round.

Give the leader an extra `"<faction>_leader"` string if you want leader-only
doors.

## 4. Radio

Set `radio_channel_name` and `radio_channel_color` on every job in the faction,
and give them the faction headset in the outfit:

	ears = /obj/item/radio/headset/faction        // members
	ears = /obj/item/radio/headset/faction/heads  // leader, high-volume mode

Always use the faction headset. It ships with no keyslot, no channels and no
preset frequency, so the only thing on it is the channel the job assigns. Every
other headset brings channels the faction should not have:

- `/obj/item/radio/headset/syndicatecity` is hard-tuned to `FREQ_DISCIPLINE`,
  which the remaining city syndicates all share. A faction using it is not
  private - the other syndicates hear everything on it.
- The department headsets (`headset_control`, `headset_safety` and friends)
  carry an encryption key. Key channels are merged into `channels` and survive
  alongside the faction channel, so the job ends up on both.

A frequency is allocated automatically from the `FREQ_JOB_CHANNEL_MIN` to
`FREQ_JOB_CHANNEL_MAX` band, which ordinary radios cannot tune into. Players
speak on it with `;`. The colour is an inline style, so no tgui rebuild is
needed.

## 5. Base capsule

If the faction has a base, give its capsule the same access so deploying it
updates the doors so only are only accessable by the faction:

	/obj/item/structurecapsule/syndicate/thumb
		name = "Thumb Capsule"
		template_id = "thumbfinger_base"
		custom_access = list("thumb_south")

The capsule scans a 23x13 rectangle around itself for doors, before the
template loads, and appends the access to each one. Tune the box with
`access_scan_width` and `access_scan_height`.

## 6. Include the files

Add every new `.dm` file to `lobotomy-corp13.dme`. Nothing loads without it.

## Checklist

- Leader points at itself, members point at the leader
- `faction_positions` set on every job, authored positions left at 0
- Access string in both `access` and `minimal_access`
- Radio name and colour on every job, faction headset in every outfit
- Faction block added to `factions.dm`
- Files added to the `.dme`

## Gotchas

- A job subtype inherits `leader`, so it is pulled into the faction unless you
  set `leader = null` on it. See `/datum/job/doctor/fixer`.
- Do not open member slots from the leader's `after_spawn()`. That fires after
  roundstart assignment has finished, so those slots would be latejoin-only.
  The faction system handles it.
- Do not reuse `/obj/item/radio/headset/syndicatecity` for a new faction. It is
  tuned to the shared Discipline frequency, and a keyed headset also diverts
  `:h` to the key's channel instead of the faction one.
- The system is inert outside `SSmaptype.citymaps`.
