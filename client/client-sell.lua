local RSGCore = exports['rsg-core']:GetCoreObject()
-- FOLLOW COMMENTS FOR -- need change name respource
---------------------------------------------
-- sell vendor menu
---------------------------------------------
RegisterNetEvent('hdrp-companions:client:openSellMenu') -- change resource
AddEventHandler('hdrp-companions:client:openSellMenu', function(menuId)
    local actualMenuId
    if type(menuId) == "table" then actualMenuId = tostring(menuId[1]) else actualMenuId = tostring(menuId) end
    if not actualMenuId then print("Error: menuId es nulo o vacío.", actualMenuId)  return end
    RSGCore.Functions.TriggerCallback('hdrp-companions:server:GetItems', function(result)
        if not result or not result.items or #result.items == 0 then lib.notify({ title = 'Error', description = 'There are no items available to sell.', type = 'error', duration = 7000 })  return end
        for _, v in pairs(Config.PetsLocations) do --  change resource config
            if v.stablepetid == actualMenuId then
                TriggerEvent('hdrp-companions:client:ShopSell', result.items) -- change resource
                break
            end
        end
    end, actualMenuId)
end)

RegisterNetEvent('hdrp-companions:client:ShopSell') -- change resource
AddEventHandler('hdrp-companions:client:ShopSell', function(sellId)
    local itemsList = sellId
    if type(sellId) == "table" then itemsList = sellId end

    local sellSubMenu = {
        id = 'items_sellpets_menu',
        title = 'Items to sell',
        description = 'List of sellable items',
        menu = 'petshop_menu', -- change resource menu 
        options = {},
        onBack = function()
        end,
    }

    local subOptionAll = {
        title = 'Sell all items',
        description = 'Sell all available items',
        event = 'hdrp-companions:client:sellAll', -- change resource
        args = { itemsList },
        icon = 'fa-solid fa-handshake',
        arrow = true,
    }

    table.insert(sellSubMenu.options, subOptionAll)

    if Config.Debug then print('sellId:', json.encode(itemsList)) end
    for _, item in ipairs(itemsList) do

        if Config.Debug then print('Id:', json.encode(item)) end

        if item and item.name then
            local itemLabel = RSGCore.Shared.Items[tostring(item.name)].label
            local itemImage = "nui://" .. Config.img .. RSGCore.Shared.Items[tostring(item.name)].image
            --local itemprice = tonumber(item.price) / 100
            local optionTitle = string.format("$%d | %s | Ud.: %d", tonumber(item.price), itemLabel, tonumber(item.amount))

            local subOptions = {
                title = optionTitle,
                event = 'hdrp-companions:client:sellcount', -- change resource
                args = { name = item.name, amount = tonumber(item.amount), price = tonumber(item.price) },
                icon = itemImage,
                image = itemImage,
                arrow = true,
            }
            table.insert(sellSubMenu.options, subOptions)

        else
            if Config.Debug then print("Elemento no tiene nombre:", json.encode(item)) end
        end
    end

    lib.registerContext(sellSubMenu)
    lib.showContext('items_sellpets_menu')
end)

---------------------------------------------
-- sell amount
---------------------------------------------
RegisterNetEvent('hdrp-companions:client:sellcount') -- change resource
AddEventHandler('hdrp-companions:client:sellcount', function(args)
    local maX = args.amount
    local labelX = RSGCore.Shared.Items[tostring(args.name)].label
    local input = lib.inputDialog('Do you want to sell, do you have what I need?', {
        {   label = 'Have '.. labelX.. ' | Ud.:'.. maX,
            type = 'number',
            min = 1,
            max = maX,
            required = true,
            icon = 'fa-solid fa-hashtag'
        },
    })

    if not input or not tonumber(input[1]) then lib.notify({ title = 'Error', description = 'Please enter a valid numeric value.', type = 'error', duration = 7000 })  return end

    local amount = tonumber(input[1])
    if amount < 1 then lib.notify({ title = 'Insufficient quantity', description = 'The minimum quantity to sell is 1.', type = 'error', duration = 7000 })  return end

    local hasItem = RSGCore.Functions.HasItem(args.name, amount)
    if not hasItem then lib.notify({ title = 'Unable to sell', description = 'You do not have enough items to sell.', type = 'error', duration = 7000 })  return end

    TriggerServerEvent('hdrp-companions:server:sellitem', args.name, amount, args.price) -- change resource

end)

RegisterNetEvent('hdrp-companions:client:sellAll', function(sellId) -- change resource
    local input = lib.inputDialog('You are sure?', {
        {   label = 'Sell All $',
            type = 'select',
            options = {
                { value = 'yes', label = 'Yes' },
                { value = 'no', label = 'No' }
            },
            required = true,
            icon = 'fa-solid fa-circle-question'
        },
    })
    LocalPlayer.state:set("inv_busy", true, true)
    if not input or input[1] == 'no' then lib.notify({ title = 'Sell canceled', description = 'Sale was canceled.', type = 'error', duration = 7000 }) LocalPlayer.state:set("inv_busy", false, true) return end

    if input[1] == 'yes' then
        local items = sellId
        if type(sellId) == "table" then
            items = sellId
        end

        if lib.progressBar({
            duration = Config.SellTime,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disableControl = true,
            disable = {
                move = true,
                mouse = true,
            },
            label = "Trading...",
        }) then

            TriggerServerEvent('hdrp-companions:server:sellall', items) -- change resource
            LocalPlayer.state:set("inv_busy", false, true)
        else
            lib.notify({ title = 'Sale canceled', description = 'The sale was canceled.', type = 'error', duration = 7000 })
            LocalPlayer.state:set("inv_busy", false, true)
        end
    end
end)