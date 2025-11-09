script_name("phobos")
script_author("haunt")
script_version("11.9.2025")
local enable_autoupdate = true -- false to disable auto-update + disable sending initial telemetry (server, moonloader version, script version, samp nickname, virtual volume serial number)
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/deobfuscateme/testt/refs/heads/main/testt/version.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/deobfuscateme/testt/"
        end
    end
end
require "lib.moonloader"

local imgui = require "mimgui"
local ffi = require "ffi"
local sampev = require "lib.samp.events"
local key = require "vkeys"
local inicfg = require "inicfg"
local encoding = require "encoding"
local memory = require "memory"
local lfs = require "lfs"
local Matrix3X3 = require "matrix3x3"
local Vector3D = require "vector3d"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local original_extraws_bytes = {}
local original_crosshair_byte = nil
local nospread_original_values = {}
local initialization_done = false
local extraws_addresses = {0x5109AC, 0x5109C5, 0x5231A6, 0x52322D, 0x5233BA}
local nospread_addresses = {spread_for_non_shotguns = 0x8D6110, spread_for_shotguns = 0x8D611C}
local ADDR_PLAYER_PED = 0xB6F5F0

local config = {
    main = {
        input_id = 0, input_text = "", input_countdown = 0, input_count = 1,
        input_delay = 0, selected_mode = 0, enabled_oz = false, active_tab = 0,
        enabled_wallhack = false,
        enabled_extraws = false, enabled_show_crosshair = false, enabled_autoc = false,
        enabled_capt_spammer = false,
        outmapper_timeout = 7.0,
        enabled_antimask = false,
        enabled_rollerfix = false,
        enabled_nospread = false,
        enabled_fullskill = false,
        enabled_autobike = false,
        enabled_nobike = false,
        enabled_clickwarp = false,
        enabled_inf_fuel = false,
        enabled_skin_changer = false,
        skin_changer_id = 0,
        enabled_antieject = false,
        enabled_attachcars = false,
        enabled_cargm = false,
        enabled_wheelgm = false,
        enabled_surfing = false,
        enabled_antidriverkill = false,
        enabled_antidriveby = false,
        enabled_antistun = false,
        enabled_camhack = false,
        enabled_airbrake = false,
        airbrake_speed_onfoot = 0.7,
        airbrake_speed_incar = 0.7,
        airbrake_speed_passenger = 0.7,
        enabled_infrun = false,
        enabled_crouchhook = false,
    }
}
local config_dir = getWorkingDirectory() .. "/config"
local config_path = config_dir .. "/phobos.ini"

if not doesDirectoryExist(config_dir) then
    lfs.mkdir(config_dir)
end

local state = {
    main_window_state = imgui.new.bool(false),
    input_id = imgui.new.int(0),
    input_text = imgui.new.char[256](''),
    input_countdown = imgui.new.int(0),
    input_count = imgui.new.int(1),
    input_delay = imgui.new.int(0),
    selected_mode = imgui.new.int(0),
    active_tab = imgui.new.int(0),
    enabled_oz = imgui.new.bool(false),
    enabled_wallhack = imgui.new.bool(false),
    enabled_extraws = imgui.new.bool(false),
    enabled_show_crosshair = imgui.new.bool(false),
    enabled_autoc = imgui.new.bool(false),
    enabled_capt_spammer = imgui.new.bool(false),
    outmapper_timeout = imgui.new.float(7.0),
    stuff_weather = imgui.new.int(10),
    stuff_time = imgui.new.int(12),
    enabled_antimask = imgui.new.bool(false),
    enabled_rollerfix = imgui.new.bool(false),
    enabled_nospread = imgui.new.bool(false),
    enabled_fullskill = imgui.new.bool(false),
    enabled_autobike = imgui.new.bool(false),
    enabled_nobike = imgui.new.bool(false),
    enabled_clickwarp = imgui.new.bool(false),
    enabled_inf_fuel = imgui.new.bool(false),
    enabled_skin_changer = imgui.new.bool(false),
    skin_changer_id = imgui.new.int(0),
    enabled_antieject = imgui.new.bool(false),
    enabled_attachcars = imgui.new.bool(false),
    enabled_cargm = imgui.new.bool(false),
    enabled_wheelgm = imgui.new.bool(false),
    enabled_surfing = imgui.new.bool(false),
    enabled_antidriverkill = imgui.new.bool(false),
    enabled_antidriveby = imgui.new.bool(false),
    enabled_antistun = imgui.new.bool(false),
    enabled_camhack = imgui.new.bool(false),
    enabled_airbrake = imgui.new.bool(false),
    airbrake_speed_onfoot = imgui.new.float(0.7),
    airbrake_speed_incar = imgui.new.float(0.7),
    airbrake_speed_passenger = imgui.new.float(0.7),
    enabled_infrun = imgui.new.bool(false),
    enabled_crouchhook = imgui.new.bool(false),
}

local cheat = { outmapper = { state = false, started = 0, last_eject = 0, passengers = {} } }
local modes = {"SMS", "Chat", "Yvirili", "Admin", "VIP AD"}
local tabs = {u8"General", u8"Outmapper", u8"Stuff", u8"FakeMSG", u8"Settings"}
local modes_array = imgui.new["const char*"][#modes](modes)

local clickwarp_font, clickwarp_font2 = nil, nil
local clickwarp_cursor_enabled = false
local clickwarp_point_marker = nil
local autobike_bike = {[481] = true, [509] = true, [510] = true}
local autobike_moto = {[448] = true, [461] = true, [462] = true, [463] = true, [468] = true, [471] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true}
local camhack_mode = 0
local camhack_speed = 1.0
local camhack_posX, camhack_posY, camhack_posZ = 0, 0, 0
local camhack_angZ, camhack_angY = 0, 0
local is_airbrake_active = false
local airbrake_coords = {0, 0, 0}
local airbrake_sync = 0

function toggle_extraws(state_bool)
    for _, address in ipairs(extraws_addresses) do
        if original_extraws_bytes[address] then
            if state_bool then memory.write(address, 235, 1, true) else memory.write(address, original_extraws_bytes[address], 1, true) end
        end
    end
end

function toggle_show_crosshair(state_bool)
    if original_crosshair_byte then
        if state_bool then memory.write(0x0058E1D9, 0xEB, 1, true) else memory.write(0x0058E1D9, original_crosshair_byte, 1, true) end
    end
end

function nameTagOn()
    local sSp = sampGetServerSettingsPtr()
    if sSp and sSp ~= 0 then
        memory.setfloat(sSp + 39, 1200); memory.setint8(sSp + 47, 0); memory.setint8(sSp + 56, 1)
    end
end

function nameTagOff()
    local sSp = sampGetServerSettingsPtr()
    if sSp and sSp ~= 0 then
        memory.setfloat(sSp + 39, 25.5); memory.setint8(sSp + 47, 1); memory.setint8(sSp + 56, 1)
    end
end

function toggle_wallhack(state_bool)
    if state_bool then
        nameTagOn(); addOneOffSound(0, 0, 0, 1139); sampAddChatMessage("{00FF00}[phobos]: {FFFFFF}Wallhack ON.", -1)
    else
        nameTagOff(); addOneOffSound(0, 0, 0, 1139); sampAddChatMessage("{FF0000}[phobos]: {FFFFFF}Wallhack OFF.", -1)
    end
end

function set_player_skin(id, skin)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id)
    raknetBitStreamWriteInt32(bs, skin)
    raknetEmulRpcReceiveBitStream(153, bs)
    raknetDeleteBitStream(bs)
