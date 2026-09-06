class_name FishCatalog
extends RefCounted

## Single source of truth for every fishing species.
##
## `FishId` is the stable enum used by code. The string `id` is persisted in
## save data, so existing starter IDs must never be renamed.

enum FishId {
	GREEN_FISH,
	CORAL_ANGELFISH,
	GOLDEN_RIBBONFISH,
	BLUE_SMALL_FISH,
	YELLOW_STRIPED_FISH,
	PINK_SALMON,
	BLUE_TANG,
	PEACH_GOBY,
	SILVER_BLUE_MACKEREL,
	TURQUOISE_GUPPY,
	CLOWNFISH,
	RED_CARDINALFISH,
	MINT_CATFISH,
	YELLOW_BOXFISH,
	RED_WHITE_KOI,
	PURPLE_BUTTERFLY_FISH,
	ROUND_PUFFERFISH,
	LAVENDER_MOONFISH,
	DEEP_BLUE_TUNA,
	LIONFISH,
	STARLIGHT_FISH,
	BROWN_ANGLERFISH,
	NEON_TETRA,
	ZEBRA_DANIO,
	BLACK_MOLLY,
	SUNSET_SWORDTAIL,
	RUBY_BETTA,
	FIRE_DARTFISH,
	SAPPHIRE_DISCUS,
	ROYAL_GRAMMA,
	MANDARIN_DRAGONET,
	RAINBOW_PARROTFISH,
	PICASSO_TRIGGERFISH,
	MOORISH_IDOL,
	SPOTTED_FROGFISH,
	SILVER_FLYINGFISH,
	GLASS_KNIFEFISH,
	ELECTRIC_EEL,
	EMERALD_SEAHORSE,
	BLUE_SPOTTED_STINGRAY,
	MORAY_EEL,
	SPOTTED_GAR,
	RED_AROWANA,
	GOLDEN_MANTA_RAY,
	BABY_WHALE_SHARK,
	HAMMERHEAD_SHARK,
	GIANT_ARAPAIMA,
	ANCIENT_STURGEON,
	OCEAN_SUNFISH,
	LEAFY_SEADRAGON,
	SAWFISH,
	COELACANTH
}

const MIN_RARITY_LEVEL := 0
const MAX_RARITY_LEVEL := 15
const AQUARIUM_CAPACITY := 10
const DEFAULT_AQUARIUM_FISH_IDS: Array[String] = ["green"]
const BASE_GOAL_COUNTS_BY_RARITY_LEVEL: Array[int] = [
	10, 10, 10,
	8, 8, 8,
	6, 6, 6,
	4, 4, 4,
	2, 2, 2,
	2
]
const BASE_GOAL_COUNT_OVERRIDES := {
	"coelacanth": 1
}
# Runtime spawn weights are grouped by rarity so the curve is transparent and
# late-game fish remain meaningfully obtainable. The rarest tier is one fourth
# as likely as the most common tier, rather than one hundredth as likely.
const SPAWN_WEIGHTS_BY_RARITY_LEVEL: Array[float] = [
	1.00, 0.95, 0.90, 0.85,
	0.80, 0.75, 0.70, 0.65,
	0.60, 0.55, 0.50, 0.45,
	0.40, 0.35, 0.30, 0.25
]
const FORCE_OPAQUE_SHADER_CODE := """
shader_type canvas_item;

void fragment() {
	vec4 sampled = texture(TEXTURE, UV);
	float opaque_alpha = smoothstep(0.02, 0.18, sampled.a);
	COLOR = vec4(sampled.rgb, opaque_alpha) * COLOR;
}
"""

