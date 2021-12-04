-- Find game Base address and Main address
local mainAddr
local baseAddr

do
 local seedAddressScan = createMemScan()
 local foundList = createFoundList(seedAddressScan)
 seedAddressScan.firstScan(soExactValue, vtQword, 0, "04B2A61830444F4D", "", 0, 0x7FFFFFFFFFFF,
                           "", fsmNotAligned, nil, true, false, false, false)
 seedAddressScan.waitTillDone()
 foundList.initialize()

 mainAddr = tonumber(foundList.Address[1], 16) - 0x8
 baseAddr = mainAddr - 0x8004000

 foundList.destroy()
 seedAddressScan.destroy()
end



-- Set addresses
local function getPlayerPrefsProviderAddr()
 local playerPrefsProviderInstanceAddr = readQword(mainAddr + 0x4E60170)
 playerPrefsProviderInstanceAddr = readQword(playerPrefsProviderInstanceAddr + baseAddr + 0x18)
 playerPrefsProviderInstanceAddr = readQword(playerPrefsProviderInstanceAddr + baseAddr + 0xC0)
 playerPrefsProviderInstanceAddr = readQword(playerPrefsProviderInstanceAddr + baseAddr + 0x28)
 playerPrefsProviderInstanceAddr = readQword(playerPrefsProviderInstanceAddr + baseAddr + 0xB8)

 return readQword(playerPrefsProviderInstanceAddr + baseAddr)
end

local function getBattleSetupParamAddr(playerPrefsProviderAddr)
 local battleSetupParamAddr = readQword(playerPrefsProviderAddr + baseAddr + 0x7E8)
 battleSetupParamAddr = readQword(battleSetupParamAddr + baseAddr + 0x58)
 battleSetupParamAddr = readQword(battleSetupParamAddr + baseAddr + 0x28)

 if battleSetupParamAddr ~= 0 then
  battleSetupParamAddr = readQword(battleSetupParamAddr + baseAddr + 0x10)
  battleSetupParamAddr = readQword(battleSetupParamAddr + baseAddr + 0x20)
  battleSetupParamAddr = readQword(battleSetupParamAddr + baseAddr + 0x20)
  battleSetupParamAddr = readQword(battleSetupParamAddr + baseAddr + 0x18)
  battleSetupParamAddr = battleSetupParamAddr + baseAddr + 0x20

  return battleSetupParamAddr
 else
  return nil
 end
end

local s0Addr = readQword(mainAddr + 0x4F8CCD0) + baseAddr
local s1Addr = s0Addr + 0x8
local playerPrefsProviderAddr = getPlayerPrefsProviderAddr()
local IDsAddr = playerPrefsProviderAddr + baseAddr + 0xE8
local isEggReadyFlagAddr = playerPrefsProviderAddr + baseAddr + 0x458
local eggSeedAddr = isEggReadyFlagAddr + 0x8
local eggStepsCounterAddr = eggSeedAddr + 0x8



-- Set trainer info
local TID = bAnd(readInteger(IDsAddr), 0xFFFF)
local SID = bShr(readInteger(IDsAddr), 16)
local G8TID = bAnd(bShl(SID, 16) | TID, 0xFFFFFFFF) % 1000000
local TSV = bShr((TID ~ SID), 4)



-- PK8 class
local natureNamesList = {
 "Hardy", "Lonely", "Brave", "Adamant", "Naughty",
 "Bold", "Docile", "Relaxed", "Impish", "Lax",
 "Timid", "Hasty", "Serious", "Jolly", "Naive",
 "Modest", "Mild", "Quiet", "Bashful", "Rash",
 "Calm", "Gentle", "Sassy", "Careful", "Quirky"}

local speciesNamesList = {
 -- Gen 1
 "Bulbasaur", "Ivysaur", "Venusaur", "Charmander", "Charmeleon", "Charizard", "Squirtle", "Wartortle", "Blastoise",
 "Caterpie", "Metapod", "Butterfree", "Weedle", "Kakuna", "Beedrill", "Pidgey", "Pidgeotto", "Pidgeot", "Rattata",
 "Raticate", "Spearow", "Fearow", "Ekans", "Arbok", "Pikachu", "Raichu", "Sandshrew", "Sandslash", "Nidoran♀",
 "Nidorina", "Nidoqueen", "Nidoran♂", "Nidorino", "Nidoking", "Clefairy", "Clefable", "Vulpix", "Ninetales",
 "Jigglypuff", "Wigglytuff", "Zubat", "Golbat", "Oddish", "Gloom", "Vileplume", "Paras", "Parasect", "Venonat",
 "Venomoth", "Diglett", "Dugtrio", "Meowth", "Persian", "Psyduck", "Golduck", "Mankey", "Primeape", "Growlithe",
 "Arcanine", "Poliwag", "Poliwhirl", "Poliwrath", "Abra", "Kadabra", "Alakazam", "Machop", "Machoke", "Machamp",
 "Bellsprout", "Weepinbell", "Victreebel", "Tentacool", "Tentacruel", "Geodude", "Graveler", "Golem", "Ponyta",
 "Rapidash", "Slowpoke", "Slowbro", "Magnemite", "Magneton", "Farfetch'd", "Doduo", "Dodrio", "Seel", "Dewgong",
 "Grimer", "Muk", "Shellder", "Cloyster", "Gastly", "Haunter", "Gengar", "Onix", "Drowzee", "Hypno", "Krabby",
 "Kingler", "Voltorb", "Electrode", "Exeggcute", "Exeggutor", "Cubone", "Marowak", "Hitmonlee", "Hitmonchan",
 "Lickitung", "Koffing", "Weezing", "Rhyhorn", "Rhydon", "Chansey", "Tangela", "Kangaskhan", "Horsea", "Seadra",
 "Goldeen", "Seaking", "Staryu", "Starmie", "Mr. Mime", "Scyther", "Jynx", "Electabuzz", "Magmar", "Pinsir", "Tauros",
 "Magikarp", "Gyarados", "Lapras", "Ditto", "Eevee", "Vaporeon", "Jolteon", "Flareon", "Porygon", "Omanyte", "Omastar",
 "Kabuto", "Kabutops", "Aerodactyl", "Snorlax", "Articuno", "Zapdos", "Moltres", "Dratini", "Dragonair", "Dragonite",
 "Mewtwo", "Mew",
 -- Gen 2
 "Chikorita", "Bayleef", "Meganium", "Cyndaquil", "Quilava", "Typhlosion", "Totodile", "Croconaw", "Feraligatr",
 "Sentret", "Furret", "Hoothoot", "Noctowl", "Ledyba", "Ledian", "Spinarak", "Ariados", "Crobat", "Chinchou", "Lanturn",
 "Pichu", "Cleffa", "Igglybuff", "Togepi", "Togetic", "Natu", "Xatu", "Mareep", "Flaaffy", "Ampharos", "Bellossom",
 "Marill", "Azumarill", "Sudowoodo", "Politoed", "Hoppip", "Skiploom", "Jumpluff", "Aipom", "Sunkern", "Sunflora",
 "Yanma", "Wooper", "Quagsire", "Espeon", "Umbreon", "Murkrow", "Slowking", "Misdreavus", "Unown", "Wobbuffet",
 "Girafarig", "Pineco", "Forretress", "Dunsparce", "Gligar", "Steelix", "Snubbull", "Granbull", "Qwilfish", "Scizor",
 "Shuckle", "Heracross", "Sneasel", "Teddiursa", "Ursaring", "Slugma", "Magcargo", "Swinub", "Piloswine", "Corsola",
 "Remoraid", "Octillery", "Delibird", "Mantine", "Skarmory", "Houndour", "Houndoom", "Kingdra", "Phanpy", "Donphan",
 "Porygon2", "Stantler", "Smeargle", "Tyrogue", "Hitmontop", "Smoochum", "Elekid", "Magby", "Miltank", "Blissey",
 "Raikou", "Entei", "Suicune", "Larvitar", "Pupitar", "Tyranitar", "Lugia", "Ho-Oh", "Celebi",
 -- Gen 3
 "Treecko", "Grovyle", "Sceptile", "Torchic", "Combusken", "Blaziken", "Mudkip", "Marshtomp", "Swampert", "Poochyena",
 "Mightyena", "Zigzagoon", "Linoone", "Wurmple", "Silcoon", "Beautifly", "Cascoon", "Dustox", "Lotad", "Lombre", "Ludicolo",
 "Seedot", "Nuzleaf", "Shiftry", "Taillow", "Swellow", "Wingull", "Pelipper", "Ralts", "Kirlia", "Gardevoir", "Surskit",
 "Masquerain", "Shroomish", "Breloom", "Slakoth", "Vigoroth", "Slaking", "Nincada", "Ninjask", "Shedinja", "Whismur",
 "Loudred", "Exploud", "Makuhita", "Hariyama", "Azurill", "Nosepass", "Skitty", "Delcatty", "Sableye", "Mawile", "Aron",
 "Lairon", "Aggron", "Meditite", "Medicham", "Electrike", "Manectric", "Plusle", "Minun", "Volbeat", "Illumise", "Roselia",
 "Gulpin", "Swalot", "Carvanha", "Sharpedo", "Wailmer", "Wailord", "Numel", "Camerupt", "Torkoal", "Spoink", "Grumpig",
 "Spinda", "Trapinch", "Vibrava", "Flygon", "Cacnea", "Cacturne", "Swablu", "Altaria", "Zangoose", "Seviper", "Lunatone",
 "Solrock", "Barboach", "Whiscash", "Corphish", "Crawdaunt", "Baltoy", "Claydol", "Lileep", "Cradily", "Anorith", "Armaldo",
 "Feebas", "Milotic", "Castform", "Kecleon", "Shuppet", "Banette", "Duskull", "Dusclops", "Tropius", "Chimecho", "Absol",
 "Wynaut", "Snorunt", "Glalie", "Spheal", "Sealeo", "Walrein", "Clamperl", "Huntail", "Gorebyss", "Relicanth", "Luvdisc",
 "Bagon", "Shelgon", "Salamence", "Beldum", "Metang", "Metagross", "Regirock", "Regice", "Registeel", "Latias", "Latios",
 "Kyogre", "Groudon", "Rayquaza", "Jirachi", "Deoxys",
 -- Gen 4
 "Turtwig", "Grotle", "Torterra", "Chimchar", "Monferno", "Infernape", "Piplup", "Prinplup", "Empoleon", "Starly",
 "Staravia", "Staraptor", "Bidoof", "Bibarel", "Kricketot", "Kricketune", "Shinx", "Luxio", "Luxray", "Budew", "Roserade",
 "Cranidos", "Rampardos", "Shieldon", "Bastiodon", "Burmy", "Wormadam", "Mothim", "Combee", "Vespiquen", "Pachirisu",
 "Buizel", "Floatzel", "Cherubi", "Cherrim", "Shellos", "Gastrodon", "Ambipom", "Drifloon", "Drifblim", "Buneary",
 "Lopunny", "Mismagius", "Honchkrow", "Glameow", "Purugly", "Chingling", "Stunky", "Skuntank", "Bronzor", "Bronzong",
 "Bonsly", "Mime Jr.", "Happiny", "Chatot", "Spiritomb", "Gible", "Gabite", "Garchomp", "Munchlax", "Riolu", "Lucario",
 "Hippopotas", "Hippowdon", "Skorupi", "Drapion", "Croagunk", "Toxicroak", "Carnivine", "Finneon", "Lumineon", "Mantyke",
 "Snover", "Abomasnow", "Weavile", "Magnezone", "Lickilicky", "Rhyperior", "Tangrowth", "Electivire", "Magmortar",
 "Togekiss", "Yanmega", "Leafeon", "Glaceon", "Gliscor", "Mamoswine", "Porygon-Z", "Gallade", "Probopass", "Dusknoir",
 "Froslass", "Rotom", "Uxie", "Mesprit", "Azelf", "Dialga", "Palkia", "Heatran", "Regigigas", "Giratina", "Cresselia",
 "Phione", "Manaphy", "Darkrai", "Shaymin", "Arceus"}

