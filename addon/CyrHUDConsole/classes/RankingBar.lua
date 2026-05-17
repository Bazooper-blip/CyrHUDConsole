-- This file is part of CyrHUD
--
-- (C) 2015 Scott Yeskie (Sasky)
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
CyrHUD.RankingBar = {}
CyrHUD.RankingBar.type = "RankingBar"
CyrHUD.RankingBar.__index = CyrHUD.RankingBar

setmetatable(CyrHUD.RankingBar, {
    __call = function(cls, ...) return cls.new(...) end
})

local bar = CyrHUD.RankingBar

function CyrHUD.RankingBar.new(campaign)

    local self = setmetatable({}, CyrHUD.RankingBar)

    self.campaign = campaign or GetCurrentCampaignId()
	self.alliance = GetUnitAlliance("player")
    self:update()

    return self
end




function bar:update()

	self.rank = self.rank or 0
	self.points = self.points or 0
	self.dName = self.dName or ""
	self.prevRank = self.prevRank or 0
	self.prevName = self.prevName or ""
	self.diffPoints = self.diffPoints or 0
	
    if not CyrHUD.CampaignDataPending then 
		local entrycount = GetNumCampaignAllianceLeaderboardEntries(self.campaign, self.alliance)

		local rank, points, dName, prevRank, prevPoints, prevName = 0, 0, "", 0, 0, ""
		for entry = 1, entrycount do
			local isPlayer, ranking, _, alliancePoints, _, displayName = GetCampaignAllianceLeaderboardEntryInfo(self.campaign, self.alliance, entry)
			
			if isPlayer then
			   rank = entry --ranking
			   points = alliancePoints
			   dName = displayName
			   break
			else
				prevRank = entry --ranking
				prevPoints = alliancePoints
				prevName = displayName
			end	
		end

		if rank ~= 0 and points ~= self.points then
		   -- player
		   self.rank = rank
		   self.points = points.."p"
		   self.dName = dName
		   
		   -- previous rank player
		   if rank ~= 1 then
			   self.prevRank = prevRank
			   self.prevName = prevName 
			   self.diffPoints = (prevPoints - points).."p"
		   else
			   self.prevRank = ""
			   self.prevName = "" 
			   self.diffPoints = ""
		   end
		   self.updated = true
		end
	end
	
	if self.updated then
	    local state = QueryCampaignLeaderboardData(self.alliance)
		if state == LEADERBOARD_DATA_RESPONSE_PENDING then
		   self.updated = false
		   CyrHUD.CampaignDataPending = true
		end
    end	

	
end


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

local ICON_MEM = "img32"
local ICON_ELV = "img33"
local ICON_ARE = "img34"
local ICON_NOB = "img35"
local ICON_ARB = "img36"
local ICON_TEM = "img37"


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


--local TEXT_KILLS, TEXT_DEATHS = "txt14","txt15"

