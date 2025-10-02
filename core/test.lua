local SLOT_DATA_LIST = {
    { key = "BELLY", offsetY = 0.5 },
    { key = "NECK", offsetY = 0.5 },
    -- { key = "BACK", offsetY = 0.5 },
    { key = "HANDS", offsetY = 0.5 },
    { key = "HEAD", offsetY = 2.5 },
    { key = "BODY", offsetY = 0.5 },
    { key = "SHOES", offsetY = -0.3 },
}

-- 一些修复时以恢复血量为展示的物品
local HEALTH_PREFAB_LIST = {
    daidai = true,
    bernie_active = true,
    bernie_big = true,
}

local function PlayEffect(inst, item, offestY)
    local x, y, z = item.Transform:GetWorldPosition()
    local fxfire = SpawnPrefab("attackfx_handpillow_steelwool")

    if not Materials then Log("找不到Materials") end

    if offestY then y = y + offestY end

    fxfire.Transform:SetPosition(x, y, z)
    fxfire.Transform:SetScale(0.5, 0.5, 0.5)
end

local function PlaySound(inst)
    if inst.SoundEmitter then inst.SoundEmitter:PlaySound("yotr_2023/common/pillow_hit_steelwool") end
end

local function CanRepairHealth(item)
    -- 白名单判断
    if not HEALTH_PREFAB_LIST[item.prefab] then return false end

    -- 存在health组件
    if item.components.health and item.components.health.DoDelta then
        if not item.components.health:IsDead() then return true end
    end
end

local function IsArmor(item)
    if item.components.armor and item.components.armor.Repair then return true end

    return false
end

local function IsCanFixByFuel(item)
    if item.components.fueled and item.components.fueled.fueltype == FUELTYPE.USAGE and item.components.fueled.DoDelta then return true end

    return false
end

-- 修复装备
local function TryRepair(TheTarget, item, offsetY)
    if not item then return false end

    local didRepair = false
    local didPlaySound = false

    local showName = item.prefab
    if item.GetDisplayName then showName = item:GetDisplayName() end

    -- 修复护甲类装备
    if IsArmor(item) then
        if item.components.armor:GetPercent() < 0.99 then
            Log("armor修复: " .. showName .. tostring(item.components.armor:GetPercent()))

            item.components.armor:Repair(10)
            didRepair = true
        end

    -- 修复衣物（可通过修补工具修复的）
    elseif IsCanFixByFuel(item) then
        if item.components.fueled:GetPercent() < 0.99 then
            Log("fueled修复: " .. showName .. tostring(item.components.fueled:GetPercent()))

            item.components.fueled:DoDelta(40)
            didRepair = true
        end
    elseif CanRepairHealth(item) then
        if item.components.health:GetPercent() < 0.99 then
            Log("health修复: " .. showName .. tostring(item.components.health:GetPercent()))

            item.components.health.DoDelta(1)
            didRepair = true
        end
    elseif item.components.repairable then
        Log("repairable修复: " .. showName)
    else
        -- Log("不处理: " .. showName)
        a = nil
    end

    if didRepair then
        -- 播放修复特效
        PlayEffect(TheTarget, item, offsetY)
        PlaySound(TheTarget or ThePlayer)
    end

    return didRepair
end

local function checkItemCanRepair(target)
    -- 确保实体有效且有prefab名称
    if not target or not target.prefab then return false end

    -- 是否实体
    if not target.components.inventory then return false end

    -- 是否被燃烧过
    if target.HasTag and target:HasTag("burnt") then return false end

    return true
end

