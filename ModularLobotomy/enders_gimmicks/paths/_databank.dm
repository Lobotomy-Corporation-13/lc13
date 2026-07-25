// The Data Bank: what the facility has managed to piece together about the
// place the Pathstriders came from.
//
// Every record is a datum sorted into one of five categories. Most start
// sealed. Holographic logs shake loose off fragmentum-touched ordeal mobs and
// Asat Pramad's void rangers, and feeding one into the terminal opens a record
// at random, so a drop is worth something right up until the bank is full.
//
// Records are read straight off the type tree rather than kept in a hand-
// written list, so adding lore later means adding a datum and nothing else.

#define DATABANK_CREATURES "Enemy Creatures"
#define DATABANK_AEONS "Aeons"
#define DATABANK_FACTIONS "Factions"
#define DATABANK_TERMS "Terms"
#define DATABANK_CHARACTERS "Characters"

/// Category order, which is also the order the terminal lays them out in.
GLOBAL_LIST_INIT(databank_categories, list(
	DATABANK_CREATURES,
	DATABANK_AEONS,
	DATABANK_CHARACTERS,
	DATABANK_TERMS,
	DATABANK_FACTIONS,
))

/// Every record in the game, built once off the type tree.
GLOBAL_LIST_EMPTY(databank_entries)
/// Records the facility has opened this round: "[type]" -> TRUE.
GLOBAL_LIST_EMPTY(databank_unlocked)
/// Every holographic log currently loose in the world and not yet filed.
GLOBAL_LIST_EMPTY(databank_loose_logs)

/// Chance for a holographic log to fall off something that carries them.
#define HOLO_LOG_DROP_CHANCE 2
/// Cans of enkephalin handed over for filing a log.
#define HOLO_LOG_PE_REWARD 10

// ---- Records ----

/datum/databank_entry
	/// Title, as it reads in the index.
	var/name = "unfiled record"
	var/category = DATABANK_TERMS
	/// One line under the title, for context at a glance.
	var/subtitle = ""
	/// The record itself. Left blank until the lore is written in.
	var/lore = "The transcription of this record is not yet complete."
	/// Set on the handful the facility already knows when the round opens.
	var/starts_open = FALSE
	/// Position within its category. Equal values fall back to title order.
	var/sort_order = 0
	/// Set on the per-category bases, which carry settings rather than lore.
	var/abstract = FALSE

/// Builds the record list on first use and hands it back.
/proc/GetDatabankEntries()
	if(length(GLOB.databank_entries))
		return GLOB.databank_entries
	for(var/entry_type in subtypesof(/datum/databank_entry))
		var/datum/databank_entry/E = new entry_type()
		if(E.abstract)
			qdel(E)
			continue
		GLOB.databank_entries += E
		if(E.starts_open)
			GLOB.databank_unlocked["[entry_type]"] = TRUE
	return GLOB.databank_entries

/proc/DatabankIsOpen(datum/databank_entry/E)
	return !isnull(GLOB.databank_unlocked["[E.type]"])

/// Every record still sealed, in no particular order.
/proc/DatabankSealedEntries()
	var/list/sealed = list()
	for(var/datum/databank_entry/E as anything in GetDatabankEntries())
		if(!DatabankIsOpen(E))
			sealed += E
	return sealed

/// Opens one sealed record at random. Returns it, or null if none are left.
/proc/DatabankOpenRandom()
	var/list/sealed = DatabankSealedEntries()
	if(!length(sealed))
		return null
	var/datum/databank_entry/E = pick(sealed)
	GLOB.databank_unlocked["[E.type]"] = TRUE
	return E

// ---- Holographic logs ----

/obj/item/holo_log
	name = "holographic log"
	desc = "A palm-sized slate throwing a slow diamond of light above itself. \
		Something recorded this, a long way from here, and meant it to be read."
	icon = 'ModularLobotomy/_Lobotomyicons/holo_log.dmi'
	icon_state = "holo_log"
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 0
	force = 0
	/// A particular record to open. Left null, it opens whatever is sealed.
	var/datum/databank_entry/bound_entry

/obj/item/holo_log/Initialize(mapload)
	. = ..()
	GLOB.databank_loose_logs += src

/obj/item/holo_log/Destroy()
	GLOB.databank_loose_logs -= src
	return ..()

/obj/item/holo_log/examine(mob/user)
	. = ..()
	. += span_notice("A data bank terminal could read this.")

/// Rolls the drop for anything that carries logs. Called from death procs.
///
/// A log is only worth something if there is a sealed record left for it to
/// open, so the number already loose in the world is counted against the
/// number still sealed. Once the two match, mobs stop dropping them: further
/// logs could only ever be filed as duplicates.
/proc/RollHoloLog(turf/T)
	if(!T || !prob(HOLO_LOG_DROP_CHANCE))
		return
	if(length(GLOB.databank_loose_logs) >= length(DatabankSealedEntries()))
		return
	new /obj/item/holo_log(T)

#undef HOLO_LOG_DROP_CHANCE
