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
    elseif type == "tarderPlayer" then
        PerformHttpRequest(Config['Webhooks']['tarderPlayer'], function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
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

    if Config.Payment == 'item' then
    	local cashItem = Player.Functions.GetItemByName(Config.PaymentType)
    	local cashAmount = cashItem.amount

        if not cashItem and tonumber(cashAmount) < tonumber(price) then
            TriggerClientEvent('RSGCore:Notify', src, 'error.no_cash', 'error')
            return
        else
            Player.Functions.RemoveItem(Config.PaymentType, price, 'pet-stake')
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.PaymentType], "remove")
            TriggerClientEvent('RSGCore:Notify', src, 'success.pet_owned' , 'success')
        end
    elseif Config.Payment == 'money' then
	    local currentCash = Player.PlayerData.money[Config.PaymentType]
        if tonumber(currentCash) < tonumber(price) then
            TriggerClientEvent('RSGCore:Notify', src, 'error.no_cash', 'error')
            return
        else
            Player.Functions.RemoveMoney(Config.PaymentType, price, 'pet-stake')
            TriggerClientEvent('RSGCore:Notify', src, 'success.pet_owned' , 'success')
        end
    end

    local discordMessage = string.format(
            "Citizenid:** %s \n**Ingame ID:** %d \n**Name:** %s %s \n**Pet ID:** %s \n**Pet name:** %s \n**Pet model:** %s \n** Pay $:** %.2f**",
            Player.PlayerData.citizenid,
            Player.PlayerData.cid,
            Player.PlayerData.charinfo.firstname,
            Player.PlayerData.charinfo.lastname,
            dogid,
            dogname,
            model,
            price
        )
    TriggerClientEvent('ox_lib:notify', src, { title = dogname.. ' pet buy for'.. price, type = 'inform', duration = 5000 })
    sendToDiscord(16753920,	"Companions | BUY PET", discordMessage, "Trader for RSG Framework", "trader")

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

    local discordMessage = string.format(
        "Citizenid:** %s \n**Ingame ID:** %d \n**Name:** %s %s \n**Player ID:** %s pet owned \n**Pet ID:** %s **",
        Player2.PlayerData.citizenid,
        Player2.PlayerData.cid,
        Player2.PlayerData.charinfo.firstname,
        Player2.PlayerData.charinfo.lastname,
        playerId,
        petId
    )

    sendToDiscord(16753920,	"Companions | TRADE PET", discordMessage, "Trader for RSG Framework", "tarderPlayer")
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
    local petname = data.name
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

            if Config.Payment == 'item' then
                Player.Functions.AddItem(Config.PaymentType, sellprice, 'sellvendor-sold')
                TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.PaymentType], "add")
            elseif Config.Payment == 'money' then
                Player.Functions.AddMoney(Config.PaymentType, sellprice, 'sellvendor-sold')
            end

            local discordMessage = string.format(
                    "Citizenid:** %s \n**Ingame ID:** %d \n**Name:** %s %s \n**Pet ID:** %s \n**Pet name:** %s \n**Pet model:** %s \n** Recive $:** %.2f**",
                    Player.PlayerData.citizenid,
                    Player.PlayerData.cid,
                    Player.PlayerData.charinfo.firstname,
                    Player.PlayerData.charinfo.lastname,
                    petid,
                    petname,
                    modelPet,
                    sellprice
                )
            TriggerClientEvent('ox_lib:notify', src, { title = petname.. ' pet sold for'.. sellprice, type = 'inform', duration = 5000 })
            sendToDiscord(16753920,	"Companions | VENDOR", discordMessage, "Trader for RSG Framework", "trader")
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
        local happiness = happinesspet + Config.HappinessIncrease
        if happiness >= 100 then
            happiness = 100
            local dirt = 0.0
            MySQL.update("UPDATE tbrp_companions SET dirt = ?, happiness = ?, dogxp = ?  WHERE id = ? AND citizenid = ?", { dirt, happiness, xppet + Config.XpPerClean, activepet, Player.PlayerData.citizenid})
        else
            local dirt = 0.0
            MySQL.update("UPDATE tbrp_companions SET dirt = ?, happiness = ?, dogxp = ?  WHERE id = ? AND citizenid = ?", { dirt, happiness, xppet + Config.XpPerClean, activepet, Player.PlayerData.citizenid})
        end
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

            local thirst = thirstpet + Config.ThirstIncrease
            if thirst >= 100 then
                thirst = 100
                MySQL.update("UPDATE tbrp_companions SET thirst = ?, dogxp = ? WHERE id = ? AND citizenid = ?", { thirst, xppet + Config.XpPerDrink, activepet, Player.PlayerData.citizenid})
            else
                MySQL.update("UPDATE tbrp_companions SET thirst = ?, dogxp = ? WHERE id = ? AND citizenid = ?", { thirst, xppet + Config.XpPerDrink, activepet, Player.PlayerData.citizenid})
            end
            local happiness = happinesspet + Config.HappinessIncrease
            if happiness >= 100 then
                happiness = 100
                MySQL.update("UPDATE tbrp_companions SET happiness = ? WHERE id = ? AND citizenid = ?", { happiness, activepet, Player.PlayerData.citizenid})
            else
                MySQL.update("UPDATE tbrp_companions SET happiness = ? WHERE id = ? AND citizenid = ?", { happiness, activepet, Player.PlayerData.citizenid})
            end
            local dirt = dirtpet + Config.DegradeDirt
            if dirt >= 100 then
                dirt = 100
                MySQL.update("UPDATE tbrp_companions SET dirt = ? WHERE id = ? AND citizenid = ?", { dirt, activepet, Player.PlayerData.citizenid})
            else
                MySQL.update("UPDATE tbrp_companions SET dirt = ? WHERE id = ? AND citizenid = ?", { dirt, activepet, Player.PlayerData.citizenid})
            end
        elseif item == Config.AnimalFood then
			Player.Functions.RemoveItem(Config.AnimalFood, 1)
			TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.AnimalFood], "remove")

            local hunger = hungerpet + Config.HungerIncrease
            if hunger >= 100 then
                hunger = 100
                MySQL.update("UPDATE tbrp_companions SET hunger = ?, dogxp = ? WHERE id = ? AND citizenid = ?", { hunger, xppet + Config.XpPerFeed, activepet, Player.PlayerData.citizenid})
            else
                MySQL.update("UPDATE tbrp_companions SET hunger = ?, dogxp = ? WHERE id = ? AND citizenid = ?", { hunger, xppet + Config.XpPerFeed, activepet, Player.PlayerData.citizenid})
            end
            local happiness = happinesspet + Config.HappinessIncrease
            if happiness >= 100 then
                happiness = 100
                MySQL.update("UPDATE tbrp_companions SET happiness = ? WHERE id = ? AND citizenid = ?", { happiness, activepet, Player.PlayerData.citizenid})
            else
                MySQL.update("UPDATE tbrp_companions SET happiness = ? WHERE id = ? AND citizenid = ?", { happiness, activepet, Player.PlayerData.citizenid})
            end
            local dirt = dirtpet + Config.DegradeDirt
            if dirt >= 100 then
                dirt = 100
                MySQL.update("UPDATE tbrp_companions SET dirt = ? WHERE id = ? AND citizenid = ?", { dirt, activepet, Player.PlayerData.citizenid})
            else
                MySQL.update("UPDATE tbrp_companions SET dirt = ? WHERE id = ? AND citizenid = ?", { dirt, activepet, Player.PlayerData.citizenid})
            end
        end
    else
        TriggerClientEvent('RSGCore:Notify', src, "You don't have "..item, 'error')
    end
