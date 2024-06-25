local tag = "Quiz"
util.AddNetworkString(tag)
local Quiz = {}
local LastWords = {}
local Folder = tag .. ".txt"
if not Quiz.Modes then Quiz.Modes = {} end
if not Quiz.TextModes then Quiz.TextModes = {} end
function Quiz:Save()
    file.Write(Folder, util.TableToJSON(Quiz.TextModes))
    Quiz:Update()
end

function Quiz:Update()
    if file.Exists(Folder, "DATA") then
        Quiz.TextModes = util.JSONToTable(file.Read(Folder, "DATA"))
    else
        file.Write(Folder, util.TableToJSON({}))
    end

    local ModesToSend = table.Copy(Quiz.TextModes)
    for name, v in pairs(Quiz.Modes) do
        ModesToSend[name] = {
            quest = "Функция",
            ans = "Функция"
        }
    end

    for _, pl in ipairs(player.GetAll()) do
        if not pl:IsSuperAdmin() then continue end
        net.Start(tag)
        net.WriteString("update")
        net.WriteTable(ModesToSend)
        net.Send(pl)
    end
end

Quiz:Update()
function Quiz:SendMessage(txt)
    if not txt then return end
    net.Start(tag)
    net.WriteString("msg")
    net.WriteString(txt)
    net.Broadcast()
end

function Quiz:SendPlayerMessage(pl, txt)
    if not IsValid(pl) or not txt then return end
    net.Start(tag)
    net.WriteString("msg")
    net.WriteString(txt)
    net.Broadcast()
end

function Quiz:OpenAdminMenu(pl)
    if not IsValid(pl) then return end
    Quiz:Update()
    net.Start(tag)
    net.WriteString("menu")
    net.Send(pl)
end

function Quiz:Start(name)
    if not name then return end
    table.Empty(LastWords)
    local quest, ans
    for name2, func in pairs(Quiz.Modes) do
        if name == name2 then quest, ans = func() end
    end

    for name2, v in pairs(Quiz.TextModes) do
        if name == name2 then quest, ans = v.quest, v.ans end
    end

    if not quest or not ans then return end
    Quiz:SendMessage(quest)
    hook.Add("PlayerSay", tag, function(pl, txt) LastWords[pl] = txt end)
    timer.Create("EndQuiz", 10, 1, function() Quiz:End(name, ans) end)
end

function Quiz:End(name, ans)
    hook.Remove("PlayerSay", tag)
    local winners = {}
    for pl, txt in pairs(LastWords) do
        if txt == ans then winners[pl:Nick()] = pl:SteamID() end
    end

    local countwinner = table.Count(winners)
    if countwinner >= 1 then
        Quiz:SendMessage((countwinner == 1 and "Игрок %s дал правильный ответ" or "Игроки %s дали правильный ответ"):format(Quiz:FormatNicks(winners)))
    else
        Quiz:SendMessage("Никто не дал правильный ответ")
    end
end

function Quiz:AddTextMode(name, quest, ans)
    if not name or not quest or not ans then return end
    Quiz.TextModes[name] = {
        quest = quest,
        ans = ans
    }

    Quiz:Save()
end

function Quiz:AddMode(name, func)
    if not name then return end
    if not isfunction(func) then return end
    local quest, ans = func()
    if not quest or not ans then return end
    Quiz.Modes[name] = func
    Quiz:Update()
end

function Quiz:RemoveTextMode(name)
    Quiz.TextModes[name] = nil
    Quiz:Save()
end

function Quiz:FormatNicks(tbl)
    local txt = ""
    local keys = table.GetKeys(tbl)
    local count = table.Count(keys)
    if count <= 1 then
        for i, k in ipairs(keys) do
            txt = k
        end
        return txt
    end

    for i, k in ipairs(keys) do
        if i < count then
            txt = txt .. k .. (i <= count - 2 and ", " or "")
        else
            txt = txt .. " и " .. k
        end
    end
    return txt
end

Quiz:AddMode("math_easy", function()
    local a = math.random(1, 10)
    local b = math.random(1, 10)
    return ("Сколько будет %s + %s?"):format(a, b), tostring(a + b)
end)

concommand.Add(tag, function(pl, _, args)
    local count_args = table.Count(args)
    if count_args < 1 or not pl:IsSuperAdmin() then
        Quiz:SendPlayerMessage(pl, "У вас недостаточно прав или вы забыли указать команду.")
        return
    end

    if args[1] == "menu" then Quiz:OpenAdminMenu(pl) end
end)

net.Receive(tag, function(len, pl)
    if not pl:IsSuperAdmin() then return end
    local cmd = net.ReadString()
    if cmd == "start" then
        local name = net.ReadString()
        Quiz:Start(name)
    end

    if cmd == "add" or cmd == "edit" then
        local name = net.ReadString()
        local ans = net.ReadString()
        local quest = net.ReadString()
        if ans == "Функция" or quest == "Функция" then return end
        Quiz:AddTextMode(name, ans, quest)
    end

    if cmd == "remove" then
        local name = net.ReadString()
        Quiz:RemoveTextMode(name)
    end
end)