local abilityNamesList = {
 -- Gen 3
 "Stench", "Drizzle", "Speed Boost", "Battle Armor", "Sturdy", "Damp", "Limber", "Sand Veil", "Static", "Volt Absorb",
 "Water Absorb", "Oblivious", "Cloud Nine", "Compound Eyes", "Insomnia", "Color Change", "Immunity", "Flash Fire", "Shield Dust",
 "Own Tempo", "Suction Cups", "Intimidate", "Shadow Tag", "Rough Skin", "Wonder Guard", "Levitate", "Effect Spore", "Synchronize",
 "Clear Body", "Natural Cure", "Lightning Rod", "Serene Grace", "Swift Swim", "Chlorophyll", "Illuminate", "Trace", "Huge Power",
 "Poison Point", "Inner Focus", "Magma Armor", "Water Veil", "Magnet Pull", "Soundproof", "Rain Dish", "Sand Stream", "Pressure",
 "Thick Fat", "Early Bird", "Flame Body", "Run Away", "Keen Eye", "Hyper Cutter", "Pickup", "Truant", "Hustle", "Cute Charm",
 "Plus", "Minus", "Forecast", "Sticky Hold", "Shed Skin", "Guts", "Marvel Scale", "Liquid Ooze", "Overgrow", "Blaze", "Torrent",
 "Swarm", "Rock Head", "Drought", "Arena Trap", "Vital Spirit", "White Smoke", "Pure Power", "Shell Armor", "Air Lock",
 -- Gen 4
 "Tangled Feet", "Motor Drive", "Rivalry", "Steadfast", "Snow Cloak",
 "Gluttony", "Anger Point", "Unburden", "Heatproof", "Simple", "Dry Skin", "Download", "Iron Fist", "Poison Heal", "Adaptability",
 "Skill Link", "Hydration", "Solar Power", "Quick Feet", "Normalize", "Sniper", "Magic Guard", "No Guard", "Stall", "Technician",
 "Leaf Guard", "Klutz", "Mold Breaker", "Super Luck", "Aftermath", "Anticipation", "Forewarn", "Unaware", "Tinted Lens", "Filter",
 "Slow Start", "Scrappy", "Storm Drain", "Ice Body", "Solid Rock", "Snow Warning", "Honey Gather", "Frisk", "Reckless", "Multitype",
 "Flower Gift", "Bad Dreams",
 -- Gen 5
 "Pickpocket", "Sheer Force", "Contrary", "Unnerve", "Defiant", "Defeatist", "Cursed Body", "Healer", "Friend Guard", "Weak Armor",
 "Heavy Metal", "Light Metal", "Multiscale", "Toxic Boost", "Flare Boost", "Harvest", "Telepathy", "Moody", "Overcoat", "Poison Touch",
 "Regenerator", "Big Pecks", "Sand Rush", "Wonder Skin", "Analytic", "Illusion", "Imposter", "Infiltrator", "Mummy", "Moxie",
 "Justified", "Rattled", "Magic Bounce", "Sap Sipper", "Prankster", "Sand Force", "Iron Barbs", "Zen Mode", "Victory Star",
 "Turboblaze", "Teravolt",
 -- Gen 6
 "Aroma Veil", "Flower Veil", "Cheek Pouch", "Protean", "Fur Coat", "Magician", "Bulletproof", "Competitive", "Strong Jaw",
 "Refrigerate", "Sweet Veil", "Stance Change", "Gale Wings", "Mega Launcher", "Grass Pelt", "Symbiosis", "Tough Claws", "Pixilate",
 "Gooey", "Aerilate", "Parental Bond", "Dark Aura", "Fairy Aura", "Aura Break", "Primordial Sea", "Desolate Land", "Delta Stream",
 -- Gen 7
 "Stamina", "Wimp Out", "Emergency Exit", "Water Compaction", "Merciless", "Shields Down", "Stakeout", "Water Bubble",
 "Steelworker", "Berserk", "Slush Rush", "Long Reach", "Liquid Voice", "Triage", "Galvanize", "Surge Surfer",
 "Schooling", "Disguise", "Battle Bond", "Power Construct", "Corrosion", "Comatose", "Queenly Majesty", "Innards Out",
 "Dancer", "Battery", "Fluffy", "Dazzling", "Soul-Heart", "Tangling Hair", "Receiver", "Power of Alchemy",
 "Beast Boost", "RKS System", "Electric Surge", "Psychic Surge", "Misty Surge", "Grassy Surge", "Full Metal Body", "Shadow Shield",
 "Prism Armor", "Neuroforce",
 -- Gen 8
 "Intrepid Sword", "Dauntless Shield", "Libero", "Ball Fetch", "Cotton Down", "Propeller Tail", "Mirror Armor", "Gulp Missile",
 "Stalwart", "Steam Engine", "Punk Rock", "Sand Spit", "Ice Scales", "Ripen", "Ice Face", "Power Spot", "Mimicry", "Screen Cleaner",
 "Steely Spirit", "Perish Body", "Wandering Spirit", "Gorilla Tactics", "Neutralizing Gas", "Pastel Veil", "Hunger Switch",
 "Quick Draw", "Unseen Fist", "Curious Medicine", "Transistor", "Dragon’s Maw", "Chilling Neigh", "Grim Neigh", "As One", "As One"}