end

function toggle_nospread(state_bool)
    if state_bool then
        memory.setfloat(nospread_addresses.spread_for_non_shotguns, 0.0, true)
        memory.setfloat(nospread_addresses.spread_for_shotguns, 0.0, true)
    else
        if nospread_original_values.non_shotgun then
            memory.setfloat(nospread_addresses.spread_for_non_shotguns, nospread_original_values.non_shotgun, true)
        end
        if nospread_original_values.shotgun then
            memory.setfloat(nospread_addresses.spread_for_shotguns, nospread_original_values.shotgun, true)
        end
    end
end

function imgui.DarkTheme()
    imgui.SwitchContext()
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5); imgui.GetStyle().FramePadding = imgui.ImVec2(5, 2)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5); imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(5, 5); imgui.GetStyle().IndentSpacing = 5
    imgui.GetStyle().ScrollbarSize = 10; imgui.GetStyle().GrabMinSize = 10
    imgui.GetStyle().WindowBorderSize = 1; imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1; imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1; imgui.GetStyle().WindowRounding = 5
    imgui.GetStyle().ChildRounding = 5; imgui.GetStyle().FrameRounding = 5
    imgui.GetStyle().PopupRounding = 5; imgui.GetStyle().ScrollbarRounding = 5
    imgui.GetStyle().GrabRounding = 5; imgui.GetStyle().TabRounding = 5
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5); imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    local colors = imgui.GetStyle().Colors; colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.50, 0.50, 0.50, 1.00); colors[imgui.Col.WindowBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00); colors[imgui.Col.PopupBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    colors[imgui.Col.Border] = imgui.ImVec4(0.25, 0.25, 0.26, 0.54); colors[imgui.Col.FrameBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00); colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00); colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.CheckMark] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00); colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00); colors[imgui.Col.Button] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00); colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[imgui.Col.Header] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00); colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.47, 0.47, 0.47, 1.00); colors[imgui.Col.Tab] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.TabHovered] = imgui.ImVec4(0.28, 0.28, 0.28, 1.00); colors[imgui.Col.TabActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
end

imgui.OnInitialize(function() imgui.GetIO().IniFilename = nil; imgui.DarkTheme() end)

function load_config_and_init_features()
    if doesFileExist(config_path) then
        local loaded_ini = inicfg.load(nil, config_path)
        if loaded_ini and type(loaded_ini.main) == "table" then
            for k, v in pairs(loaded_ini.main) do
                if config.main[k] ~= nil then
                    config.main[k] = v
                end
            end
        end
    end
    
    state.input_id[0] = config.main.input_id; ffi.copy(state.input_text, u8:decode(config.main.input_text))
    state.input_countdown[0] = config.main.input_countdown; state.input_count[0] = config.main.input_count
    state.input_delay[0] = config.main.input_delay; state.selected_mode[0] = config.main.selected_mode
    state.active_tab[0] = config.main.active_tab; state.enabled_oz[0] = config.main.enabled_oz
    state.enabled_wallhack[0] = config.main.enabled_wallhack; state.enabled_extraws[0] = config.main.enabled_extraws
    state.enabled_show_crosshair[0] = config.main.enabled_show_crosshair; state.enabled_autoc[0] = config.main.enabled_autoc
    state.enabled_capt_spammer[0] = config.main.enabled_capt_spammer; state.outmapper_timeout[0] = config.main.outmapper_timeout
    
    state.enabled_antimask[0] = config.main.enabled_antimask
    state.enabled_rollerfix[0] = config.main.enabled_rollerfix
    state.enabled_nospread[0] = config.main.enabled_nospread
    state.enabled_fullskill[0] = config.main.enabled_fullskill
    state.enabled_autobike[0] = config.main.enabled_autobike
    state.enabled_nobike[0] = config.main.enabled_nobike
    state.enabled_clickwarp[0] = config.main.enabled_clickwarp
    state.enabled_inf_fuel[0] = config.main.enabled_inf_fuel
    state.enabled_skin_changer[0] = config.main.enabled_skin_changer
    state.skin_changer_id[0] = config.main.skin_changer_id
    state.enabled_antieject[0] = config.main.enabled_antieject
    state.enabled_attachcars[0] = config.main.enabled_attachcars
    state.enabled_cargm[0] = config.main.enabled_cargm
    state.enabled_wheelgm[0] = config.main.enabled_wheelgm
    state.enabled_surfing[0] = config.main.enabled_surfing
    state.enabled_antidriverkill[0] = config.main.enabled_antidriverkill
    state.enabled_antidriveby[0] = config.main.enabled_antidriveby
    state.enabled_antistun[0] = config.main.enabled_antistun
    state.enabled_camhack[0] = config.main.enabled_camhack
    state.enabled_airbrake[0] = config.main.enabled_airbrake
    state.airbrake_speed_onfoot[0] = config.main.airbrake_speed_onfoot
    state.airbrake_speed_incar[0] = config.main.airbrake_speed_incar
    state.airbrake_speed_passenger[0] = config.main.airbrake_speed_passenger
    state.enabled_infrun[0] = config.main.enabled_infrun
    state.enabled_crouchhook[0] = config.main.enabled_crouchhook

    state.stuff_weather[0] = memory.getint8(0xC81320); state.stuff_time[0] = memory.getint8(0xB70153)
end

function save_config_all()
    config.main.input_id = state.input_id[0]; config.main.input_text = u8:encode(ffi.string(state.input_text))
    config.main.input_countdown = state.input_countdown[0]; config.main.input_count = state.input_count[0]
    config.main.input_delay = state.input_delay[0]; config.main.selected_mode = state.selected_mode[0]
    config.main.active_tab = state.active_tab[0]; config.main.enabled_oz = state.enabled_oz[0]
    config.main.enabled_wallhack = state.enabled_wallhack[0]; config.main.enabled_extraws = state.enabled_extraws[0]
    config.main.enabled_show_crosshair = state.enabled_show_crosshair[0]; config.main.enabled_autoc = state.enabled_autoc[0]
    config.main.enabled_capt_spammer = state.enabled_capt_spammer[0]; config.main.outmapper_timeout = state.outmapper_timeout[0]
    
    config.main.enabled_antimask = state.enabled_antimask[0]
    config.main.enabled_rollerfix = state.enabled_rollerfix[0]
    config.main.enabled_nospread = state.enabled_nospread[0]
    config.main.enabled_fullskill = state.enabled_fullskill[0]
    config.main.enabled_autobike = state.enabled_autobike[0]
    config.main.enabled_nobike = state.enabled_nobike[0]
    config.main.enabled_clickwarp = state.enabled_clickwarp[0]
    config.main.enabled_inf_fuel = state.enabled_inf_fuel[0]
    config.main.enabled_skin_changer = state.enabled_skin_changer[0]
    config.main.skin_changer_id = state.skin_changer_id[0]
    config.main.enabled_antieject = state.enabled_antieject[0]
    config.main.enabled_attachcars = state.enabled_attachcars[0]
    config.main.enabled_cargm = state.enabled_cargm[0]
    config.main.enabled_wheelgm = state.enabled_wheelgm[0]
    config.main.enabled_surfing = state.enabled_surfing[0]
    config.main.enabled_antidriverkill = state.enabled_antidriverkill[0]
    config.main.enabled_antidriveby = state.enabled_antidriveby[0]
    config.main.enabled_antistun = state.enabled_antistun[0]
    config.main.enabled_camhack = state.enabled_camhack[0]
    config.main.enabled_airbrake = state.enabled_airbrake[0]
    config.main.airbrake_speed_onfoot = state.airbrake_speed_onfoot[0]
    config.main.airbrake_speed_incar = state.airbrake_speed_incar[0]
    config.main.airbrake_speed_passenger = state.airbrake_speed_passenger[0]
    config.main.enabled_infrun = state.enabled_infrun[0]
    config.main.enabled_crouchhook = state.enabled_crouchhook[0]
    
    pcall(inicfg.save, config, config_path)
end

function render_settings_tab()
    imgui.Text("This tab is for general script settings.")
    imgui.Separator()
    imgui.Text("Menu Hotkey is hardcoded to: Alt + E")
    imgui.Separator()
    if imgui.Button("Save Settings", imgui.ImVec2(imgui.GetWindowWidth() * 0.45, 0)) then
        save_config_all()
        sampAddChatMessage("{00FF00}[phobos]:{FFFFFF} Settings saved.", -1)
    end
    imgui.SameLine()
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 1.0)); imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.9, 0.3, 0.3, 1.0)); imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1.0, 0.2, 0.2, 1.0))
    if imgui.Button("PANIC (Unload Script)", imgui.ImVec2(imgui.GetWindowWidth() * 0.45, 0)) then
        lua_thread.create(function() thisScript():unload() end)
    end
    imgui.PopStyleColor(3)
