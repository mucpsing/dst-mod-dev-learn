--[[
 * @Author: CPS
 * @email: 373704015@qq.com
 * @Date: 
 * @Last Modified by: CPS
 * @Last Modified time: 2025-10-11 08:18:56.016080
 * @Filename main.lua
 * @Description: 缝纫机核心逻辑
]] --
-- ============================================================
-- # 特效管理
-- ============================================================

-- 裁缝中的特效
-- inst.AnimState:PushAnimation("active_loop") -- 裁缝动作
-- inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/LP", snd) -- 裁缝的声音
-- inst.SoundEmitter:KillSound("snd")

-- inst.SoundEmitter:KillAllSounds()
-- 默认静止状态
-- inst.AnimState:PlayAnimation("idle") -- 待机缝纫机

-- 被锤子敲击或者刚使用完
-- inst.AnimState:PlayAnimation("hit") -- 实体震动以下，可以用作被锤子敲击，或者打开关闭后的动效

-- 打开头部容器
-- inst.AnimState:PlayAnimation("open") -- 整个缝纫机头部打开
-- inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/open")

-- 关闭头部容器
-- inst.AnimState:PlayAnimation("close") -- 缝纫机头部关闭还原
-- inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/close")

-- 修补装备
-- inst.SoundEmitter:PlaySound("yotr_2023/common/pillow_hit_steelwool")  -- 修补装备时的声效

-- inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/stop")
-- inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/done")

-- Log("mod配置: " .. config.REPAIR_RANGE)

-- if inst.SoundEmitter.PlayingSound then inst.SoundEmitter:PlayingSound() end

local function PlayEffect(inst, item, offsetY)
    local x, y, z = item.Transform:GetWorldPosition()
    local fxfire = SpawnPrefab("attackfx_handpillow_steelwool")

    if offsetY then y = y + offsetY end

    fxfire.Transform:SetPosition(x, y, z)
    fxfire.Transform:SetScale(0.5, 0.5, 0.5)
    -- inst.AnimState:PushAnimation("active_loop", false)
end

local function PlaySound(inst)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("yotr_2023/common/pillow_hit_steelwool")
        inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/LP", "start_repair")
    end
end

local function EffectOnRepairStart(inst)
    inst.AnimState:PushAnimation("active_loop")
    inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/LP", "start_repair")
end
local function EffectOnRepairStop(inst)
    inst.AnimState:PlayAnimation("idle", false) -- 待机缝纫机
    inst.SoundEmitter:KillSound("start_repair")
end

local function EffectOnItemAccept(inst)
    -- inst.AnimState:PlayAnimation("hit") -- 实体震动以下，可以用作被锤子敲击，或者打开关闭后的动效
    inst.AnimState:PlayAnimation("open")
    inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/open")

    inst:DoTaskInTime(0.5, function(inst)
        inst.AnimState:PlayAnimation("close")
        inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/close")
        inst.AnimState:PushAnimation("idle", false)
    end)
end

-- ============================================================
-- # 修复逻辑
-- ============================================================
local function CanRepairHealth(item)
    -- 白名单判断
    if not CPS.DATA.HEALTH_PREFAB_LIST[item.prefab] then return false end

    -- 存在health组件
    if item.components.health and item.components.health.DoDelta then
        if not item.components.health:IsDead() then return true end
    end

    return false
end

local function IsArmor(item)
    if item.components.armor and item.components.armor.Repair then return true end

    return false
end

local function IsCanFixByFuel(item)
    if item.components.fueled and item.components.fueled.fueltype == FUELTYPE.USAGE and item.components.fueled.DoDelta then return true end

    return false
end

local function IsContainer(item)
    if item and item.components and item.components.container then return true end

    return false
end

local function UpdateXianzhou(inst, need_xianzhou)
    inst.xianzhou = inst.xianzhou + need_xianzhou
    inst.components.named:SetName("缝纫机\n线轴" .. inst.xianzhou)
end

local function HasEnoughXianzhou(inst, count, modConfig)
    local need_xianzhou = count * modConfig.REPAIR_XIANZHOU

    if inst.xianzhou > need_xianzhou then
        UpdateXianzhou(inst, -need_xianzhou)
        return true
    end

    return false
end

