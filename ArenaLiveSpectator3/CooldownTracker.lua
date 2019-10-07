local addonName, L = ...;

local DEFAULT_CD_TRACKER_HEIGHT = 35;
local DEFAULT_CD_TRACKER_Y_OFFSET = 7;

local COOLDOWN_TRACKER_BORDER_SIZES = {
	["DIVIDED"] = {
		[1] = {403, 64},
		[2] = {403, 106},
		[3] = {403, 148},
		[5] = {403, 230},
	},
	["UNITED"] = {
		["Left"] = {
			[1] = {403, 64},
			[2] = {403, 106},
			[3] = {403, 148},
			[5] = {403, 230},
		},
		["Right"] = {
			[1] = {403, 64},
			[2] = {403, 106},
			[3] = {403, 148},
			[5] = {403, 230},
		},
	},
};
local COOLDOWN_TRACKER_BORDER_TEX_COORDS = {
	["DIVIDED"] = {
		[1] = {0.1064453125, 0.8935546875, 0.037109375, 0.330859375},
		[2] = {0.1064453125, 0.8935546875, 0.037109375, 0.451171875},
		[3] = {0.1064453125, 0.8935546875, 0.037109375, 0.615234375},
		[5] = {0.1064453125, 0.8935546875, 0.037109375, 0.935546875},
	},
	["UNITED"] = {
		["Left"] = {
			[1] = {0, 0.7802734375, 0.07421875, 0.39484375},
			[2] = {0, 0.7802734375, 0.07421875, 0.51953125},
			[3] = {0, 0.7802734375, 0.07421875, 0.68359375},
			[5] = {0, 0.7802734375, 0.07421875, 0.97265625},
		},
		["Right"] = {
			[1] = {0, 0.7861328125, 0.07421875, 0.39484375},
			[2] = {0, 0.7861328125, 0.07421875, 0.51953125},
			[3] = {0, 0.7861328125, 0.07421875, 0.68359375},
			[5] = {0, 0.7861328125, 0.07421875, 0.97265625},
		},
	},
};

local COOLDOWN_TRACKER_GLOW_TEX_COORDS = {
	["Left"] = {
		[1] = {0.125, 0.8740234375, 0.052734375, 0.316374440},
		[2] = {0.125, 0.8740234375, 0.052734375, 0.435546875},
		[3] = {0.125, 0.8740234375, 0.052734375, 0.599609375},
		[5] = {0.125, 0.8740234375, 0.052734375, 0.927734375},
	},
	["Right"] = {
		[1] = {0.8740234375, 0.125, 0.052734375, 0.316374440},
		[2] = {0.8740234375, 0.125, 0.052734375, 0.435546875},
		[3] = {0.8740234375, 0.125, 0.052734375, 0.599609375},
		[5] = {0.8740234375, 0.125, 0.052734375, 0.927734375},
	},
};

local function OnPositionUpdate(tracker)
	local point, relativeTo, relativePoint, xOffset, yOffset = tracker.classIcon:GetPoint();
	tracker.classIcon:ClearAllPoints();
	yOffset = (DEFAULT_CD_TRACKER_HEIGHT - 26) / 2;
	tracker.classIcon:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
	
	point, relativeTo, relativePoint, xOffset = tracker.nameText:GetPoint();
	tracker.nameText:ClearAllPoints();
	tracker.nameText:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
end

local function initialiseSingleTracker(tracker, group)
	local prefix = tracker:GetName();
	local id = tracker:GetID();
	tracker.OnPositionUpdate = OnPositionUpdate;
	ArenaLive:ConstructHandlerObject(tracker, "CooldownTracker", _G[prefix.."Name"], _G[prefix.."ClassIcon"], addonName, group, "ALSPEC_CooldownTrackerIconTemplate");
end

function ArenaLiveSpectator:InitialiseCooldownTracker()
	local database = ArenaLive:GetDBComponent(addonName);
	local r, g, b = unpack(database.TeamA.Colour);
	
	ALSPEC_CDTrackersLeftGlow:SetVertexColor(r, g, b, 0.3);
	r, g, b = unpack(database.TeamB.Colour);
	ALSPEC_CDTrackersRightGlow:SetVertexColor(r, g, b, 0.3);
	for i = 1, 5 do
		local tracker = _G["ALSPEC_CDTrackersLeftTracker"..i];
		initialiseSingleTracker(tracker, "Left");
		
		tracker = _G["ALSPEC_CDTrackersRightTracker"..i];
		initialiseSingleTracker(tracker, "Right");
	end
