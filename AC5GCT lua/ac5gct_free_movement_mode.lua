{$lua}

--[[
===========================================================
==== ACE COMBAT 5: THE UNSUNG WAR - FREE MOVEMENT MODE ====
===========================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
This script was written and is best viewed on Notepad++.
v221125

TODO:
-- Redo everything
-- Shorten the code comments
-- Look for the movement speed address.
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

---------------+
---- [VAR] ----+
---------------+

AC5freeMovement_flagAddress = nil

-----------------+
---- [CHECK] ----+
-----------------+

-- Check if any of the "HANGAR", "ADJUST THIRD PERSON CAMERA DISTANCE" or "FREE MOVEMENT MODE" scripts are active. If false continue with the next check.
if (IsAC5freecamGameplayEnabled or IsAC5adjustTPSviewCamEnabled) ~= true then

	-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
	-- Set the working RAM region ranges based on emulator version.
	EERAMver_AC5freeMovement = pcsx2_version_check()

	if (EERAMver_AC5freeMovement[3] == nil) then

		-- Check if the emulator version is compatible with this script.
		if (EERAMver_AC5freeMovement[1] == 2) then

			-- Check if the emulator has the right game loaded.
			local SLUS_20851_check = memscan_func(soExactValue, vtByteArray, nil, "80 55 42 00 90 55 42 00 A0 55 42 00 B0 55 42 00", nil, EERAMver_AC5freeMovement[2] + 0x300000, EERAMver_AC5freeMovement[2] + 0x4000000, "", 2, "0", true, nil, nil, nil)

			if #SLUS_20851_check ~= 0 then

				-- Check if the player is currently in a mission.
				if (readBytes(EERAMver_AC5freeMovement[2] + 0x47B87C, 1) == 1) then
				
					-- Check if the script can be used in the current game state.
					if value_exists({768, 518, 774, 516, 772, 517, 773}, readSmallInteger(EERAMver_AC5freeMovement[2] + 0x6CD49C, 2)) then
		
						-- Enable script if all checks were passed.
						IsAC5freeMovementEnabled = true
					
					else
					
						showMessage("<< The script won't work while cutscenes are playing. >>")
					
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

		if EERAMver_AC5freeMovement[3] == 1 then

			showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

		elseif EERAMver_AC5freeMovement[3] == 2 then

			showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

		elseif EERAMver_AC5freeMovement[3] == 3 then

			showMessage("<< PCSX2 has no ISO file loaded. >>")

		end

	end

else

	showMessage("<< This script will not activate if any other of the following scripts are also active: ".."\n".."\n- [GAMEPLAY]".."\n- [ADJUST THIRD PERSON CAMERA DISTANCE]".."\n >>")

end

----------------+
---- [MAIN] ----+
----------------+

if IsAC5freeMovementEnabled then

	-- Look for and store the address containing the invincibility flag address.
	local tbl = memscan_func(soExactValue, vtByteArray, nil, "1700000060000000????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????1000000020000000????????????????????????????????????????????????05000000", nil, EERAMver_AC5freeMovement[2] + 0x700000, EERAMver_AC5freeMovement[2] + 0x1F00000, "", 2, "0", true, nil, nil, nil)
	local main_file = retrieve_toc(tbl[1])
	local mission_file = retrieve_toc(main_file[1] + 0x20)
	local entity_file = retrieve_toc(mission_file[1] + 0x20)
	local current_entities_group = retrieve_toc(entity_file[1] + 0x50)
	
	-- Enable solid state flag (?)
	writeBytes(current_entities_group[2] + 0xB3, 1)
	
	-- Enable mode
	writeBytes(EERAMver_AC5freeMovement[2] + 0x9C9861, 0)
	
	-- Store address
	AC5freeMovement_flagAddress = current_entities_group[2] + 0xB3

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear flags on script deactivation.
if IsAC5freeMovementEnabled then

	if readInteger(EERAMver_AC5freeMovement[2]) ~= nil then
	
		if (readBytes(EERAMver_AC5freeMovement[2] + 0x47B87C, 1) == 1) then
			
			writeBytes(AC5freeMovement_flagAddress + 0xB3, 0)
		
		end
		
		writeBytes(EERAMver_AC5freeMovement[2] + 0x9C9861, 2)
	
	end

	AC5freeMovement_flagAddress = nil

	IsAC5freeMovementEnabled = nil

end

EERAMver_AC5freeMovement = nil
