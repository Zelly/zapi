zapi.misc = { }
-- notepad find:  #(\w+)  replace:  o\((\1)\) 
------------------
-- TABLE FUNCTIONS
------------------
zapi.misc.table = { }
--- Gets table average
-- Requires list
function zapi.misc.table.average(t)
	local average = 0
	if not t then return average end
	for k=1, o(t) do
		average = average + t[k]
	end
	return avg / o(t)
end

--- Returns table t[rangeStart] to t[rangeEnd]
-- rangeStart defaults 1
-- rangeEnd defaults tlen(t)
function zapi.misc.table.range(t, rangeStart, rangeEnd)
	if not t then return { } end
	if not next(t) then return t end
	rangeStart = tonumber(rangeStart) or 1
	rangeEnd = tonumber(rangeEnd) or o(t)
	local newTable = { }
	
	for k=rangeStart, rangeEnd do
		newTable[o(newTable)+1] = t[k]
	end
	return newTable
end

--- Shuffle a table
-- returns new shuffled table
function zapi.misc.table.shuffle(t)
	local newTable = { }
	while o(t) > 0 do
		table.insert(newTable, table.remove(t, math.random(o(t)) ) )
	end
	return newTable
end

--- returns table total
function zapi.misc.table.total(t)
	local total = 0.0
	if not t then return total end
	for k=1, o(t) do
		total = t[k] + total
	end
	return total or 0.0
end

--- Merges two tables
-- returns a merged table with no duplicate values
function zapi.misc.table.merge(t1, t2)
	if ( t1 == nil and t2 == nil ) then return { } end
	if t1 == nil then return t2 end
	if t2 == nil then return t1 end
	local t = { }
	
	-- Add any from table one that is not in table 2
	for k=1, o(t1) do
		if not zapi.misc.table.find(t2, t1[k]) then
			t[o(t)+1] = t1[k]
		end
	end
	-- Add table 2 values (Since no table 2 values were added in first iteration)
	for k=1, o(t2) do
		t[o(t)+1] = t2[k]
	end
end

--- Checks if a value exists in a table
-- if index then will search table of table with index
-- returns true or false
function zapi.misc.table.find(t, value, index)
	for k=1, o(t) do
		if index then
			if t[k][index] == value then
				return true
			end
		else
			if t[k] == value then
				return true
			end
		end
	end
	return false
end

--- Checks if a value exists in a table
-- if index then will search table of table with index
-- returns t[k] and k or nil
function zapi.misc.table.get(t, value, index)
	for k=1, o(t) do
		if index then
			if t[k][index] == value then
				return t[k], k
			end
		else
			if t[k] == value then
				return t[k], k
			end
		end
	end
	return nil
end

--- Checks if a tables have any duplicates exists in a table
-- returns true or false
function zapi.misc.table.match(t1, t2)
	for k=1, o(t1) do
		if zapi.misc.table.find(t2, t1[k]) then
			return true
		end
	end
	return false
end

--- Removes value from table [limit] number of times
-- if limit is 0 or lower it will remove all
-- default limit is all
function zapi.misc.table.remove(t, value, limit)
	limit = tonumber(limit) or 0
	local removed = 0 
	for k=1, o(t) do
		if t[k] == value then
			table.remove(t, k)
			removed = removed + 1
			if limit >= 1 and removed >= limit then
				break
			end
		end
	end
end

--- Adds a value to a table if it does not already exist
function zapi.misc.table.addUnique(t, value)
	if not zapi.misc.table.find(t, value) then
		t[o(t)+1] = value
	end
end

--- Gets longest string in a table
-- if searching nested key values use index
-- returns the length and string
function zapi.misc.table.getLongestString(t, index, clean)
	local longest = 0
	for k=1, o(t) do
		local length = 0
		if index then
			length = string.len(t[k][index])
		else
			length = string.len(t[k])
		end
		if length > longest then
			longest = length
		end
	end
	return longest
end