function bar:configureLabel(label)
    label:exposeControls(3,4)
    --label.main:SetCenterColor(CyrHUD.info.invisColor:UnpackRGBA())
	
    label:getControl(ICON_EMPEROR):SetTexture(CyrHUD.icons["emperor"])
	label:getControl(ICON_EMPEROR):SetDrawLayer(3)
	label:getControl(ICON_EMPEROR):SetColor(CyrHUD.info[self.alliance].color:UnpackRGBA())
	label:positionControl(ICON_EMPEROR, 32, 32, 0, 0)
	
	

	label:positionControl(TEXT_RIVALNAME, 130, 50, 35, -3)
	label:getControl(TEXT_RIVALNAME):SetDrawLayer(3)

	
	label:positionControl(TEXT_RIVALRANK, 30, 50, 170, -3)
	label:getControl(TEXT_RIVALRANK):SetDrawLayer(3)
	

	label:positionControl(TEXT_RIVALSCORE, 130, 50, 205, -3)
	label:getControl(TEXT_RIVALSCORE):SetDrawLayer(3)


    label:positionControl(TEXT_PLAYERNAME, 130, 50, 35, 16)
	label:getControl(TEXT_PLAYERNAME):SetDrawLayer(3)
	
	label:positionControl(TEXT_PLAYERRANK, 30, 50, 170, 16)
	label:getControl(TEXT_PLAYERRANK):SetDrawLayer(3)

	label:positionControl(TEXT_PLAYERSCORE, 130, 50, 205, 16)
	label:getControl(TEXT_PLAYERSCORE):SetDrawLayer(3)
	
	label:getControl(ICON_ASH):SetTexture(CyrHUD.icons[KEEPTYPE_KEEP])
	label:getControl(ICON_WELL):SetTexture(CyrHUD.icons[KEEPTYPE_KEEP])
	label:getControl(ICON_CHAL):SetTexture(CyrHUD.icons[KEEPTYPE_KEEP])
	label:getControl(ICON_BRK):SetTexture(CyrHUD.icons[KEEPTYPE_KEEP])
	label:getControl(ICON_SIA):SetTexture(CyrHUD.icons[KEEPTYPE_KEEP])
	label:getControl(ICON_ROE):SetTexture(CyrHUD.icons[KEEPTYPE_KEEP])
	
	
	label:getControl(ICON_MEM):SetTexture(CyrHUD.icons[KEEPTYPE_IMPERIAL_CITY_DISTRICT])
	label:getControl(ICON_ELV):SetTexture(CyrHUD.icons[KEEPTYPE_IMPERIAL_CITY_DISTRICT])
	label:getControl(ICON_ARE):SetTexture(CyrHUD.icons[KEEPTYPE_IMPERIAL_CITY_DISTRICT])
	label:getControl(ICON_NOB):SetTexture(CyrHUD.icons[KEEPTYPE_IMPERIAL_CITY_DISTRICT])
	label:getControl(ICON_ARB):SetTexture(CyrHUD.icons[KEEPTYPE_IMPERIAL_CITY_DISTRICT])
	label:getControl(ICON_TEM):SetTexture(CyrHUD.icons[KEEPTYPE_IMPERIAL_CITY_DISTRICT])	
	
	
	
	
    label:getControl(ICON_ASH):SetDrawLayer(4)
	label:getControl(ICON_WELL):SetDrawLayer(4)
	label:getControl(ICON_CHAL):SetDrawLayer(4)
	label:getControl(ICON_BRK):SetDrawLayer(4)
	label:getControl(ICON_SIA):SetDrawLayer(4)
	label:getControl(ICON_ROE):SetDrawLayer(4)
	
	
	label:getControl(ICON_MEM):SetDrawLayer(4)
	label:getControl(ICON_ELV):SetDrawLayer(4)
	label:getControl(ICON_ARE):SetDrawLayer(4)
	label:getControl(ICON_NOB):SetDrawLayer(4)
	label:getControl(ICON_ARB):SetDrawLayer(4)
	label:getControl(ICON_TEM):SetDrawLayer(4)
	
	label:positionControl(ICON_WELL, 15, 15, 0, -2)
	label:positionControl(ICON_CHAL, 15, 15, 18, -2)
	
    label:positionControl(ICON_ASH, 15, 15, -5, 10)
	label:positionControl(ICON_BRK, 15, 15, 23, 10)
	
	label:positionControl(ICON_ROE, 15, 15, 0, 20)
	label:positionControl(ICON_SIA, 15, 15, 18, 20)
	
	
	
	label:positionControl(ICON_MEM, 20, 20, 9, -2)
	
	label:positionControl(ICON_ELV, 20, 20, -2, 4)
	label:positionControl(ICON_ARE, 20, 20, 20, 4)
	
	label:positionControl(ICON_ARB, 20, 20, 20, 15)
	label:positionControl(ICON_NOB, 20, 20, -2, 15)
	
	label:positionControl(ICON_TEM, 20, 20, 9, 20)	
	
	
	--label:positionControl(TEXT_KILLS, 90, 40, 10, -30)
	--label:positionControl(TEXT_DEATHS, 90, 40, 10, -10)

end

