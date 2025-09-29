-- 设置当前模块的元表，确保可以访问全局变量。
-- GLOBAL.getfenv(1)：获取当前函数的环境（即模块的全局环境）。
GLOBAL.setmetatable(GLOBAL.getfenv(1), {
    __index = function(self, index) return GLOBAL.rawget(GLOBAL, index) end,
})

modimport("core/sm_materials")
modimport("core/sm_dialogues")
local SM = {}
SM.Dialogues = Dialogues
SM.Materials = Materials

--修草甲芦苇甲，牛帽返牛角，修帐篷
-- AddSimPostInit：饥荒 API，在游戏世界模拟初始化完成后执行函数。
-- 存储物品名称的全局表。
-- 存储制作配方描述的全局表。
-- 自定义 Mod 物品的名称和描述，使其更符合 Mod 的主题。
AddSimPostInit(function()
    STRINGS.NAMES.YOTB_SEWINGMACHINE_ITEM = "缝纫机套件"
    STRINGS.RECIPE_DESC.YOTB_SEWINGMACHINE_ITEM = "用线轴和机器去缝衣服，伙计。"
end)

-- 排序函数
-- 修改制作菜单中配方的排序位置。
-- 根据 after参数，将目标配方移动到参照配方的后面或前面。
-- 让 Mod 添加的新配方（缝纫机）出现在制作菜单中期望的位置（紧挨着缝纫工具包）。
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

--- 添加新配方
local TTT = GetModConfigData("onlyplayer") -- 读取Mod配置
local Shoetime = GLOBAL.KnownModIndex:IsModEnabled("workshop-2039181790") -- 检查特定Mod是否启用
-- 饥荒 API，添加一个新配方。
AddRecipe2(
    "sewingmachine", -- 配方产物
    -- 设置制作材料
    -- "sewing_kit", 1 修补工具1格
    -- "beefalowool", 6 牛毛6格
    -- "goldnugget", 6 , 黄金6个
    -- "gears", 2，齿轮

    { Ingredient("sewing_kit", 1), Ingredient("beefalowool", 6), Ingredient("goldnugget", 6), Ingredient("gears", 2) },
    TECH.SCIENCE_TWO, -- 所需科技等级
    { product = "yotb_sewingmachine_item" }, -- 实际产出的物品
    { "CLOTHING" } -- 所属制作分类，将这个配方归类到 "衣物" 制作标签下。
)

-- 缝纫机的锤击行为
-- 定义当玩家用锤子敲击缝纫机时发生的行为（替换原版行为）。
-- 如果缝纫机在燃烧，熄灭它。
-- 如果缝纫机有容器功能，掉落所有内容物。
-- 掉落战利品：1个金块 + 2个丝绸。
-- 播放金属坍塌和小物件破坏的特效。
-- 移除缝纫机实体。
-- 自定义缝纫机被破锤子坏时的行为和掉落物，使其更符合 Mod 设定。
local function NewOnHammered(inst, worker)
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

----------------------- # 动作定义 #-------------------------
-- 全局的线材阈值定义，将一些特定的物品添加上"线材值"
-- 对所有预制物进行初始化后处理
-- 饥荒 API，对游戏中每一个预制物（Prefab）初始化后执行函数。

AddPrefabPostInitAny(function(inst)
    -- 确保只在主模拟环境中执行（避免在客户端执行）
    if not TheWorld.ismastersim then return inst end

    -- 服务器判断
    if not inst.components.inventoryitem then return end

    -- 检查物品是否有库存组件（确保是可拾取/可携带的物品）
    -- 为后续的缝纫机功能（填充线轴、修复衣物）提供基础数据支持。不同的材料有不同的价值。

    if SM.Materials.hasItem(inst.prefab) then inst.xiancai = SM.Materials.getXianZhouByItem(inst) end
end)

--1、 官方API 添加动作到菜单
-- 如果物品有 inventoryitem组件，将 "填充线轴" 动作添加到可选动作列表。
AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
    -- 档玩家点击裁缝机时触发这个动作
    if target.prefab == "yotb_sewingmachine" and doer:HasTag("player") then table.insert(actions, ACTIONS.XIANZHOU) end
