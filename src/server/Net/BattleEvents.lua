local ServerScriptService = game:GetService("ServerScriptService")

local Events = ServerScriptService:WaitForChild("Server"):WaitForChild("Services"):WaitForChild("Events")

return {
	BattleStartedEvent = Events:WaitForChild("BattleStartedEvent"),
	PassToEncounterEvent = Events:WaitForChild("PassToEncounterEvent"),
}
