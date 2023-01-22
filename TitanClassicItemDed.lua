
-- TODO: combine from inventory to bank
-- TODO: count main bank container too

TITAN_ITEMDED_ID = "ItemDed";

---- Imported Globals
if (not TPIDCache) then TPIDCache = {} end
local TPIDCache = TPIDCache
if (not TPIDCache.Get) then TPIDCache.Get = {} end
if (not TPIDCache.OnUpdate) then TPIDCache.OnUpdate = {} end
if (not TPIDCache.OnInitFunctions) then TPIDCache.OnInitFunctions = {} end
--- Imported Globals end

local ITEMDED_WARN_THRESHOLD = 4;	-- TOOD: make an option for this:
local ITEMDED_MAX_QUALITY=8	-- Max quality of item to display in menu. 8 = Heirloom.

local L = LibStub("AceLocale-3.0"):GetLocale("TitanClassic", true)

-- Local variables
local TPID_isLoaded = false;
local TitanItemDed_ignored = {};
local TitanItemDed_droppable = {};
-- Better use at least one character that guaranteed not to appear in player name or realm name
local PlayerIdent = GetRealmName().."|"..UnitName("player");
local PlayerSettings

-- Locale BEGIN
local TPID_MENU_TEXT = "Itemized Deductions"

local TPID_TOOLTIP_TITLE = "Itemized Deductions"
local TPID_TOOLTIP_BAGS = "\nOpen bags\tClick\n"
local TPID_TOOLTIP_DESTROY = "Destroy item\tShift-click\n"
local TPID_TOOLTIP_IGNORE = "Ignore item\tDoubleclick\nAlways ignore\tAlt-Doubleclick\n\n"
local TPID_TOOLTIP_SELL = "Sell item\tShift-click\n"
local TPID_TOOLTIP_NO_ITEM = "No item"
local TPID_TOOLTIP_TOTAL = "Total"

local TPID_MENU_SELL_ALL_JUNK = "Sell all junk"
local TPID_MENU_SELL_ALL_DROPPABLE = "Sell all listed items"
local TPID_MENU_SELL_ITEM = "Sell item"
local TPID_MENU_DROP_ITEM = "Drop item"
local TPID_MENU_ALWAYS_DROPPABLE_ITEM = "Item is always droppable/sellable"
local TPID_MENU_PRICE_AUCTIONEER_BUYOUT_ITEM = "Use auctioneer buyout price for item"
local TPID_MENU_IGNORE_ITEM = "Ignore for this session"
local TPID_MENU_ALWAYS_IGNORE_ITEM = "Ignore always"
local TPID_MENU_RESET_IGNORE_LIST = "Reset current ignore list"
local TPID_MENU_RESET_ALWAYS_IGNORE_LIST = "Reset always ignore list"
local TPID_MENU_THRESHOLD = "Threshold"
local TPID_MENU_IGNORE_CLASS = "Ignore item class"
local TPID_MENU_IGNORE_POOR_IGNORE_CLASS = "Do not use ignore class for "..string.lower(ITEM_QUALITY0_DESC).." items"
local TPID_MENU_IGNORE_SOULBOUND = "Do not show "..string.lower(ITEM_SOULBOUND).." items"
local TPID_MENU_SHOW_SOULBOUND = "Always show "..string.lower(ITEM_SOULBOUND).." items"
local TPID_MENU_COMBINE_INCOMPLETE_STACKS = "Combine incomplete stacks"
local TPID_MENU_COMBINE_INCOMPLETE_STACKS_BANK = "Combine incomplete stacks in bank"
local TPID_MENU_SHOW_PANEL_PRICE = "Show item price in panel"
local TPID_MENU_SHOW_PANEL_TOTAL = "Show total price in panel"

local TPID_GSC_SEPARATOR = "."
local TPID_GSC_NONE = "none"

local TPID_MENU_CHAT_FEEDBACK = "Chat feedback"
local TPID_CHATBACK_THRESHOLD_SET="Threshold set to %s."
local TPID_CHATBACK_ERROR_PARSE_ITEM="Error parsing item link or ID."
local TPID_CHATBACK_ITEM_IGNORED = "%s is now ignored."
local TPID_CHATBACK_NOTHING_TO_IGNORE = "Nothing to ignore!"
local TPID_CHATBACK_ITEM_NOW_ALWAYS_DROPPABLE = "%s is now always droppable/sellable."
local TPID_CHATBACK_ITEM_NO_LONGER_ALWAYS_DROPPABLE = "%s is no longer always droppable/sellable."
local TPID_CHATBACK_SET_PRICE_MODE_ITEM="Price mode for %s is set to %s."
local TPID_CHATBACK_ITEM_ALWAYS_IGNORED = "%s is now always ignored."
local TPID_CHATBACK_ITEM_NO_LONGER_ALWAYS_IGNORED = "%s is no longer always ignored."
local TPID_CHATBACK_RESET_IGNORE_LIST = "Current ignored items list reset."
local TPID_CHATBACK_RESET_ALWAYS_IGNORE_LIST = "Always ignored items list reset."
local TPID_CHATBACK_ITEM1 = "item"
local TPID_CHATBACK_ITEMP = "items"
local TPID_CHATBACK_MOVED_ITEMS = "Moved %d %s."
local TPID_CHATBACK_GETMAIL_NO_MORE_ITEMS = "No more matching items in mailbox."
local TPID_CHATBACK_GETMAIL_INVENTORY_FULL = "No free space in inventory to get item from mailbox."
local TPID_CHATBACK_CLASS_NOW_IGNORED = "\"%s / %s\" items are now ignored."
local TPID_CHATBACK_CLASS_NO_LONGER_IGNORED = "\"%s / %s\" items are no longer ignored."
-- You can reverse parameters if your language needs this
-- Example:
-- local TPID_CHATBACK_ITEM_DELETED = "Deleting item with price %2$s named %1$s."
local TPID_CHATBACK_ITEM_DELETED = "Deleting %s worth %s."
local TPID_CHATBACK_NO_ITEM_TO_DESTROY = "No item to destroy."

local TPID_CUSTOM_PRICE_NA	= "N/A"
local TPID_CUSTOM_PRICE={
	auctioneer_buyout	= { short="buyout",	long="auctioneer buyout" },
	player_defined		= { short="player",	long="player defined"},
	-- used for "nil" custom price mode
	vendor			= { short="vendor",	long="vendor sell price (default, no custom price)"},
}

local TPID_CHATBACK_SETTING={
	ShowPanelPrice = {
		ON =	"Item price display in panel turned on.",
		OFF =	"Item price display in panel turned off.",
	},
	ShowPanelTotalPrice = {
		ON =	"Total price display in panel turned on.",
		OFF =	"Total price display in panel turned off.",
	},
	DontUsePoorClass = {
		ON =	"Item class settings will be ignored for "..string.lower(ITEM_QUALITY0_DESC).." items.",
		OFF =	"Item class settings will be used for all items.",
	},
	IgnoreSoulbound = {
		ON =	ITEM_SOULBOUND.." items will be ignored.",
		OFF =	ITEM_SOULBOUND.." items will be shown.",
	},
}
-- Locale END