local moveNamesList = {
 -- Gen 1
 "--", "Pound", "Karate Chop", "Double Slap", "Comet Punch", "Mega Punch", "Pay Day", "Fire Punch", "Ice Punch", "Thunder Punch",
 "Scratch", "Vice Grip", "Guillotine", "Razor Wind", "Swords Dance", "Cut", "Gust", "Wing Attack", "Whirlwind", "Fly",
 "Bind", "Slam", "Vine Whip", "Stomp", "Double Kick", "Mega Kick", "Jump Kick", "Rolling Kick", "Sand Attack", "Headbutt",
 "Horn Attack", "Fury Attack", "Horn Drill", "Tackle", "Body Slam", "Wrap", "Take Down", "Thrash", "Double-Edge",
 "Tail Whip", "Poison Sting", "Twineedle", "Pin Missile", "Leer", "Bite", "Growl", "Roar", "Sing", "Supersonic", "Sonic Boom",
 "Disable", "Acid", "Ember", "Flamethrower", "Mist", "Water Gun", "Hydro Pump", "Surf", "Ice Beam", "Blizzard", "Psybeam",
 "Bubble Beam", "Aurora Beam", "Hyper Beam", "Peck", "Drill Peck", "Submission", "Low Kick", "Counter", "Seismic Toss",
 "Strength", "Absorb", "Mega Drain", "Leech Seed", "Growth", "Razor Leaf", "Solar Beam", "Poison Powder", "Stun Spore",
 "Sleep Powder", "Petal Dance", "String Shot", "Dragon Rage", "Fire Spin", "Thunder Shock", "Thunderbolt", "Thunder Wave",
 "Thunder", "Rock Throw", "Earthquake", "Fissure", "Dig", "Toxic", "Confusion", "Psychic", "Hypnosis", "Meditate",
 "Agility", "Quick Attack", "Rage", "Teleport", "Night Shade", "Mimic", "Screech", "Double Team", "Recover", "Harden",
 "Minimize", "Smokescreen", "Confuse Ray", "Withdraw", "Defense Curl", "Barrier", "Light Screen", "Haze", "Reflect",
 "Focus Energy", "Bide", "Metronome", "Mirror Move", "Self-Destruct", "Egg Bomb", "Lick", "Smog", "Sludge", "Bone Club",
 "Fire Blast", "Waterfall", "Clamp", "Swift", "Skull Bash", "Spike Cannon", "Constrict", "Amnesia", "Kinesis", "Soft-Boiled",
 "High Jump Kick", "Glare", "Dream Eater", "Poison Gas", "Barrage", "Leech Life", "Lovely Kiss", "Sky Attack", "Transform",
 "Bubble", "Dizzy Punch", "Spore", "Flash", "Psywave", "Splash", "Acid Armor", "Crabhammer", "Explosion", "Fury Swipes",
 "Bonemerang", "Rest", "Rock Slide", "Hyper Fang", "Sharpen", "Conversion", "Tri Attack", "Super Fang", "Slash",
 "Substitute", "Struggle",
 -- Gen 2
 "Sketch", "Triple Kick", "Thief", "Spider Web", "Mind Reader", "Nightmare", "Flame Wheel",
 "Snore", "Curse", "Flail", "Conversion 2", "Aeroblast", "Cotton Spore", "Reversal", "Spite", "Powder Snow", "Protect",
 "Mach Punch", "Scary Face", "Feint Attack", "Sweet Kiss", "Belly Drum", "Sludge Bomb", "Mud-Slap", "Octazooka", "Spikes",
 "Zap Cannon", "Foresight", "Destiny Bond", "Perish Song", "Icy Wind", "Detect", "Bone Rush", "Lock-On", "Outrage",
 "Sandstorm", "Giga Drain", "Endure", "Charm", "Rollout", "False Swipe", "Swagger", "Milk Drink", "Spark", "Fury Cutter",
 "Steel Wing", "Mean Look", "Attract", "Sleep Talk", "Heal Bell", "Return", "Present", "Frustration", "Safeguard",
 "Pain Split", "Sacred Fire", "Magnitude", "Dynamic Punch", "Megahorn", "Dragon Breath", "Baton Pass", "Encore", "Pursuit",
 "Rapid Spin", "Sweet Scent", "Iron Tail", "Metal Claw", "Vital Throw", "Morning Sun", "Synthesis", "Moonlight", "Hidden Power",
 "Cross Chop", "Twister", "Rain Dance", "Sunny Day", "Crunch", "Mirror Coat", "Psych Up", "Extreme Speed", "Ancient Power",
 "Shadow Ball", "Future Sight", "Rock Smash", "Whirlpool", "Beat Up",
 -- Gen 3
 "Fake Out", "Uproar", "Stockpile", "Spit Up", "Swallow", "Heat Wave", "Hail", "Torment", "Flatter", "Will-O-Wisp", "Memento",
 "Facade", "Focus Punch", "Smelling Salts", "Follow Me", "Nature Power", "Charge", "Taunt", "Helping Hand", "Trick", "Role Play",
 "Wish", "Assist", "Ingrain", "Superpower", "Magic Coat", "Recycle", "Revenge", "Brick Break", "Yawn", "Knock Off", "Endeavor",
 "Eruption", "Skill Swap", "Imprison", "Refresh", "Grudge", "Snatch", "Secret Power", "Dive", "Arm Thrust", "Camouflage",
 "Tail Glow", "Luster Purge", "Mist Ball", "Feather Dance", "Teeter Dance", "Blaze Kick", "Mud Sport", "Ice Ball", "Needle Arm",
 "Slack Off", "Hyper Voice", "Poison Fang", "Crush Claw", "Blast Burn", "Hydro Cannon", "Meteor Mash", "Astonish", "Weather Ball",
 "Aromatherapy", "Fake Tears", "Air Cutter", "Overheat", "Odor Sleuth", "Rock Tomb", "Silver Wind", "Metal Sound",
 "Grass Whistle", "Tickle", "Cosmic Power", "Water Spout", "Signal Beam", "Shadow Punch", "Extrasensory", "Sky Uppercut",
 "Sand Tomb", "Sheer Cold", "Muddy Water", "Bullet Seed", "Aerial Ace", "Icicle Spear", "Iron Defense", "Block", "Howl",
 "Dragon Claw", "Frenzy Plant", "Bulk Up", "Bounce", "Mud Shot", "Poison Tail", "Covet", "Volt Tackle", "Magical Leaf",
 "Water Sport", "Calm Mind", "Leaf Blade", "Dragon Dance", "Rock Blast", "Shock Wave", "Water Pulse", "Doom Desire",
 "Psycho Boost",
 -- Gen 4
 "Roost", "Gravity", "Miracle Eye", "Wake-Up Slap", "Hammer Arm", "Gyro Ball", "Healing Wish", "Brine",
 "Natural Gift", "Feint", "Pluck", "Tailwind", "Acupressure", "Metal Burst", "U-turn", "Close Combat", "Payback", "Assurance",
 "Embargo", "Fling", "Psycho Shift", "Trump Card", "Heal Block", "Wring Out", "Power Trick", "Gastro Acid", "Lucky Chant",
 "Me First", "Copycat", "Power Swap", "Guard Swap", "Punishment", "Last Resort", "Worry Seed", "Sucker Punch", "Toxic Spikes",
 "Heart Swap", "Aqua Ring", "Magnet Rise", "Flare Blitz", "Force Palm", "Aura Sphere", "Rock Polish", "Poison Jab",
 "Dark Pulse", "Night Slash", "Aqua Tail", "Seed Bomb", "Air Slash", "X-Scissor", "Bug Buzz", "Dragon Pulse", "Dragon Rush",
 "Power Gem", "Drain Punch", "Vacuum Wave", "Focus Blast", "Energy Ball", "Brave Bird", "Earth Power", "Switcheroo",
 "Giga Impact", "Nasty Plot", "Bullet Punch", "Avalanche", "Ice Shard", "Shadow Claw", "Thunder Fang", "Ice Fang", "Fire Fang",
 "Shadow Sneak", "Mud Bomb", "Psycho Cut", "Zen Headbutt", "Mirror Shot", "Flash Cannon", "Rock Climb", "Defog",
 "Trick Room", "Draco Meteor", "Discharge", "Lava Plume", "Leaf Storm", "Power Whip", "Rock Wrecker", "Cross Poison", "Gunk Shot",
 "Iron Head", "Magnet Bomb", "Stone Edge", "Captivate", "Stealth Rock", "Grass Knot", "Chatter", "Judgment", "Bug Bite",
 "Charge Beam", "Wood Hammer", "Aqua Jet", "Attack Order", "Defend Order", "Heal Order", "Head Smash", "Double Hit",
 "Roar of Time", "Spacial Rend", "Lunar Dance", "Crush Grip", "Magma Storm", "Dark Void", "Seed Flare", "Ominous Wind",
 "Shadow Force",
 -- Gen 5
 "Hone Claws", "Wide Guard", "Guard Split", "Power Split", "Wonder Room", "Psyshock", "Venoshock", "Autotomize", "Rage Powder",
 "Telekinesis", "Magic Room", "Smack Down", "Storm Throw", "Flame Burst", "Sludge Wave", "Quiver Dance", "Heavy Slam", "Synchronoise",
 "Electro Ball", "Soak", "Flame Charge", "Coil", "Low Sweep", "Acid Spray", "Foul Play", "Simple Beam", "Entrainment", "After You",
 "Round", "Echoed Voice", "Chip Away", "Clear Smog", "Stored Power", "Quick Guard", "Ally Switch", "Scald",
 "Shell Smash", "Heal Pulse", "Hex", "Sky Drop", "Shift Gear", "Circle Throw", "Incinerate", "Quash",
 "Acrobatics", "Reflect Type", "Retaliate", "Final Gambit", "Bestow", "Inferno", "Water Pledge", "Fire Pledge",
 "Grass Pledge", "Volt Switch", "Struggle Bug", "Bulldoze", "Frost Breath", "Dragon Tail", "Work Up", "Electroweb",
 "Wild Charge", "Drill Run", "Dual Chop", "Heart Stamp", "Horn Leech", "Sacred Sword", "Razor Shell", "Heat Crash",
 "Leaf Tornado", "Steamroller", "Cotton Guard", "Night Daze", "Psystrike", "Tail Slap", "Hurricane", "Head Charge",
 "Gear Grind", "Searing Shot", "Techno Blast", "Relic Song", "Secret Sword", "Glaciate", "Bolt Strike", "Blue Flare",
 "Fiery Dance", "Freeze Shock", "Ice Burn", "Snarl", "Icicle Crash", "V-create", "Fusion Flare", "Fusion Bolt",
 -- Gen 6
 "Flying Press", "Mat Block", "Belch", "Rototiller", "Sticky Web", "Fell Stinger", "Phantom Force", "Trick-or-Treat",
 "Noble Roar", "Ion Deluge", "Parabolic Charge", "Forest’s Curse", "Petal Blizzard", "Freeze-Dry", "Disarming Voice", "Parting Shot",
 "Topsy-Turvy", "Draining Kiss", "Crafty Shield", "Flower Shield", "Grassy Terrain", "Misty Terrain", "Electrify", "Play Rough",
 "Fairy Wind", "Moonblast", "Boomburst", "Fairy Lock", "King’s Shield", "Play Nice", "Confide", "Diamond Storm",
 "Steam Eruption", "Hyperspace Hole", "Water Shuriken", "Mystical Fire", "Spiky Shield", "Aromatic Mist", "Eerie Impulse", "Venom Drench",
 "Powder", "Geomancy", "Magnetic Flux", "Happy Hour", "Electric Terrain", "Dazzling Gleam", "Celebrate", "Hold Hands",
 "Baby-Doll Eyes", "Nuzzle", "Hold Back", "Infestation", "Power-Up Punch", "Oblivion Wing", "Thousand Arrows", "Thousand Waves",
 "Land’s Wrath", "Light of Ruin", "Origin Pulse", "Precipice Blades", "Dragon Ascent", "Hyperspace Fury",
 -- Gen 7
 "Breakneck Blitz", "Breakneck Blitz", "All-Out Pummeling", "All-Out Pummeling", "Supersonic Skystrike", "Supersonic Skystrike",
 "Acid Downpour", "Acid Downpour", "Tectonic Rage", "Tectonic Rage", "Continental Crush", "Continental Crush", "Savage Spin-Out",
 "Savage Spin-Out", "Never-Ending Nightmare", "Never-Ending Nightmare", "Corkscrew Crash", "Corkscrew Crash", "Inferno Overdrive",
 "Inferno Overdrive", "Hydro Vortex", "Hydro Vortex", "Bloom Doom", "Bloom Doom", "Gigavolt Havoc", "Gigavolt Havoc", "Shattered Psyche",
 "Shattered Psyche", "Subzero Slammer", "Subzero Slammer", "Devastating Drake", "Devastating Drake", "Black Hole Eclipse",
 "Black Hole Eclipse", "Twinkle Tackle", "Twinkle Tackle", "Catastropika", "Shore Up", "First Impression", "Baneful Bunker",
 "Spirit Shackle", "Darkest Lariat", "Sparkling Aria", "Ice Hammer", "Floral Healing", "High Horsepower", "Strength Sap", "Solar Blade",
 "Leafage", "Spotlight", "Toxic Thread", "Laser Focus", "Gear Up", "Throat Chop", "Pollen Puff", "Anchor Shot", "Psychic Terrain", "Lunge",
 "Fire Lash", "Power Trip", "Burn Up", "Speed Swap", "Smart Strike", "Purify", "Revelation Dance", "Core Enforcer",
 "Trop Kick", "Instruct", "Beak Blast", "Clanging Scales", "Dragon Hammer", "Brutal Swing", "Aurora Veil", "Sinister Arrow Raid",
 "Malicious Moonsault", "Oceanic Operetta", "Guardian of Alola", "Soul-Stealing 7-Star Strike", "Stoked Sparksurfer", "Pulverizing Pancake",
 "Extreme Evoboost", "Genesis Supernova", "Shell Trap", "Fleur Cannon", "Psychic Fangs", "Stomping Tantrum", "Shadow Bone", "Accelerock",
 "Liquidation", "Prismatic Laser", "Spectral Thief", "Sunsteel Strike", "Moongeist Beam", "Tearful Look", "Zing Zap", "Nature’s Madness",
 "Multi-Attack", "10,000,000 Volt Thunderbolt", "Mind Blown", "Plasma Fists", "Photon Geyser", "Light That Burns the Sky",
 "Searing Sunraze Smash", "Menacing Moonraze Maelstrom", "Let’s Snuggle Forever", "Splintered Stormshards", "Clangorous Soulblaze",
 "Zippy Zap", "Splishy Splash", "Floaty Fall", "Pika Papow", "Bouncy Bubble", "Buzzy Buzz", "Sizzly Slide", "Glitzy Glow", "Baddy Bad",
 "Sappy Seed", "Freezy Frost", "Sparkly Swirl", "Veevee Volley", "Double Iron Bash",
 -- Gen 8
 "Max Guard", "Dynamax Cannon", "Snipe Shot", "Jaw Lock", "Stuff Cheeks", "No Retreat", "Tar Shot", "Magic Powder", "Dragon Darts",
 "Teatime", "Octolock", "Bolt Beak", "Fishious Rend", "Court Change", "Max Flare", "Max Flutterby", "Max Lightning",
 "Max Strike", "Max Knuckle", "Max Phantasm", "Max Hailstorm", "Max Ooze", "Max Geyser", "Max Airstream", "Max Starfall",
 "Max Wyrmwind", "Max Mindstorm", "Max Rockfall", "Max Quake", "Max Darkness", "Max Overgrowth", "Max Steelspike", "Clangorous Soul",
 "Body Press", "Decorate", "Drum Beating", "Snap Trap", "Pyro Ball", "Behemoth Blade", "Behemoth Bash", "Aura Wheel",
 "Breaking Swipe", "Branch Poke", "Overdrive", "Apple Acid", "Grav Apple", "Spirit Break", "Strange Steam", "Life Dew",
 "Obstruct", "False Surrender", "Meteor Assault", "Eternabeam", "Steel Beam", "Expanding Force", "Steel Roller", "Scale Shot",
 "Meteor Beam", "Shell Side Arm", "Misty Explosion", "Grassy Glide", "Rising Voltage", "Terrain Pulse", "Skitter Smack", "Burning Jealousy",
 "Lash Out", "Poltergeist", "Corrosive Gas", "Coaching", "Flip Turn", "Triple Axel", "Dual Wingbeat", "Scorching Sands",
 "Jungle Healing", "Wicked Blow", "Surging Strikes", "Thunder Cage", "Dragon Energy", "Freezing Glare", "Fiery Wrath", "Thunderous Kick",
 "Glacial Lance", "Astral Barrage", "Eerie Spell"}

