-- This file is part of CyrHUD (Console port).
--
-- Original CyrHUD addon by Sasky, @aldericon, Baertram, and @Masteroshi430.
-- Console port: trims keyboard-only code paths and swaps LibAddonMenu-2 for
-- LibHarvensAddonSettings. See CyrHUDConsole.addon for the full manifest.
--
-- (C) 2016 Scott Yeskie (Sasky) and the CyrHUD authors above.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

CyrHUD = CyrHUD or {}
CyrHUD.addonVars = {}
CyrHUD.addonVars.version	= "2026.05.17"
CyrHUD.addonVars.name 		= "CyrHUD"
CyrHUD.addonVars.author 	= "Sasky, |c4779ce@aldericon|r, Baertram, |c3CB371@Masteroshi430|r — console port"
CyrHUD.addonVars.website	= "http://www.esoui.com/downloads/fileinfo.php?id=559#info"

-- Console doesn't ship the PC-only deprecation aliases for the renamed AvA
-- objective functions (see libs/esoui/esoui/ingame/addoncompatibilityaliases/
-- pc/addoncompatibilityaliases_pc.lua:273 in the API mirror), so the upstream
-- name resolves to nil on console and crashes scanKeeps. Mirror the PC alias
-- here so unchanged upstream code in CyrHUD.lua / classes/Battle.lua works.
if not GetAvAObjectiveKeysByIndex and GetObjectiveIdsForIndex then
    GetAvAObjectiveKeysByIndex = GetObjectiveIdsForIndex
end
-- CyrHUD.yourKills = 0
-- CyrHUD.yourDeaths = 0



----------------------------------------------
-- Console anchor presets
----------------------------------------------
CyrHUD.ANCHOR_PRESETS = {
    TOP_RIGHT    = { self = TOPRIGHT,    anchor = TOPRIGHT,    x = -40, y =   80 },
    TOP_LEFT     = { self = TOPLEFT,     anchor = TOPLEFT,     x =  40, y =   80 },
    MIDDLE_RIGHT = { self = RIGHT,       anchor = RIGHT,       x = -40, y =    0 },
    MIDDLE_LEFT  = { self = LEFT,        anchor = LEFT,        x =  40, y =    0 },
    BOTTOM_RIGHT = { self = BOTTOMRIGHT, anchor = BOTTOMRIGHT, x = -40, y = -120 },
    BOTTOM_LEFT  = { self = BOTTOMLEFT,  anchor = BOTTOMLEFT,  x =  40, y = -120 },
}

function CyrHUD.applyAnchorPreset()
    if not CyrHUD.ui then return end
    local key = CyrHUD.cfg and CyrHUD.cfg.position or "TOP_RIGHT"
    local preset = CyrHUD.ANCHOR_PRESETS[key] or CyrHUD.ANCHOR_PRESETS.TOP_RIGHT
    CyrHUD.ui:ClearAnchors()
    CyrHUD.ui:SetAnchor(preset.self, GuiRoot, preset.anchor, preset.x, preset.y)
end

CyrHUD.keepsToObjectivesMap = {}

-- Fort Warden
CyrHUD.keepsToObjectivesMap[3] = {lower = 55, upper = 56}

-- Fort Rayles
CyrHUD.keepsToObjectivesMap[4] = {lower = 76, upper = 75}

-- Fort Glademist
CyrHUD.keepsToObjectivesMap[5] = {lower = 71, upper = 70}

-- Fort Ash
CyrHUD.keepsToObjectivesMap[6] = {lower = 178, upper = 177}

-- Fort Aleswell
CyrHUD.keepsToObjectivesMap[7] = {lower = 174, upper = 173}

-- Fort Dragonclaw
CyrHUD.keepsToObjectivesMap[8] = {lower = 170, upper = 169}

-- Chalman Keep
CyrHUD.keepsToObjectivesMap[9] = {lower = 180, upper = 179}

-- Arrius Keep
CyrHUD.keepsToObjectivesMap[10] = {lower = 66, upper = 65}

-- Kingscrest Keep
CyrHUD.keepsToObjectivesMap[11] = {lower = 78, upper = 77}

-- Farragut Keep
CyrHUD.keepsToObjectivesMap[12] = {lower = 50, upper = 51}

-- Blue Road Keep
CyrHUD.keepsToObjectivesMap[13] = {lower = 175, upper = 176}

-- Drakelowe Keep
CyrHUD.keepsToObjectivesMap[14] = {lower = 172, upper = 171}

-- Castle Alessia
CyrHUD.keepsToObjectivesMap[15] = {lower = 168, upper = 167}

-- Castle Faregyl
CyrHUD.keepsToObjectivesMap[16] = {lower = 61, upper = 60}

-- Castle Roebeck
CyrHUD.keepsToObjectivesMap[17] = {lower = 166, upper = 165}

-- Castle Brindle
CyrHUD.keepsToObjectivesMap[18] = {lower = 164, upper = 163}

-- Castle Black Boot
CyrHUD.keepsToObjectivesMap[19] = {lower = 48, upper = 49}

-- Castle Bloodmayne
CyrHUD.keepsToObjectivesMap[20] = {lower = 41, upper = 40}

-- Nikel Outpost
CyrHUD.keepsToObjectivesMap[132] = {lower = 217, upper = 216}

-- Sejanus Outpost
CyrHUD.keepsToObjectivesMap[133] = {lower = 215, upper = 214}

-- Bleaker's Outpost
CyrHUD.keepsToObjectivesMap[134] = {lower = 219, upper = 218}

-- Winter's Reach Outpost
CyrHUD.keepsToObjectivesMap[163] = {lower = 432, upper = 431}

-- Carmala Outpost
CyrHUD.keepsToObjectivesMap[164] = {lower = 434, upper = 433}

-- Harlun's Outpost
CyrHUD.keepsToObjectivesMap[165] = {lower = 436, upper = 435}

