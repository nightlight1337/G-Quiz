local a = "quiz/"
if SERVER then
    AddCSLuaFile(a .. "cl_quiz.lua")
    include(a .. "sv_quiz.lua")
else
    include(a .. "cl_quiz.lua")
end