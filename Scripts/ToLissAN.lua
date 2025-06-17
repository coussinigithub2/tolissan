-- ToLiss Announcements by Coussini 2025

--+==================================+
--|  L O C A L   V A R I A B L E S   |
--+==================================+
local ToLissAN = {}
ToLissAN.log_file_path = SCRIPT_DIRECTORY .. "ToLissAN.log"
ToLissAN.sounds_pack_path = SCRIPT_DIRECTORY .. "ToLissAN_sounds"
os.remove(ToLissAN.log_file_path)

--+====================================================================+
--|       T H E   F O L L O W I N G   A R E   H I G H   L E V E L      |
--|                       F U N C T I O N S                            |
--+====================================================================+

--++-------------------------------------++
--|| ToLissAN.log() Log for this program ||
--++-------------------------------------++
function ToLissAN.log(msg)
    local f = io.open(ToLissAN.log_file_path, "a")
    if f then
        local ts = os.date("[%Y-%m-%d %H:%M:%S]")
        f:write(ts .. " " .. msg .. "\n")
        f:close()
    end
end

--++------------------------------------------------------------------------++
--|| ToLissAN.get_company_list() Get the company list from the sound folder ||
--++------------------------------------------------------------------------++
function ToLissAN.get_company_list()
    local cmd = "dir /b \"" .. ToLissAN.sounds_pack_path .. "\""
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

--++-----------------------------------------------------------------------++
--|| ToLissAN.load_safety_sound_for_company() Load a Specific Safety sound ||
--++-----------------------------------------------------------------------++
function ToLissAN.load_safety_sound_for_company(name)
    ToLissAN.log("✅ ---load_safety_sound_for_company---")
    ToLissAN.selected_company_name = name
    if ToLissAN.safety_sound then
        pcall(function()
            stop_sound(ToLissAN.safety_sound)
            unload_sound(ToLissAN.safety_sound)
        end)
    end
    local path = ToLissAN.sounds_pack_path .. "/" .. name .. "/Safety.wav"
    ToLissAN.safety_sound = load_WAV_file(path)
    ToLissAN.log("✅ NEW COMPANY FOR SAFETY MESSAGE IS " .. name)
end

--++---------------------------------------------------------------------++
--|| ToLissAN.menu_callback() When a user select a company from the menu ||
--++---------------------------------------------------------------------++
function ToLissAN.menu_callback(menuRef, itemRef)
    if itemRef ~= nil then
        ToLissAN.log("✅ ---ToLissAN.menu_callback---")
        local name = ToLissAN.ffi.string(ToLissAN.ffi.cast("const char*", itemRef))
        ToLissAN.selected_company_name = name
        ToLissAN.log("✅ Selected company : " .. name)
        ToLissAN.load_safety_sound_for_company(ToLissAN.selected_company_name)
    else
        ToLissAN.log("❌ itemRef is nil")
    end
end

--++------------------------------------------------------------------------++
--|| ToLissAN_IncludeResourcesForMenu() Include resources for menu creation ||
--++------------------------------------------------------------------------++
function ToLissAN_IncludeResourcesForMenu()
    ToLissAN.log("✅ ---ToLissAN_IncludeResourcesForMenu---")
    ToLissAN.ffi = require("ffi")
    ToLissAN.ffi.cdef[[
        typedef void* XPLMMenuID;
        typedef void (*XPLMMenuHandler_f)(void*, void*);
        int XPLMAppendMenuItem(void* menu, const char* itemName, void* itemRef, int deprecated);
        XPLMMenuID XPLMCreateMenu(const char* name, void* parentMenu, int parentItem, XPLMMenuHandler_f handler, void* ref);
        void* XPLMFindPluginsMenu(void);
    ]]
    ToLissAN.XPLM = ToLissAN.ffi.load("XPLM_64")
    ToLissAN.log("✅ Resources FFI definitions loaded")
end

