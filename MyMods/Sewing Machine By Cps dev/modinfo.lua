name = "[dev] 缝纫机重做/Sewing Machine dev"
description = [[

- 对牛年缝纫机进行重做！
- 塞入线材类材料转变为线轴修补身上或者附近的衣服

]]
author = "CPS"
version = "1.31.1"
--version_compatible = "0.0"
server_filter_tags = { "Bering", "白令", "白令改造"}

api_version = 10
priority = -400
dst_compatible = true

client_only_mod = false
all_clients_require_mod = true

configuration_options = {
    {
    name = "onlyplayer",
    label = "只修玩家",
    hover = "缝纫机只缝补穿在玩家身上的衣服，不修地上或假人身上的",
    options = 
        {
            
            {description = "都修", data = true},
            {description = "只修玩家", data = false},
        },
        default = true,
    },
}