end

function main()
    while not isSampAvailable() do wait(100) end
    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.url)
    end

    for _, address in ipairs(extraws_addresses) do original_extraws_bytes[address] = memory.read(address, 1, false) end
    original_crosshair_byte = memory.read(0x0058E1D9, 1, false)
    nospread_original_values.non_shotgun = memory.getfloat(nospread_addresses.spread_for_non_shotguns, true)
    nospread_original_values.shotgun = memory.getfloat(nospread_addresses.spread_for_shotguns, true)

    load_config_and_init_features()
    sampRegisterChatCommand("fafa", function() state.main_window_state[0] = not state.main_window_state[0] end)
    
    clickwarp_font = renderCreateFont("Tahoma", 10, 5)
    clickwarp_font2 = renderCreateFont("Arial", 8, 5)

    imgui.OnFrame(
        function() return state.main_window_state[0] end,
        function()
            pcall(save_config_all)

            imgui.SetNextWindowPos(imgui.ImVec2(imgui.GetIO().DisplaySize.x / 2, imgui.GetIO().DisplaySize.y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(520, 389), imgui.Cond.FirstUseEver)
            imgui.Begin(u8"phobos", state.main_window_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.MenuBar)
            if imgui.BeginMenuBar() then for i, name in ipairs(tabs) do if imgui.MenuItemBool(name) then state.active_tab[0] = i - 1 end end; imgui.EndMenuBar() end
            
            if state.active_tab[0] == 0 then -- General TAB
                imgui.Columns(3, 'misc_cols', false)
                if imgui.Checkbox(u8"ExtraWS", state.enabled_extraws) then toggle_extraws(state.enabled_extraws[0]) end
                if imgui.Checkbox(u8"ShowCrosshairInstantly", state.enabled_show_crosshair) then toggle_show_crosshair(state.enabled_show_crosshair[0]) end
                if imgui.Checkbox(u8"Wallhack", state.enabled_wallhack) then toggle_wallhack(state.enabled_wallhack[0]) end
                if imgui.Checkbox(u8"NoSpread", state.enabled_nospread) then toggle_nospread(state.enabled_nospread[0]) end
                imgui.Checkbox(u8"AntiMask", state.enabled_antimask)
                imgui.Checkbox(u8"RollerFix", state.enabled_rollerfix)
                imgui.Checkbox(u8"Auto +C", state.enabled_autoc)
                imgui.Checkbox(u8"AntiStun", state.enabled_antistun)
                imgui.Checkbox(u8"CamHack", state.enabled_camhack)
                imgui.NextColumn()
                imgui.Checkbox(u8"Green Zone Bypass", state.enabled_oz)
                imgui.Checkbox(u8"Full Skill", state.enabled_fullskill)
                imgui.Checkbox(u8"Auto Bike", state.enabled_autobike)
                imgui.Checkbox(u8"NoBike", state.enabled_nobike)
                imgui.Checkbox(u8"ClickWarp", state.enabled_clickwarp)
                imgui.Checkbox(u8"Infinite Fuel", state.enabled_inf_fuel)
                imgui.Checkbox(u8"CarGM", state.enabled_cargm)
                imgui.Checkbox(u8"WheelGM", state.enabled_wheelgm)
                imgui.Checkbox(u8"Infinite Run", state.enabled_infrun)
                imgui.NextColumn()
                imgui.Checkbox(u8"AntiEject", state.enabled_antieject)
                imgui.Checkbox(u8"AttachCars", state.enabled_attachcars)
                imgui.Checkbox(u8"SurfOnVehicle", state.enabled_surfing)
                imgui.Checkbox(u8"AntiDriverKill", state.enabled_antidriverkill)
                imgui.Checkbox(u8"AntiDriveBy", state.enabled_antidriveby)
                imgui.Checkbox(u8"CrouchHook", state.enabled_crouchhook)
                imgui.Checkbox(u8"SkinChanger", state.enabled_skin_changer)
                imgui.PushItemWidth(80); imgui.InputInt(u8"Skin ID", state.skin_changer_id); imgui.PopItemWidth(); imgui.SameLine()
                if imgui.Button(u8"Apply") then
                    if state.skin_changer_id[0] >= 0 then
                        local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                        set_player_skin(id, state.skin_changer_id[0])
                    end
                end
                if imgui.Checkbox(u8"Capt Flooder", state.enabled_capt_spammer) and state.enabled_capt_spammer[0] then
                    lua_thread.create(function()
                        while state.enabled_capt_spammer[0] do
                            sampAddChatMessage("capt", -1)
                            wait(200)
                        end
                    end)
                end
                
                imgui.Columns(1); imgui.Separator()
                if imgui.Button(u8"Teleport to Marker", imgui.ImVec2(245, 0)) then local b, x, y, z = getTargetBlipCoordinates(); if b then setCharCoordinates(PLAYER_PED, x, y, z) end end
                imgui.SameLine()
                if imgui.Button(u8"Kill Self", imgui.ImVec2(245, 0)) then setCharHealth(PLAYER_PED, 0.0) end
                imgui.Checkbox("AirBrake", state.enabled_airbrake)
                if state.enabled_airbrake[0] then
                    imgui.Text('Speed Settings')
                    imgui.PushItemWidth(-1)
                    imgui.SliderFloat("On Foot##airbrake", state.airbrake_speed_onfoot, 0.1, 5.0, "%.1f")
                    imgui.SliderFloat("In Car##airbrake", state.airbrake_speed_incar, 0.1, 5.0, "%.1f")
                    imgui.SliderFloat("As Passenger##airbrake", state.airbrake_speed_passenger, 0.1, 5.0, "%.1f")
                    imgui.PopItemWidth()
                end
            elseif state.active_tab[0] == 1 then
                imgui.Text(u8"Outmapper"); imgui.Separator()
                if imgui.Button(u8"Eject All Passengers", imgui.ImVec2(-1, 0)) then if isCharInAnyCar(PLAYER_PED) and getDriverOfCar(getCarCharIsUsing(PLAYER_PED)) == PLAYER_PED then cheat.outmapper.state = true; cheat.outmapper.started = os.clock(); cheat.outmapper.last_eject = 0.0; cheat.outmapper.passengers = {}; sampAddChatMessage("[Outmapper] Activated.", 0x00FF00) else sampAddChatMessage("[Outmapper] You must be the driver.", 0xFF0000) end end
                imgui.SliderFloat(u8"Eject Timeout##outmapper", state.outmapper_timeout, 1.0, 20.0, "%.1fs")
            elseif state.active_tab[0] == 2 then
                imgui.Text(u8"World Modifiers"); imgui.Separator()
                if imgui.SliderInt(u8"Weather", state.stuff_weather, 0, 45) then memory.setint8(0xC81320, state.stuff_weather[0], true) end
                if imgui.SliderInt(u8"Time (Hour)", state.stuff_time, 0, 23) then memory.setint8(0xB70153, state.stuff_time[0], true); memory.setint8(0xB70152, 0, true) end
            elseif state.active_tab[0] == 3 then
                imgui.InputInt(u8"ID", state.input_id); imgui.InputText(u8"Teqsti", state.input_text, 256); imgui.InputInt(u8"Countdown", state.input_countdown); imgui.InputInt(u8"Count", state.input_count); imgui.InputInt(u8"Delay", state.input_delay); imgui.Combo(u8"Mode", state.selected_mode, modes_array, #modes)
                if imgui.Button(u8"Send", imgui.ImVec2(100, 0)) then
                    local id, text, countdown, count, delay, mode = state.input_id[0], u8:encode(ffi.string(state.input_text)), state.input_countdown[0], state.input_count[0], state.input_delay[0], modes[state.selected_mode[0] + 1]:lower()
                    lua_thread.create(function() if countdown > 0 then wait(countdown * 1000) end; for i = 1, count do if sampIsPlayerConnected(id) then if mode == "sms" then sendFakeSMS(id, text) elseif mode == "chat" then sendFakeChat(id, text) elseif mode == "yvirili" then sendFakeScream(id, text) elseif mode == "admin" then sendFakeB(id, text) elseif mode == "vip ad" then sendFakeVipAd(id, text) end end; if i < count and delay > 0 then wait(delay * 1000) end end end)
                end
            elseif state.active_tab[0] == 4 then render_settings_tab()
            end
            imgui.End()
        end
    )
    
    while true do
        wait(0)

        if not initialization_done and isSampAvailable() and sampIsLocalPlayerSpawned() then
            initialization_done = true
            
            lua_thread.create(function()
                wait(3000)
                pcall(function()
                    toggle_extraws(state.enabled_extraws[0])
                    toggle_show_crosshair(state.enabled_show_crosshair[0])
                    toggle_wallhack(state.enabled_wallhack[0])
                    toggle_nospread(state.enabled_nospread[0])
                end)
            end)
        end
        
        if isKeyDown(key.VK_MENU) and isKeyJustPressed(key.VK_E) then state.main_window_state[0] = not state.main_window_state[0] end
        if state.enabled_autoc[0] and isKeyDown(key.VK_F) and isKeyJustPressed(key.VK_RBUTTON) then RunC(50); while isKeyDown(key.VK_F) do wait(0) end end
        if cheat.outmapper.state then
            local car = isCharInAnyCar(PLAYER_PED) and getCarCharIsUsing(PLAYER_PED) or nil
            if not car or os.clock() - cheat.outmapper.started > state.outmapper_timeout[0] or getDriverOfCar(car) ~= PLAYER_PED then cheat.outmapper.state = false
            elseif (os.clock() - cheat.outmapper.last_eject > 1.0 and os.clock() - cheat.outmapper.started > 0.3) then
                for _, ped in ipairs(getAllChars()) do
                    if ped ~= PLAYER_PED and isCharInCar(ped, car) then local res, id = sampGetPlayerIdByCharHandle(ped); if res and (not cheat.outmapper.passengers[id] or os.clock() - cheat.outmapper.passengers[id] > 3.0) then cheat.outmapper.passengers[id] = os.clock(); cheat.outmapper.last_eject = os.clock(); sampSendChat("/eject " .. id); break end end
                end
            end
        end

        if state.enabled_crouchhook[0] then
            local playerPedPtr = memory.getuint32(ADDR_PLAYER_PED)
            if playerPedPtr ~= 0 then
                if memory.getuint8(playerPedPtr + 0x46F) ~= 128 then
                    memory.setuint8(playerPedPtr + 0x46F, 128)
                end
            end
        end

        if state.enabled_airbrake[0] and is_airbrake_active then
            local speed
            if isCharInAnyCar(PLAYER_PED) then 
                setCarHeading(getCarCharIsUsing(PLAYER_PED), getHeadingFromVector2d(select(1, getActiveCameraPointAt()) - select(1, getActiveCameraCoordinates()), select(2, getActiveCameraPointAt()) - select(2, getActiveCameraCoordinates()))) 
                if getDriverOfCar(getCarCharIsUsing(PLAYER_PED)) == -1 then 
                    speed = getFullSpeed(state.airbrake_speed_passenger[0]) 
                else 
                    speed = getFullSpeed(state.airbrake_speed_incar[0]) 
                end 
            else 
                speed = getFullSpeed(state.airbrake_speed_onfoot[0]) 
                setCharHeading(PLAYER_PED, getHeadingFromVector2d(select(1, getActiveCameraPointAt()) - select(1, getActiveCameraCoordinates()), select(2, getActiveCameraPointAt()) - select(2, getActiveCameraCoordinates()))) 
            end
    
            if not sampIsCursorActive() then
                if isKeyDown(VK_SPACE) then 
                    airbrake_coords[3] = airbrake_coords[3] + speed / 2 
                elseif isKeyDown(VK_LSHIFT) and airbrake_coords[3] > -95.0 then 
                    airbrake_coords[3] = airbrake_coords[3] - speed / 2
                end
                if isKeyDown(VK_S) then 
                    airbrake_coords[1] = airbrake_coords[1] - speed * math.sin(-math.rad(getCharHeading(PLAYER_PED))) 
                    airbrake_coords[2] = airbrake_coords[2] - speed * math.cos(-math.rad(getCharHeading(PLAYER_PED))) 
                elseif isKeyDown(VK_W) then 
                    airbrake_coords[1] = airbrake_coords[1] + speed * math.sin(-math.rad(getCharHeading(PLAYER_PED))) 
                    airbrake_coords[2] = airbrake_coords[2] + speed * math.cos(-math.rad(getCharHeading(PLAYER_PED))) 
                end
                if isKeyDown(VK_D) then 
                    airbrake_coords[1] = airbrake_coords[1] + speed * math.sin(-math.rad(getCharHeading(PLAYER_PED) - 90)) 
                    airbrake_coords[2] = airbrake_coords[2] + speed * math.cos(-math.rad(getCharHeading(PLAYER_PED) - 90)) 
                elseif isKeyDown(VK_A) then 
                    airbrake_coords[1] = airbrake_coords[1] - speed * math.sin(-math.rad(getCharHeading(PLAYER_PED) - 90)) 
                    airbrake_coords[2] = airbrake_coords[2] - speed * math.cos(-math.rad(getCharHeading(PLAYER_PED) - 90)) 
                end
            end
            if isCharInAnyCar(PLAYER_PED) then
                setCharCoordinates(PLAYER_PED, airbrake_coords[1], airbrake_coords[2], airbrake_coords[3])
            else
                setCharCoordinatesDontResetAnim(PLAYER_PED, airbrake_coords[1], airbrake_coords[2], airbrake_coords[3] + 0.5)
                local ped = getCharPointer(playerPed)
                memory.setuint8(ped + 0x46C, 3, true)
                setCharVelocity(PLAYER_PED, 0, 0, 0)
            end
        end

        if state.enabled_camhack[0] then
            if isKeyDown(VK_C) and isKeyDown(VK_1) and camhack_mode == 0 then
                camhack_mode = 1
                displayRadar(false)
                displayHud(false)   
                camhack_posX, camhack_posY, camhack_posZ = getCharCoordinates(playerPed)
                camhack_angZ = getCharHeading(playerPed) * -1.0
                camhack_angY = 0.0
                setFixedCameraPosition(camhack_posX, camhack_posY, camhack_posZ, 0.0, 0.0, 0.0)
                lockPlayerControl(true)
            end

            if camhack_mode == 1 then
                if not sampIsChatInputActive() and not isSampfuncsConsoleActive() then
                    local offMouX, offMouY = getPcMouseMovement()
                    camhack_angZ = camhack_angZ + (offMouX / 4.0)
                    camhack_angY = camhack_angY + (offMouY / 4.0)
                    if camhack_angZ > 360.0 then camhack_angZ = camhack_angZ - 360.0 end
                    if camhack_angZ < 0.0 then camhack_angZ = camhack_angZ + 360.0 end
                    if camhack_angY > 89.0 then camhack_angY = 89.0 end
                    if camhack_angY < -89.0 then camhack_angY = -89.0 end

                    local radZ, radY = math.rad(camhack_angZ), math.rad(camhack_angY)
                    local sinZ, cosZ = math.sin(radZ), math.cos(radZ)
                    local sinY, cosY = math.sin(radY), math.cos(radY)
                    local moveX, moveY, moveZ = sinZ * cosY, cosZ * cosY, sinY

                    if isKeyDown(VK_W) then
                        camhack_posX = camhack_posX + moveX * camhack_speed
                        camhack_posY = camhack_posY + moveY * camhack_speed
                        camhack_posZ = camhack_posZ + moveZ * camhack_speed
                    end
                    if isKeyDown(VK_S) then
                        camhack_posX = camhack_posX - moveX * camhack_speed
                        camhack_posY = camhack_posY - moveY * camhack_speed
                        camhack_posZ = camhack_posZ - moveZ * camhack_speed
                    end
                    local rightRadZ = math.rad(camhack_angZ - 90.0)
                    local rightMoveX, rightMoveY = math.sin(rightRadZ), math.cos(rightRadZ)
                    if isKeyDown(VK_A) then
                        camhack_posX = camhack_posX + rightMoveX * camhack_speed
                        camhack_posY = camhack_posY + rightMoveY * camhack_speed
                    end
                    if isKeyDown(VK_D) then
                        camhack_posX = camhack_posX - rightMoveX * camhack_speed
                        camhack_posY = camhack_posY - rightMoveY * camhack_speed
                    end
                    if isKeyDown(VK_SPACE) then camhack_posZ = camhack_posZ + camhack_speed end
                    if isKeyDown(VK_SHIFT) then camhack_posZ = camhack_posZ - camhack_speed end

                    setFixedCameraPosition(camhack_posX, camhack_posY, camhack_posZ, 0.0, 0.0, 0.0)
                    pointCameraAtPoint(camhack_posX + moveX, camhack_posY + moveY, camhack_posZ + moveZ, 2)

                    if isKeyDown(187) then camhack_speed = camhack_speed + 0.01; printStringNow(string.format("Speed: %.2f", camhack_speed), 1000) end
                    if isKeyDown(189) then camhack_speed = camhack_speed - 0.01; if camhack_speed < 0.01 then camhack_speed = 0.01 end; printStringNow(string.format("Speed: %.2f", camhack_speed), 1000) end

                    if isKeyDown(VK_C) and isKeyDown(VK_2) then
                        camhack_mode = 0
                        displayRadar(true)
                        displayHud(true)
                        lockPlayerControl(false)
                        restoreCameraJumpcut()
                        setCameraBehindPlayer()
                    end
                end
            end
        end

        if state.enabled_antimask[0] then
            pcall(function()
                local samp_dll = getModuleHandle('samp.dll')
                if samp_dll and samp_dll ~= 0 then
                    local p_pool = memory.getuint32(samp_dll + 0x21A0E4)
                    if p_pool and p_pool ~= 0 then
                        for i = 0, sampGetMaxPlayerId(true) do
                            if sampIsPlayerConnected(i) then
                                local r_ptr = memory.getuint32(p_pool + 0x1A44 + i * 4)
                                if r_ptr and r_ptr ~= 0 then
                                    local c_ptr = r_ptr + 0x22
                                    if bit.band(bit.rshift(memory.getuint32(c_ptr), 24), 0xFF) == 0 then
                                        local new_color = bit.bor(bit.band(memory.getuint32(c_ptr), 0x00FFFFFF), 0xAA000000)
                                        memory.setuint32(c_ptr, new_color, true)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        if state.enabled_rollerfix[0] and (isKeyDown(key.VK_W) or isKeyDown(key.VK_A) or isKeyDown(key.VK_S) or isKeyDown(key.VK_D)) then setCharAnimSpeed(PLAYER_PED, 'skate_idle', 1000.0) end
        if state.enabled_fullskill[0] then for i=70, 79 do if i~=73 and i~=74 and i~=75 then registerIntStat(i, 1000) end end end
        if state.enabled_autobike[0] then
             if isCharOnAnyBike(PLAYER_PED) and autobike_isKeyCheckAvailable() and isKeyDown(0xA0) then
                if autobike_bike[getCarModel(storeCarCharIsInNoSave(PLAYER_PED))] then
                    setGameKeyState(16, 255); wait(10); setGameKeyState(16, 0)
                elseif autobike_moto[getCarModel(storeCarCharIsInNoSave(PLAYER_PED))] then
                    setGameKeyState(1, -128); wait(10); setGameKeyState(1, 0)
                end
            end
            if (isCharOnFoot(PLAYER_PED) or isCharInWater(PLAYER_PED)) and isKeyDown(0x31) and autobike_isKeyCheckAvailable() then
                setGameKeyState(16, 256); wait(10); setGameKeyState(16, 0)
            end
        end
        if state.enabled_nobike[0] then setCharCanBeKnockedOffBike(PLAYER_PED, false) else setCharCanBeKnockedOffBike(PLAYER_PED, true) end
        if state.enabled_surfing[0] then
            if isKeyJustPressed(key.VK_K) then
                activated_surfing = not activated_surfing
                addOneOffSound(0.0, 0.0, 0.0, activated_surfing and 1083 or 1084)
            end
            if activated_surfing and not isCharInAnyCar(PLAYER_PED) then
                local CPed = getCharPointer(PLAYER_PED)
                setCharProofs(PLAYER_PED, false, false, false, true, false)
                local camX, camY, camZ = getActiveCameraCoordinates()
                local actCamX, actCamY, actCamZ = getActiveCameraPointAt()
                actCamX = actCamX - camX
                actCamY = actCamY - camY
                local zAngle = getHeadingFromVector2d(actCamX, actCamY)
                setCharHeading(PLAYER_PED, zAngle)
                local vecX, vecY, vecZ = getCharVelocity(PLAYER_PED)
                vecX = vecX * 1.001
                vecY = vecY * 1.001
                local speedMultX = memory.getfloat(CPed + 0x550)
                local speedMultY = memory.getfloat(CPed + 0x554)
                speedMultX = speedMultX * 15.0
                speedMultY = speedMultY * 15.0
                vecX = vecX + speedMultX
                vecY = vecY + speedMultY
                setCharVelocity(PLAYER_PED, vecX, vecY, vecZ)
                if not isCharPlayingAnim(PLAYER_PED, "KO_skid_back") then
                    memory.setuint8(CPed + 0x46C, 0, true)
                end
            end
        end
        if state.enabled_antidriverkill[0] and isCharInAnyCar(playerPed) and getCharHealth(playerPed) >= 1 then
            if isCharPlayingAnim(playerPed, "CAR_fallout_LHS") then    
                local fX, fY, fZ = getOffsetFromCharInWorldCoords(playerPed, 0, 0, 2.5);
                warpCharFromCarToCoord(playerPed, fX, fY, fZ);
            elseif isCharPlayingAnim(playerPed, "CAR_rollout_LHS") then
                wait(1610);
                clearCharTasksImmediately(playerPed);      
            end
        end

        if isCharInAnyCar(PLAYER_PED) then
            local veh = storeCarCharIsInNoSave(PLAYER_PED)
            if state.enabled_cargm[0] then
                setCarProofs(veh, true, true, true, true, true)
            end
            if state.enabled_wheelgm[0] then
                setCanBurstCarTires(veh, false)
            end
        end

        if state.enabled_clickwarp[0] then
            if not isPauseMenuActive() and not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() then
                if isKeyJustPressed(key.VK_MBUTTON) then
                    clickwarp_cursor_enabled = not clickwarp_cursor_enabled
                    clickwarp_showCursor(clickwarp_cursor_enabled)
                end
                if clickwarp_cursor_enabled then
                    local mode = sampGetCursorMode()
                    if mode == 0 then
                        clickwarp_showCursor(true)
                    end
                    local sx, sy = getCursorPos()
                    local sw, sh = getScreenResolution()
                    if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
                        local camX, camY, camZ = getActiveCameraCoordinates()
                        local wX, wY, wZ = convertScreenCoordsToWorld3D(sx, sy, 700.0)
                        local result, colpoint = processLineOfSight(camX, camY, camZ, wX, wY, wZ, true, true, false, true, false, false, false)
                        if result and colpoint.entity ~= 0 then
                            local normal = colpoint.normal
                            local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
                            local zOffset = 300
                            if normal[3] >= 0.5 then zOffset = 1 end
                            local result2, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3, true, true, false, true, false, false, false)
                            if result2 then
                                pos = Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3] + 1)
                                local curX, curY, curZ = getCharCoordinates(PLAYER_PED)
                                local dist = getDistanceBetweenCoords3d(curX, curY, curZ, pos.x, pos.y, pos.z)
                                local hoffs = renderGetFontDrawHeight(clickwarp_font)
                                renderFontDrawText(clickwarp_font, string.format("%.2fm", dist), sx - 2, sy - 2 - hoffs, -1)
                                local tpIntoCar = nil
                                if colpoint.entityType == 2 then
                                    local car = getVehiclePointerHandle(colpoint.entity)
                                    if doesVehicleExist(car) and (not isCharInAnyCar(PLAYER_PED) or storeCarCharIsInNoSave(PLAYER_PED) ~= car) then
                                        clickwarp_displayVehicleName(sx - 2, sy - 2 - hoffs * 2, getNameOfVehicleModel(getCarModel(car)))
                                        local color = 0xAAFFFFFF
                                        if isKeyDown(key.VK_RBUTTON) then
                                            tpIntoCar = car
                                            color = 0xFFFFFFFF
                                        end
                                        renderFontDrawText(clickwarp_font2, "Hold right mouse button to teleport into the car", sx - 2, sy - 2 - hoffs * 3, color)
                                    end
                                end
                                clickwarp_createPointMarker(pos.x, pos.y, pos.z)
                                if isKeyJustPressed(key.VK_LBUTTON) then
                                    if tpIntoCar then
                                        if not clickwarp_jumpIntoCar(tpIntoCar) then
                                            clickwarp_teleportPlayer(pos.x, pos.y, pos.z)
                                        end
                                    else
                                        clickwarp_teleportPlayer(pos.x, pos.y, pos.z)
                                    end
                                    clickwarp_removePointMarker()
                                    clickwarp_showCursor(false)
                                end
                            end
                        else
                             clickwarp_removePointMarker()
                        end
                    else
                         clickwarp_removePointMarker()
                    end
                else
                    clickwarp_removePointMarker()
                end
            end
        end
        if state.enabled_inf_fuel[0] and isCharInAnyCar(PLAYER_PED) then local car = storeCarCharIsInNoSave(PLAYER_PED); if car and doesVehicleExist(car) then setCarEngineOn(car, true) end end
        if state.enabled_skin_changer[0] and state.skin_changer_id[0] >= 0 and getCharModel(PLAYER_PED) ~= state.skin_changer_id[0] then local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED); set_player_skin(id, state.skin_changer_id[0]) end
        if state.enabled_attachcars[0] then local KEY_J = key.VK_J; if isKeyDown(KEY_J) and not sampIsCursorActive() and isCharInAnyCar(PLAYER_PED) and getDriverOfCar(getCarCharIsUsing(PLAYER_PED)) == PLAYER_PED then local x, y = getScreenResolution(); local radius = 150; x = x/2 - radius/2; y = y/3.3 - radius/2; renderDrawLine(x, y, x+radius, y, 3, -1); renderDrawLine(x, y, x, y+radius+3, 3, -1); renderDrawLine(x, y+radius, x+radius, y+radius, 3, -1); renderDrawLine(x+radius, y, x+radius, y+radius, 3, -1); local vehs = getAllVehicles(); local clear = true; for _, v in ipairs(vehs) do if v ~= getCarCharIsUsing(PLAYER_PED) then local vx, vy, vz = getCarCoordinates(v); local sx, sy = convert3DCoordsToScreen(vx, vy, vz); local px, py, pZ = getCharCoordinates(PLAYER_PED); if sx >= x and sx <= x+radius and sy >= y and sy <= y+radius and isCarOnScreen(v) and getDistanceBetweenCoords3d(px,py,pz,vx,vy,vz) <= 20 then renderDrawLine(sx, sy, x+radius/2, y+radius/2, 3, -1); attachcars_trailer = v; clear = false; break end end end; if clear then attachcars_trailer = nil end elseif not isKeyDown(KEY_J) and attachcars_trailer then if isCharInAnyCar(PLAYER_PED) and doesVehicleExist(attachcars_trailer) then if isTrailerAttachedToCab(attachcars_trailer, getCarCharIsUsing(PLAYER_PED)) then detachTrailerFromCab(attachcars_trailer, getCarCharIsUsing(PLAYER_PED)) else attachTrailerToCab(attachcars_trailer, getCarCharIsUsing(PLAYER_PED)) end end; attachcars_trailer = nil end end
    end
