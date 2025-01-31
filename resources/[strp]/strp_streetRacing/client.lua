ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

local ready_state = false

local in_online_race = false

Citizen.CreateThread(function()
    for k,v in pairs(Config.OnlineRace) do
        blip = AddBlipForCoord(v.Start.x, v.Start.y, v.Start.z)
        SetBlipSprite(blip, 315)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(v.Players .. ' racers')
        EndTextCommandSetBlipName(blip)
    end
    for k,v in pairs(Config.OfflineRace) do
        blip = AddBlipForCoord(v.Start.x, v.Start.y, v.Start.z)
        SetBlipSprite(blip, 315)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('NPC Race')
        EndTextCommandSetBlipName(blip)
    end
end)

local canRace = true

RegisterNetEvent('strp_racing:offlineRace_cl')
AddEventHandler('strp_racing:offlineRace_cl', function(can_or_not)
    canRace = can_or_not
end)

RegisterNetEvent('strp_racing:print')
AddEventHandler('strp_racing:print', function(what)
    print(what)
end)

local online_race_leaderboard = {}

RegisterNetEvent('strp_racing:get_online_race_position_client')
AddEventHandler('strp_racing:get_online_race_position_client', function(race, data, player)
    online_race_leaderboard[player][race][player].checkpoint = data
end)

RegisterNetEvent('strp_racing:scaleform_showfreemodemessage')
AddEventHandler('strp_racing:scaleform_showfreemodemessage', function(title, msg, time)
    local s = time
    local scaleform = ESX.Scaleform.Utils.RequestScaleformMovie('MP_BIG_MESSAGE_FREEMODE')

    BeginScaleformMovieMethod(scaleform, 'SHOW_SHARD_WASTED_MP_MESSAGE')
	PushScaleformMovieMethodParameterString(title)
	PushScaleformMovieMethodParameterString(msg)
	EndScaleformMovieMethod()

	while s > 0 do
		Citizen.Wait(1)
		s = s - 0.01

		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
	end

    SetScaleformMovieAsNoLongerNeeded(scaleform)
end)

RegisterNetEvent('strp_racing:onlinerace_cantstart')
AddEventHandler('strp_racing:onlinerace_cantstart', function()
    ready_state = false
    ESX.ShowNotification('Someone else is already running this race, wait until they are ready!')
end)

RegisterNetEvent('strp_racing:end_race_cl')
AddEventHandler('strp_racing:end_race_cl', function()
    -- if in_online_race ~= false then
    --     TriggerServerEvent('strp_racing:end_online_race', in_online_race)
    -- end
end)

