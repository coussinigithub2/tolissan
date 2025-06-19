-- ToLiss Announcements by Coussini 2025

--+==================================+
--|  L O C A L   V A R I A B L E S   |
--+==================================+
local ToLissAN = {}

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

    if itemRef ~= nil then
        ToLissAN_Log("✅ ---ToLissAN_MenuCallback---")
        local name = ToLissAN.FFI.string(ToLissAN.FFI.cast("const char*", itemRef))
        ToLissAN.SelectedCompanyName = name
        ToLissAN_Log("✅ Selected company : " .. name)
        ToLissAN.ToLissAN_LoadSpecificSoundsForCompany(ToLissAN.SelectedCompanyName)
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
    if ToLissAN.Datarefs["TolissPhase"].ValueBefore ~= ToLissAN.Datarefs["TolissPhase"].Value then

        if ToLissAN.Datarefs["TolissPhase"].Value == 0 then
            ToLissAN.isPreflight = true
        elseif ToLissAN.Datarefs["TolissPhase"].Value == 1 then
            ToLissAN.isPreflight = false
            ToLissAN.isTakeoff = true
        elseif ToLissAN.Datarefs["TolissPhase"].Value == 2 then
            ToLissAN.isTakeoff = false
            ToLissAN.isClimb = true
        elseif ToLissAN.Datarefs["TolissPhase"].Value == 3 then
            ToLissAN.isClimb = false
            ToLissAN.isCruise = true
        elseif ToLissAN.Datarefs["TolissPhase"].Value == 4 then
            ToLissAN.isCruise = false
            ToLissAN.isDescent = true
        elseif ToLissAN.Datarefs["TolissPhase"].Value == 5 then
            ToLissAN.isDescent = false
            ToLissAN.isApproach = true
        elseif ToLissAN.Datarefs["TolissPhase"].Value == 6 then
            ToLissAN.isApproach = false
            ToLissAN.isLanding = true
        end

        ToLissAN.Datarefs["TolissPhase"].ValueBefore = ToLissAN.Datarefs["TolissPhase"].Value
    end

    if ToLissAN.isPreflight and
      (ToLissAN.Datarefs["Eng1SwitchOn"].ValueBefore ~= ToLissAN.Datarefs["Eng1SwitchOn"].Value or
       ToLissAN.Datarefs["Eng2SwitchOn"].ValueBefore ~= ToLissAN.Datarefs["Eng2SwitchOn"].Value) then

        if ToLissAN.Datarefs["Eng1SwitchOn"].Value == 1 or ToLissAN.Datarefs["Eng2SwitchOn"].Value == 1 then
            ToLissAN.isAirbusStarted = true
        end

        ToLissAN.Datarefs["Eng1SwitchOn"].ValueBefore = ToLissAN.Datarefs["Eng1SwitchOn"].Value
        ToLissAN.Datarefs["Eng2SwitchOn"].ValueBefore = ToLissAN.Datarefs["Eng2SwitchOn"].Value
    end

    if ToLissAN.isTakeoff and
       ToLissAN.Datarefs["IasCaptain"].ValueBefore ~= ToLissAN.Datarefs["IasCaptain"].Value then

        if ToLissAN.Datarefs["IasCaptain"].Value > 95 then -- 100 kts
            ToLissAN.is100KtsReached = true
        end
        if ToLissAN.Datarefs["IasCaptain"].Value > ToLissAN.Datarefs["V1"].Value then
            ToLissAN.isV1Reached = true
        end
        if ToLissAN.Datarefs["IasCaptain"].Value > ToLissAN.Datarefs["V2"].Value then
            ToLissAN.isV2Reached = true
        end

        ToLissAN.Datarefs["IasCaptain"].ValueBefore = ToLissAN.Datarefs["IasCaptain"].Value
    end

    if ToLissAN.isClimb and
       ToLissAN.Datarefs["AltitudeCaptain"].ValueBefore ~= ToLissAN.Datarefs["AltitudeCaptain"].Value then

        if ToLissAN.Datarefs["AltitudeCaptain"].Value > 10000 then
            ToLissAN.is10000FeetReached = true
        end

        ToLissAN.Datarefs["AltitudeCaptain"].ValueBefore = ToLissAN.Datarefs["AltitudeCaptain"].Value
    end

    -----------------------
    -- BOARDING AMBIENCE --
    -----------------------
    if ToLissAN.isPreflight and not
       ToLissAN.CommonSounds["Boarding_Ambience"].played and
       ToLissAN.Datarefs["ExtPwr"].ValueBefore ~= ToLissAN.Datarefs["ExtPwr"].Value then

        if ToLissAN.Datarefs["ExtPwr"].Value == 1 then
            set_sound_gain(ToLissAN.CommonSounds["Boarding_Ambience"].sound, 0.10)
            play_sound(ToLissAN.CommonSounds["Boarding_Ambience"].sound)
            ToLissAN.CommonSounds["Boarding_Ambience"].played = true
        end

        ToLissAN.Datarefs["ExtPwr"].ValueBefore = ToLissAN.Datarefs["ExtPwr"].Value
    end

    -----------------------
    -- DOORS CROSS CHECK --
    -----------------------
    if ToLissAN.isPreflight and not
       ToLissAN.CommonSounds["DoorsCrossCheck"].played and
       ToLissAN.Datarefs["MainDoor"].ValueBefore ~= ToLissAN.Datarefs["MainDoor"].Value then

        if ToLissAN.Datarefs["MainDoor"].Value == 0 then
            play_sound(ToLissAN.CommonSounds["DoorsCrossCheck"].sound)
            ToLissAN.CommonSounds["DoorsCrossCheck"].played = true
        end

        ToLissAN.Datarefs["MainDoor"].ValueBefore = ToLissAN.Datarefs["MainDoor"].Value
    end

    -----------------
    -- CPT WELCOME --
    -----------------
    if ToLissAN.isPreflight and not
       ToLissAN.CommonSounds["CptWelcome"].played and
       ToLissAN.Datarefs["BeaconLight"].ValueBefore ~= ToLissAN.Datarefs["BeaconLight"].Value then

        if ToLissAN.Datarefs["BeaconLight"].Value == 1 then
            play_sound(ToLissAN.CommonSounds["CptWelcome"].sound)
            ToLissAN.CommonSounds["CptWelcome"].played = true
        end

        ToLissAN.Datarefs["BeaconLight"].ValueBefore = ToLissAN.Datarefs["BeaconLight"].Value
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
       ToLissAN.Datarefs["StrobeLightOn"].ValueBefore ~= ToLissAN.Datarefs["StrobeLightOn"].Value then

        if ToLissAN.Datarefs["StrobeLightOn"].Value == 2 then
            play_sound(ToLissAN.CommonSounds["CptTakeoff"].sound)
            ToLissAN.CommonSounds["CptTakeoff"].played = true
        end

        ToLissAN.Datarefs["StrobeLightOn"].ValueBefore = ToLissAN.Datarefs["StrobeLightOn"].Value
    end

    -------------
    -- 100 KTS --
    -------------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds[["100kts"]].played and
       ToLissAN.is100KtsReached then

        play_sound(ToLissAN.CommonSounds[["100kts"]].sound)
        ToLissAN.CommonSounds[["100kts"]].played = true
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
       ToLissAN.Datarefs["SeatBeltSignsOn"].ValueBefore ~= ToLissAN.Datarefs["SeatBeltSignsOn"].Value then

        if ToLissAN.Datarefs["SeatBeltSignsOn"].Value == 0 then
            play_sound(ToLissAN.CommonSounds["DutyFree"].sound)
            ToLissAN.CommonSounds["DutyFree"].played = true

        ToLissAN.Datarefs["SeatBeltSignsOn"].ValueBefore = ToLissAN.Datarefs["SeatBeltSignsOn"].Value
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
        if company ~= "common" then
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

    local datarefs = {
        ExtPwr               = { path = "AirbusFBW/ExtPowOHPArray", index = 0 },
        MainDoor             = { path = "AirbusFBW/PaxDoorModeArray", index = 0 },
        BeaconLight          = { path = "AirbusFBW/OHPLightSwitches", index = 0 },
        Eng1SwitchOn         = { path = "AirbusFBW/ENG1MasterSwitch" },
        Eng2SwitchOn         = { path = "AirbusFBW/ENG2MasterSwitch" },
        StrobeLightOn        = { path = "AirbusFBW/OHPLightSwitches", index = 7 },
        V1                   = { path = "toliss_airbus/performance/V1" },
        V2                   = { path = "toliss_airbus/performance/V2" },
        IasCaptain           = { path = "AirbusFBW/IASCapt" },
        SeatBeltSignsOn      = { path = "AirbusFBW/SeatBeltSignsOn" },
        AltitudeCaptain      = { path = "AirbusFBW/ALTCapt" },
        TolissPhase          = { path = "AirbusFBW/APPhase", index = 0 },
    }

    for name, def in pairs(datarefs) do
        if def.index then
            DataRef("ToLissAN_" .. name, def.path, "readonly", def.index)
        else
            DataRef("ToLissAN_" .. name, def.path, "readonly")
        end

        ToLissAN.Datarefs[name] = {
            Value = _G["ToLissAN_" .. name],
            ValueBefore = -1
        }
    end

    ToLissAN_Log("✅ Datarefs loaded")

