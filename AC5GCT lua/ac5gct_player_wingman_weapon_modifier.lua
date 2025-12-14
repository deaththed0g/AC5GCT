{$lua}

--[[
=====================================================================================
==== ACE COMBAT 5: THE UNSUNG WAR - EDIT PLAYER/WINGMAN WEAPON PARAMETERS SCRIPT ====
=====================================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v221125
]]

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+

AC5playerWingmanWpn_dataList = {}

---------------------+
---- [FUNCTIONS] ----+
---------------------+

-- Create header 
local function create_header(header_name, header_appendtoentry, header_options)

	local header_memory_record_name = getAddressList().createMemoryRecord()
	header_memory_record_name.Description = header_name
	header_memory_record_name.isGroupHeader = true
	
	if header_appendtoentry ~= nil then
	
		header_memory_record_name.appendToEntry(header_appendtoentry)
		
	end
	
	if header_options then
		
		header_memory_record_name.options = "[moHideChildren, moAllowManualCollapseAndExpand, moManualExpandCollapse]"
		
	end
	
	return header_memory_record_name
	
end

-- Create memory record
local function create_memory_record(base_address, offset_list, vt_list, description_list, append_to_entry)

	for i = 1, #offset_list do
		
		local memory_record = getAddressList().createMemoryRecord()
		memory_record.Description = description_list[i]
		memory_record.setAddress(base_address + offset_list[i])
		
		if type(vt_list[i]) == "table" then
			
			if vt_list [i][1] == vtByteArray then
				
				memory_record.Type = vtByteArray
				memory_record.Aob.Size = vt_list[i][2]
				memory_record.ShowAsHex = true
				
			elseif vt_list [i][1] == vtString then
				
				memory_record.Type = vtString
				memory_record.String.Size = vt_list[i][2]
				
			end
			
		else
			
			memory_record.Type = vt_list[i]
			
		end
		
		memory_record.appendToEntry(append_to_entry)
		
	end
	
	return
	
end

