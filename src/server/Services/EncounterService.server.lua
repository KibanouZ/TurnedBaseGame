-- ── Dependências ─────────────────────────────────────────────────────────────

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Requires = require(Shared.Util.Requires)
local PartyManager = Requires.partyManager()
local DataManager = Requires.dataManager()

local Remotes = require(Shared.Net.BattleRemotes)
local TurnEvent = Remotes.TurnEvent
local BattleEvents = require(ServerScriptService.Server.Net.BattleEvents)
local BattleStartedEvent = BattleEvents.BattleStartedEvent
local PassToEncounterEvent = BattleEvents.PassToEncounterEvent

-- Domínio (sem Roblox direto)
local PartyPositioner = require(ServerScriptService.Server.Domain.Encounter.PartyPositioner)
local BattleSetup = require(ServerScriptService.Server.Domain.Encounter.BattleSetup)

-- Infraestrutura (toca Roblox)
local EnemySpawner = require(ServerScriptService.Server.Infraestructure.EnemySpawner)

-- ── Referências de workspace / assets ────────────────────────────────────────

local EffectiveArea = workspace:WaitForChild("EncounterStart"):WaitForChild("EffectiveArea")
local BattlesFolder = workspace:WaitForChild("Battles")
local EnemyModels = Shared:WaitForChild("Assets"):WaitForChild("Enemies")

if not EnemyModels then
	warn("[EncounterService] ReplicatedStorage.Shared.Assets.Enemies não encontrada.")
end

-- ── Estado interno ───────────────────────────────────────────────────────────

-- activeStates[battleId] = BattleSetup.BattleState
local activeStates: { [string]: BattleSetup.BattleState } = {}

-- debounce por UserId para evitar duplo-trigger
local debounce: { [number]: boolean } = {}

-- ── Helpers locais ────────────────────────────────────────────────────────────

-- Coleta todos os membros da party com personagem válido.
local function collectMembers(leader: Player, memberIds: { number }): { Player }
	local members: { Player } = { leader }
	for _, id in ipairs(memberIds) do
		local member = game.Players:GetPlayerByUserId(id)
		if member and member ~= leader and member.Character then
			table.insert(members, member)
		end
	end
	return members
end

-- Extrai posições atuais dos membros como { [userId] = Vector3 }.
local function extractPositions(members: { Player }): { [number]: Vector3 }
	local positions: { [number]: Vector3 } = {}
	for _, member in ipairs(members) do
		local root = member.Character and member.Character:FindFirstChild("HumanoidRootPart")
		if root then
			positions[member.UserId] = (root :: BasePart).Position
		end
	end
	return positions
end

-- Aplica freeze/unfreeze no Humanoid de um personagem.
local function setFrozen(member: Player, frozen: boolean)
	local char = member.Character
	if not char then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = frozen and 0 or 16
		humanoid.JumpPower = frozen and 0 or 50
	end
end

-- Desfaz tudo de uma batalha: descongela, devolve chars ao workspace, limpa tabelas.
local function cleanupBattle(battleId: string, members: { Player }, battleFolder: Folder)
	for _, member in ipairs(members) do
		setFrozen(member, false)
		debounce[member.UserId] = nil
	end

	if battleFolder and battleFolder.Parent then
		battleFolder:Destroy()
	end

	activeStates[battleId] = nil
end

-- ── Fluxo principal ───────────────────────────────────────────────────────────

