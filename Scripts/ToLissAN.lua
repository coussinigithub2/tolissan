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

--++-------------------------------------------------------------------------++
--|| ToLissAN_CreateCompanyCombo() Create and manage compagny drop down list ||
--++-------------------------------------------------------------------------++
function ToLissAN_CreateCompanyCombo(wnd, x, y)

    if imgui.BeginCombo("Company", ToLissAN.CompanyList[ToLissAN.Company]) then

        for i = 1, #ToLissAN.CompanyList do
            if imgui.Selectable(ToLissAN.CompanyList[i], ToLissAN.Company == i) then
                ToLissAN.Company = i
            end
        end

        if ToLissAN.CompanyList[ToLissAN.Company] ~= ToLissAN.SelectedCompanyName then
            ToLissAN.SelectedCompanyName = ToLissAN.CompanyList[ToLissAN.Company]
            ToLissAN_LoadSpecificSoundsForCompany(ToLissAN.SelectedCompanyName)
        end

        imgui.EndCombo()
    end

end

--++-------------------------------------------------------------------++
--|| ToLissAN_CloseCompanySelectionWindow() Close the selection window ||
--++-------------------------------------------------------------------++
function ToLissAN_CloseCompanySelectionWindow(wnd)
end

--++-----------------------------------------------------------------------------++
--|| ToLissAN_ShowSelectedCompany() Show the selected company in the bottom left ||
--++-----------------------------------------------------------------------------++
function ToLissAN_ShowSelectedCompany()

    local pos = 0

    pos = big_bubble(20, pos, "Selected company : " .. ToLissAN.CompanyList[ToLissAN.Company])

end

--++----------------------------------------------------------------------++
--|| ToLissAN_GetCompanyList() Get the company list from the sound folder ||
--++----------------------------------------------------------------------++
function ToLissAN_GetCompanyList()

    ToLissAN_Log("🟢 ---ToLissAN_GetCompanyList---")

    local cmd = "dir /b \"" .. ToLissAN.SoundsPackPath .. "\""
    local file = io.popen(cmd)
    local list = {}

    if file then
        for line in file:lines() do
            if line ~= "Common" then
                table.insert(list, line)
            end
        end
        file:close()
    end

    ToLissAN_Log("✅ Company list created")

    return list

end