end)

RegisterServerEvent('tbrp_companions:server:setpetAttributes', function(number)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local dirtpet = MySQL.scalar.await('SELECT dirt FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local dirt = dirtpet + number
    if dirt >= 100 then
        dirt = 100
        MySQL.update("UPDATE tbrp_companions SET dirt = ? WHERE id = ? AND citizenid = ?", { dirt, activepet, Player.PlayerData.citizenid})
    else
        MySQL.update("UPDATE tbrp_companions SET dirt = ? WHERE id = ? AND citizenid = ?", { dirt, activepet, Player.PlayerData.citizenid})
    end
end)

RegisterServerEvent('tbrp_companions:server:setpetAttributesGrowth', function(number)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local growthpet = MySQL.scalar.await('SELECT growth FROM tbrp_companions WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    local growth = growthpet + number
    if growth >= 100 then
        growth = 100
        MySQL.update("UPDATE tbrp_companions SET growth = ? WHERE id = ? AND citizenid = ?", { growth, activepet, Player.PlayerData.citizenid})
    else
        MySQL.update("UPDATE tbrp_companions SET growth = ? WHERE id = ? AND citizenid = ?", { growth, activepet, Player.PlayerData.citizenid})
    end
end)

------------------------------------------
-- timer
------------------------------------------

-- lib.cron.new(Config.CronupkeepJob, function ()

--     local result = MySQL.query.await('SELECT * FROM tbrp_companions')
--     if not result then
--         if Config.CycleNotify then
--             print('No results from database query')
--         end
--         return
--     end

--     for i = 1, #result do -- problem with i = 1 table take id = 1  instead of taking all the results

--         local id = result[i].id
--         local petname = result[i].name
--         local petid = result[i].dogid
--         local owner = result[i].citizenid
--         local live = result[i].live
--         local hunger = result[i].hunger
--         local thirst = result[i].thirst
--         local growth = result[i].growth
--         local happiness = result[i].happiness
--         local dirt = result[i].dirt
--         local currentTime = os.time()
--         local timeDifference = currentTime - result[i].born
--         local daysPassed = math.floor(timeDifference / (24 * 60 * 60))
--         local updated = false

--         if growth < 100 then
--             if live > 0 then
--                 thirst = thirst - 1
--                 hunger = hunger - 1
--                 growth = growth + 1

--                 if thirst < 75 or hunger < 75 then
--                     happiness = happiness - 1
--                 end

--                 if thirst < 25 or hunger < 25 then
--                     live = live - 1
--                     thirst = thirst - 1
--                     hunger = hunger - 1
--                     happiness = happiness - 1
--                 end

--                 if thirst == 0 and hunger > 0 then
--                     live = live - 1
--                     hunger = hunger - 1
--                     happiness = happiness - 1
--                 end

--                 if hunger == 0 and thirst > 0 then
--                     live = live - 1
--                     thirst = thirst - 1
--                     happiness = happiness - 1
--                 end

--                 if hunger == 0 and thirst == 0 then
--                     live = live - 1
--                     happiness = happiness - 1
--                 end

--                 if dirt > 75 then
--                     live = live - 2
--                     happiness = happiness - 1
--                 end

--                 if dirt > 50 then
--                     happiness = happiness - 1
--                 end

--                 if hunger < 0 then hunger = 0 end
--                 if thirst < 0 then thirst = 0 end
--                 if dirt <= 0 then dirt = 0 end
--                 if dirt >= 100 then dirt = 100 end
--                 if growth >= 100 then growth = 100 end
--                 if happiness < 0 then happiness = 0 end

--                 updated = true

--                 if updated then
--                     local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {owner, true})
--                     MySQL.update('UPDATE tbrp_companions SET dirt = ?, live = ?, hunger = ?, thirst = ?, growth = ?, happiness = ?  WHERE dogid = ? AND active = ?', {dirt, live, hunger, thirst, growth, happiness, petid, activepet })
--                 end
--                 updated = false
--             else
--                 if live <= 0 then live = 0 end
--                 if hunger > 0 then hunger = 0 end
--                 if thirst > 0 then thirst = 0 end
--                 if dirt < 100 then dirt = 100 end
--                 if happiness > 0 then happiness = 0 end

--                 updated = true

--                 if updated then
--                     if daysPassed == Config.PetDieAge then
--                         -- delete pet
--                         MySQL.update('DELETE FROM tbrp_companions WHERE id = ?', {id})

--                         local discordMessage = string.format(
--                             "Citizenid:** %s\n**Ingame Pet ID:** %d\n**Name Pet belonging to:** %s died of old age!**",
--                             owner,
--                             petid,
--                             petname
--                         )

--                         sendToDiscord(16753920,	"Companions | PET DIED", discordMessage, "Companions for RSG Framework", "petinfo")

--                         -- telegram message to the pet owner
--                         MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
--                         {   owner,
--                             'Pet Owner',
--                             '22222222',
--                             'Pet Stables',
--                             petname..' passed away',
--                             os.date("%x"),
--                             'I am sorry to inform you that your pet '..petname..' has passed away, please visit your friendly pet trainer to discuss a replacement!',
--                         })
--                     else
--                         local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {owner, true})
--                         MySQL.update('UPDATE tbrp_companions SET live = ?, hunger = ?, thirst = ?, dirt = ?, happiness = ?, WHERE dogid = ? AND active = ?', {live, hunger, thirst, dirt, happiness, petid, activepet })

