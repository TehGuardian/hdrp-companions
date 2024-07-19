local RSGCore = exports['rsg-core']:GetCoreObject()

---- pets
local entities = {}
local timeout = false
local timeoutTimer = 30
local dogPed = 0
local dogBlip = nil
local dogSpawned = false
local DogCalled = false
local dogXP = 0
local doggender = nil
local dogBonding = 0
local bondingLevel = 0
local dogLevel = 0

local closestStablePets = nil
local SpawnedPetshopBilps ={}

--------------------------------------
-- PROMPTS E 'Feed' / 'Pet Attack' / C 'Pet Track' / 'Follow' / C 'Stay' / F 'Hunt Mode' / 
--------------------------------------
local MenuPrompt = {}
local ActionsPrompt = {}

local AttackPrompt = {}
local TrackPrompt = {}

local AddedAttackPrompt = {} -- Add the entities you've already targeted so it doesn't try adding the prompt over and over again. 
local AddedTrackPrompt = {} -- Add the entities you've already targeted so it doesn't try adding the prompt over and over again. 


local function SetPetAttributes(entity)
    -- | SET_ATTRIBUTE_POINTS | --
    Citizen.InvokeNative( 0x09A59688C26D88DF, entity, 0, 1100 )
    Citizen.InvokeNative( 0x09A59688C26D88DF, entity, 1, 1100 )
    Citizen.InvokeNative( 0x09A59688C26D88DF, entity, 2, 1100 )
    -- | ADD_ATTRIBUTE_POINTS | --
    Citizen.InvokeNative( 0x75415EE0CB583760, entity, 0, 1100 )
    Citizen.InvokeNative( 0x75415EE0CB583760, entity, 1, 1100 )
    Citizen.InvokeNative( 0x75415EE0CB583760, entity, 2, 1100 )
    -- | SET_ATTRIBUTE_BASE_RANK | --
    Citizen.InvokeNative( 0x5DA12E025D47D4E5, entity, 0, 10 )
    Citizen.InvokeNative( 0x5DA12E025D47D4E5, entity, 1, 10 )
    Citizen.InvokeNative( 0x5DA12E025D47D4E5, entity, 2, 10 )
    -- | SET_ATTRIBUTE_BONUS_RANK | --
    Citizen.InvokeNative( 0x920F9488BD115EFB, entity, 0, 10 )
    Citizen.InvokeNative( 0x920F9488BD115EFB, entity, 1, 10 )
    Citizen.InvokeNative( 0x920F9488BD115EFB, entity, 2, 10 )
    -- | SET_ATTRIBUTE_OVERPOWER_AMOUNT | --
    Citizen.InvokeNative( 0xF6A7C08DF2E28B28, entity, 0, 5000.0, false )
    Citizen.InvokeNative( 0xF6A7C08DF2E28B28, entity, 1, 5000.0, false )
    Citizen.InvokeNative( 0xF6A7C08DF2E28B28, entity, 2, 5000.0, false )
end

function AddAttackPrompts(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    local str2 = 'Pet Attack'
    AttackPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(AttackPrompt[entity], Config.Prompt.PetAttack)
    local str = CreateVarString(10, 'LITERAL_STRING', str2)
    PromptSetText(AttackPrompt[entity], str)
    PromptSetEnabled(AttackPrompt[entity], true)
    PromptSetVisible(AttackPrompt[entity], true)
    PromptSetStandardMode(AttackPrompt[entity], true)
    PromptSetGroup(AttackPrompt[entity], group)
    PromptRegisterEnd(AttackPrompt[entity])
end

function AddTrackPrompts(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    local str3 = 'Pet Track'
    TrackPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(TrackPrompt[entity], Config.Prompt.PetTrack)
    local str = CreateVarString(10, 'LITERAL_STRING', str3)
    PromptSetText(TrackPrompt[entity], str)
    PromptSetEnabled(TrackPrompt[entity], true)
    PromptSetVisible(TrackPrompt[entity], true)
    PromptSetStandardMode(TrackPrompt[entity], true)
    PromptSetGroup(TrackPrompt[entity], group)
    PromptRegisterEnd(TrackPrompt[entity])
end

local function AddActionsPrompts(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    local str4 = 'Actions'
    ActionsPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(ActionsPrompt[entity], Config.Prompt.Actions)
    local str = CreateVarString(10, 'LITERAL_STRING', str4)
    PromptSetText(ActionsPrompt[entity], str)
    PromptSetEnabled(ActionsPrompt[entity], true)
    PromptSetVisible(ActionsPrompt[entity], true)
    PromptSetStandardMode(ActionsPrompt[entity], true)
    PromptSetGroup(ActionsPrompt[entity], group)
    PromptRegisterEnd(ActionsPrompt[entity])
end

local function AddMenuPrompts(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    local str7 = 'Menu'
    MenuPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(MenuPrompt[entity], Config.Prompt.PetMenu)
    local str = CreateVarString(10, 'LITERAL_STRING', str7)
    PromptSetText(MenuPrompt[entity], str)
    PromptSetEnabled(MenuPrompt[entity], true)
    PromptSetVisible(MenuPrompt[entity], true)
    PromptSetStandardMode(MenuPrompt[entity], true)
    PromptSetGroup(MenuPrompt[entity], group)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, MenuPrompt, true)
    PromptRegisterEnd(MenuPrompt[entity])
end

------------------------------------
-- get closest stable to store pet
------------------------------------
local function SetClosestStablePetsLocation()
    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist = nil

    for k, v in pairs(Config.PetsLocations) do
        local dest = vector3(v.coords.x, v.coords.y, v.coords.z)
        local dist2 = #(pos - dest)

        if current then
            if dist2 < dist then
                current = v.stablepetid
                dist = dist2
            end
        else
            dist = dist2
            current = v.stablepetid
        end
    end

    if current ~= closestStablePets then
        closestStablePets = current
    end
end

------------------------------------
-- flee
------------------------------------

local function FleePet()
    TaskAnimalFlee(dogPed, cache.ped, -1)
    Wait(10000)
    TriggerEvent("hdrp-companions:client:FleePet")
    DeleteEntity(dogPed)
    dogPed = 0
    DogCalled = false
end

local function FleePetStore()
    TaskAnimalFlee(dogPed, cache.ped, -1)
    Wait(10000)
	SetClosestStablePetsLocation()
	TriggerServerEvent('hdrp-companions:server:fleeStorePet', closestStablePets)
    DeleteEntity(dogPed)
    dogPed = 0
    DogCalled = false
end
------------------------------------
-- exports
------------------------------------
-- Export for pet Level checks
exports('CheckPetsLevel', function()
    return dogLevel
end)

-- Export for pet Bonding Level checks
exports('CheckPetsBondingLevel', function()
    return bondingLevel
end)

-- Export for active dogPed
exports('CheckActivePets', function()
    return dogPed
end)

------------
-- commands
------------

RegisterCommand("fleepet", function() --  COMMAND
    if Config.StoreFleedPet then
		FleePetStore()
    else
        FleePet()
	end
	Wait(3000) -- Spam protect
end, false)

RegisterCommand('setpetname', function() -- rename pet name command
    local input = lib.inputDialog('Quieres cambiar el nombre de la mascota?', {
        {
            type = 'input',
            isRequired = true,
            label = 'Cual es el nuevo nombre?',
            icon = 'fas fa-paw'
        },
    })

    if not input then
        return
    end

    TriggerServerEvent('hdrp-companions:renamePet', input[1])
end, false)

--------------------------------------
-- PETSHOP PROMPTS hours system
--------------------------------------
Citizen.CreateThread(function()
    for _, v in pairs(Config.PetsLocations) do
        if Config.UseTarget == true then
			exports['rsg-target']:AddCircleZone(v.stablepetid, v.coords, 2, {
				name = v.stablepetid,
				debugPoly = false,
			}, {
				options = {
					{   type = "client",
						action = function()
							TriggerEvent('hdrp-companions:client:openpetshop2', v.stablepetid)
						end,
						icon = "fas fa-comments-dollar",
						label = v.name,
					},
				},
				distance = 3,
			})
		else
            exports['rsg-core']:createPrompt(v.stablepetid, v.coords, RSGCore.Shared.Keybinds[Config.KeyBind], v.name, {
                type = 'client',
                event = 'hdrp-companions:client:openpetshop2',
				args = { v.stablepetid },
            })
        end
    end
end)

-- open petshop with opening hours
local OpenPetShop = function(stablepetid)
    if not Config.AlwaysOpen then
        local hour = GetClockHours()
        if (hour < Config.OpenTime) or (hour >= Config.CloseTime) and not Config.AlwaysOpen then
            lib.notify({ title = Lang:t('info.close_1'), description = Lang:t('info.close_2')..Config.OpenTime..Lang:t('info.close_3'), type = 'error', icon = 'fa-solid fa-shop', iconAnimation = 'shake', duration = 7000})
            return
        end
    end
    TriggerEvent('hdrp-companions:client:openpetshop', stablepetid)
end

-- get petshelter hours function
local GetPetShelterHours = function()
    local hour = GetClockHours()
    if not Config.AlwaysOpen then
        if (hour < Config.OpenTime) or (hour >= Config.CloseTime) then
            for k, v in pairs(SpawnedPetshopBilps) do
                BlipAddModifier(v, joaat('BLIP_MODIFIER_MP_COLOR_2'))
            end
        else
            for k, v in pairs(SpawnedPetshopBilps) do
                BlipAddModifier(v, joaat('BLIP_MODIFIER_MP_COLOR_8'))
            end
        end
    else
        for k, v in pairs(SpawnedPetshopBilps) do
            BlipAddModifier(v, joaat('BLIP_MODIFIER_MP_COLOR_8'))
        end
    end
end

-- get petshelter hours on player loading
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    GetPetShelterHours()
end)

-- update petshop hours every min
CreateThread(function()
    while true do
        GetPetShelterHours()
        Wait(60000) -- every min
    end
end)

AddEventHandler('hdrp-companions:client:openpetshop2', function(stablepetid)
    OpenPetShop(stablepetid)
end)

-- PETSHOP OPEN AND MENUS
RegisterNetEvent('hdrp-companions:client:openpetshop', function(stablepetid)
    for _, v in pairs(Config.PetsLocations) do
        if v.stablepetid == stablepetid then
            lib.registerContext({
                id = 'petshop_menu',
                title = Lang:t('label.petshop'),
                options = {
                    {   title = 'Ver mascotas',
                        description = 'pets view pets',
                        icon = 'fa-solid fa-eye',
                        event = 'hdrp-companions:client:menuinfo',
                        args = { stablepetid = stablepetid },
                        arrow = true
                    },
                    {   title = Lang:t('label.petshop_3'),
                        icon = 'fa-solid fa-coins',
                        event = 'hdrp-companions:client:MenuDel',
                        arrow = true
                    },
                    {   title = 'Comercio/Intercambio',
                        icon = 'fa-solid fa-people-arrows',
                        event = 'hdrp-companions:client:tradepet',
                        arrow = true
                    },
                    {   title = "Vender animales capturados",
                        icon = 'fas fa-shopping-basket',
                        event = 'hdrp-companions:client:openSellMenu',
                        args = { stablepetid },
                    },
                    {	title = Lang:t('label.petshop_2'),
                        icon = 'fa-solid fa-box',
                        event = 'hdrp-companions:client:OpenPetShop',
                        arrow = true
                    },
                    {   title = 'Almacenar mascota',
                        icon = 'fa-solid fa-warehouse',
                        event = 'hdrp-companions:client:storepet',
                        args = { stablepetid = stablepetid },
                        arrow = true
                    },
                }
            })
            lib.showContext('petshop_menu')
        end
    end
end)

-------------------------
-- OPTIONS PETS STABLE MENUS
-------------------------
local function TradePet()
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetActivePet', function(data, newnames)
        if dogPed ~= 0 then
            local player, distance = RSGCore.Functions.GetClosestPlayer()
            if player ~= -1 and distance < 1.5 then
                local playerId = GetPlayerServerId(player)
                local petId = data.dogid
                TriggerServerEvent('hdrp-companions:server:TradePet', playerId, petId)
                RSGCore.Functions.Notify('pet_traded', 'success', 7500)
            else
                RSGCore.Functions.Notify('no_nearby_player', 'success', 7500)
            end
        end
    end)
end

--------------------------------------
-- SPAWN PET
--------------------------------------
-- place on ground properly
local function PlacePedOnGroundProperly(hPed)
    local playerPed = PlayerPedId()
    local howfar = math.random(15, 30)
    local x, y, z = table.unpack(GetEntityCoords(playerPed))
    local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(x - howfar, y, z)

    if found then
        SetEntityCoordsNoOffset(hPed, x - howfar, y, groundz + normal.z, true)
    end
end

-- calculate pet bonding levels
local function BondingLevels()
    local maxBonding = GetMaxAttributePoints(dogPed, 7)
    local currentBonding = GetAttributePoints(dogPed, 7)
    local thirdBonding = maxBonding / 3

    if currentBonding >= maxBonding then
        bondingLevel = 4
    end

    if currentBonding >= thirdBonding and thirdBonding * 2 > currentBonding then
        bondingLevel = 2
    end

    if currentBonding >= thirdBonding * 2 and maxBonding > currentBonding then
        bondingLevel = 3
    end

    if thirdBonding > currentBonding then
        bondingLevel = 1
    end
end

local function setPetBehavior(pet)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), GetHashKey('PLAYER'))
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 143493179)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -2040077242)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 1222652248)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 1077299173)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -887307738)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1998572072)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -661858713)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 1232372459)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1836932466)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 1878159675)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 1078461828)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1535431934)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 1862763509)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1663301869)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1448293989)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1201903818)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -886193798)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1996978098)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 555364152)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -2020052692)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 707888648)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 378397108)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -350651841)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1538724068)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 1030835986)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1919885972)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1976316465)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 841021282)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 889541022)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1329647920)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -319516747)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -767591988)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -989642646)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), 1986610512)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(pet), -1683752762)
end