end)

-- 2. 定义动作
-- priority：动作优先级。
-- mount_valid：允许在坐骑上执行
-- str：动作显示文本
-- id：动作唯一标识符。
-- fn：动作执行时的核心逻辑函数。
local XIANZHOU = Action({ priority = 10, mount_valid = true })
XIANZHOU.str = "填充线轴"
XIANZHOU.id = "XIANZHOU"
XIANZHOU.fn = function(act)
    if act.doer and act.target and act.target.xianzhou and act.invobject and act.invobject.xiancai then
        local item = act.invobject
        local winonabuff = act.doer.prefab == "winona" and 1.25 or 1

        -- 定义特殊物品处理表
        local HatsItem = {
            walrushat = true, -- 海象帽：高级保暖帽
            winterhat = true, -- 冬帽：基础保暖帽
            earmuffshat = true, -- 兔耳罩：耳朵保暖装备
            monkey_smallhat = true, -- 猴子帽：趣味装饰帽
            beefalohat = true, -- 牛毛帽：中阶保暖帽
        }

        -- 支持使用特定帽子进行填充
        if HatsItem[item.prefab] then
            -- 返回指定的线轴
            act.target.xianzhou = act.target.xianzhou + math.floor(item.xiancai * winonabuff * item.components.fueled:GetPercent())

            --牛毛帽，除了提供线材值，还会额外掉落一个牛角 (horn)。
            if item.prefab == "beefalohat" then
                -- 创建一个牛角
                local loot = SpawnPrefab("horn")
                loot.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
                local x, y, z = act.target.Transform:GetWorldPosition()
                loot.components.inventoryitem:DoDropPhysics(x, y, z, true)
            end

            item:Remove()
        else
            local Stack = item.components.stackable and item.components.stackable:StackSize() or 1
            for i = 1, Stack do
                act.target.xianzhou = act.target.xianzhou + math.floor(item.xiancai * winonabuff + math.random(-3, 7))
            end
            item:Remove()
        end

        -- 填充物品后播放声效和动作
        act.target.AnimState:PlayAnimation("close")
        act.target.SoundEmitter:KillSound("snd")
        act.target.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/stop")
        act.target.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/done")
        return true

    -- 物品不能作为线材填充，这里角色将进行一个反馈
    elseif act.doer and act.doer.components.talker then
        local msg = SM.Dialogues.getRejectMsg(owner.prefab)
        act.doer.components.talker:Say(msg)
        return true
    end
    return false
end

-- 注册动作
AddAction(XIANZHOU)

-- 3. 添加动作状态处理
for sg, client in pairs({
    wilson = false,
    wilson_client = true,
}) do
    AddStategraphActionHandler(
        sg,

        -- 根据堆叠数量决定动作时长
        ActionHandler(ACTIONS.XIANZHOU, function(inst, action)
            if action.invobject.components.stackable then
                if action.invobject.components.stackable:StackSize() <= 5 then
                    return "domediumaction"
                elseif action.invobject.components.stackable:StackSize() <= 15 then
                    return "dolongaction"
                else
                    return "dolongestaction"
                end
            else
                return "dolongaction"
            end
        end)
    )
end
---------------------------## 缝纫机核心功能 ##---------------------
local function Log(msg)
    print("[ccccccccccccccccccccccccccccccc]" .. msg)
    if not GLOBAL and not GLOBAL.TheNet then return end

    GLOBAL.TheNet:Announce("【Log】" .. msg)
    -- GLOBAL.TheNet:SystemMessage("【SystemMessage2】" .. msg)
end

-- ================= 工具函数 =================
local NEED_XIANZHOU = 2

-- 播放修复音效与特效
local function PlayRepairEffect(inst, target, offsetY, scale)
    Log("PlayRepairEffect")
    if target and target.SoundEmitter then target.SoundEmitter:PlaySound("yotr_2023/common/pillow_hit_steelwool") end
    local fx = SpawnPrefab("attackfx_handpillow_steelwool")
    local x, y, z = target.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, y + (offsetY or 0.5), z)
    fx.Transform:SetScale(scale or 0.5, scale or 0.5, scale or 0.5)
