-- ============================================================================
-- MH-MOD                                                 for World of Warcraft
-- == Version information (do not modify) =====================================
local sEmpty                  = "";    -- Null string (const)
local Version                 = {      -- You're not nice if you change these
  Name        = "MhMod",        Author = "Mhat",
  Release     = 23,             Extra = sEmpty,
  Website     = "github.com/mhatxotic",
  WebsiteFull = "https://github.com/mhatxotic/mhmod"
};
-- Player data ----------------------------------------------------------------
local sMyName                 = sEmpty; -- Current player name
local sMyRealm                = sEmpty; -- Current realm name
local sMyNameRealm            = sEmpty; -- Current name-realm name
local bAutoClearAFKDisabled   = false; -- Clear AFK was disabled by us
local nAwayFromKeyboard       = 0;     -- Away from keyboard time (0=not afk)
local nDoNotDisturb           = 0;     -- Do not disturb time (0=not dnd)
local nCombatTime             = 0;     -- In combat? (0=not ic)
local nChatLogLastPruned      = 0;     -- Time the chat logs were pruned
local bInDuel                 = false; -- Currently in duel status
local iIgnorePartyMessage     = 0;     -- Counter to ignore party message
local iLastChannelMsgId       = -1;    -- Stop pointless event recursions
local sLastInstance           = sEmpty; -- Last instance entered
local bLoading                = true;  -- Player on loading screen
local bLowHealth          = GetTime(); -- Time player was low on health
local bLowMana            = GetTime(); -- Time player was low on mana
local bPassingOnLoot          = false; -- Addon has set pass-on-loot?
local iSessionStart          = time(); -- Time the character logged in
local bTradeDisabled          = false; -- Trade was disabled by this addon
local bTradeStartedByMe       = false; -- Trade was started by client
local iBNWhisperReplySent     = 0;     -- Ignore own BN whispers counter
local iWhisperReplySent       = 0;     -- Ignore own whispers counter
local iItemLevel              = -1;    -- Equipped item level
-- Honour data ----------------------------------------------------------------
local iHonour                 = 0;     -- Honour points
local iHonourGainsLeft        = 0;     -- Honour gains left till next level
local iHonourLevel            = 0;     -- Honour level
local iHonourLeft             = 0;     -- Honour points left till next level
local iHonourMax              = 0;     -- Honour maximum to next level
local iHonourSession          = 0;     -- Honour gained this session
local iHonourLastGain         = 0;     -- Honour points gained last
-- Experience data ------------------------------------------------------------
local iLevel                  = 0;     -- Player level
local iCurrentXP              = 0;     -- Current XP
local iXPGainsLeft            = 0;     -- Number of gains left to level
local iXPLeft                 = 0;     -- XP needed to level
local iXPMax                  = 0;     -- XP total needed to level
local iXPSession              = 0;     -- XP gathered this session
local iXPLastGain             = 0;     -- Last XP gain
-- Money ----------------------------------------------------------------------
local iMoney                  = 0;     -- Current money
local iMoneySession           = 0;     -- Money gained this session
local MoneyData;                       -- Money statistical data
-- Other data storage ---------------------------------------------------------
local EventsData;                      -- Global event hooks
local UnitEventsData;                  -- Unit events data
local FrameEventHookData;              -- Blizzard frames event hooks
local FunctionHookData;                -- Blizzard function hooks
local LocalCommandsData;               -- Contains /mh commands data
local RemoteCommandsData;              -- Contains !mh commands data
-- Persistant data aliases ----------------------------------------------------
local BestStatsData;                   -- Alias of 'mhstats.BS'
local ConfigNewData;                   -- New options detected at start up
local ConfigBooleanData;               -- Alias of 'mhconfig.boolean'
local ConfigDynamicData;               -- Alias to 'mhconfig.dynamic'
-- Frames data ----------------------------------------------------------------
local MhMod;                           -- Main MhMod frames
local MenuEditBoxFrame;                -- Generic menu edit box frame
local PetManaBarFrames        = { };   -- Party pet mana bar frames
-- Dynamic storage ------------------------------------------------------------
local ArchaeologyData         = { };   -- Archaeology data
local AutoMsgData             = { };   -- DND/AFK message anti-spam data
local BagData                 = { };   -- Bags data
local BagsData                = { };   -- Individual bags data
local BGData                  = { };   -- Battleground data
local BGScoresData            = { };   -- Battleground scores data
local CalendarEventsData      = { };   -- Calendar events data
local CommandThrottleData     = { };   -- Public command system flood control
local CurrencyData            = { };   -- Currency data
local EquipData               = { };   -- Strip/dress commands
local FactionData             = { };   -- Faction (Reputation) data
local FriendsData             = { };   -- Friends data array
local GroupBGData             = { };   -- Battleground group and raid data
local GroupData               = { };   -- Realm group and raid data
local PrintData               = { };   -- Smoothed print data
local InstanceData            = { };   -- Saved instances data
local LastNewMail             = { };   -- New mail data
local MapPingerData           = { };   -- Map ping flood control
local MirrorTimerData         = { };   -- Countdown timers (breath, etc.)
local QuestData               = { };   -- Quests data
local RealmMoneyData;                  -- Money statistical data of all chars
local TextFloodData           = { };   -- Player text flood control
local TimerData               = { };   -- Timers
local WhisperData             = { };   -- Contains all whisper times
local WhisperExemptData       = { };   -- Players recently whispered
local GuildData;                       -- Guild member data
-- Other data -----------------------------------------------------------------
local OldChatInputTexture     = { };   -- Self explanitory
local OldChatTabTexture       = { };   -- Self explanitory
-- Cached commonly used settings. We can't do them all unfortunately ----------
local bStatsBests             = false; -- Announce best stats
local bStatsReset             = false; -- Reset stats on combat
local bStatsInstance          = false; -- Reset stats at instance start
local bStatsInBG              = false; -- Collect stats in battleground
local bStatsEnabled           = false; -- Collect stats
local bBarTimers              = false; -- Show bar timers
local bActionCounts           = false; -- Show action bar counts
local bActionFades            = false; -- Fade action buttons
local bMapCoords              = false; -- Map co-ordinates enabled
local bShowDps                = false; -- Show damage per second
-- Function Prototypes --------------------------------------------------------
local SlashFunc;                       -- Slash command function
local BlockTrades;                     -- Set block trades
local ClampNumber;                     -- Clamp number between min/max
local ClickDialogButton;               -- Synthesis a dialogue button click
local CommandExists;                   -- Specified command exists
local CreateBlankGroupArray;           -- Create blank group data template
local CreateTimer;                     -- Create a timer
local FindPartySlot;                   -- Find unit id for player name
local GetDurability;                   -- Get equipped items durability
local GetDynSetting;                   -- Get dynamic setting
local GetFreeBagSpaces;                -- Get free bag spaces
local GetGroupData;                    -- Get current group data
local GetInstanceName;                 -- Get instance name
local GetNearestUnit;                  -- Close to specified unit
local GetQuestLinkFromName;            -- Get a quest link from specified name
local GetTimer;                        -- Get info about a timer
local GetUnitInfo;                     -- Get info about unit
local GetVersion;                      -- Get version information
local HudMessage;                      -- Show hud message
local IsBegger;                        -- Text is begging
local IsFlooding;                      -- Player name is flooding
local IsInBattleground;                -- Player is in battleground
local IsPublicSpam;                    -- Is public spam
local IsSpam;                          -- Text is spam
local KillTimer;                       -- Kill a timer
local Log;                             -- Log message
local MakeCountdown;                   -- Make a countdown timer from integer
local MakeLocationString;              -- Make a player location string
local MakePlayerLink;                  -- Make player link for chat
local MakeMoneyReadable;               -- Make money readable
local MakePrettyIcon;                  -- Make a pretty icon (for chat)
local MakePrettyName;                  -- Make a pretty name (for chat)
local StripRealmFromName               -- Strip realm from name
local MakeQuestPrettyName;             -- Make a pretty quest name (for chat)
local MakeQuestPrettyNameId;           -- Make a pretty quest name (for chat)
local MakeTime;                        -- Make a time from integer
local OneOrBoth;                       -- Return one or both ("Current/Max")
local FormatNumber;                    -- Makes a prettier number
local PassOnLoot;                      -- Set pass on loot
local Print;                           -- Print message
local ProcessTextString;               -- Process a text string
local RegisterSpamComplaint;           -- Register spam complaint
local RoundNumber;                     -- Round a number
local SendChat;                        -- Send chat message
local SendWhisper;                     -- Send whisper
local SendResponse;                    -- Send response to an operation
local SetDynSetting;                   -- Set dynamic setting
local SettingEnabled;                  -- Setting is enabled
local ShowDelayedWhispers;             -- Show delayed whispers to client
local ShowDialog;                      -- Show main dialog
local ShowInput;                       -- Show input message box
local ShowMsg;                         -- Show a generic message box
local ShowPasteMenu;                   -- Show paste text menu
local ShowQuestion;                    -- Show question message box
local ShowURL;                         -- Show a URL copy message box
local SortedPairs;                     -- Sorted pairs()
local StatsClear;                      -- Clear stats database
local StatsSet;                        -- Set data in statistics database
local StringToColour;                  -- Convert a string to a colour code
local StripColour;                     -- Strip colour from text
local TableSize;                       -- Return size of a keystring table
local TriggerTimer;                    -- Trigger a created timer
local UnitFrameUpdate;                 -- Update unit frame
local UnitIsFriend;                    -- Specified unit is a friend
local UpdateGroupTrackData;            -- Update group tracker data
local UserIsMe;                        -- User is me
local UserIsExempt;                    -- User name is exempt from blocks
local UserIsIgnored;                   -- Unit name is in ignore list
local UserIsInGuild;                   -- Unit name is in your guild
local UserIsOfficer;                   -- Unit name is an officer of guild
local VariableExists;                  -- Specified variable exists
local DebugTable;                      -- Debug a table
local HandleChatEvent;                 -- Handles chat events
local BAnd                 = bit.band; -- Alias
local CreateMenuItem;                  -- Menu item creation helper
local WhisperIsDelayed;                -- Whisper is delayed?
local ShouldSendWhisper;               -- Should reply to whisper?
-- Initialisation data. Tells if data has been downloaded yet -----------------
local InitsData = {                    -- Inits data structure
  Bags                       = false;  -- Bags initialised?
  Money                      = false;  -- Money initialised?
  XP                         = false;  -- Experience initialised?
  Artefact                   = false;  -- Artifact initialised?
  Archaeology                = false;  -- Archaeology initialised?
  BGScores                   = false;  -- Battleground scores initialised?
  Friends                    = false;  -- Friends list initialised?
  Guild                      = false;  -- Guild roster initialised (x2)?
  Interface                  = false;  -- Entire user interface initialised?
  Party                      = false;  -- Party data initialised?
  Played                     = false;  -- Playtime updated?
  Quests                     = false;  -- Quest data initialised?
  Raid                       = false;  -- Raid data initialised?
};
-- Bags to enumerate on bag update event --------------------------------------
local BagUpdateData = { -2, 0, 1, 2, 3, 4, 5 };
-- Money data valid values for verifiying database ---------------------------
local ValidMoneyValues = {
  nIncSec    = 0, nIncMin    = 0, nIncHr     = 0, nIncTotal    = 0,
  nIncDay    = 0, nIncWk     = 0, nIncMon    = 0, nIncYr       = 0,
  nIncSesSec = 0, nIncSesMin = 0, nIncSesHr  = 0, nIncSesTotal = 0,
  nIncSesDay = 0, nIncSesWk  = 0, nIncSesMon = 0, nIncSesYr    = 0,
  nExpSesSec = 0, nExpSesMin = 0, nExpSesHr  = 0, nExpSesTotal = 0,
  nExpSesDay = 0, nExpSesWk  = 0, nExpSesMon = 0, nExpSesYr    = 0,
  nExpSec    = 0, nExpMin    = 0, nExpHr     = 0, nExpTotal    = 0,
  nExpDay    = 0, nExpWk     = 0, nExpMon    = 0, nExpYr       = 0,
  nTotal     = 0, nTimeSes   = 0, nTimeStart = 0, nTotal       = 0,
};
-- Tooltip unit classification types data -------------------------------------
local UnitClassificationTypesData = {
  normal    = { C=0x000000, F=0x00, N=sEmpty },
  elite     = { C=0xFFCC00, F=0x01, N="Elite" },
  worldboss = { C=0xFF2F2F, F=0x11, N="Boss" },
  rare      = { C=0x6666FF, F=0x02, N="Rare" },
  rareelite = { C=0xAAAAFF, F=0x03, N="Rare Elite" },
  trivial   = { C=0x00FF00, F=0x04, N="Trivial" },
  minus     = { C=0x777777, F=0x08, N="Minion" }
};
-- Statistics categories data ------------------------------------------------
local StatsCatsData = {
  D    = { SD="Deaths Dealt",                  LD="The number of killing blows that the shown players had landed" },
  DT   = { SD="Deaths Received",               LD="The number times the shown players had died" },
  MA   = { SD="Melee Absorbs Dealt",           LD="The number of times a melee hit from the shown players was absorbed by an enemy target" },
  MAT  = { SD="Melee Absorbs Received",        LD="The number of times the players shown absorbed a melee attack from an enemy target" },
  MB   = { SD="Melee Blocks Dealt",            LD="The number of times a melee attack from the shown players was blocked by an enemy target" },
  MBT  = { SD="Melee Blocks Received",         LD="The number of times a melee hit was blocked by the shown players from an enemy target" },
  MC   = { SD="Melee Criticals Dealt",         LD="The number of times a critical hit from a melee attack by the shown players landed on an enemy target" },
  MCT  = { SD="Melee Criticals Received",      LD="The number of times a melee attack criticall hit the shown players from an enemy target" },
  MCR  = { SD="Melee Crushes Dealt",           LD="The number of crushing blows the players shown landed on enemy targets" },
  MCRT = { SD="Melee Crushes Received",        LD="The number of times the players shown received a crushing blow from a melee attack" },
  MD   = { SD="Melee Damage Dealt",            LD="The amount of melee (white) damage that the players shown had dealt to enemy targets" },
  MDT  = { SD="Melee Damage Received",         LD="The amount of melee (white) damage that the players shown recieved" },
  MG   = { SD="Melee Glances Dealt",           LD="The number of galcing blows the players shown landed on enemy targets" },
  MGT  = { SD="Melee Glances Received",        LD="The number of times the players shown received a glancing blow from a melee attack" },
  MH   = { SD="Melee Hits Dealt",              LD="The number of times the players shown landed a successful melee attack" },
  MHT  = { SD="Melee Hits Received",           LD="The number of times a melee attack from an enemy target hit the players shown" },
  MM   = { SD="Melee Misses Dealt",            LD="The number of times a melee attack from the shown players was avoided by the enemy target" },
  MMT  = { SD="Melee Misses Received",         LD="The number of times the shown players avoided a melee attack from an enemy target" },
  RA   = { SD="Ranged Absorbs Dealt",          LD="The number of times a ranged attack from the players shown was absorbed by an enemy target" },
  RAT  = { SD="Ranged Absorbs Received",       LD="The number of times the players shown absorbed a ranged attack from an enemy target" },
  RC   = { SD="Ranged Criticals Dealt",        LD="The number of times a ranged critical hit was dealt by the players shown" },
  RCT  = { SD="Ranged Criticals Received",     LD="The number of ranged critical hits the players shown received from an enemy target" },
  RD   = { SD="Ranged Damage Dealt",           LD="The amount of damage dealt by ranged attacks from the shown players" },
  RDT  = { SD="Ranged Damage Received",        LD="The amount of damage received from ranged attacks by enemy targets to the shown players" },
  RH   = { SD="Ranged Hits Dealt",             LD="The number of times a ranged attack successfully hit an enemy target by the players shown" },
  RHT  = { SD="Ranged Hits Received",          LD="The number of times a ranged attack hit from an enemy target hit the players shown" },
  RM   = { SD="Ranged Misses Dealt",           LD="The number of ranged attacks from the players shown that missed an enemy target" },
  RMT  = { SD="Ranged Misses Received",        LD="The number of ranged attacks from an enemy target that missed the players shown" },
  SA   = { SD="Skill Absorbs Dealt",           LD="The number of times a skill or spell cast from the players shown was absorbed by an enemy target" },
  SAT  = { SD="Skill Absorbs Received",        LD="The number of times the players shown absorbed an attack by a skill or spell cast" },
  SC   = { SD="Skill Criticals Dealt",         LD="The number of times the players shown landed a critical hit with a skill or spell" },
  SCT  = { SD="Skill Criticals Received",      LD="The number of times the players shown were critically hit by a skill or spell from an enemy target" },
  SD   = { SD="Skill Damage Dealt",            LD="The amount of damage dealt by the players shown using a skill or spell cast to an enemy target" },
  SDT  = { SD="Skill Damage Taken",            LD="The amount of damage the players shown had taken by a skill or spell cast from an enemy target" },
  SDP  = { SD="Skill Dispels Dealt",           LD="The number of buffs the player shown has removed" },
  SDPT = { SD="Skill Dispels Received",        LD="The number of buffs or debuffs removed from the players shown" },
  SFD  = { SD="Skill Failed Dispels Dealt",    LD="The number of failed attempts to remove a buff by the players shown to their designated target" },
  SFDT = { SD="Skill Failed Dispels Received", LD="The number of failed attempts to remove a buff from the players shown by enemy targets" },
  SH   = { SD="Skill Healing Dealt",           LD="The amount of healing done by the players shown" },
  SHT  = { SD="Skill Healing Received",        LD="The amount of healing the players shown has received" },
  SHC  = { SD="Skill Heal Criticals Dealt",    LD="The number of critical heals the players shown landed on others" },
  SHCT = { SD="Skill Heal Criticals Received", LD="The number of critical heals landed on the players shown" },
  SHH  = { SD="Skill Heals Dealt",             LD="The number of times a heal was cast by the players shown" },
  SHHT = { SD="Skill Heals Received",          LD="The number of times a successful heal landed on the players shown" },
  SHT  = { SD="Skill Hits Dealt",              LD="The number of times the players shown landed a hit with skill or spell" },
  SHTT = { SD="Skill Hits Received",           LD="The number of times the players shown received a successful hit with a skill or spell by an enemy target" },
  SI   = { SD="Skill Interrupts Dealt",        LD="The number of enemy target skill or spell casts that were interrupted by the players shown" },
  SIT  = { SD="Skill Interrupts Received",     LD="The number of skill or spell casts that were interrupted from the players shown" },
  SM   = { SD="Skill Misses Dealt",            LD="The number of skills or spells that the players shown failed to hit on their designated target" },
  SMT  = { SD="Skill Misses Received",         LD="The number of skills or spells that the players shown managed to avoid and miss by enemy targets" },
  SO   = { SD="Skill Overhealing Dealt",       LD="The amount of over-healing dealt from the players shown" },
  SOT  = { SD="Skill Overhealing Received",    LD="The amount of over-healing received to the players shown" },
  SOH  = { SD="Skill Overheals Dealt",         LD="The number of over-heals dealt from the players shown" },
  SOHT = { SD="Skill Overheals Received",      LD="The number of over-heals received to the players shown" },
  SR   = { SD="Skill Resists Dealt",           LD="The number of times the players shown used skill or spell cast on a enemy target and was resisted" },
  SRT  = { SD="Skill Resists Received",        LD="The number of times a skill or spell cast on the players shown were resisted" },
  SS   = { SD="Skill Steals Dealt",            LD="The number of buffs the players shown managed to steal from an enemy target" },
  SST  = { SD="Skill Steals Received",         LD="The number of buffs from the players shown stolen by an enemy target" },
  TD   = { SD="Total Damage Dealt",            LD="The total damage from all melee, ranged, skill and spell attacks that the shown players had dealt" },
  TDT  = { SD="Total Damage Received",         LD="The total damage from all melee, ranged, skill and spell attacks that landed on the shown players "}
};
-- Variables and commands list -----------------------------------------------
local ConfigData = {
  Command = "mh",                      -- Command as lower case
  CommandUpper = sEmpty,               -- Filled in at init
  New = { },                           -- New options
  Options = {
    ["Battleground"] = {
      autorel = { R=0, SD="Auto-release corpse in battleground",    LD="Automatically release your corpse. Only works in battlegrounds" },
      bgavnms = { R=0, SD="Use new Alterac Valley message system",  LD="Replaces all herald and general yelling with new short and more understandable generic messages" },
      bgreprt = { R=0, SD="Report battleground status to party",    LD="Reports all battleground activity to the party you are in" },
      blockai = { R=0, SD="Block arena team invites",               LD="Block all incoming arena team invites. Depending on your exemptions you will still see invites from your friends, guild members, party members, etc" },
      blockbg = { R=0, SD="Block battleground chat",                LD="Block all battleground chat. Depending on your exemptions you will still see chat from your friends, guild members, party members, etc" },
      blockwb = { R=0, SD="Block whispers in battlegrounds",        LD="Block all incoming whispers from battlegrounds. Depending on your exemptions you will still see whispers from your friends, guild members, party members, etc" },
    }, ["Quest"] = {
      autoaap = { R=0, SD="Announce achievement progress",          LD="Automatically announce achievement progress" },
      autoaeq = { R=0, SD="Auto-accept escort quests",              LD="Automatically accepts scripted event quests if another party member starts it" },
      autoaqs = { R=0, SD="Announce quest progress",                LD="Announces quest progress. A message is displayed to yourself when soloing, a message is sent to the party when in a party, and sent to the raid when in a raid" },
      autoaqw = { R=0, SD="Announce tracked quests only",           LD="Requires 'Announce quest progress' enabled. Announces only if the quest is a tracked quest on the standard Blizzard UI" },
      autoaaq = { R=0, SD="Auto-accept quests",                     LD="Automatically accepts new quests. Hold shift while selecting NPC to disable functionality" },
      autoasq = { R=0, SD="Auto-accept shared quests",              LD="Automatically accepts shared quests from other party members" },
      autocth = { R=0, SD="Auto-close talking head panels",         LD="Automatically closes talking head speech panels that obstruct the screen. Ignored in withered training" },
      autctha = { R=0, SD="Auto-close talking head panels + audio", LD="Automatically kill speech audio when automatically closing talking head panels. Must have 'Auto-close talking head panels' option enabled too for this to work" },
      autoqcm = { R=0, SD="Auto-complete quests",                   LD="Automatically complete quests. Only works if the NPC has only one quest" },
      autorfq = { R=0, SD="Auto-remove failed quests from log",     LD="Automatically removes failed quests from quest logs" },
      autosaq = { R=0, SD="Auto-share accepted quests",             LD="Automatically push sharable quests to other group members when you accept them. It is recommended that you use this feature cautiously and notify your group members that you are using this feature" },
      autoslq = { R=0, SD="Auto-select options on npc dialogs",     LD="If when you talk to an NPC, there is one quest available to retreive or hand in, this quest will be automatically selected for you. You can also hold the control key to automatically skip speech pages. Hold the shift key and chat to an NPC to temporarly disable auto-selection" },
    }, ["Battle"] = {
      autoacr = { R=0, SD="Auto-accept resurrections",              LD="Auto-accepts resurrections from party members, guild members, friends, etc. You will not automatically accept this if you are away from keyboard" },
      autoalh = { R=0, SD="Auto-emote on low health",               LD="Displays an /emote when your health goes below 25% (which is changable in advanced options). Only works when in a party or raid" },
      autoalm = { R=0, SD="Auto-emote on low mana",                 LD="Displays an /emote when your mana goes below 10% (which is changable in advanced options). Only works when in a party or raid" },
      automkt = { R=0, SD="Auto-mark target in combat",             LD="Automatically mark your targets in combat" },
      autoswr = { R=0, SD="Auto-set reputation bar",                LD="Automatically sets the active reputation bar to the last highest reputation change" },
      blockrw = { R=0, SD="Block annoying raid warning sound",      LD="Block the original raid warning format and instead displays the message in the chat console and also removes the annoying sound" },
      showicm = { R=0, SD="Play in/out of combat warnings",         LD="Plays a sound for when you enter or leave combat" },
    }, ["Loot"] = {
      autodis = { R=0, SD="Auto-disenchant loot when possible",     LD="Automatically selects disenchant instead of auto-greed when possible" },
      autodpl = { R=0, SD="Auto-unset pass on loot in instance",    LD="Automatically re-enables your pass-on-loot status when you enter a new instance. This is useful if you are boosting someone and goto a proper instance later on, but you forgot to unset it! A manadatory warning will be shown when this option is disabled" };
      autogrb = { R=0, SD="Auto-greed even on rare items",          LD="When 'Auto-greed on non-binding loot items' is enabled. You will also automatically roll on rare (blue) quality items too" },
      autogre = { R=0, SD="Auto-greed on non-binding loot items",   LD="Automatically greeds on loot when prompted. Bind-On-Pickup, rare and epic items are ignored. Use this command wisely and make sure you have read and understood the disclaimer for this addon" },
      autopas = { R=0, SD="Auto-pass on all loot items",            LD="Automatically passes on loot when prompted. Use this command wisely and make sure you have read and understood the disclaimer for this addon" },
      autopol = { R=0, SD="Auto-pass on loot when AFK",             LD="If you go AFK, then you will automatically pass-on-loot and will be disabled again when you come out of being AFK" },
    }, ["Money & Item"] = {
      advtrak = { R=0, SD="Advanced data tracking",                 LD="Improves the way honor, experience, spells, money, reputation and item gains and losses are displayed and gives you more advanced information then what is normally shown" },
      autonnm = { R=0, SD="Auto-notify on new mail",                LD="Automatically notifies you when you receive new mail and displays who sent you the mail" },
      autonos = { R=0, SD="Auto-announce AH sell success",          LD="Automatically notifies you on an auction house item selling with a sound and a message in the middle of your screen" },
      autorep = { R=0, SD="Auto-repair all your equipment",         LD="Automatically repair your items when they need repairing. The amount of money spent is displayed. You can hold the shift key while opening the repair merchant window to temporarily disable this feature" },
      autorgf = { R=0, SD="Force repair when guild repair fails",   LD="Automatically repair your items using your own characters purse when the guild bank repair fails. Requires guild bank repair to be enabled" },
      autorpg = { R=0, SD="Auto-repair with guild bank",            LD="Automatically repair your items when they need repairing from the guild bank. The amount of money spent is displayed. You need to enable auto-repair for this to work" },
      autosel = { R=0, SD="Auto-sell poor quality items",           LD="Automatically sells gray quality items to the vendor. Ignores higher quality items" },
      autotra = { R=0, SD="Auto-purchase training",                 LD="Automatically purchases new spells, recipes, patterns, plans, etc. from trainers" },
      bagclik = { R=0, SD="Allow item alt+click enhancements",      LD="Allows you to Alt+LeftClick an item to track it and Alt+RightClick to show more information about it. This applies to items in your bags, merchant items and item links" },
      bagsell = { R=0, SD="Allow auto-auctioning of items",         LD="If you have alt+click announcements enabled, holding shift key while alt+clicking an item in your bag while the auction house is open will automatically auction the item for you" },
    }, ["Group"] = {
      autoall = { R=0, SD="Auto-accept LFG role confirm dialog",    LD="Automatically accepts the looking-for-group role confirmation dialog-box. The description can be automatically set by editing 'dalfgd' in advanced settings. This can be temporarily disabled by holding shift before this event occurs" },
      autoarc = { R=0, SD="Auto-accept role check dialog",          LD="Automatically accepts the looking-for-dungeon role confirmation dialog-box. You can still change your role by right clicking your portrait and selecting 'set role' or by removing yourself from the LFD queue" },
      autoasa = { R=0, SD="Auto-accept summons only when away",     LD="Automatically accept summons from exempted players but only when you are away" },
      autoasu = { R=0, SD="Auto-accept summons",                    LD="Automatically accept summons from exempted players" },
      autojpf = { R=0, SD="Auto-accept group invites",              LD="Automatically accept party or raid invites. Rules apply. Exclusion options apply" },
      autocdl = { R=0, SD="Auto-close LFG de-list alert",           LD="Automatically closes the 'group delisted' dialog box" },
      autorof = { R=0, SD="Report offline group members",           LD="When a group member goes offline. You will get a sound and message notification" },
      blockpt = { R=0, SD="Block party invites",                    LD="Block all incoming party invite requests" },
      forcequ = { R=0, SD="Never report messages to group",         LD="When you have options that report to the party or raid (e.g. Buff Watcher, Quest progress, etc.). These messages will NOT send a party or raid message. Just a local (client only) message" },
      trackgr = { R=0, SD="Track group members",                    LD="Tracks group members and informs you if you have been playing with these people before, where and when along with extra details" },
    }, ["Friends"] = {
      showfrn = { R=0, SD="Show friends online on login",           LD="Shows which of your friends are online when you login to your character" },
      trackfa = { R=0, SD="Notify when friends data changes",       LD="Needs 'Keep track' enabled. Messages will come up on the screen when your friends change area or level up (Big Brother)" },
      trackfr = { R=0, SD="Keep track of your friends data",        LD="When a friend logs off, their data is saved in your friends note. If a custom note is set for a friend then the data is not set for that friend. Sometimes the location data can be inaccurate, a server issue" },
    }, ["Guild"] = {
      blockgi = { R=0, SD="Block guild invites",                    LD="Block all incoming guild invites" },
      blockgp = { R=0, SD="Block guild petitions",                  LD="Block all incoming guild petition sign requests" },
      showgui = { R=0, SD="Show members online on login",           LD="Shows which of your guild members are online when you login to your character" },
    }, ["Chat"] = {
      chatcol = { R=0, SD="Colourise names in chat",                LD="Colourise the names of people who talk in chat" },
      chaticn = { R=0, SD="Show icons for guild and friends",       LD="If the person who is talking is a friend or guild member, that person will have an icon next to their name in the chat log" },
      chatinh = { R=2, SD="Hide text input texture",                LD="Fill me in later!" },
      chaturl = { R=0, SD="Allow ability to click web links",       LD="Allows you the ability to click web links in the chat window. Caution: May cause problems with other addons, such as DBM and may decrease performance!" },
      hidechb = { R=2, SD="Hide chat frame hover background",       LD="Removes the really annoying background you get when you put your mouse cursor over" },
      logchat = { R=0, SD="Enable logging of chat messages",        LD="Enables logging of all chat messages for up to a week. You can change this duration in advanced options" },
      whstlsa = { R=0, SD="Always play sound for whispers",         LD="People who are exempt (friends, guild members, party members, etc.) will always make a tell sound when they whisper you" },
    }, ["Social"] = {
      blockbe = { R=0, SD="Block beggers",                          LD="Try to block annoying beggers. This option is to be used as a caution as it could block genuine requests" },
      blockdu = { R=0, SD="Block duels",                            LD="Block all incoming duels" },
      blockpd = { R=0, SD="Block pet duels",                        LD="Block all incoming pet duels" },
      blockfl = { R=0, SD="Block text flood",                       LD="Block all incoming text flooding" },
      blockns = { R=0, SD="Block npc chat when resting",            LD="Blocks all NPC chat and yells when your character is resting" },
      blocksp = { R=0, SD="Block spam",                             LD="Block all incoming public messages and whispers with URL's in them" },
      blocktr = { R=0, SD="Block trades",                           LD="Block all incoming trade requests. Does not affect outgoing trade requests" },
      blockwh = { R=0, SD="Block whispers",                         LD="Block all incoming whispers. Overrides spam blocking" },
      blockwr = { R=0, SD="Automatically respond to blocks",        LD="Sends a response to the sender when any operation is blocked" },
      command = { R=0, SD="Enable public command system",           LD="Allows players in your guild and friends list to run special commands from your client" },
      delaydn = { R=0, SD="Delay whispers when dnd",                LD="Any whisper sent when you are dnd is delayed until you are are no longer afk" },
      delaywa = { R=0, SD="Delay whispers when afk",                LD="Any whisper sent when you are afk is delayed until you are are no longer afk" },
      delaywc = { R=0, SD="Delay whispers when in combat",          LD="Any whisper sent when you are in combat is delayed until you are out of combat" },
      noaspam = { R=0, SD="Stop AFK/DND Auto-reply spam",           LD="If you whisper someone who is AFK or DND, you are usually told the reason for this, but since you only need to know this once, having this option enabled will make sure you see this message ONLY once, until the DND or AFK reason changes or after five minutes" },
      smartfi = { R=0, SD="Smart message filtering",                LD="Hides all messages that do not relate to you, your party or raid, guild or friends. Some of the things that are filtered are achievements, tipsy, drunk, battleground join/leave and battleground loot messages)" },
      spammsg = { R=0, SD="Blocked public spam messages",           LD="Lets you know when people have been blocked for spamming in a public channel, but not in whispers" },
      trfiltr = { R=0, SD="Trade channel filter",                   LD="Ignores all messages in the trade channel that do not have WTT, WTS, WTB or item links in them" },
    }, ["Tooltip"] = {
      enhtool = { R=2, SD="Enhanced tooltips",                      LD="Show a more enhanced (detailed, colourful and meaningful) unit mouseover tooltip. Also optimises the health bar, creates a mana bar and makes the text easier on all tooltips easier to read" },
      toolfra = { R=2, SD="New tooltip border",                     LD="Use a new tooltip border for the game tooltip" },
      tooltip = { R=0, SD="Anchor tooltip to mouse",                LD="Anchor the tooltip to the mouse cursor" },
      tooltpe = { R=0, SD="Disable unit tooltips",                  LD="Disables the tooltip for units" },
      tooltpm = { R=0, SD="Disable unit tooltips on unit frames",   LD="Disables the tooltip when you put your mouse cursor over a unit frame but not when it is over a unit model" },
      tooltpt = { R=0, SD="Show targets on tooltips",               LD="Shows the target of the unit your mouse cursor is over" },
    }, ["Dialog"] = {
      sapstat = { R=0, SD="Show empty stats in personal stats",     LD="Shows empty 'zero' stats in the personal stats dialog" },
      sastats = { R=0, SD="Show empty stats in rankings",           LD="Shows empty 'zero' stats in the ranking stats dialog" },
      savehis = { R=0, SD="Save history when browsing dialogs",     LD="This option will save your history when ever you switch from one MhMod dialog to another and when you close the dialog, the last dialog you accessed will be shown until there is no history left" },
    }, ["Unit Frame"] = {
      numcolr = { R=2, SD="Colourise status bar values",            LD="Colourises the status bar values and timers. 0% showing red, 50% showing green, 100% showing white, a bit like what the Final Fantasy games do with displaying HP/MP values" },
      petmana = { R=2, SD="Show pet focus/mana bars",               LD="Shows pet focus bars (or player mana bars if vehicle). Not 100% accurate as the server doesn't normally send party pet mana updates" },
      tsbrprt = { R=2, SD="Shift-click bars to report status",      LD="When you click a status bar (player health, mana, exp, etc.) the status of that bar is reported to the party/raid, like in Guild Wars" },
      unitnpe = { R=2, SD="Unit frame enhancements",                LD="Colourises the unit frame name text so it uses the class name and health bar colour so you can tell what class the player is and shows the target that a party member is targeting" },
    }, ["Action"] = {
      asbfade = { R=0, SD="Advanced action button fade",            LD="Fades your action buttons red when you are not in range, blue if you don't have enough mana and green when they are unusable for some other reason" },
      showabc = { R=2, SD="Show cast counts on action buttons",     LD="Shows a number on all your action buttons to show how many more times you can use that action" },
    }, ["Miscellaneous"] = {
      wmcoord = { R=2, SD="Show co-ordinates in world map",         LD="Shows the player and cursor co-ordinates in the titlebar of the world map window" },
      awaytim = { R=2, SD="Display away-from-keyboard timer",       LD="Displays an chronometer on your health and mana bar for when you are away-from-keyboard" },
      bartimr = { R=0, SD="Timer countdowns on bars",               LD="Show timer countdowns for breath, feign death and casting bars" },
      blocktm = { R=0, SD="Prevent trade in mailbox and bank",      LD="Prevents players trading you when the mailbox or bank is opened because if you get traded then the windows are automatically closed" },
      showbag = { R=2, SD="Show bag slot count on each bag",        LD="Shows the number of slots free in all your bags" },
      showdur = { R=0, SD="Show durability status when zoning",     LD="Displays your current durability state when you login and zone. Colour of the message shows severity; green, orange and red" },
      showwmp = { R=0, SD="Show who is pinging the map",            LD="Shows who pings the minimap in the console. Spam controlled to five seconds per player" },
      mmcoord = { R=0, SD="Show co-ordinates on minimap",           LD="Shows co-ordinates instead of the zone text above the minimap when moving. The original text is restored after 5 seconds of stopping moving" },
      simperh = { R=2, SD="Less obtrusive error handler",           LD="Uses a more simplified error handler and shows errors in chat instead of in a obstructive dialog. It also prevents error message spamming too. You'll need to reload the UI for this option to take effect. It will also log these messages if logging is enabled" },
      trdeenh = { R=0, SD="Trade dialog enhancements",              LD="Addeds extra messages and sound effects to the trade dialog which helps you better to tell whats going on with things which you might forget to see!" },
      windrag = { R=2, SD="Allow dragging of windows",              LD="Allows some Blizzard UI windows to be dragged around the screen while dragging the mouse with the control key and right mouse button held down" },
      skipacs = { R=2, SD="Skip all cutscenes and cinematics",      LD="This will skip all cut-scenes and cinematics, unless you happen to be holding the shift key before it happens" },
    }, ["Exclusion"] = {
      xfriend = { R=0, SD="Exclude friends from blocks",            LD="Exclude everyone in your friends list from any sort of blocks" },
      xgroupm = { R=0, SD="Exclude group members from blocks",      LD="Exclude party and raid members from blocks" },
      xguildm = { R=0, SD="Exclude guild from blocks",              LD="Exclude everyone in your guild from any sort of blocks" },
      xtarget = { R=0, SD="Exclude selected target from blocks",    LD="Exclude the player that I am targeting from any sort of blocks" },
      xwhispt = { R=0, SD="Exclude whisper targets from blocks",    LD="Exclude players who I whisper (Five minute timeout) from any sort of blocks" },
    }, ["Stats"] = {
      shwnewr = { R=1, SD="Show new personal bests",                LD="Shows when you get a new highest damage or healing on any of your skills" },
      stsarst = { R=1, SD="Reset stats when entering combat",       LD="When you enter combat, all the battle stats are reset automatically for you" },
      stsator = { R=1, SD="Reset stats when entering instances",    LD="As you enter a new instance. The stats will be reset automatically for you" },
      stsbatt = { R=1, SD="Gather stats in battlegrounds",          LD="Gather statistics in battlegrounds" },
      stsenab = { R=1, SD="Enable statistics gathering",            LD="This is a global option for statistics gathering. If this option is turned off, no statistics will be gathered at all in any case" },
      stssdps = { R=2, SD="Show damage per second",                 LD="Shows your damage per second above your player portrait" },
    },
  }, Commands = {
    ["Quest"] = {
      dumpllqu = { SD="Clear low level quests",                LD="Completely clears low level quests from your quest log" },
      dumpduqu = { SD="Clear dungeon quests",                  LD="Completely clears dungeon and raid quests from your quest log" },
      dumpalqu = { SD="Clear quest log",                       LD="Completely clears your quest log" },
      showqu   = { SD="Report all quests",                     LD="Reports to the chat all the quests you have started" },
    }, ["Interface"] = {
      reload   = { SD="Reload the user interface",             LD="Reload the user interface which reloads all the built in UI scripts and all your modifications" },
      resetui  = { SD="Refresh UI improvements",               LD="Refreshes all the extended UI features this addon features" },
    }, ["Logging"] = {
      logclear = { SD="Clear log database",                    LD="Completely resets the logging database" },
      logdata  = { SD="Show log data dialog",                  LD="Displays a dialog showing logs of all messages your client has captured. You must have logging enabled to actually see any data" },
    }, ["Group"] = {
      i        = { SD="Send single or multi-invite",           LD="Allows you to send an invite to multiple people at once" },
      kickall  = { SD="Kick all users from group",             LD="This will kick all players from the party or raid, useful for full re-grouping" },
      kickallo = { SD="Kick all offline users from group",     LD="This will kick all the offline players from the party or raid" },
      resettdb = { SD="Reset group tracking data",             LD="Resets the group tracking database" },
      setricon = { SD="Set auto-raid target icon",             LD="Allows you to change the raid icon used when auto-mark target feature is enabled" },
      lfg      = { SD="Look for group in current area",        LD="Automatically looks for a group in the current area. You need to click the search button to complete the search" },
    }, ["Item"] = {
      compact  = { SD="Compact bag space",                     LD="Attempts to recover bag space by compacting items into stacks. You may need to run this command multiple times" },
      dress    = { SD="Dress your character",                  LD="Re-dress your character after you have stripped" },
      getitem  = { SD="Get item information",                  LD="Retrieve the information about the item. You must have already seen the item in-game for this to work" },
      showinv  = { SD="Report inventory",                      LD="Reports to the chat all the items you have equipped" },
      showitem = { SD="Report all items in bags",              LD="Reports to the chat all the items in your bags" },
      strip    = { SD="Strip your character",                  LD="Strip your character bare. Your equipment settings are saved for when you dress" },
      trackadd = { SD="Track item",                            LD="Tracks items in your bags and notifies self/party when you obtain more of this item" },
      trackclr = { SD="Track item list purge",                 LD="Clears the item tracking list so no more items will be tracked" },
      trackdel = { SD="Track item deletion",                   LD="Removes the specified item so it is no longer tracked" },
      tracklst = { SD="Track item list",                       LD="Lists all the items in the tracking list" },
    }, ["Social"] = {
      clear    = { SD="Clear console text",                    LD="Clear the text in all your console windows" },
      emotes   = { SD="Show emotes list",                      LD="Show all the emotes supported by the game that you can use" },
      fnclear  = { SD="Clear friends' notes",                  LD="Clear all the notes on all your friends" },
      frlclear = { SD="Clear friends list",                    LD="Clears your friends list of all your friends" },
      iglclear = { SD="Clear ignore list",                     LD="Removes all entries from your ignore list" },
      w        = { SD="Send single or multi-whisper",          LD="Allows you to send a whisper to multiple people at once" },
    }, ["Notes"] = {
      edit     = { SD="Edit the default notes file",           LD="Allows you to make permanant notes of whatever you want. Please note that the data you enter is quite volatile, i.e. if your game crashes or you don't exit the game properly, you will lose ALL your changes and additions" },
      editas   = { SD="Edit the specified notes file",         LD="Allows you to make permanant notes of whatever you want and save to your own custom variable. Please note that the data you enter is quite volatile, i.e. if your game crashes or you don't exit the game properly, you will lose ALL your changes and additions" },
      editasro = { SD="View the specified notes file",         LD="Allows you to view the notes of the specified file without making any changes to them" },
      editclr  = { SD="Reset entire notes list",               LD="Allows you to reset all the notes you have created" },
      editdel  = { SD="Delete notes file",                     LD="Allows you to delete a custom notes file" },
      editdup  = { SD="Duplicate a notes file",                LD="Allows you to duplicate (copy) a notes file" },
      editlst  = { SD="Display all notes files",               LD="Allows you to list all the notes which you have created" },
      editren  = { SD="Rename a notes file",                   LD="Allows you to rename a notes file to a new one" },
      editro   = { SD="View the default notes file",           LD="Allows you to view the default notes without making any changes to them" },
      editsetd = { SD="Set default notes file",                LD="Allows you to change the default notes file" },
    }, ["Script"] = {
      advert   = { SD="Advertise addon",                       LD="Advertises this addon to your party/raid" },
      calc     = { SD="Perform simple calculation",            LD="Performs a calculation. Valid operators are + (add), - (subtract), / (divide), * (multiply), % (modulous), & (and), || (or). (Example: 1 + 1 / 1 * 2)" },
      cmds     = { SD="Show commands list",                    LD="Shows all the different commands you can run on this addon" },
      config   = { SD="Show configuration dialog",             LD="Displays the configuration dialog so you modify many options this addon has to offer" },
      disable  = { SD="Disable all options",                   LD="Disable every variable in this script. This is considered an emergency procedure" },
      help     = { SD="Lookup command or variable",            LD="Allows you to lookup a specific variable or command" },
      reset    = { SD="Reset the addon",                       LD="This will completely reset the addon's settings, databases (everything) and reload the UI" },
      vars     = { SD="Show variables list",                   LD="Shows all the different variables you can set in the chat window" },
    }, ["Money"] = {
      monclear = { SD="Full statistics reset",                 LD="Reset the entire money statistics database" },
      monclrch = { SD="Reset statistics for character",        LD="Reset money statistics data for the current character" },
      monclrs  = { SD="Reset session counters",                LD="Reset's the session counters for XP and Money" },
      money    = { SD="Money statistics",                      LD="Show data for your income and expendature" },
    }, ["Stats"] = {
      playtime = { SD="Show time played on character",         LD="Show the total play time aquired by your character" },
      stats    = { SD="Show stats rankings dialog",            LD="Displays a dialog where all players' stats are calculated up and ranked up in many categories" },
      stsbestc = { SD="Reset all personal bests stats",        LD="Resets your highest heals/damage values" },
      stsclear = { SD="Reset all battle stats",                LD="Completely resets the damage and healing statistics database" },
      stsfullr = { SD="Full statistics database reset",        LD="Resets all battle stats, personal bests and temporary counters" },
      stsshowb = { SD="Show other players' stats dialog",      LD="Allows you to specify someone else to view their best melee, skill and healing records" },
      stsshowp = { SD="Show personal stats dialog",            LD="Shows your best melee, skill and healing records" },
    }, ["System"] = {
      logout   = { SD="Log out this character",                LD="Logs out your character to the character select screen" },
      quit     = { SD="Log out this character and quit",       LD="Logs out your character and quits the game" },
      quitnow  = { SD="Quit the game",                         LD="Immediatly quits the game without confirmation (as if alt+f4 was pressed)" },
      resetgx  = { SD="Reset the graphics engine",             LD="Resets the graphics engine in the game. Useful when you change a video setting in options" },
      resetsx  = { SD="Reset the sound engine",                LD="Resets the sound engine in the game. Useful when you change a sound setting in options" },
      run      = { SD="Execute LUA code",                      LD="For debugging purposes. Executes a line of LUA code, captures its output and prints that output as a table" },
      shot     = { SD="Take UI'less screenshot",               LD="Takes a screenshot without showing any user interface elements" },
      stopmus  = { SD="Stop any music playing",                LD="Stops any music from playing" },
      togglef =  { SD="Toggle full-screen/window mode",        LD="A quick command to toggle full-screen/window mode" },
    },
  }, Dynamic = {
    dalfgd = { DF=     sEmpty,                     SD="Automatic LFG description message",      LD="When this is not empty, the text specified will be automatically entered into the LFG description box and automatically accepted. The setting 'autoall' must be enabled for this to work" },
    damet  = { DF=       300, MI=   1, MA=   3600, SD="Timeout limit for AFK msg anti-spam",    LD="Seconds to wait before a DND or AFK auto-reply message is displayed again" },
    darti  = { DF=         1, MI=   1, MA=      8, SD="Default auto-target raid icon",          LD="Changes the icon used for auto-marking. 1=Star, 2=Circle, 3=Diamond, 4=Triangle, 5=Moon, 6=Square, 7=Cross or 8=Skull" },
    dasr   = { DF=         5, MI=   1, MA=     10, SD="Automatic sell rate per update",         LD="Because Blizzard recently started limiting the amount of items you can sell at once using a script, this value allows you to fine tune how many items are sold at once" },
    dbgalt = { DF=       120, MI=   0, MA=    120, SD="Battleground auto-leave time",           LD="Specifies the number of seconds before automatically leaving a battleground" },
    ddfn   = { DF="Untitled",                      SD="Default notes filename",                 LD="Default notes filename" },
    ddrt   = { DF=        95, MI=   0, MA=    100, SD="Durability report threshold",            LD="If durability falls below this threshold percentage, then a message will be displayed in the chat" },
    ddo    = { DF=       100, MI=   1, MA=    100, SD="MhMod Dialog Opacity",                   LD="The percentage of opacity to apply to the MhMod Dialogs" },
    dflm   = { DF=         6, MI=   2, MA=    100, SD="Maximum text flood lines allowed",       LD="Maximum number of lines allowed before blocking a player for flooding" },
    dflt   = { DF=         3, MI=   1, MA=     10, SD="Seconds between lines allowed",          LD="Seconds cooldown before the number of flood lines for a player is reset" },
    dfto   = { DF=        60, MI=   5, MA=  86400, SD="Timeout before player is removed",       LD="Timeout before a player's flooding data is completely removed" },
    dfart  = { DF=        30, MI=  10, MA=     60, SD="Friends list auto-refresh interval",     LD="The interval in seconds for each friends and guild list automatic updates. A higher value will make the track friends option less accurate whereas a lower value will make it more accurate, but require more processing by your computer!" },
    dldii  = { DF=      3600, MI=  60, MA=2592000, SD="Log dialog date sorting interval",       LD="The interval in seconds that records are sorted into when viewing available logs in the dialog (60 = 1min, 3600 = 1hour, 86400 = 1day, 604800 = 1wk, 2592000 = 1mth). Warning! LOWER values will require more CPU and memory resources. Use with care!" },
    dlept  = { DF=     86400, MI=  60, MA=2592000, SD="Log entry persistance time",             LD="The amount of time in seconds that entries are kept in your log before they are deleted (60 = 1min, 3600 = 1hour, 86400 = 1day, 604800 = 1wk, 2592000 = 1mth). Warning! HIGHER values will require more CPU and memory resources. Use with care!" },
    dlepr  = { DF=         0, MI=   0, MA=      1, SD="Log pruning rate",                       LD="The amount of time in seconds when each log entry is checked. It is recommended you leave this at zero, but may experience slight lag when the logs are being cleaned up. Remember you can use fractions for this value" },
    dlepc  = { DF=       100, MI=   1,             SD="Log prune count per tick",               LD="When the log pruning rate timer has ticked, this is the number of log records are scanned and removed during this event. If this value is too high then you may experience performance issues and if this value is too low, the pruning process might end prematurely if there are many log entries" },
    dlpit  = { DF=      3600, MI=  60, MA=2592000, SD="Log prune interval time",                LD="The amount of time in seconds before checking the log database for out-of-date entries (60 = 1min, 3600 = 1hour, 86400 = 1day, 604800 = 1wk, 2592000 = 1mth). Warning! Setting really low or high values will compromise the performance of the game!" },
    dlht   = { DF=        10, MI=   1, MA=     25, SD="Percent threshold before out-of-health", LD="Threshold to pass before you /healme" },
    dlmt   = { DF=        25, MI=   1, MA=     25, SD="Percent threshold before out-of-mana",   LD="Threshold to pass before you /oom" },
    dlswi  = { DF=        10, MI=   1,             SD="Time to wait between low stat emotes",   LD="Minimum seconds to wait before you /oom or /healme again" },
    dmch   = { DF=      1024, MI= 128, MA=  16384, SD="Chat history back-buffer lines",         LD="Maximum number of chat history backlog lines (Requires UI reset)" },
    dmbx   = { DF=87.7144122, MI=-100, MA=    100, SD="Default button X position",              LD="X position of minimap button. Best to just adjust this properly by just dragging the minimap button" },
    dmby   = { DF=-37.140157, MI=-100, MA=    100, SD="Default button Y position",              LD="Y position of minimap button. Best to just adjust this properly by just dragging the minimap button" },
    docfs  = { DF=         0, MI=   0, MA=     72, SD="Chat frame font size override",          LD="Allows you to override the default chat frame font size. Set to 0 to disable this feature" },
    dpcd   = { DF="None",                          SD="Public commands disabled",               LD="A space separated list of public commands which you don't want anyone to use (i.e. 'lag help')" },
    dtri   = { DF=         1, MI= 0.5, MA=     10, SD="Tooltip target info refresh rate",       LD="The rate in seconds for when the target tooltip info is refreshed" },
    dwiet  = { DF=       500, MI=   5, MA=   3600, SD="Whisper exempt time",                    LD="When block whispers and Exclude whisper targets is enabled, this is the time in seconds before the last whisper message you sent can no longer can be replied to" },
    drfs   = { DF=         1, MI= 0.1, MA=      2, SD="Default raid frame scale",               LD="Use this to rescale the default raid frame size" },
    dspt   = { DF=     86400, MI=  60,             SD="Personal stats prune time",              LD="The amount of time in seconds before expiring entries in the personal stats database (60 = 1min, 3600 = 1hour, 86400 = 1day, 604800 = 1wk, 2592000 = 1mth). Warning! Setting really low or high values will compromise the performance of the game!" },
    dgtpt  = { DF=    604800, MI=  60,             SD="Group tracker prune time",               LD="The amount of time in seconds before expiring entries in the group tracker database (60 = 1min, 3600 = 1hour, 86400 = 1day, 604800 = 1wk, 2592000 = 1mth). Warning! Setting really low or high values will compromise the performance of the game!" },
  }
};
-- == All the available output methods =======================================
local OutputMethodData = {
  BATTLEGROUND = { T=1, L="Battleground", F=function() return IsInBattleground() end },
  CHANNEL      = { T=3, L="Channel",      F=function() return GetChannelList() end },
  ECHO         = { T=0, L="Echo",         F=function() return -1 end },
  EMOTE        = { T=1, L="EMote",        F=function() return true end },
  GUILD        = { T=1, L="Guild",        F=function() return IsInGuild() end },
  INSTANCE     = { T=1, L="Instance",     F=function() return IsInInstance() end },
  OFFICER      = { T=0, L="Officer",      F=function() return UserIsOfficer(sMyName) end },
  PARTY        = { T=0, L="Party",        F=function() return IsInGroup() end },
  RAID         = { T=0, L="Raid",         F=function() return IsInRaid() end },
  RAID_WARNING = { T=0, L="Warning",      F=function() return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") end },
  SAY          = { T=1, L="Say",          F=function() return true end },
  WHISPER      = { T=2, L="Whisper",      F=function() return true end },
  YELL         = { T=1, L="Yell",         F=function() return true end },
};
-- == Combat stats data =======================================================
-- This lookup table allows the COMBAT_LOG_EVENT_UNFILTERED to quickly lookup
-- data for a particular event... (false = not used)
-- * C[1] = The argument index to test for existance in the event (int)
-- * S[2] = the argument index that has the amount value in the event (int)
-- * K[3] = The argument index that has the skill name (int)
-- * H[4] = The skill is a healing skill (boolean)
-- * A[5] = The alternative skill name if K is nil (string)
-- ----------------------------------------------------------------------------
local CombatStatsEventsData = {
  -- EVENT_NAME = { InternalName = { C, S, K, H, A } }
  SWING_DAMAGE = {
    { MD   = { false,    12, false, false, "Melee" },
      TD   = { false,    12, false, false, false },
      MH   = { false, false, false, false, false },
      MB   = {    16, false, false, false, false },
      MA   = {    17, false, false, false, false },
      MG   = {    19, false, false, false, false },
      MCR  = {    20, false, false, false, false },
      MC   = {    18, false, false, false, false } },
    { MDT  = { false,    12, false, false, false },
      TDT  = { false,    12, false, false, false },
      MHT  = { false, false, false, false, false },
      MBT  = {    16, false, false, false, false },
      MAT  = {    17, false, false, false, false },
      MGT  = {    19, false, false, false, false },
      MCRT = {    20, false, false, false, false },
      MCT  = {    18, false, false, false, false } }
  }, SWING_MISSED = {
    { MM   = { false, false, false, false, false } },
    { MMT  = { false, false, false, false, false } }
  }, RANGE_DAMAGE = {
    { RD   = { false,    15,    12, false, "Ranged" },
      TD   = { false,    15, false, false, false },
      RH   = { false, false, false, false, false },
      RA   = {    20, false, false, false, false },
      RC   = {    21, false, false, false, false } },
    { RDT  = { false,    15, false, false, false },
      TDT  = { false,    15, false, false, false },
      RHT  = { false, false, false, false, false },
      RAT  = {    20, false, false, false, false },
      RCT  = {    21, false, false, false, false } }
  }, RANGE_MISSED = {
    { RM   = { false, false, false, false, false } },
    { RMT  = { false, false, false, false, false } }
  }, SPELL_INTERRUPT = {
    { SI   = { false, false, false, false, false } },
    { SIT  = { false, false, false, false, false } }
  }, SPELL_DAMAGE = {
    { SD   = { false,    15,    12, false, "Skill" },
      TD   = { false,    15, false, false, false },
      SHT  = { false, false, false, false, false },
      SA   = {    20, false, false, false, false },
      SR   = {    18, false, false, false, false },
      SC   = {    21, false, false, false, false } },
    { SDT  = { false,    15, false, false, false },
      TDT  = { false,    15, false, false, false },
      SHTT = { false, false, false, false, false },
      SAT  = {    20, false, false, false, false },
      SRT  = {    18, false, false, false, false },
      SCT  = {    21, false, false, false, false } }
  }, SPELL_DRAIN = {
    { SD   = { false,    15,    12, false, "Skill" },
      TD   = { false,    15, false, false, false },
      SHT  = {    17,    17, false, false, false } },
    { SDT  = { false,    15, false, false, false },
      TDT  = { false,    15, false, false, false } }
  }, SPELL_MISSED = {
    { SM   = { false, false, false, false, false } },
    { SMT  = { false, false, false, false, false } }
  }, SPELL_HEAL = {
    { SH   = { false,    15,    12, true,  "Skill" },
      SHH  = { false, false, false, false, false },
      SO   = {    16,    16, false, true,  false },
      SOH  = {    16, false, false, false, false },
      SHC  = {    17, false, false, false, false } },
    { SHT  = { false,    15, false, true,  false },
      SHHT = { false, false, false, false, false },
      SOT  = {    16,    16, false, true,  false },
      SOHT = {    16, false, false, false, false },
      SHCT = {    17, false, false, false, false } }
  }, SPELL_DISPEL_FAILED = {
    { SFD  = { false, false, false, false, false } },
    { SFDT = { false, false, false, false, false } }
  }, SPELL_DISPEL = {
    { SDP  = { false, false, false, false, false } },
    { SDPT = { false, false, false, false, false } }
  }, SPELL_STOLEN = {
    { SS   = { false, false, false, false, false } },
    { SST  = { false, false, false, false, false } }
  }, PARTY_KILL = {
    { D    = {     6, false, false, false, false } },
    { DT   = {     9, false, false, false, false } }
  }, ENVIRONMENTAL_HEAL = {
    { },
    { SHT  = { false,    13, false, true,  false } }
  }, ENVIRONMENTAL_DAMAGE = {
    { },
    { TDT  = { false,    13, false, false, false } }
  },
};-- EVENT_NAME / InternalName  C   S   K   H      A
CombatStatsEventsData.SPELL_PERIODIC_DAMAGE= CombatStatsEventsData.SPELL_DRAIN;
CombatStatsEventsData.SPELL_PERIODIC_DRAIN = CombatStatsEventsData.SPELL_DRAIN;
CombatStatsEventsData.SPELL_LEECH = CombatStatsEventsData.SPELL_DRAIN;
CombatStatsEventsData.SPELL_PERIODIC_LEECH = CombatStatsEventsData.SPELL_DRAIN;
CombatStatsEventsData.SPELL_PERIODIC_HEAL = CombatStatsEventsData.SPELL_HEAL;
CombatStatsEventsData.UNIT_DIED = CombatStatsEventsData.PARTY_KILL;
-- == Battleground Yell Data ==================================================
local BGYellData = {
  ["Herald"] = {
    { T=2, S="(.*) was destroyed by the (.*)%!",
      R="%s was destroyed by the %s!" },
    { T=2, S="(.*) was taken by the (.*)%!",
      R="%s was taken by the %s!" },
    { T=2, S="(.*) is under attack%!  If left unchecked%, the (.*) will .* it%!",
      R="%s is under attack from the %s!" },
    { T=3, S="The (.*) wins%!",
      R="The %s have won Alterac Valley!" },
    { T=0, S="The Frostwolf General is dead%!",
      R="The Frostwolf General has been defeated!" },
    { T=1, S="The Stormpike General is dead%!",
      R="The Stormpike General has been defeated!" },
    { T=3, S="The (.*) has taken (.*)%!  Its supplies will now be used for reinforcements%!",
      R="The %s has captured the %s!" },
  }, ["Captain Balinda Stonehearth"] = {
    { T=1, S="Begone%, uncouth scum%!  The Alliance shall prevail in Alterac Valley%!",
      R="The Stormpike Captain is under attack!" },
    { T=0, S="Filthy Frostwolf cowards%! If you want a fight%, you%'ll have to come to me%!",
      R="An attack on the Stormpike Captain has failed!" },
    { T=0, S="Take heart%, Alliance%!  Throw these villains from Alterac Valley%!",
      R="The Alliance team has been blessed with extra health!" },
  }, ["Captain Galvangar"] = {
    { T=0, S="Die%!  Your kind has no place in Alterac Valley%!",
      R="The Frostwolf Captain is under attack!" },
    { T=1, S="I%'ll never fall for that%, fool%! If you want a battle, it will be on my terms and in my lair%.",
      R="An attack on the Frostwolf Captain has failed!" },
    { T=1, S="Now is the time to attack%!  For the Horde%!",
      R="The Horde team has been blessed with extra health!" },
  }, ["Drek'Thar"] = {
    { T=1, S="Leave no survivors!",
      R="The Horde team has been blessed with extra damage!" },
    { T=1, S="You seek to draw the General of the Frostwolf legion out from his fortress%? PREPOSTEROUS%!",
      R="An attack on the Frostwolf General has failed!" },
    { T=1, S="Stormpike weaklings%, face me in my fortress %- if you dare%!",
      R="An attack on the Frostwolf General has failed!" },
    { T=0, S="Stormpike filth%! In my keep%?%! Slay them all%!",
      R="The Frostwolf General is under attack!" },
    { T=0, S="If you will not leave Alterac Valley on your own%, then the Frostwolves will force you out%!",
      R="The Frostwolf General is under heavy attack!" },
    { T=0, S="Today%, you will meet your ancestors%!",
      R="The Frostwolf General is under heavy attack!" },
    { T=0, S="Your attacks are slowed by the cold%, I think%!",
      R="The Frostwolf General is under heavy attack!" },
    { T=0, S="You are no match for the strength of the Horde%!",
      R="The Frostwolf General is under heavy attack!" },
    { T=0, S="You cannot defeat the Frostwolf clan%!",
      R="The Frostwolf General is under heavy attack!" },
    { T=0, S="Your spirits are weak%, and your blows are weaker%!",
      R="The Frostwolf General is under heavy attack!" },
  }, ["Vanndar Stormpike"] = {
    { T=1, S="Soldiers of Stormpike%, your General is under attack%! I require aid%! Come%! Come%! Slay these mangy Frostwolf dogs%.",
      R="The Stormpike General is under attack!" },
    { T=1, S="We will not be swayed from our mission%!",
      R="The Stormpike General is under heavy attack!" },
    { T=1, S="We%, the Alliance%, will prevail%!",
      R="The Stormpike General is under heavy attack!" },
    { T=0, S="You%'ll never get me out of me bunker%, heathens%!",
      R="An attack on the Stormpike General has failed!" },
    { T=0, S="Why don%'t ya try again without yer cheap tactics%, pansies%! Or are you too chicken%?",
      R="An attack on the Stormpike General has failed!" },
    { T=1, S="I will tell you this much%.%.%.Alterac Valley will be ours%.",
      R="The Stormpike General is under heavy attack!" },
    { T=1, S="Your attacks are weak%!  Go practice on some rabbits and come back when you%'re stronger%.",
      R="The Stormpike General is under heavy attack!" },
    { T=1, S="It%'ll take more than you rabble to bring me down%!",
      R="The Stormpike General is under heavy attack!" },
    { T=1, S="The Stormpike clan bows to no one%, especially the horde%!",
      R="The Stormpike General is under heavy attack!" },
    { T=1, S="Is that the best you can do%?",
      R="The Stormpike General is under heavy attack!" },
    { T=1, S="Take no prisoners%! Drive these heathens from our lands%!",
      R="The Stormpike General is under heavy attack!" },
  }, ["Wing Commander Slidore"] = {
    { T=0, S="I%'m coming Frostwolf%, and this time you%'re gonna feel the flames%!",
      R="The Alliance have launched air support from Slidore" },
  }, ["Wing Commander Vipore"] = {
    { T=0, S="Senior Wing Commander Vipore launching%. Pray for a swift death%, Frostwolf%.",
      R="The Alliance have launched air support from Vipore" },
  }, ["Wing Commander Jeztor"] = {
    { T=1, S="Jeztor%'s coming for you%, Stormpike%!",
      R="The Horde have launched air support from Jeztor" },
  }, ["Wing Commander Guse"] = {
    { T=1, S="Guse is entering the battle%! Time to take out the Stormpike filth%!",
      R="The Horde have launched air support from Guse" },
  }, ["Wing Commander Ichman"] = {
    { T=0, S="You%'re going down%, Mulv%!",
      R="Wing Commander Ichman is at Frostwolf and escaping!" },
    { T=0, S="Drek%'thar%, I%'m coming for you%!",
      R="The Alliance have launched air support from Ichman" },
  }, ["Wing Commander Mulverick"] = {
    { T=1, S="I come for you%, puny Alliance%!",
      R="Wing Commander Mulverick is at Stonehearth and escaping!" },
    { T=1, S="Incoming air support to Dun Baldar%! Stormpike bow down%!",
      R="The Horde have launched air support from Mulverick" },
  }, ["Taskmaster Snivvle"] = {
    { T=4, S="Snivvle is here%!  Snivvle claims the (.*)%!",
      R="The %s has fallen into a neutral state!" },
  }, ["Morloch"] = {
    { T=4, S="I am here%!  And the (.*) is%.%.%. MINE%!",
      R="The %s has fallen into a neutral state!" },
  }, ["Ivus the Forest Lord"] = {
    { T=0, S="Wicked%, wicked%, mortals%! The forest weeps%. The elements recoil at the destruction%. Ivus must purge you from this world%!",
      R="The Forest Lord has been summoned by the Alliance!" },
  }, ["Lok'holar the Ice Lord"] = {
    { T=1, S="WHO DARES SUMMON LOK%'HOLAR%? The blood of a thousand Stormpike soldiers shall I spill%.%.%. none may stand against the Ice Lord%!",
      R="The Ice Lord has been summoned by the Horde!" },
    { T=1, S="I drink in your suffering%, mortal%. Let your essence congeal with Lokholar%!",
      R="The Ice Lord claims an Alliance soul and becomes stronger!" },
    { T=1, S="Your base is forfeit%, puny mortals%!",
      R="The Ice Lord has reached Dun Baldar and is guarding the area!" },
  }, ["Arch Druid Renferal"] = {
    { T=0, S="Soldiers of Stormpike%, aid and protect us%! The Forest Lord has granted us his protection%. The portal must now be opened%!",
      R="The Alliance are on their way to summon the Forest Lord!" },
  }, ["Primalist Thurloga"] = {
    { T=1, S="Soldiers of Frostwolf%, aid and protect us%! The Ice Lord has granted us his protection%. The portal must now be opened%! The time has come to unleash him upon the Stormpike Army%!",
      R="The Horde are on their way to summon the Ice Lord!" },
    { T=1, S="It is done%! Lok%'holar has arrived%! Bow to the might of the Horde%, fools%!",
      R="The Horde have finished summoning the Ice Lord!" },
  }, ["Stormpike Stable Master"] = {
    { T=4, S="The stable is empty%! We must provide our cavalry with suitable mounts%. Stormpike Stables requests your assistance%!",
      R="The Stormpike Stable Master requires assistance in Dun Baldar." },
  },
};
-- == Main frame events =======================================================
EventsData = {
  -- Player entering world and all character data loaded ---------------------
  PLAYER_ENTERING_WORLD = function()
    -- Loading finished
    bLoading = false;
    -- Initialise player counters and other things
    EventsData.PLAYER_PVP_KILLS_CHANGED();
    EventsData.PLAYER_XP_UPDATE();
    EventsData.PLAYER_MONEY();
    EventsData.UPDATE_INSTANCE_INFO();
    UnitEventsData.player.UNIT_INVENTORY_CHANGED();
    -- Re-initialise configuration and custom ui elements
    LocalCommandsData.applycfg();
    LocalCommandsData.resetui();
    -- Show durability information if requested
    if SettingEnabled("showdur") then
      local nCurrent, nMaximum, nPercent = GetDurability();
      if nCurrent and nPercent <= GetDynSetting("ddrt") then
        local oColour;
        if     nPercent > 50 then oColour = { r=0.0, g=1.0, b=0.0 };
        elseif nPercent > 25 then oColour = { r=0.5, g=0.5, b=0.0 };
        elseif nPercent >  0 then oColour = { r=1.0, g=0.0, b=0.0 };
        else                      oColour = { r=0.5, g=0.5, b=0.5 } end;
        Print("Durability status is "..BreakUpLargeNumbers(nCurrent)..
          " of "..BreakUpLargeNumbers(nMaximum).." at "..
          RoundNumber(nPercent, 2).."%.", oColour);
      end
    end
    -- Just trigger regular update timer if interface already initialised
    if InitsData.Interface then return TriggerTimer("FART") end;
    -- Create timer to trigger every so often to update data and maintenence
    CreateTimer(GetDynSetting("dfart"), function()
      -- Update friends list
      C_FriendList.ShowFriends();
      -- Update guild members list
      if IsInGuild() then C_GuildInfo.GuildRoster() end;
      -- Get current time
      local nTime = GetTime();
      -- Done if chat log doesn't need pruning
      if bLoading or GetTimer("CLPT") or nTime - nChatLogLastPruned <
        GetDynSetting("dlpit") then return end;
      -- Get time where log entries should be removed
      local nLimit = time() - GetDynSetting("dlept");
      -- Get first log category and if we have it?
      local sCat, aCat = next(mhclog);
      if sCat and aCat then
        -- Get number of items to prune per timer tick
        local iCount = GetDynSetting("dlepc");
        -- Get first log entry
        local iRecord = next(aCat);
        -- Create a timer to process each log entry
        CreateTimer(GetDynSetting("dlepr"), function()
          -- Until we've reached the count
          for iI = 1, iCount do
            -- If we have the entry
            if iRecord then
              -- Entry is older than the limit?
              if iRecord < nLimit then
                -- Save entry
                local aLast = iRecord;
                -- Get next entry
                iRecord = next(aCat, iRecord);
                -- Remove last entry
                aCat[aLast] = nil;
              -- Entry is not older so leave it and get next entry
              else iRecord = next(aCat, iRecord) end;
            end
            -- If we have no more records in this category?
            if not iRecord then
              -- If category list is now empty?
              if not next(aCat) then
                -- Save last category
                local aLast = sCat;
                -- Get next category
                sCat, aCat = next(mhclog, sCat);
                -- Clear the last category
                mhclog[aLast] = nil;
              -- Category still has entries so just set the next category
              else sCat, aCat = next(mhclog, sCat) end;
              -- If there is no next category then kill timer as we're done!
              if not sCat then return true end;
              -- Set the first record
              iRecord = next(aCat);
            end
          end
        end, nil, "CLPT", true);
      end
      -- Update time the chatlog was last pruned
      nChatLogLastPruned = nTime;
    end, nil, "FART", true);
    -- Interface initialised
    InitsData.Interface = true;
    -- Update more data. Blizzard already sends these events at reload but not
    -- at login.
    EventsData.UPDATE_BATTLEFIELD_STATUS();
    EventsData.CALENDAR_UPDATE_EVENT_LIST();
    UnitEventsData.player.PLAYER_FLAGS_CHANGED();
    -- FIXME    RequestArtifactCompletionHistory();
  end,
  -- Player leaving world ----------------------------------------------------
  PLAYER_LEAVING_WORLD = function()
    UpdateGroupTrackData({ C=0,N={ } }, GetGroupData());
    if SettingEnabled("advtrak") then
      if iXPSession > 0 then
        Print("You gained "..FormatNumber(iXPSession)..
          " XP in the last "..MakeTime(time()-iSessionStart)..
          " and need "..FormatNumber(iXPLeft).." to level",
            ChatTypeInfo.COMBAT_XP_GAIN);
      end
      if iHonourSession > 0 then
        Print("You gained "..FormatNumber(iHonourSession)..
          " honour in the last "..MakeTime(time()-iSessionStart)..
          " and need "..FormatNumber(iHonourLeft).." to level",
            ChatTypeInfo.COMBAT_HONOR_GAIN);
      end
      local Msg = nil;
      if iMoneySession < 0 then
        Msg = "spent "..MakeMoneyReadable(-iMoneySession);
      elseif iMoneySession > 0 then
        Msg = "gained "..MakeMoneyReadable(iMoneySession);
      end
      if Msg then
        Print("You "..Msg.." in the last "..MakeTime(time()-iSessionStart)..
          " and have "..MakeMoneyReadable(iMoney).." total",
            ChatTypeInfo.MONEY);
      end
    end
    BlockTrades(false);
    PassOnLoot(true);
    bLoading = true;
    -- Trigger timers one time and then kill them
    while #TimerData > 0 do
      local sName = TimerData[1].N
      TriggerTimer(sName);
      KillTimer(sName);
    end
  end,
  -- An action was forbidden by an addon -------------------------------------
  ADDON_ACTION_FORBIDDEN = function(Addon, Function)
    if GetCVar("scriptErrors") == "0" then return end;
    local sMsg;
    if not Function then sMsg = Addon.." was denied";
    else sMsg = Function.." prevented because of "..Addon end;
    ClickDialogButton("ADDON_ACTION_FORBIDDEN", 2);
    error("WARNING: Call to "..sMsg..".");
  end,
  -- Group is full and has been delisted -------------------------------------
  LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS = function()
    -- Ignore if setting is disabled
    if not SettingEnabled("autocdl") then return end;
    -- Close the dialog
    ClickDialogButton("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS", 1);
    -- Message with warning and a sound affact
    PlaySoundFile("Sound/INTERFACE/PVPWarningAllianceMono.ogg");
    -- Print in upper middle of screen
    HudMessage("The group is full and has now been delisted", 1, 0.25, 0);
  end,
  -- Looking for group role check shown --------------------------------------
  LFG_ROLE_CHECK_SHOW = function()
    -- Ignore if autoset role is disabled
    if not SettingEnabled("autoarc") then return end;
    -- Iterate through the role type buttons in the LFD dialog and if they're
    -- checked, add to the message to say that role was set.
    local sMsg = sEmpty;
    for sType, aData in pairs({
      TANK    = { LFDRoleCheckPopupRoleButtonTank,   INLINE_TANK_ICON },
      HEALER  = { LFDRoleCheckPopupRoleButtonHealer, INLINE_HEALER_ICON },
      DAMAGER = { LFDRoleCheckPopupRoleButtonDPS,    INLINE_DAMAGER_ICON }
    }) do if aData[1].checkButton:GetChecked() then
      if sMsg then sMsg = sMsg..PLAYER_LIST_DELIMITER.." " end;
      sMsg = sMsg..aData[2].." "..sType;
    end end;
    -- Ignore if no role data so user can pick
    if #sMsg == 0 then return end;
    -- Echo roles to chat and automatically accept the roles
    Print("Automatically accepted role as "..sMsg.."!");
    LFDRoleCheckPopupAccept_OnClick();
  end,
  -- Trainer was closed ------------------------------------------------------
  TRAINER_CLOSED = function()
    -- Kill auto train timer
    KillTimer("ATRA");
  end,
  -- A trainer was shown -----------------------------------------------------
  TRAINER_SHOW = function()
    -- Done if auto-learn is disabled or shift key pressed
    if not SettingEnabled("autotra") or IsShiftKeyDown() then return end;
    -- When the dialog is open the list isn't ready yet so wait until the
    -- server gives us the list.
    CreateTimer(0.5, function()
      -- Turn timer off if auto-learn is disabled or shift key pressed
      if not SettingEnabled("autotra") or
             IsShiftKeyDown() then return true end;
      -- Iterate through each purchase
      for iIndex = 1, GetNumTrainerServices() do
        -- Get purchase info and if the purchase is available and can afford?
        local sName, sType = GetTrainerServiceInfo(iIndex);
        if sType and #sType > 0 and
           sType == "available" and
           GetTrainerServiceCost(iIndex) <= iMoney then
          -- Purchase this one and return
          return BuyTrainerService(iIndex);
        end
      end
      -- We keep the timer running to purchase any new services
    end, nil, "ATRA", true);
  end,
  -- A duel has finished -----------------------------------------------------
  DUEL_FINISHED = function() bInDuel = false end,
  -- Resurrection dialog opened ----------------------------------------------
  RESURRECT_REQUEST = function(sFrom)
    -- Ignore if auto accept resurrection setting is disabled, or user isn't
    -- knnown by the addon, or I am not AFK.
    if not SettingEnabled("autoacr") or
       not UserIsExempt(sFrom) or UnitIsAFK("player") then return end;
    -- There are three different resurraction dialog types so auto-choose the
    -- appropriate one. More than one of these cannot happen at once so it's
    -- safe and the funciton checks to see if the dialog is open already so it
    -- can't accidentally choose something else.
    for _, sDialog in ipairs({
      "RESURRECT", "RESURRECT_NO_SICKNESS", "RESURRECT_NO_TIMER"
    }) do ClickDialogButton(sDialog, 1) end;
    -- Echo in chat what we did
    Print("Auto-accepting resurrection from "..MakePlayerLink(sFrom));
  end,
  -- Calendar event opened ---------------------------------------------------
  CALENDAR_OPEN_EVENT = function()
    if CalendarEventHasPendingInvite() then return end;
    local Title, Description, Creator = CalendarGetEventInfo();
    if Title and Description and Creator then
      if Creator == "Unknown" or (not UserIsExempt(Creator) and
          (IsSpam(Description) or IsSpam(Title))) then
        local MonthIndex, DayIndex, EventIndex = CalendarGetEventIndex();
        CalendarRemoveEvent()
        Print("Calendar event '"..Title.."' ("..MonthIndex..":"..
          DayIndex..":"..EventIndex..") automatically blocked from "..
          MakePlayerLink(Creator)..".", {r=1,g=0,b=0});
      end
    end
    CalendarCloseEvent();
  end,
  -- New calendar data (just call to update calendar data) -------------------
  CALENDAR_NEW_EVENT = OpenCalendar,
  -- Got calendar data -------------------------------------------------------
  CALENDAR_UPDATE_EVENT_LIST = function()
    --[[ FIXME
    CreateTimer(1, function()
      if CalendarGetNumPendingInvites() <= 0 then return end;
      local NewCalData, Events = { };
      for MonthIndex = 1, 12 do
        for DayIndex = 1, 31 do
          Events = CalendarGetNumDayEvents(MonthIndex, DayIndex);
          for EventIndex = 1, Events do
            tinsert(NewCalData, { MonthIndex, DayIndex, EventIndex });
          end
        end
      end
      for Id, Data in ipairs(NewCalData) do
        CalendarOpenEvent(Data[1], Data[2], Data[3]);
      end
      CalendarEventsData = NewCalData;
    end, 1, "CU");
    --]]
  end,
  -- A pet duel was requested ------------------------------------------------
  PET_BATTLE_PVP_DUEL_REQUESTED = function(Player)
    if not SettingEnabled("blockpd") or UserIsExempt(Player) then return end;
    ClickDialogButton("PET_BATTLE_PVP_DUEL_REQUESTED", 2);
    Print("A pet duel request from "..MakePlayerLink(Player).." was blocked",
      { r=1, g=0, b=0 });
    SendResponse(Player, "Sorry, but pet duels are auto-declined");
  end,
  -- A duel was requested ----------------------------------------------------
  DUEL_REQUESTED = function(Player)
    if not SettingEnabled("blockdu") or UserIsExempt(Player) then return end;
    ClickDialogButton("DUEL_REQUESTED", 2);
    Print("A duel request from "..MakePlayerLink(Player).." was blocked",
      { r=1, g=0, b=0 });
    SendResponse(Player, "Sorry, but duel requests are auto-declined");
  end,
  -- A guild invite was requested --------------------------------------------
  GUILD_INVITE_REQUEST = function(sPlayer, sGuild)
    -- Allow request if setting to block not enabled or we know the issuer
    if not SettingEnabled("blockgi") or UserIsExempt(sPlayer) then return end;
    -- Echo message in the chat
    Print("A guild invite from "..MakePlayerLink(sPlayer).." to join "..
      sGuild.." was blocked", {r=1,g=0,b=0});
    -- Send a response to to the issuer
    SendResponse(sPlayer, "Sorry, but guild invites are auto-declined");
    -- Hide the petition
    HideUIPanel(GuildInviteFrame);
    -- Decline the invitation
    DeclineGuild();
  end,
  -- A party invite was requested --------------------------------------------
  PARTY_INVITE_REQUEST = function(sWho)
    -- Do NOT do anything if in a loading screen or automatically accepting the
    -- invite will bug the client requiring a relog.
    if bLoading then return end;
    -- If auto-join party setting is enabled
    if SettingEnabled("autojpf") then
      -- Put message in chat
      Print("Party invite from "..MakePlayerLink(sWho).." auto-accepted");
      -- Click the join button
      return ClickDialogButton("PARTY_INVITE", 1);
    end
    -- If block party invites are disabled or user is exempt then allow the
    -- game to ask the player normally.
    if not SettingEnabled("blockpt") or UserIsExempt(Player) then return end;
    -- This will block the party invite message in chat
    iIgnorePartyMessage = iIgnorePartyMessage + 1;
    -- Print the message in chat and tell the inviter
    Print("Party invite from "..MakePlayerLink(Player).." was blocked");
    SendResponse(Player, "Party invites are currently blocked");
    -- Decline the party invite
    ClickDialogButton("PARTY_INVITE", 2);
  end,
  -- Talking head requested? --------------------------------------------------
  TALKINGHEAD_REQUESTED = function()
    -- Ignore if setting disabled
    if not SettingEnabled("autocth") then return end;
    -- Query the current zone because we can't close certain speeches
    local sZone = GetSubZoneText();
    -- Ignore withered training
    if sZone == "Temple of Fal'adora" or
       sZone == "Falanaar Tunnels" or
       sZone == "Shattered Locus" then return end;
    -- Auto-close the speech but keep the audio playing?
    if SettingEnabled("autctha") then
      C_TalkingHead.IgnoreCurrentTalkingHead();
    else TalkingHeadFrame:Hide() end;
  end,
  -- Summon confirmation required --------------------------------------------
  CONFIRM_SUMMON = function()
    -- Ignore if auto accept summent requests are disabled or auto-accept
    -- summon requests is enabled and player is not away from keyboard
    if not SettingEnabled("autoasu") or
       (SettingEnabled("autoasa") and nAwayFromKeyboard == 0) then return end;
    -- Get summoner and location of summoner
    local sUser, sLocation =
      GetSummonConfirmSummoner(), GetSummonConfirmAreaName();
    -- Print message that we auto-accepted the summon
    Print("Auto-accepting summon from "..
      MakePlayerLink(User).." to "..Location);
    -- Accept the summon request
    ClickDialogButton("CONFIRM_SUMMON", 1);
  end,
  -- Player started moving ---------------------------------------------------
  PLAYER_STARTED_MOVING = function()
    -- Ignore if setting disabled
    if not SettingEnabled("mmcoord") then return end;
    -- Ignore if map not available
    if not C_Map.GetBestMapForUnit("player") then return end;
    -- Kill zone text reset timer
    KillTimer("PSRT");
    -- For every 0.1 sec...
    CreateTimer(0.1, function()
      -- Get player position and kill timer if map not available
      local iMapId = C_Map.GetBestMapForUnit("player");
      if not iMapId then return true end;
      local aData = C_Map.GetPlayerMapPosition(iMapId, "player");
      if not aData then return true end;
      -- Get XY
      local nPX, nPY = aData:GetXY();
      -- Set text to white
      MinimapZoneText:SetTextColor(1, 1, 1);
      -- Get zone
      local sZone = GetSubZoneText();
      if not sZone or #sZone == 0 then sZone = GetZoneText() end;
      -- Update text to player co-ordinates
      MinimapZoneText:SetText(format("%.01f, %.01f |cff00ff00(%s)",
        nPX*100, nPY*100, sZone));
    end, nil, "PSM", true);
  end,
  -- Player stopped moving ---------------------------------------------------
  PLAYER_STOPPED_MOVING = function()
    -- Kill movement update timer and return if failed
    if not KillTimer("PSM") then return end;
    -- Set text to green
    MinimapZoneText:SetTextColor(0, 1, 0.5);
    -- Set to original minimap text in 5 seconds.
    CreateTimer(5.0, Minimap_Update, 1, "PSRT");
  end,
  -- Petition frame was shown ------------------------------------------------
  PETITION_SHOW = function()
    -- Allow petition if block guild petitions is disabled
    if not SettingEnabled("blockgp") then return end;
    -- Get guild petition info and return if it is my guild or the user
    -- requesting the signature is exempt.
    local _, sGuild, _, _, sName, bMyGuild = GetPetitionInfo();
    if bMyGuild or UserIsExempt(sName) then return end;
    -- Close the petition
    ClosePetition();
    -- Put message in chat
    Print("Petition request to join "..sGuild.." blocked from "..
      MakePlayerLink(sName), { r = 1, g = 0, b = 0 });
    -- Tell user petitions are blocked
    SendResponse(sName, "Petition requests are blocked");
  end,
  -- An arena team invite was requested --------------------------------------
--[[ FIXME
  ARENA_TEAM_INVITE_REQUEST = function(Player, Team)
    -- Ignore if block arena invite requests or
    if not SettingEnabled("blockai") or UserIsExempt(Player) then return end;
    ClickDialogButton("ARENA_TEAM_INVITE", 2);
    Print("An arena invite request from "..MakePlayerLink(Player)..
      " to join "..Team.." was blocked", {r=1,g=0,b=0});
    SendResponse(Player, "Arena team invites are currently blocked");
  end,
--]]
  -- A quest giver with options is shown -------------------------------------
  GOSSIP_SHOW = function(...)
    -- Alias tables and functions for speed
    local nsGI = C_GossipInfo;
    assert(type(nsGI)=="table");
    local funcGO = nsGI.GetOptions;
    assert(type(funcGO)=="function");
    local funcSO = nsGI.SelectOption;
    assert(type(funcSO)=="function");
    local funcGACQ = nsGI.GetActiveQuests;
    assert(type(funcGACQ)=="function");
    local funcSACQ = nsGI.SelectActiveQuest;
    assert(type(funcSACQ)=="function");
    local funcGAVQ = nsGI.GetAvailableQuests;
    assert(type(funcGAVQ)=="function");
    local funcSAVQ = nsGI.SelectAvailableQuest;
    assert(type(funcSAVQ)=="function");
    -- Callback functions
    local aFunctions = {
      -- Selects normal quests first
      function(aI) return not aI.isTrivial and
                          not aI.repeatable and
                          not aI.frequency end,
      -- Then legendary quests
      function(aI) return aI.isLegendary end,
      -- Then repeatable quests
      function(aI) return aI.isRepeatable end,
      -- Then every other quest
      function(aI) return true end
    };
    -- Actual function
    local function Event()
      -- Ignore automation if shift pressed or automation setting is disabled
      if IsShiftKeyDown() then return end;
      -- Get current options, active and available quests
      local aOptions = funcGO();
      local aActive = funcGACQ();
      local aAvailable = funcGAVQ();
      -- Get auto select options setting and if...
      local bAutoSelectOptions = SettingEnabled("autoslq")
      if bAutoSelectOptions and            -- Setting is enabled? and
         ((not IsControlKeyDown() and      -- Not control held?
           #aActive + #aAvailable == 0 and -- No quests?
           #aOptions == 1) or              -- Only one option? or
          (IsControlKeyDown() and          -- Control held? and
           #aOptions > 0)) then            -- More than one option?
        -- Select a random option
        local aOption = aOptions[math.random(#aOptions)];
        if aOption.status == 0 then
          return funcSO(aOption.gossipOptionID);
        end
      end
      -- If auto-complete quests enabled?
      if SettingEnabled("autoqcm") then
        -- Get active quests and enumerate through them
        for iIndex = 1, #aActive do
          -- Get active quest data and if autocomplete it if completed
          local aOption = aActive[iIndex];
          if aOption.isComplete then return funcSACQ(aOption.questID) end;
        end
      end
      -- Auto select options enabled and have gossip options?
      if bAutoSelectOptions and #aOptions > 0 then
        -- Walk through each gossip option
        for iIndex = 1, #aOptions do
          -- Get gossip item and select it if its for quest progress
          local aOption = aOptions[iIndex];
          if aOption.name:sub(1, 11) == "|cFF0000FF(" then
            -- Select this option and return
            return funcSO(aOption.gossipOptionID);
          end
        end
      end
      -- If auto-accept quests enabled?
      if SettingEnabled("autoaaq") then
        -- Get available quest data and if there is some?
        if #aAvailable > 0 then
          -- Iterate through importance of available quests
          for iFuncIndex = 1, #aFunctions do
            -- Get callback function and enumerate through each available quest
            local fcbFilter = aFunctions[iFuncIndex];
            for iOptIndex = 1, #aAvailable do
              -- Get the item data and if theres a filter match then select it
              local aOption = aAvailable[iOptIndex];
              if fcbFilter(aOption) then return funcSAVQ(aOption.questID) end;
            end
          end
        end
      end
    end
    -- Set actual function and call it for the first time
    EventsData.GOSSIP_SHOW = Event;
    Event(...);
  end,
  -- Quest giver dialog (when only quests are available) ----------------------
  QUEST_GREETING = function(...)
    -- Ignore automation if shift pressed
    if IsShiftKeyDown() then return end;
    -- Enumerate thquests and complete all that are done if setting enabled
    if SettingEnabled("autoqcm") then
      for iIndex = 1, GetNumActiveQuests() do
        local sTitle, bComplete = GetActiveTitle(iIndex);
        if bComplete then return SelectActiveQuest(iIndex) end;
      end
    end
    -- No completable quests available so accept first available
    if SettingEnabled("autoaaq") and GetNumAvailableQuests() > 0 then
      return SelectAvailableQuest(1) end;
  end,
  -- Quest log updated -------------------------------------------------------
  QUEST_LOG_UPDATE = function(...)
    -- Namespace and function aliases
    local nsQL = C_QuestLog;
    assert(type(nsQL)=="table");
    local funcGNQLE = nsQL.GetNumQuestLogEntries;
    assert(type(funcGNQLE)=="function");
    local funcGQIFLI = nsQL.GetQuestIDForLogIndex;
    assert(type(funcGQIFLI)=="function");
    local funcGQWT = nsQL.GetQuestWatchType;
    assert(type(funcGQWT)=="function");
    local funcIC = nsQL.IsComplete;
    assert(type(funcIC)=="function");
    local funcIF = nsQL.IsFailed;
    assert(type(funcIF)=="function");
    local funcGQO = nsQL.GetQuestObjectives
    assert(type(funcGQO)=="function");
    -- Automatic quest popup helpers
    local aAutoQuestPopUpHelpers = {
      OFFER    = { "autoaaq", ShowQuestOffer    },
      COMPLETE = { "autoqcm", ShowQuestComplete }
    };
    -- Override original function
    EventsData.QUEST_LOG_UPDATE = function()
      -- New quest data that will be set
      local aNew = { };
      -- Enumerate through the players quest log
      for iLogIndex = 1, funcGNQLE() do
        -- Convert quest log index to unique quest index and if valid?
        local iUniqueIndex = funcGQIFLI(iLogIndex);
        if iUniqueIndex > 0 then
          -- Add quest data to new table
          aNew[iUniqueIndex] = {
            C = not not funcIC(iUniqueIndex),
            F = not not funcIF(iUniqueIndex),
            I = iUniqueIndex,
            N = iLogIndex,
            O = funcGQO(iUniqueIndex),
            W = not not funcGQWT(iLogIndex)
          };
        end
      end
      -- If quests not initialised yet?
      if not InitsData.Quests then
        -- Set initialised and return (don't check for new quests)
        InitsData.Quests = true;
        QuestData = aNew;
        return
      end
      -- Get current settings
      local ProgressReport = SettingEnabled("autoaqs");
      local OnlyWatched = SettingEnabled("autoaqw");
      local AutoShare = SettingEnabled("autosaq");
      -- Walk through new quests table
      for Quest, QuestTable in pairs(aNew) do
        local OldQuestData = QuestData[Quest];
        if OldQuestData then
          local OldObjectivesData = OldQuestData.O;
          for Objective, ObjectiveTable in pairs(QuestTable.O) do
            if OldObjectivesData[Objective] and ProgressReport and
              (not OnlyWatched or (OnlyWatched and QuestTable.W)) then
              local OldObjectiveData = OldObjectivesData[Objective];
              if(ObjectiveTable.numFulfilled and
                 OldObjectiveData.numFulfilled and
                 ObjectiveTable.numFulfilled >
                   OldObjectiveData.numFulfilled) or
                (ObjectiveTable.finished and not
                   OldObjectiveData.finished) then
                local Objective, ObjectiveLink = ObjectiveTable.text;
                if Objective then
                  _, ObjectiveLink = GetItemInfo(Objective);
                  if not ObjectiveLink then
                    ObjectiveLink = "["..Objective.."]";
                  end
                else
                  ObjectiveLink = "["..ObjectiveName.."]";
                end
                local Message = "<";
                if not ObjectiveTable.finished then
                  local iCurrent = ObjectiveTable.numFulfilled;
                  local iTotal =  ObjectiveTable.numRequired;
                  if type(iCurrent) == "number" and
                     type(iTotal) == "number"then
                    Message = Message.."("..floor(iCurrent/iTotal*100).."%)";
                  else
                    Message = Message.."(Progress)";
                  end
                else
                  Message = Message.."(Done!)";
                  PlaySound(SOUNDKIT.UI_QUEST_ROLLING_FORWARD_01);
                end
                PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT);
                SendChat(Message..GetQuestLink(QuestTable.I)..
                  ObjectiveLink..">");
              end
            end
          end
        else
          Message = "<"..MakeQuestPrettyName(QuestTable.N).." added to log";
          if GroupData.D.C > 0 and AutoShare and
              C_QuestLog.IsPushableQuest(QuestTable.N) then
            C_QuestLog.SetSelectedQuest(QuestTable.N);
            QuestLogPushQuest();
            Message = Message.." and shared";
          end
          Print(Message..">", ChatTypeInfo.SYSTEM);
        end
      end
      local AutoRemove = SettingEnabled("autorfq");
      for Quest, QuestTable in pairs(aNew) do
        local OldQuestData = QuestData[Quest];
        if OldQuestData then
          if QuestTable.F ~= OldQuestData.F then
            local QuestId = OldQuestData.I;
            if ProgressReport and (not OnlyWatched or QuestTable.W) then
              SendChat("<"..GetQuestLink(QuestId).." was failed!>");
            end
            HudMessage(GetQuestLink(QuestId).." was failed!", 1, 0, 0);
            if AutoRemove then
              C_QuestLog.SelectQuestLogEntry(QuestTable.N);
              C_QuestLog.SetAbandonQuest();
              C_QuestLog.AbandonQuest();
            end
          elseif QuestTable.C ~= OldQuestData.C then
            if ProgressReport and (not OnlyWatched or QuestTable.W) then
              local sLink = GetQuestLink(OldQuestData.I);
              if sLink then SendChat("<"..sLink.." is complete!>") end;
            end
            PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE);
          end
        end
      end
      -- Walk through old quests
      for Quest, QuestTable in pairs(QuestData) do
        -- Get quest in new quest data and if not found?
        local NewQuestData = aNew[Quest];
        if not NewQuestData then
          -- Then the quest was removed by the server obviously
          Print("<"..MakeQuestPrettyNameId(QuestTable.I)..
            " removed from log>", ChatTypeInfo.SYSTEM);
        end
      end
      -- Any quest popups?
      if GetNumAutoQuestPopUps() > 0 then
        -- Can't accept when dead
        if UnitIsDeadOrGhost("player") then return end;
        -- Get auto quest info and if there is any?
        local iId, sType = GetAutoQuestPopUp(1);
        if iId then
          -- Popup index and popups that were closed
          local iPopupIndex, aPopupsClosed = 1, { };
          -- Process current item
          repeat
            -- Get popup helper for type and if found and setting is enabled?
            local aHelper = aAutoQuestPopUpHelpers[sType];
            if aHelper and SettingEnabled(aHelper[1]) then
              -- Call the function and add it for removal
              aHelper[2](iId);
              tinsert(aPopupsClosed, iId);
            end
            -- See if there are other popups
            iPopupIndex = iPopupIndex + 1;
            iId, sType = GetAutoQuestPopUp(iPopupIndex);
          -- Break if there are no more popups
          until not iId;
          -- For each popup processed
          repeat
            -- Next popup
            iPopupIndex = iPopupIndex - 1;
            -- Remove the popup from screen
            RemoveAutoQuestPopUp(aPopupsClosed[iPopupIndex]);
          -- Until the last popup closed
          until iPopupIndex == 1;
        end
      end
      -- Set new quest data
      QuestData = aNew;
    end
    -- Call actual function
    return EventsData.QUEST_LOG_UPDATE(...);
  end,
  -- A shared quest was displayed --------------------------------------------
  QUEST_DETAIL = function()
    -- Get name of quest giver
    local sWho = UnitName("questnpc");
    -- This is for automaatic 'secret' quests that appear when you do certain
    -- things in the world. Since the quest is automatically accepted anyway
    -- we'll just use this to close the dialog.
    if SettingEnabled("autoqcm") and UserIsMe(sWho) then
      return CloseQuest();
    end
    -- If quest is a shared quest from another player?
    if UnitPlayerOrPetInRaid("questnpc") or
       UnitPlayerOrPetInParty("questnpc") then
      -- Auto accept quests from other players?
      if SettingEnabled("autoasq") then
        Print("Auto-accepting quest "..(GetQuestLinkFromName(GetTitleText()) or
          GetTitleText()).." from "..MakePlayerLink(sWho));
        AcceptQuest();
      end
      -- Done
      return;
    end
    -- Auto accept normal quests? (ignored if shift pressed)
    if SettingEnabled("autoaaq") and not IsShiftKeyDown() then
      return AcceptQuest();
    end
  end,
  -- An escort quest was started ---------------------------------------------
  QUEST_ACCEPT_CONFIRM = function(Player, Quest)
    if not SettingEnabled("autoaeq") then return end;
    if not Player then Player = "Unknown" end;
    local _, NumQuests = C_QuestLog.GetNumQuestLogEntries();
    local Q = GetQuestLinkFromName(Quest) or Quest;
    if NumQuests >= MAX_QUESTS then
      return Print("Cannot auto-accept quest "..Q.." from "..
        MakePlayerLink(Player).." because your quest log is full",
          {r=1,g=0,b=0});
    end
    Print("Auto-accepting quest "..Q.." from "..MakePlayerLink(Player));
    return ClickDialogButton("QUEST_ACCEPT", 1);
  end,
  -- The player's target changed ---------------------------------------------
  PLAYER_TARGET_CHANGED = function()
    -- Update target and target of target frame
    UnitFrameUpdate(TargetFrame);
    UnitFrameUpdate(TargetFrameToT);
    if SettingEnabled("automkt") and UnitExists("target") and
       (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and
       UnitCanAttack("player", "target") and not UnitIsPlayer("target") and
       not GetRaidTargetIndex("target") then
      SetRaidTarget("target", GetDynSetting("darti"));
    end
  end,
  -- Cinematic started playing ------------------------------------------------
  CINEMATIC_START = function()
    if SettingEnabled("skipacs") and not IsShiftKeyDown() then
      CinematicFrame_CancelCinematic() end;
  end,
  -- Movie started playing ----------------------------------------------------
  PLAY_MOVIE = function()
    -- Replace function and call it
    if SettingEnabled("skipacs") and not IsShiftKeyDown() then
      CinematicFinished(Enum.CinematicType.GameMovie, true) end;
  end,
  -- The player died ---------------------------------------------------------
  PLAYER_DEAD = function()
    if SettingEnabled("autorel") and IsInBattleground() and
      not HasSoulstone() then RepopMe() end;
  end,
  -- Combat has started ------------------------------------------------------
  PLAYER_REGEN_DISABLED = function()
    -- Ignore if already in combat
    if nCombatTime > 0 then return end;
    -- If stats are enabled then calculate combat time
    if bStatsEnabled then
       mhstats.CT = mhstats.CT + (GetTime() - nCombatTime) end;
    -- Say combat has started if requested
    if SettingEnabled("showicm") then PlaySound(25477) end;
    -- Set combat time
    nCombatTime = GetTime();
  end,
  -- Combat has ended --------------------------------------------------------
  PLAYER_REGEN_ENABLED = function()
    -- Ignore if not in combat
    if nCombatTime == 0 then return end;
    -- Say combat has ended if requested
    if SettingEnabled("showicm") then PlaySound(39517) end;
    -- Show delayed whispers
    ShowDelayedWhispers();
    -- Reset combat time
    nCombatTime = 0;
  end,
  -- A completed quest was shown ---------------------------------------------
  QUEST_PROGRESS = function()
    -- Get quest text and return if nil (happens when clicking really fast
    local sText = QuestProgressText:GetText();
    if not sText then return end;
    -- Is quest completable?
    if IsQuestCompletable() then
      -- Auto quest completion enabled? Complete it
      if SettingEnabled("autoqcm") and
         not IsShiftKeyDown() then CompleteQuest();
      -- Auto quest completion disabled?
      else QuestProgressText:SetText(sText..
        "\n\n|cff00ff00You have completed this task!|r") end;
    -- Quest not completed? Add text to signify that
    else QuestProgressText:SetText(sText..
      "\n\n|cffff0000You have not completed this task yet!|r") end;
  end,
  -- Ui message generated ----------------------------------------------------
  UI_INFO_MESSAGE = function(...)
    -- Messages we're interested in
    local aMessages = {
      [ERR_TRADE_CANCELLED] = "Sound/Interface/Error.wav",
      [ERR_TRADE_COMPLETE] = "Sound/Interface/AuctionWindowClose.wav"
    }
    -- Actual event function
    local function Event(sMsg)
      -- Return if trade enhancement settings are disabled
      if not SettingEnabled("trdeenh") then return end;
      -- If it's a message we're interested in then play specified sound
      local sSound = aMessages[sMsg];
      if sSound then PlaySoundFile(sSound) end;
    end
    -- Replace initialisation function
    EventsData.UI_INFO_MESSAGE = Event;
    -- Execute real function for first time
    Event(...);
  end,
  -- Player trade item list changed ------------------------------------------
  TRADE_PLAYER_ITEM_CHANGED = function()
    if not SettingEnabled("trdeenh") then return end;
    PlaySoundFile("Sound/Interface/GuildBankOpenBag2.wav");
  end,
  -- Target trade item list changed ------------------------------------------
  TRADE_TARGET_ITEM_CHANGED = function()
    if not SettingEnabled("trdeenh") then return end;
    PlaySoundFile("Sound/Interface/GuildBankOpenBag3.wav");
  end,
  -- Transmog removed --------------------------------------------------------
  TRADE_POTENTIAL_REMOVE_TRANSMOG = function()
    if not SettingEnabled("trdeenh") then return end;
    PlaySoundFile("Sound/Interface/GuildBankOpenBag3.wav");
  end,
  -- Enchant changed ---------------------------------------------------------
  TRADE_POTENTIAL_BIND_ENCHANT = function()
    if not SettingEnabled("trdeenh") then return end;
    PlaySoundFile("Sound/Interface/GuildBankOpenBag3.wav");
  end,
  -- Player trade money changed ----------------------------------------------
  PLAYER_TRADE_MONEY = function()
    if not SettingEnabled("trdeenh") then return end;
    PlaySoundFile("Sound/Interface/LootCoinLarge.wav");
  end,
  -- Player trade currency changed -------------------------------------------
  PLAYER_TRADE_CURRENCY = function()
    if not SettingEnabled("trdeenh") then return end;
    PlaySoundFile("Sound/Interface/GuildBankOpenBag3.wav");
  end,
  -- Trade money changed -----------------------------------------------------
  TRADE_MONEY_CHANGED = function()
    if not SettingEnabled("trdeenh") then return end;
    PlaySoundFile("Sound/Interface/iMoneyDialogOpen.wav");
  end,
  -- Trade accept status updated ---------------------------------------------
  TRADE_ACCEPT_UPDATE = function(PlayerDone, TargetDone)
    if not SettingEnabled("trdeenh") then return end;
    PlaySoundFile("Sound/Interface/PlaceHolder.wav");
  end,
  -- Trade window opened -----------------------------------------------------
  TRADE_SHOW = function()
    local Player = UnitName("NPC") or
      TradeFrameRecipientNameText:GetText() or "Unknown";
    if not bTradeStartedByMe and
       SettingEnabled("blocktr") and Player and
       not UserIsExempt(Player) then
      Print("A request to trade from "..MakePlayerLink(Player).." was blocked",
        { r=1, g=0, b=0 });
      SendResponse(Player, "Trade requests are currently blocked");
      CloseTrade();
      return;
    end
    if not SettingEnabled("trdeenh") then return end;
    if bTradeStartedByMe then
      Print("You opened a trade window with "..MakePlayerLink(Player).."!",
        ChatTypeInfo.SYSTEM);
    else
      Print(MakePlayerLink(Player).." opened a trade window with you!",
        ChatTypeInfo.SYSTEM);
    end
    PlaySoundFile("Sound/Interface/AuctionWindowOpen.wav");
  end,
  -- The mechant dialog was opened -------------------------------------------
  MERCHANT_SHOW = function(...)
    -- Tables and functions
    local nsC = C_MerchantFrame;
    assert(type(nsC)=="table");
    local funcISAJE = nsC.IsSellAllJunkEnabled;
    assert(type(funcISAJE)=="function");
    local funcGNJI = nsC.GetNumJunkItems;
    assert(type(funcGNJI)=="function");
    local funcSAJE = nsC.SellAllJunkItems;
    assert(type(funcISAJE)=="function");
    -- Repair id and colour
    local iSfxRepairId = SOUNDKIT.ITEM_REPAIR;
    local aColMoney = ChatTypeInfo.MONEY;
    -- Actual event function
    local function Event()
      -- Return if shift key pressed
      if IsShiftKeyDown() then return end;
      -- If auto-repair enabled? Try to repair
      if SettingEnabled("autorep") then
        -- Get repair cost and if we can repair, and if we can repair?
        local iRepairCost, bCanRepair = GetRepairAllCost();
        if bCanRepair then
          -- If repair with guild bank enabled?
          if SettingEnabled("autorpg") and CanGuildBankRepair() then
            -- Repair items with guild bank and tell user
            RepairAllItems(true);
            PlaySound(SOUNDKIT.ITEM_REPAIR);
            return Print("Automatically repairing equipment with guild bank "..
              "for "..MakeMoneyReadable(iRepairCost), aColMoney);
          end
          -- Repair with own funds
          RepairAllItems();
          PlaySound(iSfxRepairId);
          Print("Automatically repairing equipment for "..
            MakeMoneyReadable(iRepairCost), aColMoney);
        -- Cannot repair with own funds but can we repair with guild bank?
        elseif CanGuildBankRepair() and SettingEnabled("autorgf") then
          -- Do repair with guild bank instead and tell user
          RepairAllItems(true);
          PlaySound(iSfxRepairId);
          Print("Unable to automatically repair items with own funds but "..
            "repairing equipment with guild bank for "..
              MakeMoneyReadable(iRepairCost).." instead", aColMoney);
        end
      end
      -- If auto-sell trash enabled then find items to sell
      if SettingEnabled("autosel") and funcISAJE() then
        -- Get number of junk items to sell and if there are any?
        local iCount = funcGNJI();
        if iCount > 0 then
          -- Sell them all
          funcSAJE();
          -- Report that we're selling them all
          Print("Selling "..iCount.." trash items to the vendor...",
            aColMoney);
        end
      end
    end
    -- Set actual event function and call it for first time
    EventsData.MERCHANT_SHOW = Event;
    Event(...);
  end,
  -- The faction log was updated ---------------------------------------------
  UPDATE_FACTION = function(...)
    -- Original faction rank data ranges
    local aORanks = {
      [-42000] = "Hated",   [-6000] = "Hostile",  [-3000] = "Unfriendly",
      [     0] = "Neutral", [ 3000] = "Friendly", [ 9000] = "Honoured",
      [ 21000] = "Revered", [42000] = "Exalted"
    };
    -- Ignore further updates when expanding headers
    local bInitialised = false;
    local aAutoSetData = { };
    -- Get commonly used namespaces and functions
    local nsR = C_Reputation;
    assert(type(nsR)=="table");
    local funcGFDBI = nsR.GetFactionDataByIndex;
    assert(type(funcGFDBI)=="function");
    local funcEFH = nsR.ExpandFactionHeader;
    assert(type(funcEFH)=="function");
    local funcCFH = nsR.CollapseFactionHeader;
    assert(type(funcCFH)=="function");
    local funcGFPI = nsR.GetFactionParagonInfo;
    assert(type(funcGFPI)=="function");
    local funcSWFBI = nsR.SetWatchedFactionByIndex
    assert(type(funcSWFBI)=="function");
    local funcGMFRI = C_MajorFactions.GetMajorFactionRenownInfo;
    assert(type(funcGMFRI)=="function");
    -- Event updates disabled
    local function fcbDisabled() end;
    -- Event updates enabled
    local function fcbEnabled()
      -- New faction data and faction headers we expanded
      local aNew, aExpanded = { }, { };
      -- Disable further updates until we're done and expanded all headers
      EventsData.UPDATE_FACTION = fcbDisabled;
      -- Get first faction item and if valid?
      local aData = funcGFDBI(1);
      if aData then
        -- Current faction log id and header
        local iIndex, sHeader = 1;
        -- Process faction item
        repeat
          -- Get quest name and unique faction id
          local sName = aData.name;
          local iUniqueId = aData.factionID;
          -- If its a header?
          if aData.isHeader or aData.isHeaderWithRep then
            -- Set current header name
            sHeader = sName;
            -- If is collapsed header? We can't see the other reputations
            if aData.isCollapsed then
              -- Insert into a list to collapse again later
              tinsert(aExpanded, iIndex);
              -- Expand it now (ignoring updates)
              funcEFH(iIndex);
            end
          end
          -- Check if this is a renown faction and if it is?
          local aRData = funcGMFRI(iUniqueId);
          if aRData then
            local iLevel = aRData.renownLevel;
            local iUpper = aRData.renownLevelThreshold;
            local iCurrent = aRData.renownReputationEarned;
            local iBottom = (iLevel - 1) * iUpper;
            local nPercent = iCurrent / iUpper * 100;
            aNew[sName] = {
              C  = sHeader,            CH = iUpper,
              CV = iCurrent,           CP = nPercent,
              I  = iIndex,             M  = true,
              R  = "Renown "..iLevel,  TB = iBottom,
              TH = iUpper,             TV = iCurrent,
              TP = nPercent,           U  = iUniqueId,
            };
          -- It's not a renown faction?
          else
            local iBottom = aData.currentReactionThreshold;
            local iStanding = aData.currentStanding;
            local iCurrent = iStanding - iBottom;
            local iTotal = 43000 + iStanding;
            local iNext = aData.nextReactionThreshold - iBottom;
            local aData = {
              C  = sHeader,            CH = iNext,
              CV = iCurrent,           CP = iCurrent / iNext * 100,
              I  = iIndex,             M  = false,
              R  = aORanks[iBottom],   TB = 43000 + iBottom,
              TH = 85000,              TV = iTotal,
              TP = iTotal / 85000 * 100,
              U  = iUniqueId,
            };
            -- Get paragon information and if it's valid?
            local iPCurrent, iPNext = funcGFPI(iUniqueId);
            if iPCurrent then
              -- Set data
              aData.PC = iPCurrent;
              aData.PV = iPCurrent % iPNext;
              aData.PH = iPNext;
              aData.PP = iPCurrent / iPNext * 100;
            end
            -- Assign data
            aNew[sName] = aData;
          end
          -- Read next item
          iIndex = iIndex + 1;
          aData = funcGFDBI(iIndex);
        -- Break if no more items
        until not aData;
        -- For each collapsed faction header
        while #aExpanded > 0 do
          -- Do the collapse (ignoring the update)
          funcCFH(aExpanded[#aExpanded]);
          -- Remove from list
          tremove(aExpanded, #aExpanded);
        end
      end
      -- If we haven't initialised this yet?
      if not bInitialised then
        -- Enable updates again
        EventsData.UPDATE_FACTION = fcbEnabled;
        -- Set to initialised
        bInitialised = true;
        -- Set new data
        FactionData = aNew;
        -- We're done
        return;
      end
      -- Get colour for messages, tracking and automatic tracking settings
      local aColour = ChatTypeInfo.COMBAT_FACTION_CHANGE;
      local bIsAutoTrack = SettingEnabled("autoswr");
      -- Advanced tracking is enabled?
      if SettingEnabled("advtrak") then
        -- Remove 'Guild' reputation for now because then a reputation loss
        -- for 'Guild' appears which is annoying.
        local aGuild = aNew.Guild;
        if aGuild then aNew.Guild = nil end;
        -- Enumerate through new data
        for sNFName, aNFData in pairs(aNew) do
          -- Get old faction data and if it exists?
          local aOFData = FactionData[sNFName];
          if aOFData then
            -- Get old/new total value and has the value changed?
            local iOTotalValue, iNTotalValue = aOFData.TV, aNFData.TV;
            if iNTotalValue ~= iOTotalValue then
              -- Which way, the next threshold and the amount it changed by
              local sMsg, iNext, iAmount;
              -- If reputation was lost?
              if iNTotalValue < iOTotalValue then
                -- Renown level increases will show drops so ignore them
                if not aNFData.M then
                  sMsg = "Lost ";
                  iNext = iNTotalValue - aNFData.TB;
                  iAmount = iOTotalValue - iNTotalValue;
                end
              -- Reputation was gained?
              else
                sMsg = "Received ";
                iNext = aNFData.CH - aNFData.CV;
                iAmount = iNTotalValue - iOTotalValue;
              end
              -- We have something to report?
              if sMsg then
                -- Add amount changed by
                sMsg = sMsg..BreakUpLargeNumbers(iAmount).." REP! ("..sNFName;
                -- Add reputation level
                if aNFData.R then sMsg = sMsg.."; "..aNFData.R end;
                -- If we're under the maximum level?
                if iNTotalValue < aNFData.TH then
                  -- Add total reputation, percentage and to next level
                  sMsg = sMsg.."; "..BreakUpLargeNumbers(aNFData.CV).."; "..
                         RoundNumber(aNFData.CP, 2).."%; Next: "..
                         BreakUpLargeNumbers(iNext);
                  -- Report how many more of these increases to next level?
                  local iCount = ceil(iNext / iAmount);
                  if iCount > 0 then
                    sMsg = sMsg.."; x"..BreakUpLargeNumbers(iCount);
                  end
                end
                -- Print the message with the system colour
                Print(sMsg..")", aColour);
              end
              -- If we're automatically tracking reputation then add data
              if bIsAutoTrack then aAutoSetData[aNFData.I] = iAmount end;
            -- Has the paragon experience changed?
            elseif aNFData.PC and aNFData.PC ~= aOFData.PC then
              -- Get current value, next threshold and amount changed by
              local iTotal = aNFData.PV;
              local iNext, iChange =
                aNFData.PH - iTotal, aNFData.PC - aOFData.PC;
              -- Start building message to send to player
              local sMsg = "Received "..BreakUpLargeNumbers(iChange)..
                " PTS! ("..sNFName.."; "..
                RoundNumber(iTotal / aNFData.PH * 100, 2)..
                "%; Next: "..BreakUpLargeNumbers(iNext);
              -- Get changes required to be on the next level and add to msg
              local iCount = iNext / iChange;
              if iCount > 0 then
                sMsg = sMsg.."; x"..BreakUpLargeNumbers(ceil(iCount));
              end
              -- Print the message to player in system colour
              Print(sMsg..")", aColour);
              -- If we're automatically tracking reputation then add data
              if bIsAutoTrack then aAutoSetData[aNFData.I] = iChange end;
            end
          end
        end
        -- Add guild data back
        aNew.Guild = aGuild;
      end
      -- If we have auto track reputation enabled?
      if bIsAutoTrack then
        -- Because we can get spammed with reputation gains, we'll use a timer
        -- in which each call of this overwrites the previous timer.
        CreateTimer(1, function()
          -- Highest found value and id
          local iHighest, iHighestId = 0, 0;
          -- Find the highest value
          for iIndex, iValue in pairs(aAutoSetData) do
            if iValue > iHighest then
              iHighestId, iHighest = iIndex, iValue;
            end
          end
          -- If we got the highest id then set it and clear data
          if iHighestId > 0 then funcSWFBI(iHighestId) end;
          aAutoSetData = { };
        end, 1, "FactionCalculator");
      end
      -- Set new datax
      FactionData = aNew;
      -- Enable updates again
      EventsData.UPDATE_FACTION = fcbEnabled;
    end
    -- Set real function and call it for the first time
    EventsData.UPDATE_FACTION = fcbEnabled;
    fcbEnabled(...);
  end,
  -- An auto-complete quest was completed ------------------------------------
  QUEST_AUTOCOMPLETE = function(iQuestID)
    -- Return if setting isn't enabled for auto quest complete
    if not iQuestId or not SettingEnabled("autoqcm") then return end;
    -- Get and check data for requested quest id
    local aQData = QuestData[iQuestID];
    if not aQData then return end;
    -- Automatically complete the uest
    ShowQuestComplete(aQData.N);
  end,
  -- A quest was completed ---------------------------------------------------
  QUEST_COMPLETE = function()
    -- If auto complete quests is enabled and there is just one reward choice,
    -- and shift key isn't held then grab the reward and complete quest
    if SettingEnabled("autoqcm") and GetNumQuestChoices() <= 1 and
      not IsShiftKeyDown() then GetQuestReward(1) end;
  end,
  -- Status has changed for a battlefield ------------------------------------
  UPDATE_BATTLEFIELD_STATUS = function(...)
    -- Battleground reason change data
    local BGChangeReasonsData = {
      queued = {
        queued  = "Re-queued for",        confirm = "Now eligable to join",
        active  = nil,                    none    = "Left the queue for",
        error   = "Queue error for",
      }, confirm = {
        queued  = "Reset the queue for",  confirm = nil,
        active  = "Joined",               none    = "Declined entry for",
        error   = "Joining",
      }, active = {
        queued  = nil,                    confirm = "Now joined",
        active  = nil,                    none    = "Leaving",
        error   = "Error in",
      }, none = {
        queued  = "Now in the queue for", confirm = nil,
        active  = nil,                    none    = nil,
        error   = "Error in",
      }, error = {
        queued  = nil,                    confirm = nil,
        active  = nil,                    none    = nil,
        error   = nil,
      },
    };
    -- Battleground names
    local aNames = {
      "Alterac Valley",                "Arathi Basin",
      "Arena Skirmish",                "Ashran",
      "Battle for Wintergrasp",        "Brawl: Packed House",
      "Deepwind Gorge",                "Eye of the Storm",
      "Isle of Conquest",              "Random Battleground",
      "Random Epic Battleground",      "Seething Shore",
      "Silvershard Mines",             "Strand of the Ancients",
      "Temple of Kotmogu",             "The Battle for Gilneas",
      "Tol Barad",                     "Twin Peaks",
      "Warsong Gulch",                 "Wintersgrasp"
    };
    -- Number of battleground queues allowed
    local iNumBattlegrounds = 3;
    -- Battleground is initialised
    local bInitialised = false;
    -- Real function
    EventsData.UPDATE_BATTLEFIELD_STATUS = function()
      -- Status counters data
      local aCData = { queued=0, confirm=0, active=0, none=0, error=0 };
      -- Names data
      local aNData = { };
      -- Indexes data
      local aIData = { };
      -- New battleground data
      local aNew = { C = aCData, I = aIData, N = aNData };
      -- Build names list
      for iIndex = 1, #aNames do
        local sName = aNames[iIndex];
        aNData[sName] = { I=nil, S="none", M=sName, N=0, W=nil };
      end
      -- If this is the first initialisation?
      if not bInitialised then
        -- Set initialised
        bInitialised = true;
        -- Set new data
        BGData = aNew;
        -- Done
        return;
      end
      -- Enumerate through
      for iIndex = 1, iNumBattlegrounds do
        -- Get battlefield queue status
        local sState, sMap = GetBattlefieldStatus(iIndex);
        -- Build data for battleground
        local aData = {
          I = iIndex, S = sState, M = sMap or "UNKNOWN",
          W = GetBattlefieldEstimatedWaitTime(iIndex)
        };
        -- Set data in named index if valid
        if sMap and sState~="none" then aNData[sMap] = aData end;
        -- Set data as indexed table
        aIData[iIndex] = aData;
        -- Increase counter count
        aCData[sState] = aCData[sState] + 1;
      end
      -- If we're in a battleground request the current score data
      if aCData.active > 0 then RequestBattlefieldScoreData() end;
      local Report = SettingEnabled("bgreprt");
      local OldBGCountersData = BGData.C;
      local OldBGNamesData = BGData.N;
      local OldBGIndexesData = BGData.I;
      for BGName, BattlegroundData in pairs(aNData) do
        local Data = OldBGNamesData[BGName];
        assert(Data, "Internal Error: No data for '"..BGName.."'!");
        sState = BGChangeReasonsData[Data.S];
        assert(sState, "Internal Error: No reason data for '"..Data.S.."'!");
        sState = sState[BattlegroundData.S];
        if sState and Report and BattlegroundData.S ~= Data.S then
          SendChat("<"..sState.." "..BattlegroundData.M..">");
        end
      end
      -- Set new data
      BGData = aNew;
    end
    -- Call actual function for first time
    EventsData.UPDATE_BATTLEFIELD_STATUS(...);
  end,
  -- Scoreboard changed in the battleground ----------------------------------
  UPDATE_BATTLEFIELD_SCORE = function()
    local NewBGScoresData = {
      A = { },
      C = GetNumBattlefieldScores(),
      E = IsActiveBattlefieldArena(),
      H = { },
      M = { },
      N = { },
      R = { },
      W = GetBattlefieldWinner(),
      X = GetBattlefieldInstanceExpiration(),
    };
    if NewBGScoresData.C <= 0 then
      BGScoresData = NewBGScoresData;
      return;
    end
    local ScoreData, MeData;
    local NamesData = NewBGScoresData.N;
    local RanksData = NewBGScoresData.R;
    local HordeData = NewBGScoresData.H;
    local AllianceData = NewBGScoresData.A;
    for iIndex = 1, NewBGScoresData.C do
      local Name, KillingBlows, HonorKills, KOs, HonorGained, Faction, Rank,
        Race, Class, Filename, DamageDone, HealingDone =
          GetBattlefieldScore(iIndex);
      if Name then
        ScoreData = {
          KB = KillingBlows, HK = HonorKills, DE = KOs,       HG = HonorGained,
          FA = Faction,      RA = Rank,       RC = Race,        CL = Class,
          FN = Filename,     DD = DamageDone, HD = HealingDone, RN = 0
        };
        NamesData[Name] = ScoreData;
        if Faction == 0 then HordeData[Name] = ScoreData;
        else AllianceData[Name] = ScoreData end;
        if UserIsMe(Name) then
          NewBGScoresData.M, MeData = ScoreData, ScoreData;
        end
      end
    end
    local List = { };
    for Name, Data in pairs(NamesData) do
      List[Name] = Data;
    end
    local Id = 1;
    local ThisNext, ThisNextId, ActiveData;
    while TableSize(List) > 0 do
      ThisNext = 0;
      for Name, Data in pairs(List) do
        if Data.KB >= ThisNext then
          ThisNextId = Name;
          ThisNext = Data.KB;
          ActiveData = Data;
        end
      end
      ActiveData.RN = Id;
      RanksData[Id] = ActiveData;
      Id = Id + 1;
      List[ThisNextId] = nil;
    end
    if NewBGScoresData.W then
      if NewBGScoresData.E then
        if NewBGScoresData.W == 0 then
          NewBGScoresData.W = "green team";
        elseif NewBGScoresData.W == 1 then
          NewBGScoresData.W = "yellow team";
        end
      else
        if NewBGScoresData.W == 0 then
          NewBGScoresData.W = "Horde";
        elseif NewBGScoresData.W == 1 then
          NewBGScoresData.W = "Alliance";
        end
      end
    end
    if not InitsData.BGScores then
      InitsData.BGScores = true;
      BGScoresData = NewBGScoresData;
      return;
    end
    if not BGScoresData.W and NewBGScoresData.W then
      if SettingEnabled("bgreprt") then
        SendChat("<The "..NewBGScoresData.W.." have won this battleground!>");
        if IsInBattleground() == "Alterac Valley" then
          PlaySoundFile("Sound/INTERFACE/PVPVictory"..
            NewBGScoresData.W.."Mono.ogg");
        end
      end
      CreateTimer(GetDynSetting("dbgalt"), LeaveBattlefield, 1,
        "LBFT");
      if MeData then
        SendChat("<Score position "..MeData.RN.." of "..NewBGScoresData.C..
          " with "..MeData.KB.." kills and "..MeData.DE.." deaths>");
      end
    end
    BGScoresData = NewBGScoresData;
  end,
  -- Raid roster has been updated --------------------------------------------
  GROUP_ROSTER_UPDATE = function()
    local ActiveGroupData, NewData, AltGroupData, AltNewData;
    if IsInBattleground() then
      ActiveGroupData = GroupBGData;
      NewData = GetGroupData();
      AltGroupData = GroupData;
      AltNewData = AltGroupData.D;
    else
      ActiveGroupData = GroupData;
      NewData = GetGroupData();
      AltGroupData = GroupBGData;
      AltNewData = CreateBlankGroupArray();
    end
    if not InitsData.Raid then
      InitsData.Raid = true;
      ActiveGroupData.D = NewData;
      AltGroupData.D = AltNewData;
      return;
    end
    local OldRaidData = ActiveGroupData.D;
    ActiveGroupData.D = NewData;
    AltGroupData.D = AltNewData;
    UpdateGroupTrackData(OldRaidData, NewData);
  end,
  -- A combat log event has occured ------------------------------------------
  COMBAT_LOG_EVENT_UNFILTERED = function()
    -- Ignore if stats not available or not in chat or if...
    if not bStatsEnabled or nCombatTime == 0 or
      -- ...in battleground and we don't want to log bg stats
      (not bStatsInBG and IsInBattleground()) then return end;
    -- Build arguments array
    local aArgs = { CombatLogGetCurrentEventInfo() };
    -- Get data for event and return if we haven't made data for the event
    local aData = CombatStatsEventsData[aArgs[2]];
    if not aData then return end;
    -- Grab frequently used vars from the array
    local iTime, sSName, iSFlags, sDName, iDFlags =
      aArgs[1], aArgs[5], aArgs[6], aArgs[9], aArgs[10];
    -- Check source flags. We only care if it is to do with me, the party,
    -- or the raid.
    if BAnd(iSFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 or
       BAnd(iSFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) ~= 0 or
       BAnd(iSFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) ~= 0 then
      local sName = sSName or sDName;
      if BAnd(iSFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 then
        for sVar, aVar in pairs(aData[1]) do
          local iArg = aVar[1];
          if not iArg or aArgs[iArg] then
            StatsSet(iTime, sDName, iSFlags, sVar, sName, aArgs[aVar[2]] or 1,
              aArgs[aVar[3]] or aVar[5], aVar[4]);
          end
        end
      elseif BAnd(iSFlags, COMBATLOG_OBJECT_TYPE_PET) ~= 0 then
        for sVar, aVar in pairs(aData[1]) do
          local iArg = aVar[1];
          if not iArg or aArgs[iArg] then
            StatsSet(iTime, sDName, iSFlags, sVar, sName, aArgs[aVar[2]] or 1,
              nil, aVar[4]);
          end
        end
      end
    end
    -- Check destination flags. We only care if it is to do with me, the party,
    -- or the raid.
    if BAnd(iDFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 or
       BAnd(iDFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) ~= 0 or
       BAnd(iDFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) ~= 0 then
      local sName = sDName or sSName;
      if BAnd(iDFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 then
        for sVar, aVar in pairs(aData[2]) do
          local iArg = aVar[1];
          if not iArg or aArgs[iArg] then
            StatsSet(iTime, sDName, iSFlags, sVar, sName, aArgs[aVar[2]] or 1,
              aArgs[aVar[3]] or aVar[5], aVar[4]);
          end
        end
      elseif BAnd(iDFlags, COMBATLOG_OBJECT_TYPE_PET) ~= 0 then
        for sVar, aVar in pairs(aData[2]) do
          local iArg = aVar[1];
          if not iArg or aArgs[iArg] then
            StatsSet(iTime, sDName, iSFlags, sVar, sName, aArgs[aVar[2]] or 1,
              nil, aVar[4]);
          end
        end
      end
    end
  end,
  -- The guild roster was updated --------------------------------------------
  GUILD_ROSTER_UPDATE = function()
    -- New guild data
    local aNames, aIndexes, aConnected, aDisconnected = { }, { }, { }, { };
    local aNewData = { N=aNames, I=aIndexes, C=aConnected, D=aDisconnected };
    -- Get init count for this event
    local iInitCount = InitsData.Guild;
    -- If not in guild then we're done
    if not IsInGuild() then
      -- Set data
      GuildData = aNewData;
      -- Guild data initialised
      InitsData.Guild = true;
      -- Done
      return;
    end
    -- Get number of guild members and if no members?
    local iCount = GetNumGuildMembers();
    if iCount <= 0 then
      -- Set data
      GuildData = aNewData;
      -- Guild data initialised
      InitsData.Guild = true;
      -- Done
      return;
    end
    -- Get realm
    local sRealm = sMyRealm;
    -- Iterate through them all
    for iIndex = 1, iCount do
      -- Get member information
      local sName, sRank, iRank, iLevel, sClass, sZone, sNote, sONote,
        bOnline, iStatus, _, iAPoints, iARank, bMobile, bSoR, iRep =
          GetGuildRosterInfo(iIndex);
      if sName then
        -- Remove realm if it is mine
        local sNewName, sNewRealm = sName:match("^(.-)%-(.+)$");
        -- Make data
        local aNewData = {
          N  = sName,    RS = sRank,  RI = iRank,   L = iLevel,  C = sClass,
          Z  = sZone,    NN = sNote,  NO = sONote,  O = bOnline, S = iStatus,
          AP = iAPoints, AR = iARank, M  = bMobile, SR = bSoR,   R = iRep,
          SN = sNewName, SR = sNewRealm, SM = sNewRealm == sRealm
        };
        -- Assign as name and insert as index
        aNames[sName], aNames[sNewName] = aNewData, aNewData;
        tinsert(aIndexes, aNewData);
        -- Add user to connected or disconnected lists
        if bOnline then tinsert(aConnected, aNewData);
                   else tinsert(aDisconnected, aNewData) end;
      end
    end
    -- Set guild data
    GuildData = aNewData;
    -- Done if data already initialised
    if iInitCount then return end;
    -- Data initialised
    InitsData.Guild = true;
    -- If there is no one online?
    if #aConnected == 0 then
      Print("None of your "..#aIndexes.." guild members are online.");
    -- Guild members online
    else
      -- Names that are connected
      local aConnNames = { };
      -- For each connected member
      for iI = 1, #aConnected do
        -- Get member data
        local aData = aConnected[iI];
        -- If is on my server, use short name else use long name
        if aData.SM then tinsert(aConnNames, aData.SN);
                    else tinsert(aConnNames, aData.N) end;
      end
      -- Sort names
      sort(aConnNames);
      -- Now build a string from those names
      local sMsg = "Guild Online ("..#aConnected.."/"..#aIndexes.."): ";
      for iI = 1, #aConnNames do
        -- Get name and add it to the string
        local sName = aConnNames[iI];
        sMsg = sMsg.."|Hplayer:"..sName.."|h"..sName.."|h";
        -- Add a comma
        if iI < #aConnNames then sMsg = sMsg..", " end;
      end
      -- Print all the people that are online
      Print(sMsg..".", ChatTypeInfo.GUILD);
    end
  end,
  -- The friends list is updated ---------------------------------------------
  FRIENDLIST_UPDATE = function()
    -- Counter ignoring friends updates
    local iIgnoreFriendsUpdates = 0;
    -- Timer event
    local function OnFriendListTimerTick()
      -- When we automatically update the friend note, we will need to ignore
      -- these events that will trigger after we do that.
      if iIgnoreFriendsUpdates > 0 then
        iIgnoreFriendsUpdates = iIgnoreFriendsUpdates - 1;
        return;
      end
      -- New friends data (A=all, L=online, O=offline)
      local aNData = { };
      -- Total number of battle.net friends
      local iFriendsBN = BNGetNumFriends();
      -- Get number of local friends and add to grand total
      local iFriendsLocal = C_FriendList.GetNumFriends();
      -- Total number of local and battle.net friends
      local iFriendsTotal = iFriendsBN + iFriendsLocal;
      -- If we're tracking friends?
      local bTrack = SettingEnabled("trackfr");
      -- Get current date and time
      local sTime = date("%d/%m %H:%M");
      -- For each battle.net friend
      for iI = 1, max(iFriendsBN, iFriendsLocal) do
        -- Get info about the local friend and if local friend is online?
        local aData = C_FriendList.GetFriendInfoByIndex(iI);
        local bOnline = aData.connected;
        if bOnline then
          local sIGName, iLv, sClass, sZone, sNote =
            aData.name, aData.level, aData.className, aData.area,
            aData.notes;
          local sStatus = "ONLINE";
          if aData.afk then sStatus = sStatus.."+AFK" end;
          if aData.dnd then sStatus = sStatus.."+DND" end;
          if aData.mobile then sStatus = sStatus.."+MOBILE" end;
          -- Set name and realm (local friends are always on my server)
          local sNameAndRealm = sIGName.."-"..sMyRealm;
          -- Prepare data
          local aData = { I=iI,L=iLv,S=sStatus,C=sClass,A=sZone,O=bOnline,
            N=sIGName,E=sNote,R=sMyRealm,NR=sNameAndRealm };
          -- Assign to data
          aNData[sNameAndRealm] = aData;
          tinsert(aNData, aData);
          -- Set note if we're tracking data and the player has not set a
          -- note for them already and user.S is online?
          if bTrack and (not sNote or
                             #sNote == 0 or
                             sNote:sub(1, 1) == "<") then
            -- Set new message
            local sNew = "<"..iLv.." "..sClass.."; "..sTime.."; "..sZone..">";
            -- Set last known data for friend if it changed?
            if sNote ~= sNew then
              -- Set the new note
              C_FriendList.SetFriendNotes(sIGName, sNew);
              -- This will trigger another event so make sure we ignore it
              iIgnoreFriendsUpdates = iIgnoreFriendsUpdates + 1;
            end
          end
        end
        -- Get info about the battle.net friend and if they're online?
        local aBNData = C_BattleNet.GetGameAccountInfoByID(iI);
        if aBNData and aBNData.isOnline then
          -- Get info about the battle.net friend in-game status and if
          -- playing world of warcraft? We need the realm and zone as well
          -- because they are not updated instantly.
          sIGName = aBNData.characterName;
          sRealm = aBNData.realmDisplayName;
          if sIGName and
             aBNData.clientProgram == BNET_CLIENT_WOW and
             #sRealm > 0 and aBNData.areaName then
            -- Set name and realm
            local sNameAndRealm = sIGName.."-"..sRealm;
            -- Get status
            local sStatus;
            if aBNData.isGameAFK then sStatus = "<AFK>"
            elseif aBNData.isGameBusy then sStatus = "<DND>" end;
            -- Prepare data
            local aData = { I = iI, L = iLv, O = bOnline, E = sNote,
                            N = sIGName, B = aBNData.characterName, R = sRealm,
                            NR = sNameAndRealm, A = sZone, S = sStatus,
                            BN = true };
            -- Assign to data
            aNData[sNameAndRealm] = aData;
            tinsert(aNData, aData);
            -- Set note if we're tracking data and the player has not set a
            -- note for them already and user is online?
            if bTrack and sZone and
               (not sNote or
                #sNote == 0 or
                sNote:sub(1, 1) == "<") then
              -- Set new message
              local sNew = "<Last seen @ "..sTime.." on "..sNameAndRealm.." "..
                "(Lv."..iLv.." "..sClass..") in "..sZone..">";
              -- Set last known data for friend if it changed?
              if sNote ~= sNew then
                -- Set the new note
                C_BattleNet.BNSetFriendNote(iPId, sNew);
                -- This will trigger another event so make sure we ignore it
                iIgnoreFriendsUpdates = iIgnoreFriendsUpdates + 1;
              end
            end
          end
        end
      end
      -- Friends data not initialised?
      if not InitsData.Friends then
        -- Have friends and setting to show friends data enabled?
        if iFriendsTotal > 0 and SettingEnabled("showfrn") then
          -- Online friends list
          local aOnline = { };
          -- For each friend online
          for iI = 1, #aNData do
            -- Get friend data
            local aData = aNData[iI];
            -- Is battle.net friend?
            local sName = aData.B;
            if sName then tinsert(aOnline,
              "|HBNplayer:"..sName..":0|h"..sName.."|h");
            -- Is not bnet friend
            else
              -- Name to add to list
              local sName;
              -- Is logged in on my realm? Use name without realm name
              if aData.R == sMyRealm then sName = aData.N;
              -- Is not logged in on my realm? Use name with realm name
              else sName = aData.NR end;
              -- Add to online list
              tinsert(aOnline, "|Hplayer:"..sName..":0|h"..sName.."|h");
            end
          end
          -- Message to echo
          local sMsg;
          -- Friends are online?
          if #aOnline > 0 then
            -- Sort the online list
            sort(aOnline);
            -- Echo out the list
            sMsg = "Friends Online ("..#aOnline.."/"..iFriendsTotal.."): "..
              strjoin(", ", unpack(aOnline))..".";
          -- All friends offline
          else
            sMsg = "None of your "..iFriendsTotal.." friends are online.";
          end
          -- Dispatch message
          Print(sMsg, ChatTypeInfo.SYSTEM);
        end
        -- Friends data initialised
        InitsData.Friends = true;
        -- Set friends data so we can compare if this event occurs again
        FriendsData = aNData;
        -- Done!
        return;
      end
      -- If we're tracking friends?
      if bTrack and SettingEnabled("trackfa") then
        -- For each friend in the updated data
        for iI = 1, #aNData do
          -- Get friend data, name, and old data
          local aNFData = aNData[iI];
          local sIGName = aNFData.NR;
          local aOFData = FriendsData[sIGName];
          -- If user is still online and not in my party?
          if aOFData then
            -- Get status and old status and if status changed?
            local sNStatus, sOStatus = aNFData.S, aOFData.S;
            if sNStatus and (not sOStatus or sOStatus ~= sNStatus) then
              Print(MakePlayerLink(sIGName).." is now "..sNStatus:sub(2, -2),
                ChatTypeInfo.SYSTEM);
            -- Status removed?
            elseif not sNStatus and sOStatus then
              Print(MakePlayerLink(sIGName).." is no longer "..
                sOStatus:sub(2, -2), ChatTypeInfo.SYSTEM);
            end
            -- Location changed?
            local sNLoc, sOLoc = aNFData.A, aOFData.A;
            if sNLoc ~= sOLoc then
              Print(MakePlayerLink(sIGName).." is now in "..sNLoc,
                ChatTypeInfo.SYSTEM);
            end
            -- Level changed?
            local iNLv, iOLv = aNFData.L, aOFData.L;
            if iNLv ~= iOLv then
              Print(MakePlayerLink(sIGName).." is now level "..iNLv,
                ChatTypeInfo.SYSTEM) end;
          else Print(MakePlayerLink(sIGName).." just logged in to "..
            aNFData.A, ChatTypeInfo.SYSTEM) end;
        -- If user wasn't logged in?
        end
        -- For each friend in the old data
        for iI = 1, #FriendsData do
          -- Get friend data, name, and old data
          local aOFData = FriendsData[iI];
          local sIGName = aOFData.NR;
          local aNFData = aNData[sIGName];
          -- If user went offline
          if not aNFData then Print(MakePlayerLink(sIGName)..
            " logged off in "..aOFData.A, ChatTypeInfo.SYSTEM) end;
        end
      end
      -- Set new friends data
      FriendsData = aNData;
    end
    -- Actual event function. Prevent multiple updates in a short time
    local function OnUpdate()
      CreateTimer(1.0, OnFriendListTimerTick, 1, "FLU");
    end
    -- Set actual function and call it for the first time
    EventsData.FRIENDLIST_UPDATE = OnUpdate;
    OnUpdate();
  end,
  -- The guild bank window has been closed -----------------------------------
  GUILDBANKFRAME_CLOSED = function() BlockTrades(false) end,
  -- The guild bank window has been shown ------------------------------------
  GUILDBANKFRAME_OPENED = function() BlockTrades(true) end,
  -- The bank window has been closed -----------------------------------------
  BANKFRAME_CLOSED = function() BlockTrades(false) end,
  -- The bank window has been shown ------------------------------------------
  BANKFRAME_OPENED = function() BlockTrades(true) end,
  -- The mail window has been shown ------------------------------------------
  MAIL_SHOW = function() BlockTrades(true) end,
  -- The mail window has been closed -----------------------------------------
  MAIL_CLOSED = function() BlockTrades(false) end,
  -- Achievement completed ---------------------------------------------------
  ACHIEVEMENT_EARNED = function(iAId)
    -- Ignore if auto-announce achievement progress is disabled
    if not SettingEnabled("autoaap") or not iAId then return end;
    -- Send achievement to chat or echo
    SendChat("<(Complete!)"..GetAchievementLink(iAId)..">");
  end,
  -- Achievement criteria completed ------------------------------------------
  CRITERIA_EARNED = function(iAId, sCr) -- sCr is name string of objective
    -- Ignore if auto-announce achievement progress is disabled
    if not SettingEnabled("autoaap") then return end;
    -- Send achievement progress to chat
    SendChat("<(Done!)["..sCr.."]"..GetAchievementLink(iAId)..">");
    -- Add header text and play sound
    PlaySound(SOUNDKIT.UI_QUEST_ROLLING_FORWARD_01);
  end,
  -- Players money changes ---------------------------------------------------
  PLAYER_MONEY = function()
    local Money = GetMoney();
    if Money == iMoney then return end;
    local Change = Money - iMoney;
    -- Cache current value
    iMoney = Money;
    -- Done if money values not initialised
    if not InitsData.Money then InitsData.Money = true return end;
    -- Update money gained this session
    iMoneySession = iMoneySession + Change;
    -- Done if we're not tracking money
    if not SettingEnabled("advtrak") then return end;
    -- Put current value in stats too so we can see this amount of money on
    -- other players
    MoneyData.nTotal = Money;
    -- Make changes to income/expend/session totals
    if Change > 0 then
      MoneyData.nIncTotal = MoneyData.nIncTotal + Change;
      MoneyData.nIncSesTotal = MoneyData.nIncSesTotal + Change;
    else
      MoneyData.nExpTotal = MoneyData.nExpTotal + -Change;
      MoneyData.nExpSesTotal = MoneyData.nExpSesTotal + -Change;
    end
    -- Get time
    local Time = time();
    -- Calulate all-time seconds session and if valid?
    local nSec = Time - MoneyData.nTimeStart;
    if nSec < 1 then nSec = 1 end;
    -- Calculate different units
    local nMin, nHour, nDay, nWeek, nMonth, nYear =
      nSec/60,     nSec/3600,    nSec/86400,
      nSec/604800, nSec/2419200, nSec/29030400;
    -- Calculate session income
    local nIncome = MoneyData.nIncTotal;
    MoneyData.nIncSec, MoneyData.nIncMin = nIncome / nSec, nIncome / nMin;
    MoneyData.nIncHr, MoneyData.nIncDay = nIncome / nHour, nIncome / nDay;
    MoneyData.nIncWk, MoneyData.nIncMon = nIncome / nWeek,nIncome / nMonth;
    MoneyData.nIncYr = nIncome / nYear;
    -- Calculate session expendature
    local nExpend = MoneyData.nExpTotal;
    MoneyData.nExpSec, MoneyData.nExpMin = nExpend / nSec, nExpend / nMin;
    MoneyData.nExpHr, MoneyData.nExpDay = nExpend / nHour, nExpend / nDay;
    MoneyData.nExpWk, MoneyData.nExpMon = nExpend / nWeek,nExpend / nMonth;
    MoneyData.nExpYr = nExpend / nYear;
    -- Calulate seconds session and ignore if invalid
    local nSesSec = Time - MoneyData.nTimeSes;
    if nSesSec <= 0 then return true end;
    -- Calculate different units
    local nSesMin, nSesHour, nSesDay, nSesWeek, nSesMonth, nSesYear =
      nSesSec / 60,     nSesSec / 3600,    nSesSec / 86400,
      nSesSec / 604800, nSesSec / 2419200, nSesSec / 29030400;
    -- Calculate session income
    local nSesInc = MoneyData.nIncSesTotal;
    MoneyData.nIncSesSec = nSesInc / nSesSec;
    MoneyData.nIncSesMin = nSesInc / nSesMin;
    MoneyData.nIncSesHr = nSesInc / nSesHour;
    MoneyData.nIncSesDay = nSesInc / nSesDay;
    MoneyData.nIncSesWk = nSesInc / nSesWeek;
    MoneyData.nIncSesMon = nSesInc / nSesMonth;
    MoneyData.nIncSesYr = nSesInc / nSesYear;
    -- Calculate session expendature
    local nSesExp = MoneyData.nExpSesTotal;
    MoneyData.nExpSesSec = nSesExp / nSesSec;
    MoneyData.nExpSesMin = nSesExp / nSesMin;
    MoneyData.nExpSesHr = nSesExp / nSesHour;
    MoneyData.nExpSesDay = nSesExp / nSesDay;
    MoneyData.nExpSesWk = nSesExp / nSesWeek;
    MoneyData.nExpSesMon = nSesExp / nSesMonth;
    MoneyData.nExpSesYr = nSesExp / nSesYear;
    -- Message to output
    local sMsg;
    if Change > 0 then
      sMsg = "Received "..MakeMoneyReadable(Change).."! (Now: "..
        MakeMoneyReadable(Money);
    else
      sMsg = "Spent "..MakeMoneyReadable(-Change).."! (Left: "..
        MakeMoneyReadable(Money);
    end
    if iMoneySession ~= 0 then
      sMsg = sMsg.."; Session: "..
        MakeMoneyReadable(iMoneySession);
    end
    Print(sMsg..")", ChatTypeInfo.MONEY);
  end,
  -- Artifact power updated --------------------------------------------------
  ARTIFACT_XP_UPDATE = function(...)
    -- Last item details
    local iIdLast, iTotalLast;
    -- Get tables and functions
    local nsAI = C_AzeriteItem;
    assert(type(nsAI)=="table");
    local funcFAAI = nsAI.FindActiveAzeriteItem;
    assert(type(funcFAAI)=="function");
    local funcGAIXPI = nsAI.GetAzeriteItemXPInfo;
    assert(type(funcGAIXPI)=="function");
    local funcGPL = nsAI.GetPowerLevel;
    -- Actual event
    local function Event()
      -- Find an active azerite item and return if not found
      local aItemLoc = funcFAAI();
      if not aItemLoc then return end;
      -- Get equipped artefact data and return if none
      local iAXP, iAXPMax = funcGAIXPI(aItemLoc);
      if not iAXP then return end;
      -- Get level and return if none
      local iLevel = funcGPL(aItemLoc);
      if not iLevel then return end;
      -- Get name of item
      local aIData = Item:CreateFromItemLocation(aItemLoc);
      if not aIData then return end;
      -- If is new item
      local iId = aIData:GetItemID();
      if not iId then return end;
      -- Caluclate XP total;
      local iTotal = (iAXPMax * iLevel) + iAXP;
      -- Is same item from last?
      if iId == iIdLast then
        -- Calculations
        local nPercent = iAXP / iAXPMax * 100;
        local iGain = iTotal - iTotalLast;
        if iGain ~= 0 then
          local iNext = iAXPMax - iAXP;
          -- Prepare message
          local sMsg = "Received "..FormatNumber(iGain)..
            " AXP! ("..GetItemInfo(iId).."; "..RoundNumber(nPercent, 2)..
            "%; Next: "..FormatNumber(iNext);
          -- Calculate remaining count
          local iLeft = ceil(iNext / iGain);
          if iLeft > 0 then sMsg = sMsg.."; x"..FormatNumber(iLeft) end;
          -- Dispatch message
          Print(sMsg..")", ChatTypeInfo.COMBAT_XP_GAIN);
        end
      end
      -- Set new id and xp values
      iIdLast = iId;
      iTotalLast = iTotal;
    end
    -- Set and call actual function for first time
    EventsData.ARTIFACT_XP_UPDATE = Event;
    Event(...);
  end,
  -- Player experience updated -----------------------------------------------
  PLAYER_XP_UPDATE = function()
    local iCur, iLv, iGain = UnitXP("player"), UnitLevel("player");
    if iLv == iLevel then iGain = iCur - iCurrentXP;
    else iGain, iLevel = iXPLeft + iCur, iLv end;
    local iMax = UnitXPMax("player");
    local iLeft = iMax - iCur;
    -- Cache new values
    iCurrentXP = iCur;
    iXPMax = iMax;
    iXPLeft = iLeft;
    -- Done if values not initialised
    if not InitsData.XP then InitsData.XP = true return end;
    -- Done if no XP gained
    if iGain == 0 then return end;
    -- Cache session values
    iXPSession = iXPSession + iGain;
    iXPGainsLeft = iLeft / iGain;
    -- Set message to show
    local sMsg = "Received "..FormatNumber(iGain).." XP! ("..
      RoundNumber(iCurrentXP/iXPMax*100, 2).."%; Next: "..
      FormatNumber(iXPLeft);
    if iXPGainsLeft > 0 then
      sMsg = sMsg.."; x"..FormatNumber(ceil(iXPGainsLeft));
    end
    Print(sMsg..")", ChatTypeInfo.COMBAT_XP_GAIN);
  end,
  -- Player pvp kills has changed? -------------------------------------------
  PLAYER_PVP_KILLS_CHANGED = function()
    -- Use a timer so we don't spam the chat with updates
    local iCur, iLv, iGain = UnitHonor("player"), UnitHonorLevel("player");
    if iLv == iHonourLevel then iGain = iCur - iHonour;
    else iGain, iHonourLevel = iHonourLeft + iCur, iLv end;
    local iMax = UnitHonorMax("player");
    local iLeft = iMax - iCur;
    -- Cache new values
    iHonour = iCur;
    iHonourMax = iMax;
    iHonourLeft = iLeft;
    -- Done if not initialised yet
    if not InitsData.Honour then InitsData.Honour = true return end;
    if iGain <= 0 then return end;
    -- Update session values
    iHonourSession = iHonourSession + iGain;
    iHonourGainsLeft = iLeft / iGain;
    -- Prepare message
    local sMsg = "Received "..FormatNumber(iGain).." HXP! ("..
      RoundNumber(iHonour/iHonourMax*100, 2).."%; Next: "..
      FormatNumber(iHonourLeft);
    if iHonourGainsLeft > 0 then
      sMsg = sMsg.."; x"..FormatNumber(ceil(iHonourGainsLeft));
    end
    Print(sMsg..")", ChatTypeInfo.COMBAT_HONOR_GAIN);
--    TextStatusBar_UpdateTextString(HonorWatchBar.OverlayFrame.Text);
  end,
  -- Exhaustion updated ------------------------------------------------------
  UPDATE_EXHAUSTION = function()
  end,
  -- Asked to pickup BoP item ------------------------------------------------
  LOOT_BIND_CONFIRM = function()
    if GroupData.D.C > 0 or not SettingEnabled("autogre") then return end;
    ClickDialogButton("LOOT_BIND", 1);
  end,
  -- Loot is available to roll on --------------------------------------------
  START_LOOT_ROLL = function(LootId)
    local _, Name, Count, Quality, BoP, _, CanGreed, CanDis =
      GetLootRollItemInfo(LootId);
    local What, Command;
    if CanDis and SettingEnabled("autodis") then
      if not BoP or GroupData.D.C <= 0 then
        if Quality == 3 and not SettingEnabled("autogrb") or Quality > 3 then
          return;
        end
        What = "disenchanting";
        Command = 3;
      end
    elseif SettingEnabled("autogre") then
      if not CanGreed then
        return;
      elseif not BoP or GroupData.D.C <= 0 then
        if Quality == 3 and not SettingEnabled("autogrb") or Quality > 3 then
          return;
        end
        What = "greeding";
        Command = 2;
      end
    elseif SettingEnabled("autopas") then
      if Quality > 2 then
        return;
      end
      What = "passing";
      Command = 0;
    end
    if What and Command then
      local sMsg = "Automatically "..What.." on "..
        (GetLootRollItemLink(LootId) or Name);
      if Count > 1 then
        sMsg = sMsg.."x"..BreakUpLargeNumbers(Count);
      end
      Print(sMsg);
      RollOnLoot(LootId, Command);
    end
  end,
  -- The players currency counts have changed --------------------------------
  CURRENCY_DISPLAY_UPDATE = function(...)
    -- Variables
    local CurrencyInitialised = false;
    -- Tables and functions
    local nsCI = C_CurrencyInfo;
    assert(type(nsCI)=="table");
    local funcGCLI = nsCI.GetCurrencyListInfo;
    assert(type(funcGCLI)=="function");
    local funcECL = nsCI.ExpandCurrencyList;
    assert(type(funcECL)=="function");
    local funcGCLL = nsCI.GetCurrencyListLink;
    assert(type(funcGCLL)=="function");
    -- Actual functions
    EventsData.CURRENCY_DISPLAY_UPDATE = function()
      -- New currency data and collapse data as we need tp expand headers
      local aNCData = { };
      -- Get first item and if we have it?
      local CurrencyItem = funcGCLI(1);
      if CurrencyItem then
        -- Id's that need to be collapsed
        local CurrencyCollapse = { };
        -- Current index and header
        local CurrencyIndex, CurrencyHeaderCurrent = 1;
        -- Process current item
        repeat
          -- Get currency name
          local CurrencyName = CurrencyItem.name;
          -- If it's a header?
          if CurrencyItem.isHeader then
            -- Set header name for currency items
            CurrencyHeaderCurrent = CurrencyName;
            -- If header is not expanded?
            if not CurrencyItem.isHeaderExpanded then
              -- Collapse this header at the end
              tinsert(CurrencyCollapse, CurrencyIndex);
              -- Do the expand
              funcECL(CurrencyIndex, true);
            end
          -- It's not a header?
          else
            -- Store link and amount
            local sLink = funcGCLL(CurrencyIndex)
            if sLink then aNCData[sLink] = CurrencyItem.quantity end;
          end
          -- Increment currency id
          CurrencyIndex = CurrencyIndex + 1;
          -- Grab next item info
          CurrencyItem = funcGCLI(CurrencyIndex)
        -- Break if invalid or loop to process new item
        until not CurrencyItem;
        -- Collapse expanded sections
        for CurrencyIndex = #CurrencyCollapse, 1, -1 do
          funcECL(CurrencyIndex, false);
        end
      end
      -- Values not initialised yet?
      if not CurrencyInitialised then
        -- OK, this is annoying. When you login to a server, Blizzard can send
        -- multiple events which can trigger showing changes but not during a
        -- a /reload so we will need to cancel them out with our timer. One
        -- second should be enough time to initialise the currency list.
        return CreateTimer(1, function()
          CurrencyInitialised = true;
          CurrencyData = aNCData;
        end, 1, "CI");
      end
      -- Reset obsolete items
      for sLink, iNCount in pairs(CurrencyData) do
        if not aNCData[sLink] then aNCData[sLink] = 0 end;
      end
      -- Check for new or used items
      for sLink, iNCount in pairs(aNCData) do
        -- Get old count and if different from new count
        local iOCount = CurrencyData[sLink] or 0;
        if iOCount ~= iNCount then
          -- Get used or recieved
          local sWhat, iValue;
          if iNCount < iOCount then
            sWhat, iValue = "Used", iOCount - iNCount;
          elseif iNCount > iOCount then
            sWhat, iValue = "Received", iNCount - iOCount;
          end
          -- Only one item?
          if iValue == 1 then iValue = sEmpty;
          -- More than one item?
          else iValue = "x"..BreakUpLargeNumbers(iValue) end;
          -- Print message to chat
          Print(sWhat.." currency "..sLink..iValue.." (Total: "..
            BreakUpLargeNumbers(iNCount)..")",
            ChatTypeInfo.CURRENCY);
        end
      end
      -- Store new data
      CurrencyData = aNCData;
    end
    -- Run for first time
    EventsData.CURRENCY_DISPLAY_UPDATE(...);
  end,
  -- Artifact history is ready -----------------------------------------------
--[[ FIXNE
  ARTIFACT_HISTORY_READY = function(IgnoreInit)
    local NewArchaeologyData, ItemCount, Count =
      { }, 0, GetNumArchaeologyRaces();
    for Index = 1, Count do
      _, _, _, ItemCount = GetArchaeologyRaceInfo(Index);
      if ItemCount and ItemCount > 0 then
        NewArchaeologyData[Index] = ItemCount;
      end
    end
    if not InitsData.Archaeology then
      if not IgnoreInit then
        InitsData.Archaeology = true;
        ArchaeologyData = NewArchaeologyData;
      end
      return;
    end
    for ItemId, ItemCount in pairs(NewArchaeologyData) do
      Count = ArchaeologyData[ItemId] or 0;
      if not Count or Count ~= ItemCount then
        local What, Value;
        if ItemCount < Count then
          What, Value = "Used", Count - ItemCount;
        elseif ItemCount > Count then
          What, Value = "Received", ItemCount - Count;
        end
        if Value > 0 then
          if Value == 1 then Value = sEmpty;
          else Value = "x"..BreakUpLargeNumbers(Value) end
          local Name, _, _, _, Extra = GetArchaeologyRaceInfo(ItemId);
          local sMsg = What.." ".."artefact |Hspell:80451|h|cffffafff["..Name..
            "]|r|h"..Value.." (Total: "..BreakUpLargeNumbers(ItemCount);
          if Extra > 0 then
            sMsg = sMsg.."; Max: "..BreakUpLargeNumbers(Extra);
            local Percent = ItemCount/Extra*100;
            if Percent < 100 then
              sMsg = sMsg.."; "..RoundNumber(Percent, 2).."%";
            else
              sMsg = sMsg.."; Complete";
            end
          end
          sMsg = sMsg..")";
          Print(sMsg, ChatTypeInfo["CURRENCY"]);
        end
      end
    end
    ArchaeologyData = NewArchaeologyData;
  end,
--]]
  -- The players bags have changed -------------------------------------------
  BAG_UPDATE_DELAYED = function()
    -- Bag data
    local aNBagsData, aNBagData = { }, { };
    -- Include equipment in the unified bag slots too
    local aIData = { };
    aNBagsData.I = aIData;
    for iSId = 1, 23 do
      -- Get item id and if we get it?
      local iItemId = GetInventoryItemID("player", iSId);
      if iItemId then
        -- Get item link and if we get it?
        local sLink = GetInventoryItemLink("player", iSId);
        if sLink then
          -- Build fake item data
          local aItem = {
            fakeitem = true,
            hyperlink = sLink,
            itemID = iItemId,
            quality = GetInventoryItemQuality("player", iSId),
            stackCount = 1
          };
          -- Set slot in inventory data
          aIData[iSId] = aItem;
          -- Get existing unified count and stack it if found
          local aNItem = aNBagData[iItemId];
          if aNItem then aNItem.stackCount = aNItem.stackCount + 1;
          -- Not added yet so add it
          else aNBagData[iItemId] = aItem end;
        end
      end
    end
    -- Enumerate keyring, backpack, the four additional bags and reagent bag
    for iIndex = 1, #BagUpdateData do
      -- Get bag id
      local iBId = BagUpdateData[iIndex];
      -- Initialise individual bag
      local aBData = { };
      aNBagsData[iBId] = aBData;
      -- Enumerate through the bags slots
      for iSId = 1, C_Container.GetContainerNumSlots(iBId) do
        -- Get item link and if it is valid?
        local aData = C_Container.GetContainerItemInfo(iBId, iSId);
        if aData then
          -- Assign bag/slot data
          aBData[iSId] = aData;
          -- Get item id
          local iItemId = aData.itemID;
          -- Get existing unified count and stack it if found
          local aNItem = aNBagData[iItemId];
          if aNItem then
            aNItem.stackCount = aNItem.stackCount + aData.stackCount;
          -- First instance of this item
          else
            -- Record bag and slot id
            aData.slotID, aData.bagID = iSId, iBId;
            -- Assign data to unified bag
            aNBagData[iItemId] = aData;
          end
        end
      end
    end
    -- Entered world? BAG_UPDATE fires before PLAYER_ENTERING_WPRLD
    if InitsData.Bags then
      -- Check new bag data
      for iItemId, aNItem in pairs(aNBagData) do
        -- Check for item in old unified bags
        local aOItem = BagData[iItemId];
        -- Get old stack count or initialise it to zero and if more?
        local iNTotal, iOTotal = aNItem.stackCount;
        if aOItem then iOTotal = aOItem.stackCount else iOTotal = 0 end;
        if iNTotal > iOTotal then
          -- Get information about item
          local sLink = aNItem.hyperlink;
          local iQuantity = iNTotal - iOTotal;
          local sName, _, _, iLv, _, sType, sSType = GetItemInfo(sLink);
          -- Start building message
          local sMsg = "Received "..sLink;
          if iQuantity > 1 then
            sMsg = sMsg.."x"..BreakUpLargeNumbers(iQuantity);
          end
          sMsg = sMsg.."! (Total: "..BreakUpLargeNumbers(iNTotal);
          if iLv and iLv > 1 then sMsg = sMsg.."; Lv: "..iLv end;
          if sSType and sSType ~= "Other" then
            sMsg = sMsg.."; Type: "..sSType;
          elseif sType then sMsg = sMsg.."; Type: "..sType end
          Print(sMsg..")", ChatTypeInfo.LOOT);
          iQuantity = mhtrack[sName];
          if iQuantity then
            sMsg = "[Tracker]"..sLink;
            if iNTotal >= iQuantity then
              sMsg = sMsg.."(Done!)";
              mhtrack[sName] = nil;
              if TableSize(mhtrack) < 1 then
                local sMsg2 = "The final task in your tracking "..
                  "list has been completed!";
                PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE);
                HudMessage(sMsg2, 1, 1, 0);
                Print(sMsg2);
              end
              PlaySound(SOUNDKIT.UI_QUEST_ROLLING_FORWARD_01);
            else
              sMsg = sMsg.."("..iNTotal.."/"..iQuantity..")";
              PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT);
            end
            SendChat("<"..sMsg..">");
            HudMessage(sMsg, 1, 1, 0);
          end
        end
      end
      -- Check for items removed. Enumerate old bag data
      for iItemId, aOItem in pairs(BagData) do
        -- Check for item in new unified bags
        local aNItem = aNBagData[iItemId];
        -- Get old stack count or initialise it to zero and if more?
        local iOTotal, iNTotal = aOItem.stackCount;
        if aNItem then iNTotal = aNItem.stackCount else iNTotal = 0 end;
        if iNTotal < iOTotal then
          -- Get information about item
          local sLink = aOItem.hyperlink;
          local sName, _, _, iLv, _, sType, sSType = GetItemInfo(sLink);
          -- Start building message
          local aParts, sMsg = { };
          -- Item was removed? Say that it was removed with quantity
          if iNTotal == 0 then sMsg = "Removed "..sLink;
          -- Only dispensed partially?
          else
            -- Say that it was dispensed with quantity
            sMsg = "Dispensed "..sLink;
            -- Add total remaining
            tinsert(aParts, "Remain: "..BreakUpLargeNumbers(iNTotal));
          end
          -- Add quantity to end of string
          local iQuantity = iOTotal - iNTotal;
          if iQuantity > 1 then
            sMsg = sMsg.."x"..BreakUpLargeNumbers(iQuantity) end;
          -- Have an item level?
          if iLv and iLv > 1 then tinsert(aParts, "Lv: "..iLv) end;
          -- Have a secondary type and not 'Other'?
          if sSType and
             sSType ~= "Other" then tinsert(aParts, "Type: "..sSType);
          -- Have a primary type instead?
          elseif sType then tinsert(aParts, "Type: "..sType) end;
          -- Build string with extended information if we have it
          if #aParts > 0 then
            Print(sMsg.."! ("..strjoin("; ", unpack(aParts))..")",
              ChatTypeInfo.LOOT);
          -- Basic information (impossible I think but just incase)
          else Print(sMsg.."!", ChatTypeInfo.LOOT) end;
        end
      end
    -- Now initialised
    else InitsData.Bags = true end;
    -- Set new individual and unified bags data
    BagsData, BagData = aNBagsData, aNBagData;
  end,
  -- Someone pinged the minimap ----------------------------------------------
  MINIMAP_PING = function(sUnit, nX, nY)
    -- Ignore if setting not enabled
    if not SettingEnabled("showwmp") then return end;
    -- Ignore if unit is invalido the player
    if not UnitExists(sUnit) then return end;
    -- Get unit's name
    local sName = UnitName(sUnit) or sUnit;
    -- Get current time and clear timedout anti-spam table entries
    local nTime = GetTime();
    for sName, nTimeout in pairs(MapPingerData) do
      if nTime >= nTimeout then MapPingerData[sName] = nil end;
    end
    -- Ignore if unit already clicked the minimap recently or pinger was me.
    -- Note that the server can ping the minimap too but that is in the player
    -- name which is dissapointing so we'll just ignore it anyway.
    if MapPingerData[sName] or sName == sMyName then return end;
    -- Message to send
    local sMsg = " pinged the minimap ";
    -- Calculate distance
    nY = -nY;
    local nDist = sqrt(math.pow(nX, 2) + math.pow(nY, 2));
    if nDist < 0.05 then sMsg = sMsg.."on you!";
    else
      if     nDist < 0.15 then nDist = "near";
      elseif nDist < 0.30 then nDist = "far";
      elseif nDist < 0.45 then nDist = "very far";
      else                     nDist = "extremely far" end;
      -- Calculate angle
      local nAngle = ((1 + (atan2(nY, nX) / 360)) - 0.75) % 1;
      if     nAngle >= 0.9375 or
             nAngle <  0.0625 then nAngle = "north";
      elseif nAngle <  0.1875 then nAngle = "north-east";
      elseif nAngle <  0.3125 then nAngle = "east";
      elseif nAngle <  0.4375 then nAngle = "south-east";
      elseif nAngle <  0.5625 then nAngle = "south";
      elseif nAngle <  0.6875 then nAngle = "south-west";
      elseif nAngle <  0.8125 then nAngle = "west";
      elseif nAngle <  0.9375 then nAngle = "north-west";
      else                         nAngle = "unknown" end;
      sMsg = sMsg.."bearing "..nDist.." "..nAngle.."!";
    end
    -- Get player position and print it in chat
    Print(MakePlayerLink(sName)..sMsg, {r=1,g=0,b=1});
    HudMessage(sName..sMsg, 1, 0, 1);
    -- Set timeout before player can trigger another message
    MapPingerData[sName] = nTime + 1;
  end,
  -- A units' name has been updated ------------------------------------------
  UNIT_NAME_UPDATE = function() EventsData.GROUP_ROSTER_UPDATE() end,
  -- a Units pet has changed -------------------------------------------------
  UNIT_PET = function() EventsData.GROUP_ROSTER_UPDATE() end,
  -- Mail has been received --------------------------------------------------
  UPDATE_PENDING_MAIL = function()
    if not SettingEnabled("autonnm") or not HasNewMail() then
      LastNewMail = { };
      return;
    end
    local NewMail = { GetLatestThreeSenders() };
    for Id, Sender in pairs(NewMail) do
      if Sender == sEmpty then
        Sender = "<Unknown>";
        NewMail[Id] = Sender;
      end
      if not LastNewMail[Sender] then
        LastNewMail[Sender] = true;
        local sMsg = Sender.." has sent you new mail";
        Print(sMsg);
        HudMessage(sMsg, 1.0, 1.0, 1.0);
        PlaySound(SOUNDKIT.MAP_PING);
      end
    end
    for _, Sender in pairs(LastNewMail) do
      if not NewMail[Sender] then LastNewMail[Sender] = nil end;
    end
  end,
  -- PvP objective headers on HUD changed ------------------------------------
--[[ FIXME
  UPDATE_WORLD_STATES = function()
    local BG = IsInBattleground();
    if not BG or (BG ~= "Arathi Basin" and
           BG ~= "Eye of the Storm") then return end;
    local ABase, ARes, AMRes = AlwaysUpFrame1Text:GetText():
      match("^Bases%:%s-([-%d]+)%s-.+%:%s-([-%d]+)%/([-%d]+)%s-");
    local HBase, HRes, HMRes = AlwaysUpFrame2Text:GetText():
      match("^Bases%:%s-([-%d]+)%s-.+%:%s-([-%d]+)%/([-%d]+)%s-");
    ABase, HBase = tonumber(ABase or 0) or 0, tonumber(HBase or 0) or 0;
    ARes,  HRes  = tonumber(ARes  or 0) or 0, tonumber(HRes  or 0) or 0;
    AMRes, HMRes = tonumber(AMRes or 0) or 0, tonumber(HMRes or 0) or 0;
    local R = { 0, .5, 1.25, 2.5, 5, 30 };
    local BGArathiData = {
      AL = math.floor((AMRes-ARes)/R[ABase+1]),
      HL = math.floor((HMRes-HRes)/R[HBase+1]),
      HR = HRes,
      AR = ARes;
    }
    AlwaysUpFrame1Text:SetText(format("%02u:%02u  %.1f%%  %u/%u",
      (BGArathiData.AL/60)%100, BGArathiData.AL%60, (ARes/AMRes)*100,
      ABase, ARes));
    AlwaysUpFrame2Text:SetText(format("%02u:%02u  %.1f%%  %u/%u",
      (BGArathiData.HL/60)%100, BGArathiData.HL%60, (HRes/HMRes)*100,
      HBase, HRes));
  end,
--]]
  -- Instance data has been updated ------------------------------------------
  UPDATE_INSTANCE_INFO = function()
    local Data, Count, Time, Total = { }, GetNumSavedInstances(), time(), 0;
    for Index = 1, Count do
      local Name, _, Remain, Diff = GetSavedInstanceInfo(Index);
      if Remain > 0 then
        Data[Name.."_"..Diff], Data[Index] = Time+Remain, Name.."_"..Diff;
        Total = Total+1;
      end
    end
    local Name = GetInstanceName();
    if Name ~= "World_1" then
      local Remain = GetInstanceLockTimeRemaining();
      if not Data[Name] then
        Total = Total+1;
        Data[Total] = Name;
        Data[Name] = Time+Remain;
      elseif Remain > 0 then
        Data[Name] = Time+Remain;
      end
      if Name ~= sLastInstance then
        if GetOptOutOfLoot() then
          local sMsg;
          if SettingEnabled("autodpl") then
            sMsg = "Loot eligability has been automatically enabled!";
            SetOptOutOfLoot(false);
          else
            sMsg = "You have entered an instance with loot disabled. "..
                   "Enable eligability if you don't want to miss loot!";
          end
          Print(sMsg, { r=1.0, g=0.25, b=0 });
        end
        if bStatsInstance then StatsClear(true, false) end;
        sLastInstance = Name;
      end
    end
    Data[0] = Total;
    InstanceData = Data;
  end,
}; -- End of events -----------------------------------------------------------
-- == Main frame events for a unit ============================================
UnitEventsData = {
  -- A player event has occured / beginning with player health ----------------
  player = { UNIT_HEALTH = function()
    if nCombatTime == 0 or bInDuel or not SettingEnabled("autoalh") or
      UnitIsDeadOrGhost("player") or
      (UnitHealth("player")/UnitHealthMax("player"))*100 >=
      GetDynSetting("dlht") or
      GetTime() <= bLowHealth or not GetNearestUnit() then return end;
    DoEmote("healme");
    bLowHealth = GetTime() + GetDynSetting("dlswi");
  end,
  -- Player inventory has changed ---------------------------------------------
  UNIT_INVENTORY_CHANGED = function()
    -- Update artefact XP
    EventsData.ARTIFACT_XP_UPDATE();
    -- Level not initialised?
    if iItemLevel == -1 then
      -- Get item level, set it and return
      local _, iEqILv = GetAverageItemLevel();
      iItemLevel = iEqILv;
      -- Done
      return;
    end
    -- Use a timer so we don't have this triggered multiple times
    CreateTimer(0.5, function()
      -- Cache updated artefact values
      EventsData.ARTIFACT_XP_UPDATE();
      -- Check item level
      local _, iEqILv = GetAverageItemLevel();
      if iEqILv == iItemLevel then return end;
      -- Item level raised?
      if iEqILv > iItemLevel then
        -- Report raise
        Print("Average item level raised from "..iItemLevel.." to "..
          iEqILv.."!", {r=0,g=1,b=0.75});
      -- Item level dropped?
      else
        -- Report reduction
        Print("Average item level dropped from "..iItemLevel.." to "..
          iEqILv.."!", {r=1,g=0,b=0.75});
      end
      -- Set new item level
      iItemLevel = iEqILv;
    end, 1, "UIC");
  end,
  -- Player flags changed -----------------------------------------------------
  PLAYER_FLAGS_CHANGED = function()
    if UnitIsAFK("player") then
      if SettingEnabled("autopol") and GroupData.D.C > 0 then
        PassOnLoot(false);
      end
      if nAwayFromKeyboard == 0 and SettingEnabled("awaytim") then
        CreateTimer(1, function()
          if nAwayFromKeyboard == 0 then return true end;
          local Duration = GetTime()-nAwayFromKeyboard;
          local AnimId = floor(Duration%5);
          local LeftIndicator, RightIndicator = sEmpty, sEmpty;
          for Index = 1, AnimId do LeftIndicator, RightIndicator =
            LeftIndicator.."<", RightIndicator..">" end;
          local ManaBar =
            PlayerFrame.PlayerFrameContent.
            PlayerFrameContentMain.ManaBarArea.ManaBar.TextString;
          ManaBar:SetTextColor(1, 1, 1);
          ManaBar:SetText(LeftIndicator..
            format(" AFK %02u:%02u ", Duration/60%60,
              Duration%60)..RightIndicator);
        end, nil, "AFKT", true);
      end
      nAwayFromKeyboard = GetTime();
    elseif nAwayFromKeyboard ~= 0 then
      PassOnLoot(true);
      KillTimer("AFKT");
      PlayerFrame_GetManaBar():UpdateTextString();
      ShowDelayedWhispers();
      nAwayFromKeyboard = 0;
    end
    if UnitIsDND("player") then nDoNotDisturb = GetTime();
    elseif nDoNotDisturb ~= 0 then
      ShowDelayedWhispers();
      nDoNotDisturb = 0;
    end
    if UnitAffectingCombat("player") then EventsData.PLAYER_REGEN_DISABLED();
    else EventsData.PLAYER_REGEN_ENABLED() end;
  end,
  -----------------------------------------------------------------------------
  UNIT_ENTERED_VEHICLE = function()
  end,
  -----------------------------------------------------------------------------
  UNIT_EXITED_VEHICLE = function()
    local oDpsFrame = MhMod.DpsDataFrame;
    oDpsFrame:SetParent(PlayerFrame);
    oDpsFrame:SetPoint("BOTTOMRIGHT", PlayerFrame, "TOPRIGHT", -40, -41 );
  end,
  -----------------------------------------------------------------------------
  UNIT_DISPLAYPOWER = function()
  end,
  -----------------------------------------------------------------------------
  UNIT_POWER_UPDATE = function()
    if nCombatTime == 0 or bInDuel or not SettingEnabled("autoalm") or
      UnitPowerType("player") ~= 0 or UnitIsDeadOrGhost("player") or
      (UnitMana("player")/UnitManaMax("player"))*100 >=
        GetDynSetting("dlmt") or
      GetTime() <= bLowMana or not GetNearestUnit() then return end;
    DoEmote("oom");
    bLowMana = GetTime() + GetDynSetting("dlswi");
  end },
  -----------------------------------------------------------------------------
  party1 = { UNIT_TARGET = function() UnitFrameUpdate(PartyMemberFrame1) end },
  party2 = { UNIT_TARGET = function() UnitFrameUpdate(PartyMemberFrame2) end },
  party3 = { UNIT_TARGET = function() UnitFrameUpdate(PartyMemberFrame3) end },
  party4 = { UNIT_TARGET = function() UnitFrameUpdate(PartyMemberFrame4) end },
  target = { UNIT_TARGET = function() UnitFrameUpdate(TargetFrameToT) end },
  -----------------------------------------------------------------------------
};
-- == Chat frame hook events =================================================
-- Parameters:-
-- ---------------------------------------------------------------------------
--  1 message       = The message thats received (string)
--  2 sender        = The sender's username. (string)
--  3 language      = The language the message is in. (string)
--  4 channelString = The full name of the channel, including number. (string)
--  5 target        = The username of the target of the action. Not used by all
--                    events. (string)
--  6 flags         = The various chat flags. Like, DND, AFK, GM. (string)
--  7 unknown       = This variable has an unkown purpose, although it may be
--                    some sort of internal channel id. That however is not
--                    confirmed. (number)
--  8 channelNumber = The numeric ID of the channel. (number)
--  9 channelName   = The full name of the channel, does not include the
--                    number. (string)
-- 10 unknown       = This variable has an unkown purpose although it always
--                    seems to be 0. (number)
-- 11 counter       = This variable appears to be a counter of chat events
--                    that the client recieves. (number)
-- 12 guid          = This variable appears to contain the globally unique ID
--                    for the player character who whispered you (guid)
-- ---------------------------------------------------------------------------
local ChatEventsData =                 -- Chat event hooks
{ -- -- Battlenet whisper ----------------------------------------------------
  CHAT_MSG_BN_WHISPER = function(_, _, Msg, User, _, _, _, _, _, _, _, _,
      MsgId, _, UserId)
    -- Delay whispers if neccesary
    if WhisperIsDelayed(Msg, User, MsgId, UserId) then return 1 end;
    -- Play whisper sound
    PlaySound(SOUNDKIT.TELL_MESSAGE);
    -- Whisper is allowed
    return MakePrettyName("BN_WHISPER", Msg, User, "B.Net", sEmpty, "BN",
      MsgId);
  end,
  -- Battlenet whisper sent ---------------------------------------------------
  CHAT_MSG_BN_WHISPER_INFORM = function(_, _, Msg, User, _, _, _, _, _, _, _,
      _, _, _, MsgId)
    -- Do not show automated responses
    if iBNWhisperReplySent > 0 then
      iBNWhisperReplySent = max(0, iBNWhisperReplySent - 1);
      return 1;
    end
    return MakePrettyName("BN_WHISPER_INFORM", Msg, User, "B.Net", sEmpty, "BN",
      MsgId);
  end,
  -- -- Whisper sent to me ---------------------------------------------------
  CHAT_MSG_WHISPER = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _, _, _,
      MsgId)
    -- Reply colour
    local Colour = { r=1, g=0, b=0 };
    if not UserIsExempt(User) then
      if Flag == "GM" then return;
      elseif IsFlooding(User) then return 1;
      elseif IsSpam(Msg) then
        Print("A whisper was blocked from "..MakePlayerLink(User, MsgId)..
          " due to spamming", Colour);
        SendResponse(User, "Your message was not received because there is "..
          "spam detected in your message. Please remove any references to "..
          "external addresses and try again. You might also want to check "..
          "your punctuation and grammar");
        return 1;
      elseif IsBegger(Msg) then
        Print("A whisper was blocked from "..MakePlayerLink(User, MsgId)..
          " due to begging", Colour);
        SendResponse(User, "Your message was not received because begging "..
          "is not tolerated by this player");
        return 1;
      elseif SettingEnabled("blockwh") then
        Print("A whisper from "..MakePlayerLink(User, MsgId).." was blocked",
          Colour);
        SendResponse(User, "Your message was not received because all "..
          "whisper's are blocked. Please use the public channel");
        return 1;
      elseif SettingEnabled("blockwb") and IsInBattleground() and
          FindPartySlot(User:match("(.*)-.*") or User) then
        Print("A battleground whisper from "..MakePlayerLink(User, MsgId)..
          " was blocked", Colour);
        SendResponse(User, "Your message was not received because all "..
          "battleground whisper's are blocked");
        return 1;
      elseif Msg:sub(1, 1) == "!" then
        Print("Client command from "..MakePlayerLink(User, MsgId)..
          " disallowed", Colour);
        return 1;
      elseif WhisperIsDelayed(Msg, User, MsgId) then return 1 end;
    elseif SettingEnabled("command") and Msg:sub(1, 1) == "!" then
      local ThrottleData = CommandThrottleData[User] or 0;
      if time() < ThrottleData then return 1 end;
      CommandThrottleData[User] = time() + 1;
      local Command = Msg:match("^%!(%w+)");
      if not Command or Command == sEmpty then
        Print("An invalid command syntax from "..MakePlayerLink(User, MsgId)..
          " was ignored", Colour);
        SendWhisper(User, "Please specify the command name");
      elseif not RemoteCommandsData[Command] then
        Print("An invalid command from "..MakePlayerLink(User, MsgId)..
          " was ignored", Colour);
        SendWhisper(User, "The command '"..Command.."' is invalid");
      else
        local sDCmds =
          (GetDynSetting("dpcd") or sEmpty):lower();
        if #sDCmds > 0 and sDCmds ~= "none" then
          for _, sDCmd in pairs({ strsplit(" ", sDCmds) }) do
            if sDCmd == Command then
              Print(MakePlayerLink(User, MsgId)..
                " tried to execute disabled command "..Command, Colour);
              SendWhisper(User, "That command has been disabled");
              return 1;
            end
          end
        end
        RemoteCommandsData[Command](User, Msg);
      end
      return 1;
    end
    if SettingEnabled("whstlsa") and UserIsExempt(User) then
      PlaySound(SOUNDKIT.TELL_MESSAGE);
    else
      local LastWhisperTime = WhisperData[User];
      if not LastWhisperTime or time() >= LastWhisperTime then
        WhisperData[User] = time() + CHAT_TELL_ALERT_TIME;
        PlaySound(SOUNDKIT.TELL_MESSAGE);
      end
    end
    return MakePrettyName("WHISPER", Msg, User, Lang, Chan, Flag, MsgId);
  end,
  -- -- AFK message was received ---------------------------------------------
  CHAT_MSG_AFK = function(_, _, Msg, User)
    if not SettingEnabled("noaspam") then return end;
    local Time = time();
    for Name, Data in pairs(AutoMsgData) do
      if Data.AFKUpdate and
          Time - Data.AFKUpdate >= GetDynSetting("damet") then
        if not Data.AFKUpdate then AutoMsgData[Name] = nil;
        else Data.AFKUpdate, Data.AFKMessage = nil end;
      end
    end
    if not AutoMsgData[User] then AutoMsgData[User] = { } end;
    local Data = AutoMsgData[User];
    if Data.AFKMessage and Data.AFKMessage == Msg then return 1 end;
    Data.AFKUpdate, Data.AFKMessage = Time, Msg;
  end,
  -- -- DND message was received ---------------------------------------------
  CHAT_MSG_DND = function(_, _, Msg, User)
    if not SettingEnabled("noaspam") then return end;
    local Time = time();
    for Name, Data in pairs(AutoMsgData) do
      if Data.DNDUpdate and
          Time - Data.DNDUpdate >= GetDynSetting("damet") then
        if not Data.DNDUpdate then AutoMsgData[Name] = nil;
        else Data.DNDUpdate, Data.DNDMessage = nil end;
      end
    end
    if not AutoMsgData[User] then AutoMsgData[User] = { } end;
    local Data = AutoMsgData[User];
    if Data.DNDMessage and Data.DNDMessage == Msg then return 1 end;
    Data.DNDUpdate, Data.DNDMessage = Time, Msg;
  end,
  -- -- Something was created using tradeskills ------------------------------
  CHAT_MSG_TRADESKILLS = function(_, _, Msg, User)
    if SettingEnabled("advtrak") and Msg:sub(1, 4) == "You " then return 1 end;
  end,
  -- -- Someone is looting ---------------------------------------------------
  CHAT_MSG_LOOT = function(_, _, Msg, User)
    if Msg:find("^You [cr]") or Msg:find("^Received ") then
      if SettingEnabled("advtrak") then return 1 end;
    elseif SettingEnabled("smartfi") and IsInBattleground() then return 1 end;
  end,
  -- -- Reputation changed ---------------------------------------------------
  CHAT_MSG_COMBAT_FACTION_CHANGE =
    function() return SettingEnabled("advtrak") end,
  -- -- Honor gained ---------------------------------------------------------
  CHAT_MSG_COMBAT_HONOR_GAIN = function() return SettingEnabled("advtrak") end,
  -- -- Experience gained ----------------------------------------------------
  CHAT_MSG_COMBAT_XP_GAIN = function() return SettingEnabled("advtrak") end,
  -- -- Currency amount changed ----------------------------------------------
  CHAT_MSG_CURRENCY = function() return SettingEnabled("advtrak") end,
  -- -- Money changed --------------------------------------------------------
  CHAT_MSG_MONEY = function() return SettingEnabled("advtrak") end,
  -- -- Print received from a channel --------------------------------------
  CHAT_MSG_CHANNEL = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _,
      Channel, _, MsgId, _)
    if iLastChannelMsgId == MsgId then return 1 end;
    iLastChannelMsgId = MsgId;
    if UserIsExempt(User) then
      return MakePrettyName("CHANNEL", Msg, User, Lang, Chan, Flag, MsgId);
    elseif not IsPublicSpam(Msg, User, "channel") then
      if not SettingEnabled("trfiltr") or Channel ~= "Trade - City" then
        return MakePrettyName("CHANNEL", Msg, User, Lang, Chan, Flag, MsgId);
      end
      local LoweredMsg = Msg:lower();
      for _, Pattern in pairs({
        "lf%s", "wts", "wtt", "wtb", "buying", "selling", "%|h", "trading",
        "trade",
      }) do
        if LoweredMsg:find(Pattern) then
          return MakePrettyName("CHANNEL", Msg, User, Lang, Chan, Flag, MsgId);
        end
      end
    end
    return 1;
  end,
  -- -- Print received from a guild officer --------------------------------
  CHAT_MSG_OFFICER = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _, _,
      _, MsgId, _)
    return MakePrettyName("OFFICER", Msg, User, Lang, Chan, Flag, MsgId);
  end,
  -- -- Print received from a party leader ---------------------------------
  CHAT_MSG_PARTY_LEADER = function(_, _, sMsg, sUser, sLang, sChan, _, sFlag,
      _, _, _, _, iMsgId)
    return HandleChatEvent(sMsg, sUser, sLang, sChan, sFlag, iMsgId, "(PL) ",
      "PARTY_LEADER");
  end,
  -- -- Print received from a party member ---------------------------------
  CHAT_MSG_PARTY = function(_, _, sMsg, sUser, sLang, sChan, _, sFlag, _, _, _,
      _, iMsgId)
    return HandleChatEvent(sMsg, sUser, sLang, sChan, sFlag, iMsgId, "(P) ",
      "PARTY");
  end,
  -- -- Print received from a raid member ----------------------------------
  CHAT_MSG_RAID = function(_, _, sMsg, sUser, sLang, sChan, _, sFlag, _, _, _,
      _, iMsgId)
    return HandleChatEvent(sMsg, sUser, sLang, sChan, sFlag, iMsgId, "(R) ",
      "RAID");
  end,
  -- -- Print received from a instance member ----------------------------------
  CHAT_MSG_INSTANCE_CHAT = function(_, _, sMsg, sUser, sLang, sChan, _, sFlag,
      _, _, _, _, iMsgId)
    return HandleChatEvent(sMsg, sUser, sLang, sChan, sFlag, iMsgId, "(I) ",
      "INSTANCE_CHAT");
  end,
  -- -- Print received from a instance member ----------------------------------
  CHAT_MSG_INSTANCE_CHAT_LEADER = function(_, _, sMsg, sUser, sLang, sChan, _,
      sFlag, _, _, _, _, iMsgId, _)
    return HandleChatEvent(sMsg, sUser, sLang, sChan, sFlag, iMsgId, "(IL) ",
      "INSTANCE_CHAT_LEADER");
  end,
  -- -- Print received from a raid leader ----------------------------------
  CHAT_MSG_RAID_LEADER = function(_, _, sMsg, sUser, sLang, sChan, _, sFlag, _,
      _, _, _, iMsgId, _)
    return HandleChatEvent(sMsg, sUser, sLang, sChan, sFlag, iMsgId, "(RL) ",
      "RAID_LEADER");
  end,
  -- -- Print received from a raid leader or assistant ---------------------
  CHAT_MSG_RAID_WARNING = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _,
      _, _, MsgId, _)
    if not SettingEnabled("blockrw") then
      RaidNotice_AddMessage(RaidWarningFrame, Msg,
        ChatTypeInfo.RAID_WARNING);
      PlaySound(SOUNDKIT.RAID_WARNING);
    end
    return MakePrettyName("RAID_WARNING", Msg, User, Lang, Chan, Flag, MsgId);
  end,
  -- Print received from a guild member -------------------------------------
  CHAT_MSG_GUILD = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _, _, _,
      MsgId, _)
    return MakePrettyName("GUILD", Msg, User, Lang, Chan, Flag, MsgId);
  end,
  -- -- Print received from a nearby player ---------------------------------
  CHAT_MSG_SAY = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _, _, _,
      MsgId, _)
    if not UserIsExempt(User) then
      if IsFlooding(User) or IsBegger(Msg) or
        IsPublicSpam(Msg, User, "say") then return 1 end;
    end
    return MakePrettyName("SAY", Msg, User, Lang, Chan, Flag, MsgId);
  end,
  -- -- Someone is gathering reagents ----------------------------------------
  CHAT_MSG_OPENING = function(_, _, Msg)
    local Name = Msg:match("^(.+)%s+");
    if Name ~= "You" and SettingEnabled("smartfi") and
      not UserIsExempt(Name) then return 1 end;
  end,
  -- -- Print emote received from a nearby player --------------------------
  CHAT_MSG_TEXT_EMOTE = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _, _,
      _, MsgId, _)
    if not UserIsExempt(User) and IsFlooding(User) then return 1 end;
    return MakePrettyName("TEXT_EMOTE", Msg, sEmpty, Lang, Chan, "EM", MsgId);
  end,
  -- -- Custom message emote received from a nearby player -------------------
  CHAT_MSG_EMOTE = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _, _, _,
      MsgId, _)
    if not UserIsExempt(User) then
      if IsFlooding(User) or IsBegger(Msg) then return 1 end;
      if IsPublicSpam(Msg, User, "emote") then return 1 end;
    end
    return MakePrettyName("EMOTE", Msg, User, Lang, Chan, "EM", MsgId), nil;
  end,
  -- -- Yell message received from a NPC -----------------------------------
  CHAT_MSG_MONSTER_YELL = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _,
      _, _, MsgId, _)
    if SettingEnabled("blockns") and IsResting() then return 1 end;
    if SettingEnabled("bgavnms") and "Alterac Valley"==IsInBattleground() then
      local aYellList = BGYellData[User];
      if aYellList then for iI = 1, #aYellList do
        local aYellData = aYellList[iI];
        local M1, M2 = Msg:match(aYellData.S);
        if M1 then
          local iT, sR, sC, sM = aYellData.T, aYellData.R;
          if     iT==0 then sC,sM="BG_SYSTEM_ALLIANCE", sR;
          elseif iT==1 then sC,sM="BG_SYSTEM_HORDE", sR;
          elseif iT==2 then sC,sM="BG_SYSTEM_"..M2:upper(),format(sR,M1,M2);
          elseif iT==3 then sC,sM="BG_SYSTEM_"..M1:upper(),format(sR,M1,M2);
          elseif iT==4 then sC,sM="BG_SYSTEM_NEUTRAL", format(sR,M1) end;
          if sM then Print(sM, ChatTypeInfo[sC]) return 1 end;
        end
      end end
    end
    return MakePrettyName("MONSTER_YELL", Msg, User, Lang, Chan, "NPC", MsgId);
  end,
  -- -- Print received from a nearby NPC -----------------------------------
  CHAT_MSG_MONSTER_SAY = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _,
      _, _, MsgId, _)
    if SettingEnabled("blockns") and IsResting() then return 1 end;
    return MakePrettyName("MONSTER_SAY", Msg, User, Lang, Chan, "NPC", MsgId);
  end,
  -- -- Whisper received from a nearby NPC ------------------------------------
  CHAT_MSG_MONSTER_WHISPER = function(_, _, Msg, User, Lang, Chan, _, Flag, _,
      _, _, _, MsgId, _)
    return MakePrettyName("MONSTER_WHISPER", Msg, User, Lang, Chan, "NPC",
      MsgId);
  end,
  -- -- Yell message received from a player -----------------------------------
  CHAT_MSG_YELL = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _, _, _,
      MsgId, _)
    if not UserIsExempt(User) then
      if IsFlooding(User) or IsBegger(Msg) then return 1 end;
      if IsPublicSpam(Msg, User, "yell") then return 1 end;
    end
    return MakePrettyName("YELL", Msg, User, Lang, Chan, Flag, MsgId);
  end,
  -- -- Print received from a player in a battleground ------------------------
  CHAT_MSG_BATTLEGROUND = function(_, _, Msg, User, Lang, Chan, _, Flag, _, _,
      _, _, MsgId, _)
    if not UserIsExempt(User) then
      if SettingEnabled("blockbg") or IsFlooding(User) then return 1 end;
      if IsPublicSpam(Msg, User, "pvp") then return 1 end;
    end
    return MakePrettyName("BATTLEGROUND", Msg, User, Lang, Chan, Flag, MsgId);
  end,
  -- -- Print received from a leader in a battleground ------------------------
  CHAT_MSG_BATTLEGROUND_LEADER = function(_, _, Msg, User, Lang, Chan, _, Flag,
      _, _, _, _, MsgId, _)
    if not UserIsExempt(User) then
      if SettingEnabled("blockbg") or IsFlooding(User) then return 1 end;
      if IsPublicSpam(Msg, User, "pvp leader") then return 1 end;
    end
    return MakePrettyName("BATTLEGROUND_LEADER", Msg, User, Lang, Chan, Flag,
      MsgId);
  end,
  -- -- Print sent confirmation to another player --------------------------
  CHAT_MSG_WHISPER_INFORM = function(_, _, Msg, User, Lang, Chan, _, Flag, _,
      _, _, _, MsgId, _)
    if iWhisperReplySent > 0 then
      iWhisperReplySent = max(0, iWhisperReplySent - 1);
      if bAutoClearAFKDisabled then
        bAutoClearAFKDisabled = false;
        SetCVar("autoClearAFK", "1");
      end
      return 1;
    end
    if UserIsMe(User) then return 1 end;
    WhisperExemptData[User] = time()+GetDynSetting("dwiet");
    return MakePrettyName("WHISPER_INFORM", Msg, User, Lang, Chan, Flag,
      MsgId);
  end,
  -- -- Achievement message received -----------------------------------------
  CHAT_MSG_ACHIEVEMENT = function(_, _, Msg, User)
    if SettingEnabled("smartfi") and not UserIsExempt(User) then return 1 end;
    return MakePrettyName("ACHIEVEMENT", format(Msg, MakePlayerLink(User)),
      sEmpty, sEmpty, sEmpty, sEmpty, sEmpty, 0);
  end,
  -- -- Guild achievement message received -----------------------------------
  CHAT_MSG_GUILD_ACHIEVEMENT = function(_, _, Msg, User)
    if SettingEnabled("smartfi") and not UserIsExempt(User) then return 1 end;
    return MakePrettyName("GUILD_ACHIEVEMENT",
      format(Msg, MakePlayerLink(User)), sEmpty, sEmpty, sEmpty, sEmpty, sEmpty, 0);
  end,
  -- -- System message received ----------------------------------------------
  CHAT_MSG_SYSTEM = function(_, _, Msg)
    if SettingEnabled("autonos") then
      local aCTISystem = ChatTypeInfo.SYSTEM;
      for _, V in pairs({
        { S="MONEY_FRAME_OPEN",  R=0, G=1, B=0,
          M="You won an auction for .+" },
        { S="MONEY_FRAME_OPEN",  R=0, G=1, B=0,
          M="A buyer has been found for your auction of .+%." },
        { S="IG_BACKPACK_OPEN",  R=1, G=0, B=0,
          M="Your auction of .+ has expired%." },
        { S="IG_BACKPACK_CLOSE", R=1, G=0, B=0,
          M="You have been outbid on .+%." },
      }) do
        if Msg:find(V.M) then
          HudMessage(Msg, V.R, V.G, V.B);
          PlaySound(SOUNDKIT[V.S]);
          local sMatch = V.M;
          local Item = Msg:match(sMatch:gsub("%.%+", "(.+)"));
          if Item then
            local _, sLink = GetItemInfo(Item);
            if sLink then
              Print(format(sMatch:gsub("%%", sEmpty):gsub("%.%+", "%%s"),
                sLink), aCTISystem);
              return 1;
            end
          end
          return;
        end
      end
    end
    if Msg:find("Quest accepted: .+") then return 1 end;
    if Msg == "Interface action blocked due to addon." then return 1 end;
    if Msg:find("You have requested to trade with .+%.") then
      bTradeStartedByMe = true;
      return;
    end
    if SettingEnabled("advtrak") then
      if (Msg:find("^.+ leaves") or Msg:find("^.+ joins") or
          Msg:find("^.+ has %w+ the %w+ group") or
          Msg:find("^.+ gains [%d,]+ Artifact") or
          Msg:find("^Received ")) then return 1 end;
      if Msg:find("^.+ is busy") then
        bTradeStartedByMe = false;
        return;
      end;
      -- Death
      local sMatch = Msg:match("%|Hdeath:(%d+)");
      if sMatch then
        -- Get durability info
        local Current, Maximum, Percent = GetDurability();
        if Current then Print("You died (|Hdeath:"..sMatch.."|h#"..sMatch..
          "|h)! Durability is now "..BreakUpLargeNumbers(Current).." of "..
          BreakUpLargeNumbers(Maximum).." at "..RoundNumber(Percent, 2)..
          "%!", {r=1,g=0.25,b=0});
        else Print("You died but with no durability loss (|Hdeath:"..sMatch..
          "|h#"..sMatch.."|h)!", {r=0,g=1,b=0});
        end
        return 1;
      end
      return;
    end
    if not bInDuel and Msg:find("Duel starting%: %d") then
      bInDuel = true;
      return;
    end
    if iWhisperReplySent > 0 and
        Msg:find("No player named %'.+%' is currently playing%.") then
      iWhisperReplySent = iWhisperReplySent - 1;
      if iWhisperReplySent < 0 then iWhisperReplySent = 0 end;
      return 1;
    end
    if iIgnorePartyMessage > 0 and
        Msg:find(".+ has invited you to join a group%.") then
      iIgnorePartyMessage = iIgnorePartyMessage - 1;
      return 1;
    end
    if Msg == "You are now saved to this instance" then
      return RequestRaidInfo();
    end
    if SettingEnabled("smartfi") then for _, Match in ipairs({
      "^(.+) has defeated (.+) in a duel",
      "^(.+) has fled from (.+) in a duel",
      "^(.+) seems to be sobering up%.",
      "^(.+) seems a little tipsy from the .+%.",
      "^(.+) looks tipsy%.",
      "^(.+) looks drunk%.",
      "^(.+) is getting drunk off of .+%.",
      "^(.+) is completely smashed from the .+%.",
      "^.+%[(.+)%] has joined the battle.*",
      "^(.+) has joined the battle.*",
      "^(.+) has left the battle",
    }) do
      local First, Second = Msg:match(Match);
      if (First and not UserIsExempt(First)) or
        (Second and not UserIsExempt(Second)) then return 1 end;
    end end
    if SettingEnabled("trackfr") and Msg:find("^.+ has %w+ o.+line%.") then
      TriggerTimer("FART");
    end
    return MakePrettyName("SYSTEM", Msg, sEmpty, sEmpty, sEmpty, sEmpty,
      sEmpty, 0);
  end
};-- -- End of chat events ---------------------------------------------------
-- == Debug a table ==========================================================
DebugTable = function(TableName, String)
  if TableName == nil then
    return ShowInput("Input returned nothing! Refine your specification?",
      "run", String);
  end
  if type(TableName) ~= "table" then
    return ShowInput("Input returned '"..TableName..
      "'! Refine your specification?", "run", String);
  end
  if TableSize(TableName) <= 0 then
    return ShowInput("The evaluated string did not return any data or there "..
      "was an error parsing it! Refine your specification?", "run", String);
  end
  if not String then String = tostring(TableName) end;
  local MaxLevel = 0xFF;
  local Lines = { "|cff0000ffThis is the result of evaluating|r |cff00ff00"..
    String.."|r" };
  local LinePacks = { };
  local Tables = { };
  local function FinishPack()
    tinsert(LinePacks, strjoin(sEmpty, unpack(Lines)));
    Lines = { };
  end
  local function AddLine(sLine)
    tinsert(Lines, sLine);
    if #Lines >= 1000 then FinishPack() end;
  end
  function InternalShowTable(TableName, Level, MaxLevel)
    local Colour, Index, Type = 255-(Level*32), 0;
    local Name = TableName.GetName;
    if type(Name) == "function" then
      Name = Name(TableName);
      if Name then
        AddLine(format(" (|cffffff00"..Name.."|r)...", tostring(Name)));
      else AddLine("...") end;
    else AddLine("...") end;
    for Key, Value in pairs(TableName) do
      Index = Index + 1;
      AddLine(format("|n|cff%02xff%02x%"..(Level*2).."s%u: %s = %s|r",
        Colour, Colour, sEmpty, Index, tostring(Key), tostring(Value)));
      if type(Value) == "table" then
        local AlreadyEnumerated = false;
        for iI = 1, #Tables do
          local Table = Tables[iI]
          if Table == Value then
            AlreadyEnumerated = true;
            break;
          end
        end
        if not AlreadyEnumerated then
          tinsert(Tables, Value);
          if Level + 1 < MaxLevel then
            InternalShowTable(Value, Level + 1, MaxLevel)
          end
        end
      end
    end
    AddLine(format("|n|cff%02xff%02x%"..(Level*2)..
      "sA total of %u items in this table.|r", Colour, Colour, sEmpty, Index));
  end
  InternalShowTable(TableName, 0, MaxLevel or 10);
  FinishPack();
  local sLines = sEmpty;
  for iI = 1, #LinePacks do
    sLines = sLines..LinePacks[iI];
  end
  ShowDialog(sLines, "LUA evaluation", "EDITOR");
end
-- == Client commands ========================================================
LocalCommandsData = {
  quitnow = ForceQuit,
  logout = Logout,
  quit = Quit,
  advert = function()
    SendChat("Using MhMod v"..Version.Release..Version.Extra.." by "..
      Version.Author.." at "..Version.WebsiteFull);
  end,
  lfg = function(sWhat)
    -- Show LFG frame
    PVEFrame:Show();
    -- Select LFG tab
    PVEFrame_ShowFrame("GroupFinderFrame", "LFGListPVEStub");
    -- Select 'Custom' category
    LFGListCategorySelection_SelectCategory(LFGListFrame.CategorySelection,
      6, 0);
    LFGListCategorySelectionFindGroupButton_OnClick(LFGListFrame.
      CategorySelection.FindGroupButton);
    -- If no argument specified?
    if not sWhat or #sWhat == 0 then
      -- Player is targeting something attackable? Use name of mob
      if UnitCanAttack("target", "player") then sWhat = UnitName("target");
      -- Else use zone name
      else sWhat = GetZoneText() end;
    end
    -- Set input text (user must click refresh)
    LFGListFrame.SearchPanel.SearchBox:SetText(sWhat);
  end,
  editsetd = function(Arguments, ArgV, ArgC)
    local CurrentDefault = GetDynSetting("ddfn");
    if ArgC <= 0 then
      return ShowInput("Please specify the default notes filename",
        "editsetd", CurrentDefault)
    end
    local NewDefault = ArgV[1];
    if CurrentDefault == NewDefault then
      return ShowMsg("No change was made to the default filename!");
    end
    SetDynSetting("ddfn", NewDefault);
    ShowMsg("A new default notes filename of |cff7f7f7f"..NewDefault..
      "|r has been set");
  end,
  editren = function(_, ArgV, ArgC)
    if ArgC <= 0 then
      return ShowInput("Please specify the notes file to rename",
        "editren", GetDynSetting("ddfn"));
    end
    local Source = ArgV[1];
    local SourceData = mhnotes[Source];
    if not SourceData then
      return ShowMsg("The specified source filename of |cff7f7f7f"..Source..
        "|r was not matched!", "editren", GetDynSetting("ddfn"));
    end
    if ArgC <= 1 then
      return ShowInput("Please specify the new name of the notes file",
        "editren "..Source, Source.."Renamed");
    end
    local Destination = ArgV[2];
    local DestData = mhnotes[Destination];
    if Source == Destination then
      return ShowMsg("The source and destination specified of |cff7f7f7f"..
        Destination.."|r cannot be the same!", "editren "..Source);
    end
    if DestData then
      return ShowMsg("The specified destination filename of |cff7f7f7f"..
        Destination.."|r already exists!", "editren "..Source);
    end
    mhnotes[Destination] = mhnotes[Source];
    mhnotes[Source] = nil;
    ShowMsg("Notes file |cff7f7f7f"..Source.."|r renamed to |cff7f7f7f"..
      Destination.."|r successfully!");
  end,
  editdup = function(_, ArgV, ArgC)
    if ArgC <= 0 then
      return ShowInput("Please specify the notes file to duplicate", "editdup",
        GetDynSetting("ddfn"));
    end
    local Source = ArgV[1];
    local SourceData = mhnotes[Source];
    if not SourceData then
      return ShowMsg("The specified source filename of |cff7f7f7f"..Source..
        "|r was not matched!", "editdup", GetDynSetting("ddfn"));
    end
    if ArgC <= 1 then
      return ShowInput("Please specify the name of the duplicated notes file",
        "editdup "..Source, Source.."Duplicate");
    end
    local Destination = ArgV[2];
    local DestData = mhnotes[Destination];
    if Source == Destination then
      return ShowMsg("The source and destination specified of |cff7f7f7f"..
        Destination.."|r cannot be the same!", "editdup "..Source);
    end
    if DestData then
      return ShowMsg("The specified destination filename of |cff7f7f7f"..
        Destination.."|r already exists!", "editdup "..Source);
    end
    mhnotes[Destination] = mhnotes[Source];
    ShowMsg("Notes file |cff7f7f7f"..Source.."|r duplicated to |cff7f7f7f"..
      Destination.."|r successfully!");
  end,
  editas = function()
    ShowInput("Please specify the notes file to open. "..
      "If you specify no file then the default is used. "..
      "Specify an invalid file to create a new one!",
      "edit", GetDynSetting("ddfn"));
  end,
  editasro = function()
    ShowInput("Please specify the filename to view. "..
      "If you specify no file then the default is used. "..
      "Specify an invalid file and an error will occur!",
      "editro", GetDynSetting("ddfn"));
  end,
  edit = function(Arguments, ArgV, ArgC)
    local Variable = GetDynSetting("ddfn");
    if ArgC > 0 then Variable = ArgV[1] end;
    local Body = mhnotes[Variable];
    ShowDialog(Body or sEmpty, Variable, "EDITOR", function(Text, Var)
      if #Text > 0 then mhnotes[Var] = Text;
                   else mhnotes[Var] = nil end;
    end);
  end,
  editro = function(Arguments, ArgV, ArgC)
    local Variable = GetDynSetting("ddfn");
    if ArgC > 0 then Variable = ArgV[1] end;
    local Body = mhnotes[Variable];
    if not Body then
      return ShowMsg("The specified filename of |cff7f7f7f"..Variable..
        "|r was not matched and cannot be viewed!", "editasro");
    end
    ShowDialog(Body, Variable, "EDITOR");
  end,
  editdel = function(_, ArgV, ArgC)
    if ArgC <= 0 then
      return ShowInput("Please specify the notes file you want to delete",
        "editdel");
    end
    local File = ArgV[1];
    if not mhnotes[File] then
      return ShowMsg("The notes file named |cff7f7f7f"..File..
        "|r was not matched!", "editdel");
    end
    mhnotes[File] = nil;
    ShowMsg("The notes file named |cff7f7f7f"..File..
      "|r was deleted successfully!");
  end,
  editclr = function(_, ArgV, ArgC)
    local Count = TableSize(mhnotes);
    if Count <= 0 then
      ShowMsg("There are no notes saved!");
      return;
    end
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("A total of |cff7f7f7f"..Count..
        "|r files will be deleted! "..
        "Are you sure you want to reset your notes list?", "editclr confirm");
    end
    mhnotes = { };
    ShowMsg("A total of |cff7f7f7f"..Count.."|r notes were cleared!");
  end,
  editlst = function()
    local Text = "Here is a list of all the notes files that are saved...\n\n";
    Text = Text.."|cffaaaaaaID  FILENAME  PREVIEW|r\n";
    Text = Text.."|cff7f7f7f==========================================|r\n";
    local Count = 0;
    for File, Data in pairs(mhnotes) do
      Count = Count + 1;
      Text = Text.."|cffff0000"..Count.."|r  |cff0000ff"..File..
        "|r  |cff00ff00"..Data:sub(1, 40):gsub("\n", " ").."|r...\n";
    end
    Text = Text.."|cff7f7f7f==========================================|r\n";
    if Count <= 0 then
      return ShowMsg("There are no notes saved!");
    end
    Text = Text.."\nA total of "..Count.." note files saved";
    ShowDialog(Text, "Notes files list", "EDITOR");
  end,
  help = function(Arguments, ArgV, ArgC)
    if ArgC <= 0 then
      return ShowInput("Specify the command or variable you want to lookup",
        "help");
    end
    local Parameter = ArgV[1]:lower();
    local ParameterU = Parameter:upper();
    if CommandExists(Parameter) then
      local cmddata = CommandExists(Parameter);
      ShowDialog("|cffffff00Information about the command...|r\n"..
        "|cff0000ff"..ParameterU..
        "|r\n\n|cffaaaaaaBrief description of command...|r\n"..cmddata.SD..
        ".\n\n|cffaaaaaaDetailed description of command...|r\n"..cmddata.LD..
        ".", "Help for command "..ParameterU, "EDITOR");
    elseif VariableExists(Parameter) then
      local vardata = VariableExists(Parameter);
      local setting;
      if SettingEnabled(Parameter) then
        setting = "|cff00ff00ENABLED|r";
      else
        setting = "|cffff0000DISABLED|r";
      end
      ShowDialog("|cffffff00Information about the variable...|r\n|cff0000ff"..
        ParameterU.."|r\n\n|cffaaaaaaBrief description of variable...|r\n"..
        vardata.SD..".\n\n|cffaaaaaaDetailed description of variable...|r\n"..
        vardata.LD..".\n\n|cff00ff00This setting is currently set to|r "..
        setting..".\n\n|cffaaaaaaTo toggle this setting, type|r |cff0000ff/"..
        ConfigData.Command.." "..Parameter..".|r.",
        "Help for setting "..ParameterU, "EDITOR");
    else
      ShowMsg("The variable or command |cffaaaaaa"..Parameter..
        "|r is not recognised", "help");
    end
  end,
  iglclear = function(_, ArgV, ArgC)
    local Count = C_FriendList.GetNumIgnores();
    if Count <= 0 then
      ShowMsg("Your ignore list is empty!");
      return;
    end
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("A total of |cff7f7f7f"..Count.."|r ignore "..
        "entries will be deleted! Are you sure you want to reset your "..
        "ignore list?", "iglclear confirm");
    end
    for Index = 1, Count do
      C_FriendList.DelIgnore(C_FriendList.GetIgnoreName(Index));
    end
    ShowMsg("A total of |cff7f7f7f"..Count.."|r players removed from your "..
      "ignore list!");
  end,
  frlclear = function(_, ArgV, ArgC)
    local iCount = C_FriendList.GetNumFriends();
    if iCount <= 0 then
      ShowMsg("Your friends list is empty!");
      return;
    end
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("A total of |cff7f7f7f"..Count.."|r friends "..
        "entries will be deleted! Are you sure you want to reset your "..
        "friends list?", "frlclear confirm");
    end
    for Index = 1, iCount do
      C_FriendList.RemoveFriend(
        C_FriendList.GetFriendInfoByIndex(Index).name) end;
    ShowMsg("A total of |cff7f7f7f"..iCount..
      "|r friends removed from your friends list!");
  end,
  fnclear = function(_, ArgV, ArgC)
    local iCount = C_FriendList.GetNumFriends();
    if iCount <= 0 then
      ShowMsg("Your friends list is empty!");
      return;
    end
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("A total of |cff7f7f7f"..iCount..
        "|r friends notes will be cleared! "..
        "Are you sure you want to clear them?", "fnclear confirm");
    end
    local iDone = 0;
    for iFriendIndex = 1, iCount do
      local aData = C_FriendList.GetFriendInfoByIndex(iFriendIndex);
      if aData then
        local sName, sNote = aData.name, aData.notes;
        if sName and sNote and #sNote > 0 then
          C_FriendList.SetFriendNotes(iFriendIndex, sEmpty);
          iDone = iDone + 1;
        end
      end
    end
    ShowMsg("A total of |cff7f7f7f"..iDone.."|r of |cff7f7f7f"..iCount..
      "|r friend notes were removed.");
  end,
  playtime = function()
    RequestTimePlayed();
  end,
  cmds = function()
    local M = "This is a full list of commands that MhMod Addon supports:\n"..
      "\nIf you want to use a command here, simply type "..
      "|cff0000ff/"..ConfigData.Command.." <cmd>|r, "..
      "where <cmd> is any of the commands in blue specified below...\n";
    local C = 0;
    local I = 0;
    for K, V in pairs(ConfigData.Commands) do
      M = M.."\n|cffffff00"..K:upper().." COMMANDS:|r\n====================\n";
      for K, V in pairs(V) do
        M = M.."|cff0000ff"..K:upper()..
          "|r - |cffaaaaaa"..V.SD.."|r\n"..V.LD.."\n";
        I = I + 1;
      end
      C = C + 1;
    end
    ShowDialog(M.."\nA total of "..BreakUpLargeNumbers(I).." commands in "..
      BreakUpLargeNumbers(C).." categories.", "Commands List", "EDITOR");
  end,
  vars = function()
    local M = "This is a full list of variables that MhMod Addon supports:\n"..
      "\nIf you want to toggle an option off or on, simply type |cff0000ff/"..
      ConfigData.Command.." <varname>|r, where <varname> is any of the "..
      "options in blue specified below...\n";
    local C, I, S = 0, 0;
    for K, V in pairs(ConfigData.Options) do
      M = M.."\n|cffffff00"..K:upper().." OPTIONS:|r\n====================\n";
      for K, V in pairs(V) do
        if SettingEnabled(K) then S = "|cff00ff00ENABLED|r";
                             else S = "|cffff0000DISABLED|r" end;
        M = M.."|cff0000ff"..K:upper().."|r ("..S..") - |cffaaaaaa"..V.SD..
          "|r\n"..V.LD.."\n";
        I = I + 1;
      end
      C = C + 1;
    end
    ShowDialog(M.."\nA total of "..BreakUpLargeNumbers(I).." options in "..
      BreakUpLargeNumbers(C).." categories.", "Variables List", "EDITOR");
  end,
  shot = function()
    if GetTimer("ScreenShot") then return end;
    local CVars = {
      UnitNameOwn = false,
      UnitNameNPC = false,
      UnitNameNonCombatCreatureName = false,
      UnitNamePlayerGuild = false,
      UnitNamePlayerPVPTitle = false,
      UnitNameFriendlyPlayerName = false,
      UnitNameFriendlyPetName = false,
      UnitNameFriendlyGuardianName = false,
      UnitNameFriendlyTotemName = false,
      UnitNameEnemyPlayerName = false,
      UnitNameEnemyPetName = false,
      UnitNameEnemyGuardianName = false,
      UnitNameEnemyTotemName = false
    };
    UIParent:Hide();
    for CVar in pairs(CVars) do
      CVars[CVar] = GetCVar(CVar);
      SetCVar(CVar, "0");
    end
    Screenshot();
    CreateTimer(0.1, function()
      for CVar, Value in pairs(CVars) do SetCVar(CVar, Value) end;
      UIParent:Show();
    end, 1, "SS");
  end,
  clear = function(UserCalled)
    for Index = 1, NUM_CHAT_WINDOWS do
      local Frame = _G["ChatFrame"..Index];
      if Frame ~= nil and Frame:IsVisible() then Frame:Clear() end;
    end
    if UserCalled then ShowMsg("All console text windows were cleared!") end;
  end,
  compact = function()
    BagItemAutoSortButton:Click(1);
    ShowMsg("Compact of bags completed!");
  end,
  disable = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Do you want to turn off and disable all the "..
        "options in this addon?", "disable confirm");
    end
    mhconfig = { boolean = { }, dynamic = { } };
    ShowMsg("All options have disabled!");
    LocalCommandsData.resetui();
  end,
  config = function()
    ShowDialog(nil, nil, "CONFIG");
  end,
  reset = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("All of your MhMod settings, notes, logs and "..
        "stats will be destroyed permanantly. Do you really want to "..
        "COMPLETELY reset this addon?", "reset confirm");
    end
    mhconfig, mhnotes, mhstats, mhwlog, mhtrack, mhgtrack, mhclog = nil;
    ReloadUI();
  end,
  applycfg = function()
    bShowDps = SettingEnabled("stssdps");
    bStatsBests = SettingEnabled("shwnewr");
    bStatsReset = SettingEnabled("stsarst");
    bStatsInstance = SettingEnabled("stsator");
    bStatsInBG = SettingEnabled("stsbatt");
    bStatsEnabled = SettingEnabled("stsenab");
    bBarTimers = SettingEnabled("bartimr");
    bActionCounts = SettingEnabled("showabc");
    bActionFades = SettingEnabled("asbfade");
    bMapCoords = SettingEnabled("wmcoord");
  end,
  resetui = function(UserCall)
    local function InitUnitFrameEnhancements()
      local function InitPartyMemberPetFrame(Parent)
        local Frame = PetManaBarFrames[Id];
        if not Frame then
          Frame = CreateFrame("StatusBar", nil, Parent, "TextStatusBar");
          Frame:SetID(Id);
          PetManaBarFrames[Id] = Frame;
          Frame:SetPoint("TOPLEFT", Parent, 23, -10);
          Frame:SetWidth(35);
          Frame:SetHeight(4);
          Frame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
        end
        if SettingEnabled("petmana") then
          local function UpdatePetManaBar(Self, _, Unit)
            local ThisUnit = "partypet"..Self:GetID();
            if Unit ~= ThisUnit then return end;
            local ThisOwner = "party"..Self:GetID();
            if UnitInVehicle(ThisOwner) then ThisUnit = ThisOwner end;
            Self:SetMinMaxValues(1, UnitManaMax(ThisUnit));
            Self:SetValue(UnitMana(ThisUnit));
            local ManaColour = PowerBarColor[UnitPowerType(ThisUnit)];
            Self:SetStatusBarColor(ManaColour.r, ManaColour.g, ManaColour.b);
          end
          Frame:RegisterEvent("UNIT_PET");
          Frame:RegisterEvent("UNIT_FOCUS");
          Frame:RegisterEvent("UNIT_HEALTH");
          Frame:RegisterEvent("UNIT_MAXFOCUS");
          Frame:SetScript("OnEvent", UpdatePetManaBar);
          UpdatePetManaBar(Frame, nil, "partypet"..Id);
          Frame:Show();
        else
          Frame:UnregisterAllEvents();
          Frame:SetScript("OnEvent", nil);
          Frame:Hide();
        end
        for _, oFrame in ipairs({
          PartyMemberFrame1PetFrame, PartyMemberFrame2PetFrame,
          PartyMemberFrame3PetFrame, PartyMemberFrame4PetFrame
        }) do InitPartyMemberPetFrame(oFrame) end;
      end
      -- Function to call when updating party member nameplates
      local function SetTargetNameText(oText, sUnit)
        -- Get target name and just update text if it doesnt exist then just
        -- draw the player name text
        local sTarget = sUnit.."-target";
        if not UnitExists(sTarget) then
          return oText:SetText(UnitName(sUnit)) end;
        -- Get target name class colour
        local CC;
        if UnitIsDeadOrGhost(sTarget) then CC = { r=1 ,g=0, b=0 };
        else
          local _, UC = UnitClass(sTarget);
          CC = RAID_CLASS_COLORS[UC];
        end
        -- Set the name text with target
        oText:SetText(format("%s |cffffffff@|r |cff%02x%02x%02x%s|r",
          UnitName(sUnit), CC.r*255, CC.g*255, CC.b*255,
          UnitName(sTarget)));
      end
      -- For each unitframe we're enhancing
      for Unit, Data in pairs({
        player       = { PlayerFrame,               false },
        pet          = { PetFrame,                  false },
        target       = { TargetFrame,               false },
        targettarget = { TargetFrameToT,            false },
-- FIXME        party1       = { PartyMemberFrame1,         SetTargetNameText },
-- FIXME        partypet1    = { PartyMemberFrame1PetFrame, false },
-- FIXME        party2       = { PartyMemberFrame2,         SetTargetNameText },
-- FIXME        partypet2    = { PartyMemberFrame2PetFrame, false },
-- FIXME        party3       = { PartyMemberFrame3,         SetTargetNameText },
-- FIXME        partypet3    = { PartyMemberFrame3PetFrame, false },
-- FIXME        party4       = { PartyMemberFrame4,         SetTargetNameText },
-- FIXME        partypet4    = { PartyMemberFrame4PetFrame, false }
      }) do
        -- Get frame name for unit and optional update callback function
        local Frame, Function = Data[1], Data[2];
        assert(Frame, "Invalid frame '"..Unit.."'!");
        assert(Function == false or Function,
          "Invalid function '"..Unit.."'!");
        -- Assign callback if valid
        if Function then Frame:SetAttribute("mhcb", Data[2]) end;
        -- Setup health bar text
        local HealthBar = Frame.healthbar;
        if HealthBar then
          local HealthBarText = HealthBar.TextString;
          if HealthBarText then
            HealthBarText:SetFont("fonts\\frizqt__.ttf", 10, sEmpty);
            HealthBarText:SetShadowColor(0, 0, 0);
            HealthBarText:SetShadowOffset(1, -1);
            HealthBar:UpdateTextString();
          end
        end
        -- Setup mana bar text
        local ManaBar = Frame.manabar;
        if ManaBar then
          local ManaBarText = ManaBar.TextString;
          if ManaBarText then
            ManaBarText:SetFont("fonts\\frizqt__.ttf", 10, sEmpty);
            ManaBarText:SetShadowColor(0, 0, 0);
            ManaBarText:SetShadowOffset(1, -1);
            ManaBar:UpdateTextString();
          end
        end
        -- Update nameplate / target
        UnitFrameUpdate(Frame);
      end
      -- Initialise custom raid frame scale
      CompactRaidFrameManager:SetScale(GetDynSetting("drfs"));
    end
    local function InitShiftClickFrameEnhancements()
      local ClickState = SettingEnabled("tsbrprt");
      local HoverState = SettingEnabled("unitnpe");
      local function SetFullOpacity(oFrame) oFrame:SetAlpha(1.00) end;
      local function SetPartialOpacity(oFrame) oFrame:SetAlpha(0.25) end;
      -- Unit power types
      local PowerTypes = {
        [ 0] = "mana",        [ 1] = "rage",        [ 2] = "focus",
        [ 3] = "energy",      [ 4] = "chi",         [ 5] = "power",
        [ 6] = "runic power", [ 7] = "soul shards", [ 8] = "lunar power",
        [ 9] = "holy power",  [11] = "maelstrom",   [13] = "insanity",
        [17] = "fury",        [18] = "pain"
      }
      local function OnClicked(Self, Button)
        if not IsShiftKeyDown() or GetMouseFoci()[1] ~= Self then return end;
        if Self == ContainerFrame1MoneyFrameGoldButton or
           Self == ContainerFrame1MoneyFrameSilverButton or
           Self == ContainerFrame1MoneyFrameCopperButton then
          if Button ~= "RightButton" then return end;
          local M;
          if iMoneySession < 0 then
            M = "Lost "..MakeMoneyReadable(-iMoneySession);
          elseif iMoneySession > 0 then
            M = "Made "..MakeMoneyReadable(iMoneySession);
          else
            M = "Made nothing";
          end
          SendChat("<"..M.." this session and have "..
            MakeMoneyReadable(iMoney).." in total>");
        elseif Self == BackpackTokenFrameToken1 or
               Self == BackpackTokenFrameToken2 or
               Self == BackpackTokenFrameToken3 then
          local ItemId = Self.currencyID;
          if ItemId then
            local ItemName, ItemCount = GetCurrencyInfo(ItemId);
            SendChat("<Have "..BreakUpLargeNumbers(ItemCount).." of "..
              GetCurrencyLink(ItemId)..">");
          end
        elseif Self:GetName():find(".*Bar") then
          local Prefix, Id, Type =
            Self:GetName():match("(.*)Frame(%d)PetFrame(.*)Bar");
          local Unit;
          if not Prefix or not Type then
            Prefix, Type = Self:GetName():match("(.*)Frame(.*)Bar");
            if not Prefix and not Type then return end;
            Id = Type:match("(%d).*");
            if Id and Type then Type = Type:match("%d(.*)")
            else Id = sEmpty end;
            Unit = Prefix:gsub("Member", sEmpty)..Id;
          else
            Unit = Prefix:gsub("Member", sEmpty).."pet"..Id;
            Prefix = Prefix.."Pet";
          end
          local Current, Maximum;
          if Type == "Health" then
            Current = UnitHealth(Unit);
            Maximum = UnitHealthMax(Unit);
          elseif Type == "AlternateMana" then
            Current = UnitMana(Unit);
            Maximum = UnitManaMax(Unit);
            Type = PowerTypes[Self.powerType or 0];
          elseif Type == "Mana" then
            Type = (Self.FeedbackFrame or Self).powerType or 0;
            Current = UnitPower(Unit, Type);
            Maximum = UnitPowerMax(Unit, Type);
            Type = PowerTypes[Type];
          end
          SendChat("<"..Prefix.." "..UnitName(Unit).." has "..
            BreakUpLargeNumbers(Current).."/"..
            BreakUpLargeNumbers(Maximum).." ("..
            RoundNumber(Current/Maximum*100, 2).."%) "..
            Type:lower()..">");
        elseif Self == PlayerFrame then
          local Equipped, Overall = GetAverageItemLevel();
          Equipped = floor(Equipped);
          Overall = floor(Overall);
          if Equipped < Overall then Equipped = Equipped.."/"..Overall end;
          local SpecId = GetSpecialization();
          local _, Spec = GetSpecializationInfo(SpecId);
          local Msg = "Lv."..UnitLevel("player").." "..
            UnitRace("player").." "..Spec.." "..UnitClass("player");
          Msg = Msg.."; iLevel: "..Equipped;
          SendChat("<"..Msg..">");
        else
          local Prefix, Extra = Self:GetName():match("(.*)Frame(.*)");
          local Unit = Prefix:gsub("Member", sEmpty);
          local Id = Extra:match("(%d).*");
          if Id then
            if Extra:find("PetFrame") then
              Extra = Extra:match("%dPetFrame(.*)");
              Unit = Unit.."Pet"..Id;
            else
              Extra = Extra:match("%d(.*)");
              Unit = Unit..Id;
            end
          end
          if not UnitExists(Unit) then return end;
          local M = Prefix.." "..UnitName(Unit);
          if not UnitIsConnected(Unit) then M = M.."; Offline" end;
          M = M.."; Lv.";
          local Level = UnitLevel(Unit);
          if Level > 0 then M = M..Level;
          elseif iLevel >= 100 then M = M.."???";
          else M = M.."??" end;
          if UnitIsPlayer(Unit) then
            if UnitRace(Unit) then M = M.." "..UnitRace(Unit) end;
            if UnitClass(Unit) then M = M.." "..UnitClass(Unit) end;
          else
            local sClass = UnitClassification(Unit);
            if sClass and #sClass > 0 then
              local aClass = UnitClassificationTypesData[sClass];
              if aClass and aClass.F > 0 then M = M.."; "..aClass.N end;
            end
          end
          if UnitIsDeadOrGhost(Unit) then M = M.."; Dead" end;
          if UnitIsPVP(Unit) then M = M.."; PvP" end;
          if UnitCanAttack("player", Unit) then M = M.."; Attackable" end;
          if UnitIsFeignDeath(Unit) then M = M.."; Feigned" end;
          if UnitIsAFK(Unit) then M = M.."; Away" end;
          SendChat("<"..M..">");
        end
      end
    end
    local function InitChatFrameEnhancements()
      local ChatInput = SettingEnabled("chatinh");
      for Index = 1, NUM_CHAT_WINDOWS do
        local ChatFrameName = "ChatFrame"..Index;
        local ChatFrame = _G[ChatFrameName.."Tab"];
        if ChatFrame then
          for  _, Id in pairs({
            "glow", "leftTexture", "middleTexture", "rightTexture",
            "leftSelectedTexture", "middleSelectedTexture",
            "rightSelectedTexture", "leftHighlightTexture",
            "middleHighlightTexture", "rightHighlightTexture"
          }) do
            local Frame = ChatFrame[Id];
            if Frame then
              if ChatInput then
                if not OldChatTabTexture[Id] then
                  OldChatTabTexture[Id] = Frame:GetTexture();
                end
                Frame:SetTexture(nil);
              elseif OldChatTabTexture[Id] then
                Frame:SetTexture(OldChatTabTexture[Id]);
              end
            end
          end
        end
        for  _, Location in pairs({ "Left", "Mid", "Right" }) do
          local Frame = _G[ChatFrameName.."EditBox"..Location];
          if Frame then
            if ChatInput then
              if not OldChatInputTexture[Location] then
                OldChatInputTexture[Location] = Frame:GetTexture();
              end
              Frame:SetTexture(nil);
            elseif OldChatInputTexture[Location] then
              Frame:SetTexture(OldChatInputTexture[Location]);
            end
          end
        end
        local Frame = _G[ChatFrameName];
        if Frame then FunctionHookData.FCF_FadeInChatFrame(Frame) end;
      end
      if GetDynSetting("docfs") > 0 then
        local Size = GetDynSetting("docfs");
        for _, Frame in pairs(FCFDock_GetChatFrames(GENERAL_CHAT_DOCK)) do
          local Font, _, Flags = Frame:GetFont();
          Frame:SetFont(Font, Size, Flags);
        end
      end
    end
    local function InitOtherFrameEnhancements()
      if SettingEnabled("showbag") then
        MainMenuBarBackpackButtonCount:Hide();
      else
        MainMenuBarBackpackButtonCount:Show();
      end

      if not GameTooltip.GetBackdrop then
        Mixin(GameTooltip, BackdropTemplateMixin);
      end

      if SettingEnabled("toolfra") then
        GameTooltip:SetBackdrop({tile=true,tileSize=32,edgeSize=16,
          bgFile="Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
          edgeFile="Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
          insets = {left=4,right=4,top=4,bottom=4}});
      else
        GameTooltip:SetBackdrop({tile=true,tileSize=16,edgeSize=16,
          bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
          edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
          insets={left=5,right=5,top=5,bottom=5}});
      end
    end

    -- Error handler variables
    local LastErrorMessage;            -- Last error message
    local LastErrorMessageCount = 0;   -- Count error message was repeated
    local LastErrorMessageFirst = 0;   -- Time first error message occured
    -- Error handler initialise function
    local function InitErrorHandler()
      -- Don't install handler if setting not eanbled
      if not SettingEnabled("simperh") then return end;
      -- Set new error handler function
      seterrorhandler(function(Message)
        -- Clear timers so the event can't trigger continuously if it happened
        -- in a timer event
        if #TimerData > 0 then TimerData = { } end;
        -- If this is a new error or not the last error that occured
        if not LastErrorMessage or LastErrorMessage ~= Message then
          if LastErrorMessage and
             LastErrorMessageCount > 0 and
             SettingEnabled("logchat") then
            Log("ERROR", "Last error message occured "..LastErrorMessageCount..
              " more times in the last "..(time()-LastErrorMessageFirst)..
              " seconds.");
          end
          LastErrorMessageCount = 0;
          LastErrorMessageFirst = time();
          LastErrorMessage = Message;
          DEFAULT_CHAT_FRAME:AddMessage(Message, 1, 0, 0);
          if SettingEnabled("logchat") then
            Log("ERROR", Message.."|n"..debugstack(3, 1000, 1000));
          end
        elseif LastErrorMessage then
          LastErrorMessageCount = LastErrorMessageCount + 1;
          if LastErrorMessageCount >= 100 or
            time() - LastErrorMessageFirst >= 5 then
            if SettingEnabled("logchat") then
              Log("ERROR", "Last error message occured "..
                LastErrorMessageCount.." more times in the last "..
                (time()-LastErrorMessageFirst).." seconds.") end;
            LastErrorMessageCount, LastErrorMessageFirst = 0, time();
          end
        end
      end);
    end
    -- When an action button is updated -----------------------------------------
    InitUnitFrameEnhancements();
    InitShiftClickFrameEnhancements();
    InitChatFrameEnhancements();
    InitOtherFrameEnhancements();
    InitErrorHandler();

    if UserCall then
      ShowMsg("The UI improvement features have been refreshed!");
    end
  end,
  reload = function()
    ReloadUI();
  end,
  emotes = function()
    local Index, Emotes, Data = 1, { };
    while Index < 1000 do
      Data = _G["EMOTE"..Index.."_TOKEN"];
      if not Data then
        break;
      end
      tinsert(Emotes, Data);
      Index = Index + 1;
    end
    local Msg = "This is a full list of emotes (in alphabetical order) that "..
      "your character can use...\n\n";
    local Red, Green, Blue;
    sort(Emotes);
    for _, Emote in ipairs(Emotes) do
      Red, Green, Blue = StringToColour(Emote);
      Msg = format("%s/|cff%02x%02x%02x%s|r ", Msg, Red, Green, Blue, Emote);
    end
    ShowDialog(Msg.."\n\nA total of "..BreakUpLargeNumbers(Index)..
      " emotes supported by the game.",
      "World of Warcraft emotes list", "EDITOR");
  end,
  resettdb = function()
    nhtrack = { }
    ShowMsg("The tracking database has been reset!");
  end,
  kickallo = function(_, ArgV, ArgC)
    if GroupData.D.C <= 0 then
      return ShowMsg("You are not in a party or raid!");
    end
    local MemberData = GroupData.D;
    local Count = MemberData.C - 1;
    if not UserIsMe(MemberData.L) then
      return ShowMsg("You are not the group leader!");
    end
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to disband all the offline "..
        "persons in your entire group?", "kickallo confirm");
    end
    local Kicked = 0;
    for Name, Data in pairs(MemberData.N) do
      if not Data.S then
        UninviteUnit(Name);
        Kicked = Kicked + 1;
      end
    end
    if Kicked <= 0 then
      ShowMsg("|cff7f7f7fNone|r of the |cff7f7f7f"..Count..
        "|r persons in your group were removed for being offline!");
    elseif Kicked == Count then
      ShowMsg("All of the |cff7f7f7f"..Kicked..
        "|r persons in your group were removed for being offline!");
    else
      ShowMsg("Only |cff7f7f7f"..Kicked.." of "..Count..
        "|r persons in your group were removed for being offline!");
    end
  end,
  kickall = function(_, ArgV, ArgC)
    if GroupData.D.C <= 0 then
      return ShowMsg("You are not in a party or raid!");
    end
    local MemberData = GroupData.D;
    local Count = MemberData.C - 1;
    if not UserIsMe(MemberData.L) then
      return ShowMsg("You are not the group leader!");
    end
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Kick everyone in your entire group?",
        "kickall confirm");
    end
    local Kicked = 0;
    for Name in pairs(MemberData.N) do
      if not UserIsMe(Name) then
        UninviteUnit(Name);
        Kicked = Kicked + 1;
      end
    end
    if Kicked <= 0 then
      ShowMsg("|cff7f7f7fNone|r of the |cff7f7f7f"..Count..
        "|r persons in your group were removed!");
    elseif Kicked == Count then
      ShowMsg("All of the |cff7f7f7f"..Kicked..
        "|r persons in your group were removed!");
    else
      ShowMsg("Only |cff7f7f7f"..Kicked.." of "..Count..
        "|r persons in your group were removed!");
    end
  end,
  logclear = function(Arguments, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Clear the entire log database?",
        "logclear confirm");
    end
    mhclog = { };
    ShowMsg("The logs database was completely reset!");
  end,
  logdata = function(Arguments, ArgV, ArgC)
    if ArgC <= 2 then return ShowDialog(nil, nil, "CHATLOG") end;
    local Start = tonumber(ArgV[1]);
    if not Start then
      return ShowMsg("The specified start time is invalid", "logdata");
    end
    local Duration = tonumber(ArgV[2]);
    if not Duration then
      return ShowMsg("The specified duration time is invalid", "logdata");
    end
    local Category = ArgV[3];
    if ArgC > 3 then Category = Category.." "..ArgV[4] end;
    local CatData = mhclog[Category];
    if not CatData then
      return ShowMsg("The specified category |cffaaaaaa"..Category..
        "|r was not found in the logs database!", "logdata");
    end
    local aLines, Total = { }, 0;
    for Time, Data in SortedPairs(CatData) do
      for _, Line in ipairs({ strsplit("\31", Data) }) do
        if Time >= Start and Time < Start+Duration then
          local Text = "(|cffffff00"..date("%H:%M:%S", Time).."|r) ";
          local Name, Msg = Line:match("(.-)\30(.+)");
          if Name and Msg then
            tinsert(aLines, Text.."|cff0000ff"..Name.."|r: "..Msg.."\n");
          else tinsert(aLines, Text..Line.."\n") end;
        end
        Total = Total + 1;
      end
    end
    if Count == 0 then
      return ShowMsg("No records matching your criteria", "logdata");
    end
    ShowDialog("Chat log data for |cffaaaaaa"..Category..
      "|r,\nFrom |cffaaaaaa"..date("%d/%m/%y-%H:%M:%S", Start)..
      "|r to |cffaaaaaa"..date("%d/%m/%y-%H:%M:%S", Start+Duration)..
      "|r...\n\n"..strjoin(sEmpty, unpack(aLines)).."\nMatched |cffaaaaaa"..
      BreakUpLargeNumbers(#aLines).."|r of |cffaaaaaa"..
      BreakUpLargeNumbers(Total).."|r lines of text.",
      "Chat log for "..Category, "EDITOR");
  end,
  calc = function(Math, ArgV, ArgC)
    if ArgC <= 0 then
      return ShowInput("Please specify the arguments you would like to "..
        "evaluate (Valid operators are + - / * %%)", "calc");
    end
    local Formatted = Math:gsub("[%+%/%*%-%%]", " %1 "):gsub("  ", " ");
    local Result, Current, Token, IsNumber = 0, 0, "+", true;
    local Data = {
      ["+"] = function(A,B) return A+B end;
      ["-"] = function(A,B) return A-B end;
      ["/"] = function(A,B) return A/B end;
      ["*"] = function(A,B) return A*B end;
      ["%"] = function(A,B) return A%B end;
    };
    while Math and #Math > 0 do
      if IsNumber then
        Current, Math = Math:match("^%s*([-%d%.]+)%s*(.*)$");
        if not Current then Result = nil break end;
        Current = tonumber(Current);
        if not Current then Result = nil break end;
        Result = Data[Token](Result, Current);
        IsNumber = false;
      else
        Token, Math = Math:match("^%s*([%+%-%/%*%%])%s*(.*)$");
        if not Token then Result = nil break end;
        IsNumber = true;
      end
    end
    if not Result then
      return ShowInput("Sorry, but there was an |cffff0000syntax error|r in "..
        "your argument. Please check it and try again.", "calc", Math);
    end
    if tostring(Result) == "1.#INF" then
      return ShowInput("Sorry, but a |cffff0000mathematical error|r occured "..
        "in your syntax and the result was |cffff0000infinity|r. It could "..
        "have been a |cff00ff00divide-by-zero|r error. Please check it and "..
        "try again.", "calc", Math);
    end
    ShowInput("Result: |cffff4f00"..Formatted:gsub("%%", "%"):
      gsub("([-%d%.]+)", "|cffffff00%1|r|cffff4f00")..
        "|r = |cff0000ff"..Result.."|r!", "calc", Formatted:gsub(" ", sEmpty));
  end,
  trackadd = function(Arguments, ArgV, ArgC)
    if ArgC < 1 then
      return ShowInput("Please specify the item amount then the item name "..
        "(e.g. |cff0000ff250|r |cff00ff00Mageweave Cloth|r)", "trackadd");
    end
    if ArgC < 2 then
      return ShowMsg("You must also specify the item name!", "trackadd");
    end
    local Count = tonumber(ArgV[1]);
    if not Count then
      ShowMsg("Must specify a numeric integer for the count!", "trackadd");
      return;
    end
    if Count < 1 then
      ShowMsg("Please specify a valid positive numreic integer!", "trackadd");
      return;
    end
    local Item = Arguments:match("^%w+%s+(.+)");
    Item = Item:match("%[(.+)%]") or Item;
    if mhtrack[Item] then
      if mhtrack[Item] == Count then
        ShowMsg(Item.."x"..Count.." is already added to the tracking list!");
        return
      end
      ShowMsg("Updating "..Item.."x"..Count.." in the item tracking list!");
    else
      local _, sLink = GetItemInfo(Item);
      if sLink then
        ShowMsg("Added "..sLink.."|cff7f7f7fx"..Count..
          "|r to the item tracking list!");
      else
        ShowMsg("This item was not matched in the local item cache. "..
          "Please check your spelling and grammar! All item names are "..
          "case-sensetive also. Added ["..Item.."]|cff7f7f7fx"..Count..
          "|r to the item tracking list anyway!");
      end
    end
    mhtrack[Item] = Count;
  end,
  trackclr = function(_, ArgV, ArgC)
    local ItemCount = TableSize(mhtrack);
    if ItemCount <= 0 then
      return ShowMsg("There are no items in the item tracking database!");
    end
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Delete |cff7f7f7f"..ItemCount..
        "|r tracking database items?", "trackclr confirm");
    end
    mhtrack = { };
    ShowMsg("A total of |cff7f7f7f"..ItemCount..
      "|r items were removed from the item tracking database!");
  end,
  trackdel = function(Item, ArgV, ArgC)
    if ArgC < 1 then
      return ShowInput("Specify item to remove (e.g. Mageweave Cloth)",
        "trackdel");
    end
    if not mhtrack[Item] then
      return ShowMsg("Item |cff7f7f7f"..Item.."|r not being tracked!",
        "trackdel");
    end
    mhtrack[Item] = nil
    local _, Link = GetItemInfo(Item);
    ShowMsg("Removed "..(Link or Item).." from the item tracking database!");
  end,
  tracklst = function(msg)
    local Entry, Link, ItemId, Total, Message = 0;
    for Name, Count in pairs(mhtrack) do
      Entry = Entry + 1;
      _, Link = GetItemInfo(Name);
      Message = Entry..": "..(Link or Name).."x"..Count;
      if Link then
        Total = BagData[tonumber(Link:match("%|Hitem%:(%d+)%:"))];
        if Total then
          Message = Message.." (Current: "..BreakUpLargeNumbers(Total)..")";
        end
      end
      Print(Message);
    end
    if Entry <= 0 then
      ShowMsg("There are no items in the item tracking database to list!");
    else
      Print("A total of "..Entry.." items in the tracking list");
    end
  end,
  i = function(NUL, ArgV, ArgC)
    if ArgC < 1 then
      return ShowInput("Please specify the players to invite. "..
        "Separate each player using a comma character and use no spaces", "i");
    end
    local Names = { strsplit(",", ArgV[1]); }
    if #Names <= 0 then ShowMsg("No names specified") end;
    for NUL, Name in ipairs(Names) do InviteUnit(Name) end;
  end,
  w = function(NUL, ArgV, ArgC)
    if ArgC < 1 then
      return ShowInput("Please specify the players to whisper. "..
        "Separate each player using a comma character and use no spaces", "w");
    elseif ArgC < 2 then
      return ShowInput("Specify the message to whisper to these players",
        "w "..ArgV[1]);
    end
    local Names = { strsplit(",", ArgV[1]); }
    if #Names <= 0 then ShowMsg("No names specified") end;
    local Message = ArgV[2];
    for Index = 3, ArgC do Message = Message.." "..ArgV[Index] end;
    for NUL, Name in ipairs(Names) do
      if IsValidPlayerName(Name) then
        SendChatMessage(Message, "WHISPER", nil, Name);
      elseif Name ~= sEmpty then
        Print("The player name '"..Name.."' is invalid!");
      end
    end
  end,
  stopmus = function()
    StopMusic()
    ShowMsg("Music playback stopped!");
  end,
  resetsx = function()
    Sound_GameSystem_RestartSoundSystem();
    ShowMsg("Sound engine restarted!");
  end,
  togglef = function()
    local Value = GetCVar("gxWindow");
    if not Value or Value == "0" then
      Value = 1;
    else
      Value = 0;
    end
    SetCVar("gxWindow", Value);
    RestartGx();
  end,
  tgaddon = function(_, ArgV, ArgC)
    if ArgC <= 0 then
      ShowMsg("Please specify the addon to toggle", "tgaddon");
    end
    local Addon = ArgV[1];
    local Name, Title, _, Enabled = C_AddOns.GetAddOnInfo(Addon);
    if not Name then
      return ShowMsg("The addon |cffaaaaaa"..Addon..
        "|r is not currently loaded!", "tgaddon");
    end
    if Name == Version.Name and (ArgC <= 1 or ArgV[2] ~= "confirm") then
      return ShowQuestion("|cffff0000Warning:|r If you disable this addon, "..
        "you will have to enable it again in the |cff00ff00Blizzard addons "..
        "manager|r on the |cff0000fflogin screen|r or type "..
        "|cff7f7f7f/script EnableAddOn(\""..Addon.."\")|r and "..
        "|cff7f7f7f/console reloadui|r. Are you sure you want to do this?",
        "tgaddon "..Addon.." confirm");
    end
    if Enabled then
      C_AddOns.DisableAddOn(Addon);
      ShowMsg("The addon |cffaaaaaa"..Addon.."|r has been disabled!");
    else
      C_AddOns.EnableAddOn(Addon);
      ShowMsg("The addon |cffaaaaaa"..Addon.."|r has been enabled!");
    end
    ReloadUI();
  end,
  resetgx = function()
    RestartGx();
    ShowMsg("Graphics engine restarted!");
  end,
  dumpllqu = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to remove all "..
        "|cffffff00low level|r quests?", "dumpllqu confirm");
    end
    local iMax, iCount = C_QuestLog.GetNumQuestLogEntries();
    if iCount == 0 then
      return ShowMsg("There are no dungeon quests to abandon!") end;
    local iDumped = 0;
    for QuestIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
      local QuestId = C_QuestLog.GetQuestIDForLogIndex(QuestIndex);
      if QuestId > 0 then
        if C_QuestLog.IsQuestTrivial(QuestId) then
          C_QuestLog.SetSelectedQuest(QuestId);
          C_QuestLog.SetAbandonQuest();
          C_QuestLog.AbandonQuest();
          iDumped = iDumped + 1;
        end
      end
    end
    ShowMsg("A total of |cff7f7f7f"..iDumped..
      "|r low level quests were abandoned!");
  end,
  dumpduqu = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to remove all "..
        "|cffffff00dungeon|r quests?", "dumpduqu confirm");
    end
    local iMax, iCount = C_QuestLog.GetNumQuestLogEntries();
    if iCount == 0 then
      return ShowMsg("There are no dungeon quests to abandon!") end;
    local iDumped = 0;
    for QuestIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
      local QuestId = C_QuestLog.GetQuestIDForLogIndex(QuestIndex);
      if QuestId > 0 then
        local QuestInfo = C_QuestLog.GetQuestTagInfo(QuestId);
        if QuestInfo then
          local Tag = QuestInfo.tagID;
          -- https://wowpedia.fandom.com/wiki/API_C_QuestLog.GetQuestTagInfo
          if Tag == 62 or              -- Raid
             Tag == 81 or              -- Dungeon
             Tag == 85 or              -- Heroic
             Tag == 88 or              -- Raid (10)
             Tag == 89 then            -- Raid (25)
            C_QuestLog.SetSelectedQuest(QuestId);
            C_QuestLog.SetAbandonQuest();
            C_QuestLog.AbandonQuest();
            iDumped = iDumped + 1;
          end
        end
      end
    end
    ShowMsg("A total of |cff7f7f7f"..iDumped..
      "|r dungeon quests were abandoned!");
  end,
  dumpalqu = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to |cffffff00completely|r "..
        "clear your entire quest log?", "dumpalqu confirm");
    end
    local iMax, iCount = C_QuestLog.GetNumQuestLogEntries();
    if iCount == 0 then return ShowMsg("There are no quests to abandon!") end;
    local iDumped = 0;
    for QuestIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
      local QuestId = C_QuestLog.GetQuestIDForLogIndex(QuestIndex);
      if QuestId > 0 then
        C_QuestLog.SetSelectedQuest(QuestId);
        C_QuestLog.SetAbandonQuest();
        C_QuestLog.AbandonQuest();
        iDumped = iDumped + 1;
      end
    end
    ShowMsg("A total of |cff7f7f7f"..iDumped.."|r quests were abandoned!");
  end,
  showqu = function()
    local iTotal, iDone, sText = 0, 0, sEmpty;
    for iQuestId, QuestTable in SortedPairs(QuestData) do
      iTotal = iTotal + 1;
      sText = sText..iTotal..": ";
      local aTag = C_QuestLog.GetQuestTagInfo(iQuestId);
      sText = sText..GetQuestLink(iQuestId);
      if aTag then sText = sText.." (|cff0000ff"..aTag.tagName.."|r)" end;
      if QuestTable.C then
        iDone = iDone + 1;
        sText = sText.." <|cff00ff00Complete|r>";
      else sText = sText.." <|cffff0000Incomplete|r>" end;
      local Objectives = QuestTable.O;
      if Objectives and #Objectives > 0 then
        sText = sText.."...|n";
        for Objective, ObjectiveTable in SortedPairs(QuestTable.O) do
          sText = sText.." "..Objective..": "..ObjectiveTable.text.." <";
          if ObjectiveTable.finished then
            sText = sText.."|cff00ff00Complete|r>.|n";
          else sText = sText.."|cffff0000Incomplete|r>.|n" end;
        end
      else sText = sText..".|n" end;
    end
    ShowDialog(sText.."|nA total of |cff00ff00"..iTotal..
      "|r quests (|cff00ff00"..iDone.."|r completed).",
      "Quest List", "EDITOR");
  end,
  showinv = function()
    local Text, Items, Link, Level, SubType, EquipLoc = sEmpty, 0;
    for SlotId = 1, 23 do
      Link = GetInventoryItemLink("player", SlotId);
      if Link then
        _, _, _, Level, _, _, SubType, _, EquipLoc = GetItemInfo(Link);
        Text = Text.."|cff00ff7fL#"..format("%03u", Level).."|r/|cffff0000"..
          EquipLoc.."|r/|cff0000ff"..SubType.."|r -> "..Link.."\n";
        Items = Items + 1;
      end
    end
    ShowDialog(Text.."\nA total of "..Items.." items equipped.",
      "Equipment List", "EDITOR");
  end,
  showitem = function()
    local iStacks, iItems, sText = 0, 0, sEmpty;
    for iBagId = 0, NUM_BAG_FRAMES do
      local aBag = BagsData[iBagId];
      if aBag then
        for iSlotId, aSlot in SortedPairs(aBag) do
          local _, _, _, _, _, sType, sSubType = GetItemInfo(aSlot.itemID);
          local iItemCount = aSlot.stackCount;
          sText = sText.."B|cffff7f00"..iBagId.."|r/S|cffff7f00"..
            iSlotId.."|r: |cff00ff00"..sType.."|r/|cff0000ff"..sSubType..
            "|r -> "..aSlot.hyperlink.."x"..BreakUpLargeNumbers(iItemCount)..
            "\n";
          iStacks = iStacks + 1;
          iItems = iItems + iItemCount;
        end
      end
    end
    ShowDialog(sText.."\nFound "..BreakUpLargeNumbers(iStacks)..
      " stacks of "..BreakUpLargeNumbers(iItems).." items.",
      "Item List", "EDITOR");
  end,
  getitem = function(Item, ArgV, ArgC)
    if ArgC <= 0 then
      return ShowInput("Please specify the item name or id number "..
        "(e.g. Hearthstone or 44687). Note: Names have to be cached to "..
        "query, id's do not", "getitem");
    end
    if ArgC == 2 and ArgV[2] == "@" then
      return ShowURL("http://www.wowhead.com/item="..ArgV[1]);
    end
    local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType,
      iStackCount, sEquipLoc, sTex, iValue = GetItemInfo(Item);
    if not sName then
      return ShowMsg("The specified item |cffaaaaaa"..Item..
        "|r was not matched!");
    end
    if not sType or sType == sEmpty then sType = "N/A" end;
    if not sSubType or sSubType == sEmpty then sSubType = "N/A" end;
    if not sEquipLoc or sEquipLoc == sEmpty then sEquipLoc = "N/A"  end;
    local ItemId = tonumber(sLink:match("%|Hitem%:(%d+)%:"));
    local R, G, B = GetItemQualityColor(iRarity);
    local Count = BagData[ItemId];
    if Count then
      Count = Count.stackCount;
      if not Count then Count = 0 end;
    else Count = 0 end;
    local TotalValue = iValue * Count;
    if TotalValue <= 0 then TotalValue = "nothing";
    else TotalValue = MakeMoneyReadable(TotalValue) end;
    if iValue <= 0 then iValue = "nothing";
    else iValue = MakeMoneyReadable(iValue) end;
    local RarityTypes = {
      [-1] = "Garbage",   [ 0] = "Poor",     [ 1] = "Common",
      [ 2] = "Uncommon",  [ 3] = "Rare",     [ 4] = "Epic",
      [ 5] = "Legendary", [ 6] = "Artifact", [ 7] = "Heirloom"
    };
    ShowMsg(sLink.."\n\nStack: |cffaaaaaa"..iStackCount..
      "|r, Rarity: |cffaaaaaa"..RarityTypes[iRarity]..
      "|r, Level: |cffaaaaaa"..iLevel.."|r, MinLevel: |cffaaaaaa"..iMinLevel..
      "|r\nType: |cffaaaaaa"..sType.."|r, SubType: |cffaaaaaa"..sSubType..
      "|r, EquipType: |cffaaaaaa"..sEquipLoc.."|r, ItemId: |cffaaaaaa"..
      ItemId.."|r.\n\nWorth |cffaaaaaa"..iValue..
      "|r to vendor.\nYou have |cffaaaaaa"..BreakUpLargeNumbers(Count)..
      "|r quantity of this item.\nTotal value of items is |cffaaaaaa"..
      TotalValue.."|r.", "getitem "..ItemId.." @", nil, {
        name=sName, index=1, color={R,G,B,1}, link=sLink,
        count=Count, texture=sTex
      });
  end,
  dress = function()
    -- Cannot dress in combat
    if nCombatTime > 0 then
      return ShowMsg("Cannot dress when in combat!") end;
    -- Cannot dress when dead
    if UnitIsDeadOrGhost("player") then
      return ShowMsg("Cannot dress when dead!") end;
    -- Cannot dress if no data
    if #EquipData == 0 then
      return ShowMsg("No saved strip data available!") end;
    -- Items equipped
    local iEquipped = 0;
    -- Start dressing
    for iIndex = 1, #EquipData do
      -- Get deequip info
      local aItem = EquipData[iIndex];
      -- Get bag and slot
      local iBagId, iSlotId = aItem.B, aItem.S;
      -- Check slot and if it's the same as we stored?
      if C_Container.GetContainerItemLink(iBagId, iSlotId) == aItem.L then
        -- Pick it up and equip it
        C_Container.PickupContainerItem(iBagId, iSlotId);
        AutoEquipCursorItem();
        -- Equipped it
        iEquipped = iEquipped + 1;
      end
    end
    -- Show result
    ShowMsg("Re-equipped |cff7f7f7f"..iEquipped.."|r of |cff7f7f7f"..
      #EquipData.."|r inventory items!");
  end,
  strip = function()
    -- Ignore if in combat
    if nCombatTime > 0 then
      return ShowMsg("Cannot strip when in combat!") end;
    -- Ignore if dead
    if UnitIsDeadOrGhost("player") then
      return ShowMsg("Cannot strip when dead!") end;
    -- Prepare new equipment data
    EquipData = { };
    -- Reserved slots
    local aReserved = { };
    -- Enumerate inventory slots
    for iInvId, aInvItem in pairs(BagsData.I) do
      -- Found empty slot?
      local bFound;
      -- Find an empty bag slot
      for iBagId = 0, NUM_BAG_FRAMES do
        -- Enumerate all the slots on this bag
        for iSlotId = 1, C_Container.GetContainerNumSlots(iBagId) do
          -- Label for reserved slot
          local sReserved = iBagId.."."..iSlotId;
          -- Check if we already reserved this slot and if we didnt?
          if not aReserved[sReserved] then
            -- Get item info and if no item is there?
            if not C_Container.GetContainerItemLink(iBagId, iSlotId) then
              -- We will use this slot
              tinsert(EquipData, { I=iInvId, B=iBagId, S=iSlotId,
                L=aInvItem.hyperlink });
              -- Slot reserved
              aReserved[sReserved] = true;
              -- Found a slot for this
              bFound = true;
              -- Done
              break;
            end
          end
        end
        -- Break again if found
        if bFound then break end;
      end
      -- Return if not found
      if not bFound then
        -- If we get here then we could not find an item.
        ShowMsg("Need "..TableSize(BagsData.I) - #EquipData..
          " more free bags slots to strip!");
        -- Clear equipment data
        EquipData = { };
        -- Done
        return;
      end
    end
    -- Return if nothing stripped
    if #EquipData == 0 then return ShowMsg("No inventory to strip!") end;
    -- Now remove all items
    for iIndex = 1, #EquipData do
      -- Get deequip info
      local aItem = EquipData[iIndex];
      -- De-equip to designated slot
      PickupInventoryItem(aItem.I);
      C_Container.PickupContainerItem(aItem.B, aItem.S);
    end
    -- Show number of items stripped
    ShowMsg("Stripped |cff7f7f7f"..#EquipData.."|r items!");
  end,
  money = function() ShowDialog(nil, nil, "MONEY", sMyName) end,
  monclrs = function(UserCalled)
    iXPSession, iMoneySession = 0, 0;
    iSessionStart = time();
    if UserCalled then
      ShowMsg("Session XP and money counters have been reset!");
    end
  end,
  monclear = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to reset the entire money "..
        "statistics database?", "monclear confirm");
    end
    MoneyData = { };
    for sKey, vDef in pairs(ValidMoneyValues) do MoneyData[sKey] = vDef end;
    MoneyData.nTimeSes = time();
    MoneyData.nTimeStart = time();
    RealmMoneyData = { [sMyName] = MoneyData };
    mhmoney = { [sMyRealm] = RealmMoneyData };
    ShowMsg("The money database has been completely reset!");
  end,
  monclrch = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to reset the entire money "..
        "statistics database for current character?", "monclear confirm");
    end
    MoneyData = { };
    for sKey, vDef in pairs(ValidMoneyValues) do MoneyData[sKey] = vDef end;
    MoneyData.nTimeSes = time();
    MoneyData.nTimeStart = time();
    RealmMoneyData[sMyName] = MoneyData;
    ShowMsg("The money database has been reset for the current character!");
  end,
  stsfullr = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to reset the personal, "..
        "battle and temporary statistics databases?", "stsfullr confirm");
    end
    StatsClear(true, true);
    ShowMsg("The personal, battle and temporary statistics database have "..
      "been reset!");
  end,
  stsclear = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to reset the battle "..
        "statistics database?", "stsclear confirm");
    end
    StatsClear(true, false);
    ShowMsg("The battle statistics database has been reset!");
  end,
  stsbestc = function(_, ArgV, ArgC)
    if ArgC <= 0 or ArgV[1] ~= "confirm" then
      return ShowQuestion("Are you sure you want to reset the personal "..
        "statistics database?", "stsbestc confirm");
    end
    StatsClear(false, true);
    ShowMsg("The personal statistics database has been reset!");
  end,
  stsshowp = function()
    ShowDialog(nil, nil, "MYSTATS", sMyName);
  end,
  stsshowb = function(_, ArgV, ArgC)
    if ArgC <= 0 then
      return ShowInput("Which player do you want to look at statistics for?",
        "stsshowb", sMyName);
    end
    local Who = ArgV[1]:lower();
    Who = Who:sub(1, 1):upper()..Who:sub(2);
    ShowDialog(nil, nil, "MYSTATS", Who);
  end,
  stats = function()
    ShowDialog(nil, nil, "STATS");
  end,
  setricon = function(_, ArgV, ArgC)
    if ArgC <= 0 then
      return ShowInput("Set the auto-raid target icon to either "..
        "1=|cffffff7fStar|r, 2=|cffff7f00Circle|r, 3=|cffff00ffDiamond|r, "..
        "4=|cff00ff00Triangle|r, 5=|cff7fafffMoon|r, 6=|cff007fffSquare|r, "..
        "7=|cffff0000Cross|r or 8=|cffffffffSkull|r.", "setricon",
          GetDynSetting("darti"));
    end
    local Value = tonumber(ArgV[1]);
    if not Value then
      return ShowMsg("The value you specified is invalid and must be an "..
        "integer. Please use an integer between |cff00ff001|r and "..
        "|cff00ff008|r!", "setricon");
    end
    if Value < 0 or Value > 8 then
      return ShowMsg("The value specified of |cff7f7f7f"..Value..
        "|r is out of range. Please use a number between |cff00ff001|r and "..
        "|cff00ff008|r!", "setricon");
    end
    SetDynSetting("darti", Value);
    ShowMsg("The auto-raid target icon id has been set to |cff7f7f7f"..Value..
      "|r!");
  end,
  tdebug = function() DebugTable(TimerData, "Timers") end,
  run = function(String)
    if not String or #String <= 0 then
      return ShowInput("Enter LUA string to evaluate", "run");
    end
    RunScript("MhMod.O={"..String.."}");
    Print(MhMod.O, String);
    MhMod.O = nil;
  end,
  rund = function(String)
    if not String or #String <= 0 then
      return ShowInput("Enter LUA string to evaluate", "run");
    end
    RunScript("MhMod.O={"..String.."}");
    DebugTable(MhMod.O, String);
    MhMod.O = nil;
  end,
  mo = function()
    local oFocus = GetMouseFoci()[1];
    local sRes;
    if          oFocus  == nil         then sRes = "Frame no found";
    elseif type(oFocus) ~= "table"     then sRes = "Frame not valid table";
    else
      local fFunc = oFocus.GetName;
      if fFunc == nil or type(fFunc) ~= "function" then
        fFunc = function(F) return tostring(F) end end;
      return DebugTable({oFocus}, fFunc(oFocus));
    end
    Print(sRes);
  end
};
-- == Public command system commands =========================================
RemoteCommandsData = {
  help = function(User)
    Print(MakePlayerLink(User).." requested the command list");
    local M = "Commands:";
    for K in pairs(RemoteCommandsData) do M = M.." !"..K end;
    SendWhisper(User, M);
  end,
  version = function(User)
    Print(MakePlayerLink(User).." requested version information");
    local Type = " for ";
    if IsWindowsClient() then Type = Type.."Windows";
    elseif IsMacClient() then Type = Type.."Macintosh";
    elseif IsLinuxClient() then Type = Type.."Linux";
    else Type = sEmpty end;
    SendWhisper(User, GetVersion()..Type);
  end,
  ilvl = function(User)
    Print(MakePlayerLink(User).." requested item level information");
    local Overall, Equipped = GetAverageItemLevel();
    local Extra = sEmpty;
    if Overall > Equipped then
      Extra = " ("..floor(Overall).." available)";
    end
    SendWhisper(User, "Current item level is "..floor(Equipped)..Extra);
  end,
  durability = function(User)
    Print(MakePlayerLink(User).." requested durability information");
    local Current, Maximum, Percent = GetDurability();
    SendWhisper(User, "Durability status is "..BreakUpLargeNumbers(Current)..
      "/"..BreakUpLargeNumbers(Maximum).." ("..RoundNumber(Percent, 2).."%)");
  end,
  resetinst = function(User)
    if IsInInstance() then
      Print(MakePlayerLink(User)..
        " requested to reset instances but you are already in an instance");
      return SendWhisper(User,
        "Cannot reset instance when I am in one already");
    end
    if GroupData.D.C <= 0 then
      Print(MakePlayerLink(User)..
        " requested to reset instances but you are not in a group");
      return SendWhisper(User,
        "Cannot reset instance when I am not in a group");
    end
    if not UnitIsGroupLeader("player") then
      Print(MakePlayerLink(User)..
        " requested to reset instances but you are not the group leader");
      return SendWhisper(User,
        "Cannot reset instance when I am not the group leader");
    end
    Print(MakePlayerLink(User).." requested to reset instances");
    ResetInstances();
    SendWhisper(User, "Instance reset requested");
  end,
  lag = function(User)
    Print(MakePlayerLink(User).." requested lag information");
    local Down, Up, Home, World = GetNetStats();
    SendWhisper(User, "In: "..BreakUpLargeNumbers(Down).."kB/s; Out: "..
      BreakUpLargeNumbers(Up).."kB/s; Home: "..BreakUpLargeNumbers(Home)..
      "ms; World: "..BreakUpLargeNumbers(World).."ms; FPS: "..
      BreakUpLargeNumbers(GetFramerate()).."/s");
  end,
  followme = function(User)
    local Slot = FindPartySlot(User);
    if Slot then
      if not CheckInteractDistance(User, 4) then
        Print(MakePlayerLink(User)..
          " requested follow but player is out of range");
        return SendWhisper(User,
          "I cannot follow you because you are out of range");
      end
      Print(MakePlayerLink(User).." requested follow and are now following");
      SendWhisper(User, "OK!");
    else
      Print(MakePlayerLink(User).." requested follow and attempting to do so");
      SendWhisper(User, "OK! Attempted to follow you!");
    end
    FollowUnit(User);
  end,
  bgstatus = function(User)
    Print(MakePlayerLink(User).." requested battleground status");
    local found = 0;
    for i=1, #BGData.I do
      local state, map, id = GetBattlefieldStatus(i);
      if state == "active" then
        local _, _, ascore = GetWorldStateUIInfo(1);
        local _, _, hscore = GetWorldStateUIInfo(2);
        local acount, hcount, count = 0, 0, 0;
        for I = 1, GetNumBattlefieldScores() do
          local _, _, _, _, _, faction = GetBattlefieldScore(I);
          if faction == 0 then acount = acount + 1;
          elseif faction == 1 then hcount = hcount + 1 end;
          count = count + 1;
        end
        SendWhisper(User, "Currently "..count.." players in "..map.." "..id);
        if not IsActiveBattlefieldArena() then
          SendWhisper(User, "* Alliance ("..acount..") progress - "..ascore);
          SendWhisper(User, "* Horde ("..acount..") progress - "..hscore);
        end
        SendWhisper(User, "* Been playing for "..
          MakeTime(ceil(GetBattlefieldInstanceRunTime()/1000)));
        found = 1;
        break;
      end
    end
    for i=1, #BGData.I do
      local state, map, id = GetBattlefieldStatus(i);
      local estwait = ceil(GetBattlefieldEstimatedWaitTime(i) / 1000);
      local wait = ceil(GetBattlefieldTimeWaited(i) / 1000);
      if state == "confirm" then
        SendWhisper(User, "Eligable to join "..map.." "..id);
        found = 1;
      elseif state == "queued" then
        SendWhisper(User, "Queued to join "..map);
        SendWhisper(User, "* Been waiting "..MakeTime(wait).." get in");
        SendWhisper(User, "* Estimated wait time to get in is "..
          MakeTime(estwait));
        found = 1;
      end
    end
    if found == 0 then
      SendWhisper(User,
        "I am not currently participating in any battlegrounds!");
    end
  end,
  readycheck = function(User)
    if IsInBattleground() then
      Print(MakePlayerLink(User)..
        " requested ready check but you are in a battleground!");
      return SendWhisper(User,
        "I cannot do a ready check when I am in a battleground!");
    end
    if GroupData.D.C <= 0 then
      Print(MakePlayerLink(User)..
        " requested ready check but you are not in a group!");
      return SendWhisper(User,
        "I cannot do a ready check because I am not in a group!");
    end
    Print(MakePlayerLink(User).." requested ready check!");
    SendWhisper(User, "OK!");
    DoReadyCheck()
  end,
  giveleader = function(User)
    if IsInBattleground() then
      Print(MakePlayerLink(User)..
        " requested leader but you are in a battleground!");
      return SendWhisper(User,
        "I cannot make you leader when I am in a battleground!");
    end
    if GroupData.D.C <= 0 then
      Print(MakePlayerLink(User)..
        " requested leader but you are not in a group!");
      return SendWhisper(User,
        "I cannot make you leader because I am not in a group!");
    end
    if not UnitIsGroupLeader("player") then
      Print(MakePlayerLink(User)..
        " requested leader but you are not the group leader!");
      return SendWhisper(User,
        "I cannot make you leader because I am not the group leader!");
    end
    local Slot = FindPartySlot(User);
    if not Slot then
      Print(MakePlayerLink(User)..
        " requested leader but player is not in your group!");
      return SendWhisper(User,
        "I cannot make you leader because you are not in my group!");
    end
    PromoteToLeader(Slot);
    SendWhisper(User, "OK!");
    Print(MakePlayerLink(User)..
      " requested leader and was automatically given!");
  end,
  position = function(User)
    Print(MakePlayerLink(User).." requested location information");
    SendWhisper(User, "My location is "..MakeLocationString());
  end,
  group = function(User)
    if GroupData.D.C == 0 and GroupBGData.D.C == 0 then
      Print(MakePlayerLink(User)..
        " requested group information but am not in a group");
      return SendWhisper(User, "I am not currently in a group");
    end
    Print(MakePlayerLink(User).." requested group information");
    if GroupBGData.D.C > 0 then
      SendWhisper(User, GroupBGData.D.L..
        " leads the battleground group of "..GroupBGData.D.C.." players");
    end
    if GroupData.D.C > 0 then
      SendWhisper(User, GroupData.D.L..
        " leads a group of "..GroupData.D.C.." players");
    end
    local Names;
    for Name in SortedPairs(GroupData.D.N) do
      if Names then Names = Name..", "..Names;
      else Names = Name end;
    end
    if Names then SendWhisper(User, "Members are: "..Names) end;
  end,
  inviteme = function(User)
    if FindPartySlot(User) then
      Print(MakePlayerLink(User)..
        " requested invite but player is already in this group");
      return SendWhisper(User, "You are already in my group");
    end
    local Leader = GroupData.D.L;
    if IsInBattleground() and GroupBGData.C == 0 then
      SendWhisper(User, "I am in a battleground and the invite might fail");
    elseif not UserIsMe(GroupData.D.L) and GroupData.D.C > 0 then
      Print(MakePlayerLink(User)..
        " requested invite but you are not the group leader");
      return SendWhisper(User,
        "I cannot invite you because "..GroupData.D.L.." is the group leader");
    elseif GroupData.D.C == MAX_RAID_MEMBERS then
      Print(MakePlayerLink(User)..
        " requested invite but this raid group is full");
      return SendWhisper(User,
        "I cannot invite you because this raid group is full");
    end
    InviteUnit(User);
    SendWhisper(User, "OK!");
    Print(MakePlayerLink(User)..
      " requested an invite and was automatically invited");
  end
};
-- == SECURE FUNCTION HOOKS ==================================================
FunctionHookData = {
  -- -------------------------------------------------------------------------
  FCF_FadeInChatFrame = function(Frame)
    local Name = Frame:GetName();
    local Setting = SettingEnabled("hidechb");
    for Index, Value in pairs(CHAT_FRAME_TEXTURES) do
      local Object = _G[Name..Value];
      if Setting then if Object:IsShown() then Object:Hide() end;
      elseif not Object:IsShown() then Object:Show() end;
    end
  end,
  -- -------------------------------------------------------------------------
  ShowUIPanel = function(Frame, Force)
    local Count = 0;
    for _,Name in pairs({"left","center","right","doublewide","fullscreen"}) do
      if GetUIPanel(Name) then Count = Count + 1 end;
    end
    if Count > 0 and Dialog and Dialog:IsShown() then Dialog:Hide() end;
  end,
  -- -------------------------------------------------------------------------
  ChatFrame_OnHyperlinkShow = function(Self, BareLink, Link, Button)
    if BareLink:find("^quest%:%d+:[-%d]+$") then
      local Name = BareLink:match("^.+%[(.+)%].+$");
      if Name and (IsAltKeyDown() or
        IsShiftKeyDown() or IsControlKeyDown()) then QuestLog:Show() end;
      return;
    end
    if BareLink:find("^url%:%w+%:[%w%p]+$") then
      local Protocol, Address = BareLink:match("^url%:(%w+)%:([%w%p]+)$")
      if Protocol and Address then ShowURL(Protocol.."://"..Address) end;
      return;
    end
    if not SettingEnabled("bagclik") or not IsAltKeyDown() then return end;
    local ItemId = tonumber(Link:match("%|Hitem%:(%d+)%:"));
    if not ItemId then return end;
    if Button == "RightButton" then return SlashFunc("getitem "..Link) end;
    local Count = BagData[ItemId].stackCount or 0;
    ShowInput("How many of "..Link.." would you like to keep track of? "..
      "Currently have |cffaaaaaa"..BreakUpLargeNumbers(Count).."|r!",
      "trackadd", Count+1, Link);
  end,
  -- -------------------------------------------------------------------------
  MerchantItemButton_OnModifiedClick = function(Self, Button)
    if MerchantFrame.selectedTab ~= 1 or
      not SettingEnabled("bagclik") or
      not IsAltKeyDown() or Button ~= "RightButton" then return end;
    local Link = GetMerchantItemLink(Self:GetID())
    if Link then SlashFunc("getitem "..Link) end;
  end,
  -- -------------------------------------------------------------------------
  ChatFrame_OnEvent = function(Self, Event, Msg, User, _, _, _, _, _, _,
      Channel, _, MsgId)
    if Self ~= DEFAULT_CHAT_FRAME or
      not SettingEnabled("logchat") then return end;
    local Type = Event:match("^CHAT_MSG_(.+)");
    if not Type then return end;
    if not Msg or #Msg == 0 then Msg = Event end;
    if #User == 0 then User = nil end;
    if Type == "WHISPER" then
      Type = "WHISPER "..User;
    elseif Type == "WHISPER_INFORM" then
      Type, User = "WHISPER "..User, sMyName;
    elseif Type == "BN_WHISPER" then
      Type = "BN_WHISPER "..User;
    elseif Type == "BN_WHISPER_INFORM" then
      Type, User = "BN_WHISPER "..User, sMyName;
    elseif Type == "CHANNEL" or
           Type == "CHANNEL_NOTICE" or
           Type == "CHANNEL_NOTICE_USER" then
      if Channel and #Channel > 0 then
        local NewChannel = Channel:match("(%w+)");
        if NewChannel and #NewChannel > 0 then Channel = NewChannel end;
      else Channel = "???" end;
      Type = "CHANNEL "..Channel;
    elseif Type == "BATTLEGROUND_LEADER" or Type == "BG_SYSTEM_ALLIANCE" or
           Type == "BG_SYSTEM_HORDE" or Type == "BG_SYSTEM_NEUTRAL" then
      Type = "BATTLEGROUND";
    elseif Type == "MONSTER_EMOTE" or Type == "MONSTER_SAY" or
           Type == "MONSTER_YELL" or Type == "MONSTER_WHISPER" then
      Type = "NPC";
    end
    Log(Type, Msg, User);
  end,
  -- --------------------------------------------------------------------------
--[[ FIXME
  BagSlotButton_OnDrag = function(Self)
    if LOCK_ACTIONBAR == "1" and not IsModifiedClick("PICKUPACTION") then
      BagSlotButton_OnClick(Self);
    end
  end,
--]]
  -- --------------------------------------------------------------------------
  LFGListApplicationDialog_Show = function(Frame)
    -- Ignore if setting not enabled
    if not SettingEnabled("autoall") then return end;
    -- Set the description
    Frame.Description.EditBox:
      SetText(GetDynSetting("dalfgd") or sEmpty);
    -- Do not auto-accept if shift held
    if IsShiftKeyDown() then return end;
    -- Click the button
    local oButton = Frame.SignUpButton;
    oButton:GetScript("OnClick")(oButton);
  end,
  -- --------------------------------------------------------------------------
};
-- == SECURE EVENT REGISTRATION ===============================================
FrameEventHookData = { OnUpdate = {
  -- Main casting bar in middle of frame --------------------------------------
  CastingBarFrame = FunctionHookData.CastingBarFrame_OnUpdate,
  -- Target frame casting bar -------------------------------------------------
  TargetFrameSpellBar = FunctionHookData.CastingBarFrame_OnUpdate,
  -- Casting bar of focus frame -----------------------------------------------
  FocusFrameSpellBar = FunctionHookData.CastingBarFrame_OnUpdate,
  -- ==========================================================================
}, OnValueChanged = {
  -- Automatically update tooltip mana bar ------------------------------------
  GameTooltipStatusBar = function() TriggerTimer("TUT") end,
  -- ==========================================================================
}, OnMouseUp = {
  -- --------------------------------------------------------------------------
  MiniMapWorldMapButton = function(_, Button)
    if not SettingEnabled("tsbrprt") or not IsShiftKeyDown() or
      Button ~= "RightButton" then return end;
    SendChat("<My location is "..MakeLocationString()..">");
  end,
  -- --------------------------------------------------------------------------
  PlayerPVPIconHitArea = function(_, Button)
    if not SettingEnabled("tsbrprt") or not IsShiftKeyDown() then return end;
    if Button == "LeftButton" then return end;
    SendChat("<PVP Time Remaining: "..MakeTime(GetPVPTimer()/1000)..">");
  end,
  -- ==========================================================================
}};                                    -- FrameEventHookData
-- ============================================================================
GetVersion = function()
  return format("%u%s", Version.Release, Version.Extra);
end
-- == 'pairs' like function to return sortedpairs ============================
SortedPairs = function(aData, fcbFunc)
  -- Check table
  assert(type(aData) == "table", "Invalid table");
  -- Output table
  local aOut = { };
  -- Insert all keys and values as indexed and sort them by name
  for sKey, vVal in pairs(aData) do tinsert(aOut, { sKey, vVal }) end;
  sort(aOut, fcbFunc or function(a, b) return a[1] < b[1] end);
  -- Output table index
  local iIndex = 0;
  -- Return iterator callback that returns the next item in the list
  return function()
    iIndex = iIndex + 1;
    local aItem = aOut[iIndex];
    if aItem then return aItem[1], aItem[2] end;
  end
end
-- == Template for group data ================================================
CreateBlankGroupArray = function() return { N={}, U={}, P={}, I={}, L=sEmpty,
  C=0, G={ [1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={} } } end;
-- == Return all information about the current party or raid =================
GetGroupData = function()
  -- Create new group data template
  local aGroupData = CreateBlankGroupArray();
  -- Get some aliases
  local aByNames, aByGuids = aGroupData.N, aGroupData.U;
  local aByGroup, aByPet, aByUnit = aGroupData.G, aGroupData.P, aGroupData.I;
  -- Member count
  local iCount = 0;
  -- Get group type
  local sPrefix;
  if IsInRaid() then sPrefix = "raid" else sPrefix = "Party" end;
  aGroupData.T = sPrefix;
  -- Iterate through all raid slots
  for iIndex = 1, MAX_RAID_MEMBERS do
    -- Get raid member information and if raid member is valid? Sometimes the
    -- level won't get reported straight away, so we will only validate the
    -- member when the level has been updated.
    local sName, iRank, iGroup, iLevel, sClass, sFile, sZone, bOnline, bDead,
      iRole, bMaster, sCId = GetRaidRosterInfo(iIndex);
    if sName and iLevel and iLevel > 0 then
      -- Increment count
      iCount = iCount + 1;
      -- Get unit name
      local sUnit = sPrefix..iIndex;
      -- Get unique id
      local sId = UnitGUID(sUnit) or 0;
      -- Setup new data object
      local aNewData = {
        I = sUnit,   N = sName,  R = iRank, G = iGroup,
        L = iLevel,  C = sClass, F = sFile, Z = sZone,
        O = bOnline, D = bDead,  E = iRole, M = bMaster,
        U = sId;
      };
      -- If this unit is leader then set it in the root
      if aNewData.R == 2 then aGroupData.L = sName end;
      -- Assign name, unique id, unit name and index versions of data
      aByNames[sName] = aNewData;
      aByGuids[sId] = aNewData;
      aByUnit[sUnit] = aNewData;
      tinsert(aByGroup[iGroup], aNewData);
      -- Check and record if there is a pet is assigned to the unit
      sUnit = sPrefix.."pet"..iIndex;
      sName = UnitName(sUnit);
      if sName then
        sId = UnitGUID(sUnit) or 0;
        local aNewPetData = { O = aNewData, N = sName, I = sUnit, U = sId };
        aNewData.P = aNewPetData;
        aByPet[sName] = aNewPetData;
        aByGuids[sId] = aNewPetData;
      end
    end
  end
  -- Set group member count
  aGroupData.C = iCount;
  -- Set 'in-raid' flag
  aGroupData.R = IsInRaid();
  -- Set my data
  local aMyData = aByNames[sMyName];
  if aMyData then aMyData.S = true end;
  -- Return group data to caller
  return aGroupData;
end
-- == Check if a certain user is flooding the chat with too many messages ====
IsFlooding = function(sUser)
  -- Check parameter
  assert(sUser, "User not specified");
  -- Ignore if 'block flooders' setting is disabled
  if not SettingEnabled("blockfl") then return false end;
  -- Get current time
  local iTime = time();
  -- Get timeout for existing entries
  local nTimeout = GetDynSetting("dfto");
  for sUser, aData in pairs(TextFloodData) do
    if iTime - aData.T >= nTimeout then aData[sUser] = nil end;
  end
  -- Get existing data for user and if entry doesn't exist?
  local aTFData = TextFloodData[sUser];
  if not aTFData then
    -- Set new data
    TextFloodData[sUser] = { C = 1, T = iTime };
    -- Player not flooding
    return false;
  end
  -- Get maximum lines setting. The maximum number of lines before player is
  -- deemed flooding. Return flooding if the current lines exceeds the maximum
  -- allowed lines.
  local iLinesCurrent, iLinesMax = aTFData.C, GetDynSetting("dflm");
  if iLinesCurrent >= iLinesMax then return true end;
  -- Get maximum time before the maximum lines amount is reset for player and
  local MaxTime = GetDynSetting("FloodLineTime");
  -- If the current lines reset time hasn't exceeded yet?
  if iTime - aTFData.T <= MaxTime then
    -- Increase number of lines this player has sent
    aTFData.C = iLinesCurrent + 1;
    -- If number of lines exceeded?
    if iLinesCurrent >= iLinesMax then
      -- Echo blocked message in chat
      Print("Temporarily blocked player "..MakePlayerLink(sUser)..
        " for flooding", { r=1, g=0, b=0 });
      -- Player is flooding
      return true;
    end
  -- Reset counter because time ran out
  else aTFData.C = 1 end;
  -- Update record time
  aTFData.T = iTime;
  -- User not flooding
  return false;
end
-- == Checks a message for spam ==============================================
IsSpam = function(...)
  -- Spam patterns
  local SpamPatterns = {
    "h%W?t%W?t%W?p%W?%:%W?%/%W?%/",    -- H?T?T?P?:?/?/
    "w%W?w%W?w%W?[%,%.]",              -- W?W?W?,.
    "[%,%.]%W?c%W?[o%@0]%W?m",         -- ,.?C?O?M ,.?C?0?M ,.?C?@?M
    "[%,%.]%W?n%W?e%W?t",              -- ,.?N?E?T
    "[%,%.]%W?[o%@0]%W?r%W?g",         -- ,.?O?R?G ,.?0?R?G ,.?@?R?G
    "[%,%.]%W?c%W?n",                  -- ,.?C?N
    "per%s+%d+%s+gold",                -- Money spam
  };
  -- Real function
  local function _IsSpam(sText)
    -- Check parameter
    assert(sText, "String to check for spam not specified");
    -- Ignore if spam checking not enabled
    if not SettingEnabled("blocksp") then return false end;
    -- Remove links and convert to lower case
    sText = sText:gsub("|[HT].+|[ht]", sEmpty):lower();
    -- For each spam pattern, check it against the string and return if found
    for iI = 1, #SpamPatterns do
      if sText:find(SpamPatterns[iI]) then return true end;
    end
    -- No patterns found so not spam
    return false;
  end
  -- Set and call real function
  IsSpam = _IsSpam;
  IsSpam(...);
end
-- == Checks if a message sent in public is spam =============================
IsPublicSpam = function(sText, sUser, sType)
  -- Check parameters
  assert(sText, "Text not specified");
  assert(sUser, "User not specified");
  assert(sType, "Type not specified");
  -- Ignore if not spam or we don't show a spam message
  if not IsSpam(sText) or not SettingEnabled("spammsg") then return false end;
  -- Show spam message
  Print("A "..sType.." message from "..MakePlayerLink(sUser)..
    " was blocked due to spam", {r=1,g=0,b=0});
  -- Return spam found
  return true;
end
-- == Check beggar patterns ==================================================
IsBegger = function(...)
  -- Beggar patterns
  local BeggarPatterns = {
    "can%s+%a%s+give",    "can%s+you%s+give",    "will%s+you%s+give",
    "please%s+give",      "can%s+%a%s+have",     "could%s+%a%s+have",
    "could%s+%a%s+spare", "could%s+you%s+spare", "can%s+%a%s+get",
    "can%s+%a%s+boost",   "can%s+you%s+boost",   "can%s+%a%s+help",
    "can%s+you%s+help",   "can%s+%a%s+please",   "can%s+%a%s+give",
    "could%s+%a%s+lend",  "can%s+%a%s+lend"
  };
  -- Real function
  local function _IsBegger(sText)
    -- Check parameter
    assert(sText, "Text not specified");
    -- Ignore if check beggar patterns are disabled
    if not SettingEnabled("blockbe") then return false end;
    -- Convert string to lower case
    sText = sText:lower();
    -- For each beggar pattern, check it against the string and return if found
    for iI = 1, #BeggarPatterns do
      if sText:find(BeggarPatterns[iI]) then return true end;
    end
    -- No patterns found so not spam
    return false;
  end
  -- Set and call real function
  IsBegger = _IsBegger;
  IsBegger(...);
end
-- == Send a chat message helper =============================================
SendChat = function(sMessage, sDest, sTarget, aColour, bOverride)
  -- Check that the parameters are valid, only the first one is required
  assert(sMessage, "Message not specified");
  assert(sDest     == nil or type(sDest)     == "string",  "Dest invalid");
  assert(sTarget   == nil or type(sTarget)   == "string",  "Target invalid");
  assert(aColour   == nil or type(aColour)   == "table",   "Colour invalid");
  assert(bOverride == nil or type(bOverride) == "boolean", "Invalid override");
  -- Convert non-strings to strings
  if type(sMessage) ~= "string" then sMessage = tostring(sMessage) end;
  -- If no destination was specified?
  if not sDest then
    -- Player is in instance? Set to SAY since there's no PARTY
    if IsInInstance() then sDest = "SAY";
    -- Else if in a group? Set to PARTY
    elseif GroupData.D.C > 0 then sDest = "PARTY" end;
  end
  -- If we finally got a destination?
  if sDest then
    -- Get data about the specified destination and make sure it's valid
    local Data = OutputMethodData[sDest];
    assert(Data, "Destination '"..sDest.."' is an invalid destination");
    -- If the destination can be used? and 'never report messages' setting
    -- is not enabled or the override flag is set? Send the message
    local iResult = Data.F();
    if iResult and iResult ~= -1 and
      (not SettingEnabled("forcequ") or bOverride) then
      -- Remove player links if needed
      return SendChatMessage(sMessage, sDest, nil, sTarget);
    end
  end
  -- The destination was not specified so just echo to chat.
  Print(sMessage, aColour);
end
-- == Send a whisper response to something someone else did ===================
SendResponse = function(sWho, sMessage)
  -- Check parameters
  assert(sWho, "Destination not specified");
  assert(sMessage ~= nil, "Message not specified");
  -- Ignore if sending responses is disabled
  if not SettingEnabled("blockwr") then return end;
  -- If who is not a number then it's a normal game message
  if type(sWho) ~= "number" then return SendWhisper(sWho, sMessage) end;
  -- Send the battle.net whisper
  BNSendWhisper(sWho, "<"..sMessage..">");
  -- Increment battle.net whisper counter so the automated message does not
  -- show to user.
  iBNWhisperReplySent = iBNWhisperReplySent + 1;
end
-- == Send a whisper to someone ==============================================
SendWhisper = function(sWho, sMessage)
  -- Check parameters
  assert(type(sWho) == "string", "Dest not specified or invalid variable");
  assert(IsValidPlayerName(sWho), "Invalid username syntax specified");
  assert(sMessage ~= nil, "Message not specified");
  -- If I'm AFK then we need to clear the auto clear AFK setting because we
  -- will get spammed when whispering ourselves (testing).
  if nAwayFromKeyboard > 0 and GetCVar("autoClearAFK") == "1" then
    bAutoClearAFKDisabled = true;
    SetCVar("autoClearAFK", "0");
  end
  SendChatMessage("<"..sMessage..">", "WHISPER", nil, sWho);
  iWhisperReplySent = iWhisperReplySent + 1;
end
-- == Put a message in the top middle of the stream ==========================
HudMessage = function(sText, nR, nG, nB)
  -- Check parameter
  assert(sText, "No text was specified");
  -- ADd the message for the default time
  UIErrorsFrame:AddMessage(sText, nR or 1, nG or 1, nB or 1, 1,
    UIERRORS_HOLD_TIME);
end
-- ===========================================================================
Log = function(sType, sMsg, sUser)
  -- Check parameters
  assert(sType, "Type not specified!");
  assert(sMsg, "Message not specified!");
  assert(mhclog, "No log database?!");
  -- Get log category and make it if it doesn't exist
  local aCat = mhclog[sType];
  if not aCat then aCat = { } mhclog[sType] = aCat end;
  -- Get current time
  local iTime = time();
  -- Check if a log entry for this timestamp already exists and if it does?
  local sText = aCat[iTime];
  if sText then
    -- Append the string if there is a user
    if sUser then sText = sText.."\31"..sUser.."\30"..sMsg;
    -- No username
    else sText = sText.."\31"..sMsg end;
  -- Log entry doesn't exist so set one if user set
  elseif sUser then sText = sUser.."\30"..sMsg;
  -- No user set
  else sText = sMsg end;
  -- Set the new timestamp
  aCat[iTime] = sText;
end
-- Text printer ---------------------------------------------------------------
Print = function(sText, aColour)
  -- If text is a table
  if type(sText) == "table" then
    -- Maximum level
    local MaxLevel = 0xFF;
    -- Do not reparse existing tables list
    local Tables = { };
    -- The recursive function
    function InternalShowTable(sText, Level, MaxLevel)
      local Colour, Index, Type = 255-(Level*32), 0;
      local Name = sText.GetName;
      if type(Name) == "function" then
        Name = Name(sText);
        if Name then
          Print(format("|cff%02xff%02x%"..
            (Level*2).."s%s (|cffffff00"..Name.."|r)...",
              Colour, Colour, sEmpty, tostring(sText), tostring(Name)));
        end
      end
      for Key, Value in pairs(sText) do
        Index = Index + 1;
        Print(format("|cff%02xff%02x%"..(Level*2).."s%u: %s = %s|r",
          Colour, Colour, sEmpty, Index, tostring(Key), tostring(Value)));
        if type(Value) == "table" then
          local AlreadyEnumerated = false;
          for iI = 1, #Tables do
            local Table = Tables[iI]
            if Table == Value then
              AlreadyEnumerated = true;
              break;
            end
          end
          if not AlreadyEnumerated then
            tinsert(Tables, Value);
            if Level + 1 < MaxLevel then
              InternalShowTable(Value, Level + 1, MaxLevel)
            end
          end
        end
      end
      Print(format("|cff%02xff%02x%"..(Level*2)..
        "sA total of %u items in this table.|r",
          Colour, Colour, sEmpty, Index));
    end
    -- Do the enumeration and return
    return InternalShowTable(sText, 0, MaxLevel or 10);
  end
  -- Set a default colour if none specified. This table is compatible with
  -- Blizzard;s ChatTypeInfo[] object members.
  if type(aColour) ~= "table" then aColour = { r=1, g=0.75, b=0.5 } end;
  -- Make sure text it's a string
  sText = tostring(sText);
  -- Add the text to the default chat frame
  tinsert(PrintData, { MakeTimestamp()..FilterUrls(sText), aColour });
  -- Also log it
  Log("ECHO", sText);
end
-- ===========================================================================
IsInBattleground = function()
  local Boolean, Type = IsInInstance();
  if Boolean and (Type == "pvp" or Type == "arena") then
    for _, Data in pairs(BGData.I) do
      if Data.S == "active" then return Data.M end;
    end
    return "Unknown";
  end
end
-- ===========================================================================
UnitIsFriend = function(user)
  assert(user, "User not specified");
  return FriendsData[user];
end
-- == Check if specified player is in your guild =============================
UserIsInGuild = function(sUser)
  assert(sUser, "sUser not specified");
  if not IsInGuild() then return false end;
  local Count = GetNumGuildMembers();
  for Index = 1, Count do
    if GetGuildRosterInfo(Index) == sUser then return Index end;
  end
  return false;
end
-- ===========================================================================
UserIsOfficer = function(User)
  if not IsInGuild() then return false end;
  if not User then User = sMyName end;
  local Count = GetNumGuildMembers();
  for Index = 1, Count do
    local Name, _, Rank = GetGuildRosterInfo(Index);
    if Name == User then
      local _, _, _, CanTalk = C_GuildInfo.GuildControlGetRankFlags(4);
      return CanTalk or Rank == 0;
    end
  end
  return false;
end
-- ===========================================================================
UserIsIgnored = function(User)
  assert(User, "User not specified");
  local Count = 0; -- FIXME GetNumIgnores();
  for Index = 1, Count do
    if GetIgnoreName(Index) == User then return true end;
  end
  return false;
end
-- ===========================================================================
UserIsMe = function(user)
  return sMyName == user or sMyNameRealm == user;
end
-- ===========================================================================
UserIsExempt = function(user)
  assert(user, "User not specified");
  if WhisperExemptData[user] and time() >= WhisperExemptData[user] then
    WhisperExemptData[user] = nil;
  end
  return not UserIsIgnored(user) and (UserIsMe(user) or
    (SettingEnabled("xwhispt") and WhisperExemptData[user]) or
    (SettingEnabled("xfriend") and UnitIsFriend(user)) or
    (SettingEnabled("xguildm") and UserIsInGuild(user)) or
    (SettingEnabled("xtarget") and UnitName("target") == user)) or
    (SettingEnabled("xgroupm") and GetUnitInfo(user))
end
-- ===========================================================================
SettingEnabled = function(Setting)
  assert(Setting, "Setting not specified");
  return ConfigBooleanData[Setting];
end
-- ===========================================================================
SetDynSetting = function(Setting, Value)
  assert(Setting, "Setting not specified");
  assert(mhconfig, "No configuration database, please restart!");
  ConfigDynamicData[Setting] = Value;
end
-- ===========================================================================
GetDynSetting = function(Setting)
  assert(Setting, "Setting not specified");
  assert(mhconfig, "No configuration database, please restart!");
  return ConfigDynamicData[Setting];
end
-- ===========================================================================
FindPartySlot = function(User, Battleground)
  assert(User, "User not specified");
  local Data;
  if Battleground then Data = GroupBGData else Data = GroupData end;
  Data = Data.D.N[User];
  if not Data then return nil end;
  return Data.I;
end
-- ===========================================================================
ClickDialogButton = function(Dialog, Index)
  assert(Dialog, "Dialog not specified");
  assert(Index, "Index not specified");
  for I = 1, STATICPOPUP_NUMDIALOGS do
    local F = _G["StaticPopup"..I];
    if F:IsVisible() and F.which == Dialog then
      local D = StaticPopupDialogs[Dialog];
      assert(D, "No StaticPopupDialogs data for "..Dialog);
      StaticPopup_OnClick(F, Index);
      StaticPopup_OnClick(F, 2);
    end
  end
end
-- ===========================================================================
StringToColour = function(String)
  assert(String, "String not specified");
  local R, G, B, L, C = 0, 0, 0, #String;
  for I = 1, L do
    C = strbyte(String, I);
    R = (B + C * L + G)%0x100;
    G = (R + C * L + B)%0x100;
    B = (G + C * L + R)%0x100;
  end
  return R, G, B;
end
-- ===========================================================================
TableSize = function(Table)
  assert(Table, "Table not specified");
  assert(type(Table) == "table", "Not a table");
  local Count = 0;
  for _ in pairs(Table) do Count = Count + 1 end;
  return Count;
end
-- ===========================================================================
ShowQuestion = function(Text, Function)
  assert(Text, "Text not specified");
  assert(Function, "Function not specified");
  local WindowName = "MH_QUESTION";
  StaticPopup_Hide(WindowName);
  StaticPopupDialogs[WindowName] = {
    text      = Text, button1   = "Yes", button2      = "No", timeout   = 0,
    exclusive = 1,    whileDead = 1,     hideOnEscape = 1,    showAlert = 1,
    OnAccept  = function(Self) SlashFunc(Function) end,
  }
  StaticPopup_Show(WindowName);
end
-- ===========================================================================
ShowMsg = function(Text, Function, Icon, Item)
  assert(Text, "Text not specified");
  local WindowName = "MH_MESSAGE";
  local function Evaluate(Var, Text)
    if Var then return Text end;
    return nil;
  end
  StaticPopupDialogs[WindowName] = {
    text = Text,
    button1 = "Ok",
    button2 = Evaluate(Item, "Cancel"),
    OnShow = function(Self)
      if not Self then return end;
      local Tex = _G[Self:GetName().."AlertIcon"];
      if Tex and Tex:IsVisible() and Icon and Icon ~= true then
        Tex:SetTexture(Icon);
      end
    end,
    OnHide = function(Self)
      if not Self then return end;
      local Tex = _G[Self:GetName().."AlertIcon"];
      if Tex and Tex:IsVisible() then
        Tex:SetTexture("Interface\\DialogFrame\\DialogAlertIcon");
      end
      if Self.Accepted and Function then
        SlashFunc(Function);
      end
      Self.Accepted = nil;
    end,
    OnCancel = function(Self)
      if not Self then return end;
      Self.Accepted = false;
    end,
    OnAccept = function(Self)
      if not Self then return end;
      Self.Accepted = true;
    end,
    hasItemFrame = Item ~= nil,
    showAlert = Icon ~= nil,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
  }
  StaticPopup_Show(WindowName, nil, nil, Item);
end
-- ===========================================================================
ShowURL = function(Address)
  local Key;
  if IsMacClient() then
    Key = "Cmd";
  else
    Key = "Ctrl";
  end
  ShowInput("Press |cff7f7f7f"..Key.."+A|r to select the text and |cff7f7f7f"..Key.."+C|r to copy it. You can then paste this text with |cff7f7f7f"..Key.."+V|r in your browser or any other standard edit box.", nil, Address);
end
-- ===========================================================================
ShowInput = function(Text, Function, Current, Extra)
  assert(Text, "Text not specified");
  local WindowName = "MH_INPUT";
  local function Confirm(Self)
    assert(Function, "Function not specified!");
    local Parent = Self:GetParent();
    assert(Parent, "Parent not specified!");
    local ParentName = Parent:GetName();
    assert(ParentName, "Parent name not resolved!");
    if ParentName == "UIParent" then Self = Self.editBox end;
    assert(Self, "Self not resolved!");
    local Text = Self:GetText();
    if Extra and Text == sEmpty then return end;
    local Command = Function.." "..Text;
    if Extra then Command = Command.." "..Extra end;
    SlashFunc(Command);
  end
  local function VarOrNil(Condition, IfTrue, IfFalse)
    if Condition then return IfTrue else return IfFalse end;
  end
  StaticPopupDialogs[WindowName] =
  {
    text = Text,
    button1 = VarOrNil(Function, "Accept", nil);
    button2 = VarOrNil(Function, "Cancel", "Close");
    hasEditBox = 1,
    hasWideEditBox = 1,
    maxLetters = 256,
    OnShow = function(oSelf)
      local oBox = oSelf.editBox;
      oBox:SetText(Current or sEmpty);
      oBox:HighlightText();
    end,
    EditBoxOnEnterPressed = Confirm,
    EditBoxOnEscapePressed = function(Self)
      Self:GetParent():Hide();
    end,
    OnAccept = Confirm,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
  }
  StaticPopup_Show(WindowName);
end
-- ===========================================================================
VariableExists = function(Variable)
  assert(Variable, "Variable not specified");
  for _, V in pairs(ConfigData.Options) do
    if V[Variable] then return V[Variable] end;
  end
end
-- ===========================================================================
CommandExists = function(Command)
  assert(Command, "Command not specified");
  for _, V in pairs(ConfigData.Commands) do
    if V[Command] then
      return V[Command];
    end
  end
end
-- ===========================================================================
MakeLocationString = function()
  local ZoneData;
  local SubZone = GetSubZoneText();
  if SubZone and SubZone ~= sEmpty then
    ZoneData ="the "..SubZone.." of "..GetRealZoneText();
  else
    ZoneData = GetRealZoneText();
  end
  local iMapId = C_Map.GetBestMapForUnit("player");
  local aData = C_Map.GetPlayerMapPosition("player");
  local X, Y = aData:GetXY();
  if X == 0 and Y == 0 then return "inside "..ZoneData end;
  return RoundNumber(X*100, 1)..","..RoundNumber(Y*100, 1).." in "..ZoneData;
end
-- ===========================================================================
GetNearestUnit = function()
  for Name, Data in pairs(GroupData) do
    if not UserIsMe(Name) and UnitIsVisible(Data.I) then return Data.I end;
  end
end
-- ===========================================================================
RoundNumber = function(Integer, Count)
  assert(Integer, "Number not specified");
  assert(Count, "Count not specified");
  local Power = 1;
  while Count > 0 do
    Power = Power*10
    Count = Count-1;
  end
  return floor(Integer*Power+0.5)/Power;
end
-- ===========================================================================
MakeCountdown = function(Label, Cur, Max)
  assert(Label, "Label not specified");
  assert(Cur, "Current not specified");
  assert(Max, "Maximum not specified");
  Cur = ClampNumber(Cur, 0, Max);
  if Cur >= 60 then
    return format("|cffffffff%s (|r%u:%02u|cffffffff)|r", Label, Cur/60, Cur%60);
  end
  return format("|cffffffff%s (|r%.1f|cffffffff)|r", Label, Cur);
end
-- ===========================================================================
MakeTime = function(Seconds)
  assert(Seconds, "Seconds not specified");
  local Number, OfWhat;
  if Seconds >= 604800 then Number, OfWhat = floor(Seconds/604800), "week";
  elseif Seconds >= 86400 then Number, OfWhat = floor(Seconds/86400), "day";
  elseif Seconds >= 3600 then Number, OfWhat = floor(Seconds/3600), "hour";
  elseif Seconds >= 60 then Number, OfWhat = floor(Seconds/60), "min";
  else Number, OfWhat = floor(Seconds), "sec" end;
  if Number ~= 1 then OfWhat = OfWhat.."s" end;
  return Number.." "..OfWhat;
end
-- ===========================================================================
StatsClear = function(DoAll, AndBestStats)
  if not mhstats then mhstats = { } end;
  for Data in pairs(StatsCatsData) do
    if not mhstats[Data] or DoAll then mhstats[Data] = { } end;
  end
  local AdditionalStatsData = {
    BS = { DF={ },    CO=AndBestStats }, BST = { DF=time(), CO=AndBestStats },
    SB = { DF=time(), CO=DoAll },        CT  = { DF=0,      CO=DoAll },
  }
  for Variable, Data in pairs(AdditionalStatsData) do
    if not mhstats[Variable] or Data.CO then
      mhstats[Variable] = Data.DF;
    end
  end
end
-- ===========================================================================
MakeMoneyReadable = function(iAmount)
  -- GCTS will fail if < 0 so make sure we handle it
  local sExtra;
  if iAmount < 0 then iAmount, sExtra = -iAmount, "-";
                 else sExtra = sEmpty end;
  -- Return the amount
  return sExtra..GetCoinTextureString(iAmount);
end
-- ===========================================================================
MakePrettyIcon = function(User)
  if not SettingEnabled("chaticn") then return sEmpty end;
  if UnitIsFriend(User) then
    return ICON_LIST[ICON_TAG_LIST.diamond].."0|t";
  end
  if UserIsInGuild(User) then
    if UserIsOfficer(User) then
      return ICON_LIST[ICON_TAG_LIST.star].."0|t";
    end
    return ICON_LIST[ICON_TAG_LIST.circle].."0|t";
  end
  return sEmpty;
end
-- ===========================================================================
MakeQuestPrettyNameId = function(iId)
  local sTitle = C_QuestLog.GetTitleForQuestID(iId);
  if not sTitle then return sEmpty end;
  local sText = sEmpty;
  local sTag = C_QuestLog.GetQuestTagInfo(iId);
  if sTag then
    sTag = sTag.tagName;
    sText = "[|cff"..format("%02x%02x%02x", StringToColour(sTag))..sTag.."|r]";
  end
  if iGroup and iGroup > 0 then
    sText = sText.."[|cffffffffx"..iGroup.."|r]" end;
  sText = sText..(GetQuestLink(iId) or ("["..sTitle.."]"));
  local iGroup = C_QuestLog.GetSuggestedGroupSize(iId);
  return sText;
end
-- ===========================================================================
MakeQuestPrettyName = function(iIndex)
  return MakeQuestPrettyNameId(C_QuestLog.GetQuestIDForLogIndex(iIndex));
end
-- ===========================================================================
StripRealmFromName = function(sName)
  -- Match name and realm and return only user part if on my realm
  local sUser, sRealm = sName:match("^(.+)%-(.+)$");
  if sUser and sRealm and sRealm == sMyRealm then return sUser end;
  -- Else return full name
  return sName;
end
-- ===========================================================================
MakePrettyName = function(Part, UMsg, User, Lang, Chan, Flag, MsgId)
  if not SettingEnabled("chatcol") then return end;

  local Msg, R, G, B = sEmpty;

  if #User > 0 then
    -- Trim user name if on same realm
    User = StripRealmFromName(User);

    R, G, B = StringToColour(User);
    if Flag == "NPC" then Msg = _G["CHAT_"..Part.."_GET"]:gsub("%%s",
      format("[|cff000000NPC|r][|cff%02x%02x%02x%s|r]", R, G, B, User));
    elseif Flag == "BN" then Msg = _G["CHAT_"..Part.."_GET"]:gsub("%%s",
      format("|HBNplayer:%s:%u|h[|cff%02x%02x%02x%s%s|r]|h", User, MsgId or 0,
        R, G, B, MakePrettyIcon(User), User));
    else Msg = _G["CHAT_"..Part.."_GET"]:gsub("%%s",
      format("|Hplayer:%s:%u|h[|cff%02x%02x%02x%s%s|r]|h", User, MsgId or 0,
        R, G, B, MakePrettyIcon(User), User));
    end
  end

  if Lang ~= sEmpty and Lang ~= "Universal" and
     Lang ~= DEFAULT_CHAT_FRAME.defaultLanguage then
    R, G, B = StringToColour(Lang);
    Msg = format("%s(|cff%02x%02x%02x%s|r) %s", Msg, R, G, B, Lang, UMsg);
  else
    Msg = Msg..UMsg;
  end

  if Flag == "GM" then
    Msg = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:18:12:0:-1|t"..Msg;
  elseif _G["CHAT_FLAG_"..Flag] then
    Msg = "<"..Flag..">"..Msg;
  end

  if Part == "CHANNEL" then
    local Channel = Chan;
    local Dash = Chan:find(" %- ");
    if Dash then
      Channel = Chan:sub(1, Dash - 1);
    end
    R, G, B = StringToColour(Channel);
    Msg = format("[|cff%02x%02x%02x%s|r] %s", R, G, B, Channel, Msg);
  end
  local I = ChatTypeInfo[Part];
  if not I then return nil end;

  for Tag in Msg:gmatch("%b{}") do
    local Term = Tag:gsub("[{}]", sEmpty):lower();
    if ICON_TAG_LIST[Term] and ICON_LIST[ICON_TAG_LIST[Term]] then
      Msg = Msg:gsub(Tag, ICON_LIST[ICON_TAG_LIST[Term]].."0|t");
    end
  end

  Print(MakeTimestamp()..FilterUrls(Msg), I);

  return 1;
end
-- ===========================================================================
ShowDelayedWhispers = function()
  -- Ignore if no whisper log or it is empty
  if not mhwlog or #mhwlog <= 0 then return end;
  -- Until whisper log is empty
  while #mhwlog > 0 do
    -- Get data for whisper
    local aData = mhwlog[#mhwlog];
    -- Remove whisper from log
    tremove(mhwlog, #mhwlog);
    -- Colour
    local sColour, sExtra;
    if aData.B then sColour, sExtra = "BN_WHISPER", "on B.Net ";
               else sColour, sExtra = "WHISPER", sEmpty end;
    -- Print the whisper
    Print(aData.N.." whispered "..sExtra..MakeTime(time()-aData.T)..
      " ago: "..aData.M, ChatTypeInfo[sColour]);
  end
  -- Play whisper sound
  PlaySound(SOUNDKIT.TELL_MESSAGE);
end
-- ===========================================================================
GetQuestLinkFromName = function(QuestNameToLink)
  assert(QuestNameToLink, "Name not specified");
  for QuestId, Data in pairs(QuestData) do
    local QuestLink = GetQuestLink(Data.N);
    if QuestLink then
      local QuestName = QuestLink:match("^.+%[(.+)%].+$");
      if QuestName and QuestNameToLink == QuestName then return QuestLink end;
    end
  end
end
-- ===========================================================================
ProcessTextString = function(Frame, Percent, Text)
  assert(Frame, "Frame not specified");
  assert(Percent, "Percent value not specified");
  assert(Text, "Text not specified");
  if not Frame:IsVisible() then Frame:Show() end;
  Frame:SetText(Text);
  if not SettingEnabled("numcolr") then return end;
  if Percent >= 50 then Frame:SetTextColor(1, 1, (Percent-50)/50);
  elseif Percent >= 0 then Frame:SetTextColor(1, Percent/50, 0) end;
end
-- ===========================================================================
-- Trigger a timer event
-- ===========================================================================
TriggerTimer = function(sName)
  -- Check parameter
  assert(type(sName)=="string", "Invalid timer");
  -- Get timer and return if it doesn't exist
  local aData = TimerData[sName];
  if not aData then return end;
  -- Trigger the timer by setting the end time
  aData.E = GetTime();
end
-- ===========================================================================
CreateTimer = function(Dura, Func, Loop, Name, Trigger)
  -- Check parameters
  assert(type(Name)=="string", "Invalid name");
  assert(type(Dura)=="number", "Invalid duration");
  assert(type(Func)=="function", "Invalid callback");
  -- Check for existing data and if it exists? Update data
  local aTimer = TimerData[Name];
  if aTimer then aTimer.D, aTimer.C, aTimer.F, aTimer.E =
                   Dura, Loop, Func, GetTime();
  -- Set new data
  else aTimer = { N=Name,              -- Name of timer
                  D=Dura,              -- Duration of timer
                  C=Loop,              -- Number of loops (nil = infinite)
                  F=Func,              -- Callback function
                  E=GetTime() };       -- End time
    -- Set in timer list
    TimerData[Name] = aTimer;
    -- Also add an index to the timer list. This is for faster iteration
    tinsert(TimerData, aTimer);
  end
  -- If trigger boolean is false then extend the duration
  if not Trigger then aTimer.E = aTimer.E + Dura end;
end
-- ===========================================================================
GetTimer = function(sName)
  -- Check parameter
  assert(type(sName)=="string", "Invalid timer");
  -- Return data for timer
  return TimerData[sName];
end
-- ===========================================================================
KillTimer = function(sName)
  -- Check parameter
  assert(type(sName)=="string", "Invalid timer");
  -- Get timer and return if it doesn't exist
  local aData = TimerData[sName];
  if not aData then return false end;
  -- Remove the key/value timer
  TimerData[sName] = nil;
  -- Now iterate through the indexes and delete the timer when we find it
  for iI = 1, #TimerData do
    if TimerData[iI] == aData then tremove(TimerData, iI) break end;
  end
  -- Success
  return true;
end
-- == Sets combat statistical persistant data ================================
StatsSet = function(iTime, sName, iFlags, sTable, sIndex, iAmount, iSkId, bHe)
  -- Increment counters best on skill
  local Data = GroupData.D.P[sIndex];
  if Data then sIndex = Data.O.N end;
  Data = mhstats[sTable];
  Data[sIndex] = (Data[sIndex] or 0) + iAmount;
  -- Done if no skill name was supplied
  if not iSkId then return end;
  -- Set a new key value to use because some healing and damage will use the
  -- same skill ID.
  local sKey;
  if bHe then sKey = iSkId.."H" else sKey = iSkId.."D" end;
  -- Negate number if was healing
  if bHe then iAmount = -iAmount end;
  -- Get best stats for player and new record if not found
  local BSDPlayer = BestStatsData[sIndex];
  if not BSDPlayer then
    BestStatsData[sIndex] =
      { iTime, 1, {[sKey]={ iTime, iAmount, sName }} };
  else
    -- Get best stats data entries for player and new record if not found
    local BSDPData = BSDPlayer[3];
    if not BSDPData then
      BestStatsData[sIndex] =
        { iTime, 1, {[sKey]={ iTime, iAmount, sName }} };
    else
      -- Entry is updated
      BSDPlayer[1] = iTime;
      -- Get best stats for player and skill if we found it
      local BSDPSData = BSDPData[sKey];
      if BSDPSData then
        -- Get last top amount and if it is valid? There is a problem where
        -- some skills have the same name for both healing/damage so we will
        -- just prioritise damage bests only.
        local iTopAmount = BSDPSData[2];
        if iTopAmount and iAmount <= iTopAmount then return end;
      -- Not found so adding a new entry
      else BSDPlayer[2] = BSDPlayer[2] + 1 end;
      -- Add or replace the entry
      BSDPData[sKey] = { iTime, iAmount, sName };
    end
  end
  -- Done if skill wasn't cast by me or show new records setting is disabled
  if 0 == BAnd(COMBATLOG_OBJECT_AFFILIATION_MINE, iFlags) or
    not bStatsBests then return end;
  -- Get link for spell so player can click on it. Use skill name if nil.
  local sLink = C_Spell.GetSpellLink(iSkId);
  if not sLink or #sLink == 0 then sLink = sSkill or iSkId end;
  -- Print the new record to chat
  local sType;
  if iAmount >= 0 then sType = "damage";
  else iAmount = -iAmount; sType = "healing" end;
  Print("New "..sLink.." "..sType.." record of "..
    BreakUpLargeNumbers(iAmount));
end
-- ===========================================================================
UnitFrameUpdate = function(oFrame)
  -- Ignore if no frame
  if not oFrame then return end;
  -- Ignore if frame is not visible
  if not oFrame:IsVisible() then return end;
  -- Get unit and return if a unit name is not assigned
  local sUnit = oFrame.unit;
  if not sUnit then return end;
  -- Get nameplate text frame and return if invalid
  local oText = oFrame.name;
  if not oText then return end;
  -- If the unit exists and the 'show
  if UnitExists(sUnit) and SettingEnabled("unitnpe") then
    if not UnitIsConnected(sUnit) then
      oText:SetTextColor(.5, .5, .5);
    elseif UnitIsDeadOrGhost(sUnit) then
      oText:SetTextColor(1, 0, 0);
    elseif UnitClass(sUnit) then
      local _, UC = UnitClass(sUnit);
      local CC = RAID_CLASS_COLORS[UC];
      oText:SetTextColor(CC.r, CC.g, CC.b);
    end
    -- Get frame callback and if it exists? Run it
    local fCb = oFrame:GetAttribute("mhcb");
    if fCb then fCb(oText, sUnit) else oText:SetText(UnitName(sUnit)) end;
    return;
  end
  oText:SetTextColor(1, 1, .75);
  oText:SetText(UnitName(sUnit));
end
-- ===========================================================================
GetFreeBagSpaces = function()
  local Count = 0;
  for Index = 0, 4 do Count = Count + GetContainerNumFreeSlots(Index) end;
  return Count;
end
-- ===========================================================================
MakePlayerLink = function(Name, Id)
  assert(Name, "Name not specified");
  if Id then return "|Hplayer:"..Name..":"..Id.."|h["..Name.."]|h" end;
  return "|Hplayer:"..Name.."|h["..Name.."]|h";
end
-- ===========================================================================
CreateMenuItem = function(aIn, ...)
  -- Check parameter
  assert(type(aIn)=="table", "Supplied table is invalid");
  -- Prepare menu item to be compatible with Blizzard secure code
  local aOut = UIDropDownMenu_CreateInfo();
  -- Copy table into this
  for sKey, vValue in pairs(aIn) do aOut[sKey] = vValue end;
  -- Add the menu item
  UIDropDownMenu_AddButton(aOut, ...);
end
-- ===========================================================================
ShowPasteMenu = function(Frame, Function)
  assert(Frame, "Frame not specified");
  assert(Function, "Function not specified");
  UIDropDownMenu_Initialize(MhMod, function(Self, Level)
    if Level == 1 then
      CreateMenuItem({ isTitle = 1, hasArrow = false, notCheckable = true,
        text = "Paste to..." });
      for Method, Data in SortedPairs(OutputMethodData) do
        if Data.F() then
          local bHasArrow, bKeepShown, sArg1, fCb;
          if Data.T >= 1 then bHasArrow, bKeepShown = true, true;
          else bHasArrow, sArg1, fCb = false, Method, Function end;
          CreateMenuItem({ disabled = false, notCheckable = true,
            value = Method, text = Data.L, hasArrow = bHasArrow,
            keepShownOnClick = bKeepShown, arg1 = sArg1, func = fCb });
        end
      end
      return;
    end
    if UIDROPDOWNMENU_MENU_VALUE == "WHISPER" then
      CreateMenuItem({ text = "Whisper who?", isTitle = 1, hasArrow = false,
        notCheckable = true }, 2);
      CreateMenuItem({ text = "           ", isTitle = 1, hasArrow = false,
        notCheckable = true }, 2);
      local Parent = DropDownList2Button2;
      local Frame = MenuEditBoxFrame;
      if not Frame then
        Frame = CreateFrame("EditBox", nil, nil,
          "AutoCompleteEditBoxTemplate" and
          BackdropTemplateMixin and "BackdropTemplate");
        MenuEditBoxFrame = Frame;
        Frame.autoCompleteParams = AUTOCOMPLETE_LIST.ALL;
        Frame:SetBackdrop({
          bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
          tile     = true,
          tileSize = 8,
          insets   = { left = 0, right = 0, top = 0, bottom = 0 }
        });
        Frame:SetFont("fonts\\frizqt__.ttf", 12, sEmpty);
        Frame:SetShadowColor(0, 0, 0);
        Frame:SetShadowOffset(1, -1);
        Frame:SetBackdropColor(0, 0, 0, 1);
        Frame:SetScript("OnShow", function(Self)
          Frame:SetParent(Parent);
          Frame:SetPoint("TOPLEFT", Parent);
          Frame:SetJustifyH("LEFT");
          Frame:SetWidth(Parent:GetParent().maxWidth);
          Frame:SetHeight(Parent:GetHeight());
          Frame:SetAutoFocus(true);
          Frame:SetMultiLine(false);
          Frame:HighlightText();
          Frame:SetFocus();
        end);
        Parent:SetScript("OnHide", function(Self)
          Frame:ClearFocus();
          Frame:Hide();
        end);
        Frame:SetMaxLetters(12);
        Frame:SetScript("OnEscapePressed", function(Self)
          Self:ClearFocus();
          ToggleDropDownMenu(nil, nil, MhMod);
        end);
        Frame:SetScript("OnEnterPressed", function(Self)
          Function(Self, UIDROPDOWNMENU_MENU_VALUE, Self:GetText());
          ToggleDropDownMenu(nil, nil, MhMod);
        end);
        Frame:SetScript("OnTextChanged", function(Self, Text)
          AutoCompleteEditBox_OnTextChanged(Self, Text);
        end);
      end
      Frame:Show();
      return
    end
    if UIDROPDOWNMENU_MENU_VALUE == "CHANNEL" then
      CreateMenuItem({ text = "Channels", hasArrow = false,
        notCheckable = true, isTitle = 1 }, 2);
      local Id;
      for _, Channel in pairs({ GetChannelList() }) do
        if not Id then Id = Channel;
        else
          CreateMenuItem({ text = Channel, notCheckable = true,
            hasArrow = false, arg1 = UIDROPDOWNMENU_MENU_VALUE, arg2 = Id,
            func = Function }, 2);
          Id = nil;
        end
      end
      return;
    end
    CreateMenuItem({ text = "Are you sure?", isTitle = 1, hasArrow = false,
      notCheckable = true }, 2);
    CreateMenuItem({ hasArrow = false, notCheckable = true, func = Function,
      arg1 = UIDROPDOWNMENU_MENU_VALUE,
      text = "Yes, "..OutputMethodData[UIDROPDOWNMENU_MENU_VALUE].L }, 2);
  end, "MENU", 1);
  ToggleDropDownMenu(1, nil, MhMod, Frame, 0, 0);
end
-- ===========================================================================
StripColour = function(sT)
  assert(sT, "Text not specified");
  local aLinks, iCount = { }, 0;
  sT = sT:gsub("\124c%x%x%x%x%x%x%x%x\124H.-\124h.-\124h\124r", function(sS)
    tinsert(aLinks, sS);
    iCount = iCount+1;
    return "\29"..iCount;
  end);
  sT = sT:gsub("\124c%x%x%x%x%x%x%x%x", sEmpty):
          gsub("\124c", sEmpty):
          gsub("\124[Hh]", sEmpty):
          gsub("\124r", sEmpty);
  while iCount > 0 do
    sT = sT:gsub("\29"..iCount, aLinks[iCount]);
    iCount = iCount - 1;
  end
  return sT;
end
-- ===========================================================================
ShowDialog = function(Body, Caption, Type, TypeParam)
  -- Check parameters
  assert(Type, "Type not specified");
  -- Available dialog backgrounds
  local BackgroundPicturesData = {
    "ABrewingStorm","AhnQiraj20man","AhnQiraj40man","ArathiBasin",
    "ArgentDungeon","ARGENTRAID","AssaultonZanVess","AUCHINDOUN","BaradinHold",
    "BlackFathomDeeps","BlackrockCaverns","BlackrockDepths","BlackrockSpire",
    "BlackTemple","BlackwingDescentRaid","BlackWingLair","BladesEdgeArena",
    "BlizzCon09","BrewmoonFestival","Cave","ChamberBlack","ChampionsHall",
    "CryptOfForgottenKings","DalaranSewersArena","DarkmoonIsland","Deadmines",
    "DeathwingRaid","Deepholm","DEEPHOLMDUNGEON","DeepRunTram","DireMaul",
    "DrakTheron","Dungeon","EASTERNKINGDOM","EasternKingdom2",
    "EASTERNKINGDOM2WIDE","EasternKingdomWide","EndTime","Enviroment",
    "Firelands","FirelandsRaid","GateoftheSettingSun","GilneasBG","GilneasBG2",
    "Gnomeregan","GreenstoneVillage","GRIMBATOL","GrimBatolRaid",
    "HallofLegends","HallsofOrigination","HallsofReflection","HeartOfFear",
    "HELLFIRECITADEL","HELLFIRECITADEL5MAN","HELLFIRECITADELRAID",
    "HourofTwilight","Hyjal","Icecrown5man","IcecrownCitadel","ISLEOFCONQUEST",
    "JadeForest","JadeTemple","KALIMDOR","Kalimdor2","KALIMDOR2WIDE",
    "KalimdorWide","Maelstrom","Maraudon","MogushanPalace","MoguShanVaults",
    "MoltenCore","Monastery","NagrandArenaBattlegrounds","Naxxramas",
    "NetherBattlegrounds","Nexus80","NORTHREND","Northrend2","NORTHREND2WIDE",
    "NorthrendBG","NorthrendWide","OrgrimmarArena","OUTLAND","Outland2",
    "OUTLAND2WIDE","OutlandWide","Pandaria","PandariaWide","PitofSaron",
    "PvpBattleground","RagefireChasm","Raid","RazorfenDowns","RazorfenKraul",
    "RubySanctum","RuinedCity","RuinsofLordaeronBattlegrounds","ScarletHalls",
    "ScarletMonastery2","Scholomance","Scholomance2","SHADOWFANGKEEP",
    "ShadowpanMonastery","SiegeofNizaoTemple","SilvershardMines","Skywall",
    "SkywallRaid","StormstoutBrewery","StormwindStockade","Strathome",
    "SunkenTemple","Sunwell5Man","TEMPESTKEEP","TerraceofEndlessSprings",
    "TheramoreAlliance","TheramoreHorde","ThroneoftheTides","TolvirArena",
    "TwinPeaksBG","ULDAMAN","UngaIngoo","ValleyofPower",
    "ValleyoftheFourWindsMap","WailingCaverns","WANDERINGISLE","WarsongGulch",
    "WellofEternity","Wintergrasp","World","ZULAMAN","ZulAman2","ZulFarrak",
    "ZulGurub"
  };
  -- Dialog properties
  local aHistoryData = { };
  local iBorder = 10;
  local iDivide = 8;
  local iWidth = 640;
  local iHeight = 480;
  -- Create dialog for first time (initially hidden) and only used in this
  -- scope so we can keep it local.
  local oDialog = CreateFrame("Frame", "Dialog", nil,
    BackdropTemplateMixin and "BackdropTemplate");
  oDialog:Hide();
  -- Setup local storage for sub-controls of the dialog
  local oTitleText, oSubTitleText, oEditor, oBrowser, oScrollBar, oScrollBack,
    oCloseButton, oPasteButton, oScrollFrame, oAnchor, oConfigFrame,
    oConfigEditbox, oContentBack;
  -- Other settings which some dialog functions uses
  local fEditorFunction, sEditorVariable, oMouseOver, fScrollUpdate,
    bExpandOnlyOne;
  -- Configure the dialog
  oDialog:SetFrameStrata("HIGH");
  oDialog:SetPoint("CENTER", UIParent);
  oDialog:EnableMouse(true);
  oDialog:EnableKeyboard(true);
  oDialog:SetMovable(true);
  oDialog:SetWidth(iWidth+iBorder*2+22);
  oDialog:RegisterForDrag("RightButton");
  oDialog:SetScript("OnDragStart", function()
    if GetMouseFoci()[1] == oDialog then oDialog:StartMoving() end;
  end);
  oDialog:SetScript("OnDragStop", function()
    oDialog:StopMovingOrSizing();
  end);
  oDialog:SetScript("OnShow", function()
    PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
  end);
  oDialog:SetScript("OnHide", function()
    PlaySound(SOUNDKIT.IG_ABILITY_CLOSE);
    oDialog:StopMovingOrSizing();
    oTitleText:SetText(sEmpty);
    oSubTitleText:SetText(sEmpty);
    oBrowser:SetText(sEmpty);
    if fEditorFunction then
      fEditorFunction(oEditor:GetText(), sEditorVariable);
      fEditorFunction = nil;
    end
    sEditorVariable = nil;
    oEditor:SetText(sEmpty);
    oEditor:ClearFocus();
    ToggleDropDownMenu(nil, nil, MhMod);

    -- Done if no history data
    if #aHistoryData == 0 then return end;
    -- Remove last entry
    tremove(aHistoryData, #aHistoryData);
    -- Get last (was penultimate) entry and return if not there
    local aLastDialog = aHistoryData[#aHistoryData];
    if not aLastDialog then return end;
    -- Reopen saved dialog
    ShowDialog(aLastDialog.B, aLastDialog.C, aLastDialog.T, aLastDialog.P,
      true);
  end);
  oTitleText = oDialog:CreateFontString(nil, nil, "NumberFont_Outline_Large");
  oTitleText:SetPoint("TOP", oDialog, 0, -iBorder);
  oDialog:SetHeight(iHeight+20+oTitleText:GetHeight()+iBorder*2+iDivide);
  oDialog:SetBackdropBorderColor(1, 1, 1, 1);
  oContentBack = CreateFrame("Frame", nil, oDialog,
    BackdropTemplateMixin and "BackdropTemplate");
  oContentBack:SetPoint("CENTER", oDialog, -iBorder-1, 0);
  oContentBack:SetWidth(iWidth-iBorder*2);
  oContentBack:SetHeight(iHeight-iBorder*2-iDivide-6);
  oContentBack:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    tile     = true,
    tileSize = 16,
    insets   = { left = -8, right = -31, top = -8, bottom = -8 }
  });
  oContentBack:SetBackdropColor(0, 0, 0, .75);
  oScrollBar = CreateFrame("ScrollFrame", nil, oDialog,
    "UIPanelScrollFrameTemplate");
  oScrollBar:SetPoint("CENTER", oDialog, -iBorder-1, 0);
  oScrollBar:SetWidth(iWidth-iBorder*2);
  oScrollBar:SetHeight(iHeight-iBorder*2-iDivide-6);
  oScrollBar:HookScript("OnVerticalScroll", function()
    if fScrollUpdate then fScrollUpdate() end;
  end);
  oScrollBack = CreateFrame("Frame", nil, oScrollBar,
    BackdropTemplateMixin and "BackdropTemplate");
  oScrollBack:SetBackdrop({
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    tile     = true,
    tileSize = 8,
    insets   = { left = -8, right = -9, top = -8, bottom = -8 }
  });
  oScrollBack:SetBackdropColor(0, 0, 0, .75);
  oScrollBack:SetPoint("TOPRIGHT", oScrollBar, 16, -6);
  oScrollBack:SetHeight(oScrollBar:GetHeight() - 12);
  oScrollBack:SetWidth(4);
  oCloseButton = CreateFrame("Button", nil, oDialog, "UIPanelCloseButton");
  oCloseButton:SetPoint("TOPRIGHT", oDialog, -8, -8)
  oCloseButton:SetFrameStrata("HIGH");
  oCloseButton:SetToplevel(true);
  oCloseButton:SetScript("OnClick", function()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    if IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then
      aHistoryData = { };
    end
    oDialog:Hide();
  end);
  oPasteButton = CreateFrame("Button", nil, oDialog);
  oPasteButton:SetPoint("LEFT", oCloseButton, -26, 0)
  oPasteButton:SetFrameStrata("HIGH");
  oPasteButton:SetToplevel(true);
  oPasteButton:
    SetNormalTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Up");
  oPasteButton:
    SetPushedTexture("Interface\\BUTTONS\\UI-Panel-ExpandButton-Down");
  oPasteButton:SetWidth(oCloseButton:GetWidth());
  oPasteButton:SetHeight(oCloseButton:GetHeight());
  oPasteButton:SetScript("OnClick", function(Self, Button)
    oEditor:ClearFocus();
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    if Button ~= "LeftButton" then return end;
    ShowPasteMenu(Self, function(Self, Method, Target)
      assert(Method, "No method specified");
      if oEditor and oEditor:IsVisible() then Self = oEditor end;
      if oBrowser and oBrowser:IsVisible() then Self = oBrowser end;
      for _, Line in ipairs({ strsplit("\n", Self:GetText():trim()) }) do
        SendChat(StripColour(Line), Method, Target, nil, true);
      end
    end);
  end);
  oScrollFrame = CreateFrame("Frame", nil, oScrollBar);
  oScrollFrame:SetWidth(iWidth);
  oScrollFrame:SetHeight(iHeight);
  oScrollBar:SetScrollChild(oScrollFrame);
  oAnchor = CreateFrame("frame", nil, oScrollFrame);
  oAnchor:SetPoint("TOPLEFT", oScrollFrame);
  oAnchor:SetWidth(oScrollBar:GetWidth());
  oAnchor:SetHeight(1);
  oBrowser = oScrollFrame:CreateFontString(nil, nil, "SystemFont_Shadow_Med3");
  oBrowser:SetJustifyH("LEFT");
  oBrowser:SetPoint("TOPLEFT", oScrollFrame);
  oBrowser:SetWidth(oScrollBar:GetWidth());
  -- oDialog editor
  oEditor = CreateFrame("EditBox", nil, oScrollFrame)
  oEditor:SetFont("fonts\\frizqt__.ttf", 14, sEmpty);
  oEditor:SetShadowColor(0, 0, 0);
  oEditor:SetShadowOffset(1, -1);
  oEditor:SetJustifyH("LEFT");
  oEditor:SetPoint("TOPLEFT", oScrollFrame);
  oEditor:SetWidth(oScrollBar:GetWidth());
  oEditor:SetAutoFocus(true);
  oEditor:SetMultiLine(true);
  oEditor:SetScript("OnEscapePressed", function()
    oDialog:Hide();
  end);
  local function UpdateEditorStatus()
    local _, EBLine = oEditor:GetFont();
    local LineMaximum = oEditor:GetHeight()/EBLine;
    local LineCurrent = ClampNumber(oScrollBar:GetVerticalScroll() /
      EBLine + 1, 1, LineMaximum);
    oSubTitleText:SetText(format("Viewing line %s of %s (%.2f%%)",
      BreakUpLargeNumbers(floor(LineCurrent)),
      BreakUpLargeNumbers(floor(LineMaximum)),
      ClampNumber((oScrollBar:GetVerticalScroll() /
        oEditor:GetHeight()) * 100, 0, 100)));
  end
  oEditor:SetScript("OnCursorChanged", function(_, _, EBScroll, _, EBHeight)
    local SBScroll = oScrollBar:GetVerticalScroll();
    local SBHeight = oScrollBar:GetHeight();
    if SBScroll+EBScroll>0 then
      oScrollBar:SetVerticalScroll(-EBScroll);
    elseif 0>SBScroll+EBScroll-EBHeight+SBHeight then
      oScrollBar:SetVerticalScroll(-(EBScroll-EBHeight+SBHeight));
    end
    UpdateEditorStatus();
  end);
  oSubTitleText = oDialog:CreateFontString(nil, nil, "NumberFont_Outline_Large");
  oSubTitleText:SetPoint("BOTTOM", oDialog, 0, iBorder+2);
  oConfigFrame = CreateFrame("Frame", nil, oScrollFrame);
  oConfigFrame:SetPoint("TOPLEFT", oScrollFrame);
  oConfigFrame:SetWidth(iWidth);
  oConfigFrame:SetHeight(iHeight);
  oConfigFrame.MaxCat = 0;
  oConfigFrame.MaxOpt = 0;
  oConfigEditbox = CreateFrame("EditBox");
  oConfigEditbox:SetFont("fonts\\frizqt__.ttf", 12, sEmpty);
  oConfigEditbox:SetShadowColor(0, 0, 0);
  oConfigEditbox:SetShadowOffset(1, -1);
  oConfigEditbox:SetJustifyH("RIGHT");
  oConfigEditbox:SetWidth(iWidth/4);
  oConfigEditbox:SetHeight(16);
  oConfigEditbox:SetMultiLine(false);
  oConfigEditbox:SetScript("OnEscapePressed", function(Self)
    Self:ClearFocus();
    Self:Hide();
  end);
  oConfigEditbox:SetScript("OnEnterPressed", function(Self)
    Self.Save = true;
    Self:ClearFocus();
    Self:Hide();
  end);
  local function Modify(Frame, Adjustment)
    assert(Frame, "Frame not specified");
    local R, G, B = Frame:GetBackdropColor();
    Frame:SetBackdropColor(R+Adjustment, G+Adjustment, B+Adjustment);
    R, G, B = Frame:GetBackdropBorderColor();
    Frame:SetBackdropBorderColor(R+Adjustment, G+Adjustment, B+Adjustment);
  end
  local function Lighten(Self)
    assert(Self, "Frame not specified");
    Modify(Self, .2);
    oMouseOver = Self;
  end
  local function Darken(Self)
    assert(Self, "Frame not specified");
    Modify(Self, -.2);
  end
  local function SetTooltip(Frame, HoverData)
    assert(Frame, "Frame not specified");
    Frame.HoverData = HoverData;
    if not HoverData then
      Frame:SetScript("OnEnter", Lighten);
      Frame:SetScript("OnLeave", Darken);
      return;
    end
    Frame:SetScript("OnEnter", function(Self)
      GameTooltip:SetOwner(Self, "ANCHOR_BOTTOMRIGHT", -200, 0);
      for _, Data in pairs(Self.HoverData) do
        if Data.T then
          GameTooltip:AddLine(Data.T, 1, 1, 1);
        elseif Data.L and Data.R then
          GameTooltip:AddDoubleLine(Data.L, Data.R, .5, .5, 0, .6, .6, .2);
        elseif Data.S then
          GameTooltip:AddLine(Data.S..".", 0, 1, 0, 40);
        elseif Data.I then
          GameTooltip:AddLine(format("<%s>", Data.I));
        end
      end
      GameTooltip:Show();
      Lighten(Self);
    end);
    Frame:SetScript("OnLeave", function(Self)
      GameTooltip:Hide();
      Darken(Self);
    end);
  end
  local function CollapseAll()
    local Frame = oConfigFrame;
    local Maximum = Frame.MaxCat - 1;
    for Index = 0, Maximum do
      Frame["CategoryButton"..Index].Expanded = false;
    end
  end
  local GetCategoryDefaultDialogLineData = {
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 8,
    bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
    tile     = true,
    tileSize = 8,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 }
  };
  local function GetCategory(ClickFunc, NumCat, Parent, HoverData)
    assert(ClickFunc, "Update function not specified");
    assert(NumCat, "Category option count not specified");
    assert(Parent, "Parent not specified");
    local Frame = oConfigFrame;
    local CatFrameName = "CategoryButton"..NumCat;
    local CatFrame = Frame[CatFrameName];
    if not CatFrame then
      CatFrame = CreateFrame("Frame", nil, Frame,
        BackdropTemplateMixin and "BackdropTemplate");
      Frame[CatFrameName] = CatFrame;
      CatFrame:SetWidth(Parent:GetWidth());
      CatFrame:SetHeight(21);
      CatFrame:SetID(NumCat);
      CatFrame:EnableMouse(true);
      CatFrame:SetScript("OnEnter", Lighten);
      CatFrame:SetScript("OnLeave", Darken);
      CatFrame:SetBackdrop(GetCategoryDefaultDialogLineData);
      CatFrame.Expanded = false;
      local Texture = CatFrame:CreateTexture();
      Texture:SetWidth(16);
      Texture:SetHeight(16);
      Texture:SetPoint("LEFT", CatFrame, "LEFT", 5, 0);
      CatFrame.Texture = Texture;
      local TextLeft =
        CatFrame:CreateFontString(nil, nil, "SystemFont_Shadow_Med3");
      TextLeft:SetPoint("LEFT", CatFrame, "LEFT", 22, 0);
      CatFrame.TextLeft = TextLeft
      local TextRight =
        CatFrame:CreateFontString(nil, nil, "SystemFont_Shadow_Med3");
      TextRight:SetPoint("RIGHT", CatFrame, "RIGHT", -10, 0);
      CatFrame.TextRight = TextRight;
    else
      CatFrame:ClearAllPoints();
    end
    CatFrame:SetScript("OnMouseUp", function(Self, Button)
      if GetMouseFoci()[1] ~= Self then return end;
      if Button == "LeftButton" then
        if Self.Expanded then
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
          Self.Expanded = false;
        else
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
          if bExpandOnlyOne then CollapseAll() end;
          Self.Expanded = true;
        end
      end
      ClickFunc(Self, Button);
    end);
    SetTooltip(CatFrame, HoverData);
    CatFrame:SetPoint("BOTTOMLEFT", Parent, "BOTTOMLEFT", 0, -19);
    CatFrame.TextLeft:SetTextColor(1, 1, 1);
    CatFrame.TextRight:SetTextColor(.9, .9, .9);
    CatFrame:Show();
    return CatFrame;
  end
  local function HideRest(NumOpt, NumCat)
    assert(NumOpt, "Number of options not specified");
    if oMouseOver then Lighten(oMouseOver) end;
    local Frame = oConfigFrame;
    local ChildFrame;
    if NumOpt > Frame.MaxOpt then Frame.MaxOpt = NumOpt;
    else while NumOpt < Frame.MaxOpt do
      ChildFrame = Frame["OptionCheckBox"..NumOpt];
      ChildFrame:SetScript("OnEnter", nil);
      ChildFrame:SetScript("OnLeave", nil);
      ChildFrame:SetScript("OnMouseUp", nil);
      ChildFrame:Hide();
      ChildFrame.TextLeft:SetText(sEmpty);
      ChildFrame.TextCentre:SetText(sEmpty);
      ChildFrame.TextRight:SetText(sEmpty);
      ChildFrame.Variable = nil;
      NumOpt = NumOpt + 1;
    end end
    if NumCat > Frame.MaxCat then Frame.MaxCat = NumCat;
    else while NumCat < Frame.MaxCat do
      ChildFrame = Frame["CategoryButton"..NumCat];
      ChildFrame:SetScript("OnEnter", nil);
      ChildFrame:SetScript("OnLeave", nil);
      ChildFrame:SetScript("OnMouseUp", nil);
      ChildFrame:Hide();
      ChildFrame.TextLeft:SetText(sEmpty);
      ChildFrame.TextRight:SetText(sEmpty);
      NumCat = NumCat + 1;
    end end
  end
  local function GetOption(CatFrame, ClickFunc, NumOpt, Parent, HoverData)
    assert(CatFrame, "Category frame not specified");
    assert(ClickFunc, "Click function not specified");
    assert(NumOpt, "Option count not specified");
    assert(Parent, "Parent not specified");
    local ParentFrame = oConfigFrame;
    local OptFrameName = "OptionCheckBox"..NumOpt;
    local OptFrame = ParentFrame[OptFrameName];
    if not OptFrame then
      ParentFrame.MaxOpt = ParentFrame.MaxOpt + 1;
      OptFrame = CreateFrame("Frame", nil, ParentFrame,
        BackdropTemplateMixin and "BackdropTemplate");
      ParentFrame[OptFrameName] = OptFrame;
      OptFrame:SetWidth(Parent:GetWidth());
      OptFrame:SetHeight(21);
      OptFrame:EnableMouse(true);
      OptFrame:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8,
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        tile     = true,
        tileSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
      });
      -- Left justified text (option number)
      local oFS = OptFrame:CreateFontString(nil,nil,"SystemFont_Shadow_Med1");
      oFS:SetPoint("LEFT", OptFrame, "LEFT", 10, 0);
      OptFrame.TextLeft = oFS;
      -- Left justified text (option name)
      oFS = OptFrame:CreateFontString(nil,nil,"SystemFont_Shadow_Med1");
      oFS:SetPoint("LEFT", OptFrame, "LEFT", 34, 0);
      OptFrame.TextCentre = oFS;
      -- Right justified text (option value)
      oFS = OptFrame:CreateFontString(nil,nil,"SystemFont_Shadow_Med1");
      oFS:SetPoint("RIGHT", OptFrame, "RIGHT", -10, 0);
      OptFrame.TextRight = oFS;
    else OptFrame:ClearAllPoints() end;
    OptFrame:SetPoint("BOTTOMLEFT", Parent, "BOTTOMLEFT", 0, -19);
    SetTooltip(OptFrame, HoverData);
    OptFrame:SetScript("OnMouseUp", function(Frame, Button)
      if GetMouseFoci()[1] ~= Frame then return end;
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
      ClickFunc(Frame, Button);
    end);
    OptFrame.TextLeft:SetTextColor(.8, .8, .8);
    OptFrame.TextCentre:SetTextColor(.9, .9, .9);
    OptFrame.TextRight:SetTextColor(.8, .8, .8);
    OptFrame:Show();
    return OptFrame;
  end
  local function ConfigFrameUpdate()
    local NumCat, NumOpt, TotOpt, Parent = 0, 0, 0, oAnchor;
    for Category, CatData in SortedPairs(ConfigData.Options) do
      local CatFrame = GetCategory(ConfigFrameUpdate, NumCat, Parent, {
        { T=Category.." Settings" },
        { I="Left click to access" },
      });
      CatFrame.TextLeft:SetText(Category.." Settings");
      CatFrame.TextLeft:SetTextColor(1, 1, 1);
      local OptNum = TableSize(CatData);
      CatFrame.TextRight:SetText(OptNum.." Options");
      TotOpt = TotOpt + OptNum;
      CatFrame.TextRight:SetTextColor(.75, .75, .75);
      Parent = CatFrame;
      if CatFrame.Expanded then
        CatFrame:SetBackdropColor(0, 0, .7);
        CatFrame:SetBackdropBorderColor(0, 0, .8);
        CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-MinusButton-UP");
        SortedOptions = { };
        for _, OptData in pairs(CatData) do
          tinsert(SortedOptions, OptData.SD);
        end
        sort(SortedOptions);
        OptNum = 0;
        for _, SortedOption in pairs(SortedOptions) do
          for Option, OptData in pairs(CatData) do
            if SortedOption == OptData.SD then
              local OptFrame = GetOption(CatFrame, function(Self, Button)
                if Button == "LeftButton" then SlashFunc(Self.Variable) end;
                ConfigFrameUpdate();
              end, NumOpt, Parent, {
                { T=OptData.SD },
                { S=OptData.LD },
                { I="Left click to toggle" },
              });
              OptFrame.Variable = Option;
              OptFrame.TextLeft:SetText(OptNum+1);
              OptFrame.TextCentre:SetText(OptData.SD);
              if ConfigNewData[Option] then
                OptFrame.TextCentre:SetText(OptFrame.TextCentre:GetText()..
                  " |cff0000ff<NEW!>|r");
              end
              if SettingEnabled(Option) then
                OptFrame:SetBackdropColor(0, .6, 0);
                OptFrame:SetBackdropBorderColor(0, .7, 0);
                OptFrame.TextRight:SetText("ON");
                OptFrame.TextRight:SetTextColor(1, 1, 0);
              else
                OptFrame:SetBackdropColor(.6, 0, 0);
                OptFrame:SetBackdropBorderColor(.7, 0, 0);
                OptFrame.TextRight:SetText("OFF");
                OptFrame.TextRight:SetTextColor(1, 0, 0);
              end
              Parent = OptFrame;
              NumOpt = NumOpt + 1;
              OptNum = OptNum + 1;
              break;
            end
          end
        end
      else
        CatFrame:SetBackdropColor(0, 0, .5);
        CatFrame:SetBackdropBorderColor(0, 0, .6);
        CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-PlusButton-UP");
      end
      NumCat = NumCat + 1;
    end
    CatFrame = GetCategory(ConfigFrameUpdate, NumCat, Parent, {
      { T="Advanced Settings" },
      { S="It is recommended that you fully understand what these settings "..
          "do as incorrect values can alter the performance and stability "..
          "of the addon. Click the option to modify its value, specify no "..
          "value to reset it to it's default. Green bars are variables that "..
          "are at their default values and red bars are variables that have "..
          "been modified" },
      { I="Left click for variables access" },
    });
    NumCat = NumCat + 1;
    Parent = CatFrame;
    oConfigEditbox:Hide();
    CatFrame.TextLeft:SetText("Advanced Settings");
    CatFrame.TextLeft:SetTextColor(1, 1, 1);
    OptNum = TableSize(ConfigData.Dynamic);
    CatFrame.TextRight:SetText(OptNum.." Options");
    TotOpt = TotOpt + OptNum;
    CatFrame.TextRight:SetTextColor(.75, .75, .75);
    if CatFrame.Expanded then
      SortedOptions = { };
      for _, OptData in pairs(ConfigData.Dynamic) do
        tinsert(SortedOptions, OptData.SD);
      end
      sort(SortedOptions);
      OptNum = 1;
      for _, SortedOption in pairs(SortedOptions) do
        for Option, OptData in pairs(ConfigData.Dynamic) do
          if SortedOption == OptData.SD then
            OptFrame = GetOption(CatFrame, function(Self, Button)
              if Button ~= "LeftButton" then
                local Default = ConfigData.Dynamic[Self.Variable].DF;
                if #Default > 0 then
                  SetDynSetting(Self.Variable, Default);
                  Self.TextRight:SetText(Default);
                end
                Self:SetBackdropColor(0, .7, 0);
                Self:SetBackdropBorderColor(0, .8, 0);
                Modify(Self, .2);
                return;
              end
              -- This will trigger 'OnHide' event to perform a visual reset
              oConfigEditbox:Hide();
              oConfigEditbox.Variable = Self.Variable;
              oConfigEditbox:SetParent(Self);
              oConfigEditbox:SetFocus(true);
              oConfigEditbox:ClearAllPoints();
              oConfigEditbox:SetPoint("RIGHT", Self, -iBorder, 0);
              oConfigEditbox:SetText(Self.TextRight:GetText() or sEmpty);
              Self.TextRight:Hide();
              oConfigEditbox:HighlightText();
              oConfigEditbox:Show();
              Modify(Self, 1);
            end, NumOpt, Parent, {
              { T=OptData.SD },
              { S=OptData.LD },
              { L="Default",  R=OptData.DF },
              { L="Minimum",  R=OptData.MI },
              { L="Maximum",  R=OptData.MA },
              { I="Left click to modify this variable" },
              { I="Right click to set variable default" },
            });
            if GetDynSetting(Option) == OptData.DF then
              OptFrame:SetBackdropColor(0, .7, 0);
              OptFrame:SetBackdropBorderColor(0, .8, 0);
            else
              OptFrame:SetBackdropColor(.7, 0, 0);
              OptFrame:SetBackdropBorderColor(.8, 0, 0);
            end
            OptFrame.TextLeft:SetText(OptNum);
            OptFrame.TextLeft:SetTextColor(.5, .5, .5);
            OptFrame.TextCentre:SetText(OptData.SD);
            OptFrame.TextCentre:SetTextColor(.75, .75, .75);
            OptFrame.TextRight:SetText(GetDynSetting(Option));
            OptFrame.TextRight:SetTextColor(.5, .5, .5);
            OptFrame.Variable = Option;
            OptFrame.TextRight:Show();
            Parent = OptFrame;
            NumOpt = NumOpt + 1;
            OptNum = OptNum + 1;
            break;
          end
        end
      end
      CatFrame:SetBackdropColor(0, 0, .7);
      CatFrame:SetBackdropBorderColor(0, 0, .8);
      CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-MinusButton-UP");
    else
      CatFrame:SetBackdropColor(0, 0, .5);
      CatFrame:SetBackdropBorderColor(0, 0, .6);
      CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-PlusButton-UP");
    end
    oSubTitleText:SetText("A total of "..TotOpt.." options in "..
      NumCat.." categories");
    HideRest(NumOpt, NumCat);
  end
  oConfigEditbox:SetScript("OnHide", function(Self)
    if Self.Save then
      Self.Save = nil;
      assert(Self.Variable, "No parent variable");
      local VarData = ConfigData.Dynamic[Self.Variable];
      assert(VarData, "Variable data for "..Self.Variable.." not found");
      local Value = Self:GetText():trim() or sEmpty;
      if #Value <= 0 then SetDynSetting(Self.Variable, VarData.DF);
      elseif type(VarData.DF) == "number" then
        Value = tonumber(Value);
        local iMin, iMax = VarData.MI, VarData.MA;
        if (not iMin or (iMin and Value >= iMin)) and
           (not iMax or (iMax and Value <= iMax)) then
          SetDynSetting(Self.Variable, Value);
        end
      else SetDynSetting(Self.Variable, Value) end;
    end
    ConfigFrameUpdate();
  end);
  local function LogDetailUpdate()
    local NumCat, NumOpt, Parent = 0, 0, oAnchor;
    local SortInterval = GetDynSetting("dldii");
    for CatName, CatData in SortedPairs(mhclog) do
      local CatFrame = GetCategory(LogDetailUpdate, NumCat, Parent, {
        { T=CatName },
        { I="Left click to expand" },
      });
      Parent = CatFrame;
      NumCat = NumCat + 1;
      CatFrame.TextLeft:SetText(CatName);
      CatFrame.TextRight:SetText(BreakUpLargeNumbers(TableSize(CatData))..
        " total line(s)");
      if CatFrame.Expanded then
        local Dates = { };
        for Time, Data in SortedPairs(CatData) do
          local Date = floor(Time/SortInterval)*SortInterval;
          if not Dates[Date] then
            Dates[Date] = { L=date("%A %d %B %Y %H:%M:%S", Date), C=1 };
          else
            Dates[Date].C = Dates[Date].C + 1;
          end
        end
        local OptNum = 0;
        for Date, DateData in SortedPairs(Dates) do
          local OptFrame = GetOption(oBrowser, function(Self, Button)
            SlashFunc("logdata "..Date.." "..(SortInterval-1).." "..CatName);
            LogDetailUpdate();
          end, NumOpt, Parent);
          Parent = OptFrame;
          NumOpt = NumOpt + 1;
          OptNum = OptNum + 1;
          OptFrame.TextLeft:SetText(OptNum);
          OptFrame.TextCentre:SetTextColor(1, 1, 1);
          OptFrame.TextCentre:SetText(DateData.L);
          OptFrame.TextRight:SetText(BreakUpLargeNumbers(DateData.C)..
            " line(s)");
          OptFrame:SetBackdropColor(.6, 0, .6);
          OptFrame:SetBackdropBorderColor(.8, 0, .8);
        end
        CatFrame:SetBackdropColor(.7, .7, .7);
        CatFrame:SetBackdropBorderColor(.8, .8, .8);
        CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-MinusButton-UP");
      else
        CatFrame:SetBackdropColor(.6, .6, .6);
        CatFrame:SetBackdropBorderColor(.7, .7, .7);
        CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-PlusButton-UP");
      end
    end
    if NumCat <= 0 then
      oBrowser:SetText("There are no logs to display! To create new logs, "..
        "make sure the logging option is enabled and come back to this "..
        "dialog to see some logs!");
      oBrowser:Show();
    else
      oBrowser:SetText(sEmpty);
      oBrowser:Hide();
    end
    HideRest(NumOpt, NumCat);
    oSubTitleText:SetText(sMyName.."; Level "..UnitLevel("player")..
      " "..UnitRace("player").." "..UnitClass("player").." on "..
      sMyRealm);
  end
  local function PersonalStatsUpdate(Specific)
    local NumCat, NumOpt, Parent = 0, 0, oAnchor;
    local ShowAll = SettingEnabled("sapstat");
    local CombatTime = ClampNumber(mhstats.CT, 1);
    for Who, WhoData in SortedPairs(BestStatsData) do
      local CatFrame = GetCategory(PersonalStatsUpdate, NumCat, Parent, {
        { T=Who },
        { I="Left click to view stats" },
      });
      Parent = CatFrame;
      NumCat = NumCat + 1;
      CatFrame.TextLeft:SetText(Who);
      local Data1 = (mhstats.TD[Who] or 0)/CombatTime;
      local Data2 = (mhstats.SH[Who] or 0)/CombatTime;
      local TextRight = CatFrame.TextRight;
      if Data1 == 0 and Data2 == 0 then
        TextRight:SetText("Only Best Stats Available");
        TextRight:SetTextColor(1, 0, 0);
      elseif Data2 > Data1 then
        TextRight:SetText(BreakUpLargeNumbers(Data2).."hp/sec");
        TextRight:SetTextColor(0, 1, 0);
      else
        TextRight:SetText(BreakUpLargeNumbers(Data1).."dp/sec");
        TextRight:SetTextColor(1, 1, 1);
      end
      if Specific and Specific == Who then
        CatFrame.Expanded = true;
        oScrollBar:SetVerticalScroll(oBrowser:GetTop()-CatFrame:GetTop());
        Specific = nil;
      end
      WhoData = WhoData[3];
      if WhoData and CatFrame.Expanded then
        local OptNum = 0;
        for iId, Data in pairs(WhoData) do
          iId = iId:sub(1,-2);
          local sRealName = C_Spell.GetSpellInfo(iId);
          if sRealName then sRealName = "|Hspell:"..iId.."|h"..sRealName.name.."|h";
          else sRealName = iId end;
          local sDate = date("%d/%m/%y %H:%M", Data[1]);
          local iValue = Data[2];
          if iValue >= 0 then iValue = BreakUpLargeNumbers(iValue);
          else iValue = "|cff00ff00"..BreakUpLargeNumbers(-iValue).."|r" end;
          local sWho = Data[3];
          local OptFrame = GetOption(oBrowser, function(Self, Button)
            if Button ~= "RightButton" then return end;
            ShowPasteMenu(Self, function(Self, Method, Target)
              assert(Method, "No method specified");
              SendChat(Who.."'s best "..C_Spell.GetSpellLink(iId).." of "..
                iValue.." on "..sWho.." at "..sDate, Method, Target, nil,
                true);
            end);
          end, NumOpt, Parent, {
            { T=sRealName },
            { S="for "..Who };
            { I="Right click to paste" },
          });
          Parent = OptFrame;
          NumOpt = NumOpt + 1;
          OptNum = OptNum + 1;
          OptFrame.TextLeft:SetText(OptNum);
          OptFrame.TextCentre:SetTextColor(1, 1, 1);
          OptFrame.TextCentre:SetText(sRealName);
          OptFrame.TextRight:SetText("|cffff007fon|r "..sWho..
            " |cffff007ffor|r "..iValue.." |cffff007fat|r "..sDate);
          OptFrame:SetBackdropColor(.6, 0, .6);
          OptFrame:SetBackdropBorderColor(.8, 0, .8);
        end
        OptNum = 0;
        for Variable, CatData in SortedPairs(StatsCatsData) do
          Variable = mhstats[Variable] or { };
          Variable = Variable[Who] or 0;
          if ShowAll or Variable > 0 then
            local OptFrame = GetOption(oBrowser, function(Self, Button)
              PersonalStatsUpdate();
              if Button == "RightButton" then
                ShowPasteMenu(Self, function(Self, Method, Target)
                  assert(Method, "No method specified");
                  SendChat(Who.."'s "..CatData.SD.." is "..
                    BreakUpLargeNumbers(Variable).." ("..
                    BreakUpLargeNumbers(Variable/CombatTime).."/s)",
                    Method, Target, nil, true);
                end);
              end
            end, NumOpt, Parent, {
              { T=CatData.SD },
              { S=CatData.LD },
              { I="Right click to paste" },
            });
            Parent = OptFrame;
            NumOpt = NumOpt + 1;
            OptNum = OptNum + 1;
            if Variable > 0 then
              OptFrame.TextRight:SetTextColor(1, 1, 0);
              OptFrame:SetBackdropColor(.6, .6, 0);
              OptFrame:SetBackdropBorderColor(.8, .8, 0);
            else
              OptFrame.TextRight:SetTextColor(1, 0, 0);
              OptFrame:SetBackdropColor(.4, 0, 0);
              OptFrame:SetBackdropBorderColor(.6, 0, 0);
            end
            OptFrame.TextLeft:SetText(OptNum);
            OptFrame.TextCentre:SetText(CatData.SD);
            OptFrame.TextRight:SetText(BreakUpLargeNumbers(Variable)..
              " ("..BreakUpLargeNumbers(Variable/CombatTime).."/s)");
          end
        end
        CatFrame:SetBackdropColor(.7, .7, .7);
        CatFrame:SetBackdropBorderColor(.8, .8, .8);
        CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-MinusButton-UP");
      else
        CatFrame:SetBackdropColor(.6, .6, .6);
        CatFrame:SetBackdropBorderColor(.7, .7, .7);
        CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-PlusButton-UP");
      end
    end
    if NumCat <= 0 then
      oBrowser:SetText("There are no records to display! To create new "..
        "records, make sure the 'Statistics gathering' option is enabled, "..
        "perform some battles and come back to this dialog to see some "..
        "stats!");
      oBrowser:Show();
    else
      oBrowser:SetText(sEmpty);
      oBrowser:Hide();
    end
    HideRest(NumOpt, NumCat);
    oSubTitleText:SetText("Personal stats last reset "..
      MakeTime(time()-mhstats.BST).." ago and main stats "..
      MakeTime(time()-mhstats.SB).." ago");
  end
  local function StatsUpdate()
    local function MakeTableFromStats(Type, Maximum, Ascending)
      assert(Type, "Type not specified");
      assert(mhstats, "No stats database, please restart!");
      local SourceData = mhstats[Type];
      assert(SourceData, "Stats type of '"..Type.."' are invalid");
      local Table, List, Total, Sources = { }, { }, 0, 0;
      for Id, Data in pairs(SourceData) do
        List[Id] = Data;
        Total = Total + Data;
        Sources = Sources + 1;
      end
      local CombatTime = ClampNumber(mhstats.CT, 1);
      if Sources <= 0 then
        return Table, 0, CombatTime, 0, Total/CombatTime;
      end
      if not Maximum or Maximum < 1 or Maximum > Sources then
        Maximum = Sources;
      end
      local Id = 1;
      local ThisNext, ThisNextId;
      while TableSize(List) > 0 do
        if Ascending then
          ThisNext = 0;
        else
          ThisNext = 0xFFFFFFFF;
        end
        ThisNextId = nil;
        for Name, Data in pairs(List) do
          if (Ascending and Data >= ThisNext) or
             (not Ascending and Data < ThisNext) then
            ThisNext = Data;
            ThisNextId = Name;
          end
        end
        if Id <= Maximum then
          tinsert(Table, { N=ThisNextId, T=ThisNext, D=ThisNext/CombatTime,
            P=(ThisNext/Total)*100 });
        end
        Id = Id + 1;
        List[ThisNextId] = nil;
      end
      return Table, Sources, CombatTime, Total, Total/CombatTime;
    end
    local NumCat, NumOpt, OptNum, Parent = 0, 0, 0, oAnchor;
    local ShowAll = SettingEnabled("sastats");
    for Variable, CatData in SortedPairs(StatsCatsData) do
      local Table, Sources, Elapsed, Total, PerSec =
        MakeTableFromStats(Variable, nil, true);
      if ShowAll or Sources > 0 then
        local CatFrame = GetCategory(function(Self, Button)
          if Button == "RightButton" then
            local Table, Sources, Elapsed, Total, PerSec =
              MakeTableFromStats(Variable, nil, true);
            if Sources <= 0 then return end;
            local Title = Self.TextLeft:GetText();
            local Text = "|cff00ff00Best|r |cffffffff"..Title:lower()..
              "|r |cff00ff00within |cffffffff"..MakeTime(Elapsed)..
              "|r |cff00ff00combat time...|r\n\n";
            local sMask = "|cff002f00%2u:|r |cff00ff00%10s|r @ "..
                "|cff007f00%6s/s|r (|cff009f00%5.2f%%|r) %s\n";
            for Id, Data in ipairs(Table) do
              local Name = Data.N;
              if UserIsMe(Name) then Name = "|cff7fff7f"..Name.."|r";
              elseif UnitIsFriend(Name) or UserIsInGuild(Name) then
                Name = "|cff4faf4f"..Name.."|r";
              else Name = "|cff00af00"..Name.."|r" end;
              Text = Text..format(sMask, Id, BreakUpLargeNumbers(Data.T),
                BreakUpLargeNumbers(Data.D), Data.P, Name);
            end
            ShowDialog(Text.."\n|cff00ff00Total|r |cffffffff"..
              BreakUpLargeNumbers(Total).."|r |cff00ff00@|r |cffffffff"..
              BreakUpLargeNumbers(PerSec).."/s|r |cff00ff00from|r |cffffffff"..
              Sources.."|r |cff00ff00source(s)|r\n", "Best "..Title..
              " Statistics Rankings", "EDITOR");
          end
          StatsUpdate();
        end, NumCat, Parent, {
          { T=CatData.SD },
          { S=CatData.LD },
          { I="Left click to expand/collapse" },
          { I="Right click to copy/paste stats" },
        });
        NumCat = NumCat + 1;
        CatFrame.TextLeft:SetText(CatData.SD);
        Parent = CatFrame;
        if CatFrame.Expanded then
          if Sources <= 0 then
            local OptFrame = GetOption(CatFrame, StatsUpdate, NumOpt, Parent);
            NumOpt = NumOpt + 1;
            OptFrame:SetBackdropColor(0, 0, .1);
            OptFrame:SetBackdropBorderColor(0, 0, .2);
            OptFrame.TextLeft:SetText(sEmpty);
            OptFrame.TextCentre:
              SetText("There are no records to display for this statistic");
            OptFrame.TextRight:SetText(sEmpty);
            Parent = OptFrame;
            CatFrame:SetBackdropColor(.7, 0, 0);
            CatFrame:SetBackdropBorderColor(.8, 0, 0);
          else
            OptNum = 0;
            for _, Data in ipairs(Table) do
              local OptFrame = GetOption(CatFrame, function(Self, Button)
                ShowDialog(nil, nil, "MYSTATS", Self.TextCentre:GetText());
              end, NumOpt, Parent, {
                { T=Data.N },
                { I="Left click for personal stats" },
              });
              NumOpt = NumOpt + 1;
              OptNum = OptNum + 1;
              OptFrame:SetBackdropColor(0, 0, .3);
              OptFrame:SetBackdropBorderColor(0, 0, .4);
              OptFrame.TextLeft:SetText(OptNum);
              OptFrame.TextCentre:SetText(Data.N);
              OptFrame.TextRight:SetText(BreakUpLargeNumbers(Data.T).." @ "..
                BreakUpLargeNumbers(Data.D).."/s ("..
                BreakUpLargeNumbers(Data.P).."%)");
              OptFrame.TextRight:SetTextColor(1, 1, 0);
              Parent = OptFrame;
            end
            CatFrame:SetBackdropColor(0, .7, 0);
            CatFrame:SetBackdropBorderColor(0, .8, 0);
          end
          CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-MinusButton-UP");
        else
          if Sources <= 0 then
            CatFrame:SetBackdropColor(.6, 0, 0);
            CatFrame:SetBackdropBorderColor(.7, 0, 0);
          else
            CatFrame:SetBackdropColor(0, .6, 0);
            CatFrame:SetBackdropBorderColor(0, .7, 0);
          end
          CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-PlusButton-UP");
        end
        if Sources <= 0 then
          CatFrame.TextRight:SetText("No Records");
          CatFrame.TextRight:SetTextColor(.5, .5, .5);
        else
          CatFrame.TextRight:SetText(BreakUpLargeNumbers(Total).." ("..
            BreakUpLargeNumbers(PerSec).."/s) from "..Sources);
        end
      end
    end
    if NumCat <= 0 then
      oBrowser:SetText("There are no records to display! To create new "..
        "records, make sure the 'Statistics gathering' option is enabled, "..
        "perform some battles and come back to this dialog to see some "..
        "stats!");
      oBrowser:Show();
    else
      oBrowser:SetText(sEmpty);
      oBrowser:Hide();
    end
    HideRest(NumOpt, NumCat);
    oSubTitleText:SetText("Stats last reset "..
      MakeTime(time()-mhstats.SB).." ago with "..
      MakeTime(mhstats.CT).." combat time");
  end
  local function MoneyDataUpdate(Name)
    local aIncomeData, aIncomeSessionData,
          aExpendData, aExpendSessionData = {
      { "nIncTotal", "Total income" },
      { "nIncSec",   "Average income per-second" },
      { "nIncMin",   "Average income per-minute" },
      { "nIncHr",    "Average income per-hour" },
      { "nIncDay",   "Average income per-day" },
      { "nIncWk",    "Average income per-week" },
      { "nIncMon",   "Average income per-month" },
      { "nIncYr",    "Average income per-year" },
    }, {
      { "nIncSesTotal", "Last session income total" },
      { "nIncSesSec",   "Last session average income per-second" },
      { "nIncSesMin",   "Last session average income per-minute" },
      { "nIncSesHr",    "Last session average income per-hour" },
      { "nIncSesDay",   "Last session average income per-day" },
      { "nIncSesWk",    "Last session average income per-week" },
      { "nIncSesMon",   "Last session average income per-month" },
      { "nIncSesYr",    "Last session average income per-year" },
    }, {
      { "nExpTotal", "Total expendature" },
      { "nExpSec",   "Average expendature per-second" },
      { "nExpMin",   "Average expendature per-minute" },
      { "nExpHr",    "Average expendature per-hour" },
      { "nExpDay",   "Average expendature per-day" },
      { "nExpWk",    "Average expendature per-week" },
      { "nExpMon",   "Average expendature per-month" },
      { "nExpYr",    "Average expendature per-year" },
    }, {
      { "nExpSesTotal", "Last session expendature total" },
      { "nExpSesSec",   "Last session average expendature per-second" },
      { "nExpSesMin",   "Last session average expendature per-minute" },
      { "nExpSesHr",    "Last session average expendature per-hour" },
      { "nExpSesDay",   "Last session average expendature per-day" },
      { "nExpSesWk",    "Last session average expendature per-week" },
      { "nExpSesMon",   "Last session average expendature per-month" },
      { "nExpSesYr",    "Last session average expendature per-year" },
    };
    local NumCat, NumOpt, TotOpt, TotalMoney, Parent = 0, 0, 0, 0, oAnchor;
    for Category, CatData in SortedPairs(RealmMoneyData) do
      local CatFrame = GetCategory(MoneyDataUpdate, NumCat, Parent, {
        { T=Category.."'s money data" },
        { I="Left click to access" },
      });
      CatFrame.TextLeft:SetText(Category);
      CatFrame.TextLeft:SetTextColor(1, 1, 1);
      local OptNum = TableSize(CatData);
      CatFrame.TextRight:SetText(MakeMoneyReadable(CatData.nTotal));
      TotOpt = TotOpt + OptNum;
      CatFrame.TextRight:SetTextColor(.75, .75, .75);
      Parent = CatFrame;
      if Name and Category == Name then
        CatFrame.Expanded = true;
        Name = nil;
      end
      if CatFrame.Expanded then
        CatFrame:SetBackdropColor(0, 0, .7);
        CatFrame:SetBackdropBorderColor(0, 0, .8);
        CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-MinusButton-UP");
        OptNum = 0;
        local function AddLine(Var, Name, Filter, R, G, B)
          local OptFrame = GetOption(CatFrame, function(Self, Button)
            if Button == "RightButton" then
              ShowPasteMenu(Self, function(Self, Method, Target)
                assert(Method, "No method specified");
                SendChat(Category.."'s "..Name.." is "..Filter(Var), Method,
                  Target, nil, true);
              end);
            end
            MoneyDataUpdate();
          end, NumOpt, Parent, {
            { T=Name },
            { I="Right click to paste" },
          });
          OptFrame.Variable = Option;
          OptFrame.TextLeft:SetText(Name);
          OptFrame.TextCentre:SetText(sEmpty);
          OptFrame:SetBackdropColor(.6, 0, 0);
          OptFrame:SetBackdropBorderColor(.7, 0, 0);
          OptFrame.TextRight:SetText(Filter(Var));
          OptFrame.TextRight:SetTextColor(R, G, B);
          Parent = OptFrame;
          NumOpt = NumOpt + 1;
          OptNum = OptNum + 1;
        end
        local function DoTime(Time)
          return "("..MakeTime(time()-Time).." ago) "..
            date("%d/%m/%y %H:%M:%S", Time)
        end
        AddLine(CatData.nTimeStart, "Recording began", DoTime, 1, 1, 1);
        AddLine(CatData.nTimeSes, "Last session began", DoTime, 1, 1, 1);
        if CatData.nIncTotal > 0 then
          for _, aData in ipairs(aIncomeData) do
            AddLine(CatData[aData[1]], aData[2], MakeMoneyReadable, 0, 1, 0);
          end
          if CatData.nIncSesTotal > 0 then
            for _, aData in ipairs(aIncomeSessionData) do
              AddLine(CatData[aData[1]], aData[2], MakeMoneyReadable, 0, 1, 0);
            end
          end
        end
        if CatData.nExpTotal > 0 then
          for _, aData in ipairs(aExpendData) do
            AddLine(CatData[aData[1]], aData[2], MakeMoneyReadable, 1, 0, 0);
          end
          if CatData.nExpSesTotal > 0 then
            for _, aData in ipairs(aExpendSessionData) do
              AddLine(CatData[aData[1]], aData[2], MakeMoneyReadable, 1, 0, 0);
            end
          end
        end
        local Profit, R, G = CatData.nIncTotal - CatData.nExpTotal;
        if Profit >= 0 then R,G=0,1 else R,G=1,0 end;
        AddLine(Profit, "Total Profit/Loss", MakeMoneyReadable, R, G, 0);
        local ProfSes = iMoneySession;
        if ProfSes >= 0 then R,G=0,1 else R,G=1,0 end;
        AddLine(ProfSes, "Session Profit/Loss", MakeMoneyReadable, R, G, 0);
        AddLine(CatData.nTotal, "Total money", MakeMoneyReadable, 0, 1, 0);
      else
        CatFrame:SetBackdropColor(0, 0, .5);
        CatFrame:SetBackdropBorderColor(0, 0, .6);
        CatFrame.Texture:SetTexture("Interface\\Buttons\\UI-PlusButton-UP");
      end
      TotalMoney = TotalMoney + CatData.nTotal;
      NumCat = NumCat + 1;
    end
    if NumCat <= 0 then
      oBrowser:SetText("There are no money statistics to display! "..
        "You may need to enable to option to track these details for you.");
      oBrowser:Show();
    else
      oBrowser:SetText(sEmpty);
      oBrowser:Hide();
    end
    oSubTitleText:SetText("A total of |c0000ff00"..
      MakeMoneyReadable(TotalMoney).."|r across |c0000ff00"..
      NumCat.."|r character(s) on |c0000ff00"..sMyRealm.."|r");
    HideRest(NumOpt, NumCat);
  end
  -- This dialog is a part of the UISpecialFrames club
  tinsert(UISpecialFrames, oDialog:GetName());
  -- Now overwrite the function with the actual one that will not have to go
  -- through the init process again.
  ShowDialog = function(Body, Caption, Type, TypeParam, Recall)
    -- Check parameters
    assert(Type, "Type not specified");
    -- Set a random backdrop
    oDialog:SetBackdrop({
      bgFile   = "Interface/GLUES/LoadingScreens/LoadScreen"..
        BackgroundPicturesData[random(#BackgroundPicturesData)],
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    });
    -- Set dialog opacity
    oDialog:SetAlpha(GetDynSetting("ddo")/100);
    -- Set full intensity backdrop colour
    oDialog:SetBackdropColor(1, 1, 1, 1);
    -- Hide all other dialogs
    oBrowser:Hide();
    oEditor:Hide();
    oConfigFrame:Hide();
    oPasteButton:Hide();
    oConfigEditbox:Hide();
    -- Clear settings
    fScrollUpdate, bExpandOnlyOne, oMouseOver = nil;
    -- Which dialog did the caller request?
    if Type == "CONFIG" then
      oTitleText:SetText("MhMod Configuration");
      oConfigFrame:Show();
      ConfigFrameUpdate();
    elseif Type == "EDITOR" then
      oEditor:Show();
      oEditor:SetText(Body);
      oEditor:SetFocus();
      oPasteButton:Show();
      fEditorFunction = TypeParam;
      sEditorVariable = Caption;
      oTitleText:SetText("MhMod Editor - "..Caption);
      oSubTitleText:
        SetText("Press escape or the X button to save your changes");
      fScrollUpdate = UpdateEditorStatus;
      UpdateEditorStatus();
    elseif Type == "CHATLOG" then
      oTitleText:SetText("MhMod Chat Log");
      oConfigFrame:Show();
      LogDetailUpdate();
    elseif Type == "MYSTATS" then
      oTitleText:SetText("MhMod Personal Stats");
      oConfigFrame:Show();
      bExpandOnlyOne = true;
      PersonalStatsUpdate(TypeParam);
    elseif Type == "MONEY" then
      oTitleText:SetText("MhMod Money Data");
      oConfigFrame:Show();
      bExpandOnlyOne = true;
      MoneyDataUpdate(TypeParam);
    elseif Type == "STATS" then
      oTitleText:SetText("MhMod Rankings");
      oConfigFrame:Show();
      StatsUpdate();
    end
    -- If this dialog is a new dialog and we're saving previous dialogs?
    if SettingEnabled("savehis") and not Recall then
      -- Add to history
      tinsert(aHistoryData,{ B=Body, C=Caption, T=Type, P=TypeParam });
      -- Also scroll to top
      oScrollBar:SetVerticalScroll(0);
    end
    -- Show the dialog!
    oDialog:Show();
  end
  -- Execute the function
  ShowDialog(Body, Caption, Type, TypeParam);
end
-- ===========================================================================
ClampNumber = function(nNum, nMin, nMax)
  assert(nNum, "Number not specified");
  return max(min(nNum, nMax or 0x7FFFFFFFFFFFFFFF),
                       nMin or -0x7FFFFFFFFFFFFFFF);
end
-- ===========================================================================
BlockTrades = function(bState)
  -- If we're to block trades?
  if bState then
    -- We will only block trades in dialogs if the setting is anbled and the
    -- cvar is set to disabled
    if not SettingEnabled("blocktm") and
           GetCVar("BlockTrades") ~= "1" then return end;
    -- Block trades
    SetCVar("BlockTrades", "1");
    -- This boolean says that we actually disabled trades so we can reset it.
    bTradeDisabled = true;
    -- Done
    return;
  end
  -- If our cache says trades are disabled then we don't need to set cvar
  if not bTradeDisabled or
         GetCVar("BlockTrades") ~= "0" then return end;
  -- Unblock trades
  SetCVar("BlockTrades", "0");
  bTradeDisabled = false;
end
-- ===========================================================================
PassOnLoot = function(bState)
  assert(type(bState)=="boolean", "Invalid state");
  local IsPassingOnLoot = GetOptOutOfLoot();
  if bState then
    if bPassingOnLoot and IsPassingOnLoot then
      SetOptOutOfLoot(false);
      bPassingOnLoot = false;
    end
    return;
  end
  if not IsPassingOnLoot then
    bPassingOnLoot = true;
    SetOptOutOfLoot(true);
  end
end
-- ===========================================================================
GetUnitInfo = function(Name, Battleground)
  assert(Name, "Player name not specified");
  if Battleground then return GroupBGData.D.N[Name] end;
  return GroupData.D.N[Name];
end
-- ===========================================================================
GetInstanceName = function()
  local InInst, InstType = IsInInstance();
  if not InInst or (InstType ~= "party" and InstType ~= "raid") then
    return "World_1" end;
  local Name, _, Diff = GetInstanceInfo();
  return Name.."_"..Diff;
end
-- ===========================================================================
WhisperIsDelayed = function(Msg, User, MsgId, UserId)
  -- Process whisper function
  local function ProcessWhisper(sResponse)
    -- Get prefix if battle.net whisper
    local sPrefix;
    if UserId then sPrefix = "BN" else sPrefix = sEmpty end;
    -- Get user colour
    local R, G, B = StringToColour(User);
    -- Add to delayed whisper list
    tinsert(mhwlog, { N=format("|H"..sPrefix..
        "player:%s:%u|h[|cff%02x%02x%02x%s%s|r]|h",
      User, MsgId or 0, R, G, B, MakePrettyIcon(User), User), T=time(),
      M=Msg, L=MsgId, B=UserId });
    -- Dispatch the response
    SendResponse(UserId or User, sResponse);
    -- Done
    return true;
  end
  -- If delay when delay when do-not-disturb is enabled?
  if SettingEnabled("delaydn") and nDoNotDisturb > 0 then
    return ProcessWhisper("I am busy at the moment and will read your "..
      "message later. Total time in DND is "..
      MakeTime(GetTime()-nDoNotDisturb)..".");
  end
  -- If afk when delay when afk is enabled?
  if SettingEnabled("delaywa") and nAwayFromKeyboard > 0 then
    return ProcessWhisper("I am AFK and will read your message when I "..
      "return. Total time AFK is "..
      MakeTime(GetTime()-nAwayFromKeyboard)..".");
  end
  -- If in combat when delay when in combat is enabled?
  if SettingEnabled("delaywc") and nCombatTime > 0 then
    local sMsg = "I am in combat and will read your message soon";
    if UnitExists("target") then
      local iCur, iMax = UnitHealth("target"), UnitHealthMax("target");
      sMsg = sMsg..". "..UnitName("target").." @ "..OneOrBoth(iCur, iMax)..
        " ("..ceil(iCur/iMax*100).."%) for "..MakeTime(GetTime()-nCombatTime);
    end
    return ProcessWhisper(sMsg);
  end
end
-- ===========================================================================
UpdateGroupTrackData = function(aOldData, aNewData)
  -- Veryify parameters
  assert(type(aOldData)=="table", "Invalid old group data");
  assert(type(aNewData)=="table", "Invalid new group data");
  -- Get counts and ignore if both are zero
  local iOldCount, iNewCount = aOldData.C, aNewData.C;
  if iOldCount == 0 and iNewCount == 0 then return end;
  -- Get names from old and new lists
  local aOldNames, aNewNames = aOldData.N, aNewData.N;
  -- Advanced data tracking and group tracking enabled?
  local bAdvTrack = SettingEnabled("advtrak");
  local bTrack = SettingEnabled("trackgr");
  local bRepOffline = SettingEnabled("autorof");
  -- Data we will store about the player if it exists
  local iTime = time();
  local nCombatTime = max(1, mhstats.CT or 0);
  local aDpsData = mhstats.TD;
  local aHpsData = mhstats.SH;
  local aKoData = mhstats.DT;
  local sLocation = GetRealZoneText();
  local bInstance = IsInInstance();
  local bBg = IsInBattleground();
  local bIsLeader = UnitIsGroupLeader("player");
  -- Joining party?
  local bIsJoining = iOldCount == 0 and iNewCount > 0;
  -- Iterate through each group member
  for sName, aData in pairs(aNewNames) do
    -- User isn't me?
    if not aData.S then
      -- Get old data for this user. If set then member still in group
      local aOData = aOldNames[sName];
      if aOData then
        if bRepOffline and aOData.O and not aData.O then
          -- Message to send
          local sMsg;
          -- We're in combat and in an instance but not a battleground?
          if nCombatTime > 0 and bInstance and not bBg then
            -- Message with warning and a sound affact
            sMsg = "Warning! "..MakePlayerLink(sName).." has disconnected!";
            PlaySoundFile("Sound/INTERFACE/PVPWarningHordeMono.ogg");
          -- Not in combat so set message that user went offline
          else sMsg = MakePlayerLink(sName).." has gone offline." end;
          -- Print in upper middle of screen
          HudMessage(sMsg, 1, 1, 0.5);
          -- Send in chat or echo if I am group leader
          if bIsLeader then Print("<"..sMsg..">") end;
        end
      -- No old data so member just joined the group
      elseif bAdvTrack and not bIsJoining then
        -- Set group type
        local sType;
        if IsInRaid() then sType = "raid" else sType = "party" end;
        -- Class label
        local sClass = aData.C;
        if sClass then sClass = " "..sClass end;
        -- Send in chat or echo if I am group leader
        Print(MakePlayerLink(sName).." (Lv."..aData.L..sClass..
          ") has joined the "..sType..".", ChatTypeInfo.SYSTEM);
      end
      -- Tracking enabled?
      if bTrack then
        -- Find existing tracking data and if no data then add a new entry
        local aTData = mhgtrack[sName];
        if not aTData then
          mhgtrack[sName] = { iTime, (aDpsData[sName] or 0) / nCombatTime,
            (aHpsData[sName] or 0) / nCombatTime, aKoData[sName] or 0,
            sLocation or false, false };
        else
          if aOldNames and not aOldNames[sName] and not aData.O then
            local nDuration = iTime - aTData[1];
            if nDuration >= 60 then
              local sMsg = "Seen "..MakePlayerLink(sName).." ";
              local nDamage, nHealing = aTData[2], aTData[3];
              if nDamage and nHealing then
                if nDamage >= nHealing and nDamage > 0 then
                  sMsg = sMsg.."|c00ffffff"..
                    BreakUpLargeNumbers(nDamage).."dps|r ";
                elseif nDamage < nHealing and nHealing > 0 then
                  sMsg = sMsg.."|c0000ff00"..
                    BreakUpLargeNumbers(nHealing).."hps|r ";
                end
              end
              local iDeaths = aTData[4];
              if iDeaths and iDeaths > 0 then
                sMsg = sMsg.."|c00ff0000"..
                  BreakUpLargeNumbers(iDeaths).." ko|r ";
              end
              sMsg = sMsg.."in "..aTData[5].." about "..
                MakeTime(nDuration).." ago";
              local sLastMsg = aTData[6];
              if sLasgMsg then sMsg = sMsg.."; last said "..sLastMsg end;
              Print(sMsg..".");
            end
          end
          -- Update record
          aTData[1] = iTime;
          aTData[2] = (aDpsData[sName] or 0) / nCombatTime;
          aTData[3] = (aHpsData[sName] or 0) / nCombatTime;
          aTData[4] = aKoData[sName] or 0;
          aTData[5] = sLocation or false;
        end
      end
    end
  end
  -- Done if no old names specified or tracking disabled
  if not bTrack then return end;
  -- Leaving party?
  local bIsLeaving = iOldCount > 0 and iNewCount == 0;
  -- Iterate through each OLD group member because we now need to update member
  -- data if they left as it was not done so in the above iterations.
  for sName, aData in pairs(aOldNames) do
    -- Member isn't me?
    if not aData.S then
      -- Get data for this member from new names and if we don't find it then
      -- the user left the group.
      local aNData = aNewNames[sName];
      if not aNData then
        -- Advanced tracking enabled?
        if bAdvTrack and not bIsLeaving then
          -- Set group type
          local sType;
          if IsInRaid() then sType = "raid" else sType = "party" end;
          -- Class label
          local sClass = aData.C;
          if sClass then sClass = " "..sClass end;
          -- Send in chat or echo if I am group leader
          Print(MakePlayerLink(sName).." (Lv."..aData.L.." "..
            sClass..") has left the "..sType..".", ChatTypeInfo.SYSTEM);
        end
        -- Get tracked user and add a new entry if not found
        local aTData = mhgtrack[sName];
        if not aTData then
          mhgtrack[sName] = { iTime, (aDpsData[sName] or 0) / nCombatTime,
            (aHpsData[sName] or 0) / nCombatTime, aKoData[sName] or 0,
            sLocation or false, false };
        else
          -- Update record
          aTData[1] = iTime;
          aTData[2] = (aDpsData[sName] or 0) / nCombatTime;
          aTData[3] = (aHpsData[sName] or 0) / nCombatTime;
          aTData[4] = aKoData[sName] or 0;
          aTData[5] = sLocation or false;
        end
      end
    end
  end
end
-- ===========================================================================
GetDurability = function()
  local iTotalCurrent, iTotalMaximum = 0, 0;
  for iIndex = 1, 19 do
    local iCurrent, iMaximum = GetInventoryItemDurability(iIndex);
    if iMaximum and iMaximum > 0 then
      iTotalCurrent = iTotalCurrent + iCurrent;
      iTotalMaximum = iTotalMaximum + iMaximum;
    end
  end
  if iTotalCurrent == 0 and iTotalMaximum == 0 then return false end;
  return iTotalCurrent, iTotalMaximum, iTotalCurrent/iTotalMaximum*100
end
-- ===========================================================================
FormatNumber = function(iNum)
  local sSuffix;
  if iNum > 1000000000000 then iNum, sSuffix = iNum/1000000000, " B";
  elseif iNum > 1000000000 then iNum, sSuffix = iNum/1000000, " M";
  elseif iNum > 1000000 then iNum, sSuffix = iNum/1000, " K";
  else sSuffix = sEmpty end;
  return BreakUpLargeNumbers(ceil(iNum))..sSuffix;
end
-- ===========================================================================
OneOrBoth = function(nOne, nTwo)
  if not nOne then return "<null>" end;
  local sOne = FormatNumber(nOne);
  if not nTwo or nOne == nTwo then return sOne end;
  return sOne.."/"..FormatNumber(nTwo);
end
-- ===========================================================================
HandleChatEvent = function(sMsg, sUser, sLang, sChan, sFlag, iMsgId, sPrfx,
  sType)
  -- Ignore if 'track group members' disabled
  if not SettingEnabled("trackgr") then return end;
  -- Set message to store
  local sMsgStore = sPrfx..sMsg;
  -- Get existing user and if it doesn't exist? Make new data
  local aData = mhgtrack[sUser];
  if not aData then mhgtrack[sUser] = { time(), 0, 0, 0, false, sMsgStore };
  else aData[6] = sMsgStore end;
  -- Allow message to pass through to Blizzard code and return result
  return MakePrettyName(sType, sMsg, sUser, sLang, sChan, sFlag, iMsgId);
end
-- ===========================================================================
MakeTimestamp = function()
  -- Use internal Blizzard timestamp cvar for timestamp
  local sTimestamp = GetCVar("showTimestamps");
  if not sTimestamp or sTimestamp == "none" then return sEmpty end;
  return "(|cff7f7f7f"..date(sTimestamp:trim()).."|r) ";
end
-- == Converts urls in text to clickable hyperlinks ==========================
FilterUrls = function(sMsg)
  -- Return original message if seting to format links is disabled
  if not SettingEnabled("chaturl") then return sMsg end;
  -- Now find linkable text and format using Blizzards link syntax
  return sMsg:gsub("(%w+)%:%/%/([%w%p]+)", "|cff0000ff|Hurl:%1:%2|h[%2]|h|r");
end
-- Checks if a player name is valid ignoring realm name ==================== --
IsValidPlayerName = function(sStr)
  -- Find server name delimiter if there is one and remove characters up to it
  local iDash, sName = sStr:find("-");
  if iDash then sStr = sStr:sub(1, iDash-1) end;
  -- Return if the name is valid, is between 2 and 12 characters and scanning
  -- for valid letters equals the original size of the name
  return sStr and #sStr >= 2 and #sStr <= 12;
end
-- Initialisation Routine ================================================== --
MhMod = CreateFrame("Frame", "MhMod", nil, "UIDropDownMenuTemplate");
-- Initialisation procedures =============================================== --
MhMod.InitProcedures = {               -- Defeats 60 upvalue limitation
  -- Main init ------------------------------------------------------------- --
  function()
    -- Unregister event as we don't need it anymore
    MhMod:UnregisterEvent("ADDON_LOADED");
    -- Initialise addon events system
    MhMod:SetScript("OnEvent", function(_, sEv, sUnit, ...)
      local fCb = EventsData[sEv];
      if fCb then return fCb(sUnit, ...) end;
      if not sUnit then return end;
      fCb = UnitEventsData[sUnit];
      if not fCb then return end;
      fCb = fCb[sEv];
      if fCb then return fCb(...) end;
    end);
    for sEv in pairs(EventsData) do MhMod:RegisterEvent(sEv) end;
    for sUn, aCbD in pairs(UnitEventsData) do for sEv in pairs(aCbD) do
      MhMod:RegisterUnitEvent(sEv, sUn);
    end end
  end,
  -- Database initialisation ----------------------------------------------- --
  function()
    -- Initialise and check internal and persistant databases
    -- Set basic information
    local sName = UnitName("player");
    sMyName = sName;
    local sRealm = GetRealmName();
    sMyRealm = sRealm;
    sMyNameRealm = sMyName.."-"..sMyRealm;
    -- Group member databases
    GroupData.D = CreateBlankGroupArray();
    GroupBGData.D = CreateBlankGroupArray();
    -- Make sure config database exists
    if type(mhconfig) ~= "table" then
      mhconfig = { boolean = {}, dynamic = {} };
    end
    -- Alias and check boolean settings database
    ConfigBooleanData = mhconfig.boolean;
    if type(ConfigBooleanData) ~= "table" then
      ConfigBooleanData = { };
      mhconfig.boolean = ConfigBooleanData;
    end
    -- This is a check to make sure all the variables are valid.
    for sVar, sVal in pairs(ConfigBooleanData) do
      if not VariableExists(sVar) then
        ConfigBooleanData[sVar] = nil;
      elseif type(sVal) ~= "boolean" then
        if type(sVal) == "number" then ConfigBooleanData[sVar] = sVal ~= 0;
        else ConfigBooleanData[sVar] = nil end;
      end
    end
    -- Make sure missing booleans are set
    ConfigNewData = ConfigData.New;
    for _, CategoryData in pairs(ConfigData.Options) do
      for VariableName in pairs(CategoryData) do
        if type(ConfigBooleanData[VariableName]) ~= "boolean" then
          ConfigNewData[VariableName] = true;
          ConfigBooleanData[VariableName] = false;
        end
      end
    end
    -- Alias and check dynamic settings database
    ConfigDynamicData = mhconfig.dynamic;
    if type(ConfigDynamicData) ~= "table" then
      ConfigDynamicData = { };
      mhconfig.dynamic = ConfigDynamicData;
    end
    -- Make sure dynamic config database entries are valid
    for sVar, sVal in pairs(ConfigDynamicData) do
      if type(ConfigData.Dynamic[sVar].DF) ~= type(sVal) then
        ConfigDynamicData[sVar] = ConfigData.Dynamic[sVar].DF;
      end
    end
    -- Make sure new dynamic config var defaults are valid
    for sVar, aVarData in pairs(ConfigData.Dynamic) do
      if not ConfigDynamicData[sVar] then
        ConfigDynamicData[sVar] = aVarData.DF
      end
    end
    -- Check and verify whisper log database
    if type(mhwlog) ~= "table" then mhwlog = { } end;
    for sName, aData in pairs(mhwlog) do
      if type(aData) ~= "table" or
         type(aData.N) ~= "string" or
         type(aData.T) ~= "number" or
         type(aData.M) ~= "string" then
        tremove(mhwlog, sName);
      end
    end
    -- Check and verify notes database
    if type(mhnotes) ~= "table" then mhnotes = { } end;
    for sIdentifier, sText in pairs(mhnotes) do
      if type(sIdentifier) ~= "string" or type(sText) ~= "string" then
        mhnotes[sIdentifier] = nil;
      end
    end
    -- Check and verify group tracker log database
    local nTimePrune = time() - GetDynSetting("dgtpt");
    if type(mhgtrack) ~= "table" then mhgtrack = { } end;
    for sItem, aData in pairs(mhgtrack) do
      if type(aData) ~= "table" or #aData ~= 6 then
        mhgtrack[sItem] = nil;
      else
        local nTime = aData[1];
        if type(nTime) ~= "number" or nTime < nTimePrune then
          mhgtrack[sItem] = nil;
        end
      end
    end
    -- Check and verify tracker log database
    if type(mhtrack) ~= "table" then mhtrack = { } end;
    for sLink, iAmount in pairs(mhtrack) do
      if type(sLink) ~= "string" or type(iAmount) ~= "number" then
        mhtrack[sLink] = nil;
      end
    end
    -- Check and verify money database
    if type(mhmoney) ~= "table" then mhmoney = { } end;
    RealmMoneyData = mhmoney[sRealm];
    if type(RealmMoneyData) ~= "table" then
      MoneyData = { };
      for sKey, vDef in pairs(ValidMoneyValues) do
        MoneyData[sKey] = vDef end;
      MoneyData.nTimeSes = time();
      MoneyData.nTimeStart = time();
      RealmMoneyData = { [sName] = MoneyData };
      mhmoney[sRealm] = RealmMoneyData;
    end
    MoneyData = RealmMoneyData[sName];
    if type(MoneyData) ~= "table" then
      MoneyData = { };
      for sKey, vDef in pairs(ValidMoneyValues) do
        MoneyData[sKey] = vDef end;
      MoneyData.nTimeSes = time();
      MoneyData.nTimeStart = time();
      RealmMoneyData[sName] = MoneyData;
    end
    for sRealm, aRealmData in pairs(mhmoney) do
      if #sRealm <= 0 or type(aRealmData) ~= "table" then
        mhmoney[sRealm] = nil
      else
        for sPlayer, aMoneyData in pairs(aRealmData) do
          if #sPlayer <= 0 or type(aMoneyData) ~= "table" then
            aMoneyData[sPlayer] = nil
          else
            for sKey, vValue in pairs(aMoneyData) do
              local vDefault = ValidMoneyValues[sKey];
              if not vDefault then
                aMoneyData[sKey] = nil;
              elseif type(vValue) ~= type(vDefault) then
                aMoneyData[sKey] = vDefault;
              end
            end
            for sKey, vDefault in pairs(ValidMoneyValues) do
              if not aMoneyData[sKey] then aMoneyData[sKey] = vDefault end;
            end
          end
        end
      end
    end
    -- Check and verify chat log database
    if type(mhclog) ~= "table" then mhclog = { } end;
    for CId, CData in pairs(mhclog) do
      if type(CId) == "string" and type(CData) == "table" then
        for Time, Line in pairs(CData) do
          if type(Time) ~= "number" or
             type(Line) ~= "string" then CData[Time] = nil end;
        end
        if not next(CData) then mhclog[CId] = nil end;
      end
    end
    -- Check and verify stats database
    if type(mhstats) ~= "table" then mhstats = { } end;
    local aOtherValidStats = {
      BS = { "table",  { }    }, BST = { "number", time() },
      SB = { "number", time() }, CT  = { "number", 0 },
    }
    for sKey, aData in pairs(mhstats) do
      if StatsCatsData[sKey] then
        if type(aData) ~= "table" then mhstats[sKey] = nil;
        else for sName, iCounter in pairs(aData) do
          if type(iCounter) ~= "number" then aData[sName] = nil end;
        end end
      else
        local aType = aOtherValidStats[sKey];
        if not aType or type(aData) ~= aType[1] then mhstats[sKey] = nil end;
      end
    end
    for sKey in pairs(StatsCatsData) do
      if not mhstats[sKey] then mhstats[sKey] = { } end;
    end
    for sKey, aData in pairs(aOtherValidStats) do
      if not mhstats[sKey] then mhstats[sKey] = aData[2] end;
    end
    -- Alias and check best stats databases
    BestStatsData = mhstats.BS;
    if type(BestStatsData) ~= "table" then
      BestStatsData = { };
      mhstats.BS = BestStatsData;
    end
    local nTimePrune = time() - GetDynSetting("dspt");
    for sName, aSkillData in pairs(BestStatsData) do
      if type(aSkillData) ~= "table" or #aSkillData ~= 3 then
        BestStatsData[sName] = nil;
      else
        local nUpdateTime, iCount, aEntries =
          aSkillData[1], aSkillData[2], aSkillData[3];
        if type(nUpdateTime) ~= "number" or nUpdateTime < nTimePrune or
           type(iCount) ~= "number" or iCount <= 0 or
           type(aEntries) ~= "table" then
          BestStatsData[sName] = nil;
        else for sSkill, aBestData in pairs(aEntries) do
          if type(aBestData) ~= "table" or #aBestData ~= 3 or
             type(aBestData[1]) ~= "number" or
             type(aBestData[2]) ~= "number" or
             type(aBestData[3]) ~= "string" then
            aEntries[sSkill] = nil
            local iNewCount = iCount - 1;
            if iNewCount <= 0 then
              BestStatsData[sName] = nil;
            else
              aSkillData[2] = iCount - 1;
            end
          end
        end end
      end
    end
  end,
  -- Initialise chat hacks ------------------------------------------------- --
  function()
    -- Get maximum chat history setting
    local iMaxChatHistory = GetDynSetting("dmch")
    -- For each chat window
    for Index = 1, NUM_CHAT_WINDOWS do
      local Frame = _G["ChatFrame"..Index];
      Frame:SetMaxLines(iMaxChatHistory);
    end
    -- Init message event filed
    local OldSetItemRef = SetItemRef; -- Meh! :(
    SetItemRef = function(Link, Text, Button)
      if Link:find("^url%:%w+%:[%w%p]+$") then return end;
      OldSetItemRef(Link, Text, Button);
    end
  end,
  -- Blizzard UI hooks ----------------------------------------------------- --
  function()
    -- Hook chat events
    foreach(ChatEventsData, ChatFrame_AddMessageEventFilter);
    -- Hook Blizzard secure functions
    foreach(FunctionHookData, hooksecurefunc);
    -- Hook Blizzard secure script events
    for Type, TypeData in pairs(FrameEventHookData) do
      for Name, Function in pairs(TypeData) do
        local Frame = _G[Name];
        if Frame and Frame:HasScript(Type) then
          if Frame:GetScript(Type) then Frame:HookScript(Type, Function);
          else Frame:SetScript(Type, Function) end;
        end
      end
    end
    -- Status bar updater function
    local function StatusBarUpdate(oFrame)
      -- Return if frame is invalid
      if not oFrame then return end;
      -- If frame has a text string
      local oSubFrame = oFrame.TextString;
      if oSubFrame then
        local _, nMax = oFrame:GetMinMaxValues();
        if nMax <= 0 then
          if oSubFrame:IsShown() then oSubFrame:Hide() end
          return;
        end
        local nCur = oFrame:GetValue();
        ProcessTextString(oSubFrame, nCur/nMax*100, OneOrBoth(nCur,nMax));
      end
      -- Return if the unit isn't specified or doesn't exist
      local sUnit = oFrame.unit;
      if not sUnit or not UnitExists(sUnit) then return end;
      -- Get frame health bar and return if invalid or a power bar
      oSubFrame = oFrame.healthbar or oFrame;
      if not oSubFrame or oSubFrame.powerType or
        not oSubFrame.SetStatusBarColor then return end;
      -- Use the default green colour if the unit frame enhancements setting is
      -- disabled.
      if not SettingEnabled("unitnpe") then
        return oSubFrame:SetStatusBarColor(0, 1, 0) end;
      -- Get the class of the unit and return if there is no class
      local _, sClass = UnitClass(sUnit);
      if not sClass then return end;
      -- Set the health bar to the colour of the class. For some reason, instead
      -- of Blizzard using gray textures so devs can set any colour the want,
      -- they decided to use a yellow texture so that limits the colours, so
      -- we'll have to try and offset that.
      local aCol = RAID_CLASS_COLORS[sClass];
      oSubFrame:SetStatusBarColor(aCol.r-0.37, aCol.g-0.75, aCol.b-0.10);
    end
    for iIndex, aSBFrame in ipairs({
      PlayerFrame_GetHealthBar(), PlayerFrame_GetManaBar(),
      TargetFrame.healthbar,      TargetFrame.manabar,
      TargetFrameToT.healthbar,   TargetFrameToT.manabar,
      FocusFrame.healthbar,       FocusFrame.manabar,
      PetFrame.healthbar,         PetFrame.manabar
    }) do
      hooksecurefunc(aSBFrame, "UpdateTextString", StatusBarUpdate);
    end
  end,
  -- Other hacks ----------------------------------------------------------- --
  function()
    RaidWarningFrame:UnregisterEvent("CHAT_MSG_RAID_WARNING");
    RuneFrame:SetParent(PlayerFrame);
  end,
  -- Bag button enhancements ----------------------------------------------- --
  function()
    -- Iterate through Blizzards bag slot frames
    for iId, oBag in pairs({
      [0] = MainMenuBarBackpackButton, [1] = CharacterBag0Slot,
      [2] = CharacterBag1Slot,         [3] = CharacterBag2Slot,
      [4] = CharacterBag3Slot,         [5] = CharacterReagentBag0Slot
    }) do
      -- Create a font string inherited by Blizzard bag slot frame
      local oText = oBag:CreateFontString(nil, nil, "NumberFontNormal");
      -- Text appears in the bottom right of the button
      oText:SetPoint("BOTTOMRIGHT", oBag);
      -- Right align the text
      oText:SetJustifyH("RIGHT");
      -- Hook onto Blizzard's bag event which already has BAG_UPDATE reg'd
      oBag:HookScript("OnEvent", function()
        -- Setting is enabled?
        if SettingEnabled("showbag") then
          -- Get number of total slots in bag and if bag is available?
          local iTotal = C_Container.GetContainerNumSlots(iId);
          if iTotal and iTotal > 0 then
            -- Get bag free slots
            local iCount = C_Container.GetContainerNumFreeSlots(iId);
            -- Set the text
            ProcessTextString(oText, iCount/iTotal*100, iCount);
          -- No bag so hide the bag count
          else oText:Hide() end;
        -- Setting disabled so hide our bag counts
        else oText:Hide() end;
      end);
    end
  end,
  -- Dps frame enhancements ------------------------------------------------ --
  function()
    -- Prepare dps value frame
    local oFrame = CreateFrame("FRAME", nil, PlayerFrame);
    MhMod.DpsDataFrame = oFrame;
    oFrame:EnableMouse(true);
    oFrame:SetWidth(64);
    oFrame:SetHeight(16);
    local Text = oFrame:CreateFontString("Text", nil, "NumberFontNormal");
    Text:SetShadowColor(0, 0, 0);
    Text:SetShadowOffset(1, -1);
    Text:SetPoint("RIGHT", oFrame, "RIGHT", 0, 0);
    Text:SetFont("fonts\\frizqt__.ttf", 10, sEmpty);
    Text:SetJustifyH("RIGHT");
    local Dps = true;
    -- Update position function
    local function UpdatePosition()
      local nX;
      if UnitHasVehicleUI("player") then nX = -26 else nX = -40 end;
      oFrame:ClearAllPoints();
      oFrame:SetPoint("BOTTOMRIGHT", PlayerFrame, "TOPRIGHT", nX, -41);
    end
    -- Update value function
    local function Update()
      local Time, Source = max(1, mhstats.CT);
      if Dps then
        Source = mhstats.TD[sMyName] or 0;
        Text:SetTextColor(1, 1, 1);
      else
        Source = mhstats.SH[sMyName] or 0;
        Text:SetTextColor(0, 1, 0);
      end
      Text:SetAlpha(0.75);
      local nValue;
      if nCombatTime > 0 then nValue = Source/(Time+(GetTime()-nCombatTime));
      else nValue = Source/Time end;
      if not oFrame:IsShown() then oFrame:Show() end;
      Text:SetText(FormatNumber(nValue));
    end
    -- Mouse entered dps value?
    oFrame:SetScript("OnEnter", function()
      GameTooltip:SetOwner(oFrame, "ANCHOR_LEFT");
      GameTooltip:AddLine("Last fight", 1, 1, 1);
      GameTooltip:AddDoubleLine("Damage",
        FormatNumber(mhstats.TD[sMyName] or 0), 0,1,0, 0,0.5,0);
      GameTooltip:AddDoubleLine("Healing",
        FormatNumber(mhstats.SH[sMyName] or 0), 0,1,0, 0,0.5,0);
      GameTooltip:AddDoubleLine("Taken",
        FormatNumber(mhstats.TDT[sMyName] or 0), 0,1,0, 0,0.5,0);
      GameTooltip:AddDoubleLine("Duration",
        MakeTime(mhstats.CT), 0,1,0, 0,0.5,0);
      GameTooltip:Show();
    end);
    -- Mouse left dps value?
    oFrame:SetScript("OnLeave", function() GameTooltip:Hide() end);
    -- Mouse clicked on dps value?
    oFrame:SetScript("OnMouseUp", function(_, Button)
      if Button ~= "LeftButton" then return LocalCommandsData.stats() end;
      if not IsShiftKeyDown() then
        Dps = not Dps;
        oFrame:GetScript("OnEnter")();
        PlaySound(SOUNDKIT.IG_MINIMAP_CLOSE);
        return Update();
      end
      local Type;
      if Dps then Type = "damage" else Type = "healing" end;
      return SendChat("<Currently doing "..Text:GetText().." "..Type..
        " per second>");
    end);
    -- Event received
    oFrame:SetScript("OnEvent", function(_, sEvent)
      -- Hide and return if not needed
      if not bShowDps then
        if oFrame:IsShown() then Text:SetText(sEmpty) oFrame:Hide() end;
        return;
      end
      -- Out of combat?
      if sEvent == "PLAYER_REGEN_ENABLED" then
        -- Reset events
        oFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        oFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
        oFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
      -- Entering combat?
      elseif sEvent == "PLAYER_REGEN_DISABLED" then
        -- If we're resetting stats before each fight? Clear them
        if bStatsReset then StatsClear(true, false) end;
        -- Prepare events
        oFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        oFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
        oFrame:UnregisterEvent("PLAYER_REGEN_DISABLED");
      -- In vehicle?
      elseif sEvent == "UNIT_ENTERED_VEHICLE"
          or sEvent == "UNIT_EXITED_VEHICLE" then UpdatePosition() end;
      -- Update dps value
      Update();
    end);
    -- Update value and position
    UpdatePosition();
    -- Wait for events
    oFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    oFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
    oFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
    oFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player");
    oFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player");
  end,
  -- Tooltip frame enhancements -------------------------------------------- --
  function()
    -- Add power bar to complement the health bar
    local TooltipManaBar =
      CreateFrame("StatusBar", nil, GameTooltipStatusBar, "TextStatusBar");
    TooltipManaBar:SetPoint("TOPLEFT", GameTooltipStatusBar,
      "BOTTOMLEFT", 0, 0);
    TooltipManaBar:SetPoint("BOTTOMRIGHT", GameTooltipStatusBar,
      "BOTTOMRIGHT", 0, -8);
    TooltipManaBar:SetStatusBarTexture(
      "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill");
    TooltipManaBar:SetFrameLevel(0);
    -- Add power bar text for the power bar
    local TooltipManaBarText =
      TooltipManaBar:CreateFontString(nil, nil, "NumberFontNormal");
    TooltipManaBarText:SetFont("fonts\\frizqt__.ttf", 10, sEmpty);
    TooltipManaBarText:SetShadowColor(0, 0, 0);
    TooltipManaBarText:SetShadowOffset(1, -1);
    TooltipManaBarText:SetPoint("CENTER", TooltipManaBar, "CENTER", 0, 0);
    TooltipManaBarText:SetTextHeight(10);
    -- Add text to the default gametooltip  health bar
    local TooltipHealthBarText =
      GameTooltipStatusBar:CreateFontString(nil, nil, "NumberFontNormal")
    TooltipHealthBarText:SetFont("fonts\\frizqt__.ttf", 10, sEmpty);
    TooltipHealthBarText:SetShadowColor(0, 0, 0);
    TooltipHealthBarText:SetShadowOffset(1, -1);
    TooltipHealthBarText:SetPoint("CENTER", GameTooltipStatusBar,
      "CENTER", 0, 0);
    TooltipHealthBarText:SetTextHeight(10);
    local sUnit, oTargetLine;
    -- Refresh tooltip data
    local function RefreshTooltip()
      if not UnitExists(sUnit) then return end;
      local TooltipName = GameTooltip:GetName();
      local UR, RC = UnitRace(sUnit) or UnitCreatureFamily(sUnit) or
        UnitCreatureType(sUnit) or UnitFactionGroup(sUnit) or "Unknown",
        0xFFFFFF;
      if UR == "Not specified" then UR = "Extraterrestrial" end;
      if UnitIsPlayer(sUnit) and UnitSex(sUnit) == 3 then RC = 0xffc0cb end;
      UR = UR.." ";
      local UC, UCF, CC = UnitClass(sUnit);
      if UC then
        CC = BAnd(tonumber("0x"..RAID_CLASS_COLORS[UCF].colorStr), 0xFFFFFF);
        if not UnitIsPlayer(sUnit) then UC, RC = sEmpty, CC;
        elseif UC == "Demon Hunter" then UC = "D.Hunter ";
        elseif UC == "Death Knight" then UC = "D.Knight ";
        else UC = UC.." " end;
      else UC, CC = sEmpty, 0xFFFFFF end;
      local UL, LC = UnitLevel(sUnit), 0xFFFFFF;
      if UnitFactionGroup(sUnit) ~= UnitFactionGroup("player") then
        local LD = UL - UnitLevel("player");
        if UnitIsTrivial(sUnit) then LC = 0x888888;
        elseif LD >= 5 or UL == -1 then LC = 0xFF0000;
        elseif LD >= 3 then LC = 0xFF6600;
        elseif LD >= -2 then LC = 0xFFFF00;
        else LC = 0x00FF00 end;
      else LC = 0xFFCC00 end;

      local UD = UnitIsDead(sUnit);
      local TypeData = UnitClassificationTypesData
        [UnitClassification(sUnit) or "normal"] or
          UnitClassificationTypesData.normal;
      local EC = TypeData.C;
      local FlagsModded = TypeData.F;
      if UL > 0 then UL = UL.." " else UL = "?? " end;
      local UCC;
      if FlagsModded > 0 then
        UCC = {};
        if BAnd(FlagsModded, 0x01) ~= 0 then
          UL = "+"..UL; tinsert(UCC, "Elite") end;
        if BAnd(FlagsModded, 0x02) ~= 0 then
          tinsert(UCC, "Rare") end;
        if BAnd(FlagsModded, 0x04) ~= 0 then
          UL = "-"..UL tinsert(UCC, "Trivial") end;
        if BAnd(FlagsModded, 0x08) ~= 0 then
          tinsert(UCC, "Minion") end;
        if BAnd(FlagsModded, 0x10) ~= 0 then
          tinsert(UCC, "Boss") end;
        UCC = "("..strjoin(" ", unpack(UCC))..")";
      else UCC = sEmpty end;
      local UN, US = UnitName(sUnit);
      local BDC    = { R=0, G=0, B=0 };
      local NC     = 0xFFFFFF;
      local DC     = 0xFFFFFF;
      if GetCVar("UnitNamePlayerPVPTitle") == "1" then
        UN = UnitPVPName(sUnit) or UN;
      end
      local UIG = UnitIsDeadOrGhost(sUnit);
      local UIA = UnitIsAFK(sUnit);
      local UID = UnitIsDND(sUnit);
      if UnitPlayerControlled(sUnit) then
        if UnitCanAttack(sUnit, "player") then
          if UnitCanAttack("player", sUnit) then
            BDC, NC, DC = { R=.5, G=0, B=0 }, 0xFF0000, 0xDD0000;
          else
            BDC, NC, DC = { R=.5, G=0, B=.5 }, 0xFF66FF, 0xBB55BB;
          end
        else
          if UnitCanAttack("player", sUnit) then
            BDC, NC, DC = { R=.5, G=.5, B=0 }, 0xFFFF00, 0xCCCC00;
          else
            BDC = { R=0, G=0, B=.5 };
            if UnitIsPVP(sUnit) then NC, DC = 0x00FF00, 0x00AA00;
                               else NC, DC = 0x00AAFF, 0x0088FF end;
            if UnitIsPlayer(sUnit) then
              if UnitIsFriend(UN) then
                BDC = { R=0, G=0, B=.75 };
                if UnitIsPVP(sUnit) then NC, DC = 0x00FF4F, 0x00AA4F;
                                   else NC, DC = 0xFFFFFF, 0xFFFFFF end;
              elseif UnitIsInMyGuild(sUnit) then
                BDC = { R=0, G=0, B=.75 };
                if UnitIsPVP(sUnit) then NC, DC = 0x00FF2F, 0x00AA2F;
                                   else NC, DC = 0xFFFFFF, 0xFFFFFF end;
              end
              local TooltipRight1 = _G[TooltipName.."TextRight1"];
              if UIA or UID or UIG or not UIC then
                TooltipRight1:Show();
                if UIA then TooltipRight1:SetText("|c0000ff00AFK|r");
                elseif UID then TooltipRight1:SetText("|c0000ff00DND|r");
                elseif UIG then TooltipRight1:SetText("|c00ff0000DEAD|r") end;
              end
              if not TooltipRight1:GetText() then TooltipRight1:Hide() end;
            end
          end
        end
      else
        local Reaction = UnitReaction(sUnit, "player");
        if Reaction then
          if     Reaction <= 3 then NC, DC = 0xFF0000, 0xDD0000;
          elseif Reaction == 4 then NC, DC = 0xFFFF00, 0xCCCC00 end;
        elseif UnitIsPVP(sUnit) then NC, DC = 0x00FF00, 0x00AA00;
                               else NC, DC = 0x00AAFF, 0x0088FF end;
      end
      if UnitIsFeignDeath(sUnit) then
        UCC = "Feigned";
      elseif UD then
        CC, RC, EC = 0x888888, 0x888888, 0x888888;
        NC, DC, LC = 0x888888, 0x888888, 0x888888;
        UCC = "Corpse";
        BDC = { R=.25, G=.25, B=.25 };
      end
      GameTooltip:SetBackdropColor(BDC.R, BDC.G, BDC.B, 0.5);
      if US and US ~= sEmpty then
        _G[TooltipName.."TextRight1"]:SetText(format("|cff7f7f7f%s|r", US));
        US = UN:match("^(.+)-");
      end
      _G[TooltipName.."TextLeft1"]:SetText(format("|c%08x%s|r", NC, UN));
      local TooltipLeft2 = _G[TooltipName.."TextLeft2"];
      if TooltipLeft2:GetText() then
        local Guild, GuildOn = TooltipLeft2:GetText():match("^(.+)-(.+)$");
        if GuildOn and #GuildOn > 0 then
          local TooltipRight2 = _G[TooltipName.."TextRight2"];
          TooltipLeft2:SetText(Guild);
          TooltipRight2:SetText(format("|cff7f7f7f%s|r", GuildOn));
          TooltipRight2:Show();
        end
        local _, LL = TooltipLeft2:GetText():gsub("Level.*", sEmpty);
        if LL == 1 then LL = 2;
        else
          LL = _G[TooltipName.."TextLeft3"];
          if LL and LL:GetText() then
            _, LL = LL:GetText():gsub("Level.*", sEmpty);
            if LL == 1 then LL = 3 else LL = nil end;
          else LL = nil end;
        end
        if LL and UCC then
          _G[TooltipName.."TextLeft"..LL]:
            SetText(format("|c%08x%s|r|c%08x%s|r|c%08x%s|r|c%08x%s|r",
              LC, UL, RC, UR, CC, UC, EC, UCC));
          if LL == 3 then
            TooltipLeft2:SetText(format("|c%08x%s|r", DC,
              TooltipLeft2:GetText()));
          end
        end
      end

      if UnitIsDeadOrGhost(sUnit) or not SettingEnabled("enhtool") then
        TooltipHealthBarText:Hide();
        TooltipManaBar:Hide();
      else
        if SettingEnabled("tooltpt") then
          local Target = sUnit.."-target";
          if UnitExists(Target) then
            local sLine;
            if UnitIsDeadOrGhost(Target) then
              sLine = "@ |cffff0000"..UnitName(Target).."|r";
            else
              local _, sClass = UnitClass(Target);
              if sClass then
                local aCData = RAID_CLASS_COLORS[sClass].colorStr;
                sLine = "@ |c"..aCData..UnitName(Target).."|r";
                local nPercent = UnitHealth(Target)/UnitHealthMax(Target)*100;
                if nPercent < 100 then
                  local nGreen, nBlue;
                  if nPercent >= 50 then nGreen, nBlue = 255, nPercent*2.55;
                  elseif nPercent >= 0 then
                     nGreen, nBlue = nPercent*2.55, 0 end;
                  sLine = sLine.." |cffff"..format("%02x%02x", nGreen, nBlue)..
                    RoundNumber(nPercent, 2).."%";
                end
              end
            end
            if not oTargetLine then
              GameTooltip:AddLine(sLine, 1, 1, 1);
              oTargetLine =
                _G[TooltipName.."TextLeft"..GameTooltip:NumLines()];
            else oTargetLine:SetText(sLine) end;
            oTargetLine:Show();
          elseif oTargetLine then oTargetLine:Hide() end;
        end
        local HealthMax = UnitHealthMax(sUnit);
        if HealthMax > 0 then
          local Health = UnitHealth(sUnit);
          local HealthPerc = Health/HealthMax*100;
          local Extra;
          if HealthPerc == 100 then Extra = sEmpty else
            Extra = " ("..ceil(HealthPerc).."%)" end;
          if Health > 1 then
            ProcessTextString(TooltipHealthBarText, HealthPerc,
              OneOrBoth(Health,HealthMax)..Extra);
          else TooltipHealthBarText:Hide() end;
          local _, Class = UnitClass(sUnit);
          local ClassColour = RAID_CLASS_COLORS[Class];
          if not ClassColour then ClassColour = { r=0,g=0,b=0 } end;
          GameTooltipStatusBar:SetStatusBarColor(ClassColour.r+.15,
            ClassColour.g+.15, ClassColour.b+.15);
          local ManaMax = UnitPowerMax(sUnit);
          if ManaMax <= 1 then
            TooltipManaBar:Hide();
          else
            local Mana = UnitPower(sUnit);
            local ManaPerc = (Mana/ManaMax)*100;
            TooltipManaBar:SetMinMaxValues(1, ManaMax);
            TooltipManaBar:SetValue(Mana);
            local ManaColour = PowerBarColor[UnitPowerType(sUnit)];
            TooltipManaBar:SetStatusBarColor(ManaColour.r, ManaColour.g, ManaColour.b);
            local Extra;
            if ManaPerc == 100 then Extra = sEmpty;
            else Extra = " ("..ceil(ManaPerc).."%)" end;
            ProcessTextString(TooltipManaBarText, ManaPerc,
              OneOrBoth(Mana,ManaMax)..Extra);
            TooltipManaBar:Show();
          end
        else
          TooltipHealthBarText:Hide();
          TooltipManaBar:Hide();
        end
      end
      GameTooltip:Show();
    end
    -- Hook onto clearstatus bars on gametooltip to kill the update timer
    GameTooltip:HookScript("OnHide", function()
      GameTooltip:SetBackdropColor(0, 0, 0, 0.5);
      GameTooltip:Hide();
      KillTimer("TUT");
      oTargetLine = nil;
      sUnit = nil;
    end);
    -- Fires when tooltip code wants to change position
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(oFrame)
      if not SettingEnabled("tooltip") then return end;
      local mX, mY = GetCursorPosition();
      local UIScale = UIParent:GetEffectiveScale();
      local TTScale = oFrame:GetScale();
      oFrame:ClearAllPoints();
      oFrame:SetOwner(UIParent, "ANCHOR_CURSOR");
      oFrame:SetPoint("BOTTOMLEFT", nil, "BOTTOMLEFT",
        (mX + 32) / UIScale / TTScale, mY / UIScale / TTScale);
    end);
    -- Override the default style when the gametooltip is shown
    hooksecurefunc("GameTooltip_UnitColor", function(Unit)
      if not UnitExists(Unit) or SettingEnabled("tooltpe") or
         (Unit ~= "mouseover" and SettingEnabled("tooltpm")) then
        KillTimer("TUT");
        GameTooltip:SetBackdropColor(0, 0, 0, 0.5);
        oTargetLine = nil;
        GameTooltip:Hide();
      end
      if not SettingEnabled("enhtool") then return end;
      sUnit = Unit;
      oTargetLine = nil;
      CreateTimer(GetDynSetting("dtri"), function()
        if GameTooltip:GetUnit() then RefreshTooltip() return end;
        sUnit = nil;
        GameTooltip:Hide();
        return true;
      end, nil, "TUT");
    end);
  end,
  -- Utility button -------------------------------------------------------- --
  function()
    -- Button is only used in this scope so this use of local is fine
    local oButton = CreateFrame("Button", nil, Minimap);
    oButton:SetWidth(32);
    oButton:SetHeight(32);
    oButton:SetFrameStrata("HIGH");
    oButton:SetToplevel(true);
    oButton:SetHighlightTexture("Interface\\Minimap\\"..
      "UI-Minimap-ZoomButton-Highlight");
    oButton:SetPoint("CENTER", GetDynSetting("dmbx"),
      GetDynSetting("dmby"));
    -- Setup button frame
    local oIcon = oButton:CreateTexture(nil, "BACKGROUND");
    oIcon:SetTexture("Interface\\ICONS\\Temp");
    oIcon:SetTexCoord(.1, .9, .1, .9);
    oIcon:SetWidth(19);
    oIcon:SetHeight(19);
    oIcon:SetPoint("CENTER", oButton, "CENTER", 1, 0);
    -- Setup button border
    local oBorder = oButton:CreateTexture(nil, "OVERLAY");
    oBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");
    oBorder:SetWidth(53);
    oBorder:SetHeight(53);
    oBorder:SetPoint("TOPLEFT", oButton, "TOPLEFT");
    -- Setup button scripts
    oButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    oButton:RegisterForDrag("LeftButton", "RightButton");
    oButton:SetScript("OnDragStart", function(Self)
      if not IsShiftKeyDown() or not IsControlKeyDown()
                              or not IsAltKeyDown() then return end;
      Self:SetScript("OnUpdate", function(Self)
        local CentreX, CentreY = Minimap:GetCenter();
        local MouseX, MouseY = GetCursorPosition();
        MouseX = MouseX/Self:GetEffectiveScale()-CentreX;
        MouseY = MouseY/Self:GetEffectiveScale()-CentreY;
        CentreX = abs(MouseX);
        CentreY = abs(MouseY);
        CentreX = (CentreX/sqrt(CentreX^2+CentreY^2))*100;
        CentreY = (CentreY/sqrt(CentreX^2+CentreY^2))*100;
        Self.XPos = MouseX < 0 and -CentreX or CentreX;
        Self.YPos = MouseY < 0 and -CentreY or CentreY;
        Self:ClearAllPoints();
        Self:SetPoint("CENTER", Self.XPos, Self.YPos);
      end);
      GameTooltip:Hide();
    end);
    oButton:SetScript("OnDragStop", function(Self)
      oIcon:SetTexCoord(.1, .9, .1, .9);
      oIcon:SetVertexColor(1.0, 1.0, 1.0);
      Self:SetScript("OnUpdate", nil);
      SetDynSetting("dmbx", Self.XPos);
      SetDynSetting("dmby", Self.YPos);
    end);
    oButton:SetScript("OnMouseDown", function(Self)
      oIcon:SetTexCoord(0, 1, 0, 1)
      oIcon:SetVertexColor(0.5, 0.5, 0.5);
    end);
    local function CreateLabel(iLevel, sName)
      CreateMenuItem({
        text = sName, isTitle = true, notCheckable = true
      }, iLevel);
    end
    local function CreateSubMenu(iLevel, sName, fcbCallback)
      CreateMenuItem({
        text = sName, func = ToggleDropDownMenuCallback,
        notCheckable = true, hasArrow     = true, value = fcbCallback
      }, iLevel);
    end
    local function SortFunc(aA, aB) return aA[2].SD < aB[2].SD end;
    local function CreateSubItem(iLevel, bNoCheck, bChecked, sText, fcbFunc)
      CreateMenuItem({
        notCheckable = bNoCheck, keepShownOnClick = not bNoCheck,
        checked = bChecked, text = sText, func = fcbFunc
      }, iLevel);
    end
    local function DropDownMenuCallback()
      local fcbCallback = UIDROPDOWNMENU_MENU_VALUE;
      if fcbCallback then return fcbCallback() end;
      CreateLabel(1, Version.Name.." v"..GetVersion());
      CreateSubMenu(1, "Commands", function()
        CreateLabel(2, "Commands...");
        for Category, Data in SortedPairs(ConfigData.Commands) do
          CreateSubMenu(2, Category.." commands", function()
            CreateLabel(3, Category.." commands...");
            local iIndex = 0;
            for sCmdName, aCmdData in SortedPairs(Data, SortFunc) do
              CreateSubItem(3, true, nil,
                "|cff00ff00("..strchar(0x41+iIndex)..")|r "..aCmdData.SD,
                function()
                  if IsShiftKeyDown() or IsControlKeyDown() then
                    SlashFunc("help "..sCmdName);
                  else
                    SlashFunc(sCmdName);
                  end
                  HideDropDownMenu(1);
                end);
              iIndex = iIndex + 1;
            end
            CreateMenuItem({
              text = "Shift+Click for help";
              notCheckable = true;
              isTitle = true;
            }, 3);
          end);
        end
      end);
      CreateSubMenu(1, "Settings", function()
        CreateLabel(2, "Settings...");
        for Category, Data in SortedPairs(ConfigData.Options) do
          CreateSubMenu(2, Category.." settings", function()
            CreateLabel(3, Category.." settings...");
            local iIndex = 0;
            for sVarName, aVarData in SortedPairs(Data, SortFunc) do
              local sText =
                "|cff00ff00("..strchar(0x41+iIndex)..")|r "..aVarData.SD
              if ConfigNewData[sVarName] then
                sText = sText.." |cff0000ff<NEW!>|r" end;
              CreateSubItem(3, false, SettingEnabled(sVarName), sText,
                function()
                  if IsShiftKeyDown() or IsControlKeyDown() then
                    SlashFunc("help "..sVarName);
                    HideDropDownMenu(1);
                  else
                    SlashFunc(sVarName);
                  end
                end);
              iIndex = iIndex + 1;
            end
            CreateMenuItem({
              text = "Shift+Click for help";
              notCheckable = true;
              isTitle = true;
            }, 3);
          end);
        end
        CreateSubMenu(2, "Advanced settings", function()
          CreateLabel(3, "Advanced settings...");
          local iIndex = 0;
          for sVarName, aVarData in SortedPairs(ConfigData.Dynamic, SortFunc) do
            CreateSubItem(3, false, GetDynSetting(sVarName) ~= aVarData.DF,
              "|cff00ff00("..strchar(0x41+iIndex)..")|r "..aVarData.SD,
              function()
                if IsShiftKeyDown() or IsControlKeyDown() then
                  SlashFunc("help "..sVarName);
                else
                  SlashFunc(sVarName);
                end
                HideDropDownMenu(1);
              end);
            iIndex = iIndex + 1;
          end
          CreateMenuItem({
            text = "Shift+Click for help";
            notCheckable = true;
            isTitle = true;
          }, 3);
        end);

      end);
      CreateSubMenu(1, "Addons", function()
        CreateLabel(2, "Addons...");
        local AddonCount = C_AddOns.GetNumAddOns();
        local AddonEnabled, MemoryUsageTotal, MemoryUsage = 0, 0;
        local Name, Title, Checked, Reason;
        UpdateAddOnMemoryUsage();
        local AddonHidden = 0;
        local Deps = { };
        for Index = 1, AddonCount do
          for _, Dep in pairs({C_AddOns.GetAddOnDependencies(Index)}) do
            Deps[C_AddOns.GetAddOnInfo(Index)] = Index;
          end
        end
        for Index = 1, AddonCount do
          Name, Title, _, Checked, _, Reason =
            C_AddOns.GetAddOnInfo(Index);
          MemoryUsage = GetAddOnMemoryUsage(Name);
          MemoryUsageTotal = MemoryUsageTotal + MemoryUsage;
          if IsShiftKeyDown() or Enabled or not Deps[Name] then
            local sText = "|cff00ff00("..strchar(0x40+Index)..")|r ";
            if Checked then
              sText = sText..StripColour(Title).." |cff0000ff["..
                BreakUpLargeNumbers(MemoryUsage).."KB]|r";
            else sText = sText.."|cff7f7f7f"..
              StripColour(Title).."|r" end;
            CreateMenuItem({
              arg1             = Name,
              text             = sText,
              notCheckable     = nil,
              checked          = Checked,
              keepShownOnClick = false,
              func             = function() SlashFunc("tgaddon "..Name) end;
            }, 2);
            AddonEnabled = AddonEnabled + 1;
          else AddonHidden = AddonHidden + 1 end;
        end
        Deps = { };
        CreateMenuItem({
          notCheckable = true;
          text = AddonEnabled.." of "..AddonCount-AddonHidden..
            " loaded ("..AddonHidden.." hidden)";
          isTitle = true;
        }, 2);
        CreateMenuItem({
          notCheckable = true;
          text = BreakUpLargeNumbers(MemoryUsageTotal)..
            "KB of memory in-use";
          isTitle = true;
        }, 2);
        return;
      end);
    end
    oButton:SetScript("OnMouseUp", function(Self, Button)
      local function ToggleDropDownCallback()
        ToggleDropDownMenu(1, nil, MhMod, oButton, -128, 128);
      end
      oIcon:SetTexCoord(.1, .9, .1, .9);
      oIcon:SetVertexColor(1.0, 1.0, 1.0);
      GameTooltip:Hide();
      if GetMouseFoci()[1] ~= Self then return end;
      if Button == "LeftButton" then
        if IsAltKeyDown() then -- Nullop
        elseif IsControlKeyDown() then LocalCommandsData.stsshowp();
        elseif IsShiftKeyDown() then LocalCommandsData.stats();
        else LocalCommandsData.config() end;
      else
        if IsAltKeyDown() then LocalCommandsData.edit(sEmpty, { }, 0);
        elseif IsControlKeyDown() then LocalCommandsData.logdata(sEmpty, { }, 0);
        elseif IsShiftKeyDown() then LocalCommandsData.money(sEmpty, { }, 0);
        else
          UIDropDownMenu_Initialize(MhMod, DropDownMenuCallback, "MENU", 1);
          ToggleDropDownCallback();
        end
      end
    end);
    oButton:SetScript("OnEnter", function(Self)
      UpdateAddOnMemoryUsage();
      GameTooltip:SetOwner(Self, "ANCHOR_LEFT");
      GameTooltip:AddDoubleLine("MhMod", "Ver. "..GetVersion(),
        1.0, 1.0, 1.0, 0.9, 0.9, 0.9);
      GameTooltip:AddDoubleLine("Memory Usage",
        BreakUpLargeNumbers(GetAddOnMemoryUsage(Version.Name)).."KB",
          0.5, 0.5, 0.5, 0.75, 0.75, 0.75);
      GameTooltip:AddLine("<Lc/Settings, Rc/Commands>");
      GameTooltip:AddLine("<S&Lc/Rankings, S&Rc/Money>");
      GameTooltip:AddLine("<C&Lc/Personals, C&Rc/Logs>");
      GameTooltip:AddLine("<A&Lc/Unused, A&Rc/Notes>");
      GameTooltip:AddLine("Hold S+C+A&Drag to move this", 0.5, 0.5, 0.5);
      GameTooltip:Show();
    end);
    oButton:SetScript("OnLeave", function() GameTooltip:Hide() end);
  end,
  -- Experience bars enhancemnts ------------------------------------------- --
  function()
    -- Reputation bar text was modified
    local function ReputationBarModified(oText)
      if not FactionData then return end;
      local aData = C_Reputation.GetWatchedFactionData();
      if not aData then return end;
      local sName = aData.name;
      aData = FactionData[sName];
      if not aData then return end;
      local sCat = aData.C;
      if sCat and sCat ~= sName then sName = sName.." of "..sCat end;
      local sText = sName..": "..OneOrBoth(aData.CV, aData.CH).." ("..
        RoundNumber(aData.CP, 2).."%)";
      local sResult = aData.R;
      if sResult then sText = sText.."; "..sResult end;
      if not aData.M and aData.TP < 100 then
        sText = sText..": "..OneOrBoth(aData.TV, aData.TH)..
          " ("..RoundNumber(aData.TP, 2).."%)";
      end
      if aData.PT then
        sText = sText.."; B="..OneOrBoth(aData.PV, Data.PH)..
          " ("..RoundNumber(aData.PP, 2).."%)";
      end
      ProcessTextString(oText, aData.CP, sText);
    end
    -- Honour bar text was modified
    local function HonourBarModified(oText)
      local Text = "Honor: "..BreakUpLargeNumbers(iHonour).."/"..
        FormatNumber(iHonourMax)..
        " ("..RoundNumber(iHonour/iHonourMax*100, 2).."%); Level "..
        iHonourLevel.."; Next: "..FormatNumber(iHonourMax-iHonour);
      if iHonourGainsLeft >= 1 and iHonourGainsLeft < 1000 then
        Text = Text.." (x"..ceil(iHonourGainsLeft)..")";
      end
      return ProcessTextString(oText, iHonour/iHonourMax*100, Text);
    end
    -- Experience bar text was modified
    local function XPBarModified(oText)
      -- Build new text string
      local sText = "XP="..BreakUpLargeNumbers(iCurrentXP).."/"..
        FormatNumber(iXPMax)..
        " ("..RoundNumber(iCurrentXP/iXPMax*100, 2).."%); Next: "..
        FormatNumber(iXPMax-iCurrentXP);
      -- Add gains remaining
      if iXPGainsLeft >= 1 and iXPGainsLeft < 1000 then
        sText = sText.." (x"..ceil(iXPGainsLeft)..")";
      end
      -- Add exhaustion
      if GetXPExhaustion() then
        sText = sText.."; RX="..BreakUpLargeNumbers(GetXPExhaustion())..
          " ("..RoundNumber(GetXPExhaustion()/iXPMax*100, 2).."%)";
      end
      -- Updte the text string
      ProcessTextString(oText, iCurrentXP/iXPMax*100, sText);
    end
    -- Artefact bar text was modified
    local function ArtefactBarModified(oText)
      -- Find an active azerite item and return if not found
      local aItemLoc = C_AzeriteItem.FindActiveAzeriteItem();
      if not aItemLoc then return end;
      -- Get equipped artefact data and return if none
      local iAXP, iAXPMax = C_AzeriteItem.GetAzeriteItemXPInfo(aItemLoc);
      if not iAXP then return end;
      -- Get name of item
      local aIData = Item:CreateFromItemLocation(aItemLoc);
      if not aIData then return end;
      -- Get level and return if none
      local iLevel = C_AzeriteItem.GetPowerLevel(aItemLoc);
      if not iLevel then return end;
      -- Calculate percent
      local nPercent = iAXP / iAXPMax * 100;
      -- Set the new text string
      ProcessTextString(oText, nPercent, aIData:GetItemName().." (Lv."..
        iLevel.."); "..FormatNumber(iAXP).."/"..FormatNumber(iAXPMax).." ("..
        RoundNumber(nPercent, 2).."%); Next: "..FormatNumber(iAXPMax - iAXP));
    end
    -- For each container (e.g. 1,4+2,1 = XP+Rep Bar)
    local aContainers = StatusTrackingBarManager.barContainers;
    for iIndex = 1, #aContainers do
      -- Get next container
      local aContainer = aContainers[iIndex];
      -- Get reputation bar and hook the event function
      local ReputationBar = aContainer.bars[1];
      local ReputationBarText = ReputationBar.OverlayFrame.Text;
      hooksecurefunc(ReputationBar, "SetBarText", function()
        if not SettingEnabled("advtrak") then return end;
        ReputationBarModified(ReputationBarText) end);
      -- Get honour bar and hook the event function
      local HonourBar = aContainer.bars[2];
      local HonourBarText = HonourBar.OverlayFrame.Text;
      hooksecurefunc(HonourBar, "SetBarText", function()
        if not SettingEnabled("advtrak") then return end;
        HonourBarModified(HonourBarText) end);
      -- Get experience bar and hook the event function
      local XPBar = aContainer.bars[4];
      local XPBarText = XPBar.OverlayFrame.Text;
      hooksecurefunc(XPBar, "SetBarText", function()
        if not SettingEnabled("advtrak") then return end;
        XPBarModified(XPBarText) end);
      -- Get artefact bar and hook the event function
      local ArtefactBar = aContainer.bars[5];
      local ArtefactBarText = ArtefactBar.OverlayFrame.Text;
      hooksecurefunc(ArtefactBar, "UpdateOverlayFrameText", function()
        if not SettingEnabled("advtrak") then return end;
        ArtefactBarModified(ArtefactBarText) end);
      hooksecurefunc(ArtefactBar, "SetBarText", function()
        if not SettingEnabled("advtrak") then return end;
        ArtefactBarModified(ArtefactBarText) end);
    end
  end,
  -- Action bars ----------------------------------------------------------- --
  function()
    -- Text count update function
    local function UpdateCount(iSpellId)
      -- Done if no spell id (i.e. no spell/macro assigned to button)
      if type(iSpellId) ~= "number" then return end;
      -- Get spell power cost data, return if no data
      local aData = C_Spell.GetSpellPowerCost(iSpellId);
      if not aData or #aData == 0 then return end;
      -- This data is formatted in an array so we need to enumerate through it
      -- to try and find a cost and not a return.
      for iI = 1, #aData do
        -- Get data for cost
        local aCData = aData[iI];
        -- Get power type id
        local iType = aCData.type;
        -- Get maximum power of this type
        local iMax = UnitPowerMax("player", iType);
        local iCost = aCData.cost or aCData.minCost;
        if iCost and iCost > 0 then
          local iCur;
          if iType == 5 then
            iCur = 0;
            for iRId = 1, iMax do
              local _, _, bReady = GetRuneCooldown(iRId);
              if bReady then iCur = iCur + 1 end;
            end
          else iCur = UnitPower("player", iType) end;
          local nPerc = iCur/iCost;
          return floor(nPerc), nPerc/(iMax/iCost)*100;
        end
      end
    end
    -- Standard action button callback
    local function StandardBar(iAction)
      -- Get info about action, spell or macro and return if invalid
      local sType, iSpellId = GetActionInfo(iAction);
      if not sType or not iSpellId or iSpellId == 0 then return end;
      if "spell" == sType then return UpdateCount(iSpellId) end;
      if "macro" == sType then return UpdateCount(GetMacroSpell(iSpellId)) end;
    end
    -- Valid action buttons data
    local aCastCountFrames = { };
    for sName, fcbCb in pairs({
      ActionButton = StandardBar,
      BonusActionButton = StandardBar,
      MultiBarLeftButton = StandardBar,
      MultiBarRightButton = StandardBar,
      MultiBarBottomLeftButton = StandardBar,
      MultiBarBottomRightButton = StandardBar,
      StanceButton = function(iIndex)
        local _, sName = GetShapeshiftFormInfo(iIndex)
        if sName then return UpdateCount(sName) end;
      end,
      PetActionButton = function(iIndex)
        local sName = C_Spell.GetSpellInfo(GetPetActionInfo(iIndex) or sEmpty);
        if sName then return UpdateCount(sName) end;
      end
    }) do for iIndex = 1, 12 do
      -- Get target frame and if we got it?
      local oButton = _G[sName..iIndex];
      if oButton then
        -- Create font string for action button
        local oTextFrame =
          oButton:CreateFontString(nil, nil, "GameFontNormalLarge");
        -- Set data
        tinsert(aCastCountFrames, { oButton, fcbCb, iIndex, oTextFrame });
        -- Align to action button
        oTextFrame:SetHeight(oButton:GetWidth());
        oTextFrame:SetWidth(oButton:GetHeight());
        oTextFrame:SetPoint("CENTER", oButton);
      end
    end end
    -- Initialise event handling for refreshing cast count
    local oFrame = CreateFrame("FRAME", nil, nil);
    oFrame:SetScript("OnEvent", function()
      -- Decide if we should show the count or not
      local bState = bActionCounts and not UnitIsDeadOrGhost("player");
      -- Walk through all the casting butotns
      for iIndex = 1, #aCastCountFrames do
        -- Get data
        local aData = aCastCountFrames[iIndex];
        -- Hide if disabled
        if not bState then return aData[4]:Hide() end;
        -- Get count and percent complete of maximum power
        local iCount, nPercent = aData[2](aData[1].action or aData[3]);
        -- If have a count, percent and is shown? Set the new text
        if iCount then
          -- Don't show if value over 99
          if iCount > 99 then
            -- Get frame as we're using it more than once
            local oFrame = aData[4];
            if not oFrame:IsVisible() then oFrame:Show() end;
            oFrame:SetText("*");
            oFrame:SetTextColor(1, 1, 1);
          else ProcessTextString(aData[4], nPercent, iCount) end;
        -- Otherwise hide it
        else aData[4]:Hide() end;
      end
    end);
    -- Register events that will update the cast counts
    oFrame:RegisterEvent("RUNE_POWER_UPDATE");
    oFrame:RegisterEvent("RUNE_TYPE_UPDATE");
    -- FIXME Frame:RegisterEvent("PLAYER_PET_CHANGED");
    oFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED");
    oFrame:RegisterEvent("ACTIONBAR_SHOWGRID");
    oFrame:RegisterEvent("ACTIONBAR_HIDEGRID");
    oFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
    oFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
    oFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player");
  end,
  -- Action button fades --------------------------------------------------- --
  function()
    -- When button is updated
    local function OnUpdate(oButton)
      -- Return if no button here
      if not oButton then return end;
      -- Ignore if not enabled
      if not bActionFades then return oButton.icon:SetVertexColor(1, 1, 1) end;
      -- Set red/greyish colour of action button if out of range
      local iAction = oButton.action;
      if false == IsActionInRange(iAction) then
        return oButton.icon:SetVertexColor(1, .5, .5) end;
      -- Get usable action information
      local bUsable, bNoMana = IsUsableAction(iAction);
      if bNoMana then return oButton.icon:SetVertexColor(.5, .5, 1) end;
      if bUsable then return oButton.icon:SetVertexColor(1, 1, 1) end;
      -- Not usable so set a red/green'ish colour
      oButton.icon:SetVertexColor(1, .75, .5);
    end
    -- Hook scripts onto buttons
    for _, sType in ipairs({ "ActionButton",
                             "MultiBarBottomLeftButton",
                             "MultiBarBottomRightButton" }) do
      for iIndex = 1, 12 do
        _G[sType..iIndex]:HookScript("OnUpdate", OnUpdate);
      end
    end
  end,
  -- Chat slash command ---------------------------------------------------- --
  function()
    -- Command callback function
    local function OnCommand(sCmdLine)
      -- Check parameter
      assert(type(sCmdLine)=="string", "Invalid or no string specified");
      -- Get function name and arguments and return if no function
      local sFunc, sArgs = sCmdLine:trim():match("^(%w+)%s*(.-)$");
      if not sFunc then return end;
      -- Lower case the function as all the functions are in lowercase
      sFunc = sFunc:lower();
      -- Have arguments?
      if sArgs then
        -- Strip extra and double spaces
        sArgs = sArgs:trim();
        while sArgs:find("  ") do sArgs = sArgs:gsub("  ", " ") end;
        -- Nullify if nothing there now
        if #sArgs == 0 then sArgs = nil end;
      end
      -- Get function for command and if function is found
      local fCb = LocalCommandsData[sFunc];
      if fCb then
        -- Split string into individually accessable arguments
        local aArgV;
        if sArgs and #sArgs > 0 then aArgV = { strsplit(" ", sArgs) };
                                else aArgV = { } end;
        -- Execute the function and return
        return LocalCommandsData[sFunc](sArgs, aArgV, #aArgV);
      end
      -- Check if variable exists of this function and if not?
      aVData = VariableExists(sFunc);
      if not aVData then
        -- Check if dynamic variable exists. Return with message if none
        aVData = ConfigData.Dynamic[sFunc];
        if not aVData then
          return Print("The variable or command '"..sFunc.."' is invalid") ;
        end
        -- Value specified? Set it, report it and return
        if sArgs then
          SetDynSetting(sFunc, sArgs);
          return Print(aVData.SD.." ("..sFunc..") has been set to "..sArgs);
        end
        -- Ask for input
        local sCurrent = GetDynSetting(sFunc);
        local sText = aVData.LD.."|n|nCurrent: |cffaaaa00"..sCurrent..
          "|r|nDefault: |cffaaaa00"..aVData.DF.."|r";
        local nMin = aVData.MI;
        if nMin then sText = sText.."|nMinimum: |cffaaaa00"..nMin.."|r" end;
        local nMax = aVData.MA;
        if nMax then sText = sText.."|nMaximum: |cffaaaa00"..nMax.."|r" end;
        return ShowInput(sText..
          "|n|nSet value of |cffaaaaaa"..aVData.SD.."|r to?", sFunc, sCurrent);
      end
      -- Get current setting and toggle it
      local bEnabled = SettingEnabled(sFunc);
      ConfigBooleanData[sFunc] = not bEnabled;
      -- Get reload information about the variable
      local iReload = aVData.R;
      if iReload >= 1 then LocalCommandsData.applycfg() end;
      if iReload >= 2 then LocalCommandsData.resetui() end;
      -- Prepare and dispatch output message
      local sMsg = aVData.SD.." ("..sFunc..") has been ";
      if bEnabled then sMsg = sMsg.."disabled" else sMsg = sMsg.."enabled" end;
      Print(sMsg);
    end
    -- Set uppercase version of command
    ConfigData.CommandUpper = ConfigData.Command:upper();
    -- Make a local reference of function for our own use.
    SlashFunc = OnCommand;
    -- Prepare global variable for command
    _G["SLASH_"..ConfigData.CommandUpper.."1"] = "/"..ConfigData.Command;
    -- Assign command to slash command list
    SlashCmdList[ConfigData.CommandUpper] = SlashFunc;
  end,
  -- Timer system ---------------------------------------------------------- --
  function()
    -- Initialise timer system
    MhMod:SetScript("OnUpdate", function()
      -- If there are any messages to print
      if #PrintData > 0 then
        -- Get message data and delete it
        local aItem = PrintData[1];
        tremove(PrintData, 1);
        -- Get colour
        local aColour = aItem[2];
        -- Print it
        DEFAULT_CHAT_FRAME:AddMessage(aItem[1],
          aColour.r, aColour.g, aColour.b, aColour.id);
      end
      -- Done if no timers
      if #TimerData == 0 then return end;
      -- Get time and create timer index for iterator
      local nTime, iI = GetTime(), 1;
      -- Iterate through each timer
      while iI <= #TimerData do
        -- Get timer
        local aData = TimerData[iI];
        -- End time has elapsed?
        if nTime >= aData.E then
          -- Call the callback function and if it returned nil?
          if not aData.F() then
            -- Get current iterations left and if no iterations?
            local iIterations = aData.C;
            if not iIterations then
              -- Timer looping forever, set next elapsed time and iterate
              aData.E, iI = nTime+aData.D, iI+1;
            -- Iterations remaining, decrement and set new end time
            elseif iIterations > 1 then
              -- Subtract iterations and iterate next timer
              aData.C, aData.E, iI = iIterations-1, nTime+aData.D, iI+1;
            else
              -- Remove the named and indexed timer (don't increment index)
              TimerData[aData.N] = nil;
              tremove(TimerData, iI);
            end
          -- Callback function requested the timer be killed
          else
            -- Remove the named and indexed timer (don't increment index)
            TimerData[aData.N] = nil;
            tremove(TimerData, iI);
          end
        -- Next item
        else iI = iI + 1 end;
      end
    end);
  end,
  -- Casting bar enhancements ---------------------------------------------- --
  function()
    -- Casting labels
    local aLabels = { };
    -- On show, record label
    local function OnShow(oFrame)
      aLabels[oFrame:GetName()..oFrame.unit] = oFrame.Text:GetText();
    end
    -- On hide, prevent update
    local function OnHide(oFrame)
      aLabels[oFrame:GetName()..oFrame.unit] = nil;
    end
    -- Update function
    local function OnUpdate(oFrame, nValue)
      -- Ignore if setting disabled
      if not bBarTimers or not oFrame:IsShown() then return end;
      -- Get recorded label
      local sLabel = aLabels[oFrame:GetName()..oFrame.unit];
      if not sLabel then return end;
      -- Get min max values
      local nMin, nMax = oFrame:GetMinMaxValues();
      -- Is casting or channeling?
      if not oFrame.channeling then nValue = nMax - nValue end;
      -- Set text string
      ProcessTextString(oFrame.Text, nValue/nMax*100,
        MakeCountdown(sLabel, nValue, nMax));
    end
    -- Hook player casting bar
    hooksecurefunc(PlayerCastingBarFrame, "UpdateShownState", OnShow);
    PlayerCastingBarFrame:HookScript("OnValueChanged", OnUpdate);
    hooksecurefunc(PlayerCastingBarFrame, "HandleInterruptOrSpellFailed",
      OnHide);
    -- Hook target casting bar
    hooksecurefunc(TargetFrameSpellBar, "UpdateShownState", OnShow);
    TargetFrameSpellBar:HookScript("OnValueChanged", OnUpdate);
    hooksecurefunc(TargetFrameSpellBar, "HandleInterruptOrSpellFailed",
      OnHide);
  end,
  -- Mirror timer enhancements --------------------------------------------- --
  function()
    -- Mirror labels
    local aLabels = { };
    -- When a timer is shown
    local function OnShow(oFrame)
      -- Ignore if no timer
      if not oFrame:HasTimer() then return end;
      -- Set label so we can reuse it
      local sLabel = oFrame.Text:GetText();
      aLabels[oFrame.timer] = sLabel;
    end
    -- When a timer is hidden
    local function OnHide(oFrame)
      -- Ignore if no timer
      if not oFrame:HasTimer() then return end;
      local sTimer = oFrame.timer;
      if not sTimer then return end;
      -- Clear label
      local sLabel = oFrame.Text:GetText();
      aLabels[sTimer] = nil
    end
    -- Update function
    local function OnUpdate(oFrame, nValue)
      -- Ignore if disabled
      if not bBarTimers then return end;
      -- Ignore if no timer
      oFrameParent = oFrame:GetParent();
      if not oFrameParent:HasTimer() then return end;
      -- Get current data for timer and return if there is no data set by
      -- MirrorTimer_SHow or the show timer on casting bars setting disabled.
      local sLabel = aLabels[oFrameParent.timer];
      if not sLabel then return end;
      local oFrameText = oFrameParent.Text;
      -- Get min max values
      local nMin, nMax = oFrame:GetMinMaxValues();
      -- Get text data
      ProcessTextString(oFrameText, nValue/nMax*100,
        MakeCountdown(sLabel, nValue, nMax));
    end
    -- Apply to all mirror timers
    for _, oFrame in ipairs(MirrorTimerContainer.mirrorTimers) do
      oFrame:HookScript("OnShow", OnShow);
      oFrame.StatusBar:SetScript("OnValueChanged", OnUpdate);
      oFrame:HookScript("OnHide", OnHide);
    end
  end,
  -- Map co-ordinates ------------------------------------------------------ --
  function()
    -- Rounding function
    local function Round(float) return floor(float+0.5) end;
    -- For every game tick the world map is open
    WorldMapFrame:HookScript("OnUpdate", function()
      -- Ignore if disabled
      if not bMapCoords then
        return WorldMapFrameTitleText:SetText(MAP_AND_QUEST_LOG) end;
      -- Get and calculate cursor based on visual world map size
      local nCX, nCY = WorldMapFrame:GetNormalizedCursorPosition()
      nCX = Round(nCX * 1000) / 10;
      nCY = Round(nCY * 1000) / 10;
      -- Get player position
      local iMapId, nPX, nPY = C_Map.GetBestMapForUnit("player");
      if iMapId then
        local aData = C_Map.GetPlayerMapPosition(iMapId, "player");
        if aData then nPX, nPY = aData:GetXY() else nPX, nPY = 0, 0 end;
      else nPX, nPY = 0, 0 end;
      -- New title starts with default title
      local sText = MAP_AND_QUEST_LOG;
      -- Add player position if valid
      if nPX and nPX ~= 0 and nPY ~= 0 then
        sText = sText..
          format(" - |cff7f7f7fPlayer: %.1f, %.1f|r", nPX * 100, nPY * 100);
      end
      -- Add cursor position if valid
      if nCX > 0 and nCX < 100 and nCY > 0 and nCY < 100 then
        sText = sText..
          format(" - |cffffffffCursor: %.1f, %.1f|r", nCX, nCY);
      end
      -- Set the text
      WorldMapFrameTitleText:SetText(sText);
    end);
  end,
  -- Bag button click modifier --------------------------------------------- --
  function()
    -- Hook buttons
    hooksecurefunc("HandleModifiedItemClick", function(_, oLoc)
      -- Return if no location sent
      if not oLoc then return end;
      -- Get bag id and return if none
      local iBagId, iSlotId = oLoc:GetBagAndSlot();
      if not iBagId or not iSlotId then return end;
      -- Return if setting disabled
      if not SettingEnabled("bagclik") then return end;
      -- Get item data and return if there is none for this item
      local aSlot = BagsData[iBagId];
      if not aSlot then return end;
      aSlot = aSlot[iSlotId];
      if not aSlot then return end;
      -- Get if button is locked and return if it is
      local _, _, bLocked = C_Container.GetContainerItemInfo(iBagId, iSlotId);
      if bLocked then return end;
      -- Get item link and return if none
      local sLink = aSlot.hyperlink;
      if not sLink then return end;
      -- Is alt or option key pressed?
      if IsAltKeyDown() then
        -- Is auction frame open?
        if AuctionFrame and AuctionFrame:IsVisible() then
          -- Put item in auction house
          AuctionFrameTab_OnClick(AuctionFrameTab3, 3);
          if CursorHasItem() then ClearCursor() end;
          C_Container.PickupContainerItem(iBagId, iSlotId);
          ClickAuctionSellItemButton();
          if CursorHasItem() then return ClearCursor() end;
          if IsShiftKeyDown() and SettingEnabled("bagsell") then
            AuctionsCreateAuctionButton_OnClick();
            local sMsg = "Automatically put "..sLink.." up for "..
              MakeMoneyReadable(LAST_ITEM_START_BID).." bid";
            if LAST_ITEM_BUYOUT > 0 then
              sMsg = sMsg.." and "..MakeMoneyReadable(LAST_ITEM_BUYOUT)..
                "buyout";
            end
            Print(sMsg.."!");
          end
        -- Auction frame not open?
        else
          -- Read current quantity
          local iCount = aSlot.stackCount or 0;
          -- Show track dialog input
          ShowInput("How many of "..sLink..
            " would you like to keep track of?|n|n"..
            "Current quantity: |cffaaaaaa"..
            BreakUpLargeNumbers(iCount).."|r", "trackadd", iCount+1, sLink);
        end
      -- Is shift key pressed? Just show information instead
      elseif IsShiftKeyDown() then SlashFunc("getitem "..sLink) end;
    end);
  end,
  -- Aura buttons enhancements --------------------------------------------- --
  function()
    -- Event function to replace with
    local function OnUpdate(oFrame, nRemain)
      -- If no time remaning then ignore because the text will be already
      -- hidden
      if not nRemain then return end;
      -- Get duration text frame
      oFrame = oFrame.Duration;
      -- Format days
      if nRemain >= 86400 then
        oFrame:SetFormattedText("%02u D", ceil(nRemain/86400%100));
      -- Format hours
      elseif nRemain >= 3600 then
        oFrame:SetFormattedText("%02u H", ceil(nRemain/3600%24));
      -- Format minutes
      elseif nRemain >= 60 then
        oFrame:SetFormattedText("%02u M", ceil(nRemain/60%60));
      -- Format seconds
      elseif nRemain >= 1 then
        oFrame:SetFormattedText("%02u S", nRemain%60);
      -- Buff ending now
      else oFrame:SetFormattedText("END") end;
      -- Set text colour from yellow (not ending soon) to white
      -- (ending now)
      oFrame:SetTextColor(1.00, 1.00,
        ClampNumber(1-(nRemain-60)/1800, 0, 1));
    end
    -- Hook onto buff and debuff frames
    for _, oParent in ipairs({ BuffFrame, DebuffFrame }) do
      -- For each button in those frames
      for _, oFrame in ipairs(oParent.auraFrames) do
        -- If we haven't hooked this button yet?
        if not oFrame:GetAttribute("MhMod") then
          -- Now hooking
          oFrame:SetAttribute("MhMod");
          -- Hook on to update duration function
          if oFrame.UpdateDuration then
            hooksecurefunc(oFrame, "UpdateDuration", OnUpdate);
          end
          -- Hook onto script
          oFrame:HookScript("OnMouseUp", function(oSelf, sButton)
            -- Ignore if not left button, shift not held or shift+click
            -- reporting is disabled.
            if sButton ~= "LeftButton" or not IsShiftKeyDown() or
              not SettingEnabled("tsbrprt") then return end;
            -- Get buff info and return if invalid buff
            local aData = C_UnitAuras.GetAuraDataByIndex(oSelf.unit,
              oSelf.buttonInfo.index, oSelf.filter);
            if not aData then return end;
            local sName = aData.name;
            -- Get spell link from id and use link instead of name if found
            local sLink = C_Spell.GetSpellLink(aData.spellId);
            if sLink and #sLink > 0 then sName = sLink end;
            -- Start building message and dispatch it
            local sMsg;
            if aData.duration > 0 then
              sMsg = MakeTime(aData.expirationTime - GetTime()).." left";
            else sMsg = "No time limit" end;
            sMsg = sMsg.." on "..sName;
            local iLevels = aData.charges;
            if iLevels then sMsg = sMsg.."x"..BreakUpLargeNumbers(iLevels) end;
            SendChat("<"..sMsg..">");
          end);
        end
      end
    end
  end,
  -- Final report version -------------------------------------------------- --
  function()
    -- Print banner
    Print("MhMod v"..GetVersion().." by "..Version.Author.." at "..
      Version.WebsiteFull, { r=1, g=0.5, b=1 });
    -- Check if version different
    local sType, sExtra;
    if not mhconfig.version or
       not mhconfig.verextra then
      sType, sExtra = "installing",
        "Left click on the 'W' button on your mini-map to start "..
        "enabling features or right click on it for commands!";
    elseif mhconfig.version ~= Version.Release or
           mhconfig.verextra ~= Version.Extra then
      sType, sExtra = "upgrading to",
      "New configuration options are marked as |c000000ff<NEW>|r on the "..
      "options window. Check out the website at |c000000ff"..
      Version.WebsiteFull.."|r for a full changelog!";
    end
    -- Check for new initialisation
    if sType then
      ShowMsg("Thanks for "..sType.." |c00ff00ffMhMod v"..GetVersion()..
        "|r! This dialog means that the add-on is successfully "..
        "activated and will not be shown again until you upgrade!|n|n"..
        sExtra);
      mhconfig.version = Version.Release;
      mhconfig.verextra = Version.Extra;
    end
  end,
};
-- Initialisation event ==================================================== --
MhMod:SetScript("OnEvent", function(_, _, sName)
  -- Unregister this event as we don't need it anymorez1
  MhMod:UnregisterAllEvents();
  -- Ignore if not my addon
  if sName ~= Version.Name then return end;
  -- Perform initialisations
  local aInits = MhMod.InitProcedures;
  MhMod.InitProcedures = nil;
  for iIndex = 1, #aInits do aInits[iIndex]() end;
end);
-- Initialise when we get ADDON_LOADED ----------------------------------------
MhMod:RegisterEvent("ADDON_LOADED");
-- ========================================================================= --
-- END-OF-FILE                                                   END-OF-FILE --
-- ========================================================================= --