local function getControlOfEntity(entity)
    NetworkRequestControlOfEntity(entity)
    SetEntityAsMissionEntity(entity, true, true)
    local timeout = 2000

    while timeout > 0 and NetworkHasControlOfEntity(entity) == nil do
        Wait(100)
        timeout = timeout - 100
    end
    return NetworkHasControlOfEntity(entity)
end

CreateThread(function()
    while true do
        if (timeout) then
            if (timeoutTimer == 0) then
                timeout = false
            end
            timeoutTimer = timeoutTimer - 1
            Wait(1000)
        end
        Wait(0)
    end
end)

---------------
--
---------------
local function followOwner(pet, PlayerPedId)
	FreezeEntityPosition(pet, false)
	ClearPedTasks(pet)
	ClearPedSecondaryTask(pet)
	TaskFollowToOffsetOfEntity(pet, PlayerPedId, 0.0, -1.5, 0.0, 1.0, -1,  Config.PetAttributes.FollowDistance * 100000000, 1, 1, 0, 0, 1)
end

local function SpawnPet()
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetActivePet', function(data)
        if (data) then
            local ped = PlayerPedId()
            local player = PlayerId()
            local model = GetHashKey(data.dog)
            local location = GetEntityCoords(ped)
            local x, y, z = table.unpack(location)
            local _, nodePosition = GetClosestVehicleNode(x - 15, y, z, 0, 3.0, 0.0)
            local distance = math.floor(#(nodePosition - location))
            local onRoad = false

            if distance < 50 then
                onRoad = true
            end

            if Config.SpawnOnRoadOnly and not onRoad then
                RSGCore.Functions.Notify('near_road', 'error')
                return
            end

            if (location) then
                while not HasModelLoaded(model) do
                    RequestModel(model)
                    Wait(10)
                end

                local heading = 300

                getControlOfEntity(dogPed)

                if dogBlip then
                    RemoveBlip(dogBlip)
                end

                SetEntityAsMissionEntity(dogPed, true, true)
                DeleteEntity(dogPed)
                DeletePed(dogPed)
                SetEntityAsNoLongerNeeded(dogPed)

                dogPed = 0

                if onRoad then
                    dogPed = CreatePed(model, nodePosition, heading, true, true, 0, 0)
                    SetEntityCanBeDamaged(dogPed, false)
                    Citizen.InvokeNative(0x9587913B9E772D29, dogPed, false)
                    onRoad = false
                else
                    dogPed = CreatePed(model, location.x - 10, location.y, location.z, heading, true, true, 0, 0)
                    SetEntityCanBeDamaged(dogPed, false)
                    Citizen.InvokeNative(0x9587913B9E772D29, dogPed, false)
                    PlacePedOnGroundProperly(dogPed)
                end

                while not DoesEntityExist(dogPed) do
                    Wait(10)
                end

                getControlOfEntity(dogPed)

                dogBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1749618580, dogPed) -- BlipAddForEntity
                Citizen.InvokeNative(0x9CB1A1623062F402, dogBlip, data.name)           -- SetBlipName
                Citizen.InvokeNative(0x931B241409216C1F, ped, dogPed, true)            -- SetPedOwnsAnimal

                SetModelAsNoLongerNeeded(model)
                SetEntityAsNoLongerNeeded(dogPed)
                SetEntityAsMissionEntity(dogPed, true)
                SetEntityCanBeDamaged(dogPed, true)
                SetPedNameDebug(dogPed, data.name)
                SetPedPromptName(dogPed, data.name)

                -- set pet dirt
                Citizen.InvokeNative(0x5DA12E025D47D4E5, dogPed, 16, data.dirt)

				-- set PET OUTFIT
				SET_PED_OUTFIT_PRESET( dogPed, data.skin )

                -- set pet xp and gender
                dogXP = data.dogxp
                doggender = data.gender
                -- doggrowth = data.growth

                -- set pet health/stamina/ability/speed/acceleration (increased by pet training)
                local hValue = 0
                local overPower = false

                if dogXP <= 99 then
                    hValue = Config.Level1
                    dogLevel = 1
                    goto continue
                end
                if dogXP >= 100 and dogXP <= 199 then
                    hValue = Config.Level2
                    dogLevel = 2
                    goto continue
                end
                if dogXP >= 200 and dogXP <= 299 then
                    hValue = Config.Level3
                    dogLevel = 3
                    goto continue
                end
                if dogXP >= 300 and dogXP <= 399 then
                    hValue = Config.Level4
                    dogLevel = 4
                    goto continue
                end
                if dogXP >= 400 and dogXP <= 499 then
                    hValue = Config.Level5
                    dogLevel = 5
                    goto continue
                end
                if dogXP >= 500 and dogXP <= 999 then
                    hValue = Config.Level6
                    dogLevel = 6
                    goto continue
                end
                if dogXP >= 1000 and dogXP <= 1999 then
                    hValue = Config.Level7
                    dogLevel = 7
                    goto continue
                end
                if dogXP >= 2000 and dogXP <= 2999 then
                    hValue = Config.Level8
                    dogLevel = 8
                    goto continue
                end
                if dogXP >= 3000 and dogXP <= 3999 then
                    hValue = Config.Level9
                    dogLevel = 9
                    goto continue
                end
                if dogXP >= 4000 then
                    hValue = Config.Level10
                    dogLevel = 10
                    overPower = true
                end

                ::continue::
                -- SetPetAttributes(dogPed)
                SetAttributePoints(dogPed, 0, hValue) -- HEALTH (0-2000)
                SetAttributePoints(dogPed, 4, hValue) -- AGILITY (0-2000)
                SetAttributePoints(dogPed, 5, hValue) -- SPEED (0-2000)
                SetAttributePoints(dogPed, 6, hValue) -- ACCELERATION (0-2000)

                -- overpower settings
                if overPower then
                    EnableAttributeOverpower(dogPed, 0, 5000.0)                       -- health overpower
                    local setoverpower = data.dogxp + .0                              -- convert overpower to float value
                    Citizen.InvokeNative(0xF6A7C08DF2E28B28, dogPed, 0, setoverpower) -- set health with overpower
                end

                if Config.PetAttributes.Invincible then
					SetEntityInvincible(dogPed, true)
				end

                -- AddHuntModePrompts(dogPed)
                -- AddStayPrompts(dogPed)
                -- AddAttackPrompts(dogPed)
                -- AddTrackPrompts(dogPed)
                -- AddFleePrompts(dogPed)

                AddMenuPrompts(dogPed)
				AddActionsPrompts(dogPed)

				if Config.NoFear then
					Citizen.InvokeNative(0x013A7BA5015C1372, dogPed, true)
					Citizen.InvokeNative(0x3B005FF0538ED2A9, dogPed)
					Citizen.InvokeNative(0xAEB97D84CDF3C00B, dogPed, false)
				end

				SetPetAttributes(dogPed)
				setPetBehavior(dogPed)
				SetPedAsGroupMember(dogPed, GetPedGroupIndex(PlayerPedId()))

				if Config.RaiseAnimal then
					local halfGrowth1 = Config.FullGrownXp * 3 / 4
					local halfGrowth2 = Config.FullGrownXp / 2
					local halfGrowth4 = Config.FullGrownXp / 4

					if dogXP >= Config.FullGrownXp then
						SetPedScale(dogPed, 1.0) --Use this for the XP system with pets
					elseif dogXP >= halfGrowth1 then
						SetPedScale(dogPed, 0.9)
					elseif dogXP >= halfGrowth2 then
						SetPedScale(dogPed, 0.8)
					elseif dogXP >= halfGrowth4 then
						SetPedScale(dogPed, 0.7)
					else
						SetPedScale(dogPed, 0.6)
                    end
				else
					dogXP = Config.FullGrownXp
                    -- AddStayPrompts(dogPed)
                    -- AddHuntModePrompts(dogPed)
				end

				while (GetScriptTaskStatus(dogPed, 0x4924437d) ~= 8) do
					Wait(1000)
				end

				followOwner(dogPed, player)

				if isdead and Config.PetAttributes.Invincible == false then
					RSGCore.Functions.Notify(Lang:t('success.pethealed'), 'success', 3000)
				end
				-- end of overpower settings
                -- end set pet health/stamina/ability/speed/acceleration (increased by pet training)

                -- pet bonding level: start
                local bond = Config.MaxBondingLevel
                local bond1 = bond * 0.25
                local bond2 = bond * 0.50
                local bond3 = bond * 0.75

                if dogXP <= bond * 0.25 then -- level 1 (0 -> 1250)
                    dogBonding = 1
                end
                if dogXP > bond1 and dogXP <= bond2 then -- level 2 (1250 -> 2500)
                    dogBonding = 817
                end
                if dogXP > bond2 and dogXP <= bond3 then -- level 3 (2500 -> 3750)
                    dogBonding = 1634
                end
                if dogXP > bond3 then -- level 4 (3750 -> 5000)
                    dogBonding = 2450
                end

                Citizen.InvokeNative(0x09A59688C26D88DF, dogPed, 7, dogBonding)
                BondingLevels()
                -- pet bonding level: end

                local faceFeature = 0.0

                -- set gender of pet
                if doggender ~= 'male' then
                    faceFeature = 1.0
                end

                Citizen.InvokeNative(0xB8B6430EAD2D2437, dogPed, joaat('PLAYER_HORSE')) -- SetPedPersonality
                Citizen.InvokeNative(0x5653AB26C82938CF, dogPed, 41611, faceFeature)
                Citizen.InvokeNative(0xCC8CA3E88256E58F, dogPed, false, true, true, true, false)

                -- ModifyPlayerUiPromptForPed / pet Target Prompts / (Block = 0, Hide = 1, Grey Out = 2)
                --Citizen.InvokeNative(0xA3DB37EDF9A74635, player, dogPed, 35, 1, true) -- TARGET_INFO
                Citizen.InvokeNative(0xA3DB37EDF9A74635, player, dogPed, 49, 1, true) -- HORSE_BRUSH
                Citizen.InvokeNative(0xA3DB37EDF9A74635, player, dogPed, 50, 1, true) -- HORSE_FEED

                PetPrompts = PromptGetGroupIdForTargetEntity(dogPed)

                -- SetupPetPrompts()

                -- movePetToPlayer()

                Wait(5000)

                dogSpawned = true
                DogCalled = true

            end
        end
    end)