-- Vlastarus
CyrHUD.keepsToObjectivesMap[149] = {merchant = 303, central = 294, outlier = 304}

-- Bruma
CyrHUD.keepsToObjectivesMap[151] = {merchant = 299, central = 296, outlier = 297}

-- Cropsford
CyrHUD.keepsToObjectivesMap[152] = {merchant = 301, central = 300, outlier = 302}

----------------------------------------------
-- Utility
----------------------------------------------

local function bl(val)
	if val == nil then return "NIL" elseif val then return "T" else return "F" end
end

local function nn(val)
    if val == nil then return "NIL" end
    return val
end

function CyrHUD.formatTime(delta, inclueSec, doAdditional)
    local sec = delta % 60
    delta = (delta - sec) / 60
    local min = delta % 60
    local out = min .. "m"

	if doAdditional == true then
		if min == 0 then
		    if sec == 0 then
			    out = '  '.."now"
			else
			    out = '  '..sec.."s"
			end
			
		elseif min > 9 then
            out = '  '..out 		
		else
		    if sec < 10 then sec = "0"..sec end
			out = '  '..min..":"..sec
		end
	end

    if inclueSec then
        out = out .. " " .. sec .. "s"
    end

    return out
end

-- function CyrHUD.dump()
    -- for keepIdCounter = 1, 165 do
		 -- for objectiveIdCounter = 1, 1000 do
			 -- local objectiveName, _, objectiveState =  GetObjectiveInfo(keepIdCounter, objectiveIdCounter, BGQUERY_LOCAL)

             -- if objectiveName and objectiveName ~= "" then
			     -- d(objectiveName.." keepid: "..keepIdCounter.." objectiveId: "..objectiveIdCounter)
			 -- end
		 -- end
	-- end 
-- end


CyrHUD.errors = {}

function CyrHUD:error(val)
    if not self.errors[val] then
        self.errors[val] = 1
        d("|cFF0000ERROR (CyrHUD): " .. val .. "\n|CCCCCCCPlease file this bug info with a screenshot at |CEEEEFFesoui.com (CyrHUD)")
    end
end

----------------------------------------------
-- Events
----------------------------------------------

function CyrHUD.eventAttackChange(_, keepID, battlegroundContext, underAttack)
    local self = CyrHUD

    --Optionally hide IC district battles
    if GetKeepType(keepID) == KEEPTYPE_IMPERIAL_CITY_DISTRICT then
        if CyrHUD.cfg.hideImpBattles then
            return
        end
    end
	
	if (GetKeepType(keepID) == KEEPTYPE_BRIDGE or GetKeepType(keepID) == KEEPTYPE_MILEGATE) and CyrHUD.cfg.hideBridgesAndMilegates then
	   return
	end

	
	-- Console port note: `gateOpen` was declared local inside the if-block below in
	-- the PC source, which left it nil at the read site below. Hoisted out so the
	-- gate/bridge/milegate impassable path actually triggers self:add(keepID).
	local gateOpen = false
	if GetKeepType(keepID) == KEEPTYPE_ARTIFACT_GATE or GetKeepType(keepID) == KEEPTYPE_BRIDGE or GetKeepType(keepID) == KEEPTYPE_MILEGATE then
		local pinType,_,_ = GetKeepPinInfo(keepID, battlegroundContext)
		if pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_ALDMERI_DOMINION or pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_DAGGERFALL_COVENANT or pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_EBONHEART_PACT then
			 gateOpen = true
		elseif pinType == MAP_PIN_TYPE_KEEP_BRIDGE_IMPASSABLE or pinType == MAP_PIN_TYPE_KEEP_MILEGATE_IMPASSABLE or pinType == MAP_PIN_TYPE_KEEP_MILEGATE_CENTER_DESTROYED then
		    gateOpen = true -- yep, it should be keepImpassable = true but the code is cleaner/has less lines like that
		end
	end


    if underAttack or gateOpen then
        self:add(keepID)
    elseif self.battles[keepID] ~= nil then
        self.battles[keepID]:update()
    end

    self.battleContext = battlegroundContext
end


function CyrHUD.SetMovingObjective(_, keepId, objectiveId, battlegroundContext, objectiveName, objectiveType, objectiveControlEvent, state, holdingAlliance, attackingAlliance, pinType)
   local self = CyrHUD

    if state == OBJECTIVE_CONTROL_STATE_FLAG_DROPPED or state == OBJECTIVE_CONTROL_STATE_FLAG_HELD or objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_SPAWNED then
        objectiveName = LocalizeString('<<1>>', objectiveName)
		
        CyrHUD.MovingObjective[objectiveId] = CyrHUD.MovingObjective[objectiveId] or {}
		CyrHUD.MovingObjective[objectiveId].startMovingObjective = CyrHUD.MovingObjective[objectiveId].startMovingObjective or GetTimeStamp()
		CyrHUD.MovingObjective[objectiveId].endMovingObjective = nil
		local _, holderName = GetCarryableObjectiveHoldingCharacterInfo(keepId, objectiveId, battlegroundContext)
		CyrHUD.MovingObjective[objectiveId].holder = holderName
        CyrHUD.MovingObjective[objectiveId].name = objectiveName
		CyrHUD.MovingObjective[objectiveId].objectiveId = objectiveId 
		CyrHUD.MovingObjective[objectiveId].keepId = keepId
		CyrHUD.MovingObjective[objectiveId].objectiveType = objectiveType
		CyrHUD.MovingObjective[objectiveId].objectiveControlEvent = objectiveControlEvent
		CyrHUD.MovingObjective[objectiveId].holdingAlliance = holdingAlliance
		CyrHUD.MovingObjective[objectiveId].color = CyrHUD.info[holdingAlliance].color:UnpackRGBA()
		CyrHUD.MovingObjective[objectiveId].texture = ZO_MapPin.PIN_DATA[pinType].texture
		CyrHUD.MovingObjective[objectiveId].type = "MovingObjective"


	   if self.MovingObjectives[objectiveId] ~= nil then
	       CyrHUD.MovingObjectives[objectiveId]:update()
	   else
	       self:addObj(objectiveId)
	   end

   else
       -- remove the objective if not held or dropped
	   if CyrHUD.MovingObjectives[objectiveId] then CyrHUD.MovingObjectives[objectiveId] = nil end 
   end


   self.battleContext = battlegroundContext 
