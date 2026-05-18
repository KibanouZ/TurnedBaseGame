local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TurnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")
local BattleStartedEvent = ServerScriptService:WaitForChild("Server")
	:WaitForChild("Services")
	:WaitForChild("Events")
	:WaitForChild("BattleStartedEvent")

local EnemiesData = require(ReplicatedStorage.Shared.Services.Modules.EnemiesData)
local PartyManager = require(ReplicatedStorage.Shared.Services.Modules.PartyManager)
local DataManager = require(ServerScriptService.Server.Data.DataManager)

-- Keep track of active battles, indexed by player UserId
local ActiveBattles = {}

-- Get player speed from their profile, fallback  to 5 if not loaded
local function GetPlayerSpeed(player)
	local profile = DataManager.Profiles[player.UserId]
	if profile then
		return profile.Data.Stats.Speed
	end
	return 5
end

-- Build the turn order based on player speed and enemy speed
local function BuildTurnOrder(allies, enemies)
	local allEntities = {}

	for _, player in ipairs(allies) do
		table.insert(allEntities, {
			type = "ally",
			player = player,
			speed = GetPlayerSpeed(player),
		})
	end

	for _, enemy in ipairs(enemies) do
		table.insert(allEntities, {
			type = "enemy",
			id = enemy.id,
			speed = EnemiesData[enemy.id].Speed,
		})
	end

	-- Sort by speed descending
	table.sort(allEntities, function(a, b)
		return a.speed > b.speed
	end)

	return allEntities
end

-- start battle when event is fired
BattleStartedEvent.Event:Connect(function(player)
	local memberIds = PartyManager.GetMemberIds(player)
	local allies = { player }
	for _, id in ipairs(memberIds) do
		local member = Players:GetPlayerByUserId(id)
		if member and member ~= player then
			table.insert(allies, member)
		end
	end

	-- 1 enemy for test
	local enemies = {
		{ id = "Enemy1", currentHealth = EnemiesData["Enemy1"].MaxHealth },
	}

	local turnOrder = BuildTurnOrder(allies, enemies)

	-- save the active battles on table server
	ActiveBattles[player.UserId] = {
		turnOrder = turnOrder,
		currentIndex = 1,
		allies = allies,
		enemies = enemies,
	}

	print("Ordem dos turnos:")
	for i, entity in ipairs(turnOrder) do
		if entity.type == "ally" then
			print(i, "Ally:", entity.player.Name, "Speed:", entity.speed)
		else
			print(i, "Enemy:", entity.id, "Speed:", entity.speed)
		end
	end

	-- Notify clients about the new battle
end)
