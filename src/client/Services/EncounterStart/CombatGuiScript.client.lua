local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")
local TurnActionEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnActionEvent")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CombatGui = PlayerGui:WaitForChild("CombatGui", 10)
local VictoryFrame = CombatGui:WaitForChild("VictoryFrame")
-- Hp display variables
local BillBoardGui = nil
local EnemyFolder = nil
local Enemy1 = nil
local EnemyHealthStroke = nil
local BarFill = nil
local Hplabel = nil
-- Stroke variables
local Stroke = nil
-- Player Hp and Energy display variables
local MainBg = CombatGui:WaitForChild("MainBg")
local SecondMainBg = MainBg:WaitForChild("2MainBg")
local Bars = SecondMainBg:WaitForChild("bars")
local HealthStroke = Bars:WaitForChild("HealthStroke")
local EnergyStroke = Bars:WaitForChild("EnergyStroke")
local EnergyBar = EnergyStroke:WaitForChild("Energy")
local HealthBar = HealthStroke:WaitForChild("Health")
local LoseFrame = CombatGui:WaitForChild("LoseFrame")
local SelectEnemy = CombatGui:WaitForChild("SelectEnemy")
local EnemiesData = require(ReplicatedStorage.Shared.Services.Modules.EnemiesData)
local FrameButtons = CombatGui:WaitForChild("Buttons")
local ButtonAttack = FrameButtons:WaitForChild("Attack")
local ButtonItems = FrameButtons:WaitForChild("Items")
local ButtonEscape = FrameButtons:WaitForChild("Escape")
local AttackFrame = CombatGui:WaitForChild("Attack")
local ScrollFrame = AttackFrame:WaitForChild("ScrollingFrame")
local ButtonBack = AttackFrame:WaitForChild("BackButton")
local StatusTurn = CombatGui:WaitForChild("StatusTurn")
local StatusLabel = StatusTurn:WaitForChild("StatusLabel")

local playerMaxHealth = nil -- store player's max health for health bar updates

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

