/*
 * Curtain Call pre-typed landmarks; each has its `id` baked into the type.
 *   start_point/<node_id> → id "<node_id>"        (AddNode arg 1)
 *   spawner/<node_id>     → id "<node_id>_spawns"  (AddNode arg 2)
 */

// ---------- Player start points (one per node) ----------

/obj/effect/landmark/refraction/start_point/zeal_s1n1
	id = "zeal_s1n1"

/obj/effect/landmark/refraction/start_point/zeal_s1n2
	id = "zeal_s1n2"

/obj/effect/landmark/refraction/start_point/zeal_s2n1
	id = "zeal_s2n1"

/obj/effect/landmark/refraction/start_point/zeal_s2n2
	id = "zeal_s2n2"

/obj/effect/landmark/refraction/start_point/zeal_s3n1
	id = "zeal_s3n1"

/obj/effect/landmark/refraction/start_point/zeal_s3n2
	id = "zeal_s3n2"

/obj/effect/landmark/refraction/start_point/zeal_s4n1
	id = "zeal_s4n1"

/obj/effect/landmark/refraction/start_point/zeal_s4n2
	id = "zeal_s4n2"

// Kept so the existing curtain_call.dmm continues to load while mappers
// migrate to the per-wave landmarks below.
/obj/effect/landmark/refraction/start_point/serio_zeal
	id = "serio_zeal"

/obj/effect/landmark/refraction/start_point/serio_zeal_w1
	id = "serio_zeal_w1"

/obj/effect/landmark/refraction/start_point/serio_zeal_w2
	id = "serio_zeal_w2"

// ---------- Mob spawners (one per node) ----------

/obj/effect/landmark/refraction/spawner/zeal_s1n1
	id = "zeal_s1n1_spawns"

/obj/effect/landmark/refraction/spawner/zeal_s1n2
	id = "zeal_s1n2_spawns"

/obj/effect/landmark/refraction/spawner/zeal_s2n1
	id = "zeal_s2n1_spawns"

/obj/effect/landmark/refraction/spawner/zeal_s2n2
	id = "zeal_s2n2_spawns"

/obj/effect/landmark/refraction/spawner/zeal_s3n1
	id = "zeal_s3n1_spawns"

/obj/effect/landmark/refraction/spawner/zeal_s3n2
	id = "zeal_s3n2_spawns"

/obj/effect/landmark/refraction/spawner/zeal_s4n1
	id = "zeal_s4n1_spawns"

/obj/effect/landmark/refraction/spawner/zeal_s4n2
	id = "zeal_s4n2_spawns"

// Kept so the existing curtain_call.dmm continues to load while mappers
// migrate to the per-wave spawners below.
/obj/effect/landmark/refraction/spawner/serio_zeal
	id = "serio_zeal_spawns"

/obj/effect/landmark/refraction/spawner/serio_zeal_w1
	id = "serio_zeal_w1_spawns"

/obj/effect/landmark/refraction/spawner/serio_zeal_w2
	id = "serio_zeal_w2_spawns"

// ---------- Per-node misc landmarks ----------
// Reload point: the Capo Rat in zeal_s1n1 pathfinds to one of these when the
// Thumb East Capo runs out of ammo, "loads up" for a few seconds, then runs
// the package back. If no landmark of this type is on the arena, the rat
// silently stays in normal-AI mode (graceful degradation).

/obj/effect/landmark/refraction/reload_point
	name = "refraction reload point"
	desc = "Courier-AI pathfinding target."

/obj/effect/landmark/refraction/reload_point/zeal_s1n1
	id = "zeal_s1n1_reload"
