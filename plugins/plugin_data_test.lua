BANETO_CommunityFile([[KmoLib]],[[KmoCommon]])

if not _G.Kmo then
    _G.Kmo = {}
    Kmo.loadedPlugins = {}
end

if not Kmo.loadedPlugins then
    Kmo.loadedPlugins = {}
end

if Kmo.loadedPlugins['PluginData'] and not Kmo.loadedPlugins['PluginDataTest'] then
    Kmo.PluginDataTest = {}
    Kmo.PluginDataTest.PluginData = Kmo.PluginData.LoadOrCreate({pluginName = 'PluginDataTest', scope = 1})

    if not Kmo.PluginDataTest.PluginData.character then
        Kmo.PluginDataTest.PluginData.character = {}
    end
    if not Kmo.PluginDataTest.PluginData.character.object then
        Kmo.PluginDataTest.PluginData.character.object = {
            name = 'Test',
            born = GetTime(),
            age = 0
        }
    end
    if not Kmo.PluginDataTest.PluginData.character.tmp then
        Kmo.PluginDataTest.PluginData.character.tmp = 0
    end

    Kmo.loadedPlugins['PluginDataTest'] = true
end

if Kmo.loadedPlugins['PluginDataTest'] then
    Kmo.PluginDataTest.PluginData.character.tmp = Kmo.PluginDataTest.PluginData.character.tmp + 1
    Kmo.PluginDataTest.PluginData.character.object.age = GetTime() - Kmo.PluginDataTest.PluginData.character.object.born
    print('Kmo.PluginDataTest.PluginData.character.tmp: ' .. Kmo.PluginDataTest.PluginData.character.tmp)
    print('Kmo.PluginDataTest.PluginData.character.object: ' .. Kmo.Common.dump(Kmo.PluginDataTest.PluginData.character.object))
end