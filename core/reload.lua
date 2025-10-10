function Log(msg)
    if not msg then return end
    if not GLOBAL and not GLOBAL.TheNet then return end

    if CPS and CPS.DEBUG then
        GLOBAL.TheNet:Announce("【 Announce 】" .. msg)
        print("CPS_DEV: " .. msg)
    end
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

-- 初始化定时器
local function SetupReloadTimer(watchFileList, reloadInterval, mod_name)
    GLOBAL.TheWorld:DoTaskInTime(1, function()
        InitFileModTimes(watchFileList)
        GLOBAL.TheWorld:DoPeriodicTask(reloadInterval, function()
            if not GLOBAL.TheSim then return end

            if not GLOBAL.TheNet then return end

            CheckFilesForChanges(watchFileList)
        end)
    end)
end

if CPS then CPS.UTILS.SetupReloadTimer = SetupReloadTimer end
