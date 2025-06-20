-- ToLiss Announcements by Coussini 2025

--+==================================+
--|  L O C A L   V A R I A B L E S   |
--+==================================+
local ToLissAN = {}

ToLissAN.LogFilePath = SCRIPT_DIRECTORY .. "ToLissAN_Log.txt"
os.remove(ToLissAN.LogFilePath)

--+====================================================================+
--|       T H E   F O L L O W I N G   A R E   H I G H   L E V E L      |
--|                       F U N C T I O N S                            |
--+====================================================================+

--++-------------------------------------++
--|| ToLissAN_Log() Log for this program ||
--++-------------------------------------++
function ToLissAN_Log(msg)

    local f = io.open(ToLissAN.LogFilePath, "a")

    if f then
        local ts = os.date("[%Y-%m-%d %H:%M:%S]")
        f:write(ts .. " " .. msg .. "\n")
        f:close()
    end

end

--++----------------------------------------------------------------------++
--|| ToLissAN_GetCompanyList() Get the company list from the sound folder ||
--++----------------------------------------------------------------------++
function ToLissAN_GetCompanyList()

    local cmd = "dir /b \"" .. ToLissAN.SoundsPackPath .. "\""
    local file = io.popen(cmd)
    local list = {}

    if file then
        for line in file:lines() do
            table.insert(list, line)
        end
        file:close()
    end

    return list

end

--++--------------------------------------------------------------------++
--|| ToLissAN_MenuCallback() When a user select a company from the menu ||
--++--------------------------------------------------------------------++
function ToLissAN_MenuCallback(menuRef, itemRef)

    ToLissAN_Log("✅ ---ToLissAN_MenuCallback---")

    if itemRef ~= nil then
        local name = ToLissAN.FFI.string(ToLissAN.FFI.cast("const char*", itemRef))
        ToLissAN.SelectedCompanyName = name
        ToLissAN_Log("✅ Selected company : " .. name)
        ToLissAN_LoadSpecificSoundsForCompany(ToLissAN.SelectedCompanyName)
    else
        ToLissAN_Log("❌ itemRef is nil")
    end

end

