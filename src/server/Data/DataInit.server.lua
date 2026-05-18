-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--ProfileStore
local ProfileStore = require(ServerScriptService.Server.Libraries.ProfileStore)

local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local Template = require(ServerScriptService.Server.Data.Template)
local DataManager = require(ServerScriptService.Server.Data.DataManager)
-- Acess profile store
local PlayerStore = ProfileStore.New(GetStoreName(), Template)
--add leaderstats and sincronize player data
local function Initialize(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
	--sync player data with profile
end
--creates and stores a profile
local function PlayerAdded(player: Player)
	--Start a new profile session
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	--Check if the profile was loaded successfully
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile() -- Fil missing data with template
		--Handle session lock
		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player.UserId] = nil
			player:Kick("Data error ocurred.Rejoin")
		end)
		if player.Parent == Players then
			DataManager.Profiles[player.UserId] = profile
			Initialize(player, profile)
		else
			profile:EndSession()
		end
	else
		--Server Shutdown down while player is joining, kick
		player:Kick(" Detected some data issues, please rejoin.")
	end
end
--Early players joining before the server is ready
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end
Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player.UserId]
	if not profile then
		return
	end
	profile:EndSession()
	DataManager.Profiles[player] = nil
end)
