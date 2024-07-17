-- Based on Malik's and Blue's animal shelters and vorp animal shelter, hunting/raising/tracking system added by HAL, converted to RSG by Szileni

Config = {}

Config.Debug = true
Config.Img = "rsg-inventory/html/images/"

---------------------------------
-- SHOP SETTINGS
---------------------------------
Config.KeyBind      = 'J'
Config.UseTarget    = true --For Pet Shop NPC
Config.AlwaysOpen   = true -- if false configure the open/close times
Config.OpenTime     = 8 -- store opens
Config.CloseTime    = 20 -- store closes
Config.Payment      = 'money' -- can 'item' or 'money'
Config.SellTime     = 3000 -- time sell all

-- stable npc settings
Config.DistanceSpawn = 20.0
Config.FadeIn        = true

-- items shop
Config.PetShop = {
    -- pet shop items
    [1] = { name = 'feed_dog', price = 3, amount = 500, info = {}, type = 'item', slot = 1, },
    [2] = { name = "horsebrush",   price = 5,    amount = 500,  info = {}, type = "item", slot = 2, },
    -- [2] = { name = 'stimulant_dog', price = 3, amount = 500, info = {}, type = 'item', slot = 2, },
}

---------------------------------
-- shop/sell/stablepets locations
---------------------------------
Config.PetsLocations = {
    {
        stablepetid = 'valentine',
		name = Lang:t('label.petshop'),
        coords = vector3(-283.79, 659.05, 113.38),
        npcmodel = `mbh_rhodesrancher_females_01`,
        npccoords = vector4(-283.79, 659.05, 113.38, 84.08),
        npcpetmodel = `A_C_DogHound_01`,
        npcpetcoords = vector4(-284.50, 658.01, 113.31, 17.89),

        Ring = true,
        ActiveDistance = 1.5,
        -- Spawndog = vector4(-286.3233, 659.20825, 113.41064, 130.15997),
		scenario = 'MP_LOBBY_STANDING_D',

        showblip = true,
        blipsprite = 'blip_taxidermist',
        blipscale = 0.1,
},
    {
        stablepetid = 'blackwater',
		name = Lang:t('label.petshop'),
        coords = vector3(-939.59, -1238.36, 52.07),
        npcmodel = `u_m_m_bwmstablehand_01`,
        npccoords = vector4(-939.59, -1238.36, 52.07, 238.11),
		npcpetmodel = `A_C_DogAustralianSheperd_01`,
        npcpetcoords = vector4(-937.47, -1235.65, 52.09, 208.05),

        Ring = true,
        ActiveDistance = 1.5,
        -- Spawndog = vector4(-947.0184, -1225.372, 52.836936, 192.60287),
        scenario = 'MP_LOBBY_STANDING_C',

        showblip = true,
        blipsprite = 'blip_taxidermist',
        blipscale = 0.1,
},
}


---------------------------------
-- general settings
---------------------------------

--Not working correcly right now, I need to check it
--Config.AnimalTrackingJobOnly = false -- If true only people with the jobs below can use the tracking option
--Config.AnimalTrackingJobs = {
--	[1] = 'police',
--	[2] = 'hunter',
--}

--------------------
-- Pets Attributes
--------------------
Config.SpawnOnRoadOnly    = false -- always spawn on road
Config.CheckCycle         = 1 -- pet check system (mins)
Config.PetDieAge          = 30 -- pet age in days till it dies (days)
Config.StoreFleedPet      = true -- store pet if flee is used
Config.EnableServerNotify = true

Config.CallPetKey         = true --Set to true to use the CallPet hotkey below

Config.Prompt = {
    FleePet     = 0xE30CD707, -- R INPUT_ENTER
    PetAttack   = 0xDB096B85, -- CTRL INPUT_INTERACT_HORSE_BRUSH
    PetTrack    = 0x8FFC75D6, -- SHIFT INPUT_LOOK_BEHIND
    Stay        = 0x760A9C6F, -- F

    Follow      = 0xCEFD9220, -- E INPUT_INTERACT_HORSE_BRUSH
    HuntMode    = 0xC7B5340A, -- ENTER
    PetBrush    = 0x63A38F2C, -- B
    CallPet     = 0xD8F73058, -- U INPUT_AIM_IN_AIR
}

Config.DefensiveMode    = true --If set to true, pets will become hostile to anything you are in combat with
Config.SearchRadius     = 50.0 -- How far the pet will search for a hunted animal. Always a float value i.e 50.0

Config.NoFear           = true --Set this to true if you are using Bears/Wolves as pets so that your horses won't be in constant fear and wont get stuck on the eating dead body animation.
Config.RaiseAnimal      = true -- If this is enabled, you will have to feed your animal for it to gain XP and grow. Only full grown pets can use commands (halfway you get the Stay command)
Config.FullGrownXp      = 1000 -- The amount of XP that it is fully grown. At the halfway point the pet will grow to 50% of max size.
Config.XpPerFeed        = 20 -- The amount of XP every feed gives

Config.NotifyWhenHungry = true -- Puts up a little notification letting you know your pet can be fed. 
Config.FeedInterval     = 1800 -- 1800 = 30 min, How often in seconds the pet will want to be fed
Config.AnimalFood       = 'feed_dog' -- The item required to feed and/or level up your pet

--The attack command sets your animal to attack a target
Config.AttackCommand     = true -- Set true to be able to send your pet to attack a target you are locked on (holding right-click on them)
Config.AttackOnly = {-- <<Only have one of these 3 be true or all 3 false if you want the attack prompt on all targets -->>
    Players = false, -- The attack command works on only player peds
    Animals = false, -- The attack command works on animal types, not players/peds
    NPC     = false, -- If this is enabled, you can attack NPC peds and animals but not people
}

