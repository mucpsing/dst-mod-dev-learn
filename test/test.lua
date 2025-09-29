GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local function Log(msg)
    print(msg)
    if not GLOBAL and not GLOBAL.TheNet then return end

    GLOBAL.TheNet:Announce("[cps dev]: " .. msg)
end

local SLOT_DATA_LIST = {
    { key = "BELLY", offset = 0.5 },
    { key = "NECK", offset = 0.5 },
    -- { key = "BACK", offset = 0.5 },
    { key = "HANDS", offset = 0.5 },
    { key = "HEAD", offset = 2 },
    { key = "BODY", offset = 0.5 },
    { key = "SHOES", offset = -0.3 },
}

-- 一些修复时以恢复血量为展示的物品
local HEALTH_PREFAB_LIST = {
    daidai = true,
    bernie_active = true,
    bernie_big = true,
}

local function PlayEffect(inst, item, position, offestY)
    local x, y, z = item.Transform:GetWorldPosition()
    local fxfire = SpawnPrefab("attackfx_handpillow_steelwool")
    fxfire.Transform:SetPosition(x, y, z)
    fxfire.Transform:SetScale(0.5, 0.5, 0.5)
end

local function PlaySound(inst)
    if inst.SoundEmitter then inst.SoundEmitter:PlaySound("yotr_2023/common/pillow_hit_steelwool") end
end

local function CanRepairHealth(inst, item)
    -- 白名单判断
    if not HEALTH_PREFAB_LIST[item.prefab] then return false end

    -- 存在health组件
    if item.components.health then
        if item.components.health:GetPercent() ~= 1 and not v.components.health:IsDead() then return true end
    end
end

local function IsArmor(item)
    if item.components.armor then
        if item.components.armor:GetPercent() < 1 then return true end
    end

    return false
end

local function IsCanFixByFuel(item)
    if item.components.fueled and item.components.fueled.fueltype == FUELTYPE.USAGE then
        if item.components.fueled:GetPercent() < 1 then return true end
    end

    return false
end

-- 修复装备
local function TryRepair(inst, item)
    if not item then return false end

    local didRepair = false
    local didPlaySound = false

    local showName = item.prefab
    if item.GetDisplayName then showName = item:GetDisplayName() end

    -- 修复护甲类装备
    if IsArmor(item) then
        item.components.armor:Repair(10)
        Log("armor修复: " .. showName .. tostring(item.components.armor:GetPercent()))
        didRepair = true

    -- 修复衣物（可通过修补工具修复的）
    elseif IsCanFixByFuel(item) then
        item.components.fueled:DoDelta(40)
        Log("fueled修复: " .. showName .. tostring(item.components.fueled:GetPercent()))
        didRepair = true
    elseif CanRepairHealth(item) then
        item.components.health.DoDelta(1)
        
    elseif item.components.repairable then
        Log("repairable修复: " .. showName)
    else
        -- Log("不处理: " .. showName)
        do
        end
    end

    if didRepair then
        -- 播放特效

        PlayEffect(inst, item)
        PlaySound(inst or ThePlayer)
    end

    return didRepair
end

function checkItemCanRepair(target)
    -- 确保实体有效且有prefab名称
    if not target or not target.prefab then return false end

    -- 是否实体
    if not target.components.inventory then return false end

    -- 是否被燃烧过
    if target.HasTag and target:HasTag("burnt") then return false end

    return true
end

-- 主函数：获取并打印第一个玩家附近的所有实体
function GetEntitiesNearFirstPlayer(inst, range)
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

    local targetPlayer = players[1]

    -- 3. 获取玩家位置并查找周围实体
    local x, y, z = targetPlayer.Transform:GetWorldPosition()
    local near_by_inst_entities = GLOBAL.TheSim:FindEntities(x, y, z, search_range)

    -- 4. 遍历并打印实体的prefab名称
    for i, target in ipairs(near_by_inst_entities) do
        if not checkItemCanRepair(target) then
            do
            end

        -- 这里使用处理人物身上的物品
        elseif target:HasTag("player") then
            local inv = target.components.inventory

            -- 修复已装备的衣物
            for k, eachItem in pairs(SLOT_DATA_LIST) do
                if GLOBAL.EQUIPSLOTS[eachItem.key] then
                    slotItem = inv:GetEquippedItem(EQUIPSLOTS[eachItem.key])

                    -- if slotItem and slotItem.GetDisplayName then
                    --     show_name = slotItem:GetDisplayName()
                    --     Log(eachItem.key .. "=>" .. show_name)
                    -- end

                    -- Log("TryRepair ==> 1")
                    TryRepair(nil, slotItem)
                end
            end
        else
            -- TryRepair()
            -- Log("TryRepair ==> 2")
            -- TryRepair(nil, target)
            do
            end
        end
    end
end

GetEntitiesNearFirstPlayer()