--++--------------------------------------------------------------++
--|| M_UTILITIES.SetTimer() Return a time limit value for a timer ||
--++--------------------------------------------------------------++
function ToLissAN_SetTimer(time)
    return UTILITIES_TotalRunningTimeSec + time
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
            ToLissAN_Log("🟢 ---ToLissAN_CheckDataref---")
            ToLissAN_Log("📉 isPreflight = " .. tostring(ToLissAN.isPreflight))
        elseif DATAREF_TolissPhase == 1 then
            ToLissAN.isPreflight = false
            ToLissAN.isTakeoff = true
            ToLissAN_Log("📉 isTakeoff = " .. tostring(ToLissAN.isTakeoff))
        elseif DATAREF_TolissPhase == 2 then
            ToLissAN.isTakeoff = false
            ToLissAN.isClimb = true
            ToLissAN_Log("📉 isClimb = " .. tostring(ToLissAN.isClimb))
        elseif DATAREF_TolissPhase == 3 then
            ToLissAN.isClimb = false
            ToLissAN.isCruise = true
            ToLissAN_Log("📉 isCruise = " .. tostring(ToLissAN.isCruise))
        elseif DATAREF_TolissPhase == 4 then
            ToLissAN.isCruise = false
            ToLissAN.isDescent = true
            ToLissAN_Log("📉 isDescent = " .. tostring(ToLissAN.isDescent))
        elseif DATAREF_TolissPhase == 5 then
            ToLissAN.isDescent = false
            ToLissAN.isApproach = true
            ToLissAN_Log("📉 isApproach = " .. tostring(ToLissAN.isApproach))
        elseif DATAREF_TolissPhase == 6 then
            ToLissAN.isApproach = false
            ToLissAN.isGoAround = true
            ToLissAN_Log("📉 isGoAround = " .. tostring(ToLissAN.isGoAround))
        elseif DATAREF_TolissPhase == 7 then
            ToLissAN.isApproach = false
            ToLissAN.isGoAround = false
            ToLissAN.isDone = true
            ToLissAN_Log("📉 isLanding = " .. tostring(ToLissAN.isDone))
        end

        DATAREF_TolissPhaseBefore = DATAREF_TolissPhase
    end

    if ToLissAN.isPreflight and
      (DATAREF_Eng1SwitchOnBefore ~= DATAREF_Eng1SwitchOn or
       DATAREF_Eng2SwitchOnBefore ~= DATAREF_Eng2SwitchOn) then

        if DATAREF_Eng1SwitchOn == 1 or DATAREF_Eng2SwitchOn == 1 then
            ToLissAN.isAirbusStarted = true
        end

        DATAREF_Eng1SwitchOnBefore = DATAREF_Eng1SwitchOn
        DATAREF_Eng2SwitchOnBefore = DATAREF_Eng2SwitchOn
    end

    if ToLissAN.isTakeoff and
       DATAREF_IasCaptainBefore ~= DATAREF_IasCaptain then

        if DATAREF_IasCaptain > 95 then -- 100 kts
            ToLissAN.is100KtsReached = true
        end
        if DATAREF_IasCaptain > DATAREF_V1 then
            ToLissAN.isV1Reached = true
        end
        if DATAREF_IasCaptain > DATAREF_V2 then
            ToLissAN.isV2Reached = true
        end

        DATAREF_IasCaptainBefore = DATAREF_IasCaptain
    end

    if ToLissAN.isClimb and
       DATAREF_AltitudeCaptainBefore ~= DATAREF_AltitudeCaptain then

        if DATAREF_AltitudeCaptain > 10000 then
            ToLissAN.is10000FeetReached = true
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
            ToLissAN_Log("🔊 Playing Boarding_Ambience")
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
            ToLissAN_Log("🔊 Playing DoorsCrossCheck")
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
            ToLissAN_Log("🔊 Playing CptWelcome")
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
        ToLissAN_Log("🔊 Playing Safety")
        ToLissAN.SpecificSounds["Safety"].played = true
    end

    -----------------
    -- CPT TAKEOFF --
    -----------------
    if ToLissAN.isPreflight and not
       ToLissAN.CommonSounds["CptTakeoff"].played and
       ToLissAN.SpecificSounds["Safety"].played and
       DATAREF_StrobeLightOnBefore ~= DATAREF_StrobeLightOn then

        if DATAREF_StrobeLightOn == 2 then
            play_sound(ToLissAN.CommonSounds["CptTakeoff"].sound)
            ToLissAN_Log("🔊 Playing CptTakeoff")
            ToLissAN.CommonSounds["CptTakeoff"].played = true
        end

        DATAREF_StrobeLightOnBefore = DATAREF_StrobeLightOn
    end

    ----------------
    -- THRUST SET --
    ----------------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds["ThrustSet"].played then

        play_sound(ToLissAN.CommonSounds["ThrustSet"].sound)
        ToLissAN_Log("🔊 Playing ThrustSet")
        ToLissAN.CommonSounds["ThrustSet"].played = true

        --------------------------------------------
        -- Take the flaps set position at takeoff --
        --------------------------------------------
        DATAREF_FlapLeverRatioBefore = DATAREF_FlapLeverRatio
    end

    -------------
    -- 100 KTS --
    -------------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds["100kts"].played and
       ToLissAN.is100KtsReached then

        play_sound(ToLissAN.CommonSounds["100kts"].sound)
        ToLissAN_Log("🔊 Playing 100kts")
        ToLissAN.CommonSounds["100kts"].played = true
    end

    --------
    -- V1 --
    --------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds["V1"].played and
       ToLissAN.isV1Reached  then

        play_sound(ToLissAN.CommonSounds["V1"].sound)
        ToLissAN_Log("🔊 Playing V1")
        ToLissAN.CommonSounds["V1"].played = true
    end

    ------------------
    -- V2 OR ROTATE --
    ------------------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds["Rotate"].played and
       ToLissAN.isV2Reached  then

        play_sound(ToLissAN.CommonSounds["Rotate"].sound)
        ToLissAN_Log("🔊 Playing Rotate")
        ToLissAN.CommonSounds["Rotate"].played = true
    end

    --------------------
    -- POSITIVE CLIMB --
    --------------------
    if ToLissAN.isTakeoff and not
       ToLissAN.CommonSounds["PositiveClimb"].played and
       DATAREF_VviFpmPilot > 500 then

        play_sound(ToLissAN.CommonSounds["PositiveClimb"].sound)
        ToLissAN_Log("🔊 Playing PositiveClimb")
        ToLissAN.CommonSounds["PositiveClimb"].played = true
    end

    -------------
    -- GEAR UP --
    -------------
    if ToLissAN.isTakeoff and
       ToLissAN.CommonSounds["PositiveClimb"].played and not
       ToLissAN.CommonSounds["GearUp"].played and
       DATAREF_GearLever == 0 then

        play_sound(ToLissAN.CommonSounds["GearUp"].sound)
        ToLissAN_Log("🔊 Playing GearUp")
        ToLissAN.CommonSounds["GearUp"].played = true
    end

    -----------------------------
    -- FLAPS TAKEOFF OR CLIMB  --
    -----------------------------
    if (ToLissAN.isTakeoff or ToLissAN.isClimb) and
        DATAREF_FlapLeverRatioBefore ~= DATAREF_FlapLeverRatio then

        ToLissAN.CommonSounds["SpeedCheckFlap0"].played = false
        ToLissAN.CommonSounds["SpeedCheckFlap1"].played = false
        ToLissAN.CommonSounds["SpeedCheckFlap2"].played = false
        ToLissAN.CommonSounds["SpeedCheckFlap3"].played = false

        if DATAREF_FlapLeverRatio == 0 then
            if not ToLissAN.CommonSounds["SpeedCheckFlap0"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlap0"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlap0")
                ToLissAN.CommonSounds["SpeedCheckFlap0"].played = true
            end

        elseif DATAREF_FlapLeverRatio == 0.25 then
            if not ToLissAN.CommonSounds["SpeedCheckFlap1"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlap1"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlap1")
                ToLissAN.CommonSounds["SpeedCheckFlap1"].played = true
            end

        elseif DATAREF_FlapLeverRatio == 0.5 then
            if not ToLissAN.CommonSounds["SpeedCheckFlap2"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlap2"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlap2")
                ToLissAN.CommonSounds["SpeedCheckFlap2"].played = true
            end

        elseif DATAREF_FlapLeverRatio == 0.75 then
            if not ToLissAN.CommonSounds["SpeedCheckFlap3"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlap3"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlap3")
                ToLissAN.CommonSounds["SpeedCheckFlap3"].played = true
            end
        end
        DATAREF_FlapLeverRatioBefore = DATAREF_FlapLeverRatio
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
            ToLissAN_Log("🔊 Playing DutyFree")
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
        ToLissAN_Log("🔊 Playing CptCruiseLvl")
        ToLissAN.CommonSounds["CptCruiseLvl"].played = true
    end

    -------------------
    -- DESCENT REACH --
    -------------------
    if ToLissAN.isDescent and not
       ToLissAN.CommonSounds["CptDescent"].played  then

        play_sound(ToLissAN.CommonSounds["CptDescent"].sound)
        ToLissAN_Log("🔊 Playing CptDescent")
        ToLissAN.CommonSounds["CptDescent"].played = true

    end

    --------------------------------
    -- FLAPS DESCENT OR APPROACH  --
    --------------------------------
    if (ToLissAN.isDescent or ToLissAN.isApproach) and
        DATAREF_FlapLeverRatioBefore ~= DATAREF_FlapLeverRatio  then

        ToLissAN.CommonSounds["SpeedCheckFlap0"].played = false
        ToLissAN.CommonSounds["SpeedCheckFlap1"].played = false
        ToLissAN.CommonSounds["SpeedCheckFlap2"].played = false
        ToLissAN.CommonSounds["SpeedCheckFlap3"].played = false
        ToLissAN.CommonSounds["SpeedCheckFlapFull"].played = false

        if DATAREF_FlapLeverRatio == 0 then
            if not ToLissAN.CommonSounds["SpeedCheckFlap0"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlap0"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlap0")
                ToLissAN.CommonSounds["SpeedCheckFlap0"].played = true
            end

        elseif DATAREF_FlapLeverRatio == 0.25 then
            if not ToLissAN.CommonSounds["SpeedCheckFlap1"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlap1"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlap1")
                ToLissAN.CommonSounds["SpeedCheckFlap1"].played = true
            end

        elseif DATAREF_FlapLeverRatio == 0.5 then
            if not ToLissAN.CommonSounds["SpeedCheckFlap2"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlap2"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlap2")
                ToLissAN.CommonSounds["SpeedCheckFlap2"].played = true
            end

        elseif DATAREF_FlapLeverRatio == 0.75 then
            if not ToLissAN.CommonSounds["SpeedCheckFlap3"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlap3"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlap3")
                ToLissAN.CommonSounds["SpeedCheckFlap3"].played = true
            end

        elseif DATAREF_FlapLeverRatio == 1 then
            if not ToLissAN.CommonSounds["SpeedCheckFlapFull"].played then
                play_sound(ToLissAN.CommonSounds["SpeedCheckFlapFull"].sound)
                ToLissAN_Log("🔊 Playing SpeedCheckFlapFull")
                ToLissAN.CommonSounds["SpeedCheckFlapFull"].played = true
            end
        end
        DATAREF_FlapLeverRatioBefore = DATAREF_FlapLeverRatio
    end

    ---------------
    -- GEAR DOWN --
    ---------------
    if (ToLissAN.isDescent or ToLissAN.isApproach) and not
       ToLissAN.CommonSounds["GearDown"].played and
       DATAREF_GearLever == 1 then

        play_sound(ToLissAN.CommonSounds["GearDown"].sound)
        ToLissAN_Log("🔊 Playing GearDown")
        ToLissAN.CommonSounds["GearDown"].played = true
    end

    --------------------
    -- APPROACH REACH --
    --------------------
    if ToLissAN.isApproach and not
       ToLissAN.CommonSounds["CptLanding"].played  then

        play_sound(ToLissAN.CommonSounds["CptLanding"].sound)
        ToLissAN_Log("🔊 Playing CptLanding")
        ToLissAN.CommonSounds["CptLanding"].played = true
    end

    -------------------
    -- REVERSE GREEN --
    -------------------
    --[[
    if ToLissAN.isApproach and not
       ToLissAN.CommonSounds["ReverseGreen"].played and
       DATAREF_Engine1ReverserDeloyment == 1 and
       DATAREF_Engine2ReverserDeloyment == 1 then

        play_sound(ToLissAN.CommonSounds["ReverseGreen"].sound)
        ToLissAN.CommonSounds["ReverseGreen"].played = true
    end
    ]]

    --------------
    -- SPOILERS --
    --------------
    if ToLissAN.isApproach and not
       ToLissAN.CommonSounds["Spoilers"].played and
       ToLissAN.CommonSounds["CptLanding"].played and
       DATAREF_RadioAltimeterHeightPilot < 3 and
       DATAREF_Spoiler0 == 1 and
       DATAREF_Spoiler1 == 1 then

        play_sound(ToLissAN.CommonSounds["Spoilers"].sound)
        ToLissAN_Log("🔊 Playing Spoilers")
        ToLissAN.CommonSounds["Spoilers"].played = true

        if DATAREF_AutoBrkLo == 1 then
            ToLissAN.TimerSpoilers = ToLissAN_SetTimer(4)
        elseif DATAREF_AutoBrkMed == 1 then
            ToLissAN.TimerSpoilers = ToLissAN_SetTimer(2)
        end
    end

    -----------
    -- DECEL --
    -----------
    if ToLissAN.isApproach and not
       ToLissAN.CommonSounds["Decel"].played and
       ToLissAN.CommonSounds["Spoilers"].played and
       DATAREF_RadioAltimeterHeightPilot < 3 and
       UTILITIES_TotalRunningTimeSec > ToLissAN.TimerSpoilers then

        play_sound(ToLissAN.CommonSounds["Decel"].sound)
        ToLissAN_Log("🔊 Playing Decel")
        ToLissAN.CommonSounds["Decel"].played = true
    end

    ------------
    -- 70 KTS --
    ------------
    if ToLissAN.isApproach and not
       ToLissAN.CommonSounds["70kts"].played and
       DATAREF_RadioAltimeterHeightPilot < 3 and
       DATAREF_IasCaptain < 70 then

        play_sound(ToLissAN.CommonSounds["70kts"].sound)
        ToLissAN_Log("🔊 Playing 70kts")
        ToLissAN.CommonSounds["70kts"].played = true
        ToLissAN.CommonSounds["Boarding_Ambience"].played = false
    end

    -------------------------
    -- DEBOARDING AMBIENCE --
    -------------------------
    if ToLissAN.isDone and not
       ToLissAN.CommonSounds["Boarding_Ambience"].played and
       ToLissAN.CommonSounds["70kts"].played and
       DATAREF_SeatBeltSignsOn == 0 then

        play_sound(ToLissAN.CommonSounds["Boarding_Ambience"].sound)
        ToLissAN_Log("🔊 Playing Boarding_Ambience")
        ToLissAN.CommonSounds["Boarding_Ambience"].played = true
        ToLissAN_Log("✅ Ending Sound playing")
    end
