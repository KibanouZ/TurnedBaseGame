local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TurnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")
local TurnActionEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnActionEvent")
local BattleStartedEvent = ServerScriptService:WaitForChild("Server")
	:WaitForChild("Services")
	:WaitForChild("Events")
	:WaitForChild("BattleStartedEvent")
local AttacksData = require(ReplicatedStorage.Shared.Services.Modules.AttacksData)
local EnemiesData = require(ReplicatedStorage.Shared.Services.Modules.EnemiesData)
local PartyManager = require(ReplicatedStorage.Shared.Services.Modules.PartyManager)
local DataManager = require(ServerScriptService.Server.Data.DataManager)
local EnemiesAttacksData = require(ReplicatedStorage.Shared.Services.Modules.EnemiesAttacksData)

local ActiveBattles = {}

local function GetPlayerSpeed(player)
	local profile = DataManager.Profiles[player.UserId]
	if profile then
		return profile.Data.Stats.Speed
	end
	return 5
end

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
			currentHealth = enemy.currentHealth,
			speed = EnemiesData[enemy.id].Speed,
		})
	end

	table.sort(allEntities, function(a, b)
		return a.speed > b.speed
	end)

	return allEntities
end

local function CheckBattleEnd(battleId)
	local battle = ActiveBattles[battleId]
	if not battle then
		return
	end

	local allEnemiesDead = true
	for _, enemy in ipairs(battle.enemies) do
		if enemy.currentHealth > 0 then
			allEnemiesDead = false
			break
		end
	end

	local allAlliesDead = true
	for _, ally in ipairs(battle.allies) do
		local profile = DataManager.Profiles[ally.UserId]
		if profile then
			if profile.Data.Stats.Health > 0 then
				allAlliesDead = false
			else
				print("Aliado", ally.Name, "foi derrotado.")
				profile.Data.Stats.Health = 0
			end
		end
	end

	if allEnemiesDead then
		for _, ally in ipairs(battle.allies) do
			TurnEvent:FireClient(ally, "Victory")
		end
		ActiveBattles[battleId] = nil
		return true
	elseif allAlliesDead then
		for _, ally in ipairs(battle.allies) do
			TurnEvent:FireClient(ally, "Defeat")
		end
		ActiveBattles[battleId] = nil
		return true
	end

	return false
end

local StartTurn

local function NextTurn(battleId)
	local battle = ActiveBattles[battleId]
	if not battle then
		return
	end

	battle.currentIndex = battle.currentIndex + 1
	if battle.currentIndex > #battle.turnOrder then
		battle.currentIndex = 1
	end

	StartTurn(battleId)
end

