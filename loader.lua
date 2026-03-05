local github_raw_url = "https://github.com/DanielNov2014/EXE-6-Client-Sided/raw/refs/heads/main/Exe6PanelNewest.rbxm"
local file_name = "Exe6PanelNewest.rbxm"

print("Downloading .rbxm from GitHub...")
writefile(file_name, game:HttpGet(github_raw_url))

local loaded_objects = game:GetObjects(getcustomasset(file_name))
local Package = loaded_objects[1]

-- 1. DISABLE PHYSICAL SCRIPTS
for _, obj in pairs(Package:GetDescendants()) do
    if obj:IsA("LocalScript") or obj:IsA("Script") then
        obj.Disabled = true
    end
end

-- 2. PARENT THE UI AND STORAGE
local Storage = Package:FindFirstChild("EXE6_STORAGE")
if Storage then Storage.Parent = game:GetService("ReplicatedStorage") end

local UI = Package:FindFirstChild("EXE6")
if UI then 
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    if PlayerGui:FindFirstChild(UI.Name) then PlayerGui[UI.Name]:Destroy() end
    UI.Parent = PlayerGui 
end

-- 3. THE CUSTOM REQUIRE HOOK
getgenv().ORIGINAL_REQUIRE = getgenv().ORIGINAL_REQUIRE or require
getgenv().CUSTOM_EXE6_REQUIRE = function(module)
    if typeof(module) == "Instance" and module:IsA("ModuleScript") and module:FindFirstChild("HiddenSource") then
        local _g = getgenv()
        _g._EXE6_CACHE = _g._EXE6_CACHE or {}
        if _g._EXE6_CACHE[module] then 
            return unpack(_g._EXE6_CACHE[module]) 
        end
        
        local mod_source = "local script = ...;\nlocal require = getgenv().CUSTOM_EXE6_REQUIRE;\n" .. module.HiddenSource.Value
        local loaded_func, err = loadstring(mod_source)
        
        if loaded_func then
            local result = loaded_func(module)
            _g._EXE6_CACHE[module] = {result}
            return result
        else
            warn("Failed to compile ModuleScript: " .. module.Name)
        end
    end
    return getgenv().ORIGINAL_REQUIRE(module)
end

-- 4. THE TRACER EXECUTION (Only runs scripts in the UI!)
for _, obj in pairs(UI:GetDescendants()) do
    if obj:IsA("LocalScript") and obj:FindFirstChild("HiddenSource") then
        task.spawn(function()
            -- Inject Tracer Prints
            local source = "print('🟢 STARTED: ' .. (...).Name);\nlocal script = ...;\nlocal require = getgenv().CUSTOM_EXE6_REQUIRE;\n" .. obj.HiddenSource.Value .. "\nprint('✅ FINISHED: ' .. (...).Name)"
            local func, err = loadstring(source)
            
            if func then
                local success, run_err = pcall(function()
                    func(obj)
                end)
                if not success then
                    warn("❌ RUNTIME ERROR in " .. obj.Name .. ":\n" .. tostring(run_err))
                end
            end
        end)
    end
end

print("🚀 Tracer Panel Loaded! Check the console.")
