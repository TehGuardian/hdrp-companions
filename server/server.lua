local RSGCore = exports['rsg-core']:GetCoreObject()
--------------------
-- send To Discord
-------------------

local function sendToDiscord(color, name, message, footer, type)
    local embed = {
        {   ["color"] = color,
            ["title"] = "**".. name .."**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = footer
            }
        }
    }
    if type == "wildpet" then
        PerformHttpRequest(Config['Webhooks']['wildpet'], function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
    elseif type == "petinfo" then
        PerformHttpRequest(Config['Webhooks']['petinfo'], function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
    elseif type == "trader" then
        PerformHttpRequest(Config['Webhooks']['trader'], function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
end

----------------
-- ITEMS
----------------
-- feed pet feed
RSGCore.Functions.CreateUseableItem('feed_dog', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("tbrp_companions:client:playerfeedpet", source, item.name)
    end
end)

 -- feed Stimulant dog 
RSGCore.Functions.CreateUseableItem("stimulant_dog", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("tbrp_companions:client:playerfeedpet", source, item.name)
    end
end)

-- pet reviver
RSGCore.Functions.CreateUseableItem("petreviver", function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then return end

    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid=@citizenid AND active=@active',
    {
        ['@citizenid'] = cid,
        ['@active'] = 1
    })

    if not result[1] then
        RSGCore.Functions.Notify(src, 'no_active_pet', 'error', 3000)

        return
    end

    TriggerClientEvent("tbrp_companions:client:revivepet", src, item, result[1])
end)

----------------
-- find pet command
----------------
RSGCore.Commands.Add("findpet", "find where your pets are stored", {}, false, function(source)
    local src = source
    TriggerClientEvent('tbrp_companions:client:getpetlocation', src)
end)

RSGCore.Functions.CreateCallback('tbrp_companions:server:GetAllPets', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local pets = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid=@citizenid', { ['@citizenid'] = Player.PlayerData.citizenid })
    if pets[1] ~= nil then
        cb(pets)
    else
        cb(nil)
    end
end)

RegisterServerEvent('tbrp_companions:server:revivepet', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[item.name], "remove")
    end
end)

------------------------
-- BUY PETS WITH CLIENT/PETS.LUA
------------------------
RegisterServerEvent('tbrp_companions:server:BuyPet', function(price, model, stablepet, dogname, gender)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if (Player.PlayerData.money.cash < price) then
        TriggerClientEvent('RSGCore:Notify', src, 'error.no_cash', 'error')
        return
    end
    local dogid = GeneratePetid()
	local skin = math.floor(math.random(0, 2))
	local canTrack = CanTrack(src)
    MySQL.insert('INSERT INTO tbrp_companions(stablepet, citizenid, dogid, name, dog, skin, gender, active, born) VALUES(@stablepet, @citizenid, @dogid, @name, @dog, @skin, @gender, @active, @born)', {
        ['@stablepet'] = stablepet,
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@dogid'] = dogid,
        ['@name'] = dogname,
        ['@dog'] = model,
        ['@skin'] = skin,
        ['@gender'] = gender,
        ['@active'] = false,
        ['@born'] = os.time()
    })
    Player.Functions.RemoveMoney('cash', price)
    TriggerClientEvent('RSGCore:Notify', src, 'success.pet_owned' , 'success')
end)

------------------------
-- BUY PETS WITH CLIENT/client.LUA
------------------------
RegisterNetEvent("tbrp_companions:server:TradePet", function(playerId, petId, source)
    local src = source
    local Player2 = RSGCore.Functions.GetPlayer(playerId)
    local Playercid2 = Player2.PlayerData.citizenid
    MySQL.update('UPDATE tbrp_companions SET citizenid = ? WHERE dogid = ? AND active = ?', {Playercid2, petId, 1})
    MySQL.update('UPDATE tbrp_companions SET active = ? WHERE citizenid = ? AND active = ?', {0, Playercid2, 1})
    TriggerClientEvent('RSGCore:Notify', playerId, 'pet owned', 'success')
end)

-- generate dogid
function GeneratePetid()
    local UniqueFound = false
    local dogid = nil
    while not UniqueFound do
        dogid = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM tbrp_companions WHERE dogid = ?", { dogid })
        if result == 0 then
            UniqueFound = true
        end
    end
    return dogid
end

RegisterServerEvent('tbrp_companions:server:SetPetsActive', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activedog = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    MySQL.update('UPDATE tbrp_companions SET active = ? WHERE id = ? AND citizenid = ?', { false, activedog, Player.PlayerData.citizenid })
    MySQL.update('UPDATE tbrp_companions SET active = ? WHERE id = ? AND citizenid = ?', { true, id, Player.PlayerData.citizenid })
end)

RegisterServerEvent('tbrp_companions:server:SetPetsUnActive', function(id, stablepetid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activedog = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, false})
    MySQL.update('UPDATE tbrp_companions SET active = ? WHERE id = ? AND citizenid = ?', { false, activedog, Player.PlayerData.citizenid })
    MySQL.update('UPDATE tbrp_companions SET active = ? WHERE id = ? AND citizenid = ?', { false, id, Player.PlayerData.citizenid })
    MySQL.update('UPDATE tbrp_companions SET stablepet = ? WHERE id = ? AND citizenid = ?', { stablepetid, id, Player.PlayerData.citizenid })
end)