end

--++------------------------------------------------------------++
--|| ToLissAN_LoadDatarefsForEvents() Load datarefs for events  ||
--++------------------------------------------------------------++
function ToLissAN_LoadDatarefsForEvents()

    ToLissAN_Log("🟢 ---ToLissAN_LoadDatarefsForEvents---")

    DataRef("UTILITIES_TotalRunningTimeSec","sim/time/total_running_time_sec","readonly")

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

    DataRef("DATAREF_SeatBeltSignsOn","AirbusFBW/SeatBeltSignsOn","readonly")
    DATAREF_SeatBeltSignsOnBefore = -1

    DataRef("DATAREF_GearLever","AirbusFBW/GearLever","readonly")
    DATAREF_GearLeverBefore = -1

    DataRef("DATAREF_FlapRequestPos","AirbusFBW/FlapRequestPos","readonly")
    DATAREF_FlapRequestPosBefore = -1

    DataRef("DATAREF_FlapLeverRatio","AirbusFBW/FlapLeverRatio","readonly")
    DATAREF_FlapLeverRatioBefore = -1

    DataRef("DATAREF_V1","toliss_airbus/performance/V1","readonly")
    DATAREF_V1Before = -1

    DataRef("DATAREF_V2","toliss_airbus/performance/V2","readonly")
    DATAREF_V2Before = -1

    DataRef("DATAREF_RadioAltimeterHeightPilot","sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot","readonly")
    DATAREF_RadioAltimeterHeightPilotBefore = -1

    DataRef("DATAREF_IasCaptain","AirbusFBW/IASCapt","readonly")
    DATAREF_IasCaptainBefore = -1

    DataRef("DATAREF_VviFpmPilot","sim/cockpit2/gauges/indicators/vvi_fpm_pilot","readonly")
    DATAREF_VviFpmPilotBefore = -1

    DataRef("DATAREF_AltitudeCaptain","AirbusFBW/ALTCapt","readonly")
    DATAREF_AltitudeCaptainBefore = -1

    DataRef("DATAREF_Engine1ReverserDeloyment","AirbusFBW/EngineReverserDeloymentArray","readonly",0)
    DATAREF_Engine1ReverserDeloymentBefore = -1

    DataRef("DATAREF_Engine2ReverserDeloyment","AirbusFBW/EngineReverserDeloymentArray","readonly",1)
    DATAREF_Engine2ReverserDeloymentBefore = -1

    DataRef("DATAREF_Spoiler0","AirbusFBW/SDSpoilerArray","readonly",0)
    DATAREF_DATAREF_Spoiler0Before = -1

    DataRef("DATAREF_Spoiler1","AirbusFBW/SDSpoilerArray","readonly",1)
    DATAREF_DATAREF_Spoiler1Before = -1

    DataRef("DATAREF_AutoBrkLo","AirbusFBW/AutoBrkLo","readonly",1)
    DATAREF_AutoBrkLoBefore = -1

    DataRef("DATAREF_AutoBrkMed","AirbusFBW/AutoBrkMed","readonly",1)
    DATAREF_AutoBrkMedBefore = -1

    DataRef("DATAREF_TolissPhase","AirbusFBW/APPhase","readonly")
    DATAREF_TolissPhaseBefore = -1

    ToLissAN_Log("✅ Datarefs loaded")