end

RegisterCommand("callpet", function() --  COMMAND
	SpawnPet()
	Wait(3000) -- Spam protect
end, false)

---------------
-- STOP RESOURCE
---------------
AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		FleePet()
        for k, v in pairs(entities) do
            DeletePed(v)
            SetEntityAsNoLongerNeeded(v)
        end
        if (dogPed ~= 0) then
            DeletePed(dogPed)
            SetEntityAsNoLongerNeeded(dogPed)
        end
	end
end)

Citizen.CreateThread(function()
    for _, v in pairs(Config.PetsLocations) do
		if v.showblip == true then
			local StablesPetsBlip = BlipAddForCoords(1664425300, v.coords)
			SetBlipSprite(StablesPetsBlip, joaat(v.blipsprite), true)
			SetBlipScale(StablesPetsBlip, v.blipscale)
			SetBlipName(StablesPetsBlip, v.name)
		end
    end
end)

-------------------------
-- SpawnPet
-------------------------
local PetId = nil

RegisterNetEvent('hdrp-companions:client:SpawnPet', function(data)
    PetId = data.player.id
    TriggerServerEvent("hdrp-companions:server:SetPetsActive", data.player.id)
    RSGCore.Functions.Notify('pet active', 'success', 7500)
end)

AddEventHandler('hdrp-companions:client:FleePet', function()
    if dogPed then
        getControlOfEntity(dogPed)

        if dogBlip then
            RemoveBlip(dogBlip)
        end

        SetEntityAsMissionEntity(dogPed, true, true)
        DeleteEntity(dogPed)
        DeletePed(dogPed)
        SetEntityAsNoLongerNeeded(dogPed)

        dogPed = 0
        DogCalled = false
    end
end)