--++-------------------------------------------------------------++
--|| ToLissAN_CheckDataref() Monitoring dataref for sounds event ||
--++-------------------------------------------------------------++
function ToLissAN_CheckDataref()

    -----------------------------------------------------
    --++++++++++++++++ MULTI CONDITION ++++++++++++++++--
    -----------------------------------------------------
    if DATAREF_TolissPhaseBefore ~= DATAREF_TolissPhase then

        if DATAREF_TolissPhase == 0 then
            ToLissAN.isPreflight = true
            ToLissAN_Log("ℹ️ isPreflight = " .. tostring(ToLissAN.isPreflight))
        elseif DATAREF_TolissPhase == 1 then
            ToLissAN.isPreflight = false
            ToLissAN.isTakeoff = true
            ToLissAN_Log("ℹ️ isTakeoff = " .. tostring(ToLissAN.isTakeoff))
        elseif DATAREF_TolissPhase == 2 then
            ToLissAN.isTakeoff = false
            ToLissAN.isClimb = true
            ToLissAN_Log("ℹ️ isClimb = " .. tostring(ToLissAN.isClimb))
        elseif DATAREF_TolissPhase == 3 then
            ToLissAN.isClimb = false
            ToLissAN.isCruise = true
            ToLissAN_Log("ℹ️ isCruise = " .. tostring(ToLissAN.isCruise))
        elseif DATAREF_TolissPhase == 4 then
            ToLissAN.isCruise = false
            ToLissAN.isDescent = true
            ToLissAN_Log("ℹ️ isDescent = " .. tostring(ToLissAN.isDescent))
        elseif DATAREF_TolissPhase == 5 then
            ToLissAN.isDescent = false
            ToLissAN.isApproach = true
            ToLissAN_Log("ℹ️ isApproach = " .. tostring(ToLissAN.isApproach))
        elseif DATAREF_TolissPhase == 6 then
            ToLissAN.isApproach = false
            ToLissAN.isLanding = true
            ToLissAN_Log("ℹ️ isLanding = " .. tostring(ToLissAN.isLanding))
        end

        DATAREF_TolissPhaseBefore = DATAREF_TolissPhase
    end

    if ToLissAN.isPreflight and
      (DATAREF_Eng1SwitchOnBefore ~= DATAREF_Eng1SwitchOn or
       DATAREF_Eng2SwitchOnBefore ~= DATAREF_Eng2SwitchOn) then

        if DATAREF_Eng1SwitchOn == 1 or DATAREF_Eng2SwitchOn == 1 then
            ToLissAN.isAirbusStarted = true
            ToLissAN_Log("ℹ️ isAirbusStarted = " .. tostring(ToLissAN.isAirbusStarted))
        end

        DATAREF_Eng1SwitchOnBefore = DATAREF_Eng1SwitchOn
        DATAREF_Eng2SwitchOnBefore = DATAREF_Eng2SwitchOn
    end

    if ToLissAN.isTakeoff and
       DATAREF_IasCaptainBefore ~= DATAREF_IasCaptain then

        if DATAREF_IasCaptain > 95 then -- 100 kts
            ToLissAN.is100KtsReached = true
            ToLissAN_Log("ℹ️ is100KtsReached = " .. tostring(ToLissAN.is100KtsReached))
        end
        if DATAREF_IasCaptain > DATAREF_V1 then
            ToLissAN.isV1Reached = true
            ToLissAN_Log("ℹ️ isV1Reached = " .. tostring(ToLissAN.isV1Reached))
        end
        if DATAREF_IasCaptain > DATAREF_V2 then
            ToLissAN.isV2Reached = true
            ToLissAN_Log("ℹ️ isV2Reached = " .. tostring(ToLissAN.isV2Reached))
        end

        DATAREF_IasCaptainBefore = DATAREF_IasCaptain
    end

    if ToLissAN.isClimb and
       DATAREF_AltitudeCaptainBefore ~= DATAREF_AltitudeCaptain then

        if DATAREF_AltitudeCaptain > 10000 then
            ToLissAN.is10000FeetReached = true
            ToLissAN_Log("ℹ️ is10000FeetReached = " .. tostring(ToLissAN.is10000FeetReached))
        end

        DATAREF_AltitudeCaptainBefore = DATAREF_AltitudeCaptain
    end

    -----------------------
    -- BOARDING AMBIENCE --
    -----------------------
    if ToLissAN.isPreflight and not
       ToLissAN.CommonSounds["Boarding_Ambience"].played and
       DATAREF_ExtPwrBefore ~= DATAREF_ExtPwr then

        if DATAREF_ExtPwr == 1 then
            set_sound_gain(ToLissAN.CommonSounds["Boarding_Ambience"].sound, 0.10)
            play_sound(ToLissAN.CommonSounds["Boarding_Ambience"].sound)
            ToLissAN.CommonSounds["Boarding_Ambience"].played = true
        end

        DATAREF_ExtPwrBefore = DATAREF_ExtPwr
    end

    -----------------------
    -- DOORS CROSS CHECK --
    -----------------------
    if ToLissAN.isPreflight and not
       ToLissAN.CommonSounds["DoorsCrossCheck"].played and
       DATAREF_MainDoorBefore ~= DATAREF_MainDoor then

        if DATAREF_MainDoor == 0 then
            play_sound(ToLissAN.CommonSounds["DoorsCrossCheck"].sound)
            ToLissAN.CommonSounds["DoorsCrossCheck"].played = true
        end

        DATAREF_MainDoorBefore = DATAREF_MainDoor
    end

    -----------------
    -- CPT WELCOME --
    -----------------
    if ToLissAN.isPreflight and not
       ToLissAN.CommonSounds["CptWelcome"].played and
       DATAREF_BeaconLightBefore ~= DATAREF_BeaconLight then

        if DATAREF_BeaconLight == 1 then
            play_sound(ToLissAN.CommonSounds["CptWelcome"].sound)
            ToLissAN.CommonSounds["CptWelcome"].played = true
        end

        DATAREF_BeaconLightBefore = DATAREF_BeaconLight
    end

    --------------------
    -- SAFETY ANNONCE --
    --------------------
    if ToLissAN.isPreflight and not
       ToLissAN.SpecificSounds["Safety"].played and
       ToLissAN.isAirbusStarted then

        play_sound(ToLissAN.SpecificSounds["Safety"].sound)
        ToLissAN.SpecificSounds["Safety"].played = true
    end

    -----------------
    -- CPT TAKEOFF --
    -----------------
    if ToLissAN.isPreflight and not
       ToLissAN.CommonSounds["CptTakeoff"].played and
       DATAREF_StrobeLightOnBefore ~= DATAREF_StrobeLightOn then

        if DATAREF_StrobeLightOn == 2 then
            play_sound(ToLissAN.CommonSounds["CptTakeoff"].sound)
            ToLissAN.CommonSounds["CptTakeoff"].played = true
        end

        DATAREF_StrobeLightOnBefore = DATAREF_StrobeLightOn
    end

    -------------
    -- 100 KTS --
    -------------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds["100kts"].played and
       ToLissAN.is100KtsReached then

        play_sound(ToLissAN.CommonSounds["100kts"].sound)
        ToLissAN.CommonSounds["100kts"].played = true
    end

    --------
    -- V1 --
    --------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds["V1"].played and
       ToLissAN.isV1Reached  then

        play_sound(ToLissAN.CommonSounds["V1"].sound)
        ToLissAN.CommonSounds["V1"].played = true
    end

    ------------------
    -- V2 OR ROTATE --
    ------------------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds["Rotate"].played and
       ToLissAN.isV2Reached  then

        play_sound(ToLissAN.CommonSounds["Rotate"].sound)
        ToLissAN.CommonSounds["Rotate"].played = true
    end

    ---------------
    -- DUTY FREE --
    ---------------
    if ToLissAN.isClimb and not
       ToLissAN.CommonSounds["DutyFree"].played and
       ToLissAN.is10000FeetReached and
       DATAREF_SeatBeltSignsOnBefore ~= DATAREF_SeatBeltSignsOn then

        if DATAREF_SeatBeltSignsOn == 0 then
            play_sound(ToLissAN.CommonSounds["DutyFree"].sound)
            ToLissAN.CommonSounds["DutyFree"].played = true
        end

        DATAREF_SeatBeltSignsOnBefore = DATAREF_SeatBeltSignsOn
    end

    ------------------
    -- CRUISE REACH --
    ------------------
    if ToLissAN.isCruise and not
       ToLissAN.CommonSounds["CptCruiseLvl"].played then

        play_sound(ToLissAN.CommonSounds["CptCruiseLvl"].sound)
        ToLissAN.CommonSounds["CptCruiseLvl"].played = true
    end

    -------------------
    -- DESCENT REACH --
    -------------------
    if ToLissAN.isDescent and not
       ToLissAN.CommonSounds["CptDescent"].played  then

        play_sound(ToLissAN.CommonSounds["CptDescent"].sound)
        ToLissAN.CommonSounds["CptDescent"].played = true

    end

    --------------------
    -- APPROACH REACH --
    --------------------
    if ToLissAN.isApproach and not
       ToLissAN.CommonSounds["CptLanding"].played  then

        play_sound(ToLissAN.CommonSounds["CptLanding"].sound)
        ToLissAN.CommonSounds["CptLanding"].played = true
    end