end

local g_pvpKillFeedDeathRecurrenceTracker = nil
do
    -- The PvP Kill Feed uses ZO_RecurrenceTracker to track whether any given
    -- killer/victim message has been shown within the last 10 seconds from a
    -- given source (local vs. kill location). Note that the instance count
    -- tracked by ZO_RecurrenceTracker is irrelevant here for the purpose of
    -- the kill feed.
    local EXPIRATION_MS = 10000 -- 10 seconds
    local EXTENSION_MS = 10000 -- 10 seconds
    g_pvpKillFeedDeathRecurrenceTracker = ZO_RecurrenceTracker:New(EXPIRATION_MS, EXTENSION_MS)
end

function CyrHUD.playerKilled(_, killLocation, killerPlayerDisplayName, killerPlayerCharacterName, killerPlayerAlliance, killerPlayerRank, victimPlayerDisplayName, victimPlayerCharacterName, victimPlayerAlliance, victimPlayerRank)
    local self = CyrHUD
	
	killLocation = LocalizeString('<<1>>', killLocation)
	
	-- clean previous data if no deaths in the place during the last 6 mn
	if CyrHUD.Graveyard and CyrHUD.Graveyard[killLocation] and GetDiffBetweenTimeStamps(GetTimeStamp(), CyrHUD.Graveyard[killLocation].lastUpdate) > 360 then
        CyrHUD.Graveyard[killLocation] = nil
    end	

	
	-- ZOS' spam filter
	local messageKeySuffix = string.format("%s___%s", killerPlayerDisplayName, victimPlayerDisplayName)
	local messageKeyLocal = "L" .. messageKeySuffix
	local messageKeyKillLocation = "B" .. messageKeySuffix
	if isKillLocation then
		-- This message was kill location sourced.
		if g_pvpKillFeedDeathRecurrenceTracker:RemoveValue(messageKeyLocal) ~= nil then
			-- The same message was already shown as a result of a local message;
			-- remove the original message from the tracker and suppress this message.
			return
		end
		-- Track this kill location sourced message.
		g_pvpKillFeedDeathRecurrenceTracker:AddValue(messageKeyKillLocation)
	else
		-- This message was locally sourced.
		if g_pvpKillFeedDeathRecurrenceTracker:RemoveValue(messageKeyKillLocation) ~= nil then
			-- The same message was already shown as a result of a kill location message;
			-- remove the original message from the tracker and suppress this message.
			return
		end
		-- Track this locally sourced message.
		g_pvpKillFeedDeathRecurrenceTracker:AddValue(messageKeyLocal)
	end

	
	-- populate your kills and deaths
	-- local yourDisplayName = GetDisplayName()
	-- if killerPlayerDisplayName == yourDisplayName then
	       -- CyrHUD.yourKills = CyrHUD.yourKills + 1
	-- elseif victimPlayerDisplayName == yourDisplayName then
	       -- CyrHUD.yourDeaths = CyrHUD.yourDeaths + 1
	-- end
	
	-- We terminate previous graveyards in case there is a new one when there is more than 10 entries to avoid too much infos 
	if not self.Graveyards[killLocation] and CyrHUD.entryCount > 10 then
	   for k, _ in pairs(self.Graveyards) do
           self.Graveyards[k].endGraveyard = GetTimeStamp()
		   CyrHUD.Graveyards[k] = nil
       end
	end
	
	CyrHUD.Graveyard = CyrHUD.Graveyard or {}
	CyrHUD.Graveyard[killLocation] = CyrHUD.Graveyard[killLocation] or {}
    CyrHUD.Graveyard[killLocation].startGraveyard = CyrHUD.Graveyard[killLocation].startGraveyard or GetTimeStamp()
	CyrHUD.Graveyard[killLocation].name = killLocation
	CyrHUD.Graveyard[killLocation].endGraveyard = nil
	CyrHUD.Graveyard[killLocation].lastUpdate = GetTimeStamp()
	CyrHUD.Graveyard[killLocation].type = "Graveyard"
	
	-- avoid nil values
	CyrHUD.Graveyard[killLocation].allianceKills = CyrHUD.Graveyard[killLocation].allianceKills or {}
	CyrHUD.Graveyard[killLocation].allianceKills[1] = CyrHUD.Graveyard[killLocation].allianceKills[1] or 0
	CyrHUD.Graveyard[killLocation].allianceKills[2] = CyrHUD.Graveyard[killLocation].allianceKills[2] or 0
	CyrHUD.Graveyard[killLocation].allianceKills[3] = CyrHUD.Graveyard[killLocation].allianceKills[3] or 0
	CyrHUD.Graveyard[killLocation].allianceDeaths = CyrHUD.Graveyard[killLocation].allianceDeaths or {}
	CyrHUD.Graveyard[killLocation].allianceDeaths[1] = CyrHUD.Graveyard[killLocation].allianceDeaths[1] or 0
	CyrHUD.Graveyard[killLocation].allianceDeaths[2] = CyrHUD.Graveyard[killLocation].allianceDeaths[2] or 0
	CyrHUD.Graveyard[killLocation].allianceDeaths[3] = CyrHUD.Graveyard[killLocation].allianceDeaths[3] or 0
	
	-- increment the location's alliance counters for kills & deaths
	CyrHUD.Graveyard[killLocation].allianceKills[killerPlayerAlliance] = CyrHUD.Graveyard[killLocation].allianceKills[killerPlayerAlliance] + 1
	CyrHUD.Graveyard[killLocation].allianceDeaths[victimPlayerAlliance] = CyrHUD.Graveyard[killLocation].allianceDeaths[victimPlayerAlliance] + 1
	
	-- calculate if we are in the winning alliance
	local ADscore = CyrHUD.Graveyard[killLocation].allianceKills[1] - CyrHUD.Graveyard[killLocation].allianceDeaths[1]
	local DCscore = CyrHUD.Graveyard[killLocation].allianceKills[3] - CyrHUD.Graveyard[killLocation].allianceDeaths[3]
	local EPscore = CyrHUD.Graveyard[killLocation].allianceKills[2] - CyrHUD.Graveyard[killLocation].allianceDeaths[2]
	
	--d("ADscore: "..ADscore.." EPscore: "..EPscore.." DCscore: "..DCscore)

	if ADscore >= DCscore and ADscore >= EPscore then
	       CyrHUD.Graveyard[killLocation].winningAlliance = 1
	elseif DCscore >= ADscore and DCscore >= EPscore then
	       CyrHUD.Graveyard[killLocation].winningAlliance = 3
	elseif EPscore >= ADscore and EPscore >= DCscore then  
	       CyrHUD.Graveyard[killLocation].winningAlliance = 2
	else
	       CyrHUD.Graveyard[killLocation].winningAlliance = 0
	end
	
	
	-- the data is entered but has it enough deaths (10) to be displayed? 
	if CyrHUD.Graveyard[killLocation].allianceDeaths[1] + CyrHUD.Graveyard[killLocation].allianceDeaths[2] + CyrHUD.Graveyard[killLocation].allianceDeaths[3] < 10 then
	   return
	end
	
	
	-- choose the right texture 
	local ADinvolved = (CyrHUD.Graveyard[killLocation].allianceKills[1] + CyrHUD.Graveyard[killLocation].allianceDeaths[1]) > 0 
	local DCinvolved = (CyrHUD.Graveyard[killLocation].allianceKills[3] + CyrHUD.Graveyard[killLocation].allianceDeaths[3]) > 0
	local EPinvolved = (CyrHUD.Graveyard[killLocation].allianceKills[2] + CyrHUD.Graveyard[killLocation].allianceDeaths[2]) > 0
	
	if ADinvolved and DCinvolved and EPinvolved then
	      CyrHUD.Graveyard[killLocation].texture = "EsoUI/Art/MapPins/AvA_3Way.dds"
	elseif ADinvolved and DCinvolved then
	       CyrHUD.Graveyard[killLocation].texture = "EsoUI/Art/MapPins/AvA_AldmeriVDaggerfall.dds"
	elseif ADinvolved and EPinvolved then
	       CyrHUD.Graveyard[killLocation].texture = "EsoUI/Art/MapPins/AvA_AldmeriVEbonheart.dds"
	elseif DCinvolved and EPinvolved then
	       CyrHUD.Graveyard[killLocation].texture = "EsoUI/Art/MapPins/AvA_EbonheartVDaggerfall.dds"
	else
	       CyrHUD.Graveyard[killLocation].texture = "/esoui/art/treeicons/gamepad/gp_tutorial_idexicon_death.dds"
	end
	
	if self.Graveyards[killLocation] ~= nil then
	    CyrHUD.Graveyards[killLocation]:update()
	else
	    self:addGraveyard(killLocation)
	end

