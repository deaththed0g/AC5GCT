{$lua}

--[[
================================================================
==== ACE COMBAT 5: THE UNSUNG WAR - GAMEPLAY FREECAM SCRIPT ====
================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v120226

Special thanks to GG for their debugger handling code.
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

	if process_found[1] ~= nil then -- Check if there's an instance of PCSX2 up.

		if #process_found <= 2 then -- If CE is using AutoAttach then check how many instances of PCSX2 are up.

			if (process_found[2] == getOpenedProcessID()) then -- Check if CE is attached to PCSX2.

				-- Set memory region according to the version of the emulator.
				-- Check if there's a game loaded, too.
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

				error_flag = 1

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

-- "X item exists in Y table" check function
local function value_exists(tab, val)

	for index, value in ipairs(tab) do

		if value == val then

			return true

		end

	end

	return false

end

-- Third-person camera freecam
function AC5freecamGameplay_checkKeysTPS_func(AC5freecamGameplay_checkKeysTPS_timer)

	-- Check if PCSX2 is up and running. if not, disable script.
	if readInteger(EERAMver_AC5freecamGameplay[2]) ~= nil then

		if (isKeyPressed(VK_A)) then   -- [TPS CAM 1] Move left
			writeFloat(AC5freecamGameplay_dataList[1], readFloat(AC5freecamGameplay_dataList[1]) + camera_base_speed)
		elseif (isKeyPressed(VK_D)) then -- [TPS CAM 1] Move right
			writeFloat(AC5freecamGameplay_dataList[1], readFloat(AC5freecamGameplay_dataList[1]) - camera_base_speed)
		elseif (isKeyPressed(VK_S)) then -- [TPS CAM 1] Move down
			writeFloat(AC5freecamGameplay_dataList[1] + 0x4, readFloat(AC5freecamGameplay_dataList[1] + 0x4) + camera_base_speed)
		elseif (isKeyPressed(VK_W)) then -- [TPS CAM 1] Move up
			writeFloat(AC5freecamGameplay_dataList[1] + 0x4, readFloat(AC5freecamGameplay_dataList[1] + 0x4) - camera_base_speed)
		elseif (isKeyPressed(VK_Q)) then -- [TPS CAM 1] Zoom in
			writeFloat(AC5freecamGameplay_dataList[1] + 0x8, readFloat(AC5freecamGameplay_dataList[1] + 0x8) - camera_base_speed)
		elseif (isKeyPressed(VK_E)) then -- [TPS CAM 1] Zoom out
			writeFloat(AC5freecamGameplay_dataList[1] + 0x8, readFloat(AC5freecamGameplay_dataList[1] + 0x8) + camera_base_speed)
		end

		if (isKeyPressed(VK_J)) then -- [TPS CAM 2] Move left
			writeFloat(AC5freecamGameplay_dataList[1] + 0xC, readFloat(AC5freecamGameplay_dataList[1] + 0xC) + camera_base_speed)
		elseif (isKeyPressed(VK_L)) then -- [TPS CAM 2] Move right
			writeFloat(AC5freecamGameplay_dataList[1] + 0xC, readFloat(AC5freecamGameplay_dataList[1] + 0xC) - camera_base_speed)
		elseif (isKeyPressed(VK_K)) then -- [TPS CAM 2] Move down
			writeFloat(AC5freecamGameplay_dataList[1] + 0x10, readFloat(AC5freecamGameplay_dataList[1] + 0x10) + camera_base_speed)
		elseif (isKeyPressed(VK_I)) then -- [TPS CAM 2] Move up
			writeFloat(AC5freecamGameplay_dataList[1] + 0x10, readFloat(AC5freecamGameplay_dataList[1] + 0x10) - camera_base_speed)
		elseif (isKeyPressed(VK_O)) then -- [TPS CAM 2] Zoom out
			writeFloat(AC5freecamGameplay_dataList[1] + 0x14, readFloat(AC5freecamGameplay_dataList[1] + 0x14) - camera_base_speed)
		elseif (isKeyPressed(VK_U)) then -- [TPS CAM 2] Zoom in
			writeFloat(AC5freecamGameplay_dataList[1] + 0x14, readFloat(AC5freecamGameplay_dataList[1] + 0x14) + camera_base_speed)
		end

		-- PYR, zoom, reset
		if (isKeyPressed(VK_NUMPAD2)) then -- Pitch up
				writeFloat(AC5freecamGameplay_dataList[1] + 0xF0, readFloat(AC5freecamGameplay_dataList[1] + 0xF0) + rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD5)) then -- Pitch down
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF0, readFloat(AC5freecamGameplay_dataList[1] + 0xF0) - rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw left
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF4, readFloat(AC5freecamGameplay_dataList[1] + 0xF4) + rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw right
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF4, readFloat(AC5freecamGameplay_dataList[1] + 0xF4) - rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll left
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF8, readFloat(AC5freecamGameplay_dataList[1] + 0xF8) + rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll right
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF8, readFloat(AC5freecamGameplay_dataList[1] + 0xF8) - rotation_base_speed)
		end

		if (isKeyPressed(VK_ADD)) then -- Increase camera XYZ speed
			camera_base_speed = camera_base_speed + camera_move_rate
		elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease camera XYZ speed
			camera_base_speed = camera_base_speed - camera_move_rate
		elseif (isKeyPressed(VK_NUMPAD7)) then -- reset XZY
			writeBytes(AC5freecamGameplay_dataList[1], AC5freecamGameplay_dataList[2][1])
		elseif (isKeyPressed(VK_NUMPAD8)) then -- resetXZY2
			writeBytes(AC5freecamGameplay_dataList[1] + 0xC, AC5freecamGameplay_dataList[2][2])
		elseif (isKeyPressed(VK_NUMPAD9)) then -- resetPYR
			writeBytes(AC5freecamGameplay_dataList[1] + 0xF0, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
		elseif (isKeyPressed(VK_SPACE)) then -- Panic key
			writeBytes(AC5freecamGameplay_dataList[1], AC5freecamGameplay_dataList[2][1])
			writeBytes(AC5freecamGameplay_dataList[1] + 0xC, AC5freecamGameplay_dataList[2][2])
			writeBytes(AC5freecamGameplay_dataList[1] + 0xF0, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
			camera_base_speed = old_camera_base_speed
		end

		if (camera_base_speed <= 0) then -- Reset camera speed value if it goes below 1.0
			camera_base_speed = camera_move_rate
		end

	else

		-- Self disable script.
		getAddressList().getMemoryRecordByDescription("Adjust camera lens distortion").Active = false
		getAddressList().getMemoryRecordByDescription("Gameplay").Active = false

	end

	return

end

-- Cockpit/HUD camera freecam
function AC5freecamGameplay_checkKeysCKPTHUD_func(AC5freecamGameplay_checkKeysCKPTHUD_timer)

	-- Check if PCSX2 is up and running. if not, disable script.
	if readInteger(EERAMver_AC5freecamGameplay[2]) ~= nil then

		-- Cycle through entities:
		-- Press the "2" key to switch focus on the next entity.
		-- Press the "1" key to switch back.
		-- Enable only if the Player is using the HUD view.
		if readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) == 0 then

			if (isKeyPressed(VK_1)) then

				if AC5freecamGameplay_currentEntityID < 2 then

					 AC5freecamGameplay_currentEntityID = #AC5freecamGameplay_entityCoordList

				else

					AC5freecamGameplay_currentEntityID = AC5freecamGameplay_currentEntityID - 1

				end

				writeBytes(AC5freecamGameplay_dataList[1] - 0x5F0, AC5freecamGameplay_entityCoordList[AC5freecamGameplay_currentEntityID])

			elseif (isKeyPressed(VK_2)) then

				if AC5freecamGameplay_currentEntityID > #AC5freecamGameplay_entityCoordList then

					 AC5freecamGameplay_currentEntityID = 2

				else

					AC5freecamGameplay_currentEntityID = AC5freecamGameplay_currentEntityID + 1

				end

				writeBytes(AC5freecamGameplay_dataList[1] - 0x5F0, AC5freecamGameplay_entityCoordList[AC5freecamGameplay_currentEntityID])

			end

		end

		-- Camera XYZ movement
		if (isKeyPressed(VK_A)) then   -- [COCKPIT CAM] Move left
			writeFloat(AC5freecamGameplay_dataList[1] + 0x18, readFloat(AC5freecamGameplay_dataList[1] + 0x18) - camera_base_speed)
		elseif (isKeyPressed(VK_D)) then -- [COCKPIT CAM] Move right
			writeFloat(AC5freecamGameplay_dataList[1] + 0x18, readFloat(AC5freecamGameplay_dataList[1] + 0x18) + camera_base_speed)
		elseif (isKeyPressed(VK_Q)) then -- [COCKPIT CAM] Move down
			writeFloat(AC5freecamGameplay_dataList[1] + 0x1C, readFloat(AC5freecamGameplay_dataList[1] + 0x1C) - camera_base_speed)
		elseif (isKeyPressed(VK_E)) then -- [COCKPIT CAM] Move up
			writeFloat(AC5freecamGameplay_dataList[1] + 0x1C, readFloat(AC5freecamGameplay_dataList[1] + 0x1C) + camera_base_speed)
		elseif (isKeyPressed(VK_S)) then -- [COCKPIT CAM] Move backwards
			writeFloat(AC5freecamGameplay_dataList[1] + 0x20, readFloat(AC5freecamGameplay_dataList[1] + 0x20) + camera_base_speed)
		elseif (isKeyPressed(VK_W)) then -- [COCKPIT CAM] Move forward
			writeFloat(AC5freecamGameplay_dataList[1] + 0x20, readFloat(AC5freecamGameplay_dataList[1] + 0x20) - camera_base_speed)
		end

		-- PYR, zoom, reset
		if (isKeyPressed(VK_NUMPAD2)) then -- Pitch up
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF0, readFloat(AC5freecamGameplay_dataList[1] + 0xF0) + rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD5)) then -- Pitch down
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF0, readFloat(AC5freecamGameplay_dataList[1] + 0xF0) - rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw left
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF4, readFloat(AC5freecamGameplay_dataList[1] + 0xF4) + rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw right
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF4, readFloat(AC5freecamGameplay_dataList[1] + 0xF4) - rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll left
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF8, readFloat(AC5freecamGameplay_dataList[1] + 0xF8) + rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll right
			writeFloat(AC5freecamGameplay_dataList[1] + 0xF8, readFloat(AC5freecamGameplay_dataList[1] + 0xF8) - rotation_base_speed)
		end

		-- Reset position, adjust speeds
		if (isKeyPressed(VK_ADD)) then -- Increase camera XYZ speed
			camera_base_speed = camera_base_speed + camera_move_rate
		elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease camera XYZ speed
			camera_base_speed = camera_base_speed - camera_move_rate
		elseif (isKeyPressed(VK_NUMPAD7)) and readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) ~= 0 then -- reset XZY COCKPIT
			writeBytes(AC5freecamGameplay_dataList[1] + 0x18, AC5freecamGameplay_dataList[2][3])
		elseif (isKeyPressed(VK_NUMPAD9)) then -- resetPYR
			writeBytes(AC5freecamGameplay_dataList[1] + 0xF0, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
		elseif (isKeyPressed(VK_SPACE)) then -- Panic key

			-- While not in HUD view
			if readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) ~= 0 then

				writeBytes(AC5freecamGameplay_dataList[1] + 0x18, AC5freecamGameplay_dataList[2][3])
				writeBytes(AC5freecamGameplay_dataList[1] + 0xF0, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

			else

				writeBytes(AC5freecamGameplay_dataList[1] + 0x18, {0x5D, 0xE6, 0xDA, 0xC2, 0x62, 0xA6, 0x8B, 0x42, 0x97, 0xD9, 0xA4, 0xC2})
				writeBytes(AC5freecamGameplay_dataList[1] + 0xF0, {0x00, 0x00, 0x00, 0xBF, 0x01, 0x00, 0x00, 0xC0, 0x00, 0x00, 0x00, 0x00})

			end

			camera_base_speed = old_camera_base_speed

		end

		if (camera_base_speed <= 0) then -- Reset camera speed value if it goes below 1.0
			camera_base_speed = camera_move_rate
		end

	else

		-- Self disable script.
		getAddressList().getMemoryRecordByDescription("Gameplay").Active = false

	end

	return

end

-- Switch
function switch(bool)

	if bool then

		-- Disable control input
		writeBytes(EERAMver_AC5freecamGameplay[2] + 0x4459B0, {0x00, 0x00, 0x00, 0x00})

		---- if 4:3 then:
		---- if 16:9 then:

		if readBytes(EERAMver_AC5freecamGameplay[2] + 0x40CEA4, 1) == 0 then -- if Screen Ratio is set to 4:3

			writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980C, 0xC3)

		else -- Do the same as above if the Screen Ratio is set to 16:9

			writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980C, 0xCB)

		end

		-- Remove HUD
		writeBytes(AC5freecamGameplay_dataList[3], {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
		writeBytes(AC5freecamGameplay_dataList[3] + 0x10, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})

		writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980D, 0x0)

		-- Remove HUD elements
		-- Alternate, unfortunately it removes the sun graphics when enabled.
		--writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C9A14, 0x0B)

		-- Disable camera opcodes
		for i = 1, #AC5freecamGameplay_addressListAOB, 2 do
			
			local tempArray = {}
			
			for i = 1, #AC5freecamGameplay_addressListAOB[i + 1] do
				
				tempArray[#tempArray + 1] = 0x90
			
			end
		
			writeBytes(AC5freecamGameplay_addressListAOB[i], tempArray)
		
		end

	else

		writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980D, 0x0E)

		-- Restore HUD
		writeBytes(AC5freecamGameplay_dataList[3], AC5freecamGameplay_dataList[4])

		-- Restore camera opcodes
		for i = 1, #AC5freecamGameplay_addressListAOB do

			writeBytes(AC5freecamGameplay_addressListAOB[i], {0x0F, 0x29, 0x09})

		end

		-- Restore camera coordinates.
		if readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) == 2 then

			writeBytes(AC5freecamGameplay_dataList[1] + 0x18, AC5freecamGameplay_dataList[2][3])

		else

			writeBytes(AC5freecamGameplay_dataList[1], AC5freecamGameplay_dataList[2][1])
			writeBytes(AC5freecamGameplay_dataList[1] + 0xC, AC5freecamGameplay_dataList[2][2])
			writeBytes(AC5freecamGameplay_dataList[1] + 0x18, AC5freecamGameplay_dataList[2][3])

		end

		-- Restore control input
		writeBytes(EERAMver_AC5freecamGameplay[2] + 0x4459B0, {0x80, 0x7B, 0x48, 0x00})

		if readBytes(EERAMver_AC5freecamGameplay[2] + 0x40CEA4, 1) == 0 then

			if value_exists({4, 5}, readBytes(EERAMver_AC5freecamGameplay[2] + 0x6CD49C, 1)) then

				writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980C, 0xC2)

			else

				writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980C, 0xC2)

			end

		else

			if value_exists({4, 5}, readBytes(EERAMver_AC5freecamGameplay[2] + 0x6CD49C, 1)) then

				writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980C, 0xCA)

			else

				writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980C, 0xCA)

			end

		end

	end

	return

