local tag = "Quiz"
local white = Color(255, 255, 255)
local orange = Color(255, 150, 0)
local quiz_data
net.Receive(tag, function()
    local cmd = net.ReadString()
    if cmd == "msg" then
        local msg = net.ReadString()
        chat.AddText(orange, "[Викторина] ", white, msg)
    end

    if cmd == "menu" then
        local m = vgui.Create("DFrame")
        m:SetSize(ScrW() * 0.3, ScrH() * 0.5)
        m:Center()
        m:SetTitle("Quiz / Управление")
        m:MakePopup()
        m.cachedata = tostring(quiz_data)
        m.Think = function()
            if tostring(quiz_data) ~= m.cachedata then
                m:Remove()
                RunConsoleCommand(tag, "menu")
            end
        end

        local quiz_list = m:Add("DListView")
        quiz_list:Dock(FILL)
        quiz_list:SetMultiSelect(false)
        quiz_list:AddColumn("Название")
        quiz_list:AddColumn("Вопрос")
        quiz_list:AddColumn("Ответ")
        quiz_list.OnRowSelected = function(lst, index, pnl)
            local get_quest_name = pnl:GetColumnText(1)
            local get_quest = pnl:GetColumnText(2)
            local get_quest_ans = pnl:GetColumnText(3)
            local dm = DermaMenu()
            dm:AddOption("Запустить", function()
                net.Start(tag)
                net.WriteString("start")
                net.WriteString(get_quest_name)
                net.SendToServer()
            end):SetIcon("icon16/clock_play.png")

            if get_quest ~= "Функция" then
                dm:AddOption("Редактировать", function()
                    Derma_StringRequest("Викторина / Редактировать", "Введите название", get_quest_name, function(questname)
                        Derma_StringRequest("Викторина / Редактировать", "Введите вопрос", get_quest, function(questtxt)
                            Derma_StringRequest("Викторина / Редактировать", "Введите ответ", get_quest_ans, function(anstxt)
                                net.Start(tag)
                                net.WriteString("edit")
                                net.WriteString(questname)
                                net.WriteString(questtxt)
                                net.WriteString(anstxt)
                                net.SendToServer()
                            end, _, "Дальше", "Отменить")
                        end, _, "Дальше", "Отменить")
                    end, _, "Сохранить", "Отменить")
                end):SetIcon("icon16/pencil.png")

                dm:AddOption("Удалить", function()
                    net.Start(tag)
                    net.WriteString("remove")
                    net.WriteString(get_quest_name)
                    net.SendToServer()
                end):SetIcon("icon16/cancel.png")
            end

            dm:AddOption("Закрыть", function() end):SetIcon("icon16/cross.png")
            dm:Open()
        end

        for k, v in pairs(quiz_data) do
            quiz_list:AddLine(k, v.quest, v.ans)
        end

        local add_btn = m:Add("DButton")
        add_btn:SetSize(0, 30)
        add_btn:Dock(BOTTOM)
        add_btn:SetText("Добавить")
        add_btn:SetIcon("icon16/add.png")
        add_btn.DoClick = function()
            Derma_StringRequest("Викторина / Добавить", "Введите название", "", function(questname)
                Derma_StringRequest("Викторина / Добавить", "Введите вопрос", "", function(questtxt)
                    Derma_StringRequest("Викторина / Добавить", "Введите ответ", "", function(anstxt)
                        net.Start(tag)
                        net.WriteString("add")
                        net.WriteString(questname)
                        net.WriteString(questtxt)
                        net.WriteString(anstxt)
                        net.SendToServer()
                    end, _, "Дальше", "Отменить")
                end, _, "Дальше", "Отменить")
            end, _, "Сохранить", "Отменить")
        end
    end

    if cmd == "update" then quiz_data = net.ReadTable() end
end)