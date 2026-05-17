-- CyrHUDConsole settings.lua — Harvens panel
-- Replaces the PC menu.lua (LibAddonMenu-2) since LAM doesn't exist on console.

CyrHUD = CyrHUD or {}

local POSITION_ITEMS = {
    { name = "TOP_RIGHT"    },
    { name = "TOP_LEFT"     },
    { name = "MIDDLE_RIGHT" },
    { name = "MIDDLE_LEFT"  },
    { name = "BOTTOM_RIGHT" },
    { name = "BOTTOM_LEFT"  },
}

function CyrHUD.registerSettings()
    if CyrHUD._settingsRegistered then return end
    CyrHUD._settingsRegistered = true

    local LHAS = LibHarvensAddonSettings
    if not LHAS then
        d("|cFF0000[CyrHUDConsole] LibHarvensAddonSettings not loaded — settings panel unavailable")
        return
    end

    local panel = LHAS:AddAddon("CyrHUD", { allowDefaults = true })

    panel:AddSetting({
        type = LHAS.ST_SECTION,
        label = GetString(SI_CAMPAIGNRULESETTYPE1),   -- "Cyrodiil"
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_ITEM_ACTION_USE) .. " CyrHUD",
        default = true,
        getFunction = function() return CyrHUD.cfg.enableInCyro end,
        setFunction = function(v) CyrHUD.cfg.enableInCyro = v; CyrHUD.playerInit() end,
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_CYRHUD_POPBAR),
        tooltip = GetString(SI_CYRHUD_POPBAR_INFO),
        default = false,
        getFunction = function() return CyrHUD.cfg.showPopBars end,
        setFunction = function(v) CyrHUD.cfg.showPopBars = v; CyrHUD:reconfigureLabels() end,
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_CYRHUD_HIDE_BRIDGESANDMILEGATES),
        tooltip = GetString(SI_CYRHUD_HIDE_BRIDGESANDMILEGATES_INFO),
        default = false,
        getFunction = function() return CyrHUD.cfg.hideBridgesAndMilegates end,
        setFunction = function(v) CyrHUD.cfg.hideBridgesAndMilegates = v; CyrHUD:reconfigureLabels() end,
    })

    panel:AddSetting({
        type = LHAS.ST_SECTION,
        label = GetString(SI_CAMPAIGNRULESETTYPE4),   -- "Imperial City"
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_ITEM_ACTION_USE) .. " CyrHUD",
        default = true,
        getFunction = function() return CyrHUD.cfg.enableInIC end,
        setFunction = function(v) CyrHUD.cfg.enableInIC = v; CyrHUD.playerInit() end,
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_CYRHUD_HIDE_IC),
        tooltip = GetString(SI_CYRHUD_HIDE_IC_INFO),
        default = false,
        getFunction = function() return CyrHUD.cfg.hideImpBattles end,
        setFunction = function(v) CyrHUD.cfg.hideImpBattles = v; CyrHUD:reconfigureLabels() end,
    })

    panel:AddSetting({
        type = LHAS.ST_CHECKBOX,
        label = GetString(SI_GAMECAMERAACTIONTYPE24) .. " " ..
                GetString(SI_CAMPAIGNRULESETTYPE4) .. " " ..
                GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES501),
        default = false,
        getFunction = function() return CyrHUD.cfg.hidePatrollingHorrors end,
        setFunction = function(v)
            CyrHUD.cfg.hidePatrollingHorrors = v
            CyrHUD:refresh()
            CyrHUD:reconfigureLabels()
        end,
    })

    panel:AddSetting({
        type = LHAS.ST_SECTION,
        label = "Display",
    })

    panel:AddSetting({
        type = LHAS.ST_DROPDOWN,
        label = "HUD position",
        items = POSITION_ITEMS,
        default = "TOP_RIGHT",
        getFunction = function() return CyrHUD.cfg.position end,
        setFunction = function(_, _, data)
            CyrHUD.cfg.position = data.name
            CyrHUD.applyAnchorPreset()
        end,
    })
end
