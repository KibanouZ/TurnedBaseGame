local EffectiveArea = game.Workspace:WaitForChild("EncounterStart"):WaitForChild("EffectiveArea")
local Player = game.Players.LocalPlayer
local Character = Player.Character
local Hrp = Character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")
EffectiveArea.Touched:Connect(function()
	RemoteEvent:FireServer()
end)
