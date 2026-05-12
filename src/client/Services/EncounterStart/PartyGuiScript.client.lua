local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PartyGui = PlayerGui:WaitForChild("PartyGui")
local ShowPartyButton = PartyGui:WaitForChild("ShowParty")
local Party = PartyGui:WaitForChild("Party")
local ClosePartyButton = PartyGui:WaitForChild("CloseParty")
local CreatePartyButton = Party:WaitForChild("Create/Disband")
local InviteButton = Party:WaitForChild("InvitePlayer")
local _PartyPlayers = { Player }
local InvFrame = PartyGui:WaitForChild("InvFrame")
local ScrollingFrame = InvFrame:WaitForChild("ScrollingFrame")
local SendablesPlayers = {}
local function UpdatePlayers()
	table.clear(SendablesPlayers)

	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(SendablesPlayers, player)
	end
end

Players.PlayerAdded:Connect(UpdatePlayers)
Players.PlayerRemoving:Connect(UpdatePlayers)
UpdatePlayers()
ShowPartyButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Party.Visible = true
		ClosePartyButton.Visible = true
	end
end)
ClosePartyButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Party.Visible = false
		ClosePartyButton.Visible = false
	end
end)
local partyCreated = false

CreatePartyButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if partyCreated then
			CreatePartyButton.Text = "Create"
			InviteButton.Visible = false
			partyCreated = false
		else
			CreatePartyButton.Text = "Disband"
			InviteButton.Visible = true
			partyCreated = true
		end
	end
end)

InviteButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		InvFrame.Visible = true
		for _, jogador in ipairs(SendablesPlayers) do
			local InvPlayer = Instance.new("TextButton")
			InvPlayer.Parent = InvFrame
			InvPlayer.Text = jogador.Name
			print(InvPlayer.Text)
		end
	end
end)