-- store pet when flee is used
RegisterServerEvent('tbrp_companions:server:fleeStorePet', function(stablepetid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activedog = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, 1})
    MySQL.update('UPDATE tbrp_companions SET active = ? WHERE id = ? AND citizenid = ?', { 0, activedog, Player.PlayerData.citizenid })
    MySQL.update('UPDATE tbrp_companions SET stablepet = ? WHERE id = ? AND citizenid = ?', { stablepetid, activedog, Player.PlayerData.citizenid })
end)

RegisterServerEvent('tbrp_companions:renamePet', function(name)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local newName = MySQL.query.await('UPDATE tbrp_companions SET name = ? WHERE citizenid = ? AND active = ?' , {name, Player.PlayerData.citizenid, 1})

    if newName == nil then
        TriggerClientEvent('RSGCore:Notify', src, 'error.name_change_failed', 'error')
        return
    end

    TriggerClientEvent('RSGCore:Notify', src, 'Pet name changed to \''..name..'\' successfully!', 'success')
end)

--------------------------------------
-- SELL PET
--------------------------------------
RegisterServerEvent('tbrp_companions:server:deletepet', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local modelPet = nil
    local dogid = data.dogid
    local player_pets = MySQL.query.await('SELECT * FROM tbrp_companions WHERE id = @id AND `citizenid` = @citizenid', {
        ['@id'] = dogid,
        ['@citizenid'] = Player.PlayerData.citizenid
    })
    for i = 1, #player_pets do
        if tonumber(player_pets[i].id) == tonumber(dogid) then
            modelPet = player_pets[i].dog
            MySQL.update('DELETE FROM tbrp_companions WHERE id = ? AND citizenid = ?', { data.dogid, Player.PlayerData.citizenid })
        end
    end
    for k, v in pairs(Config.BoxZones) do
        for j, n in pairs(v) do
            if n.model == modelPet then
                local sellprice = n.price * 0.5
                Player.Functions.AddMoney('cash', sellprice)
                TriggerClientEvent('RSGCore:Notify', src, 'pet sold for'..sellprice, 'success')
            end
        end
    end
end)

RSGCore.Functions.CreateCallback('tbrp_companions:server:GetPet', function(source, cb, stablepet)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local GetPet = {}
    local pets = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid=@citizenid AND stablepet=@stablepet', { ['@citizenid'] = Player.PlayerData.citizenid, ['@stablepet'] = stablepet })
    if pets[1] ~= nil then
        cb(pets)
    else
        cb(nil)
    end
end)

RSGCore.Functions.CreateCallback('tbrp_companions:server:GetActivePet', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid=@citizenid AND active=@active', { ['@citizenid'] = cid, ['@active'] = 1 })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        return
    end
end)

-- Check if Player has petbrush before brush the pet
RegisterServerEvent('tbrp_companions:server:brushpet', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.GetItemByName(item) then
        TriggerClientEvent("tbrp_companions:client:playerbrushpet", source, item)
    else
        TriggerClientEvent('RSGCore:Notify', src, "You don't have "..item, 'error')
    end
end)

RegisterServerEvent('tbrp_companions:server:setpetAttributes', function(dirt)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    MySQL.update('UPDATE tbrp_companions SET dirt = ? WHERE id = ? AND citizenid = ?', { dirt, activepet, Player.PlayerData.citizenid })
end)