RegisterNetEvent('strp_racing:start_online_race')
AddEventHandler('strp_racing:start_online_race', function(_race, position, players)
    local race = _race
    TriggerServerEvent('strp_racing:not_ready_online_race', race)
    in_online_race = race
    ready_state = false
    local pP = PlayerPedId()
    FreezeEntityPosition(pP, false)
    local playerVehicle = {}
    if Config.OnlineRace[race].Type == 'event' then
        local vehicle_hash = GetHashKey(Config.OnlineRace[race].Vehicle)
        RequestModel(vehicle_hash)
        while not HasModelLoaded(vehicle_hash) do
            Wait(0)
        end
        local sL = Config.OnlineRace[race].StartLine[position]
        playerVehicle = CreateVehicle(vehicle_hash, sL.x, sL.y, sL.z, sL.h, true, true)
        TaskWarpPedIntoVehicle(pP, playerVehicle, -1)
    else
        if(IsPedInAnyVehicle(pP, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(pP, false), -1) == pP) then
            playerVehicle = GetVehiclePedIsIn(pP, false)
            local sl = Config.OnlineRace[race].StartLine[position]
            SetEntityCoords(playerVehicle, sl.x, sl.y, sl.z)
            SetEntityHeading(playerVehicle, sl.h)
            TaskWarpPedIntoVehicle(pP, playerVehicle, -1)
        end
    end

    FreezeEntityPosition(playerVehicle, true)
    PlaySoundFrontend(-1, '5S', 'MP_MISSION_COUNTDOWN_SOUNDSET', true)
    Wait(550)
    TriggerServerEvent('strp_racing:countdown')
    Wait(3300)
    FreezeEntityPosition(playerVehicle, false)

    local currentCheckpoint = 0

    local blips = {}

    for i=1, Config.OnlineRace[race].NumberOfZones do
        Wait(0)
        local v = Config.OnlineRace[race].Zones[i]
        local blip = AddBlipForCoord(v.x, v.y, v.z-5)
        if i == Config.OnlineRace[race].NumberOfZones then
            SetBlipSprite(blip, 38)
        else
            SetBlipSprite(blip, 164)
        end
        table.insert(blips, {[i] = {Blip = blip}})
    end

    local faketimer = 0
    local row_in_table = 1

    online_race_leaderboard = {}

    Wait(150)

    for i=1, players do
        table.insert(online_race_leaderboard, {[race] = {[i] = {checkpoint = 0}}})
    end

    local fail_reason = {}

    local isRacing = true
    while isRacing do
        Wait(1)

        --[[for i=1, #number do
            if online_race_leaderboard[row_in_table][race][i].checkpoint == Config.OnlineRace[race].NumberOfZones then
                winner = i
                isRacing = false
            end
        end]]
        local checkpoints = Config.OnlineRace[race].NumberOfZones
        for i=1, #online_race_leaderboard do
            if online_race_leaderboard[i][race][i].checkpoint == checkpoints then
                winner = i
                isRacing = false
            end
        end

        faketimer = faketimer + 1

        if faketimer == 5 then
            TriggerServerEvent('strp_racing:get_online_race_position', race)
            faketimer = 0
        end

        drawTxt('Leaderboard:', 0.07, 0.24, 0.4)

        drawTxt('You: checkpoint ' .. online_race_leaderboard[position][race][position].checkpoint, 0.07, 0.28, 0.4)
        local txt_position = 0.32
        for i=1, players do
            if i ~= position then
                drawTxt('Opponents ' .. i .. ': checkpoint ' .. online_race_leaderboard[i][race][i].checkpoint, 0.07, txt_position, 0.3)
                txt_position = txt_position + 0.04
            end
        end

        local v = {}
        if currentCheckpoint < Config.OnlineRace[race].NumberOfZones then
            v = Config.OnlineRace[race].Zones[currentCheckpoint+1]
            DrawMarker(6, v.x, v.y, v.z+2.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 3.0, 241, 244, 66, 255, false, true, 2, false, false, false, false)
            SetBlipColour(blips[currentCheckpoint+1][currentCheckpoint+1].Blip, 2)
            if currentCheckpoint+1 == Config.OnlineRace[race].NumberOfZones then
                DrawMarker(5, v.x, v.y, v.z+2.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 3.0, 241, 244, 66, 255, false, true, 2, false, false, false, false)
            else
                DrawMarker(21, v.x, v.y, v.z+2.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 1.0, 241, 244, 66, 200, false, true, 2, false, false, false, false)
            end
        end

        local coords = GetEntityCoords(PlayerPedId())

        -- if not IsPedInAnyVehicle(PlayerPedId(), false) then
        --     DeleteCheckpoint(CheckPoint)
        --     fail_reason = 'fall_off'
        --     isRacing = false
        -- end

        if GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < 8.0 then
            currentCheckpoint = currentCheckpoint + 1
            TriggerServerEvent('strp_racing:online_race_update', race, position, currentCheckpoint)
            RemoveBlip(blips[currentCheckpoint][currentCheckpoint].Blip)
            if currentCheckpoint < Config.OnlineRace[race].NumberOfZones then
            end
            PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS")

            if (math.random(1,10) == 1) then -- 10% chance of CAD alert
                local notification = {
                    subject  = 'Robbery in Progress',
                    msg      = "Reports of an illegal street race in-progress",
                    icon = 'fas fa-car',
                    iconStyle = 'red',
                    locationX = v.x,
                    locationY = v.y,
                    caller = 0,
                }
                TriggerServerEvent('esx_service:callAllInService', notification, "police")
            end
        end        
    end

    TriggerServerEvent('strp_racing:end_online_race', race, online_race_leaderboard[position][race][position].checkpoint)

    for i=1, #blips do
        if DoesBlipExist(blips[i][i].Blip) then
            RemoveBlip(blips[i][i].Blip)
        end
    end
    blips = {}
    if Config.OnlineRace[race].Type == 'event' then
        SetEntityAsMissionEntity(playerVehicle, true, true)
        DeleteVehicle(playerVehicle)
        if Config.TPBack then
            SetEntityCoords(pP, Config.OnlineRace[race].Start.x, Config.OnlineRace[race].Start.y, Config.OnlineRace[race].Start.z)
        end
    end
    TriggerServerEvent('strp_racing:online_race_update', race, position, 0)
    ready_state = false
    in_online_race = false
end)

