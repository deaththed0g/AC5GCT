{$lua}

--[[
=============================================================================
==== ACE COMBAT 5: THE UNSUNG WAR - ADJUST CAMERA LENS DISTORTION SCRIPT ====
=============================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v281125

TODO:
-- Redo everything
-- Shorten the code comments
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

---------------------+
---- [FUNCTIONS] ----+
---------------------+

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

-- "X item exists in Y table" check function
local function value_exists(tab, val)

	for index, value in ipairs(tab) do

		if value == val then

			return true

		end

	end

	return false

end

-- Memory scanner
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

-- Adjust camera lens function (for gameplay)
function AC5adjustPerspectiveGameplay_checkKeysFunc()
	
	-- Check if PCSX2 is up and running. if not, disable script.
	
	if (readInteger(EERAMver_AC5adjustPerspective[2]) ~= nil or IsAC5freecamGameplayEnabled ~= nil or IsAC5freecamHangarEnabled ~= nil) ~= false then
		
		-- Reset camera to default value if pincushion distortion value is greater than (camera distortion value * 4).
		if readFloat(AC5adjustPerspective_dataList[1]) >= (camBackgroundLayerW * 4) then
			
			writeFloat(AC5adjustPerspective_dataList[1], camBackgroundLayerW * 4)
			writeFloat(AC5adjustPerspective_dataList[1] + 0x4, camBackgroundLayerH * 4)
			
			writeFloat(AC5adjustPerspective_dataList[3], camObjectLayerW * 4)
			writeFloat(AC5adjustPerspective_dataList[3] + 0x4, camObjectLayerH * 4)
			
		end
		
		-- Reset camera to default value if barrel distortion value is less than (camera distortion value / 4).
		if readFloat(AC5adjustPerspective_dataList[1]) <= (camBackgroundLayerW / 4) then
			
			writeFloat(AC5adjustPerspective_dataList[1], camBackgroundLayerW / 4)
			writeFloat(AC5adjustPerspective_dataList[1] + 0x4, camBackgroundLayerH / 4)
			
			writeFloat(AC5adjustPerspective_dataList[3], camObjectLayerW / 4)
			writeFloat(AC5adjustPerspective_dataList[3] + 0x4, camObjectLayerH / 4)
			
		end
		
		-- Modify towards pincushion distortion
		if (isKeyPressed(VK_UP)) then
			
			-- Width/Height, BG layer
			writeFloat(AC5adjustPerspective_dataList[1], readFloat(AC5adjustPerspective_dataList[1]) + (camBackgroundLayerW / 32))
			writeFloat(AC5adjustPerspective_dataList[1] + 0x4, readFloat(AC5adjustPerspective_dataList[1] + 0x4) + (camBackgroundLayerH / 32))
			
			-- Width/Height, Object layer
			writeFloat(AC5adjustPerspective_dataList[3], readFloat(AC5adjustPerspective_dataList[3]) + (camObjectLayerW / 32))
			writeFloat(AC5adjustPerspective_dataList[3] + 0x4, readFloat(AC5adjustPerspective_dataList[3] + 0x4) + (camObjectLayerH / 32))
			
		elseif (isKeyPressed(VK_DOWN)) then -- Modify towards barrel distortion
			
			-- Width/Height, BG layer
			writeFloat(AC5adjustPerspective_dataList[1], readFloat(AC5adjustPerspective_dataList[1]) - (camBackgroundLayerW / 32))
			writeFloat(AC5adjustPerspective_dataList[1] + 0x4, readFloat(AC5adjustPerspective_dataList[1] + 0x4) - (camBackgroundLayerH / 32))
			
			-- Width/Height, Object layer
			writeFloat(AC5adjustPerspective_dataList[3], readFloat(AC5adjustPerspective_dataList[3]) - (camObjectLayerW / 32))
			writeFloat(AC5adjustPerspective_dataList[3] + 0x4, readFloat(AC5adjustPerspective_dataList[3] + 0x4) - (camObjectLayerH / 32))
			
		elseif (isKeyPressed(VK_LEFT)) then -- Panic key (reset everything)
			
			for i = 1, #AC5adjustPerspective_dataList, 2 do
		
				writeBytes(AC5adjustPerspective_dataList[i], AC5adjustPerspective_dataList[i + 1])
			
			end
			
		end
	
	else
		
		-- Self disable script.
		getAddressList().getMemoryRecordByDescription("Adjust camera lens distortion").Active = false
	
	end
	
	return
	
end

-- Adjust camera lens function (for hangar)
function AC5adjustPerspectiveHangar_checkKeysFunc()
	
	-- Check if PCSX2 is up and running. if not, disable script.
	
	if readInteger(EERAMver_AC5freecamHangar[2]) ~= nil then
		

		-- Modify towards barrel distortion if the DOWN ARROW key is being pressed.
		if (isKeyPressed(VK_DOWN)) then
		
			-- Keep barrel distortion until camera distortion is greater than (camera distortion value * 4).
			if not (readFloat(AC5adjustPerspective_dataList[1]) >= (oldCamHangarFOV * 4)) then
			
				-- Width/Height, BG layer
				writeFloat(AC5adjustPerspective_dataList[1], readFloat(AC5adjustPerspective_dataList[1]) + (oldCamHangarFOV / 32))
			
				-- Hangar lights size adjustment, prevents increasing size as the camera distortion increases.
				writeFloat(AC5adjustPerspective_dataList[3], readFloat(AC5adjustPerspective_dataList[3]) + (oldCamHangarFOV / 1.8))
			
			else -- Stop distortion if camera distortion value is greater than (camera distortion value * 4)
				
				writeFloat(AC5adjustPerspective_dataList[3], readFloat(AC5adjustPerspective_dataList[3]))
				writeFloat(AC5adjustPerspective_dataList[1], oldCamHangarFOV * 4)
			
			end
			
		elseif (isKeyPressed(VK_UP)) then -- Modify towards pincushion distortion
			
			-- Keep pincushion distortion until camera distortion is less than (camera distortion value / 4).
			if not (readFloat(AC5adjustPerspective_dataList[1]) <= (oldCamHangarFOV / 4)) then
			
				-- Width/Height, BG layer
				writeFloat(AC5adjustPerspective_dataList[1], readFloat(AC5adjustPerspective_dataList[1]) - (oldCamHangarFOV / 32))
				
				-- Hangar lights size adjustment, prevents increasing size as the camera distortion increases.
				writeFloat(AC5adjustPerspective_dataList[3], readFloat(AC5adjustPerspective_dataList[3]) - (oldCamHangarFOV / 1.8))
			
			else -- Stop distortion if camera distortion value is less than (camera distortion value / 4)
				
				writeFloat(AC5adjustPerspective_dataList[3], readFloat(AC5adjustPerspective_dataList[3]))
				writeFloat(AC5adjustPerspective_dataList[1], oldCamHangarFOV / 4)
			
			end
			
		elseif (isKeyPressed(VK_LEFT)) then -- Panic key (reset everything)
			
			for i = 1, #AC5adjustPerspective_dataList, 2 do
		
				writeBytes(AC5adjustPerspective_dataList[i], AC5adjustPerspective_dataList[i + 1])
			
			end
			
		end
	
	else
		
		-- Self disable script.
		getAddressList().getMemoryRecordByDescription("Adjust camera lens distortion").Active = false
	
	end
	
	return
	
end

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if any of the "GAMEPLAY" or "FREE MOVEMENT MODE" scripts are active. If false continue with the next check.
if IsAC5freecamGameplayEnabled or IsAC5freecamHangarEnabled then

	-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
	-- Set the working RAM region ranges based on emulator version.
	EERAMver_AC5adjustPerspective = pcsx2_version_check()

	-- Enable script if previous checks were passed.
	IsAC5adjustCamLensEnabled = true

else

	showMessage("<< This script requires either the [GAMEPLAY] or [HANGAR] scripts to be active to work. >>")

end

----------------+
---- [MAIN] ----+
----------------+

if IsAC5adjustCamLensEnabled then
	
	-- Initialize a table to store addresses and values.
	AC5adjustPerspective_dataList = {}
	
	-- Check if the player is in a hangar or in a mission.
	-- Store values according to the current camera view and/or mode.
	
	-- Check if the player is currently in any of the hangars available in the game.
	if readBytes(EERAMver_AC5adjustPerspective[2] + 0x47B87C) == 0 and value_exists({8, 16, 136}, readBytes(EERAMver_AC5adjustPerspective[2] + 0x8D3242, 1)) then
		
		-- Store addresses and data.
		AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = EERAMver_AC5adjustPerspective[2] + 0x5CC628
		AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = readBytes(EERAMver_AC5adjustPerspective[2] + 0x5CC628, 0x4, true)
		
		-- Hangar lamps glow size
		-- Store value of the current hangar.
		if readBytes(EERAMver_AC5adjustPerspective[2] +  0x40D824) == 0 then -- Sand Island
		
			AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = EERAMver_AC5adjustPerspective[2] + 0x3CB0E4
			AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = readBytes(EERAMver_AC5adjustPerspective[2] + 0x3CB0E4, 0x4, true)
		
		elseif readBytes(EERAMver_AC5adjustPerspective[2] +  0x40D824) == 1 then -- Kestrel
		
			AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = EERAMver_AC5adjustPerspective[2] + 0x3CB110
			AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = readBytes(EERAMver_AC5adjustPerspective[2] + 0x3CB110, 0x4, true)
		
		elseif readBytes(EERAMver_AC5adjustPerspective[2] +  0x40D824) == 2 then -- Kirwin Island
		
			AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = EERAMver_AC5adjustPerspective[2] + 0x3CB13C
			AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = readBytes(EERAMver_AC5adjustPerspective[2] + 0x3CB13C, 0x4, true)
		
		elseif readBytes(EERAMver_AC5adjustPerspective[2] +  0x40D824) == 3 then -- ISAF AFB
		
			AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = EERAMver_AC5adjustPerspective[2] + 0x3CB168
			AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = readBytes(EERAMver_AC5adjustPerspective[2] + 0x3CB168, 0x4, true)
		
		end
		
		oldCamHangarFOV = readFloat(AC5adjustPerspective_dataList[1])
		
		-- Initialize timer object for the hotkey function.
		AC5adjustPerspective_hotkeyTimer = createTimer(nil, true) -- Create timer object
		AC5adjustPerspective_hotkeyTimer.Interval = 50 -- Set tick rate
		AC5adjustPerspective_hotkeyTimer.onTimer = AC5adjustPerspectiveHangar_checkKeysFunc -- Call this function every Nms value set in the ".Interval" parameter.
		AC5adjustPerspective_hotkeyTimer.Enabled = true -- Enable the timer object.
	
	elseif (readBytes(EERAMver_AC5freecamGameplay[2] + 0x47B87C, 1) == 1) then -- If in a mission
	
		AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = AC5freecamGameplay_dataList[1] - 0xD20
		AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = readBytes(AC5freecamGameplay_dataList[1] - 0xD20, 0x8, true)
		
		AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = AC5adjustPerspective_dataList[1] + 0x1C0
		AC5adjustPerspective_dataList[#AC5adjustPerspective_dataList + 1] = readBytes(AC5adjustPerspective_dataList[1] + 0x1C0, 0x8, true)
		
		writeBytes(EERAMver_AC5adjustPerspective[2] + 0x3A1C73, 0x0)
		
		camBackgroundLayerW = readFloat(AC5adjustPerspective_dataList[1])
		camBackgroundLayerH = readFloat(AC5adjustPerspective_dataList[1] + 0x4)
		camObjectLayerW = readFloat(AC5adjustPerspective_dataList[3])
		camObjectLayerH = readFloat(AC5adjustPerspective_dataList[3] + 0x4)
		
		-- Initialize timer object for the hotkey function.
		AC5adjustPerspective_hotkeyTimer = createTimer(nil, true) -- Create timer object
		AC5adjustPerspective_hotkeyTimer.Interval = 50 -- Set tick rate
		AC5adjustPerspective_hotkeyTimer.onTimer = AC5adjustPerspectiveGameplay_checkKeysFunc -- Call this function every Nms value set in the ".Interval" parameter.
		AC5adjustPerspective_hotkeyTimer.Enabled = true -- Enable the timer object.
	
	end

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags on script deactivation.
if IsAC5adjustCamLensEnabled then

	if AC5adjustPerspective_hotkeyTimer then

		AC5adjustPerspective_hotkeyTimer.destroy()
		AC5adjustPerspective_hotkeyTimer = nil

	end
	
	if (readInteger(EERAMver_AC5adjustPerspective[2]) ~= nil or IsAC5freecamGameplayEnabled ~= nil or IsAC5freecamHangarEnabled ~= nil) == true then
	
		for i = 1, #AC5adjustPerspective_dataList, 2 do
		
			writeBytes(AC5adjustPerspective_dataList[i], AC5adjustPerspective_dataList[i + 1])
			
		end
		
		writeBytes(EERAMver_AC5adjustPerspective[2] + 0x3A1C73, 0x80)
	
	end
	
	camBackgroundLayerW = nil
	camBackgroundLayerH = nil
	camObjectLayerW = nil
	camObjectLayerH = nil
	oldCamHangarFOV = nil
	
	AC5adjustPerspective_dataList = nil
	IsAC5adjustCamLensEnabled = nil

end

EERAMver_AC5adjustPerspective = nil