-- ItemizedDeductions imports
-- 0 is Consumable, subclass 0 is food & drink
-- 1 is Container, Subclass 1 is Bag, it used to be soul bags
-- 2 is Weapon, Subclass 20 is Fishing Poles
-- 5 is Trade Goods, Subclass 5 is Meat
-- 6 is Miscellaneous, Subclass is junk
-- 7 is Trade Goods, subclass 0 is meat
-- 9 is Recipe, subclass 3 is engineering
-- 11 is Container, subclass 2 is bag (used to be quiver), subclass 3 is bag (used to be ammo pouches)
-- 12 is quest, subclass 0 is quest
local TPID_itemClassSubclassKnown={
	[0]={[0]={117, 118, 159, 414, 422, 724, 733, 787, 858, 929, 954, 955, 1017, 1082, 1179, 1180, 1181, 1191, 1205, 1251, 1262, 1322, 1399, 1477, 1478, 1645, 1703, 1707, 1708, 1710, 1711, 1712, 1970, 2070, 2287, 2289, 2290, 2304, 2313, 2455, 2456, 2457, 2458, 2459, 2581, 2596, 2633, 2679, 2680, 2681, 2682, 2683, 2684, 2685, 2687, 2888, 2894, 3012, 3013, 3220, 3382, 3383, 3385, 3386, 3388, 3389, 3391, 3530, 3531, 3662, 3663, 3664, 3665, 3666, 3726, 3728, 3729, 3770, 3771, 3775, 3823, 3824, 3825, 3826, 3827, 3828, 3829, 3927, 3928, 4265, 4419, 4422, 4424, 4426, 4457, 4479, 4480, 4536, 4537, 4538, 4539, 4540, 4541, 4542, 4544, 4592, 4593, 4594, 4598, 4599, 4601, 4602, 4603, 4604, 4605, 4606, 4607, 4608, 4623, 4791, 5042, 5095, 5205, 5206, 5232, 5457, 5472, 5476, 5477, 5480, 5525, 5527, 5631, 5633, 5634, 5740, 5816, 5996, 5997, 6038, 6048, 6049, 6050, 6051, 6052, 6149, 6289, 6290, 6291, 6303, 6308, 6361, 6362, 6372, 6373, 6450, 6451, 6529, 6530, 6532, 6657, 6662, 6807, 6887, 6888, 6890, 6949, 7307, 7676, 8164, 8173, 8364, 8365, 8544, 8545, 8766, 8932, 8948, 8949, 8951, 8953, 8956, 8957, 9036, 9088, 9144, 9154, 9155, 9172, 9179, 9187, 9197, 9206, 9224, 9233, 9260, 9264, 9311, 9312, 9313, 9360, 9451, 10306, 10308, 10592, 11846, 12190, 12210, 12212, 12214, 12215, 12217, 12218, 12238, 12820, 13442, 13443, 13444, 13445, 13446, 13452, 13454, 13456, 13457, 13458, 13511, 13512, 13754, 13756, 13758, 13851, 13927, 13929, 13930, 14529, 14530, 15564, 16166, 16167, 16168, 16169, 16170, 16766, 17048, 17196, 17197, 17198, 17202, 17222, 17404, 18045, 18154, 18662, 19182, 20470, 20471, 20472, 20709, 20857, 21030, 21031, 21033, 21071, 21072, 21114, 21140, 21153, 21213, 21217, 21546, 21552, 21990, 21991, 22058, 22829, 23334, 23354, 23756, 24072, 24105, 25498, 27503, 27651, 27856, 28101, 28102, 28103, 28104, 28399, 30816}},
	[1]={[1]={21340, 21341, 21342, 21872, 22243, 22244}},
	[2]={[20]={6256, 6365, 6367, 12225}},
	[5]={[0]={2665, 4470, 4471, 4611, 5116, 5140, 5529, 6265, 6358, 6359, 6370, 6371, 6452, 6453, 6470, 6471, 7067, 7068, 7069, 7070, 7071, 7072, 7075, 7076, 7077, 7078, 7079, 7080, 7081, 7082, 7972, 8168, 9060, 9061, 10286, 11291, 12803, 12808, 13422, 13423, 15420, 17020, 17030, 17031, 17032, 17033, 17034, 17035, 17036, 17037, 17038, 18512, 22147, 22456, 22575, 23571}},
	[6]={[2]={2512, 2515, 3030, 9399, 11285, 18042, 28053}, [3]={2516, 2519, 3033, 3465, 5568, 8067, 8068, 8069, 10512, 10513, 11284, 11630, 15997, 28060}},
	[7]={[0]={723, 729, 730, 731, 732, 765, 769, 783, 785, 814, 1015, 1080, 1081, 1206, 1274, 1288, 1468, 1475, 2251, 2296, 2318, 2319, 2320, 2321, 2324, 2325, 2447, 2449, 2450, 2452, 2453, 2589, 2592, 2604, 2605, 2672, 2673, 2674, 2675, 2677, 2678, 2692, 2770, 2771, 2772, 2775, 2776, 2835, 2836, 2838, 2840, 2841, 2842, 2862, 2863, 2871, 2880, 2886, 2924, 2928, 2930, 2934, 2996, 2997, 3172, 3173, 3174, 3182, 3239, 3241, 3340, 3355, 3356, 3357, 3358, 3369, 3371, 3372, 3404, 3466, 3470, 3478, 3486, 3575, 3576, 3577, 3667, 3685, 3712, 3713, 3730, 3731, 3777, 3818, 3819, 3820, 3821, 3857, 3858, 3859, 3860, 4231, 4232, 4233, 4234, 4235, 4236, 4289, 4291, 4304, 4305, 4306, 4337, 4338, 4339, 4340, 4341, 4342, 4402, 4461, 4625, 4655, 5060, 5465, 5468, 5469, 5471, 5503, 5504, 5635, 5637, 5784, 5785, 5833, 6037, 6042, 6043, 6217, 6218, 6260, 6261, 6338, 6339, 6522, 6889, 6986, 7428, 7911, 7912, 7964, 7965, 7966, 7967, 7969, 7974, 8146, 8150, 8151, 8152, 8153, 8167, 8169, 8170, 8171, 8343, 8368, 8831, 8836, 8838, 8839, 8845, 8846, 8923, 8924, 8925, 9210, 9262, 10285, 10290, 10620, 10647, 10648, 10938, 10939, 10940, 10978, 10998, 11082, 11083, 11084, 11128, 11130, 11134, 11135, 11137, 11138, 11139, 11144, 11145, 11174, 11175, 11176, 11177, 11178, 11370, 11371, 12037, 12184, 12202, 12203, 12204, 12205, 12208, 12359, 12360, 12365, 12404, 12644, 12655, 12804, 12810, 12811, 13463, 13464, 13465, 13467, 13468, 14047, 14048, 14227, 14256, 14341, 14342, 14343, 14344, 15407, 15409, 15417, 15423, 16202, 16203, 16204, 16206, 16207, 17194, 18256, 18567, 19726, 20424, 20520, 20744, 20745, 20746, 20747, 20749, 20750, 20815, 20816, 20817, 20824, 20957, 20963, 21752, 21840, 21842, 21844, 21877, 21882, 21887, 22445, 22446, 22447, 22448, 22449, 22461, 22462, 22644, 22785, 23446, 23676, 24186, 25649, 25707, 25844, 27668, 27671, 27676, 30817}},
	[9]={[3]={4408, 4409, 4410, 4412, 4414, 4416, 4417, 6716, 7561, 7742, 10601, 10603, 10604, 10606, 10609, 13308, 13309, 13310, 13311, 16041, 16043, 16046, 16048, 16050, 17720, 18648, 18649, 18650, 18652, 18655, 18656, 18661}, [6]={2553, 2555, 3394, 3395, 3832, 5640, 5642, 6053, 6056, 6211, 9293, 9294, 9295, 9296, 9298, 9300, 9301, 12958, 13476, 13478, 13490, 13491, 13492, 13495, 13496, 13499, 13520, 14634, 21547}, [8]={6342, 6344, 6347, 6348, 6349, 6375, 6377, 11038, 11039, 11081, 11098, 11101, 11150, 11151, 11152, 11163, 11164, 11165, 11166, 11167, 11202, 11203, 11204, 11205, 11206, 11207, 11208, 11225, 16215, 16218, 16220, 16221, 16223, 16224, 16243, 16246, 16248, 16251, 16252, 16255, 20752, 20753, 20758, 22539}},
	[11]={[2]={2101, 5439, 7278, 7371, 8217, 11362}, [3]={2102, 5441, 7279, 7372, 8218}},
	[12]={[0]={915, 1075, 1083, 1260, 1261, 1524, 2466, 2713, 2797, 2799, 3616, 3637, 3639, 3917, 3919, 3922, 3923, 3924, 3925, 3926, 3960, 4016, 4105, 4278, 4469, 4533, 5413, 5440, 5463, 5493, 5505, 5519, 5544, 5570, 5675, 5808, 5809, 7741, 8392, 8703, 9308, 10418, 10593, 12060, 12431, 12433, 12435, 18706, 18780, 19698, 19699, 19700, 19701, 19702, 19703, 19704, 19705, 19706, 19710, 19711, 19712, 19713, 19714, 20404, 23984, 24246}},
}

local TPID_THROTTLE=5
local TPID_lastRefreshDone=GetTime()
local TPID_copyFrame
function TPID_RefreshItem(itemID)
	-- Hammering this request seems to confuse either server or client,
	-- so we don't do it more than one time per THROTTLE seconds
	if(GetTime()-TPID_lastRefreshDone < TPID_THROTTLE) then return nil end
	if(GetItemInfo(itemID)) then return true end	-- already known
	if(not TPID_copyFrame) then
		local fromFrame=getglobal("DressUpModel")
		if(not fromFrame) then
			return nil
		end
		TPID_copyFrame=CreateFrame(fromFrame:GetObjectType(), nil, UIParent)
	end
	TPID_copyFrame:TryOn(itemID)
	TPID_lastRefreshDone=GetTime()
	return true
end

local TPID_NEED_MATCHES_GT=2
function TPID_RefreshClass(classID, subclassID)
	if(GetTime()-TPID_lastRefreshDone < TPID_THROTTLE) then return end
	for idx = 1, TPID_NEED_MATCHES_GT+1 do
		local itemID=TPID_itemClassSubclassKnown[classID][subclassID][idx]
		local _, _, _, _, _, itemClass, itemSubclass=GetItemInfo(itemID)
		-- Must be careful with IDs in itemClassSubclassKnown.
		-- Incorrect IDs can cause disconnect there.
		if(not (itemClass and itemSubclass)) then
			TPID_RefreshItem(itemID)
			-- rotate items to get more chances
			table.insert(TPID_itemClassSubclassKnown[classID][subclassID], (table.remove(TPID_itemClassSubclassKnown[classID][subclassID], idx)))
			return
		end
	end
end

-- Called once in a while from some event to see if there are
-- any classes that are not refreshed/initialized yet
-- Self-destructs when all work is done
local function TPID_PassiveInitRefreshNextClass()
	if(GetTime()-TPID_lastRefreshDone < TPID_THROTTLE) then return end
	for classID, subclassTable in pairs(TPID_itemClassSubclassKnown) do
		for subclassID in pairs(subclassTable) do
			if(TPID_itemClassSubclassKnown[classID][subclassID]) then
				return TPID_InitLocalClassName(classID, subclassID)
			end
		end
	end
	-- if we have nothing more to do, self-destruct
	TPID_PassiveInitRefreshNextClass=nil
end

local TPID_itemClassName={}
local TPID_itemClassID={}
local TPID_itemSubclassName={}
local TPID_itemSubclassID={}
function TPID_InitLocalClassName(classID, subclassID, doNotRefresh)
	-- No samples
	if((not TPID_itemClassSubclassKnown[classID]) or (not TPID_itemClassSubclassKnown[classID][subclassID])) then return nil end
	-- Already initialized
	if(TPID_itemClassName[classID] and TPID_itemClassName[classID][subclassID]) then return true end

	local className, subclassName
	if(not TPID_itemClassSubclassKnown[classID][subclassID]) then return end
	local match=0
	-- TODO: better match detection. Table of hits, maybe?
	for idx, itemID in pairs(TPID_itemClassSubclassKnown[classID][subclassID]) do
		local _, _, _, _, _, itemClass, itemSubclass=GetItemInfo(itemID)
		if(itemClass==nil or itemSubclass==nil) then
			-- Do nothing
		elseif(className==nil) then
			className=itemClass subclassName=itemSubclass match=match+1
		elseif(className==itemClass and subclassName==itemSubclass) then
			match=match+1
			if(match > TPID_NEED_MATCHES_GT) then break end
		end
	end
	if(match > TPID_NEED_MATCHES_GT) then
		if(not TPID_itemSubclassName[classID]) then TPID_itemSubclassName[classID]={} end
		if(not TPID_itemSubclassID[className]) then TPID_itemSubclassID[className]={} end
		TPID_itemClassName[classID]=className
		TPID_itemClassID[className]=classID
		TPID_itemSubclassName[classID][subclassID]=subclassName
		TPID_itemSubclassID[className][subclassName]=subclassID

		-- also save persistent cache
		local locale=GetLocale()
		if(not TPIDCacheLocal.ClassSubclassRelations[locale]) then TPIDCacheLocal.ClassSubclassRelations[locale]={} end
		if(not TPIDCacheLocal.ClassSubclassRelations[locale].ItemClassID) then TPIDCacheLocal.ClassSubclassRelations[locale].ItemClassID={} end
		if(not TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassID) then TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassID={} end
		if(not TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassID[className]) then TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassID[className]={} end
		if(not TPIDCacheLocal.ClassSubclassRelations[locale].ItemClassName) then TPIDCacheLocal.ClassSubclassRelations[locale].ItemClassName={} end
		if(not TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassName) then TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassName={} end
		if(not TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassName[classID]) then TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassName[classID]={} end
		TPIDCacheLocal.ClassSubclassRelations[locale].ItemClassID[className]=classID
		TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassID[className][subclassName]=subclassID
		TPIDCacheLocal.ClassSubclassRelations[locale].ItemClassName[classID]=className
		TPIDCacheLocal.ClassSubclassRelations[locale].ItemSubclassName[classID][subclassID]=subclassName

		-- wipe table - we no longer need it
		TPID_itemClassSubclassKnown[classID][subclassID]=nil
		-- Initialized successfully
		return true
	else
		if(not doNotRefresh) then TPID_RefreshClass(classID, subclassID) end
		-- Failed, try again later
		return false
	end