end

-- 消耗线轴（或者惩罚玩家精神值）
local function ConsumeThreadOrSanity(inst, target, sanityDelta)
    Log("ConsumeThreadOrSanity")
    if inst.xianzhou > 0 then
        inst.xianzhou = inst.xianzhou - NEED_XIANZHOU
    elseif target.components.sanity then
        target.components.sanity:DoDelta(sanityDelta or -1.5)
    end
end

-- 修复护甲
local function RepairArmor(inst, target, armor, amount, offsetY)
    Log("RepairArmor")
    if armor and armor.components.armor and armor.components.armor:GetPercent() < 1 then
        armor.components.armor:Repair(amount)
        ConsumeThreadOrSanity(inst, target)
        PlayRepairEffect(inst, target, offsetY, 0.5)
        return true
    end
    return false
end

-- 修复血量（专门给 daidai / bernie）
local function RepairHealth(inst, target, baseAmount, extraAmount)
    Log("RepairHealth")
    if target.components.health and target.components.health:GetPercent() < 1 and not target.components.health:IsDead() then
        target.components.health:DoDelta(baseAmount)
        if extraAmount then target.components.health:DoDelta(extraAmount) end
        ConsumeThreadOrSanity(inst, target)
        PlayRepairEffect(inst, target, 3, 0.5)
        return true
    end
    return false
end

-- 修复 repairable 类型装备
local function RepairRepairable(inst, target, item, offsetY)
    Log("RepairRepairable")
    if item and item.components.repairable then
        if item.components.repairable:Repair() then
            ConsumeThreadOrSanity(inst, target)
            PlayRepairEffect(inst, target, offsetY, 0.5)
            return true
        end
    end
    return false
end

-- 修复耐久度（fueled 类型物品）
local function RepairFueled(inst, target, item, amount, offsetY)
    Log("RepairFueled")
    if item and item.components.fueled and item.components.fueled.fueltype == FUELTYPE.USAGE and item.components.fueled:GetPercent() < 1 then
        item.components.fueled:DoDelta(amount, inst)
        ConsumeThreadOrSanity(inst, target)
        PlayRepairEffect(inst, target, offsetY, 0.5)
        return true
    end
    return false
end

-- 一些需要特殊处理修复的物品
local function RepairSpecialItem(inst, target, target, repairMultiplier, offsetY)
    Log("RepairSpecialItem")
    res = false
    -- 燃料类物品修复（提灯、火把等）
    if target.components.fueled and target.components.fueled:GetPercent() <= 0.99 then
        target.components.fueled:DoDelta(40, nil)
        res = true
    end

    -- 护甲类物品修复（木甲、草甲等）
    if target.components.armor then
        -- 检查耐久是否不满
        if target.components.armor:GetPercent() ~= 1 then
            target.components.armor:Repair(10)
            res = true
        end
    end

    -- 睡袋修复（有使用次数的物品）
    if target.components.sleepingbag and target.components.finiteuses then
        -- 检查耐久是否不满
        if target.components.finiteuses.current ~= target.components.finiteuses.total then
            if math.random() <= 0.02 then
                target.components.finiteuses:Repair(1)
                res = true
            end
        end
    end

    -- 播放声效
    if res then PlayRepairEffect(inst, target, offsetY, 0) end
    return res
end

-- 通用修复尝试函数
local function TryRepair(inst, target, item, repairMultiplier, offsetY)
    if target and target.GetDisplayName then
        local chineseName = target:GetDisplayName()
        Log("TryRepair: =>" .. chineseName)
    else
        Log("TryRepair: => " .. target.prefab)
    end

    if not target then return false end

    if RepairArmor(inst, target, item, 10 * repairMultiplier, offsetY) then return true end
    if RepairFueled(inst, target, item, 40 * repairMultiplier, offsetY) then return true end
    if RepairRepairable(inst, target, item, offsetY) then return true end
    if RepairSpecialItem(inst, target, target, repairMultiplier, offsetY) then return true end

    return false
