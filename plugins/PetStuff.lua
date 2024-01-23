if not Kmo or not Kmo.PetStuff or not Kmo.loadedPlugins or not Kmo.loadedPlugins['PetStuff'] then
  if not Kmo then
    Kmo = {}
  end
  if not Kmo.loadedPlugins then
    Kmo.loadedPlugins = {}
  end
  Kmo.PetStuff = {}
  Kmo.PetStuff.feedPetWait = nil
  Kmo.PetStuff.feedPetWaitInterval = 60

  function Kmo.PetStuff.FeedPet()
    local happinessInfo = {GetPetHappiness()}
    local happiness = happinessInfo[1]
    if not happiness then
      BANETO_PrintPlugin('Not feeding pet because we do not have one out. Waiting 60s before checking again.')
      Kmo.PetStuff.feedPetWait = GetTime() + Kmo.PetStuff.feedPetWaitInterval
      return
    end
    if happiness == 3 then
      BANETO_PrintPlugin('Not feeding pet because it is already happy. Waiting 60s before checking again.')
      Kmo.PetStuff.feedPetWait = GetTime() + Kmo.PetStuff.feedPetWaitInterval
      return
    end
    local beingFed = BANETO_HasBuff('pet', 1539, false)
    while happiness < 3 do
      while beingFed do
        coroutine.yield()
        beingFed = BANETO_HasBuff('pet', 1539, false)
        happinessInfo = {GetPetHappiness()}
        happiness = happinessInfo[1]
      end
      if happiness >= 3 then
        break
      end
      local hasFood, foodId = BANETO_HasPetFeedItem()
      if not hasFood then
        BANETO_PrintPlugin('No pet food found in bags. Waiting 60s before checking again.')
        Kmo.PetStuff.feedPetWait = GetTime() + Kmo.PetStuff.feedPetWaitInterval
        break
      end
      local foodInfo = {GetItemInfo(foodId)}
      local petFood = foodInfo[1]
      BANETO_PrintPlugin('Feeding pet ' .. petFood .. '.')
      -- BANETO_CastSpell(6991, false)
      BANETO_RunMacroText('/cast Feed Pet')
      local wait = GetTime() + 0.5
      while GetTime() < wait do
        coroutine.yield()
      end
      if not petFood then
        BANETO_RunMacroText('/use Wild Ricecake')
      else
        BANETO_RunMacroText('/use ' .. petFood)
      end
      BANETO_DelayStateTick(20)
      wait = GetTime() + 5
      while GetTime() < wait do
        coroutine.yield()
      end
      beingFed = true
      happinessInfo = {GetPetHappiness()}
      happiness = happinessInfo[1]
    end
    BANETO_DelayStateTick(0)
  end

  Kmo.loadedPlugins['PetStuff'] = true
end

if BANETO_IsRunning() then
  if Kmo.PetStuff.feedPetWait and GetTime() < Kmo.PetStuff.feedPetWait then
    return
  end
  Kmo.PetStuff.status, Kmo.PetStuff.err = true, nil
  if not Kmo.PetStuff.status and Kmo.PetStuff.err then
    return
  end
  if not Kmo.PetStuff.feedPetCo or coroutine.status(Kmo.PetStuff.feedPetCo) == 'dead' then
    Kmo.PetStuff.feedPetCo = coroutine.create(Kmo.PetStuff.FeedPet)
  end
  if not UnitAffectingCombat('player') then
    Kmo.PetStuff.status, Kmo.PetStuff.err = coroutine.resume(Kmo.PetStuff.feedPetCo)
    if not Kmo.PetStuff.status then
      BANETO_PrintError('Error feeding pet: ' .. Kmo.PetStuff.err)
    end
  end
end