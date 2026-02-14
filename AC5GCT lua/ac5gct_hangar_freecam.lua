{$lua}

--[[
==============================================================
==== ACE COMBAT 5: THE UNSUNG WAR - HANGAR FREECAM SCRIPT ====
==============================================================
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

-- Cockpit/HUD camera freecam
function AC5freecamHangar_checkKeys_func(AC5freecamHangar_checkKeys_timer)

	-- Check if PCSX2 is up and running. if not, disable script.
	if readInteger(EERAMver_AC5freecamHangar[2]) ~= nil then

		if (isKeyPressed(VK_A)) then   -- Move left
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650) - camera_base_speed)
		elseif (isKeyPressed(VK_D)) then -- Move right
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650) + camera_base_speed)
		elseif (isKeyPressed(VK_Q)) then -- Move down
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x4, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x4) - camera_base_speed)
		elseif (isKeyPressed(VK_E)) then -- Move up
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x4, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x4) + camera_base_speed)
		elseif (isKeyPressed(VK_S)) then -- Move backwards
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x8, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x8) + camera_base_speed)
		elseif (isKeyPressed(VK_W)) then -- Move forward
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x8, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x8) - camera_base_speed)
		end
		
		if (isKeyPressed(VK_NUMPAD2)) then -- Pitch up
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x10, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x10) - rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD5)) then -- Pitch down
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x10, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x10) + rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD3)) then -- Yaw left
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x14, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x14) - rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD1)) then -- Yaw right
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x14, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x14) + rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD6)) then -- Roll left
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x18, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x18) - rotation_base_speed)
		elseif (isKeyPressed(VK_NUMPAD4)) then -- Roll right
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x18, readFloat(EERAMver_AC5freecamHangar[2] + 0x40D650 + 0x18) + rotation_base_speed)
		end
		
		if (isKeyPressed(VK_ADD)) then -- Increase camera XYZ speed
			camera_base_speed = camera_base_speed + camera_move_rate
		elseif (isKeyPressed(VK_SUBTRACT)) then -- Decrease camera XYZ speed
			camera_base_speed = camera_base_speed - camera_move_rate
		elseif (isKeyPressed(VK_NUMPAD7)) then -- reset XZY
			writeBytes(EERAMver_AC5freecamHangar[2] + 0x40D650, AC5freecamHangar_dataList[2])
		elseif (isKeyPressed(VK_NUMPAD8)) then -- reset HANGAR
			--writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EE07, AC5freecamHangar_dataList[1])
			writeBytes(AC5freecamHangar_dataList[4][1], AC5freecamHangar_dataList[4][2])
			writeBytes(AC5freecamHangar_dataList[5][1], AC5freecamHangar_dataList[5][2])
		elseif (isKeyPressed(VK_NUMPAD9)) then -- reset PYR
			writeBytes(EERAMver_AC5freecamHangar[2] + 0x40D660, AC5freecamHangar_dataList[3])
		elseif (isKeyPressed(VK_SPACE)) then -- Panic key
			writeBytes(EERAMver_AC5freecamHangar[2] + 0x40D650, AC5freecamHangar_dataList[2])
			writeBytes(EERAMver_AC5freecamHangar[2] + 0x40D660, AC5freecamHangar_dataList[3])
			--writeBytes(EERAMver_AC5freecamHangar[2] + 0x40EE07, AC5freecamHangar_dataList[1])
			writeBytes(AC5freecamHangar_dataList[4][1], AC5freecamHangar_dataList[4][2])
			writeBytes(AC5freecamHangar_dataList[5][1], AC5freecamHangar_dataList[5][2])
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40E020, 0.0)
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40E4B0, 0.0)
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40E940, 0.0)
			writeFloat(EERAMver_AC5freecamHangar[2] + 0x40EDD0, 0.0)
			camera_base_speed = old_camera_base_speed
		end
		
		if (camera_base_speed <= 0) then -- Reset camera speed value if it goes below 1.0
			camera_base_speed = camera_move_rate
		end
		
	else
	
		-- Self disable script.
		getAddressList().getMemoryRecordByDescription("Hangar").Active = false

	end

	return

