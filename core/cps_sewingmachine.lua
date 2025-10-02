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

local function OnHammered(inst, worker)
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

    inst:AddComponent("named")
    inst.xianzhou = 233 --初始233线轴

    -- 添加被锤子敲销毁
    inst.components.workable:SetOnFinishCallback(OnHammered)

    local taskInter = 0.3

    inst:DoTaskInTime(math.random() * 3, function() --防止缝纫机过于统一
        local postiton = { x = nil, y = nil, z = nil }
        local x, y, z = inst.Transform:GetWorldPosition()

        -- 周期性任务
        inst:DoPeriodicTask(taskInter, function()
            if inst:HasTag("burnt") then inst.components.named:SetName("烧毁的缝纫机剩余线轴[" .. inst.xianzhou .. "]") end

            -- 当前实体位置，可优化
            local dh = false
            local ents
            -- 播放声效

            -- 修复物品逻辑
            -- 播放特效

            -- 执行修复，返回需要消耗的线轴
        end)
    end)
end)