# Ordered from most common to rarest. A lower spawn weight makes a species
# appear less often; speed_multiplier changes how quickly it crosses the river.
# Rare fish are intentionally not all fast: silhouette, scarcity, and speed can
# each provide a different kind of difficulty.
const RAW_FISH_TYPES: Array[Dictionary] = [
	{
		"enum_id": FishId.GREEN_FISH,
		"id": "green",
		"name": "Green Fish",
		"rarity_level": 0,
		"description": "A LEAF WITH FINS. IT REFUSES TO EXPLAIN THE DIFFERENCE.",
		"speed_multiplier": 1.00,
		"base_goal_count": 4,
		"swim_size": Vector2(47.5, 30),
		"catch_popup_scale": 0.5,
		# This source image is tightly cropped, so fitting it to the common
		# Fish Book bounds makes the visible body much larger than nearby fish.
		"fish_book_slot_scale": 0.72,
		"fish_book_detail_scale": 0.52,
		"texture": preload("res://assets/ui/fishing/fish/processed/green_fish_v2.png"),
		"texture_region": Rect2(0, 0, 968, 515)
	},
	{
		"enum_id": FishId.CORAL_ANGELFISH,
		"id": "coral",
		"name": "Coral Angelfish",
		"rarity_level": 0,
		"description": "DRESSED FOR A GALA THAT MAY OR MAY NOT BE HAPPENING.",
		"speed_multiplier": 1.03,
		"base_goal_count": 3,
		"swim_size": Vector2(62, 56),
		"texture": preload("res://assets/ui/fishing/fish/processed/coral_angelfish_v2.png"),
		"texture_region": Rect2(330, 287, 637, 679)
	},
	{
		"enum_id": FishId.GOLDEN_RIBBONFISH,
		"id": "golden",
		"name": "Golden Ribbonfish",
		"rarity_level": 0,
		"description": "SO LONG THAT ITS TAIL ARRIVES SLIGHTLY AFTER THE REST OF IT.",
		"speed_multiplier": 1.06,
		"base_goal_count": 2,
		"swim_size": Vector2(138, 65),
		"texture": preload("res://assets/ui/fishing/fish/processed/golden_ribbonfish_v2.png"),
		"texture_region": Rect2(162, 336, 1458, 226)
	},
	{
		"enum_id": FishId.BLUE_SMALL_FISH,
		"id": "blue_small",
		"name": "Blue Small Fish",
		"rarity_level": 1,
		"description": "SMALL, BLUE, AND ABSOLUTELY CERTAIN IT IS THE OCEAN'S MANAGER.",
		"speed_multiplier": 1.08,
		"base_goal_count": 4,
		"swim_size": Vector2(188, 122),
		"texture": preload("res://assets/ui/fishing/fish/processed/blue_small_fish.png")
	},
	{
		"enum_id": FishId.YELLOW_STRIPED_FISH,
		"id": "yellow_striped",
		"name": "Yellow Striped Fish",
		"rarity_level": 1,
		"description": "WEARS RACING STRIPES. HAS NEVER READ THE RULES.",
		"speed_multiplier": 1.10,
		"base_goal_count": 4,
		"swim_size": Vector2(96, 64),
		"texture": preload("res://assets/ui/fishing/fish/processed/yellow_striped_fish.png")
	},
	{
		"enum_id": FishId.PINK_SALMON,
		"id": "pink_salmon",
		"name": "Pink Salmon",
		"rarity_level": 1,
		"description": "SWIMS UPSTREAM MOSTLY TO AVOID AWKWARD SMALL TALK.",
		"speed_multiplier": 1.06,
		"base_goal_count": 3,
		"swim_size": Vector2(204.75, 120.9),
		"texture": preload("res://assets/ui/fishing/fish/processed/pink_salmon_v2.png"),
		"goal_texture_region": Rect2(51, 396, 1152, 460)
	},
	{
		"enum_id": FishId.BLUE_TANG,
		"id": "blue_tang",
		"name": "Blue Tang",
		"rarity_level": 1,
		"description": "IT HAS BEEN BLUE ALL DAY. NOBODY ASKED WHY.",
		"speed_multiplier": 1.12,
		"base_goal_count": 3,
		"swim_size": Vector2(99, 67),
		"texture": preload("res://assets/ui/fishing/fish/processed/blue_tang.png")
	},
	{
		"enum_id": FishId.PEACH_GOBY,
		"id": "peach_goby",
		"name": "Peach Goby",
		"rarity_level": 2,
		"description": "SITS NEAR THE BOTTOM AND JUDGES EVERYONE FROM A COMFORTABLE ANGLE.",
		"speed_multiplier": 0.94,
		"base_goal_count": 3,
		"swim_size": Vector2(101, 58),
		"texture": preload("res://assets/ui/fishing/fish/processed/peach_goby.png")
	},
	{
		"enum_id": FishId.SILVER_BLUE_MACKEREL,
		"id": "silver_mackerel",
		"name": "Silver Blue Mackerel",
		"rarity_level": 2,
		"description": "FAST, SHINY, AND ALWAYS LATE FOR SOMEWHERE IMPORTANT.",
		"speed_multiplier": 1.16,
		"base_goal_count": 3,
		"swim_size": Vector2(108, 58),
		"texture": preload("res://assets/ui/fishing/fish/processed/silver_blue_mackerel.png")
	},
	{
		"enum_id": FishId.TURQUOISE_GUPPY,
		"id": "turquoise_guppy",
		"name": "Turquoise Guppy",
		"rarity_level": 2,
		"description": "HOLDS SECRET MEETINGS. FORGOT WHAT THE MEETING WAS ABOUT.",
		"speed_multiplier": 1.20,
		"base_goal_count": 3,
		"swim_size": Vector2(103, 67),
		"texture": preload("res://assets/ui/fishing/fish/processed/turquoise_guppy.png")
	},
	{
		"enum_id": FishId.CLOWNFISH,
		"id": "clownfish",
		"name": "Clownfish",
		"rarity_level": 2,
		"description": "TELLS TERRIBLE JOKES. THE ANEMONE LAUGHS ANYWAY.",
		"speed_multiplier": 1.12,
		"base_goal_count": 3,
		"swim_size": Vector2(100, 66),
		"texture": preload("res://assets/ui/fishing/fish/processed/clownfish.png")
	},
	{
		"enum_id": FishId.RED_CARDINALFISH,
		"id": "red_cardinalfish",
		"name": "Red Cardinalfish",
		"rarity_level": 3,
		"description": "LAUGHS AT ALL KINDS OF JOKES.",
		"speed_multiplier": 1.23,
		"base_goal_count": 3,
		"swim_size": Vector2(106, 61),
		"texture": preload("res://assets/ui/fishing/fish/processed/red_cardinalfish.png")
	},
	{
		"enum_id": FishId.MINT_CATFISH,
		"id": "mint_catfish",
		"name": "Mint Catfish",
		"rarity_level": 3,
		"description": "HAS WHISKERS, NO CAT, AND SEVERAL UNANSWERED QUESTIONS.",
		"speed_multiplier": 0.91,
		"base_goal_count": 3,
		"swim_size": Vector2(102.9, 50.89),
		"force_opaque": true,
		"texture": preload("res://assets/ui/fishing/fish/processed/mint_catfish_v2.png"),
		"texture_region": Rect2(57, 139, 1438, 711)
	},
	{
		"enum_id": FishId.YELLOW_BOXFISH,
		"id": "yellow_boxfish",
		"name": "Yellow Boxfish",
		"rarity_level": 3,
		"description": "THINKS OUTSIDE THE BOX. UNFORTUNATELY, IT IS THE BOX.",
		"speed_multiplier": 0.87,
		"base_goal_count": 2,
		"swim_size": Vector2(92, 68),
		"texture": preload("res://assets/ui/fishing/fish/processed/yellow_boxfish.png")
	},
	{
		"enum_id": FishId.RED_WHITE_KOI,
		"id": "red_white_koi",
		"name": "Red White Koi",
		"rarity_level": 4,
		"description": "SWIMS LIKE A PAINTING THAT DECIDED TO TAKE THE DAY OFF.",
		"speed_multiplier": 1.17,
		"base_goal_count": 2,
		"swim_size": Vector2(136.5, 81.9),
		"texture": preload("res://assets/ui/fishing/fish/processed/red_white_koi_v2.png")
	},
	{
		"enum_id": FishId.PURPLE_BUTTERFLY_FISH,
		"id": "purple_butterfly",
		"name": "Purple Butterfly Fish",
		"rarity_level": 4,
		"description": "HALF FISH, HALF BUTTERFLY, FULL-TIME DRAMA.",
		"speed_multiplier": 1.25,
		"base_goal_count": 2,
		"swim_size": Vector2(99, 72),
		"texture": preload("res://assets/ui/fishing/fish/processed/purple_butterfly_fish.png")
	},
	{
		"enum_id": FishId.ROUND_PUFFERFISH,
		"id": "round_pufferfish",
		"name": "Round Pufferfish",
		"rarity_level": 4,
		"description": "MOSTLY CIRCLE. OCCASIONALLY OPINION.",
		"speed_multiplier": 0.83,
		"base_goal_count": 2,
		"swim_size": Vector2(90, 75),
		"texture": preload("res://assets/ui/fishing/fish/processed/round_pufferfish.png")
	},
	{
		"enum_id": FishId.LAVENDER_MOONFISH,
		"id": "lavender_moonfish",
		"name": "Lavender Moonfish",
		"rarity_level": 5,
		"description": "CLAIMS THE MOON IS JUST A VERY DISTANT POND.",
		"speed_multiplier": 0.93,
		"base_goal_count": 2,
		"swim_size": Vector2(88, 82),
		"texture": preload("res://assets/ui/fishing/fish/processed/lavender_moonfish.png")
	},
	{
		"enum_id": FishId.DEEP_BLUE_TUNA,
		"id": "deep_blue_tuna",
		"name": "Deep Blue Tuna",
		"rarity_level": 5,
		"description": "BUILT FOR SPEED AND MILDLY CONCERNED ABOUT SANDWICHES.",
		"speed_multiplier": 1.37,
		"base_goal_count": 2,
		"swim_size": Vector2(116, 62),
		"texture": preload("res://assets/ui/fishing/fish/processed/deep_blue_tuna.png")
	},
	{
		"enum_id": FishId.LIONFISH,
		"id": "lionfish",
		"name": "Lionfish",
		"rarity_level": 6,
		"description": "HAS A ROYAL MANE AND ZERO INTEREST IN ROYAL DUTIES.",
		"speed_multiplier": 0.89,
		"base_goal_count": 1,
		"swim_size": Vector2(104, 78),
		"texture": preload("res://assets/ui/fishing/fish/processed/lionfish.png")
	},
	{
		"enum_id": FishId.STARLIGHT_FISH,
		"id": "starlight_fish",
		"name": "Starlight Fish",
		"rarity_level": 6,
		"description": "GLOWS JUST ENOUGH TO BE MYSTERIOUS, NOT ENOUGH TO PAY THE ELECTRIC BILL.",
		"speed_multiplier": 1.31,
		"base_goal_count": 1,
		"swim_size": Vector2(102, 70),
		"texture": preload("res://assets/ui/fishing/fish/processed/starlight_fish.png")
	},
	{
		"enum_id": FishId.BROWN_ANGLERFISH,
		"id": "brown_anglerfish",
		"name": "Brown Anglerfish",
		"rarity_level": 7,
		"description": "CARRIES ITS OWN LAMP BECAUSE THE DEEP SEA HAS TERRIBLE CUSTOMER SERVICE.",
		"speed_multiplier": 0.74,
		"base_goal_count": 1,
		"swim_size": Vector2(104, 76),
		"texture": preload("res://assets/ui/fishing/fish/processed/brown_anglerfish.png")
	},
	{
		"enum_id": FishId.NEON_TETRA,
		"id": "neon_tetra",
		"name": "Neon Tetra",
		"rarity_level": 7,
		"description": "SMALL ENOUGH TO MISS, BRIGHT ENOUGH TO FILE A COMPLAINT.",
		"speed_multiplier": 1.28,
		"base_goal_count": 1,
		"swim_size": Vector2(200, 110),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/neon_tetra.png")
	},
	{
		"enum_id": FishId.ZEBRA_DANIO,
		"id": "zebra_danio",
		"name": "Zebra Danio",
		"rarity_level": 7,
		"description": "COUNTS ITS STRIPES WHENEVER THE WIFI GOES OUT.",
		"speed_multiplier": 1.34,
		"base_goal_count": 1,
		"swim_size": Vector2(208, 108),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/zebra_danio.png")
	},
	{
		"enum_id": FishId.BLACK_MOLLY,
		"id": "black_molly",
		"name": "Black Molly",
		"rarity_level": 8,
		"description": "DRESSED FOR MIDNIGHT. ARRIVED AT NOON.",
		"speed_multiplier": 0.95,
		"base_goal_count": 1,
		"swim_size": Vector2(98, 65),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/black_molly.png")
	},
	{
		"enum_id": FishId.SUNSET_SWORDTAIL,
		"id": "sunset_swordtail",
		"name": "Sunset Swordtail",
		"rarity_level": 8,
		"description": "BROUGHT A SWORD TO A SWIMMING LESSON. POLITELY.",
		"speed_multiplier": 1.20,
		"base_goal_count": 1,
		"swim_size": Vector2(118, 60),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/sunset_swordtail.png")
	},
	{
		"enum_id": FishId.RUBY_BETTA,
		"id": "ruby_betta",
		"name": "Ruby Betta",
		"rarity_level": 8,
		"description": "HAS A CAPE, NO KINGDOM, AND A VERY BUSY MIRROR.",
		"speed_multiplier": 1.05,
		"base_goal_count": 1,
		"swim_size": Vector2(100, 72),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/ruby_betta.png")
	},
	{
		"enum_id": FishId.FIRE_DARTFISH,
		"id": "fire_dartfish",
		"name": "Fire Dartfish",
		"rarity_level": 8,
		"description": "LOOKS LIKE A COMET, PANICS LIKE A PAPERCLIP.",
		"speed_multiplier": 1.42,
		"base_goal_count": 1,
		"swim_size": Vector2(112, 52),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/fire_dartfish.png")
	},
	{
		"enum_id": FishId.SAPPHIRE_DISCUS,
		"id": "sapphire_discus",
		"name": "Sapphire Discus",
		"rarity_level": 9,
		"description": "ROUND, BLUE, AND CONVINCED EVERY POND IS A BALLROOM.",
		"speed_multiplier": 0.88,
		"base_goal_count": 1,
		"swim_size": Vector2(91, 80),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/sapphire_discus.png")
	},
	{
		"enum_id": FishId.ROYAL_GRAMMA,
		"id": "royal_gramma",
		"name": "Royal Gramma",
		"rarity_level": 9,
		"description": "HALF PURPLE, HALF YELLOW, COMPLETELY IN CHARGE OF NOTHING.",
		"speed_multiplier": 1.18,
		"base_goal_count": 1,
		"swim_size": Vector2(98, 65),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/royal_gramma.png")
	},
	{
		"enum_id": FishId.MANDARIN_DRAGONET,
		"id": "mandarin_dragonet",
		"name": "Mandarin Dragonet",
		"rarity_level": 9,
		"description": "WEARS EVERY COLOR IT COULD FIND BEFORE BREAKFAST.",
		"speed_multiplier": 1.12,
		"base_goal_count": 1,
		"swim_size": Vector2(105, 70),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/mandarin_dragonet.png")
	},
	{
		"enum_id": FishId.RAINBOW_PARROTFISH,
		"id": "rainbow_parrotfish",
		"name": "Rainbow Parrotfish",
		"rarity_level": 9,
		"description": "BITES ROCKS AND CALLS IT INTERIOR DESIGN.",
		"speed_multiplier": 1.04,
		"base_goal_count": 1,
		"swim_size": Vector2(103, 68),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/rainbow_parrotfish.png")
	},
	{
		"enum_id": FishId.PICASSO_TRIGGERFISH,
		"id": "picasso_triggerfish",
		"name": "Picasso Triggerfish",
		"rarity_level": 10,
		"description": "PAINTED ITSELF. REFUSES ALL FOLLOW-UP QUESTIONS.",
		"speed_multiplier": 1.14,
		"base_goal_count": 1,
		"swim_size": Vector2(100, 68),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/picasso_triggerfish.png")
	},
	{
		"enum_id": FishId.MOORISH_IDOL,
		"id": "moorish_idol",
		"name": "Moorish Idol",
		"rarity_level": 10,
		"description": "THE FIN IS FORMAL. THE SCHEDULE IS NOT.",
		"speed_multiplier": 1.10,
		"base_goal_count": 1,
		"swim_size": Vector2(92, 86),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/moorish_idol.png")
	},
	{
		"enum_id": FishId.SPOTTED_FROGFISH,
		"id": "spotted_frogfish",
		"name": "Spotted Frogfish",
		"rarity_level": 10,
		"description": "WALKED INTO THE OCEAN AND FORGOT TO KEEP WALKING.",
		"speed_multiplier": 0.72,
		"base_goal_count": 1,
		"swim_size": Vector2(96, 72),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/spotted_frogfish.png")
	},
	{
		"enum_id": FishId.SILVER_FLYINGFISH,
		"id": "silver_flyingfish",
		"name": "Silver Flyingfish",
		"rarity_level": 10,
		"description": "FLIES JUST LONG ENOUGH TO MISS THE NEXT MEETING.",
		"speed_multiplier": 1.48,
		"base_goal_count": 1,
		"swim_size": Vector2(175, 85.4),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/silver_flyingfish.png")
	},
	{
		"enum_id": FishId.GLASS_KNIFEFISH,
		"id": "glass_knifefish",
		"name": "Glass Knifefish",
		"rarity_level": 11,
		"description": "NEITHER GLASS NOR A KNIFE. MARKETING WAS INVOLVED.",
		"speed_multiplier": 0.90,
		"base_goal_count": 1,
		"swim_size": Vector2(195, 72),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/glass_knifefish.png")
	},
	{
		"enum_id": FishId.ELECTRIC_EEL,
		"id": "electric_eel",
		"name": "Electric Eel",
		"rarity_level": 11,
		"description": "FULLY CHARGED. CANNOT FIND THE CORRECT CABLE.",
		"speed_multiplier": 1.30,
		"base_goal_count": 1,
		"swim_size": Vector2(171.6, 72.8),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/electric_eel.png")
	},
	{
		"enum_id": FishId.EMERALD_SEAHORSE,
		"id": "emerald_seahorse",
		"name": "Emerald Seahorse",
		"rarity_level": 11,
		"description": "RIDES NO HORSES. STILL INSISTS ON THE TITLE.",
		"speed_multiplier": 0.78,
		"base_goal_count": 1,
		"swim_size": Vector2(78, 100),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/emerald_seahorse.png")
	},
	{
		"enum_id": FishId.BLUE_SPOTTED_STINGRAY,
		"id": "blue_spotted_stingray",
		"name": "Blue-Spotted Stingray",
		"rarity_level": 11,
		"description": "WEARS POLKA DOTS TO EVERY SANDY OCCASION.",
		"speed_multiplier": 0.86,
		"base_goal_count": 1,
		"swim_size": Vector2(105, 82),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/blue_spotted_stingray.png")
	},
	{
		"enum_id": FishId.MORAY_EEL,
		"id": "moray_eel",
		"name": "Moray Eel",
		"rarity_level": 12,
		"description": "LIVES IN A HOLE AND CALLS IT OPEN-CONCEPT.",
		"speed_multiplier": 1.08,
		"base_goal_count": 1,
		"swim_size": Vector2(126, 62),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/moray_eel.png")
	},
	{
		"enum_id": FishId.SPOTTED_GAR,
		"id": "spotted_gar",
		"name": "Spotted Gar",
		"rarity_level": 12,
		"description": "AN ANCIENT NOODLE WITH EXCELLENT POSTURE.",
		"speed_multiplier": 1.35,
		"base_goal_count": 1,
		"swim_size": Vector2(528, 208),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/spotted_gar.png")
	},
	{
		"enum_id": FishId.RED_AROWANA,
		"id": "red_arowana",
		"name": "Red Arowana",
		"rarity_level": 12,
		"description": "TWO TINY WHISKERS, ONE ENORMOUS OPINION.",
		"speed_multiplier": 1.24,
		"base_goal_count": 1,
		"swim_size": Vector2(292.5, 126),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/red_arowana.png")
	},
	{
		"enum_id": FishId.GOLDEN_MANTA_RAY,
		"id": "golden_manta_ray",
		"name": "Golden Manta Ray",
		"rarity_level": 13,
		"description": "A FLYING CARPET WITH NOWHERE URGENT TO BE.",
		"speed_multiplier": 0.82,
		"base_goal_count": 1,
		"swim_size": Vector2(110, 88),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/golden_manta_ray.png")
	},
	{
		"enum_id": FishId.BABY_WHALE_SHARK,
		"id": "baby_whale_shark",
		"name": "Baby Whale Shark",
		"rarity_level": 13,
		"description": "HAS A WHALE OF A NAME AND A VERY SMALL CALENDAR.",
		"speed_multiplier": 0.98,
		"base_goal_count": 1,
		"swim_size": Vector2(177, 99),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/baby_whale_shark.png")
	},
	{
		"enum_id": FishId.HAMMERHEAD_SHARK,
		"id": "hammerhead_shark",
		"name": "Hammerhead Shark",
		"rarity_level": 13,
		"description": "OWNS NO NAILS. REMAINS EXTREMELY QUALIFIED.",
		"speed_multiplier": 1.38,
		"base_goal_count": 1,
		"swim_size": Vector2(240, 136),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/hammerhead_shark.png")
	},
	{
		"enum_id": FishId.GIANT_ARAPAIMA,
		"id": "giant_arapaima",
		"name": "Giant Arapaima",
		"rarity_level": 14,
		"description": "SO LARGE IT NEEDS A SECOND INTRODUCTION.",
		"speed_multiplier": 0.88,
		"base_goal_count": 1,
		"swim_size": Vector2(270, 130),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/giant_arapaima.png")
	},
	{
		"enum_id": FishId.ANCIENT_STURGEON,
		"id": "ancient_sturgeon",
		"name": "Ancient Sturgeon",
		"rarity_level": 14,
		"description": "HAS SEEN EMPIRES RISE AND STILL MISPLACES ITS KEYS.",
		"speed_multiplier": 1.12,
		"base_goal_count": 1,
		"swim_size": Vector2(264, 116),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/ancient_sturgeon.png")
	},
	{
		"enum_id": FishId.OCEAN_SUNFISH,
		"id": "ocean_sunfish",
		"name": "Ocean Sunfish",
		"rarity_level": 14,
		"description": "BUILT LIKE A DINNER PLATE, SCHEDULED LIKE A CLOUD.",
		"speed_multiplier": 0.70,
		"base_goal_count": 1,
		"swim_size": Vector2(88, 92),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/ocean_sunfish.png")
	},
	{
		"enum_id": FishId.LEAFY_SEADRAGON,
		"id": "leafy_seadragon",
		"name": "Leafy Seadragon",
		"rarity_level": 15,
		"description": "A SALAD THAT LEARNED STEALTH AND CHOSE DRAMA.",
		"speed_multiplier": 0.76,
		"base_goal_count": 1,
		"swim_size": Vector2(118, 72),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/leafy_seadragon.png")
	},
	{
		"enum_id": FishId.SAWFISH,
		"id": "sawfish",
		"name": "Sawfish",
		"rarity_level": 15,
		"description": "MEASURES TWICE, SWIMS ONCE.",
		"speed_multiplier": 1.06,
		"base_goal_count": 1,
		"swim_size": Vector2(290, 104),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/sawfish.png")
	},
	{
		"enum_id": FishId.COELACANTH,
		"id": "coelacanth",
		"name": "Coelacanth",
		"rarity_level": 15,
		"description": "MISSED EXTINCTION BECAUSE IT NEVER CHECKS EMAIL.",
		"speed_multiplier": 0.84,
		"base_goal_count": 1,
		"swim_size": Vector2(112, 70),
		"texture": preload("res://assets/ui/fishing/fish/candidates_30/processed/coelacanth.png")
	}
]