end

-- Try to init all known classes without refreshing
function TPID_InitLocalClassNameAll()
	for classID, subclassTable in pairs(TPID_itemClassSubclassKnown) do
		for subclassID in pairs(subclassTable) do
			TPID_InitLocalClassName(classID, subclassID, true)
		end
	end
	-- self-destruct
	TPID_InitLocalClassNameAll=nil
end

function TPID_GetClassSubclassID(className, subclassName)
    --TitanItemDed_Chatback("className "..className.." subclassName "..subclassName)
	if(TPID_PassiveInitRefreshNextClass) then TPID_PassiveInitRefreshNextClass() end
	local subclassTable=TPID_itemSubclassID[className]
	local classID=TPID_itemClassID[className]
	local subclassID=(subclassTable and subclassTable[subclassName] or nil)
	local locale=GetLocale()
	if((not classID) or (not subclassID)) then
		-- try cache
		local relationsTable=TPIDCacheLocal.ClassSubclassRelations[locale]
		classID=relationsTable and relationsTable.ItemClassID
		classID=classID and classID[className]
		subclassID=relationsTable and relationsTable.ItemSubclassID
		subclassID=subclassID and subclassID[className]
		subclassID=subclassID and subclassID[subclassName]
	end
	return classID, subclassID
end

function TPID_GetClassSubclassName(classID, subclassID)
	-- Previously was located in event handler. Placing it there insures that no potentially dangerous
	-- refreshes happen if GetClass* functionality is not used.
	if(TPID_PassiveInitRefreshNextClass) then TPID_PassiveInitRefreshNextClass() end
	local subclassTable=TPID_itemSubclassName[classID]
	local className=TPID_itemClassName[classID]
	local subclassName=(subclassTable and subclassTable[subclassID] or nil)
	if((not className) or (not subclassName)) then
		-- try cache
		local relationsTable=TPIDCacheLocal.ClassSubclassRelations[GetLocale()]
		className=relationsTable and relationsTable.ItemClassName
		className=className and className[classID]
		subclassName=relationsTable and relationsTable.ItemSubclassName
		subclassName=subclassName and subclassName[classID]
		subclassName=subclassName and subclassName[subclassID]
	end
	return className, subclassName
end

function TPIDCache.Get.ByID_class(itemID)
	local _, _, _, _, _, itemClass, itemSubclass=GetItemInfo(itemID)
	return TPID_GetClassSubclassID(itemClass, itemSubclass)
end

-- simplified version to find only one attribute (pattern)
function TPID_ScanTooltipPattern(pattern)
	for i=2, TPIDTooltip:NumLines(), 1 do
		local line = getglobal("TPIDTooltipTextLeft"..i):GetText()
		if (line and line == pattern) then return true end
	end
	return false
end

function TPID_TooltipScanBagItemIsSoulbound(bag, slot)
	TPIDTooltip:ClearLines()
	TPIDTooltip:SetBagItem(bag, slot)
	return TPID_ScanTooltipPattern(ITEM_SOULBOUND)
end

-- ItemizedDeductions Import end

-- localize my functions
local TitanItemDed_IsAlwaysDroppable
local TitanItemDed_IsDroppable
local TitanItemDed_InitSubMenu
local TitanItemDed_GetMail_TakeInboxItemAllStart
local TitanItemDed_GetTextGSC
local TitanItemDed_UpdateList
local TitanPanelItemDedButton_UpdateIcon
local TitanPanelItemDed_Slash
local TitanItemDed_CustomPriceMode
local TitanItemDed_GetCustomPrice

-- localize external
--local ItemDataCache=ItemDataCache
local GetItemInfo=GetItemInfo
local GetContainerNumSlots=GetContainerNumSlots
local GetContainerItemInfo=GetContainerItemInfo
local sort=sort
local match=string.match
local tonumber=tonumber

local function TitanItemDed_Chatback(str)
	if (TitanGetVar(TITAN_ITEMDED_ID, "ShowChatFeedback")) then
		DEFAULT_CHAT_FRAME:AddMessage("<ItemDed> "..str);
	end
end

local TPID_Color = {}
for idx = 0, ITEMDED_MAX_QUALITY-1 do
	local _, _, _, hex = GetItemQualityColor(idx)
	TPID_Color[idx+1]={"|c" .. hex, _G["ITEM_QUALITY"..idx.."_DESC"]}
end

function TitanItemDed_OnLoad(self)
	self.registry = {
		id = TITAN_ITEMDED_ID,
		menuText = TPID_MENU_TEXT,
		buttonTextFunction = "TitanPanelItemDedButton_GetButtonText",
		tooltipTitle = TPID_TOOLTIP_TITLE,
		tooltipTextFunction = "TitanPanelItemDedButton_GetTooltipText",
		icon = "",
		iconWidth = 16,
		category = "Information",
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowChatFeedback = 1
		}
	};

	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("BAG_UPDATE");
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	SlashCmdList["ITEMDED"] = TitanPanelItemDed_Slash
	SLASH_ITEMDED1 = "/itemded"
	SLASH_ITEMDED2 = "/tid"
	SLASH_ITEMDED3 = "/tpid"

	-- self-destruct
	TitanItemDed_OnLoad=nil
end

-- local
function TitanPanelItemDed_Slash(command)
	local command1, command2, command3=string.match(string.lower(command), "^%s*(%S+)%s*(%S*)%s*(%S*)")
	-- TitanItemDed_Chatback("C1 <"..tostring(command1).."> C2 <"..tostring(command2).."> C3 <"..tostring(command3)..">")
	if(command1=="combine" or command1=="combineall" or command1=="combineallinv" or command1=="combineinv") then
		TitanItemDed_CombineAllBags()
	elseif(command1=="combinebank" or command1=="combineallbank") then
		TitanItemDed_CombineAllBank()
	elseif(command1=="alwaysdrop" or command1=="ad") then
		if(command2=="add") then TitanItemDed_SetAlwaysDroppable(command3, 1) end
		if(command2=="remove" or command2=="del" or command2=="delete") then TitanItemDed_SetAlwaysDroppable(command3, nil) end
	elseif(command1=="alwaysignore" or command1=="alwaysignored" or command1=="ai") then
		if(command2=="add") then TitanItemDed_SetAlwaysIgnored(command3, 1) end
		if(command2=="remove" or command2=="del" or command2=="delete") then TitanItemDed_SetAlwaysIgnored(command3, nil) end
	elseif(command1=="getmail" or command1=="gm") then
		TitanItemDed_GetMail_TakeInboxItemAllStart(command2)
	else
		return
	end
	TitanItemDed_UpdateList()
	TitanPanelItemDedButton_UpdateIcon();
end

local ignorableClasses={
	{0, 0},	-- Consumables
	{5, 0},	-- Reagent
	{6, 2}, -- Projectile/Arrow
	{6, 3}, -- Projectile/Bullet
	{7, 0}, -- Trade Goods
	{12, 0},-- Quest
}

local function TitanItemDed_InitIgnorableClasses()
	local result=true
	for idx, ids in ipairs(ignorableClasses) do
		result=result and TPID_InitLocalClassName(ids[1], ids[2])
	end
	-- self-destruct if everything worked
	if(result) then TitanItemDed_InitIgnorableClasses=nil end
end

function TitanItemDed_OnEvent(self, event, ...)
	if (event == "VARIABLES_LOADED") then
		if(not TPIDCacheLocal) then TPIDCacheLocal={} end
		if(not TPIDCacheLocal.ClassSubclassRelations) then TPIDCacheLocal.ClassSubclassRelations={} end
		if(TitanItemDed_InitIgnorableClasses) then TitanItemDed_InitIgnorableClasses() end
		TitanItemDed_Init()
		TPID_isLoaded = true
		TPIDCache.isLoaded = true
		TitanItemDed_UpdateList()
		TitanPanelItemDedButton_UpdateIcon();
	end
	if (event == "PLAYER_ENTERING_WORLD") then
		if(not TPIDCacheLocal) then TPIDCacheLocal={} end
		if(not TPIDCacheLocal.ClassSubclassRelations) then TPIDCacheLocal.ClassSubclassRelations={} end
		if(TitanItemDed_InitIgnorableClasses) then TitanItemDed_InitIgnorableClasses() end
		TitanItemDed_UpdateList()
		TitanPanelItemDedButton_UpdateIcon();
	end
	if (event == "BAG_UPDATE") then
	    local arg1=...;
		if(not TPIDCacheLocal) then TPIDCacheLocal={} end
		if(not TPIDCacheLocal.ClassSubclassRelations) then TPIDCacheLocal.ClassSubclassRelations={} end
		if(TitanItemDed_InitIgnorableClasses) then TitanItemDed_InitIgnorableClasses() end
		if(arg1 <= NUM_BAG_FRAMES) then		-- Ignore bank updates
			TitanItemDed_UpdateList()
			TitanPanelItemDedButton_UpdateIcon();
		end
	end
