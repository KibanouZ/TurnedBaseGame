local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.BattleRemotes)
local TurnEvent = Remotes.TurnEvent
local TurnActionEvent = Remotes.TurnActionEvent
local BattleEvents = require(ServerScriptService.Server.Net.BattleEvents)
local BattleStartedEvent = BattleEvents.BattleStartedEvent
local PassToEncounterEvent = BattleEvents.PassToEncounterEvent

local Requires = require(Shared.Util.Requires)
local AttacksData = Requires.playerSkills()
local EnemiesData = Requires.enemyRegistry()
local EnemiesAttacksData = Requires.enemySkills()
local PartyManager = Requires.partyManager()
local DataManager = Requires.dataManager()
local ActiveBattles = {}

-- ================================================
-- BATTLE CLASS
-- ================================================

local Battle = {}
Battle.__index = Battle

local EnemyPool = {
	{ name = "UseAttack", chance = 0.50 },
	{ name = "UseSpecial", chance = 0.10 },
	{ name = "UseHeal", chance = 0.20 },
	{ name = "UseDebuff", chance = 0.10 },
	{ name = "UseBuff", chance = 0.10 },
	{ name = "UseFlee", chance = 0.00 },
}

function Battle.new(player, allies, enemies, turnOrder)
	local self = setmetatable({}, Battle)
	self.player = player
	self.allies = allies
	self.enemies = enemies
	self.turnOrder = turnOrder
	self.currentIndex = 1
	return self
end

-- ================================================
-- HELPERS
-- ================================================

function Battle:GetEnemy(enemyId)
	for _, enemy in ipairs(self.enemies) do
		if enemy.id == enemyId then
			return enemy
		end
	end
	return nil
end

function Battle:FireAllAllies(event, data)
	for _, ally in ipairs(self.allies) do
		TurnEvent:FireClient(ally, event, data)
	end
end

function Battle:ApplyCooldown(enemyState, attackName, attackData)
	if attackData.Cooldown and attackData.Cooldown > 0 then
		if not enemyState.AttackCooldowns then
			enemyState.AttackCooldowns = {}
		end
		enemyState.AttackCooldowns[attackName] = attackData.Cooldown
	end
end

-- ================================================
-- EFFECTS
-- ================================================

function Battle:ProcessEffects(profile, player)
	local i = 1
	while i <= #profile.Data.Effects do
		local effect = profile.Data.Effects[i]

		if effect.type == "Dot" then
			profile.Data.Stats.Health = math.max(0, profile.Data.Stats.Health - effect.DamagePerTurn)
			TurnEvent:FireClient(player, "DotDamage", {
				effectName = effect.name,
				damage = effect.DamagePerTurn,
				remainingHealth = profile.Data.Stats.Health,
				maxHealth = profile.Data.Stats.MaxHealth,
			})

			effect.duration -= 1
			if effect.duration <= 0 then
				table.remove(profile.Data.Effects, i)
				TurnEvent:FireClient(player, "EffectExpired", { effectName = effect.name })
			else
				i += 1
			end
		else
			i += 1
		end
	end
end

-- ================================================
-- CHECK BATTLE END
-- ================================================

function Battle:CheckBattleEnd(battleId)
	local allEnemiesDead = true
	for _, enemy in ipairs(self.enemies) do
		if enemy.currentHealth > 0 then
			allEnemiesDead = false
			break
		end
	end

	local allAlliesDead = true
	for _, ally in ipairs(self.allies) do
		local profile = DataManager.Profiles[ally.UserId]
		if profile then
			if profile.Data.Stats.Health > 0 then
				allAlliesDead = false
			else
				profile.Data.Stats.Health = 0
			end
		end
	end

	if allEnemiesDead then
		self:FireAllAllies("Victory", {})
		PassToEncounterEvent:Fire(self.allies)
		ActiveBattles[battleId] = nil
		return true
	elseif allAlliesDead then
		self:FireAllAllies("Defeat", {})
		PassToEncounterEvent:Fire(self.allies)
		ActiveBattles[battleId] = nil
		return true
	end

	return false
end

-- ================================================
-- ENEMY ACTION HANDLERS
-- ================================================