RegisterNetEvent('hdrp-companions:client:storepet', function(data)
    if (dogPed ~= 0) then
        TriggerServerEvent('hdrp-companions:server:SetPetsUnActive', PetId, data.stablepetid)
        RSGCore.Functions.Notify('success.storing_pet', 'success', 7500)
        FleePetStore()
        DogCalled = false
    else
        RSGCore.Functions.Notify('no_pet_out', 'error', 7500)
    end
end)

-- pet menu trade
RegisterNetEvent("hdrp-companions:client:tradepet", function(data)
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetActivePet', function(data, newnames)
        if (dogPed ~= 0) then
            TradePet()
            if Config.StoreFleedPet then
                FleePetStore()
            else
                FleePet()
            end
            DogCalled = false
        else
            RSGCore.Functions.Notify('error.no_pet_out', 'error', 7500)
        end
    end)
end)

RegisterNetEvent('hdrp-companions:client:menuinfo', function(data)

    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetPet', function(pets)

        if pets == nil then
            RSGCore.Functions.Notify('error.no_pets', 'error')
            return
        end

        local options = {}

        for i = 1, #pets do
            local pets = pets[i]
            options[#options + 1] = {
                title = pets.name,
                description = 'Gender:' ..pets.gender ..' Xp: ' .. pets.dogxp .. ' Active: ' .. pets.active,
                icon = 'fa-solid fa-pet',
                event = 'hdrp-companions:client:SpawnPet',
                args = { player = pets, active = 1 },
                arrow = true
            }
        end

        lib.registerContext({
            id = 'pets_view',
            title = 'pet_view_pets',
            position = 'top-right',
            menu = 'petshop_menu',
            onBack = function() end,
            options = options
        })
        lib.showContext('pets_view')

    end, data.stablepetid)

end)

-- pet menu sell
RegisterNetEvent('hdrp-companions:client:MenuDel', function()
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetPetB', function(pets)
        if pets == nil then
            RSGCore.Functions.Notify('error.no_pets', 'error')
            return
        end
        local options = {}
        for i = 1, #pets do
            local pets = pets[i]
            options[#options + 1] = {
                title = pets.name,
                description = 'Gender:' ..pets.gender ..' Xp: ' .. pets.dogxp .. ' Active: ' .. pets.active,
                icon = 'fa-solid fa-paw',
                serverEvent = 'hdrp-companions:server:deletepet',
                args = { petid = pets.id, name = pets.name },
                arrow = true
            }
        end
        lib.registerContext({
            id = 'sellpet_menu', -- Corrected the context ID here
            title = 'sell_pet_menu',
            position = 'top-right',
            menu = 'petshop_menu',
            onBack = function() end,
            options = options
        })
        lib.showContext('sellpet_menu') -- Use the correct context ID here
    end)
end)

--------------------------------------
-- PET FLEE/CALL
--------------------------------------
Citizen.CreateThread(function() -- call
	while true do
        Wait(0)
		if Config.CallPetKey == true then
			if IsControlJustPressed(0, Config.Prompt.CallPet) then
				RSGCore.Functions.GetPlayerData(function(PlayerData)
					if PlayerData.metadata["injail"] == 0 then
						local coords = GetEntityCoords(PlayerPedId())
						local petCoords = GetEntityCoords(dogPed)
						local distance = #(coords - petCoords)

                        TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'CALLING_WHISTLE_01', 1)

						if not DogCalled and (distance > 100.0) then
							SpawnPet()
							Wait(3000) -- Spam protect
						else
							followOwner(dogPed, PlayerPedId())
						end
					end
				end)
			end
		end
        -- local size = GetNumberOfEvents(0)
        -- if size > 0 then
        --     for i = 0, size - 1 do
        --         local eventAtIndex = GetEventAtIndex(0, i)
        --         if eventAtIndex == `EVENT_PLAYER_PROMPT_TRIGGERED` then
        --             local eventDataSize = 10
        --             local eventDataStruct = DataView.ArrayBuffer(8*eventDataSize) -- buffer must be 8*eventDataSize or bigger
        --             for a = 0, eventDataSize -1 do
        --               eventDataStruct:SetInt32(8*a ,0)
        --             end
        --             local is_data_exists = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize)

        --             if is_data_exists then

        --                 if eventDataStruct:GetInt32(0) == 33 then
        --                     if dogPed == eventDataStruct:GetInt32(16) then
        --                         if Config.StoreFleedPet then
        --                             FleePetStore()
        --                         else
        --                             FleePet()
        --                         end
        --                     end
        --                 end
        --             end
        --         end
        --     end
        -- end
		Wait(1)
	end
end)

local RequestControl = function(entity)
    local type = GetEntityType(entity)

    if type < 1 or type > 3 then return end

    NetworkRequestControlOfEntity(entity)
end

local loadAnimDict = function(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- Player revive pet
RegisterNetEvent("hdrp-companions:client:revivepet")
AddEventHandler("hdrp-companions:client:revivepet", function(item, data)
    local playerPed = PlayerPedId()
    local playercoords = GetEntityCoords(playerPed)
    local petcoords = GetEntityCoords(dogPed)
    local distance = #(playercoords - petcoords)

    if dogPed == 0 then
        RSGCore.Functions.Notify('no_pet_out', 'error')

        return
    end

    if IsEntityDead(dogPed) then
        if distance > 1.5 then
            RSGCore.Functions.Notify('pet_too_far', 'error')

            return
        end

        RequestControl(dogPed)

        local healAnim1Dict1 = "mech_skin@sample@base"
        local healAnim1 = "sample_low"

        loadAnimDict(healAnim1Dict1)

        ClearPedTasks(playerPed)
        ClearPedSecondaryTask(playerPed)
        ClearPedTasksImmediately(playerPed)
        FreezeEntityPosition(playerPed, false)
        SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
        TaskPlayAnim(playerPed, healAnim1Dict1, healAnim1, 1.0, 1.0, -1, 0, false, false, false)

        if lib.progressBar({
            duration = 3000,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disableControl = true,
            disable = {
                move = true,
                mouse = true,
            },
            label = Lang:t('menu.reviving_pet'),
        }) then
            ClearPedTasks(playerPed)
            FreezeEntityPosition(playerPed, false)
            TriggerServerEvent('hdrp-companions:server:revivepet', item)
            SpawnPet()
        end
    else
        RSGCore.Functions.Notify('pet_not_injured_dead', 'error')
    end
end)

----------------------
--
----------------------
local petbusy = false
local candoaction = false

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(dogPed))
        local ZoneTypeId = 1
        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
        local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x, y, z, ZoneTypeId)
        if town == false then
            candoaction = true
        end
        if dogPed ~= 0 and petbusy and dist < 12 then
            if Citizen.InvokeNative(0x57AB4A3080F85143, dogPed) then -- IsPedUsingAnyScenario
                ClearPedTasks(dogPed)
                petbusy = false
            end
        end
        if dogPed ~= 0 and not petbusy and dist > 12 and dogSpawned and candoaction then
            if not Citizen.InvokeNative(0xAAB0FE202E9FC9F0, dogPed, -1) then -- IsMountSeatFree
                return
            end
            Citizen.InvokeNative(0x524B54361229154F, dogPed, joaat('WORLD_ANIMAL_HORSE_RESTING_DOMESTIC'), -1, true, 0, GetEntityHeading(dogPed), false)                                                                                                           -- TaskStartScenarioInPlaceHash
            petbusy = true
        end
        Wait(sleep)
    end
end)

-- save pet attributes 
-- Citizen.CreateThread(function()
--     while true do
--         local sleep = 5000
--         local petdirt = Citizen.InvokeNative(0x147149F2E909323C, dogPed, 16, Citizen.ResultAsInteger())
--         if dogPed ~= 0 then
--             TriggerServerEvent('hdrp-companions:server:setpetAttributes', petdirt)
--         end
--         Wait(sleep)
--     end
-- end)

-----------------
-- Pet menu Shop
-----------------
RegisterNetEvent('hdrp-companions:client:OpenPetShop', function()
    local ShopItems = {}
    ShopItems.label = Lang:t('label.petshop_2')
    ShopItems.items = Config.PetShop
    ShopItems.slots = #Config.PetShop
    TriggerServerEvent("inventory:server:OpenInventory", "shop", "PetShop_"..math.random(1, 99), ShopItems)
end)