end

------------------------------------------------------------------------------
-- Bag Search functions
------------------------------------------------------------------------------

local function TitanItemDed_GetItemIdNameFromLink(linkOrId)
	if(not linkOrId) then return nil end
	local _, itemId, itemName
	if(type(linkOrId)=="number") then
		itemId=linkOrId
	else
		itemId=tonumber(linkOrId) or tonumber(match(linkOrId, "item:(%d+)"))
		if(not itemId) then return nil end
	end
	itemName=GetItemInfo(itemId)
	if(not itemName) then return nil end

	return itemId, itemName
end

local function TitanItemDed_GetItemName(bag, slot)
	local link = C_Container.GetContainerItemLink(bag, slot)
	if(link) then
		local itemName = GetItemInfo(link)
		return itemName
	end
	return nil
end

local function TitanItemDed_GetItemId(bag, slot)
	local itemId=C_Container.GetContainerItemID(bag, slot)
	return itemId
end

local function TitanItemDed_GetQuality(bag, slot)
	local quality = C_Container.GetContainerItemInfo(bag, slot)
	if(quality) then quality = quality.quality else quality = nil end
	if(not quality) then return nil end
	if(quality == nil) then return nil end
	if(quality == -1) then
		local link = C_Container.GetContainerItemLink(bag, slot)
		if (link) then
			_, _, quality = GetItemInfo(link)
			if(quality == nil) then return nil end
			return quality+1	-- TitanItemDed indexes go from 1 (Lua convention) instead of Blizzard's 0 (C convention)
		end
		return nil
	else
		return quality+1
	end
end

-- This function checked for soul bags, ammo pouches, and quivers, all which no longer exist, so it is no longer required.
local function TitanItemDed_IsSpecialBag(bag)
	if(bag<1 or bag>11) then return nil end
	local bagInvId=C_Container.IDToInventoryID(bag)
	if(not bagInvId) then return nil end
	local bagLink=GetInventoryItemLink("player", bagInvId)
	if(not bagLink) then return nil end
	local itemClassID, itemSubClassID=TPIDCache.Get.ByID_class(bagLink)
	if(not itemClassID or not itemSubClassID) then return nil end
	--TitanItemDed_Chatback("itemClassID "..itemClassID.." itemSubClassID "..itemSubClassID)
	if(itemClassID==11 or (itemClassID==1 and itemSubClassID==1)) then
		return true
	else
		return false
	end
end

-- 3-element sized tables for reuse
-- get for unordered list:
-- local newtable if(ftnum==0) then newtable={} else newtable=ftstorage[ftnum] ftnum=ftnum-1 end
-- get for ordered list with removable tail:
-- if(not newtable) then if(ftnum==0) then newtable={} else newtable=ftstorage[ftnum] ftnum=ftnum-1 end end
-- free:
-- ftnum=ftnum+1 ftstorage[ftnum]=newtable newtable=nil
local ftstorage={}
local ftnum=0

local TitanItemDed_ItemList={ }
local TitanItemDed_ItemListSize=0
local totalPrice
local titanPanelOutdatedTooltip=false
local first, firstID, numEmpty
-- no need to track icon - it should be updated always
-- local debugUpdateNumber=1

local function TitanPanelItemDedButton_SortByPrice(a, b)
	return a[3]<b[3]
end

-- local
function TitanItemDed_UpdateList()
	-- TitanItemDed_Chatback("Scan no. "..debugUpdateNumber..".") debugUpdateNumber=debugUpdateNumber+1
	local TitanItemDed_ItemListIdx = 0;
	totalPrice=0
	numEmpty=0
	titanPanelOutdatedTooltip=true

	for bag = 0, NUM_BAG_FRAMES do
		--if (not TitanItemDed_IsSpecialBag(bag)) then
			for slot=1,C_Container.GetContainerNumSlots(bag) do
				local price = nil;
				local itemID = TitanItemDed_GetItemId(bag, slot);
				local stackCount = C_Container.GetContainerItemInfo(bag, slot);
				if(stackCount) then stackCount = stackCount.stackCount else stackCount = nil end

				if(itemID and stackCount) then
					if(TitanItemDed_CustomPriceMode(itemID)) then
						price = TitanItemDed_GetCustomPrice(C_Container.GetContainerItemLink(bag, slot))
					end
					-- fallback to vendor price if no custom price data is available
					if(not price) then _,_,_,_,_,_,_,_,_,_,price = GetItemInfo(itemID) end

					if (price) then
						price = price * stackCount
						-- CHECK: ID more efficient?
						-- UPDATE: we can't use ID, since we need to check locked status
						if(TitanItemDed_IsDroppable(bag, slot)) then
							totalPrice=totalPrice+price
							TitanItemDed_ItemListIdx=TitanItemDed_ItemListIdx+1
							-- TODO: extra lookup optimization
							-- get
							if(not TitanItemDed_ItemList[TitanItemDed_ItemListIdx]) then if(ftnum==0) then TitanItemDed_ItemList[TitanItemDed_ItemListIdx]={} else TitanItemDed_ItemList[TitanItemDed_ItemListIdx]=ftstorage[ftnum] ftnum=ftnum-1 end end
							TitanItemDed_ItemList[TitanItemDed_ItemListIdx][1] = bag
							TitanItemDed_ItemList[TitanItemDed_ItemListIdx][2] = slot
							TitanItemDed_ItemList[TitanItemDed_ItemListIdx][3] = price
						end
					end
				else
					numEmpty=numEmpty+1
				end
			end
		--end
	end

	-- cut list tail
	if(TitanItemDed_ItemListSize > TitanItemDed_ItemListIdx) then for idx=TitanItemDed_ItemListIdx+1, TitanItemDed_ItemListSize do
		-- free
		ftnum=ftnum+1 ftstorage[ftnum]=TitanItemDed_ItemList[idx] TitanItemDed_ItemList[idx]=nil
	end end
	TitanItemDed_ItemListSize=TitanItemDed_ItemListIdx

	sort(TitanItemDed_ItemList, TitanPanelItemDedButton_SortByPrice);
	first=TitanItemDed_ItemList[1]
	firstID=nil
end

-- local
function TitanPanelItemDedButton_UpdateIcon()
	-- TitanItemDed_Chatback("Regenerating button icon.")
	local button = TitanUtils_GetButton(TITAN_ITEMDED_ID, true);

	if (first) then
		local texture=C_Container.GetContainerItemInfo(first[1], first[2])
		if(texture) then texture = texture.iconFileID else texture = nil end
		button.registry.icon = texture
	else
		button.registry.icon = "";
	end
	TitanPanelButton_UpdateButton(TITAN_ITEMDED_ID);
end

-- building blocks
-- itemcolor, itemname, stackCount
local TITAN_BUTTONTEXT_BLOCK_EMPTYCOUNT=" %s(%d)"..FONT_COLOR_CODE_CLOSE
-- emptyColor, emptyNum
local TITAN_BUTTONTEXT_BLOCK_ITEM="%s[%s]"..FONT_COLOR_CODE_CLOSE.." x%d"
-- GSCPrice
local TITAN_BUTTONTEXT_BLOCK_ITEM_PRICE=" = %s"
-- GSCTotalPrice
local TITAN_BUTTONTEXT_BLOCK_TOTAL_PRICE=" {%s}"

-- itemcolor, itemname, stackCount, emptyColor, emptyNum
local TITAN_BUTTONTEXT_HAVEITEM_FORMAT=TITAN_BUTTONTEXT_BLOCK_ITEM..TITAN_BUTTONTEXT_BLOCK_EMPTYCOUNT
-- itemcolor, itemname, stackCount, GSCTotalPrice, emptyColor, emptyNum
local TITAN_BUTTONTEXT_HAVEITEM_WITH_TOTAL_FORMAT=TITAN_BUTTONTEXT_BLOCK_ITEM..TITAN_BUTTONTEXT_BLOCK_TOTAL_PRICE..TITAN_BUTTONTEXT_BLOCK_EMPTYCOUNT
-- itemcolor, itemname, stackCount, GSCPrice, emptyColor, emptyNum
local TITAN_BUTTONTEXT_HAVEITEM_WITH_PRICE_FORMAT=TITAN_BUTTONTEXT_BLOCK_ITEM..TITAN_BUTTONTEXT_BLOCK_ITEM_PRICE..TITAN_BUTTONTEXT_BLOCK_EMPTYCOUNT
-- itemcolor, itemname, stackCount, GSCTotalPrice, emptyColor, emptyNum
local TITAN_BUTTONTEXT_HAVEITEM_WITH_PRICE_WITH_TOTAL_FORMAT=TITAN_BUTTONTEXT_BLOCK_ITEM..TITAN_BUTTONTEXT_BLOCK_ITEM_PRICE..TITAN_BUTTONTEXT_BLOCK_TOTAL_PRICE..TITAN_BUTTONTEXT_BLOCK_EMPTYCOUNT
-- emptyColor, emptyNum
local TITAN_BUTTONTEXT_NOITEM_FORMAT=TPID_TOOLTIP_NO_ITEM..TITAN_BUTTONTEXT_BLOCK_EMPTYCOUNT

-- destroy building blocks
TITAN_BUTTONTEXT_BLOCK_EMPTYCOUNT=nil
TITAN_BUTTONTEXT_BLOCK_ITEM=nil
TITAN_BUTTONTEXT_BLOCK_ITEM_PRICE=nil
TITAN_BUTTONTEXT_BLOCK_TOTAL_PRICE=nil