Citizen.CreateThread(function()
    while true do
        TriggerServerEvent('strp_racing:offlineRace_sv', 'can_i_start')
        Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        for k, c in pairs(Config.OfflineRace) do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local v = c['Start']
            if GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < 50.0 then
                DrawMarker(27, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 1.5, 50, 255, 50, 150, false, true, 2, false, false, false, false)
                if GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < 2.0 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(Config.Strings['start_npc'])
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('strp_racing:offlineRace_sv', 'can_i_start')
                        Wait(100)
                        if canRace then
                            TriggerServerEvent('strp_racing:offlineRace_sv', 'start')
                            startNPCRace(k)
                        else
                            ESX.ShowNotification('You can\'t start a race now - someone else is already running one!')
                        end
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        for k, c in pairs(Config.OnlineRace) do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local v = c.Start
            local raceReady = 0
            if GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < 50.0 and in_online_race == false then
                DrawMarker(27, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, c.Size, c.Size, 1.5, 50, 255, 50, 150, false, true, 2, false, false, false, false)
                if GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < c.Size + 0.2 then
                    BeginTextCommandDisplayHelp('STRING')
                    if ready_state then
                        AddTextComponentSubstringPlayerName(Config.Strings['stop_online'])
                    else
                        AddTextComponentSubstringPlayerName(c.Text)
                    end
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then
                        if(IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1) == ped) or c.Type == 'event' then
                            ready_state = not ready_state
                            if ready_state then
                                ready_state = false
                                raceReady = k
                                ESX.UI.Menu.Open(
                                'default', GetCurrentResourceName(), '_ready_online',
                                {
                                    title    = 'Start the race against ' .. c.Players-1 .. ' other players?',
                                    align = 'bottom-right',
                                    elements = {
                                        {label = 'Yes', value = 'yes'},
                                        {label = 'No', value = 'no'}
                                    }
                                },
                                function(data, menu)
                                    if data.current.value == 'yes' then
                                        TriggerServerEvent('strp_racing:ready_online_race', k)
                                        menu.close()
                                        ready_state = true
                                    elseif data.current.value == 'no' then
                                        menu.close()
                                        ready_state = false
                                    end
                                end,
                                function(data, menu)
                                    menu.close()
                                end
                            )
                            else
                                TriggerServerEvent('strp_racing:not_ready_online_race', k)
                            end
                        else
                            ESX.ShowNotification('You have to drive a vehicle!')
                        end
                    end
                end
            else
                if ready_state == true then
                    if k == raceReady then
                        ready_state = false
                        ESX.ShowNotification('You moved too far from the race and you are therefore no longer ready!')
                        TriggerServerEvent('strp_racing:not_ready_online_race', k)
                    end
                end
            end
            if not IsPedInAnyVehicle(PlayerPedId()) and ready_state and c.Type == 'street_race' then
                if k == raceReady then
                    ready_state = false
                    TriggerServerEvent('strp_racing:not_ready_online_race', k)
                    ESX.ShowNotification('You have to be in a vehicle! You are therefore no longer ready.')
                end
            end
        end
    end
end)