end


function CyrHUD.onMonsterDeath(_, unitTag, isDead)
    if GetCurrentMapId() ~= 660 then return end -- only in imperial city upper district
	-- mapid 785 is Barathrum Centrata (Molag Bal) 
    local self = CyrHUD	
	local monsterName = GetUnitName(unitTag)
	local isDeadly = GetUnitDifficulty(unitTag) == MONSTER_DIFFICULTY_DEADLY
	
	if monsterName == nil or monsterName == "" or not isDeadly then return end -- Abort if unit is not part of Patrolling Horrors

	if isDead == true then -- Imperial City Boss just died
	     
		local currentAreaName = string.gsub(GetPlayerLocationName(), "(%w+)[%^]+.*", "%1") 
		if not currentAreaName then return end
		local areaBossName = currentAreaName.." "..GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES501)
		
		if self.PatrollingHorrors[areaBossName] ~= nil then
			CyrHUD.PatrollingHorrors[areaBossName]:restart()
		else
			self:addPatrollingHorror(areaBossName)
		end

	end
end

function CyrHUD.onMonsterReticle(_)
    if GetCurrentMapId() ~= 660 then return end -- only in imperial city upper district
    local self = CyrHUD
	local unitName = GetUnitNameHighlightedByReticle()
    local isDeadly = GetUnitDifficulty('reticleover') == MONSTER_DIFFICULTY_DEADLY
		
	if unitName == nil or unitName == "" or not isDeadly then return end -- Abort if unit is not part of Patrolling Horrors
	
	local isDead = IsUnitDead('reticleover')
    local currentAreaName = string.gsub(GetPlayerLocationName(), "(%w+)[%^]+.*", "%1")
	if not currentAreaName then return end
	local areaBossName = currentAreaName.." "..GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES501) 
	
	if isDead == true then -- Imperial City Boss is dead on the floor 
		if self.PatrollingHorrors[areaBossName] then
			if self.PatrollingHorrors[areaBossName].lastSeenAlive and GetDiffBetweenTimeStamps( GetTimeStamp(), self.PatrollingHorrors[areaBossName].lastSeenAlive) < 5 then -- died before your eyes
			       self.PatrollingHorrors[areaBossName].lastSeenAlive = nil
                   CyrHUD.PatrollingHorrors[areaBossName]:restart()  			
			elseif self.PatrollingHorrors[areaBossName]:getRawDuration() > 960 then -- Already dead before you arrive, we end the notification
				self.PatrollingHorrors[areaBossName].endPatrollingHorror = GetTimeStamp()
			end
        end

	else -- Imperial City Boss is facing you alive  
	    if self.PatrollingHorrors[areaBossName] == nil then -- no notification yet 
            self:engagePatrollingHorror(areaBossName)  
        elseif (900 - self.PatrollingHorrors[areaBossName]:getRawDuration()) > 0 then -- adjust time
		     self.PatrollingHorrors[areaBossName].startPatrollingHorror = GetTimeStamp() - 900
		else
             self.PatrollingHorrors[areaBossName].lastSeenAlive = GetTimeStamp()		
		end	
         		
	end