end

--++---------------------------------------------------------------------------++
--|| ToLissAN_LoadSpecificSoundsForCompany() Load specific sounds from company ||
--++---------------------------------------------------------------------------++
function ToLissAN_LoadSpecificSoundsForCompany(company)

    ToLissAN_Log("🟢 ---ToLissAN_LoadSpecificSoundsForCompany---")

    local sounds = {
        Safety = "Safety.wav"
    }

    for name, file in pairs(sounds) do
        pcall(function()
            if ToLissAN.SpecificSounds[name] and ToLissAN.SpecificSounds[name].sound then
                stop_sound(ToLissAN.SpecificSounds[name].sound)
                replace_WAV_file(ToLissAN.SpecificSounds[name].sound, ToLissAN.SoundsPackPath .. "/" .. company .. "/" .. file)
                ToLissAN_Log("📢 Previous company '" .. name .. "' sound, stopped and replaced successfully.")
            end
        end)
        ToLissAN.SpecificSounds[name] = {
            file = ToLissAN.SoundsPackPath .. "/" .. company .. "/" .. file,
            sound = load_WAV_file(ToLissAN.SoundsPackPath .. "/" .. company .. "/" .. file),
            played = false,
        }
    end

    ToLissAN_Log("✅ Specific Sounds loaded for : " .. company)

