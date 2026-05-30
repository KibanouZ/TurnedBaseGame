-- RemoteEvents de combate/party (sincronizados via Rojo em Shared.Services.TurnSystem)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Services = Shared:WaitForChild("Services")
local TurnSystem = Services:WaitForChild("TurnSystem")

return {
	TurnEvent = TurnSystem:WaitForChild("TurnEvent"),
	TurnActionEvent = TurnSystem:WaitForChild("TurnActionEvent"),
	RequestEvent = TurnSystem:WaitForChild("RequestEvent"),
}