function Battle:UseAttack(entity, enemyState)
	local enemyData = EnemiesData[entity.id]
	local validAttacks = {}

	for _, attackName in ipairs(enemyData.Attacks) do
		local attackData = EnemiesAttacksData[attackName]
		if attackData and attackData.ActionType == "Attack" then
			local cooldown = enemyState.AttackCooldowns and enemyState.AttackCooldowns[attackName]
			if not cooldown or cooldown <= 0 then
				table.insert(validAttacks, attackName)
			end
		end
	end

	if #validAttacks == 0 then
		return false
	end

	local attackName = validAttacks[math.random(1, #validAttacks)]
	local attackData = EnemiesAttacksData[attackName]

	if attackData.EnergyCost and enemyState.Energy < attackData.EnergyCost then
		return false
	end

	local target = self.allies[math.random(1, #self.allies)]
	if not target then
		return false
	end

	local profile = DataManager.Profiles[target.UserId]
	if not profile then
		return false
	end

	profile.Data.Stats.Health = math.max(0, profile.Data.Stats.Health - attackData.Damage)
	TurnEvent:FireClient(target, "Attacked", {
		damage = attackData.Damage,
		attackName = attackName,
		attackType = attackData.Type,
		DotType = attackData.Dot,
		remainingHealth = profile.Data.Stats.Health,
		maxHealth = profile.Data.Stats.MaxHealth,
	})

	self:ApplyCooldown(enemyState, attackName, attackData)
	return true
end

function Battle:UseSpecial(entity, enemyState)
	local enemyData = EnemiesData[entity.id]
	local validAttacks = {}

	for _, attackName in ipairs(enemyData.Attacks) do
		local attackData = EnemiesAttacksData[attackName]
		if attackData and attackData.ActionType == "AttackSpecial" then
			local cooldown = enemyState.AttackCooldowns and enemyState.AttackCooldowns[attackName]
			if not cooldown or cooldown <= 0 then
				table.insert(validAttacks, attackName)
			end
		end
	end

	if #validAttacks == 0 then
		return false
	end

	local attackName = validAttacks[math.random(1, #validAttacks)]
	local attackData = EnemiesAttacksData[attackName]

	if attackData.EnergyCost and enemyState.Energy < attackData.EnergyCost then
		return false
	end

	local target = self.allies[math.random(1, #self.allies)]
	if not target then
		return false
	end

	local profile = DataManager.Profiles[target.UserId]
	if not profile then
		return false
	end

	profile.Data.Stats.Health = math.max(0, profile.Data.Stats.Health - attackData.Damage)
	TurnEvent:FireClient(target, "Attacked", {
		damage = attackData.Damage,
		attackName = attackName,
		remainingHealth = profile.Data.Stats.Health,
		maxHealth = profile.Data.Stats.MaxHealth,
	})

	self:ApplyCooldown(enemyState, attackName, attackData)
	return true
end

function Battle:UseHeal(entity, enemyState)
	local enemyData = EnemiesData[entity.id]
	local validAttacks = {}

	for _, attackName in ipairs(enemyData.Attacks) do
		local attackData = EnemiesAttacksData[attackName]
		if attackData and attackData.ActionType == "Heal" then
			local cooldown = enemyState.AttackCooldowns and enemyState.AttackCooldowns[attackName]
			if not cooldown or cooldown <= 0 then
				table.insert(validAttacks, attackName)
			end
		end
	end

	if #validAttacks == 0 then
		return false
	end

	local attackName = validAttacks[math.random(1, #validAttacks)]
	local attackData = EnemiesAttacksData[attackName]

	if attackData.EnergyCost and enemyState.Energy < attackData.EnergyCost then
		return false
	end

	local enemy = self:GetEnemy(entity.id)
	if not enemy then
		return false
	end

	enemy.currentHealth = math.min(enemy.currentHealth + attackData.Heal, enemyData.MaxHealth)

	self:FireAllAllies("EnemyHealed", {
		enemyId = entity.id,
		healAmount = attackData.Heal,
		currentHealth = enemy.currentHealth,
		maxHealth = enemyData.MaxHealth,
		attackName = attackName,
	})

	self:ApplyCooldown(enemyState, attackName, attackData)
	return true
end

function Battle:UseDebuff(entity, enemyState)
	local enemyData = EnemiesData[entity.id]
	local validAttacks = {}

	for _, attackName in ipairs(enemyData.Attacks) do
		local attackData = EnemiesAttacksData[attackName]
		if attackData and attackData.ActionType == "Debuff" then
			local cooldown = enemyState.AttackCooldowns and enemyState.AttackCooldowns[attackName]
			if not cooldown or cooldown <= 0 then
				table.insert(validAttacks, attackName)
			end
		end
	end

	if #validAttacks == 0 then
		return false
	end

	local attackName = validAttacks[math.random(1, #validAttacks)]
	local attackData = EnemiesAttacksData[attackName]

	if attackData.EnergyCost and enemyState.Energy < attackData.EnergyCost then
		return false
	end

	local target = self.allies[math.random(1, #self.allies)]
	if not target then
		return false
	end

	local profile = DataManager.Profiles[target.UserId]
	if not profile then
		return false
	end

	if attackData.Type == "Dot" then
		table.insert(profile.Data.Effects, {
			name = attackName,
			type = "Dot",
			duration = attackData.Effect.Duration,
			DamagePerTurn = attackData.Effect.DamagePerTurn,
		})
	end

	profile.Data.Stats.Health = math.max(0, profile.Data.Stats.Health - attackData.Damage)
	TurnEvent:FireClient(target, "Debuff", {
		damage = attackData.Damage,
		attackName = attackName,
		DotType = attackData.Dot,
		duration = attackData.Effect and attackData.Effect.Duration,
		remainingHealth = profile.Data.Stats.Health,
		maxHealth = profile.Data.Stats.MaxHealth,
	})

	self:ApplyCooldown(enemyState, attackName, attackData)
	return true
end

function Battle:UseBuff(entity, enemyState)
	local enemyData = EnemiesData[entity.id]
	local validAttacks = {}

	for _, attackName in ipairs(enemyData.Attacks) do
		local attackData = EnemiesAttacksData[attackName]
		if attackData and attackData.ActionType == "Buff" then
			local cooldown = enemyState.AttackCooldowns and enemyState.AttackCooldowns[attackName]
			if not cooldown or cooldown <= 0 then
				table.insert(validAttacks, attackName)
			end

			if attackData.Threshold then
				local enemy = self:GetEnemy(entity.id)
				local healthPercent = enemy.currentHealth / enemyData.MaxHealth
				if healthPercent > attackData.Threshold then
					return false
				end
			end
		end
	end

	if #validAttacks == 0 then
		return false
	end

	local attackName = validAttacks[math.random(1, #validAttacks)]
	local attackData = EnemiesAttacksData[attackName]

	if attackData.EnergyCost and enemyState.Energy < attackData.EnergyCost then
		return false
	end

	local enemy = self:GetEnemy(entity.id)
	if not enemy then
		return false
	end

	if not enemy.activeBuffs then
		enemy.activeBuffs = {}
	end
	table.insert(enemy.activeBuffs, {
		name = attackName,
		damageBonus = attackData.Effect.DamageIncrease,
		duration = attackData.Effect.Duration,
	})

	self:FireAllAllies("EnemyBuffed", {
		enemyId = entity.id,
		attackName = attackName,
		duration = attackData.Effect.Duration,
	})

	self:ApplyCooldown(enemyState, attackName, attackData)
	return true
end

function Battle:UseFlee(entity, enemyState)
	print("Inimigo tentou fugir")
	return true
end

-- ================================================
-- EXECUTE ENEMY TURN
-- ================================================

function Battle:ExecuteEnemyTurn(battleId)
	local entity = self.turnOrder[self.currentIndex]
	local enemy = self:GetEnemy(entity.id)
	if not enemy then
		return
	end

	if not enemy.Energy then
		enemy.Energy = 0
	end
	enemy.Energy += 3

	-- decrementa cooldowns
	if enemy.AttackCooldowns then
		for attackName, turns in pairs(enemy.AttackCooldowns) do
			if turns > 0 then
				enemy.AttackCooldowns[attackName] = turns - 1
			end
		end
	end

	local triedActions = {}

	local function ChooseAction()
		local availablePool = {}
		for _, actionData in ipairs(EnemyPool) do
			if not triedActions[actionData.name] then
				table.insert(availablePool, actionData)
			end
		end

		if #availablePool == 0 then
			return nil
		end

		local total = 0
		for _, actionData in ipairs(availablePool) do
			total = total + actionData.chance
		end

		local roll = math.random() * total
		local accumulated = 0
		for _, actionData in ipairs(availablePool) do
			accumulated = accumulated + actionData.chance
			if roll <= accumulated then
				return actionData.name
			end
		end

		return availablePool[#availablePool].name
	end

	local chosenAction = ChooseAction()

	for _ = 1, #EnemyPool do
		if not chosenAction then
			break
		end

		local handler = self[chosenAction]
		if handler then
			local success = handler(self, entity, enemy)
			if success then
				break
			end
		end

		triedActions[chosenAction] = true
		chosenAction = ChooseAction()
	end

	task.wait(1.5)

	if self:CheckBattleEnd(battleId) then
		return
	end
	self:NextTurn(battleId)
end

-- ================================================
-- START TURN / NEXT TURN
-- ================================================

function Battle:NextTurn(battleId)
	self.currentIndex += 1
	if self.currentIndex > #self.turnOrder then
		self.currentIndex = 1
	end
	self:StartTurn(battleId)
end

function Battle:StartTurn(battleId)
	local entity = self.turnOrder[self.currentIndex]

	if entity.type == "ally" then
		local profile = DataManager.Profiles[entity.player.UserId]
		if not profile then
			return
		end

		self:ProcessEffects(profile, entity.player)

		if self:CheckBattleEnd(battleId) then
			return
		end

		-- decrementa cooldowns do player
		for attackName, turns in pairs(profile.Data.AttackCooldowns) do
			if turns > 0 then
				profile.Data.AttackCooldowns[attackName] = turns - 1
			end
		end

		profile.Data.Stats.Energy += 1

		TurnEvent:FireClient(entity.player, "YourTurn", {
			attacks = profile.Data.Attacks,
			energy = profile.Data.Stats.Energy,
			maxEnergy = profile.Data.Stats.MaxEnergy,
		})
	elseif entity.type == "enemy" then
		task.wait(1)
		self:ExecuteEnemyTurn(battleId)
	end
end

-- ================================================
-- ACTIVE BATTLES
-- ================================================

local function GetPlayerSpeed(player)
	local profile = DataManager.Profiles[player.UserId]
	return profile and profile.Data.Stats.Speed or 5
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
			speed = EnemiesData[enemy.id].Speed,
		})
	end

	table.sort(allEntities, function(a, b)
		return a.speed > b.speed
	end)

	return allEntities
end

-- ================================================
-- BATTLE STARTED
-- ================================================

BattleStartedEvent.Event:Connect(function(player, enemyList)
	local memberIds = PartyManager.GetMemberIds(player)
	local allies = { player }

	for _, id in ipairs(memberIds) do
		local member = Players:GetPlayerByUserId(id)
		if member and member ~= player then
			table.insert(allies, member)
		end
	end

	for _, ally in ipairs(allies) do
		local profile = DataManager.Profiles[ally.UserId]
		if profile then
			profile.Data.Stats.Energy = 0
			profile.Data.Stats.Health = profile.Data.Stats.MaxHealth
			profile.Data.Effects = {}
			profile.Data.AttackCooldowns = {}
		end
	end

	local enemies = {}
	for _, enemy in ipairs(enemyList) do
		table.insert(enemies, {
			id = enemy.id,
			currentHealth = EnemiesData[enemy.id].MaxHealth,
			Energy = 0,
			activeBuffs = {},
			AttackCooldowns = {},
		})
	end

	local turnOrder = BuildTurnOrder(allies, enemies)
	local battle = Battle.new(player, allies, enemies, turnOrder)
	ActiveBattles[player.UserId] = battle

	battle:StartTurn(player.UserId)
end)

-- ================================================
-- TURN ACTION EVENT
-- ================================================

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

			local cooldown = profile.Data.AttackCooldowns[attackName]
			if cooldown and cooldown > 0 then
				TurnEvent:FireClient(player, "OnCooldown", {
					attackName = attackName,
					turnsLeft = cooldown,
				})
				return
			end

			profile.Data.Stats.Energy -= attackData.EnergyCost
			target.currentHealth = math.max(0, target.currentHealth - attackData.Damage)

			if attackData.Cooldown and attackData.Cooldown > 0 then
				profile.Data.AttackCooldowns[attackName] = attackData.Cooldown
			end

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
		end
	end

	if battle:CheckBattleEnd(battleId) then
		return
	end
	battle:NextTurn(battleId)
end)