end




function CyrHUD.actionLayerChange(_, _, activeLayerIndex)
    CyrHUD_UI:SetHidden(activeLayerIndex > 2)
end

----------------------------------------------
-- Notification UI pool
----------------------------------------------

CyrHUD.entryCount = 0
CyrHUD.entries = {}

function CyrHUD:reconfigureLabels()
    for _,entry in pairs(self.entries) do
        --Forces reconfigure on next update
        entry.type = nil
    end
end

function CyrHUD:hideRow(index)
    if self.entries[index] then
        self.entries[index].main:SetHidden(true)
    end
end

function CyrHUD:getUIRow(index)
    if #self.entries < index then
        table.insert(self.entries, self.Label())
        index = #self.entries
    end

    self.entries[index].main:SetHidden(false)

    return self.entries[index]
end

function CyrHUD:printAll()
	local i = 1

    for _,status in ipairs(self.statusBars) do
        self:getUIRow(i):update(status)
        i = i + 1
    end
    
    
    CyrHUD.rowDisplayedCount = CyrHUD.rowDisplayedCount or 0 
    local rowDislpayedCount = 0
    -- we reorder by priority: keeps, outposts, towns and then the rest

    for _,battle in pairs(self.battles) do
        if battle.keepType == KEEPTYPE_ARTIFACT_GATE then
          self:getUIRow(i):update(battle)
          i = i + 1
          rowDislpayedCount = rowDislpayedCount +1
        end
    end
    
    for _,battle in pairs(self.battles) do
        if battle.keepType == KEEPTYPE_KEEP then
          self:getUIRow(i):update(battle)
          i = i + 1
          rowDislpayedCount = rowDislpayedCount +1
        end
    end
    
    for _,battle in pairs(self.battles) do
        if battle.keepType == KEEPTYPE_OUTPOST then
          self:getUIRow(i):update(battle)
          i = i + 1
          rowDislpayedCount = rowDislpayedCount +1
        end
    end
    
    for _,battle in pairs(self.battles) do
        if battle.keepType == KEEPTYPE_TOWN then
          self:getUIRow(i):update(battle)
          i = i + 1
          rowDislpayedCount = rowDislpayedCount +1
        end
    end
    
    local thrashKeepCount = 0
    for _,battle in pairs(self.battles) do
        if battle.keepType ~= KEEPTYPE_TOWN and battle.keepType ~= KEEPTYPE_OUTPOST and battle.keepType ~= KEEPTYPE_KEEP and battle.keepType ~= KEEPTYPE_ARTIFACT_GATE and CyrHUD.rowDisplayedCount + thrashKeepCount < 11 then
          self:getUIRow(i):update(battle)
          i = i + 1
          thrashKeepCount = thrashKeepCount +1
        end
    end
    
    ----------------------------------------
	
	for _,MovingObjective in pairs(self.MovingObjectives) do
        self:getUIRow(i):update(MovingObjective)
        i = i + 1
        rowDislpayedCount = rowDislpayedCount +1
    end
	
	for _,Graveyard in pairs(self.Graveyards) do
        self:getUIRow(i):update(Graveyard)
        i = i + 1
        rowDislpayedCount = rowDislpayedCount +1
    end
	
	for _,PatrollingHorror in pairs(self.PatrollingHorrors) do
        self:getUIRow(i):update(PatrollingHorror)
        i = i + 1
        rowDislpayedCount = rowDislpayedCount +1
    end

    --Fix since auto-resize doesn't seem to work well
    self.ui:SetHeight(math.max(i*42,70))
	
	CyrHUD.entryCount = i-2
  CyrHUD.rowDisplayedCount = rowDislpayedCount


    for j=i,#self.entries do
        self:hideRow(j)
    end

end

----------------------------------------------
-- Battle management
----------------------------------------------

CyrHUD.battles = {}
CyrHUD.MovingObjectives = {}
CyrHUD.Graveyards = {} 
CyrHUD.PatrollingHorrors = {} 

function CyrHUD:add(keepID)
    if self.battles[keepID] == nil then
        self.battles[keepID] = self.Battle(keepID)
    else
        self.battles[keepID]:restart()
    end
end

function CyrHUD:checkAdd(keepID, fromFlag)
    if self.battles[keepID] == nil then
        local battle = self.Battle(keepID)

      if battle:isBattle() or fromFlag then 
              self.battles[keepID] = battle
        if fromFlag then
            self.battles[keepID].flagUAsince = GetTimeStamp()
        end
        
      end
    elseif self.battles[keepID]:isBattle() or fromFlag then
        self.battles[keepID]:restart()
		if fromFlag then
			self.battles[keepID].flagUAsince = GetTimeStamp()
		end
    end
end