-------------------------------------------------------------------------------
-- Command findpet get pet location server/server.lua
-------------------------------------------------------------------------------
RegisterNetEvent('hdrp-companions:client:getpetlocation', function()
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetAllPets', function(results)
        if results ~= nil then
            local options = {}
            for i = 1, #results do
                local results = results[i]
                options[#options + 1] = {
                    title = 'Pet: '..results.name,
                    description = 'is stabled in '..results.stablepet..' active: '..results.active,
                    icon = 'fa-solid fa-paw',
                }
            end
            lib.registerContext({
                id = 'showpet_menu',
                title = 'Find Your Pet',
                position = 'top-right',
                options = options
            })
            lib.showContext('showpet_menu')
        else
            RSGCore.Functions.Notify('no pets', 'error')
        end
    end)
end)

--------------------------
-- Mypets
--------------------------
RegisterNetEvent('hdrp-companions:client:mypets', function()
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetAllPets', function(results)
        if results ~= nil then
            local options = {}
            for i = 1, #results do

                local results = results[i]
                local timeDifference = results.born
                local daysPassed = math.floor(timeDifference / (24 * 60 * 60))

                if results.active ~= 0 then
                    options[#options + 1] = {
                        title = 'Pet: '..results.name,
                        description = 'Stabled in '..results.stablepet..'\nOwner: '..results.citizenid.. '\n ID: '..results.dogid..'\ntime of life '..daysPassed,
                        icon = 'fa-solid fa-circle-info',
                    }
                    options[#options + 1] = {
                        title = 'XP: '..results.dogxp,
                        progress = results.dogxp,
                        icon = 'fa-solid fa-expand',
                    }
                    options[#options + 1] = {
                        title = 'Vida: '..results.live,
                        progress = results.live,
                        colorScheme = liveColorScheme,
                        icon = 'fa-solid fa-heart',
                    }
                    options[#options + 1] = {
                        title = 'Felicidad: '..results.happiness,
                        progress = results.happiness,
                        icon = 'fa-solid fa-face-grin-hearts',
                    }
                    options[#options + 1] = {
                        title = 'Crecimiento: '..results.growth,
                        progress = results.growth,
                        colorScheme = 'green',
                        icon = 'fa-solid fa-arrow-up-right-dots',
                    }
                    options[#options + 1] = {
                        title = 'Hambre: '..results.hunger,
                        progress = results.hunger,
                        icon = 'fa-solid fa-drumstick-bite',
                        onSelect = function()
                            TriggerServerEvent('hdrp-companions:server:eatpet', 'feed_dog')
                        end,
                        arrow = true
                    }
                    options[#options + 1] = {
                        title = 'Sed: '..results.thirst,
                        progress = results.thirst,
                        icon = 'fa-solid fa-droplet',
                        onSelect = function()
                            TriggerServerEvent('hdrp-companions:server:eatpet', 'drink_dog')
                        end,
                        arrow = true
                    }
                    options[#options + 1] = {
                        title = 'Suciedad: '..results.dirt,
                        progress = results.dirt,
                        icon = 'fa-solid fa-shower',
                        onSelect = function()
                            TriggerServerEvent('hdrp-companions:server:brushpet', 'horsebrush')
                        end,
                        arrow = true
                    }
                end
            end
            lib.registerContext({
                id = 'show_mypet_menu',
                title = 'Pet info',
                position = 'top-right',
                options = options
            })
            lib.showContext('show_mypet_menu')
        else
            RSGCore.Functions.Notify('no pets', 'error')
        end
    end)
end)

local function DogEatAnimation()
	local waiting = 0
	local dict = "amb_creature_mammal@world_dog_eating_ground@base"
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		waiting = waiting + 100
		Citizen.Wait(100)
		if waiting > 5000 then
			RSGCore.Functions.Notify(Lang:t('info.petaway'), 'error', 3000)
			break
		end
	end
	TaskPlayAnim(dogPed, dict, "base", 1.0, 8.0, -1, 1, 0, false, false, false)
end

local function DogSitAnimation()
	local waiting = 0
	local dict = "amb_creature_mammal@world_dog_sitting@base"
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		waiting = waiting + 100
		Citizen.Wait(100)
		if waiting > 5000 then
			RSGCore.Functions.Notify(Lang:t('error.brokeanim'), 'error', 3000)
			break
		end
	end
	TaskPlayAnim(dogPed, dict, "base", 1.0, 8.0, -1, 1, 0, false, false, false)
end

local function petStay(pet)
	local coords = GetEntityCoords(pet)
	ClearPedTasks(pet)
	ClearPedSecondaryTask(pet)
	DogSitAnimation()
	FreezeEntityPosition(pet, true)
end

--------
-- target pet
--------

local function AttackTarget(targetentity)
	local retval, group = AddRelationshipGroup("attackedPeds") --We need to make a new group so the pet doesn't go haywire on other peds in the default group
	SetPedRelationshipGroupHash(targetentity,group) --Setting the attacked target to be in the new group
	SetRelationshipBetweenGroups(5, GetPedRelationshipGroupHash(dogPed), GetPedRelationshipGroupHash(targetentity))	--Setting the relationship of the pet to target at 5 (hated)
	TaskCombatPed(dogPed, targetentity, 0, 16)
end

local function TrackTarget(targetentity)
	TaskFollowToOffsetOfEntity(dogPed, targetentity, 0.0, -1.5, 0.0, 1.0, -1,  2 * 100000000, 1, 1, 0, 0, 1)
	--TaskCombatPed(dogPed,targetentity,0,16)
end

local function ReturnKillToPlayer(fetchedKill, PlayerPedId)
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetActivePet', function(data)
        if (data) then
			local coords = GetEntityCoords(PlayerPedId)
			TaskGoToCoordAnyMeans(dogPed, coords, 1.5, 0, 0, 786603, 0xbf800000)
			while true do
				Citizen.Wait(2000)
				coords = GetEntityCoords(PlayerPedId)
				local coords2 = GetEntityCoords(dogPed)
				TaskGoToCoordAnyMeans(dogPed, coords, 1.5, 0, 0, 786603, 0xbf800000) --this might have been causing the pet to freeze up by calling it so much

				if GetDistanceBetweenCoords(coords, coords2, true) <= 2.0 then
					DetachEntity(fetchedObj)
					Wait(100)
					PlaceObjectOnGroundProperly(fetchedObj, true)
					Retrieving = false
					followOwner(dogPed, PlayerPedId)
					break
				end
			end
		end
	end)
end