-- 主函数：获取并打印第一个玩家附近的所有实体
local function GetItemToRepair(inst, range)
    if not GLOBAL then Log("找不到GLOBAL") end
    if not GLOBAL.ThePlayer then Log("找不到GLOBAL.ThePlayer") end
    if not GLOBAL.AllPlayers then Log("找不到GLOBAL.AllPlayers") end

    -- 1. 设置搜索范围
    local search_range = 3.33 * (range or 1)

    -- 2. 安全地获取第一个玩家
    local players = GLOBAL.ThePlayer and { GLOBAL.ThePlayer } or GLOBAL.AllPlayers
    if not players or #players == 0 then
        Log("警告：未找到任何玩家。")
        return
    end

    -- [dev]
    local TheTarget = inst or players[1]

    -- 3. 获取玩家位置并查找周围实体
    local x, y, z = TheTarget.Transform:GetWorldPosition()
    local searchItemList = GLOBAL.TheSim:FindEntities(x, y, z, search_range, { "player" })

    local DO_NOTHING = false
    local RepairCount = 0

    -- 4. 遍历并打印实体的prefab名称
    for i, target in ipairs(searchItemList) do
        -- 最基础的有效物品判断
        if not checkItemCanRepair(target) then
            DO_NOTHING = true

        -- 这里使用处理人物身上的物品
        elseif target:HasTag("player") then
            local inv = target.components.inventory

            -- 修复已装备的衣物
            for k, eachItem in pairs(SLOT_DATA_LIST) do
                if GLOBAL.EQUIPSLOTS[eachItem.key] then
                    slotItem = inv:GetEquippedItem(EQUIPSLOTS[eachItem.key])

                    if TryRepair(TheTarget, slotItem, eachItem.offsetY) then RepairCount = RepairCount + 1 end
                end
            end
        else
            -- 附近物品，目前不考虑，仅维修玩家穿身上的
            -- TryRepair()
            -- Log("TryRepair ==> 2")
            -- TryRepair(nil, target)
            DO_NOTHING = true
        end
    end

    return RepairCount
end

if CPS then
    CORE = CPS.CORE

    CORE.CheckModel = function()
        -- if Dialogues then Log("Dialogues 已加载123") end
        -- if Materials then Log("Materials 已加载123") end
        do
        end
    end

    CORE.Log = function(msg)
        print(msg)
        if not GLOBAL and not GLOBAL.TheNet then return end

        GLOBAL.TheNet:Announce("[cps dev]: " .. msg)
    end

    CORE.Test = function(inst)
        if not GLOBAL and not GLOBAL.TheNet then return end

        if inst.xianzhou <= 0 then return end

        -- if GLOBAL.Action and AddAction and (AddComponentAction or GLOBAL.AddComponentAction) then
        --     Log("可以添加动作")
        --     AddActionXIANZHOU()
        -- end

        -- 添加可交互组件（如果尚未添加）
        if not inst.components.inspectable then
            inst:AddComponent("inspectable")
            Log("需要添加交互组件")
        end

        CORE.CheckModel()

        local old_xianzhou = inst.xianzhou
        local each_xianzhou_time = 10
        local RepairCount = GetItemToRepair(inst, 2)
        local need_xianzhou = 10 * RepairCount

        -- 更新线轴
        if need_xianzhou >= inst.xianzhou then
            inst.xianzhou = 0
        elseif inst.xianzhou > need_xianzhou then
            inst.xianzhou = inst.xianzhou - need_xianzhou * RepairCount
            inst.components.named:SetName("缝纫机\n线轴" .. inst.xianzhou)
        end
    end

    CORE.OnHammered = function(inst, worker)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then inst.components.burnable:Extinguish() end

        if inst.components.container ~= nil then inst.components.container:DropEverything() end

        inst.components.lootdropper:SpawnLootPrefab("goldnugget")
        inst.components.lootdropper:SpawnLootPrefab("silk")
        inst.components.lootdropper:SpawnLootPrefab("silk")

        inst.components.lootdropper:DropLoot()

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("metal")
        local fx2 = SpawnPrefab("junk_break_fx")
        fx2.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:Remove()
    end

    CORE.SetAcceptTest = function(inst, item, giver)
        -- return Materials.hasItem(item)
        if Materials.itemRange[item.prefab] then
            Log("SetAcceptTest1: " .. item.prefab)
            return true
        else
            Log("SetAcceptTest2: " .. item.prefab)
            return false
        end
    end

    CORE.Onaccept = function(inst, giver, item) Log("Onaccept: " .. item.prefab) end
end