function bar:updateLabel(label)

	-- if not CyrHUD.cfg.hideKillsDeaths then
	    -- label:getControl(TEXT_KILLS):SetText("K: "..CyrHUD.yourKills)
	    -- label:getControl(TEXT_DEATHS):SetText("D: "..CyrHUD.yourDeaths)
		-- label:getControl(TEXT_KILLS):SetHidden(false)
		-- label:getControl(TEXT_DEATHS):SetHidden(false)
	-- else
	    -- label:getControl(TEXT_KILLS):SetHidden(true)
		-- label:getControl(TEXT_DEATHS):SetHidden(true)
    -- end


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

    label:getControl(L_UA):SetHidden(true)
	label:getControl(L_LUMB):SetHidden(true)
	label:getControl(L_MINE):SetHidden(true)
	label:getControl(L_FARM):SetHidden(true)
    label:getControl(L_SCROLL):SetHidden(true)
	label:getControl(L_ATT_SIEGE):SetHidden(true)
	label:getControl(L_DEF_SIEGE):SetHidden(true)
	label:getControl(CYROCHAT_ICON):SetHidden(true)
    label:getControl(L_ATT_SIEGE_ICON):SetHidden(true)
	label:getControl(L_DEF_SIEGE_ICON):SetHidden(true)
	label:getControl(L_CONNECTED):SetHidden(true)
	label:getControl(L_HOLDER):SetHidden(true)
	label:getControl(L_ARROW):SetAlpha(0)
	
    label:getControl(L_NAME):SetHidden(true)
	label:getControl(L_ICON):SetHidden(true)
	label:getControl(L_TIME):SetHidden(true)

	

	label:getControl(TEXT_PLAYERNAME):SetHidden(false)
	label:getControl(TEXT_RIVALNAME):SetHidden(false)
	label:getControl(TEXT_PLAYERRANK):SetHidden(false)
	label:getControl(TEXT_RIVALRANK):SetHidden(false)
	label:getControl(TEXT_PLAYERSCORE):SetHidden(false)
	label:getControl(TEXT_RIVALSCORE):SetHidden(false)

	
	
	
	

	
	
	
	

	if IsInImperialCity() then
	
	
	    label:getControl(ICON_EMPEROR):SetHidden(true)
	
		local MemAlliance = CyrHUD.imperialKeeps[142] or 0
		local ElvAlliance = CyrHUD.imperialKeeps[148] or 0	
		local AreAlliance = CyrHUD.imperialKeeps[146] or 0
		local NobAlliance = CyrHUD.imperialKeeps[141] or 0
		local ArbAlliance = CyrHUD.imperialKeeps[143] or 0
		local TemAlliance = CyrHUD.imperialKeeps[147] or 0
		
		local NemColor = CyrHUD.info[MemAlliance].color 
		local ElvColor = CyrHUD.info[ElvAlliance].color 	
		local AreColor = CyrHUD.info[AreAlliance].color 
		local NobColor = CyrHUD.info[NobAlliance].color 
		local ArbColor = CyrHUD.info[ArbAlliance].color 
		local TemColor = CyrHUD.info[TemAlliance].color 

		
		label:getControl(ICON_MEM):SetColor(NemColor:UnpackRGBA())
		label:getControl(ICON_ELV):SetColor(ElvColor:UnpackRGBA())
		label:getControl(ICON_ARE):SetColor(AreColor:UnpackRGBA())
		label:getControl(ICON_NOB):SetColor(NobColor:UnpackRGBA())
		label:getControl(ICON_ARB):SetColor(ArbColor:UnpackRGBA())
		label:getControl(ICON_TEM):SetColor(TemColor:UnpackRGBA())

	
		label:getControl(ICON_MEM):SetHidden(false)
		label:getControl(ICON_ELV):SetHidden(false)
		label:getControl(ICON_ARE):SetHidden(false)
		label:getControl(ICON_NOB):SetHidden(false)
		label:getControl(ICON_ARB):SetHidden(false)
		label:getControl(ICON_TEM):SetHidden(false)	
	
	
	
		label:getControl(ICON_ASH):SetHidden(true)
		label:getControl(ICON_WELL):SetHidden(true)
		label:getControl(ICON_CHAL):SetHidden(true)
		label:getControl(ICON_BRK):SetHidden(true)
		label:getControl(ICON_SIA):SetHidden(true)
		label:getControl(ICON_ROE):SetHidden(true)
		
        local telVarIcon = GetCurrencyKeyboardIcon(CURT_TELVAR_STONES)
		local fragmentsIcon = GetCurrencyKeyboardIcon(CURT_IMPERIAL_FRAGMENTS)
		
		local telVarColor = ZO_ColorDef:New(GetCurrencyKeyboardColor(CURT_TELVAR_STONES))
		local fragmentsColor = ZO_ColorDef:New(GetCurrencyKeyboardColor(CURT_IMPERIAL_FRAGMENTS))

		local numTelVar = GetCurrencyAmount(CURT_TELVAR_STONES, CURRENCY_LOCATION_CHARACTER)..zo_iconTextFormatNoSpace(telVarIcon,12,12,"")
		      numTelVar = telVarColor:Colorize(numTelVar)
		local numFragments = GetCurrencyAmount(CURT_IMPERIAL_FRAGMENTS, CURRENCY_LOCATION_ACCOUNT)..zo_iconTextFormatNoSpace(fragmentsIcon,12,12,"")
		      numFragments = fragmentsColor:Colorize(numFragments)
		
		local telVar = GetCurrencyName(CURT_TELVAR_STONES, false, true)
		      telVar = telVarColor:Colorize(telVar)
		local fragments = GetCurrencyName(CURT_IMPERIAL_FRAGMENTS, false, true)
		      fragments = fragmentsColor:Colorize(fragments)
		local multiplier = GetTelvarStoneMultiplier(GetTelvarStoneMultiplierThresholdIndex())
		
		
		
		
		
		if tostring(numTelVar) ~= label:getControl(TEXT_RIVALSCORE):GetText() or tostring(numFragments) ~= label:getControl(TEXT_PLAYERSCORE):GetText() then
		    self.startBattle = GetTimeStamp()
		end

		
		label:getControl(TEXT_RIVALNAME):SetText(telVar)
		label:getControl(TEXT_RIVALRANK):SetText("x"..multiplier)
		label:getControl(TEXT_RIVALSCORE):SetText(numTelVar)	

		label:getControl(TEXT_PLAYERNAME):SetText(fragments)
		label:getControl(TEXT_PLAYERRANK):SetText("")  
		label:getControl(TEXT_PLAYERSCORE):SetText(numFragments)
		
		label:getControl(TEXT_RIVALNAME):SetAlpha(1)
	    label:getControl(TEXT_RIVALRANK):SetAlpha(1)
	    label:getControl(TEXT_RIVALSCORE):SetAlpha(1)	
		
		
		
	else
	    label:getControl(ICON_EMPEROR):SetHidden(false)
	
		local emperorAlliance = GetCampaignEmperorInfo(self.campaign)
		label:getControl(ICON_EMPEROR):SetColor(CyrHUD.info[emperorAlliance].color:UnpackRGBA())
		
		local AshAlliance = CyrHUD.imperialKeeps[6] or 0
		local AleswellAlliance = CyrHUD.imperialKeeps[7] or 0	
		local ChalmanAlliance = CyrHUD.imperialKeeps[9] or 0
		local BlueRoadAlliance = CyrHUD.imperialKeeps[13] or 0
		local AlessiaAlliance = CyrHUD.imperialKeeps[15] or 0
		local RoebeckAlliance = CyrHUD.imperialKeeps[17] or 0
		
		local AshColor = CyrHUD.info[AshAlliance].color 
		local AleswellColor = CyrHUD.info[AleswellAlliance].color 	
		local ChalmanColor = CyrHUD.info[ChalmanAlliance].color 
		local BlueRoadColor = CyrHUD.info[BlueRoadAlliance].color 
		local AlessiaColor = CyrHUD.info[AlessiaAlliance].color 
		local RoebeckColor = CyrHUD.info[RoebeckAlliance].color 

		
		label:getControl(ICON_ASH):SetColor(AshColor:UnpackRGBA())
		label:getControl(ICON_WELL):SetColor(AleswellColor:UnpackRGBA())
		label:getControl(ICON_CHAL):SetColor(ChalmanColor:UnpackRGBA())
		label:getControl(ICON_BRK):SetColor(BlueRoadColor:UnpackRGBA())
		label:getControl(ICON_SIA):SetColor(AlessiaColor:UnpackRGBA())
		label:getControl(ICON_ROE):SetColor(RoebeckColor:UnpackRGBA())
		
		if label:getControl(TEXT_PLAYERSCORE):GetText() ~= tostring(self.points) then
            self.startBattle = GetTimeStamp()
        end
	
		label:getControl(TEXT_RIVALNAME):SetText(self.prevName)
		label:getControl(TEXT_RIVALRANK):SetText("#"..self.prevRank)
		label:getControl(TEXT_RIVALSCORE):SetText("+"..self.diffPoints)	

		label:getControl(TEXT_PLAYERNAME):SetText(self.dName)
		label:getControl(TEXT_PLAYERRANK):SetText("#"..self.rank)  
		label:getControl(TEXT_PLAYERSCORE):SetText(self.points)
	
	
		label:getControl(ICON_ASH):SetHidden(false)
		label:getControl(ICON_WELL):SetHidden(false)
		label:getControl(ICON_CHAL):SetHidden(false)
		label:getControl(ICON_BRK):SetHidden(false)
		label:getControl(ICON_SIA):SetHidden(false)
		label:getControl(ICON_ROE):SetHidden(false)	
		
		
		label:getControl(ICON_MEM):SetHidden(true)
		label:getControl(ICON_ELV):SetHidden(true)
		label:getControl(ICON_ARE):SetHidden(true)
		label:getControl(ICON_NOB):SetHidden(true)
		label:getControl(ICON_ARB):SetHidden(true)
		label:getControl(ICON_TEM):SetHidden(true)

        label:getControl(TEXT_RIVALNAME):SetAlpha(0.5)
	    label:getControl(TEXT_RIVALRANK):SetAlpha(0.5)
	    label:getControl(TEXT_RIVALSCORE):SetAlpha(0.5)		
	end
	    --Background color
    label.main:SetCenterColor(self:getBGColor():UnpackRGBA())
end

function bar:getBGColor()

    local delta = GetDiffBetweenTimeStamps(GetTimeStamp(), self.startBattle)

    if delta < 15 then
        return CyrHUD.info.endAttackColor:Lerp(CyrHUD.info.defaultBGColor, delta/30)
    end

    return CyrHUD.info.defaultBGColor
end