end

function AutoUpdaterMSG(prefix, text)
    color = "FF0000"
    return sampAddChatMessage(string.format('{%s}[%s] {D8D6D8}%s', color, prefix, text), -1)
end


function onScriptTerminate(script, quit_game)
    toggle_extraws(false)
    toggle_show_crosshair(false)
    toggle_nospread(false)
    if isCharInAnyCar(PLAYER_PED) then
        local veh = storeCarCharIsInNoSave(PLAYER_PED)
        setCarProofs(veh, false, false, false, false, false)
        setCanBurstCarTires(veh, true)
    end
    setCharCanBeKnockedOffBike(PLAYER_PED, true)
    nameTagOff()
end

function sampev.onSendVehicleSync(data) if cheat.outmapper.state then data.position.z = data.position.z - 3.0; return data end end
function sampev.onReceiveRpc(id, bs) if state.enabled_oz[0] and (id==87 or id==88 or id==21 or id==67 or id==14 or id==61 or id==86) then return false end end
function sampev.onRemovePlayerFromVehicle() if state.enabled_antieject[0] then return false end end

function sampev.onSendPlayerSync(data)
    if state.enabled_antistun[0] and data.animationId == 1084 then
        data.animationFlags = 32772
        data.animationId = 1189
    end
end

function sampev.onSendGiveTakeDamage(playerid, amount, weaponid, bodypart)
    if state.enabled_antidriveby[0] and isCharInAnyCar(PLAYER_PED) and getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)) ~= PLAYER_PED then
        return false
    end
