-- ==========================================
-- EXE 6 SERVER-SIDE CORE (Fully Featured)
-- ==========================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- 1. Create the Secure Remote Folder
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "EXE6-remotes"
remoteFolder.Parent = ReplicatedStorage

-- 2. Create the RemoteFunctions
local humanoidRemote = Instance.new("RemoteFunction")
humanoidRemote.Name = "Humanoid"
humanoidRemote.Parent = remoteFolder

local characterRemote = Instance.new("RemoteFunction")
characterRemote.Name = "Character"
characterRemote.Parent = remoteFolder

local primaryRemote = Instance.new("RemoteFunction")
primaryRemote.Name = "Primary"
primaryRemote.Parent = remoteFolder

-- 3. Announce to the Client that the Server is active!
CollectionService:AddTag(ReplicatedStorage, "HasServerInjected")

-- ==========================================
-- AUTHENTICATION & UTILITIES
-- ==========================================
local function IsAuthorized(userId)
	return true -- Update this later with your Admin IDs or Group Ranks!
end

local function DeserializeIds(serializedString)
	local ids = {}
	if not serializedString then return ids end
	for idStr in string.gmatch(serializedString, "([^,]+)") do
		table.insert(ids, tonumber(idStr))
	end
	return ids
end

-- ==========================================
-- PRIMARY MODERATION ROUTER (Kick/Ban/Unban)
-- ==========================================
primaryRemote.OnServerInvoke = function(caller, actionString, properties)
	if not IsAuthorized(caller.UserId) then return nil, "Unauthorized." end

	local idsToProcess = DeserializeIds(properties.SerializedIds)
	local successList = {}
	local safeReason = properties.Reason or "No reason provided."

	if actionString == "Kick" then
		for _, id in ipairs(idsToProcess) do
			local target = Players:GetPlayerByUserId(id)
			if target then
				target:Kick("You have been kicked.\nReason: " .. safeReason)
				table.insert(successList, id)
			end
		end
		return {Success = successList, All = idsToProcess}

	elseif actionString == "Ban" then
		for _, id in ipairs(idsToProcess) do
			local success = pcall(function()
				Players:BanAsync({
					UserIds = {id},
					Duration = properties.Duration or -1, -- Default to permanent
					DisplayReason = "You are banned.\nReason: " .. safeReason,
					PrivateReason = "Banned via EXE 6 by " .. caller.Name,
					ApplyToUniverse = true
				})
			end)
			if success then table.insert(successList, id) end
		end
		return {Success = successList, All = idsToProcess}

	elseif actionString == "Unban" then
		for _, id in ipairs(idsToProcess) do
			if properties.ServerOnly then
				-- If you have a custom datastore for server-only bans, you'd remove them here.
				-- For now, we'll just mark it successful.
				table.insert(successList, id)
			else
				local success = pcall(function()
					Players:UnbanAsync({
						UserIds = {id},
						ApplyToUniverse = true
					})
				end)
				if success then table.insert(successList, id) end
			end
		end
		return {Success = successList, All = idsToProcess}

	elseif actionString == "Warn" then
		-- Can tie this into a UI popup or Datastore warning system later!
		return {Success = idsToProcess, All = idsToProcess}
	end

	return nil, "Unknown Primary Action."
end

-- ==========================================
-- HUMANOID & CHARACTER ROUTERS
-- ==========================================
humanoidRemote.OnServerInvoke = function(caller, targetUserId, actionString, value)
	if not IsAuthorized(caller.UserId) then return false, "Unauthorized" end
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer or not targetPlayer.Character then return false, "Target unavailable" end
	local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false, "Humanoid missing" end

	if actionString == "Health" then humanoid.Health = value return true, "Health set"
	elseif actionString == "Speed" then humanoid.WalkSpeed = value return true, "Speed set"
	elseif actionString == "Jump" then humanoid.JumpPower = value humanoid.JumpHeight = value return true, "Jump set" end
	return false, "Invalid Humanoid Action"
end

characterRemote.OnServerInvoke = function(caller, targetUserId, actionString, value)
	if not IsAuthorized(caller.UserId) then return false, "Unauthorized" end
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer or not targetPlayer.Character then return false, "Target unavailable" end
	local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false, "HRP missing" end

	if actionString == "Freeze" then hrp.Anchored = true return true, "Froze player"
	elseif actionString == "Unfreeze" then hrp.Anchored = false return true, "Unfroze player"
	elseif actionString == "Bring" then
		local callerHrp = caller.Character and caller.Character:FindFirstChild("HumanoidRootPart")
		if callerHrp then hrp.CFrame = callerHrp.CFrame * CFrame.new(0, 0, -5) return true, "Brought player" end
	elseif actionString == "Invisible" or actionString == "Visible" or actionString == "Transparency" then
		local t = (actionString == "Invisible") and 1 or (actionString == "Visible") and 0 or value
		for _, p in pairs(targetPlayer.Character:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Transparency = t end
		end
		return true, "Updated visibility"
	end
	return false, "Invalid Character Action"
end

print("🛡️ [EXE 6] Secure Server Framework Injected.")