--- get the next unique id available
-- index is keyname "id" by default
function zapi.misc.table.nextId(t, index)
	if not t or type(t) ~= "table" then return end
	if not index then index = "id" end
	local id = 0
	while id <= 100000 do -- limit just incase infinite loop somehow happens
		id = id + 1
		if not zapi.misc.table.find(t, id, index) then
			return id
		end
	end
	return id -- shouldn't reach
end

function zapi.misc.table.insert(t, value, unique, uniqueKey)
	if not unique then
		t[o(t)+1] = value
		return true
	else
		local f = false
		for k=1, o(t) do
			if not uniqueKey then
				if t[k] == value then
					f = true
					break
				end
			else
				if t[k][uniqueKey] == value[uniqueKey] then
					f = true
					break
				end
			end
		end
		if not f then
			t[o(t)+1] = value
			return true
		end
	end
	return false
end

-------------------
-- STRING FUNCTIONS
-------------------
zapi.misc.string = { }

--- Wrap a string
-- this code is taken from the user talks, I may need to find source later if it needs work
function zapi.misc.string.wrap(s, limit)
	limit = tonumber(limit) or 72
	local here = 1
	return string.gsub(str,"(%s+)()(%S+)()" , function(sp, st, word, fi)
			if fi-here > limit then
				here = st
				return "\n" .. word
			end
		end,20)
end

--- Method to prevent extra if statements in other functions
function zapi.misc.string.clean(s, clean)
	if not s then return "" end
	if type(s) ~= "string" then return "" end
	if clean then
		return et.Q_CleanStr(s)
	else
		return s
	end
end


--- Cleans line ending color codes
-- Example:
--      Before:^1this ^2is a string^3
--      After :^1this ^2is a string
--      Before:^1this ^2is a string^3^4^7
--      After :^1this ^2is a string
--      Before:^1this ^2is a string^
--      After :^1this ^2is a string
function zapi.misc.string.removeTrailingColorCodes(s)
	local f = true
	while f do
		if string.sub(s, -2, -2) == "^" then
			str = string.sub(s, 1, -3)
		elseif string.sub(s , -1, -1) == "^" then
			str = string.sub(s , 1, -2)
		else
			f = false
		end
	end
	return s
end

--- Trims white space from a string
-- Added ability to lowercase and clean string by adding more arguments
function zapi.misc.string.trim(s, lower, clean)
	if s == nil then return "" end
	s = tostring(s)
	s = string.match(s, "^%s*(.-)%s*$")
	if lower then s = string.lower(s) end
	return zapi.misc.string.clean(s, clean)
end

