local addonName, L = ...;

local function initialiseSideFrame(frame, group)

	local prefix = frame:GetName();
	local id = frame:GetID();
	
	ArenaLive:ConstructHandlerObject(frame, "UnitFrame", addonName, group, "target", nil, function(self) CommentatorLookatPlayer(self.group == "Right" and 2 or 1, self:GetID()) end, nil, nil, "menu");
	
	frame.border = _G[prefix.."Border"];
	frame.background = _G[prefix.."Background"];
	
	frame:RegisterHandler(_G[prefix.."HealthBar"], "HealthBar", nil, _G[prefix.."HealthBarHealPredictionBar"], _G[prefix.."HealthBarAbsorbBar"], _G[prefix.."HealthBarAbsorbBarOverlay"], 32, _G[prefix.."HealthBarAbsorbBarFullHPIndicator"], nil, addonName, group);
	frame:RegisterHandler(_G[prefix.."PowerBar"], "PowerBar", nil, addonName, group);
	frame:RegisterHandler(_G[prefix.."Portrait"], "Portrait", nil, _G[prefix.."PortraitBackground"], _G[prefix.."PortraitTexture"], frame);
	frame:RegisterHandler(_G[prefix.."PortraitCCIndicator"], "CCIndicator", nil, _G[prefix.."PortraitCCIndicatorTexture"], _G[prefix.."PortraitCCIndicatorCooldown"], addonName);
	frame:RegisterHandler(_G[prefix.."Name"], "NameText", nil, frame);
	frame:RegisterHandler(_G[prefix.."HealthBarText"], "HealthBarText", nil, frame);
	frame:RegisterHandler(_G[prefix.."PowerBarText"], "PowerBarText", nil, frame);
	frame:RegisterHandler(_G[prefix.."CastBar"], "CastBar", nil, _G[prefix.."CastBarIcon"], _G[prefix.."CastBarText"], _G[prefix.."CastBarShield"], _G[prefix.."CastBarAnimation"], _G[prefix.."CastBarAnimationFadeOut"], true, addonName, group);
	frame:RegisterHandler(_G[prefix.."CastHistory"], "CastHistory");
	frame:RegisterHandler(_G[prefix.."AuraFrame"], "Aura", nil, _G[prefix.."AuraFrameBuffFrame"], _G[prefix.."AuraFrameDebuffFrame"]);
	frame:RegisterHandler(_G[prefix.."MainTargetIndicator"], "MainTargetIndicator");
	frame:RegisterHandler(_G[prefix.."SpiritHealerFrame"], "SpiritHealerFrame");
end

function ArenaLiveSpectator:InitialiseSideFrames()
	for i = 1, 5 do
		local frame = _G["ALSPEC_LeftSideFramesFrame"..i];
		initialiseSideFrame(frame, "Left");
		
		frame = _G["ALSPEC_RightSideFramesFrame"..i];
		initialiseSideFrame(frame, "Right");
	end
	local barstosmooth = {    -- SMOOTH HEALTH AND POWER LOSE\GAIN ANIMATION
        ALSPEC_LeftSideFramesFrame1HealthBar, ALSPEC_RightSideFramesFrame1PowerBar, ALSPEC_RightSideFramesFrame1CastBar,
        ALSPEC_LeftSideFramesFrame2HealthBar, ALSPEC_RightSideFramesFrame2PowerBar, ALSPEC_RightSideFramesFrame2CastBar,
        ALSPEC_LeftSideFramesFrame3HealthBar, ALSPEC_RightSideFramesFrame3PowerBar, ALSPEC_RightSideFramesFrame3CastBar,
        ALSPEC_TargetFrameHealthBar, ALSPEC_TargetFramePowerBar, ALSPEC_TargetFrameCastBar,
        ALSPEC_TargetTargetFrameHealthBar, ALSPEC_TargetTargetFramePowerBar, ALSPEC_TargetFrameCastBar
    }
 
    local smoothframe = CreateFrame'Frame'
    smoothing = {}
 
    local min, max = math.min, math.max
    local function AnimationTick()
        local limit = 30/GetFramerate()
        for bar, value in pairs(smoothing) do
            local cur = bar:GetValue()
            local new = cur + min((value - cur)/3, max(value - cur, limit))
            if new ~= value then new = value end
            if cur == value or abs(new - value) < 2 then
                bar:SetValue_(value)
                smoothing[bar] = nil
            else
                bar:SetValue_(new)
            end
        end
    end
 
    local function SmoothSetValue(self, value)
        local _, max = self:GetMinMaxValues()
        if value == self:GetValue() or self._max and self._max ~= max then
            smoothing[self] = nil
            self:SetValue_(value)
        else
            smoothing[self] = value
        end
        self._max = max
    end
 
    for bar, value in pairs(smoothing) do
        if bar.SetValue_ then bar.SetValue = SmoothSetValue end
    end
 
    local function SmoothBar(bar)
        if not bar.SetValue_ then
            bar.SetValue_ = bar.SetValue bar.SetValue = SmoothSetValue
        end
    end
 
    local function ResetBar(bar)
        if bar.SetValue_ then
            bar.SetValue = bar.SetValue_ bar.SetValue_ = nil
        end
    end
 
    smoothframe:SetScript('OnUpdate', function()AnimationTick()end) 
    for _, v in pairs (barstosmooth) do if v then SmoothBar(v) end end
end