local function ExecuteEnemyTurn(battleId)
	local battle = ActiveBattles[battleId]
	if not battle then
		return
	end

	local entity = battle.turnOrder[battle.currentIndex]
	local enemyData = EnemiesData[entity.id]
	local Allies = battle.allies
	local targetIndex = math.random(1, #Allies)
	local target = Allies[targetIndex]

	if not target then
		NextTurn(battleId)
		return
	end

	local AttacksName = enemyData.Attacks
	local attackName = AttacksName[math.random(1, #AttacksName)]
	local attackData = EnemiesAttacksData[attackName]
	local profile = DataManager.Profiles[target.UserId]

	if profile then
		profile.Data.Stats.Health = math.max(0, profile.Data.Stats.Health - attackData.Damage)
		TurnEvent:FireClient(target, "Attacked", {
			damage = attackData.Damage,
			attackName = attackName,
			remainingHealth = profile.Data.Stats.Health,
			maxHealth = profile.Data.Stats.MaxHealth,
		})
		print("Enemy", entity.id, "used", attackName, "on", target.Name, "dealing", attackData.Damage, "damage.")
	else
		warn("Profile nil para", target.Name, "- pulando turno do inimigo")
	end

	task.wait(1.5)

	if CheckBattleEnd(battleId) then
		return
	end

	NextTurn(battleId)
end

StartTurn = function(battleId)
	local battle = ActiveBattles[battleId]
	if not battle then
		return
	end

	local entity = battle.turnOrder[battle.currentIndex]

	if entity.type == "ally" then
		local profile = DataManager.Profiles[entity.player.UserId]
		if not profile then
			return
		end

		profile.Data.Stats.Energy += 1

		TurnEvent:FireClient(entity.player, "YourTurn", {
			attacks = profile.Data.Attacks,
			energy = profile.Data.Stats.Energy,
			maxEnergy = profile.Data.Stats.MaxEnergy,
		})

		print("Turno de:", entity.player.Name)
	elseif entity.type == "enemy" then
		print("Turno do inimigo:", entity.id)
		task.wait(1)
		ExecuteEnemyTurn(battleId)
	end
end

BattleStartedEvent.Event:Connect(function(player, enemyList)
	local memberIds = PartyManager.GetMemberIds(player)
	local allies = { player }

	for _, id in ipairs(memberIds) do
		local member = Players:GetPlayerByUserId(id)
		if member and member ~= player then
			table.insert(allies, member)
		end
	end

	-- Zera energia de todos no início da batalha
	for _, ally in ipairs(allies) do
		local profile = DataManager.Profiles[ally.UserId]
		if profile then
			profile.Data.Stats.Energy = 0
			profile.Data.Stats.Health = profile.Data.Stats.MaxHealth
		end
	end

	local enemies = {}
	for _, enemy in ipairs(enemyList) do
		table.insert(enemies, {
			id = enemy.id,
			currentHealth = EnemiesData[enemy.id].MaxHealth,
		})
	end

	local turnOrder = BuildTurnOrder(allies, enemies)

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

	StartTurn(player.UserId)
end)

TurnActionEvent.OnServerEvent:Connect(function(player, action, data)
	local battleId = player.UserId
	local battle = ActiveBattles[battleId]
	if not battle then
		return
	end

	local entity = battle.turnOrder[battle.currentIndex]
	if entity.type ~= "ally" or entity.player ~= player then
		return
	end

	if action == "Attack" then
		local target = nil

		if data and data.targetName then
			for _, enemy in ipairs(battle.enemies) do
				if enemy.id == data.targetName and enemy.currentHealth > 0 then
					target = enemy
					break
				end
			end
		end

		if not target then
			for _, enemy in ipairs(battle.enemies) do
				if enemy.currentHealth > 0 then
					target = enemy
					break
				end
			end
		end

		if target then
			local profile = DataManager.Profiles[player.UserId]
			local attackName = data and data.attackName
			local attackData = attackName and AttacksData[attackName]

			if not attackData then
				warn("attackName inválido:", attackName)
				return
			end

			if profile.Data.Stats.Energy < attackData.EnergyCost then
				TurnEvent:FireClient(player, "NotEnoughEnergy")
				return
			end

			profile.Data.Stats.Energy = profile.Data.Stats.Energy - attackData.EnergyCost
			target.currentHealth = math.max(0, target.currentHealth - attackData.Damage)

			TurnEvent:FireClient(player, "AttackSuccess", {
				enemyId = target.id,
				damage = attackData.Damage,
				targetHealth = target.currentHealth,
				remainingEnergy = profile.Data.Stats.Energy,
			})
		end
	elseif action == "Flee" then
		local roll = math.random(1, 100)
		if roll <= 50 then
			TurnEvent:FireClient(player, "FleeSuccess")

			for i, ally in ipairs(battle.allies) do
				if ally == player then
					table.remove(battle.allies, i)
					break
				end
			end

			for i, e in ipairs(battle.turnOrder) do
				if e.type == "ally" and e.player == player then
					table.remove(battle.turnOrder, i)
					break
				end
			end
		else
			TurnEvent:FireClient(player, "FleeFailed")
			print(player.Name, "tentou fugir mas falhou")
		end
	end

	if CheckBattleEnd(battleId) then
		return
	end

	NextTurn(battleId)
end)
