--=> Setup <=--

if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

if getgenv().PeaAPI then
    print("Do not run Pea API multiple times.")
    return
else
    getgenv().PeaAPI = true
end

--=> Main Variables <=--

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService")
}

local Player = Services.Players.LocalPlayer
Whitelisted = {Player}

local sfind, slower, ssub, slen, ssplit =
    string.find, string.lower, string.sub, string.len, string.split

local tfind, tinsert, tremove =
    table.find, table.insert, table.remove

--=> Files <=--

local Config = {
    Prefix = "."
}

function MakeConfig()
    local JSON = Services.HttpService:JSONEncode(Config)
    if isfolder("PeaAPI") then
        writefile("PeaAPI/config.json", JSON)
    else
        makefolder("PeaAPI")
        makefolder("PeaAPI/addons")
        writefile("PeaAPI/config.json", JSON)
    end
end

function LoadConfig()
    if isfolder("PeaAPI") and isfile("PeaAPI/config.json") then
        return Services.HttpService:JSONDecode(readfile("PeaAPI/config.json"))
    else
        MakeConfig()
        return Services.HttpService:JSONDecode(readfile("PeaAPI/config.json"))
    end
end

function SaveConfig(newConfig)
    if not isfolder("PeaAPI") and isfile("PeaAPI/config.json") then
        MakeConfig()
    end
    local oldConfig = LoadConfig()
    for _,v in next, newConfig do
        oldConfig[_] = v
    end
    writefile("PeaAPI/config.json", Services.HttpService:JSONEncode(oldConfig))
end

--=> Main Functions <=--

function getOthers()
    local New = {}
    for _,v in next, Services.Players:GetPlayers() do
        if v ~= Player then
            tinsert(New, v)
        end
    end
    return New
end

function getPlayer(String)
    local LC = slower(String)
    if LC == "all" or LC == "others" then
        return getOthers()
    elseif LC == "me" then
        return {Player}
    elseif LC == "random" then
        local Others = getOthers()
        return Others[math.random(#Others)]
    else
        for _,v in next, Services.Players:GetPlayers() do
            if sfind(slower(v.Name), LC) or sfind(slower(v.DisplayName), LC) then
                return v
            end
        end
    end
end

Commands = {}
function addCommand(Names, Description, RequiredArgs, Function)
    local Data = {
        Names = Names,
        Description = Description,
        Function = Function,
        RequiredArgs = RequiredArgs,
        Env = {}
    }
    tinsert(Commands, Data)
end

function getCommand(Name)
    for _,v in next, Commands do
        for _,x in next, v.Names do
            if Name:lower() == x:lower() then
                return v
            end
        end
    end
end

function removeCommand(Name)
    for _,v in next, Commands do
        for i,x in next, v.Names do
            if Name:lower() == x:lower() then
                tremove(Commands, tfind(Commands, v))
                break
            end
        end
    end
end --as of now i think this is broken and i couldn't find a solution :sob: but i'll fix it one day dont worry!

function runCommand(Name, Args)
    local Command = getCommand(Name)
    Command.Function(Args or {})
end

function getEnvironment(Name)
    return getCommand(Name).Env
end

local spoofedProperties = {}
function spoofProperty(Instance, Property)
    for _,v in pairs(spoofedProperties) do
        if not table.find(spoofedProperties, {Instance, Property}) then
            local oldValue = Instance[Property]
            local oldIndex = hookmetamethod(game, "__index", function(Self, Key)
                if Self == Instance and Key == Property then
                    return oldValue
                end
                return oldIndex(Self, Key)
            end)
        end
    end
end

--=> Core <=--

for _,v in next, listfiles("PeaAPI/addons") do
    loadfile(v)()
end -- executes plugins (stolen directly from moonprompt!!!)

addCommand({"setprefix"}, "sets prefix for API", 1, function(Message, Args, Targets)
    local newPrefix = Args[1]
    SaveConfig({
        Prefix = newPrefix
    })
end)

addCommand({"info"}, "gives info on a command", 1, function(Messasge, Args, Targets)
    local Command = getCommand(Args[1])
    if Command then
        print(Command.Description)
    end
end)

addCommand({"commands", "cmds"}, "lists commands", 0, function(Message, Args, Targets)
    for _,v in next, Commands do
        print(v.Names[1])
    end
end)

addCommand({"whitelist"}, "whitelists a target", 1, function(Message, Args, Targets)
    for _,v in next, Targets do
        tinsert(Whitelisted, v)
    end
end)

addCommand({"blacklist"}, "blacklists a target", 1, function(Message, Args, Targets)
    for _,v in next, Targets do
        local Found = tfind(Whitelisted, v)
        if Found then
            tremove(Whitelisted, Found)
        end
    end
end)

addCommand({"import"}, "imports an addon", 1, function(Message, Args)
    local Addon = Args[1]
    pcall(function()
        writefile("PeaAPI/addons/" .. Addon, "https://raw.githubusercontent.com/PeaPattern/Pea-API-v2.0/addons/" . Addon)
        loadfile("PeaAPI/addons/" .. Addon)()
    end)
end) --skidded straight from moonprompt again :yawn:

local Event = Services.ReplicatedStorage.DefaultChatSystemChatEvents
Event.OnMessageDoneFiltering.OnClientEvent:Connect(function(Object)
    local Speaker = getPlayer(Object.FromSpeaker)
    if tfind(Whitelisted, Speaker) then
        local Message = Object.Message or ""
        local Prefix = LoadConfig().Prefix
        for _,v in next, Commands do
            local Names = v.Names
            local RequiredArgs = v.RequiredArgs
            local Function = v.Function
            for i,x in next, Names do
                if slower(ssub(Message, 1, slen(x) + slen(Prefix))) == slower(Prefix) .. slower(x) then
                    local Args = {}
                    if ssub(Message, slen(x) + slen(Prefix) + 2) then
                        Args = ssplit(ssub(Message, slen(x) + slen(Prefix) + 2), " ")
                    end
                    local Targets = {}
                    if #Args >= 1 then
                        for _,v in next, Args do
                            local Target = getPlayer(v)
                            if Target then
                                tinsert(Targets, Target)
                            end
                        end
                    end
                    if #Args >= RequiredArgs then
                        Function(Message, Args, Targets)
                    end
                end
            end
        end
    end
end)
