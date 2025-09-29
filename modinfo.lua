name = "CPS_TEST"

description = "个人学习mods使用"

author = "CPS"

version = "0.0.1"

server_filter_tags = {"CPS", "切斯特", "Capsion"}

api_version = 10

priority = 100 -- 加载优先等级

dst_compatible = true  -- [必需] 是否兼容联机版（默认 true）
all_clients_require_mod = true  -- 是否强制所有客户端安装（true 表示服务器需要 Mod）

client_only_mod = false

configuration_options = {
    {
    name = "Enable",
    label = "是否开启",
    hover = "个人自用",
    options = 
        {
            
            {description = "On", data = true},
            {description = "Off", data = false},
        },
        default = true,
    },
}
