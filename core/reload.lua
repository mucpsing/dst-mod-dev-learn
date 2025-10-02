function Log(msg)
    if not GLOBAL and not GLOBAL.TheNet then return end

    GLOBAL.TheNet:Announce("【 Announce 】" .. msg)
end

local fileModTimes = {}

-- 工具函数：初始化文件修改时间记录
local function InitFileModTimes(watchFileList)
    if not GLOBAL or not GLOBAL.TheSim then return end

    if not MODROOT then return end

    for _, each_file in ipairs(watchFileList) do
        local filePath = MODROOT .. each_file
        local modTime = TheSim:GetFileModificationTime(filePath)

        fileModTimes[each_file] = modTime

        Log("开始监听文件: " .. each_file .. ", 修改时间: " .. (modTime or "未知"))
    end
end

-- 工具函数：检查文件是否有更新
local function CheckFilesForChanges(watchFileList)
    if not MODROOT then return false end

    local hasChanges = false
    for _, each_file in ipairs(watchFileList) do
        local filePath = MODROOT .. each_file
        local currentModTime = TheSim:GetFileModificationTime(filePath)
        local lastModTime = fileModTimes[each_file]

        if currentModTime ~= lastModTime then
            Log("检测到文件变更: " .. each_file .. ", 旧时间: " .. (lastModTime or "无") .. ", 新时间: " .. (currentModTime or "无"))

            fileModTimes[each_file] = currentModTime

            hasChanges = true
            modimport(each_file)
        end
    end
    return hasChanges
end

-- 重载函数，无法使用，直接采用modimport替代
-- local function ReloadMod(mod_name)
--     if not GLOBAL.ModManager then return log("没法找到ModManager") end

--     Log("[" .. mod_name .. "] 检测到文件变更，正在重载模组...")

--     GLOBAL.TheWorld:DoTaskInTime(1, function()
--         local mod = GLOBAL.ModManager:GetMod(mod_name)
--         if mod and GLOBAL.ModManager and GLOBAL.ModManager.ReloadMod then
--             GLOBAL.ModManager:ReloadMod(mod_name)

--             Log("[" .. mod_name .. "] 模组重载！")
--         elseif modimport then
--             modimport("test/test.lua")
--         else
--             Log("mod重载失败，无法找到modimport")
--         end
--     end)
-- end

-- 初始化定时器
function SetupReloadTimer(watchFileList, reloadInterval, mod_name)
    GLOBAL.TheWorld:DoTaskInTime(1, function()
        InitFileModTimes(watchFileList)
        GLOBAL.TheWorld:DoPeriodicTask(reloadInterval, function()
            if not GLOBAL.TheSim then return end

            if not GLOBAL.TheNet then return end

            CheckFilesForChanges(watchFileList)
            -- if CheckFilesForChanges(watchFileList) then ReloadMod(mod_name) end
        end)
    end)
end