--The track command sets your animal to follow the selected target 
Config.TrackCommand      = true -- If this is enabled, you can send pets to track a target you are locked on
Config.TrackOnly = {  -- <<Only have one of these 3 be true or all 3 false if you want the track prompt on all targets -->>
    Players  = false, -- The track command works on only player peds
    Animals  = false, -- The track command works on animal types, not players/peds
    NPC      = false, -- If this is enabled, you can track NPC peds and animals but not people
}

Config.PetAttributes = {
    FollowDistance  = 5,
    Invincible      = false,
    SpawnLimiter    = 100, -- Set this to limit how often a pet can be spawned or 0 to disable it
    DeathCooldown   = 300, -- Time before a pet can be respawned after dying
}

---------------------------------
-- Pets carry animals
--------------------
Config.Animals = { --These are the animals the dogs will retrieve	 --Hash ID must be the ID of the table
	[-1003616053]   = {["name"] = "Duck", },
    [1459778951]    = {["name"] = "Eagle", },
	[-164963696]    = {["name"] = "Herring Seagull",},
	[-1104697660]   = {["name"] = "Vulture",},
	[-466054788]    = {["name"] = "Wild Turkey",},
    [-2011226991]   = {["name"] = "Wild Turkey",},
    [-166054593]    = {["name"] = "Wild Turkey",},
	[-1076508705]   = {["name"] = "Roseate Spoonbill",},
	[-466687768]    = {["name"] = "Red-Footed Booby",},
	[-575340245]    = {["name"] = "Wester Raven",},
	[1416324601]    = {["name"] = "Ring-Necked Pheasant",},
	[1265966684]    = {["name"] = "American White Pelican",},
	[-1797450568]   = {["name"] = "Blue And Yellow Macaw",},
	[-2073130256]   = {["name"] = "Double-Crested Cormorant",},
	[-564099192]    = {["name"] = "Whooping Crane",},
	[723190474]     = {["name"] = "Canada Goose",},
	[-2145890973]   = {["name"] = "Ferruinous Hawk",},
	[1095117488]    = {["name"] = "Great Blue Heron",},
	[386506078]     = {["name"] = "Common Loon",},
	[-861544272]    = {["name"] = "Great Horned Owl",},
}

---------------------------------
-- pet health/stamina/ability/speed/acceleration levels
---------------------------------
Config.Level1 = 100
Config.Level2 = 200
Config.Level3 = 300
Config.Level4 = 400
Config.Level5 = 500
Config.Level6 = 900
Config.Level7 = 1000
Config.Level8 = 1500
Config.Level9 = 1750
Config.Level10 = 2000

---------------------------------
-- player feed pet settings
---------------------------------
Config.PetFeed = {
    ["feed_dog"]      = { health = 10,  eating = 10,  ismedicine = false },
    ["drink_dog"]     = { health = 10,  thirst = 10,  ismedicine = false },
    -- medicineHash is optional. If u do not set, the default value
    -- ["stimulant_dog"] = { health = 100, stamina = 100, ismedicine = true, medicineHash = "consumable_pet_stimulant" },
}

---------------------------------
-- pet bonding settings
---------------------------------
Config.MaxBondingLevel = 5000

---------------------------------
-- pet settings -- client/pets.lua
---------------------------------
Config.PetBuySpawn = {
    -- valentine
    {
        petcoords = vector4(-290.62, 657.11, 113.57, 122.57),
        petmodel = 'A_C_DogHusky_01',
        petprice = 200,
        petname = 'Husky',
        stablepetid = 'valentine',
    },
    {
        petcoords = vector4(-289.32, 653.85, 113.44, 297.49),
        petmodel = 'A_C_DogCatahoulaCur_01',
        petprice = 50,
        petname = 'Mutt',
        stablepetid = 'valentine'
    },
    {
        petcoords = vector4(-283.77, 653.09, 113.22, 124.67),
        petmodel = 'A_C_DogLab_01',
        petprice = 100,
        petname = 'Labrador Retriever',
        stablepetid = 'valentine'
    },
    {
        petcoords = vector4(-286.63, 649.03, 113.24, 295.18),
        petmodel = 'A_C_DogRufus_01',
        petprice = 100,
        petname = 'Rufus',
        stablepetid = 'valentine'
    },
    {
        petcoords = vector4(-285.48, 654.38, 113.10, 120.20),
        petmodel = 'A_C_DogBluetickCoonhound_01',
        petprice = 150,
        petname = 'Coon Hound',
        stablepetid = 'valentine'
    },
    -- blackwater
    {
        petcoords = vector4(-935.24, -1241.28, 51.55, 58.12),
        petmodel = 'A_C_DogHound_01',
        petprice = 200,
        petname = 'Hound',
        stablepetid = 'blackwater'
    },
    {
        petcoords = vector4(-933.99, -1240.08, 51.49, 48.18),
        petmodel = 'A_C_DogCollie_01',
        petprice = 500,
        petname = 'Collie',
        stablepetid = 'blackwater'
    },
    {
        petcoords = vector4(-936.63, -1242.85, 51.62, 15.40),
        petmodel = 'A_C_DogPoodle_01',
        petprice = 120,
        petname = 'Poodle',
        stablepetid = 'blackwater'
    },
    {
        petcoords = vector4(-932.13, -1237.06, 51.33, 53.85),
        petmodel = 'A_C_DogAmericanFoxhound_01',
        petprice = 225,
        petname = 'Fox hound',
        stablepetid = 'blackwater'
    },
    {
        petcoords = vector4(-933.00, -1238.60, 51.41, 59.48),
        petmodel = 'A_C_DogAustralianSheperd_01',
        petprice = 350,
        petname = 'Australian Sheperd',
        stablepetid = 'blackwater'
    }
}
