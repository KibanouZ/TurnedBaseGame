local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("RequestEvent")
local parties = {}
RequestEvent.OnServerEvent:Connect(function(player, action, targetPlayer)
	if action == "PartyInvite" then
		RequestEvent:FireClient(targetPlayer, "PartyInviteRequest", player)
	end
	if action == "AcceptInvite" then
		local party = { player, targetPlayer }
		parties[player.UserId] = party
		parties[targetPlayer.UserId] = party

		RequestEvent:FireClient(player, "PartyFormed", party)
		RequestEvent:FireClient(targetPlayer, "PartyFormed", party)
	end
end)
