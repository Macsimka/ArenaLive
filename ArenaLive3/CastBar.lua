--[[ ArenaLive Core Functions: Castbar Handler
Created by: Vadrak
Creation Date: 11.04.2014
Last Update: 10.09.2014
This file contains all relevant functions for cast bars and their behaviour
]]--

-- ArenaLive addon Name and localisation table:
local addonName, L = ...;

-- Create table to store casting frames:
local castBarsCasting = {};

--[[
**************************************************
******* GENERAL HANDLER SET UP STARTS HERE *******
**************************************************
]]--
-- Create new Handler:
local CastBar = ArenaLive:ConstructHandler("CastBar", true, true);
CastBar.canToggle = true;

-- Register the handler for all needed events.
CastBar:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED_SPELL_INTERRUPT");
CastBar:RegisterEvent("PLAYER_ENTERING_WORLD");
CastBar:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_START");
CastBar:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_SUCCESS");
CastBar:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_FAILED");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_START");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_DELAYED");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_FAILED");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_STOP");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
-- CastBar:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");



--[[
****************************************
****** HANDLER METHODS START HERE ******
****************************************
]]--
--[[ Method: ConstructObject
	 Creates a new frame of the type health bar.
		castBar (frame [Statusbar]): The frame that is going to be set up as a cast var.
		icon (Texture): A texture that shows the current cast's icon.
		text (FontString): A FontString that shows the name of the current cast.
		shield (Texture [optional]): A texture that is shown when a cast isn't interruptable.
		animation (AnimationGroup): An animation group that is used to fade out the cast bar.
		fadeOut (Alpha): An animation inside the animation group that is used to fade out the cast bar.
		showTradeSkills (boolean): If true, the cast bar shows spells that are marked as trade skills.
]]--
function CastBar:ConstructObject(castBar, icon, text, shield, animation, fadeOut, showTradeSkills, addonName, frameType)
	ArenaLive:CheckArgs(castBar, "StatusBar", icon, "Texture", text, "FontString");

	-- Set basic info:
	castBar.showTradeSkills = showTradeSkills;
	
	-- Set references:
	castBar.icon = icon;
	castBar.text = text;
	castBar.shield = shield;
	castBar.animation = animation;
	castBar.fadeOut = fadeOut;
	
	-- Set initial values:
	castBar.minValue = 0;
	castBar.value = 0;
	castBar.maxValue = 0;
	
	CastBar:SetReverseFill(castBar, addonName, frameType);
end

function CastBar:OnEnable(unitFrame)
	CastBar:Update(unitFrame);
end

function CastBar:OnDisable(unitFrame)
	CastBar:Reset(unitFrame);
end

function CastBar:SetReverseFill (castBar, addonName, frameType)
	local database = ArenaLive:GetDBComponent(addonName, self.name, frameType);
	local reverseFill = database.ReverseFill;
	castBar:SetReverseFill(reverseFill);
end

function CastBar:Update(unitFrame)
	local unit = unitFrame.unit;
	local castBar = unitFrame[self.name];
	
	if ( not unit or not castBar.enabled ) then
		return;
	end
	
	-- Check if unit casts/channels:
	local spell = UnitCastingInfo(unit);
	local event;
	if ( not spell ) then
		spell = UnitChannelInfo(unit);
	end
	event = "COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_START"
	
	-- Start cast if there is one:
	if ( spell ) then
		CastBar:StartCast(castBar, unit, event);
	else
		-- Not casting so reset and hide castBar just in case:
		CastBar:Reset(unitFrame);
	end
end


function CastBar:Reset(object)
	-- This reset function is different from others, as sometimes, it directly receives the castbar instead of the unit frame:
	local castBar = CastBar:GetHandlerObject(object);
	castBarsCasting[castBar] = nil;
	castBar.lineID = nil;
	castBar.casting = nil;
	castBar.channeling = nil;
	castBar.minValue = 0;
	castBar.value = 0;
	castBar.maxValue = 0;	
	castBar:Hide();		
end

