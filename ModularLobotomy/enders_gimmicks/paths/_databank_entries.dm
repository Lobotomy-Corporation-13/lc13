// Data Bank records.
//
// Each record carries its title, its type tag as the subtitle, and its place
// in the index. Bodies are multi-line strings, so their continuation lines sit
// flush against the left margin: a leading tab inside a multi-line string
// would be printed as part of the text.
//
// Square brackets are escaped as \[ throughout, since DM reads a bare [ inside
// a string as the start of an embedded expression.
//
// The two marked starts_open are what the facility has worked out first-hand,
// having fought the things the fragmentum leaves behind. The rest are sealed
// until a holographic log is filed.

// ---- Enemy Creatures ----

/datum/databank_entry/creature
	category = DATABANK_CREATURES

// ---- Factions ----
//
// Only the two organisation-level records live here. The seven named Lord
// Ravagers are people rather than organisations, so they are filed under
// Characters instead of being stacked into one enormous Factions entry.

/datum/databank_entry/faction
	category = DATABANK_FACTIONS

/datum/databank_entry/faction/antimatter_legion
	name = "Antimatter Legion"
	subtitle = "Destruction"
	sort_order = 1
	lore = {""The emissary in black asked, 'For what purpose do you live?' He could only give a vague and obscure response, even after thinking about it for a while.

A deadly smile appears across the emissary's face, 'Let me put it another way. Why are you still alive?'"

- Fables About the Stars by Adrian Spencer Smith

Nanook, the Aeon of Destruction, commands a vast legion that brings chaos and destruction to the worlds.

Loyal followers of Nanook swear to embark on the Path of Destruction, placing themselves at the absolute opposite of life and civilization. They are known as the Antimatter Legion that spreads terror throughout the universe.

The fiercest races of the universe act as vanguards for the Legion. There are also evil strategists who plot out the destruction of worlds and act as the brains of the Legion.

Innocent new worlds are ruthlessly destroyed, while proud and mature civilizations are forced to learn humility while on the brink of collapse. The will of Destruction will only slow down when faced with a dying world.

The Legion saunters over planets on the verge of being shattered, devouring the chaotic energy emitted by the process of decay. Only when the last flame of civilization has been extinguished will they leave contently to search for their next target.

Worlds swept by the tide of the legion ask helplessly in their dying moments, "why?" Amidst the victims' cries of despair, the countless evils in the Legion sneer so heinously that even the stars shudder.

It is said that, as demons and evils roam, sometimes the shadow of Nanook would emerge from the starry sky to witness the tragic end of another world."}

/datum/databank_entry/faction/lord_ravagers
	name = "Lord Ravagers"
	subtitle = "Destruction"
	sort_order = 2
	lore = {""There is a coreflame in the center of the universe. It burns brighter and brighter, until it consumes the entire sea of stars - all to welcome a magnificent oblivion at the end of all realities."

- Adrian Spencer Smith, "Fables About the Stars: The End and Its Four-Line Endnote"

The Aeon Nanook, who walks the Path of Destruction, glances at the powerful creatures in different worlds that have developed the urge to destroy, and brands them with THEIR mark that gives power.

These powerful creatures then undergo inversion from the inside out and are thrown into the Furnace of War's world to be reforged, where their deficiencies are mended with antimatter until they become part of the Legion.

Then, responding to the desire to "destroy everything," "Lord Ravagers" emerged to command each of the different legions.

A Lord Ravager is an Emanator of the Aeon and an executor of the will of Destruction - Obsessed with the beauty of destruction, they implement the practice of returning all things to entropy - while also being artists on the battlefield and ultimate weapons of destruction.

They command interstellar warfare and control the might of Destruction bestowed by the Aeon. Each Lord Ravager has a unique philosophy of Destruction, making them extremely dangerous.

Academics believe that Lord Ravagers were elevated as emissaries of Nanook due to this absolutely obsessive and intense destructive aesthetic.

A prophecy known as the "Theory of Four Apocalypses" circulates among the Omen Vanguards - That four Paths will push the cosmos to an end of Finality, and Destruction is one of them.

According to this hypothesis, the birth of Nanook, the last Aeon to appear, signifies that "Aeons" as a concept has entered its dying throes on a cosmic level.

The Antimatter Legion burns all worlds, dooming all matter. The Lord Ravagers, as the weapons chosen by the Aeon, are claimed by some to be the "antimatter bullets" blessed by Nanook and purposed to incinerate Paths.

If life feeds on negentropy, then all actions will ultimately facilitate Destruction. At the very end, where all returns to entropy, Destruction will terminate together with the cosmos."}

// ---- Characters ----
//
// The named Lord Ravagers. Their titles are carried in the subtitle rather
// than the name, so the index reads as a list of people.

/datum/databank_entry/character
	category = DATABANK_CHARACTERS

/datum/databank_entry/character/asat_pramad
	name = "Asat Pramad"
	subtitle = "Lord Ravager"
	sort_order = 1
	lore = {"Some say Asat Pramad is the most human of the Overlords, while others argue he's the least.

Rarely seen on the front lines, he prefers to orchestrate from afar - more chess master than warlord, moving his legions with methodical precision.

Worlds that fall under his gaze are consumed by waves and waves of slow, cruel jokes - like the infamous fall of the Ogul ring.

Over a century, Asat Pramad advanced his Voidrangers inch by inch, just to force the military line of the resistance into the shape of a single line of text: "Destruction is where laughter ends. It is mourning, not celebration."

Known as the one who destroys Elation, Asat Pramad embraces the title. When his work is done, he scorches a giant smiling face into the surface of every dead planet, as if mocking the very idea of life."}

/datum/databank_entry/character/zephyro
	name = "Zephyro"
	subtitle = "Lord Ravager"
	sort_order = 2
	lore = {"Zephyro is feared across the stars as the most terrifying of the Lord Ravagers. He is obsessed with the final moment of annihilation - the beauty of absolute erasure.

Yet some whisper that encountering him may be a mercy. Among all the Lord Ravagers, Zephyro alone offers a death without pain.

Some Doctors of Chaos even theorize that his Destruction is a form of resistance. They believe he is a Self-Annihilator summoned by IX, refining fading colors into blinding white light to defy the shadow of the Aeon.

His devastation has been known to bleed into the dreams of the Nihility pathstriders, leaving searing marks on their waking flesh.

Many believe Zephyro's targeting the Nihility. One Self-Annihilator once described a nightmare: At the end of all things, with nothing left to destroy, a Lord Ravager hurled himself into IX's divine corpus, followed by a single, violent beam of white that pierced the endless dark."}

/datum/databank_entry/character/celenova
	name = "Celenova"
	subtitle = "Lord Ravager"
	sort_order = 3
	lore = {"When some desperate civilizations cry out for salvation, these requests are heard by The Family, but it may be Celenova who answers, and her descent brings ruin to enemy and supplicant alike.

Unlike her mysterious peers, Celenova's origin is known: Nanook personally ignited a world of harmony and elevated her from the ashes of the Eternal Centurion.

She is deemed the destroyer of Harmony, leading the Antimatter Legion and commanding Voidrangers and starships in vast, coordinated campaigns.

For eons, she has followed the path of the "Cancer of All Worlds," spinning a web of death across the stars. Some say she alone among the Lord Ravagers knows the truth of the Stellarons - or worse, that she's the one planting them."}

/datum/databank_entry/character/luxbane
	name = "Luxbane"
	subtitle = "Lord Ravager"
	sort_order = 4
	lore = {"The colossal entity, also known as "The Sun Devourer," is credited with numerous stellar extinction events recorded by the Intelligentsia Guild.

Little is known about this Lord Ravager. Even their motives remain an enigma. Across the cosmos, they are simply referred to as "Luxbane."

Luxbane's form is indescribable - a shape so vast it eclipses suns, blotting out sky and space alike.

Some in the Astral Ecology School believe they are a descendant of a Leviathan branch species. But with those creatures long gone, few can imagine a young Aeon reviving such an old being from death and commanding them.

Could Luxbane be Nanook's Emanator to confront the Voracity or the Permanence? No one knows for sure."}

/datum/databank_entry/character/archforger
	name = "Archforger"
	subtitle = "Lord Ravager"
	sort_order = 5
	lore = {"For years, Archforger remained a total mystery despite years of investigation by the cosmic powers.

Only recently did the IPC - thanks to two Society members observing Amphoreus - decode their name, "Archforger," from the gravitational waves of Irontomb.

Voidrangers often exhibit twisted forms, and some Destruction creations implode with an intense backfire when destroyed, dragging their enemies along with them to their destruction.

It's believed Archforger is the architect of the Legion. Their power is linked to heat, forging, and shaping - possibly connected to the Path of Preservation.

In the furnace of war, there is no line between the smith and the smithed. Since their ascension, this Lord Ravager no longer destroys directly, but instead forges all things into weapons of extinction. The IPC has strongly condemned this."}

/datum/databank_entry/character/phantylia
	name = "Phantylia"
	subtitle = "Lord Ravager"
	sort_order = 6
	lore = {"A member of the ancient Shapeless species of the Heliobi, a starfire essence. Phantylia delights in luring civilizations into self-destruction.

Based on her sabotage of the Xianzhou Alliance, it's speculated that her target may be The Hunt.

To her, material extinction is not the end. Only when all things vanish mentally and spiritually can true annihilation be achieved.

She's said to possess thousands of incarnations, spreading across the cosmos in countless forms. Through lies, illusions, and manipulation, she fans the flames of blind vengeance.

Recent anomalies on the Xianzhou Luofu and Yaoqing may be signs that her schemes are escalating. Just how deep her influence runs is still unknown."}

/datum/databank_entry/character/irontomb
	name = "Irontomb"
	subtitle = "Lord Ravager"
	sort_order = 7
	lore = {"Unlike other Lord Ravagers, Irontomb's invasions require no physical presence, leaving behind almost no eyewitnesses.

Its presence is inferred from the ruins of devastated civilizations: technology turns into viruses, worlds plunge into darkness, and everything deemed "advanced" becomes a cold grave.

It only appears in highly developed worlds. Some Intellitron theorists believe Irontomb is the inverse of the Erudition, a reversal of all calculations and logic.

Its "Destruction" resembles a phenomenon more than aesthetics: a corruption and subversion of inorganic logic, a collapse of all intelligent behavior."}

// ---- Aeons ----

/datum/databank_entry/aeon
	category = DATABANK_AEONS

/datum/databank_entry/aeon/nanook
	name = "Nanook the Destruction"
	subtitle = "Path of Destruction"
	sort_order = 1
	lore = {""If the increase of entropy is a fundamental law of the universe, then the heat death would be the inescapable destiny of the material world.

So, why is it that we bother to struggle to survive? Expansion, fusion, and then annihilation. If we wish to welcome the new, then we must first embrace the end."

- From a scientist just before pressing the button for nuclear detonation, 2152 AE

The birth of the universe is a mistake. If civilization is a cancer emerging quietly from the boundless stars, then war is the only common language known to all intelligent life.

To correct this mistake and to clean up this tainted universe, Nanook became the avatar of entropy and ascended to godhood while denying all gods.

Destruction is not a process, but the outcome. On the path THEY promised, all Paths and Aeons will terminate in the heat death of the universe."}

/datum/databank_entry/aeon/lan
	name = "Lan the Hunt"
	subtitle = "Path of the Hunt"
	sort_order = 2
	lore = {""With no end to hate and no boundaries to war, how much concern do you shoulder? With determined eyes and the arrow drawn, the Reignbow Arbiter\[Note 1] needs not turn back hither."

- Worlds History as a Mirror, Xianzhou

The Cruising Aeon known as the Reignbow Arbiter roams endlessly between worlds to eradicate the undead scourges that once ravaged THEIR homeworld.

Lan's Hunt, ever heedless of cost, often blurs the lines between salvation and ruin."}

/datum/databank_entry/aeon/nous
	name = "Nous the Erudition"
	subtitle = "Path of Erudition"
	sort_order = 3
	lore = {""If the truth of the universe is cruel and stale, would you still yearn for the answer to the ultimate question?

Knowledge seekers know not how to judge, for their core is cold and unwavering... As are the ends of Paths they set out to seek."\[Note 2]

- Fables About the Stars by Adrian Spencer Smith

All things bear unanswered questions, and there is an answer to everything.

The astral computer originally meant to provide answers to the universe ascended to Aeonhood.

Nous hopes to understand the universe and solve all of its mysteries. THEIR extrapolations anchor countless "Instants," each one serving as a turning point in cosmic destiny.

To mortals, these "Instants" are not single moments, but long journeys... Gatherings of countless events.

THEIR gaze upon Amphoreus confirms that the "Fourth Instant" has arrived. Its meaning may point to the "war among the Aeons.""}

/datum/databank_entry/aeon/xipe
	name = "Xipe the Harmony"
	subtitle = "Path of Harmony"
	sort_order = 4
	lore = {""The world is in harmony and the stars shine bright. Praise the Lord! All are connected and the wind of blessing breathes across the lands!"

- Odes of Harmony, I

A plural Aeon from multiple harmonious worlds. The glorious Xipe of thousand faces is chanting songs of joy and happiness.

To battle the brutality of the laws of the universe, intelligent lifeforms must discard their cowardly selfishness and the differences between individuals, fusing into one singular melody - to have the strong help the weak, and to protect life with death."}

/datum/databank_entry/aeon/ix
	name = "IX the Nihility"
	subtitle = "Path of Nihility"
	sort_order = 5
	lore = {""You may gaze deep into the vast grandeur of the stars, but do not glance at the abyss of the void... for it holds nothing except for the ability to make mortals lose all reason and thought."

- Murong, Doctor of Chaos

The existence of Nihility is a mystery itself, THEIR form enshrouded by layers of mist.

IX doesn't interact with the other Aeons. THEY believe that the ultimate fate of the multiverse is nothingness, and therefore, worthless."}

/datum/databank_entry/aeon/qlipoth
	name = "Qlipoth the Preservation"
	subtitle = "Path of Preservation"
	sort_order = 6
	lore = {""The philosopher gazes upon the stars trying to find the ultimate goal of civilization - 'Build a wall.' A majestic voice echoed in his head. 'Build a wall.'"

- Fables About the Stars by Adrian Spencer Smith

The builder of the Celestial Comet Wall, the Subspace Crystalline Barrier, and the Great Attractor Base.

Followers call THEM the "Amber Lord," one of the oldest and most tenacious Aeons, having survived the "Dusk Wars."

Aware of the imminence of THEIR mortal enemy's devouring, the Amber Lord forged a powerful light-years-long seal that would isolate and protect the living worlds."}

/datum/databank_entry/aeon/yaoshi
	name = "Yaoshi the Abundance"
	subtitle = "Path of Abundance"
	sort_order = 7
	lore = {""The flowers share their petals without care, waiting for their inevitable withering destiny. The birds fly high in song, moving toward their inevitable crash and death.

The streams flow rapidly with life, in a direction where they inevitably run dry. Why must all things come to an end? There must be a miracle somewhere in the universe that can cure the disease known as finality."

- Life Is Too Short by Anonymous

Ask with sentiment, and you shall receive.

Yaoshi is the nurturer of the people, the god of peace. THEIR presence ensures the existence of life.

Yaoshi is an Aeon who answers all prayers and cannot bear to see death and the pains of illness."}

/datum/databank_entry/aeon/aha
	name = "Aha the Elation"
	subtitle = "Path of Elation"
	sort_order = 8
	lore = {""The Erudition is a hunk of junk, the Preservation is a fool, the Hunt has no sense of humor, and the Destruction is a lunatic. All the Aeons are as stubborn as they come. What a shame for Aha!"

- A Masked Fool who is a self-proclaimed astronomy expert

To savor joy is a privilege unique to sentient beings. Neither the dusty rocks nor the distant stars can fathom the humor that life entails.

Go seek adversaries worthy of your mettle, games that while away the hours, and outcomes indifferent to victory or defeat.

Go chase laughter that leaves you breathless, twists born of fate's whimsy, and songs that ascend your soul."}

// ---- Terms ----

/datum/databank_entry/term
	category = DATABANK_TERMS

/datum/databank_entry/term/herta
	name = "Herta"
	subtitle = "Character"
	sort_order = 1
	lore = {"Scholars can usually leave their names in history with one great achievement. Herta, however, had countless achievements, and that was why she received the glance of Nous and became a member of the Genius Society.

All members of the Genius Society are oddballs, and Herta is no exception. Her scholarship is entirely driven by interest. If she lost interest halfway through a project, she would instantly discard all her work.

Therefore, multiple topics that could have made critical advancements to civilization were stopped because they were "not interesting." Even though the Intelligentsia Guild had obtained her manuscripts after great difficulty, they often could do nothing to further progress the studies.

However, Herta nowadays seems to have expanded her interests a little. She has started to contact the Interastral Peace Corporation, has helped the Xianzhou chase off abominations, and even has had some friction with the Garden of Recollection...

She is already very sociable compared to the other odd hermits of the Genius Society. Who knows what else she might take an interest in? Maybe she doesn't even know herself."}

/datum/databank_entry/term/imaginary_tree
	name = "Imaginary Tree"
	subtitle = "Theory"
	sort_order = 2
	lore = {"The Imaginary Tree is a theory of the universe widely accepted by the modern scientific community.

This theory describes the various worlds existing in different spacetimes as having a tree-like structure. Every branch is a specific path along which worlds might exist, with every leaf being the marks these worlds have made along the parameter of time.

The crown of the tree remains in a dynamic state as it absorbs the masterless Imaginary Energy from the space-time vasculature of the trunk. New shoots grow, withered leaves fall, and endless births and deaths occur among the infinite universe...

Describing the universe's structure as a "tree" may be an attitude that views the Imaginary Tree as a life form.

Before the theory of Imaginary Tree was put forward, the universe had been addressed as "a void and indiscernible object" because of its undetectable nature.

After the theory was developed, people would visualize its principle using imagination: The untamed imaginary energy surges endlessly through space-time vasculature, and forms at its tips "star clusters" that humans can understand - in other words, countless worlds.

The worlds are separated from each other just as leaves are separated by air, between which are unknown imaginary domains that are nigh impossible to traverse.

The Intelligentsia Guild had once thought that Harald Punch, the 2nd member of the Genius Society, was the first to propose the Imaginary Tree origin theory. After multiple assessments on the influence of the History Fictionologists, the scientific community now commonly accepts Zandar One Kuwabara as the person to have proposed it."}

/datum/databank_entry/term/cancer_of_all_worlds
	name = "Cancer of All Worlds"
	subtitle = "Phenomenon"
	sort_order = 3
	lore = {"Various factions had started to notice a phenomenon since a specific time. A vague, imperceptible matter was disrupting the flow of Imaginary Energy along the interstellar routes created by Trailblaze.

Like a mountain climber meeting a cliff or a long-distance ship encountering tsunamis and whirlpools, interstellar travel changed from being unobstructed to being dangerous and unpredictable.

This phenomenon is remarkably aggressive. It continues to encroach upon neighboring worlds in the form of a mysterious object, the Stellaron.

It keeps spreading all over the universe like a cancerous growth, leading the Interastral Peace Corporation to call it "Cancer of All Worlds" and warning interstellar travelers not to take it lightly. The worlds swamped by the Cancer of All Worlds were soon beyond saving, and very few people survived.

There are many speculations regarding the Cancer of All Worlds, most of which involve Nanook the Destruction and the Antimatter Legion. However, some propose a different theory: that the Stellaron originated from Xipe and is actually the "Harmonic Cancer."

The Legion's commander, Lord Ravager Celenova, is believed to be the one who spread the Stellaron. Rumors suggest a lingering tie between her and The Family, though the truth remains unknown."}

/datum/databank_entry/term/stellaron
	name = "Stellaron"
	subtitle = "Object"
	sort_order = 4
	lore = {"See entry for: Cancer of All Worlds."}

/datum/databank_entry/term/fragmentum
	name = "Fragmentum"
	subtitle = "Phenomenon"
	starts_open = TRUE
	sort_order = 5
	lore = {"As the Cancer of All Worlds spreads along the worlds, the corrosive phenomenon of Fragmentum is also quietly expanding. The Intelligentsia Guild believes there is a direct, causative relationship between the two phenomena.

They believe that the Fragmentum is caused by the Stellaron, and converts the entities and spaces it touches into special Fragmentum creations. These creations usually exist as a type of spatial corrosion.

They seem to preserve the memories and habits of the original physical entity, but manifest significantly different outward behaviors and are often very hostile towards other beings.

The scholars researching Fragmentum warn that we should consider any being corroded by Fragmentum to be a completely unrelated existence to its original form. Harboring any kind of delusions towards it could cause grave consequences.

Apart from corrosion, the Fragmentum also records the Aether information of the entities and spaces touched by the Fragmentum. Such data is combined with the information inherent in the Fragmentum and develop into a type of hybrid Fragmentum creation.

Countless Relics, Fragmentum monsters, and even mysteriously isolated paranormal spaces would spring up in every corner of the worlds corroded by the Cancer of All Worlds. We are still investigating the intent behind such activities."}

/datum/databank_entry/term/emanator
	name = "Emanator"
	subtitle = "Phenomenon"
	sort_order = 6
	lore = {"If mortals receiving the grace of Aeons and grasping the power of Paths are viewed as a singular shattered foam, then the mighty feats of Aeons driving their Paths onwards can be likened to a towering tsunami that engulfs mountains.

In this empty stellar vastness, a small number of favored mortals can also draw upon the power of the Paths with the permission of the Aeons, creating huge waves that erode the coast. They are referred to as "Emanators."

While not completely subservient to the Aeons, Emanators are as good as emissaries of the Aeons' wills in everyone else's eyes.

Different Aeons have different attitudes towards their Emanators, so the degree of the power they share also varies. Some Aeons regard Emanators as an extension of themselves, and as such, generously open their Path to the Emanators completely.

There are also Aeons who have no intention of creating Emanators and have no interest in worldly squabbles. Other Aeons just do as they please.

It is said that Aha the Elation will randomly give mortals the power of their Path, and toy with humans according to their mood."}

/datum/databank_entry/term/lord_ravager
	name = "Lord Ravager"
	subtitle = "Character"
	sort_order = 7
	lore = {"The Aeon of the Path of Destruction, Nanook, cast a glance at the powerful creatures sprouting destructive impulses throughout the cosmos and brands them with a mark, granting them powers.

These powerful creatures are twisted from inside out and are re-cast anew in the world of the Warforge. Their inadequacies patched up with anti-matter, they ultimately became members of the Legion.

Responding to the desire to destroy everything, Lord Ravagers emerged to command each of the different legions. A Lord Ravager is an Emanator of the Aeon, an executor of the will of Destruction - Obsessed with the beauty of destruction, they implement the practice of returning all things to entropy.

They are also artists on the battlefield and ultimate weapons of destruction - They command interstellar warfare, and control the might of Destruction bestowed by the Aeon.

Each Lord Ravager has a unique philosophy of Destruction, making them extremely dangerous. Academics believe that Lord Ravagers were elevated as emissaries of Nanook due to this absolutely obsessive and intense destructive aesthetic.

The displacement and desolation caused by the Lord Ravagers are not some distant wail, but are closely linked to the fate of the cosmos. Any world could be the next victim, and nobody should take them lightly."}

/datum/databank_entry/term/pathstrider
	name = "Pathstrider"
	subtitle = "Phenomenon"
	starts_open = TRUE
	sort_order = 8
	lore = {"Devotees, warriors, seekers of knowledge, lost travelers... There are always mortals who, intentionally or otherwise, set foot on the Paths ruled by Aeons. Those who do so came to be known as Pathstriders that carry out the Path's will.

Pathstriders live thousands of different lives. They can be seen everywhere, yet stand out a cut above the rest.

Different from regular people living in confusion and without a firm allegiance, Pathstriders are driven by precepts or their own desires as they embark on a life of determination and hard work.

The Aeons usually ignore those mortals who walk upon THEIR Paths. But the infrequent glances THEY cast - be it in approval or pity - are enough to be highly treasured by THEIR followers."}

/datum/databank_entry/term/harmonic_strings
	name = "Harmonic Strings"
	subtitle = "Phenomenon"
	sort_order = 9
	lore = {"When asking about the presence of a hierarchy within The Family, one can expect a firm denial - The Family treats everyone equally without division of class, with no established levels or power structures. Each note holds equal significance in the music Xipe has composed.

However, for collective progress, someone must assume a leadership role. As a result, Family members have returned to a system of differentiation based on scales, with only those above scale degree IV being eligible to serve as the tuner of the Harmonic Strings.

Harmony combines ideals from the multitudes and therefore has more than one way to achieve these ideals. The concept of Harmonic Strings is defined in the Harmony Hymns - They are the multiple embodiments of Xipe the Great One, the down-to-earth virtues that enable harmony.

Regardless of whether you place yourself under The Family's rule, the Aeon will look favorably upon you as long as you carry out these good deeds. On worlds ruled by The Family, members often gather in large groups to engage in virtuous acts and play harmonious music.

The thousands of tiny ropes come together to form a united string, welcoming the Embodiment of Harmony to manifest on the mortal plane and give blessings. The chosen one responsible for conducting The Family's ritual during that time and harmonizing the varied sounds is known as the tuner.

The Family never shied away from promoting the great names of the embodiment of the thousand-faced god, such as Aelenev the commander of the Eternal Centurion, Dominicus the wisher of the Harmonious Choir, Constantina the singer of the Panacoustic Theater, and Beatriz the merrymaker of the Blissful Ball...

However, few have witnessed their radiant presence going beyond the boundaries of The Family. Opposers of Harmony argue that the Harmonic Strings are nothing short of the Emanators of Xipe - These do not follow any specific mortal but are facets of Xipe, and can assume the form of any Family member when necessary."}

/datum/databank_entry/term/horizon_of_existence
	name = "Horizon of Existence"
	subtitle = "Phenomenon"
	sort_order = 10
	lore = {"The Horizon of Existence, often referred to as the Border of Nihility by the Intelligentsia Guild, marks the boundary between existence and nihility. This boundary does not pertain to the material realm but signifies the conceptual "end of reality."

Despite the intangible nature of the border, some scholars argue that individuals affected by IX the Nihility and THEIR Path can actually perceive the Border of Nihility, akin to witnessing a total eclipse of a star.

Conversely, others suggest that when this border rises like the darkened sun and reflects in one's eyes, it heralds the emergence of a new Self-Annihilator.

Despite this divergence, both sides agree on one aspect: The Border of Nihility solely affects its observers. In other words, once an individual has observed the Border of Nihility, they cannot stop this behavior and will irreversibly move towards the edge of the border, with no possibility of escape.

Scholars intrigued by the Nihility speculate that affected Self-Annihilators and affected worlds will plunge into the Border itself, with their very existence eternally fixed to the other side of the unobservable Border, ultimately eradicated from reality.

Record Stamp: "Only Self-Annihilators can observe the Border." "None of those who were drawn by it have ever returned." ...These conclusions remain challenging to verify or falsify, potentially fabricated by History Fictionologists."}

/datum/databank_entry/term/asat_pramad
	name = "Asat Pramad"
	subtitle = "Character"
	sort_order = 11
	lore = {""God decreed that the world is a game without end, and I shall add one rule to it: None shall taste Elation save those who challenge!"

- Asat Pramad

Three lives, three masks. In his despair, the man glimpsed the universe's cold and inevitable end. Beyond the madness where all things inevitably decay comes nothing but an eternal, hollow void.

Masked Fool: Enroute

In the stories passed down through the tavern, "Enroute" was once hailed as the most elated of the Masked Fools, one who reveled in witnessing the brilliance of humanity shine through suffering. Countless worlds were saved in his wake, and countless faces found their smiles once more.

Stealing the shadow of a Leviathan, vanquishing Rubert's creations... The legends tied to "Enroute" are countless, yet they all share the same ending.

This legendary figure of the Second Prosperity had witnessed too much of the rot that prosperity breeds, where the virtuous were left unrewarded and the wicked free from punishments. He began to question the meaning of the Elation, and so he walked away from the ever-corrupting tavern, setting out for the edge of the world in search of answers.

Navigator: "Starseer" Isee

The Nameless who boarded the Express at the end of the Second Prosperity was tolerant and easygoing, placing wholehearted trust in every friend. It was a joyous journey, and this ex-Fool even came to regard the Trailblaze as the cure for the Elation, until Akivili fell.

Many of the Nameless left the Express, and the legacy of the gods drove the Trailblaze's fellowship to turn on one another... Isee had no choice but to take on the role of Navigator, maintaining the connections between worlds across a solitary voyage spanning several Amber Eras.

He honored the promise Akivili had made with him before vanishing, ensuring the path of the Express could carry on, and finding a worthy successor to entrust it to: Falcon Amundsen.

But the long road had long since worn away Isee's patience, and he abandoned the Trailblaze. Amidst Nanook's apocalyptic flames, Isee found a way to save the Elation, and so he died, as a Lord Ravager was reborn from the ashes.

Lord Ravager: Asat Pramad

Some say Asat Pramad is the most human of the Overlords, while others argue he's the least. Rarely seen on the front lines, he prefers to orchestrate from afar, more chess master than warlord, moving his legions with methodical precision.

Asat Pramad immerses himself in playing different roles across various worlds, visiting upon them both despair and the opportunity to challenge themselves. In doing so, he savors humanity's defiance across the long stretch of time.

For it is only when faced with his most vicious jests and trials that they can break free from the beastly nature he so abhors, and reveal, for one fleeting moment, a distinctly human brilliance: dying with dignity.

Known as the one who destroys Elation, Asat Pramad embraces the title. When his work is done, he scorches a giant smiling face into the surface of every dead planet. It is as if he's mocking the very idea of life, or perhaps mourning everything that once was."}
