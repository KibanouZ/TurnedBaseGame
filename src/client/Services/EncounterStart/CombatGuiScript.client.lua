local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CombatGui = PlayerGui:WaitForChild("CombatGui", 10)
TurnEvent.OnClientEvent:Connect(function(action)
	if action == "StartBattle" then
		CombatGui.Enabled = true
	end
end)
local FrameButtons = CombatGui:WaitForChild("Buttons")
local ButtonAttack = FrameButtons:WaitForChild("Attack")
local ButtonItems = FrameButtons:WaitForChild("Items")
local ButtonEscape = FrameButtons:WaitForChild("Escape")
local AttackFrame = CombatGui:WaitForChild("Attack")
local ButtonBack = AttackFrame:WaitForChild("BackButton")
ButtonAttack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		AttackFrame.Visible = true
	end
end)
ButtonBack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		AttackFrame.Visible = false
	end
end)
