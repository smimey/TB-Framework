local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local inside = false
local closesthouse = nil
local hasKey = false
local isOwned = false

local stashLoc = {}
local closetLoc = {}

TBCore = nil
local isLoggedIn = true
local contractOpen = false

local cam = nil
local viewCam = false

Citizen.CreateThread(function()
	while TBCore == nil do
		TriggerEvent('tb-core:client:getObject', function(obj) TBCore = obj end)
		Citizen.Wait(0)
    end
end)

RegisterNetEvent('tb-core:client:setCharacterData')
AddEventHandler('tb-core:client:setCharacterData', function(Player)
    pData = Player
end)

RegisterNetEvent('tb-core:client:PlayerLoaded')
AddEventHandler('tb-core:client:PlayerLoaded', function()
    isLoggedIn = true
    print('Successfully logged in!')
    TriggerEvent('tb-houses:client:setupHouseBlips')
end)

RegisterNetEvent('tb-houses:client:sellHouse')
AddEventHandler('tb-houses:client:sellHouse', function()
    if closesthouse ~= nil and hasKey then
        TriggerServerEvent('tb-houses:server:viewHouse', closesthouse)
    end
end)

--------------------------------------------------------------
-- RegisterNetEvent('tb-houses:client:setupClosestHouse')
-- AddEventHandler('tb-houses:client:setupClosestHouse', function()
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        while isLoggedIn do
            if not inside and TBCore ~= nil then
                SetClosestHouse()
            end
            Citizen.Wait(5000)
        end
    end)
-- end)

function doorText(x, y, z, text)
    SetTextScale(0.325, 0.325)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.011, -0.025+ factor, 0.03, 0, 0, 0, 68)
    ClearDrawOrigin()
end

local houseObj = {}
local POIOffsets = nil
local entering = false
local data = nil

