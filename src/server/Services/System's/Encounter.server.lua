local EffectiveArea = game.Workspace:WaitForChild("EncounterStart"):WaitForChild("EffectiveArea")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PartyManager = require(ReplicatedStorage.Shared.Services.Modules.PartyManager)
local EnemiesData = require(ReplicatedStorage.Shared.Services.Modules.EnemiesData)
local EnemieSModels = ReplicatedStorage.Shared.Services.Enemies
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")
local ServerScriptService = game:GetService("ServerScriptService")
local BattleStartedEvent = ServerScriptService:WaitForChild("Server")
	:WaitForChild("Services")
	:WaitForChild("Events")
	:WaitForChild("BattleStartedEvent")
local debounce = false
local SpacingBetweenPlayers = 10
local EnemyDistance = 30
local enemyId = "Enemy1"

local function GetAllPartyMembers(leaderPlayer, memberIds)
	local members = { leaderPlayer }
	for _, id in ipairs(memberIds) do
		local member = game.Players:GetPlayerByUserId(id)
		if member and member ~= leaderPlayer and member.Character then
			table.insert(members, member)
		end
	end
	return members
end

local function PositionPartyFormation(members, leaderPosition, enemyPosition)
	local ForwardDir = (enemyPosition - leaderPosition).Unit

	local RightDir = ForwardDir:Cross(Vector3.new(0, 1, 0)).Unit

	local total = #members

	local startOffset = -((total - 1) / 2) * SpacingBetweenPlayers

	for i, member in ipairs(members) do
		local sideOffset = startOffset + (i - 1) * SpacingBetweenPlayers
		local targetPos = leaderPosition + RightDir * sideOffset

		if member.Character and member.Character:FindFirstChild("HumanoidRootPart") then
			targetPos = Vector3.new(targetPos.X, member.Character.HumanoidRootPart.Position.Y, targetPos.Z)

			local targetCFrame = CFrame.lookAt(targetPos, targetPos + ForwardDir)
			member.Character:PivotTo(targetCFrame)
		end
	end
end

local function SetPlayerFrozen(member, frozen)
	if member.Character then
		local humanoid = member.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = frozen and 0 or 16
			humanoid.JumpPower = frozen and 0 or 50
		end
	end
end

EffectiveArea.Touched:Connect(function(hit)
	if debounce then
		return
	end

	if hit.Parent:FindFirstChild("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end

		debounce = true
		print("1- Player encontrado:", player.Name)
		EffectiveArea.CanTouch = false

		local BattleFolder = Instance.new("Folder")
		BattleFolder.Name = "Batalha de " .. player.Name
		BattleFolder.Parent = game.Workspace

		local AllyFolder = game.Workspace:WaitForChild("AllyFolder")
		AllyFolder.Parent = BattleFolder
		local EnemyFolder = game.Workspace:WaitForChild("EnemyFolder")
		EnemyFolder.Parent = BattleFolder

		-- Mudar Futuramente para spawnar inimigos aleatórios
		local leaderPos = player.Character:WaitForChild("HumanoidRootPart").Position
		print("4 - Posição do líder:", leaderPos)
		local EnemyModel = EnemieSModels[enemyId]:Clone()
		EnemyModel.Parent = EnemyFolder
		local enemyPos = leaderPos + Vector3.new(0, 0, -EnemyDistance)
		print("5 - Inimigo posicionado")
		EnemyModel:PivotTo(CFrame.lookAt(enemyPos, leaderPos))

		local memberIds = PartyManager.GetMemberIds(player)
		print("2 - memberIds", memberIds)
		local allMembers = GetAllPartyMembers(player, memberIds)
		print("3 - allMembers", #allMembers)

		PositionPartyFormation(allMembers, leaderPos, enemyPos)
		print("6 - Formação posicionada")

		for _, member in ipairs(allMembers) do
			print("7 - Processando membro:", member.Name)
			member.Character.Parent = AllyFolder
			SetPlayerFrozen(member, true)
			RemoteEvent:FireClient(member, "StartBattle")
		end
		local enemyList = {
			{ id = enemyId },
		}

		print("8 - Batalha iniciando")
		BattleStartedEvent:Fire(player, enemyList)
	end
end)
