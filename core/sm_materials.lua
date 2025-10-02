Materials = {
    itemRange = {
        -- 普通材料
        silk = { min = 7, max = 10 },
        beefalowool = { min = 12, max = 16 },
        steelwool = { min = 85, max = 110 },
        beardhair = { min = 12, max = 16 },
        tinybobbin = { min = 24, max = 36 },
        manrabbit_tail = { min = 20, max = 30 },
        sewing_tape = { min = 40, max = 50 },
        cattenball = { min = 120, max = 180 },
        furtuft = { min = 20, max = 30 },

        -- 帽子类 (拥有耐久度的帽子，大小设置一致，这样后期计算会尝试根据耐久度进行
        walrushat = { min = 800, max = 800 },
        winterhat = { min = 100, max = 100 },
        earmuffshat = { min = 80, max = 80 },
        monkey_smallhat = { min = 100, max = 100 },

        -- 羽毛类
        malbatross_feathered_weave = { min = 200, max = 240 },
        malbatross_feather = { min = 30, max = 40 },
        goose_feather = { min = 30, max = 40 },
        feather_canary = { min = 20, max = 30 },
        feather_catbird = { min = 20, max = 30 },
        feather_chaffinch = { min = 20, max = 30 },
        feather_crow = { min = 10, max = 20 },
        feather_robin = { min = 10, max = 20 },
        feather_robin_winter = { min = 10, max = 20 },

        -- 植物类
        cutreeds = { min = 3, max = 5 },
        palmleaf = { min = 12, max = 16 },

        -- 怪物掉落
        tentaclespots = { min = 70, max = 80 },
        slurper_pelt = { min = 30, max = 45 },
        coontail = { min = 24, max = 36 },
        snakeskin = { min = 24, max = 36 },

        -- 高级材料
        voidcloth = { min = 100, max = 120 },
        fabric = { min = 40, max = 50 },

        -- 特殊物品
        trinket_22 = { min = 600, max = 700 },
        stinger = { min = 12, max = 18 },
    },

    -- 特殊幸运金块在外部进行处理
    -- lucky_goldnugget
}

-- 材料验证函数
function Materials:hasItem(item)
    if Materials.itemRange[item.prefab] then
        -- Log("SetAcceptTest1: " .. item.prefab)
        return true
    else
        -- Log("SetAcceptTest2: " .. item.prefab)
        return false
    end
end

-- 获取线轴值
function Materials:getXianZhouByItem(item)
    local xianzhou = 0
    local stackSize = item.components.stackable and item.components.stackable:StackSize() or 1

    if self.itemRange[item.prefab] then
        local itemRange = self.itemRange[item.prefab]

        if itemRange.min == itemRange.max then
            -- 固定价值材料（如帽子）
            xianzhou = math.floor(itemRange.min * (item.components.fueled and item.components.fueled:GetPercent() or 1))
        else
            -- 随机价值材料
            xianzhou = math.random(itemRange.min, itemRange.max) * stackSize
        end
    end

    return xianzhou
end
