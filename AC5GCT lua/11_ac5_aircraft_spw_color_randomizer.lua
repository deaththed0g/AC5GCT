{$lua}

--[[
=============================================================================
==== ACE COMBAT 5: THE UNSUNG WAR - AIRCRAFT/SpW/COLOR RANDOMIZER SCRIPT ====
=============================================================================
By death_the_d0g (death_the_d0g @ Twitter and deaththed0g @ Github)
Written and best viewed in Notepad ++.
v240826

Special thanks to anonymous for their RNG/shuffle function used here.
]]

setMethodProperty(getMainForm(), "OnCloseQuery", nil) -- Disable CE's save prompt.

[ENABLE]

if syntaxcheck then return end -- Prevent script from running after editing in CE's own script editor.

math.randomseed(getTickCount()) -- Grab seed.

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

-- RNG shuffler and keeper function.
local function AC5aircraftSpwRandomizer_RNGfunc(min, max, excludedPool)

	local function shuffleTable(t)

		for i = #t, 2, -1 do

			local j = math.random(i)
			t[i], t[j] = t[j], t[i]

		end

	end

	local masterPool = {}
	local currentPool = {}

	-- Build the exclusion lookup table
	local excludes = {}

	if excludedPool then

		for _, val in ipairs(excludedPool) do

			excludes[val] = true

		end

	end

	-- Populate the master pool, skipping any excluded IDs
	for i = min, max do

		if not excludes[i] then

			masterPool[#masterPool + 1] = i

		end

	end

	local function refillPool()

		for i, val in ipairs(masterPool) do

			currentPool[i] = val

		end

		shuffleTable(currentPool)

	end

	refillPool()

	return function(entityTable)

		if #currentPool == 0 then refillPool() end

		entityTable.AircraftID = table.remove(currentPool)

	end

end

-- Aircraft/COLOR/SpW randomizer function
function AC5aircraftSpwRandomizer_outSortieCheck(AC5aircraftSpwRandomizer_outSortieCheckTimer)

	-- Check if PCSX2 is up and running. if not, disable script.
	if EERAMver_AC5aircraftSpwRandomizer[2] ~= nil then

		-- Check if the game's current.
		if readBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x8E9BC1, 1) == 0 then

			-- Pause the timer that checks if the player is outside of a sortie.
			AC5aircraftSpwRandomizer_outSortieCheckTimer.enabled = false

			-- Populate the separate tables
			AC5aircraftSpwRandomizer_aircraftUsed(AC5aircraftSpwRandomizer_playerList)
			AC5aircraftSpwRandomizer_aircraftUsed(AC5aircraftSpwRandomizer_wingman1List)
			AC5aircraftSpwRandomizer_aircraftUsed(AC5aircraftSpwRandomizer_wingman2List)
			AC5aircraftSpwRandomizer_aircraftUsed(AC5aircraftSpwRandomizer_wingman3List)

			-- Draw the randomized values and write them to their respective addresses.
			writeBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x5C8CBB, AC5aircraftSpwRandomizer_playerList.AircraftID)
			writeBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x5C8CBF, math.random(0, 2))

			writeBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x5C8CBC, AC5aircraftSpwRandomizer_wingman1List.AircraftID)
			writeBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x5C8CC0, math.random(0, 2))

			writeBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x5C8CBD, AC5aircraftSpwRandomizer_wingman2List.AircraftID)
			writeBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x5C8CC1, math.random(0, 2))

			writeBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x5C8CBE, AC5aircraftSpwRandomizer_wingman3List.AircraftID)
			writeBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x5C8CC2, math.random(0, 2))

			-- Begin the "in-mission" function checker.
			function AC5aircraftSpwRandomizer_inSortieCheck(AC5aircraftSpwRandomizer_inSortieCheckTimer)

				-- Run function as long PCSX2 is up.
				if readInteger(EERAMver_AC5aircraftSpwRandomizer[2]) ~= nil then

					if readBytes(EERAMver_AC5aircraftSpwRandomizer[2] + 0x47B4C4, 1) ~= 4 then

						AC5aircraftSpwRandomizer_inSortieCheckTimer.enabled = false
						AC5aircraftSpwRandomizer_outSortieCheckTimer.enabled = true

					end

				else

					-- Disable script on emulator crash or exit.
					getAddressList().getMemoryRecordByDescription("Aircraft/SpW/COLOR randomizer").Active = false

				end

			end

			-- Start the "in-sortie" checker function or unpause if there's a timer object active already.
			-- Resume emulation.
			if AC5aircraftSpwRandomizer_inSortieCheck_Timer == nil then

				AC5aircraftSpwRandomizer_inSortieCheck_Timer = createTimer()
				AC5aircraftSpwRandomizer_inSortieCheck_Timer.Interval = 300
				AC5aircraftSpwRandomizer_inSortieCheck_Timer.onTimer = AC5aircraftSpwRandomizer_inSortieCheck
				AC5aircraftSpwRandomizer_inSortieCheck_Timer.Enabled = true


			else

				AC5aircraftSpwRandomizer_inSortieCheck_Timer.Enabled = true


			end

		end



	else

		-- Self disable script on emulator crash or exit.
		getAddressList().getMemoryRecordByDescription("Aircraft/SpW/COLOR randomizer").Active = false

	end

	return

