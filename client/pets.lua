local spawnedPets = {}

CreateThread(function()
    while true do
        Wait(500)
        for key, value in pairs(Config.PetBuySpawn) do
            local playerCoords = GetEntityCoords(cache.ped)
            local distance = #(playerCoords - value.petcoords.xyz)

            if distance < Config.DistanceSpawn and not spawnedPets[key] then
                local spawnedPet = NearPet(value.petmodel, value.petcoords, value.petprice, value.petname, value.stablepetid )
                spawnedPets[key] = { spawnedPet = spawnedPet }
            end

            if distance >= Config.DistanceSpawn and spawnedPets[key] then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedPets[key].spawnedPet, i, false)
                    end
                end
                DeletePed(spawnedPets[key].spawnedPet)
                spawnedPets[key] = nil
            end
        end
    end
end)

function NearPet(petmodel, petcoords, petprice, petname, stablepetid)

    RequestModel(petmodel)

    while not HasModelLoaded(petmodel) do
        Wait(500)
    end

    spawnedPet = CreatePed(petmodel, petcoords.x, petcoords.y, petcoords.z - 1.0, petcoords.w, false, false, 0, 0)
    SetEntityAlpha(spawnedPet, 0, false)
    SetRandomOutfitVariation(spawnedPet, true)
    SetEntityCanBeDamaged(spawnedPet, false)
    SetEntityInvincible(spawnedPet, true)
    FreezeEntityPosition(spawnedPet, true)
    SetBlockingOfNonTemporaryEvents(spawnedPet, true)
    -- set relationship group between pet and player
    SetPedRelationshipGroupHash(spawnedPet, GetPedRelationshipGroupHash(spawnedPet))
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedPet), `PLAYER`)
    -- end of relationship group

    if Config.FadeIn then
        for i = 0, 255, 51 do
            Citizen.Wait(50)
            SetEntityAlpha(spawnedPet, i, false)
        end
    end

    -- target start
    exports['rsg-target']:AddTargetEntity(spawnedPet, {
        options = {
            {
                icon = "fas fa-horse-head",
                label = petname..' $'..petprice,
                targeticon = "fas fa-eye",
                action = function(newnames)
                    local dialog = lib.inputDialog('Pet Setup', {
                        { type = 'input', label = 'Pet Name', required = true },
                        {
                            type = 'select',
                            label = 'Pet Gender',
                            options = {
                                { value = 'male',   label = 'Gelding' },
                                { value = 'female', label = 'Mare' }
                            }
                        }
                    })

                    if not dialog then return end

                    local setPetName = dialog[1]
                    local setPetGender = dialog[2]

                    if setPetName and setPetGender then
                        TriggerServerEvent('hdrp-companions:server:BuyPet', petprice, petmodel, stablepetid, setPetName, setPetGender)
                    else
                        return
                    end
                end
            }
        },
        distance = 2.5,
    })
    -- target end
    return spawnedPet
end

-- cleanup
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for key,value in pairs(spawnedPets) do
        DeletePed(spawnedPets[key].spawnedPet)
        spawnedPets[key] = nil
    end
end)
