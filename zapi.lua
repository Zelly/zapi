zapi = { }

if string.find(_VERSION,"5.0") then
	zapi.old = true
else
	zapi.old = false
end

if zapi.old then
	local _tlen = table.getn
	local _sform = string.format
	local _unp = unpack
	local _sf = string.find
	va = function(...)
		return _sform(_unp(arg))
	end
	o = function(t)
		if not t or type(t) ~= "table" then return 0 end
		return _tlen(t)
	end
	string.match = function(s, p)
		local junk1,junk2,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10 = _sf(s , p )
		return a1,a2,a3,a4,a5,a6,a7,a8,a9,a10
	end
end
--[[

also tabs because im savage
]]--
zapi.NAME = "zapi"
zapi.LONGNAME = "Zelly's Lua API"
zapi.VERSION = "v0.0.1"
zapi.DESCRIPTION = "Zelly's Lua API of a Lua API, meant to make using Lua in ET easier"
zapi.AUTHOR = "Zelly"
zapi.CONTACT = "Discord: Tetra#4663"


--- Basepath is where the executable and lua files are
zapi.basepath = string.gsub( et.trap_Cvar_Get("fs_basepath"),"\\","/") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/"
LUA_PATH = LUA_PATH .. ';' .. zapi.basepath -- Perhaps bad, if it already exists?
--- Homepath is where logs and json goes
zapi.homepath = string.gsub( et.trap_Cvar_Get("fs_homepath"),"\\","/") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/"


zapi.startTime = -1 -- Level time the game started.
zapi.isRestart = false
zapi.currentRound = 0

require("zapi/misc")
require("zapi/vars")
require("zapi/logger")
require("zapi/file")
require("zapi/client")
require("zapi/command")
require("zapi/misc")


--[[
InitGame
	Called every map load, including warmups
	[levelTime]
		The current level time in milliseconds
	[randomSeed]
		Number that can be used to seed random number generators
	[restart]
		1 if map restart 0 if not
]]--
function et_InitGame(levelTime, randomSeed, restart)
	levelTime = levelTime
	math.randomseed(randomSeed)
	if restart == 1 then
		zapi.isRestart = true
	else
		zapi.isRestart = false
	end
	et.RegisterModname( zapi.NAME)
	zapi.logger.info(zapi.NAME .. " finished loading")
end

--[[ Intermission
[round] don't remember the actual values this goes through
]]--
function et_IntermissionStarts( round )
	zapi.currentRound = round
end

--- ShutdownGame
-- [restart] if map restart then 1 else 0
function et_ShutdownGame( restart )
	zapi.logger.save()
end

--- Damage
-- [target] Target id
-- [attacker] Attacker id
-- [damage] Damage amount
-- [dflags] Damage flags
-- [mod] method of death
function et_Damage( target, attacker, damage, dflags, mod )
	
end

--- RunFrame
-- [levelTime]  is the current level time in milliseconds
function et_RunFrame( levelTime )
	if not math.mod(levelTime, 50) == 0 then return end
end

--- ClientUserinfoChanged
-- [clientNum]
function et_ClientUserinfoChanged(clientNum)
	
end

--- ClientBegin
-- [clientNum]
function et_ClientBegin( clientNum )
	
end

--- et_ClientConnect
-- [clientNum]
function et_ClientConnect(clientNum, firstTime, isBot)
	
end

--- et_ClientDisconnect
-- [clientNum]
function et_ClientDisconnect( clientNum )
	
end

--- et_ClientSpawn
-- [clientNum]
-- [revived]
-- [teamChange]
-- [restoreHealth]
function et_ClientSpawn( clientNum, revived, teamChange, restoreHealth )
	
end

--- et_Obituary
-- [clientNum]
function et_Obituary( victimNum, killerNum, meansOfDeath )
	
end

--- et_ConsoleCommand
-- [clientNum]
function et_ConsoleCommand( command )
	
end

--- et_ClientCommand
-- [clientNum]
function et_ClientCommand( clientNum, command )
	
end

--- et_CvarValue
-- [clientNum]
function et_CvarValue( clientNum, cvar, value )
	
end

--- Print
-- [text] text printed to server console
-- not used
--[[function et_Print( text )
	-- body
end--]]
