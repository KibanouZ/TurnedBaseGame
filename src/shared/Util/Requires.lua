-- Caminhos de require. Funções de servidor só podem ser chamadas no server.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local serverFolder = nil

local function getServerFolder()
	if not RunService:IsServer() then
		error("[Requires] Acesso ao servidor só é permitido em Scripts do ServerScriptService", 2)
	end
	if not serverFolder then
		serverFolder = game:GetService("ServerScriptService"):WaitForChild("Server")
	end
	return serverFolder
end

local Requires = {}

function Requires.getShared()
	return Shared
end

function Requires.getServer()
	return getServerFolder()
end

function Requires.playerSkills()
	return require(Shared.Definitions.Skills.PlayerSkills)
end

function Requires.enemySkills()
	return require(Shared.Definitions.Skills.EnemySkills)
end

function Requires.enemyRegistry()
	return require(Shared.Definitions.Enemies.EnemyRegistry)
end

function Requires.partyManager()
	return require(getServerFolder().Services.PartyManager)
end

function Requires.dataManager()
	return require(getServerFolder().Data.DataManager)
end

function Requires.zoneModule()
	return require(Shared.World.Zone)
end

return Requires