function startNPCRace(number)
    local NPCVehicles = {}
    local NPCs = {}
    local Leaderboard = {}
    local position = 1

    for i=1, #Config.OfflineRace[number].StartLine.NPC, 1 do
        Wait(5)
        local vehicle_hash = GetHashKey(Config.OfflineRace[number].Vehicle)
        RequestModel(vehicle_hash)
        while not HasModelLoaded(vehicle_hash) do
            Wait(0)
        end   

        local sL = Config.OfflineRace[number].StartLine.NPC[i]
        local pedVehicle = CreateVehicle(vehicle_hash, sL.x, sL.y, sL.z, sL.h, true, false)
        SetVehicleMod(pedVehicle, 13, 5, false)
        ToggleVehicleMod(vehicle,  18, true)
        local ped_hash = 1813637474
        RequestModel(ped_hash)
        while not HasModelLoaded(ped_hash) do
            Wait(0)
        end
        
        local ped = CreatePed(4, ped_hash, 0.0, 0.0, 0.0, true, true)
        TaskWarpPedIntoVehicle(ped, pedVehicle, -1)
        table.insert(NPCs, {[i] = {npc = ped}})
        table.insert(NPCVehicles, {[i] = {vehicle = pedVehicle}})
    end

    local vehicle_hash = GetHashKey(Config.OfflineRace[number].Vehicle)
    RequestModel(vehicle_hash)
	while not HasModelLoaded(vehicle_hash) do
		Wait(0)
    end

    local sL = Config.OfflineRace[number].StartLine.Player
    local pP = PlayerPedId()
    local playerVehicle = CreateVehicle(vehicle_hash, sL.x, sL.y, sL.z, sL.h, true, false)
    TaskWarpPedIntoVehicle(pP, playerVehicle, -1)
    local locked_speed = GetVehicleMaxSpeed(GetEntityModel(playerVehicle))/3.6 - 15/3.6 -- 15km/h  långsammare än maxhastighet
    SetEntityMaxSpeed(playerVehicle, locked_speed) -- annars är det 99% att man vinner mot npcer

    Wait(500)
    for i=1, 4 do
        Wait(5)
        local vehicle = NPCVehicles[i][i].vehicle
        local ped = NPCs[i][i].npc
        local lastZone = Config.OfflineRace[number].Zones[Config.OfflineRace[number].NumberOfZones]
        FreezeEntityPosition(vehicle, true)
        TaskVehicleDriveToCoord(ped, vehicle, lastZone.x, lastZone.y, lastZone.z, GetVehicleMaxSpeed(vehicle), 0, -1848994066, 262144, 10.0)
        SetDriveTaskDrivingStyle(ped, 262144)       
        SetPedKeepTask(ped, true)
    end
    PlaySoundFrontend(-1, '5S', 'MP_MISSION_COUNTDOWN_SOUNDSET', true)
    Wait(550)
    local sec = 4
    local countingDown = true
    while countingDown do
        Wait(0)
        FreezeEntityPosition(GetVehiclePedIsUsing(PlayerPedId()), true)
        sec = sec - 1
        if sec == 2 then
            ESX.Scaleform.ShowFreemodeMessage(sec, '', 0.55)
        else
            ESX.Scaleform.ShowFreemodeMessage(sec, '', 0.45)
        end
        if sec == 1 then
        for i=1, 4 do
            local vehicle = NPCVehicles[i][i].vehicle
            FreezeEntityPosition(vehicle, false)
        end -- npc får försprång så de har en chans
            ESX.Scaleform.ShowFreemodeMessage('DRIVE!!!', '', 0.4)
            FreezeEntityPosition(GetVehiclePedIsUsing(PlayerPedId()), false)
            countingDown = false
        end
    end

    local currentCheckpoint = 0
    for i=1, 4 do
        Wait(5)
        local ped = NPCs[i][i].npc
        table.insert(Leaderboard, {[i] = {checkpoint = 0}})
    end
    table.insert(Leaderboard, {[5] = {checkpoint = 0}})

    local blips = {}

    for i=1, Config.OfflineRace[number].NumberOfZones do
        Wait(0)
        local v = Config.OfflineRace[number].Zones[i]
        local blip = AddBlipForCoord(v.x, v.y, v.z+5)
        SetBlipColour(blip, 11)
        if i == Config.OfflineRace[number].NumberOfZones then
            SetBlipSprite(blip, 38)
        else
            SetBlipSprite(blip, 128)
        end
        table.insert(blips, {[i] = {Blip = blip}})
    end

    while currentCheckpoint < Config.OfflineRace[number].NumberOfZones do
        Wait(0)
        local v = {}
        v = Config.OfflineRace[number].Zones[currentCheckpoint+1]
        DrawMarker(6, v.x, v.y, v.z+2.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 3.0, 241, 244, 66, 255, false, true, 2, false, false, false, false)
        if currentCheckpoint+1 == Config.OfflineRace[number].NumberOfZones then
            DrawMarker(5, v.x, v.y, v.z+2.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 3.0, 241, 244, 66, 255, false, true, 2, false, false, false, false)
        else
            DrawMarker(21, v.x, v.y, v.z+2.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 1.0, 241, 244, 66, 200, false, true, 2, false, false, false, false)
        end
        local me = PlayerPedId()
        local coords = GetEntityCoords(me)

        drawTxt('Leaderboard:', 0.07, 0.24, 0.4)

        drawTxt('You: checkpoint ' .. Leaderboard[5][5].checkpoint, 0.07, 0.28, 0.4)
        drawTxt('NPC 1: checkpoint ' .. Leaderboard[1][1].checkpoint, 0.07, 0.32, 0.4)
        drawTxt('NPC 2: checkpoint ' .. Leaderboard[2][2].checkpoint, 0.07, 0.36, 0.4)
        drawTxt('NPC 3: checkpoint ' .. Leaderboard[3][3].checkpoint, 0.07, 0.4, 0.4)
        drawTxt('NPC 4: checkpoint ' .. Leaderboard[4][4].checkpoint, 0.07, 0.44, 0.4)

        -- kolla om npc kör in i checkpoint / mål
        for i=1, 4 do
            if Leaderboard[i][i].checkpoint < 11 then
                local ped = NPCs[i][i].npc
                local npcCoords = GetEntityCoords(ped)
                local npcCheckpoint = Leaderboard[i][i].checkpoint
                local lastZone = Config.OfflineRace[number].Zones[npcCheckpoint+1]
                if GetDistanceBetweenCoords(npcCoords, lastZone.x, lastZone.y, lastZone.z, true) < 8.0 then
                    Leaderboard[i][i].checkpoint = npcCheckpoint + 1
                end
                if Leaderboard[i][i].checkpoint == Config.OfflineRace[number].NumberOfZones then
                    DeleteEntity(NPCs[i][i].npc)
                    DeleteVehicle(NPCVehicles[i][i].vehicle)
                    position = position + 1
                end
            end
        end
        

        if GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true) < 8.0 then
            currentCheckpoint = currentCheckpoint + 1
            RemoveBlip(blips[currentCheckpoint][currentCheckpoint].Blip)
            if currentCheckpoint < Config.OfflineRace[number].NumberOfZones then
                SetBlipRoute(blips[currentCheckpoint+1][currentCheckpoint+1].Blip, true)
                SetBlipRouteColour(blips[currentCheckpoint+1][currentCheckpoint+1].Blip, 11)
                Leaderboard[5][5].checkpoint = currentCheckpoint
            end
            PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS")
        end        
        -- if not IsPedInAnyVehicle(PlayerPedId(), false) then
        --     DeleteVehicle(playerVehicle)
        --     DeleteCheckpoint(CheckPoint)
        --     position = 'falled_off'
        --     currentCheckpoint = Config.OnlineRace[number].NumberOfZones
        -- end
    end
    for i=1, 4 do
        Wait(5)
        DeleteEntity(NPCs[i][i].npc)
        DeleteVehicle(NPCVehicles[i][i].vehicle)
    end
    if position == 'falled_off' then
        ESX.ShowNotification('Bad luck! You left the vehicle and ~r~lose')
    else
        ESX.ShowNotification('Good work! You came: ~g~' .. position .. ' ~s~of 5!')
    end
    TriggerServerEvent('strp_racing:offlineRace_sv', 'stop')
    DeleteVehicle(playerVehicle)
    if Config.TPBack then
        SetEntityCoords(PlayerPedId(), Config.OfflineRace[number].Start.x, Config.OfflineRace[number].Start.y, Config.OfflineRace[number].Start.z)
    end
end

function drawTxt(text, x, y, scale)
	SetTextFont(8)
	SetTextProportional(0)
	SetTextScale(scale, scale)
	SetTextColour(255, 255, 255, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
    DrawText(x, y)
    DrawRect(0.0, 0.36, 0.3, 0.25, 71, 71, 71, 75)
end