end

-- Switch
function switch(bool)

	if bool then
		
		-- Disable control input
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x4459B0, {0x00, 0x00, 0x00, 0x00})
		
		-- Disable camera opcodes
		for i = 1, #AC5freecamHangar_addressListAOB, 2 do
			
			local tempArray = {}
			
			for i = 1, #AC5freecamHangar_addressListAOB[i + 1] do
				
				tempArray[#tempArray + 1] = 0x90
			
			end
		
			writeBytes(AC5freecamHangar_addressListAOB[i], tempArray)
		
		end
		
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
		for i = 1, #AC5freecamHangar_addressListAOB, 2 do
		
			writeBytes(AC5freecamHangar_addressListAOB[i], AC5freecamHangar_addressListAOB[i + 1])
		
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
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40D650, AC5freecamHangar_dataList[2])
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x40D660, AC5freecamHangar_dataList[3])
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x8D3059, AC5freecamHangar_dataList[1])
		writeBytes(AC5freecamHangar_dataList[4][1], AC5freecamHangar_dataList[4][2])
		writeBytes(AC5freecamHangar_dataList[5][1], AC5freecamHangar_dataList[5][2])
		writeFloat(EERAMver_AC5freecamHangar[2] + 0x40E020, 0.0)
		writeFloat(EERAMver_AC5freecamHangar[2] + 0x40E4B0, 0.0)
		writeFloat(EERAMver_AC5freecamHangar[2] + 0x40E940, 0.0)
		writeFloat(EERAMver_AC5freecamHangar[2] + 0x40EDD0, 0.0)
		
		-- Restore control input
		writeBytes(EERAMver_AC5freecamHangar[2] + 0x4459B0, {0x80, 0x7B, 0x48, 0x00})

	end
	
	return
	
end

-- Debugger handling
function AC5freecamHangar_detachDebugger()
	
	-- For every time the AC5freecamHangar_detachDebugger() function is called
	-- add +1 to the hitsFound global variable. If the amount is equal to 2 then
	-- proceed with the main block of the script.
	
	-- Only proceed if we have all the data we need
	if #AC5freecamHangar_addressListAOB == 8 then
	
		-- This Timer is the secret to preventing the "Hang"
		local t = createTimer(nil)
		t.Interval = 100
		t.OnTimer = function(timer)
		
			timer.destroy() -- Always destroy the timer once it's used
			
			-- Safe to detach now because the Debugger callback has finished
			detachIfPossible()
			
			-- Enable script if all checks were passed.
			IsAC5freecamHangarEnabled = true
			
			-- Safe to run the rest of your script (MAIN block)
			AC5freecamHangar_mainBlock()
			
		end
		
	end
	
end

------------------+
---- [TABLES] ----+
------------------+

AC5freecamHangar_dataList = {}
AC5freecamHangar_addressListAOB = {}
hitsFound = 0

-----------------+
---- [CHECK] ----+
-----------------+

