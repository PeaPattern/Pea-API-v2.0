local Services = {
    Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	TeleportService = game:GetService("TeleportService")
}
local Player = game:GetService("Players").LocalPlayer
local Camera = workspace.CurrentCamera
Commands = {}
SaveConfig({
	Prefix = "-"
})

addCommand({"gr"}, "desc", 0, function()
	local Humanoid = Player and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		local newHumanoid = Humanoid:Clone()
		newHumanoid.Name = Humanoid.Name
		newHumanoid.Parent = Humanoid.Parent
		Humanoid:Destroy()
		Camera.CameraSubject = newHumanoid
	end
end)

addCommand({"re"}, "desc", 0, function()
	local OldPos = Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.CFrame
	local Humanoid = Player and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	if Humanoid and OldPos then
		local newHumanoid = Humanoid:Clone()
		newHumanoid.Name = Humanoid.Name
		newHumanoid.Parent = Humanoid.Parent
		Humanoid:Destroy()
		Camera.CameraSubject = newHumanoid
		local Connection = Player.CharacterAdded:Connect(function(newChar)
			repeat task.wait() until newChar and newChar:FindFirstChild("HumanoidRootPart")
			newChar.HumanoidRootPart.CFrame = OldPos
			Connection:Disconnect()
			Connection = nil
		end)
	end
end)

addCommand({"noclip"}, "desc", 0, function()
	local Env = getEnvironment("noclip")
	Env.Noclip1 = Services.RunService.Heartbeat:Connect(function()
		for _,v in next, Player.Character:GetChildren() do
			if v:IsA("BasePart") then
				spoofProperty(v, "CanCollide")
				v.CanCollide = false
			end
		end
	end)
	local Torso = Player and Player.Character and Player.Character:FindFirstChild("Torso") or Player.Character:FindFirstChild("UpperTorso")
	if Torso then
		Env.Noclip2 = Torso.Touched:Connect(function(Object)
			if Object and Object.CanCollide and not Object.Parent:FindFirstChildOfClass("Humanoid") then
				Object.CanCollide = false
				wait(2)
				Object.CanCollide = true
			end
		end)
	end
	local Humanoid = Player and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	Env.Noclip3 = Humanoid.Died:Connect(function()
		for _,v in next, Env do
			v:Disconnect()
			v = nil
		end
	end)
end)

addCommand({"clip"}, "desc", 0, function()
	local Env = getEnvironment("noclip")
	if #Env >= 1 then
		for _,v in next, Env do
			v:Disconnect()
			v = nil
		end
	end
end)

addCommand({"rj"}, "desc", 0, function()
	if #Services.Players:GetPlayers() == 1 then
		Player:Kick()
		Services.TeleportService:Teleport(game.PlaceId)
	else
		Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
	end
end)
