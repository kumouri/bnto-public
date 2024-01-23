--[[
Copyright 2023 Will Armstrong, All Rights Reserved.

Version: 0.3.0

This is a collection of common functions that I use in my plugins. It is not intended to be used as a standalone plugin.

Changelog:
    0.3.0 : 2024-21-01
        - Added Kmo.Common.EnsureFoldersExist
        - Switch from using CreateFontstring to CreateFontString
        - Change which print function is used in Kmo.Logging:Print based on the log level
    0.2.0 : 2023-12-20
        - Moved scope to Kmo.Settings and added scopeStrings
        - Added a lot of documentation
    0.1.0 : 2023-10-20
        - Initial release

TODO:
    - Add more documentation
    - Make documentation website
    - Finish Settings
    - Make sure Logging works
    - Add PatchUtil?
    - Make private variables actually private
    - Remove unused sections
        - Profiles
        - Plugins
        - Threading?
    - Make sure all functions are documented
    - Look into Lua Unit Testing
    - Look into Lua Linting
    - Look into wrapping BANETO_Print* functions to go through Kmo.Logging
    - Make Threading work
]]

---@class Kmo
---@field loadedPlugins table<string, boolean> A table of loaded plugins
---@field loading table<string, boolean> A table of plugins that have been requested to load
---@field Common Kmo.Common
---@field Profiles Kmo.Profiles
---@field Settings Kmo.Settings
---@field PluginData Kmo.PluginData
---@field Logging Kmo.Logging
---@field UI Kmo.UI

---@class Kmo.Plugin
---@field HandleError function The function to handle errors

if not _G.Kmo then
    _G.Kmo = {}
    Kmo.loadedPlugins = {}
end

if not Kmo.loadedPlugins then
    Kmo.loadedPlugins = {}
end

if not Kmo.loadedPlugins['Common'] then
    ---@class Kmo.Common
    Kmo.Common = {}

    ---@description Dumps a table to a string with optional max depth
    ---@param o table The table to dump
    ---@param maxDepth number? The maximum depth to dump
    ---@param depth number? The current depth
    ---@return string table The table dumped to a string
    function Kmo.Common.dump(o, maxDepth, depth)
        if not depth then
            depth = 0
        end
        if not maxDepth then
            maxDepth = 200
        end
        if (depth > maxDepth) then
            return tostring(o)
        end
        if type(o) == 'table' then
            local s = '{\n'
            for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"' .. k .. '"' end
                s = s .. string.rep('  ', depth + 1) .. '[' .. k .. '] = ' .. Kmo.Common.dump(v, maxDepth, depth + 1) .. ',\n'
            end
            return s .. string.rep('  ', depth) .. '}'
        else
            return tostring(o)
        end
    end

    ---@description Resumes a coroutine handling any errors and returning the results
    ---@param cr thread The coroutine to resume
    ---@param handlingPlugin Kmo.Plugin The plugin that is handling the coroutine, requires a :HandleError function
    ---@vararg any The arguments to pass to the coroutine
    function Kmo.Common.ResumeCoroutine(cr, handlingPlugin, ...)
        local result = {coroutine.resume(cr, ...)}
        if not result[1] then
            BANETO_PrintDev('Error in coroutine: ' .. result[2])
            handlingPlugin:HandleError(result[2])
        end
        return unpack(result, 2)
    end

    Kmo.Common.EnsureFoldersExist = function(path)
        assert(path and type(path) == 'table', 'Kmo.Common.EnsureFoldersExist: path must be a table')
        local currentPath = ''
        for _, folder in ipairs(path) do
            currentPath = currentPath .. '/' .. folder
            if not DirectoryExists(currentPath) then
                CreateDirectory(currentPath)
            end
        end
    end

    -- local oldPrint = BANETO_Print
    -- BANETO_Print = function (...)
    --     oldPrint(...)
    --     if not FileExists('/Logs/baneto.log') then
    --         BANETO_WriteFile('/Logs/baneto.log', '', false)
    --     end
    --     BANETO_WriteFile('/Logs/baneto.log', date('%Y-%m-%d %H:%M:%S') .. ' ' .. Kmo.Common.dump({...}) .. '\n', true)
    -- end

    Kmo.loadedPlugins['Common'] = true
end

if not Kmo.loadedPlugins['Profiles'] then
    ---@class Kmo.Profiles
    Kmo.Profiles = {}

    Kmo.Profiles.BuildBanetoCentersFromPulls = function(pulls)
        assert(pulls and type(pulls) == 'table', 'Kmo.Profiles.BuildBanetoCentersFromPulls: pulls must be a table')
        for _, pull in ipairs(pulls) do
            if pull.PullCenter then
                BANETO_DefineCenter(pull.PullCenter.x, pull.PullCenter.y, pull.PullCenter.z, pull.PullCenter.radius)
            end
            if pull.Centers then
                for _, center in ipairs(pull.Centers) do
                    BANETO_DefineCenter(center.x, center.y, center.z, center.radius)
                end
            end
            if pull.FightCenter then
                BANETO_DefineCenter(pull.FightCenter.x, pull.FightCenter.y, pull.FightCenter.z, pull.FightCenter.radius)
            end
        end
    end

    Kmo.loadedPlugins['Profiles'] = true
end

-- if not Kmo.loadedPlugins['Threading'] then
--     Kmo.Threading = {}

--     Kmo.Threading.__private = {
--         threads = {},
--         queue = {},
--         runningThread = nil,
--         schedulerFrame = nil,
--     }

--     Kmo.Threading.MAX_TIME_USAGE_RATIO = 0.25
--     Kmo.Threading.EXCESSIVE_TIME_USED_RATIO = 1.2
--     Kmo.Threading.EXCESSIVE_TIME_LOG_THRESHOLD = 0.1
--     Kmo.Threading.MAX_QUANTUM = 0.01
--     Kmo.Threading.SEND_MSG_SYNC_TIMEOUT = 3
--     Kmo.Threading.YIELD_VALUE_START = {}
--     Kmo.Threading.YIELD_VALUE = {}
--     Kmo.Threading.SCHEDULER_TIME_WARNING_THRESHOLD = 0.1

--     if TSM then
--         Kmo.Threading.Thread = TSM.Include("LibTSMClass").DefineClass("Thread")
--     else
--         Kmo.Threading.Thread = function (name, func) end
--     end

--     function Kmo.Threading.New(name, func)
--         assert(name and func)
--         local thread = Kmo.Threading.Thread(name, func)
--         print(Kmo.Common.dump(thread))
--         local threadId = strjoin("-", tostring(thread), tostring(func))
--         Kmo.Threading.__private.threads[threadId] = thread
--         return threadId
--     end

--     Kmo.loadedPlugins['Threading'] = true
-- end

-- if not Kmo.loadedPlugins['Plugins'] then
--     Kmo.Plugins = {}

--     Kmo.Plugins.__private = {
--         plugins = {},
--     }

--     Kmo.Plugins.Register = function(pluginName, plugin)
--         assert(pluginName and plugin)
--         local pluginString = BANETO_ReadFile('/scripts/baneto/plugins/'..pluginName..'.lua')
--         local pluginFunction = loadstring(pluginString)
--         if pluginFunction then
--             setfenv(pluginFunction, getfenv())
--             local pluginThread = Kmo.Threading.New(pluginName, pluginFunction)
--             Kmo.Plugins.__private.plugins[pluginName] = pluginThread
--         end
--     end

--     Kmo.Plugins.Get = function(pluginName)
--         assert(pluginName)
--         return Kmo.Plugins.__private.plugins[pluginName]
--     end

--     Kmo.loadedPlugins['Plugins'] = true
-- end

