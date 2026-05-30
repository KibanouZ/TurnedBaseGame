local EffectiveArea = game.Workspace:WaitForChild("EncounterStart"):WaitForChild("EffectiveArea")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Requires = require(Shared.Util.Requires)
local PartyManager = Requires.partyManager()
local EnemiesData = Requires.enemyRegistry()
local ServicesFolder = Shared:WaitForChild("Services")
local Battles = game.Workspace:WaitForChild("Battles")
local HttpService = game:GetService("HttpService")
local EnemieSModels = Shared:WaitForChild("Assets"):WaitForChild("Enemies")
if not EnemieSModels then
	warn("[EncounterService] Pasta ReplicatedStorage.Shared.Services.Enemies não encontrada. ")
end
local Remotes = require(Shared.Net.BattleRemotes)
local RemoteEvent = Remotes.TurnEvent
local DataManager = Requires.dataManager()
local BattleEvents = require(ServerScriptService.Server.Net.BattleEvents)
local BattleStartedEvent = BattleEvents.BattleStartedEvent
local PassToEncounterEvent = BattleEvents.PassToEncounterEvent
local ActiveBattles = {}
local debounce = {}
local SpacingBetweenPlayers = 10
local EnemyDistance = 30
local enemyId = "Enemy1"
local connection
--Helpers

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

--mudar algum dia para spawnar inimigos aleatórios, talvez usando um sistema de níveis ou algo do tipo
EffectiveArea.Touched:Connect(function(hit)
	if hit.Name ~= "HumanoidRootPart" then
		return
	end
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)

	if not player then
		return
	end

	if debounce[player] then
		return
	end

	if hit.Parent:FindFirstChild("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end

		debounce[player] = true
		print("1- Player encontrado:", player.Name)
		EffectiveArea.CanTouch = false

		local BattleFolder = Instance.new("Folder")
		local battleId = "battle_" .. HttpService:GenerateGUID(false)
		BattleFolder.Name = battleId
		BattleFolder:SetAttribute("BattleId", battleId)
		BattleFolder.Parent = Battles
		ActiveBattles[battleId] = {
			Id = battleId,
			Folder = BattleFolder,
			Players = {},
			Enemies = {},
			State = "starting",
		}

		local AllyFolder = Instance.new("Folder")
		AllyFolder.Name = "AllyFolder"
		AllyFolder.Parent = BattleFolder
		local EnemyFolder = Instance.new("Folder")
		EnemyFolder.Name = "EnemyFolder"
		EnemyFolder.Parent = BattleFolder

		-- Mudar Futuramente para spawnar inimigos aleatórios
		local leaderPos = player.Character:WaitForChild("HumanoidRootPart").Position

		if not EnemieSModels or not EnemieSModels:FindFirstChild(enemyId) then
			warn("[EncounterService] Modelo de inimigo não encontrado:", enemyId)
			EffectiveArea.CanTouch = true
			debounce[player] = nil
			return
		end
		local EnemyModel = EnemieSModels[enemyId]:Clone()
		EnemyModel.Parent = EnemyFolder
		local enemyPos = leaderPos + Vector3.new(0, 0, -EnemyDistance)

		EnemyModel:PivotTo(CFrame.lookAt(enemyPos, leaderPos))

		local memberIds = PartyManager.GetMemberIds(player)

		local allMembers = GetAllPartyMembers(player, memberIds)

		PositionPartyFormation(allMembers, leaderPos, enemyPos)

		for _, member in ipairs(allMembers) do
			member.Character.Parent = AllyFolder
			SetPlayerFrozen(member, true)
			local profile = DataManager.Profiles[member.UserId]
			local maxHealth = profile and profile.Data.Stats.MaxHealth or 25

			RemoteEvent:FireClient(member, "StartBattle", {
				maxHealth = maxHealth,
			})
		end
		local enemyList = {
			{ id = enemyId },
		}

		BattleStartedEvent:Fire(player, enemyList)

		connection = PassToEncounterEvent.Event:Connect(function(allies)
			for _, member in ipairs(allies) do
				SetPlayerFrozen(member, false)

				if member.Character then
					member.Character.Parent = workspace
				end
			end
			debounce[player] = nil
			EffectiveArea.CanTouch = true
			BattleFolder:Destroy()
			connection:Disconnect()
		end)
	end
end)
