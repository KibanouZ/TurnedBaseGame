local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PartyGui = PlayerGui:WaitForChild("PartyGui")
local ShowPartyButton = PartyGui:WaitForChild("ShowParty")
local Party = PartyGui:WaitForChild("Party")
local ClosePartyButton = PartyGui:WaitForChild("CloseParty")
local CreatePartyButton = Party:WaitForChild("Create/Disband")
local InviteButton = Party:WaitForChild("InvitePlayer")
local InvitedBy = nil
local Request = PartyGui:WaitForChild("Request")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Services")
	:WaitForChild("TurnSystem")
	:WaitForChild("RequestEvent")
local InvFrame = PartyGui:WaitForChild("InvFrame")
local DeclineButton = Request:WaitForChild("Decline")
local AcceptButton = Request:WaitForChild("Accept")
local SendablesPlayers = {}
local function UpdatePlayers()
	table.clear(SendablesPlayers)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Player then
			table.insert(SendablesPlayers, player)
		end
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
local InviteOpen = false

InviteButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if InviteOpen then
			InviteOpen = false
			InviteButton.Text = "Invite"
			InvFrame.Visible = false
		else
			InviteOpen = true
			InviteButton.Text = "Cancel"
			InvFrame.Visible = true

			for _, child in InvFrame:GetChildren() do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end

			for _, jogador in ipairs(SendablesPlayers) do
				local InvPlayer = Instance.new("TextButton")
				InvPlayer.Text = jogador.Name
				InvPlayer.TextXAlignment = Enum.TextXAlignment.Center
				InvPlayer.Size = UDim2.new(1, 0, 0, 40)
				InvPlayer.Parent = InvFrame
				InvPlayer.InputBegan:Connect(function(inputInner)
					if inputInner.UserInputType == Enum.UserInputType.MouseButton1 then
						RequestEvent:FireServer("PartyInvite", jogador)
					end
				end)
			end
		end
	end
end)

RequestEvent.OnClientEvent:Connect(function(action, requester)
	print(action)
	print(requester)
	if action == "PartyInviteRequest" then
		InvitedBy = requester
		Request.Visible = true
	end
end)

AcceptButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		RequestEvent:FireServer("AcceptInvite", InvitedBy.UserId)
	end
end)

DeclineButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Request.Visible = false
	end
end)
