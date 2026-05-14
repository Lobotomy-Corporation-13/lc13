/*
 * Nova Flare pre-typed landmarks.
 *
 * Each landmark variant has its `id` baked into the type itself, so the
 * dmm just references the typed path with no var-override block. This is
 * map-editor-friendly: StrongDMM treats the typed subtype as a standard
 * obj path it can drop on a tile, and there's nothing to edit per-tile.
 *
 * Naming convention:
 *   start_point/<node_id>      → id = "<node_id>"           (matches AddNode arg 1)
 *   spawner/<node_id>          → id = "<node_id>_spawns"    (matches AddNode arg 2)
 *
 * Parent type names (`start_point`, `spawner`) deliberately avoid `spawn`
 * as a path component; the BYOND runtime dmm loader trips on
 * `/spawn/<child>` paths because `spawn` is also a DM control-flow
 * keyword.
 *
 * If you add a new node to nova_flare via AddNode("foo", "foo_spawns", ...),
 * also add `/obj/effect/landmark/refraction/start_point/foo` and
 * `/obj/effect/landmark/refraction/spawner/foo` here, then place them in
 * the dmm wherever players should land and where mobs should spawn.
 */

// ---------- Player start points (one per node) ----------

/obj/effect/landmark/refraction/start_point/nova_s1n1
	id = "nova_s1n1"

/obj/effect/landmark/refraction/start_point/nova_s1n2
	id = "nova_s1n2"

/obj/effect/landmark/refraction/start_point/nova_s1n3
	id = "nova_s1n3"

/obj/effect/landmark/refraction/start_point/nova_s2n1
	id = "nova_s2n1"

/obj/effect/landmark/refraction/start_point/nova_s2n2
	id = "nova_s2n2"

/obj/effect/landmark/refraction/start_point/nova_s2n3
	id = "nova_s2n3"

/obj/effect/landmark/refraction/start_point/nova_s3n1
	id = "nova_s3n1"

/obj/effect/landmark/refraction/start_point/nova_s3n2
	id = "nova_s3n2"

/obj/effect/landmark/refraction/start_point/nova_core
	id = "nova_core"

// ---------- Mob spawners (one per node) ----------

/obj/effect/landmark/refraction/spawner/nova_s1n1
	id = "nova_s1n1_spawns"

/obj/effect/landmark/refraction/spawner/nova_s1n2
	id = "nova_s1n2_spawns"

/obj/effect/landmark/refraction/spawner/nova_s1n3
	id = "nova_s1n3_spawns"

/obj/effect/landmark/refraction/spawner/nova_s2n1
	id = "nova_s2n1_spawns"

/obj/effect/landmark/refraction/spawner/nova_s2n2
	id = "nova_s2n2_spawns"

/obj/effect/landmark/refraction/spawner/nova_s2n3
	id = "nova_s2n3_spawns"

/obj/effect/landmark/refraction/spawner/nova_s3n1
	id = "nova_s3n1_spawns"

/obj/effect/landmark/refraction/spawner/nova_s3n2
	id = "nova_s3n2_spawns"

/obj/effect/landmark/refraction/spawner/nova_core
	id = "nova_core_spawns"