end

function sampev.onPlayerChatBubble(id, color, distance, duration, text)
    if camhack_mode == 1 then
        return {id, color, 1500.0, duration, text}
    end
end

function onSystemInitialized()
end

function onWindowMessage(msg, wparam, lparam)
    if state.enabled_airbrake[0] and msg == 0x100 and lparam == 3538945 and autobike_isKeyCheckAvailable() then
        is_airbrake_active = not is_airbrake_active
        if is_airbrake_active then
            airbrake_coords = {getCharCoordinates(PLAYER_PED)}
            if not isCharInAnyCar(PLAYER_PED) then airbrake_coords[3] = airbrake_coords[3] - 1.0 end
        end
        sampAddChatMessage(is_airbrake_active and "{00FF00}[phobos]: AirBrake Activated." or "{FF0000}[phobos]: AirBrake Deactivated.", -1)
    end
    if is_airbrake_active and (wparam == key.VK_SPACE or wparam == key.VK_SHIFT) and autobike_isKeyCheckAvailable() then
         consumeWindowMessage(true, false)
    end
end

function getPlayerName(id) return sampGetPlayerNickname(id) or "Unknown" end
function sendFakeSMS(id, text) sampAddChatMessage("[SMS:Inbox] "..getPlayerName(id).."["..id.."]: "..text..".", 0xFFFF00) end
function sendFakeChat(id, text) sampAddChatMessage("- "..getPlayerName(id).."["..id.."]: "..text, -1) end
function sendFakeScream(id, text) sampAddChatMessage(getPlayerName(id).." Yviris: "..text.."!!", -1) end
function sendFakeB(id, text) sampAddChatMessage("{FF0000}"..getPlayerName(id).."{FFFFFF}: (( "..text.." ))", -1) end
function sendFakeVipAd(id, text) sampAddChatMessage("{FFD600}[VIP AD] "..getPlayerName(id).."["..id.."]:{FFFFFF} "..text, -1) end
function RunC(wt) if not sampIsChatInputActive() and not isSampfuncsConsoleActive() and isWeaponReload() then setVirtualKeyDown(key.VK_LBUTTON, true); wait(wt); setVirtualKeyDown(key.VK_LBUTTON, false); setVirtualKeyDown(key.VK_RBUTTON, false); setVirtualKeyDown(key.VK_C, true); wait(wt); setVirtualKeyDown(key.VK_C, false); setVirtualKeyDown(key.VK_RBUTTON, true) end end
function getAmmoInClip() local s=getCharPointer(PLAYER_PED); local p1=memory.getint8(s+0x718,false)*0x1C; local p2=s+0x5A0+p1+0x8; return memory.getint32(p2,false) end
function isWeaponReload() local w=getCurrentCharWeapon(PLAYER_PED); if w==24 and getAmmoInClip()~=0 then return true end; return false end

