GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local MOD_NAME = "cps_test"
local RELOAD_INTERVAL = 1 
local IMPORT_FILES_LIST = { "modinfo.lua", "modmain.lua", "test/test.lua" }

modimport("core/utils.lua")
modimport("core/sm_dialogues.lua")
modimport("core/sm_materials.lua")

AddSimPostInit(function()
    -- 通过 GLOBAL 表访问 TheWorld，并检查是否在主世界
    if GLOBAL.TheWorld and GLOBAL.TheWorld.ismastersim then
        Log("TheWorld is ready and we are on the master sim!")

        if not GLOBAL.TheWorld.ismastersim then return false end

        -- 你的初始化代码可以安全地放在这里
        SetupReloadTimer(IMPORT_FILES_LIST, RELOAD_INTERVAL, MOD_NAME)
    else
        Log("TheWorld is not available or we are not on the master sim.")
    end
end)