EffectiveArea.Touched:Connect(function(hit: BasePart)
	-- só HumanoidRootPart com Humanoid no pai
	if hit.Name ~= "HumanoidRootPart" then
		return
	end
	if not (hit.Parent :: Instance):FindFirstChild("Humanoid") then
		return
	end

	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end
	if debounce[player.UserId] then
		return
	end
	debounce[player.UserId] = true

	-- ── 1. Coletar membros e posições ─────────────────────────────────────────
	local memberIds = PartyManager.GetMemberIds(player)
	local members = collectMembers(player, memberIds)
	local positions = extractPositions(members)

	local leaderPos = positions[player.UserId]
	if not leaderPos then
		warn("[EncounterService] líder sem HumanoidRootPart:", player.Name)
		debounce[player.UserId] = nil
		return
	end

	-- ── 2. Tentar spawnar inimigo (infraestrutura) ────────────────────────────
	local battleId = BattleSetup.GenerateId()
	local battleFolder = Instance.new("Folder")
	battleFolder.Name = battleId
	battleFolder:SetAttribute("BattleId", battleId)
	battleFolder.Parent = BattlesFolder

	local allyFolder = Instance.new("Folder")
	allyFolder.Name = "AllyFolder"
	allyFolder.Parent = battleFolder

	local enemyFolder = Instance.new("Folder")
	enemyFolder.Name = "EnemyFolder"
	enemyFolder.Parent = battleFolder

	-- TODO: trocar "Enemy1" por tabela de spawn data-driven (Fase 4 do plano)
	local spawnResult = EnemySpawner.Spawn("Enemy1", EnemyModels, enemyFolder, leaderPos)
	if not spawnResult.ok then
		warn("[EncounterService]", spawnResult.errorMsg)
		battleFolder:Destroy()
		debounce[player.UserId] = nil
		return
	end

	local enemyPos = spawnResult.position :: Vector3

	-- ── 3. Posicionar party (domínio puro) ────────────────────────────────────
	local userIds: { number } = {}
	for _, m in ipairs(members) do
		table.insert(userIds, m.UserId)
	end

	local formation = PartyPositioner.Calculate(userIds, positions, enemyPos)

	-- aplica CFrames calculados (chamada Roblox fica aqui no Service, não no módulo)
	for _, entry in ipairs(formation) do
		local member = game.Players:GetPlayerByUserId(entry.memberId)
		if member and member.Character then
			member.Character:PivotTo(entry.targetCFrame)
		end
	end

	-- ── 4. Montar estado da batalha (domínio puro) ────────────────────────────
	local snapshots: { BattleSetup.AllySnapshot } = {}
	for _, member in ipairs(members) do
		local profile = DataManager.Profiles[member.UserId]
		table.insert(
			snapshots,
			BattleSetup.SnapshotFromProfile(member.UserId, member.DisplayName, profile and profile.Data or nil)
		)
	end

	local enemyList: { BattleSetup.EnemyEntry } = {
		{ id = "Enemy1", displayName = "Enemy1" },
	}

	local battleState = BattleSetup.Build(battleId, snapshots, enemyList)
	activeStates[battleId] = battleState

	-- ── 5. Preparar jogadores (Roblox) ────────────────────────────────────────
	for _, member in ipairs(members) do
		setFrozen(member, true)

		-- envia battleId + snapshot do aliado correspondente ao cliente
		local snap = snapshots[1] -- fallback
		for _, s in ipairs(snapshots) do
			if s.userId == member.UserId then
				snap = s
				break
			end
		end
		print("enviando")
		TurnEvent:FireClient(member, "StartBattle", {
			battleId = battleId,
			maxHealth = snap.maxHealth,
			energy = snap.energy,
		})
	end

	-- ── 6. Notificar TurnSystem ───────────────────────────────────────────────
	-- passa allMembers (não só o líder) para que o TurnSystem registre todos
	local snapshots = {}
	for _, member in ipairs(members) do
		local profile = DataManager.Profiles[member.UserId]
		table.insert(
			snapshots,
			BattleSetup.SnapshotFromProfile(member.UserId, member.DisplayName, profile and profile.Data or nil)
		)
	end

	local enemyEntries = { { id = "Enemy1", displayName = "Enemy1" } }
	local battleState = BattleSetup.Build(battleId, snapshots, enemyEntries)

	BattleStartedEvent:Fire(player, members, enemyList, battleId, battleState)

	-- ── 7. Ouvir fim da batalha ───────────────────────────────────────────────
	-- connection LOCAL por batalha — evita sobrescrever conexão de outra batalha simultânea
	local connection: RBXScriptConnection
	connection = PassToEncounterEvent.Event:Connect(function(returnedBattleId: string)
		print("[EncounterService] PassToEncounter recebido:", returnedBattleId, "esperado:", battleId)
		if returnedBattleId ~= battleId then
			return
		end
		cleanupBattle(battleId, members, battleFolder)
		connection:Disconnect()
	end)
end)
