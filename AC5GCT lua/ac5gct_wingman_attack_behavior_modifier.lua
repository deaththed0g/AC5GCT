{$lua}

--[[
================================================================================
==== ACE COMBAT 5: THE UNSUNG WAR - WINGMAN ATTACK BEHAVIOR MODIFIER SCRIPT ====
================================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written in and is best viewed on Notepad++.
v281125
]]

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

------------------+
---- [TABLES] ----+
------------------+

AC5adjustWingmanAttack_dataList = {}

---------------------+
---- [FUNCTIONS] ----+
---------------------+

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

-- Wingman attack behavior modifierifier function
function AC5adjustWingmanAttack_outSortieCheck(AC5adjustWingmanAttack_outSortieCheckTimer)
	
	-- Execute function while PCSX2 is up.
	if readInteger(EEMEMver_AC5adjustWingmanAttack[2]) ~= nil then
	
		--If the player is currently in a mission, modify data.
		if readBytes(EEMEMver_AC5adjustWingmanAttack[2] + 0x47B4C4, 1) == 4 then
				
			-- Pause "outer" timer
			AC5adjustWingmanAttack_outSortieCheckTimer.enabled = false
			
			-- Empty the global table.
			for k, v in pairs(AC5adjustWingmanAttack_dataList) do AC5adjustWingmanAttack_dataList[k] = nil end
			
			-- Scan for the file containing a wingman's attack parameters.
			local AC5_wingmanDat = memscan_func(soExactValue, vtByteArray, nil, "0600000020000000????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????41434D00", nil, EEMEMver_AC5adjustWingmanAttack[2] + 0x700000, EEMEMver_AC5adjustWingmanAttack[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
			
			-- Modify said attack parameters
			for i = 1, #AC5_wingmanDat do
			
				local dat_file_toc = retrieve_toc(AC5_wingmanDat[i])
				AC5adjustWingmanAttack_dataList[#AC5adjustWingmanAttack_dataList + 1] = dat_file_toc[4]
				AC5adjustWingmanAttack_dataList[#AC5adjustWingmanAttack_dataList + 1] = readBytes(dat_file_toc[4], 160, true)
				
				writeBytes(dat_file_toc[4], {0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x7A, 0x44, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9A, 0x99, 0x19, 0x3E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9A, 0x99, 0x99, 0x3E, 0xCD, 0xCC, 0x1C, 0x41, 0xA0, 0x0F, 0x01, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0xC8, 0x44, 0x00, 0x80, 0x3B, 0x45, 0x00, 0x00, 0x80, 0x3F, 0xCD, 0xCC, 0xCC, 0x3D, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x80, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x42, 0x00, 0x00, 0x00, 0x00, 0xCD, 0xCC, 0x1C, 0x41, 0xE8, 0x03, 0x02, 0x28, 0x5A, 0x00, 0x00, 0x00})
			
			end
			
			-- Adjust minimum altitude limit to prevent the wingmen from flying too close the ground without attacking any enemies.
			-- This happens in missions like FRONT LINE and ANCIENT WALLS.
			
			-- For this, the script will use two methods to adjust an entity's minimum altitude:
			--- Method 1: edit the entity's minimum altitude value while the mission is loading.
			--- Method 2: edit the entity's minimum altitude value stored in a dynamic address.
			
			---- Method 1
			--local tempScan = memscan_func(soExactValue, vtByteArray, nil, "000000000000000010000000300000000000000000000000??????????????????????????00FF??FFFF000000000000", nil, EEMEMver_AC5adjustWingmanAttack[2] + 0x700000, EEMEMver_AC5adjustWingmanAttack[2] + 0x1F00000, "", 1, "4", true, nil, nil, nil)
			--
			--for i = 1, #tempScan do
			--
			--	AC5adjustWingmanAttack_dataList[#AC5adjustWingmanAttack_dataList + 1] = tempScan[i] + 0x20
			--	AC5adjustWingmanAttack_dataList[#AC5adjustWingmanAttack_dataList + 1] = readBytes(tempScan[i] + 0x20, 4, true)
			--	
			--	if readFloat(tempScan[i] + 0x20) == 0 then
			--	
			--		writeFloat(tempScan[i] + 0x20, 1025.0) -- Might want to set this value to 2048.0 instead?
			--	
			--	end
			--
			--end
			
			-- Method 2
			local AC5adjustWingmanAttack_IFF = {"CC CC 4C 42 45 44 47 45", "CC CC 4C 42 53 57 4F 52", "CC CC 4C 42 41 52 43 48", "CC CC 4C 42 48 54 42 52", "CC CC 4C 42 43 48 4F 50", "CC CC 4C 42 50 4F 50 53"}
			
			for i = 1, #AC5adjustWingmanAttack_IFF do
			
				local tempScan = memscan_func(soExactValue, vtByteArray, nil, AC5adjustWingmanAttack_IFF[i], nil, EEMEMver_AC5adjustWingmanAttack[2] + 0x700000, EEMEMver_AC5adjustWingmanAttack[2] + 0x1F00000, "", 2, "8", true, nil, nil, nil)
				
				for i = 1, #tempScan do

					if readInteger(tempScan[i] - 0x10C) == 1065353216 then
					
						AC5adjustWingmanAttack_dataList[#AC5adjustWingmanAttack_dataList + 1] = tempScan[i] - 0x174
						AC5adjustWingmanAttack_dataList[#AC5adjustWingmanAttack_dataList + 1] = readBytes(tempScan[i] - 0x174, 4, true)

						if readFloat(tempScan[i] - 0x174) == 0 then
						
							writeFloat(tempScan[i] - 0x174, 1025.0) -- Might want to set this value to 2048.0 instead?
						
						end
					
					end
				
				end
			
			end
			
			-- Create a function to check if player IS currently in a mission.
			function AC5adjustWingmanAttack_inSortieCheck(AC5adjustWingmanAttack_inSortieCheckTimer)
				
				-- Exit script if the emulator closes abruptly.
				if readInteger(EEMEMver_AC5adjustWingmanAttack[2]) ~= nil then
					
					-- Stop "inner" timer, clear flag value and resume the "outer" timer.
					if readBytes(EEMEMver_AC5adjustWingmanAttack[2] + 0x47B4C4, 1) ~= 4 then
						
						AC5adjustWingmanAttack_inSortieCheckTimer.enabled = false
	
						AC5adjustWingmanAttack_outSortieCheckTimer.enabled = true
	
					end
	
				else
	
					getAddressList().getMemoryRecordByDescription("Wingman attack behavior modifier").Active = false
	
				end
	
			end
			
			-- Start "inner" timer.
			if AC5adjustWingmanAttack_inSortieCheck_Timer == nil then
	
				AC5adjustWingmanAttack_inSortieCheck_Timer = createTimer()
				AC5adjustWingmanAttack_inSortieCheck_Timer.Interval = 300
				AC5adjustWingmanAttack_inSortieCheck_Timer.onTimer = AC5adjustWingmanAttack_inSortieCheck
				AC5adjustWingmanAttack_inSortieCheck_Timer.Enabled = true

			else
	
				AC5adjustWingmanAttack_inSortieCheck_Timer.Enabled = true

			end

		end

	else

		getAddressList().getMemoryRecordByDescription("Wingman attack behavior modifier").Active = false

	end

end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EEMEMver_AC5adjustWingmanAttack = pcsx2_version_check()

if (EEMEMver_AC5adjustWingmanAttack[3] == nil) then
	
	-- Check if the emulator version is compatible with this script.
	if (EEMEMver_AC5adjustWingmanAttack[1] == 2) then

		-- Check if the emulator has the right game loaded.
		local SLUS20851_check = memscan_func(soExactValue, vtByteArray, nil, "80 55 42 00 90 55 42 00 A0 55 42 00 B0 55 42 00", nil, EEMEMver_AC5adjustWingmanAttack[2] + 0x300000, EEMEMver_AC5adjustWingmanAttack[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
		
		if #SLUS20851_check ~= 0 then
			
			-- If the [[AC5GCT] Wingman engagement behavior modifier] cheat is not enabled suggest the user to enable it.
			if readInteger(EEMEMver_AC5adjustWingmanAttack[2] + 0x175144) ~= 1006747552 then
				
				showMessage("<< You might want to enable the '[AC5GCT] WINGMAN ENGAGEMENT MODIFIER' cheat to get the most out of this script. >>")
			
			end
			
			-- Activate script if all checks were successfully passed.
			IsAC5adjustWingmanAttackEnabled = true
			
		else
		
			showMessage("<< This script is not compatible with the game you're currently emulating. >>")
			
		end
	
	else
	
		showMessage("<< This script is only compatible with PCSX2-qt. >>")
	
	end
	
else

	if EEMEMver_AC5adjustWingmanAttack[3] == 1 then
	
		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")
		
	elseif EEMEMver_AC5adjustWingmanAttack[3] == 2 then
	
		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")
		
	elseif EEMEMver_AC5adjustWingmanAttack[3] == 3 then
	
		showMessage("<< PCSX2 has no ISO file loaded. >>")
		
	end
	
end

----------------+
---- [MAIN] ----+
----------------+

if IsAC5adjustWingmanAttackEnabled then

	-- Create a function check if the player is NOT in a mission.
	AC5adjustWingmanAttack_outSortieCheck_Timer = createTimer()
	AC5adjustWingmanAttack_outSortieCheck_Timer.Interval = 300
	AC5adjustWingmanAttack_outSortieCheck_Timer.onTimer = AC5adjustWingmanAttack_outSortieCheck
	AC5adjustWingmanAttack_outSortieCheck_Timer.Enabled = true

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags on script deactivation.
if IsAC5adjustWingmanAttackEnabled then

	if AC5adjustWingmanAttack_inSortieCheck_Timer ~= nil then

		AC5adjustWingmanAttack_inSortieCheck_Timer.destroy()
		AC5adjustWingmanAttack_inSortieCheck_Timer = nil

	end

	if AC5adjustWingmanAttack_outSortieCheck_Timer ~= nil then

		AC5adjustWingmanAttack_outSortieCheck_Timer.destroy()
		AC5adjustWingmanAttack_outSortieCheck_Timer = nil

	end
	
	if readInteger(EEMEMver_AC5adjustWingmanAttack[2]) ~= nil then
	
		if (readBytes(EEMEMver_AC5adjustWingmanAttack[2] + 0x47B4C4, 1) == 4) then

			for i = 1, #AC5adjustWingmanAttack_dataList, 2 do
			
				writeBytes(AC5adjustWingmanAttack_dataList[i], AC5adjustWingmanAttack_dataList[i + 1])
			
			end
			
		end
	
	end
	
	AC5adjustWingmanAttack_dataList = nil
	IsAC5adjustWingmanAttackEnabled = nil
	
end

EEMEMver_AC5adjustWingmanAttack = nil