function autobike_isKeyCheckAvailable()
    if not isSampLoaded() then return true end
    if not isSampfuncsLoaded() then return not sampIsChatInputActive() and not sampIsDialogActive() end
    return not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive()
end

function getFullSpeed(speed)
    local fps = memory.getfloat(0xB7CB50, true)
    if fps < 60 then fps = 60 end
    return (speed / (fps / 60))
end

function setCharCoordinatesDontResetAnim(char, x, y, z)
    if doesCharExist(char) then
        local ptr = getCharPointer(char)
        setEntityCoordinates(ptr, x, y, z)
    end
end

function setEntityCoordinates(entityPtr, x, y, z)
    if entityPtr ~= 0 then
        local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
        if matrixPtr ~= 0 then
            local posPtr = matrixPtr + 0x30
            writeMemory(posPtr + 0, 4, representFloatAsInt(x), false) -- X
            writeMemory(posPtr + 4, 4, representFloatAsInt(y), false) -- Y
            writeMemory(posPtr + 8, 4, representFloatAsInt(z), false) -- Z
        end
    end
end

function clickwarp_createPointMarker(x, y, z)
    if clickwarp_point_marker then removeUser3dMarker(clickwarp_point_marker) end
    clickwarp_point_marker = createUser3dMarker(x, y, z, 4)
