--!strict
-- Infrastructure/EnemySpawner.lua
--
-- Responsável por clonar o modelo do inimigo e posicioná-lo no workspace.
-- INFRAESTRUTURA: é o único lugar do fluxo de encounter que toca instâncias Roblox
-- diretamente (Clone, PivotTo, Parent). Não tem lógica de jogo.

local EnemySpawner = {}

local ENEMY_DISTANCE = 30 -- distância do inimigo ao líder (studs)

export type SpawnResult = {
	ok: boolean,
	model: Model?,
	position: Vector3?,
	errorMsg: string?,
}

-- Clona e posiciona o modelo do inimigo.
-- @param enemyId      nome do modelo dentro de modelsFolder
-- @param modelsFolder pasta com os modelos (ReplicatedStorage.Shared.Assets.Enemies)
-- @param parentFolder pasta de destino (EnemyFolder dentro da BattleFolder)
-- @param leaderPos    posição do líder da party
-- @returns SpawnResult
function EnemySpawner.Spawn(
	enemyId: string,
	modelsFolder: Folder,
	parentFolder: Folder,
	leaderPos: Vector3
): SpawnResult
	if not modelsFolder then
		return { ok = false, errorMsg = "[EnemySpawner] modelsFolder é nil" }
	end

	local template = modelsFolder:FindFirstChild(enemyId)
	if not template then
		return {
			ok = false,
			errorMsg = "[EnemySpawner] modelo não encontrado: " .. tostring(enemyId),
		}
	end

	local model = (template :: Model):Clone()
	local enemyPos = leaderPos + Vector3.new(0, 0, -ENEMY_DISTANCE)

	model:PivotTo(CFrame.lookAt(enemyPos, leaderPos))
	model.Parent = parentFolder

	return {
		ok = true,
		model = model,
		position = enemyPos,
	}
end

-- Remove todos os modelos de inimigo de uma pasta.
-- Chamado no cleanup da batalha antes de destruir a BattleFolder.
function EnemySpawner.DespawnAll(enemyFolder: Folder)
	for _, child in ipairs(enemyFolder:GetChildren()) do
		child:Destroy()
	end
end

return EnemySpawner
