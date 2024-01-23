if not COMBATRANGE_ONLYRUNONCE then
	local _,myClass,_ = UnitClass("player")
	local settings = {
		["WARRIOR"] = 5,
		["PALADIN"] = 5,
		["HUNTER"] = 35,
		["ROGUE"] = 5,
		["PRIEST"] = 30,
		["DEATHKNIGHT"] = 5,
		["SHAMAN"] = 30,
		["MAGE"] = 40,
		["WARLOCK"] = 30,
		["MONK"] = 3,
		["DRUID"] = 35,
		["DEMONHUNTER"] = 5
	}
	local newRange = settings[myClass]
	if newRange and _G.BANETO_CUSTOM_COMBAT_RANGE ~= newRange then
		BANETO_PrintPlugin("Changing default " .. myClass .. " combat range to custom combat range: " .. newRange)
		_G.BANETO_CUSTOM_COMBAT_RANGE = newRange
	end
	COMBATRANGE_ONLYRUNONCE = true
end