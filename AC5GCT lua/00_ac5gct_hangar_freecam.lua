{$lua}

--[[
==============================================================
==== ACE COMBAT 5: THE UNSUNG WAR - HANGAR FREECAM SCRIPT ====
==============================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v200826

Special thanks to anonymous for the debugger code used in this script.
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

-- Camera freecam controls
local function AC5freecamHangar_mainFunc(screenWidth, screenWidth_old, screenHeight, screenHeight_old, distortionFactorW, distortionFactorW_old, distortionFactorH, distortionFactorH_old, distortionLimitMaxW, distortionLimitMaxH, distortionLimitMinW, distortionLimitMinH, xPos, xPos_old, zPos, zPos_old, yPos, yPos_old, pRot, pRot_old, yRot, yRot_old, rRot, rRot_old, camera_base_speed, hangarPlayerObjPos, hangarPlayerObjPos_old, hangarWingmanObjPos, hangarWingmanObjPos_old, hangarPlayerObjRot, hangarPlayerObjRot_old, hangarWingman1ObjRot, hangarWingman1ObjRot_old, hangarWingman2ObjRot, hangarWingman2ObjRot_old, hangarWingman3ObjRot, hangarWingman3ObjRot_old, hangarReflectionFlag, hangarReflectionFlag_old)

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

	-- The descriptions of the directional movement keys assume
	-- that the camera's current pitch, yaw and roll axis values are {0, 0, 0}.
	if (isKeyPressed(VK_A)) then -- Move left
		writeFloat(xPos, readFloat(xPos) - camera_base_speed)
	elseif (isKeyPressed(VK_D)) then -- Move right
		writeFloat(xPos, readFloat(xPos) + camera_base_speed)
	elseif (isKeyPressed(VK_S)) then -- Move down
		writeFloat(zPos, readFloat(zPos) - camera_base_speed)
	elseif (isKeyPressed(VK_W)) then -- Move up
		writeFloat(zPos, readFloat(zPos) + camera_base_speed)
	elseif (isKeyPressed(VK_Q)) then -- Move backwards
		writeFloat(yPos, readFloat(yPos) + camera_base_speed)
	elseif (isKeyPressed(VK_E)) then -- Move forward
		writeFloat(yPos, readFloat(yPos) - camera_base_speed)
	end

	if (isKeyPressed(VK_NUMPAD2)) then -- Pitch up
		writeFloat(pRot, readFloat(pRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD5)) then -- Pitch down
		writeFloat(pRot, readFloat(pRot) + rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw left
		writeFloat(yRot, readFloat(yRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw right
		writeFloat(yRot, readFloat(yRot) + rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll left
		writeFloat(rRot, readFloat(rRot) - rotSpeed)
	elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll right
		writeFloat(rRot, readFloat(rRot) + rotSpeed)
	end

	-- Camera lens distortion
	if (isKeyPressed(VK_UP)) then -- Pincushion distortion
		if readFloat(screenWidth) >= distortionLimitMaxW then -- Clamp if the screen width exceeds the defined limit.
			writeFloat(screenWidth, distortionLimitMaxW)
			writeFloat(screenHeight, distortionLimitMaxH)
		else
			distortionFactorW = distortionFactorW * 0.99
			distortionFactorH = distortionFactorH * 0.99
			writeFloat(screenWidth, 512.0 / distortionFactorW)
			writeFloat(screenHeight, 448.0 / distortionFactorH)

		end
	elseif (isKeyPressed(VK_DOWN)) then -- Barrel distortion.
		if readFloat(screenWidth) <= distortionLimitMinW then -- Clamp if the screen width exceeds the defined limit.
			writeFloat(screenWidth, distortionLimitMinW)
			writeFloat(screenHeight, distortionLimitMinH)
		else
			distortionFactorW = distortionFactorW * 1.01
			distortionFactorH = distortionFactorH * 1.01
			writeFloat(screenWidth, 512.0 / distortionFactorW)
			writeFloat(screenHeight, 448.0 / distortionFactorH)
		end
	elseif (isKeyPressed(VK_LEFT)) then -- Reset screen resolution and projection scale values.
		writeBytes(screenWidth, screenWidth_old)
		writeBytes(screenHeight, screenHeight_old)
		distortionFactorW = distortionFactorW_old
		distortionFactorH = distortionFactorH_old
	end

	-- Camera movement speed adjustment, reset keys.
	if (isKeyPressed(VK_ADD)) then -- Increase movement speed.
		camera_base_speed = camera_base_speed + 0.1 / factor
	elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease movement speed.
		camera_base_speed = camera_base_speed - 0.1 / factor
	elseif (isKeyPressed(VK_NUMPAD7)) then -- Reset camera position.
		writeBytes(xPos, xPos_old)
		writeBytes(zPos, zPos_old)
		writeBytes(yPos, yPos_old)
	elseif (isKeyPressed(VK_NUMPAD8)) then -- Reset hangar parameters.
		writeBytes(hangarPlayerObjPos, hangarPlayerObjPos_old)
		writeBytes(hangarWingmanObjPos, hangarWingmanObjPos_old)
		writeBytes(hangarPlayerObjRot, hangarPlayerObjRot_old)
		writeBytes(hangarWingman1ObjRot, hangarWingman1ObjRot_old)
		writeBytes(hangarWingman2ObjRot, hangarWingman2ObjRot_old)
		writeBytes(hangarWingman3ObjRot, hangarWingman3ObjRot_old)
		writeBytes(hangarReflectionFlag, hangarReflectionFlag_old)
	elseif (isKeyPressed(VK_NUMPAD9)) then -- Reset camera axis position.
		writeBytes(pRot, pRot_old)
		writeBytes(yRot, yRot_old)
		writeBytes(rRot, rRot_old)
	elseif (isKeyPressed(VK_SPACE)) then --Panic key (reset !!!EVERYTHING!!!)
		writeBytes(xPos, xPos_old)
		writeBytes(zPos, zPos_old)
		writeBytes(yPos, yPos_old)
		writeBytes(pRot, pRot_old)
		writeBytes(yRot, yRot_old)
		writeBytes(rRot, rRot_old)
		writeBytes(hangarPlayerObjPos, hangarPlayerObjPos_old)
		writeBytes(hangarWingmanObjPos, hangarWingmanObjPos_old)
		writeBytes(hangarPlayerObjRot, hangarPlayerObjRot_old)
		writeBytes(hangarWingman1ObjRot, hangarWingman1ObjRot_old)
		writeBytes(hangarWingman2ObjRot, hangarWingman2ObjRot_old)
		writeBytes(hangarWingman3ObjRot, hangarWingman3ObjRot_old)
		writeBytes(hangarReflectionFlag, hangarReflectionFlag_old)
		writeBytes(screenWidth, screenWidth_old)
		writeBytes(screenHeight, screenHeight_old)
		distortionFactorW = distortionFactorW_old
		distortionFactorH = distortionFactorH_old
		camera_base_speed = 0.1
	end

	-- Clamp camera movement speed if value is less than zero.
	if (camera_base_speed <= 0) then
		camera_base_speed = 0.1
	end

	-- Return the modified variables back to the timer.
	return distortionFactorW, distortionFactorH, camera_base_speed

end

-- Switch
function switch(bool)

	if bool then

		-- Disable control input
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x4459B0, {0x00, 0x00, 0x00, 0x00})

		-- Remove HUD graphics
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x8D38AE, 0x0)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF83, 0x0)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF87, 0x0)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF8B, 0x0)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF8F, 0x0)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF93, 0x0)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x8D3059, 0xA)
		writeFloat(EERAMver_AC5freecamHangar[2] + 0x9E2DE4, 0x0)

	else

		-- Restore camera opcodes
		for i = 1, #AC5freecamHangarAOB_dataList, 2 do

			writeBytes(AC5freecamHangarAOB_dataList[i], AC5freecamHangarAOB_dataList[i + 1])

		end

		-- Restore HUD graphics
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x8D38AE, 0x7F)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF83, 0x60)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF87, 0x60)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF8B, 0x60)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF8F, 0x60)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EF93, 0x20)
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x8D3059, 0x7)
		writeFloat(EERAMver_AC5freecamHangar[2] + 0x9E2DE4, 60)

		-- Restore default hangar settings.
		for i = 1, #AC5freecamHangar_dataList, 2 do

			writeBytes(AC5freecamHangar_dataList[i], AC5freecamHangar_dataList[i + 1])

		end

		-- Restore control input
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x4459B0, {0x80, 0x7B, 0x48, 0x00})

	end

	return

