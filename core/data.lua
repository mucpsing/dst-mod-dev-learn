local CPS_DATA = {
    REJECT_LINES = {
        willow = "把这个当线材用？还不如让我烧了！",
        wolfgang = "沃尔夫冈认为这个不能作为线轴来用。",
        wendy = "那只能让衣物比我的心更加千疮百孔。",
        wx78 = "错误，补丁不兼容。",
        wickerbottom = "亲爱的，我从来没见过用这个缝衣服的。",
        woodie = "不行，这个甚至都不能修我的格子衫。",
        waxwell = "我的西服怎么能容许被这种材料羞辱？",
        wathgrithr = "这个材料无法为勇士们缝补战衣。",
        webber = "我们觉得用这个修衣服会出大问题的。",
        winona = "不行，添加用料这种事，一定要严之又严。",
        warly = "啊，你会用番茄条蘸土豆酱吗？",
        wortox = "哼，如果这是一场恶作剧，那么我可能会把这东西扔进去。",
        wormwood = "嗖嗖不喜欢这个",
        wurt = "浮浪噗，我很清醒，不会乱塞东西的。",
        walter = "沃比的毛都比这东西适合缝纫。",
        wanda = "我没时间在这里给材料试错，拿对的来！",
        wirlywings = "唔姆，这个肯定不行，我还是有点缝纫知识的！",
        daidai = "嗯，这个是绝对修不了玩偶和衣服的",
        wathom = "材料，不正确。",
        winky = "……我觉得还没有我们的体毛合适。",
        wixie = "有这试材料的时间不如去打弹弓。",
        default = "用这个来缝纫是不科学的。",
    },

    ITEM_XIANZHOU_RANGE = {
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
        beefalohat = { min = 500, max = 500 },

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
}

-- 加载到全局
if CPS then CPS.DATA = CPS_DATA end