function CyrHUD:scanKeeps()

    if IsInImperialCity() then
	    -- Districts
		self:checkAdd(141)
		self:checkAdd(142)
		self:checkAdd(143)
		self:checkAdd(146)
		self:checkAdd(147)
		self:checkAdd(148)

	elseif IsInCyrodiil() then
	    -- Keeps / Resources
		for i=3,87 do
			self:checkAdd(i)
		end

		-- Outposts
		for i=132,134 do
			self:checkAdd(i)
		end
        
		-- Outposts
		for i=163,165 do
			self:checkAdd(i)
		end

		-- Towns
		self:checkAdd(149)
		self:checkAdd(151)
		self:checkAdd(152)

        if not CyrHUD.cfg.hideBridgesAndMilegates then
			-- Bridges / Milegates
			for i=154,162 do 
				self:checkAdd(i)
			end
		end
		
		-- Scroll temple Gates
		for i=124,129 do 
			self:checkAdd(i)
		end	
		
		-- Border Keeps: 105 to 110
		
		-- Scroll temples: 118 to 123
		   -- 118 altadoon 124 it's gate
		   -- 119 mnem     125 it's gate
		   -- 120 ghartok  126 it's gate
		   -- 121 chim     127 it's gate
		   -- 122 ni mohk  128 it's gate
		   -- 123 alma ruma 129 it's gate

		
		-- held Volendrung & Scrolls
		for i = 1, GetNumObjectives() do
		   local okeepId, objectiveId, obgContext = GetAvAObjectiveKeysByIndex(i)
	        if(IsLocalBattlegroundContext(obgContext)) then
			    local objectiveName, objectiveType, objectiveState = GetObjectiveInfo(okeepId, objectiveId, obgContext)
			   if objectiveType == OBJECTIVE_ARTIFACT_DEFENSIVE or objectiveType == OBJECTIVE_ARTIFACT_OFFENSIVE or objectiveType == OBJECTIVE_DAEDRIC_WEAPON then
			      local objectiveControlEvent = GetLastObjectiveControlEvent(okeepId, objectiveId, obgContext)
			      if objectiveState == OBJECTIVE_CONTROL_STATE_FLAG_DROPPED or objectiveState == OBJECTIVE_CONTROL_STATE_FLAG_HELD or objectiveControlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_SPAWNED then
			         local holdingAlliance, lastHoldingAlliance = GetCarryableObjectiveHoldingAllianceInfo(okeepId, objectiveId, obgContext)
				     local pinType = GetObjectivePinInfo(okeepId, objectiveId, obgContext) 
			         CyrHUD.SetMovingObjective(nil, okeepId, objectiveId, obgContext, objectiveName, objectiveType, objectiveControlEvent, objectiveState, holdingAlliance, lastHoldingAlliance, pinType)
			       
			      end 
			   end
		    end 
        end		

	end
end

----------------------------------------------
-- held Scrolls & Volendrung management
----------------------------------------------


function CyrHUD:addObj(objectiveId)
    if self.MovingObjectives[objectiveId] == nil then
        self.MovingObjectives[objectiveId] = self.MovingObjective(objectiveId)
    else
        self.MovingObjectives[objectiveId]:restart()
    end
end

function CyrHUD:checkAddObj(objectiveId)
    if self.MovingObjectives[objectiveId] == nil then
        local MovingObjective = self.MovingObjective(objectiveId)
       
        self.MovingObjectives[objectiveId] = MovingObjective
		
    else
        self.MovingObjectives[objectiveId]:restart()
    end
end


----------------------------------------------
-- Graveyards management
----------------------------------------------


function CyrHUD:addGraveyard(killLocation)
    if self.Graveyards[killLocation] == nil then
         self.Graveyards[killLocation] = self.Graveyard(killLocation)
    else
         self.Graveyards[killLocation]:restart()
    end
end

function CyrHUD:checkAddGraveyard(killLocation)
    if self.Graveyards[killLocation] == nil then
        local Graveyard = self.Graveyard[killLocation]
       
        self.Graveyards[killLocation] = Graveyard
		
    else
        self.Graveyards[killLocation]:restart()
    end
end

----------------------------------------------
-- Patrolling Horrors management
----------------------------------------------


function CyrHUD:addPatrollingHorror(areaBossName)
    if self.PatrollingHorrors[areaBossName] == nil then
         self.PatrollingHorrors[areaBossName] = self.PatrollingHorror(areaBossName)
    else
         self.PatrollingHorror[areaBossName]:restart()
    end
end

function CyrHUD:engagePatrollingHorror(areaBossName)
    if self.PatrollingHorrors[areaBossName] == nil then
         self.PatrollingHorrors[areaBossName] = self.PatrollingHorror(areaBossName, true)
    end
end

function CyrHUD:checkAddPatrollingHorror(areaBossName)
    if self.PatrollingHorrors[areaBossName] == nil then
        local PatrollingHorror = self.PatrollingHorror[areaBossName]
       
        self.PatrollingHorrors[areaBossName] = PatrollingHorror
		
    else
        self.PatrollingHorrors[areaBossName]:restart()
    end
end

--------------------------------------------------


function CyrHUD:updateAll()
    for i,_ in pairs(self.battles) do
        --Update in-place
        self.battles[i]:update()
    end
	
	for j,_ in pairs(self.MovingObjectives) do
       self.MovingObjectives[j]:update()
    end
	
	for k, _ in pairs(self.Graveyards) do
       self.Graveyards[k]:update()
    end
	
	for k, _ in pairs(self.PatrollingHorrors) do
       self.PatrollingHorrors[k]:update()
    end

    for _,status in pairs(self.statusBars) do
        status:update()
    end

	-- to test
	if GetAssignedCampaignId() == self.campaign then
	   if #self.statusBars == 1 then
			CyrHUD:refresh()
	   end
	elseif IsInImperialCity() then
	   if #self.statusBars == 1 then
			CyrHUD:refresh()
	   end       
	else
	    if #self.statusBars == 2 then
			table.remove(self.statusBars, 2)
	   end 
	end
end



------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------

CyrHUD.visible = false