static var FISH_TYPES: Array[Dictionary] = _build_balanced_fish_types()
static var _force_opaque_material: ShaderMaterial

const STARTER_FISH_IDS: Array[String] = ["green"]

const RARITY_LEVEL_FISH_IDS: Array[Array] = [
	["green", "coral", "golden"],
	["blue_small", "yellow_striped", "pink_salmon", "blue_tang"],
	["peach_goby", "silver_mackerel", "turquoise_guppy", "clownfish"],
	["red_cardinalfish", "mint_catfish", "yellow_boxfish"],
	["red_white_koi", "purple_butterfly", "round_pufferfish"],
	["lavender_moonfish", "deep_blue_tuna"],
	["lionfish", "starlight_fish"],
	["brown_anglerfish", "neon_tetra", "zebra_danio"],
	["black_molly", "sunset_swordtail", "ruby_betta", "fire_dartfish"],
	["sapphire_discus", "royal_gramma", "mandarin_dragonet", "rainbow_parrotfish"],
	["picasso_triggerfish", "moorish_idol", "spotted_frogfish", "silver_flyingfish"],
	["glass_knifefish", "electric_eel", "emerald_seahorse", "blue_spotted_stingray"],
	["moray_eel", "spotted_gar", "red_arowana"],
	["golden_manta_ray", "baby_whale_shark", "hammerhead_shark"],
	["giant_arapaima", "ancient_sturgeon", "ocean_sunfish"],
	["leafy_seadragon", "sawfish", "coelacanth"]
]


