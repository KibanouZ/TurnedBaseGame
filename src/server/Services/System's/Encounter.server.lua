local EffectiveArea = game.Workspace:WaitForChild("EncounterStart"):WaitForChild("EffectiveArea")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemiesData = require(ReplicatedStorage.Shared.Services.Modules.EnemiesData)
local EnemieSModels = ReplicatedStorage.Shared.Services.Enemies
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")

local debounce = false
EffectiveArea.Touched:Connect(function(hit)
	if debounce then
		return
	end
	EffectiveArea.CanTouch = false
	if hit.Parent:FindFirstChild("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			debounce = true
			RemoteEvent:FireClient(player)
			EffectiveArea.CanTouch = false
			local BattleFolder = Instance.new("Folder")
			BattleFolder.Parent = game.Workspace
			BattleFolder.Name = "Batalha de " .. player.Name
			local AllyFolder = game.Workspace:WaitForChild("AllyFolder")
			AllyFolder.Parent = BattleFolder
			local EnemyFolder = game.Workspace:WaitForChild("EnemyFolder")
			EnemyFolder.Parent = BattleFolder
			player.Character.Parent = AllyFolder
			local EnemyModel = EnemieSModels.Enemy1:Clone()
			EnemyModel.Parent = EnemyFolder
			local STATS = EnemiesData["Enemy1"]
			print(STATS.MaxHealth)
		end
	end
end)