local function RetrieveKill(ClosestPed)
	fetchedObj = ClosestPed
	local ped = PlayerPedId()
	local TaskedToMove = false
	local coords = GetEntityCoords(fetchedObj)
	TaskGoToCoordAnyMeans(dogPed, coords, 2.0, 0, 0, 786603, 0xbf800000)
	Retrieving = true
	print('Retrieve Kill')

	while true do
		Citizen.Wait(2000)
		TaskGoToCoordAnyMeans(dogPed, coords, 2.0, 0, 0, 786603, 0xbf800000)
		local petCoords = GetEntityCoords(dogPed)
		coords = GetEntityCoords(fetchedObj)
		if GetDistanceBetweenCoords(coords, petCoords, true) <= 2.5 then
			--AttachEntityToEntity(fetchedObj, dogPed, GetPedBoneIndex(dogPed, 14285), 0.0, 0.0,0.09798, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
			AttachEntityToEntity(fetchedObj, dogPed, GetPedBoneIndex(dogPed, 21030), 0.14,0.14,0.09798, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
			RetrievedEntities[fetchedObj] = true
			ReturnKillToPlayer(fetchedObj,ped)
			break
		end
	end
end

RegisterNetEvent('hdrp-companions:client:mypetsactions', function(dogPedmenu)
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetAllPets', function(results)
        if results ~= nil then
            local options = {}
            for i = 1, #results do
                local results = results[i]

                if results.active ~= 0 then
                    options[#options + 1] = {
                        title = 'Pet: '..results.name,
                        icon = 'fa-solid fa-circle-info',
                    }
                    options[#options + 1] = {
                        title = 'Follow',
                        icon = 'fa-solid fa-person',
                        onSelect = function()
                            followOwner(dogPedmenu, PlayerPedId())
                        end,
                        arrow = true
                    }
                    options[#options + 1] = {
                        title = 'Stay',
                        icon = 'fa-solid fa-location-dot',
                        onSelect = function()
                            petStay(dogPedmenu)
                        end,
                        arrow = true
                    }
                    -- options[#options + 1] = {
                    --     title = 'Carry',
                    --     icon = 'fa-solid fa-share',
                    --     onSelect = function()
                    --     end,
                    --     arrow = true
                    -- }
                    -- options[#options + 1] = {
                    --     title = 'Take snoulder',
                    --     icon = 'fa-solid fa-share',
                    --     onSelect = function()
                    --     end,
                    --     arrow = true
                    -- }
                    options[#options + 1] = {
                        title = 'Animations',
                        icon = 'fa-solid fa-share',
                        onSelect = function()
                            TriggerEvent('hdrp-companions:client:mypetsanimations', dogPedmenu)
                        end,
                        arrow = true
                    }
                    
                    options[#options + 1] = {
                        title = 'Hunt Mode ON/OFF',
                        icon = 'fa-solid fa-toggle-on',
                        onSelect = function()
                            if not HuntMode then
                                RSGCore.Functions.Notify(Lang:t('info.retrieve'), 'info', 3000)
                                HuntMode = true
                            else
                                HuntMode = false
                                RSGCore.Functions.Notify(Lang:t('error.notretrieve'), 'error', 3000)
                            end
                        end,
                        arrow = true
                    }
                    options[#options + 1] = {
                        title = 'Comercio/Intercambio',
                        icon = 'fa-solid fa-horse',
                        onSelect = function()
                            TriggerEvent('hdrp-companions:client:tradepet')
                        end,
                        arrow = true
                    }
                    options[#options + 1] = {
                        title = 'Flee',
                        icon = 'fa-solid fa-warehouse',
                        onSelect = function()
                            if Config.StoreFleedPet then
                                FleePetStore()
                            else
                                FleePet()
                            end
                        end,
                        arrow = true
                    }
                end
            end
            lib.registerContext({
                id = 'show_mypetactions_menu',
                title = 'Pet info actions',
                -- menu = 'show_mypet_menu',
                -- onBack = function() end,
                position = 'top-right',
                options = options
            })
            lib.showContext('show_mypetactions_menu')
        else
            RSGCore.Functions.Notify('no pets', 'error')
        end
    end)
end)

---------------------------
-- ANIMATIONS MENU
---------------------------
local playanim = false
local petanimdict = nil
local petanimdictname = nil
local petanimname = nil

local function StopAnimation(pet, animdict, animdictname)
	if Config.Debug then print(animdict) print(animdictname) end
	TaskPlayAnim(pet, animdict, animdictname, 1.0, 1.0, -1, 0, 1.0, false, false, false)
	FreezeEntityPosition(pet, false)
end

local function AnimationPet(pet, dict, name)
	local waiting = 0
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		waiting = waiting + 100
		Wait(100)
		if waiting > 5000 then
			RSGCore.Functions.Notify(Lang:t('error.brokeanim'), 'error', 3000)
			break
		end
	end
	TaskPlayAnim(pet, dict, name, 1.0, 1.0, -1, 1, 0, false, false, false)
    playanim = true
end

local function petAnimation(pet, dict, dictname)
	local coords = GetEntityCoords(pet)
	ClearPedTasks(pet)
	ClearPedSecondaryTask(pet)
	AnimationPet(pet, dict, dictname)
	FreezeEntityPosition(pet, true)
end

RegisterNetEvent('hdrp-companions:client:mypetsanimations', function(dogPedmenu)
	local options = {}
    options[#options + 1] = {
        title = 'STOP ANIM',
        -- description = 'Current: ' .. petanimname,
        icon = 'fa-solid fa-pause',
        args = {
        },
        onSelect = function()
        StopAnimation(dogPedmenu, petanimdict, petanimdictname)
            petanimdict = nil
            petanimdictname = nil
            petanimname = nil
        lib.showContext('show_mypetanimation_menu')
        end,
    }
    for k,v in ipairs(Config.Animations) do
        options[#options + 1] = {
            title = v.animname,
            -- description = v.dict,
            icon = 'fa-solid fa-box',
            onSelect = function()
                petAnimation(dogPedmenu, v.dict, v.dictname)
                petanimdict = v.dict
                petanimdictname = v.dictname
                petanimname = v.animname
                lib.showContext('show_mypetanimation_menu')
			end,
            -- arrow = true,
        }
	end
    lib.registerContext({
        id = 'show_mypetanimation_menu',
        title = 'Pet Animations',
        menu = 'show_mypetactions_menu',
        position = 'top-right',
        options = options
    })
    lib.showContext('show_mypetanimation_menu')
end)


--------------------
-- INTERACTIONS ANIMAL 
--------------------
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local id = PlayerId()
        if IsPlayerTargettingAnything(id) then
            local result, entity = GetPlayerTargetEntity(id)
            if PromptHasStandardModeCompleted(MenuPrompt[entity]) then
			    TriggerEvent("hdrp-companions:client:mypets")
				Wait(2000)
            end
            if PromptHasStandardModeCompleted(ActionsPrompt[entity]) then
			    TriggerEvent("hdrp-companions:client:mypetsactions", dogPed)
				Wait(2000)
            end
			if PromptHasStandardModeCompleted(AttackPrompt[entity]) then
				AttackTarget(entity)
			end
			if PromptHasStandardModeCompleted(TrackPrompt[entity]) then
				TrackTarget(entity)
			end
			if Config.AttackCommand and dogPed then
				if not AddedAttackPrompt[entity] and entity ~= dogPed then
					if entity ~= dogPed then
						 if Config.AttackOnly.Animals and GetPedType(entity) == 28 then
							AddAttackPrompts(entity)
							AddedAttackPrompt[entity] = true

						elseif Config.AttackOnly.NPC and not IsPedAPlayer(entity) then
							AddAttackPrompts(entity)
							AddedAttackPrompt[entity] = true

						elseif Config.AttackOnly.Players and IsPedAPlayer(entity) then
							AddAttackPrompts(entity)
							AddedAttackPrompt[entity] = true

						elseif not Config.AttackOnly.Animals and not Config.AttackOnly.NPC and not Config.AttackOnly.Players then
							AddAttackPrompts(entity)
							AddedAttackPrompt[entity] = true

						end
					end
				end
			end
			if Config.TrackCommand and dogPed then
				if not AddedTrackPrompt[entity] and entity ~= dogPed then
					if entity ~= dogPed then
						 if Config.TrackOnly.Animals and GetPedType(entity) == 28 then
							AddTrackPrompts(entity)
							AddedTrackPrompt[entity] = true

						elseif Config.TrackOnly.NPC and not IsPedAPlayer(entity) then
							AddTrackPrompts(entity)
							AddedTrackPrompt[entity] = true

						elseif Config.TrackOnly.Players and IsPedAPlayer(entity) then
							AddTrackPrompts(entity)
							AddedTrackPrompt[entity] = true

						elseif not Config.TrackOnly.Animals and not Config.TrackOnly.NPC and not Config.TrackOnly.Players then
							AddTrackPrompts(entity)
							AddedTrackPrompt[entity] = true
					
						end
					end				
				end
			end
		else
		Wait(500)
        end
    end
end)

