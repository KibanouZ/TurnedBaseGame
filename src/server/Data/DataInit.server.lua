-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- ProfileStore
local ProfileStore = require(ServerScriptService.Server.Libraries.ProfileStore)
local PlayerProfile = require(ServerScriptService.Server.Data.PlayerProfile)
local DataManager = require(ServerScriptService.Server.Data.DataManager)

local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local PlayerStore = ProfileStore.New(GetStoreName(), PlayerProfile.new())

local function Initialize(player: Player, profile)
	-- sync player data with profile aqui
end

local function PlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player.UserId] = nil
			player:Kick("Data error ocurred. Rejoin")
		end)

		if player.Parent == Players then
			DataManager.Profiles[player.UserId] = profile
			Initialize(player, profile)
		else
			profile:EndSession()
		end
	else
		player:Kick("Detected some data issues, please rejoin.")
	end
end

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
	DataManager.Profiles[player.UserId] = nil
end)