RegisterNetEvent('tb-houses:client:lockHouse')
AddEventHandler('tb-houses:client:lockHouse', function(bool, house)
    Config.Houses[house].locked = bool
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local pos = GetEntityCoords(GetPlayerPed(-1), true)

        if hasKey then
            -- ENTER HOUSE
            if not inside then
                if closesthouse ~= nil then
                    if(GetDistanceBetweenCoords(pos, Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z, true) < 1.5)then
                        if Config.Houses[closesthouse].locked then
                            doorText(Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z + 1.2, '[~g~E~w~] Om huis te betreden | [~g~L~w~] Huis is ~r~vergrendeld')
                            if IsControlJustPressed(0, Keys["L"]) then
                                TriggerServerEvent('tb-houses:server:lockHouse', false, closesthouse)
                            end
                        else
                            doorText(Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z + 1.2, '[~g~E~w~] Om huis te betreden | [~g~L~w~] Huis is ~b~ontgrendeld')
                            if IsControlJustPressed(0, Keys["L"]) then
                                TriggerServerEvent('tb-houses:server:lockHouse', true, closesthouse)
                            end
                        end
                        if IsControlJustPressed(0, Keys["E"]) then
                            enterOwnedHouse(closesthouse)
                        end
                    end
                end
            end

            -- EXIT HOUSE
            if inside then
                if not entering then
                --if closesthouse ~= nil then
                    if(GetDistanceBetweenCoords(pos, Config.Houses[closesthouse].coords.enter.x + POIOffsets.exit.x, Config.Houses[closesthouse].coords.enter.y + POIOffsets.exit.y, Config.Houses[closesthouse].coords.enter.z - 25 + POIOffsets.exit.z, true) < 1.5)then
                        TBCore.Functions.DrawText3D(Config.Houses[closesthouse].coords.enter.x + POIOffsets.exit.x, Config.Houses[closesthouse].coords.enter.y + POIOffsets.exit.y, Config.Houses[closesthouse].coords.enter.z - 25 + POIOffsets.exit.z, '[~g~E~w~] Om huis te verlaten')
                        if IsControlJustPressed(0, Keys["E"]) then
                            leaveOwnedHouse(closesthouse)
                        end
                    end
                end
                --end
            end

            local StashObject = nil
            -- STASH
            if inside then
                if closesthouse ~= nil then
                    if(GetDistanceBetweenCoords(pos, 894.17, -617.66, 34.54, true) < 1.5)then
                        TBCore.Functions.DrawText3D(894.17, -617.66, 34.54, '[~g~E~w~] Stash')
                        if IsControlJustPressed(0, Keys["E"]) then
                            TriggerEvent('tb-inventory:client:openHouseInventory', closesthouse)
                        end
                    elseif(GetDistanceBetweenCoords(pos, 894.17, -617.66, 34.54, true) < 30)then
                        if not DoesEntityExist(SafeObject) then
                            local stashModel = GetHashKey("v_res_tre_bedsidetable")
                            StashObject = CreateObject(stashModel, 349.4877, -1007.531, -100.1697, false, false, false)
                            FreezeEntityPosition(StashObject, true)
                            SetEntityHeading(StashObject, -90.0)
                        end
                        TBCore.Functions.DrawText3D(894.17, -617.66, 34.54, 'Stash')
                    end
                end
            end
        else
            if not isOwned then
                if closesthouse ~= nil then
                    if(GetDistanceBetweenCoords(pos, Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z, true) < 1.5)then
                        if not viewCam then
                            TBCore.Functions.DrawText3D(Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z + 1.2, '[~g~E~w~] Om het huis te bezichtigen')
                            if IsControlJustPressed(0, Keys["E"]) then
                                TriggerServerEvent('tb-houses:server:viewHouse', closesthouse)
                            end
                        end
                    end
                end
            elseif isOwned then
                if closesthouse ~= nil then
                    if not inOwned then
                        if(GetDistanceBetweenCoords(pos, Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z, true) < 1.5)then
                            if not Config.Houses[closesthouse].locked then
                                TBCore.Functions.DrawText3D(Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z + 1.2, '[~g~E~w~] Om naar ~b~binnen~w~ te gaan')
                                if IsControlJustPressed(0, Keys["E"])  then
                                    enterNonOwnedHouse(closesthouse)
                                end
                            else
                                TBCore.Functions.DrawText3D(Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z + 1.2, 'De deur is ~r~vergrendeld')
                            end
                        end
                    elseif inOwned then
                        if(GetDistanceBetweenCoords(pos, Config.Houses[closesthouse].coords.enter.x + POIOffsets.exit.x, Config.Houses[closesthouse].coords.enter.y + POIOffsets.exit.y, Config.Houses[closesthouse].coords.enter.z - 25 + POIOffsets.exit.z, true) < 1.5)then
                            TBCore.Functions.DrawText3D(Config.Houses[closesthouse].coords.enter.x + POIOffsets.exit.x, Config.Houses[closesthouse].coords.enter.y + POIOffsets.exit.y, Config.Houses[closesthouse].coords.enter.z - 25 + POIOffsets.exit.z, '[~g~E~w~] Om huis te verlaten')
                            if IsControlJustPressed(0, Keys["E"]) then
                                leaveNonOwnedHouse(closesthouse)
                            end
                        end

                        -- STASH
                        local StashObject = nil
                        if(GetDistanceBetweenCoords(pos, 894.17, -617.66, 34.54, true) < 1.5)then
                            TBCore.Functions.DrawText3D(894.17, -617.66, 34.54, '[~g~E~w~] Stash')
                            if IsControlJustPressed(0, Keys["E"]) then
                                TriggerEvent('tb-inventory:client:openHouseInventory', closesthouse)
                            end
                        elseif(GetDistanceBetweenCoords(pos, 894.17, -617.66, 34.54, true) < 30)then
                            if not DoesEntityExist(SafeObject) then
                                local stashModel = GetHashKey("v_res_tre_bedsidetable")
                                StashObject = CreateObject(stashModel, 349.4877, -1007.531, -100.1697, false, false, false)
                                FreezeEntityPosition(StashObject, true)
                                SetEntityHeading(StashObject, -90.0)
                            end
                            TBCore.Functions.DrawText3D(894.17, -617.66, 34.54, 'Stash')
                        end
                    end
                end
            end
        end          
    end
end)