end

-----------------+
---- [CHECK] ----+
-----------------+
-- Check how many instances of PCSX2 are running, the current version of the emulator and if it has a game loaded.
-- Set the working RAM region ranges based on emulator version.
EERAMver_AC5aircraftSpwRandomizer = pcsx2_version_check()

if (EERAMver_AC5aircraftSpwRandomizer[3] == nil) then

	-- Check if the emulator has the right game loaded.
	local SLUS_20851_check = memscan_func(soExactValue, vtByteArray, nil, "80 55 42 00 90 55 42 00 A0 55 42 00 B0 55 42 00", nil, EERAMver_AC5aircraftSpwRandomizer[2] + 0x300000, EERAMver_AC5aircraftSpwRandomizer[2] + 0x4000000, "", 2, "0", true, nil, nil, nil)

	if #SLUS_20851_check ~= 0 then

		-- Enable script if the check was passed.
		IsAC5aircraftSpwRandomizerEnabled = true

	else

		showMessage("<< This script is not compatible with the game you're currently emulating. >>")

	end

else

	if EERAMver_AC5aircraftSpwRandomizer[3] == 1 then

		showMessage("<< Attach this table to a running instance of PCSX2 first. >>")

	elseif EERAMver_AC5aircraftSpwRandomizer[3] == 2 then

		showMessage("<< Multiple instances of PCSX2 were detected. Only one is needed. >>")

	elseif EERAMver_AC5aircraftSpwRandomizer[3] == 3 then

		showMessage("<< PCSX2 has no ISO file loaded. >>")

	end

end

----------------+
---- [MAIN] ----+
----------------+
if IsAC5aircraftSpwRandomizerEnabled then

	-- Initialize a table to store backup data, used later for restoration.
	AC5aircraftSpwRandomizer_aircraftUsed = AC5aircraftSpwRandomizer_RNGfunc(0, 54,{47, 48})

	-- Create dedicated tables for each entity
	AC5aircraftSpwRandomizer_playerList = {}
	AC5aircraftSpwRandomizer_wingman1List = {}
	AC5aircraftSpwRandomizer_wingman2List = {}
	AC5aircraftSpwRandomizer_wingman3List = {}

	-- Begin the "out-of-sortie" checker function.
	AC5aircraftSpwRandomizer_outSortieCheck_Timer = createTimer()
	AC5aircraftSpwRandomizer_outSortieCheck_Timer.Interval = 300
	AC5aircraftSpwRandomizer_outSortieCheck_Timer.onTimer = AC5aircraftSpwRandomizer_outSortieCheck
	AC5aircraftSpwRandomizer_outSortieCheck_Timer.Enabled = true

end

[DISABLE]

if syntaxcheck then return end

-- Restore modified data to their default values, destroy headers, timers if any and clear tables, flags and stray debug breakpoints on script deactivation.
if IsAC5aircraftSpwRandomizerEnabled then

	if AC5aircraftSpwRandomizer_inSortieCheck_Timer ~= nil then

		AC5aircraftSpwRandomizer_inSortieCheck_Timer.destroy()
		AC5aircraftSpwRandomizer_inSortieCheck_Timer = nil

	end

	if AC5aircraftSpwRandomizer_outSortieCheck_Timer ~= nil then

		AC5aircraftSpwRandomizer_outSortieCheck_Timer.destroy()
		AC5aircraftSpwRandomizer_outSortieCheck_Timer = nil

	end

	AC5aircraftSpwRandomizer_playerList = nil
	AC5aircraftSpwRandomizer_wingman1List = nil
	AC5aircraftSpwRandomizer_wingman2List = nil
	AC5aircraftSpwRandomizer_wingman3List = nil
	IsAC5aircraftSpwRandomizerEnabled = nil

end

EERAMver_AC5aircraftSpwRandomizer = nil