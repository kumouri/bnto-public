-- TODO
--  - Add a UI to change the number of events and states to track
if not _G.Kmo then
    _G.Kmo = {}
    Kmo.loadedPlugins = {}
end

if not Kmo.loadedPlugins then
    Kmo.loadedPlugins = {}
end

if not Kmo.loadedPlugins['Ddr'] or not Kmo.Ddr then
    Kmo.Ddr = {}
    Kmo.Ddr.playerGuid = UnitGUID('player')
    Kmo.Ddr.mainFrame = CreateFrame("Frame", "KmoDdrMainFrame", UIParent)
    Kmo.Ddr.mainFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    Kmo.Ddr.LogFilePath = '/Logs/DeathRecap.txt'

    Kmo.Ddr.MaxEvents = 10
    Kmo.Ddr._events = {}

    Kmo.Ddr.MaxStates = 5
    Kmo.Ddr._states = {}

    if not FileExists(Kmo.Ddr.LogFilePath) then
        WriteFile(Kmo.Ddr.LogFilePath, '')
    end

    function Kmo.Ddr.OnCombatLogEventUnfiltered(...)
        local info = {CombatLogGetCurrentEventInfo()}
        local subEvent = info[2]
        local sourceGuid = info[4]
        local destGuid = info[8]
        local destName = info[9]

        -- Only track events that the player did or that happened to the player and are not AURA events (buffs/debuffs)
        if (destGuid == Kmo.Ddr.playerGuid or sourceGuid == Kmo.Ddr.playerGuid) and not string.find(subEvent, 'AURA') then
            table.insert(Kmo.Ddr._events, 1, info)
            if #Kmo.Ddr._events > Kmo.Ddr.MaxEvents then
                table.remove(Kmo.Ddr._events, #Kmo.Ddr._events)
            end
        end

        -- If the player dies, write the last 10 events to a file and send them to Discord
        if subEvent == 'UNIT_DIED' and destGuid == Kmo.Ddr.playerGuid then
            local px, py, pz = BANETO_ObjectPosition('player')
            local realZoneText = tostring(GetRealZoneText())
            local subZoneText = tostring(GetSubZoneText())
            local minimapZoneText = tostring(GetMinimapZoneText())
            px = tostring(px)
            py = tostring(py)
            pz = tostring(pz)
            local recap = "# Kumouri's Death Recap for __**" .. destName .. "**__:\\n## Location:\\n```"
            recap = recap .. realZoneText .. ' (' .. subZoneText .. ') ' .. minimapZoneText .. '\\n'
            recap = recap .. px .. ', ' .. py .. ', ' .. pz .. '```\\n## States:\\n```'
            local logMessage = '-------------------------\n' .. 'Death Recap for <' .. destName .. '> [' .. date('%Y-%m-%d %H:%M:%S') .. ']\n\tLocation:\n'
            logMessage = logMessage .. '\t\t' .. realZoneText .. ' (' .. subZoneText .. ') ' .. minimapZoneText .. '\n'
            logMessage = logMessage .. '\t\t' .. px .. ', ' .. py .. ', ' .. pz .. '\n\tStates:\n'

            local i = #Kmo.Ddr._states
            while i > 0 do
                local entry = Kmo.Ddr._states[i]
                local timestamp = entry.timestamp
                local state = entry.state
                recap = recap .. '[' .. i .. '][' .. timestamp .. ']: [' .. state .. ']\\n'
                logMessage = logMessage .. '\t\t[' .. i .. '][' .. timestamp .. ']: [' .. state .. ']\n'
                i = i - 1
            end

            recap = recap .. '```\\n## Combat Log:\\n```'
            logMessage = logMessage .. '\n\tCombat Log:\n'

            -- Write the last 10 events to a file and send them to Discord in chunks of 2000 characters or less
            --  Start at the end of the table and work backwards
            i = #Kmo.Ddr._events
            while i > 0 do
                info = Kmo.Ddr._events[i]
                local timestamp = info[1] or 'UNKNOWN'
                subEvent = info[2] or 'UNKNOWN'
                sourceGuid = info[4] or 'UNKNOWN'
                if sourceGuid == '' then
                    sourceGuid = 'UNKNOWN'
                end
                local sourceName = info[5] or 'UNKNOWN'
                if sourceName == '' then
                    sourceName = 'UNKNOWN'
                end
                local spellName = info[13]
                local amount = info[15]
                local overkill
                if string.find(subEvent, 'DAMAGE') then
                    overkill = info[16]
                end

                logMessage = logMessage .. '\t\t[' .. i .. '][' .. timestamp .. ']: [' .. subEvent .. ']'
                if type(spellName) == 'string' then
                    logMessage = logMessage .. ' from [' .. spellName .. ']'
                end
                if amount then
                    logMessage = logMessage .. ' for [' .. amount .. ']'
                end
                if overkill and overkill > 0 then
                    logMessage = logMessage .. '[' .. overkill .. '] (overkill)'
                end
                logMessage = logMessage .. ' from [' .. sourceName .. '] with GUID [' .. sourceGuid .. ']\n'

                recap = recap .. '[' .. i .. '][' .. timestamp .. ']: [' .. subEvent .. ']'
                if type(spellName) == 'string' then
                    recap = recap .. ' from [' .. spellName .. ']'
                end
                if amount then
                    recap = recap .. ' for [' .. amount .. ']'
                end
                if overkill and overkill > 0 then
                    recap = recap .. '[' .. overkill .. '] (overkill)'
                end
                recap = recap .. ' from [' .. sourceName .. '] with GUID [' .. sourceGuid .. ']\\n'

                if #recap > 1997 then
                    local tmpRecap = string.sub(recap, 1, 1997)
                    tmpRecap = tmpRecap .. '```'
                    recap = string.sub(recap, 1998)
                    recap = '```' .. recap
                    BANETO_DiscordSendPluginCustomText(tmpRecap)
                end
                i = i - 1
            end
            recap = recap .. '```'
            logMessage = logMessage .. '-------------------------\n'
            WriteFile('/Logs/DeathRecap.txt', logMessage, true)
            BANETO_DiscordSendPluginCustomText(recap)
        end
    end

    function Kmo.Ddr.OnRegenEnabled()
        wipe(Kmo.Ddr._events)
    end

    function Kmo.Ddr.OnEvent(self, event, ...)
        if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
            Kmo.Ddr.OnCombatLogEventUnfiltered(...)
        elseif event == 'PLAYER_REGEN_ENABLED' then
            Kmo.Ddr.OnRegenEnabled()
        end
    end

    Kmo.Ddr.mainFrame:SetScript("OnEvent", Kmo.Ddr.OnEvent)

    Kmo.loadedPlugins['Ddr'] = true
end

if Kmo.loadedPlugins['Ddr'] then
    if not Kmo.Ddr._states then
        Kmo.Ddr._states = {}
    end

    local state = BANETO_GetState()
    if #Kmo.Ddr._states > 0 then
        if Kmo.Ddr._states[1].state ~= state then
            table.insert(Kmo.Ddr._states, 1, {timestamp = GetTime(), state = state})
            if #Kmo.Ddr._states > Kmo.Ddr.MaxStates then
                table.remove(Kmo.Ddr._states, #Kmo.Ddr._states)
            end
        end
    else
        table.insert(Kmo.Ddr._states, 1, {timestamp = GetTime(), state = state})
    end
end