end

--++---------------------------------------------------------------------------++
--|| ToLissAN_LoadSpecificSoundsForCompany() Load specific sounds from company ||
--++---------------------------------------------------------------------------++
function ToLissAN_LoadSpecificSoundsForCompany(company)

    ToLissAN_Log("✅ ---ToLissAN_LoadSpecificSoundsForCompany---")

    local sounds = {
        Safety                  = "Safety.wav"
    }

    for name, file in pairs(sounds) do
        ToLissAN.SpecificSounds[name] = {
            file = ToLissAN.SoundsPackPath .. company .. file,
            sound = load_WAV_file(ToLissAN.SoundsPackPath .. company .. file),
            played = false,
        }
    end
    --[[
        pcall(function()
            stop_sound(ToLissAN.SpecificSounds)
            unload_sound(ToLissAN.SpecificSounds)
        end)
    ]]

    ToLissAN_Log("✅ Specific Sounds loaded for : " .. company)

end

--++----------------------------------------------------------------------++
--|| ToLissAN_LoadCommonSoundsForCompany() Load common sounds for company ||
--++----------------------------------------------------------------------++
function ToLissAN_LoadCommonSoundsForCompany()

    ToLissAN_Log("✅ ---ToLissAN_LoadCommonSoundsForCompany---")

    local sounds = {
        Boarding_Ambience       = "Boarding_Ambience.wav",
        DoorsCrossCheck         = "DoorsCrossCheck.wav",
        CptWelcome              = "CptWelcome.wav",
        -- safety_sound treated elsewhere
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

    ToLissAN.LogFilePath = SCRIPT_DIRECTORY .. "ToLissAN_Log"
    os.remove(ToLissAN.LogFilePath)

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
if  string.lower(PLANE_AUTHOR) == "gliding kiwi" then

    ToLissAN_Log("🛫 Start ToLissAN program for Toliss "..PLANE_ICAO)

    ToLissAN_Initialization()
    ToLissAN_PrepareMenu()
    do_every_frame("ToLissAN_CheckDataref()")

end