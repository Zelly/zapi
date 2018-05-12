zapi.scheduler = { }
zapi.scheduler.active = false
zapi.scheduler.levelTime = 0
zapi.scheduler.functions = { }

--[[ scheduled_function table info:
id: Identifier of the function
func: Function to run
remove: bool - if is marked to be removed from the functions table, will no longer run the function
loop: Milliseconds between loops if 0 then is a "run once" function and will be deleted on run
last: LevelTime that the function last ran ( 0 to start aka not ran yet )
run : LevelTime to start the function run. (Usually 0 for looping routines)
desc: description of the function for debugging etc

Idea: add run_till_success key, which will loop infintiely (loop delay must be set) until function returns true
]]--
function zapi.scheduler.run()
	if zapi.scheduler.active then return end -- Already running
	zapi.scheduler.active = true
	if not zapi.scheduler.levelTime or zapi.scheduler.levelTime == 0 then
		-- Game was not active
		zapi.scheduler.active = false
		return
	end
	
	local funcs_to_remove = { }
	
	for k=1,o(zapi.scheduler.functions) do
		local func_t = zapi.scheduler.functions[k]
		if not func_t or not func_t.id or not func_t.func or not func_t.run or not func_t.loop or not func_t.last then -- Possibly was removed while loop was running
			zapi.logger.debug("zapi.scheduler.run: func_t was nil or had nil value")
			break
		end
		if func_t.remove then
			funcs_to_remove[o(funcs_to_remove)+1] = func_t.id
		else
			if func_t.run == 0 or func_t <= zapi.scheduler.levelTime then
				if func_t.loop == 0 or func_t.last == 0 or ( func_t.last + func_t.loop ) <= zapi.scheduler.levelTime then
					func_t.last = zapi.scheduler.levelTime
					func_t.func()
					if func_t.loop == 0 then
						funcs_to_remove[o(funcs_to_remove)+1] = func_t.id
						zapi.logger.debug("zapi.scheduler.run: func_t " .. func_t.id .. " scheduled to remove")
					end
				end
			end
		end -- func_t.remove
	end -- for loop
	
	-- Removes the functions that are done.
	if next(funcs_to_remove) then
		for k=1, o(funcs_to_remove) do
			local _,index = zapi.misc.table.get(zapi.scheduler.functions, funcs_to_remove[k], "id")
			if index then
				table.remove(zapi.scheduler.functions, index)
			end
		end
	end
	zapi.scheduler.active = false
end

function zapi.scheduler.add(func, loop, run, desc)
	if type(func) ~= "function" then return end
	loop = tonumber(loop) or 0
	run = tonumber(run) or 0
	desc = zapi.misc.string.trim(desc, false, true)
	if loop == 0 and run == 0 then
		zapi.logger.debug("zapi.scheduler.add: Tried to add a scheduled function that would never run")
		return
	end
	loop = math.floor(loop*1000) -- Convert to ms
	local id = zapi.misc.table.nextId(zapi.scheduler.functions, "id")
	zapi.scheduler.functions[o(zapi.scheduler.functions)+1] = {
		id = id,
		func = func,
		loop = loop,
		run = run,
		last = last,
		desc = desc,
	}
	zapi.logger.debug("zapi.scheduler.add: Added new function(" .. desc ..")")
	return id
end

-- a safe method to remove a (possibly active) function from the scheduler
function zapi.scheduler.remove(id)
	id = tonumber(id)
	if not id then
		zapi.logger.debug("zapi.scheduler.remove: tried to remove nil func id")
		return
	end
	local func_t, index = zapi.misc.table.get(zapi.scheduler.functions, id, "id")
	func_t.remove = true
end
