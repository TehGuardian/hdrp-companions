local RSGCore = exports['rsg-core']:GetCoreObject()

---------------------------------------------
-- send To Discord
-------------------------------------------
local function sendToDiscord(color, name, message, footer, type)
    local embed = {
            {
                ["color"] = color,
                ["title"] = "**".. name .."**",
                ["description"] = message,
                ["footer"] = {
                ["text"] = footer
            }
        }
    }
    if type == "trader" then
        PerformHttpRequest(Config['Webhooks']['trader'], function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
end

--------------------------------------------
-- SELL
--------------------------------------------
-- FOLLOW COMMENTS FOR -- need change name respource
RegisterServerEvent("hdrp-companions:server:sellitem") -- change resource
AddEventHandler("hdrp-companions:server:sellitem", function(item, amount, price)
    local src = source
	local Player = RSGCore.Functions.GetPlayer(src)
    local totalvalue = (amount * price) / 100

    if Player.Functions.RemoveItem(item, amount) then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
        Wait(1000)
        if Config.Payment == 'item' then
            Player.Functions.AddItem('cash', totalvalue, 'sellvendor-sold')
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['cash'], "add")
        elseif Config.Payment == 'money' then
            Player.Functions.AddMoney('cash', totalvalue, 'sellvendor-sold')
        end
        local discordMessage = string.format(
            "Citizenid:** %s\n**Ingame ID:** %d\n**Name:** %s %s\n**Item sold:** %dx %s\n**Sold for $:** %.2f**",
            Player.PlayerData.citizenid,
            Player.PlayerData.cid,
            Player.PlayerData.charinfo.firstname,
            Player.PlayerData.charinfo.lastname,
            amount,
            RSGCore.Shared.Items[item].label,
            totalvalue
        )

        sendToDiscord(16753920,	"sell | VENDOR",discordMessage, "Trader for RSG Framework", "trader")
        TriggerClientEvent('ox_lib:notify', src, { title = 'Sell '.. RSGCore.Shared.Items[tostring(item)].label.. ' | $:'.. totalvalue, description = 'You items to sell.', type = 'inform', duration = 5000 })
    end
end)

RegisterServerEvent("hdrp-companions:server:sellall")-- change resource
AddEventHandler("hdrp-companions:server:sellall", function(sellId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local items = sellId
    if type(sellId[1]) == "table" then  items = sellId[1] end

    local totalValue = 0

    if Config.debug then
        for k, v in pairs(items) do print("Items sell player: ", items) print(k, v) end
    end

    for _, item in pairs(items) do
        if Config.debug then
            for k, v in pairs(item) do print("Items sell player: ", item) print(k, v) end
        end
        local itemName = item.name
        local itemAmount = item.amount
        local itemPrice = item.price

        if Player.Functions.RemoveItem(itemName, itemAmount) then
            totalValue = totalValue + ((itemAmount * itemPrice) / 100)
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], "remove")
        end
    end

    if Config.Payment == 'item' then
        Player.Functions.AddItem('cash', totalValue, 'sellvendor-sold')
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['cash'], "add")
    elseif Config.Payment == 'money' then
        Player.Functions.AddMoney('cash', totalValue, 'sellvendor-sold')
    end

    local discordMessage = string.format(
        "Citizenid:** %s\n**Ingame ID:** %d\n**Name:** %s %s\n**Items sold for $:** %.2f**",
        Player.PlayerData.citizenid,
        Player.PlayerData.cid,
        Player.PlayerData.charinfo.firstname,
        Player.PlayerData.charinfo.lastname,
        totalValue
    )

    sendToDiscord(16753920, "Sell | VENDOR", discordMessage, "Trader for RSG Framework", "trader")
    TriggerClientEvent('ox_lib:notify', src, { title = 'Total earnings | $' .. totalValue, description = 'All items sold', type = 'inform', duration = 5000 })

end)

--------------------------------------------
-- ADD MENU OPTIONS
--------------------------------------------

RSGCore.Functions.CreateCallback("hdrp-companions:server:GetItems", function(source, cb, sellid) -- change resource
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then print("Player not found") cb({ error = "Player not found" }) return end

    local playerItems = {}
    if Player.PlayerData.items and next(Player.PlayerData.items) then
        for _, item in pairs(Player.PlayerData.items) do
            playerItems[item.name] =  item.amount
        end
    end

    local id = tostring(sellid)
    local response = {
        id = id,
        items = {}
    }

    for _, shop in ipairs(Config.PetsLocations) do -- change resource config
        if shop.stablepetid == id then
            for _, subTable in pairs(shop.shopdata) do
                for itemName, itemPrice in pairs(subTable) do
                    local playerItemAmount = playerItems[itemName] or 0
                    local tableSub = {}
                    if playerItemAmount > 0 then
                        tableSub = {
                            name = itemName,
                            amount = playerItemAmount,
                            price = itemPrice,
                        }
                        table.insert(response.items, tableSub)
                        if Config.Debug then
                            print("Added Object:", itemName, playerItemAmount, itemPrice)
                        end
                    end
                end
            end
            cb(response)
            break
        end
    end

end)

--------------------------------------------
-- CAN SELL
--------------------------------------------
--[[ CanItemBeSaled = function(item)
    local retval = false
    if Config.AllowedItems[item] ~= nil then
        retval = true
    end
    return retval
end ]]