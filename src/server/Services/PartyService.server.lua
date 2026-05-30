local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Requires = require(Shared.Util.Requires)
local PartyManager = Requires.partyManager()
local RequestEvent = require(Shared.Net.BattleRemotes).RequestEvent

RequestEvent.OnServerEvent:Connect(function(player, action, targetPlayer)
	if action == "PartyCreated" then
		PartyManager.CreateParty(player)

		RequestEvent:FireClient(player, "SetLeader")
		RequestEvent:FireClient(player, "PartyFormed", PartyManager.GetMemberIds(player))
	end

	if action == "PartyInvite" then
		local target = game.Players:GetPlayerByUserId(targetPlayer)
		if not target then
			return
		end
		RequestEvent:FireClient(target, "PartyInviteRequest", player.UserId)
	end

	if action == "AcceptInvite" then
		local leader = game.Players:GetPlayerByUserId(targetPlayer)
		if not leader then
			return
		end

		PartyManager.AddMember(leader, player)

		local memberIds = PartyManager.GetMemberIds(leader)
		local party = PartyManager.GetParty(leader)
		for _, member in ipairs(party.Members) do
			RequestEvent:FireClient(member, "PartyFormed", memberIds)
		end
	end

	if action == "PartyLeave" then
		local party = PartyManager.GetParty(player)
		if not party then
			return
		end

		PartyManager.RemoveMember(player)
		RequestEvent:FireClient(player, "PartyDisbanded")

		local memberIds = PartyManager.GetMemberIds(party.owner)
		for _, member in ipairs(party.Members) do
			RequestEvent:FireClient(member, "PartyFormed", memberIds)
		end
	end

	if action == "PartyDisband" then
		local party = PartyManager.GetParty(player)
		if not party then
			return
		end
		if party.owner ~= player then
			return
		end

		for _, member in ipairs(party.Members) do
			RequestEvent:FireClient(member, "PartyDisbanded")
		end

		PartyManager.DisbandParty(player)
	end
end)