function ArenaLiveSpectator:SetUpSideFrames(numPlayers)
	
	-- Enable and disable frames:
	local frame;
	for i = 1, 5 do
		if ( i <= numPlayers ) then
			frame = _G["ALSPEC_LeftSideFramesFrame"..i];
			self:UpdateSideFrameConstituents(frame);
			frame:Enable();
			frame:UpdateUnit("commentator"..i);
			frame.unit = "commentator"..i;

			frame = _G["ALSPEC_RightSideFramesFrame"..i];
			self:UpdateSideFrameConstituents(frame)
			frame:Enable();
			frame:UpdateUnit("commentator"..5+i);
			frame.unit = "commentator"..5+i;
		else
			frame = _G["ALSPEC_LeftSideFramesFrame"..i];
			frame:Disable();
			
			frame = _G["ALSPEC_RightSideFramesFrame"..i];
			frame:Disable();
		end
	end
end

function ArenaLiveSpectator:UpdateSideFrameAppearance(frame)
	if ( not frame.unit or not frame.enabled ) then
		return;
	end
	local database = ArenaLive:GetDBComponent(addonName);
	
	if ( database.HideTargetFrames and UnitIsUnit(frame.unit, "target") ) then
		if ( not frame.hasTargetSize ) then
			frame:SetSize(235, 72);
			frame.background:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\TargetFrameBackground");
			
			frame.border:SetSize(239, 75);
			frame.border:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\SideFrameTargetBorder");
			
			frame.MainTargetIndicator:SetSize(240, 79);
			frame.MainTargetIndicator:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\TargetIndicatorGlowLarge");
			
			if ( frame.group == "Left" ) then
				frame.background:SetTexCoord(0.125, 0.865234375, 0.20703125, 0.76953125);
				frame.border:SetTexCoord(0.037109375, 0.970703125, 0.22265625, 0.8046875);
				frame.MainTargetIndicator:SetTexCoord(0.0390625, 0.9765625, 0.18359375, 0.80078125);
			elseif ( frame.group == "Right" ) then
				frame.background:SetTexCoord(0.865234375, 0.125, 0.20703125, 0.76953125);
				frame.border:SetTexCoord(0.970703125, 0.037109375, 0.22265625, 0.8046875);
				frame.MainTargetIndicator:SetTexCoord(0.9765625, 0.0390625, 0.18359375, 0.80078125);
			end
			
			frame.HealthBar:SetWidth(165);
			frame.PowerBar:SetWidth(165);
		
			frame.hasTargetSize = true;
			frame:Update();
		end
	elseif ( frame.hasTargetSize ) then
		frame:SetSize(182, 72);
		frame.background:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\SideFrameBackground");
		
		frame.border:SetSize(184, 75);
		frame.border:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\SideFrameBorder");
		
		frame.MainTargetIndicator:SetSize(185, 79);
		frame.MainTargetIndicator:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\TargetIndicatorGlow");
			
		if ( frame.group == "Left" ) then
			frame.background:SetTexCoord(0.140625, 0.8515625, 0.20703125, 0.76953125);
			frame.border:SetTexCoord(0.140625, 0.859375, 0.20703125, 0.7890625);
			frame.MainTargetIndicator:SetTexCoord(0.140625, 0.865234375, 0.18359375, 0.80078125);
		elseif ( frame.group == "Right" ) then
			frame.background:SetTexCoord(0.8515625, 0.140625, 0.20703125, 0.76953125);
			frame.border:SetTexCoord(0.859375, 0.140625, 0.20703125, 0.7890625);
			frame.MainTargetIndicator:SetTexCoord(0.865234375, 0.140625, 0.18359375, 0.80078125);
		end
		
		frame.HealthBar:SetWidth(110);
		frame.PowerBar:SetWidth(110);
		
		frame.hasTargetSize = nil;
		
		frame:Update();
	end
end

function ArenaLiveSpectator:UpdateSideFrames()
	local database = ArenaLive:GetDBComponent(addonName);
	local numPlayers = database.PlayMode;
	local frame;
	
	for i = 1, numPlayers do
		frame = _G["ALSPEC_LeftSideFramesFrame"..i];
		if ( frame.enabled ) then
			frame:UpdateGUID();
			frame:Update();
		end
		
		frame = _G["ALSPEC_RightSideFramesFrame"..i];
		if ( frame.enabled ) then
			frame:UpdateGUID();
			frame:Update();
		end
	end
end

function ArenaLiveSpectator:UpdateSideFrameConstituents(frame)
	local database = ArenaLive:GetDBComponent(frame.addon, nil, frame.group);
	
	-- Update cast bar and cast history states:
	frame:ToggleHandler("CastBar");
	frame:ToggleHandler("CastHistory");
	
	-- Grow cast history upwards if castbar is disabled:
	if ( database.CastBar.Enabled ) then
		frame.CastHistory:SetSize(73, 18);
		if ( frame.group == "Left" and database.CastHistory.Direction == "UP" ) then
			database.CastHistory.Direction = "RIGHT";
		elseif ( frame.group == "Right" and database.CastHistory.Direction == "UP" ) then
			database.CastHistory.Direction = "LEFT";
		end
	else
		frame.CastHistory:SetSize(18, 73);
		if ( database.CastHistory.Direction ~= "UP" ) then
			database.CastHistory.Direction = "UP";
		end
	end
end

function ArenaLiveSpectator:UpdateAllSideFrameConstituents()
	local frame;
	for i = 1, 5 do
		frame = _G["ALSPEC_LeftSideFramesFrame"..i];
		ArenaLiveSpectator:UpdateSideFrameConstituents(frame);
		frame = _G["ALSPEC_RightSideFramesFrame"..i];
		ArenaLiveSpectator:UpdateSideFrameConstituents(frame);
	end
end