if not Kmo.loadedPlugins['Settings'] then
    ---@class Kmo.Settings

    ---@class Kmo.Settings.SettingGroup
    ---@field id string The name of the setting group
    ---@field scope number The scope of the setting group
    ---@field settings table<Kmo.Settings.Setting> The settings in the setting group

    ---@class Kmo.Settings.Setting
    ---@field id string The unique identifier for the setting
    ---@field type string The type of setting
    ---@field scope number? The scope for the setting
    ---@field settingGroup string The setting group for the setting
    ---@field label string The label for the setting
    ---@field default any? The default value for the setting
    ---@field tooltip string? The tooltip for the setting
    ---@field options table? The options for the setting (only used for dropdowns)
    ---@field min number? The minimum value for the setting
    ---@field max number? The maximum value for the setting
    ---@field step number? The step value for the setting
    ---@field callback function? The callback function for the setting (only used for buttons)
    ---@field preSave function? The pre-save function for the setting
    ---@field postSave function? The post-save function for the setting

    ---@class Kmo.Settings.InfoTable
    ---@field text string Button text for this option.
    ---@field value	any	A value tag for this option. Inherits text key if this is undefined.
    ---@field checked	boolean, function	If true, this button is checked (tick icon displayed next to it)
    ---@field func	function	function called when this button is clicked. The signature is (self, arg1, arg2, checked)
    ---@field isTitle	boolean	True if this is a title (cannot be clicked, special formatting).
    ---@field disabled	boolean	If true, this button is disabled (cannot be clicked, special formatting)
    ---@field arg1	any	Arguments to the custom function assigned in func.
    ---@field arg2	any	Arguments to the custom function assigned in func.
    ---@field hasArrow	boolean	If true, this button has an arrow and opens a nested menu.
    ---@field icon	string	A texture path. The icon is scaled down and displayed to the right of the text.
    ---@field iconOnly	boolean	If true, only the icon is shown.
    ---@field iconXOffset	number	number of pixels to shift the button's icon to the left or right (positive numbers shift right, negative numbers shift left).
    ---@field iconTooltipTitle	string	Title of the tooltip shown on icon mouseover
    ---@field iconTooltipText	string	Text of the tooltip shown on icon mouseover
    ---@field iconTooltipBackdropStyle	table	Optional Backdrop style of the tooltip shown on icon mouseover
    ---@field mouseOverIcon	Texture	An override icon when a button is moused over
    ---@field tCoordLeft	number	SetTexCoord for the icon. ALL four must be defined for this to work.
    ---@field tCoordRight	number	SetTexCoord for the icon. ALL four must be defined for this to work.
    ---@field tCoordTop	    number	SetTexCoord for the icon. ALL four must be defined for this to work.
    ---@field tCoordBottom	number	SetTexCoord for the icon. ALL four must be defined for this to work.
    ---@field tSizeX number	Sets the icon width / height. SetWidth(tSizeX), SetHeight(tSizeY)
    ---@field tSizeY number	Sets the icon width / height. SetWidth(tSizeX), SetHeight(tSizeY)
    ---@field iconInfo.tFitDropDownSizeX	boolean	Adjusts the dropdowns automatic width by minus 5 (internally used for UIDropDownMenu_AddSeparator to fix the icon adding too much width)
    ---@field isNotRadio	boolean	If true, use a check mark for the tick icon instead of a circular dot.
    ---@field hasColorSwatch	boolean	If true, this button has an attached color selector.
    ---@field r	number [0.0, 1.0]	Initial color value for the color selector.
    ---@field g	number [0.0, 1.0]	Initial color value for the color selector.
    ---@field b	number [0.0, 1.0]	Initial color value for the color selector.
    ---@field colorCode	string	"|cffrrggbb" sequence that is prepended to info.text only if the button is enabled.
    ---@field swatchFunc	function	function called when the color is changed.
    ---@field hasOpacity	boolean	If true, opacity can be customized in addition to color.
    ---@field opacity	number [0.0, 1.0]	Initial opacity value (0 = transparent).
    ---@field opacityFunc	function	function called when opacity is changed.
    ---@field cancelFunc	function	function called when color/opacity alteration is cancelled.
    ---@field registerForRightClick	boolean	Register dropdown buttons for right clicks
    ---@field notClickable	boolean	If true, this button cannot be clicked, but changes the Disabled Font to match the standard white font (GameFontHighlightSmallLeft) - Does not respect fontObject.
    ---@field noClickSound	boolean	Set to 1 to suppress the sound when clicking the button. The sound only plays if .func is set.
    ---@field notCheckable	boolean	If true, this button cannot be checked (selected) - this also moves the button to the left, since there's no space stored for the tick-icon
    ---@field keepShownOnClick	boolean	If true, the menu isn't hidden when this button is clicked.
    ---@field tooltipTitle	string	Tooltip title text. The tooltip appears when the player hovers over the button.
    ---@field tooltipText	string	Tooltip content text.
    ---@field tooltipOnButton	boolean	Show the tooltip attached to the button instead of as a Newbie tooltip.
    ---@field tooltipWhileDisabled	boolean	Show the tooltip, even when the button is disabled.
    ---@field tooltipWarning	string	Warning-style text of the tooltip shown on mouseover
    ---@field tooltipInstruction	string	Instruction-style text of the tooltip shown on mouseover
    ---@field tooltipBackdropStyle	table	Optional Backdrop style of the tooltip shown on mouseover
    ---@field justifyH	string	Horizontal text justification: "CENTER" for "CENTER", any other value or nil for "LEFT".
    ---@field fontObject	Font	Font object used to render the button's text.
    ---@field owner	Frame	Dropdown frame that "owns" the current dropdown list.
    ---@field padding	number	number of pixels to pad the text on the right side.
    ---@field topPadding	number	Extra spacing between buttons
    ---@field leftPadding	number	number of pixels to pad the button on the left side
    ---@field midWidth	number	Minimum width for this option's line
    ---@field menuList	table	Table used to store nested menu descriptions for the EasyMenu functionality.
    ---@field customCheckIconAtlas	boolean	Needs explanation.
    ---@field classicChecks	boolean	Classic WoW only - needs explanation.
    ---@field customFrame	Frame	Allows this button to be a completely custom frame. Custom frame should inherit from UIDropDownCustomMenuEntryTemplate and override appropriate methods

    Kmo.Settings = {
        scopeMin = 1,
        scopeMax = bit.bor(1, 2, 4),
        ---@enum Kmo.Settings.Scope
        scope = {
            CHARACTER = 1,
            REALM = 2,
            ACCOUNT = 4,
        },
        scopeStrings = {
            [1] = 'character',
            [2] = 'realm',
            [4] = 'account',
        },
        ---@alias Kmo.Settings.UITypes string
        ---|'checkbox'
        ---|'dropdown'
        ---|'slider'
        ---|'listbox'
        ---|'textinput'
        ---|'textarea'
        ---|'button'
        ---|'color'
        ---|'divider'
        ---|'tab'
        ---|'header'
        types = {
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            ['checkbox'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.checkbox: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.checkbox: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.checkbox: setting.settingGroup must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.checkbox: parentFrame must be provided', 3)
                end

                local checkboxFrame = CreateFrame('Frame', setting.id .. '_CheckboxFrame', parentFrame)
                checkboxFrame:SetSize(parentFrame:GetWidth(), 40)
                checkboxFrame:SetPoint('TOPLEFT', parentFrame:GetChildren()[#parentFrame:GetChildren()], 'BOTTOMLEFT', 0, 0)
                if setting.tooltip then
                    checkboxFrame:SetScript('OnEnter', function()
                        GameTooltip:SetOwner(checkboxFrame, 'ANCHOR_TOPLEFT')
                        GameTooltip:SetText(setting.tooltip, nil, nil, nil, nil, true)
                        GameTooltip:Show()
                    end)
                    checkboxFrame:SetScript('OnLeave', function()
                        GameTooltip:Hide()
                    end)
                end

                local label = checkboxFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
                label:SetText(setting.label)
                label:SetPoint('TOPLEFT', checkboxFrame, 'TOPRIGHT', 8, 0)

                local checkbox = CreateFrame('CheckButton', setting.id .. '_Checkbox', checkboxFrame, 'UICheckButtonTemplate')
                checkbox:SetSize(24, 24)
                checkbox:SetChecked(Kmo.Settings.Get(setting.id, setting.default or false, setting.scope, setting.settingGroup))
                checkbox:SetPoint('TOPLEFT', label, 'TOPLEFT', 8, -8)
                checkbox:SetScript('OnClick', function()
                    Kmo.Settings.Set(setting.id, setting.scope, checkbox:GetChecked(), setting.settingGroup)
                end)
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            -- TODO - Finish dropdown
            ['dropdown'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.dropdown: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.dropdown: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.dropdown: setting.settingGroup must be provided', 4)
                end
                if not setting.options then
                    error('Kmo.Settings.types.dropdown: setting.options must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.dropdown: parentFrame must be provided', 3)
                end

                local dropdownFrame = CreateFrame('Frame', setting.id .. '_DropdownFrame', parentFrame)
                dropdownFrame:SetSize(parentFrame:GetWidth(), 40)
                dropdownFrame:SetPoint('TOPLEFT', parentFrame:GetChildren()[#parentFrame:GetChildren()], 'BOTTOMLEFT', 0, 0)
                if setting.tooltip then
                    dropdownFrame:SetScript('OnEnter', function()
                        GameTooltip:SetOwner(dropdownFrame, 'ANCHOR_TOPLEFT')
                        GameTooltip:SetText(setting.tooltip, nil, nil, nil, nil, true)
                        GameTooltip:Show()
                    end)
                    dropdownFrame:SetScript('OnLeave', function()
                        GameTooltip:Hide()
                    end)
                end

                local dropdown = CreateFrame('Frame', setting.id .. '_Dropdown', dropdownFrame, 'UIDropDownMenuTemplate')
                dropdown:SetPoint('TOPLEFT', dropdownFrame, 'TOPLEFT', 8, -8)

                local function DropdownInitialize (frame, level, menuList)
                    for _, option in ipairs(setting.options) do
                        option.checked = Kmo.Settings.Get(setting.id, setting.default or '', setting.scope, setting.settingGroup) == option.value
                        if not option.func then
                            option.func = function (self, arg1, arg2, checked)
                                UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
                                self:SetChecked(not self:GetChecked())
                                Kmo.Settings.Set(setting.id, setting.scope, self:GetChecked(), setting.settingGroup)
                            end
                        end
                        UIDropDownMenu_AddButton(option)
                    end
                end

                UIDropDownMenu_Initialize(dropdown, DropdownInitialize)
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            -- TODO - Finish slider
            ['slider'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.slider: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.slider: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.slider: setting.settingGroup must be provided', 4)
                end
                if not setting.min then
                    error('Kmo.Settings.types.slider: setting.min must be provided', 4)
                end
                if not setting.max then
                    error('Kmo.Settings.types.slider: setting.max must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.slider: parentFrame must be provided', 3)
                end
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            -- TODO - List Box
            ['listbox'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.listbox: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.listbox: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.listbox: setting.settingGroup must be provided', 4)
                end
                if not setting.options then
                    error('Kmo.Settings.types.listbox: setting.options must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.listbox: parentFrame must be provided', 3)
                end
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            ['textinput'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.textinput: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.textinput: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.textinput: setting.settingGroup must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.textinput: parentFrame must be provided', 3)
                end

                local textInputFrame = CreateFrame('Frame', setting.id .. '_TextInputFrame', parentFrame)
                textInputFrame:SetSize(parentFrame:GetWidth(), 72)
                textInputFrame:SetPoint('TOPLEFT', parentFrame:GetChildren()[#parentFrame:GetChildren()], 'BOTTOMLEFT', 0, 0)
                if setting.tooltip then
                    textInputFrame:SetScript('OnEnter', function()
                        GameTooltip:SetOwner(textInputFrame, 'ANCHOR_TOPLEFT')
                        GameTooltip:SetText(setting.tooltip, nil, nil, nil, nil, true)
                        GameTooltip:Show()
                    end)
                    textInputFrame:SetScript('OnLeave', function()
                        GameTooltip:Hide()
                    end)
                end

                local label = textInputFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
                label:SetText(setting.label)
                label:SetSize(200, 24)
                label:SetPoint('TOPLEFT', textInputFrame, 'TOPLEFT', 8, -8)

                local textInput = CreateFrame('EditBox', setting.id .. '_TextInput', textInputFrame, 'InputBoxTemplate')
                textInput:SetSize(200, 24)
                textInput:SetPoint('TOPLEFT', label, 'TOPRIGHT', 8, -8)
                textInput:SetAutoFocus(false)

                local function LostFocus (self)
                    if setting.preSave then
                        setting.preSave(self)
                    end
                    textInput:ClearFocus()
                    Kmo.Settings.Set(setting.id, setting.scope, self:GetText(), setting.settingGroup)
                    if setting.postSave then
                        setting.postSave(self)
                    end
                end

                textInput:SetScript('OnEnterPressed', LostFocus)
                textInput:SetScript('OnEscapePressed', LostFocus)
                textInput:SetScript('OnEditFocusLost', LostFocus)
                textInput:SetText(Kmo.Settings.Get(setting.id, setting.default or '', setting.scope, setting.settingGroup))
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            ['textarea'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.textarea: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.textarea: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.textarea: setting.settingGroup must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.textarea: parentFrame must be provided', 3)
                end

                local textInputFrame = CreateFrame('Frame', setting.id .. '_TextInputFrame', parentFrame)
                textInputFrame:SetSize(parentFrame:GetWidth(), 284)
                textInputFrame:SetPoint('TOPLEFT', parentFrame:GetChildren()[#parentFrame:GetChildren()], 'BOTTOMLEFT', 0, 0)
                if setting.tooltip then
                    textInputFrame:SetScript('OnEnter', function()
                        GameTooltip:SetOwner(textInputFrame, 'ANCHOR_TOPLEFT')
                        GameTooltip:SetText(setting.tooltip, nil, nil, nil, nil, true)
                        GameTooltip:Show()
                    end)
                    textInputFrame:SetScript('OnLeave', function()
                        GameTooltip:Hide()
                    end)
                end

                local label = textInputFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
                label:SetText(setting.label)
                label:SetSize(200, 24)
                label:SetPoint('TOPLEFT', textInputFrame, 'TOPLEFT', 8, -8)

                local textInput = CreateFrame('EditBox', setting.id .. '_TextArea', textInputFrame, 'InputBoxTemplate')
                textInput:SetSize(200, 240)
                textInput:SetPoint('TOPLEFT', label, 'TOPRIGHT', 8, -8)
                textInput:SetAutoFocus(false)

                local function LostFocus (self)
                    if setting.preSave then
                        setting.preSave(self)
                    end
                    textInput:ClearFocus()
                    Kmo.Settings.Set(setting.id, setting.scope, self:GetText(), setting.settingGroup)
                    if setting.postSave then
                        setting.postSave(self)
                    end
                end

                textInput:SetScript('OnEnterPressed', LostFocus)
                textInput:SetScript('OnEscapePressed', LostFocus)
                textInput:SetScript('OnEditFocusLost', LostFocus)
                textInput:SetText(Kmo.Settings.Get(setting.id, setting.default or '', setting.scope, setting.settingGroup))
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            ['divider'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.divider: setting.id must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.divider: setting.settingGroup must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.divider: parentFrame must be provided', 3)
                end

                local dividerFrame = CreateFrame('Frame', setting.id .. '_DividerFrame', parentFrame)
                dividerFrame:SetSize(parentFrame:GetWidth(), 1)
                dividerFrame:SetPoint('TOPLEFT', parentFrame:GetChildren()[#parentFrame:GetChildren()], 'BOTTOMLEFT', 0, 0)
                local texture = dividerFrame:CreateTexture(nil, 'BACKGROUND')
                texture:SetAllPoints(dividerFrame)
                texture:SetColorTexture(1, 1, 1, 1)
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            ['tab'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.tab: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.tab: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.tab: setting.settingGroup must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.tab: parentFrame must be provided', 3)
                end

                local tabButtonFrame
                for _, v in pairs(parentFrame:GetChildren()) do
                    if v:GetName() == setting.id .. '_TabButtonFrame' then
                        tabButtonFrame = v
                        break
                    end
                end

                if not tabButtonFrame then
                    BANETO_PrintDev('TabButtonFrame not found for ' .. setting.id .. ', creating...')
                    tabButtonFrame = CreateFrame('Frame', setting.id .. '_TabButtonFrame', parentFrame)
                    tabButtonFrame:SetSize(parentFrame:GetWidth(), 40)
                    tabButtonFrame:SetPoint('TOPLEFT', parentFrame, 'TOPLEFT', 0, 0)
                end

                local tabFrame = CreateFrame('Frame', setting.id .. '_TabFrame', parentFrame)
                tabFrame:SetSize(parentFrame:GetWidth(), parentFrame:GetHeight())
                tabFrame:SetPoint('TOPLEFT', parentFrame, 'TOPLEFT', 0, 0)
                tabFrame:Hide()

                local tabButton = CreateFrame('Button', setting.id .. '_TabButton', tabButtonFrame, 'UIPanelButtonTemplate')
                tabButton:SetSize(160, 40)
                tabButton:SetText(setting.label)
                tabButton:SetPoint('TOPLEFT', tabButtonFrame:GetChildren()[#tabButtonFrame:GetChildren()], 'TOPRIGHT', 0, 0)
                tabButton:SetScript('OnClick', function()
                    if parentFrame.displayFrame and parentFrame.displayFrame ~= tabFrame then
                        parentFrame.displayFrame:Hide()
                        tabFrame:Show()
                        parentFrame.displayFrame = tabFrame
                    end
                end)

                return tabFrame
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            ['header'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.header: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.header: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.header: setting.settingGroup must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.header: parentFrame must be provided', 3)
                end

                local headerFrame = CreateFrame('Frame', setting.id .. '_HeaderFrame', parentFrame)
                headerFrame:SetSize(parentFrame:GetWidth(), 40)
                headerFrame:SetPoint('TOPLEFT', parentFrame:GetChildren()[#parentFrame:GetChildren()], 'BOTTOMLEFT', 0, 0)

                local header = headerFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
                header:SetText(setting.label)
                header:SetPoint('CENTER', headerFrame, 'CENTER', 0, 0)

                local dividerFrameLeft = CreateFrame('Frame', setting.id .. '_DividerFrameLeft', headerFrame)
                dividerFrameLeft:SetSize((parentFrame:GetWidth() - header:GetWidth()) / 2 - 4, 1)
                dividerFrameLeft:SetPoint('LEFT', headerFrame, 'LEFT', 4, 0)
                local textureLeft = dividerFrameLeft:CreateTexture(nil, 'BACKGROUND')
                textureLeft:SetAllPoints(dividerFrameLeft)
                textureLeft:SetColorTexture(1, 1, 1, 1)

                local dividerFrameRight = CreateFrame('Frame', setting.id .. '_DividerFrameRight', headerFrame)
                dividerFrameRight:SetSize((parentFrame:GetWidth() - header:GetWidth()) / 2 - 4, 1)
                dividerFrameRight:SetPoint('RIGHT', headerFrame, 'RIGHT', -4, 0)
                local textureRight = dividerFrameRight:CreateTexture(nil, 'BACKGROUND')
                textureRight:SetAllPoints(dividerFrameRight)
                textureRight:SetColorTexture(1, 1, 1, 1)
            end,
            -- TODO - Finish color
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            ['color'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.color: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.color: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.color: setting.settingGroup must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.color: parentFrame must be provided', 3)
                end
            end,
            ---@param parentFrame Frame The frame to add the button to
            ---@param setting Kmo.Settings.Setting The setting to add
            ['button'] = function (parentFrame, setting)
                if not setting.id then
                    error('Kmo.Settings.types.button: setting.id must be provided', 4)
                end
                if not setting.label then
                    error('Kmo.Settings.types.button: setting.label must be provided', 4)
                end
                if not setting.settingGroup then
                    error('Kmo.Settings.types.button: setting.settingGroup must be provided', 4)
                end
                if not setting.callback then
                    error('Kmo.Settings.types.button: setting.callback must be provided', 4)
                end
                if not parentFrame then
                    error('Kmo.Settings.types.button: parentFrame must be provided', 3)
                end

                local buttonFrame = CreateFrame('Frame', setting.id .. '_ButtonFrame', parentFrame)
                buttonFrame:SetSize(160, 40)
                buttonFrame:SetPoint('TOPLEFT', parentFrame:GetChildren()[#parentFrame:GetChildren()], 'BOTTOMLEFT', 0, 0)
                if setting.tooltip then
                    buttonFrame:SetScript('OnEnter', function()
                        GameTooltip:SetOwner(buttonFrame, 'ANCHOR_TOPLEFT')
                        GameTooltip:SetText(setting.tooltip, nil, nil, nil, nil, true)
                        GameTooltip:Show()
                    end)
                    buttonFrame:SetScript('OnLeave', function()
                        GameTooltip:Hide()
                    end)
                end

                local button = CreateFrame('Button', setting.id .. '_Button', buttonFrame, 'UIPanelButtonTemplate')
                button:SetSize(160, 40)
                button:SetText(setting.label)
                button:SetPoint('TOPLEFT', buttonFrame, 'TOPLEFT', 0, 0)
                button:SetScript('OnClick', setting.callback)
            end,
        },
        __private = {
            settings = {},
        },
    }

    -- Define this here so we can use table.concat(Kmo.Settings.types, ', ')
    Kmo.Settings.errorMessages = {
        settingType = 'Kmo.ValidateSetting: setting.type must be provided and be one of ' .. table.concat(Kmo.Settings.types, ', '),
    }

    ---@param settingGroup Kmo.Settings.SettingGroup
    Kmo.Settings.ValidateSettingGroup = function (settingGroup)
        if not settingGroup then
            error('Kmo.Settings.ValidateSettingGroup: settingGroup must be provided', 3)
        end
        if not settingGroup.id then
            error('Kmo.Settings.ValidateSettingGroup: settingGroup.id must be provided', 3)
        end
        if Kmo.Settings.__private.settings[settingGroup.id] then
            error('Kmo.Settings.ValidateSettingGroup: A settingGroup with the same id already exists. settingGroup.id must be unique', 3)
        end
        if not settingGroup.id then
            error('Kmo.Settings.ValidateSettingGroup: settingGroup.id must be provided', 3)
        end
        if not settingGroup.settings then
            error('Kmo.Settings.ValidateSettingGroup: settingGroup.settings must be provided', 3)
        end
        if type(settingGroup.settings) ~= 'table' then
            error('Kmo.Settings.ValidateSettingGroup: settingGroup.settings must be a table', 3)
        end
        local i = 1
        for _, setting in pairs(settingGroup.settings) do
            -- If there are any tab settings, one of them must be first so we can grab the new tab frame
            if setting.type == 'tab' and i == 1 then
                return
            elseif setting.type == 'tab' then
                error('Kmo.Settings.ValidateSettingGroup: If there are any tab settings, one of them must be first', 3)
            end
        end
    end

    ---@param setting Kmo.Settings.Setting
    Kmo.Settings.ValidateSetting = function (setting)
        if not setting then
            error('Kmo.Settings.ValidateSetting: setting must be provided', 3)
        end
        if not setting.id then
            error('Kmo.Settings.ValidateSetting: setting.id must be provided', 3)
        end
        if not setting.type then
            error('Kmo.Settings.ValidateSetting: setting.type must be provided', 3)
        end
        if type(setting.type) ~= 'string' or not tContains(Kmo.Settings.types, setting.type) then
            error(Kmo.Settings.errorMessages.settingType, 3)
        end
        if setting.type == 'tab' then
            if not setting.settings then
                error('Kmo.Settings.ValidateSetting: setting.settings must be provided', 3)
            end
            if type(setting.settings) ~= 'table' then
                error('Kmo.Settings.ValidateSetting: setting.settings must be a table', 3)
            end
        end
        if not setting.scope then
            error('Kmo.Settings.ValidateSetting: setting.scope must be provided', 3)
        end
        if type(setting.scope) ~= 'number' or not tContains(Kmo.Settings.scope, setting.scope) then
            error('Kmo.Settings.ValidateSetting: setting.scope must be provided and must be between 1 and 3', 3)
        end
        if setting.label and type(setting.label) ~= 'string' then
            error('Kmo.Settings.ValidateSetting: setting.label must be a string', 3)
        end
        if setting.tooltip and type(setting.tooltip) ~= 'string' then
            error('Kmo.Settings.ValidateSetting: setting.tooltip must be a string', 3)
        end
        if setting.options and type(setting.options) ~= 'table' then
            error('Kmo.Settings.ValidateSetting: setting.options must be a table', 3)
        end
        if setting.default and (type(setting.default) ~= 'string' or type(setting.default) ~= 'number' or type(setting.default) ~= 'boolean') then
            error('Kmo.Settings.ValidateSetting: setting.default must be a string, number, or boolean', 3)
        end
        if setting.min and type(setting.min) ~= 'number' then
            error('Kmo.Settings.ValidateSetting: setting.min must be a number', 3)
        end
        if setting.max and type(setting.max) ~= 'number' then
            error('Kmo.Settings.ValidateSetting: setting.max must be a number', 3)
        end
    end

    ---Register a plugin's settings with the settings system
    ---@param settingGroup Kmo.Settings.SettingGroup
    Kmo.Settings.RegisterSettings = function (settingGroup)
        local success, error = pcall(Kmo.Settings.ValidateSettingGroup, settingGroup)
        local settingsTable = Kmo.Settings.Load(settingGroup)
        local settingsFrame = CreateFrame('Frame', 'KmoSettings_' .. settingGroup.id .. '_Frame', Kmo.UI.SettingsUI.__private.mainFrameTabContentFrame)
        for _, setting in pairs(settingGroup.settings) do
            setting.settingGroup = settingGroup.id
            success, error = pcall(Kmo.Settings.ValidateSetting, setting)
            if not success then
                BANETO_PrintDev('Error validating setting [' .. setting.id .. '] in settingGroup [' .. settingGroup.id .. ']: ' .. error)
            else
                BANETO_PrintDev('Registering setting [' .. setting.id .. '] in settingGroup [' .. settingGroup.id .. ']')
                -- TODO
                --  - 
                local createSettingfunction = Kmo.Settings.types[setting.type]
                if createSettingfunction then
                    if setting.type == 'tab' then
                        local tabFrame = createSettingfunction(settingsFrame, setting)
                        for _, tabSetting in pairs(setting.settings) do
                            success, error = pcall(Kmo.Settings.ValidateSetting, tabSetting)
                            if not success then
                                BANETO_PrintDev('Error validating setting [' .. tabSetting.id .. '] in settingGroup [' .. settingGroup.id .. ']: ' .. error)
                            else
                                BANETO_PrintDev('Registering setting [' .. tabSetting.id .. '] in settingGroup [' .. settingGroup.id .. ']')
                                createSettingfunction = Kmo.Settings.types[tabSetting.type]
                                if createSettingfunction then
                                    createSettingfunction(tabFrame, tabSetting)
                                else
                                    BANETO_PrintDev('Error registering setting [' .. tabSetting.id .. '] in settingGroup [' .. settingGroup.id .. ']: ' .. 'Invalid setting type: ' .. tabSetting.type)
                                end
                            end
                        end
                    else
                        createSettingfunction(settingsFrame, setting)
                    end
                else
                    BANETO_PrintDev('Error registering setting [' .. setting.id .. '] in settingGroup [' .. settingGroup.id .. ']: ' .. 'Invalid setting type: ' .. setting.type)
                end
            end
        end
        Kmo.Settings.__private.AddNewSettingsTab(settingGroup, settingsFrame)

        return settingsTable
    end

    Kmo.Settings.__private.AddNewSettingsTab = function (settingGroup, tabFrame)
        assert(settingGroup.label and tabFrame)
        local tabButton = CreateFrame('Button', 'KmoUISettingsFrameTabFrame' .. settingGroup.id .. 'TabButton', Kmo.UI.SettingsUI.__private.mainFrameTabListFrame, 'CharacterFrameTabButtonTemplate')
        tabButton:SetSize(100, 30)
        tabButton:SetText(settingGroup.label)
        tabButton:SetScript('OnClick', function()
            Kmo.UI.SettingsUI.__private.currentSettingsTabFrame:Hide()
            Kmo.UI.SettingsUI.__private.currentSettingsTabFrame = tabFrame
            tabFrame:Show()
        end)
        tabButton:SetPoint('TOPLEFT', Kmo.UI.SettingsUI.__private.mainFrameTabListFrame:GetChildren()[#Kmo.UI.SettingsUI.__private.mainFrameTabListFrame:GetChildren()], 'BOTTOMLEFT', 0, 0)
        tabFrame:SetPoint('TOPLEFT', Kmo.UI.SettingsUI.__private.mainFrameTabListFrame, 'TOPLEFT', 0, 0)
        tabFrame:Hide()
    end

    Kmo.Settings.ParseScopenumber = function(scope)
        assert(type(scope) == 'number', 'Kmo.Settings.ParseScopenumber: scope must be a number')
        local scopeObj = {}
        if bit.band(scope, Kmo.Settings.scope.CHARACTER) == Kmo.Settings.scope.CHARACTER then
            scopeObj.character = true
        end
        if bit.band(scope, Kmo.Settings.scope.REALM) == Kmo.Settings.scope.REALM then
            scopeObj.realm = true
        end
        if bit.band(scope, Kmo.Settings.scope.ACCOUNT) == Kmo.Settings.scope.ACCOUNT then
            scopeObj.account = true
        end
        return scopeObj
    end

    Kmo.Settings.__private.GetSettingsPathForScope = function(scope)
        if type(scope) == 'string' then
            scope = string.lower(scope)
            if scope == Kmo.Settings.scopeStrings[Kmo.Settings.scope.CHARACTER] then
                scope = Kmo.Settings.scope.CHARACTER
            elseif scope == 'realm' then
                scope = Kmo.Settings.scope.REALM
            elseif scope == 'account' then
                scope = Kmo.Settings.scope.ACCOUNT
            else
                assert(false, 'Kmo.Settings.__private.GetSettingsPathForScope: if scope is a string it must be one of "character", "account", or "realm"')
            end
        end
        assert(scope and type(scope) == 'number' and tContains(Kmo.Settings.scope, scope), 'Kmo.Settings.__private.GetSettingsPathForScope: scope must be provided and must be 1 or 2')
        local scopeObj = Kmo.Settings.ParseScopenumber(scope)
        local pathName = '/Settings/Kmo'
        if scopeObj.account then
            pathName = pathName .. '/' .. ObjectField(UnitGUID("player"), 0xde40, 6)
        end
        if scopeObj.realm then
            pathName = pathName .. '/' .. GetRealmName()
        end
        if scopeObj.character then
            pathName = pathName .. '/' .. UnitGUIDUnlocked('player')
        end
        local path = {}
        for str in string.gmatch(pathName, "([^/]+)") do
            table.insert(path, str)
        end
        Kmo.Common.EnsureFoldersExist(path)
        return pathName
    end

    Kmo.Settings.Get = function(key, defaultValue, scope, settingGroup)
        assert(key and scope)
        if settingGroup then
            if Kmo.Settings.__private.settings[settingGroup] == nil then
                Kmo.Settings.__private.settings[settingGroup] = {}
                Kmo.Settings.__private.settings[settingGroup][scope] = {}
                Kmo.Settings.__private.settings[settingGroup][scope][key] = defaultValue
                return defaultValue
            end
            if Kmo.Settings.__private.settings[settingGroup][scope] == nil then
                Kmo.Settings.__private.settings[settingGroup][scope] = {}
                Kmo.Settings.__private.settings[settingGroup][scope][key] = defaultValue
                return defaultValue
            end
            if Kmo.Settings.__private.settings[settingGroup][scope][key] == nil then
                Kmo.Settings.__private.settings[settingGroup][scope][key] = defaultValue
                return defaultValue
            end
            return Kmo.Settings.__private.settings[settingGroup][scope][key]
        end
        if Kmo.Settings.__private.settings[scope] == nil then
            Kmo.Settings.__private.settings[scope] = {}
            Kmo.Settings.__private.settings[scope][key] = defaultValue
            return defaultValue
        end
        return Kmo.Settings.__private.settings[scope][key]
    end

    Kmo.Settings.Set = function(key, scope, value, settingGroupId)
        assert(key)
        if settingGroupId then
            if not Kmo.Settings.__private.settings[settingGroupId] then
                Kmo.Settings.__private.settings[settingGroupId] = {}
                Kmo.Settings.__private.settings[settingGroupId][scope] = {}
            end
            Kmo.Settings.__private.settings[settingGroupId][scope][key] = value
        else
            Kmo.Settings.__private.settings[key][scope] = value
        end
    end

    -- TODO - Switch to plugin data for loading/saving settings
    ---@param settingGroup Kmo.Settings.SettingGroup
    Kmo.Settings.Load = function(settingGroup)
        if not settingGroup then
            error('Kmo.Settings.Load: settingGroup must be provided', 2)
        end
        if not settingGroup.id then
            error('Kmo.Settings.Load: settingGroup.id must be provided', 2)
        end
        if not settingGroup.scope or type(settingGroup.scope) ~= 'number' or settingGroup.scope < Kmo.Settings.scopeMin or settingGroup.scope > Kmo.Settings.scopeMax then
            error('Kmo.Settings.Load: settingGroup.scope must be provided and must be between ' .. Kmo.Settings.scopeMin .. ' and ' .. Kmo.Settings.scopeMax, 2)
        end
        if Kmo.Settings.__private.settings[settingGroup.id] then
            error('Kmo.Settings.Load: settings for ' .. settingGroup.id .. ' have already been loaded', 2)
        end
        local fileName = Kmo.Settings.__private.GetSettingsPathForScope(settingGroup.scope) .. '/' .. settingGroup.id .. '.json'
        if not FileExists(fileName) then
            return
        end
        local settingsstring = BANETO_ReadFile(fileName)
        local settings = BANETO_JsonDecode(settingsstring)
        if settings then
            Kmo.Settings.__private.settings[settingGroup] = settings
        end
        return Kmo.Settings.__private.settings[settingGroup]
    end

    ---@param pluginScope Kmo.PluginData.PluginScope
    Kmo.Settings.Save = function(pluginScope)
        assert(pluginScope)
        assert(pluginScope.pluginName, 'Kmo.Settings.Load: settingGroup.id must be provided')
        assert(pluginScope.scope and type(pluginScope.scope) == 'number' and tContains(Kmo.Settings.scope, pluginScope.scope), 'Kmo.Settings.Load: settingGroup.scope must be provided and must be between 1 and 3')
        local fileName = Kmo.Settings.__private.GetSettingsPathForScope(pluginScope.scope) .. '/' .. pluginScope.pluginName .. '.json'
        local settingsstring = BANETO_JsonEncode(Kmo.Settings.__private.settings[pluginScope])
        BANETO_WriteFile(fileName, settingsstring)
    end

    Kmo.Settings.mainFrame = CreateFrame('Frame', 'KmoSettingsFrame', UIParent)
    Kmo.Settings.mainFrame:SetScript('OnEvent', function(self, event, ...)
        if event == 'ADDONS_UNLOADING' then
            for _, settingGroup in ipairs(Kmo.Settings.__private.settings) do
                Kmo.Settings.Save(settingGroup)
            end
        end
    end)

    Kmo.loadedPlugins['Settings'] = true
end

if not Kmo.loadedPlugins['PluginData'] then
    ---@class Kmo.PluginData

    ---@class Kmo.PluginData.PluginScope
    ---@field pluginName string - name of the plugin to create data for
    ---@field scope Kmo.Settings.Scope - scope of the data to create. Bitwise Or of 'character' (1), 'realm' (2), and 'account' (4) (e.g. 3 for character and realm)


    Kmo.PluginData = {
        __private = {
            data = {},
        },
    }

    --- function to create a file if it doesn't exist given a path to search and a filename to match
    --- @param path string - path to search for the file
    --- @param fileName string - name of the file to create if it doesn't exist
    Kmo.PluginData.__private.CreateIfNotExists = function(path, fileName)
        -- TODO - figure out how ListFiles works or get Bambo to implement FileExists(path)
        if not FileExists(path .. '/' .. fileName) then
            if string.find(fileName, '.json') then
                BANETO_WriteFile(path .. '/' .. fileName, '{}')
            else
                BANETO_WriteFile(path .. '/' .. fileName, '')
            end
        end
    end

    --- function to load or create plugin data for a given scope
    --- @param scope Kmo.PluginData.PluginScope plugin information to load or create data for
    --- @return table - The plugin data for the given scope, either loaded from disk or an empty table, changes to this table will be saved to disk when addons are unloaded
    Kmo.PluginData.LoadOrCreate = function(scope)
        if not scope then
            error('Kmo.PluginData.LoadOrCreate: scope must be provided', 2)
        end
        if not scope.pluginName then
            error('Kmo.PluginData.LoadOrCreate: scope.pluginName must be provided', 2)
        end
        if not scope.scope then
            error('Kmo.PluginData.LoadOrCreate: scope.scope must be provided', 2)
        end
        if type(scope.scope) ~= 'number' or not tContains(Kmo.Settings.scope, scope.scope) then
            error('Kmo.PluginData.LoadOrCreate: scope.scope must be provided and must be between ' .. Kmo.Settings.scopeMin .. ' and ' .. Kmo.Settings.scopeMax, 2)
        end
        if Kmo.PluginData.__private.data[scope.pluginName] then
            return Kmo.PluginData.__private.data[scope.pluginName]
        else
            Kmo.PluginData.__private.data[scope.pluginName] = {
                ['character'] = {},
                ['realm'] = {},
                ['account'] = {},
            }
        end
        local pluginFilename = scope.pluginName .. '.json'
        local scopeObj = Kmo.Settings.ParseScopenumber(scope.scope)
        if scopeObj.character then
            local path = Kmo.Settings.__private.GetSettingsPathForScope('character')
            Kmo.PluginData.__private.CreateIfNotExists(path, pluginFilename)
            local pluginDatastring = BANETO_ReadFile(path .. '/' .. pluginFilename) or '{}'
            local pluginData = BANETO_JsonDecode(pluginDatastring) or {}
            Kmo.PluginData.__private.data[scope.pluginName]['character'] = pluginData
        end
        if scopeObj.realm then
            local path = Kmo.Settings.__private.GetSettingsPathForScope('realm')
            Kmo.PluginData.__private.CreateIfNotExists(path, pluginFilename)
            local pluginDatastring = BANETO_ReadFile(path .. '/' .. pluginFilename) or '{}'
            local pluginData = BANETO_JsonDecode(pluginDatastring) or {}
            Kmo.PluginData.__private.data[scope.pluginName]['realm'] = pluginData
        end
        if scopeObj.account then
            local path = Kmo.Settings.__private.GetSettingsPathForScope('account')
            Kmo.PluginData.__private.CreateIfNotExists(path, pluginFilename)
            local pluginDatastring = BANETO_ReadFile(path .. '/' .. pluginFilename) or '{}'
            local pluginData = BANETO_JsonDecode(pluginDatastring) or {}
            Kmo.PluginData.__private.data[scope.pluginName]['account'] = pluginData
        end
        return Kmo.PluginData.__private.data[scope.pluginName]
    end

    --- function to release plugin data for a given scope
    --- @param scope Kmo.PluginData.PluginScope plugin information to release data for
    Kmo.PluginData.Release = function(scope)
        if not scope then
            error('Kmo.PluginData.Release: scope must be provided', 2)
        end
        if not scope.pluginName then
            error('Kmo.PluginData.Release: scope.pluginName must be provided', 2)
        end
        if not scope.scope then
            error('Kmo.PluginData.Release: scope.scope must be provided', 2)
        end
        if type(scope.scope) ~= 'number' or not (Kmo.Settings.scopeMin >= scope.scope and Kmo.Settings.scopeMax <= scope.scope) then
            error('Kmo.PluginData.Release: scope.scope must be provided and must be between ' .. Kmo.Settings.scopeMin .. ' and ' .. Kmo.Settings.scopeMax, 2)
        end
        local scopeObj = Kmo.Settings.ParseScopenumber(scope.scope)
        if scopeObj.character then
            Kmo.PluginData.__private.data[scope.pluginName]['character'] = nil
        end
        if scopeObj.realm then
            Kmo.PluginData.__private.data[scope.pluginName]['realm'] = nil
        end
        if scopeObj.account then
            Kmo.PluginData.__private.data[scope.pluginName]['account'] = nil
        end
        if not Kmo.PluginData.__private.data[scope.pluginName]['character'] and not Kmo.PluginData.__private.data[scope.pluginName]['realm'] and not Kmo.PluginData.__private.data[scope.pluginName]['account'] then
            Kmo.PluginData.__private.data[scope.pluginName] = nil
        end
    end

    --- function to save all plugin data for a given plugin
    --- @param pluginName string - name of the plugin to save data for
    Kmo.PluginData.Save = function(pluginName)
        local pluginData = Kmo.PluginData.__private.data[pluginName]
        if not pluginData then
            return
        end
        for scope, scopeData in pairs(pluginData) do
            local path = Kmo.Settings.__private.GetSettingsPathForScope(scope)
            path = path .. '/' .. pluginName .. '.json'
            local success, pluginDatastring = pcall(BANETO_JsonEncode, scopeData)
            if success then
                BANETO_WriteFile(path, pluginDatastring, false)
            end
        end
    end

    local mainFrame = CreateFrame('Frame', 'KmoPluginDataFrame', UIParent)
    Kmo.PluginData.mainFrame = mainFrame
    mainFrame:RegisterEvent('ADDONS_UNLOADING')
    mainFrame:SetScript('OnEvent', function(self, event, ...)
        if event == 'ADDONS_UNLOADING' then
            for pluginName in pairs(Kmo.PluginData.__private.data) do
                Kmo.PluginData.Save(pluginName)
            end
        end
    end)

    Kmo.loadedPlugins['PluginData'] = true
end

if not Kmo.loadedPlugins['Logging'] then
    ---@class Kmo.Logging
    Kmo.Logging = {
        __private = {
            loggers = {},
        },
        ---@enum Kmo.Logging.LEVELS
        LEVELS = {
            DEBUG = 0,
            INFO = 1,
            WARN = 2,
            ERROR = 3,
            FATAL = 4,
        }
    }

    ---@enum Kmo.Logging.LEVELS_STRINGS
    Kmo.Logging.LEVELS_STRINGS = {
        [Kmo.Logging.LEVELS.DEBUG] = 'DEBUG',
        [Kmo.Logging.LEVELS.INFO] = 'INFO',
        [Kmo.Logging.LEVELS.WARN] = 'WARN',
        [Kmo.Logging.LEVELS.ERROR] = 'ERROR',
        [Kmo.Logging.LEVELS.FATAL] = 'FATAL',
    }

    ---@class Kmo.Logging.Logger
    ---@field level number - minimum level of logs to log
    ---@field logFile string - path to the log file to log to (make sure the folder exists, @see Kmo.Common.EnsureFoldersExist)
    ---@field Log function - function to log a log to the logger
    local defaultLogger = {
        level = Kmo.Logging.LEVELS.DEBUG,
        logFile = '/Logs/KmoDefault.log',

        Log = function(self, log)
            assert(log and log.level and log.time and log.message)
            assert(log.level >= Kmo.Logging.LEVELS.DEBUG and log.level <= Kmo.Logging.LEVELS.FATAL, 'Invalid log level: ' .. tostring(log.level)..'. Must be between 0 and 4')
            if log.level < self.level then
                return
            end
            local logstring = string.format('[%s] %s: %s', date('%Y-%m-%d %H:%M:%S', log.time), Kmo.Logging.LEVELS_STRINGS[log.level], log.message)
            BANETO_WriteFile(self.logFile, logstring, true)
        end
    }

    local middle = '   Kmo Logging Started at: ' .. date('%Y-%m-%d %H:%M:%S   ')
    local x = (80 - string.len(middle)) / 2
    local logHeader = string.rep('-', 80) .. '\n' .. string.rep('-', x) .. middle .. string.rep('-', x) .. '\n' .. string.rep('-', 80) .. '\n'
    Kmo.Common.EnsureFoldersExist({'Logs'})
    if not FileExists(defaultLogger.logFile) then
        BANETO_WriteFile(defaultLogger.logFile, logHeader)
    else
        BANETO_WriteFile(defaultLogger.logFile, '\n\n' .. logHeader, true)
    end

    table.insert(Kmo.Logging.__private.loggers, defaultLogger)

    ---@description Adds a logger to the list of loggers to log to
    ---@param logger Kmo.Logging.Logger - logger to add
    function Kmo.Logging:AddLogger(logger)
        assert(logger)
        table.insert(self.__private.loggers, logger)
    end

    ---@description Logs a log to all loggers
    ---@param level Kmo.Logging.LEVELS - level of the log to log
    ---@vararg any - message to log
    function Kmo.Logging:Log(level, ...)
        local log = {
            level = level,
            time = time(),
            ---@diagnostic disable-next-line: param-type-mismatch
            message = strjoin(" ", tostringall(...)),
        }
        for _, logger in ipairs(self.__private.loggers) do
            logger:Log(log)
        end
    end

    ---@description Logs a log to all loggers and prints it to the chat frame
    ---@param pluginName string - name of the plugin to log for
    ---@param level Kmo.Logging.LEVELS - level of the log to log
    ---@vararg any - message to log
    function Kmo.Logging:Print(pluginName, level, ...)
        if not level then
            level = self.LEVELS.INFO
        end
        local message = ''
        if pluginName then
            local color = '|cFFFF55AA['
            if string.find(pluginName, 'Kmo') then
                color = '|cFFCC00FF['
            end
            message = color .. pluginName .. ']|r' .. ': '
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        message = message .. strjoin(" ", tostringall(...))
        if level >= self.LEVELS.ERROR then
            BANETO_PrintError(message)
        elseif level >= self.LEVELS.WARN then
            BANETO_PrintWarning(message)
        elseif level >= self.LEVELS.INFO then
            BANETO_PrintPlugin(message)
        else
            BANETO_PrintDev(message)
        end
        local log = {
            level = level,
            time = time(),
            message = message,
        }
        for _, logger in ipairs(self.__private.loggers) do
            logger:Log(log)
        end
    end

    ---@description Writes a DEBUG level message to all loggers
    ---@vararg any - message to log
    function Kmo.Logging:Debug(...)
        self:Log(Kmo.Logging.LEVELS.DEBUG, ...)
    end

    ---@description Writes an INFO  level message to all loggers
    ---@vararg any - message to log
    function Kmo.Logging:Info(...)
        self:Log(self.LEVELS.INFO, ...)
    end

    ---@description Writes a WARN level message to all loggers
    ---@vararg any - message to log
    function Kmo.Logging:Warn(...)
        self:Log(self.LEVELS.WARN, ...)
    end

    ---@description Writes a ERROR level message to all loggers
    ---@vararg any - message to log
    function Kmo.Logging:Error(...)
        self:Log(self.LEVELS.ERROR, ...)
    end

    ---@description Writes a FATAL level message to all loggers
    ---@vararg any - message to log
    function Kmo.Logging:Fatal(...)
        self:Log(self.LEVELS.FATAL, ...)
    end

    Kmo.loadedPlugins['Logging'] = true
end

if not Kmo.loadedPlugins['UI'] then
    ---@class Kmo.UI
    Kmo.UI = {}
    Kmo.UI.SettingsUI = {
        __private = {
            currentSettingsTabFrame = nil,
        },
    }

    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local mainFrameWidth = screenWidth * 0.66
    local mainFrameHeight = screenHeight * 0.66
    local mainFrame = CreateFrame('Frame', 'KmoUISettingsFrame', UIParent)
    Kmo.UI.SettingsUI.__private.mainFrame = mainFrame
    mainFrame = CreateFrame('Frame', 'KmoUISettingsFrame', UIParent)
    mainFrame:SetSize(mainFrameWidth, mainFrameHeight)
    mainFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', (screenWidth - mainFrameWidth) / 2, -(screenHeight - mainFrameHeight) / 2)
    mainFrame:SetMovable(true)
    mainFrame:Hide()

    local mainFrameBackgroundTexture = mainFrame:CreateTexture(nil, 'BACKGROUND')
    mainFrameBackgroundTexture:SetColorTexture(0, 0, 0, 0.75)
    mainFrameBackgroundTexture:SetAllPoints(mainFrame)
    mainFrameBackgroundTexture:SetSize(mainFrame:GetSize())

    local mainFrameTitleText = mainFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    mainFrameTitleText:SetPoint('CENTER', mainFrame, 'TOP', 0, -8)
    mainFrameTitleText:SetText("Kumouri's Baneto Plugins Settings")
    mainFrameTitleText:SetScale(1.5)

    local mainFrameCloseButton = CreateFrame('Button', 'KmoUISettingsFrameCloseButton', mainFrame, 'UIPanelCloseButton')
    mainFrameCloseButton:SetPoint('TOPRIGHT', mainFrame, 'TOPRIGHT', -8, -8)
    mainFrameCloseButton:SetScript('OnClick', function()
        mainFrame:Hide()
    end)

    local function UpdateSettingsFrameLocation()
        local Xpoa, Ypoa = GetCursorPosition()
        local Xmin, Ymin = UIParent:GetLeft(), UIParent:GetTop()
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Xpoa - Xmin, Ymin - Ypoa)
    end

    mainFrame:RegisterForDrag('LeftButton')
    mainFrame:SetScript('OnDragStart', function()
        mainFrame:StartMoving()
        mainFrame:SetScript('OnUpdate', UpdateSettingsFrameLocation)
    end)

    mainFrame:SetScript('OnDragStop', function()
        mainFrame:StopMovingOrSizing()
        mainFrame:SetScript('OnUpdate', nil)
        UpdateSettingsFrameLocation()
    end)

    local mainFrameTabListFrame = CreateFrame('Frame', 'KmoUISettingsFrameTabListFrame', mainFrame)
    Kmo.UI.SettingsUI.__private.mainFrameTabListFrame = mainFrameTabListFrame
    mainFrameTabListFrame = CreateFrame('Frame', 'KmoUISettingsFrameTabFrame', mainFrame)
    mainFrameTabListFrame:SetSize(mainFrame:GetWidth() * 0.25, mainFrame:GetHeight() - 32)
    mainFrameTabListFrame:SetPoint('TOPLEFT', mainFrame, 'TOPLEFT', 8, -8)

    local mainFrameContentFrame = CreateFrame('Frame', 'KmoUISettingsFrameContentFrame', mainFrame)
    Kmo.UI.SettingsUI.__private.mainFrameTabContentFrame = mainFrameContentFrame
    mainFrameContentFrame:SetSize(Kmo.UI.SettingsUI.__private.mainFrame:GetWidth() * 0.75 - 8, mainFrame:GetHeight() - 32)
    mainFrameContentFrame:SetPoint('TOPLEFT', mainFrameTabListFrame, 'TOPRIGHT', 8, 0)

    function Kmo.UI.SettingsUI:AddNewSettingsTab(name, tabFrame)
        assert(name and tabFrame)
        local tabButton = CreateFrame('Button', 'KmoUISettingsFrameTabFrame' .. name .. 'TabButton', self.__private.mainFrameTabListFrame, 'CharacterFrameTabButtonTemplate')
        tabButton:SetSize(100, 30)
        tabButton:SetText(name)
        tabButton:SetScript('OnClick', function()
            if self.__private.currentSettingsTabFrame and self.__private.currentSettingsTabFrame ~= tabFrame then
                self.__private.currentSettingsTabFrame:Hide()
                tabFrame:Show()
                self.__private.currentSettingsTabFrame = tabFrame
            end
        end)
        tabButton:SetPoint('TOPLEFT', self.__private.mainFrameTabListFrame:GetChildren()[#self.__private.mainFrameTabListFrame:GetChildren()], 'BOTTOMLEFT', 0, -8)
        tabFrame:SetPoint('TOPLEFT', self.__private.mainFrameTabListFrame, 'TOPLEFT', 0, 0)
        tabFrame:Hide()
    end

    -- Minimap button
    local minibtn = CreateFrame("Button", nil, Minimap)
    minibtn:SetFrameLevel(9)
    minibtn:SetSize(32,32)
    minibtn:SetMovable(true)

    minibtn:SetNormalTexture("Interface/COMMON/help-i.png")
    minibtn:SetPushedTexture("Interface/COMMON/Indicator-Green.png")
    minibtn:SetHighlightTexture("Interface/COMMON/friendship-heart.png")

    local myIconPos = 0

    -- Control movement
    local function UpdateMapBtn()
        -- Get the width and height of the minimap and scale it to get the real width and height
        local Xmin, Ymin, width, height = Minimap:GetRect()
        width = width * Minimap:GetEffectiveScale()
        height = height * Minimap:GetEffectiveScale()

        local Xpoa, Ypoa = GetCursorPosition()

        -- Calculate the position of the cursor relative to the center of the minimap
        Xpoa = Xmin - Xpoa / Minimap:GetEffectiveScale() + 70
        Ypoa = Ypoa / Minimap:GetEffectiveScale() - Ymin - 70

        -- Calculate the angle of the cursor relative to the center of the minimap
        myIconPos = math.deg(math.atan2(Ypoa, Xpoa))

        minibtn:ClearAllPoints()
        -- Set new position based on the width, height, and angle
        minibtn:SetPoint("CENTER", Minimap, "CENTER", -(width * cos(myIconPos)), (height * sin(myIconPos)))
    end

    minibtn:RegisterForDrag("LeftButton")
    minibtn:SetScript("OnDragStart", function()
        minibtn:StartMoving()
        minibtn:SetScript("OnUpdate", UpdateMapBtn)
    end)

    minibtn:SetScript("OnDragStop", function()
        minibtn:StopMovingOrSizing();
        minibtn:SetScript("OnUpdate", nil)
        UpdateMapBtn();
    end)

    local _, _, width, height = Minimap:GetRect()
    width = width * Minimap:GetEffectiveScale()
    height = height * Minimap:GetEffectiveScale()
    -- Set position
    minibtn:ClearAllPoints()
    minibtn:SetPoint("CENTER", Minimap, "CENTER", -(width * cos(myIconPos)), (height * sin(myIconPos)))

    -- Control clicks
    minibtn:SetScript("OnClick", function()
        if Kmo.UI.SettingsUI.__private.mainFrame:IsVisible() then
            Kmo.UI.SettingsUI.__private.mainFrame:Hide()
        else
            Kmo.UI.SettingsUI.__private.mainFrame:Show()
        end
    end)

    Kmo.loadedPlugins['UI'] = true
end

Kmo.loadedPlugins['KmoCommon'] = true