function openContract(bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "toggle",
        status = bool,
    })
    contractOpen = bool
end

function enterOwnedHouse(house)
    local coords = { x = Config.Houses[closesthouse].coords.enter.x, y = Config.Houses[closesthouse].coords.enter.y, z= Config.Houses[closesthouse].coords.enter.z - 25}
    if Config.Houses[house].tier == 1 then
        data = exports['tb-interior']:CreateTier1House(coords, false)
    end
    Citizen.Wait(100)
    houseObj = data[1]
    POIOffsets = data[2]
    inside = true
    entering = true
    Citizen.Wait(500)
    SetRainFxIntensity(0.0)
    TriggerEvent('tb-weathersync:client:DisableSync')
    TriggerEvent('tb-houses:client:insideHouse', true)
    TriggerEvent('tb-weed:client:getHousePlants', closesthouse)
    Citizen.Wait(100)
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')
    SetWeatherTypeNowPersist('EXTRASUNNY')
    NetworkOverrideClockTime(23, 0, 0)
    entering = false
end

function leaveOwnedHouse(house)
    DoScreenFadeOut(250)
    Citizen.Wait(500)
    exports['tb-interior']:DespawnInterior(houseObj, function()
        TriggerEvent('tb-weathersync:client:EnableSync')
        Citizen.Wait(100)
        TriggerEvent('tb-houses:client:insideHouse', false)
        DoScreenFadeIn(250)
        SetEntityCoords(GetPlayerPed(-1), Config.Houses[closesthouse].coords.enter.x, Config.Houses[closesthouse].coords.enter.y, Config.Houses[closesthouse].coords.enter.z + 0.5)
        SetEntityHeading(GetPlayerPed(-1), Config.Houses[closesthouse].coords.enter.h)
        inside = false
    end)
end

function enterNonOwnedHouse(house)
    local coords = { x = Config.Houses[closesthouse].coords.enter.x, y = Config.Houses[closesthouse].coords.enter.y, z= Config.Houses[closesthouse].coords.enter.z - 25}
    if Config.Houses[house].tier == 1 then
        data = exports['tb-interior']:CreateTier1House(coords, false)
    end
    houseObj = data[1]
    POIOffsets = data[2]
    inside = true
    entering = true
    Citizen.Wait(500)
    SetRainFxIntensity(0.0)
    TriggerEvent('tb-weathersync:client:DisableSync')
    TriggerEvent('tb-houses:client:insideHouse', true)
    TriggerEvent('tb-weed:client:getHousePlants', house)
    Citizen.Wait(100)
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')
    SetWeatherTypeNowPersist('EXTRASUNNY')
    NetworkOverrideClockTime(23, 0, 0)
    inOwned = true
end

function leaveNonOwnedHouse(house)
    DoScreenFadeOut(250)
    Citizen.Wait(500)
    exports['tb-interior']:DespawnInterior(houseObj, function()
        TriggerEvent('tb-weathersync:client:EnableSync')
        Citizen.Wait(100)
        TriggerEvent('tb-houses:client:insideHouse', false)
        DoScreenFadeIn(250)
        SetEntityCoords(GetPlayerPed(-1), Config.Houses[house].coords.enter.x, Config.Houses[house].coords.enter.y, Config.Houses[house].coords.enter.z + 0.5)
        SetEntityHeading(GetPlayerPed(-1), Config.Houses[house].coords.enter.h)
        inOwned = false
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(7)

        for k, v in pairs(Config.Houses) do
            local ped = GetPlayerPed(-1)
            local dist = GetDistanceBetweenCoords(GetEntityCoords(ped), Config.Houses[k].coords.enter.x, Config.Houses[k].coords.enter.y, Config.Houses[k].coords.enter.z, false)

            if dist < 2.5 then
                DrawMarker(2, Config.Houses[k].coords.enter.x, Config.Houses[k].coords.enter.y, Config.Houses[k].coords.enter.z + 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 255, 255, 255, 55, false, false, false, true, false, false, false)
            end
        end
    end
end)