static func _build_balanced_fish_types() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_fish in RAW_FISH_TYPES:
		var fish: Dictionary = raw_fish.duplicate(true)
		var fish_id := str(fish.get("id", ""))
		var rarity_level := clampi(
			int(fish.get("rarity_level", MIN_RARITY_LEVEL)),
			MIN_RARITY_LEVEL,
			MAX_RARITY_LEVEL
		)
		fish["base_goal_count"] = int(
			BASE_GOAL_COUNT_OVERRIDES.get(
				fish_id,
				BASE_GOAL_COUNTS_BY_RARITY_LEVEL[rarity_level]
			)
		)
		fish["spawn_weight"] = SPAWN_WEIGHTS_BY_RARITY_LEVEL[rarity_level]
		result.append(fish)
	return result


static func base_goal_count(fish_id: String) -> int:
	return int(definition(fish_id).get("base_goal_count", 1))


static func all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fish in FISH_TYPES:
		result.append(fish.duplicate(true))
	return result


static func definition(fish_id: String) -> Dictionary:
	for fish in FISH_TYPES:
		if str(fish.get("id", "")) == fish_id:
			return fish
	return FISH_TYPES[0]


static func visual_material(fish: Dictionary) -> Material:
	if not bool(fish.get("force_opaque", false)):
		return null
	if _force_opaque_material == null:
		var shader := Shader.new()
		shader.code = FORCE_OPAQUE_SHADER_CODE
		_force_opaque_material = ShaderMaterial.new()
		_force_opaque_material.shader = shader
	return _force_opaque_material


static func fish_ids_for_rarity_level(rarity_level: int) -> Array[String]:
	var safe_level := clampi(rarity_level, MIN_RARITY_LEVEL, MAX_RARITY_LEVEL)
	var result: Array[String] = []
	for fish_id in RARITY_LEVEL_FISH_IDS[safe_level]:
		result.append(str(fish_id))
	return result


static func rarity_level(fish_id: String) -> int:
	return int(definition(fish_id).get("rarity_level", MIN_RARITY_LEVEL))


static func normalize_aquarium_fish_ids(
	raw_ids: Variant,
	unlocked_fish_ids: Array[String]
) -> Array[String]:
	var normalized: Array[String] = []
	if not raw_ids is Array:
		return normalized
	for raw_id in raw_ids:
		var fish_id := str(raw_id)
		if (
			fish_id == ""
			or normalized.has(fish_id)
			or not unlocked_fish_ids.has(fish_id)
			or str(definition(fish_id).get("id", "")) != fish_id
		):
			continue
		normalized.append(fish_id)
		if normalized.size() >= AQUARIUM_CAPACITY:
			break
	return normalized