-- Retrieve Table of Contents of a container file.
local function retrieve_toc(base_address)

	local table_name = {}
	local n = readBytes(base_address, 1)
	
	for i = 1, n do
	
		table_name[#table_name + 1] = base_address + (readInteger(base_address + (i * 4)))
		
	end
	
	return table_name
end

-- Check current version and amount of active instances of PCSX2, set working RAM region.
local function pcsx2_version_check()

	version_id = nil
	pcsx2_id_ram_start = nil
	error_flag = nil
	local process_found = {}
	
	for processID, processName in pairs(getProcessList()) do
	
		if processName == "pcsx2.exe" or processName == "pcsx2-qt.exe" then
		
			process_found[#process_found + 1] = processName
			process_found[#process_found + 1] = processID
			
		end
		
	end
	
	if process_found[1] ~= nil then
	
		if (process_found[2] == getOpenedProcessID()) then
		
			if process_found[1] == "pcsx2.exe" then
			
				version_id = 1
				pcsx2_id_ram_start = getAddress(0x20000000)
				
				if readInteger(pcsx2_id_ram_start) == nil then
				
					error_flag = 3
					
				end
				
			elseif process_found[1] == "pcsx2-qt.exe" then
			
				version_id = 2
				pcsx2_id_ram_start = getAddress(readPointer("pcsx2-qt.EEmem"))
				
				if readInteger(pcsx2_id_ram_start) == 0 then
				
					error_flag = 3
					
				end
				
			end
			
		else
		
			error_flag = 2
			
		end
		
	else
	
		error_flag = 1
		
	end
	
	return {version_id, pcsx2_id_ram_start, error_flag}
	
end

-- Memory scanner function
local function memscan_func(scanoption, vartype, roundingtype, input1, input2, startAddress, stopAddress, protectionflags, alignmenttype, alignmentparam, isHexadecimalInput, isNotABinaryString, isunicodescan, iscasesensitive)

	local memory_scan = createMemScan()
	memory_scan.firstScan(scanoption, vartype, roundingtype, input1, input2 ,startAddress ,stopAddress ,protectionflags ,alignmenttype, alignmentparam, isHexadecimalInput, isNotABinaryString, isunicodescan, iscasesensitive)
	memory_scan.waitTillDone()
	local found_list = createFoundList(memory_scan)
	found_list.initialize()
	local address_list = {}
	
	if (found_list ~= nil) then
	
		for i = 0, found_list.count - 1 do
		
			table.insert(address_list, getAddress(found_list[i]))
			
		end
		
	end
	
	found_list.deinitialize()
	found_list.destroy()
	found_list = nil
	
	return address_list
	
end

-- MR generator
local function generate_mr(dat_base_address, header_name, parent_header_name, pos)

	local dat_file_toc = retrieve_toc(dat_base_address)
	local base_address = dat_file_toc[pos]
	AC5playerWingmanWpn_dataList[#AC5playerWingmanWpn_dataList + 1] = base_address
	AC5playerWingmanWpn_dataList[#AC5playerWingmanWpn_dataList + 1] = readBytes(base_address, 208, true)
	
	-- Header
	local entity_header = create_header(header_name, parent_header_name, true)
	
	-- Sub record
	local header_list = {"Ammo and SpW parameters", "GUN parameters", "Missile parameters"}
	local start_offset = {0x0, 0x30, 0x80}
	local offset_list = {{0x1C, 0x1E, 0x1F, 0x21}, {0x20, 0x24, 0x30, 0x34, 0x38, 0x40, 0x4B}, {0x20, 0x24, 0x2C, 0x30, 0x34, 0x3C, 0x4B} }
	local vt_list = { {vtWord, vtByte, vtByte, vtByte}, {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtByte}, {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtByte}}
	local description_list = {{"GUN ammo starting amount", "Standard missile ammo starting amount", "SpW ammo starting amount", "SpW slot ID"}, {"Pipper range visibility", "Bullet travel distance", "Attack interval (affects wingman only)", "Fire rate", "Attack duration (affects wingman only)", "Fire dispersion", "Damage"}, {"Lock-on range", "Missile travel distance", "Launch delay (affects wingman only)", "Launch rate 1 (affects wingman only)", "Launch rate 2", "Accuracy", "Damage"}}
	
	for i = 1, 3 do
	
		local header = create_header(header_list[i], entity_header, true)
		create_memory_record(base_address + start_offset[i], offset_list[i], vt_list[i], description_list[i], header)
		
	end
	
	return
	
end

-- PCSX2-qt status checker function
function AC5playerWingmanWpn_outSortieCheck(AC5playerWingmanWpn_outSortieCheckTimer)

	-- If the emulator is NOT running then disable the script.
	if readInteger(EEMEMver_AC5playerWingmanWpn[2]) == nil then
	
		getAddressList().getMemoryRecordByDescription("Edit player/wingman weapon parameters").Active = false
	
	end

end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EEMEMver_AC5playerWingmanWpn = pcsx2_version_check()

if (EEMEMver_AC5playerWingmanWpn[3] == nil) then

	-- Check if the emulator version is compatible with this script.
	if (EEMEMver_AC5playerWingmanWpn[1] == 2) then

		-- Check if the emulator has the right game loaded.
		local SLUS20851_check = memscan_func(soExactValue, vtByteArray, nil, "80 55 42 00 90 55 42 00 A0 55 42 00 B0 55 42 00", nil, EEMEMver_AC5playerWingmanWpn[2] + 0x300000, EEMEMver_AC5playerWingmanWpn[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
		
		if #SLUS20851_check ~= 0 then
		
			-- Check if the player is currently in a mission.
			if (readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x47B87C, 1) == 1) then
	
				-- Look for the bytearray needed by the script.
				-- If the search function returned the right amount of results then proceed with the rest of the script.
				AC5_playerWingmanWpnParam_tbl = memscan_func(soExactValue, vtByteArray, nil, "0B00000030000000????????????????????????????????????????????????????????????????????????????????10000000200000000000000000000000000000000000000000000000000000000100000010000000000000000000000000000000100000000000000000000000040000002000000060000000B00000000001000000000000000000000000000010000000000000000000000000000000", nil, EEMEMver_AC5playerWingmanWpn[2] + 0x700000, EEMEMver_AC5playerWingmanWpn[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
				
				if #AC5_playerWingmanWpnParam_tbl ~= 0	then
				
					IsAC5PlayerWingmanWpnEnabled = true
					
				else
					
					showMessage("<< Unable to activate this script (memscan_func returned nil). >>")
					
				end
				
			else
			
				showMessage("<< You'll need to be in a mission to use this script. >>")
				
			end
			
		else
		
			showMessage("<< This script is not compatible with the game you're currently emulating. >>")
			
		end
	
	else
	
		showMessage("<< This script is only compatible with PCSX2-qt. >>")
	
	end
	
else

	if EEMEMver_AC5playerWingmanWpn[3] == 1 then
	
		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")
		
	elseif EEMEMver_AC5playerWingmanWpn[3] == 2 then
	
		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")
		
	elseif EEMEMver_AC5playerWingmanWpn[3] == 3 then
	
		showMessage("<< PCSX2 has no ISO file loaded. >>")
		
	end
	
end

----------------+
---- [MAIN] ----+
----------------+

if IsAC5PlayerWingmanWpnEnabled then

	-- Create a global header to hold this script's memory records.
	AC5PlayerWingmanWpn_header_main = create_header("[MISC] WEAPON AND ATTACK SETTINGS", nil, nil)
	
	-- [Player]
	---- Find the weapon data used by the player's aircraft.
	---- Create headers and memory records to display said data.
	---- Back up said data.
	generate_mr(AC5_playerWingmanWpnParam_tbl[1], "Player", AC5PlayerWingmanWpn_header_main, 8)
	
	-- [Wingman]
	-- Check if the game is in a mode that enables wingmen.
	-- If true then scan for their data and create header and records for their stats. If not, just exit the script.
	if readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x8D3242, 1) == 8 then
	
		local AC5_wingmanDat = memscan_func(soExactValue, vtByteArray, nil, "0600000020000000????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????41434D00", nil, EEMEMver_AC5playerWingmanWpn[2] + 0x700000, EEMEMver_AC5playerWingmanWpn[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
		
		local AC5_wingmanIFF = {}
		
		-- Check what wingmen are flying with the Player so their headers can be properly named.
		if readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) == 1 or readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) == 2 then -- Heartbreak One
		
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Heartbreak One"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Edge"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Chopper"
			
		elseif readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) == 3 then -- Edge and Chopper only
		
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Edge"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Chopper"
		
		elseif readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) >= 4 and readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) <= 26 then -- Archer
		
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Edge"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Chopper"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Archer"
		
		elseif readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) >= 27 and readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) <= 29 then -- Edge and Archer only
		
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Edge"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Archer"
		
		elseif readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) == 30 then -- Pops
			
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Edge"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Archer"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Pops"
		
		elseif readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) >= 31 and readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x5C8CBA, 1) <= 43 then -- Swordsman
		
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Edge"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Swordsman"
			AC5_wingmanIFF[#AC5_wingmanIFF + 1] = "Archer"
		
		end
		
		for i = 1, #AC5_wingmanIFF do
		
			generate_mr(AC5_wingmanDat[i], AC5_wingmanIFF[i], AC5PlayerWingmanWpn_header_main, 3)
		
		end
	
	end
	
	-- Create a timer to check if the emulator is running.
	AC5playerWingmanWpn_outSortieCheck_Timer = createTimer()
	AC5playerWingmanWpn_outSortieCheck_Timer.Interval = 300
	AC5playerWingmanWpn_outSortieCheck_Timer.onTimer = AC5playerWingmanWpn_outSortieCheck
	AC5playerWingmanWpn_outSortieCheck_Timer.Enabled = true
	
	showMessage("<< Restart the mission once you've made your changes so they can take effect. >>")
	
end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags on script deactivation.
if IsAC5PlayerWingmanWpnEnabled then
	
	if AC5playerWingmanWpn_outSortieCheck_Timer ~= nil then
	
		AC5playerWingmanWpn_outSortieCheck_Timer.destroy()
		AC5playerWingmanWpn_outSortieCheck_Timer = nil
		
	end
	
	AC5PlayerWingmanWpn_header_main.destroy()
	
	if (readBytes(EEMEMver_AC5playerWingmanWpn[2] + 0x47B87C, 1) == 1) then
	
		for i = 1, #AC5playerWingmanWpn_dataList, 2 do
		
			writeBytes(AC5playerWingmanWpn_dataList[i], AC5playerWingmanWpn_dataList[i + 1])
			
		end
		
		if readInteger(EEMEMver_AC5playerWingmanWpn[2]) ~= nil then
			
			showMessage("<< Restart the mission to fully revert the changes made. >>")
		
		end
		
	end
	
	AC5playerWingmanWpn_dataList = nil
	
	IsAC5PlayerWingmanWpnEnabled = nil
	
end

EEMEMver_AC5playerWingmanWpn = nil