--                         local discordMessage = string.format(
--                             "Citizenid:** %s\n**Ingame Pet ID:** %d\n**Name Pet belonging to:** %s died for a bad master!**",
--                             owner,
--                             petid,
--                             petname
--                         )

--                         sendToDiscord(16753920,	"Companions | PET DIED", discordMessage, "Companions for RSG Framework", "petinfo")
--                     end
--                 end
--                 updated = false
--             end
--         else -- growth >= 100
--             if live > 0 then
--                 thirst = thirst - 1
--                 hunger = hunger - 1

--                 if thirst < 75 or hunger < 75 then
--                     happiness = happiness - 1
--                 end

--                 if thirst < 25 or hunger < 25 then
--                     live = live - 1
--                     thirst = thirst - 1
--                     hunger = hunger - 1
--                     happiness = happiness - 1
--                 end

--                 if thirst == 0 and hunger > 0 then
--                     live = live - 1
--                     hunger = hunger - 1
--                     happiness = happiness - 1
--                 end

--                 if hunger == 0 and thirst > 0 then
--                     live = live - 1
--                     thirst = thirst - 1
--                     happiness = happiness - 1
--                 end

--                 if hunger == 0 and thirst == 0 then
--                     live = live - 1
--                 end

--                 if dirt > 75 then
--                     live = live - 2
--                     happiness = happiness - 1
--                 end

