GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
-- 要导入的模块
CPS = { CORE = {}, DATA = {}, DEBUG = true }

local MOD_NAME = "cps_test"

modimport("core/reload.lua")
modimport("core/data.lua")
modimport("core/main.lua")

-- 创建全局监听
AddSimPostInit(function()
    -- 通过 GLOBAL 表访问 TheWorld，并检查是否在主世界
    if GLOBAL.TheWorld and GLOBAL.TheWorld.ismastersim then
        if not GLOBAL.TheWorld.ismastersim then return false end

        -- 需要实时监控的模块
        local WATCH_FILE_LIST = { "modinfo.lua", "modmain.lua", "core/main.lua", "core/data.lua" }

        -- 监听文件的时间间隔
        local RELOAD_INTERVAL = 1

        -- 你的初始化代码可以安全地放在这里
        SetupReloadTimer(WATCH_FILE_LIST, RELOAD_INTERVAL, MOD_NAME)
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
    if not TheWorld.ismastersim then return end
    inst:RemoveComponent("container") -- 移除原版容器功能

    -- 修改名称
    inst:AddComponent("named")
    inst.xianzhou = 200 --初始233线轴
    inst.components.named:SetName("缝纫机\n线轴" .. inst.xianzhou)

    -- 添加被锤子敲销毁
    inst.components.workable:SetOnFinishCallback(CPS.CORE.OnHammered)

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

            -- 修复主逻辑
            CPS.CORE.Main(inst)
        end)
    end)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(CPS.CORE.SetAcceptTest)
    inst.components.trader.onaccept = CPS.CORE.Onaccept

    inst.OnSave = CPS.CORE.OnSave
    inst.OnLoad = CPS.CORE.OnLoad
end)

--排序函数
local CRAFTING_FILTERS = GLOBAL.CRAFTING_FILTERS
local function ChangeSortKey(recipe_name, recipe_reference, filter, after)
    local recipes = CRAFTING_FILTERS[filter].recipes
    local recipe_name_index
    local recipe_reference_index

    for i = #recipes, 1, -1 do
        if recipes[i] == recipe_name then
            recipe_name_index = i
        elseif recipes[i] == recipe_reference then
            recipe_reference_index = i + (after and 1 or 0)
        end
        if recipe_name_index and recipe_reference_index then
            if recipe_name_index >= recipe_reference_index then
                table.remove(recipes, recipe_name_index)
                table.insert(recipes, recipe_reference_index, recipe_name)
            else
                table.insert(recipes, recipe_reference_index, recipe_name)
                table.remove(recipes, recipe_name_index)
            end
            break
        end
    end
end
ChangeSortKey("sewingmachine", "sewing_kit", "CLOTHING", true)
--胡须可交易
AddPrefabPostInit("stinger", function(inst)
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("tradable")
end)
