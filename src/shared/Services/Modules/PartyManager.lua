-- Shim: party logic lives on the server
local ServerScriptService = game:GetService("ServerScriptService")
return require(ServerScriptService.Server.Services.PartyManager)
