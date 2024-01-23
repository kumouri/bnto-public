if not _G.Kmo then
    _G.Kmo = {}
    Kmo.loadedPlugins = {}
    Kmo.loading = {}
end

if not Kmo.loadedPlugins then
    Kmo.loadedPlugins = {}
end

if not Kmo.loading then
    Kmo.loading = {}
end

if not Kmo.loadedPlugins["InstanceCounter"] then
    Kmo.InstanceCounter = {}
    Kmo.InstanceCounter.private.pluginData = Kmo.PluginData.LoadOrCreate({pluginName = 'KmoInstanceCounter', scope = 'character'})
    Kmo.InstanceCounter.private._instances = Kmo.InstanceCounter.private.pluginData[1]
    Kmo.InstanceCounter.private._instances.resetting = {}
    Kmo.InstanceCounter.private._instances.dailyReset = {}
    Kmo.InstanceCounter.private._instances.runningReset = {}

    function Kmo.InstanceCounter.CheckIfInstanceNew()
        local newTimeToLock = GetInstanceLockTimeRemaining()
        if newTimeToLock <= 0 then
            local savedInstanceCount = GetNumSavedInstances()
            for i = 1, savedInstanceCount do
                local _, instanceId, secondsToReset = GetSavedInstanceInfo(i)
                for j = 1, #Kmo.InstanceCounter.private._instances.resetting do
                    if Kmo.InstanceCounter.private._instances.resetting[j].instanceId == instanceId then
                        break
                    end
                end
                table.insert(Kmo.InstanceCounter.private._instances.resetting, 1, {instanceId = instanceId, resetTime = GetTime() + secondsToReset})

                for j = 1, #Kmo.InstanceCounter.private._instances.dailyReset do
                    if Kmo.InstanceCounter.private._instances.dailyReset[j].instanceId == instanceId then
                        break
                    end
                end
                table.insert(Kmo.InstanceCounter.private._instances.dailyReset, 1, {instanceId = instanceId, resetTime = GetTime() + C_DateAndTime.GetSecondsUntilDailyReset()})

                for j = 1, #Kmo.InstanceCounter.private._instances.runningReset do
                    if Kmo.InstanceCounter.private._instances.runningReset[j].instanceId == instanceId then
                        break
                    end
                end
                table.insert(Kmo.InstanceCounter.private._instances.runningReset, 1, {instanceId = instanceId, resetTime = GetTime() + 86400})
            end
        end
    end

    function Kmo.InstanceCounter.OnEvent(self, event, ...)
        if event == 'PLAYER_ENTERING_WORLD' then
            local _, type = GetInstanceInfo()
            if type == 'party' then
                RequestRaidInfo()
            end
        end
        if event == 'UPDATE_INSTANCE_INFO' then
            local timeToLock = GetInstanceLockTimeRemaining() + 5
            C_Timer.After(timeToLock, Kmo.InstanceCounter.CheckIfInstanceNew)
        end
        if event == 'ADDONS_UNLOADING' then
            Kmo.InstanceCounter.removeOldInstancesTimer:Cancel()
        end
    end

    Kmo.InstanceCounter.mainFrame = CreateFrame("Button", "KmoInstanceCounterMainFrame", UIParent)
    Kmo.InstanceCounter.mainFrame:SetScript('OnEvent', Kmo.InstanceCounter.OnEvent)
    Kmo.InstanceCounter.mainFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
    Kmo.InstanceCounter.mainFrame:RegisterEvent('UPDATE_INSTANCE_INFO')
    Kmo.InstanceCounter.mainFrame:RegisterEvent('ADDONS_UNLOADING')

    function Kmo.InstanceCounter.RemoveOldInstances()
        local maxLength = 0
        if #Kmo.InstanceCounter.private._instances.resetting > maxLength then
            maxLength = #Kmo.InstanceCounter.private._instances.resetting
        elseif #Kmo.InstanceCounter.private._instances.dailyReset > maxLength then
            maxLength = #Kmo.InstanceCounter.private._instances.dailyReset
        elseif #Kmo.InstanceCounter.private._instances.runningReset > maxLength then
            maxLength = #Kmo.InstanceCounter.private._instances.runningReset
        end
        for i = maxLength, 1, -1 do
            if Kmo.InstanceCounter.private._instances.resetting[i] and Kmo.InstanceCounter.private._instances.resetting[i].resetTime < GetTime() then
                table.remove(Kmo.InstanceCounter.private._instances.resetting, i)
            end
            if Kmo.InstanceCounter.private._instances.dailyReset[i] and Kmo.InstanceCounter.private._instances.dailyReset[i].resetTime < GetTime() then
                table.remove(Kmo.InstanceCounter.private._instances.dailyReset, i)
            end
            if Kmo.InstanceCounter.private._instances.runningReset[i] and Kmo.InstanceCounter.private._instances.runningReset[i].resetTime < GetTime() then
                table.remove(Kmo.InstanceCounter.private._instances.runningReset, i)
            end
        end
    end

    Kmo.InstanceCounter.removeOldInstancesTimer = C_Timer.NewTicker(5, Kmo.InstanceCounter.RemoveOldInstances)

    ---Return the number of instances currently counting down to reset
    ---@return integer count of instances
    function Kmo.InstanceCounter.CountResetActive()
        return #Kmo.InstanceCounter.private._instances.resetting
    end

    ---Return the number of instances you are locked to if the reset is daily
    ---@return integer count of instances
    function Kmo.InstanceCounter.CountDailyResetActive()
        return #Kmo.InstanceCounter.private._instances.dailyReset
    end

    ---Return the number of instances you are locked to if the reset is a running 24 hour period from the time you first locked
    ---@return integer count of instances
    function Kmo.InstanceCounter.CountRunningResetActive()
        return #Kmo.InstanceCounter.private._instances.runningReset
    end

    Kmo.loadedPlugins["InstanceCounter"] = true
end