--                 if dirt > 50 then
--                     happiness = happiness - 1
--                 end

--                 if hunger <= 0 then hunger = 0 end
--                 if thirst <= 0 then thirst = 0 end
--                 if dirt <= 0 then dirt = 0 end
--                 if dirt >= 100 then dirt = 100 end
--                 if happiness <= 0 then happiness = 0 end

--                 updated = true

--                 if updated then
--                     local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {owner, true})
--                     MySQL.update('UPDATE tbrp_companions SET dirt = ?, live = ?, hunger = ?, thirst = ?, happiness = ?  WHERE dogid = ? AND active = ?', {dirt, live, hunger, thirst, happiness, petid, activepet })
--                 end
--                 updated = false
--             else
--                 if live <= 0 then live = 0 end
--                 if hunger > 0 then hunger = 0 end
--                 if thirst > 0 then thirst = 0 end
--                 if dirt < 100 then dirt = 100 end
--                 if happiness > 0 then happiness = 0 end

--                 updated = true

--                 if updated then
--                     if daysPassed == Config.PetDieAge then
--                         -- delete pet
--                         MySQL.update('DELETE FROM tbrp_companions WHERE id = ?', {id})

--                         local discordMessage = string.format(
--                             "Citizenid:** %s\n**Ingame Pet ID:** %d\n**Name Pet belonging to:** %s died of old age!**",
--                             owner,
--                             petid,
--                             petname
--                         )

--                         sendToDiscord(16753920,	"Companions | PET DIED", discordMessage, "Companions for RSG Framework", "petinfo")

--                         -- telegram message to the pet owner
--                         MySQL.insert('INSERT INTO telegrams (citizenid, recipient, sender, sendername, subject, sentDate, message) VALUES (?, ?, ?, ?, ?, ?, ?)',
--                         {   owner,
--                             'Pet Owner',
--                             '22222222',
--                             'Pet Stables',
--                             petname..' passed away',
--                             os.date("%x"),
--                             'I am sorry to inform you that your pet '..petname..' has passed away, please visit your friendly pet trainer to discuss a replacement!',
--                         })
--                     else
--                         local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE citizenid = ? AND active = ?', {owner, true})
--                         MySQL.update('UPDATE tbrp_companions SET live = ?, hunger = ?, thirst = ?, dirt = ?, happiness = ?, WHERE dogid = ? AND active = ?', {live, hunger, thirst, dirt, happiness, petid, activepet })

--                         local discordMessage = string.format(
--                             "Citizenid:** %s\n**Ingame Pet ID:** %d\n**Name Pet belonging to:** %s died for a bad master!**",
--                             owner,
--                             petid,
--                             petname
--                         )

--                         sendToDiscord(16753920,	"Companions | PET DIED", discordMessage, "Companions for RSG Framework", "petinfo")
--                     end
--                 end
--                 updated = false
--             end
--         end

