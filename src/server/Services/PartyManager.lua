-- ServerScriptService > Server > PartyManager (ModuleScript)
local PartyManager = {}
local parties = {}

function PartyManager.CreateParty(player)
	parties[player.UserId] = { owner = player, Members = { player } }
end

function PartyManager.AddMember(leader, player)
	local party = parties[leader.UserId]
	if not party then
		return
	end
	table.insert(party.Members, player)
end

function PartyManager.RemoveMember(player)
	local party = PartyManager.GetParty(player)
	if not party then
		return
	end
	for i, member in ipairs(party.Members) do
		if member == player then
			table.remove(party.Members, i)
			break
		end
	end
end

function PartyManager.DisbandParty(player)
	parties[player.UserId] = nil
end

function PartyManager.GetParty(player)
	if parties[player.UserId] then
		return parties[player.UserId]
	end
	for _, party in pairs(parties) do
		for _, member in ipairs(party.Members) do
			if member == player then
				return party
			end
		end
	end
	return nil
end

function PartyManager.GetMemberIds(player)
	local party = PartyManager.GetParty(player)
	if not party then
		return { player.UserId }
	end
	local ids = {}
	for _, member in ipairs(party.Members) do
		table.insert(ids, member.UserId)
	end
	return ids
end

return PartyManager