end

-- Debugger handling
function AC5freecamGameplay_detachDebugger()

	-- For every time the AC5freecamGameplay_detachDebugger() function is called
	-- add +1 to the hitsFound global variable. If the amount is equal to 2 then
	-- proceed with the main block of the script.
	hitsFound = hitsFound + 1

	-- Only proceed if we have all the data we need
	if hitsFound == 1 then

		-- This Timer is the secret to preventing the "Hang"
		local t = createTimer(nil)
		t.Interval = 100
		t.OnTimer = function(timer)

			timer.destroy() -- Always destroy the timer once it's used

			-- Safe to detach now because the Debugger callback has finished
			detachIfPossible()

			-- Enable script if all checks were passed.
			IsAC5freecamGameplayEnabled = true

			-- Safe to run the rest of your script (MAIN block)
			AC5freecamGameplay_mainBlock()

		end

	end

end

------------------+
---- [TABLES] ----+
------------------+

AC5freecamGameplay_dataList = {}
AC5freecamGameplay_addressListAOB = {}
AC5freecamGameplay_entityCoordList = {}
hitsFound = 0

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if any of the "HANGAR", "ADJUST THIRD PERSON CAMERA DISTANCE" or "FREE MOVEMENT MODE" scripts are active. If false continue with the next check.
if (IsAC5adjustTPSviewCamEnabled or IsAC5freeMovementEnabled) ~= true then

	-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
	-- Set the working RAM region ranges based on emulator version.
	EERAMver_AC5freecamGameplay = pcsx2_version_check()

	if (EERAMver_AC5freecamGameplay[3] == nil) then

		-- Check if the emulator has the right game loaded.
		local SLUS_20851_check = memscan_func(soExactValue, vtByteArray, nil, "80 55 42 00 90 55 42 00 A0 55 42 00 B0 55 42 00", nil, EERAMver_AC5freecamGameplay[2] + 0x300000, EERAMver_AC5freecamGameplay[2] + 0x4000000, "", 2, "0", true, nil, nil, nil)

		if #SLUS_20851_check ~= 0 then

			-- Check if cheat needed by this script is enabled.
			if readBytes(EERAMver_AC5freecamGameplay[2] + 0x15CF04, 2) == 0 then

				-- Check if the player is currently in a mission.
				if (readBytes(EERAMver_AC5freecamGameplay[2] + 0x47B87C, 1) == 1) then

					-- Check if the script can be used in the current game state.
					-- 0 = normal gameplay
					-- 4 = landing
					-- 5 = take-off
					-- 6 = air refueling (2, 3)

					if value_exists({768, 518, 774, 516, 772, 517, 773}, readSmallInteger(EERAMver_AC5freecamGameplay[2] + 0x6CD49C, 2)) then

						-- Look for the camera coordinates.
						local tempScan = memscan_func(soExactValue, vtByteArray, nil, "00 00 20 44 00 00 ?? 43 ?? ?? ?? ?? ?? ?? ?? ?? 00 00 ?? ?? 00 00 00 00 00 02 C0 01 00 00 80 3F FF FF 7F 4B 00 00 00 00 00 02 C0 01 00 00", nil, EERAMver_AC5freecamGameplay[2] + 0x800000, EERAMver_AC5freecamGameplay[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)

						-- Filter scan results to obtain the right address.
						for i = 1, #tempScan do

							if readInteger(tempScan[i] - 0xCC0) == 5063489 then

								AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = tempScan[#tempScan] + 0xD20

							end

						end

						-- //[OPCODE]//
						-- Credit to G.G for this part of the code.

						-- Get the instruction that is writing the camera PYR movement.
						debug_setBreakpoint(AC5freecamGameplay_dataList[1] + 0xF0, 1, bptWrite, function()

							-- 1. Step back to the instruction that caused the break
							-- This handles the "3 or 4 byte" difference automatically
							local targetOpcodeAddr = getPreviousOpcode(RIP)

							-- 2. Capture the address and the original bytes
							-- We read the instruction size dynamically to be safe
							local instrSize = RIP - targetOpcodeAddr

							-- Store opcode offset and its bytes.
							AC5freecamGameplay_addressListAOB[#AC5freecamGameplay_addressListAOB + 1] = targetOpcodeAddr
							AC5freecamGameplay_addressListAOB[#AC5freecamGameplay_addressListAOB + 1] = readBytes(targetOpcodeAddr, instrSize, true)

							-- Detach debugger and resume game.
							debug_removeBreakpoint(AC5freecamGameplay_dataList[1] + 0xF0)

							AC5freecamGameplay_detachDebugger()

							if co_run then

								debug_continueFromBreakpoint(co_run)

							end

							return 1 -- This MUST return before detachIfPossible() is called

						end)

					else

						showMessage("<< The script won't work while cutscenes are playing. >>")


					end

				else

					showMessage("<< You'll need to be in a mission to use this script. >>")


				end

			else

				showMessage("<< Please activate the [AC5GCT: 'GAMEPLAY' SCRIPT CAMERA CODES] cheat before using this script!. >>")


			end

		else

			showMessage("<< This script is not compatible with the game you're currently emulating. >>")


		end

	else

		if EERAMver_AC5freecamGameplay[3] == 1 then

			showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

		elseif EERAMver_AC5freecamGameplay[3] == 2 then

			showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

		elseif EERAMver_AC5freecamGameplay[3] == 3 then

			showMessage("<< PCSX2 has no ISO file loaded. >>")

		end

	end

else

	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [ADJUST THIRD PERSON CAMERA DISTANCE]".."\n- [FREE MOVEMENT MODE]".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+

-- Since the main block of the code is a huge function I should move it to its right section
-- but I'll leave it here for consistency.
function AC5freecamGameplay_mainBlock()

	if IsAC5freecamGameplayEnabled then

		-- Backup old coordinate data for restoration on script exit.
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = {readBytes(AC5freecamGameplay_dataList[1], 12, true), readBytes(AC5freecamGameplay_dataList[1] + 0xC, 12, true), readBytes(AC5freecamGameplay_dataList[1] + 0x18, 12, true)}

		-- Backup HUD visibility flag.
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5freecamGameplay_dataList[1] - 0x13C
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5freecamGameplay_dataList[1] - 0x13C, 4, true)

		-- Create a global header to attach the other sub-header and memory records that will be create on script activation.
		AC5freecamGameplay_main_header = create_header("[CAMERA] GAMEPLAY FREECAM", nil, nil)

		-- //[CAMERA XZY/PYR COORDINATES]//
		-- Set record descriptions and offsets according to current camera view.
		-- Create header and memory records to display the camera's current XYZ coordinates.
		-- Store camera's last XYZ coordinates previous to script activation to use it with the restore function.
		local camera_coordinates_header = create_header("Current camera coordinates", AC5freecamGameplay_main_header, true)
		local camera_coordinates_base_address = AC5freecamGameplay_dataList[1]

		if readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) == 1 then -- If camera view is TPS

			local offset_list = {0x0, 0x4, 0x8, 0xC, 0x10, 0x14, 0xF0, 0xF4, 0xF8}
			local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "X coordinate (anchor)", "Y coordinate (anchor)", "Z coordinate (anchor)", "Pitch", "Yaw", "Roll"}
			local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}

			create_memory_record(camera_coordinates_base_address, offset_list, vt_list, description_list, camera_coordinates_header)

		elseif readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) == 2 or readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) == 0 then -- If camera view is cockpit or HUD

			local offset_list = {0x18, 0x1C, 0x20, 0xF0, 0xF4, 0xF8}
			local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "Pitch", "Yaw", "Roll"}
			local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}

			create_memory_record(camera_coordinates_base_address, offset_list, vt_list, description_list, camera_coordinates_header)

		end

		-- //[HOTKEYS]//
		-- Set base rotation speed.
		-- Before setting it check for the current camera view. HUD, cockpit views as well during landing/takeoff reverse the rotation speed value. Reversing the value will only work with the HUD/cockpit views only.
		-- Set action/movement hotkeys function.
		-- Create and enable timer on script activation.
		-- If activating HUD freecam then list all entities present in the current mission and store their XYZ coordinates.

		-- Camera views values:
		---- 0 = HUD view
		---- 1 = Third-person view
		---- 2 = Cockpit view

		-- Abbreviations:
		---- TPS: Third-Person Camera
		---- CAM: Camera

		if readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) == 1 then

			camera_base_speed, old_camera_base_speed = 1.0, 1.0
			camera_move_rate = 0.5
			rotation_base_speed = 0.07853981633

			AC5freecamGameplay_hotkey_Timer = createTimer() -- Create timer object
			AC5freecamGameplay_hotkey_Timer.Interval = 50 -- Set tick rate
			AC5freecamGameplay_hotkey_Timer.onTimer = AC5freecamGameplay_checkKeysTPS_func -- Call this function every Nms value set in the ".Interval" parameter.
			AC5freecamGameplay_hotkey_Timer.Enabled = true -- Enable the timer object.

		elseif value_exists({0, 2}, readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1)) then

			if readBytes(EERAMver_AC5freecamGameplay[2] + 0x959C0C, 1) == 2 then

				camera_base_speed, old_camera_base_speed = 0.1, 0.1
				camera_move_rate = 0.125
				rotation_base_speed = -0.07853981633

			else

				camera_base_speed, old_camera_base_speed = 0.5, 0.5
				camera_move_rate = 0.250
				rotation_base_speed = -0.07853981633

				-- Entity listing
				AC5freecamGameplay_currentEntityID = 2

				local tempScan = memscan_func(soExactValue, vtByteArray, nil, "CC CC 4C 42", nil, EERAMver_AC5freecamGameplay[2] + 0x800000, EERAMver_AC5freecamGameplay[2] + 0x1F00000, "", 2, "8", true, nil, nil, nil)

				--for i = 1, readBytes(EERAMver_AC5freecamGameplay[2] + 0x9895D4, 1) do -- Counter for the amount of entities in the current mission.

				for i = 1, #tempScan do

					-- Filter and remove entities that are not yet active or garbage data.
					if readInteger(tempScan[i] - 0x10C) == 1065353216 then

						AC5freecamGameplay_entityCoordList[#AC5freecamGameplay_entityCoordList + 1] = tempScan[i] - 0x118
						AC5freecamGameplay_entityCoordList[#AC5freecamGameplay_entityCoordList + 1] = readBytes(tempScan[i] - 0x118, 0x1C, true)

					end

				end

				-- If activating the script in HUD mode, set default camera position for this view.
				writeBytes(AC5freecamGameplay_dataList[1] + 0x18, {0x5D, 0xE6, 0xDA, 0xC2, 0x62, 0xA6, 0x8B, 0x42, 0x97, 0xD9, 0xA4, 0xC2})
				writeBytes(AC5freecamGameplay_dataList[1] + 0xF0, {0x00, 0x00, 0x00, 0xBF, 0x01, 0x00, 0x00, 0xC0, 0x00, 0x00, 0x00, 0x00})

			end

			AC5freecamGameplay_hotkey_Timer = createTimer() -- Create timer object
			AC5freecamGameplay_hotkey_Timer.Interval = 50 -- Set tick rate
			AC5freecamGameplay_hotkey_Timer.onTimer = AC5freecamGameplay_checkKeysCKPTHUD_func -- Call this function every Nms value set in the ".Interval" parameter.
			AC5freecamGameplay_hotkey_Timer.Enabled = true -- Enable the timer object.

		end

		switch(true)

	end

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any, remove stray debug breakpoints and clear flags and tables on script deactivation.
if IsAC5freecamGameplayEnabled then

	if AC5freecamGameplay_hotkey_Timer then

		AC5freecamGameplay_hotkey_Timer.destroy()
		AC5freecamGameplay_hotkey_Timer = nil

	end

	if readInteger(EERAMver_AC5freecamGameplay[2]) ~= nil then

		-- // Debugger cleanup
		-- Process exists: Clean cleanup
		local bplist = debug_getBreakpointList()

		if bplist then

			for i=1, #bplist do debug_removeBreakpoint(bplist[i]) end

		end

		-- Use a quick timer to detach so the script can finish the current 'Disable' cycle first
		local t = createTimer(nil)
		t.Interval = 100
		t.OnTimer = function(timer)

			timer.destroy()
			detachIfPossible()

		end

		-- Restore controls, HUD, etc.
		switch(false)

	else

		-- Process is DEAD:
		-- We can't remove specific breakpoints because the memory is gone,
		-- but we call this to tell CE the debugger is now "Free".
		-- Use a quick timer to detach so the script can finish the current 'Disable' cycle first
		local t = createTimer(nil)
		t.Interval = 100
		t.OnTimer = function(timer)

			timer.destroy()
			detachIfPossible()

		end

	end

	AC5freecamGameplay_main_header.destroy()

	getAddressList().getMemoryRecordByDescription("Adjust camera lens distortion").Active = false

	camera_base_speed = nil
	camera_move_rate = nil
	rotation_base_speed = nil

	AC5freecamGameplay_addressListAOB = nil
	AC5freecamGameplay_dataList = nil
	AC5freecamGameplay_entityCoordList = nil

	AC5freecamGameplay_currentEntityID = nil
	hitsFound = nil

	IsAC5freecamGameplayEnabled = nil

end

EERAMver_AC5freecamGameplay = nil
