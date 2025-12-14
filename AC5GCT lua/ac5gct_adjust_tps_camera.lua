{$lua}

--[[
============================================================================
==== ACE COMBAT 5: THE UNSUNG WAR - ADJUST THIRD POSITION CAMERA SCRIPT ====
============================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v151125

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

------------------+
---- [TABLES] ----+
------------------+

AC5adjustTPSviewCam_dataList = {}

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if any of the "GAMEPLAY" or "FREE MOVEMENT MODE" scripts are active. If false continue with the next check.
if (IsAC5freecamGameplayEnabled or IsAC5freeMovementEnabled ) ~= true then

	-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
	-- Set the working RAM region ranges based on emulator version.
	EERAMver_AC5adjustTPSviewCam = pcsx2_version_check()

	if (EERAMver_AC5adjustTPSviewCam[3] == nil) then

		-- Check if the emulator version is compatible with this script.
		if (EERAMver_AC5adjustTPSviewCam[1] == 2) then

			-- Check if the emulator has the right game loaded.
			local SLUS_20851_check = memscan_func(soExactValue, vtByteArray, nil, "80 55 42 00 90 55 42 00 A0 55 42 00 B0 55 42 00", nil, EERAMver_AC5adjustTPSviewCam[2] + 0x300000, EERAMver_AC5adjustTPSviewCam[2] + 0x4000000, "", 2, "0", true, nil, nil, nil)

			if #SLUS_20851_check ~= 0 then

				-- Check if the player is currently in a mission.
				if (readBytes(EERAMver_AC5adjustTPSviewCam[2] + 0x47B87C, 1) == 1) then
				
					-- Look for the camera coordinates.
					local camCoord = memscan_func(soExactValue, vtByteArray, nil, "00 00 20 44 00 00 ?? 43 ?? ?? ?? ?? ?? ?? ?? ?? 00 00 ?? ?? 00 00 00 00 00 02 C0 01 00 00 80 3F FF FF 7F 4B 00 00 00 00 00 02 C0 01 00 00", nil, EERAMver_AC5adjustTPSviewCam[2] + 0x800000, EERAMver_AC5adjustTPSviewCam[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
				
					-- Filter scan results and keep the right address.
					if #camCoord ~= 0 then
					
						for i = 1, #camCoord do
								
							if readInteger(camCoord[i] + 0xBF8) ~= 0 and readInteger(camCoord[i] + 0xBFC) == 0 then
								
								AC5adjustTPSviewCam_dataList[#AC5adjustTPSviewCam_dataList + 1] = camCoord[#camCoord] + 0xD28
									
							end
								
						end
						
						-- Enable script if all checks were passed.
						IsAC5adjustTPSviewCamEnabled = true
				
					else
				
						showMessage("<< Unable to activate this script (camCoord search returned nil). >>")
				
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

		if EERAMver_AC5adjustTPSviewCam[3] == 1 then

			showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

		elseif EERAMver_AC5adjustTPSviewCam[3] == 2 then

			showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

		elseif EERAMver_AC5adjustTPSviewCam[3] == 3 then

			showMessage("<< PCSX2 has no ISO file loaded. >>")

		end

	end

else

	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [GAMEPLAY]".."\n- [FREE MOVEMENT MODE]".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+

if IsAC5adjustTPSviewCamEnabled then

	-- //[CAMERA XZY/PYR COORDINATES]//
	-- Read and store the aircraft's third-person camera's Z coordinate to restore it on script deactivation.
	AC5adjustTPSviewCam_dataList[#AC5adjustTPSviewCam_dataList + 1] = readBytes(AC5adjustTPSviewCam_dataList[1], 4, true)
	
	-- //[HOTKEYS]//
	-- Store aircraft's Z camera position/coordinate previous to script activation to use it with the restore function later.
	-- Define hotkey function, speed modifier and create timer.
	
	local default_zcoord_value = readFloat(AC5adjustTPSviewCam_dataList[1]) -- Original camera's Z position value.
	local camera_base_speed = 5 -- Camera zoom speed.
	
	-- Adjust camera function.
	local function AC5adjustTPSviewCam_checkKeysFunc()
		
		-- Check if PCSX2 is up and running. if not, disable script.
		if readInteger(EERAMver_AC5adjustTPSviewCam[2]) ~= nil then
	
			if readFloat(AC5adjustTPSviewCam_dataList[1]) < default_zcoord_value then -- Reset Z position if its current value is lower than the one stored in "default_zcoord_value".
			
				writeBytes(AC5adjustTPSviewCam_dataList[1], AC5adjustTPSviewCam_dataList[2])
				
			end
			
			if (isKeyPressed(VK_ADD)) then -- [TPS CAM 1] Zoom in if ADD NUMPAD is being pressed.
			
				writeFloat(AC5adjustTPSviewCam_dataList[1], readFloat(AC5adjustTPSviewCam_dataList[1]) - camera_base_speed)
				
			elseif (isKeyPressed(VK_SUBTRACT)) then -- [TPS CAM 1] Zoom out if SUBSTRACT NUMPAD is being pressed.
			
				writeFloat(AC5adjustTPSviewCam_dataList[1], readFloat(AC5adjustTPSviewCam_dataList[1]) + camera_base_speed)
				
			elseif (isKeyPressed(VK_NUMPAD0)) then -- Panic key (reset everything) if NUMPAD 0 was pressed.
			
				writeBytes(AC5adjustTPSviewCam_dataList[1], AC5adjustTPSviewCam_dataList[2])
				
			end
		
		else
			
			-- Self disable script.
			getAddressList().getMemoryRecordByDescription("Adjust third person camera distance").Active = false
		
		end
		
		return
		
	end
	
	-- Initialize timer object for the hotkey function.
	AC5adjustTPSviewCam_hotkeyTimer = createTimer(nil, true) -- Create timer object
	AC5adjustTPSviewCam_hotkeyTimer.Interval = 80 -- Set tick rate
	AC5adjustTPSviewCam_hotkeyTimer.onTimer = AC5adjustTPSviewCam_checkKeysFunc -- Call this function every Nms value set in the ".Interval" parameter.
	AC5adjustTPSviewCam_hotkeyTimer.Enabled = true -- Enable the timer object.


end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags on script deactivation.
if IsAC5adjustTPSviewCamEnabled then

	if AC5adjustTPSviewCam_hotkeyTimer then

		AC5adjustTPSviewCam_hotkeyTimer.destroy()
		AC5adjustTPSviewCam_hotkeyTimer = nil

	end
	
	if readInteger(EERAMver_AC5adjustTPSviewCam[2]) ~= nil then
	
		if (readBytes(EERAMver_AC5adjustTPSviewCam[2] + 0x47B87C, 1) == 1) then
			
			writeBytes(AC5adjustTPSviewCam_dataList[1], AC5adjustTPSviewCam_dataList[2])
		
		end
	
	end

	AC5adjustTPSviewCam_dataList = nil

	IsAC5adjustTPSviewCamEnabled = nil

end

EERAMver_AC5adjustTPSviewCam = nil
