-- This file is part of CyrHUD
--
-- (C) 2014 Scott Yeskie (Sasky)
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

local function n0(val) if val == nil then return 0 end return val end

-- Setup class
CyrHUD.Battle = {}
CyrHUD.Battle.__index = CyrHUD.Battle
CyrHUD.Battle.type = "Battle"

setmetatable(CyrHUD.Battle, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

local shortenResourceName = function(str)
    str = LocalizeString('<<1>>', str)
    return str:gsub("%^.d$", "")
        :gsub("Castle ","")
        :gsub("[fF]ort ","")
        :gsub("Keep ","")
        :gsub("Lumber ","")
    --DE
        :gsub("Burg ","")
        :gsub("Feste ","")
        :gsub("Kastells ","")
        :gsub("Holzfällerlager ","")
        :gsub("Bauernhof ","")
        :gsub("Mine ","")
        :gsub("des ","")
        :gsub("der ","")
end

local shortenKeepName = function(str)
    str = LocalizeString('<<1>>', str) 
    return str:gsub(",..$", ""):gsub("%^.d$", "")
		:gsub("District", "")
		:gsub("Scroll Temple of ", "")
	--FR
        :gsub("avant.poste d[eu] ", "")
        :gsub("bastille d[eu]s? ", "")
        :gsub("fort de la ", "")
    --DE
        :gsub("Kastell ", "")
        :gsub("Burg ", "")
        :gsub("Feste ", "")
        :gsub("Schriftentempel von ", "Tempel ")
        :gsub("-Schriftrolle ", "-Rolle")
        :gsub(" Jagdgründe", "")
        :gsub("Carmala-Außenposten'", "Carmala")
        :gsub("Nikels Außenposten", "Nikels")
        :gsub("Sejanus' Außenposten", "Sejanus")
        :gsub("Harluns Außenposten", "Harluns")
        :gsub("Winterweite-Außenposten", "Winterweite")
        :gsub("die ","")
        :gsub("das ","")
end

----------------------------------------------
-- Creation
----------------------------------------------

CyrHUD.Battle.new = function(keepID)
    local self = setmetatable({}, CyrHUD.Battle)

    self.startBattle = self.startBattle or GetTimeStamp()
    self.endBattle = nil
    self.keepID = keepID
    self.keepName = shortenKeepName(GetKeepName(keepID))
    self.keepType = GetKeepType(keepID)

    if self.keepType == KEEPTYPE_RESOURCE then
        self.keepType = 10 + GetKeepResourceType(keepID)
        self.keepName = shortenResourceName(self.keepName)
    end
	
	local pinType, nX, nY = GetKeepPinInfo(self.keepID, CyrHUD.battleContext)
	self.nX = nX
	self.nY = nY
	
	
	if self.keepType == KEEPTYPE_ARTIFACT_GATE or self.keepType == KEEPTYPE_BRIDGE or self.keepType == KEEPTYPE_MILEGATE then

		local gateOpen = false
		if pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_ALDMERI_DOMINION or pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_DAGGERFALL_COVENANT or pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_EBONHEART_PACT then
			gateOpen = true
		elseif pinType == MAP_PIN_TYPE_KEEP_BRIDGE_IMPASSABLE or pinType == MAP_PIN_TYPE_KEEP_MILEGATE_IMPASSABLE or pinType == MAP_PIN_TYPE_KEEP_MILEGATE_CENTER_DESTROYED then
		    gateOpen = true -- yep, it should be keepImpassable = true but the code is cleaner/has less lines like that   
		end
		self.gateOpen = gateOpen
		
		if self.keepType == KEEPTYPE_ARTIFACT_GATE then -- only display scroll gates if there is a scroll in the temple
			local gateTemple = self.keepID - 6
		    local scrollObjectiveId = GetKeepArtifactObjectiveId(gateTemple)
			local scrolIsAtBase = GetObjectiveControlState(gateTemple, scrollObjectiveId, CyrHUD.battleContext) == OBJECTIVE_CONTROL_STATE_FLAG_AT_BASE
			if scrolIsAtBase then
			     self.gateTempleHasScroll = true
			else
			     self.gateTempleHasScroll = false
			end
		end
	end
	
	
	

	self.cyroChatIcon = nil
    self.siege = {}

    self:update()

    return self
end

----------------------------------------------
-- Label update
----------------------------------------------

--Label fields
local L_ICON, L_UA = "img1", "img2"
local CYROCHAT_ICON = 'img4'
local L_NAME, L_ATT_SIEGE, L_DEF_SIEGE, L_TIME = "txt1", "txt2", "txt3", "txt4"
local L_LUMB, L_MINE, L_FARM = "img5", "img6", "img7"
local L_SCROLL = "img8"
local L_ICON_DEATHS_AD, L_ICON_DEATHS_EP, L_ICON_DEATHS_DC = "img12", "img13", "img14"
local L_DEATHS_AD, L_DEATHS_EP, L_DEATHS_DC = "txt11", "txt12", "txt13"
local L_KILLS_AD, L_KILLS_EP, L_KILLS_DC = "txt23", "txt24", "txt25"
local LEGEND_KILLS, LEGEND_DEATHS = "txt26", "txt27"
local L_ATT_SIEGE_ICON, L_DEF_SIEGE_ICON = "img15", "img16"
local L_CONNECTED = "img17"
local L_ARROW = "img18"
local L_HOLDER = "txt16"

local ICON_EMPEROR = "img25"
local TEXT_PLAYERNAME = "txt17"
local TEXT_RIVALNAME = "txt18"
local TEXT_PLAYERRANK = "txt19"
local TEXT_RIVALRANK = "txt20"
local TEXT_PLAYERSCORE = "txt21"
local TEXT_RIVALSCORE = "txt22"

local ICON_ASH = "img26"
local ICON_WELL = "img27"
local ICON_CHAL = "img28"
local ICON_BRK = "img29"
local ICON_SIA = "img30"
local ICON_ROE = "img31"


function CyrHUD.Battle:configureLabel(label)
    label:exposeControls(2,4)
    label:positionControl(L_ICON, 40, 40, -2, -2)

	-- CyroChat Battles
	label:positionControl(CYROCHAT_ICON, 40, 40, -35, -2)

    -- Objective icon
    label:getControl(L_ICON):SetDrawLayer(2)

    -- Under attack graphic
    label:positionControl(L_UA, 40, 40, -2, -2)
    local ua = label:getControl(L_UA)
    ua:SetDrawLayer(1)
    ua:SetTexture(CyrHUD.info.underAttack)

    --Objective name
    label:positionControl(L_NAME, 180, 30, 35, 5)

	-- Animated arrow
    label:positionControl(L_ARROW, 20, 20, 35, 7)
    label:getControl(L_ARROW):SetTexture(CyrHUD.icons["arrow"])
	label:getControl(L_ARROW):SetTransformRotationZ(math.rad(180))
	label:getControl(L_ARROW):SetAlpha(0)

	--Holder name
	label:positionControl(L_HOLDER, 180, 30, 35, 20)

	
	--Keep resources around keep
	label:getControl(L_LUMB):SetDrawLayer(4)
	label:getControl(L_MINE):SetDrawLayer(4)
	label:getControl(L_FARM):SetDrawLayer(4)
	label:positionControl(L_LUMB, 20, 20, -5, -5) 
	label:positionControl(L_MINE, 20, 20, -5, 20) 
	label:positionControl(L_FARM, 20, 20, 22, 20) 
	
	-- keep is connected icon
	label:getControl(L_CONNECTED):SetDrawLayer(4)
	label:positionControl(L_CONNECTED, 40, 40, -2, -2)
	label:getControl(L_CONNECTED):SetTexture(CyrHUD.icons["ConnectedKeep"]) 
	label:getControl(L_CONNECTED):SetColor(CyrHUD.info.linkColor:UnpackRGBA())
	
	-- Scroll on objective icon
	label:getControl(L_SCROLL):SetDrawLayer(3)
	label:positionControl(L_SCROLL, 50, 50, -6, -6)

    --Defensive siege count
    label:positionControl(L_DEF_SIEGE, 30, 30, 274, 5)
	label:positionControl(L_DEF_SIEGE_ICON, 30, 30, 260, 0)
	label:getControl(L_DEF_SIEGE_ICON):SetTexture(CyrHUD.icons["defSiege"])
	label:getControl(L_DEF_SIEGE_ICON):SetColor(CyrHUD.info[4].color:UnpackRGBA())

    --Attacker siege count
    label:positionControl(L_ATT_SIEGE, 30, 30, 240, 5)
	label:positionControl(L_ATT_SIEGE_ICON, 30, 30, 230, 0)
	label:getControl(L_ATT_SIEGE_ICON):SetTexture(CyrHUD.icons["offSiege"])
	label:getControl(L_ATT_SIEGE_ICON):SetColor(CyrHUD.info[4].color:UnpackRGBA())

    --Time
    label:positionControl(L_TIME, 60, 30, 310, 5)
end

function CyrHUD.SetFlagStateData(eventCode, keepId, objectiveId, battlegroundContext, objectiveName, objectiveType, objectiveControlEvent, state, holdingAlliance, attackingAlliance, pinType)
    if objectiveType ~= OBJECTIVE_CAPTURE_AREA then
        if objectiveType == OBJECTIVE_ARTIFACT_DEFENSIVE or objectiveType == OBJECTIVE_ARTIFACT_OFFENSIVE or objectiveType == OBJECTIVE_DAEDRIC_WEAPON then	
		    CyrHUD.SetMovingObjective(eventCode, keepId, objectiveId, battlegroundContext, objectiveName, objectiveType, objectiveControlEvent, state, holdingAlliance, attackingAlliance, pinType)
		end
	    return 
	end

	CyrHUD.flags = CyrHUD.flags or {}
	CyrHUD.flags[keepId] = CyrHUD.flags[keepId] or {}
	CyrHUD.flags[keepId][objectiveId] = CyrHUD.flags[keepId][objectiveId] or {}

	-- we set everything to 0
    CyrHUD.flags[keepId][objectiveId][0] = 0
    CyrHUD.flags[keepId][objectiveId][1] = 0
    CyrHUD.flags[keepId][objectiveId][2] = 0
    CyrHUD.flags[keepId][objectiveId][3] = 0

	
	-- add 16.666% each step (100/6 for the 7 steps of an attack)
	   if state == OBJECTIVE_CONTROL_STATE_AREA_ABOVE_CONTROL_THRESHOLD then -- 6 none attacks defending alliance with positive or negative attack, second or sixth step of an attack
	      	 CyrHUD.flags[keepId][objectiveId][holdingAlliance] = 66.666 --80
		     CyrHUD.flags[keepId][objectiveId][attackingAlliance] = 33.333 --20
			 CyrHUD.flags[keepId][objectiveId].defender = holdingAlliance 
	   elseif state == OBJECTIVE_CONTROL_STATE_AREA_BELOW_CONTROL_THRESHOLD then  -- 5 attacking alliance attacks none with positive or negative attack, third or fith step of an attack
	         CyrHUD.flags[keepId][objectiveId][holdingAlliance] = 51 --40
		     CyrHUD.flags[keepId][objectiveId][attackingAlliance] = 49 --60
			 CyrHUD.flags[keepId][objectiveId].defender = holdingAlliance
	   elseif state == OBJECTIVE_CONTROL_STATE_AREA_NO_CONTROL then -- 4  none attacks none, flag is neutral, fourth step of attack 
             CyrHUD.flags[keepId][objectiveId][attackingAlliance] = 100
	   elseif state == OBJECTIVE_CONTROL_STATE_AREA_MAX_CONTROL then -- 7  none attacks defending alliance with positive or negative attack, first or seventh (last) step of an attack
	         CyrHUD.flags[keepId][objectiveId][holdingAlliance] = 83.333 --90
			 CyrHUD.flags[keepId][objectiveId][attackingAlliance] = 16.666 --10
			 CyrHUD.flags[keepId][objectiveId].defender = holdingAlliance
	   else
            return
	   end 
	   
    --d(GetKeepName(keepId).." "..GetAllianceName(attackingAlliance).." attacks "..GetAllianceName(holdingAlliance).." "..state )
	
	CyrHUD:checkAdd(keepId, true) 
end

function CyrHUD.UTF8ToCharArray(str)
     local charArray = {}
     local iStart = 0
     local strLen = str:len()

     local function bit(b)
           return 2 ^ (b - 1)
     end

     local function hasbit(w, b)
           return w % (b + b) >= b
     end

     local function checkMultiByte(i)
           if (iStart ~= 0) then
               charArray[#charArray + 1] = str:sub(iStart, i - 1)
               iStart = 0
           end
     end

     for i = 1, strLen do
         local b = str:byte(i)
         local multiStart = hasbit(b, bit(7)) and hasbit(b, bit(8))
         local multiTrail = not hasbit(b, bit(7)) and hasbit(b, bit(8))
         if (multiStart) then
            checkMultiByte(i)
            iStart = i
         elseif (not multiTrail) then
            checkMultiByte(i)
            charArray[#charArray + 1] = str:sub(i, i)
         end
     end

      -- process if last character is multi-byte 
     checkMultiByte(strLen + 1)
     return charArray
end

function CyrHUD.charArrayToString(array, limit)
    local str = ""
	local newArray = {}
	local i = 1
    for k,v in pairs(array) do
 		if i <= limit then
		    str = str..v 
        else
            table.insert(newArray, v)   		
		end   
		i = i + 1
	end
    return str, newArray	
end

function CyrHUD.SetFlagGauges(label,keep) -- set flag gauges
    local holder = label:getControl(L_HOLDER)
	local gaugeMessage = ""
    local iconsize = 14
    
    if CyrHUD.flags and CyrHUD.flags[keep.keepID] and NonContiguousCount(CyrHUD.flags[keep.keepID]) > 0 then 

       if (keep.keepType == KEEPTYPE_KEEP or keep.keepType == KEEPTYPE_OUTPOST) then
	       local lowerFlagId = CyrHUD.keepsToObjectivesMap[keep.keepID].lower
	       local upperFlagId = CyrHUD.keepsToObjectivesMap[keep.keepID].upper
		   
		   CyrHUD.flags[keep.keepID][lowerFlagId] = CyrHUD.flags[keep.keepID][lowerFlagId] or {}
		   local lowerFlagAD = CyrHUD.flags[keep.keepID][lowerFlagId][1] or 0
		   local lowerFlagEP = CyrHUD.flags[keep.keepID][lowerFlagId][2] or 0
		   local lowerFlagDC = CyrHUD.flags[keep.keepID][lowerFlagId][3] or 0
		   local lowerFlagNE = CyrHUD.flags[keep.keepID][lowerFlagId][0] or 0
		   local lowerDefender =  CyrHUD.flags[keep.keepID][lowerFlagId].defender or 0
		   if lowerDefender == 0 then lowerDefender = keep.defender end
		   
		   local maxLowerFlagValue = math.max(lowerFlagAD,lowerFlagEP,lowerFlagDC)
		   
		   local texture = CyrHUD.info["gauge"][0][0]["100"]
		   
		   if lowerFlagNE == 100 then

		   elseif maxLowerFlagValue == 0 then	
			      texture = CyrHUD.info["gauge"][lowerDefender][0]["100"] 
           elseif lowerFlagAD == maxLowerFlagValue then
		          texture = CyrHUD.info["gauge"][1][0][tostring(lowerFlagAD)] 
           elseif lowerFlagEP == maxLowerFlagValue then
		          texture = CyrHUD.info["gauge"][2][0][tostring(lowerFlagEP)]
           elseif lowerFlagDC == maxLowerFlagValue then	
		          texture = CyrHUD.info["gauge"][3][0][tostring(lowerFlagDC)]
		   end
		   
		   gaugeMessage = zo_iconTextFormatNoSpace(texture,iconsize,iconsize,"")
		   
		   CyrHUD.flags[keep.keepID][upperFlagId] = CyrHUD.flags[keep.keepID][upperFlagId] or {}
		   local upperFlagAD = CyrHUD.flags[keep.keepID][upperFlagId][1] or 0
		   local upperFlagEP = CyrHUD.flags[keep.keepID][upperFlagId][2] or 0
		   local upperFlagDC = CyrHUD.flags[keep.keepID][upperFlagId][3] or 0
		   local upperFlagNE = CyrHUD.flags[keep.keepID][upperFlagId][0] or 0
		   local upperDefender =  CyrHUD.flags[keep.keepID][upperFlagId].defender or 0
		   if upperDefender == 0 then upperDefender = keep.defender end
		   
		   local texture2 = CyrHUD.info["gauge"][0][0]["100"]
		   local maxUpperFlagValue = math.max(upperFlagAD,upperFlagEP,upperFlagDC)
		   if upperFlagNE == 100 then
		   
		   elseif maxUpperFlagValue == 0 then
                  texture2 = CyrHUD.info["gauge"][upperDefender][0]["100"] 				  
           elseif upperFlagAD == maxUpperFlagValue then	
                  texture2 = CyrHUD.info["gauge"][1][0][tostring(upperFlagAD)]				  
           elseif upperFlagEP == maxUpperFlagValue then
				  texture2 = CyrHUD.info["gauge"][2][0][tostring(upperFlagEP)]
           elseif upperFlagDC == maxUpperFlagValue then	
                  texture2 = CyrHUD.info["gauge"][3][0][tostring(upperFlagDC)]		   
		   end
		   
		   gaugeMessage = gaugeMessage.."     "..zo_iconTextFormatNoSpace(texture2,iconsize,iconsize,"")
		   
	   elseif keep.keepType == KEEPTYPE_TOWN then

       	   local merchantFlagId = CyrHUD.keepsToObjectivesMap[keep.keepID].merchant
	       local centralFlagId = CyrHUD.keepsToObjectivesMap[keep.keepID].central
		   local outlierFlagId = CyrHUD.keepsToObjectivesMap[keep.keepID].outlier
		   
		   CyrHUD.flags[keep.keepID][merchantFlagId] = CyrHUD.flags[keep.keepID][merchantFlagId] or {}
		   local merchantFlagAD = CyrHUD.flags[keep.keepID][merchantFlagId][1] or 0
		   local merchantFlagEP = CyrHUD.flags[keep.keepID][merchantFlagId][2] or 0
		   local merchantFlagDC = CyrHUD.flags[keep.keepID][merchantFlagId][3] or 0
		   local merchantFlagNE = CyrHUD.flags[keep.keepID][merchantFlagId][0] or 0
		   local merchantDefender =  CyrHUD.flags[keep.keepID][merchantFlagId].defender or 0
		   if merchantDefender == 0 then merchantDefender = keep.defender end

		   
		   local texture = CyrHUD.info["gauge"][0][0]["100"]
		   local maxMerchantFlagValue = math.max(merchantFlagAD,merchantFlagEP,merchantFlagDC)
		   if merchantFlagNE == 100 then

		   elseif maxMerchantFlagValue == 0 then	
                  texture = CyrHUD.info["gauge"][merchantDefender][0]["100"]				  
           elseif merchantFlagAD == maxMerchantFlagValue then
                  texture = CyrHUD.info["gauge"][1][0][tostring(merchantFlagAD)] 		   
           elseif merchantFlagEP == maxMerchantFlagValue then
		          texture = CyrHUD.info["gauge"][2][0][tostring(merchantFlagEP)]
           elseif merchantFlagDC == maxMerchantFlagValue then	
                  texture = CyrHUD.info["gauge"][3][0][tostring(merchantFlagDC)]		   
		   end
		   
		   gaugeMessage = zo_iconTextFormatNoSpace(texture,iconsize,iconsize,"")
		   
		   CyrHUD.flags[keep.keepID][centralFlagId] = CyrHUD.flags[keep.keepID][centralFlagId] or {}
		   local centralFlagAD = CyrHUD.flags[keep.keepID][centralFlagId][1] or 0
		   local centralFlagEP = CyrHUD.flags[keep.keepID][centralFlagId][2] or 0
		   local centralFlagDC = CyrHUD.flags[keep.keepID][centralFlagId][3] or 0
		   local centralFlagNE = CyrHUD.flags[keep.keepID][centralFlagId][0] or 0
		   local centrelDefender =  CyrHUD.flags[keep.keepID][centralFlagId].defender or 0
		   if centrelDefender == 0 then centrelDefender = keep.defender end
		   
		   local texture2 = CyrHUD.info["gauge"][0][0]["100"]
		   local maxCentralFlagValue = math.max(centralFlagAD,centralFlagEP,centralFlagDC)
		   if centralFlagNE == 100 then

		   elseif maxCentralFlagValue == 0 then	
                   texture2 = CyrHUD.info["gauge"][centrelDefender][0]["100"]				 
           elseif centralFlagAD == maxCentralFlagValue then	
		           texture2 = CyrHUD.info["gauge"][1][0][tostring(centralFlagAD)]
           elseif centralFlagEP == maxCentralFlagValue then
		           texture2 = CyrHUD.info["gauge"][2][0][tostring(centralFlagEP)]
           elseif centralFlagDC == maxCentralFlagValue then	
                   texture2 = CyrHUD.info["gauge"][3][0][tostring(centralFlagDC)]		   
		   end
		   
		   gaugeMessage = gaugeMessage.."     "..zo_iconTextFormatNoSpace(texture2,iconsize,iconsize,"")
		   
		   
		   CyrHUD.flags[keep.keepID][outlierFlagId] = CyrHUD.flags[keep.keepID][outlierFlagId] or {}
		   local outlierFlagAD = CyrHUD.flags[keep.keepID][outlierFlagId][1] or 0
		   local outlierFlagEP = CyrHUD.flags[keep.keepID][outlierFlagId][2] or 0
		   local outlierFlagDC = CyrHUD.flags[keep.keepID][outlierFlagId][3] or 0
		   local outlierFlagNE = CyrHUD.flags[keep.keepID][outlierFlagId][0] or 0
		   local outlierDefender =  CyrHUD.flags[keep.keepID][outlierFlagId].defender or 0
		   if outlierDefender == 0 then outlierDefender = keep.defender end
		   
		   local texture3 = CyrHUD.info["gauge"][0][0]["100"]
		   local maxOutlierFlagValue = math.max(outlierFlagAD,outlierFlagEP,outlierFlagDC)
		   if outlierFlagNE == 100 then

		   elseif maxOutlierFlagValue == 0 then	
                  texture3 = CyrHUD.info["gauge"][outlierDefender][0]["100"]				  
           elseif outlierFlagAD == maxOutlierFlagValue then
                  texture3 = CyrHUD.info["gauge"][1][0][tostring(outlierFlagAD)]		   
           elseif outlierFlagEP == maxOutlierFlagValue then
		          texture3 = CyrHUD.info["gauge"][2][0][tostring(outlierFlagEP)]  
           elseif outlierFlagDC == maxOutlierFlagValue then	
                  texture3 = CyrHUD.info["gauge"][3][0][tostring(outlierFlagDC)]		   
		   end
		   
		   gaugeMessage = gaugeMessage.."     "..zo_iconTextFormatNoSpace(texture3,iconsize,iconsize,"")

       elseif keep.keepType == 10 + GetKeepResourceType(keep.keepID) or keep.keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT then	 -- resources  
		   for flag, alliance in pairs(CyrHUD.flags[keep.keepID]) do -- AD1 EP2 DC3
			 local ad = alliance[1] or 0 
			 local ep = alliance[2] or 0
			 local dc = alliance[3] or 0
			 local ne = alliance[0] or 0
		     local defender =  CyrHUD.flags[keep.keepID][flag].defender or 0
			 if defender == 0 then defender = keep.defender end
			 
			   local texture = CyrHUD.info["gauge"][0][0]["100"] 
			   local maxFlagValue = math.max(ad,ep,dc)
			   if ne == 100 then

		       elseif maxFlagValue == 0 then	
                       texture = CyrHUD.info["gauge"][defender][0]["100"]					 
			   elseif ad == maxFlagValue then	
					 texture = CyrHUD.info["gauge"][1][0][tostring(ad)]
			   elseif ep == maxFlagValue then
					 texture = CyrHUD.info["gauge"][2][0][tostring(ep)]
			   elseif dc == maxFlagValue then		   
					 texture = CyrHUD.info["gauge"][3][0][tostring(dc)]
			   end
			   gaugeMessage = zo_iconTextFormatNoSpace(texture,iconsize,iconsize,"")
		   end
	   end
    end
	
	if gaugeMessage ~= "" then
	   gaugeMessage = "     "..gaugeMessage
	end

	holder:SetText(gaugeMessage)
end

function CyrHUD.SetColouredName(label,keep) -- set flag percentage coloured name
	local name = label:getControl(L_NAME)


	if CyrHUD.flags and CyrHUD.flags[keep.keepID] and NonContiguousCount(CyrHUD.flags[keep.keepID]) > 0 then 
	   local numFlags = NonContiguousCount(CyrHUD.flags[keep.keepID])
	   
	   local ADpercent = 0
	   local DCpercent = 0
	   local EPpercent = 0
	   local NEpercent = 0
	   
	   
	   for flag,alliance in pairs(CyrHUD.flags[keep.keepID]) do -- AD1 EP2 DC3
            local ad = alliance[1] or 0
			local ep = alliance[2] or 0
			local dc = alliance[3] or 0
			local ne = alliance[0] or 0
			ADpercent = ADpercent + ad
			DCpercent = DCpercent + dc
			EPpercent = EPpercent + ep
			NEpercent = NEpercent + ne
       end
	   
	 
	   if (keep.keepType == KEEPTYPE_KEEP or keep.keepType == KEEPTYPE_OUTPOST) and numFlags ~= 2 then 
	          if keep.defender == 1  then 
			     ADpercent = ADpercent + 100
              elseif keep.defender == 2  then
	             EPpercent = EPpercent + 100
			  elseif keep.defender == 3  then
			     DCpercent = DCpercent + 100
              end
              ADpercent = ADpercent/2
			  EPpercent = EPpercent/2
			  DCpercent = DCpercent/2
			  NEpercent = NEpercent/2
			  
			  
	   elseif keep.keepType == KEEPTYPE_TOWN then 	  
		      if numFlags == 1 then
				  if keep.defender == 1  then 
					 ADpercent = ADpercent + 200
				  elseif keep.defender == 2  then
					 EPpercent = EPpercent + 200
				  elseif keep.defender == 3  then
					 DCpercent = DCpercent + 200
				  end
			  
              elseif numFlags == 2 then	
				  if keep.defender == 1  then 
					 ADpercent = ADpercent + 100
				  elseif keep.defender == 2  then
					 EPpercent = EPpercent + 100
				  elseif keep.defender == 3  then
					 DCpercent = DCpercent + 100
				  end
			  end
	              ADpercent = ADpercent/3
				  EPpercent = EPpercent/3
				  DCpercent = DCpercent/3
				  NEpercent = NEpercent/3
	   end
	   
	   -- Who's attacking?
	   if keep.prevADpercent and ADpercent > keep.prevADpercent then
	       keep.attacker = 1
		   -- animate arrow
		   CyrHUD.Battle:animateArrow(label, keep, nil, nil, label.entryName)
	   elseif keep.prevDCpercent and DCpercent > keep.prevDCpercent then
	       keep.attacker = 3
		   -- animate arrow
		   CyrHUD.Battle:animateArrow(label, keep, nil, nil, label.entryName)
	   elseif keep.prevEPpercent and EPpercent > keep.prevEPpercent then
	       keep.attacker = 2
		   -- animate arrow
		   CyrHUD.Battle:animateArrow(label, keep, nil, nil, label.entryName)
	   elseif keep.prevNEpercent and NEpercent > keep.prevNEpercent then
	       keep.attacker = 0
		   -- animate arrow
		   CyrHUD.Battle:animateArrow(label, keep, nil, nil, label.entryName) 
	   elseif (keep.prevADpercent and ADpercent < keep.prevADpercent ) or (keep.prevDCpercent and DCpercent < keep.prevDCpercent) or (keep.prevEPpercent and EPpercent < keep.prevEPpercent) then
	       keep.attacker = 0
		   -- animate arrow
		   CyrHUD.Battle:animateArrow(label, keep, nil, nil, label.entryName) 
	   end

	   
	   -- populate previous stats
	   keep.prevNEpercent = NEpercent
	   keep.prevADpercent = ADpercent
	   keep.prevDCpercent = DCpercent
	   keep.prevEPpercent = EPpercent
	   
	   

	   if NEpercent == 100 or ADpercent == 100 or DCpercent == 100 or EPpercent == 100 then -- no need to calculate here
	      name:SetText(keep.keepName)
		  if NEpercent == 100 then
		      name:SetColor(CyrHUD.info[ALLIANCE_NONE].color:UnpackRGBA())
		  elseif ADpercent == 100 then
              name:SetColor(CyrHUD.info[1].color:UnpackRGBA())
		  elseif EPpercent == 100 then
              name:SetColor(CyrHUD.info[2].color:UnpackRGBA()) 
		  elseif DCpercent == 100 then
              name:SetColor(CyrHUD.info[3].color:UnpackRGBA())
		  end
	   elseif NEpercent == 0 and ADpercent == 0 and DCpercent == 0 and EPpercent == 0 then
	        name:SetColor(CyrHUD.info[keep.defender].color:UnpackRGBA())
	   else -- calculate keepname string colors
		   local keepNameArray = CyrHUD.UTF8ToCharArray(keep.keepName)
		   local rest = keepNameArray
		   
		   local colorLimitLetterAD = math.floor(ADpercent/100*#keepNameArray)
		   local ADstring = ""
		   if colorLimitLetterAD ~= 0 then
		       local allianceColor = GetAllianceColor(1)
               local ADcolor = "|c"..allianceColor:ToHex()
               local arrayTostring, newArray = CyrHUD.charArrayToString(keepNameArray,colorLimitLetterAD)			   
		       ADstring = ADcolor..arrayTostring.."|r"
			   rest = newArray
		   end
		   
		   local colorLimitLetterDC = math.floor(DCpercent/100*#keepNameArray)
		   local DCstring = ""
		   if colorLimitLetterDC ~= 0 then
		       local allianceColor = GetAllianceColor(3)
               local DCcolor = "|c"..allianceColor:ToHex()	
			   local arrayTostring, newArray = CyrHUD.charArrayToString(rest,colorLimitLetterDC)
		       DCstring = DCcolor..arrayTostring.."|r"
			   rest = newArray
		   end
	   
		   local colorLimitLetterEP = math.floor(EPpercent/100*#keepNameArray)
		   local EPstring = ""
		   if colorLimitLetterEP ~= 0 then
		       local allianceColor = GetAllianceColor(2)
               local EPcolor = "|c"..allianceColor:ToHex()
			   local arrayTostring, newArray = CyrHUD.charArrayToString(rest,colorLimitLetterEP)
		       EPstring = EPcolor..arrayTostring.."|r"
			   rest = newArray
		   end
		   
		   local restLength = math.floor(#rest)
		   if restLength ~= 0 then 
		        local neutralColor = CyrHUD.info[ALLIANCE_NONE].color
		        local restColor = "|c"..neutralColor:ToHex()
				local arrayTostring, newArray = CyrHUD.charArrayToString(rest,#rest)
		        rest = restColor..arrayTostring.."|r"
		   else
		       rest = ""
		   end
		   
		   -- colourise rest
		   local fullString = ADstring..DCstring..EPstring..rest
	       name:SetText(fullString)
	   end


	else -- no data or no data yet for flags
        name:SetText(keep.keepName)
        name:SetColor(CyrHUD.info[keep.defender].color:UnpackRGBA())
	end
       
end

function CyrHUD.Battle:updateLabel(label)

    label:getControl(L_ICON_DEATHS_AD):SetHidden(true)
	label:getControl(L_ICON_DEATHS_EP):SetHidden(true)
	label:getControl(L_ICON_DEATHS_DC):SetHidden(true)
    label:getControl(L_DEATHS_AD):SetHidden(true)
	label:getControl(L_DEATHS_EP):SetHidden(true)
	label:getControl(L_DEATHS_DC):SetHidden(true)
    label:getControl(L_KILLS_AD):SetHidden(true)
	label:getControl(L_KILLS_EP):SetHidden(true)
	label:getControl(L_KILLS_DC):SetHidden(true)
	label:getControl(LEGEND_KILLS):SetHidden(true)
	label:getControl(LEGEND_DEATHS):SetHidden(true)

	
	label:getControl(L_HOLDER):SetHidden(false)
	
	label:getControl(ICON_EMPEROR):SetHidden(true)
	label:getControl(TEXT_PLAYERNAME):SetHidden(true)
	label:getControl(TEXT_RIVALNAME):SetHidden(true)
	label:getControl(TEXT_PLAYERRANK):SetHidden(true)
	label:getControl(TEXT_RIVALRANK):SetHidden(true)
	label:getControl(TEXT_PLAYERSCORE):SetHidden(true)
	label:getControl(TEXT_RIVALSCORE):SetHidden(true)
	label:getControl(ICON_ASH):SetHidden(true)
	label:getControl(ICON_WELL):SetHidden(true)
	label:getControl(ICON_CHAL):SetHidden(true)
	label:getControl(ICON_BRK):SetHidden(true)
	label:getControl(ICON_SIA):SetHidden(true)
	label:getControl(ICON_ROE):SetHidden(true)
	
	label:getControl(L_NAME):SetHidden(false)
	label:getControl(L_ICON):SetHidden(false)
	label:getControl(L_TIME):SetHidden(false)
	
	

  --Keep icon
  label:getControl(L_ICON):SetTexture(self:getIcon())
  label:getControl(L_UA):SetHidden(not self.keepUA)

	-- CyroChat Battles
	label:getControl(CYROCHAT_ICON):SetTexture(self.cyroChatIcon)

	if self.cyroChatIcon ~= nil then
		label:getControl(CYROCHAT_ICON):SetHidden(false)
	else
		label:getControl(CYROCHAT_ICON):SetHidden(true)
	end

    --Keep name
	  CyrHUD.SetColouredName(label,self)
	  
    --flag gauges
      CyrHUD.SetFlagGauges(label,self)	
	
	--Keep resources around icon 
	if GetKeepType(self.keepID) == KEEPTYPE_KEEP then -- check resources 
	  local lumbermillID = GetResourceKeepForKeep(self.keepID, RESOURCETYPE_WOOD)
		local mineID = GetResourceKeepForKeep(self.keepID, RESOURCETYPE_ORE)
		local farmID = GetResourceKeepForKeep(self.keepID, RESOURCETYPE_FOOD)
		
		if lumbermillID > 0 then
		   local lumbermill = label:getControl(L_LUMB)
		   local color = GetAllianceColor(GetKeepAlliance(lumbermillID, CyrHUD.battleContext))
		   lumbermill:SetTexture(CyrHUD.icons[10 + RESOURCETYPE_WOOD]) 
		   lumbermill:SetColor(color:UnpackRGBA())
		   lumbermill:SetHidden(false)
		else
		   label:getControl(L_LUMB):SetHidden(true)
		end 
		
		if mineID > 0 then
		   local mine = label:getControl(L_MINE)
		   local color = GetAllianceColor(GetKeepAlliance(mineID, CyrHUD.battleContext))
		   mine:SetTexture(CyrHUD.icons[10 + RESOURCETYPE_ORE])
		   mine:SetColor(color:UnpackRGBA())
		   mine:SetHidden(false)
		else
		   label:getControl(L_MINE):SetHidden(true)
		end
		
		if farmID > 0 then
		   local farm = label:getControl(L_FARM)
		   local color = GetAllianceColor(GetKeepAlliance(farmID, CyrHUD.battleContext))
		   farm:SetTexture(CyrHUD.icons[10 + RESOURCETYPE_FOOD])
		   farm:SetColor(color:UnpackRGBA())
		   farm:SetHidden(false)
		else
		   label:getControl(L_FARM):SetHidden(true)
		end
	else
	    label:getControl(L_FARM):SetHidden(true)
		  label:getControl(L_MINE):SetHidden(true)
		  label:getControl(L_LUMB):SetHidden(true)
    end
	

	if self.keepCut and not self.keepUA then -- keep has no resources
        label:getControl(L_CONNECTED):SetHidden(false) 
        label:getControl(L_CONNECTED):SetTexture(CyrHUD.icons["DisconnectedKeep"])
        label:getControl(L_CONNECTED):SetColor(CyrHUD.info[ALLIANCE_NONE].color:UnpackRGBA())
	elseif GetKeepAccessible(self.keepID, CyrHUD.battleContext) and not self.keepUA then -- display if we can port to/from
		label:getControl(L_CONNECTED):SetHidden(false)
    label:getControl(L_CONNECTED):SetTexture(CyrHUD.icons["ConnectedKeep"])
    label:getControl(L_CONNECTED):SetColor(CyrHUD.info.linkColor:UnpackRGBA())
  else
	    label:getControl(L_CONNECTED):SetHidden(true)
	end

    -- Elder scrolls on keep icons
	local numObjectives = GetNumObjectives()
	for i = 1, numObjectives do
	    local okeepId, objectiveId, obgContext = GetAvAObjectiveKeysByIndex(i)
	    local thatKeep = GetKeepThatHasCapturedThisArtifactScrollObjective(okeepId, objectiveId, obgContext)

		if thatKeep ~= 0 then -- by the way we count number of scrolls for each alliance 
       local keepAlliance = GetKeepAlliance(thatKeep, CyrHUD.battleContext)  	
       CyrHUD.scrolls = CyrHUD.scrolls or {}
		   CyrHUD.scrolls[objectiveId] = keepAlliance
		
		   CyrHUD.ADscrolls = 0
		   CyrHUD.DCscrolls = 0
		   CyrHUD.EPscrolls = 0
		
			for key,value in pairs(CyrHUD.scrolls) do 
				 if CyrHUD.scrolls[key] == ALLIANCE_ALDMERI_DOMINION then CyrHUD.ADscrolls = CyrHUD.ADscrolls +1
				 elseif CyrHUD.scrolls[key] == ALLIANCE_DAGGERFALL_COVENANT then CyrHUD.DCscrolls = CyrHUD.DCscrolls +1
				 elseif CyrHUD.scrolls[key] == ALLIANCE_EBONHEART_PACT then CyrHUD.EPscrolls = CyrHUD.EPscrolls +1
				 end
			end
			--d("AD"..CyrHUD.ADscrolls.." DC"..CyrHUD.DCscrolls.." EP"..CyrHUD.EPscrolls)
		end
		
		local objectiveControlState = GetObjectiveControlState(okeepId, objectiveId, obgContext)
		
		if self.keepID == thatKeep and (objectiveControlState == OBJECTIVE_CONTROL_STATE_FLAG_AT_BASE or objectiveControlState == OBJECTIVE_CONTROL_STATE_FLAG_AT_ENEMY_BASE) then
			local scroll = label:getControl(L_SCROLL)
		    local scrollPintype,_,_,_ = GetObjectivePinInfo(okeepId, objectiveId, obgContext)
	        scroll:SetTexture(ZO_MapPin.PIN_DATA[scrollPintype].texture)
	        scroll:SetHidden(false)
		    break
		else  
		    local scroll = label:getControl(L_SCROLL)
			scroll:SetHidden(true)
		end
	end
	
	-- elder scrolls on temples icons
	if self.keepType == KEEPTYPE_ARTIFACT_GATE then
	   if self.gateTempleHasScroll then
	        local scroll = label:getControl(L_SCROLL)
		    local scrollPintype,_,_,_ = GetObjectivePinInfo(self.keepID - 6, GetKeepArtifactObjectiveId(self.keepID - 6), CyrHUD.battleContext)
	        scroll:SetTexture(ZO_MapPin.PIN_DATA[scrollPintype].texture)
	        scroll:SetHidden(false)
			local name = label:getControl(L_NAME)
			name:SetText(shortenKeepName(GetKeepName(self.keepID - 6)))
       else
	       	local scroll = label:getControl(L_SCROLL)
			scroll:SetHidden(true)
       end	   
	end

    --Time
    label:getControl(L_TIME):SetText(self:getDuration())
	if self.endBattle then 
        label:getControl(L_TIME):SetColor(CyrHUD.info[self.defender].color:UnpackRGBA())
		local name = label:getControl(L_NAME)
		name:SetText(self.keepName)
        name:SetColor(CyrHUD.info[self.defender].color:UnpackRGBA())
	else
        label:getControl(L_TIME):SetColor(CyrHUD.info[ALLIANCE_NONE].color:UnpackRGBA())	
	end   
	
    --Defensive siege
    local ds, dc = self:getDefSiege()
    local defSiege = label:getControl(L_DEF_SIEGE)
    defSiege:SetText(ds)
    defSiege:SetColor(dc:UnpackRGBA())
    label:getControl(L_ICON):SetColor(dc:UnpackRGBA())
	if ds ~= "" then
	   label:getControl(L_DEF_SIEGE_ICON):SetHidden(false)
	   if ds == "?" or ds < 10 then
		   label:positionControl(L_DEF_SIEGE, 30, 30, 224, 5) 
	   else
		   label:positionControl(L_DEF_SIEGE, 30, 30, 220, 5) 
	   end	
	else
	   label:getControl(L_DEF_SIEGE_ICON):SetHidden(true)
    end 


    --Attacking siege
    local as, ac = self:getAttSiege()
    local attSiege = label:getControl(L_ATT_SIEGE)
    attSiege:SetText(as)
    attSiege:SetColor(ac:UnpackRGBA())
	if as ~= "" then
	   label:getControl(L_ATT_SIEGE_ICON):SetHidden(false)
	   if as == "?" or as < 10 then
	       label:positionControl(L_ATT_SIEGE, 30, 30, 190, 5)
	   else
	       label:positionControl(L_ATT_SIEGE, 30, 30, 186, 5)
	   end
	else
	   label:getControl(L_ATT_SIEGE_ICON):SetHidden(true)
    end 
	
	-- animated arrows check
	if CyrHUD.animatedArrows and CyrHUD.animatedArrows[self.keepID]	and CyrHUD.animatedArrows[self.keepID].entryName and CyrHUD.animatedArrows[self.keepID].entryName == label.entryName then
	     -- do nothing
    else
	     -- removes arrow
		 local arrow = label:getControl(L_ARROW)
		 arrow:SetAlpha(0)
		 if CyrHUD.animatedArrows and CyrHUD.animatedArrows[self.keepID] and CyrHUD.animatedArrows[self.keepID].entryName then
		    CyrHUD.animatedArrows[self.keepID].label = label
		    CyrHUD.animatedArrows[self.keepID].entryName = label.entryName
		 end
		 
	end
	
	

    --Background color
    label.main:SetCenterColor(self:getBGColor():UnpackRGBA())
	
	-- set waypoint or rallypoint on click
	label:getControl(L_NAME):SetMouseEnabled(true)
    label:getControl(L_NAME):SetHandler("OnMouseUp", function(_, button, upInside, ctrl, alt, shift, command)
        if upInside then
		     if self.nX ~= nil and self.nY ~= nil  then
			    CyrHUD:setWaypoint(self.nX, self.nY)
			 end
        end
    end)

end

function CyrHUD.Battle:animateArrow(label, keep, x, alpha, entryName, timeStamp)
	
	CyrHUD.animatedArrows = CyrHUD.animatedArrows or {}
	if not x and not alpha then -- new info about the this keep so we update the label in database, 
	    CyrHUD.animatedArrows[keep.keepID] = CyrHUD.animatedArrows[keep.keepID] or {}
		CyrHUD.animatedArrows[keep.keepID].label = label
		CyrHUD.animatedArrows[keep.keepID].entryName = entryName
		timeStamp = GetTimeStamp()
		CyrHUD.animatedArrows[keep.keepID].timeStamp = timeStamp
	end

	
	if CyrHUD.animatedArrows[keep.keepID].entryName ~= entryName then -- this avoids arrows animations displayed on the wrong keep when list changes 
       label = CyrHUD.animatedArrows[keep.keepID].label
       entryName = CyrHUD.animatedArrows[keep.keepID].entryName
	end
	
	if CyrHUD.animatedArrows[keep.keepID].timeStamp ~= timeStamp then -- allow only one animated arrow at a time (fixes weird display and loop causing lag)
	   return
	end
	
	local arrow = label:getControl(L_ARROW)
	
    local minX = 35	
	local maxX = 165
    alpha = alpha or 0.1
	
	local r, g, b = GetAllianceColor(keep.attacker):UnpackRGB()

    if keep.attacker == 0 then

	    arrow:SetTransformRotationZ(math.rad(0))
		
		x = x or maxX
		if x < minX then
		   x = maxX
		   alpha = 0
		else
		    
		    x = x - 1
			
			if x > 100 then 
			   alpha = alpha + 0.0166
			else
			    alpha = alpha - 0.0166
            end
		end

         label:positionControl(L_ARROW, 20, 20, x, 7)
		 arrow:SetTexture(CyrHUD.icons["arrow"])
		 arrow:SetColor(r, g, b, alpha)

	else 

	    arrow:SetTransformRotationZ(math.rad(0))
		
		x = x or minX
		if x > maxX then
		   x = minX
		   alpha = 0
		else
		    x = x + 1
			if x < 100 then 
			   alpha = alpha + 0.0166
			else
			    alpha = alpha - 0.0166
            end			
		end

		label:positionControl(L_ARROW, 80, 80, x, -23)
		arrow:SetTexture(CyrHUD.icons[keep.attacker])
		arrow:SetColor(r, g, b, alpha)
    end

	 if keep.endBattle then 
	    arrow:SetAlpha(0)
		return
	 end
	 
     if arrow:GetAlpha() ~= 0 then
	    zo_callLater(function() CyrHUD.Battle:animateArrow(label, keep, x, alpha, entryName, timeStamp) end, 20)
	 end 
end
 
----------------------------------------------
-- Model update
----------------------------------------------

function CyrHUD.Battle:update()
    self.defender = GetKeepAlliance(self.keepID, CyrHUD.battleContext)
    self.keepUA = GetKeepUnderAttack(self.keepID, CyrHUD.battleContext)
    
	  if GetKeepType(self.keepID) == KEEPTYPE_KEEP then -- check if keep is cut 
        self.keepCut = (self.defender == GetUnitAlliance("player")) and not GetKeepHasResourcesForTravel(self.keepID, CyrHUD.battleContext)
    end
    self.siege[ALLIANCE_ALDMERI_DOMINION] = GetNumSieges(self.keepID, CyrHUD.battleContext, ALLIANCE_ALDMERI_DOMINION)
    self.siege[ALLIANCE_DAGGERFALL_COVENANT] = GetNumSieges(self.keepID, CyrHUD.battleContext, ALLIANCE_DAGGERFALL_COVENANT)
    self.siege[ALLIANCE_EBONHEART_PACT] = GetNumSieges(self.keepID, CyrHUD.battleContext, ALLIANCE_EBONHEART_PACT)
	local pinType, nX, nY = GetKeepPinInfo(self.keepID, CyrHUD.battleContext)
	self.nX = nX
	self.nY = nY
	
	
	if self.keepType == KEEPTYPE_ARTIFACT_GATE or self.keepType == KEEPTYPE_BRIDGE or self.keepType == KEEPTYPE_MILEGATE then

		local gateOpen = false
		if pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_ALDMERI_DOMINION or pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_DAGGERFALL_COVENANT or pinType == MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_EBONHEART_PACT then
			gateOpen = true
		elseif pinType == MAP_PIN_TYPE_KEEP_BRIDGE_IMPASSABLE or pinType == MAP_PIN_TYPE_KEEP_MILEGATE_IMPASSABLE or pinType == MAP_PIN_TYPE_KEEP_MILEGATE_CENTER_DESTROYED then 
		    gateOpen = true -- yep, it should be keepImpassable = true but the code is cleaner/has less lines like that   
		end
		self.gateOpen = gateOpen
		
		if self.keepType == KEEPTYPE_ARTIFACT_GATE then -- only display scroll gates if there is a scroll in the temple
			local gateTemple = self.keepID - 6
		    local scrollObjectiveId = GetKeepArtifactObjectiveId(gateTemple)
			local scrolIsAtBase = GetObjectiveControlState(gateTemple, scrollObjectiveId, CyrHUD.battleContext) == OBJECTIVE_CONTROL_STATE_FLAG_AT_BASE
			if scrolIsAtBase then
			     self.gateTempleHasScroll = true
			else
			     self.gateTempleHasScroll = false
			end
		end
	end
	
    if not self:isBattle() then
        if self.endBattle then
            --Remove after time
            if GetDiffBetweenTimeStamps(GetTimeStamp(), self.endBattle) > 15 then
				CyrHUD.battles[self.keepID] = nil
				self.flagUAsince = nil
            end
        elseif (self.flagUAsince and GetDiffBetweenTimeStamps(GetTimeStamp(), self.flagUAsince) > 25) or not self.flagUAsince then
            self.endBattle = GetTimeStamp()
        end

    end
	
	-- update imperial keeps ownership when in Cyrodiil / imperial district ownership list when in Imperial City
    if self.keepID == 6 or self.keepID == 7 or self.keepID == 9 or self.keepID == 13 or self.keepID == 15 or self.keepID == 17 or self.keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT then
	    CyrHUD.imperialKeeps = CyrHUD.imperialKeeps or {}
		CyrHUD.imperialKeeps[self.keepID] = self.defender
	end
	
end

function CyrHUD.Battle:restart()
    self.endBattle = nil
end

function CyrHUD.Battle:addIcon(icon)
	self.cyroChatIcon = icon
end

----------------------------------------------
-- Getters
----------------------------------------------

--[[
    @return red, green, blue, alpha for background color
        all in range [0,1]
--]]
function CyrHUD.Battle:getBGColor()
    if self.endBattle then
        if self.defender == GetUnitAlliance("player") then
            return CyrHUD.info.defendedColor
        end

        return CyrHUD.info.endAttackColor
    end

    local delta = GetDiffBetweenTimeStamps(GetTimeStamp(), self.startBattle)

    if delta < 60 then
        CyrHUD.info.newAttackColor:Lerp(CyrHUD.info.defaultBGColor, delta/120)
    end

    return CyrHUD.info.defaultBGColor
end

--[[
    @return elapsed time of battle event
        if an end is specified, will show total lenth
        otherwise will show current length
--]]
function CyrHUD.Battle:getDuration()
    return CyrHUD.formatTime(GetDiffBetweenTimeStamps(self.endBattle or GetTimeStamp(), self.startBattle), false, true)
end

--[[
    @return numSiege, color
        numSiege - number of defending siege equipment
        color - color for the defending faction
]]
function CyrHUD.Battle:getDefSiege()
    local siege = self.siege[self.defender]

    if not siege or siege == 0 then
		siege = ""
	end

    return siege, CyrHUD.info[self.defender].color
end

--[[
    @return numSiege, color
        numSiege - number of defending siege equipment
        color - color for the defending faction
    @note If two attacking factions, will sum the siege and show white for color
]]
function CyrHUD.Battle:getAttSiege()
    local count, faction = 0, nil

    for f,c in pairs(self.siege) do
        if f ~= self.defender and c > 0 then
            count = count + c

            if faction == nil then
                faction = f
            else
                faction = 0
            end
        end
    end

    local color = CyrHUD.info[ALLIANCE_NONE].color

    if faction and faction ~= 0 then
        color = CyrHUD.info[faction].color
    end
    

    if count == 0 then
        if not self.keepUA and n0(self.siege[self.defender]) > 0 then
            count = "?"
        else
            count = ""
        end
    end

    return count, color
end

--[[
    @return true iff battle is active
        a) keep is under attack status
        b) there is siege setup at keep
--]]
function CyrHUD.Battle:isBattle()

	if (self.keepType == KEEPTYPE_BRIDGE or self.keepType == KEEPTYPE_MILEGATE) and CyrHUD.cfg.hideBridgesAndMilegates then
	   return false
	end

    if self.keepType == KEEPTYPE_ARTIFACT_GATE then
	   return self.gateOpen and self.gateTempleHasScroll
	end

    if self.keepUA or self.gateOpen or self.keepCut then
		return true
	end

    return (self.siege[ALLIANCE_ALDMERI_DOMINION] + self.siege[ALLIANCE_DAGGERFALL_COVENANT] + self.siege[ALLIANCE_EBONHEART_PACT]) > 0
end


--[[
    @return icon for battle
        icon is based on resource type, faction, and whether it is under attack
    @see CyrHUD.info
]]
function CyrHUD.Battle:getIcon()
    --Debug code
    if CyrHUD.icons[self.keepType] == nil then
        return CyrHUD.info.noIcon
		
    end
	
	if self.keepType == KEEPTYPE_ARTIFACT_GATE then
	    if self.gateOpen then
		   if self.gateTempleHasScroll then
		       local pinType,_,_ = GetKeepPinInfo(self.keepID - 6, CyrHUD.battleContext)
		       return CyrHUD.icons[KEEPTYPE_ARTIFACT_KEEP*pinType]
		   else
		       return CyrHUD.icons[KEEPTYPE_ARTIFACT_GATE]
		   end
		    
	        
		else
		    return CyrHUD.icons[KEEPTYPE_ARTIFACT_GATE+999]
        end		
	end
	
	local pinType,_,_ = GetKeepPinInfo(self.keepID, CyrHUD.battleContext)
    local passable = IsKeepPassable(self.keepID, CyrHUD.battleContext)
	if (self.keepType == KEEPTYPE_MILEGATE or self.keepType == KEEPTYPE_BRIDGE) and not passable then
	    return CyrHUD.icons[self.keepType+999]
	elseif pinType == MAP_PIN_TYPE_KEEP_MILEGATE_CENTER_DESTROYED then	
	    return CyrHUD.icons[self.keepType+555] 
	else
		return CyrHUD.icons[self.keepType]
	end
    
end

-- in which Imperial City District is the battle
function CyrHUD.isInWhichDistrict(x,y)
   if not IsInImperialCity() then return "" end
   
    local Districts = {141,142,143,146,147,148}
	
	local keepName = ""
	local minDistance = 10000
	
	for i, keepId in ipairs(Districts) do
	   local pt, Kx, Ky = GetKeepPinInfo(keepId, BGQUERY_ASSIGNED_AND_LOCAL) 
	   local distance = math.sqrt( (Kx-x)^2 + (Ky-y)^2 )
	   if distance < minDistance then
          keepName = GetKeepName(keepId)
		      minDistance = distance
       end		  
	end
	
	return keepName
end
