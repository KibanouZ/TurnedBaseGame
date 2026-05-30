-- Shim: use ReplicatedStorage.Shared.Definitions.Skills.EnemySkills
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
return require(Shared.Definitions.Skills.EnemySkills)