local itemNamesList = {
 "None", "Master Ball", "Ultra Ball", "Great Ball", "Poké Ball", "Safari Ball", "Net Ball", "Dive Ball",
 "Nest Ball", "Repeat Ball", "Timer Ball", "Luxury Ball", "Premier Ball", "Dusk Ball", "Heal Ball", "Quick Ball",
 "Cherish Ball", "Potion", "Antidote", "Burn Heal", "Ice Heal", "Awakening", "Paralyze Heal", "Full Restore",
 "Max Potion", "Hyper Potion", "Super Potion", "Full Heal", "Revive", "Max Revive", "Fresh Water", "Soda Pop",
 "Lemonade", "Moomoo Milk", "Energy Powder", "Energy Root", "Heal Powder", "Revival Herb", "Ether", "Max Ether",
 "Elixir", "Max Elixir", "Lava Cookie", "Berry Juice", "Sacred Ash", "HP Up", "Protein", "Iron",
 "Carbos", "Calcium", "Rare Candy", "PP Up", "Zinc", "PP Max", "Old Gateau", "Guard Spec.",
 "Dire Hit", "X Attack", "X Defense", "X Speed", "X Accuracy", "X Sp. Atk", "X Sp. Def", "Poké Doll",
 "Fluffy Tail", "Blue Flute", "Yellow Flute", "Red Flute", "Black Flute", "White Flute", "Shoal Salt", "Shoal Shell",
 "Red Shard", "Blue Shard", "Yellow Shard", "Green Shard", "Super Repel", "Max Repel", "Escape Rope", "Repel",
 "Sun Stone", "Moon Stone", "Fire Stone", "Thunder Stone", "Water Stone", "Leaf Stone", "Tiny Mushroom", "Big Mushroom",
 "Pearl", "Big Pearl", "Stardust", "Star Piece", "Nugget", "Heart Scale", "Honey", "Growth Mulch",
 "Damp Mulch", "Stable Mulch", "Gooey Mulch", "Root Fossil", "Claw Fossil", "Helix Fossil", "Dome Fossil", "Old Amber",
 "Armor Fossil", "Skull Fossil", "Rare Bone", "Shiny Stone", "Dusk Stone", "Dawn Stone", "Oval Stone", "Odd Keystone",
 "Griseous Orb", "Tea", "unknown", "Autograph", "Douse Drive", "Shock Drive", "Burn Drive", "Chill Drive",
 "unknown", "Pokémon Box Link", "Medicine Pocket", "TM Case", "Candy Jar", "Power-Up Pocket", "Clothing Trunk", "Catching Pocket",
 "Battle Pocket", "unknown", "unknown", "unknown", "unknown", "unknown", "Sweet Heart", "Adamant Orb",
 "Lustrous Orb", "Greet Mail", "Favored Mail", "RSVP Mail", "Thanks Mail", "Inquiry Mail", "Like Mail", "Reply Mail",
 "Bridge Mail S", "Bridge Mail D", "Bridge Mail T", "Bridge Mail V", "Bridge Mail M", "Cheri Berry", "Chesto Berry", "Pecha Berry",
 "Rawst Berry", "Aspear Berry", "Leppa Berry", "Oran Berry", "Persim Berry", "Lum Berry", "Sitrus Berry", "Figy Berry",
 "Wiki Berry", "Mago Berry", "Aguav Berry", "Iapapa Berry", "Razz Berry", "Bluk Berry", "Nanab Berry", "Wepear Berry",
 "Pinap Berry", "Pomeg Berry", "Kelpsy Berry", "Qualot Berry", "Hondew Berry", "Grepa Berry", "Tamato Berry", "Cornn Berry",
 "Magost Berry", "Rabuta Berry", "Nomel Berry", "Spelon Berry", "Pamtre Berry", "Watmel Berry", "Durin Berry", "Belue Berry",
 "Occa Berry", "Passho Berry", "Wacan Berry", "Rindo Berry", "Yache Berry", "Chople Berry", "Kebia Berry", "Shuca Berry",
 "Coba Berry", "Payapa Berry", "Tanga Berry", "Charti Berry", "Kasib Berry", "Haban Berry", "Colbur Berry", "Babiri Berry",
 "Chilan Berry", "Liechi Berry", "Ganlon Berry", "Salac Berry", "Petaya Berry", "Apicot Berry", "Lansat Berry", "Starf Berry",
 "Enigma Berry", "Micle Berry", "Custap Berry", "Jaboca Berry", "Rowap Berry", "Bright Powder", "White Herb", "Macho Brace",
 "Exp. Share", "Quick Claw", "Soothe Bell", "Mental Herb", "Choice Band", "King’s Rock", "Silver Powder", "Amulet Coin",
 "Cleanse Tag", "Soul Dew", "Deep Sea Tooth", "Deep Sea Scale", "Smoke Ball", "Everstone", "Focus Band", "Lucky Egg",
 "Scope Lens", "Metal Coat", "Leftovers", "Dragon Scale", "Light Ball", "Soft Sand", "Hard Stone", "Miracle Seed",
 "Black Glasses", "Black Belt", "Magnet", "Mystic Water", "Sharp Beak", "Poison Barb", "Never-Melt Ice", "Spell Tag",
 "Twisted Spoon", "Charcoal", "Dragon Fang", "Silk Scarf", "Upgrade", "Shell Bell", "Sea Incense", "Lax Incense",
 "Lucky Punch", "Metal Powder", "Thick Club", "Leek", "Red Scarf", "Blue Scarf", "Pink Scarf", "Green Scarf",
 "Yellow Scarf", "Wide Lens", "Muscle Band", "Wise Glasses", "Expert Belt", "Light Clay", "Life Orb", "Power Herb",
 "Toxic Orb", "Flame Orb", "Quick Powder", "Focus Sash", "Zoom Lens", "Metronome", "Iron Ball", "Lagging Tail",
 "Destiny Knot", "Black Sludge", "Icy Rock", "Smooth Rock", "Heat Rock", "Damp Rock", "Grip Claw", "Choice Scarf",
 "Sticky Barb", "Power Bracer", "Power Belt", "Power Lens", "Power Band", "Power Anklet", "Power Weight", "Shed Shell",
 "Big Root", "Choice Specs", "Flame Plate", "Splash Plate", "Zap Plate", "Meadow Plate", "Icicle Plate", "Fist Plate",
 "Toxic Plate", "Earth Plate", "Sky Plate", "Mind Plate", "Insect Plate", "Stone Plate", "Spooky Plate", "Draco Plate",
 "Dread Plate", "Iron Plate", "Odd Incense", "Rock Incense", "Full Incense", "Wave Incense", "Rose Incense", "Luck Incense",
 "Pure Incense", "Protector", "Electirizer", "Magmarizer", "Dubious Disc", "Reaper Cloth", "Razor Claw", "Razor Fang",
 "TM01", "TM02", "TM03", "TM04", "TM05", "TM06", "TM07", "TM08",
 "TM09", "TM10", "TM11", "TM12", "TM13", "TM14", "TM15", "TM16",
 "TM17", "TM18", "TM19", "TM20", "TM21", "TM22", "TM23", "TM24",
 "TM25", "TM26", "TM27", "TM28", "TM29", "TM30", "TM31", "TM32",
 "TM33", "TM34", "TM35", "TM36", "TM37", "TM38", "TM39", "TM40",
 "TM41", "TM42", "TM43", "TM44", "TM45", "TM46", "TM47", "TM48",
 "TM49", "TM50", "TM51", "TM52", "TM53", "TM54", "TM55", "TM56",
 "TM57", "TM58", "TM59", "TM60", "TM61", "TM62", "TM63", "TM64",
 "TM65", "TM66", "TM67", "TM68", "TM69", "TM70", "TM71", "TM72",
 "TM73", "TM74", "TM75", "TM76", "TM77", "TM78", "TM79", "TM80",
 "TM81", "TM82", "TM83", "TM84", "TM85", "TM86", "TM87", "TM88",
 "TM89", "TM90", "TM91", "TM92", "TM93", "TM94", "TM95", "TM96",
 "TM97", "TM98", "TM99", "TM100", "Explorer Kit", "Loot Sack", "Rule Book", "Poké Radar",
 "Point Card", "Guidebook", "Sticker Case", "Fashion Case", "Sticker Bag", "Pal Pad", "Works Key", "Old Charm",
 "Galactic Key", "Red Chain", "Town Map", "Vs. Seeker", "Coin Case", "Old Rod", "Good Rod", "Super Rod",
 "Sprayduck", "Poffin Case", "Bike", "Suite Key", "Oak’s Letter", "Lunar Feather", "Member Card", "unknown",
 "S.S. Ticket", "Contest Pass", "Magma Stone", "Parcel", "Coupon 1", "Coupon 2", "Coupon 3", "Storage Key",
 "Secret Medicine", "Vs. Recorder", "Gracidea", "Secret Key", "Apricorn Box", "Unown Report", "Berry Pots", "Dowsing Machine",
 "Blue Card", "Slowpoke Tail", "Clear Bell", "Card Key", "Basement Key", "Squirt Bottle", "Red Scale", "Lost Item",
 "Pass", "Machine Part", "Silver Wing", "Rainbow Wing", "Mystery Egg", "Red Apricorn", "Blue Apricorn", "Yellow Apricorn",
 "Green Apricorn", "Pink Apricorn", "White Apricorn", "Black Apricorn", "Fast Ball", "Level Ball", "Lure Ball", "Heavy Ball",
 "Love Ball", "Friend Ball", "Moon Ball", "Sport Ball", "Park Ball", "Photo Album", "GB Sounds", "Tidal Bell",
 "Rage Candy Bar", "Data Card 01", "Data Card 02", "Data Card 03", "Data Card 04", "Data Card 05", "Data Card 06", "Data Card 07",
 "Data Card 08", "Data Card 09", "Data Card 10", "Data Card 11", "Data Card 12", "Data Card 13", "Data Card 14", "Data Card 15",
 "Data Card 16", "Data Card 17", "Data Card 18", "Data Card 19", "Data Card 20", "Data Card 21", "Data Card 22", "Data Card 23",
 "Data Card 24", "Data Card 25", "Data Card 26", "Data Card 27", "Jade Orb", "Lock Capsule", "Red Orb", "Blue Orb",
 "Enigma Stone", "Prism Scale", "Eviolite", "Float Stone", "Rocky Helmet", "Air Balloon", "Red Card", "Ring Target",
 "Binding Band", "Absorb Bulb", "Cell Battery", "Eject Button", "Fire Gem", "Water Gem", "Electric Gem", "Grass Gem",
 "Ice Gem", "Fighting Gem", "Poison Gem", "Ground Gem", "Flying Gem", "Psychic Gem", "Bug Gem", "Rock Gem",
 "Ghost Gem", "Dragon Gem", "Dark Gem", "Steel Gem", "Normal Gem", "Health Feather", "Muscle Feather", "Resist Feather",
 "Genius Feather", "Clever Feather", "Swift Feather", "Pretty Feather", "Cover Fossil", "Plume Fossil", "Liberty Pass", "Pass Orb",
 "Dream Ball", "Poké Toy", "Prop Case", "Dragon Skull", "Balm Mushroom", "Big Nugget", "Pearl String", "Comet Shard",
 "Relic Copper", "Relic Silver", "Relic Gold", "Relic Vase", "Relic Band", "Relic Statue", "Relic Crown", "Casteliacone",
 "Dire Hit 2", "X Speed 2", "X Sp. Atk 2", "X Sp. Def 2", "X Defense 2", "X Attack 2", "X Accuracy 2", "X Speed 3",
 "X Sp. Atk 3", "X Sp. Def 3", "X Defense 3", "X Attack 3", "X Accuracy 3", "X Speed 6", "X Sp. Atk 6", "X Sp. Def 6",
 "X Defense 6", "X Attack 6", "X Accuracy 6", "Ability Urge", "Item Drop", "Item Urge", "Reset Urge", "Dire Hit 3",
 "Light Stone", "Dark Stone", "TM93", "TM94", "TM95", "Xtransceiver", "unknown", "Gram 1",
 "Gram 2", "Gram 3", "Xtransceiver", "Medal Box", "DNA Splicers", "DNA Splicers", "Permit", "Oval Charm",
 "Shiny Charm", "Plasma Card", "Grubby Hanky", "Colress Machine", "Dropped Item", "Dropped Item", "Reveal Glass", "Weakness Policy",
 "Assault Vest", "Holo Caster", "Prof’s Letter", "Roller Skates", "Pixie Plate", "Ability Capsule", "Whipped Dream", "Sachet",
 "Luminous Moss", "Snowball", "Safety Goggles", "Poké Flute", "Rich Mulch", "Surprise Mulch", "Boost Mulch", "Amaze Mulch",
 "Gengarite", "Gardevoirite", "Ampharosite", "Venusaurite", "Charizardite X", "Blastoisinite", "Mewtwonite X", "Mewtwonite Y",
 "Blazikenite", "Medichamite", "Houndoominite", "Aggronite", "Banettite", "Tyranitarite", "Scizorite", "Pinsirite",
 "Aerodactylite", "Lucarionite", "Abomasite", "Kangaskhanite", "Gyaradosite", "Absolite", "Charizardite Y", "Alakazite",
 "Heracronite", "Mawilite", "Manectite", "Garchompite", "Latiasite", "Latiosite", "Roseli Berry", "Kee Berry",
 "Maranga Berry", "Sprinklotad", "TM96", "TM97", "TM98", "TM99", "TM100", "Power Plant Pass",
 "Mega Ring", "Intriguing Stone", "Common Stone", "Discount Coupon", "Elevator Key", "TMV Pass", "Honor of Kalos", "Adventure Guide",
 "Strange Souvenir", "Lens Case", "Makeup Bag", "Travel Trunk", "Lumiose Galette", "Shalour Sable", "Jaw Fossil", "Sail Fossil",
 "Looker Ticket", "Bike", "Holo Caster", "Fairy Gem", "Mega Charm", "Mega Glove", "Mach Bike", "Acro Bike",
 "Wailmer Pail", "Devon Parts", "Soot Sack", "Basement Key", "Pokéblock Kit", "Letter", "Eon Ticket", "Scanner",
 "Go-Goggles", "Meteorite", "Key to Room 1", "Key to Room 2", "Key to Room 4", "Key to Room 6", "Storage Key", "Devon Scope",
 "S.S. Ticket", "HM07", "Devon Scuba Gear", "Contest Costume", "Contest Costume", "Magma Suit", "Aqua Suit", "Pair of Tickets",
 "Mega Bracelet", "Mega Pendant", "Mega Glasses", "Mega Anchor", "Mega Stickpin", "Mega Tiara", "Mega Anklet", "Meteorite",
 "Swampertite", "Sceptilite", "Sablenite", "Altarianite", "Galladite", "Audinite", "Metagrossite", "Sharpedonite",
 "Slowbronite", "Steelixite", "Pidgeotite", "Glalitite", "Diancite", "Prison Bottle", "Mega Cuff", "Cameruptite",
 "Lopunnite", "Salamencite", "Beedrillite", "Meteorite", "Meteorite", "Key Stone", "Meteorite Shard", "Eon Flute",
 "Normalium Z", "Firium Z", "Waterium Z", "Electrium Z", "Grassium Z", "Icium Z", "Fightinium Z", "Poisonium Z",
 "Groundium Z", "Flyinium Z", "Psychium Z", "Buginium Z", "Rockium Z", "Ghostium Z", "Dragonium Z", "Darkinium Z",
 "Steelium Z", "Fairium Z", "Pikanium Z", "Bottle Cap", "Gold Bottle Cap", "Z-Ring", "Decidium Z", "Incinium Z",
 "Primarium Z", "Tapunium Z", "Marshadium Z", "Aloraichium Z", "Snorlium Z", "Eevium Z", "Mewnium Z", "Normalium Z",
 "Firium Z", "Waterium Z", "Electrium Z", "Grassium Z", "Icium Z", "Fightinium Z", "Poisonium Z", "Groundium Z",
 "Flyinium Z", "Psychium Z", "Buginium Z", "Rockium Z", "Ghostium Z", "Dragonium Z", "Darkinium Z", "Steelium Z",
 "Fairium Z", "Pikanium Z", "Decidium Z", "Incinium Z", "Primarium Z", "Tapunium Z", "Marshadium Z", "Aloraichium Z",
 "Snorlium Z", "Eevium Z", "Mewnium Z", "Pikashunium Z", "Pikashunium Z", "unknown", "unknown", "unknown",
 "unknown", "Forage Bag", "Fishing Rod", "Professor’s Mask", "Festival Ticket", "Sparkling Stone", "Adrenaline Orb", "Zygarde Cube",
 "unknown", "Ice Stone", "Ride Pager", "Beast Ball", "Big Malasada", "Red Nectar", "Yellow Nectar", "Pink Nectar",
 "Purple Nectar", "Sun Flute", "Moon Flute", "unknown", "Enigmatic Card", "Silver Razz Berry", "Golden Razz Berry", "Silver Nanab Berry",
 "Golden Nanab Berry", "Silver Pinap Berry", "Golden Pinap Berry", "unknown", "unknown", "unknown", "unknown", "unknown",
 "Secret Key", "S.S. Ticket", "Silph Scope", "Parcel", "Card Key", "Gold Teeth", "Lift Key", "Terrain Extender",
 "Protective Pads", "Electric Seed", "Psychic Seed", "Misty Seed", "Grassy Seed", "Stretchy Spring", "Chalky Stone", "Marble",
 "Lone Earring", "Beach Glass", "Gold Leaf", "Silver Leaf", "Polished Mud Ball", "Tropical Shell", "Leaf Letter", "Leaf Letter",
 "Small Bouquet", "unknown", "unknown", "unknown", "Lure", "Super Lure", "Max Lure", "Pewter Crunchies",
 "Fighting Memory", "Flying Memory", "Poison Memory", "Ground Memory", "Rock Memory", "Bug Memory", "Ghost Memory", "Steel Memory",
 "Fire Memory", "Water Memory", "Grass Memory", "Electric Memory", "Psychic Memory", "Ice Memory", "Dragon Memory", "Dark Memory",
 "Fairy Memory", "Solganium Z", "Lunalium Z", "Ultranecrozium Z", "Mimikium Z", "Lycanium Z", "Kommonium Z", "Solganium Z",
 "Lunalium Z", "Ultranecrozium Z", "Mimikium Z", "Lycanium Z", "Kommonium Z", "Z-Power Ring", "Pink Petal", "Orange Petal",
 "Blue Petal", "Red Petal", "Green Petal", "Yellow Petal", "Purple Petal", "Rainbow Flower", "Surge Badge", "N-Solarizer",
 "N-Lunarizer", "N-Solarizer", "N-Lunarizer", "Ilima Normalium Z", "Left Poké Ball", "Roto Hatch", "Roto Bargain", "Roto Prize Money",
 "Roto Exp. Points", "Roto Friendship", "Roto Encounter", "Roto Stealth", "Roto HP Restore", "Roto PP Restore", "Roto Boost", "Roto Catch",
 "Health Candy", "Mighty Candy", "Tough Candy", "Smart Candy", "Courage Candy", "Quick Candy", "Health Candy L", "Mighty Candy L",
 "Tough Candy L", "Smart Candy L", "Courage Candy L", "Quick Candy L", "Health Candy XL", "Mighty Candy XL", "Tough Candy XL",
 "Smart Candy XL", "Courage Candy XL", "Quick Candy XL", "Bulbasaur Candy", "Charmander Candy", "Squirtle Candy", "Caterpie Candy",
 "Weedle Candy", "Pidgey Candy", "Rattata Candy", "Spearow Candy", "Ekans Candy", "Pikachu Candy", "Sandshrew Candy", "Nidoran♀ Candy",
 "Nidoran♂ Candy", "Clefairy Candy", "Vulpix Candy", "Jigglypuff Candy", "Zubat Candy", "Oddish Candy", "Paras Candy", "Venonat Candy",
 "Diglett Candy", "Meowth Candy", "Psyduck Candy", "Mankey Candy", "Growlithe Candy", "Poliwag Candy", "Abra Candy", "Machop Candy",
 "Bellsprout Candy", "Tentacool Candy", "Geodude Candy", "Ponyta Candy", "Slowpoke Candy", "Magnemite Candy", "Farfetch’d Candy",
 "Doduo Candy", "Seel Candy", "Grimer Candy", "Shellder Candy", "Gastly Candy", "Onix Candy", "Drowzee Candy", "Krabby Candy",
 "Voltorb Candy", "Exeggcute Candy", "Cubone Candy", "Hitmonlee Candy", "Hitmonchan Candy", "Lickitung Candy", "Koffing Candy",
 "Rhyhorn Candy", "Chansey Candy", "Tangela Candy", "Kangaskhan Candy", "Horsea Candy", "Goldeen Candy", "Staryu Candy", "Mr. Mime Candy",
 "Scyther Candy", "Jynx Candy", "Electabuzz Candy", "Pinsir Candy", "Tauros Candy", "Magikarp Candy", "Lapras Candy", "Ditto Candy",
 "Eevee Candy", "Porygon Candy", "Omanyte Candy", "Kabuto Candy", "Aerodactyl Candy", "Snorlax Candy", "Articuno Candy", "Zapdos Candy",
 "Moltres Candy", "Dratini Candy", "Mewtwo Candy", "Mew Candy", "Meltan Candy", "Magmar Candy", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "Endorsement", "Pokémon Box Link", "Wishing Star", "Dynamax Band", "unknown", "unknown",
 "Fishing Rod", "Rotom Bike", "unknown", "unknown", "Sausages", "Bob’s Food Tin", "Bach’s Food Tin", "Tin of Beans",
 "Bread", "Pasta", "Mixed Mushrooms", "Smoke-Poke Tail", "Large Leek", "Fancy Apple", "Brittle Bones", "Pack of Potatoes",
 "Pungent Root", "Salad Mix", "Fried Food", "Boiled Egg", "Camping Gear", "unknown", "unknown", "Rusted Sword",
 "Rusted Shield", "Fossilized Bird", "Fossilized Fish", "Fossilized Drake", "Fossilized Dino", "Strawberry Sweet", "Love Sweet",
 "Berry Sweet", "Clover Sweet", "Flower Sweet", "Star Sweet", "Ribbon Sweet", "Sweet Apple", "Tart Apple", "Throat Spray", "Eject Pack",
 "Heavy-Duty Boots", "Blunder Policy", "Room Service", "Utility Umbrella", "Exp. Candy XS", "Exp. Candy S", "Exp. Candy M", "Exp. Candy L",
 "Exp. Candy XL", "Dynamax Candy", "TR00", "TR01", "TR02", "TR03", "TR04", "TR05",
 "TR06", "TR07", "TR08", "TR09", "TR10", "TR11", "TR12", "TR13",
 "TR14", "TR15", "TR16", "TR17", "TR18", "TR19", "TR20", "TR21",
 "TR22", "TR23", "TR24", "TR25", "TR26", "TR27", "TR28", "TR29",
 "TR30", "TR31", "TR32", "TR33", "TR34", "TR35", "TR36", "TR37",
 "TR38", "TR39", "TR40", "TR41", "TR42", "TR43", "TR44", "TR45",
 "TR46", "TR47", "TR48", "TR49", "TR50", "TR51", "TR52", "TR53",
 "TR54", "TR55", "TR56", "TR57", "TR58", "TR59", "TR60", "TR61",
 "TR62", "TR63", "TR64", "TR65", "TR66", "TR67", "TR68", "TR69",
 "TR70", "TR71", "TR72", "TR73", "TR74", "TR75", "TR76", "TR77",
 "TR78", "TR79", "TR80", "TR81", "TR82", "TR83", "TR84", "TR85",
 "TR86", "TR87", "TR88", "TR89", "TR90", "TR91", "TR92", "TR93",
 "TR94", "TR95", "TR96", "TR97", "TR98", "TR99", "TM00", "Lonely Mint",
 "Adamant Mint", "Naughty Mint", "Brave Mint", "Bold Mint", "Impish Mint", "Lax Mint", "Relaxed Mint", "Modest Mint",
 "Mild Mint", "Rash Mint", "Quiet Mint", "Calm Mint", "Gentle Mint", "Careful Mint", "Sassy Mint", "Timid Mint",
 "Hasty Mint", "Jolly Mint", "Naive Mint", "Serious Mint", "Wishing Piece", "Cracked Pot", "Chipped Pot", "Hi-tech Earbuds",
 "Fruit Bunch", "Moomoo Cheese", "Spice Mix", "Fresh Cream", "Packaged Curry", "Coconut Milk", "Instant Noodles", "Precooked Burger",
 "Gigantamix", "Wishing Chip", "Rotom Bike", "Catching Charm", "unknown", "Old Letter", "Band Autograph", "Sonia’s Book",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "Rotom Catalog", "★And458",
 "★And15", "★And337", "★And603", "★And390", "★Sgr6879", "★Sgr6859", "★Sgr6913", "★Sgr7348",
 "★Sgr7121", "★Sgr6746", "★Sgr7194", "★Sgr7337", "★Sgr7343", "★Sgr6812", "★Sgr7116", "★Sgr7264",
 "★Sgr7597", "★Del7882", "★Del7906", "★Del7852", "★Psc596", "★Psc361", "★Psc510", "★Psc437",
 "★Psc8773", "★Lep1865", "★Lep1829", "★Boo5340", "★Boo5506", "★Boo5435", "★Boo5602", "★Boo5733",
 "★Boo5235", "★Boo5351", "★Hya3748", "★Hya3903", "★Hya3418", "★Hya3482", "★Hya3845", "★Eri1084",
 "★Eri472", "★Eri1666", "★Eri897", "★Eri1231", "★Eri874", "★Eri1298", "★Eri1325", "★Eri984",
 "★Eri1464", "★Eri1393", "★Eri850", "★Tau1409", "★Tau1457", "★Tau1165", "★Tau1791", "★Tau1910",
 "★Tau1346", "★Tau1373", "★Tau1412", "★CMa2491", "★CMa2693", "★CMa2294", "★CMa2827", "★CMa2282",
 "★CMa2618", "★CMa2657", "★CMa2646", "★UMa4905", "★UMa4301", "★UMa5191", "★UMa5054", "★UMa4295",
 "★UMa4660", "★UMa4554", "★UMa4069", "★UMa3569", "★UMa3323", "★UMa4033", "★UMa4377", "★UMa4375",
 "★UMa4518", "★UMa3594", "★Vir5056", "★Vir4825", "★Vir4932", "★Vir4540", "★Vir4689", "★Vir5338",
 "★Vir4910", "★Vir5315", "★Vir5359", "★Vir5409", "★Vir5107", "★Ari617", "★Ari553", "★Ari546",
 "★Ari951", "★Ori1713", "★Ori2061", "★Ori1790", "★Ori1903", "★Ori1948", "★Ori2004", "★Ori1852",
 "★Ori1879", "★Ori1899", "★Ori1543", "★Cas21", "★Cas168", "★Cas403", "★Cas153", "★Cas542",
 "★Cas219", "★Cas265", "★Cnc3572", "★Cnc3208", "★Cnc3461", "★Cnc3449", "★Cnc3429", "★Cnc3627",
 "★Cnc3268", "★Cnc3249", "★Com4968", "★Crv4757", "★Crv4623", "★Crv4662", "★Crv4786", "★Aur1708",
 "★Aur2088", "★Aur1605", "★Aur2095", "★Aur1577", "★Aur1641", "★Aur1612", "★Pav7790", "★Cet911",
 "★Cet681", "★Cet188", "★Cet539", "★Cet804", "★Cep8974", "★Cep8162", "★Cep8238", "★Cep8417",
 "★Cen5267", "★Cen5288", "★Cen551", "★Cen5459", "★Cen5460", "★CMi2943", "★CMi2845", "★Equ8131",
 "★Vul7405", "★UMi424", "★UMi5563", "★UMi5735", "★UMi6789", "★Crt4287", "★Lyr7001", "★Lyr7178",
 "★Lyr7106", "★Lyr7298", "★Ara6585", "★Sco6134", "★Sco6527", "★Sco6553", "★Sco5953", "★Sco5984",
 "★Sco6508", "★Sco6084", "★Sco5944", "★Sco6630", "★Sco6027", "★Sco6247", "★Sco6252", "★Sco5928",
 "★Sco6241", "★Sco6165", "★Tri544", "★Leo3982", "★Leo4534", "★Leo4357", "★Leo4057", "★Leo4359",
 "★Leo4031", "★Leo3852", "★Leo3905", "★Leo3773", "★Gru8425", "★Gru8636", "★Gru8353", "★Lib5685",
 "★Lib5531", "★Lib5787", "★Lib5603", "★Pup3165", "★Pup3185", "★Pup3045", "★Cyg7924", "★Cyg7417",
 "★Cyg7796", "★Cyg8301", "★Cyg7949", "★Cyg7528", "★Oct7228", "★Col1956", "★Col2040", "★Col2177",
 "★Gem2990", "★Gem2891", "★Gem2421", "★Gem2473", "★Gem2216", "★Gem2777", "★Gem2650", "★Gem2286",
 "★Gem2484", "★Gem2930", "★Peg8775", "★Peg8781", "★Peg39", "★Peg8308", "★Peg8650", "★Peg8634",
 "★Peg8684", "★Peg8450", "★Peg8880", "★Peg8905", "★Oph6556", "★Oph6378", "★Oph6603", "★Oph6149",
 "★Oph6056", "★Oph6075", "★Ser5854", "★Ser7141", "★Ser5879", "★Her6406", "★Her6148", "★Her6410",
 "★Her6526", "★Her6117", "★Her6008", "★Per936", "★Per1017", "★Per1131", "★Per1228", "★Per834",
 "★Per941", "★Phe99", "★Phe338", "★Vel3634", "★Vel3485", "★Vel3734", "★Aqr8232", "★Aqr8414",
 "★Aqr8709", "★Aqr8518", "★Aqr7950", "★Aqr8499", "★Aqr8610", "★Aqr8264", "★Cru4853", "★Cru4730",
 "★Cru4763", "★Cru4700", "★Cru4656", "★PsA8728", "★TrA6217", "★Cap7776", "★Cap7754", "★Cap8278",
 "★Cap8322", "★Cap7773", "★Sge7479", "★Car2326", "★Car3685", "★Car3307", "★Car3699", "★Dra5744",
 "★Dra5291", "★Dra6705", "★Dra6536", "★Dra7310", "★Dra6688", "★Dra4434", "★Dra6370", "★Dra7462",
 "★Dra6396", "★Dra6132", "★Dra6636", "★CVn4915", "★CVn4785", "★CVn4846", "★Aql7595", "★Aql7557",
 "★Aql7525", "★Aql7602", "★Aql7235", "Max Honey", "Max Mushrooms", "Galarica Twig", "Galarica Cuff", "Style Card",
 "Armor Pass", "Rotom Bike", "Rotom Bike", "Exp. Charm", "Armorite Ore", "Mark Charm", "Reins of Unity", "Reins of Unity",
 "Galarica Wreath", "Legendary Clue 1", "Legendary Clue 2", "Legendary Clue 3", "Legendary Clue?", "Crown Pass", "Wooden Crown",
 "Radiant Petal", "White Mane Hair", "Black Mane Hair", "Iceroot Carrot", "Shaderoot Carrot", "Dynite Ore", "Carrot Seeds",
 "Ability Patch", "Reins of Unity", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown", "unknown",
 "Mysterious Shard S", "Mysterious Shard L", "Digger Drill", "Kanto Slate", "Johto Slate", "Soul Slate", "Rainbow Slate", "Squall Slate",
 "Oceanic Slate", "Tectonic Slate", "Stratospheric Slate", "Genome Slate", "Discovery Slate", "Distortion Slate", "DS Sounds"}