end

function clickwarp_removePointMarker()
    if clickwarp_point_marker then
        removeUser3dMarker(clickwarp_point_marker)
        clickwarp_point_marker = nil
    end
end

function clickwarp_teleportPlayer(x, y, z)
    if isCharInAnyCar(PLAYER_PED) then
        setCharCoordinates(PLAYER_PED, x, y, z)
    end
    setCharCoordinatesDontResetAnim(PLAYER_PED, x, y, z)
end

function clickwarp_showCursor(toggle)
    if toggle then
        sampSetCursorMode(3)
    else
        sampToggleCursor(false)
    end
    clickwarp_cursor_enabled = toggle
end

function clickwarp_getCarFreeSeat(car)
    if doesCharExist(getDriverOfCar(car)) then
        local maxPassengers = getMaximumNumberOfPassengers(car)
        for i = 0, maxPassengers do
            if isCarPassengerSeatFree(car, i) then
                return i + 1
            end
        end
        return nil
    else
        return 0
    end
end

function clickwarp_jumpIntoCar(car)
    local seat = clickwarp_getCarFreeSeat(car)
    if not seat then return false end
    if seat == 0 then
        warpCharIntoCar(PLAYER_PED, car)
    else
        warpCharIntoCarAsPassenger(PLAYER_PED, car, seat - 1)
    end
    restoreCameraJumpcut()
    return true
