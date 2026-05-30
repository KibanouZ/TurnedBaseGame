local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CombatGui = PlayerGui:WaitForChild("CombatGui", 10)
local FrameButtons = CombatGui:WaitForChild("Buttons")
local ButtonAttack = FrameButtons:WaitForChild("Attack")
local AttackFrame = CombatGui:WaitForChild("Attack")
local ButtonBack = AttackFrame:WaitForChild("BackButton")
local ButtonEscape = FrameButtons:WaitForChild("Escape")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Net.BattleRemotes)
local TurnEvent = Remotes.TurnEvent
local TurnActionEvent = Remotes.TurnActionEvent

-- CombatGuiHandler fica no client (UI local), não em ReplicatedStorage.Shared
local CombatGuiHandler = require(script.Parent.Parent.UI.Combat.CombatGuiHandler)
local gui = CombatGuiHandler.new()

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

ButtonEscape.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		TurnActionEvent:FireServer("Flee")
	end
end)

TurnEvent.OnClientEvent:Connect(function(action, data)
	if gui[action] then
		gui[action](gui, data)
	else
		warn("Evento não tratado:", action)
	end
end)