local STOREDSIZE = 328
local BLOCKSIZE = 80

local BLOCKPOSITION = {
 0, 1, 2, 3,
 0, 1, 3, 2,
 0, 2, 1, 3,
 0, 3, 1, 2,
 0, 2, 3, 1,
 0, 3, 2, 1,
 1, 0, 2, 3,
 1, 0, 3, 2,
 2, 0, 1, 3,
 3, 0, 1, 2,
 2, 0, 3, 1,
 3, 0, 2, 1,
 1, 2, 0, 3,
 1, 3, 0, 2,
 2, 1, 0, 3,
 3, 1, 0, 2,
 2, 3, 0, 1,
 3, 2, 0, 1,
 1, 2, 3, 0,
 1, 3, 2, 0,
 2, 1, 3, 0,
 3, 1, 2, 0,
 2, 3, 1, 0,
 3, 2, 1, 0,

 --duplicates of 0-7 to eliminate modulus
 0, 1, 2, 3,
 0, 1, 3, 2,
 0, 2, 1, 3,
 0, 3, 1, 2,
 0, 2, 3, 1,
 0, 3, 2, 1,
 1, 0, 2, 3,
 1, 0, 3, 2}

function leValue(str)
 local noSpaceStr = str:gsub("%s+", "")
 local i = #noSpaceStr
 local leStr = ""

 while i > 1 do
  leStr = leStr..noSpaceStr:sub(i - 1, i)
  i = i - 2
 end

 return tonumber(leStr, 16)