-- 修复装备
local function TryRepair(inst, thePlayer, item, offsetY, modConfig)
    if not item then return 0 end

    local RepairCount = 0
    local showName = item.GetDisplayName and item:GetDisplayName() or item.prefab

    -- 修复护甲类装备
    if IsArmor(item) then
        -- Log("armor" .. showName)
        if item:HasTag("broken") and CPS.DATA.FORGEREPAIR_LIST[item.prefab] then
            Log("armor1" .. showName)

            if item.components.forgerepairable and item.components.forgerepairable.Repair then
                RepairCount = 15
                if HasEnoughXianzhou(inst, RepairCount, modConfig) then
                    local repair_item = SpawnPrefab(CPS.DATA.FORGEREPAIR_LIST[item.prefab]) -- 创建修复材料
                    item.components.forgerepairable:Repair(thePlayer, repair_item)
                    repair_item:Remove() -- 删除材料（可选，如果只是模拟）
                end
            end
        elseif item.components.armor:GetPercent() < 0.99 then
            RepairCount = 1
            if HasEnoughXianzhou(inst, RepairCount, modConfig) then
                Log(item.prefab .. "] armor修复: " .. showName .. tostring(item.components.armor:GetPercent()))
                item.components.armor:Repair(10)
            end
        end

    -- 修复衣物（可通过修补工具修复的）
    elseif IsCanFixByFuel(item) then
        if item.components.fueled:GetPercent() < 0.99 then
            RepairCount = 1
            if HasEnoughXianzhou(inst, RepairCount, modConfig) then
                Log("fueled修复: " .. showName .. tostring(item.components.fueled:GetPercent()))
                item.components.fueled:DoDelta(40)
            end
        end

    -- 修复可以回血的物品，如大熊
    elseif CanRepairHealth(item) then
        if item.components.health:GetPercent() < 0.99 then
            RepairCount = 1
            if HasEnoughXianzhou(inst, RepairCount, modConfig) then
                Log("health修复: " .. showName .. tostring(item.components.health:GetPercent()))
                item.components.health.DoDelta(1)
            end
        end
    elseif item.components.repairable then
        -- Log("repairable修复: " .. showName)
        RepairCount = 0
    else
        -- Log("不处理: " .. showName)
        RepairCount = 0
    end

    if RepairCount > 0 then
        -- 播放修复特效
        PlayEffect(inst, item, offsetY)
        PlaySound(inst)

        EffectOnRepairStart(inst)
    end

    return RepairCount
end

local function RepairInContainer(inst, thePlayer, item, offsetY, modConfig)
    local container = item.components.container
    if not container or not container.GetNumSlots then return 0 end

    local RepairCount = 0
    for i = 1, container:GetNumSlots() do
        local eachItem = container:GetItemInSlot(i)

        -- eachItem可能是空的
        if not eachItem then return RepairCount end

        RepairCount = TryRepair(inst, thePlayer, eachItem, offsetY, modConfig) + RepairCount
    end

    return RepairCount
end

local function CheckItemCanRepair(item)
    -- 确保实体有效且有prefab名称
    if not item or not item.prefab then return false end

    -- 是否实体
    if not item.components.inventory then return false end

    -- 是否被燃烧过
    if item.HasTag and item:HasTag("burnt") then return false end

    return true
end

-- 主函数：获取并打印第一个玩家附近的所有实体
local function GetItemToRepair(inst, modConfig, instInfo)
    if inst.xianzhou <= 0 then return end

    -- 1. 设置搜索范围
    local search_range = modConfig.REPAIR_RANGE and 3.33 * modConfig.REPAIR_RANGE or 1

    -- 2. 获取玩家位置并查找周围实体，暂时尝试从instInfo获取，性能优化
    -- local x, y, z = inst.Transform:GetWorldPosition()

    -- 3. 仅获取带player便签的物品，地上的忽略
    local searchItemList = GLOBAL.TheSim:FindEntities(instInfo.x, instInfo.y, instInfo.z, search_range, { "player" })
    -- local searchItemList = GLOBAL.TheSim:FindEntities(x, y, z, search_range, { "player" })
    -- local searchItemList = GLOBAL.TheSim:FindEntities(x, y, z, search_range)

    local DO_NOTHING = false
    local BodyOffsetY = 0.5
    local RepairCount = 0

    -- 4. 遍历并打印实体的prefab名称
    for i, target in pairs(searchItemList) do
        -- 最基础的有效物品判断
        if not CheckItemCanRepair(target) then
            DO_NOTHING = true

        -- 遍历玩家
        elseif target:HasTag("player") and not target:HasTag("playerghost") then
            local inv = target.components.inventory
            local thePlayer = target
            -- 装备栏
            for k, eachSlotItem in pairs(CPS.DATA.SLOT_DATA_LIST) do
                if GLOBAL.EQUIPSLOTS[eachSlotItem.key] then
                    local slotItem = inv:GetEquippedItem(EQUIPSLOTS[eachSlotItem.key])
                    if eachSlotItem.key == "BACK" and IsContainer(slotItem) then
                        -- 背包栏
                        RepairCount = RepairInContainer(inst, thePlayer, slotItem, eachSlotItem.offsetY, modConfig) + RepairCount
                    else
                        -- 其他装备栏
                        RepairCount = TryRepair(inst, thePlayer, slotItem, eachSlotItem.offsetY, modConfig) + RepairCount
                    end
                end
            end

            -- 物品栏
            for _slot, slotItem in pairs(target.components.inventory.itemslots) do
                if slotItem and slotItem:IsValid() then
                    if slotItem and slotItem.prefab then RepairCount = TryRepair(inst, thePlayer, slotItem, BodyOffsetY, modConfig) + RepairCount end
                end
            end
        else
            -- 周围的所有物品，包含玩家
            DO_NOTHING = true
        end
    end