--     end

--     ::continue::

--     if Config.CycleNotify then print('pet stats check complete') end
-- end)
lib.cron.new(Config.CronupkeepJob, function ()
    local result = MySQL.query.await('SELECT * FROM tbrp_companions')
    if not result or #result == 0 then
        if Config.CycleNotify then
            print('No results from database query')
        end
        return
    end

    for _, pet in pairs(result) do
        -- Asegurarse de que todos los campos necesarios están presentes
        if not pet.id or not pet.dogid or not pet.born or not pet.active == nil then
            if Config.CycleNotify then
                print('Invalid data for pet:', pet)
            end
            goto continue
        end

        local id = pet.id
        local petname = pet.name
        local petid = pet.dogid
        local owner = pet.citizenid
        local live = pet.live or 0
        local hunger = pet.hunger or 0
        local thirst = pet.thirst or 0
        local growth = pet.growth or 0
        local happiness = pet.happiness or 0
        local dirt = pet.dirt or 0
        local currentTime = os.time()
        local timeDifference = currentTime - pet.born
        local daysPassed = math.floor(timeDifference / (24 * 60 * 60))

        local updated = false
        if pet.active then
            live, hunger, thirst, growth, happiness, dirt, updated = updatePetStats( live, hunger, thirst, growth, happiness, dirt)
            if updated then
                MySQL.update( 'UPDATE tbrp_companions SET dirt = ?, live = ?, hunger = ?, thirst = ?, growth = ?, happiness = ? WHERE dogid = ? AND active = ?', {dirt, live, hunger, thirst, growth, happiness, petid, true})
            end
        end

        handlePetDeath(pet, daysPassed, id, owner, petid, petname)        -- Manejo de la muerte de la mascota

        ::continue::
    end

    if Config.CycleNotify then 
        print('pet stats check complete')
    end
end)

function updatePetStats(live, hunger, thirst, growth, happiness, dirt)
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

            hunger = math.max(hunger, 0)
            thirst = math.max(thirst, 0)
            dirt = math.min(math.max(dirt, 0), 100)
            growth = math.min(growth, 100)
            happiness = math.max(happiness, 0)
            updated = true
        else
            if live <= 0 then live = 0 end
            if hunger > 0 then hunger = 0 end
            if thirst > 0 then thirst = 0 end
            if dirt < 100 then dirt = 100 end
            if happiness > 0 then happiness = 0 end
            updated = true
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

            hunger = math.max(hunger, 0)
            thirst = math.max(thirst, 0)
            dirt = math.min(math.max(dirt, 0), 100)
            happiness = math.max(happiness, 0)
            updated = true
        else
            if live <= 0 then live = 0 end
            if hunger > 0 then hunger = 0 end
            if thirst > 0 then thirst = 0 end
            if dirt < 100 then dirt = 100 end
            if happiness > 0 then happiness = 0 end
            updated = true
        end
    end

    return live, hunger, thirst, growth, happiness, dirt, updated
end

function handlePetDeath(pet, daysPassed, id, owner, petid, petname)
    if daysPassed == Config.PetDieAge then
        -- delete pet
        MySQL.update('DELETE FROM tbrp_companions WHERE id = ?', {id})

        local discordMessage = "Citizenid:** "..owner.."\n**Ingame Pet ID:** "..petid.."\n**Name Pet belonging to:** "..petname.." died of old age!!**"
        sendToDiscord(16753920, "Companions | PET DIED", discordMessage, "Companions for RSG Framework", "petinfo")

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
    elseif pet.live <= 0 then
        local activepet = MySQL.scalar.await('SELECT id FROM tbrp_companions WHERE dogid = ? AND active = ?', {petid, true})
        MySQL.update('UPDATE tbrp_companions SET live = ?, hunger = ?, thirst = ?, dirt = ?, happiness = ? WHERE dogid = ? AND active = ?', 
            {pet.live, pet.hunger, pet.thirst, pet.dirt, pet.happiness, petid, activepet}
        )

        local discordMessage = "Citizenid:** "..owner.."\n**Ingame Pet ID:** "..petid.."\n**Name Pet belonging to:** "..petname.."died for a bad master!**"
        sendToDiscord(16753920, "Companions | PET DIED", discordMessage, "Companions for RSG Framework", "petinfo")

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
    end
end


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
