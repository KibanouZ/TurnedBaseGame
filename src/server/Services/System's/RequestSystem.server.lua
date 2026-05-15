local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RequestEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("RequestEvent")

local PassToEncounterEvent = ServerScriptService:WaitForChild("Server")
	:WaitForChild("Services")
	:WaitForChild("Events")
	:WaitForChild("PassToEncounterEvent")

local parties = {}

local function getPartyByMember(player)
	for _, party in pairs(parties) do
		for _, member in ipairs(party.Members) do
			if member == player then
				return party
			end
		end
	end
	return nil
end

RequestEvent.OnServerEvent:Connect(function(player, action, targetPlayer)
	if action == "PartyCreated" then
		local party = {
			owner = player,
			Members = { player },
		}
		parties[player.UserId] = party

		local memberIds = {}
		for _, member in ipairs(party.Members) do
			table.insert(memberIds, member.UserId)
		end

		RequestEvent:FireClient(player, "SetLeader")
		RequestEvent:FireClient(player, "PartyFormed", memberIds)
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

		local party = parties[leader.UserId]
		if not party then
			return
		end

		table.insert(party.Members, player)

		local memberIds = {}
		for _, member in ipairs(party.Members) do
			table.insert(memberIds, member.UserId)
		end

		for _, member in ipairs(party.Members) do
			RequestEvent:FireClient(member, "PartyFormed", memberIds)
		end
	end

	if action == "PartyLeave" then
		local party = getPartyByMember(player)
		if not party then
			return
		end

		for i, member in ipairs(party.Members) do
			if member == player then
				table.remove(party.Members, i)
				break
			end
		end

		RequestEvent:FireClient(player, "PartyDisbanded")

		local memberIds = {}
		for _, member in ipairs(party.Members) do
			table.insert(memberIds, member.UserId)
		end
		for _, member in ipairs(party.Members) do
			RequestEvent:FireClient(member, "PartyFormed", memberIds)
		end
	end

	if action == "PartyDisband" then
		local party = parties[player.UserId]
		if not party then
			return
		end
		if party.owner ~= player then
			return
		end

		local memberIds = {}
		for _, member in ipairs(party.Members) do
			table.insert(memberIds, member.UserId)
		end

		PassToEncounterEvent:Fire(memberIds)

		-- ✅ limpa tudo em um lugar só
		for _, member in ipairs(party.Members) do
			RequestEvent:FireClient(member, "PartyDisbanded")
		end

		parties[player.UserId] = nil
	end
end)