RegisterNetEvent('tb-houses:client:setupHouseBlips')
AddEventHandler('tb-houses:client:setupHouseBlips', function()
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        if isLoggedIn then
            TBCore.Functions.TriggerServerCallback('tb-houses:server:getOwnedHouses', function(ownedHouses)
                for i=1, #ownedHouses, 1 do
                    local house = Config.Houses[ownedHouses[i]]
                    HouseBlip = AddBlipForCoord(house.coords.enter.x, house.coords.enter.y, house.coords.enter.z)

                    SetBlipSprite (HouseBlip, 40)
                    SetBlipDisplay(HouseBlip, 4)
                    SetBlipScale  (HouseBlip, 0.65)
                    SetBlipAsShortRange(HouseBlip, true)
                    SetBlipColour(HouseBlip, 3)

                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentSubstringPlayerName(house.adress)
                    EndTextCommandSetBlipName(HouseBlip)
                end
            end)
        end
    end)
end)

RegisterNetEvent('tb-houses:client:SetClosestHouse')
AddEventHandler('tb-houses:client:SetClosestHouse', function()
    SetClosestHouse()
end)

function setViewCam(coords, heading, yaw)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z, yaw, 0.00, heading, 80.00, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
    viewCam = true
end

function disableViewCam()
    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    viewCam = false
end

RegisterNUICallback('buy', function()
    openContract(false)
    disableViewCam()
    TriggerServerEvent('tb-houses:server:buyHouse', closesthouse)
end)

RegisterNUICallback('exit', function()
    openContract(false)
    disableViewCam()
end)

RegisterNetEvent('tb-houses:client:viewHouse')
AddEventHandler('tb-houses:client:viewHouse', function(houseprice, brokerfee, bankfee, taxes, firstname, lastname)
    setViewCam(Config.Houses[closesthouse].coords.cam, Config.Houses[closesthouse].coords.cam.heading, Config.Houses[closesthouse].coords.yaw)
    Citizen.Wait(500)
    openContract(true)
    SendNUIMessage({
        type = "setupContract",
        firstname = firstname,
        lastname = lastname,
        street = Config.Houses[closesthouse].adress,
        houseprice = houseprice,
        brokerfee = brokerfee,
        bankfee = bankfee,
        taxes = taxes,
        totalprice = (houseprice + brokerfee + bankfee + taxes)
    })
end)

function SetClosestHouse()
    local pos = GetEntityCoords(GetPlayerPed(-1), true)
    local current = nil
    local dist = nil

    for id, house in pairs(Config.Houses) do
        if current ~= nil then
            if(GetDistanceBetweenCoords(pos, Config.Houses[id].coords.enter.x, Config.Houses[id].coords.enter.y, Config.Houses[id].coords.enter.z, true) < dist)then
                current = id
                dist = GetDistanceBetweenCoords(pos, Config.Houses[id].coords.enter.x, Config.Houses[id].coords.enter.y, Config.Houses[id].coords.enter.z, true)
            end
        else
            dist = GetDistanceBetweenCoords(pos, Config.Houses[id].coords.enter.x, Config.Houses[id].coords.enter.y, Config.Houses[id].coords.enter.z, true)
            current = id
        end
    end
    closesthouse = current

    TBCore.Functions.TriggerServerCallback('tb-houses:server:hasKey', function(result)
        hasKey = result
    end, closesthouse)

    TBCore.Functions.TriggerServerCallback('tb-houses:server:isOwned', function(result)
        isOwned = result
    end, closesthouse)
