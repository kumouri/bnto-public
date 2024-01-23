BANETO_DefineProfileName('auctioning')
BANETO_DefineProfileType('Grinding')

local pX, pY, pZ = BANETO_ObjectPosition('player')
BANETO_DefineCenter(pX, pY, pZ, 50)

BANETO_DefineProfileContinent(BANETO_GetContinentId())