--------------------------------------
-- FEED PET EVENT WITH XP PROGRESSION
--------------------------------------
RegisterServerEvent('tbrp_companions:server:feedPet')
AddEventHandler('tbrp_companions:server:feedPet', function(xp)
    local src = source
	local Player = RSGCore.Functions.GetPlayer(src)
	local citizenid = Player.PlayerData.citizenid
	local id = Player.PlayerData.id
	local Parameters = {
		['id'] = id,
		['citizenid'] = citizenid
	}
	local currentXP = xp
	local newXp = currentXP + Config.XpPerFeed
	local amount = Player.Functions.GetItemByName(Config.AnimalFood)
	if not amount then
		TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.nofood'), 'error')
	else
		if newXp <= Config.FullGrownXp then
			Player.Functions.RemoveItem(Config.AnimalFood, 1)
			TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.AnimalFood], "add")

			local Parameters = {
				['citizenid'] = citizenid,
				['id'] = id,
				['addedXp'] = Config.XpPerFeed
			}
			MySQL.Sync.execute("UPDATE tbrp_companions SET dogxp = dogxp + @addedXp  WHERE citizenid = @citizenid AND id = @id", Parameters, function(result) end)
			local result = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid = @citizenid AND id = @id', {
				['citizenid'] = citizenid,
				['id'] = id
			})
			for i = 1, #result do
				local xpprogress = json.decode(result[i].xp)
						TriggerClientEvent('RSGCore:Notify', src, Lang:t('info.petprogress', {cpf = Config.XpPerFeed, xpp = xpprogress, cfg = Config.FullGrownXp}), 'info', 6000)
			end
			TriggerClientEvent('tbrp_companions:client:UpdateDogFed', src, newXp)
		else
			Player.Functions.RemoveItem(Config.AnimalFood, 1)
			TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.AnimalFood], "remove")
			TriggerClientEvent('tbrp_companions:client:UpdateDogFed', src, newXp)
		end
	end
end)

--------------------------------------
-- LOAD PET EVENT
--------------------------------------

-- RegisterServerEvent('tbrp_companions:server:loaddog')
-- AddEventHandler('tbrp_companions:server:loaddog', function(source)
--     local src = source
-- 	local Player = RSGCore.Functions.GetPlayer(src)
-- 	local citizenid = Player.PlayerData.citizenid
-- 	local id = Player.PlayerData.id
-- 	local canTrack = CanTrack(src)
-- 	local Parameters = {
-- 		['citizenid'] = citizenid,
-- 		['id'] = id
-- 	}
-- 	MySQL.Async.fetchAll( "SELECT * FROM tbrp_companions WHERE citizenid = @citizenid AND id = @id", Parameters, function(result)
-- 		if result[1] then
-- 			local dog = result[1].dog
-- 			local skin = result[1].skin
-- 			local xp = result[1].xp or 0
-- 			TriggerClientEvent("tbrp_companions:client:spawndog", src, dog, skin, false, xp, canTrack)
-- 		else
-- 			TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.nopet'), 'error')
-- 		end
-- 	end)
-- end)

--------------------------------------------------------------------------------------------------
-- pet check system
--------------------------------------------------------------------------------------------------
UpkeepIntervalPet = function()

    local result = MySQL.query.await('SELECT * FROM tbrp_companions')

    if not result then goto continue end

    for i = 1, #result do
        local id = result[i].id
        local petname = result[i].name
        local ownercid = result[i].citizenid
        local currentTime = os.time()
        local timeDifference = currentTime - result[i].born
        local daysPassed = math.floor(timeDifference / (24 * 60 * 60))

        if Config.Debug then
            print(id, petname, ownercid, daysPassed)
        end

        if daysPassed == Config.PetDieAge then

            -- delete pet
            MySQL.update('DELETE FROM tbrp_companions WHERE id = ?', {id})
            TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', 'Pet Died', 'red', petname..' belonging to '..ownercid..' died of old age!')

            -- telegram message to the pet owner
            MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
            {   ownercid,
                'Pet Owner',
                '22222222',
                'Pet Stables',
                petname..' passed away',
                os.date("%x"),
                'I am sorry to inform you that your pet '..petname..' has passed away, please visit your friendly pet trainer to discuss a replacement!',
            })

            goto continue
        end

    end

    ::continue::

    if Config.EnableServerNotify then
        print('pet check cycle complete')
    end

    SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepIntervalPet)
end

SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepIntervalPet)

--------------------------------------
-- TRACK EVENT
--------------------------------------

function CanTrack(source)
	local src = source
	local cb = false
	if Config.TrackCommand then
		if Config.AnimalTrackingJobOnly then
			local job = getJob(src)
			for k, v in pairs(Config.AnimalTrackingJobs) do
				if job == v then
				cb = true
				end
			end
		else
			cb = true
		end
	end
	return(cb)
end

function getJob(source)
	local src = source
 	local cb = false
	local Character = RSGCore.Functions.GetPlayerData(src).job
	cb = Player.PlayerData.job
 	return cb
end