function CyrHUD:init()
    --Init UI
    self.ui:SetHidden(false)

    --Populate data
    self:refresh()

    --Add events
    EVENT_MANAGER:RegisterForUpdate(CyrHUD.addonVars.name .. "KeepCheck", 5000, function()
        self:scanKeeps()
        self:updateAll()
		
		-- -- for testing scrolls & volendrung only (generate fake ones)
		-- if not trumpet then 
		     -- CyrHUD.SetMovingObjective(_, 2000, 2000, CyrHUD.battleContext, "Volendrung", OBJECTIVE_DAEDRIC_WEAPON, 145, OBJECTIVE_CONTROL_STATE_FLAG_DROPPED, 1, 2, MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_ALDMERI)

		     -- trumpet = true
		-- else
		     -- CyrHUD.SetMovingObjective(_, 2000, 2000, CyrHUD.battleContext, "Elder Scroll of Alma Ruma", OBJECTIVE_DAEDRIC_WEAPON, 145, OBJECTIVE_CONTROL_STATE_FLAG_AT_ENEMY_BASE, 1, 2, MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_ALDMERI)
		     -- trumpet = false  
		-- end
		-- if not done then 
		-- for objectiveIdCounter = 439, 462 do
		    -- local _, x, y = GetObjectivePinInfo(nil, objectiveIdCounter, CyrHUD.battleContext)
			-- local x, y = LibGPS3:LocalToGlobal(x, y)
		    -- d("["..objectiveIdCounter.."] = {[1] = "..x..",[2] = "..y..",},")
		-- end
		-- done = true
		-- end
	
		
		--for testing Graveyards only (generate fake ones)
		-- local killLocation = "verylongnamefromhell" --GetKeepName(math.random(162))
		-- if not killLocation or killLocation == "" then return end
		-- local killerPlayerAlliance = math.random(3)
		-- local victimPlayerAlliance = killerPlayerAlliance
		-- while (victimPlayerAlliance == killerPlayerAlliance) do
		       -- victimPlayerAlliance = math.random(3)
		-- end
		-- if not saxophone then 
		
		     -- CyrHUD.playerKilled(_, killLocation, "", "", killerPlayerAlliance, "", "", "", victimPlayerAlliance, "") 
		     -- saxophone = true
		-- else
		     -- CyrHUD.playerKilled(_, killLocation, "", "", killerPlayerAlliance, "", "", "", victimPlayerAlliance, "") 
		     -- saxophone = false  
		-- end
		
		
		
		--for testing Patrolling Horrors only (generate fake ones)
		-- if not piano then 
		     -- local self = CyrHUD	
			 -- local currentAreaName = string.gsub(GetPlayerLocationName(), "(%w+)[%^]+.*", "%1")
			 -- if not currentAreaName then return end
			 -- local areaBossName = currentAreaName.." "..GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES501)
			
			 -- if self.PatrollingHorrors[areaBossName] ~= nil then
			 
				-- CyrHUD.PatrollingHorrors[areaBossName]:restart()
			 -- else
			  	-- self:addPatrollingHorror(areaBossName)
			 -- end
		     -- piano = true
		-- else
		     -- local self = CyrHUD
                -- local currentAreaName = string.gsub(GetPlayerLocationName(), "(%w+)[%^]+.*", "%1")
				-- if not currentAreaName then return end
				-- local areaBossName = currentAreaName.." "..GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES501)
				
				-- if self.PatrollingHorrors[areaBossName] and self.PatrollingHorrors[areaBossName]:getRawDuration() >= 60 then -- Already dead before you arrive, we end the notification
					-- self.PatrollingHorrors[areaBossName].endPatrollingHorror = GetTimeStamp()
				-- end
		     -- piano = false  
		-- end
		
		
    end)

    EVENT_MANAGER:RegisterForUpdate(CyrHUD.addonVars.name .. "UIUpdate", 1000, function()
        self:printAll()
    end)

    EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."AttackChange", EVENT_KEEP_UNDER_ATTACK_CHANGED, self.eventAttackChange)
	EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."ObjectiveControlState", EVENT_OBJECTIVE_CONTROL_STATE, self.SetFlagStateData)
	EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."ArtifactControlState", EVENT_ARTIFACT_CONTROL_STATE, self.SetArtifactStateData)
	EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."ArtifactControlStatePreSet", EVENT_DAEDRIC_ARTIFACT_OBJECTIVE_STATE_CHANGED, self.PreSetArtifactStateData) 
	EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."ArtifactControlSpawned", EVENT_DAEDRIC_ARTIFACT_OBJECTIVE_SPAWNED_BUT_NOT_REVEALED, self.ArtifactSpawned)
	EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."GateChange", EVENT_KEEP_GATE_STATE_CHANGED, function(_, keepID, open) self.eventAttackChange(_, keepID, CyrHUD.battleContext)  end)
    EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."PassableChange", EVENT_KEEP_IS_PASSABLE_CHANGED, function(_, keepId, battlegroundContext, isPassable) self.eventAttackChange(_, keepID, CyrHUD.battleContext) end)
	EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."KillFeed", EVENT_PVP_KILL_FEED_DEATH, function(_, killLocation, killerPlayerCharacterName, killerPlayerDisplayName, killerPlayerAlliance, killerPlayerRank, victimPlayerCharacterName, victimPlayerDisplayName, victimPlayerAlliance, victimPlayerRank)  CyrHUD.playerKilled(_, killLocation, killerPlayerCharacterName, killerPlayerDisplayName, killerPlayerAlliance, killerPlayerRank, victimPlayerCharacterName, victimPlayerDisplayName, victimPlayerAlliance, victimPlayerRank) end)
	EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name.."CampaignDataReceived",EVENT_CAMPAIGN_LEADERBOARD_DATA_RECEIVED, function() CyrHUD.CampaignDataPending = false end)


    self.visible = true

    EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name, EVENT_ACTION_LAYER_POPPED, self.actionLayerChange)
    EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name, EVENT_ACTION_LAYER_PUSHED, self.actionLayerChange)
end