end

function clickwarp_displayVehicleName(x, y, gxt)
    x, y = convertWindowScreenCoordsToGameScreenCoords(x, y)
    useRenderCommands(true)
    setTextWrapx(640.0)
    setTextProportional(true)
    setTextJustify(false)
    setTextScale(0.33, 0.8)
    setTextDropshadow(0, 0, 0, 0, 0)
    setTextColour(255, 255, 255, 230)
    setTextEdge(1, 0, 0, 0, 100)
    setTextFont(1)
    displayText(x, y, gxt)
end

function clickwarp_rotateCarAroundUpAxis(car, vec)
    local mat = Matrix3X3(getVehicleRotationMatrix(car))
    local rotAxis = Vector3D(mat.up:get())
    vec:normalize()
    rotAxis:normalize()
    local theta = math.acos(rotAxis:dotProduct(vec))
    if theta ~= 0 then
        rotAxis:crossProduct(vec)
        rotAxis:normalize()
        rotAxis:zeroNearZero()
        mat = mat:rotate(rotAxis, -theta)
    end
    setVehicleRotationMatrix(car, mat:get())
end

function getVehicleRotationMatrix(car)
    local entityPtr = getCarPointer(car)
    if entityPtr ~= 0 then
        local mat = readMemory(entityPtr + 0x14, 4, false)
        if mat ~= 0 then
            local rx, ry, rz, fx, fy, fz, ux, uy, uz
            rx = representIntAsFloat(readMemory(mat + 0, 4, false))
            ry = representIntAsFloat(readMemory(mat + 4, 4, false))
            rz = representIntAsFloat(readMemory(mat + 8, 4, false))
            fx = representIntAsFloat(readMemory(mat + 16, 4, false))
            fy = representIntAsFloat(readMemory(mat + 20, 4, false))
            fz = representIntAsFloat(readMemory(mat + 24, 4, false))
            ux = representIntAsFloat(readMemory(mat + 32, 4, false))
            uy = representIntAsFloat(readMemory(mat + 36, 4, false))
            uz = representIntAsFloat(readMemory(mat + 40, 4, false))
            return rx, ry, rz, fx, fy, fz, ux, uy, uz
        end
    end
end

function setVehicleRotationMatrix(car, rx, ry, rz, fx, fy, fz, ux, uy, uz)
    local entityPtr = getCarPointer(car)
    if entityPtr ~= 0 then
        local mat = readMemory(entityPtr + 0x14, 4, false)
        if mat ~= 0 then
            writeMemory(mat + 0, 4, representFloatAsInt(rx), false)
            writeMemory(mat + 4, 4, representFloatAsInt(ry), false)
            writeMemory(mat + 8, 4, representFloatAsInt(rz), false)
            writeMemory(mat + 16, 4, representFloatAsInt(fx), false)
            writeMemory(mat + 20, 4, representFloatAsInt(fy), false)
            writeMemory(mat + 24, 4, representFloatAsInt(fz), false)
            writeMemory(mat + 32, 4, representFloatAsInt(ux), false)
            writeMemory(mat + 36, 4, representFloatAsInt(uy), false)
            writeMemory(mat + 40, 4, representFloatAsInt(uz), false)
        end
    end
end