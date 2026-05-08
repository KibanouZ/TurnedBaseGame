local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TurnEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("TurnEvent")
local PlayerList = {}
local CurrentTurn = 1
-- quando o jogador entrar ou sair vai atualizar a tabela de jogadores
local function UpdatePlayers()
	PlayerList = Players:GetPlayers()
end

Players.PlayerAdded:Connect(UpdatePlayers)
Players.PlayerRemoving:Connect(UpdatePlayers)
UpdatePlayers()
-- passar o turno
while true do
	return
end

local function NextTurn()
	if #PlayerList == 0 then
		return
	end
	-- se o turno atual for maior que a quantidade de players volta pro primeiro turno, no  caso o jogador 1
	if CurrentTurn > #PlayerList then
		CurrentTurn = 1
	end
	local player = PlayerList[CurrentTurn]

	print("turno de:", player.Name)

	TurnEvent:FireAllClients(player.Name)

	CurrentTurn += 1
	print("Enviando turno para:", player.Name)
	TurnEvent:FireAllClients(player.Name)
end
while true do
	NextTurn()
	task.wait(10)
end
