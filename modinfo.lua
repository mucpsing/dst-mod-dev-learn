name = "CPS_TEST"

description = "缝纫机重做，对玩家身上穿着的物品进行修复"

author = "CPS"

version = "0.0.1"

server_filter_tags = { "CPS", "切斯特", "Capsion" }

api_version = 10

priority = 100 -- 加载优先等级

dst_compatible = true -- [必需] 是否兼容联机版（默认 true）
all_clients_require_mod = true -- 是否强制所有客户端安装（true 表示服务器需要 Mod）

client_only_mod = false

configuration_options = {
    {
        name = "REPAIR_RANGE",
        label = "修补检测范围（单位: 地皮）",
        hover = "默认2格地皮",
        options = {
            { description = "1地皮", data = 1 },
            { description = "2地皮", data = 2 },
            { description = "3地皮", data = 3 },
            { description = "4地皮", data = 4 },
            { description = "5地皮", data = 5 },
        },
        default = 2,
    },
    {
        name = "REPAIR_XIANZHOU",
        label = "修复时修复多少线轴",
        hover = "默认中等消耗",
        options = {
            { description = "低消耗", data = 5 },
            { description = "中等消耗", data = 10 },
            { description = "高消耗", data = 20 },
        },
        default = 10,
    },
    {
        name = "REPAIR_INTERVAL_TIME",
        label = "1秒内进行多少次修复",
        hover = "越快系统占用越高",
        options = {
            { description = "1秒3次", data = 0.3 },
            { description = "1秒2次", data = 0.5 },
            { description = "1秒1次", data = 1 },
            { description = "2秒1次", data = 2 },
        },
        default = 0.5,
    },

    {
        name = "REPAIR_ARMOR",
        label = "修复护甲",
        hover = "默认开启",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "REPAIR_CLOTHING",
        label = "修复衣物",
        hover = "默认开启",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
    {
        name = "REPAIR_UN_FUELED",
        label = "修复不可修复的物品",
        hover = "默认开启",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
    },
}