function TitanPanelItemDedButton_GetButtonText(id)
	-- TitanItemDed_Chatback("Regenerating button text.")
	-- Those are actually Titan specific
	if (numEmpty == nil) then numEmpty = 0 end
	local emptyColor = ((numEmpty < ITEMDED_WARN_THRESHOLD) and RED_FONT_COLOR_CODE) or NORMAL_FONT_COLOR_CODE

	if (first) then
		local stackCount = C_Container.GetContainerItemInfo(first[1], first[2])
		if(stackCount) then stackCount = stackCount.stackCount else stackCount = nil end
		if(PlayerSettings.ShowPanelPrice and PlayerSettings.ShowPanelTotalPrice) then
			return format(TITAN_BUTTONTEXT_HAVEITEM_WITH_PRICE_WITH_TOTAL_FORMAT,
				TPID_Color[TitanItemDed_GetQuality(first[1], first[2])][1],
				TitanItemDed_GetItemName(first[1], first[2]),
				stackCount,
				TitanItemDed_GetTextGSC(first[3]),
				TitanItemDed_GetTextGSC(totalPrice),
				emptyColor,
				numEmpty)
			-- format end
		elseif(PlayerSettings.ShowPanelPrice) then
			return format(TITAN_BUTTONTEXT_HAVEITEM_WITH_PRICE_FORMAT,
				TPID_Color[TitanItemDed_GetQuality(first[1], first[2])][1],
				TitanItemDed_GetItemName(first[1], first[2]),
				stackCount,
				TitanItemDed_GetTextGSC(first[3]),
				emptyColor,
				numEmpty)
			-- format end
		elseif(PlayerSettings.ShowPanelTotalPrice) then
			return format(TITAN_BUTTONTEXT_HAVEITEM_WITH_TOTAL_FORMAT,
				TPID_Color[TitanItemDed_GetQuality(first[1], first[2])][1],
				TitanItemDed_GetItemName(first[1], first[2]),
				stackCount,
				TitanItemDed_GetTextGSC(totalPrice),
				emptyColor,
				numEmpty)
			-- format end
		else
			return format(TITAN_BUTTONTEXT_HAVEITEM_FORMAT,
				TPID_Color[TitanItemDed_GetQuality(first[1], first[2])][1],
				TitanItemDed_GetItemName(first[1], first[2]),
				stackCount,
				emptyColor,
				numEmpty)
			-- format end
		end
	else
		return format(TITAN_BUTTONTEXT_NOITEM_FORMAT, emptyColor, numEmpty)
	end
end

local TITAN_TOOLTIPTEXT_HEADER_DESTROY=TPID_TOOLTIP_BAGS..TPID_TOOLTIP_DESTROY..TPID_TOOLTIP_IGNORE
local TITAN_TOOLTIPTEXT_HEADER_SELL=TPID_TOOLTIP_BAGS..TPID_TOOLTIP_SELL..TPID_TOOLTIP_IGNORE
local TITAN_TOOLTIPTEXT_HEADER_NOITEM=TPID_TOOLTIP_BAGS..TPID_CHATBACK_NO_ITEM_TO_DESTROY
-- priceMode, itemcolor, itemname, stackCount, GSCPrice
local TITAN_TOOLTIPTEXT_ITEMENTRY_FORMAT="%s%s[%s]"..FONT_COLOR_CODE_CLOSE.." x%d\t%s\n"
local titanTooltipText
local function TitanPanelItemDedButton_RegenerateTooltipText()
	-- TitanItemDed_Chatback("Regenerating tooltip.")
	if(not first) then titanTooltipText=TITAN_TOOLTIPTEXT_HEADER_NOITEM return end
	-- TODO: benchmark what's better - table generation or growing string (I suspect former is better)
	local items=""

	for idx, entry in ipairs(TitanItemDed_ItemList) do
		local itemLink = C_Container.GetContainerItemLink(entry[1], entry[2])
		local itemID, itemName = TitanItemDed_GetItemIdNameFromLink(itemLink)
		local customPriceMode = TitanItemDed_CustomPriceMode(itemID)
		local customPrice, customPriceTag
		if(customPriceMode) then
			-- TitanItemDed_Chatback(customPriceTag.." "..tostring(customPrice))
			customPrice=TitanItemDed_GetCustomPrice(itemLink)
			customPriceTag="("..(customPrice and "" or (TPID_CUSTOM_PRICE_NA.." "))..TPID_CUSTOM_PRICE[customPriceMode].short..") "
		end
		local stackCount = C_Container.GetContainerItemInfo(entry[1], entry[2])
		if(stackCount) then stackCount = stackCount.stackCount else stackCount = nil end
		items = items..format(TITAN_TOOLTIPTEXT_ITEMENTRY_FORMAT,
			(customPriceTag or ""),
			TPID_Color[TitanItemDed_GetQuality(entry[1], entry[2])][1],
			itemName,
			stackCount,
			TitanItemDed_GetTextGSC(customPrice or entry[3]))
		-- format end
	end
	titanTooltipText=(MerchantFrame:IsVisible() and TITAN_TOOLTIPTEXT_HEADER_SELL or TITAN_TOOLTIPTEXT_HEADER_DESTROY)..items.."\n"..TPID_TOOLTIP_TOTAL..":\t"..TitanItemDed_GetTextGSC(totalPrice)
end

local titanPanelPrevMerchantTootltip=false
function TitanPanelItemDedButton_GetTooltipText()
	if(MerchantFrame:IsVisible() ~= titanPanelPrevMerchantTootltip) then titanPanelOutdatedTooltip=true end
	titanPanelPrevMerchantTootltip=MerchantFrame:IsVisible()
	if(titanPanelOutdatedTooltip) then TitanPanelItemDedButton_RegenerateTooltipText() titanPanelOutdatedTooltip=false end
	return titanTooltipText
end

local function TitanItemDed_InitSettingsVar(var, value)
	if(PlayerSettings[var] == nil) then PlayerSettings[var] = value end
end

function TitanItemDed_Init()
	-- Hook in ItemDataCache updates
	-- local oldItemDataCacheOnUpdateByID_selltovendor=ItemDataCache.OnUpdate.ByID_selltovendor
	-- ItemDataCache.OnUpdate.ByID_selltovendor=function() TitanItemDed_UpdateList() TitanPanelItemDedButton_UpdateIcon() return oldItemDataCacheOnUpdateByID_selltovendor() end

	if (TitanItemDedSettings == nil) then TitanItemDedSettings = {}	end
	if (TitanItemDedSettings[PlayerIdent] == nil) then TitanItemDedSettings[PlayerIdent] = {} end
	if(not TPIDCacheLocal) then TPIDCacheLocal={} end
	if(not TPIDCacheLocal.ClassSubclassRelations) then TPIDCacheLocal.ClassSubclassRelations={} end
	TPID_InitLocalClassNameAll()
	PlayerSettings=TitanItemDedSettings[PlayerIdent]
	TitanItemDed_InitSettingsVar("Ignored", {})
	TitanItemDed_InitSettingsVar("IgnoredClass", {})
	TitanItemDed_InitSettingsVar("Droppable", {})
	TitanItemDed_InitSettingsVar("CustomPrice", {})
	TitanItemDed_InitSettingsVar("Threshold", 1)

	TitanItemDed_InitSubMenu()

	TitanItemDed_UpdateList()
	TitanPanelItemDedButton_UpdateIcon();

	return;
end

function TitanItemDed_Listman(cmd)
	local act = (type(cmd) == "table") and cmd.value or cmd
	
	-- IDless/linkless commands
	if (act == "r") then
		TitanItemDed_ignored = {};
		TitanItemDed_Chatback(TPID_CHATBACK_RESET_IGNORE_LIST);
	elseif (act == "ra") then
		TitanItemDed_ignored = {};
		PlayerSettings.Ignored = {};
		TitanItemDed_Chatback(TPID_CHATBACK_RESET_ALWAYS_IGNORE_LIST);
	end

	if(first and not firstID) then firstID = TitanItemDed_GetItemId(first[1], first[2]) end
	local firstLink
	if(first) then firstLink=C_Container.GetContainerItemLink(first[1], first[2]) end

	if (act == "t") then
		if first then
			if (MerchantFrame:IsVisible()) then
				C_Container.UseContainerItem(first[1], first[2]);
			else
				local firstStack=C_Container.GetContainerItemInfo(first[1], first[2])
				if(firstStack) then firstStack = firstStack.stackCount else firstStack = nil end
				if(firstStack>1) then firstLink=firstLink.." x"..firstStack end
				TitanItemDed_Chatback(format(TPID_CHATBACK_ITEM_DELETED, firstLink, TitanItemDed_GetTextGSC(first[3])));
				C_Container.PickupContainerItem(first[1], first[2])
				DeleteCursorItem();
			end
		else
			TitanItemDed_Chatback(TPID_CHATBACK_NO_ITEM_TO_DESTROY);
		end
	elseif (act == "i") then
		if first then
			TitanItemDed_ignored[firstID] = 1
			TitanItemDed_Chatback(format(TPID_CHATBACK_ITEM_IGNORED, firstLink));
		else TitanItemDed_Chatback(TPID_CHATBACK_NOTHING_TO_IGNORE); end
	elseif (act == "ia") then
		if first then
			TitanItemDed_SetAlwaysIgnored(firstID, 1)
		else TitanItemDed_Chatback(TPID_CHATBACK_NOTHING_TO_IGNORE); end
	elseif (act == "tad") then
		-- no item check. This only should be called from menu when item is present.
		-- no simple toggle. We need "nil" to actually clear and remove table entry from saved vars.
		if(TitanItemDed_IsAlwaysDroppable(firstID)) then
			TitanItemDed_SetAlwaysDroppable(firstID, nil)
		else
			TitanItemDed_SetAlwaysDroppable(firstID, 1)
		end
	elseif (act == "auctioneer_buyout") then
		-- no item check. This only should be called from menu when item is present.
		-- With third argument set to true function works as toggle.
		-- If you set custom price to same mode again it clears it.
		TitanItemDed_SetCustomPriceMode(firstLink, "auctioneer_buyout", true)
	end

	TitanItemDed_UpdateList()
	TitanPanelItemDedButton_UpdateIcon();
end

local function TitanItemDed_CombineAllBags() return TitanItemDed_CombineAll(false) end
local function TitanItemDed_CombineAllBank() return TitanItemDed_CombineAll(false, NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS+1) end

