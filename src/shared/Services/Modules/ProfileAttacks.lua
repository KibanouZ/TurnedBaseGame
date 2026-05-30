-- Shim: use ReplicatedStorage.Shared.Definitions.Skills.PlayerSkills
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
return require(Shared.Definitions.Skills.PlayerSkills)