end

--++---------------------------------------------------------------------++
--|| ToLissAN_PrepareMenu() Create menu for Company selection and sounds ||
--++---------------------------------------------------------------------++
function ToLissAN_PrepareMenu()

    ToLissAN_Log("✅ ---ToLissAN_PrepareMenu---")

    ToLissAN.C_MenuCallback = ToLissAN.FFI.cast("XPLMMenuHandler_f", ToLissAN_MenuCallback)
    ToLissAN.PluginsMenu = ToLissAN.XPLM.XPLMFindPluginsMenu()
    ToLissAN.TopItemIndex = ToLissAN.XPLM.XPLMAppendMenuItem(ToLissAN.PluginsMenu, "ToLissCo", nil, 0)
    ToLissAN.SubMenu = ToLissAN.XPLM.XPLMCreateMenu("ToLissCo", ToLissAN.PluginsMenu, ToLissAN.TopItemIndex, ToLissAN.C_MenuCallback, nil)

    for _, company in ipairs(ToLissAN_GetCompanyList()) do
        if company ~= "Common" then
            local ptr = ToLissAN.FFI.new("char[?]", #company + 1, company)
            ToLissAN.ItemRefs[company] = ptr
            ToLissAN.XPLM.XPLMAppendMenuItem(ToLissAN.SubMenu, company, ptr, 0)
        end
    end

    ToLissAN_Log("✅ Menu created")

end

--++------------------------------------------------------------++
--|| ToLissAN_LoadDatarefsForEvents() Load datarefs for events  ||
--++------------------------------------------------------------++
function ToLissAN_LoadDatarefsForEvents()

    ToLissAN_Log("✅ ---ToLissAN_LoadDatarefsForEvents---")

    DataRef("DATAREF_ExtPwr","AirbusFBW/ExtPowOHPArray","readonly",0)
    DATAREF_ExtPwrBefore = -1

    DataRef("DATAREF_MainDoor","AirbusFBW/PaxDoorModeArray","readonly",0)
    DATAREF_MainDoorBefore = -1

    DataRef("DATAREF_BeaconLight","AirbusFBW/OHPLightSwitches","readonly",0)
    DATAREF_BeaconLightBefore = -1

    DataRef("DATAREF_Eng1SwitchOn","AirbusFBW/ENG1MasterSwitch","readonly")
    DATAREF_Eng1SwitchOnBefore = -1

    DataRef("DATAREF_Eng2SwitchOn","AirbusFBW/ENG2MasterSwitch","readonly")
    DATAREF_Eng2SwitchOnBefore = -1

    DataRef("DATAREF_StrobeLightOn","AirbusFBW/OHPLightSwitches","readonly",7)
    DATAREF_StrobeLightOnBefore = -1

    DataRef("DATAREF_V1","toliss_airbus/performance/V1","readonly")
    DATAREF_V1Before = -1

    DataRef("DATAREF_V2","toliss_airbus/performance/V2","readonly")
    DATAREF_V2Before = -1

    DataRef("DATAREF_IasCaptain","AirbusFBW/IASCapt","readonly")
    DATAREF_IasCaptainBefore = -1

    DataRef("DATAREF_SeatBeltSignsOn","AirbusFBW/SeatBeltSignsOn","readonly")
    DATAREF_SeatBeltSignsOnBefore = -1

    DataRef("DATAREF_AltitudeCaptain","AirbusFBW/ALTCapt","readonly")
    DATAREF_AltitudeCaptainBefore = -1

    DataRef("DATAREF_TolissPhase","AirbusFBW/APPhase","readonly")
    DATAREF_TolissPhaseBefore = -1

    ToLissAN_Log("✅ Datarefs loaded")

end

--++---------------------------------------------------------------------------++
--|| ToLissAN_LoadSpecificSoundsForCompany() Load specific sounds from company ||
--++---------------------------------------------------------------------------++
function ToLissAN_LoadSpecificSoundsForCompany(company)

    ToLissAN_Log("✅ ---ToLissAN_LoadSpecificSoundsForCompany---")

    local sounds = {
        Safety = "Safety.wav"
    }

    for name, file in pairs(sounds) do
        pcall(function()
            if ToLissAN.SpecificSounds[name] and ToLissAN.SpecificSounds[name].sound then
                stop_sound(ToLissAN.SpecificSounds[name].sound)
                replace_WAV_file(ToLissAN.SpecificSounds[name].sound, ToLissAN.SoundsPackPath .. "/" .. company .. "/" .. file)
                ToLissAN_Log("ℹ️ Previous company '" .. name .. "' sound, stopped and replaced successfully.")
            end
        end)
        ToLissAN.SpecificSounds[name] = {
            file = ToLissAN.SoundsPackPath .. "/" .. company .. "/" .. file,
            sound = load_WAV_file(ToLissAN.SoundsPackPath .. "/" .. company .. "/" .. file),
            played = false,
        }
    end

    ToLissAN_Log("📢 Specific Sounds loaded for : " .. company)

end

--++----------------------------------------------------------------------++
--|| ToLissAN_LoadCommonSoundsForCompany() Load common sounds for company ||
--++----------------------------------------------------------------------++
function ToLissAN_LoadCommonSoundsForCompany()

    -- Safety.wav treated in ToLissAN_LoadSpecificSoundsForCompany()

    ToLissAN_Log("✅ ---ToLissAN_LoadCommonSoundsForCompany---")

    local sounds = {
        Boarding_Ambience       = "Boarding_Ambience.wav",
        DoorsCrossCheck         = "DoorsCrossCheck.wav",
        CptWelcome              = "CptWelcome.wav",
        CptTakeoff              = "CptTakeoff.wav",
        ThrustSet               = "ThrustSet.wav",
        ["100kts"]              = "100kts.wav",
        V1                      = "V1.wav",
        Rotate                  = "Rotate.wav",
        PositiveClimb           = "PositiveClimb.wav",
        GearUp                  = "GearUp.wav",
        SpeedCheckFlap0         = "SpeedCheckFlap0.wav",
        SpeedCheckFlap1         = "SpeedCheckFlap1.wav",
        SpeedCheckFlap2         = "SpeedCheckFlap2.wav",
        SpeedCheckFlap3         = "SpeedCheckFlap3.wav",
        SpeedCheckFlapFull      = "SpeedCheckFlapFull.wav",
        DutyFree                = "DutyFree.wav",
        CptCruiseLvl            = "CptCruiseLvl.wav",
        CptDescent              = "CptDescent.wav",
        CptLanding              = "CptLanding.wav",
        GearDown                = "GearDown.wav",
        Spoilers                = "Spoilers.wav",
        ReverseGreen            = "ReverseGreen.wav",
        Decel                   = "Decel.wav",
        ["70kts"]               = "70kts.wav"
    }

    for name, file in pairs(sounds) do
        ToLissAN.CommonSounds[name] = {
            file = ToLissAN.SoundsPackPath .. "/Common/" .. file,
            sound = load_WAV_file(ToLissAN.SoundsPackPath .. "/Common/" .. file),
            played = false,
        }
    end

    ToLissAN_Log("✅ Common Sounds loaded")

end

--++------------------------------------------------------------------------++
--|| ToLissAN_IncludeResourcesForMenu() Include resources for menu creation ||
--++------------------------------------------------------------------------++
function ToLissAN_IncludeResourcesForMenu()

    ToLissAN_Log("✅ ---ToLissAN_IncludeResourcesForMenu---")

    ToLissAN.FFI = require("ffi")
    ToLissAN.FFI.cdef[[
        typedef void* XPLMMenuID;
        typedef void (*XPLMMenuHandler_f)(void*, void*);
        int XPLMAppendMenuItem(void* menu, const char* itemName, void* itemRef, int deprecated);
        XPLMMenuID XPLMCreateMenu(const char* name, void* parentMenu, int parentItem, XPLMMenuHandler_f handler, void* ref);
        void* XPLMFindPluginsMenu(void);
    ]]
    ToLissAN.XPLM = ToLissAN.FFI.load("XPLM_64")

    ToLissAN_Log("✅ Resources FFI definitions loaded")

end

--++-----------------------------------------------------------------++
--|| TolissAN_SetDefaultValues() Set default values for this program ||
--++-----------------------------------------------------------------++
function TolissAN_SetDefaultValues()

    ToLissAN_Log("✅ ---TolissAN_SetDefaultValues---")

    ToLissAN.SoundsPackPath = SCRIPT_DIRECTORY .. "ToLissAN_sounds"

    ToLissAN.ItemRefs = {} -- For the menu pointer
    ToLissAN.SelectedCompanyName = "AirCanada" -- Default Company for sound
    ToLissAN.CommonSounds = {} -- List for Common sounds for company
    ToLissAN.SpecificSounds = {} -- List for Specific sounds for company
    ToLissAN.Datarefs = {} -- List of dataref for monitoring

    --+=========================================+
    --| Boolean variables when reading datarefs |
    --+=========================================+
    -- FOR PHASES
    ToLissAN.isPreflight = false
    ToLissAN.isTakeoff = false
    ToLissAN.isClimb = false
    ToLissAN.isCruise = false
    ToLissAN.isDescent = false
    ToLissAN.isApproach = false
    ToLissAN.isLanding = false
    -- FOR EVENTS REACHED
    ToLissAN.isAirbusStarted = false
    ToLissAN.is100KtsReached = false
    ToLissAN.isV1Reached = false
    ToLissAN.isV2Reached = false
    ToLissAN.is10000FeetReached = false

    ToLissAN_Log("✅ Default values set")

end

--++---------------------------------------------------------++
--|| ToLissAN_Initialization() Initialization of the program ||
--++---------------------------------------------------------++
function ToLissAN_Initialization()

    ToLissAN_Log("✅ ---ToLissAN_Initialization---")

    TolissAN_SetDefaultValues()
    ToLissAN_IncludeResourcesForMenu()
    ToLissAN_LoadCommonSoundsForCompany()
    ToLissAN_LoadSpecificSoundsForCompany(ToLissAN.SelectedCompanyName)
    ToLissAN_LoadDatarefsForEvents()

    ToLissAN_Log("✅ Initialization done")

end

--+====================================================================+
--|       T H E   F O L L O W I N G   I S   T H E    M A I N           |
--|                          S E C T I O N                             |
--+====================================================================+
if  (string.lower(PLANE_AUTHOR) == "gliding kiwi") then

    ToLissAN_Log("🛫 Start ToLissAN program for Toliss " .. PLANE_ICAO)

    ToLissAN_Initialization()
    ToLissAN_PrepareMenu()
    do_every_frame("ToLissAN_CheckDataref()")

end