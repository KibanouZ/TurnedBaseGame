-- Shim: use ReplicatedStorage.Shared.Definitions.Enemies.EnemyRegistry
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
return require(Shared.Definitions.Enemies.EnemyRegistry)