end

-- Shared final block trigger (Called ONLY when either queue is completely empty)
function AC5freecamHangar_detachDebugger()

	local t = createTimer(nil)

	t.Interval = 100

	t.OnTimer = function(timer)

		timer.destroy()
		detachIfPossible()
		IsAC5freecamHangarEnabled = true
		AC5freecamHangar_mainBlock()

	end

end

-- Debugger function + NOPper
function AC5freecamHangar_processNextNetBreakpoint(durationMs)

	-- If we've processed all coordinates in the net queue, we are done!
	if AC5freecamHangar_queueIndex > #AC5freecamHangar_breakpointQueue then

		AC5freecamHangar_detachDebugger()
		return

	end

	local currentAddr = AC5freecamHangar_breakpointQueue[AC5freecamHangar_queueIndex]

	debug_setBreakpoint(currentAddr, 4, bptWrite, function(context)

		-- Safely grab the Instruction Pointer for 32-bit and 64-bit emulators
		local currentIP = RIP or (context and context.RIP) or EIP or (context and context.EIP)

		if not currentIP then

			debug_continueFromBreakpoint(co_run)
			return 1

		end

		local targetOpcodeAddr = getPreviousOpcode(currentIP)

		-- If we haven't NOP'd this specific opcode yet, catch it
		if not AC5freecamHangarAOB_dataList[targetOpcodeAddr] then

			local instrSize = currentIP - targetOpcodeAddr

			-- Backup bytes to the main list for easy restoration on disable
			AC5freecamHangarAOB_dataList[#AC5freecamHangarAOB_dataList + 1] = targetOpcodeAddr
			AC5freecamHangarAOB_dataList[#AC5freecamHangarAOB_dataList + 1] = readBytes(targetOpcodeAddr, instrSize, true)

			-- Mark as captured
			AC5freecamHangarAOB_dataList[targetOpcodeAddr] = true

			-- NOP the instruction immediately
			local nopArray = {}

			for i = 1, instrSize do

				nopArray[i] = 0x90

			end

			writeBytes(targetOpcodeAddr, nopArray)

		end

		debug_continueFromBreakpoint(co_run)

		return 1

	end)

	-- Wait for the duration to catch overlapping opcodes, then move on
	local t = createTimer(nil)
	t.Interval = durationMs

	t.OnTimer = function(timer)

		timer.destroy()

		-- Remove the current breakpoint
		debug_removeBreakpoint(currentAddr)

		-- Advance index and process the next coordinate in the list
		AC5freecamHangar_queueIndex = AC5freecamHangar_queueIndex + 1
		AC5freecamHangar_processNextNetBreakpoint(durationMs)

	end

end

------------------+
---- [TABLES] ----+
------------------+
AC5freecamHangar_dataList = {}
AC5freecamHangarAOB_dataList = {}
AC5freecamHangar_breakpointQueue = {}

-----------------+
---- [CHECK] ----+
-----------------+
-- Check if there are not conflicting scripts active.
if not IsAC5adjustTPSviewCamEnabled or not IsAC5freeMovementEnabled or not IsAC5freecamGameplayEnabled then

	-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
	-- Set the working RAM region ranges based on emulator version.
	EERAMver_AC5freecamHangar = pcsx2_version_check()

	if (EERAMver_AC5freecamHangar[3] == nil) then

		-- Check if the emulator has the right game loaded.
		local SLUS_20851_check = memscan_func(soExactValue, vtByteArray, nil, "80 55 42 00 90 55 42 00 A0 55 42 00 B0 55 42 00", nil, EERAMver_AC5freecamHangar[2] + 0x300000, EERAMver_AC5freecamHangar[2] + 0x4000000, "", 2, "0", true, nil, nil, nil)

		if #SLUS_20851_check ~= 0 then

			-- Check if the player is currently NOT in a mission.
			if (readBytes(EERAMver_AC5freecamHangar[2] + 0x47B87C, 1) == 0) then

				---- Check if the player is in a compatible mode
				if value_exists({8, 16, 136}, readBytes(EERAMver_AC5freecamHangar[2] + 0x8D3242, 1)) then

					-- Check if the player is inside a hangar.
					if readBytes(EERAMver_AC5freecamHangar[2] + 0x6D330E, 1) == 1 then

						-- Variables are defined and reset right here, exactly when needed
						AC5freecamHangar_queueIndex = 1

						-- Populate the queue
						AC5freecamHangar_breakpointQueue[#AC5freecamHangar_breakpointQueue + 1] = EERAMver_AC5freecamHangar[2] + 0x40D650
						AC5freecamHangar_breakpointQueue[#AC5freecamHangar_breakpointQueue + 1] = EERAMver_AC5freecamHangar[2] + 0x40D660

						-- Kick off the queue
						AC5freecamHangar_processNextNetBreakpoint(250)

					else

						showMessage("<< Activate this script while in a hangar. >>")

					end

				else

					showMessage("<< This mode is no compatible with this script. >>")

				end

			else

				showMessage("<< Activate this script while in a hangar. >>")

			end

		else

			showMessage("<< This script is not compatible with the game you're currently emulating. >>")

		end

	else

		if EERAMver_AC5freecamHangar[3] == 1 then

			showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

		elseif EERAMver_AC5freecamHangar[3] == 2 then

			showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

		elseif EERAMver_AC5freecamHangar[3] == 3 then

			showMessage("<< PCSX2 has no ISO file loaded. >>")

		end

	end

else

	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [GAMEPLAY]".."\n- [FREE MOVEMENT MODE]".."\n- [ADJUST THIRD PERSONA CAMERA POSITION]".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+
-- Since the main block of the code is a huge function I should move it to its right section
-- but I'll leave it here for consistency.
function AC5freecamHangar_mainBlock()

	if IsAC5freecamHangarEnabled then

		-- /[BACKUP]/
		-- [1] Camera's position/coordinates.
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40D650
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40D650, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40D654
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40D654, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40D658
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40D658, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40D660
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40D660, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40D664
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40D664, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40D668
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40D668, 0x4, true)

		-- [13] Player and wingmen position in hangar.
		local hangarID = readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE06, 1)
		local hangarParamBaseAddress = EERAMver_AC5freecamHangar[2] + 0x3CB0C0 + (hangarID * 0x2C)

		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = hangarParamBaseAddress
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(hangarParamBaseAddress, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = hangarParamBaseAddress + 0x4
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(hangarParamBaseAddress + 0x4, 0x4, true)

		-- [17] Aircraft model orientation in hangar.
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40E020
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40E020, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40E4B0
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40E4B0, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40E940
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40E940, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x40EDD0
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40EDD0, 0x4, true)

		-- [25] Reflection flag.
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = hangarParamBaseAddress + 0x29
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(hangarParamBaseAddress + 0x29, 0x1)

		-- [27] Camera screen's current width/height size.
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x5CC620
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x5CC620, 0x4, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x5CC624
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x5CC624, 0x4, true)

		-- [31] Current state.
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x8D3059
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x8D3059, 1, true)

		-- /[MEMORY RECORDS]/
		-- Create a global header to attach the other sub-header and memory records that will be create on script activation.
		AC5freecamHangar_mainHeader = create_header("[CAMERA] HANGAR FREECAM", nil, nil)

		-- Subheaders.
		local camera_coordinates_header = create_header("Current camera coordinates", AC5freecamHangar_mainHeader, true)
		local current_hangar_header = create_header("Current hangar parameters", AC5freecamHangar_mainHeader, true)

		-- Child records.
		local offset_list = {0x0, 0x4, 0x8, 0x10, 0x14, 0x18}
		local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "Pitch", "Yaw", "Roll"}
		local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}

		create_memory_record(AC5freecamHangar_dataList[1], offset_list, vt_list, description_list, camera_coordinates_header)

		create_memory_record(AC5freecamHangar_dataList[13], {0x0}, {vtSingle}, {"Player aircraft position"}, current_hangar_header)

		local hangarEntityCount = readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE07, 1)

		-- If the wingmen are also present, create records for them.
		if hangarEntityCount ~= 1 then

			create_memory_record(AC5freecamHangar_dataList[15], {0x0}, {vtSingle}, {"Wingmen aircraft position"}, current_hangar_header)

		end

		create_memory_record(AC5freecamHangar_dataList[25], {0x0}, {vtByte}, {"Aircraft reflection flag"}, current_hangar_header)

		local entity_yaw_header = create_header("Aircraft orientation", current_hangar_header, true)
		local description_list = {"Player", "Edge", "Chopper/Snow", "Grimm/Heartbreak"}

		for i = 1, hangarEntityCount do

			create_memory_record(AC5freecamHangar_dataList[17 + (i * 2) - 2], {0x0}, {vtSingle}, {description_list[i]}, entity_yaw_header)

		end

		--- /[INITIALIZE VARIABLES AND FUNCTIONS]/
		-- Read and store addresses and variables, initialize wrapper closure and freecam functions.
		local function AC5freecamHangar_init()

			-- Get current screen resolution.
			local screenWidth = AC5freecamHangar_dataList[27]
			local screenWidth_old = AC5freecamHangar_dataList[28]
			local screenHeight = AC5freecamHangar_dataList[29]
			local screenHeight_old = AC5freecamHangar_dataList[30]

			-- Get current projection scale values.
			local distortionFactorW = 512.0 / readFloat(AC5freecamHangar_dataList[27])
			local distortionFactorW_old = distortionFactorW
			local distortionFactorH = 448.0 / readFloat(AC5freecamHangar_dataList[29])
			local distortionFactorH_old = distortionFactorH

			-- Set projection scale limits.
			local distortionLimitMaxW = (512.0 // distortionFactorW) * 4
			local distortionLimitMaxH = (448.0 // distortionFactorH) * 4
			local distortionLimitMinW = (512.0 // distortionFactorW) // 16
			local distortionLimitMinH = (448.0 // distortionFactorH) // 16

			-- Camera coordinates.
			local xPos = AC5freecamHangar_dataList[1]
			local xPos_old = AC5freecamHangar_dataList[2]
			local zPos = AC5freecamHangar_dataList[3]
			local zPos_old = AC5freecamHangar_dataList[4]
			local yPos = AC5freecamHangar_dataList[5]
			local yPos_old = AC5freecamHangar_dataList[6]
			local pRot = AC5freecamHangar_dataList[7]
			local pRot_old = AC5freecamHangar_dataList[8]
			local yRot = AC5freecamHangar_dataList[9]
			local yRot_old = AC5freecamHangar_dataList[10]
			local rRot = AC5freecamHangar_dataList[11]
			local rRot_old = AC5freecamHangar_dataList[12]

			-- Hangar parameters.
			local hangarPlayerObjPos = AC5freecamHangar_dataList[13]
			local hangarPlayerObjPos_old = AC5freecamHangar_dataList[14]
			local hangarWingmanObjPos = AC5freecamHangar_dataList[15]
			local hangarWingmanObjPos_old = AC5freecamHangar_dataList[16]

			local hangarPlayerObjRot = AC5freecamHangar_dataList[17]
			local hangarPlayerObjRot_old = AC5freecamHangar_dataList[18]
			local hangarWingman1ObjRot = AC5freecamHangar_dataList[19]
			local hangarWingman1ObjRot_old = AC5freecamHangar_dataList[20]
			local hangarWingman2ObjRot = AC5freecamHangar_dataList[21]
			local hangarWingman2ObjRot_old = AC5freecamHangar_dataList[22]
			local hangarWingman3ObjRot = AC5freecamHangar_dataList[23]
			local hangarWingman3ObjRot_old = AC5freecamHangar_dataList[24]

			local hangarReflectionFlag = AC5freecamHangar_dataList[25]
			local hangarReflectionFlag_old = AC5freecamHangar_dataList[26]

			-- Camera movement speed.
			local camera_base_speed = 0.1

			-- Create timer object and wrapper closure function.
			AC5freecamHangar_timer = createTimer()
			AC5freecamHangar_timer.Interval = 50

			AC5freecamHangar_timer.OnTimer = function(AC5freecamHangar_timerObj)

				-- If the emulator has exited abruptly, disable script.
				if readInteger(EERAMver_AC5freecamHangar[2]) == nil then

					AC5freecamHangar_timerObj.destroy()
					AC5freecamHangar_timer = nil

					getAddressList().getMemoryRecordByDescription("Hangar").Active = false

					return

				end

				-- Ignore key input if PCSX2 is not on focus.
				if getForegroundProcess() ~= getOpenedProcessID() then

					return

				end

				-- Send arguments and/or update dynamic variables.
				distortionFactorW, distortionFactorH, camera_base_speed = AC5freecamHangar_mainFunc(screenWidth, screenWidth_old, screenHeight, screenHeight_old, distortionFactorW, distortionFactorW_old, distortionFactorH, distortionFactorH_old, distortionLimitMaxW, distortionLimitMaxH, distortionLimitMinW, distortionLimitMinH, xPos, xPos_old, zPos, zPos_old, yPos, yPos_old, pRot, pRot_old, yRot, yRot_old, rRot, rRot_old, camera_base_speed, hangarPlayerObjPos, hangarPlayerObjPos_old, hangarWingmanObjPos, hangarWingmanObjPos_old, hangarPlayerObjRot, hangarPlayerObjRot_old, hangarWingman1ObjRot, hangarWingman1ObjRot_old, hangarWingman2ObjRot, hangarWingman2ObjRot_old, hangarWingman3ObjRot, hangarWingman3ObjRot_old, hangarReflectionFlag, hangarReflectionFlag_old)

			end

		end

		-- Call function above.
		AC5freecamHangar_init()

		-- Disable camera opcodes and remove HUD graphics.
		switch(true)

	end

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and tables on script deactivation.
if IsAC5freecamHangarEnabled then

	if AC5freecamHangar_timer then

		AC5freecamHangar_timer.destroy()
		AC5freecamHangar_timer = nil

	end

	if readInteger(EERAMver_AC5freecamHangar[2]) ~= nil then

		-- / Debugger cleanup
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

	AC5freecamHangar_mainHeader.destroy()

	AC5freecamHangar_dataList = nil
	AC5freecamHangarAOB_dataList = nil
	AC5freecamHangar_breakpointQueue = nil
	AC5freecamHangar_queueIndex = nil

	IsAC5freecamHangarEnabled = nil

end

EERAMver_AC5freecamHangar = nil
