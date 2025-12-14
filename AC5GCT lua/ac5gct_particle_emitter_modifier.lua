{$lua}

--[[
=========================================================================
==== ACE COMBAT 5: THE UNSUNG WAR - PARTICLE EMITTER MODIFIER SCRIPT ====
=========================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v221125
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

---------------------+
---- [FUNCTIONS] ----+
---------------------+

-- "X item exists in Y table" check function
local function value_exists(tab, val)

	for index, value in ipairs(tab) do

		if value == val then

			return true

		end

	end

	return false

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

-- Particle meitter mod function
function AC5ParticleMod_outSortieCheck(AC5ParticleMod_outSortieCheckTimer)
	
	-- Run function as long the emulator is up.
	if readInteger(EEMEMver_AC5ParticleMod[2]) ~= nil then
		
		-- Check iof the player is currently in a mission.
		if readBytes(EEMEMver_AC5ParticleMod[2] + 0x47B4C4, 1) == 4 then
			
			-- Pause timer and modify particle emitter parameters.
			AC5ParticleMod_outSortieCheckTimer.enabled = false
			
			local AC5ParticleMod_stgFileOffset = memscan_func(soExactValue, vtByteArray, nil, "2? 00 00 00 A0 00 00 00 A0 01 00 00", nil, EEMEMver_AC5ParticleMod[2] + 0x700000, EEMEMver_AC5ParticleMod[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
			
			for k, v in pairs(AC5ParticleMod_dataList) do AC5ParticleMod_dataList[k] = nil end
			
			-- Bytearray list:
			---- 1: Particle emitter 1: missile smoke-trail parameters
			---- 2: Particle emitter 2: plane's wing trail parameters
			---- 3: Particle emitter 3: destroyed plane burning debris
			---- 4: Particle emitter 4: destroyed plane burning trail
			---- 5: Particle emitter 5: destroyed plane debris
			---- 6: Particle emitter 6: destroyed plane sparks
			
			local bytearrays_to_search = {
				"00 00 00 00 50 00 00 00 31 00 00 00 ?? ?? ?? 00",
				"00 00 00 00 10 00 00 00 09 00 00 00 ?? ?? ?? 00",
				"?? 00 00 00 30 00 00 00 4F 00 00 00 ?? ?? ?? 00",
				"00 00 00 00 40 00 00 00 02 00 00 00 ?? 00 00 00",
				"00 00 00 00 30 00 00 00 53 00 00 00 ?? ?? ?? 00",
				"00 00 00 00 20 00 00 00 42 00 00 00 ?? 00 00 00"
			}
			
			for i = 1, #AC5ParticleMod_stgFileOffset do
				
				local AC5ParticleMod_tbl = retrieve_toc(AC5ParticleMod_stgFileOffset[i])
			
				-- For every particle effect being modified, read and store the current particle's configuration
				-- so it can be used for restoration when disabling the script later.
			
				-- Particle emitter 1: missile smoke-trail parameters
				local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[1], nil, AC5ParticleMod_tbl[21], AC5ParticleMod_tbl[21] + (AC5ParticleMod_tbl[22] - AC5ParticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)
				
				if #tbl ~= 0 then
				
					for i = 1, #tbl do
			
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = tbl[i] + 0x18
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = readBytes(tbl[i] + 0x18, 4, true)
						
						if readBytes(EEMEMver_AC5ParticleMod[2] + 0x5C8CBA, 1) == 16 then
							
							writeFloat(tbl[i] + 0x18, 3)
						
						else
							
							writeFloat(tbl[i] + 0x18, 4.8)
							
						end
			
					end
			
				end
			
				-- Particle emitter 2: plane's wing trail parameters
				local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[2], nil, AC5ParticleMod_tbl[21], AC5ParticleMod_tbl[21] + (AC5ParticleMod_tbl[22] - AC5ParticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)
				
				
				if #tbl ~= 0 then
			
					for i = 1, #tbl do
			
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = tbl[i] + 0x10
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = readBytes(tbl[i] + 0x10, 8, true)
			
						writeFloat(tbl[i] + 0x14, 110)
			
					end
			
				end
			
				-- Particle emitter 3: destroyed plane burning debris
				local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[3], nil, AC5ParticleMod_tbl[21], AC5ParticleMod_tbl[21] + (AC5ParticleMod_tbl[22] - AC5ParticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)
				
				if #tbl ~= 0 then
			
					for i = 1, #tbl do
			
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = tbl[i]
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = readBytes(tbl[i], 56, true)
						
						writeFloat(tbl[i] + 0x14, 3.5) -- Particle escape speed (lower = faster)
						writeBytes(tbl[i] + 0x26, 0xF) -- Particle texture coordinate
						writeFloat(tbl[i] + 0x28, 500) -- Particle spread radius (higher = further distance)
						writeFloat(tbl[i] + 0x2C, 40) -- Particle size (higher = bigger)
						writeFloat(tbl[i] + 0x30, 0.15) -- I forgot what was this
						writeSmallInteger(tbl[i] + 0x34, 31) -- Particle trail length (higher = lengthier trail)
						writeSmallInteger(tbl[i] + 0x36, 15) -- Particle amount
			
					end
			
				end
			
				-- Particle emitter 4: destroyed plane burning trail
				local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[4], nil, AC5ParticleMod_tbl[21], AC5ParticleMod_tbl[21] + (AC5ParticleMod_tbl[22] - AC5ParticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)
				
				if #tbl ~= 0 then
			
					for i = 1, #tbl do
			
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = tbl[i]
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = readBytes(tbl[i], 72, true)
						
						writeSmallInteger(tbl[i] + 0x28, (readSmallInteger(tbl[i] + 0x28) * 2)) -- Trail length
						writeBytes(tbl[i] + 0x3E, 0xFF) -- Texture coordinate
			
					end
			
				end
			
				-- Particle emitter 5: destroyed plane debris
				local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[5], nil, AC5ParticleMod_tbl[21], AC5ParticleMod_tbl[21] + (AC5ParticleMod_tbl[22] - AC5ParticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)
				
				if #tbl ~= 0 then
				
					for i = 1, #tbl do
					
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = tbl[i]
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = readBytes(tbl[i], 72, true)
						
						writeSmallInteger(tbl[i] + 0x28, (readSmallInteger(tbl[i] + 0x28) * 10)) -- Particle amount
						writeFloat(tbl[i] + 0x2C, 0.5) -- Particle gravity?
						
					end
					
				end
				
				-- Particle emitter 6: destroyed plane sparks
				local tbl = memscan_func(soExactValue, vtByteArray, nil, bytearrays_to_search[6], nil, AC5ParticleMod_tbl[21], AC5ParticleMod_tbl[21] + (AC5ParticleMod_tbl[22] - AC5ParticleMod_tbl[21]), "", 1, "4", true, nil, nil, nil)
				
				if #tbl ~= 0 then
				
					for i = 1, #tbl do
					
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = tbl[i]
						AC5ParticleMod_dataList[#AC5ParticleMod_dataList + 1] = readBytes(tbl[i], 40, true)
						
						writeSmallInteger(tbl[i] + 0xC, (readSmallInteger(tbl[i] + 0xC) * 4)) -- Particle amount
						writeFloat(tbl[i] + 0x14, 3) -- Particle speed release
						writeFloat(tbl[i] + 0x1C, 0.75) -- Particle gravity?
						
					end
					
				end
				
			end
			
			-- Check if the Player has exit the mission.
			function AC5ParticleMod_inSortieCheck(AC5ParticleMod_inSortieCheckTimer)

				if readInteger(EEMEMver_AC5ParticleMod[2]) ~= nil then
			
					if readBytes(EEMEMver_AC5ParticleMod[2] + 0x47B4C4, 1) ~= 4 then
					
						AC5ParticleMod_inSortieCheckTimer.enabled = false
						
						AC5ParticleMod_outSortieCheckTimer.enabled = true
						
					end
				
				else
	
					getAddressList().getMemoryRecordByDescription("Particle emitter modifier").Active = false
	
				end
			
			end
			
			-- Create a function to check if the player is inside the mission.
			if AC5ParticleMod_inSortieCheck_Timer == nil then
			
				AC5ParticleMod_inSortieCheck_Timer = createTimer()
				AC5ParticleMod_inSortieCheck_Timer.Interval = 300
				AC5ParticleMod_inSortieCheck_Timer.onTimer = AC5ParticleMod_inSortieCheck
				AC5ParticleMod_inSortieCheck_Timer.Enabled = true
			
			else
			
				AC5ParticleMod_inSortieCheck_Timer.Enabled = true
			
			end
		
		end
		
	else
	
		getAddressList().getMemoryRecordByDescription("Particle emitter modifier").Active = false
	
	end

end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EEMEMver_AC5ParticleMod = pcsx2_version_check()

if (EEMEMver_AC5ParticleMod[3] == nil) then

	-- Check if the emulator version is compatible with this script.
	if (EEMEMver_AC5ParticleMod[1] == 2) then
	
		-- Check if the emulator has the right game loaded.
		local SLUS_21346_check = memscan_func(soExactValue, vtByteArray, nil, "80 55 42 00 90 55 42 00 A0 55 42 00 B0 55 42 00", nil, EEMEMver_AC5ParticleMod[2] + 0x300000, EEMEMver_AC5ParticleMod[2] + 0x5000000, "", 2, "0", true, nil, nil, nil)
	
		if #SLUS_21346_check ~= 0 then
		
			-- If the [[AC5GCT] Misc VFX modifications] cheat is not enabled suggest the user to enable it.
			if readInteger(EEMEMver_AC5ParticleMod[2] + 0x235400) ~= 1006748192 then
				
				showMessage("<< You might want to enable the '[AC5GCT] MISC VFX MODIFICATIONS' cheat to get the most out of this script. >>")
			
			end
			
			-- Enable script if all other check were passed.
			IsAC5ParticleModEnabled = true
	
		else
	
			showMessage("<< This script is not compatible with the game you're currently emulating. >>")
	
		end
	
	else
	
		showMessage("<< This script is only compatible with PCSX2-qt. >>")
	
	end

else

	if EEMEMver_AC5ParticleMod[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif EEMEMver_AC5ParticleMod[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif EEMEMver_AC5ParticleMod[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+

if IsAC5ParticleModEnabled then
	
	-- initialize a table to store addresses and values.
	AC5ParticleMod_dataList = {}
	
	-- Begin particle emitter mod function.
	AC5ParticleMod_outSortieCheck_Timer = createTimer()
	AC5ParticleMod_outSortieCheck_Timer.Interval = 300
	AC5ParticleMod_outSortieCheck_Timer.onTimer = AC5ParticleMod_outSortieCheck
	AC5ParticleMod_outSortieCheck_Timer.Enabled = true

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags on script deactivation.
if IsAC5ParticleModEnabled then

	if AC5ParticleMod_inSortieCheck_Timer ~= nil then
	
		AC5ParticleMod_inSortieCheck_Timer.destroy()
		AC5ParticleMod_inSortieCheck_Timer = nil
		
	end
	
	if AC5ParticleMod_outSortieCheck_Timer ~= nil then
	
		AC5ParticleMod_outSortieCheck_Timer.destroy()
		AC5ParticleMod_outSortieCheck_Timer = nil
		
	end
	
	if readInteger(EEMEMver_AC5ParticleMod[2]) ~= nil then

		if readBytes(EEMEMver_AC5ParticleMod[2] + 0x47B4C4, 1) == 4 then
	
			for i = 1, #AC5ParticleMod_dataList, 2 do
	
				writeBytes(AC5ParticleMod_dataList[i], AC5ParticleMod_dataList[i + 1])
	
			end
	
		end
	
	end

	AC5ParticleMod_dataList = nil

	IsAC5ParticleModEnabled = nil

end

EEMEMver_AC5ParticleMod = nil