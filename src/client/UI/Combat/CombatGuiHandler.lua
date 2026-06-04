-- CombatGuiHandler.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CombatGui = PlayerGui:WaitForChild("CombatGui", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local TurnActionEvent = require(Shared.Net.BattleRemotes).TurnActionEvent
local EnemiesData = require(Shared.Definitions.Enemies.EnemyRegistry)
local Remotes = require(Shared.Net.BattleRemotes)
local TurnEvent = Remotes.TurnEvent
-- ================================================
-- UI REFERENCES
-- ================================================

local VictoryGui = PlayerGui:WaitForChild("VictoryGui", 10)
local VictoryFrame = VictoryGui:WaitForChild("VictoryFrame")
local LoseFrame = CombatGui:WaitForChild("LoseFrame")
local MainBg = CombatGui:WaitForChild("MainBg")
local SecondMainBg = MainBg:WaitForChild("2MainBg")
local Bars = SecondMainBg:WaitForChild("bars")
local HealthStroke = Bars:WaitForChild("HealthStroke")
local EnergyStroke = Bars:WaitForChild("EnergyStroke")
local EnergyBar = EnergyStroke:WaitForChild("Energy")
local HealthBar = HealthStroke:WaitForChild("Health")
local SelectEnemy = CombatGui:WaitForChild("SelectEnemy")
local FrameButtons = CombatGui:WaitForChild("Buttons")
local AttackFrame = CombatGui:WaitForChild("Attack")
local ScrollFrame = AttackFrame:WaitForChild("ScrollingFrame")
local StatusTurn = CombatGui:WaitForChild("StatusTurn")
local StatusLabel = StatusTurn:WaitForChild("StatusLabel")
local DotFrame = CombatGui:WaitForChild("Effects")
local PoisonLabel = DotFrame:WaitForChild("Poison")

-- ================================================
-- COMBAT GUI CLASS
-- ================================================

local CombatGuiHandler = {}
CombatGuiHandler.__index = CombatGuiHandler

function CombatGuiHandler.new()
	local self = setmetatable({}, CombatGuiHandler)
	self.playerMaxHealth = nil
	self.playerMaxEnergy = nil
	self.EnemyFolder = nil
	self.Stroke = nil
	return self
end

-- ================================================
-- HELPERS
-- ================================================
function CombatGuiHandler:CleanupEnemyHpDisplays()
	if self.EnemyFolder then
		for _, enemy in ipairs(self.EnemyFolder:GetChildren()) do
			local hpDisplay = enemy:FindFirstChild("HpDisplay")
			if hpDisplay then
				hpDisplay:Destroy()
			end
		end
	end
end
function CombatGuiHandler:UpdateEnemyHealthBar(enemyId, currentHealth)
	if not self.EnemyFolder then
		return
	end
	local enemy = self.EnemyFolder:FindFirstChild(enemyId)
	if not enemy then
		return
	end

	local hpDisplay = enemy:FindFirstChild("HpDisplay")
	if not hpDisplay then
		return
	end

	local healthStroke = hpDisplay:FindFirstChild("EnemyHealthStroke")
	if healthStroke then
		local barFill = healthStroke:FindFirstChild("BarFill")
		if barFill then
			barFill.Size = UDim2.fromOffset(200 * (currentHealth / EnemiesData[enemy.Name].MaxHealth), 20)
		end
	end

	local hpLabel = hpDisplay:FindFirstChild("Hplabel")
	if hpLabel then
		print("atualizando")
		hpLabel.Text = currentHealth .. "/" .. EnemiesData[enemy.Name].MaxHealth
	end
end

function CombatGuiHandler:UpdatePlayerHealthBar(remainingHealth)
	if self.playerMaxHealth and self.playerMaxHealth > 0 then
		local barWidth = HealthStroke.AbsoluteSize.X
		HealthBar.Size = UDim2.fromOffset(barWidth * (remainingHealth / self.playerMaxHealth), 22)
	end
end

function CombatGuiHandler:UpdateEnergyBar(remainingEnergy)
	if self.playerMaxEnergy and self.playerMaxEnergy > 0 then
		local energyBarWidth = EnergyStroke.AbsoluteSize.X
		EnergyBar.Size = UDim2.fromOffset(energyBarWidth * (remainingEnergy / self.playerMaxEnergy), 22)
	end
end

function CombatGuiHandler:CreateEnemyHpDisplay(enemy)
	local enemyMaxHealth = EnemiesData[enemy.Name].MaxHealth

	local BillBoardGui = Instance.new("BillboardGui")
	BillBoardGui.Parent = enemy
	BillBoardGui.Name = "HpDisplay"
	BillBoardGui.Size = UDim2.fromOffset(200, 50)
	BillBoardGui.StudsOffset = Vector3.new(0, 3, 0)

	local EnemyHealthStroke = Instance.new("Frame")
	EnemyHealthStroke.Name = "EnemyHealthStroke"
	EnemyHealthStroke.Parent = BillBoardGui
	EnemyHealthStroke.Size = UDim2.fromOffset(200, 20)
	EnemyHealthStroke.BackgroundColor3 = Color3.new(0.12549, 0.12549, 0.12549)

	local BarFill = Instance.new("Frame")
	BarFill.Name = "BarFill"
	BarFill.Parent = EnemyHealthStroke
	BarFill.Size = UDim2.fromOffset(200, 20)
	BarFill.BackgroundColor3 = Color3.new(1, 0, 0)

	local Hplabel = Instance.new("TextLabel")
	Hplabel.Name = "Hplabel"
	Hplabel.TextColor3 = Color3.new(1, 1, 1)
	Hplabel.Parent = BillBoardGui
	Hplabel.Size = UDim2.fromOffset(200, 20)
	Hplabel.BackgroundTransparency = 1
	Hplabel.Text = enemyMaxHealth .. "/" .. enemyMaxHealth
end

function CombatGuiHandler:CreateEnemyHighlight(enemy)
	self.Stroke = Instance.new("Highlight")
	self.Stroke.Parent = enemy
	self.Stroke.Name = "Highlight"
	self.Stroke.FillColor = Color3.new(1, 0, 0)
	self.Stroke.OutlineColor = Color3.new(1, 1, 1)
	self.Stroke.Enabled = false
end

function CombatGuiHandler:CleanupButtons()
	for _, btn in ipairs(ScrollFrame:GetChildren()) do
		if btn:IsA("TextButton") then
			btn:Destroy()
		end
	end
	for _, btn in ipairs(SelectEnemy:GetChildren()) do
		if btn:IsA("TextButton") then
			btn:Destroy()
		end
	end
end

-- ================================================
-- HANDLERS
-- ================================================

function CombatGuiHandler:Victory(data)
	VictoryFrame.Visible = true
	CombatGui.Enabled = false
end

function CombatGuiHandler:Defeat(data)
	LoseFrame.Visible = true
	StatusLabel.Text = "You were defeated..."
end

function CombatGuiHandler:FleeSuccess(data)
	CombatGui.Enabled = false
end

function CombatGuiHandler:FleeFailed(data)
	StatusLabel.Text = "Couldn't escape!"
end

function CombatGuiHandler:NotEnoughEnergy(data)
	StatusLabel.Text = "Not enough energy!"
end

function CombatGuiHandler:OnCooldown(data)
	StatusLabel.Text = data.attackName .. " está em cooldown por " .. data.turnsLeft .. " turnos!"
end

function CombatGuiHandler:StartBattle(data)
	print("StartBattle received for battleId: " .. tostring(data.battleId))
	CombatGui.Enabled = true
	battleId = data.battleId
	local Battles = workspace:WaitForChild("Battles")
	local BattleFolder = Battles:WaitForChild(tostring(battleId))
	self.EnemyFolder = BattleFolder:WaitForChild("EnemyFolder")
	local Enemy1 = self.EnemyFolder:WaitForChild("Enemy1")

	self.playerMaxHealth = data and data.maxHealth or 25

	HealthBar.Size = UDim2.fromOffset(HealthStroke.AbsoluteSize.X, 22)
	EnergyBar.Size = UDim2.fromOffset(0, 22)

	self:CreateEnemyHighlight(Enemy1)
	self:CreateEnemyHpDisplay(Enemy1)
end

function CombatGuiHandler:YourTurn(data)
	if data.maxEnergy then
		self.playerMaxEnergy = data.maxEnergy
	end

	self:UpdateEnergyBar(data.energy)
	FrameButtons.Visible = true
	StatusLabel.Text = "Your Turn"

	for _, attack in ipairs(data.attacks) do
		local attackButton = Instance.new("TextButton")
		attackButton.Parent = ScrollFrame
		attackButton.Size = UDim2.new(0, 200, 0, 50)
		attackButton.Text = attack
		attackButton.Name = attack

		attackButton.MouseButton1Click:Connect(function()
			SelectEnemy.Visible = true

			for _, enemy in ipairs(self.EnemyFolder:GetChildren()) do
				local enemyButton = Instance.new("TextButton")
				enemyButton.Parent = SelectEnemy
				enemyButton.Size = UDim2.new(0, 200, 0, 50)
				enemyButton.Text = enemy.Name

				enemyButton.MouseEnter:Connect(function()
					self.Stroke.Enabled = true
				end)
				enemyButton.MouseLeave:Connect(function()
					self.Stroke.Enabled = false
				end)

				enemyButton.MouseButton1Click:Connect(function()
					TurnActionEvent:FireServer("Attack", {
						attackName = attack,
						targetName = enemy.Name,
					})
					SelectEnemy.Visible = false
					self.Stroke.Enabled = false
					for _, btn in ipairs(SelectEnemy:GetChildren()) do
						if btn:IsA("TextButton") then
							btn:Destroy()
						end
					end
				end)
			end
		end)
	end
end

function CombatGuiHandler:EnemyTurn(data)
	FrameButtons.Visible = false
	StatusLabel.Text = "Enemy Turn"
end

function CombatGuiHandler:Attacked(data)
	if data.maxHealth then
		self.playerMaxHealth = data.maxHealth
	end
	StatusLabel.Text = "Enemy used " .. data.attackName .. " dealing " .. data.damage .. " damage!"
	self:UpdatePlayerHealthBar(data.remainingHealth)
end

function CombatGuiHandler:Debuff(data)
	StatusLabel.Text = "Enemy used " .. data.attackName .. " dealing " .. data.damage .. " damage!"
	self:UpdatePlayerHealthBar(data.remainingHealth)

	if data.DotType == "Poison" then
		PoisonLabel.Visible = true
	end
end

function CombatGuiHandler:EnemyBuffed(data)
	StatusLabel.Text = "Enemy used " .. data.attackName .. " buffing itself for " .. data.duration .. " turns!"
end

function CombatGuiHandler:AttackSuccess(data)
	FrameButtons.Visible = false
	StatusLabel.Text = "Waiting for enemy turn..."
	self:CleanupButtons()
	self:UpdateEnergyBar(data.remainingEnergy)
	self:UpdateEnemyHealthBar(data.enemyId, data.targetHealth)
end

function CombatGuiHandler:EnemyHealed(data)
	StatusLabel.Text = "Enemy used " .. data.attackName .. " and healed " .. data.healAmount .. " HP!"
	self:UpdateEnemyHealthBar(data.enemyId, data.currentHealth)
end

function CombatGuiHandler:DotDamage(data)
	if data.maxHealth then
		self.playerMaxHealth = data.maxHealth
	end
	StatusLabel.Text = "Sofreu " .. data.damage .. " de " .. data.effectName
	self:UpdatePlayerHealthBar(data.remainingHealth)
end

function CombatGuiHandler:EffectExpired(data)
	if data.effectName == "Miasm" then
		PoisonLabel.Visible = false
	end
end

function CombatGuiHandler:EnemyHealthUpdate(data)
	self:UpdateEnemyHealthBar(data.enemyId, data.targetHealth)
end
return CombatGuiHandler
