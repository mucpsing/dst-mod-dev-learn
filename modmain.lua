GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local MOD_NAME = "cps_test"
local RELOAD_INTERVAL = 1
local IMPORT_FILES_LIST = { "modinfo.lua", "modmain.lua", "core/test.lua" }

CPS = { CORE = {} }
modimport("core/reload.lua")
modimport("core/sm_dialogues.lua")
modimport("core/sm_materials.lua")
modimport("core/test.lua")

-- 创建全局监听
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

-- 饥荒 API，添加一个新配方，在不开启活动也能制作这个组件
-- 新建配方是为了不用开启活动也能制作这个重制后的缝纫机
AddRecipe2(
    "sewingmachine",
    { Ingredient("sewing_kit", 1), Ingredient("beefalowool", 6), Ingredient("goldnugget", 6), Ingredient("gears", 3) },
    TECH.SCIENCE_TWO,
    { product = "yotb_sewingmachine_item" },
    { "CLOTHING" }
)

AddPrefabPostInit("yotb_sewingmachine", function(inst)
    if not TheWorld.ismastersim then return inst end
    inst:RemoveComponent("container") -- 移除原版容器功能

    -- 修改名称
    inst:AddComponent("named")
    inst.xianzhou = 200 --初始233线轴
    inst.components.named:SetName("缝纫机\n线轴" .. inst.xianzhou)

    -- 添加被锤子敲销毁
    inst.components.workable:SetOnFinishCallback(CORE.OnHammered)

    local taskIntervalTime = 1 --sec
    local IntervalTask

    inst:DoTaskInTime(math.random() * 3, function()
        local postiton = { x = nil, y = nil, z = nil }
        local x, y, z = inst.Transform:GetWorldPosition()

        -- 周期性任务
        IntervalTask = inst:DoPeriodicTask(taskIntervalTime, function()
            if inst:HasTag("burnt") then
                inst.components.named:SetName("缝纫机被烧毁，已经无法使用\n剩余线轴" .. inst.xianzhou)
                IntervalTask:Cancel()
                return false
            end
            -- 当前实体位置，可优化
            local dh = false
            local ents
            -- 播放声效

            -- 修复物品逻辑
            -- 播放特效

            -- 执行修复，返回需要消耗的线轴

            CPS.CORE.Test(inst)
        end)
    end)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(CORE.SetAcceptTest)
    inst.components.trader.onaccept = CORE.Onaccept
end)