-- Cache once generated buttons
local itemDedDropDownMenuButtons={}
function TPID_MenuButton(button, ...)
	local newButton
	if(itemDedDropDownMenuButtons[button]) then newButton=itemDedDropDownMenuButtons[button]
	else
		if(button==TPID_MENU_SELL_ALL_JUNK) then newButton={
			func = TitanItemDed_SellAll,
			arg1 = TitanItemDed_SellCheckJunk,
		} elseif(button==TPID_MENU_SELL_ALL_DROPPABLE) then newButton={
			func = TitanItemDed_SellAll,
			arg1 = TitanItemDed_SellCheckDroppableStandard,
		} elseif(button==TPID_MENU_SELL_ITEM) then newButton={
			func = TitanItemDed_Listman,
			value = "t",
		} elseif(button==TPID_MENU_DROP_ITEM) then newButton={
			func = TitanItemDed_Listman,
			value = "t",
		} elseif(button==TPID_MENU_IGNORE_ITEM) then newButton={
			func = TitanItemDed_Listman,
			value = "i",
		} elseif(button==TPID_MENU_ALWAYS_IGNORE_ITEM) then newButton={
			func = TitanItemDed_Listman,
			value = "ia",
		} elseif(button==TPID_MENU_ALWAYS_DROPPABLE_ITEM) then newButton={
			func = TitanItemDed_Listman,
			value = "tad",
		} elseif(button==TPID_MENU_PRICE_AUCTIONEER_BUYOUT_ITEM) then newButton={
			func	= TitanItemDed_Listman,
			value	= "auctioneer_buyout",
		} elseif(button==TPID_MENU_COMBINE_INCOMPLETE_STACKS) then newButton={
			func	= TitanItemDed_CombineAllBags,
		} elseif(button==TPID_MENU_COMBINE_INCOMPLETE_STACKS_BANK) then newButton={
			func	= TitanItemDed_CombineAllBank,
		} elseif(button==TPID_MENU_RESET_IGNORE_LIST) then newButton={
			func = TitanItemDed_Listman,
			value = "r",
		} elseif(button==TPID_MENU_RESET_ALWAYS_IGNORE_LIST) then newButton={
			func = TitanItemDed_Listman,
			value = "ra",
		} elseif(button==TPID_MENU_THRESHOLD) then newButton={
			value = button,
			hasArrow = 1,
		} elseif(button==TPID_MENU_IGNORE_CLASS) then newButton={
			value = button,
			hasArrow = 1,
		} elseif(button==TPID_MENU_IGNORE_POOR_IGNORE_CLASS) then newButton={
			func = TitanItemDed_ToggleSetting,
			arg1 = "DontUsePoorClass",
			keepShownOnClick = 1,
--		} elseif(button==TPID_MENU_SHOW_SOULBOUND) then newButton={
--			func	= TitanItemDed_CombineAllBank,
		} elseif(button==TPID_MENU_IGNORE_SOULBOUND) then newButton={
			func = TitanItemDed_ToggleSetting,
			arg1 = "IgnoreSoulbound",
			keepShownOnClick = 1,
		} elseif(button==TPID_MENU_SHOW_PANEL_PRICE) then newButton={
			func = TitanItemDed_ToggleSetting,
			arg1 = "ShowPanelPrice",
			keepShownOnClick = 1,
		} elseif(button==TPID_MENU_SHOW_PANEL_TOTAL) then newButton={
			func = TitanItemDed_ToggleSetting,
			arg1 = "ShowPanelTotalPrice",
			keepShownOnClick = 1,
		} elseif(button==TPID_MENU_CHAT_FEEDBACK) then newButton={
			func = TitanToggleVar,
			arg1 = TITAN_ITEMDED_ID,
			arg2 = "ShowChatFeedback",
			keepShownOnClick = 1,
		} end
		if(not newButton) then return nil end
		newButton.text=button
	end
	local attribute, value=...
	if(attribute) then newButton[attribute]=value end
	itemDedDropDownMenuButtons[button]=newButton
	return newButton
end

local thresholdLevelButton={}
local ignorableClassButton={}
function TitanItemDed_InitSubMenu()
	for i=1,ITEMDED_MAX_QUALITY do thresholdLevelButton[i]={
		text = TPID_Color[i][1]..TPID_Color[i][2],
		value = i,
		func = TitanItemDed_SetThreshold,
	} end
	for idx, ids in ipairs(ignorableClasses) do
		local className, subClassName=TPID_GetClassSubclassName(ids[1], ids[2])
		if(className and subClassName) then table.insert(ignorableClassButton, {
			text = className.." / "..subClassName,
			func = TitanItemDed_ToggleIgnoreItemClass,
			arg1 = ids[1],
			arg2 = ids[2],
		}) end
	end
end

function TitanPanelRightClickMenu_PrepareItemDedMenu()
	if (not TPID_isLoaded) then return; end

	if (_G["L_UIDROPDOWNMENU_MENU_LEVEL"] == 2) then
		local button
		if(_G["L_UIDROPDOWNMENU_MENU_VALUE"]==TPID_MENU_THRESHOLD) then
			for i=1,ITEMDED_MAX_QUALITY do
				button = thresholdLevelButton[i]
				button.checked = (PlayerSettings.Threshold == i)
				L_UIDropDownMenu_AddButton(button, _G["L_UIDROPDOWNMENU_MENU_LEVEL"])
			end
		elseif(_G["L_UIDROPDOWNMENU_MENU_VALUE"]==TPID_MENU_IGNORE_CLASS) then
			for idx, ids in ipairs(ignorableClasses) do
				button = ignorableClassButton[idx]
				if(button) then
					button.checked = (PlayerSettings.IgnoredClass[ids[1]] and PlayerSettings.IgnoredClass[ids[1]][ids[2]])
					L_UIDropDownMenu_AddButton(button, _G["L_UIDROPDOWNMENU_MENU_LEVEL"])
				end
			end
		end
		return
	end

	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_ITEMDED_ID].menuText);
	TitanPanelRightClickMenu_AddSpacer();

	-- Only show those if we have an item
	if(TitanItemDed_ItemList[1]) then
		if (MerchantFrame:IsVisible()) then
			L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_SELL_ALL_JUNK))
			L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_SELL_ALL_DROPPABLE))
		end

		L_UIDropDownMenu_AddButton(TPID_MenuButton(MerchantFrame:IsVisible() and TPID_MENU_SELL_ITEM or TPID_MENU_DROP_ITEM))
		TitanPanelRightClickMenu_AddSpacer();

		L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_IGNORE_ITEM))
		L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_ALWAYS_IGNORE_ITEM))
		TitanPanelRightClickMenu_AddSpacer()

		if(not firstID) then firstID = TitanItemDed_GetItemId(first[1], first[2]) end

		L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_ALWAYS_DROPPABLE_ITEM, "checked", TitanItemDed_IsAlwaysDroppable(firstID)))
		L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_PRICE_AUCTIONEER_BUYOUT_ITEM, "checked", (TitanItemDed_CustomPriceMode(firstID)=="auctioneer_buyout")))
		TitanPanelRightClickMenu_AddSpacer();
	end

	local combineSection=false

	if(TitanItemDed_CombineAll(true)) then
		L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_COMBINE_INCOMPLETE_STACKS))
		combineSection=true
	end
	if(TitanItemDed_CombineAll(true, NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS+1)) then
		L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_COMBINE_INCOMPLETE_STACKS_BANK))
		combineSection=true

	end
	if(combineSection) then TitanPanelRightClickMenu_AddSpacer() end

	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_RESET_IGNORE_LIST))
	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_RESET_ALWAYS_IGNORE_LIST))
	TitanPanelRightClickMenu_AddSpacer();

	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_THRESHOLD))
	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_IGNORE_CLASS))
	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_IGNORE_POOR_IGNORE_CLASS, "checked", PlayerSettings.DontUsePoorClass))
	-- L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_SHOW_SOULBOUND))
	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_IGNORE_SOULBOUND, "checked", PlayerSettings.IgnoreSoulbound))
	TitanPanelRightClickMenu_AddSpacer();

	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_SHOW_PANEL_PRICE, "checked", PlayerSettings.ShowPanelPrice))
	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_SHOW_PANEL_TOTAL, "checked", PlayerSettings.ShowPanelTotalPrice))
	L_UIDropDownMenu_AddButton(TPID_MenuButton(TPID_MENU_CHAT_FEEDBACK, "checked", TitanGetVar(TITAN_ITEMDED_ID, "ShowChatFeedback")))
	TitanPanelRightClickMenu_AddToggleIcon(TITAN_ITEMDED_ID);
    TitanPanelRightClickMenu_AddToggleLabelText(TITAN_ITEMDED_ID);
	TitanPanelRightClickMenu_AddSpacer();

	TitanPanelRightClickMenu_AddCommand(L["TITAN_PANEL_MENU_HIDE"], TITAN_ITEMDED_ID, TITAN_PANEL_MENU_FUNC_HIDE);
end

function TitanItemDed_ToggleSetting(self,setting)
	PlayerSettings[setting]=(not PlayerSettings[setting]) and true or nil
	TitanItemDed_Chatback(PlayerSettings[setting] and TPID_CHATBACK_SETTING[setting].ON or TPID_CHATBACK_SETTING[setting].OFF)
	TitanItemDed_UpdateList()
	TitanPanelItemDedButton_UpdateIcon()
end

function TitanItemDed_OnClick(self,button)
	if (button == "LeftButton") then
		if(IsShiftKeyDown()) then
			TitanItemDed_Listman("t");
		else
			OpenAllBags();
		end
	end
end

function TitanItemDed_OnDoubleClick(self,button)
	if (button == "LeftButton") then
		if(IsAltKeyDown()) then
			TitanItemDed_Listman("ia");
		else
			TitanItemDed_Listman("i");
		end
	end
end

function TitanItemDed_SetThreshold(self)
	PlayerSettings.Threshold = self.value;
	TitanItemDed_Chatback(format(TPID_CHATBACK_THRESHOLD_SET, TPID_Color[self.value][1]..TPID_Color[self.value][2].."|r"));
	TitanItemDed_UpdateList()
	TitanPanelItemDedButton_UpdateIcon()
	HideDropDownMenu(_G["L_UIDROPDOWNMENU_MENU_LEVEL"]-1)
