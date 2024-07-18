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

RSGCore.Functions.CreateUseableItem('drink_dog', function(source, item)
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
    local result = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid = ? AND active = ?', { cid, 1 })

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

RSGCore.Commands.Add("mypets", "Your pets are stored", {}, false, function(source)
    local src = source
    TriggerClientEvent('tbrp_companions:client:mypets', src)
end)

RSGCore.Functions.CreateCallback('tbrp_companions:server:GetAllPets', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local pets = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid= ?', { Player.PlayerData.citizenid })
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
    local live = Config.StartingHeart
    local hunger = Config.StartingHunger
    local thirst = Config.StartingThirst
    local happiness = Config.StartingHappines
	local canTrack = CanTrack(src)

    MySQL.insert('INSERT INTO tbrp_companions(stablepet, citizenid, dogid, name, dog, skin, gender, active, born, live, hunger, thirst, happiness) VALUES(@stablepet, @citizenid, @dogid, @name, @dog, @skin, @gender, @active, @born, @live, @hunger, @thirst, @happiness)', {
        ['@stablepet'] = stablepet,
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@dogid'] = dogid,
        ['@name'] = dogname,
        ['@dog'] = model,
        ['@skin'] = skin,
        ['@gender'] = gender,
        ['@active'] = false,
        ['@born'] = os.time(),
        ['@live'] = live,
        ['@hunger'] = hunger,
        ['@thirst'] = thirst,
        ['@happiness'] = happiness,
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
    local petid = data.dogid
    local player_pets = MySQL.query.await('SELECT * FROM tbrp_companions WHERE id = ? AND `citizenid` = ?', { petid, Player.PlayerData.citizenid })
    for i = 1, #player_pets do
        if tonumber(player_pets[i].id) == tonumber(petid) then
            modelPet = player_pets[i].dog
            MySQL.update('DELETE FROM tbrp_companions WHERE id = ? AND citizenid = ?', { data.dogid, Player.PlayerData.citizenid })
        end
    end
    for k, v in pairs(Config.PetBuySpawn) do
        if v.petmodel == modelPet then
            local sellprice = v.petprice * 0.5
            Player.Functions.AddMoney('cash', sellprice)
            TriggerClientEvent('RSGCore:Notify', src, 'pet sold for'..sellprice, 'success')
        end
    end
end)

RSGCore.Functions.CreateCallback('tbrp_companions:server:GetPet', function(source, cb, stablepet)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local GetPet = {}
    local pets = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid = ? AND stablepet = ?', { Player.PlayerData.citizenid, stablepet })
    if pets[1] ~= nil then
        cb(pets)
    else
        cb(nil)
    end
end)

RSGCore.Functions.CreateCallback('tbrp_companions:server:GetPetB', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local GetPet = {}
    local pets = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid = ?', { Player.PlayerData.citizenid })
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
    local result = MySQL.query.await('SELECT * FROM tbrp_companions WHERE citizenid= ? AND active= ?', { cid, 1 })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        return
    end
end)

-- Check if Player has petbrush before brush the pet
RegisterServerEvent('tbrp_companions:server:brushpet', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local happinesspet = MySQL.scalar.await('SELECT happiness FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local xppet = MySQL.scalar.await('SELECT dogxp FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})

    if Player.Functions.GetItemByName(item) then
        TriggerClientEvent("tbrp_companions:client:playerbrushpet", src, item)
        local dirt = 0.0
        MySQL.update('UPDATE tbrp_companions SET dirt = ?, happiness = ?, dogxp = ? WHERE id = ? AND citizenid = ?', { dirt, happinesspet + Config.QualityDegrade, xppet + Config.XpPerClean, activepet, Player.PlayerData.citizenid })
        -- TriggerClientEvent('tbrp_companions:client:UpdateDogFed', src, xppet + Config.XpPerClean)
    else
        TriggerClientEvent('RSGCore:Notify', src, "You don't have "..item, 'error')
    end
end)

RegisterServerEvent('tbrp_companions:server:eatpet', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local hungerpet = MySQL.scalar.await('SELECT hunger FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local thirstpet = MySQL.scalar.await('SELECT thirst FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local dirtpet = MySQL.scalar.await('SELECT dirt FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local happinesspet = MySQL.scalar.await('SELECT happiness FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local xppet = MySQL.scalar.await('SELECT dogxp FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})

    if Player.Functions.GetItemByName(item) then
        Player.Functions.RemoveItem(item, 1, item.slot)
        TriggerClientEvent("tbrp_companions:client:playerfeedpet", src, item)
        if item == Config.AnimalDrink then
			Player.Functions.RemoveItem(Config.AnimalDrink, 1)
			TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.AnimalDrink], "remove")

            if thirstpet >= 100 then
                thirstpet = 100
                MySQL.update("UPDATE tbrp_companions SET thirst = ?, dirt = ?, dogxp = ? WHERE id = ? AND citizenid = ?", { thirstpet, dirtpet + Config.Degrade, xppet, activepet, Player.PlayerData.citizenid})
            else
                MySQL.update("UPDATE tbrp_companions SET thirst = ?, dirt = ?, dogxp = ? WHERE id = ? AND citizenid = ?", { thirstpet + Config.ThirstIncrease, dirtpet + Config.Degrade, xppet + Config.XpPerDrink, activepet, Player.PlayerData.citizenid})
            end
        elseif item == Config.AnimalFood then
			Player.Functions.RemoveItem(Config.AnimalFood, 1)
			TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.AnimalFood], "remove")

            if hungerpet >= 100 then
                hungerpet = 100
                MySQL.update("UPDATE tbrp_companions SET hunger = ?, dirt = ?, happiness = ?, dogxp = ? WHERE id = ? AND citizenid = ?", { hungerpet, dirtpet + Config.Degrade, happinesspet + Config.QualityDegrade, xppet, activepet, Player.PlayerData.citizenid})
            else
                MySQL.update("UPDATE tbrp_companions SET hunger = ?, dirt = ?, happiness = ?, dogxp = ? WHERE id = ? AND citizenid = ?", { hungerpet + Config.HungerIncrease, dirtpet + Config.Degrade, happinesspet + Config.QualityDegrade, xppet + Config.XpPerFeed, activepet, Player.PlayerData.citizenid})
            end
        end
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

RegisterServerEvent('tbrp_companions:server:setpetAttributesGrowth', function(growth)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    MySQL.update('UPDATE tbrp_companions SET growth = ? WHERE id = ? AND citizenid = ?', { growth, activepet, Player.PlayerData.citizenid })
end)

------------------------------------------
-- timer
------------------------------------------

lib.cron.new(Config.CronupkeepJob, function ()

    local result = MySQL.query.await('SELECT * FROM tbrp_companions')
    if not result then
        if Config.CycleNotify then
            print('No results from database query')
        end
        return
    end

    for i = 1, #result do

        local id = result[i].id
        local petname = result[i].name
        local petid = result[i].dogid
        local owner = result[i].citizenid
        local live = result[i].live
        local hunger = result[i].hunger
        local thirst = result[i].thirst
        local growth = result[i].growth
        local happiness = result[i].happiness
        local dirt = result[i].dirt
        local currentTime = os.time()
        local timeDifference = currentTime - result[i].born
        local daysPassed = math.floor(timeDifference / (24 * 60 * 60))

        local updated = false

        if growth < 100 then
            if live > 0 then
                thirst = thirst - 1
                hunger = hunger - 1
                growth = growth + 1

                if thirst < 75 or hunger < 75 then
                    happiness = happiness - 1
                end

                if thirst < 25 or hunger < 25 then
                    live = live - 1
                    thirst = thirst - 1
                    hunger = hunger - 1
                    happiness = happiness - 1
                end

                if thirst == 0 and hunger > 0 then
                    live = live - 1
                    hunger = hunger - 1
                    happiness = happiness - 1
                end

                if hunger == 0 and thirst > 0 then
                    live = live - 1
                    thirst = thirst - 1
                    happiness = happiness - 1
                end

                if hunger == 0 and thirst == 0 then
                    live = live - 1
                    happiness = happiness - 1
                end

                if dirt > 75 then
                    live = live - 2
                    happiness = happiness - 1
                end

                if dirt > 50 then
                    happiness = happiness - 1
                end

                if hunger < 0 then hunger = 0 end
                if thirst < 0 then thirst = 0 end
                if dirt <= 0 then dirt = 0 end
                if dirt >= 100 then dirt = 100 end
                if live <= 0 then live = 0 end
                if growth >= 100 then growth = 100 end
                if happiness < 0 then happiness = 0 end

                updated = true

                if updated then
                    local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {owner, true})
                    MySQL.update('UPDATE tbrp_companions SET dirt = ?, live = ?, hunger = ?, thirst = ?, growth = ?, happiness = ?  WHERE dogid = ? AND active = ?', {dirt, live, hunger, thirst, growth, happiness, petid, activepet })
                end
            else
                if live <= 0 then live = 0 end

                updated = true

                if updated then
                    if daysPassed == Config.PetDieAge then
                        -- delete pet
                        MySQL.update('DELETE FROM tbrp_companions WHERE id = ?', {id})
                        TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', 'Pet Died', 'red', petname..' belonging to '..owner..' died of old age!')

                        -- telegram message to the pet owner
                        MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
                        {   owner,
                            'Pet Owner',
                            '22222222',
                            'Pet Stables',
                            petname..' passed away',
                            os.date("%x"),
                            'I am sorry to inform you that your pet '..petname..' has passed away, please visit your friendly pet trainer to discuss a replacement!',
                        })
                    else
                        local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {owner, true})
                        MySQL.update('UPDATE tbrp_companions SET live = ? WHERE dogid = ? AND active = ?', {live, petid, activepet })
                    end
                end
            end
        else -- growth >= 100
            if live > 0 then
                thirst = thirst - 1
                hunger = hunger - 1

                if thirst < 75 or hunger < 75 then
                    happiness = happiness - 1
                end

                if thirst < 25 or hunger < 25 then
                    live = live - 1
                    thirst = thirst - 1
                    hunger = hunger - 1
                    happiness = happiness - 1
                end

                if thirst == 0 and hunger > 0 then
                    live = live - 1
                    hunger = hunger - 1
                    happiness = happiness - 1
                end

                if hunger == 0 and thirst > 0 then
                    live = live - 1
                    thirst = thirst - 1
                    happiness = happiness - 1
                end

                if hunger == 0 and thirst == 0 then
                    live = live - 1
                end

                if dirt > 75 then
                    live = live - 2
                    happiness = happiness - 1
                end

                if dirt > 50 then
                    happiness = happiness - 1
                end

                if hunger <= 0 then hunger = 0 end
                if thirst <= 0 then thirst = 0 end
                if dirt <= 0 then dirt = 0 end
                if dirt >= 100 then dirt = 100 end
                if live <= 0 then live = 0 end
                if happiness <= 0 then happiness = 0 end

                updated = true

                if updated then
                    local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {owner, true})
                    MySQL.update('UPDATE tbrp_companions SET dirt = ?, live = ?, hunger = ?, thirst = ?, happiness = ?  WHERE dogid = ? AND active = ?', {dirt, live, hunger, thirst, happiness, petid, activepet })
                end
            else
                if live <= 0 then live = 0 end

                updated = true

                if updated then
                    if daysPassed == Config.PetDieAge then
                        -- delete pet
                        MySQL.update('DELETE FROM tbrp_companions WHERE id = ?', {id})
                        TriggerEvent('rsg-log:server:CreateLog', 'horsetrainer', 'Pet Died', 'red', petname..' belonging to '..owner..' died of old age!')

                        -- telegram message to the pet owner
                        MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
                        {   owner,
                            'Pet Owner',
                            '22222222',
                            'Pet Stables',
                            petname..' passed away',
                            os.date("%x"),
                            'I am sorry to inform you that your pet '..petname..' has passed away, please visit your friendly pet trainer to discuss a replacement!',
                        })
                    else
                        local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {owner, true})
                        MySQL.update('UPDATE tbrp_companions SET live = ? WHERE dogid = ? AND active = ?', {live, petid, activepet })
                    end
                end
            end
        end
    end

    ::continue::

    if Config.CycleNotify then print('pet stats check complete') end
end)

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
