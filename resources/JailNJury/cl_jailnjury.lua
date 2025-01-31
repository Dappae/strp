--[[
FiveM-JailNJury
A Jail and Justice System that gives power back to the players.
Copyright (C) 2018  Jarrett Boice

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local isJailedG = false
local jailTimeG = 0

local courtCase = false
local muted = false
local notifyCourtHouseIn = false
local notifyCourtHouseOut = false

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerLoaded = true
	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	PlayerLoaded = true
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

RegisterNetEvent("jnj:sendToJail")
AddEventHandler("jnj:sendToJail", function(jailArray)
  local targetPed = PlayerPedId()
  local jailTime = jailArray[1]
  RemoveAllPedWeapons(targetPed, true)
  SetEntityInvincible(GetPlayerPed(-1), true)
	SetPlayerInvincible(PlayerId(), true)
	SetPedCanRagdoll(GetPlayerPed(-1), false)
	SetEntityProofs(GetPlayerPed(-1), true, true, true, true, true, true, true, true)
	SetEntityOnlyDamagedByPlayer(GetPlayerPed(-1), false)
	SetEntityCanBeDamaged(GetPlayerPed(-1), false)
  SetEntityCoords(targetPed, JailConfig.prisonLocation.x, JailConfig.prisonLocation.y, JailConfig.prisonLocation.z, 0.0, 0.0, 0.0, false)
  isJailedG = true
  jailTimeG = jailTime
	TriggerEvent("esx_policejob:unrestrain")
end)

RegisterNetEvent("jnj:releaseFromJail")
AddEventHandler("jnj:releaseFromJail", function()
  local targetPed = PlayerPedId()
  jailTimeG = 0
  isJailedG = false
  SetEntityInvincible(GetPlayerPed(-1), false)
	SetPlayerInvincible(PlayerId(), false)
	SetPedCanRagdoll(GetPlayerPed(-1), true)
	SetEntityProofs(GetPlayerPed(-1), false, false, false, false, false, false, false, false)
	SetEntityOnlyDamagedByPlayer(GetPlayerPed(-1), true)
	SetEntityCanBeDamaged(GetPlayerPed(-1), true)
  SetEntityCoords(targetPed, JailConfig.prisonEntraceLocation.x, JailConfig.prisonEntraceLocation.y, JailConfig.prisonEntraceLocation.z, 0.0, 0.0, 0.0, false)
	TriggerEvent("esx_policejob:unrestrain")
end)

RegisterNetEvent("jnj:teleportToCourt")
AddEventHandler("jnj:teleportToCourt", function(pmuted, vector)
    local targetPed = PlayerPedId()
    --   RemoveAllPedWeapons(targetPed, true)
    SetEntityCoords(targetPed, vector.x, vector.y, vector.z, 0.0, 0.0, 0.0, false)
    SetEntityHeading(targetPed, vector.h)
    FreezeEntityPosition(targetPed, true)
    if pmuted then
        muted = true
    else
        muted = false
        DisableControlAction(0, 245, false)
        DisableControlAction(0, 249, false)
    end
end)

RegisterNetEvent("jnj:teleportAwayCourt")
AddEventHandler("jnj:teleportAwayCourt", function(vector)
  local targetPed = PlayerPedId()
  SetEntityCoords(targetPed, vector.x, vector.y, vector.z, 0.0, 0.0, 0.0, false)
  FreezeEntityPosition(targetPed, false)
  muted = false
  DisableControlAction(0, 245, false)
  DisableControlAction(0, 249, false)
end)

RegisterNetEvent("jnj:courtCaseStatusAll")
AddEventHandler("jnj:courtCaseStatusAll", function(boolean)
  courtCase = boolean
end)

RegisterNetEvent("jnj:courtCaseStatus")
AddEventHandler("jnj:courtCaseStatus", function(boolean)
  isJailedG = not boolean
end)

  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(0)
      if muted then
        DisableControlAction(0, 245, true)
        DisableControlAction(0, 249, true)
      end
    end
  end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isJailedG then
            local playerPed = PlayerPedId()
            if GetDistanceBetweenCoords(GetEntityCoords(playerPed), JailConfig.prisonLocation.x, JailConfig.prisonLocation.y, JailConfig.prisonLocation.z) > 50 then
                SetEntityCoords(playerPed, JailConfig.prisonLocation.x, JailConfig.prisonLocation.y, JailConfig.prisonLocation.z, 0.0, 0.0, 0.0, false)
                TriggerEvent("chatMessage", "^1Do not attempt to escape.")
            end
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if courtCase then
      local playerPed = PlayerPedId()
      if GetDistanceBetweenCoords(GetEntityCoords(playerPed), JailConfig.courtEntraceLocation.x, JailConfig.courtEntraceLocation.y, JailConfig.courtEntraceLocation.z) < 10 then
        if not notifyCourtHouseIn then
          TriggerServerEvent("jnj:requestJuror", true)
          notifyCourtHouseIn = true
          notifyCourtHouseOut = false
        end
      else
        if not notifyCourtHouseOut then
          TriggerServerEvent("jnj:requestJuror", false)
          notifyCourtHouseIn = false
          notifyCourtHouseOut = true
        end
      end
      Citizen.Wait(1000)
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if isJailedG then
      if jailTimeG == 0 then
        isJailedG = false
        TriggerServerEvent("jnj:releaseFromJail", GetPlayerServerId(PlayerId()))
      end
      Citizen.Wait(1000 * 60)
      jailTimeG = jailTimeG - 1
      TriggerServerEvent("jnj:updateJailTime", jailTimeG)
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if jailTimeG > 0 then
      SetTextFont(0)
      SetTextProportional(1)
      SetTextScale(0.0, 0.3)
      SetTextColour(128, 128, 128, 255)
      SetTextDropshadow(0, 0, 0, 0, 255)
      SetTextEdge(1, 0, 0, 0, 255)
      SetTextDropShadow()
      SetTextOutline()
      SetTextEntry("STRING")
      if isJailedG then
        AddTextComponentString("Jail Time Remaining: " .. tostring(jailTimeG) .. " Minutes")
      else
        AddTextComponentString("Jail Time Remaining: " .. tostring(jailTimeG) .. " Minutes - PAUSED")
      end
      DrawText(0.5, 0.005)
    end
  end
end)

Citizen.CreateThread(function()
  local courthouseBlip = AddBlipForCoord(JailConfig.courtEntraceLocation.x, JailConfig.courtEntraceLocation.y, JailConfig.courtEntraceLocation.z)
  SetBlipSprite(courthouseBlip, 419)
  SetBlipDisplay(courthouseBlip, 4)
  SetBlipScale(courthouseBlip, 1.0)
  SetBlipAsShortRange(courthouseBlip, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString("Supreme Court")
  EndTextCommandSetBlipName(courthouseBlip)
end)

AddEventHandler("playerSpawned", function(spawnInfo)
  TriggerServerEvent("jnj:checkJailed")
end)

RegisterCommand("jail", function(source, args, rawCommand)
	local _source = source
	local targetPedId = args[1]
	local jailTime = tonumber(args[2]) or 0
	local jailCharges = args[3]
	if inJailCells(targetPedId) == false then
		return TriggerEvent("chatMessage", "^1That player is not inside a jail cell.")
	end
	ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
        if isInService then
            if targetPedId == nil then
                return TriggerEvent("chatMessage", "^1You must enter the suspect's ID number.")
            elseif jailTime <= 0 then
                return TriggerEvent("chatMessage", "^1Invalid Jail Time, enter an amount greater than 0.")
            elseif jailCharges == nil then
                return TriggerEvent("chatMessage", "^1You must enter the suspect's charges.")
            else
                TriggerServerEvent("jnj:sendToJail", targetPedId, jailTime, jailCharges)
            end
        else
            TriggerEvent("chatMessage", "^1You are not authorized to use this command. Consider joining a Police Department.")
        end
	end, 'police')
end)

RegisterCommand("unjail", function(source, args, rawCommand)
    local _source = source
    local targetPedId = args[1]
	ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
        if isInService then
            if targetPedId == nil then
                return TriggerEvent("chatMessage", "^1You must enter the prisoner's ID number.")
            else
                TriggerServerEvent("jnj:releaseFromJail", targetPedId)
            end
        else
            TriggerEvent("chatMessage", "^1You are not authorized to use this command. Consider joining a Police Department.")
        end
	end, 'police')
end)
