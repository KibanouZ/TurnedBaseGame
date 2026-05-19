local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CombatGui = PlayerGui:WaitForChild("CombatGui", 10)
-- Hp display variables
local EnemyFolder = nil
local Enemy1 = nil
local EnemyHealthLabel = nil
local BarFill = nil
local Hplabel = nil
local EnemiesData = require(ReplicatedStorage.Shared.Services.Modules.EnemiesData)
local FrameButtons = CombatGui:WaitForChild("Buttons")
local ButtonAttack = FrameButtons:WaitForChild("Attack")
local ButtonItems = FrameButtons:WaitForChild("Items")
local ButtonEscape = FrameButtons:WaitForChild("Escape")
local AttackFrame = CombatGui:WaitForChild("Attack")
local ButtonBack = AttackFrame:WaitForChild("BackButton")
local StatusTurn = CombatGui:WaitForChild("StatusTurn")
local StatusLabel = StatusTurn:WaitForChild("StatusLabel")
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
TurnEvent.OnClientEvent:Connect(function(action)
	if action == "StartBattle" then
		CombatGui.Enabled = true
		local BattleFolder = workspace:WaitForChild("Batalha de " .. Player.Name)
		EnemyFolder = BattleFolder:WaitForChild("EnemyFolder")
		Enemy1 = EnemyFolder:WaitForChild("Enemy1")
		local BillBoardGui = Enemy1:WaitForChild("BillboardGui")
		print(BillBoardGui)
		EnemyHealthLabel = BillBoardGui:WaitForChild("GrayBg")
		BarFill = EnemyHealthLabel:WaitForChild("Hp")
		Hplabel = BillBoardGui:WaitForChild("HpLabel")
		Hplabel.Text = EnemiesData["Enemy1"].Health .. "/" .. EnemiesData["Enemy1"].MaxHealth
	end
	if action == "YourTurn" then
		FrameButtons.Visible = true
		StatusLabel.Text = "Your Turn"
	elseif action == "EnemyTurn" then
		FrameButtons.Visible = false
		StatusLabel.Text = "Enemy Turn"
	elseif action == "AttackResult" then
		-- Update enemy health display
		print("oi")
	end
end)
