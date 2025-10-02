local function Log(msg)
    print(msg)
    if not GLOBAL and not GLOBAL.TheNet then return end

    GLOBAL.TheNet:Announce("[cps dev]: " .. msg)
end
function Test(inst)
    if not GLOBAL and not GLOBAL.TheNet then return end

    if Dialogues then
        Log("Dialogues 已加载")
        return
    end

    -- 添加可交互组件（如果尚未添加）
    if not inst.components.inspectable then
        inst:AddComponent("inspectable")
        Log("需要添加交互组件")
    end

    inst.xianzhou = inst.xianzhou + 200
end