--++---------------------------------------------------------------------++
--|| ToLissAN_LoadCommonSoundsForEvents() Load common sounds for events  ||
--++---------------------------------------------------------------------++
function ToLissAN_LoadCommonSoundsForEvents()
    ToLissAN.log("✅ ---ToLissAN_LoadCommonSoundsForEvents---")
    ToLissAN.boarding_ambience = load_WAV_file(ToLissAN.sounds_pack_path .. "/Common/Boarding_Ambience.wav")
    ToLissAN.cpt_cruise        = load_WAV_file(ToLissAN.sounds_pack_path .. "/Common/CptCruiseLvl.wav")
    ToLissAN.cpt_descent       = load_WAV_file(ToLissAN.sounds_pack_path .. "/Common/CptDescent.wav")
    ToLissAN.cpt_landing       = load_WAV_file(ToLissAN.sounds_pack_path .. "/Common/CptLanding.wav")
    ToLissAN.cpt_takeoff       = load_WAV_file(ToLissAN.sounds_pack_path .. "/Common/CptTakeoff.wav")
    ToLissAN.cpt_welcome       = load_WAV_file(ToLissAN.sounds_pack_path .. "/Common/CptWelcome.wav")
    ToLissAN.doors_cross_check = load_WAV_file(ToLissAN.sounds_pack_path .. "/Common/DoorsCrossCheck.wav")
    ToLissAN.duty_free         = load_WAV_file(ToLissAN.sounds_pack_path .. "/Common/DutyFree.wav")
    ToLissAN.log("✅ Common Sounds loaded")
end

--++------------------------------------------------------------++
--|| ToLissAN_LoadDatarefsForEvents() Load datarefs for events  ||
--++------------------------------------------------------------++
function ToLissAN_LoadDatarefsForEvents()
    ToLissAN.log("✅ ---ToLissAN_LoadDatarefsForEvents---")

    --+=========================================+
    --| Boolean variables when reading datarefs |
    --+=========================================+
    ToLissAN_preflight = false
    ToLissAN_takeoff = false
    ToLissAN_climb = false
    ToLissAN_cruise = false
    ToLissAN_descent = false
    ToLissAN_approach = false
    ToLissAN_landing = false
    ToLissAN_10000_feet_reached = false
    ToLissAN_duty_free_played = false
    ToLissAN_cpt_cruise_played = false
    ToLissAN_cpt_descent_played = false

    --+=========================+
    --| Datarefs for monitoring |
    --+=========================+
    DataRef("ToLissAN_ext_pwr","AirbusFBW/ExtPowOHPArray","readonly",0)             -- Ext Power (0=off,1=on,2=avail)
    ToLissAN_ext_pwr_prev = -1
    DataRef("ToLissAN_main_door","AirbusFBW/PaxDoorModeArray","readonly",0)         -- Main boarding door (0=close,1=auto,2=open)
    ToLissAN_main_door_prev = -1
    DataRef("ToLissAN_beacon_light","AirbusFBW/OHPLightSwitches","readonly",0)      -- Beacon light (0=off,1=on)
    ToLissAN_beacon_light_prev = -1
    DataRef("ToLissAN_eng1_switch_on","AirbusFBW/ENG1MasterSwitch","readonly")      -- Engine 1 switch (0=off,1=on)
    ToLissAN_eng1_switch_on_prev = -1
    DataRef("ToLissAN_eng2_switch_on","AirbusFBW/ENG2MasterSwitch","readonly")      -- Engine 1 switch (0=off,1=on)
    ToLissAN_eng2_switch_on_prev = -1
    DataRef("ToLissAN_strobe_light_on","AirbusFBW/OHPLightSwitches","readonly",7)   -- Strobe light on (0=off,1=auto,2=on)
    ToLissAN_strobe_light_on_prev = -1
    DataRef("ToLissAN_baro_std","AirbusFBW/BaroStdCapt","readonly")                 -- Baro (0=Selected Baro,1=Std Baro)
    ToLissAN_baro_std_prev = -1
    DataRef("ToLissAN_altitude_captain","AirbusFBW/ALTCapt","readonly")             -- Altitude Captain side
    ToLissAN_altitude_captain_prev = -1
    --+======================================================================+
    --|           T O L I S S   P H A S E   F R O M   0   T O   7            |
    --| Preflight, Takeoff, Climb, Cruise, Descent, Approach, Landing & Done |
    --+======================================================================+
    DataRef("ToLissAN_toliss_phase","AirbusFBW/APPhase","readonly",0)
    ToLissAN_toliss_phase_prev = -1

    ToLissAN.log("✅ Datarefs loaded")