-- player feed pet
RegisterNetEvent('hdrp-companions:client:playerfeedpet')
AddEventHandler('hdrp-companions:client:playerfeedpet', function(itemName)
    local pcoords = GetEntityCoords(PlayerPedId())
    local hcoords = GetEntityCoords(dogPed)

    if #(pcoords - hcoords) > 2.0 then
        RSGCore.Functions.Notify('need to be closer', 'error')
        return
    end

    if Config.PetFeed[itemName] ~= nil then
        if Config.PetFeed[itemName]["ismedicine"] ~= nil then
            if Config.PetFeed[itemName]["ismedicine"] == true then
                -- is medicine
                Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), dogPed, -1355254781, 0, 0) -- TaskAnimalInteraction

                Wait(5000)

                local medicineHash = "consumable_pet_stimulant"
                if Config.PetFeed[itemName]["medicineHash"] ~= nil then medicineHash = Config.PetFeed[itemName]["medicineHash"] end
                -- TaskAnimalInteraction(PlayerPedId(), dogPed, -1355254781, GetHashKey(medicineHash), 0)

                local valueHealth = Citizen.InvokeNative(0x36731AC041289BB1, dogPed, 0)

                if not tonumber(valueHealth) then valueHealth = 0 end
                Citizen.Wait(3500)
                Citizen.InvokeNative(0xC6258F41D86676E0, dogPed, 0, valueHealth + Config.PetFeed[itemName]["health"])


                Citizen.InvokeNative(0xF6A7C08DF2E28B28, dogPed, 0, 1000.0)
                Citizen.InvokeNative(0xF6A7C08DF2E28B28, dogPed, 1, 1000.0)

                Citizen.InvokeNative(0x50C803A4CD5932C5, true) --core
                Citizen.InvokeNative(0xD4EE21B7CC7FD350, true) --core

                PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
            elseif Config.PetFeed[itemName]["ismedicine"] == false then
                -- is not medicine
                -- Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), dogPed, -224471938, 0, 0) -- TaskAnimalInteraction
                TaskTurnPedToFaceEntity(PlayerPedId(), dogPed, 5000)
                TaskTurnPedToFaceEntity(dogPed, PlayerPedId(), 5000)
                TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), 60000, true, false, false, false)
                Wait(2000)
                DogEatAnimation()
                Wait(4000)
                ClearPedTasks(PlayerPedId())
                Wait(4000)
                ClearPedTasks(dogPed)
                followOwner(dogPed, PlayerPedId(), false)

                local petHealth = Citizen.InvokeNative(0x36731AC041289BB1, dogPed, 0)  -- GetAttributeCoreValue (Health)
                local newHealth = petHealth + Config.PetFeed[itemName]["health"]

                Citizen.InvokeNative(0xC6258F41D86676E0, dogPed, 0, newHealth)  -- SetAttributeCoreValue (Health)

                PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
            else
                -- have invalid config
                RSGCore.Functions.Notify("[FEED] Feed: " .. itemName .. " have INVALID ismedicine config!", 'error')
            end
        else
            RSGCore.Functions.Notify("[FEED] Feed: " .. itemName .. " do not have ismedicine config!", 'error')
        end
    else
        RSGCore.Functions.Notify("[FEED] Feed: " .. itemName .. " do not exits!", 'error')
    end
end)

-- player brush pet
RegisterNetEvent('hdrp-companions:client:playerbrushpet')
AddEventHandler('hdrp-companions:client:playerbrushpet', function(itemName)
    local pcoords = GetEntityCoords(PlayerPedId())
    local hcoords = GetEntityCoords(dogPed)

    if #(pcoords - hcoords) > 2.0 then
        RSGCore.Functions.Notify('need_to_be_closer', 'error')
        return
    end

    local boneIndex = GetEntityBoneIndexByName(PlayerPedId(), "SKEL_R_Finger00")
    local brushitem = CreateObject(`p_brushHorse02x`, pcoords.x, pcoords.y, pcoords.z, true, true, true)
    AttachEntityToEntity(brushitem, PlayerPedId(), boneIndex, 0.06, -0.08, -0.03, -30.0, 0.0, 60.0, true, false, true, false, 0, true)

    Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), dogPed, `INTERACTION_DOG_PATTING`, 0, 0)

    Wait(6000)

    Citizen.InvokeNative(0xE3144B932DFDFF65, dogPed, 0.0, -1, 1, 1)
    ClearPedEnvDirt(dogPed)
    ClearPedDamageDecalByZone(dogPed, 10, "ALL")
    ClearPedBloodDamage(dogPed)
    Citizen.InvokeNative(0xD8544F6260F5F01E, dogPed, 10)
    SetEntityAsNoLongerNeeded(brushitem)
    DeleteEntity(brushitem)
    PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
end)

----------------------------

----------------------------

local function GetClosestAnimalPed(playerPed, radius)
	local playerCoords = GetEntityCoords(playerPed)
	local itemset = CreateItemset(true)
	local size = Citizen.InvokeNative(0x59B57C4B06531E1E, playerCoords, radius, itemset, 1, Citizen.ResultAsInteger())
	local closestPed
	local minDist = radius

	if size > 0 then
		for i = 0, size - 1 do
			local ped = GetIndexedItemInItemset(i, itemset)
			if playerPed ~= ped then
				local pedType = GetPedType(ped)
				local model = GetEntityModel(ped)
				if pedType == 28 and IsEntityDead(ped) and not RetrievedEntities[ped] and Config.Animals[model] then
					local pedCoords = GetEntityCoords(ped)
					local distance = #(playerCoords - pedCoords)
					if distance < minDist then
						closestPed = ped
						minDist = distance
					end
				end
			end
		end
	end

	if IsItemsetValid(itemset) then
		DestroyItemset(itemset)
	end

	return closestPed
end

local function GetClosestFightingPed(playerPed, radius)
	local playerCoords = GetEntityCoords(playerPed)
	local itemset = CreateItemset(true)
	local size = Citizen.InvokeNative(0x59B57C4B06531E1E, playerCoords, radius, itemset, 1, Citizen.ResultAsInteger())
	local closestPed
	local minDist = radius

	if size > 0 then
		for i = 0, size - 1 do
			local ped = GetIndexedItemInItemset(i, itemset)
			if playerPed ~= ped and playerPed ~= dogPed then
				local pedType = GetPedType(ped)
				local model = GetEntityModel(ped)
				local pedCoords = GetEntityCoords(ped)
				local distance = #(playerCoords - pedCoords)
				if IsPedInCombat(playerPed, ped) then
					closestPed = ped
					minDist = distance
				end
			end
		end
	end

	if IsItemsetValid(itemset) then
		DestroyItemset(itemset)
	end

	return closestPed
end

--------------------------------------
-- Main Thread - Checks if animal can hunt or is hungry, checks timers, etc.
--------------------------------------
-- Citizen.CreateThread(function()
-- 	while true do
-- 		Citizen.Wait(1000)
-- 		if not Config.RaiseAnimal then
-- 			if dogPed and not Retrieving and not isPetHungry and HuntMode then --Checking to see if your pet is active, not retriving and not hungry
-- 				local ped = PlayerPedId()
-- 				local ClosestPed = GetClosestAnimalPed(ped,Config.SearchRadius)
-- 				local pedType = GetPedType(ClosestPed)		  			
-- 				if pedType == 28 and IsEntityDead(ClosestPed) and not RetrievedEntities[ClosestPed] then
-- 				   local whoKilledPed = GetPedSourceOfDeath(ClosestPed)
-- 					if ped == whoKilledPed then -- Make sure the dead animal was killed by player or else it will try to steal other players hunts
-- 					local model = GetEntityModel(ClosestPed)
-- 					  for k,v in pairs(Config.Animals) do
-- 						  if model == k then
-- 						  RetrieveKill(ClosestPed)
-- 						  end
-- 					  end
-- 					else
-- 						RetrievedEntities[ClosestPed] = true --Even though it wasn't retrieved, I do this so it stops trying to check if it should retrieve this ped
-- 					end
-- 				 end
-- 			end
-- 		else
-- 			if dogPed and not Retrieving and dogXP >= Config.FullGrownXp and not isPetHungry and HuntMode then --Checking to see if your pet is active, not retriving and not hungry
-- 				local ped = PlayerPedId()
-- 				local ClosestPed = GetClosestAnimalPed(ped,Config.SearchRadius)
-- 				local pedType = GetPedType(ClosestPed)		  			
-- 				if pedType == 28 and IsEntityDead(ClosestPed) and not RetrievedEntities[ClosestPed] then
-- 				   local whoKilledPed = GetPedSourceOfDeath(ClosestPed)
-- 					if ped == whoKilledPed then -- Make sure the dead animal was killed by player or else it will try to steal other players hunts
-- 					local model = GetEntityModel(ClosestPed)
-- 					  for k,v in pairs(Config.Animals) do
-- 						  if model == k then
-- 						  RetrieveKill(ClosestPed)
-- 						  end
-- 					  end
-- 					else
-- 						RetrievedEntities[ClosestPed] = true --Even though it wasn't retrieved, I do this so it stops trying to check if it should retrieve this ped
-- 					end
-- 				 end
-- 			end
-- 		end
-- 		if dogPed then
-- 			if Config.DefensiveMode and recentlyCombat <= 0 then
-- 				local ped = PlayerPedId()
-- 				local enemyPed = GetClosestFightingPed(ped, 50.0)
-- 				if enemyPed then
-- 					ClearPedTasks(dogPed)
-- 					TaskCombatPed(dogPed,enemyPed,0,16)
-- 					recentlyCombat = 15
-- 				end
-- 			end
-- 			FeedTimer = FeedTimer + 1
-- 			if Config.FeedInterval <= FeedTimer then
-- 			 isPetHungry = true
-- 				if not AddedFeedPrompts then --Constantly re-adding the prompts breaks them, so I added this to only do it once. not AddedFeedPrompts
-- 					local itemSet = CreateItemset(true)
-- 					local size = Citizen.InvokeNative(0x59B57C4B06531E1E, GetEntityCoords(PlayerPedId()), 3.0, itemSet, 1, Citizen.ResultAsInteger())
-- 					if size > 0 then
-- 						for index = 0, size - 1 do
-- 							local entity = GetIndexedItemInItemset(index, itemSet)
-- 								if entity == dogPed then -- If pet is your pet
-- 									AddFeedPrompts(entity)
-- 									AddedFeedPrompts = true
-- 								end
-- 						end
-- 					end			
-- 					if IsItemsetValid(itemSet) then
-- 					   DestroyItemset(itemSet)
-- 					end
-- 				end
-- 				if not notifyHungry and Config.NotifyWhenHungry then
-- 					RSGCore.Functions.Notify(Lang:t('info.hungry'), 'info', 3000)
-- 					notifyHungry = true
-- 				end
-- 			end

-- 			if dogPed and IsEntityDead(dogPed) then
-- 				recentlySpawned = Config.PetAttributes.DeathCooldown
-- 				RSGCore.Functions.Notify(Lang:t('error.petdead'), 'error', 3000)
-- 				Wait(3000)
-- 				DeleteEntity(dogPed)
-- 				dogPed = nil
-- 			end
-- 		end
-- 		if recentlySpawned > 0 then
-- 			recentlySpawned = recentlySpawned - 1
-- 		end
-- 		if recentlyCombat > 0 then
-- 			recentlyCombat = recentlyCombat - 1
-- 		end
-- 	end
-- end)