end

function LCRNG(s)
 local a = 0x41C6 * (s % 0x10000) + bShr(s, 16) * 0x4E6D
 local b = 0x4E6D * (s % 0x10000) + (a % 0x10000) * 0x10000 + 0x6073
 local c = b % 4294967296

 return c
end

PK8 = {}
PK8.__index = PK8

function PK8.new(cryptedPKString)
 local o = setmetatable({}, PK8)
 o.buff = cryptedPKString

 return o
end

function PK8:getEC()
 local ec = self.buff:sub(1, (0x4 * 3) - 1)

 return leValue(ec)
end

function PK8:getSpecies()
 local species = self.buff:sub((0x8 * 3) + 1, (0x8 * 3) + ((0x2 * 3) - 1))

 return leValue(species)
end

function PK8:getHeldItem()
 local heldItem = self.buff:sub((0xA * 3) + 1, (0xA * 3) + ((0x2 * 3) - 1))

 return leValue(heldItem)
end

function PK8:getSIDTID()
 local sidtid = self.buff:sub((0x0C * 3) + 1, (0x0C * 3) + ((0x4 * 3) - 1))

 return leValue(sidtid)
end

function PK8:getAbility()
 local ability = self.buff:sub((0x14 * 3) + 1, (0x14 * 3) + ((0x2 * 3) - 1))

 return leValue(ability)
