//config files
#define CONFIG_GET(X) global.config.Get(/datum/config_entry/##X)
#define CONFIG_SET(X, Y) global.config.Set(/datum/config_entry/##X, ##Y)

#define CONFIG_MAPS_FILE "maps.txt"

//flags
/// can't edit
#define CONFIG_ENTRY_LOCKED 1
/// can't see value
#define CONFIG_ENTRY_HIDDEN 2

// Submaps
/// If no submap is chosen, chooses the first map file as a default.
#define SUBMAP_DEFAULT_STANDARD "standard"
/// If no submap is chosen, chooses a random map file to play on.
#define SUBMAP_DEFAULT_RANDOM "random"
