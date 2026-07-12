// Hello and welcome to the insidious EGO tags define file
// Simply put, these defines are used as simple strings to put inside the list called 'ego_tags' in the datum/ego_datum type.
// You use them for easy searching and filtering of EGO in consoles like the EGO purchase console and testing range EGO printer.
// They have, or should have, no gameplay impact.

// Notice:
// Some of them, such as EGO_TAG_RANGED, EGO_TAG_GUARD, EGO_TAG_REACH, EGO_TAG_MINI and EGO_TAG_KNOCKBACK are automatically assigned when appropiate, but you can manually assign them if needed.
// For example, if you have a weapon that has a base reach of 1, but can temporarily change its reach to 4, you should manually assign it the EGO_TAG_REACH.
// All /ego_weapon/ranged are given EGO_TAG_RANGED.
// All /ego_weapon/shield are given EGO_TAG_GUARD.
// All /ego_weapon/lance are given EGO_TAG_MOBILITY.
// All /ego_weapon/ with a reach over 1 are given EGO_TAG_REACH.
// All /ego_weapon/ with a knockback over 0 are given EGO_TAG_KNOCKBACK.
// All /ego_weapon/ that exist in GLOB.small_ego are given EGO_TAG_MINI.
// All /ego_weapon/ranged/ with pellets > 1 are given EGO_TAG_MULTIHIT.
// All /armor/ego_gear/ with a slowdown < 0 are given EGO_TAG_MOBILITY.
// All /armor/ego_gear/realization/ are given EGO_TAG_REALIZED.

// More important notice:
// If you add an EGO_TAG make sure you also add it to EGO_TAGS_DESCRIPTION_LIST further below, and give it an appropiate description! This description is used in tooltips for the tag.

#define EGO_TAG_RANGED "Ranged Weapon"
#define EGO_TAG_GUARD "Guard"
#define EGO_TAG_REACH "Reach"
#define EGO_TAG_SPECIAL_RANGED "Special Ranged"
#define EGO_TAG_GUNBLADE "Gunblade"
#define EGO_TAG_THROWING "Throwing"
#define EGO_TAG_BOOMERANG "Boomerang"
#define EGO_TAG_MINI "Mini"
#define EGO_TAG_COMBO "Combo"
#define EGO_TAG_KNOCKBACK "Knockback"
#define EGO_TAG_MOBILITY "Mobility"
#define EGO_TAG_MULTIHIT "Multi-hit"
#define EGO_TAG_SPLIT_DAMAGE "Split Damage"
#define EGO_TAG_VERSATILE_DAMAGE "Versatile Damage"
#define EGO_TAG_SUSTAIN "Sustain"
#define EGO_TAG_AOE_RADIAL "AoE - Radial"
#define EGO_TAG_AOE_PIERCING "AoE - Piercing"
#define EGO_TAG_DOT "Damage Over Time"
#define EGO_TAG_DEBUFFER "Debuffer"
#define EGO_TAG_SUMMONER "Summoner"
#define EGO_TAG_SUPPORT "Support"
#define EGO_TAG_HAZARDOUS "Hazardous"
#define EGO_TAG_BLOODFEAST "Bloodfeast"
#define EGO_TAG_REALIZED "Realized"
#define EGO_TAG_REALIZABLE "Realizable"
#define EGO_TAG_LOCKED_POTENTIAL "Locked Potential"
#define EGO_TAG_RANKBUMP "Rankbump"
#define EGO_TAG_ASSIMILATION "Assimilation"


#define EGO_TAGS_DESCRIPTION_LIST list(\
	EGO_TAG_RANGED = "E.G.O. weapons primarily intended to fire projectiles. They generally lack Justice scaling.",\
	EGO_TAG_GUARD = "E.G.O. which is able to block or parry to reduce incoming damage.",\
	EGO_TAG_REACH = "E.G.O. which can reach further than usual in melee combat, including spears and whips. Typically either cause a self-stun on hit, or swing very slowly.",\
	EGO_TAG_SPECIAL_RANGED = "E.G.O. which has access to unconventional, non-projectile based ranged attacks, despite not being a ranged weapon.",\
	EGO_TAG_GUNBLADE = "E.G.O. which is meant to be used in melee, but can also fire projectiles at range.",\
	EGO_TAG_THROWING = "E.G.O. meant to be thrown at enemies to deal damage or apply special effects.",\
	EGO_TAG_BOOMERANG = "E.G.O. which will return to the user after being thrown.",\
	EGO_TAG_MINI = "E.G.O. weapons which can be stored in an E.G.O. small arms belt.",\
	EGO_TAG_COMBO = "E.G.O. which has access to combo attacks.",\
	EGO_TAG_KNOCKBACK = "E.G.O. which is able to displace enemies, usually directly away from the user; sometimes towards them.",\
	EGO_TAG_MOBILITY = "E.G.O. which provides the user with enhanced mobility, usually enabling an alternate means of travel like dashing, charging or teleportation.",\
	EGO_TAG_MULTIHIT = "E.G.O. which may hit several times per attack, including melee weapons that automatically chain attacks or shotgun-type weapons.",\
	EGO_TAG_SPLIT_DAMAGE = "E.G.O. which can deal multiple types of damage when attacking.",\
	EGO_TAG_VERSATILE_DAMAGE = "E.G.O. which can deal different types of damage at the user's discretion.",\
	EGO_TAG_SUSTAIN = "E.G.O. which is able to recover the user's health, sanity, or both.",\
	EGO_TAG_AOE_RADIAL = "E.G.O. capable of damaging or affecting enemies in a radius.",\
	EGO_TAG_AOE_PIERCING = "E.G.O. capable of piercing targets in a straight line.",\
	EGO_TAG_DOT = "E.G.O. capable of placing Damage over Time effects on enemies.",\
	EGO_TAG_DEBUFFER = "E.G.O. capable of applying impairing or otherwise weakening effects on enemies.",\
	EGO_TAG_SUMMONER = "E.G.O. capable of summoning mobs in some way.",\
	EGO_TAG_SUPPORT = "E.G.O. capable of providing support to allies, possibly including buffs or healing.",\
	EGO_TAG_HAZARDOUS = "E.G.O. which either poses a significant threat to its wielder or their own allies and requires cautious usage, or requires the user to harm or impair themselves to make full use of it.",\
	EGO_TAG_BLOODFEAST = "E.G.O. which can collect, store and make use of blood and giblets.",\
	EGO_TAG_REALIZED = "Powerful E.G.O. which is obtained from Golden Bough Resonance, able to be performed only by the strongest individuals.",\
	EGO_TAG_REALIZABLE = "E.G.O. armour which can be Realized to become an ALEPH-tier E.G.O. at a Realization Engine.",\
	EGO_TAG_LOCKED_POTENTIAL = "E.G.O. weapons which can be enhanced by wearing or wielding other specific E.G.O.; usually a counterpart weapon or Realization armour.",\
	EGO_TAG_RANKBUMP = "E.G.O. originating from an Abnormality with a lower threat class.",\
	EGO_TAG_ASSIMILATION = "An E.G.O. armour able to assimilate an ALEPH weapon into another, or an E.G.O. weapon generated through that process.",\
	)