end

function PK8:getAbilityNum()
 local abilityNum = self.buff:sub((0x16 * 3) + 1, (0x16 * 3) + 2)

 return bAnd(leValue(abilityNum), 0x7)
end

function PK8:getPID()
 local pid = self.buff:sub((0x1C * 3) + 1, (0x1C * 3) + ((0x4 * 3) - 1))

 return leValue(pid)
end

function PK8:getNature()
 local nature = self.buff:sub((0x20 * 3) + 1, (0x20 * 3) + 2)

 return leValue(nature)
end

function PK8:getMove1()
 local move1 = self.buff:sub((0x72 * 3) + 1, (0x72 * 3) + ((0x2 * 3) - 1))

 return leValue(move1)
end

function PK8:getMove2()
 local move2 = self.buff:sub((0x74 * 3) + 1, (0x74 * 3) + ((0x2 * 3) - 1))

 return leValue(move2)
end

function PK8:getMove3()
 local move3 = self.buff:sub((0x76 * 3) + 1, (0x76 * 3) + ((0x2 * 3) - 1))

 return leValue(move3)
end

function PK8:getMove4()
 local move4 = self.buff:sub((0x78 * 3) + 1, (0x78 * 3) + ((0x2 * 3) - 1))

 return leValue(move4)
end