function CastBar:StartCast(castBar, unit, event)
	
	if ( not unit ) then
		return;
	end

	local name, subText, text, icon, startTime, endTime, isTradeSkill, lineID, notInterruptible, value, maxValue;
	if ( event == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_START" ) then
		if not UnitChannelInfo(unit) then
			name, subText, text, icon, startTime, endTime, isTradeSkill, lineID, notInterruptible = UnitCastingInfo(unit);
			if ( not startTime ) then
				return;
			end
			value = (GetTime() - (startTime / 1000));
			castBar.lineID = lineID;
			castBar.casting = true;
			castBar.channeling = nil;
		else
			name, subText, text, icon, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit);
			if ( not endTime ) then
				return;
			end
			value = ((endTime / 1000) - GetTime());
			castBar.lineID = nil;
			castBar.casting = nil;
			castBar.channeling = true;
		end
	end

	-- Check if we show trade skills:
	if ( isTradeSkill and not castBar.showTradeSkills ) then
		-- We're not showing this cast in that specifi cast bar so reset everything and stop function:
		castBar.lineID = nil;
		castBar.casting = nil;
		castBar.channeling = nil;		
		return;
	end
	
	-- Set Text and Texture:
	if ( castBar.icon ) then
		castBar.icon:SetTexture(icon);
	end
	
	if ( castBar.text ) then
		castBar.text:SetText(text);
	end
	
	-- Set Values:
	maxValue = ((endTime - startTime) / 1000);
	castBar.value = value;
	castBar.maxValue = maxValue;
	castBar:SetMinMaxValues(0, maxValue);
	castBar:SetValue(value);
	
	-- Set initial colour:
	castBar:SetStatusBarColor(1.0, 0.7, 0.0);
	
	-- Reset animation if it isn't finished yet:
	if ( castBar.animation:IsPlaying() ) then
		castBar.animation:Stop();
	end		
	
	-- Show/Hide shield texture if there is one:
	-- Additionally I've chosen a light blue for uninterruptable casts. This way it is easier to see if a cast is interruptable or not.
	-- TODO: Make the colour changeable via saved variables.
	if ( castBar.shield ) then
		if ( notInterruptible ) then
			castBar.shield:Show();
			castBar:SetStatusBarColor(0.0, 0.49, 1.0);
		else
			castBar.shield:Hide();
			castBar:SetStatusBarColor(1.0, 0.7, 0.0);
		end
	end
	
	-- Finally show cast bar and add it to OnUpdate Script:
	castBar:SetAlpha(1);
	castBar:Show();
	castBarsCasting[castBar] = true;
end

function CastBar:UpdateCast(castBar, unit, event)

	if ( not unit or ( not castBar.casting and not castBar.channeling ) ) then
		return;
	end

	local name, subText, text, icon, startTime, endTime, value, maxValue;
	if ( event == "UNIT_SPELLCAST_DELAYED" ) then
		name, subText, text, icon, startTime, endTime = UnitCastingInfo(unit);
		if name then value = (GetTime() - (startTime / 1000)); end
	elseif ( event == "UNIT_SPELLCAST_CHANNEL_UPDATE" ) then
		name, subText, text, icon, startTime, endTime = UnitChannelInfo(unit);
		value = ((endTime / 1000) - GetTime());
	end

	-- Update Values:
	maxValue = ((endTime - startTime) / 1000);
	castBar.value = value;
	castBar.maxValue = maxValue;
	castBar:SetMinMaxValues(0, maxValue);
	castBar:SetValue(value);	
	
end