end

--++---------------------------------------------------------++
--|| ToLissAN_Initialization() Initialization of the program ||
--++---------------------------------------------------------++
function ToLissAN_Initialization()
    ToLissAN.log("✅ ---ToLissAN_Initialization---")

    ToLissAN.selected_company_name = "AirCanada" -- Default Company for sound
    ToLissAN_IncludeResourcesForMenu()
    ToLissAN.item_refs = {} -- For the menu pointer
    ToLissAN_LoadCommonSoundsForEvents()
    ToLissAN_LoadDatarefsForEvents()
    ToLissAN.log("✅ Initialization done")
end

--++-------------------------------------------------------------++
--|| ToLissAN_CheckDataref() Monitoring dataref for sounds event ||
--++-------------------------------------------------------------++
function ToLissAN_CheckDataref()

    -----------------------------------------------------
    --++++++++++++++++ MULTI CONDITION ++++++++++++++++--
    -----------------------------------------------------
    if ToLissAN_toliss_phase_prev ~= ToLissAN_toliss_phase then
        if ToLissAN_toliss_phase == 0 then
            ToLissAN_preflight = true
        elseif ToLissAN_toliss_phase == 1 then
            ToLissAN_preflight = false
            ToLissAN_takeoff = true
        elseif ToLissAN_toliss_phase == 2 then
            ToLissAN_takeoff = false
            ToLissAN_climb = true
        elseif ToLissAN_toliss_phase == 3 then
            ToLissAN_climb = false
            ToLissAN_cruise = true
        elseif ToLissAN_toliss_phase == 4 then
            ToLissAN_cruise = false
            ToLissAN_descent = true
        elseif ToLissAN_toliss_phase == 5 then
            ToLissAN_descent = false
            ToLissAN_approach = true
        elseif ToLissAN_toliss_phase == 6 then
            ToLissAN_approach = false
            ToLissAN_landing = true
        end
        ToLissAN_toliss_phase_prev = ToLissAN_toliss_phase
    end

    if ToLissAN_climb and ToLissAN_altitude_captain ~= ToLissAN_altitude_captain_prev then
        if not ToLissAN_10000_feet_reached and ToLissAN_altitude_captain > 10000 then
            ToLissAN_10000_feet_reached = true
        end
        ToLissAN_altitude_captain_prev = ToLissAN_altitude_captain
    end

    -----------------------
    -- BOARDING AMBIENCE --
    -----------------------
    if ToLissAN_preflight and ToLissAN_ext_pwr_prev ~= ToLissAN_ext_pwr then
        if ToLissAN_ext_pwr == 1 then
            set_sound_gain(ToLissAN.boarding_ambience, 0.10)
            play_sound(ToLissAN.boarding_ambience)
        elseif ToLissAN_ext_pwr ~= 1 then
            stop_sound(ToLissAN.boarding_ambience)
        end
        ToLissAN_ext_pwr_prev = ToLissAN_ext_pwr
    end

    -----------------------
    -- DOORS CROSS CHECK --
    -----------------------
    if ToLissAN_preflight and ToLissAN_main_door_prev ~= ToLissAN_main_door then
        if ToLissAN_main_door == 0 then
            play_sound(ToLissAN.doors_cross_check)
        elseif ToLissAN_main_door ~= 0 then
            stop_sound(ToLissAN.doors_cross_check)
        end
        ToLissAN_main_door_prev = ToLissAN_main_door
    end

    -----------------
    -- CPT WELCOME --
    -----------------
    if ToLissAN_preflight and ToLissAN_beacon_light_prev ~= ToLissAN_beacon_light then
        if ToLissAN_beacon_light == 1 then
            play_sound(ToLissAN.cpt_welcome)
        elseif ToLissAN_beacon_light ~= 1 then
            stop_sound(ToLissAN.cpt_welcome)
        end
        ToLissAN_beacon_light_prev = ToLissAN_beacon_light
    end

    --------------------
    -- SAFETY ANNONCE --
    --------------------
    if ToLissAN_preflight and
       (ToLissAN_eng1_switch_on_prev ~= ToLissAN_eng1_switch_on or
        ToLissAN_eng2_switch_on_prev ~= ToLissAN_eng2_switch_on) then
        if ToLissAN_eng1_switch_on == 1 or ToLissAN_eng2_switch_on == 1 then
            play_sound(ToLissAN.safety_sound)
        elseif ToLissAN_eng1_switch_on ~= 1 or ToLissAN_eng2_switch_on ~= 1 then
            stop_sound(ToLissAN.safety_sound)
        end
        ToLissAN_eng1_switch_on_prev = ToLissAN_eng1_switch_on
        ToLissAN_eng2_switch_on_prev = ToLissAN_eng2_switch_on
    end

    -----------------
    -- CPT TAKEOFF --
    -----------------
    if ToLissAN_preflight and ToLissAN_strobe_light_on_prev ~= ToLissAN_strobe_light_on then
        if ToLissAN_strobe_light_on == 2 then
            play_sound(ToLissAN.cpt_takeoff)
        elseif ToLissAN_strobe_light_on ~= 2 then
            stop_sound(ToLissAN.cpt_takeoff)
        end
        ToLissAN_strobe_light_on_prev = ToLissAN_strobe_light_on
    end

    ---------------
    -- DUTY FREE --
    ---------------
    if ToLissAN_climb and not ToLissAN_duty_free_played and ToLissAN_10000_feet_reached then
        play_sound(ToLissAN.duty_free)
        ToLissAN_duty_free_played = true
    end

    ------------------
    -- CRUISE REACH --
    ------------------
    if ToLissAN_cruise and not ToLissAN_cpt_cruise_played then
        play_sound(ToLissAN.cpt_cruise)
        ToLissAN_cpt_cruise_played = true
    end

    -------------------
    -- DESCENT REACH --
    -------------------
    if ToLissAN_descent and not ToLissAN_cpt_descent_played  then
        play_sound(ToLissAN.cpt_descent)
        ToLissAN_cpt_descent_played = true
    end

    --------------------
    -- APPROACH REACH --
    --------------------
    if ToLissAN_approach and not ToLissAN_cpt_approach_played  then
        play_sound(ToLissAN.cpt_approach)
        ToLissAN_cpt_approach_played = true
    end