function PK8:getIV32()
 local iv32 = self.buff:sub((0x8C * 3) + 1, (0x8C * 3) + ((0x4 * 3) - 1))

 return leValue(iv32)
end

function PK8:getIVs()
 local iv32 = self:getIV32()
 local ivHp = bAnd(iv32, 0x1F)
 local ivAtk = bAnd(bShr(iv32, 5), 0x1F)
 local ivDef = bAnd(bShr(iv32, 10), 0x1F)
 local ivSpAtk = bAnd(bShr(iv32, 20), 0x1F)
 local ivSpDef = bAnd(bShr(iv32, 25), 0x1F)
 local ivSpd = bAnd(bShr(iv32, 15), 0x1F)

 return string.format("%0d/%0d/%0d/%0d/%0d/%0d", ivHp, ivAtk, ivDef, ivSpAtk, ivSpDef, ivSpd)
end

function PK8:getFakeXor()
 local SIDTID = self:getSIDTID()
 local PID = self:getPID()
 return bShr(SIDTID, 16) ~ (bAnd(SIDTID, 0xFFFF) ~ bShr(PID, 16) ~ bAnd(PID, 0xFFFF))
end

function PK8:getShinyType()
 local PID = self:getPID()
 local fakeXor = self:getFakeXor()

 if fakeXor > 15 then
  return 0
 else
  if fakeXor == 0 then
   return 2
  else
   return 1
  end
 end
end

function PK8:shinyString()
 local shinyType = self:getShinyType()

 if shinyType == 0 then
  return ""
 elseif shinyType == 1 then
  return " (Star)"
 else
  return " (Square)"
 end
end

function PK8:getFinalPID()
 local PID = self:getPID()
 local fakeXor = self:getFakeXor()
 local PSV = bShr(bShr(PID, 16) ~ bAnd(PID, 0xFFFF), 4)
 local realXor = bShr(PID, 16) ~ bAnd(PID, 0xFFFF) ~ TID ~ SID

 if fakeXor < 16 then -- Force shiny
  local shinyType = self:getShinyType()

  if fakeXor ~= realXor then
   local high = bAnd(PID, 0xFFFF) ~ TID ~ SID ~ (2 - shinyType)
   PID = bOr(bShl(high, 16), bAnd(PID, 0xFFFF))
  end
 else -- Force non shiny
  if PSV == TSV then
   PID = PID ~ 0x10000000
  end
 end

 return PID
end

function PK8:getAbilityString()
 if self:getAbilityNum() < 4 then
  return tostring(self:getAbilityNum() - 1)
 else
  return "H"
 end
end

function PK8:cryptPKM(seed, start, ending)
 local i = (start * 3) + 1

 while i <= (ending * 3) - 5 do
  seed = LCRNG(seed)
  self.buff = self.buff:sub(1, i - 1)..string.format("%02X", tonumber(self.buff:sub(i, i + 1), 16) ~ bAnd(bShr(seed, 16), 0xFF))..self.buff:sub(i + 2)
  i = i + 3
  self.buff = self.buff:sub(1, i - 1)..string.format("%02X", tonumber(self.buff:sub(i, i + 1), 16) ~ bAnd(bShr(seed, 24), 0xFF))..self.buff:sub(i + 2)
  i = i + 3
 end
end

function PK8:shuffle(sv)
 local idx = 4 * sv
 local sdata = self.buff

 for block = 0, 3 do
  local ofs = BLOCKPOSITION[idx + block + 1]
  self.buff = self.buff:sub(1, (8 + BLOCKSIZE * block) * 3)..sdata:sub(((8 + BLOCKSIZE * ofs) * 3) + 1, ((8 + BLOCKSIZE * (ofs + 1)) * 3) - 3)..self.buff:sub(((8 + BLOCKSIZE * (block + 1)) * 3) - 2)
 end
end

function PK8:decrypt()
 local seed = self:getEC()
 local sv = bAnd(bShr(seed, 13), 0x1F)

 self:cryptPKM(seed, 8, STOREDSIZE)
 self:shuffle(sv)
end

function PK8:print()
 --print(self.buff)
 print(string.format("Species: %s", speciesNamesList[self:getSpecies()]))
 print(string.format("PID: %08X%s", self:getFinalPID(), self:shinyString()))
 print(string.format("Nature: %s", natureNamesList[self:getNature() + 1]))
 print(string.format("Ability: %s (%s)", abilityNamesList[self:getAbility()], self:getAbilityString()))
 print(string.format("IVs: %s", self:getIVs()))
 print(string.format("Held Item: %s", itemNamesList[self:getHeldItem() + 1]))
 print("")
 print(string.format("Move: %s", moveNamesList[self:getMove1() + 1]))
 print(string.format("Move: %s", moveNamesList[self:getMove2() + 1]))
 print(string.format("Move: %s", moveNamesList[self:getMove3() + 1]))
 print(string.format("Move: %s", moveNamesList[self:getMove4() + 1]))
end



-- XorShift class
XorShift = {}
XorShift.__index = XorShift

function XorShift.new(s0, s1)
 local o = setmetatable({}, XorShift)
 o.initS0 = s0
 o.initS1 = s1
 o.s0 = s0
 o.s1 = s1
 o.advances = 0

 return o
end

function XorShift:next()
 local t = bAnd(self.s0, 0xFFFFFFFF)
 local s = bShr(self.s1, 32)

 t = t ~ bAnd(bShl(t, 11), 0xFFFFFFFF)
 t = t ~ bShr(t, 8)
 t = t ~ (s ~ bShr(s, 19))

 self.s0 = bAnd(bOr(bShl(bAnd(self.s1, 0xFFFFFFFF), 32), bShr(self.s0, 32)), 0xFFFFFFFFFFFFFFFF)
 self.s1 = bAnd(bOr(bShl(t, 32), bShr(self.s1, 32)), 0xFFFFFFFFFFFFFFFF)
 self.advances = self.advances + 1

 return bAnd(((t % 0xFFFFFFFF) + 0x80000000), 0xFFFFFFFF)
end

function XorShift:print()
 print(string.format("Initial Seed:\nS[0]: %016X  S[1]: %016X", self.initS0, self.initS1))
 print("")
 print(string.format("Current Seed:\nS[0]: %016X  S[1]: %016X", self.s0, self.s1))
 print("")
 print(string.format("Advances: %d", self.advances))
 print("\n")
end

local initRNG = XorShift.new(readQword(s0Addr), readQword(s1Addr))



-- Printing functions
local function printEggInfo()
 local isEggReady = readQword(isEggReadyFlagAddr) == 0x01
 local eggStepsCounter = 180 - readBytes(eggStepsCounterAddr)

 if not isEggReady then
  print("Egg Steps Counter: "..eggStepsCounter)
  print("Egg is not ready")
 end

 if isEggReady then
  local eggSeed = readInteger(eggSeedAddr)
  print("Egg generated, go get it!")
  print(string.format("Egg Seed: %08X", eggSeed))
 elseif eggStepsCounter == 1 then
  print("Next step might generate an egg!")
 elseif eggStepsCounter == 180 then
  print("180th step taken")
 else
  print("Keep on steppin'")
 end

 print("\n")
end

local function printTrainerInfo()
 print(string.format("G8TID: %d", G8TID))
 print(string.format("TID: %d", TID))
 print(string.format("SID: %d", SID))
 print(string.format("TSV: %d", TSV))
 print("\n")
end

local function printWildInfo()
 local battleSetupParamAddr = getBattleSetupParamAddr(playerPrefsProviderAddr)
 print("Wild Info")

 if battleSetupParamAddr ~= nil then
  local decStringBuff = table.concat(readBytes(battleSetupParamAddr, STOREDSIZE, true), " ")
  local hexStringBuff = decStringBuff:gsub("%S+", function (c) return string.format("%02X", c) end)

  local pk = PK8.new(hexStringBuff)
  pk:decrypt()
  pk:print()
 else
  print("No battle started")
 end
end

local function printRngInfo()
 local currS0 = readQword(s0Addr)
 local currS1 = readQword(s1Addr)
 local skips = 0

 while (currS0 ~= initRNG.s0 or currS1 ~= initRNG.s1) and skips < 99999 do
  initRNG:next()
  skips = skips + 1

  if currS0 == initRNG.s0 and currS1 == initRNG.s1 then
   GetLuaEngine().MenuItem5.doClick()
   initRNG:print()
   printEggInfo()
   printTrainerInfo()
   printWildInfo()
  end
 end
end



-- Timer function
local function aTimerTick(timer)
 if isKeyPressed(VK_0) or isKeyPressed(VK_NUMPAD0) then
  timer.destroy()
 end

 printRngInfo()
end



-- Main
initRNG:print()
printEggInfo()
printTrainerInfo()
printWildInfo()

local aTimer = nil
local timerInterval = 50

aTimer = createTimer(getMainForm())
aTimer.Interval = timerInterval
aTimer.OnTimer = aTimerTick
aTimer.Enabled = true