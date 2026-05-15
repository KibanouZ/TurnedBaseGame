local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PartyGui = PlayerGui:WaitForChild("PartyGui", 10)
local ShowPartyButton = PartyGui:WaitForChild("ShowParty")
local Party = PartyGui:WaitForChild("Party")
local ClosePartyButton = PartyGui:WaitForChild("CloseParty")
local CreatePartyButton = Party:WaitForChild("Create/Disband")
local InviteButton = Party:WaitForChild("InvitePlayer")
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
local InvitedBy = nil
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
ShowPartyButton.InputBegan:Connect(function(input) --ok
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Party.Visible = true
		ClosePartyButton.Visible = true
	end
end)
ClosePartyButton.InputBegan:Connect(function(input) --ok
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Party.Visible = false
		ClosePartyButton.Visible = false
	end
end)
local partyCreated = false

CreatePartyButton.MouseButton1Click:Connect(function()
	if partyCreated then
		if Player:GetAttribute("IsLeader") then
			RequestEvent:FireServer("PartyDisband")
		else
			RequestEvent:FireServer("PartyLeave")
		end
		CreatePartyButton.Text = "Create"
		InviteButton.Visible = false
		partyCreated = false
	else
		CreatePartyButton.Text = "Disband"
		InviteButton.Visible = true
		partyCreated = true
		InvFrame.Visible = false
		RequestEvent:FireServer("PartyCreated")
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
			for _, button in InvFrame:GetChildren() do
				if button:IsA("TextButton") then
					button:Destroy()
				end
			end
			InviteOpen = true
			InviteButton.Text = "Cancel"
			InvFrame.Visible = true
			for _, jogador in ipairs(SendablesPlayers) do
				local InvPlayer = Instance.new("TextButton")
				InvPlayer.Text = jogador.Name
				InvPlayer.TextXAlignment = Enum.TextXAlignment.Center
				InvPlayer.Size = UDim2.new(1, 0, 0, 40)
				InvPlayer.Parent = InvFrame
				InvPlayer.InputBegan:Connect(function(inputInner)
					if inputInner.UserInputType == Enum.UserInputType.MouseButton1 then
						RequestEvent:FireServer("PartyInvite", jogador.UserId)
					end
				end)
			end
		end
	end
end)

RequestEvent.OnClientEvent:Connect(function(action, party)
	if action == "SetLeader" then
		Player:SetAttribute("IsLeader", true)
	end
	if action == "PartyDisbanded" then
		for _, child in Party:WaitForChild("Players"):GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		partyCreated = false
		InviteButton.Visible = false
		CreatePartyButton.Text = "Create"
	end
	if action == "PartyFormed" then
		print("Party recebida")
		partyCreated = true
		CreatePartyButton.Text = "Disband"
		if not Player:GetAttribute("IsLeader") then
			InviteButton.Visible = false
			CreatePartyButton.Text = "leave"
		end
		for _, child in Party:WaitForChild("Players"):GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for _, UserId in ipairs(party) do
			local member = Players:GetPlayerByUserId(UserId)
			local playersinparty = Instance.new("TextLabel")
			playersinparty.Name = member.Name
			playersinparty.Text = member.Name
			playersinparty.Parent = Party:WaitForChild("Players")
			playersinparty.TextXAlignment = Enum.TextXAlignment.Center
			playersinparty.Size = UDim2.new(1, 0, 0, 40)
		end
	end
	if action == "PartyInviteRequest" then
		InvitedBy = party
		Request.Visible = true
	end
end)

AcceptButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		RequestEvent:FireServer("AcceptInvite", InvitedBy)
		Request.Visible = false
	end
end)

DeclineButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Request.Visible = false
	end
end)
