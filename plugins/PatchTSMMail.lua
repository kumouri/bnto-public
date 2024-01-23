--[[
Copyright 2023 Will Armstrong, All Rights Reserved.

Version: 1.0.0

This patches TSM to allow for the following:
    - Opening all mail without money
    - Sending groups
    - Sending disenchantables
    - Sending other items
]]
if not Kmo then
    _G.Kmo = {}
    Kmo.loadedPlugins = {}
end

if not Kmo.loadedPlugins then
    Kmo.loadedPlugins = {}
end

if not Kmo.loading then
    Kmo.loading = {}
end

if not Kmo.loadedPlugins['PatchUtil'] and not Kmo.loading['PatchUtil'] then
    Kmo.loading['PatchUtil'] = true
    BANETO_CommunityFile([[KmoLib]],[[PatchUtil]])
end

if Kmo and Kmo.PatchUtil and Kmo.loadedPlugins and Kmo.loadedPlugins['PatchUtil'] and not Kmo.loadedPlugins['PatchTSMMail'] then
    Kmo.PatchUtil.PatchTSMMail = function()
        local PATCH_STRING = '-- KumouriTsmMailing_Patched = 1.0'
        local patchedFile = false

        local uiMailingUiCorePath = 'Interface/Addons/TradeSkillMaster/Core/UI/MailingUI/Core.lua'
        local uiMailingUiCorePatchTable = {
            {
                offset = 2,
                pattern = 'private%.frame:SetSelectedNavButton%(buttonText, redraw%)',
                insert = {
                    {
                        insert = 'function MailingUI.GetSelectedTab()',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = 'if not private.frame then',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'return false',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'return private.frame:GetSelectedNavButton()',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = '',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = 'function MailingUI.IsPageOpen(name)',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = 'if not private.frame then',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'return false',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'return private.frame:GetSelectedNavButton() == name',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    }
                }
            }
        }
        patchedFile = Kmo.PatchUtil.patchFile(uiMailingUiCorePath, PATCH_STRING, uiMailingUiCorePatchTable, false)

        local uiMailingUiGroupsPath = 'Interface/Addons/TradeSkillMaster/Core/UI/MailingUI/Groups.lua'
        local uiMailingUiGroupsPatchTable = {
            {
                offset = 0,
                pattern = ':AddChild%(UIElements%.New%(\"ActionButton\", \"mailGroupBtn\"%)',
                insert = {
                    {
                        insert = ':AddChild(UIElements.NewNamed(\'ActionButton\', \'mailGroupBtn\', \'TSMMailGroupsBtn\')',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                        replace = true,
                    }
                }
            },
            {
                offset = 0,
                pattern = 'function private%.FSMGroupsCallback%(%)',
                insert = {
                    {
                        insert = 'if _G.Kmo and Kmo.Tsm and Kmo.Tsm.Mailing then',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'BANETO_PrintDev("Sending groups done")',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'Kmo.Tsm.Mailing._signals.sendingGroupsDone = true',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '\t',
                    }
                }
            }
        }
        patchedFile = Kmo.PatchUtil.patchFile(uiMailingUiGroupsPath, PATCH_STRING, uiMailingUiGroupsPatchTable, false)

        local uiMailingUiOtherPath = 'Interface/Addons/TradeSkillMaster/Core/UI/MailingUI/Other.lua'
        local uiMailingUiOtherPatchTable = {
            {
                offset = 11,
                pattern = ':AddChild%(UIElements%.New%("Frame", "enchantHeader"%)',
                insert = {
                    {
                        insert = ':AddChild(UIElements.NewNamed(\'ActionButton\', \'send\', \'TSMSendDeBtn\')',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                        replace = true,
                    }
                }
            },
            {
                offset = 20,
                pattern = ':AddChild%(UIElements%.New%("Frame", "goldHeader"%)',
                insert = {
                    {
                        insert = ':AddChild(UIElements.NewNamed(\'ActionButton\', \'send\', \'TSMSendGoldBtn\')',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                        replace = true,
                    }
                }
            },
            {
                offset = 1,
                pattern = 'elseif items then',
                insert = {
                    {
                        insert = 'TSM.Mailing.Send.StartSending(private.FSMDeCallback, recipient, "TSM Mailing: Disenchantables", "", money, items)',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                        replace = true,
                    }
                }
            },
            {
                offset = 1,
                pattern = 'function private%.FSMOthersCallback%(%)',
                insert = {
                    {
                        insert = 'if _G.Kmo and Kmo.Tsm and Kmo.Tsm.Mailing then',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'BANETO_PrintDev("Sending others done")',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'Kmo.Tsm.Mailing._signals.sendingOthersDone = true',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'private.fsm:ProcessEvent("EV_SENDING_DONE")',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = '',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = 'function private.FSMDeCallback()',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = 'if _G.Kmo and Kmo.Tsm and Kmo.Tsm.Mailing then',
                            ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'BANETO_PrintDev("Sending DE done")',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'Kmo.Tsm.Mailing._signals.sendingDeDone = true',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                },
            }
        }
        patchedFile = Kmo.PatchUtil.patchFile(uiMailingUiOtherPath, PATCH_STRING, uiMailingUiOtherPatchTable, false)

        local coreServiceMailingGroupsPath = 'Interface/Addons/TradeSkillMaster/Core/Service/Mailing/Groups.lua'
        local coreServiceMailingGroupsPatchTable = {
            {
                offset = 1,
                pattern = 'if not next%(targets%) then',
                insert = {
                    {
                        insert = 'if _G.Kmo and Kmo.Tsm and Kmo.Tsm.Mailing then',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'BANETO_PrintDev("Sending groups done")',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'Kmo.Tsm.Mailing._signals.sendingGroupsDone = true',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '\t\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '\t',
                    }
                }
            }
        }
        patchedFile = Kmo.PatchUtil.patchFile(coreServiceMailingGroupsPath, PATCH_STRING, coreServiceMailingGroupsPatchTable, false)

        local uiMailingUiInboxPath = 'Interface/Addons/TradeSkillMaster/Core/UI/MailingUI/Inbox.lua'
        local uiMailingUiInboxPatchTable = {
            {
                offset = -5,
                pattern = ':SetModifierText%(L%["Open All Mail Without Money"%], "CTRL"%)',
                insert = {
                    {
                        insert = ':AddChild(UIElements.NewNamed("ActionButton", "openAllMail", "TSMOpenAllMailBtn")',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                        replace = true,
                    }
                }
            },
            {
                offset = -5,
                pattern = ':SetModifierText%(L%["Open Mail Without Money"%], "CTRL"%)',
                insert = {
                    {
                        insert = ':AddChild(UIElements.NewNamed("ActionButton", "openAllMail", "TSMOpenAllMailBtn")',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                        replace = true,
                    }
                }
            },
            {
                offset = 1,
                pattern = 'openAll = IsShiftKeyDown%(%)',
                insert = {
                    {
                        insert = 'if _G.Kmo and Kmo.Tsm and Kmo.Tsm.Mailing then',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = 'BANETO_PrintDev("Opening all mail")',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'openAll = Kmo.Tsm.Mailing.__private.settings.openAllMail',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    }
                }
            },
            {
                offset = 0,
                pattern = 'private%.fsm:ProcessEvent%("EV_OPENING_DONE"%)',
                insert = {
                    {
                        insert = 'if _G.Kmo and Kmo.Tsm and Kmo.Tsm.Mailing then',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    },
                    {
                        insert = 'BANETO_PrintDev("Opening done")',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'Kmo.Tsm.Mailing._signals.openingDone = true',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '\t',
                    },
                    {
                        insert = 'end',
                        ignoreLeadingWhitespace = false,
                        leadingWhitespace = '',
                    }
                }
            }
        }
        patchedFile = Kmo.PatchUtil.patchFile(uiMailingUiInboxPath, PATCH_STRING, uiMailingUiInboxPatchTable, false)

        local tsmCorePath = 'Interface/Addons/TradeSkillMaster/LibTSM/Core.lua'
        local tsmCorePatchTable = {
            {
                offset = 0,
                pattern = 'local private = {',
                insert = {
                    {
                        insert = '_G.TSM = TSM',
                        ignoreLeadingWhitespace = true,
                        leadingWhitespace = '',
                    }
                }
            }
        }
        patchedFile = Kmo.PatchUtil.patchFile(tsmCorePath, '-- KumouriTsmCommon_Patched = 1.0', tsmCorePatchTable, false)

        if patchedFile then
            Kmo.PatchUtil.reloadUI()
        else
            BANETO_PrintPlugin('TSM already patched for Mailing operations!')
        end
    end

    Kmo.loadedPlugins['PatchTSMMail'] = true
    Kmo.PatchUtil.PatchTSMMail()
end