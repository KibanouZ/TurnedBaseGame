--!strict
-- Domain/Encounter/PartyPositioner.lua
--
-- Calcula as posições de formação da party em relação ao inimigo.
-- PURO: sem workspace, sem Players, sem instâncias Roblox.
-- Entrada e saída são Vector3 e CFrame — pode ser testado fora do Studio.

local PartyPositioner = {}

local SPACING = 10 -- distância lateral entre membros (studs)

export type FormationEntry = {
	memberId: number, -- UserId
	targetCFrame: CFrame,
}

-- Calcula a CFrame de destino de cada membro da party.
-- @param memberIds      lista ordenada de UserIds (líder primeiro)
-- @param memberPositions tabela { [userId] = Vector3 } com posição atual de cada membro
-- @param enemyPosition  Vector3 do inimigo
-- @returns lista de FormationEntry, uma por membro
function PartyPositioner.Calculate(
	memberIds: { number },
	memberPositions: { [number]: Vector3 },
	enemyPosition: Vector3
): { FormationEntry }
	assert(#memberIds > 0, "[PartyPositioner] memberIds não pode ser vazio")

	local leaderPos = memberPositions[memberIds[1]]
	assert(leaderPos, "[PartyPositioner] posição do líder não encontrada")

	local forward = (enemyPosition - leaderPos)
	-- fallback se o inimigo estiver exatamente na mesma posição (evita NaN)
	if forward.Magnitude < 0.001 then
		forward = Vector3.new(0, 0, -1)
	end
	forward = forward.Unit

	local right = forward:Cross(Vector3.new(0, 1, 0)).Unit
	local total = #memberIds
	local startOffset = -((total - 1) / 2) * SPACING

	local result: { FormationEntry } = {}

	for i, userId in ipairs(memberIds) do
		local currentPos = memberPositions[userId]
		if not currentPos then
			warn("[PartyPositioner] posição não encontrada para UserId:", userId)
			continue
		end

		local sideOffset = startOffset + (i - 1) * SPACING
		local flatPos = leaderPos + right * sideOffset
		-- preserva a altura Y original de cada membro
		local targetPos = Vector3.new(flatPos.X, currentPos.Y, flatPos.Z)
		local targetCFrame = CFrame.lookAt(targetPos, targetPos + forward)

		table.insert(result, {
			memberId = userId,
			targetCFrame = targetCFrame,
		})
	end

	return result
end

return PartyPositioner