function CastBar:StopCast(castBar, event, lineID)

	-- UNIT_SPELLCAST_SUCCEEDED fires for every channeling tick. So ignore these for this function
	if ( not castBar.casting and not castBar.channeling ) then
		return;
	end

	if ( event == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_SUCCESS" and castBar.casting and lineID == castBar.lineID ) then
		CastBar:FinishCast(castBar, true);
	elseif ( event == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_FAILED" and castBar.casting  and lineID == castBar.lineID ) then
		if ( castBar.text ) then
			castBar.text:SetText(FAILED);
		end	
		CastBar:FinishCast(castBar, false);
	elseif  ( event == "UNIT_SPELLCAST_INTERRUPTED" and lineID == castBar.lineID ) then
		if ( castBar.text ) then
			castBar.text:SetText(INTERRUPTED);
		end
		CastBar:FinishCast(castBar, false);
	elseif ( event == "UNIT_SPELLCAST_STOP" and lineID == castBar.lineID ) then
		CastBar:FinishCast(castBar, false);
	elseif ( event == "UNIT_SPELLCAST_CHANNEL_STOP" and castBar.channeling ) then
		CastBar:FinishCast(castBar, true);
	end

end

function CastBar:LockoutCast(castBar, school)
	castBar.text:SetText(string.format(L["Lockout! (%s)"], GetSchoolString(school)));
	CastBar:FinishCast(castBar, false);
end

function CastBar:FinishCast(castBar, wasSuccessful)

	if ( not castBar.casting and not castBar.channeling and not castBarsCasting[castBar] ) then
		return;
	end

	-- Remove from active cast bar list:
	castBarsCasting[castBar] = nil;

	if ( wasSuccessful ) then
		castBar.casting = nil;
		castBar.lineID = nil;
		castBar.channeling = nil;
		castBar:SetStatusBarColor(0.0, 1.0, 0.0);
		castBar.fadeOut:SetStartDelay(0);
	else
		castBar.casting = nil;
		castBar.channeling = nil;
		castBar.lineID = nil;
		castBar:SetStatusBarColor(1.0, 0.0, 0.0);
		castBar.fadeOut:SetStartDelay(0.5);
	end
	
	castBar:SetValue(castBar.maxValue);
	castBar.animation:Play();
end

function CastBar:UpdateShield(castBar, event)
	
	if ( not castBar.casting and not castBar.channeling ) then
		return;
	end

	if ( event == "UNIT_SPELLCAST_INTERRUPTIBLE" ) then
		if ( castBar.shield ) then
			castBar.shield:Hide();
		end
		castBar:SetStatusBarColor(1.0, 0.7, 0.0);
	elseif ( event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" ) then
		if ( castBar.shield )  then
			castBar.shield:Show();
		end
		castBar:SetStatusBarColor(0.0, 0.49, 1.0);
	end
end

function CastBar:OnUpdate(elapsed)
	for castBar in pairs(castBarsCasting) do
		-- Update cast bar:
		local unitFrame = castBar:GetParent();
		if ( not castBar:IsVisible() and unitFrame.unit ~= "target" and unitFrame.unit ~= "focus" ) then
			-- If the unit frame isn't shown stop the animation:
				-- Focus and Target units are an exception for this rule,
				-- in order to allow cast bars to be shown correctly on
				-- target and focus switches (StateDriver is too slow with
				-- updating the hidden status of the unit frames).
			self:Reset(castBar);
		elseif ( castBar.casting ) then
			castBar.value = castBar.value + elapsed;
			
            -- Check if unit casts/channels:
            local spell = UnitCastingInfo(unitFrame.unit);
            if ( not spell ) then
                spell = UnitChannelInfo(unitFrame.unit);
            end
			
            if ( not spell ) then
                CastBar:FinishCast(castBar, false);
                return;
            end
			
			if ( castBar.value >= castBar.maxValue ) then
				CastBar:FinishCast(castBar, true);
			else
				castBar:SetValue(castBar.value);
			end
		elseif ( castBar.channeling ) then
			castBar.value = castBar.value - elapsed;
			if ( castBar.value <= 0 ) then
				CastBar:FinishCast(castBar, true);
			else
				castBar:SetValue(castBar.value);
			end
		end		
	end
end

function CastBar:OnEvent(event, ...)
	local srcGuid, src, _, _, guid, dest, _, _, spellID, spellName, lineID = select(4, ...);
	local unit = ArenaLiveSpectator:GetUnitByGUID(srcGuid);
	
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		-- Update all cast bars after the loading screen finished:
		for id, unitFrame in ArenaLive:GetAllUnitFrames() do
			if ( unitFrame[self.name] and unitFrame[self.name]["enabled"] ) then
				CastBar:Update(unitFrame);
			end
		end
	end
	if not unit and not srcGuid then return end;
	if ( event == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_INTERRUPT" ) then
		local school = select(17, ...); -- SpellSchool of the kicked spell
		if ( ArenaLive:IsGUIDInUnitFrameCache(guid) ) then
			if not select(2, ArenaLive:GetAffectedUnitFramesByGUID(guid)) then return end
			for id in ArenaLive:GetAffectedUnitFramesByGUID(guid) do
				local unitFrame = ArenaLive:GetUnitFrameByID(id);
				if ( unitFrame[self.name] and unitFrame[self.name]["enabled"] ) then
					CastBar:LockoutCast(unitFrame[self.name], school)
				end
			end
		end
	elseif ( event == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_START" ) then
		if ( ArenaLive:IsUnitInUnitFrameCache(unit) ) then
			if not select(2, ArenaLive:GetAffectedUnitFramesByGUID(srcGuid)) then return end
			for id in ArenaLive:GetAffectedUnitFramesByGUID(srcGuid) do
				local unitFrame = ArenaLive:GetUnitFrameByID(id);
				if ( unitFrame[self.name] and unitFrame[self.name]["enabled"] ) then
					CastBar:StartCast(unitFrame[self.name], unitFrame.unit, event);
				end
			end
		end
	elseif ( event == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_FAILED" or event == "COMBAT_LOG_EVENT_UNFILTERED_SPELL_CAST_SUCCESS" ) then
		if ( ArenaLive:IsUnitInUnitFrameCache(unit) ) then
			if not select(2, ArenaLive:GetAffectedUnitFramesByGUID(srcGuid)) then return end
			for id in ArenaLive:GetAffectedUnitFramesByGUID(srcGuid) do
				local unitFrame = ArenaLive:GetUnitFrameByID(id);
				if ( unitFrame[self.name] and unitFrame[self.name]["enabled"] ) then
					CastBar:StopCast(unitFrame[self.name], event, lineID);
				end
			end
		end
	end

end

CastBar:SetScript("OnUpdate", CastBar.OnUpdate);

CastBar.optionSets = {
	["Enable"] = {
		["type"] = "CheckButton",
		["title"] = L["Enable"],
		["tooltip"] = L["Enables the cast bar."],
		["GetDBValue"] = function (frame) local database = ArenaLive:GetDBComponent(frame.addon, frame.handler, frame.group); return database.Enabled; end,
		["SetDBValue"] = function (frame, newValue) local database = ArenaLive:GetDBComponent(frame.addon, frame.handler, frame.group); database.Enabled = newValue; end,
		["postUpdate"] = function (frame, newValue, oldValue) for id, unitFrame in ArenaLive:GetAllUnitFrames() do if ( unitFrame.addon == frame.addon and unitFrame.group == frame.group and unitFrame[CastBar.name] ) then unitFrame:ToggleHandler(CastBar.name); end end end,
	},
	["ReverseFill"] = {
		["type"] = "CheckButton",
		["title"] = L["Reverse Fill Castbar"],
		["tooltip"] = L["If checked, the castbar will fill from right to left, instead of from left to right."],
		["GetDBValue"] = function (frame) local database = ArenaLive:GetDBComponent(frame.addon, frame.handler, frame.group); return database.ReverseFill; end,
		["SetDBValue"] = function (frame, newValue) local database = ArenaLive:GetDBComponent(frame.addon, frame.handler, frame.group); database.ReverseFill = newValue; end,
		["postUpdate"] = function (frame, newValue, oldValue) for id, unitFrame in ArenaLive:GetAllUnitFrames() do if ( unitFrame.addon == frame.addon and unitFrame.group == frame.group and unitFrame[CastBar.name] ) then CastBar:SetReverseFill(unitFrame[CastBar.name], unitFrame.addon, unitFrame.group); CastBar:Update(unitFrame); end end end,
	},
};