if IsAC5freecamHangarEnabled ~= true then

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
					
						-- //[OPCODE]//
						-- Credit to G.G for this part of the code.
						-- Set debug breakpoints on the following addresses and store the addresses of instructions accessing them
						-- So they can be NOP'd on script activation.
						
						-- The first item in the table is where the hangar camera's XYZ coordinates address is located in memory.
						-- The second one is where the hangar camera's pitch, yaw, roll axis' address is located in memory.
						local AC5coordAddress_list = {EERAMver_AC5freecamHangar[2] +0x40D650, EERAMver_AC5freecamHangar[2] +0x40D660}
						
						for i = 1, #AC5coordAddress_list do
							
							-- Initialize a table to store and check for unique RIPs.
							local currentRIP = {}
						
							-- Set breakpoint for each address.
							debug_setBreakpoint(AC5coordAddress_list[i], 4, bptWrite, function()
								
								-- If the current RIP captured is not the table then skip this block.
								if not value_exists(currentRIP, RIP) then
									
									-- Add to table.
									currentRIP[#currentRIP + 1] = RIP
	
									-- 1. Step back to the instruction that caused the break
									-- This handles the "3 or 4 byte" difference automatically
									local targetOpcodeAddr = getPreviousOpcode(RIP)
								
									-- 2. Capture the address and the original bytes
									-- We read the instruction size dynamically to be safe
									local instrSize = RIP - targetOpcodeAddr
									
									-- Store opcode offset and its bytes.
									AC5freecamHangar_addressListAOB[#AC5freecamHangar_addressListAOB + 1] = targetOpcodeAddr
									AC5freecamHangar_addressListAOB[#AC5freecamHangar_addressListAOB + 1] = readBytes(targetOpcodeAddr, instrSize, true)
									
									-- Break function if the unique RIP amount is equal to 2.
									if #currentRIP == 2 then
										
										-- Detach debugger and resume game.
										debug_removeBreakpoint(AC5coordAddress_list[i])
									
										AC5freecamHangar_detachDebugger()
										
										if co_run then
											
											debug_continueFromBreakpoint(co_run)
											
										end
									
										return 1 -- This MUST return before detachIfPossible() is called
									
									end
								
								end
								
							end)
						
						end

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
	
	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [GAMEPLAY]".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+

-- Since the main block of the code is a huge function I should move it to its right section
-- but I'll leave it here for consistency.
function AC5freecamHangar_mainBlock()

	if IsAC5freecamHangarEnabled then
	
		-- Create a global header to attach the other sub-header and memory records that will be create on script activation.
		AC5freecamHangar_main_header = create_header("[CAMERA] HANGAR FREECAM", nil, nil)
	
		-- //[CAMERA XZY/PYR COORDINATES]//
		-- Set record descriptions and offsets according to current camera view.
		-- Create header and memory records to display the camera's current XYZ coordinates.
		-- Store camera's last XYZ coordinates previous to script activation to use it with the restore function.
		local camera_coordinates_header = create_header("Current camera coordinates", AC5freecamHangar_main_header, true)
		
		local offset_list = {0x0, 0x4, 0x8, 0x10, 0x14, 0x18}
		local description_list = {"X coordinate", "Y coordinate", "Z coordinate", "Pitch", "Yaw", "Roll"}
		local vt_list = {vtSingle, vtSingle, vtSingle, vtSingle, vtSingle, vtSingle}
		
		create_memory_record(EERAMver_AC5freecamHangar[2] + 0x40D650, offset_list, vt_list, description_list, camera_coordinates_header)
		
		-- //[HANGAR STUFF]//
		local current_hangar_header = create_header("Current hangar parameters", AC5freecamHangar_main_header, true)
		
		-- Create memory records according to the hangar ID and/or amount of planes in them.
		--if readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE06, 1) ~= 1 then -- NOT in ISAF
		--
		--	create_memory_record(EERAMver_AC5freecamHangar[2] + 0x40EE07, {0x0}, {vtByte}, {"Amount of aircraft in hangar"}, current_hangar_header)
		--
		--end
		
		if readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE07, 1) == 1 then
		
			local offset_list = {0x4, 0x29}
			local description_list = {"Player aircraft position", "Aircraft reflection flag"}
			local vt_list = {vtSingle, vtbyte}
			
			create_memory_record(EERAMver_AC5freecamHangar[2] + 0x3CB0C0 + (((readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE06, 1) + 1) * 0x2C - 0x2C)), offset_list, vt_list, description_list, current_hangar_header)
			
			local entity_yaw_header = create_header("Aircraft orientation", current_hangar_header, true)
		
			create_memory_record(EERAMver_AC5freecamHangar[2] + 0x40E020, {0x0}, {vtSingle}, {"Player"}, entity_yaw_header)
		
		else
		
			local offset_list = {0x4, 0x0, 0x29}
			local description_list = {"Player aircraft position", "Wingmen aircraft position", "Aircraft reflection flag"}
			local vt_list = {vtSingle, vtSingle, vtbyte}
			
			create_memory_record(EERAMver_AC5freecamHangar[2] + 0x3CB0C0 + (((readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE06, 1) + 1) * 0x2C - 0x2C)), offset_list, vt_list, description_list, current_hangar_header)
			
			local entity_yaw_header = create_header("Aircraft orientation", current_hangar_header, true)
		
			local description_list = {"Player", "Edge", "Chopper/Snow", "Grimm/Heartbreak"}
		
			for i = 1, readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE07, 1) do
		
				create_memory_record(EERAMver_AC5freecamHangar[2] + 0x40E020 + (i * 0x490 - 0x490), {0x0}, {vtSingle}, {description_list[i]}, entity_yaw_header)
		
			end
	
		end
		
		-- //[BACKUP]//
		-- Amount of aircraft in hangar.
		--AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE07, 1)
		
		-- Current state
		--AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = EERAMver_AC5freecamHangar[2] + 0x8D3059
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x8D3059, 1, true)
		
		-- Camera position
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40D650, 12, true)
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = readBytes(EERAMver_AC5freecamHangar[2] + 0x40D660, 12, true)
		
		-- Current hangar anchor point, LoD flag.
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = {EERAMver_AC5freecamHangar[2] + 0x3CB0C0 + (((readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE06, 1) + 1) * 0x2C - 0x2C)), readBytes(EERAMver_AC5freecamHangar[2] + 0x3CB0C0 + (((readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE06, 1) + 1) * 0x2C - 0x2C)), 8, true)}
		AC5freecamHangar_dataList[#AC5freecamHangar_dataList + 1] = {EERAMver_AC5freecamHangar[2] + 0x3CB0C0 + (((readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE06, 1) + 1) * 0x2C - 0x2C)) + 0x29, readBytes(EERAMver_AC5freecamHangar[2] + 0x3CB0C0 + (((readBytes(EERAMver_AC5freecamHangar[2] + 0x40EE06, 1) + 1) * 0x2C - 0x2C)) + 0x29, 1)}
	
		-- //[CAM_FUNC]//
		-- Set base rotation speed.
		-- Before setting it check for the current camera view. HUD, cockpit views as well during landing/takeoff reverse the rotation speed value. Reversing the value will only work with the HUD/cockpit views only.
		-- Set action/movement hotkeys function.
		-- Create and enable timer on script activation.
		camera_base_speed, old_camera_base_speed = 1.0, 1.0
		camera_move_rate = 0.5
		rotation_base_speed = 0.098175
	
		AC5freecamHangar_hotkey_Timer = createTimer() -- Create timer object
		AC5freecamHangar_hotkey_Timer.Interval = 50 -- Set tick rate
		AC5freecamHangar_hotkey_Timer.onTimer = AC5freecamHangar_checkKeys_func -- Call this function every Nms value set in the ".Interval" parameter.
		AC5freecamHangar_hotkey_Timer.Enabled = true -- Enable the timer object.
		
		-- Disable camera opcodes and remove HUD graphics.
		switch(true)
	
	end

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags and tables on script deactivation.
if IsAC5freecamHangarEnabled then

	if AC5freecamHangar_hotkey_Timer then
	
		AC5freecamHangar_hotkey_Timer.destroy()
		AC5freecamHangar_hotkey_Timer = nil

	end
	
	if readInteger(EERAMver_AC5freecamHangar[2]) ~= nil then
	
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
	
	if readInteger(EERAMver_AC5freecamHangar[2]) ~= nil then

		switch(false)
	
	end
	
	getAddressList().getMemoryRecordByDescription("Adjust camera lens distortion").Active = false
	
	AC5freecamHangar_main_header.destroy()
	
	camera_base_speed = nil
	camera_move_rate = nil
	rotation_base_speed = nil

	AC5freecamHangar_addressListAOB = nil
	AC5freecamHangar_dataList = nil

	IsAC5freecamHangarEnabled = nil

end

EERAMver_AC5freecamHangar = nil