end

--++----------------------------------------------------------------------++
--|| ToLissAN_LoadCommonSoundsForCompany() Load common sounds for company ||
--++----------------------------------------------------------------------++
function ToLissAN_LoadCommonSoundsForCompany()

    -- Safety.wav treated in ToLissAN_LoadSpecificSoundsForCompany()

    ToLissAN_Log("🟢 ---ToLissAN_LoadCommonSoundsForCompany---")

    local sounds = {
        Boarding_Ambience       = "Boarding_Ambience.wav",
        DoorsCrossCheck         = "DoorsCrossCheck.wav",
        CptWelcome              = "CptWelcome.wav", -- after this, play SAFETY ANNONCE --
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
        ReverseGreen            = "ReverseGreen.wav",
        Spoilers                = "SpoilersLoad.wav",
        Decel                   = "DecelLoud.wav",
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

--++-----------------------------------------------------------------++
--|| TolissAN_SetDefaultValues() Set default values for this program ||
--++-----------------------------------------------------------------++
function TolissAN_SetDefaultValues()

    ToLissAN_Log("🟢 ---TolissAN_SetDefaultValues---")

    ToLissAN.SoundsPackPath = SCRIPT_DIRECTORY .. "ToLissAN_sounds"

    ToLissAN.SelectedCompanyName = "AirCanada" -- Default Company for sound
    ToLissAN.Company = 1 -- For the selected drop down list
    ToLissAN.CompanyList = {} -- For the selected drop down list
    ToLissAN.CommonSounds = {} -- List for Common sounds for company
    ToLissAN.SpecificSounds = {} -- List for Specific sounds for company
    ToLissAN.Datarefs = {} -- List of dataref for monitoring

    ToLissAN.TimerSpoilers = 0 -- Timer for Spoilers

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
    ToLissAN.isGoAround = false
    ToLissAN.isDone = false
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

    ToLissAN_Log("🟢 ---ToLissAN_Initialization---")

    TolissAN_SetDefaultValues()
    ToLissAN.CompanyList = ToLissAN_GetCompanyList()

    ToLissAN.Windows = float_wnd_create(300, 100, 1, true)
    float_wnd_set_title(ToLissAN.Windows, "ToLissAN - Select a company")
    float_wnd_set_imgui_builder(ToLissAN.Windows, "ToLissAN_CreateCompanyCombo")
    float_wnd_set_onclose(ToLissAN.Windows, "ToLissAN_CloseCompanySelectionWindow")

    ToLissAN_LoadCommonSoundsForCompany()
    ToLissAN_LoadSpecificSoundsForCompany(ToLissAN.SelectedCompanyName)
    ToLissAN_LoadDatarefsForEvents()

    ToLissAN_Log("✅ Initialization done")

end

--+====================================================================+
--|       T H E   F O L L O W I N G   I S   T H E    M A I N           |
--|                          S E C T I O N                             |
--+====================================================================+
if  (string.lower(PLANE_AUTHOR) == "gliding kiwi") or
    (string.lower(PLANE_AUTHOR) == "glidingkiwi") then

    ToLissAN_Log("🆗 Start ToLissAN program for Toliss " .. PLANE_ICAO)

    ToLissAN_Initialization()

    XPLMSpeakString("Welcome to the Toliss Announcement Program, Please, Select a company from this company selected list")

    do_every_frame("ToLissAN_CheckDataref()")
    do_every_draw("ToLissAN_ShowSelectedCompany()")

end