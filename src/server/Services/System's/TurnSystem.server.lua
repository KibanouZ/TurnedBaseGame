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

local EnemiesData = require(ReplicatedStorage.Shared.Services.Modules.EnemiesData)
local PartyManager = require(ReplicatedStorage.Shared.Services.Modules.PartyManager)
local DataManager = require(ServerScriptService.Server.Data.DataManager)
local StartTurn
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
			currentHealth = enemy.currentHealth,
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
BattleStartedEvent.Event:Connect(function(player, enemyList)
	local memberIds = PartyManager.GetMemberIds(player)
	local allies = { player }
	for _, id in ipairs(memberIds) do
		local member = Players:GetPlayerByUserId(id)
		if member and member ~= player then
			table.insert(allies, member)
		end
	end

	-- 1 enemy for test
	local enemies = {}
	for _, enemy in ipairs(enemyList) do
		table.insert(enemies, {
			id = enemy.id,
			currentHealth = EnemiesData[enemy.id].MaxHealth,
		})
	end
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

	StartTurn(player.UserId)
end)
local function CheckBattleEnd(battleId)
	local battle = ActiveBattles[battleId]
	if not battle then
		return
	end

	-- Verifica se todos os inimigos morreram
	local allEnemiesDead = true
	for _, enemy in ipairs(battle.enemies) do
		if enemy.currentHealth > 0 then
			allEnemiesDead = false
			break
		end
	end

	-- Verifica se todos os allies morreram ou fugiram
	local allAlliesDead = #battle.allies == 0
	for _, ally in ipairs(battle.allies) do
		local profile = DataManager.Profiles[ally.UserId]
		if profile and profile.Data.Stats.Health > 0 then
			allAlliesDead = false
			break
		end
	end

	if allEnemiesDead then
		-- Vitória
		for _, ally in ipairs(battle.allies) do
			TurnEvent:FireClient(ally, "Victory")
		end
		ActiveBattles[battleId] = nil
		return true
	elseif allAlliesDead then
		-- Derrota
		for _, ally in ipairs(battle.allies) do
			TurnEvent:FireClient(ally, "Defeat")
		end
		ActiveBattles[battleId] = nil
		return true
	end

	return false
end
local function NextTurn(battleId)
	local battle = ActiveBattles[battleId]
	if not battle then
		return
	end

	-- Avança o índice, volta pro começo se chegou no fim
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

	-- IA escolhe o ally com menos HP
	local target = nil
	local lowestHp = math.huge
	for _, ally in ipairs(battle.allies) do
		local profile = DataManager.Profiles[ally.UserId]
		if profile then
			local hp = profile.Data.Stats.Health
			if hp < lowestHp then
				lowestHp = hp
				target = ally
			end
		end
	end

	if not target then
		NextTurn(battleId)
		return
	end

	-- Aplica dano
	local damage = EnemiesData[entity.id].Damage
	local profile = DataManager.Profiles[target.UserId]
	profile.Data.Stats.Health = math.max(0, profile.Data.Stats.Health - damage)

	-- Avisa o cliente que tomou dano
	TurnEvent:FireClient(target, "EnemyAttacked", {
		enemyId = entity.id,
		damage = damage,
		targetHealth = profile.Data.Stats.Health,
	})

	print(entity.id, "atacou", target.Name, "por", damage, "de dano")

	task.wait(1.5) -- delay para parecer natural

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
		-- Avisa o player que é sua vez
		TurnEvent:FireClient(entity.player, "YourTurn")
		print("Turno de:", entity.player.Name)
	elseif entity.type == "enemy" then
		print("Turno do inimigo:", entity.id)
		task.wait(1) -- pequeno delay antes do inimigo agir
		ExecuteEnemyTurn(battleId)
	end
end
TurnActionEvent.OnServerEvent:Connect(function(player, action)
	-- Acha a batalha do player
	local battleId = player.UserId
	local battle = ActiveBattles[battleId]
	if not battle then
		return
	end

	-- Valida se é o turno desse player
	local entity = battle.turnOrder[battle.currentIndex]
	if entity.type ~= "ally" or entity.player ~= player then
		return -- não é o turno dele, ignora
	end

	if action == "Attack" then
		-- Ataca o primeiro inimigo vivo
		local target = nil
		for _, enemy in ipairs(battle.enemies) do
			if enemy.currentHealth > 0 then
				target = enemy
				break
			end
		end

		if target then
			local profile = DataManager.Profiles[player.UserId]
			local damage = profile.Data.Stats.Stregth -- mesmo nome do template
			target.currentHealth = math.max(0, target.currentHealth - damage)

			TurnEvent:FireClient(player, "AttackResult", {
				damage = damage,
				targetHealth = target.currentHealth,
			})

			print(player.Name, "atacou", target.id, "por", damage, "de dano")
		end
	elseif action == "Flee" then
		local roll = math.random(1, 100)
		if roll <= 50 then
			-- Fugiu com sucesso
			TurnEvent:FireClient(player, "FleeSuccess")
			-- Remove o player dos allies
			for i, ally in ipairs(battle.allies) do
				if ally == player then
					table.remove(battle.allies, i)
					break
				end
			end
			-- Remove da ordem de turnos
			for i, e in ipairs(battle.turnOrder) do
				if e.type == "ally" and e.player == player then
					table.remove(battle.turnOrder, i)
					break
				end
			end
		else
			-- Fuga falhou
			TurnEvent:FireClient(player, "FleeFailed")
			print(player.Name, "tentou fugir mas falhou")
		end
	end

	if CheckBattleEnd(battleId) then
		return
	end
	NextTurn(battleId)
end)