end

-- ============================================================
-- # 主逻辑
-- ============================================================
local function ModCheck()
    if not CPS.DATA or not CPS.DATA then Log("加载DATA失败") end
    if not GLOBAL.ThePlayer then Log("找不到GLOBAL.ThePlayer") end
    if not GLOBAL.AllPlayers then Log("找不到GLOBAL.AllPlayers") end
    if not GLOBAL.TheNet then Log("找不到GLOBAL.TheNet") end
end

local function Test(inst, modConfig) Log("test1") end

if CPS then
    CORE = CPS.CORE
    DATA = CPS.DATA

    local MAX_XIANZHOU = 8000

    CORE.ModCheck = ModCheck

    CORE.Loop = function(inst, modConfig, instInfo)
        GetItemToRepair(inst, modConfig, instInfo)

        EffectOnRepairStop(inst)
    end

    CORE.OnHammered = function(inst, worker)
        if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then inst.components.burnable:Extinguish() end

        if inst.components.container ~= nil then inst.components.container:DropEverything() end

        inst.components.lootdropper:SpawnLootPrefab("goldnugget")
        inst.components.lootdropper:SpawnLootPrefab("silk")
        -- inst.components.lootdropper:SpawnLootPrefab("silk")
        inst.components.lootdropper:DropLoot()

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("metal")
        local fx2 = SpawnPrefab("junk_break_fx")
        fx2.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:Remove()
    end

    CORE.SetAcceptTest = function(inst, item, giver)
        local canAccept = true

        -- 合法性检查
        if not giver or not giver:HasTag("player") then
            canAccept = false
        elseif not inst.xianzhou or inst.xianzhou >= MAX_XIANZHOU then
            canAccept = false
        elseif not DATA.ITEM_XIANZHOU_RANGE[item.prefab] then
            canAccept = false
        end

        -- 不支持的物品，人物吐槽
        if not canAccept then
            if giver.components.talker then
                local msg = DATA.REJECT_LINES[giver.prefab] or DATA.REJECT_LINES["default"] or "......"
                giver.components.talker:Say(msg)
            end
            return false
        end

        local need_xianzhou = 0

        -- 堆叠物品放在处理
        if item.components.stackable then
            local stackSize = item.components.stackable:StackSize()
            local itemRange = DATA.ITEM_XIANZHOU_RANGE[item.prefab]
            if itemRange.min == itemRange.max then
                need_xianzhou = math.floor(itemRange.min * (item.components.fueled and item.components.fueled:GetPercent() or 1))
            else
                -- 随机价值材料
                need_xianzhou = math.random(itemRange.min, itemRange.max) * stackSize
            end

            -- 线轴是否能合法的添加已经在SetAcceptTest函数中进行判断，这里的现在必然需要添加到缝纫机
            if inst.xianzhou >= MAX_XIANZHOU then return false end

            UpdateXianzhou(inst, need_xianzhou)

            item:Remove()
            EffectOnItemAccept(inst)

            return false
        end

        return canAccept
    end

    CORE.OnAccept = function(inst, giver, item)
        local need_xianzhou = 0
        local stackSize = item.components.stackable and item.components.stackable:StackSize() or 1
        local itemRange = DATA.ITEM_XIANZHOU_RANGE[item.prefab]

        if itemRange.min == itemRange.max then
            -- 固定价值材料（如帽子）
            need_xianzhou = math.floor(itemRange.min * (item.components.fueled and item.components.fueled:GetPercent() or 1))
        else
            -- 随机价值材料
            need_xianzhou = math.random(itemRange.min, itemRange.max) * stackSize
        end

        -- 线轴是否能合法的添加已经在SetAcceptTest函数中进行判断，这里的现在必然需要添加到缝纫机
        UpdateXianzhou(inst, need_xianzhou)
    end

    CORE.OnSave = function(inst, data)
        if inst.xianzhou then data.xianzhou = inst.xianzhou end
        if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then data.burnt = true end
    end

    CORE.OnLoad = function(inst, data)
        if data ~= nil then
            if data.xianzhou and inst.xianzhou then inst.xianzhou = data.xianzhou end
            if data.burnt then inst.components.burnable.onburnt(inst) end
        end
    end
end