end

function ArenaLiveSpectator:SetUpCooldownTracker(numPlayers)
	
	local database = ArenaLive:GetDBComponent(addonName);
	
	-- Enable and disable trackers:
	local tracker;
	for i = 1, 5 do
		if ( i <= numPlayers ) then
			tracker = _G["ALSPEC_CDTrackersLeftTracker"..i];
			tracker:Enable();
			tracker:UpdateUnit("commentator"..i);
			tracker = _G["ALSPEC_CDTrackersRightTracker"..i];
			tracker:Enable();
			tracker:UpdateUnit("commentator"..5+i);
		else
			tracker = _G["ALSPEC_CDTrackersLeftTracker"..i];
			tracker:Disable();
			
			tracker = _G["ALSPEC_CDTrackersRightTracker"..i];
			tracker:Disable();
		end
	end
	
	-- Set Height of Cooldowntracker:
	local height = 21; -- Base height ( 14 pixel offset to top and 7 bottom of the frame)
	height = height + ( DEFAULT_CD_TRACKER_HEIGHT * numPlayers ) + ( DEFAULT_CD_TRACKER_Y_OFFSET * ( numPlayers - 1 ) );
	ALSPEC_CDTrackersLeft:SetHeight(height);
	ALSPEC_CDTrackersRight:SetHeight(height);
	
	-- Set Anchors according to player number:
	ALSPEC_CDTrackersLeft:ClearAllPoints();
	ALSPEC_CDTrackersRight:ClearAllPoints();
	
	-- Fix cooldowns button
	local CogwheelIcon = [[Interface\HELPFRAME\HelpIcon-CharacterStuck]]--[[Interface\Scenarios\ScenarioIcon-Interact]]
	local FixCooldownFrame = CreateFrame('Button','FixCooldownFrame',ALSPEC_CDTrackersLeft)
	FixCooldownFrame:SetSize(40,40)
	hooksecurefunc(ALSPEC_CDTrackersLeftHeader,'SetPoint',function()
		if database.HideTargetFrames then
			FixCooldownFrame:SetPoint('RIGHT',ALSPEC_CDTrackersLeftHeader,-45,15)
		else
			FixCooldownFrame:SetPoint('RIGHT',ALSPEC_CDTrackersLeftHeader,152,0)
		end
	end)
	FixCooldownFrame:SetFrameStrata'LOW'
	FixCooldownFrame:SetFrameLevel(FixCooldownFrame:GetFrameLevel()+2)
	FixCooldownFrame:RegisterForClicks'AnyUp'
	FixCooldownFrame:SetScript('OnClick',function(self,button)
		if button == 'LeftButton' then
			FixCooldownFrames()
		else
			ReloadUI()
		end
	end)
	FixCooldownFrame.__icon = FixCooldownFrame:CreateTexture(nil,"BACKGROUND")
	FixCooldownFrame.__icon:SetTexture(CogwheelIcon)
	FixCooldownFrame.__icon:SetAllPoints()

	if ( numPlayers > 3 or database.HideTargetFrames ) then
		
		-- Left CD Tracker:
		ALSPEC_CDTrackersLeft:SetPoint("BOTTOMRIGHT", self, "BOTTOM", 0, 0);
		
		ALSPEC_CDTrackersLeftHeader:ClearAllPoints();
		ALSPEC_CDTrackersLeftHeader:SetPoint("CENTER", ALSPEC_CDTrackersLeftBorder, "TOPRIGHT", -10, -6);
		
		ALSPEC_CDTrackersLeftBorder:SetSize(unpack(COOLDOWN_TRACKER_BORDER_SIZES["UNITED"]["Left"][database.PlayMode]));
		ALSPEC_CDTrackersLeftBorder:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\CooldownTrackerLeftBorder");
		ALSPEC_CDTrackersLeftBorder:SetTexCoord(unpack(COOLDOWN_TRACKER_BORDER_TEX_COORDS["UNITED"]["Left"][database.PlayMode]));
		
		ALSPEC_CDTrackersLeftGlow:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\CooldownTrackerLargeGlow");
		ALSPEC_CDTrackersLeftGlow:SetTexCoord(unpack(COOLDOWN_TRACKER_GLOW_TEX_COORDS["Left"][database.PlayMode]));
		
		-- Right CD Tracker:
		ALSPEC_CDTrackersRight:SetPoint("BOTTOMLEFT", self, "BOTTOM", 0, 0);
		
		ALSPEC_CDTrackersRightHeader:Hide();
		
		ALSPEC_CDTrackersRightBorder:SetSize(unpack(COOLDOWN_TRACKER_BORDER_SIZES["UNITED"]["Right"][database.PlayMode]));
		ALSPEC_CDTrackersRightBorder:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\CooldownTrackerRightBorder");
		ALSPEC_CDTrackersRightBorder:SetTexCoord(unpack(COOLDOWN_TRACKER_BORDER_TEX_COORDS["UNITED"]["Right"][database.PlayMode]));
		
		ALSPEC_CDTrackersRightGlow:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\CooldownTrackerLargeGlow");
		ALSPEC_CDTrackersRightGlow:SetTexCoord(unpack(COOLDOWN_TRACKER_GLOW_TEX_COORDS["Right"][database.PlayMode]));
	else
		
		-- Left CD Tracker:
		ALSPEC_CDTrackersLeft:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -260, 0);

		ALSPEC_CDTrackersLeftHeader:ClearAllPoints();
		ALSPEC_CDTrackersLeftHeader:SetPoint("CENTER", ALSPEC_CDTrackersLeftBorder, "TOP", -2, -6);
		
		ALSPEC_CDTrackersLeftBorder:SetSize(unpack(COOLDOWN_TRACKER_BORDER_SIZES["DIVIDED"][database.PlayMode]));
		ALSPEC_CDTrackersLeftBorder:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\CooldownTrackerSingleBorder");
		ALSPEC_CDTrackersLeftBorder:SetTexCoord(unpack(COOLDOWN_TRACKER_BORDER_TEX_COORDS["DIVIDED"][database.PlayMode]));
		
		ALSPEC_CDTrackersLeftGlow:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\CooldownTrackerSingleGlow");
		ALSPEC_CDTrackersLeftGlow:SetTexCoord(unpack(COOLDOWN_TRACKER_GLOW_TEX_COORDS["Left"][database.PlayMode]));
		
		-- Right  CD Tracker:
		ALSPEC_CDTrackersRight:SetPoint("BOTTOMLEFT", self, "BOTTOM", 260, 0);
		
		ALSPEC_CDTrackersRightHeader:Show();
		
		ALSPEC_CDTrackersRightBorder:SetSize(unpack(COOLDOWN_TRACKER_BORDER_SIZES["DIVIDED"][database.PlayMode]));
		ALSPEC_CDTrackersRightBorder:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\CooldownTrackerSingleBorder");
		ALSPEC_CDTrackersRightBorder:SetTexCoord(unpack(COOLDOWN_TRACKER_BORDER_TEX_COORDS["DIVIDED"][database.PlayMode]));
		
		ALSPEC_CDTrackersRightGlow:SetTexture("Interface\\AddOns\\ArenaLiveSpectator3\\Textures\\CooldownTrackerSingleGlow");
		ALSPEC_CDTrackersRightGlow:SetTexCoord(unpack(COOLDOWN_TRACKER_GLOW_TEX_COORDS["Right"][database.PlayMode]));
	end
	
end

function ArenaLiveSpectator:UpdateCooldownTrackers()
	local database = ArenaLive:GetDBComponent(addonName);
	local numPlayers = database.PlayMode;
	local frame;
	
	for i = 1, numPlayers do
		frame = _G["ALSPEC_CDTrackersLeftTracker"..i];
		if ( frame.enabled ) then
			frame:Update();
		end
		
		frame = _G["ALSPEC_CDTrackersRightTracker"..i];
		if ( frame.enabled ) then
			frame:Update();
		end
	end
end