TurnEvent.OnClientEvent:Connect(function(action, data)
	if action == "Victory" then
		VictoryFrame.Visible = true
	elseif action == "StartBattle" then
		CombatGui.Enabled = true
		local BattleFolder = workspace:WaitForChild("Batalha de " .. Player.Name)
		EnemyFolder = BattleFolder:WaitForChild("EnemyFolder")
		Enemy1 = EnemyFolder:WaitForChild("Enemy1")

		-- Store player's max health for later use in health bar updates
		playerMaxHealth = data and data.maxHealth or 100

		-- Initialize player health barlocal barWidth = HealthStroke.AbsoluteSize.X
		local barWidth = HealthStroke.AbsoluteSize.X
		HealthBar.Size = UDim2.fromOffset(barWidth, 22)
		-- Create stroke around enemy
		Stroke = Instance.new("Highlight")
		Stroke.Parent = Enemy1
		Stroke.Name = "Highlight"
		Stroke.FillColor = Color3.new(1, 0, 0)
		Stroke.OutlineColor = Color3.new(1, 1, 1)
		Stroke.Enabled = false

		-- Create enemy health display
		BillBoardGui = Instance.new("BillboardGui")
		BillBoardGui.Parent = Enemy1
		BillBoardGui.Name = "HpDisplay"
		BillBoardGui.Size = UDim2.fromOffset(200, 50)
		BillBoardGui.StudsOffset = Vector3.new(0, 3, 0)

		EnemyHealthStroke = Instance.new("Frame")
		EnemyHealthStroke.Name = "EnemyHealthStroke"
		EnemyHealthStroke.Parent = BillBoardGui
		EnemyHealthStroke.Size = UDim2.fromOffset(200, 20)
		EnemyHealthStroke.BackgroundColor3 = Color3.new(0.12549, 0.12549, 0.12549)

		local enemyMaxHealth = EnemiesData["Enemy1"].MaxHealth

		BarFill = Instance.new("Frame")
		BarFill.Name = "BarFill"
		BarFill.Parent = EnemyHealthStroke
		BarFill.Size = UDim2.fromOffset(200, 20)
		BarFill.BackgroundColor3 = Color3.new(1, 0, 0)

		Hplabel = Instance.new("TextLabel")
		Hplabel.Name = "Hplabel"
		Hplabel.Parent = BillBoardGui
		Hplabel.Size = UDim2.fromOffset(200, 20)
		Hplabel.BackgroundTransparency = 1
		Hplabel.Text = enemyMaxHealth .. "/" .. enemyMaxHealth
	elseif action == "YourTurn" then
		print("Energia nesse round:" .. data.energy)
		FrameButtons.Visible = true
		StatusLabel.Text = "Your Turn"
		for _, attack in ipairs(data.attacks) do
			local attackButton = Instance.new("TextButton")
			print(attack)
			attackButton.Parent = ScrollFrame
			attackButton.Size = UDim2.new(0, 200, 0, 50)
			attackButton.Text = attack
			attackButton.Name = attack
			attackButton.MouseButton1Click:Connect(function()
				SelectEnemy.Visible = true
				for _, enemy in ipairs(EnemyFolder:GetChildren()) do
					local enemyButton = Instance.new("TextButton")
					enemyButton.Parent = SelectEnemy
					enemyButton.Size = UDim2.new(0, 200, 0, 50)
					enemyButton.Text = enemy.Name
					enemyButton.MouseEnter:Connect(function()
						Stroke.Enabled = true
					end)
					enemyButton.MouseLeave:Connect(function()
						Stroke.Enabled = false
					end)
					enemyButton.MouseButton1Click:Connect(function()
						TurnActionEvent:FireServer("Attack", {
							attackName = attack,
							targetName = enemy.Name,
						})
						SelectEnemy.Visible = false
						FrameButtons.Visible = false
						StatusLabel.Text = "Waiting for enemy turn..."
						for _, attackBtn in ipairs(ScrollFrame:GetChildren()) do
							if attackBtn:IsA("TextButton") then
								attackBtn:Destroy()
							end
						end
						for _, btn in ipairs(SelectEnemy:GetChildren()) do
							if btn:IsA("TextButton") then
								btn:Destroy()
							end
						end
					end)
				end
			end)
		end
	elseif action == "EnemyTurn" then
		FrameButtons.Visible = false
		StatusLabel.Text = "Enemy Turn"
	elseif action == "Attacked" then
		local damage = data.damage
		local attackName = data.attackName
		local remainingHealth = data.remainingHealth
		local maxHealth = data.maxHealth

		if maxHealth then
			playerMaxHealth = maxHealth
		end

		print("Damage received: " .. damage)
		print("Attack used: " .. attackName)
		print("Remaining health: " .. remainingHealth)
		print("Max health: " .. tostring(playerMaxHealth))

		StatusLabel.Text = "Enemy used " .. attackName .. " dealing " .. damage .. " damage!"

		if playerMaxHealth and playerMaxHealth > 0 then
			local barWidth = HealthStroke.AbsoluteSize.X
			HealthBar.Size = UDim2.fromOffset(barWidth * (remainingHealth / playerMaxHealth), 22)
		else
			warn("playerMaxHealth inválido:", playerMaxHealth)
		end
	elseif action == "AttackSuccess" then
		local enemyId = data.enemyId
		local targetHealth = data.targetHealth
		local remainingEnergy = data.remainingEnergy

		if EnemyFolder:FindFirstChild(enemyId) then
			local enemy = EnemyFolder:FindFirstChild(enemyId)
			if enemy then
				local hpDisplay = enemy:FindFirstChild("HpDisplay")
				if hpDisplay then
					local healthStroke = hpDisplay:FindFirstChild("EnemyHealthStroke")
					if healthStroke then
						local barFill = healthStroke:FindFirstChild("BarFill")
						if barFill then
							barFill.Size =
								UDim2.fromOffset(200 * (targetHealth / EnemiesData[enemy.Name].MaxHealth), 20)
						end
					end
					local hpLabel = hpDisplay:FindFirstChild("Hplabel")
					if hpLabel then
						hpLabel.Text = targetHealth .. "/" .. EnemiesData[enemy.Name].MaxHealth
					end
				end
			end
		end

		EnergyBar.Size = UDim2.fromOffset(200 * (remainingEnergy / 100), 20)
	elseif action == "NotEnoughEnergy" then
		StatusLabel.Text = "Not enough energy!"
	elseif action == "FleeSuccess" then
		CombatGui.Enabled = false
	elseif action == "FleeFailed" then
		StatusLabel.Text = "Couldn't escape!"
	elseif action == "Defeat" then
		StatusLabel.Text = "You were defeated..."
		LoseFrame.Visible = true
	end
end)
