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
local function NextTurn() end

BattleStartedEvent.Event:Connect(function(player)
	local BattlePlayers = { player.Name }
	print(BattlePlayers)
end)
