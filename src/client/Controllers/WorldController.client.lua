local ts = game:GetService("TweenService")
local atmosphere = game.Lighting.Atmosphere
local tween = ts:Create(atmosphere, TweenInfo.new(2, Enum.EasingStyle.Linear), { Density = 0.6 })
local exit = ts:Create(atmosphere, TweenInfo.new(2, Enum.EasingStyle.Linear), { Density = 0. })
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Requires = require(ReplicatedStorage:WaitForChild("Shared").Util.Requires)
local zonemodule = Requires.zoneModule()

local Zone = zonemodule.new(workspace:WaitForChild("Model"))

Zone.localPlayerEntered:Connect(function()
	tween:Play()
end)

Zone.localPlayerExited:Connect(function()
	exit:Play()
end)
