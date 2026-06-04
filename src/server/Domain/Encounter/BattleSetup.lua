--!strict
-- Domain/Encounter/BattleSetup.lua
--
-- Monta o estado inicial de uma batalha.
-- PURO: não cria instâncias Roblox, não lê workspace.
-- Recebe dados já extraídos (snapshots de profile, definições de inimigo)
-- e devolve uma tabela de estado que o Service vai usar.

local HttpService = game:GetService("HttpService")

local BattleSetup = {}

-- ── Tipos ────────────────────────────────────────────────────────────────────

export type AllySnapshot = {
	userId: number,
	displayName: string,
	maxHealth: number,
	health: number,
	energy: number,
}

export type EnemyEntry = {
	id: string, -- "Enemy1", "Goblin", etc.
	displayName: string,
}

export type BattleState = {
	battleId: string,
	allies: { AllySnapshot },
	enemies: { EnemyEntry },
	state: "starting" | "inProgress" | "victory" | "defeat",
	playerToBattleId: { [number]: string }, -- userId → battleId (para lookup rápido)
}

-- ── API ───────────────────────────────────────────────────────────────────────

-- Cria um battleId único.
function BattleSetup.GenerateId(): string
	return "battle_" .. HttpService:GenerateGUID(false)
end

-- Monta o BattleState inicial a partir de snapshots já extraídos.
-- @param battleId   string gerada por GenerateId()
-- @param allies     lista de AllySnapshot (extraídos dos profiles pelo Service)
-- @param enemies    lista de EnemyEntry (definições, não instâncias)
-- @returns BattleState pronto para ser armazenado em ActiveBattles
function BattleSetup.Build(battleId: string, allies: { AllySnapshot }, enemies: { EnemyEntry }): BattleState
	assert(battleId ~= "", "[BattleSetup] battleId não pode ser vazio")
	assert(#allies > 0, "[BattleSetup] batalha precisa de ao menos 1 aliado")
	assert(#enemies > 0, "[BattleSetup] batalha precisa de ao menos 1 inimigo")

	-- monta o mapa userId → battleId para todos os membros
	local playerToBattleId: { [number]: string } = {}
	for _, ally in ipairs(allies) do
		playerToBattleId[ally.userId] = battleId
	end

	return {
		battleId = battleId,
		allies = allies,
		enemies = enemies,
		state = "starting",
		playerToBattleId = playerToBattleId,
	}
end

-- Extrai um AllySnapshot de um profile do DataManager.
-- Centraliza o acesso ao formato do profile — se o formato mudar, muda aqui.
-- @param userId      número do jogador
-- @param displayName nome de exibição
-- @param profileData profile.Data (tabela do ProfileStore)
function BattleSetup.SnapshotFromProfile(userId: number, displayName: string, profileData: any): AllySnapshot
	local stats = profileData and profileData.Stats or {}
	return {
		userId = userId,
		displayName = displayName,
		maxHealth = stats.MaxHealth or 25,
		health = stats.MaxHealth or 25,
		energy = stats.MaxEnergy or 10,
	}
end

return BattleSetup