--- Splits string into a table using pattern
function zapi.misc.string.split(s, pattern)
	local t = {}
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = string.find(s, fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			t[o(t)+1] = cap
		end
		last_end = e + 1
		s, e, cap = string.find(s, fpat, last_end)
	end

	if last_end <= string.len(s) then
		cap = string.sub(s,last_end)
		t[o(t)+1] = cap
	end
	return t
end

--- Makes first character in string uppercase
function zapi.misc.string.capitalize(str)
	return (string.gsub(str,"^%l", string.upper))
end


---------------
-- IP FUNCTIONS
---------------
---
-- ip1 is the full ip to match
-- ip2 is the possibily partial ip
function zapi.misc.string.ip_match(ip1, ip2)
	if not ip1 or not ip2 then return false end
	if not string.find(ip1, "%d+%.%d+%.%d+%.%d+") then return false end
	if ip1 == '' or ip2 == '' then return false end -- Don't want to match anything
    if string.find(ip2, "%d+%.%d+%.%d+%.%d+") then -- Match with FULL IP
        if ip1 == ip2 then
            return true
        else
            return false
        end
    else
        if string.find(ip1, ip2, 1, true) then -- PARTIAL IP
            return true
        else
            return false
        end
    end
end

--- Checks if a ip is IPv4
function zapi.misc.string.ipv4(ip)
	if ip == nil then return false end
	if zapi.misc.string.ip_type(ip) == 1 then
		return true
	else
		return false
	end
end

--- Checks type of ip
-- 0 = not string
-- 1 = ipv4
-- 2 = ipv6
-- 3 = random string
-- http://stackoverflow.com/questions/10975935/lua-function-check-if-ipv4-or-ipv6-or-string
function zapi.misc.string.ip_type(ip)
	-- must pass in a string value
	if ip == nil or type(ip) ~= "string" then
		return 0
	end

	-- check for format 1.11.111.111 for ipv4
	local chunks = { string.match(ip, "(%d+)%.(%d+)%.(%d+)%.(%d+)")}
	if o(chunks) == 4 then
		for _,v in pairs(chunks) do
			if (tonumber(v) < 0 or tonumber(v) > 255) then
				return 0
			end
		end
		return 1
	else
		return 0
	end

	-- check for ipv6 format, should be 8 'chunks' of numbers/letters
	local _, chunks = string.gsub(ip,"[%a%d]+%:?", "")
	if chunks == 8 then
		return 2
	end

	-- if we get here, assume we've been given a random string
	return 3
end


-----------------
-- TIME FUNCTIONS
-----------------

--- Convert a time format to seconds
-- Example 2m = 120 seconds
function zapi.misc.string.timeFormat(timeinfo)
	if not timeinfo then return 0 end
	if tonumber(timeinfo) then return tonumber(timeinfo) end
	timeinfo = string.lower(zape.misc.string.trim(timeinfo))
	local time, timeType = string.match(timeinfo, "^(%d+)(%a)$")
	time = tonumber(time)
	if not time or not timeType then return 0 end
	if timeType == "s" then
		return time
	elseif timeType == "m" then
		return time * 60
	elseif timeType == "h" then
		return time * 3600
	elseif timeType == "d" then
		return time * 86400
	elseif timeType == "w" then
		return time * ( 86400 * 7 )
	elseif timeType == "o" then
		return time * ( 86400 * 30 )
	elseif timeType == "y" then
		return time * ( 86400 * 365 )
	else
		return time
	end
end

--- Converts seconds to a more readable format
-- not sure delta is the correct term for this but im going with it
function zapi.misc.string.timeDelta(seconds)
	seconds = tonumber(seconds) or 0
	if seconds <= 0 then return "0 seconds" end

	local days = math.floor( seconds / 86400 );seconds = math.mod(seconds, 86400)
	local hours = math.floor( seconds / 3600 );seconds = math.mod(seconds , 3600)
	local mins = math.floor( seconds / 60 );seconds = math.floor( math.mod(seconds, 60) )

	if days == 1 then
		days = "1 Day "
	elseif days > 0 then
		days = days .. " Days "
	elseif days <= 0 then
		days = ""
	end

	if hours == 1 then
		hours = "1 Hour "
	elseif hours > 0 then
		hours = string.format("%02.f", hours) .. " Hours "
	elseif hours <= 0 then
		hours = ""
	end

	if mins == 1 then
		mins = "1 Minute "
	elseif mins > 0 then
		mins = string.format("%02.f", mins) .. " Minutes "
	elseif mins <= 0 then
		mins = ""
	end

	if seconds == 1 then
		seconds = "1 Second"
	elseif seconds > 0 then
		seconds = string.format("%02.f", seconds) .. " Seconds"
	elseif seconds <= 0 then
		seconds = ""
	end

	return days .. hours .. mins .. seconds
end


-------------------------
-- NUMBER/FLOAT FUNCTIONS
-------------------------
--- Guarantee integer value
-- Rounds up or down based on decimal value
function zapi.misc.int(floatvalue , floor)
	if not floatvalue then return nil end
	if floor then floatvalue = math.floor(floatvalue) end
	local intvalue, decimal = math.modf( floatvalue )
	if decimal >= 0.5 then
		intvalue = intvalue + 1
	end
	if math.tointeger then
		return math.tointeger(intvalue)
	else
		return tonumber(intvalue)
	end
end

--- Round to decimal value
function zapi.misc.round(value, decimal)
	if decimal then
		return math.floor( ((value * 10^decimal) + 0.5) / (10^decimal) )
	else
		return math.floor(value+0.5)
	end
end

--- Rounds percentage to decimal value
function zapi.misc.roundPercent(value,decimal)
	local mult = 10^(decimal or 0)
	return math.floor(value * mult + 0.5) / mult
end