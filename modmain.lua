local MOD_NAME = "cps_test"
local reloadInterval = 1
local watchedFiles = { "modinfo.lua", "modmain.lua" }
local fileModTimes = {}

-- local TheWorld, TheNet, TheSim, ThePlayer

local function Log(msg)
    if not GLOBAL and not GLOBAL.TheNet then return end

    GLOBAL.TheNet:Announce("【Announce1】" .. msg)
    -- GLOBAL.TheNet:SystemMessage("【SystemMessage2】" .. msg)
end

-- 工具函数：初始化文件修改时间记录
local function InitFileModTimes()
    if not GLOBAL or not GLOBAL.TheSim then return end

    if not MODROOT then return end

    for _, file in ipairs(watchedFiles) do
        local filePath = MODROOT .. file
        local modTime = TheSim:GetFileModificationTime(filePath)
        fileModTimes[file] = modTime

        msg = "[" .. MOD_NAME .. "] 开始监听文件: " .. file .. ", 修改时间: " .. (modTime or "未知")

        Log(msg)
    end
end

-- 工具函数：检查文件是否有更新
local function CheckFilesForChanges()
    if not MODROOT then return false end

    local hasChanges = false
    for _, file in ipairs(watchedFiles) do
        local filePath = MODROOT .. file
        local currentModTime = TheSim:GetFileModificationTime(filePath)
        local lastModTime = fileModTimes[file]

        if currentModTime ~= lastModTime then
            msg = "[" .. MOD_NAME .. "] 检测到文件变更: " .. file .. ", 旧时间: " .. (lastModTime or "无") .. ", 新时间: " .. (currentModTime or "无")

            Log(msg)

            fileModTimes[file] = currentModTime
            hasChanges = true
        end
    end
    return hasChanges
end

-- 重载函数
local function ReloadMod()
    if not GLOBAL.ModManager then return log("没法找到ModManager") end

    Log("[" .. MOD_NAME .. "] 检测到文件变更，正在重载模组...")

    GLOBAL.TheWorld:DoTaskInTime(1, function()
        local mod = GLOBAL.ModManager:GetMod(MOD_NAME)
        if mod and GLOBAL.ModManager and GLOBAL.ModManager.ReloadMod then
            GLOBAL.ModManager:ReloadMod(MOD_NAME)

            Log("[" .. MOD_NAME .. "] 模组重载！")
        end

        if modimport then
            modimport("test/test.lua")
        else
            Log("mod重载失败，无法找到modimport")
        end
    end)
end

-- 初始化定时器
local function SetupReloadTimer()
    GLOBAL.TheWorld:DoTaskInTime(1, function()
        InitFileModTimes()
        GLOBAL.TheWorld:DoPeriodicTask(reloadInterval, function()
            if not GLOBAL.TheSim then return end

            if not GLOBAL.TheNet then return end

            if CheckFilesForChanges() then ReloadMod() end
        end)

        -- Log("[" .. MOD_NAME .. "] 文件监听器已启动，监听间隔: " .. reloadInterval .. "秒")
        -- Log("[" .. MOD_NAME .. "] 文件监听器已启动，正在监听 " .. #watchedFiles .. " 个文件")
    end)
end

AddSimPostInit(function()
    -- 通过 GLOBAL 表访问 TheWorld，并检查是否在主世界
    if GLOBAL.TheWorld and GLOBAL.TheWorld.ismastersim then
        Log("TheWorld is ready and we are on the master sim!")

        if not GLOBAL.TheWorld.ismastersim then return false end

        -- 你的初始化代码可以安全地放在这里
        SetupReloadTimer()
    else
        Log("TheWorld is not available or we are not on the master sim.")
    end
end)