end

--------------------------------------------------------------
-- Command Events
--------------------------------------------------------------

-- RegisterNetEvent('tb-houses:client:addLocation')
-- AddEventHandler('tb-houses:client:addLocation', function(soort)
--     if inside then
--         if hasKey then
--             if closesthouse ~= nil then
--                 if soort == "stash" then
--                     local pos = GetEntityCoords(GetPlayerPed(-1), true)
--                     local stashpos = { x = pos.x, y = pos.y, z = pos.z }
--                     TriggerServerEvent('tb-houses:server:addStash', stashpos, closesthouse)                    
--                 elseif soort == "closet" then
--                     local pos = GetEntityCoords(GetPlayerPed(-1), true)
--                     local closetpos = { x = pos.x, y = pos.y, z = pos.z }
--                     TriggerServerEvent('tb-houses:server:addCloset', closetpos, closesthouse)   
--                 end
--             end
--         else
--             exports['s1-notify']:DoHudText('error', 'Je hebt sleutels niet van dit huis')
--         end
--     else
--         exports['s1-notify']:DoHudText('error', 'Je moet in je huis zijn')
--     end
-- end)

-- RegisterNetEvent('tb-houses:client:removeLocation')
-- AddEventHandler('tb-houses:client:removeLocation', function(soort)
--     if inside then
--         if hasKey then
--             if closesthouse ~= nil then
--                 if soort == "stash" then
--                     TriggerServerEvent('tb-houses:server:removeStash', closesthouse)                    
--                 elseif soort == "closet" then
--                     TriggerServerEvent('tb-houses:server:removeCloset', closesthouse)   
--                 end
--             end
--         else
--             exports['s1-notify']:DoHudText('error', 'Je hebt sleutels niet van dit huis')
--         end
--     else
--         exports['s1-notify']:DoHudText('error', 'Je moet in je huis zijn')
--     end
-- end)

-- RegisterNetEvent('tb-houses:client:sendAlert')
-- AddEventHandler('tb-houses:client:sendAlert', function(msgtype, msg)
--     exports['s1-notify']:DoHudText(msgtype, msg)
-- end)

--------------------------------------------------------------

-- function OpenClothesMenu()
--     ESX.TriggerServerCallback('tb-houses:server:getPlayerDressing', function(dressing)
--         local elements = {}

--         for i=1, #dressing, 1 do
--             table.insert(elements, {
--                 label = dressing[i],
--                 value = i
--             })
--         end

--         ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_dressing', {
--             title    = "Closet",
--             align    = 'top-left',
--             elements = elements
--         }, function(data, menu)
--             TriggerEvent('skinchanger:getSkin', function(skin)
--                 ESX.TriggerServerCallback('tb-houses:server:getPlayerOutfit', function(clothes)
--                     TriggerEvent('skinchanger:loadClothes', skin, clothes)
--                     TriggerEvent('esx_skin:setLastSkin', skin)
--                     TriggerEvent('skinchanger:getSkin', function(skin)
--                         TriggerServerEvent('esx_skin:save', skin)
--                     end)
--                 end, data.current.value)
--             end)

--         end, function(data, menu)
--             menu.close()
--         end)
--     end)
-- end

-- RegisterNetEvent('tb-houses:client:setClosetStash')
-- AddEventHandler('tb-houses:client:setClosetStash', function()
--     getClosetStash()
-- end)

-- function getClosetStash()
--     ESX.TriggerServerCallback('tb-houses:server:getStashLoc', function(result)
--         if result ~= nil then
--             stashLoc = { x = result.x, y = result.y, z = result.z }
--         else
--             stashLoc = {}
--         end
--     end, closesthouse)

--     ESX.TriggerServerCallback('tb-houses:server:getClosetLoc', function(result)
--         if result ~= nil then
--             closetLoc = { x = result.x, y = result.y, z = result.z }
--         else
--             closetLoc = {}
--         end
--     end, closesthouse)
-- end