------------------
-- spawnPet compare old code
------------------
-- function spawnAnimal(model, player, x, y, z, h, skin, PlayerPedId, isdead, isshop, xp)
-- 	local EntityPedCoord = GetEntityCoords( player )
-- 	local EntitydogCoord = GetEntityCoords( dogPed )

-- 	if #( EntityPedCoord - EntitydogCoord ) > 100.0 or isshop or isdead then

-- 		if dogPed ~= nil then
-- 			DeleteEntity(dogPed)
-- 		end

-- 		dogXP = xp
-- 		dogPed = CreatePed(model, x, y, z, h, 1, 1 )
-- 		SET_PED_OUTFIT_PRESET( dogPed, skin )
-- 		-- SET_BLIP_TYPE( dogPed )

-- 		if Config.PetAttributes.Invincible then
-- 			SetEntityInvincible(dogPed, true)
-- 		end

-- 		AddFollowPrompts(dogPed)

-- 		if Config.NoFear then
-- 			Citizen.InvokeNative(0x013A7BA5015C1372, dogPed, true)
-- 			Citizen.InvokeNative(0x3B005FF0538ED2A9, dogPed)
-- 			Citizen.InvokeNative(0xAEB97D84CDF3C00B, dogPed, false)
-- 		end

-- 		SetPetAttributes(dogPed)
-- 		setPetBehavior(dogPed)
-- 		SetPedAsGroupMember(dogPed, GetPedGroupIndex(PlayerPedId))

-- 		if Config.RaiseAnimal then
-- 			local halfGrowth = Config.FullGrownXp / 2
-- 			if dogXP >= Config.FullGrownXp then
-- 				SetPedScale(dogPed, 1.0) --Use this for the XP system with pets
-- 				AddStayPrompts(dogPed)
-- 				AddHuntModePrompts(dogPed)
-- 			elseif dogXP >= halfGrowth then
-- 				SetPedScale(dogPed, 0.8)
-- 				AddStayPrompts(dogPed)
-- 			else
-- 				SetPedScale(dogPed, 0.6)
-- 			end
-- 		else
-- 			dogXP = Config.FullGrownXp
-- 			AddStayPrompts(dogPed)
-- 		end

-- 		while (GetScriptTaskStatus(dogPed, 0x4924437d) ~= 8) do
-- 			Wait(1000)
-- 		end

-- 		followOwner(dogPed, player)

-- 		if isdead and Config.PetAttributes.Invincible == false then
-- 			RSGCore.Functions.Notify(Lang:t('success.pethealed'), 'success', 3000)
-- 		end
-- 	end
-- end

-- RegisterNetEvent('hdrp-companions:client:spawndog')
-- AddEventHandler('hdrp-companions:client:spawndog', function (dog, skin, isInShop, xp, canTrack)
-- 	if dogPed then
-- 		RSGCore.Functions.Notify(Lang:t('info.petalreadyhere'), 'info', 3000)
-- 	else
-- 		if recentlySpawned <= 0 then
-- 			recentlySpawned = Config.PetAttributes.SpawnLimiter
-- 			RSGCore.Functions.Notify(Lang:t('info.dogSpawned'), 'info', 3000)
-- 		else
-- 			RSGCore.Functions.Notify(Lang:t('info.petspawning', {recentlySpawned = recentlySpawned}), 'info', 3000)
-- 			return
-- 		end

-- 		isPetHungry = false
-- 		FeedTimer = 0
-- 		notifyHungry = false
-- 		AddedFeedPrompts = false
-- 		TrackingEnabled = canTrack

-- 		local player = PlayerPedId()
-- 		local model = GetHashKey( dog )
-- 		local x, y, z, heading, a, b

-- 		if not isInShop then
-- 			x, y, z = table.unpack( GetOffsetFromEntityInWorldCoords( player, 0.0, -5.0, 0.3 ) )
-- 			a, b = GetGroundZAndNormalFor_3dCoord( x, y, z + 10 )
-- 		end

-- 		RequestModel( model )

-- 		while not HasModelLoaded( model ) do
-- 			Wait(500)
-- 		end

-- 		local EntityIsDead = false
-- 		if (dogPed ~= nil) then
-- 			EntityIsDead = IsEntityDead( dogPed )
-- 		end

-- 		if EntityIsDead then
-- 			spawnAnimal(model, player, x, y, b, heading, skin, PlayerPedId(), true, false, xp)
-- 		else
-- 			spawnAnimal(model, player, x, y, b, heading, skin, PlayerPedId(), false, false, xp)
-- 		end
-- 	end
-- end)

--------------------------------------
-- UPDATE PET FED / CRECIMIENTO DE PET DEPENDE DE LA XP PARA CONSEGUIR MAS FUNCIONES
--------------------------------------
-- RegisterNetEvent('hdrp-companions:client:UpdateDogFed')
-- AddEventHandler('hdrp-companions:client:UpdateDogFed', function (newXP, growAnimal)
--     RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetActivePet', function(data)
-- 		if (data) then
-- 			if Config.RaiseAnimal and growAnimal then
-- 				dogXP = newXP

-- 				local halfGrowth = Config.FullGrownXp / 2
-- 				if dogXP >= Config.FullGrownXp then
-- 					SetPedScale(dogPed, 1.0)
-- 					-- AddStayPrompts(dogPed)
-- 					-- AddHuntModePrompts(dogPed)
-- 					--Use this for the XP system with pets
-- 				elseif dogXP >= halfGrowth then
-- 					SetPedScale(dogPed, 0.8)
-- 					-- AddStayPrompts(dogPed)
-- 				else
-- 					SetPedScale(dogPed, 0.6)
-- 				end
-- 			end

-- 			isPetHungry = false
-- 			FeedTimer = 0
-- 			notifyHungry = false
-- 		end
-- 	end)
-- end)

--------------------------------------
-- function
--------------------------------------

-- function SecondsToClock(seconds)
-- 	local seconds = tonumber(seconds)
-- 	if seconds <= 0 then
-- 		return "00:00:00";
-- 	else
-- 		hours = string.format("%02.f", math.floor(seconds/3600));
-- 		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
-- 		secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
-- 		return hours..":"..mins..":"..secs
-- 	end
-- end

function SET_ANIMAL_TUNING_BOOL_PARAM (animal, p1, p2)
	return Citizen.InvokeNative(0x9FF1E042FA597187, animal, p1, p2)
end

function SET_PED_DEFAULT_OUTFIT (dog)
	return Citizen.InvokeNative(0x283978A15512B2FE, dog, true)
end

function SET_PED_OUTFIT_PRESET (dog, preset)
	return Citizen.InvokeNative(0x77FF8D35EEC6BBC4, dog, preset, 0)
end

------------- tbrp
local keys = Config.Keys
local pressTime = 0
local pressLeft = 0
local recentlySpawned = 0
local currentPetPed = nil;
local CurrentZoneActive = 0
local petXP = 0
local pets = Config.Pets
local fetchedObj = nil
local Retrieving = false
local Retrieved = true
local notifyHungry = false
local RetrievedEntities = {}
local FeedTimer = 0
local recentlyCombat = 0
local isPetHungry = false
local TrackingEnabled = false
local AddedFeedPrompts = false
local HuntMode = false