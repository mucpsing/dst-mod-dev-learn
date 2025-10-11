--[[
 * @Author: CPS
 * @email: 373704015@qq.com
 * @Date: 2025-10-11 08:19:15.040248
 * @Last Modified by: CPS
 * @Last Modified time: 2025-10-11 08:18:56.016080
 * @Filename modmain.lua
 * @Description: 缝纫机重置mod入口
]]
--

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })
-- 要导入的模块
CPS = { CORE = {}, DATA = {}, DEBUG = false, UTILS = {}, EFFECT = {} }

local MOD_NAME = "cps_test"

modimport("core/reload.lua") -- DEBUG
modimport("core/const.lua") -- 常量依赖
modimport("core/main.lua") -- 核心逻辑

-- 创建全局监听
AddSimPostInit(function()
    -- 通过 GLOBAL 表访问 TheWorld，并检查是否在主世界
    if GLOBAL.TheWorld and GLOBAL.TheWorld.ismastersim then
        if not GLOBAL.TheWorld.ismastersim then return false end

        -- 需要实时监控的模块
        local WATCH_FILE_LIST = { "modinfo.lua", "modmain.lua", "core/main.lua", "core/const.lua" }

        -- 监听文件的时间间隔
        local RELOAD_INTERVAL = 1

        -- 你的初始化代码可以安全地放在这里
        CPS.UTILS.SetupReloadTimer(WATCH_FILE_LIST, RELOAD_INTERVAL, MOD_NAME)
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

local MOD_CONFIG = {
    REPAIR_ARMOR = GetModConfigData("REPAIR_ARMOR"),
    REPAIR_CLOTHING = GetModConfigData("REPAIR_CLOTHING"),
    REPAIR_UN_FUELED = GetModConfigData("REPAIR_UN_FUELED"),
    REPAIR_RANGE = GetModConfigData("REPAIR_RANGE"),
    REPAIR_XIANZHOU = GetModConfigData("REPAIR_XIANZHOU"),
    REPAIR_INTERVAL_TIME = GetModConfigData("REPAIR_INTERVAL_TIME"),
}

local INST_INFO = {}

-- 缝纫机添加修补功能
AddPrefabPostInit("yotb_sewingmachine", function(inst)
    -- 仅服务器运行
    if not TheWorld.ismastersim then return end
    inst:RemoveComponent("container") -- 移除原版容器功能

    -- 修改名称
    inst.xianzhou = 200 --初始233线轴
    if not inst.components.named then inst:AddComponent("named") end
    inst.components.named:SetName("缝纫机\n线轴" .. inst.xianzhou)

    -- 添加可交互组件（如果尚未添加）旧版或者未来改版兼容
    if not inst.components.inspectable then inst:AddComponent("inspectable") end

    -- 添加被锤子敲销毁
    inst.components.workable:SetOnFinishCallback(CPS.CORE.OnHammered)

    -- 添加交易组件，可以接收物品来填充线轴
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(CPS.CORE.SetAcceptTest)
    inst.components.trader.onaccept = CPS.CORE.OnAccept
    inst.OnSave = CPS.CORE.OnSave
    inst.OnLoad = CPS.CORE.OnLoad

    local intervalTask
    local taskIntervalTime = MOD_CONFIG.REPAIR_INTERVAL_TIME or 0.33 --监测间隔
    inst:DoTaskInTime(math.random() * 3, function() --  延时执行，多个缝纫机不会那么整齐
        -- 记录位置
        local x, y, z = inst.Transform:GetWorldPosition()
        INST_INFO.x = x
        INST_INFO.y = y
        INST_INFO.z = z

        -- 周期执行
        intervalTask = inst:DoPeriodicTask(taskIntervalTime, function()
            -- 被烧毁，终止任务
            if inst:HasTag("burnt") then
                inst.components.named:SetName("缝纫机被烧毁，已经无法使用\n剩余线轴" .. inst.xianzhou)

                if intervalTask then
                    intervalTask:Cancel()
                    intervalTask = nil
                end

                return false
            end

            -- 正常执行任务
            CPS.CORE.Loop(inst, MOD_CONFIG, INST_INFO)

            -- DEBUG
            if CPS.DEBUG then CPS.CORE.Test(inst, MOD_CONFIG, INST_INFO) end
        end)
    end)
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
-- 将缝纫机排序在修补工具后面
ChangeSortKey("sewingmachine", "sewing_kit", "CLOTHING", true)

-- 在支持填充的物品上加入对应的xianzhou价值
AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return inst end

    for itemPrefab, _ in pairs(CPS.DATA.ITEM_XIANZHOU_RANGE) do
        if inst.prefab == itemPrefab and not inst.components.tradable then inst:AddComponent("tradable") end
    end
end)

--[[
c_give("stinger", 40)

c_give("armorwagpunk")

c_spawn("spider", 10)
]]
