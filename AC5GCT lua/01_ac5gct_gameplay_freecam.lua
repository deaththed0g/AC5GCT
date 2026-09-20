{$lua}

--[[
================================================================
==== ACE COMBAT 5: THE UNSUNG WAR - GAMEPLAY FREECAM SCRIPT ====
================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v190926

Credit to anonymous from CE forums for their debugger handling code.
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

-----------------------+
---- [GLOBAL VAR.] ----+
-----------------------+
AC5freecamGameplay_nextCycleTime1 = 0
AC5freecamGameplay_nextCycleTime2 = 0
AC5freecamGameplay_holdDelay = 150

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

-- Camera freecam controls
local function AC5freecamGameplay_mainFunc(screenWidthF, screenWidthF_old, screenHeightF, screenHeightF_old, screenWidthB, screenWidthB_old, screenHeightB, screenHeightB_old, distortionFactorW, distortionFactorW_old, distortionFactorH, distortionFactorH_old, distortionLimitMaxW, distortionLimitMaxH, distortionLimitMinW, distortionLimitMinH, xPosS1, xPosS1_old, zPosS1, zPosS1_old, yPosS1, yPosS1_old, xPosS2, xPosS2_old, zPosS2, zPosS2_old, yPosS2, yPosS2_old, pRot, pRot_old, yRot, yRot_old, rRot, rRot_old, camera_base_speed, currentEntityID, currentCamView, customCoordSet1, customCoordSet2, lightVal1, lightVal1_old, lightVal2, lightVal2_old)

	-- Write lighting value for the player aircraft's separate pieces (such as missiles, etc).
	writeFloat(AC5freecamGameplay_dataList[37], readFloat(AC5freecamGameplay_dataList[33]))

	-- Calculate factor that will be used for some operations within the scope of this function.
	local factor = distortionFactorW / distortionFactorW_old

	-- Calculate camera rotation speed.
	local rotSpeed = 0.1 / factor

	-- Clamp rotation speed if screen projection is bigger that 0.1.
	-- This will prevent the camera from moving very fast when the screen distortion
	-- leans towards the pincushion type.
	if rotSpeed >= 0.1 then
		rotSpeed = 0.1
	end

	-- Focus on entity (only available if using the HUD camera view).
	if currentCamView == 0 then

		local currentTime = getTickCount() -- Get the current time exactly once per timer tick

		-- Check VK_1
		if (isKeyPressed(VK_1)) then 
			if currentTime >= AC5freecamGameplay_nextCycleTime1 then -- Only trigger if enough time has passed
				AC5freecamGameplay_nextCycleTime1 = currentTime + AC5freecamGameplay_holdDelay -- Set the timestamp for the next allowed switch
				currentEntityID = currentEntityID - 1
				if currentEntityID < 1 then
					currentEntityID = #AC5freecamGameplay_entityCoordList
				end
				writeBytes(xPosS1 - 0x608, AC5freecamGameplay_entityCoordList[currentEntityID])
				writeBytes(xPosS1, customCoordSet1)
				writeBytes(pRot, customCoordSet2)
			end
		else
			-- CRITICAL: Reset the cooldown immediately when the key is released.
			-- This ensures that if you tap the key rapidly yourself, it feels instantly responsive.
			AC5freecamGameplay_nextCycleTime1 = 0 
		end

		-- Check VK_2
		if (isKeyPressed(VK_2)) then 
			if currentTime >= AC5freecamGameplay_nextCycleTime2 then 
				AC5freecamGameplay_nextCycleTime2 = currentTime + AC5freecamGameplay_holdDelay 
				currentEntityID = currentEntityID + 1
				if currentEntityID > #AC5freecamGameplay_entityCoordList then
					currentEntityID = 1
				end
				writeBytes(xPosS1 - 0x608, AC5freecamGameplay_entityCoordList[currentEntityID])
				writeBytes(xPosS1, customCoordSet1)
				writeBytes(pRot, customCoordSet2)
			end
		else
			AC5freecamGameplay_nextCycleTime2 = 0 
		end

	end

	-- Move camera, write movement values according to current camera view.
	-- The descriptions of the directional movement keys assume
	-- that the camera's current pitch, yaw and roll axis values are {0, 0, 0}.

	-- Player is third-person camera view.
	if currentCamView == 1 then

		if (isKeyPressed(VK_A)) then -- Move left
			writeFloat(xPosS1, readFloat(xPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_D)) then -- Move right
			writeFloat(xPosS1, readFloat(xPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_S)) then -- Move down
			writeFloat(zPosS1, readFloat(zPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_W)) then -- Move up
			writeFloat(zPosS1, readFloat(zPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_Q)) then -- Move backwards
			writeFloat(yPosS1, readFloat(yPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_E)) then -- Move forward
			writeFloat(yPosS1, readFloat(yPosS1) + camera_base_speed)
		end

		if (isKeyPressed(VK_J)) then -- Move left
			writeFloat(xPosS2, readFloat(xPosS2) + camera_base_speed)
		elseif (isKeyPressed(VK_L)) then -- Move right
			writeFloat(xPosS2, readFloat(xPosS2) - camera_base_speed)
		elseif (isKeyPressed(VK_K)) then -- Move down
			writeFloat(zPosS2, readFloat(zPosS2) + camera_base_speed)
		elseif (isKeyPressed(VK_I)) then -- Move up
			writeFloat(zPosS2, readFloat(zPosS2) - camera_base_speed)
		elseif (isKeyPressed(VK_U)) then -- Move backwards
			writeFloat(yPosS2, readFloat(yPosS2) - camera_base_speed)
		elseif (isKeyPressed(VK_O)) then -- Move forward
			writeFloat(yPosS2, readFloat(yPosS2) + camera_base_speed)
		end

	else -- Cockpit or HUD.

		if (isKeyPressed(VK_A)) then -- Move left
			writeFloat(xPosS1, readFloat(xPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_D)) then -- Move right
			writeFloat(xPosS1, readFloat(xPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_S)) then -- Move down
			writeFloat(zPosS1, readFloat(zPosS1) - camera_base_speed)
		elseif (isKeyPressed(VK_W)) then -- Move up
			writeFloat(zPosS1, readFloat(zPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_Q)) then -- Move backwards
			writeFloat(yPosS1, readFloat(yPosS1) + camera_base_speed)
		elseif (isKeyPressed(VK_E)) then -- Move forward
			writeFloat(yPosS1, readFloat(yPosS1) - camera_base_speed)
		end

	end

	-- Camera rotation movement gets inverted while in HUD or cockpit view
	-- so invert rotSpeed value.
	if currentCamView == 0 or currentCamView == 2 then
		rotSpeed = -rotSpeed
	end

	-- Camera's pitch, yaw and roll control.
	if (isKeyPressed(VK_NUMPAD5)) then -- Pitch up
		writeFloat(pRot, readFloat(pRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD2)) then -- Pitch down
		writeFloat(pRot, readFloat(pRot) + rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw left
		writeFloat(yRot, readFloat(yRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw right
		writeFloat(yRot, readFloat(yRot) + rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll left
		writeFloat(rRot, readFloat(rRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll right
		writeFloat(rRot, readFloat(rRot) + rotSpeed)
	end

	-- Camera lens distortion.
	if (isKeyPressed(VK_UP)) then -- Pincushion distortion
		-- Clamp if the screen width exceeds the defined limit.
		if readFloat(screenWidthF) >= distortionLimitMaxW then
			writeFloat(screenWidthF, distortionLimitMaxW)
			writeFloat(screenHeightF, distortionLimitMaxH)
			writeFloat(screenWidthB, distortionLimitMaxW)
			writeFloat(screenHeightB, distortionLimitMaxH)
		else
			distortionFactorW = distortionFactorW * 0.99
			distortionFactorH = distortionFactorH * 0.99
			writeFloat(screenWidthF, 512.0 / distortionFactorW)
			writeFloat(screenHeightF, 448.0 / distortionFactorH)
			writeFloat(screenWidthB, 512.0 / distortionFactorW)
			writeFloat(screenHeightB, 448.0 / distortionFactorH)
		end
	elseif (isKeyPressed(VK_DOWN)) then -- Barrel distortion.
		-- Clamp if the screen width exceeds the defined limit.
		if readFloat(screenWidthF) <= distortionLimitMinW then
			writeFloat(screenWidthF, distortionLimitMinW)
			writeFloat(screenHeightF, distortionLimitMinH)
			writeFloat(screenWidthB, distortionLimitMinW)
			writeFloat(screenHeightB, distortionLimitMinH)
		else
			distortionFactorW = distortionFactorW * 1.01
			distortionFactorH = distortionFactorH * 1.01
			writeFloat(screenWidthF, 512.0 / distortionFactorW)
			writeFloat(screenHeightF, 448.0 / distortionFactorH)
			writeFloat(screenWidthB, 512.0 / distortionFactorW)
			writeFloat(screenHeightB, 448.0 / distortionFactorH)
		end
	elseif (isKeyPressed(VK_LEFT)) then -- Reset screen resolution and projection scale values.
		writeBytes(screenWidthF, screenWidthB_old)
		writeBytes(screenHeightF, screenHeightB_old)
		writeBytes(screenWidthB, screenWidthB_old)
		writeBytes(screenHeightB, screenHeightB_old)
		distortionFactorW = distortionFactorW_old
		distortionFactorH = distortionFactorH_old
	end

	-- Camera movement speed adjustment, reset keys.
	if (isKeyPressed(VK_ADD)) then -- Increase movement speed.
		camera_base_speed = camera_base_speed + 0.1 / factor
	elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease movement speed.
		camera_base_speed = camera_base_speed - 0.1 / factor
	elseif (isKeyPressed(VK_NUMPAD7)) then -- Reset camera position.
		if currentCamView ~= 0 then
			writeBytes(xPosS1, xPosS1_old)
			writeBytes(zPosS1, zPosS1_old)
			writeBytes(yPosS1, yPosS1_old)
		else
			writeBytes(xPosS1, customCoordSet1)
		end
	elseif (isKeyPressed(VK_NUMPAD8)) and currentCamView == 1 then -- Reset camera's point of origin (third-person camera view only).
		writeBytes(xPosS2, xPosS2_old)
		writeBytes(zPosS2, zPosS2_old)
		writeBytes(yPosS2, yPosS2_old)
	elseif (isKeyPressed(VK_NUMPAD9)) then -- Reset camera axis position.
		if currentCamView ~= 0 then
			writeBytes(pRot, pRot_old)
			writeBytes(yRot, yRot_old)
			writeBytes(rRot, rRot_old)
		else
			writeBytes(xPosS1, customCoordSet1)
			writeBytes(pRot, customCoordSet2)
		end
	elseif (isKeyPressed(VK_SPACE)) then --Panic key (reset !!!EVERYTHING!!!).
		if currentCamView ~= 0 then
			writeBytes(xPosS1, xPosS1_old)
			writeBytes(zPosS1, zPosS1_old)
			writeBytes(yPosS1, yPosS1_old)
			writeBytes(pRot, pRot_old)
			writeBytes(yRot, yRot_old)
			writeBytes(rRot, rRot_old)
		else
			writeBytes(xPosS1, customCoordSet1)
			writeBytes(pRot, customCoordSet2)
		end
		if currentCamView == 1 then
			writeBytes(xPosS2, xPosS2_old)
			writeBytes(zPosS2, zPosS2_old)
			writeBytes(yPosS2, yPosS2_old)
		end
		writeBytes(screenWidthF, screenWidthB_old)
		writeBytes(screenHeightF, screenHeightB_old)
		writeBytes(screenWidthB, screenWidthB_old)
		writeBytes(screenHeightB, screenHeightB_old)
		writeBytes(lightVal1, lightVal1_old)
		writeBytes(lightVal2, lightVal2_old)
		distortionFactorW = distortionFactorW_old
		distortionFactorH = distortionFactorH_old
		camera_base_speed = 0.1
	end

	-- Clamp camera movement speed if value is less than zero.
	if (camera_base_speed <= 0) then 
		camera_base_speed = 0.1
	end

	-- Return the modified variables back to the timer.
	return distortionFactorW, distortionFactorH, camera_base_speed, currentEntityID

end

-- Switch
function switch(bool)

	if bool then -- On script activation.

		-- Disable control input
		writeBytes(EERAMver_AC5freecamGameplay[2] + 0x4459B0, {0x00, 0x00, 0x00, 0x00})

		-- Pause game.
		if readBytes(EERAMver_AC5freecamGameplay[2] + 0x40CEA4, 1) == 0 then -- if Screen Ratio is set to 4:3

			writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980C, 0xC3)

		else -- Do the same as above if the Screen Ratio is set to 16:9

			writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980C, 0xCB)

		end

		-- Remove HUD graphics.
		writeBytes(AC5freecamGameplay_dataList[39], {0x00, 0x00, 0x00, 0x00})
		writeBytes(AC5freecamGameplay_dataList[41], {0x00, 0x00, 0x00, 0x00})
		writeBytes(AC5freecamGameplay_dataList[43], {0x00, 0x00, 0x00, 0x00})

		-- Remove pause screen graphics.
		writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980D, 0x0)

		-- Disable camera opcodes
		for i = 1, #AC5freecamGameplayAOB_dataList, 2 do

			local nopArray = {}

			for i = 1, #AC5freecamGameplayAOB_dataList[i + 1] do

				nopArray[#nopArray + 1] = 0x90

			end

			writeBytes(AC5freecamGameplayAOB_dataList[i], nopArray)

		end

	else -- On script deactivation.

		-- Restore pause screen graphics.
		writeBytes(EERAMver_AC5freecamGameplay[2] + 0x9C980D, 0x0E)

		-- Restore camera opcodes
		for i = 1, #AC5freecamGameplayAOB_dataList do

			writeBytes(AC5freecamGameplayAOB_dataList[i], AC5freecamGameplayAOB_dataList[i + 1])

		end

		-- Restore camera coordinates and screen projection scales.
		for i = 1, 44, 2 do

			writeBytes(AC5freecamGameplay_dataList[i], AC5freecamGameplay_dataList[i + 1])

		end

		-- Restore control input
		writeBytes(EERAMver_AC5freecamGameplay[2] + 0x4459B0, {0x80, 0x7B, 0x48, 0x00})

		-- Resume game.
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

-- Final block trigger (Called ONLY when the queue is completely empty)
function AC5freecamGameplay_detachDebugger()

	local t = createTimer(nil)
	t.Interval = 100
	t.OnTimer = function(timer)

		timer.destroy()
		detachIfPossible()

		IsAC5freecamGameplayEnabled = true

		AC5freecamGameplay_mainBlock()

	end

end

-- The core processor function
function AC5freecamGameplay_processNextBreakpoint()

	-- If our index is larger than the queue size, we are done!
	if AC5freecamGameplay_queueIndex > #AC5freecamGameplay_breakpointQueue then

		AC5freecamGameplay_detachDebugger()

		return

	end

	local currentAddr = AC5freecamGameplay_breakpointQueue[AC5freecamGameplay_queueIndex]

	-- We add 'context' as a parameter to safely catch the thread state in CE 7.7+
	debug_setBreakpoint(currentAddr, 4, bptWrite, function(context)

		-- Safely grab the Instruction Pointer (handles 64-bit RIP, 32-bit EIP, and CE 7.7 thread context changes)
		local currentIP = RIP or (context and context.RIP) or EIP or (context and context.EIP)

		-- Safety catch if the IP still fails to load
		if not currentIP then

			showMessage("<< Error: Could not retrieve Instruction Pointer from debugger thread. >>")
			debug_continueFromBreakpoint(co_run)
			return 1

		end

		local targetOpcodeAddr = getPreviousOpcode(currentIP)
		local instrSize = currentIP - targetOpcodeAddr

		AC5freecamGameplayAOB_dataList[#AC5freecamGameplayAOB_dataList + 1] = targetOpcodeAddr
		AC5freecamGameplayAOB_dataList[#AC5freecamGameplayAOB_dataList + 1] = readBytes(targetOpcodeAddr, instrSize, true)

		debug_removeBreakpoint(currentAddr)

		-- Advance and process next
		AC5freecamGameplay_queueIndex = AC5freecamGameplay_queueIndex + 1
		AC5freecamGameplay_processNextBreakpoint()

		-- EXPLICITLY TELL CE TO RESUME SILENTLY
		debug_continueFromBreakpoint(co_run)

		return 1

	end)

end

------------------+
---- [TABLES] ----+
------------------+
AC5freecamGameplay_dataList = {}
AC5freecamGameplayAOB_dataList = {}
AC5freecamGameplay_entityCoordList = {}
AC5freecamGameplay_breakpointQueue = {}

-----------------+
---- [CHECK] ----+
-----------------+
-- Check if there are not conflicting scripts active.
if not IsAC5adjustTPSviewCamEnabled or not IsAC5freeMovementEnabled or not IsAC5freecamHangarEnabled then

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

						-- Get camera data base offset.
						-- Because sometimes the game write zeros to address besides the camera data offset
						-- Set a While loop to capture the offset and skip the zero'd one.
						while true do

							if readInteger(EERAMver_AC5freecamGameplay[2] + 0x987564) ~= 0 then

								AC5coord_temp = readInteger(EERAMver_AC5freecamGameplay[2] + 0x987564) + EERAMver_AC5freecamGameplay[2]
								break

							end

						end

						-- Variables are defined and reset right here, exactly when needed
						AC5freecamGameplay_queueIndex = 1

						-- Populate the queue
						AC5freecamGameplay_breakpointQueue[#AC5freecamGameplay_breakpointQueue + 1] = AC5coord_temp + 0xE10

						-- Kick off the queue
						AC5freecamGameplay_processNextBreakpoint()

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

	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [HANGAR]".."\n- [FREE MOVEMENT MODE]".."\n- [ADJUST THIRD PERSONA CAMERA POSITION]".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+
-- Since the main block of the code is a huge function I should move it to its right section
-- but I'll leave it here for consistency.
function AC5freecamGameplay_mainBlock()

	if IsAC5freecamGameplayEnabled then

		-- //[BACKUP]//
		-- Camera position/coordinates.
		-- [1]  Third-person view coordinates
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD20
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD20, 0x4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD24
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD24, 0x4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD28
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD28, 0x4, true)
		-- [7] Third-person view coordinates (anchor)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD2C
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD2C, 0x4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD30
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD30, 0x4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD34
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD34, 0x4, true)
		-- [13] Cockpit view coordinates
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD38
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD38, 0x4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD3C
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD3C, 0x4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xD40
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xD40, 0x4, true)
		-- [19] Pitch/Yaw/Rotation
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xE10
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = {0x00, 0x00, 0x00, 0x00}
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xE14
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = {0x00, 0x00, 0x00, 0x00}
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xE18
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = {0x00, 0x00, 0x00, 0x00}

		-- Store current foreground/background addresses and current resolutions.
		-- [25] Foreground
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp, 4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0x4
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0x4, 4, true)
		-- [29] Background
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0x1C0 
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0x1C0, 4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0x1C4
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0x1C4, 4, true)

		-- [33] Backup lighting values.
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = EERAMver_AC5freecamGameplay[2] + 0x3A0AC0
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(EERAMver_AC5freecamGameplay[2] + 0x3A0AC0, 0x4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = EERAMver_AC5freecamGameplay[2] + 0x39F250
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(EERAMver_AC5freecamGameplay[2] + 0x39F250, 0x4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = EERAMver_AC5freecamGameplay[2] + 0x3A0788
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(EERAMver_AC5freecamGameplay[2] + 0x3A0788, 0x4, true)

		-- [39] HUD visibility flag(s?).
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xBE4
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xBE4, 4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xBF4
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xBF4, 4, true)
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = AC5coord_temp + 0xBF8
		AC5freecamGameplay_dataList[#AC5freecamGameplay_dataList + 1] = readBytes(AC5coord_temp + 0xBF8, 4, true)

		-- //[MEMREC/CAMERA SETUP]//
		-- Create a global header to attach the other sub-header and memory records that will be create on script activation.
		AC5freecamGameplay_mainHeader = create_header("[CAMERA] GAMEPLAY FREECAM", nil, nil)

		-- //[CAMERA XZY/PYR COORDINATES]//
		-- Set record descriptions and offsets according to current camera view.
		-- Create header and memory records to display the camera's current XYZ coordinates.
		-- Store camera's last XYZ coordinates previous to script activation to use it with the restore function.
		-- Camera views values:
		---- 0 = HUD view
		---- 1 = Third-person view
		---- 2 = Cockpit view
		local camera_coordinates_header = create_header("Current camera coordinates", AC5freecamGameplay_mainHeader, true)

		-- Store current camera view ID.
		local currentCamView = readBytes(AC5coord_temp + 0xE5A, 1)

		-- If camera view is TPS:
		if currentCamView == 1 then

			local offset_list = {0x0, 0x4, 0x8, 0xC, 0x10, 0x14, 0xF0, 0xF4, 0xF8}
			local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "X coordinate (anchor)", "Y coordinate (anchor)", "Z coordinate (anchor)", "Pitch", "Yaw", "Roll"}
			local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}

			create_memory_record(AC5freecamGameplay_dataList[1], offset_list, vt_list, description_list, camera_coordinates_header)

		-- If camera view is cockpit or HUD:
		else

			local offset_list = {0x18, 0x1C, 0x20, 0xF0, 0xF4, 0xF8}
			local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "Pitch", "Yaw", "Roll"}
			local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}

			create_memory_record(AC5freecamGameplay_dataList[1], offset_list, vt_list, description_list, camera_coordinates_header)

		end

		-- Create a header to hold the addresses of the game lighting values.
		local lighting_values_header = create_header("Lighting values", AC5freecamGameplay_mainHeader, true)

		create_memory_record(EERAMver_AC5freecamGameplay[2] + 0x3A0AC0, {0x0}, {vtSingle}, {"Source light intensity (Player aircraft)"}, lighting_values_header)
		create_memory_record(EERAMver_AC5freecamGameplay[2] + 0x39F250, {0x0}, {vtSingle}, {"Source light intensity (other)"}, lighting_values_header)

		-- //[INITIALIZE VARIABLES AND FUNCTIONS]//
		-- Read and store addresses and variables, initialize wrapper closure and freecam functions.
		local function AC5freecamGameplay_init()

			-- Get current screen resolution.
			-- Foreground layer
			local screenWidthF = AC5freecamGameplay_dataList[25]
			local screenWidthF_old = AC5freecamGameplay_dataList[26]
			local screenHeightF = AC5freecamGameplay_dataList[27]
			local screenHeightF_old = AC5freecamGameplay_dataList[28]
			-- Background layer
			local screenWidthB =  AC5freecamGameplay_dataList[29]
			local screenWidthB_old =  AC5freecamGameplay_dataList[30]
			local screenHeightB =  AC5freecamGameplay_dataList[31]
			local screenHeightB_old =  AC5freecamGameplay_dataList[32]

			-- Get current projection scale values.
			local distortionFactorW = readFloat(AC5coord_temp + 0x198)
			local distortionFactorW_old = distortionFactorW
			local distortionFactorH = readFloat(AC5coord_temp + 0x19C)
			local distortionFactorH_old = distortionFactorH

			-- Set projection scale limits.
			local distortionLimitMaxW = (512.0 // distortionFactorW) * 4
			local distortionLimitMaxH = (448.0 // distortionFactorH) * 4
			local distortionLimitMinW = (512.0 // distortionFactorW) // 16
			local distortionLimitMinH = (448.0 // distortionFactorH) // 16

			-- Camera XYZ coordinates.
			-- Adjust addresses and default values depending on current camera view.
			local xPosS1
			local xPosS1_old
			local zPosS1
			local zPosS1_old
			local yPosS1
			local yPosS1_old
			local xPosS2
			local xPosS2_old
			local zPosS2
			local zPosS2_old
			local yPosS2
			local yPosS2_old

			if currentCamView == 1 then
				xPosS1 = AC5freecamGameplay_dataList[1]
				xPosS1_old = AC5freecamGameplay_dataList[2]
				zPosS1 = AC5freecamGameplay_dataList[3]
				zPosS1_old = AC5freecamGameplay_dataList[4]
				yPosS1 = AC5freecamGameplay_dataList[5]
				yPosS1_old = AC5freecamGameplay_dataList[6]

				xPosS2 = AC5freecamGameplay_dataList[7]
				xPosS2_old = AC5freecamGameplay_dataList[8]
				zPosS2 = AC5freecamGameplay_dataList[9]
				zPosS2_old = AC5freecamGameplay_dataList[10]
				yPosS2 = AC5freecamGameplay_dataList[11]
				yPosS2_old = AC5freecamGameplay_dataList[12]
			else
				xPosS1 = AC5freecamGameplay_dataList[13]
				xPosS1_old = AC5freecamGameplay_dataList[14]
				zPosS1 = AC5freecamGameplay_dataList[15]
				zPosS1_old = AC5freecamGameplay_dataList[16]
				yPosS1 = AC5freecamGameplay_dataList[17]
				yPosS1_old = AC5freecamGameplay_dataList[18]
			end

			-- Pitch, yaw, roll.
			local pRot = AC5freecamGameplay_dataList[19]
			local pRot_old = AC5freecamGameplay_dataList[20]
			local yRot = AC5freecamGameplay_dataList[21]
			local yRot_old = AC5freecamGameplay_dataList[22]
			local rRot = AC5freecamGameplay_dataList[23]
			local rRot_old = AC5freecamGameplay_dataList[24]

			-- Lighting values
			local lightVal1 = AC5freecamGameplay_dataList[33]
			local lightVal1_old = AC5freecamGameplay_dataList[34]
			local lightVal2 = AC5freecamGameplay_dataList[35]
			local lightVal2_old = AC5freecamGameplay_dataList[36]

			-- Set default entity ID which the camera will focus on.
			local currentEntityID = 1

			-- Custom XYZ/PYR coordinates that will used in the entity focus mode.
			-- This will place the camera above and at 3/4 view of the object on focus.
			local customCoordSet1 = {0x5D, 0xE6, 0xDA, 0xC2, 0x62, 0xA6, 0x8B, 0x42, 0x97, 0xD9, 0xA4, 0xC2}
			local customCoordSet2 = {0x00, 0x00, 0x00, 0xBF, 0x01, 0x00, 0x00, 0xC0, 0x00, 0x00, 0x00, 0x00}

			-- If using the HUD view, create a list of active entities in the current mission
			-- and save their coordinates to use them as the anchor point of the camera.
			if currentCamView == 0 then

				local tempScan = memscan_func(soExactValue, vtByteArray, nil, "CC CC 4C 42", nil, EERAMver_AC5freecamGameplay[2] + 0x800000, EERAMver_AC5freecamGameplay[2] + 0x1F00000, "", 2, "8", true, nil, nil, nil)

				for i = 1, #tempScan do

					-- Filter and remove entities that are not yet active or garbage data.
					if readInteger(tempScan[i] - 0x10C) == 1065353216 then

						AC5freecamGameplay_entityCoordList[#AC5freecamGameplay_entityCoordList + 1] = tempScan[i] - 0x118
						AC5freecamGameplay_entityCoordList[#AC5freecamGameplay_entityCoordList + 1] = readBytes(tempScan[i] - 0x118, 0x1C, true)

					end

				end

				-- Write the custom camera position for the HUD view mode.
				writeBytes(xPosS1, customCoordSet1)
				writeBytes(pRot, customCoordSet2)

			end

			-- Camera movement speed.
			local camera_base_speed = 0.1

			-- Create timer object and wrapper closure function.
			AC5freecamGameplay_timer = createTimer()
			AC5freecamGameplay_timer.Interval = 50

			AC5freecamGameplay_timer.OnTimer = function(AC5freecamGameplay_timerObj)

				-- If the emulator has exited abruptly, disable script.
				if readInteger(EERAMver_AC5freecamGameplay[2]) == nil then

					AC5freecamGameplay_timerObj.destroy()
					AC5freecamGameplay_timer = nil

					getAddressList().getMemoryRecordByDescription("Gameplay").Active = false

					return

				end

				-- Ignore key input if PCSX2 is not on focus.
				if getForegroundProcess() ~= getOpenedProcessID() then

					return

				end

				-- Send arguments and/or update dynamic variables.
				distortionFactorW, distortionFactorH, camera_base_speed, currentEntityID = AC5freecamGameplay_mainFunc(screenWidthF, screenWidthF_old, screenHeightF, screenHeightF_old, screenWidthB, screenWidthB_old, screenHeightB, screenHeightB_old, distortionFactorW, distortionFactorW_old, distortionFactorH, distortionFactorH_old, distortionLimitMaxW, distortionLimitMaxH, distortionLimitMinW, distortionLimitMinH, xPosS1, xPosS1_old, zPosS1, zPosS1_old, yPosS1, yPosS1_old, xPosS2, xPosS2_old, zPosS2, zPosS2_old, yPosS2, yPosS2_old, pRot, pRot_old, yRot, yRot_old, rRot, rRot_old, camera_base_speed, currentEntityID, currentCamView, customCoordSet1, customCoordSet2, lightVal1, lightVal1_old, lightVal2, lightVal2_old)

			end

		end

		-- Call function above.
		AC5freecamGameplay_init()

		-- Disable controls, camera opcodes and pause game.
		switch(true)

		-- Clear this variable.
		AC5coord_temp = nil

	end

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and tables on script deactivation.
if IsAC5freecamGameplayEnabled then

	if AC5freecamGameplay_timer then

		AC5freecamGameplay_timer.destroy()
		AC5freecamGameplay_timer = nil

	end

	if readInteger(EERAMver_AC5freecamGameplay[2]) ~= nil then

		-- // Debugger cleanup
		-- Process exists: Clean cleanup
		local bplist = debug_getBreakpointList()

		if bplist then

			for i = 1, #bplist do debug_removeBreakpoint(bplist[i]) end

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

	AC5freecamGameplay_mainHeader.destroy()

	AC5freecamGameplayAOB_dataList = nil
	AC5freecamGameplay_dataList = nil
	AC5freecamGameplay_entityCoordList = nil
	AC5freecamGameplay_breakpointQueue = nil

	AC5freecamGameplay_nextCycleTime1 = nil
	AC5freecamGameplay_nextCycleTime2 = nil
	AC5freecamGameplay_holdDelay = nil


	IsAC5freecamGameplayEnabled = nil

end

EERAMver_AC5freecamGameplay = nil