function CyrHUD:refresh()
    --Get initial scan
    self.battles = {}
	self.MovingObjectives = {}
	self.Graveyards = {}
	self.PatrollingHorrors  = {}
    self.battleContext = BGQUERY_LOCAL
	
	if self.campaign ~= GetCurrentCampaignId() then
	    CyrHUD.imperialKeeps = nil -- reset imperial keeps/ Imperial City Districts
		
		if IsInImperialCity() and not CyrHUD.cfg.hidePatrollingHorrors then -- reset Imperial City Boss timers & manage corresponding events
		    EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name, EVENT_UNIT_DEATH_STATE_CHANGED, self.onMonsterDeath)
			EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name, EVENT_RETICLE_TARGET_CHANGED, self.onMonsterReticle) 
		else
		    EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name, EVENT_UNIT_DEATH_STATE_CHANGED)
		    EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name, EVENT_RETICLE_TARGET_CHANGED)
		end
		--CyrHUD.yourKills = 0
        --CyrHUD.yourDeaths = 0
		self.ImperialCityBossTimers = {}
		self.ArtifactHolders = {}
	end
	
    self.campaign = GetCurrentCampaignId()

    --Could separate this with a data refresh eventually, but just do a hard reset for now
    self.statusBars = {}
    table.insert(self.statusBars, self.ScoringBar())
	if GetAssignedCampaignId() == self.campaign or IsInImperialCity() then
	   table.insert(self.statusBars, 2, self.RankingBar())
	end
    self:scanKeeps()

    --Force update on status bar
    self:reconfigureLabels()
end


function CyrHUD:setWaypoint(x,y)
    if x ~= nil and y ~= nil then
	
	   if IsUnitGroupLeader("player") then
	       --if GetCurrentMapId() ~= 16 then SetMapToMapId(16) end
	       PingMap(MAP_PIN_TYPE_RALLY_POINT, MAP_TYPE_LOCATION_CENTERED, x, y)
		   --SetMapToPlayerLocation()
	   else
	       --if GetCurrentMapId() ~= 16 then SetMapToMapId(16) end
	       PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, x, y)
		   --SetMapToPlayerLocation()
	   end
    end	
end

function CyrHUD:deinit()
    EVENT_MANAGER:UnregisterForUpdate(CyrHUD.addonVars.name.."KeepCheck")
    EVENT_MANAGER:UnregisterForUpdate(CyrHUD.addonVars.name.."UIUpdate")
    EVENT_MANAGER:UnregisterForUpdate(CyrHUD.addonVars.name.."UpdateAPCount")
    EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name, EVENT_ACTION_LAYER_POPPED)
	
    EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name, EVENT_ACTION_LAYER_PUSHED)
    EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name.."AttackChange", EVENT_KEEP_UNDER_ATTACK_CHANGED)
    EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name.."ObjectiveControlState", EVENT_OBJECTIVE_CONTROL_STATE)
	EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name.."ArtifactControlState", EVENT_ARTIFACT_CONTROL_STATE) 
	EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name.."GateChange", EVENT_KEEP_GATE_STATE_CHANGED)
	EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name.."PassableChange", EVENT_KEEP_IS_PASSABLE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name.."KillFeed", EVENT_PVP_KILL_FEED_DEATH)
	EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name.."CampaignDataReceived",EVENT_CAMPAIGN_LEADERBOARD_DATA_RECEIVED)

    CyrHUD_UI:SetHidden(true)
    self.visible = false
end

--Called once. Handles controls, etc.
function CyrHUD.addonInit()
    local self = CyrHUD

    --Init saved variables
    local def = {
        position = "TOP_RIGHT",
        hideImpBattles = false,
        hideBridgesAndMilegates = false,
        hidePatrollingHorrors = false,
        enableInCyro = true,
        enableInIC = true,
        showPopBars = false,
    }

    self.cfg = ZO_SavedVars:NewAccountWide("CyrHUDConsole_SavedVars", 1.0, "config", def)

    --Create UI (console: no mouse, no drag)
    self.ui = WINDOW_MANAGER:CreateTopLevelWindow("CyrHUD_UI")
    self.ui:SetWidth(CyrHUD.width)
    self.ui:SetClampedToScreen(true)

    CyrHUD.applyAnchorPreset()

    --Create settings menu (console: Harvens — see settings.lua)
    if CyrHUD.registerSettings then
        CyrHUD.registerSettings()
    end
    self.initLAM = true  -- name kept so playerInit() below still no-ops on re-entry
end

function CyrHUD.playerInit()
    local self = CyrHUD

    -- Safety fallback: if for some reason ADD_ON_LOADED didn't fire addonInit, do it
    -- now. Normally addonInit has already run by the time PLAYER_ACTIVATED fires.
    if not self.initLAM then
        self.addonInit()
    end

    if IsPlayerInAvAWorld() then
 		if IsInImperialCity() and not self.cfg.enableInIC then
		   self:deinit()
		   return
		elseif not IsInImperialCity() and not self.cfg.enableInCyro then
		   self:deinit()
		   return
		end

		if self.visible then
            if CyrHUD.campaignID ~= GetCurrentCampaignId() then self:refresh() end
        else
            self:init()
        end
	    CyrHUD.campaignID = GetCurrentCampaignId()
    elseif self.visible then
        self:deinit()
    end
end

------------------------------------------------------------------------
-- Event registration
------------------------------------------------------------------------
-- Pattern matches Votan's Minimap and other modern LHAS-using addons:
-- one-shot setup (savedvars, UI, settings panel) fires on EVENT_ADD_ON_LOADED;
-- per-character lifecycle fires on EVENT_PLAYER_ACTIVATED.
-- The addon's loaded name is its .addon file basename — "CyrHUDConsole" — which
-- is distinct from `CyrHUD.addonVars.name` ("CyrHUD"), the shared Lua namespace.

local ADDON_LOADED_NAME = "CyrHUDConsole"

local function OnAddonLoaded(event, name)
    if name ~= ADDON_LOADED_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(CyrHUD.addonVars.name .. "-load", EVENT_ADD_ON_LOADED)
    CyrHUD.addonInit()
end

EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name .. "-load", EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(CyrHUD.addonVars.name .. "-init", EVENT_PLAYER_ACTIVATED, CyrHUD.playerInit)
