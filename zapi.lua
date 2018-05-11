zapi = { }

if string.find(_VERSION,"5.0") then
	zapi.old = true
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
else
	zapi.old = false
end

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
zapi.gamestate = "none"
zapi.intermission = false
zapi.mapname = ""

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
	local status,callbackReturn = pcall( function()
		local gamestate = et.trap_Cvar_Get("gamestate")
		zapi.currentRound = et.trap_Cvar_Get("g_currentround")
		math.randomseed(randomSeed)
		zapi.startTime = levelTime
		zapi.mapname = string.lower(et.trap_Cvar_Get("mapname"))
		
		if restart == 1 then
			zapi.isRestart = true
		else
			zapi.isRestart = false
		end
		
		-- various values to tell what type of game is happening
		if not gamestate or not restart then
			zapi.gamestate = "unknown"
		elseif gamestate == 2 and restart = 0 then
			zapi.gamestate = "warmup"
		elseif gamestate == 2 and restart = 1 then
			zapi.gamestate = "restart"
		elseif gamestate == 0 and restart = 1 then
			zapi.gamestate = "game"
		else
			zapi.gamestate = "unknown gs:" .. gamestate .. " restart:" .. restart
			zapi.logger.debug("Unknown gamestate: gs:" .. gamestate .. " restart:" .. restart)
		end
		
		zapi.logger.log("init", zapi.mapname .. " " .. zapi.gamestate .. " round " .. zapi.currentRound)
		
		et.RegisterModname( zapi.NAME)
		zapi.logger.info(zapi.NAME .. " finished loading")
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_InitGame", callbackReturn)
	end
end

--[[ Intermission
[round] don't remember the actual values this goes through
]]--
function et_IntermissionStarts( round )
	-- redirect this function, cause it is not in all mods
	zapi.IntermissionStarts()
end

function zapi.IntermissionStarts()
	local status,callbackReturn = pcall( function()
		zapi.currentRound = et.trap_Cvar_Get("g_currentround")
		zapi.intermission = true
		zapi.logger.log("intermission", zapi.mapname .. " round " .. zapi.currentRound)
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("zapi.IntermissionStarts", callbackReturn)
	end
end

--- ShutdownGame
-- [restart] if map restart then 1 else 0
function et_ShutdownGame( restart )
	local status,callbackReturn = pcall( function()
		zapi.logger.save()
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ShutdownGame", callbackReturn)
	end
end

--- Damage
-- [target] Target id
-- [attacker] Attacker id
-- [damage] Damage amount
-- [dflags] Damage flags
-- [mod] method of death
function et_Damage( target, attacker, damage, dflags, mod )
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_Damage", callbackReturn)
	end
end

--- RunFrame
-- [levelTime]  is the current level time in milliseconds
function et_RunFrame( levelTime )
	if not math.mod(levelTime, 50) == 0 then return end
	zapi.scheduler.levelTime = levelTime
	local status,callbackReturn = pcall( function()
		if not zapi.intermission and et.trap_Cvar_Get("gamestate") == 3 then zapi.IntermissionStart() end -- for non silent mods
		-- Check if any active clients.
		zapi.scheduler.run(levelTime)
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_RunFrame", callbackReturn)
	end
	
	
	--[[
	todo: routine handler
	]]--
end

--- ClientUserinfoChanged
-- [clientNum]
function et_ClientUserinfoChanged(clientNum)
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientUserinfoChanged", callbackReturn)
	end
end

--- ClientBegin
-- [clientNum]
function et_ClientBegin( clientNum )
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientBegin", callbackReturn)
	end
end

--- et_ClientConnect
-- [clientNum]
function et_ClientConnect(clientNum, firstTime, isBot)
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientConnect", callbackReturn)
	end
end

--- et_ClientDisconnect
-- [clientNum]
function et_ClientDisconnect( clientNum )
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientDisconnect", callbackReturn)
	end
end

--- et_ClientSpawn
-- [clientNum]
-- [revived]
-- [teamChange]
-- [restoreHealth]
function et_ClientSpawn( clientNum, revived, teamChange, restoreHealth )
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientSpawn", callbackReturn)
	end
end

--- et_Obituary
-- [clientNum]
function et_Obituary( victimNum, killerNum, meansOfDeath )
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_Obituary", callbackReturn)
	end
end

--- et_ConsoleCommand
-- [clientNum]
function et_ConsoleCommand( command )
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ConsoleCommand", callbackReturn)
	end
end

--- et_ClientCommand
-- [clientNum]
function et_ClientCommand( clientNum, command )
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientCommand", callbackReturn)
	end
end

--- et_CvarValue
-- [clientNum]
function et_CvarValue( clientNum, cvar, value )
	local status,callbackReturn = pcall( function()
		
	end -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_CvarValue", callbackReturn)
	end
end

--- Print
-- [text] text printed to server console
-- not used
--[[function et_Print( text )
	-- body
end--]]

--- Game functions specific to ET
function zapi.getMapPercentageComplete()
	local timePassed = ( et.trap_Milliseconds() - zapi.startTime )
	local timeLimit = ( et.trap_Cvar_Get("timelimit") * 60 * 1000 )
	return zapi.misc.roundPercent(timePassed / timeLimit, 2)
end

--- Checks if shrubbot lua is supported
function zapi.shrubbot()
	if et.G_shrubbot_level == nil then
		return false
	else
		return true
	end
end

-- todo: add Game:getTeams functions
-- todo: add Game:Spec999
-- todo: add Game:ClientGibbed
-- todo: add Game:ClientSwitchTeam
-- todo: add ClientChangeName
-- todo: add setLastConnect
-- todo: add isPlayerOnServer
-- todo: add bit support
-- todo: add obituary stuff, kill, teamkill, death, selfkill,world death

