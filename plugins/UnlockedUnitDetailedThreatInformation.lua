---@alias ThreatState
---| nil # Unit is not on the threat table.
---| 0 # Unit has no threat.
---| 1 # Unit has highest threat but is not the target.
---| 2 # Unit is the target but not the highest threat.
---| 3 # Unit has the highest threat and is the target.

---@alias UnitID
---|'player'
---|'pet'
---|'target'
---|'focus'
---|'mouseover'
---|'party1'
---|'party2'
---|'party3'
---|'party4'
---|'party5'
---|'raid1'
---|'raid2'
---|'raid3'
---|'raid4'
---|'raid5'
---|'raid6'
---|'raid7'
---|'raid8'
---|'raid9'
---|'raid10'
---|'raid11'
---|'raid12'
---|'raid13'
---|'raid14'
---|'raid15'
---|'raid16'
---|'raid17'
---|'raid18'
---|'raid19'
---|'raid20'
---|'raid21'
---|'raid22'
---|'raid23'
---|'raid24'
---|'raid25'
---|'raid26'
---|'raid27'
---|'raid28'
---|'raid29'
---|'raid30'
---|'raid31'
---|'raid32'
---|'raid33'
---|'raid34'
---|'raid35'
---|'raid36'
---|'raid37'
---|'raid38'
---|'raid39'
---|'raid40'
---|'arena1'
---|'arena2'
---|'arena3'
---|'arena4'
---|'arena5'
---|'boss1'
---|'boss2'
---|'boss3'
---|'boss4'
---|'boss5'
---|'boss6'
---|'boss7'
---|'boss8'
---|'none'
---|'partypet1'
---|'partypet2'
---|'partypet3'
---|'partypet4'
---|'partypet5'
---|'raidpet1'
---|'raidpet2'
---|'raidpet3'
---|'raidpet4'
---|'raidpet5'
---|'raidpet6'
---|'raidpet7'
---|'raidpet8'
---|'raidpet9'
---|'raidpet10'
---|'raidpet11'
---|'raidpet12'
---|'raidpet13'
---|'raidpet14'
---|'raidpet15'
---|'raidpet16'
---|'raidpet17'
---|'raidpet18'
---|'raidpet19'
---|'raidpet20'
---|'raidpet21'
---|'raidpet22'
---|'raidpet23'
---|'raidpet24'
---|'raidpet25'
---|'raidpet26'
---|'raidpet27'
---|'raidpet28'
---|'raidpet29'
---|'raidpet30'
---|'raidpet31'
---|'raidpet32'
---|'raidpet33'
---|'raidpet34'
---|'raidpet35'
---|'raidpet36'
---|'raidpet37'
---|'raidpet38'
---|'raidpet39'
---|'raidpet40'
---|'vehicle'
---|'nameplate1'
---|'nameplate2'
---|'nameplate3'
---|'nameplate4'
---|'nameplate5'
---|'nameplate6'
---|'nameplate7'
---|'nameplate8'
---|'nameplate9'
---|'nameplate10'
---|'nameplate11'
---|'nameplate12'
---|'nameplate13'
---|'nameplate14'
---|'nameplate15'
---|'nameplate16'
---|'nameplate17'
---|'nameplate18'
---|'nameplate19'
---|'nameplate20'
---|'nameplate21'
---|'nameplate22'
---|'nameplate23'
---|'nameplate24'
---|'nameplate25'
---|'nameplate26'
---|'nameplate27'
---|'nameplate28'
---|'nameplate29'
---|'nameplate30'
---|'nameplate31'
---|'nameplate32'
---|'nameplate33'
---|'nameplate34'
---|'nameplate35'
---|'nameplate36'
---|'nameplate37'
---|'nameplate38'
---|'nameplate39'
---|'nameplate40'

---@alias Handle number

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

if not Kmo.Baneto or not Kmo.loadedPlugins['KmoBanetoExtensions'] then
    Kmo.Baneto = {}

    ---Unlocked version of the UnitDetailedThreatSituation function with 'player' as the first argument. Works on any (unitId|handle), including returns from `BANETO_GetObjctsTkr`.
    ---@param mobUnit UnitID|Handle The mob to check.
    ---@return boolean isTanking True if the unit is tanking mobUnit, false otherwise.
    ---@return ThreatState status The threat status of the unit against mobUnit.
    ---@return number scakedPercent The scaked threat percentage of the unit against mobUnit.
    ---@return number rawPercent The raw threat percentage of the unit against mobUnit.
    ---@return number threatValue The threat value of the unit against mobUnit.
    function _G.UnlockedUnitDetailedThreatInformation(mobUnit)
        if type(mobUnit) ~= 'string' or type(mobUnit) ~= 'number' then
            error('MobUnit must be a string or number.', 2)
        end
        local oldUnit = UnitGUID('target')
        if type(mobUnit) == 'number' then
            oldUnit = BANETO_ObjectId('target')
            UnlockedTargetUnit(mobUnit)
        end
        local isTanking, status, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation('player', 'target')
        if oldUnit then
            UnlockedTargetUnit(oldUnit)
        elseif type(mobUnit) == 'number' then
            BANETO_ClearTarget()
        end
        return isTanking, status, scaledPercent, rawPercent, threatValue
    end
end