end

function TitanItemDed_AuctioneerFound()
	if (Auctioneer and Auctioneer.Util and Auctioneer.Util.GetAuctionKey and
	    Auctioneer.ItemDB and Auctioneer.ItemDB.CreateItemKeyFromLink and
	    Auctioneer.HistoryDB and Auctioneer.HistoryDB.GetItemTotals) then
		-- AFAIR it is not possible to unload those, so cache the result
		TitanItemDed_AuctioneerFound=function() return true end
		return true
	end
	-- auctioneer not loaded/not found
	return false
end

function TitanItemDed_GetAuctioneerPrice(itemLink, ...)
	if(not TitanItemDed_AuctioneerFound()) then return false end

	local mode=... or "buyout"
	local ahKey = Auctioneer.Util.GetAuctionKey();
	local itemKey = Auctioneer.ItemDB.CreateItemKeyFromLink(itemLink);
	local itemTotals = Auctioneer.HistoryDB.GetItemTotals(itemKey, ahKey);
	if (itemTotals == nil or itemTotals.seenCount == 0) then
		-- never seen at auction
		return nil
	end

	local bidPrice, buyPrice, marketPrice, warn = Auctioneer.Statistic.GetSuggestedResale(itemKey, ahKey, 1)
	if(mode=="buyout") then return buyPrice end
	return nil
end

------------------------------------------------------------------------------
-- Mass selling
------------------------------------------------------------------------------

function TitanItemDed_SellCheckJunk(bag, slot)
	local qual = TitanItemDed_GetQuality(bag, slot);
	return (qual and qual == 1)
end

function TitanItemDed_SellCheckDroppableStandard(bag, slot)
	return (TitanItemDed_IsDroppable(bag, slot) and (not TitanItemDed_CustomPriceMode(TitanItemDed_GetItemId(bag, slot))))
end

function TitanItemDed_SellAll(self, checkFunction)
	for bag=0,NUM_BAG_FRAMES do
		for slot=1,C_Container.GetContainerNumSlots(bag) do
			if (checkFunction(bag, slot)) then
				if (MerchantFrame:IsVisible()) then
					C_Container.UseContainerItem(bag, slot);
				else
					return nil
				end
			end
		end
	end
	TitanItemDed_UpdateList()
	TitanPanelItemDedButton_UpdateIcon()
end