end



-- 缝纫机核心功能
AddPrefabPostInit("yotb_sewingmachine", function(inst)
    -- 只在服务端执行
    if not TheWorld.ismastersim then return inst end

    -- 1. 修改组件
    inst:RemoveComponent("container") -- 移除原版容器功能
    -- inst.components.container.canbeopened = false

    inst:AddComponent("named") -- 添加命名组件（用于显示自定义名称）
    inst.xianzhou = 233 --初始233线轴
    inst.components.workable:SetOnFinishCallback(NewOnHammered) -- 设置锤击回调

    -- 2. 周期性任务（核心修复逻辑）
    -- 延迟执行以防止缝纫机过于统一
    inst:DoTaskInTime(math.random() * 3, function() -- 防止缝纫机过于统一
        inst:DoPeriodicTask(3, function()
            if inst.niunian then return end

            if inst:HasTag("burnt") then
                inst.components.named:SetName("烧毁的缝纫机")
                return
            end

            -- 查找目标（TTT 为全局开关）
            -- local ents = TTT and TheSim:FindEntities(x, y, z, 7) or TheSim:FindEntities(x, y, z, 4, { "player" })
            -- 查找缝纫机大概3格地皮(3.33一个地皮)
            local x, y, z = inst.Transform:GetWorldPosition()
            local itemList = TheSim:FindEntities(x, y, z, 5)

            -- 如果缝纫机xianzhou这个属于（不再白名单），或者缝纫机线轴为0
            if not inst.xianzhou or inst.xianzhou == 0 then return end

            -- sewing_mannequin未处理

            -- 主循环逻辑
            local repairMultiplier = 1

            for _, target in pairs(itemList) do
                local didRepair = false
                if target:HasTag("playerghost") then
                    didRepair = false

                -- ================= 玩家身上穿戴的 =================
                elseif target:HasTag("player") then
                    Log("1")
                    local inv = target.components.inventory
                    local body, head, hand, shoe

                    if target.prefab == "winona" then repairMultiplier = repairMultiplier * 1.25 end

                    if inv then
                        body = inv:GetEquippedItem(EQUIPSLOTS.BODY)
                        head = inv:GetEquippedItem(EQUIPSLOTS.HEAD)
                        hand = inv:GetEquippedItem(EQUIPSLOTS.HANDS)
                        shoe = inv:GetEquippedItem(EQUIPSLOTS.SHOES) or nil
                    end

                    -- 遍历装备槽，逐个尝试修复
                    local equipSlots = {
                        { item = head, offset = 2 },
                        { item = body, offset = 0.5 },
                        { item = hand, offset = 0.5 },
                        { item = shoe, offset = -0.3 },
                    }
                    
                    for _, slot in pairs(equipSlots) do
                        if TryRepair(inst, target, slot.item, repairMultiplier, slot.offset) then didRepair = true end
                    end
                -- ================= 修复是回血的物件：daidai / bernie =================
                elseif target.prefab == "daidai" or target.prefab == "bernie_active" or target.prefab == "bernie_big" then
                    Log("3")
                    if RepairHealth(inst, target, 1, (target.prefab ~= "daidai") and 8 or nil) then didRepair = true end

                -- ================= 掉落物或其他修复目标 =================
                else
                    Log("2: " .. target.prefab or "empty")
                    local shouldRepair = false

                    -- 物品正在被移动？
                    -- if target:IsInLimbo() then
                    --     Log(string.format("[跳过] LIMBO 状态实体: %s", target.prefab))
                    --     shouldRepair = false
                    -- end

                    -- 只有实际修复了才消耗资源和播放特效
                    if shouldRepair then
                        didRepair = TryRepair(inst, target, slot.item, repairMultiplier, slot.offset)
                        inst.xianzhou = inst.xianzhou - NEED_XIANZHOU
                        PlayRepairEffect(inst, target, 0, 0.5)
                        didRepair = true
                    end
                end
            end

            -- 播放缝纫机动画与声音
            if didRepair then
                inst.AnimState:PushAnimation("active_loop", true)
                inst.SoundEmitter:KillSound("snd")
                inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/LP", "snd")
            else
                inst.SoundEmitter:KillSound("snd")
                inst.AnimState:PlayAnimation("idle")
            end

            -- 更新缝纫机名称
            inst.components.named:SetName("缝纫机\n线轴：" .. inst.xianzhou)
        end)
    end)

    -- 3. 决定缝纫机是否应该接受该物品（验证阶段）
    local function LFShouldAcceptItem(inst, item)
        local owner = item.components.inventoryitem and item.components.inventoryitem.owner
        local can_accept = false
        if owner then
            if inst.xianzhou and inst.xianzhou <= 6000 then
                if SM.Materials.hasItem(item.prefab) then
                    -- 实例是否需要额外添加牛帽
                    can_accept = true
                else
                    -- 不接收的物品打印提示信息
                    local msg = SM.Dialogues.getMsg(owner.prefab)
                    owner.components.talker:Say(msg)

                    inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/close")
                    inst.AnimState:PlayAnimation("hit")
                    inst.AnimState:PushAnimation("idle", false)
                end
            else
                owner.components.talker:Say("线轴已经足够。")
            end
        end
        return can_accept
    end

    -- 4. 处理被接受的物品（执行阶段）
    local function LFOnGetItem(inst, giver, item)
        local processed = false -- 是否最终接受这个物品

        -- 基础条件检查
        if not (inst.xianzhou and giver and giver:HasTag("player")) then return processed end

        -- 计算给予堆叠物品的情况
        -- local stackSize = item.components.stackable and item.components.stackable:StackSize() or 1

        -- 当给予的是幸运金块，这里缝纫机会生成一台新的
        if item.prefab == "lucky_goldnugget" then
            if inst.xianzhou > 230 then
                SpawnPrefab("junk_break_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
                local newji = SpawnPrefab("yotb_sewingmachine")
                newji.Transform:SetPosition(inst.Transform:GetWorldPosition())
                newji.niunian = true
                newji.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/close")
                newji.AnimState:PlayAnimation("hit")
                newji.AnimState:PushAnimation("idle", false)

                -- 继承旧的缝纫机线轴
                newji.xianzhou = inst.xianzhou
                inst:Remove()
            end

            processed = true
        else
            local value = SM.Materials.getXianZhouByItem(item)

            inst.xianzhou = inst.xianzhou + value
            processed = true
        end

        if processed then
            -- 物品被接受后的反馈，声音，动画
            inst.AnimState:PlayAnimation("close")
            inst.SoundEmitter:KillSound("snd")
            inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/stop")
            inst.SoundEmitter:PlaySound("yotb_2021/common/sewing_machine/done")
        end
    end

    -- 4. 保存/加载数据
    local function OnSaveL(inst, data) --数据保存
        if inst.xianzhou then data.xianzhou = inst.xianzhou end
        if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then data.burnt = true end
    end
    local function OnLoadL(inst, data)
        if data ~= nil then
            if data.xianzhou and inst.xianzhou then inst.xianzhou = data.xianzhou end
            if data.burnt then inst.components.burnable.onburnt(inst) end
        end
    end
    inst.OnSave = OnSaveL
    inst.OnLoad = OnLoadL
end)

--毛丛可交易
AddPrefabPostInit("furtuft", function(inst)
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("tradable")
end)
--钢丝棉可交易
AddPrefabPostInit("steelwool", function(inst)
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("tradable")
end)
--胶带可交易
AddPrefabPostInit("sewing_tape", function(inst)
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("tradable")
end)
--小线轴可交易
AddPrefabPostInit("tinybobbin", function(inst)
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("tradable")
end)
--胡须可交易
AddPrefabPostInit("beardhair", function(inst)
    if not TheWorld.ismastersim then return inst end
    inst:AddComponent("tradable")
end)

-- 修改制作菜单中配方的排序位置。
-- 让 Mod 添加的新配方（缝纫机）出现在制作菜单中期望的位置（紧挨着缝纫工具包）。
ChangeSortKey("sewingmachine", "sewing_kit", "CLOTHING", true)