end

--++---------------------------------------------------------------------++
--|| ToLissAN_PrepareMenu() Create menu for Company selection and sounds ||
--++---------------------------------------------------------------------++
function ToLissAN_PrepareMenu()
    ToLissAN.log("✅ ---ToLissAN_PrepareMenu---")
    ToLissAN.C_menu_callback = ToLissAN.ffi.cast("XPLMMenuHandler_f", ToLissAN.menu_callback)
    ToLissAN.plugins_menu = ToLissAN.XPLM.XPLMFindPluginsMenu()
    ToLissAN.top_item_index = ToLissAN.XPLM.XPLMAppendMenuItem(ToLissAN.plugins_menu, "ToLissCo", nil, 0)
    ToLissAN.submenu = ToLissAN.XPLM.XPLMCreateMenu("ToLissCo", ToLissAN.plugins_menu, ToLissAN.top_item_index, ToLissAN.C_menu_callback, nil)

    for _, company in ipairs(ToLissAN.get_company_list()) do
        local ptr = ToLissAN.ffi.new("char[?]", #company + 1, company)
        ToLissAN.item_refs[company] = ptr
        ToLissAN.XPLM.XPLMAppendMenuItem(ToLissAN.submenu, company, ptr, 0)
    end
    ToLissAN.log("✅ Menu created")
end

--+====================================================================+
--|       T H E   F O L L O W I N G   I S   T H E    M A I N           |
--|                          S E C T I O N                             |
--+====================================================================+
if  string.lower(PLANE_AUTHOR) == "gliding kiwi" then

    ToLissAN.log("🛫 Start ToLissAN program for Toliss "..PLANE_ICAO)

    ToLissAN_Initialization()
    ToLissAN_PrepareMenu()
    ToLissAN.log("✅ DEFAULT COMPANY FOR SAFETY MESSAGE IS : "..ToLissAN.selected_company_name)
    ToLissAN.load_safety_sound_for_company(ToLissAN.selected_company_name)
    do_every_frame("ToLissAN_CheckDataref()")

end