local foundIncomplete={}
local rememberStackCount={}
-- /script TitanItemDed_CombineAll(false)
-- /script TitanItemDed_CombineAll(false, NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS)
function TitanItemDed_CombineAll(checkOnly, firstBag, lastBag, dontShowZero)
	if(not firstBag) then firstBag, lastBag = 0, NUM_BAG_FRAMES end
	local moved, left = 0, 0
	local moreWork=false
	-- wipe tables
	-- the only place where memory savings COULD decrease speed slightly
	for idx, val in pairs(foundIncomplete) do
		for idx2, val2 in pairs(val) do
			ftnum=ftnum+1 ftstorage[ftnum]=val2
			val[idx2]=nil
		end
		ftnum=ftnum+1 ftstorage[ftnum]=val
		foundIncomplete[idx]=nil
	end
	for idx, val in pairs(rememberStackCount) do
		rememberStackCount[idx]=nil
	end
	-- TitanItemDed_Chatback("Size1 "..#foundIncomplete)
	-- TitanItemDed_Chatback("Size2 "..#rememberStackCount)
	-- scan in reverse direction to make incomplete stacks stay first, so
	-- they will be either used up or at least won't make CombineAll think
	-- that it is time to CombineAll again, because first use of item would
	-- take it from full stack
	for bag = lastBag, firstBag, -1 do
		-- Also check BANK_CONTAINER that "conviently" located before all container bags
		local realbag
		if(bag == NUM_BAG_SLOTS+NUM_BANKBAGSLOTS+1) then realbag=BANK_CONTAINER else realbag=bag end
		-- TitanItemDed_Chatback("Bag: "..realbag)
		for slot=C_Container.GetContainerNumSlots(realbag),1,-1 do
			local itemCount = C_Container.GetContainerItemInfo(realbag, slot)
			if(itemCount) then itemCount = itemCount.stackCount else itemCount = nil end
			local locked = C_Container.GetContainerItemInfo(realbag, slot)
			if(locked) then locked = locked.isLocked else locked = nil end
			if(locked) then moreWork=true end
			if(itemCount and not locked) then
				local itemStackCount
				local itemID=TitanItemDed_GetItemId(realbag, slot)
				_, _, _, _, _, _, _, itemStackCount=GetItemInfo(itemID)
				if(itemStackCount > 1 and itemCount ~= itemStackCount) then
					if(checkOnly) then
						if(rememberStackCount[itemID]) then return true end
						rememberStackCount[itemID] = true
					else
						if(not foundIncomplete[itemID]) then foundIncomplete[itemID]={} end
						if(#foundIncomplete[itemID] > 0) then
							rememberStackCount[itemID] = itemStackCount
						end
						-- get
						local newtable if(ftnum==0) then newtable={} else newtable=ftstorage[ftnum] ftnum=ftnum-1 end
						newtable[1]=realbag
						newtable[2]=slot
						newtable[3]=itemCount
						table.insert(foundIncomplete[itemID], newtable)
					end
				end
			end
		end
	end
	if(checkOnly) then return nil end
	for itemID, itemStackCount in pairs(rememberStackCount) do
		local bestNum, bestFirstIdx, bestSecondIdx
		local foundIncompleteItem=foundIncomplete[itemID]
		local foundIncompleteItemStacks=#foundIncompleteItem
		while(foundIncompleteItemStacks > 1) do
			bestNum=0
			for firstIdx = 1, foundIncompleteItemStacks-1 do
				for secondIdx = firstIdx+1, foundIncompleteItemStacks do
					local resultStack=foundIncompleteItem[firstIdx][3]+foundIncompleteItem[secondIdx][3]
					if(resultStack>itemStackCount) then resultStack=1 end
					if(resultStack>bestNum) then bestNum=resultStack bestFirstIdx=firstIdx bestSecondIdx=secondIdx end
					if(resultStack==itemStackCount) then break end
				end
			end
			C_Container.SplitContainerItem(foundIncompleteItem[bestSecondIdx][1], foundIncompleteItem[bestSecondIdx][2], foundIncompleteItem[bestSecondIdx][3])
			C_Container.PickupContainerItem(foundIncompleteItem[bestFirstIdx][1], foundIncompleteItem[bestFirstIdx][2])
			-- free
			ftnum=ftnum+1 ftstorage[ftnum]=foundIncompleteItem[bestFirstIdx]
			ftnum=ftnum+1 ftstorage[ftnum]=foundIncompleteItem[bestSecondIdx]
			table.remove(foundIncompleteItem, bestSecondIdx)
			table.remove(foundIncompleteItem, bestFirstIdx)
			moved=moved+1
			foundIncompleteItemStacks=#foundIncompleteItem
		end
	end
	if(not(dontShowZero and moved==0)) then TitanItemDed_Chatback(format(TPID_CHATBACK_MOVED_ITEMS, moved, (moved == 1 and TPID_CHATBACK_ITEM1 or TPID_CHATBACK_ITEMP))) end
	TitanItemDed_UpdateList()
	TitanPanelItemDedButton_UpdateIcon()
	return moreWork and (moved~=0 and moved or false)
end

function TitanItemDed_ToggleIgnoreItemClass(itemClassID, itemSubClassID)
	TitanItemDed_SetIgnoreItemClass(itemClassID, itemSubClassID, (not (PlayerSettings.IgnoredClass[itemClassID] and PlayerSettings.IgnoredClass[itemClassID][itemSubClassID])) and 1 or nil)
	HideDropDownMenu(_G["L_UIDROPDOWNMENU_MENU_LEVEL"]-1)
end

function TitanItemDed_SetIgnoreItemClass(itemClassID, itemSubClassID, ignore)
	local className, subClassName=TPID_GetClassSubclassName(itemClassID, itemSubClassID)
	if(not className or (not subClassName)) then return nil end
	if(not PlayerSettings.IgnoredClass[itemClassID]) then PlayerSettings.IgnoredClass[itemClassID]={} end
	PlayerSettings.IgnoredClass[itemClassID][itemSubClassID]=ignore
	if(ignore) then
		TitanItemDed_Chatback(format(TPID_CHATBACK_CLASS_NOW_IGNORED, className, subClassName))
	else
		TitanItemDed_Chatback(format(TPID_CHATBACK_CLASS_NO_LONGER_IGNORED, className, subClassName))
	end
	TitanItemDed_UpdateList()
	TitanPanelItemDedButton_UpdateIcon()
end

-- GUI/slash command is now in, but you still can do it manually:
-- Add: /script TitanItemDed_SetAlwaysDroppable(2862, 1) -- 2862 == rough sharpening stone, 1 == do sell/drop
-- Remove: /script TitanItemDed_SetAlwaysDroppable(2862, nil) -- 2862 == rough sharpening stone, nil == remove table entry
function TitanItemDed_SetAlwaysDroppable(item, value)
	local itemId=TitanItemDed_GetItemIdNameFromLink(item)
	if(not itemId) then TitanItemDed_Chatback(TPID_CHATBACK_ERROR_PARSE_ITEM) return nil end
	PlayerSettings.Droppable[itemId] = value
	local _, itemLink=GetItemInfo(itemId)
	if(value) then
		TitanItemDed_Chatback(format(TPID_CHATBACK_ITEM_NOW_ALWAYS_DROPPABLE, itemLink));
	else
		TitanItemDed_Chatback(format(TPID_CHATBACK_ITEM_NO_LONGER_ALWAYS_DROPPABLE, itemLink))
	end
end

function TitanItemDed_SetAlwaysIgnored(item, value)
	local itemId=TitanItemDed_GetItemIdNameFromLink(item)
	if(not itemId) then TitanItemDed_Chatback(TPID_CHATBACK_ERROR_PARSE_ITEM) return nil end
	PlayerSettings.Ignored[itemId] = value
	local _, itemLink=GetItemInfo(itemId)
	if(value) then
		TitanItemDed_Chatback(format(TPID_CHATBACK_ITEM_ALWAYS_IGNORED, itemLink));
	else
		TitanItemDed_Chatback(format(TPID_CHATBACK_ITEM_NO_LONGER_ALWAYS_IGNORED, itemLink))
	end
end

function TitanItemDed_SetCustomPriceMode(itemLink, priceMode, ...)
	local toggle=...
	local itemId, itemName=TitanItemDed_GetItemIdNameFromLink(itemLink)
	if(not itemId) then TitanItemDed_Chatback(TPID_CHATBACK_ERROR_PARSE_ITEM) return nil end
	local currentMode=TitanItemDed_CustomPriceMode(itemId)
	if(toggle and currentMode and (priceMode==currentMode)) then
		return TitanItemDed_SetCustomPriceMode(itemId, nil)
	end
	PlayerSettings.CustomPrice[itemId]=priceMode
	if(type(priceMode)=="number") then priceMode="player_defined" end
	if(type(priceMode)=="nil") then priceMode="vendor" end
	local _, itemRealLink=GetItemInfo(itemId)
	TitanItemDed_Chatback(format(TPID_CHATBACK_SET_PRICE_MODE_ITEM, itemRealLink, TPID_CUSTOM_PRICE[priceMode].long))
end

-- local
function TitanItemDed_CustomPriceMode(itemId)
	if (TitanItemDedSettings == nil) then TitanItemDedSettings = {}	end
	if (TitanItemDedSettings[PlayerIdent] == nil) then TitanItemDedSettings[PlayerIdent] = {} end
	if (PlayerSettings == nil) then PlayerSettings=TitanItemDedSettings[PlayerIdent] end
	local priceMode=PlayerSettings.CustomPrice[itemId]
	if(type(priceMode)=="number") then return "player_defined" end
	return priceMode
end

-- local
function TitanItemDed_GetCustomPrice(itemLink, ...)
	local priceMode=...
	local itemId, itemName=TitanItemDed_GetItemIdNameFromLink(itemLink)
	if(not itemId) then TitanItemDed_Chatback(TPID_CHATBACK_ERROR_PARSE_ITEM) return nil end
	priceMode=priceMode or TitanItemDed_CustomPriceMode(itemId)
	if(priceMode=="auctioneer_buyout") then return TitanItemDed_GetAuctioneerPrice(itemLink, "buyout") end
	return nil
end

-- local
function TitanItemDed_IsAlwaysDroppable(item)
	local itemId, itemName=TitanItemDed_GetItemIdNameFromLink(item)
	if(not itemId) then TitanItemDed_Chatback(TPID_CHATBACK_ERROR_PARSE_ITEM) return nil end
	return PlayerSettings.Droppable[itemId]
end

-- local
function TitanItemDed_IsDroppable(bag, slot)
	local locked = C_Container.GetContainerItemInfo(bag, slot)
	if(locked) then locked = locked.isLocked else locked = nil end
	if(locked) then return false end
	local itemId = TitanItemDed_GetItemId(bag, slot);
	if (not itemId) then return false end
	if TitanItemDed_droppable[itemId] then return true end
	if TitanItemDed_ignored[itemId] then return false end
	if PlayerSettings.Ignored[itemId] then return false end
	if PlayerSettings.Droppable[itemId] then return true end
	local quality=TitanItemDed_GetQuality(bag, slot)
	if ((not quality) or (quality > PlayerSettings.Threshold)) then return false end
	if(quality==1 and PlayerSettings.DontUsePoorClass) then return true end
	if(PlayerSettings.IgnoreSoulbound and TPID_TooltipScanBagItemIsSoulbound(bag, slot)) then return false end
	local _, _, _, _, _, itemClass, itemSubClass=GetItemInfo(itemId)
	local itemClassID, itemSubClassID=TPID_GetClassSubclassID(itemClass, itemSubClass)
	if(itemClassID and itemSubClassID) then
		local classIgnored=PlayerSettings.IgnoredClass[itemClassID]
		classIgnored=classIgnored and classIgnored[itemSubClassID]
		if(classIgnored) then return false end
	end
	return true
end

-------------------------------------------------------------------------------
-- Gold formatting code, shamelessly "borrowed" from Auctioneer no longer
-------------------------------------------------------------------------------

function TitanItemDed_GetGSC(money)
	if (money == nil) then return 0, 0, 0 end
	local g = math.floor(money / 10000);
	local s = math.floor((money - (g*10000)) / 100);
	local c = math.floor(money - (g*10000) - (s*100));
	return g,s,c;
end

local GSC_GOLD="ffd100";
local GSC_SILVER="e6e6e6";
local GSC_COPPER="c8602c";
local GSC_PART_PRE="|cff";
local GSC_FIRST_PART_POST="%d|r";
local GSC_PART_POST="%02d|r";

local GSC_FULL_G   = GSC_PART_PRE..GSC_GOLD..GSC_FIRST_PART_POST
local GSC_FULL_S   = GSC_PART_PRE..GSC_SILVER..GSC_FIRST_PART_POST
local GSC_FULL_C   = GSC_PART_PRE..GSC_COPPER..GSC_FIRST_PART_POST
local GSC_FULL_SC  = GSC_FULL_S..TPID_GSC_SEPARATOR..GSC_PART_PRE..GSC_COPPER..GSC_PART_POST
local GSC_FULL_GSC = GSC_FULL_G..TPID_GSC_SEPARATOR..GSC_PART_PRE..GSC_SILVER..GSC_PART_POST..TPID_GSC_SEPARATOR..GSC_PART_PRE..GSC_COPPER..GSC_PART_POST
local GSC_FULL_GS  = GSC_FULL_G..TPID_GSC_SEPARATOR..GSC_PART_PRE..GSC_SILVER..GSC_PART_POST
local GSC_FULL_GC  = GSC_FULL_G..TPID_GSC_SEPARATOR..GSC_PART_PRE..GSC_COPPER..GSC_PART_POST

GSC_GOLD=nil
GSC_SILVER=nil
GSC_COPPER=nil
GSC_PART_PRE=nil
GSC_FIRST_PART_POST=nil
GSC_PART_POST=nil

local GSC_NONE="|cffa0a0a0"..TPID_GSC_NONE.."|r";

-- local
function TitanItemDed_GetTextGSC(money)
	if(not money or money==0) then return GSC_NONE end
	if(money<100) then return format(GSC_FULL_C, money) end

	local g, s, c = TitanItemDed_GetGSC(money)

	if(g==0) then return format((c==0 and GSC_FULL_S or GSC_FULL_SC), s, c) end
	if(c==0) then return format((s==0 and GSC_FULL_G or GSC_FULL_GS), g, s) end
	return (s==0 and format(GSC_FULL_GC, g, c) or format(GSC_FULL_GSC, g, s, c))
end

-------------------------------------------------------------------------
-- GetMail
-------------------------------------------------------------------------

-- MAIL_INBOX_UPDATE

local GetMail_frame = CreateFrame("Frame");

local GetMail_updateInterval=0.1
local GetMail_leaveEmpty=1

local GetMail_lastBoxActionTime=GetTime()
local GetMail_inTransit
local GetMail_currentJob

-- local functions
local TitanItemDed_GetMail_StopJob
local TitanItemDed_GetMail_TakeInboxItemOnce

local function TitanItemDed_GetMail_OnUpdate(elapsed)
	-- TitanItemDed_Chatback("CJ "..tostring(GetMail_currentJob).." IT "..tostring(GetMail_inTransit))
	if(not GetMail_currentJob or GetMail_inTransit) then return end
	-- TitanItemDed_Chatback("Got job")
	local now=GetTime()
	if(now-GetMail_lastBoxActionTime<GetMail_updateInterval) then return end
	GetMail_lastBoxActionTime=now
	local itemFound=TitanItemDed_GetMail_TakeInboxItemOnce(condtion)
	if(not itemFound) then TitanItemDed_GetMail_StopJob(TPID_CHATBACK_GETMAIL_NO_MORE_ITEMS) end
end

local function TitanItemDed_GetMail_OnEvent(event, ...)
    local arg1=...;
	if(GetMail_inTransit) then
		local moreWork=TitanItemDed_CombineAll(false, nil, nil, true)
		if (not moreWork) then
			GetMail_inTransit=false
			if(numEmpty<=GetMail_leaveEmpty) then TitanItemDed_GetMail_StopJob(TPID_CHATBACK_GETMAIL_INVENTORY_FULL) end
		end
	end
end
GetMail_frame:SetScript("OnEvent", TitanItemDed_GetMail_OnEvent)

-- local
function TitanItemDed_GetMail_TakeInboxItemAllStart(condition)
	-- TitanItemDed_Chatback("Starting work on <"..condition..">.")
	GetMail_currentJob=TitanItemDed_GetItemIdNameFromLink(condition)
	GetMail_frame:SetScript("OnUpdate", TitanItemDed_GetMail_OnUpdate)
	GetMail_frame:RegisterEvent("BAG_UPDATE")
end

-- local
function TitanItemDed_GetMail_StopJob(message)
	TitanItemDed_Chatback(message)
	GetMail_currentJob=nil
	GetMail_frame:UnregisterEvent("BAG_UPDATE");
	GetMail_frame:SetScript("OnUpdate", nil)
end

-- local
function TitanItemDed_GetMail_TakeInboxItemOnce(condition)
	for idx=1, GetInboxNumItems() do
		-- packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(index);
		local idxItemLink=GetInboxItemLink(idx)
		if(idxItemLink) then
			local idxItemID=TitanItemDed_GetItemIdNameFromLink(idxItemLink)
			-- TitanItemDed_Chatback("MGOnUpdate: "..idx.." "..idxItemID)
			if(idxItemID==GetMail_currentJob) then
				TakeInboxItem(idx)
				GetMail_inTransit=true
				return true
			end
		end
	end
	return false
end

-- Endless mail grab:
-- If zero space and not locked inventory - break
-- OnUpdate if not GetMail_inTransit take item, set GetMail_inTransit
-- OnBagUpdate stack all, clear GetMail_inTransit
-- Repeat until no more items
