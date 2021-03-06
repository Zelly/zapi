--- zapi.lua - Core file callbacks, some game functions
zapi = { }
--[[
When I try to intialize global variables from the other files they are unaccessible(basically they become local)
That is why zapi pretty much acts as my "global" 
]]--
zapi.NAME = "zapi"
zapi.LONGNAME = "Zelly's Lua API"
zapi.VERSION = "v0.0.1"
zapi.DESCRIPTION = "Zelly's Lua API of a Lua API, meant to make using Lua in ET easier"
zapi.AUTHOR = "Zelly"
zapi.CONTACT = "Discord: Tetra#4663" -- Might make a discord server later

--- Checks whether we are on lua 5.0 or if we are on greater than 5.0
-- The o() function is "Table Length" used in for loops etc.
-- 5.1+ they added "#tableName" to get the length, but since we trying to be compatible with 5.0
-- we need to use o(tableName) for anytime we getting table length
if string.find(_VERSION,"5.0") then
	zapi.old = true
	va = function(...)
		return string.format(unpack(arg))
	end
	o = function(t)
		if not t or type(t) ~= "table" then return 0 end
		return table.getn(t)
	end
	string.match = function(s, p)
		local junk1,junk2,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10 = string.find(s , p )
		return a1,a2,a3,a4,a5,a6,a7,a8,a9,a10
	end
else
	zapi.old = false
	o = function(t)
		return #t
	end
	if not math.mod then
		function math.mod( num , div )
			return num % div
			--return num - ( math.tointeger(math.floor( num / div )) * div )
		end
	end
end


--- Basepath is where the executable and lua files are
zapi.basepath = string.gsub( et.trap_Cvar_Get("fs_basepath"),"\\","/") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/"
LUA_PATH = LUA_PATH .. ';' .. zapi.basepath -- Perhaps bad, if it already exists?
--- Homepath is where logs and any other written to data goes
zapi.homepath = string.gsub( et.trap_Cvar_Get("fs_homepath"),"\\","/") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/"

zapi.startTime = -1 -- Level time the game started.
zapi.currentRound = 0
zapi.gamestate = "none" -- "unknown", "warmup", "restart", "game"
zapi.isRestart = false -- is this game a result of map_restart
zapi.intermission = false
zapi.mapname = ""
zapi.modname = ""
zapi.teams = { }
zapi.teams.bots = { }
zapi.teams.players = { }


--- Load all the required zapi modules
require("zapi/misc")
require("zapi/vars")
require("zapi/logger")
require("zapi/file")
require("zapi/client")
require("zapi/scheduler")
--require("zapi/command")
-- will likely add the extra module loader here too


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
		zapi.modname = string.lower(et.trap_Cvar_Get("fs_game"))
		
		if restart == 1 then
			zapi.isRestart = true
		else
			zapi.isRestart = false
		end
		
		-- various values to tell what type of game is happening
		if not gamestate or not restart then
			zapi.gamestate = "unknown"
		elseif gamestate == 2 and restart == 0 then
			zapi.gamestate = "warmup"
		elseif gamestate == 2 and restart == 1 then
			zapi.gamestate = "restart"
		elseif gamestate == 0 and restart == 1 then
			zapi.gamestate = "game"
		else
			zapi.gamestate = "unknown gs:" .. gamestate .. " restart:" .. restart
			zapi.logger.debug("Unknown gamestate: gs:" .. gamestate .. " restart:" .. restart)
		end
		
		zapi.logger.log("init", zapi.mapname .. " " .. zapi.gamestate .. " round " .. zapi.currentRound)
		
		et.RegisterModname( zapi.NAME)
		
		-- Register debug log file to save every 15s
		if zapi.logger.debugging and zapi.logger.debugstream then
			zapi.scheduler.add(function() zapi.logger.savedebugstream() end,15,15,"Saves debug and custom log stream")
		end
		zapi.getTeams()
		zapi.logger.info(zapi.NAME .. " finished loading")
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_InitGame", callbackReturn)
	end
end

--[[ Intermission
[round] don't remember the actual values this goes through
-- not in etpro
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
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("zapi.IntermissionStarts", callbackReturn)
	end
end

--- ShutdownGame
-- [restart] if map restart then 1 else 0
function et_ShutdownGame( restart )
	local status,callbackReturn = pcall( function()
		zapi.logger.save()
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ShutdownGame", callbackReturn)
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
	end) -- end pcall (error checking)
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
		local Client = zapi.client.get(clientNum)
		if not Client then return end
		local newTeam = Client:getTeam()
		local name = zapi.misc.string.trim(Client:getName())
		if Client.team == 0 then
			-- Set team for first time, since it was not done elsewhere
			zapi.logger.debug("et_ClientUserinfoChanged("..name..") .team("..Client.team..") == 0 || newTeam = ("..newTeam..")")
			Client.team = newTeam
		elseif Client.team ~= newTeam then
			zapi.logger.debug("et_ClientUserinfoChanged("..name..") .team("..Client.team..") ~= newTeam("..newTeam..")")
			zapi.ClientSwitchTeam(Client, newTeam)
		end
		
		if name ~= Client.name then
			zapi.ClientChangeName(Client, name)
		end
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientUserinfoChanged", callbackReturn)
	end
end

function zapi.ClientChangeName(Client, name)
	zapi.logger.debug("ClientChangeName("..name..") changed name from " .. Client.name)
	Client.name = Client:getName()
end

function zapi.ClientSwitchTeam(Client, team)
	local fromTeam = Client.team
	zapi.logger.debug("ClientSwitchTeam("..Client:getName()..") .team("..Client.team..") ~= newTeam("..team..")")
	Client.team = team
	zapi.getTeams()
	-- Do I need a Client.skipNext ?
end

--- ClientBegin
-- [clientNum]
function et_ClientBegin( clientNum )
	local status,callbackReturn = pcall( function()
		zapi.logger.debug("et_ClientBegin("..clientNum..")")
		local Client = zapi.client.new(clientNum)
		if not Client.newClient then
			-- Client was already created
			return
		end
		Client.newClient = false
		if Client.name == "" then
			Client.name = zapi.misc.string.trim(Client:getName())
		end
		if Client.team == 0 then
			Client.team = Client:getTeam()
		end
		Client:validate()
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientBegin", callbackReturn)
	end
end

--- et_ClientSpawn
-- [clientNum]
-- [revived]
-- [teamChange]
-- [restoreHealth]
function et_ClientSpawn( clientNum, revived, teamChange, restoreHealth )
	local status,callbackReturn = pcall( function()
		zapi.logger.debug("et_ClientSpawn( "..clientNum..","..revived..","..tostring(teamChange)..","..tostring(restoreHealth).." )")
		--local Client = zapi.client.get(clientNum)
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientSpawn", callbackReturn)
	end
end

--- et_ClientConnect
-- [clientNum]
function et_ClientConnect(clientNum, firstTime, isBot)
	local status,callbackReturn = pcall( function()
		zapi.logger.debug("et_ClientConnect( "..clientNum..","..firstTime..","..isBot.." )")
		local Client = zapi.client.new(clientNum)
		if not Client then
			zapi.logger.debug("et_ClientConnect: failed to get new client for " .. clientNum)
			return
		end
		if firstTime == 1 then
			Client.firstConnect = true
		else
			Client.firstConnect = false
		end
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientConnect", callbackReturn)
	end
end

--- et_ClientDisconnect
-- [clientNum]
function et_ClientDisconnect( clientNum )
	local status,callbackReturn = pcall( function()
		zapi.logger.debug("et_ClientDisconnect( "..clientNum..")")
		local Client = zapi.client.get(clientNum)
		--Game:setLastConnect(Client,false)
		zapi.client.delete(Client.id)
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientDisconnect", callbackReturn)
	end
end

--- et_ConsoleCommand
-- [clientNum]
function et_ConsoleCommand( command )
	local status,callbackReturn = pcall( function()
		
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ConsoleCommand", callbackReturn)
	end
end

--- et_ClientCommand
-- [clientNum]
function et_ClientCommand( clientNum, command )
	local status,callbackReturn = pcall( function()
		
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_ClientCommand", callbackReturn)
	end
end

--- et_CvarValue
-- [clientNum]
-- [cvar]
-- [value]
-- this is where G_QueryClientCvar sends its returned info
function et_CvarValue( clientNum, cvar, value )
	local status,callbackReturn = pcall( function()
		
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_CvarValue", callbackReturn)
	end
end

--- et_Obituary
-- [clientNum]
function et_Obituary( victimNum, killerNum, meansOfDeath )
	local status,callbackReturn = pcall( function()
		if zapi.gamestate ~= "game" then return end
		zapi.logger.debug("et_Obituary( "..victimNum..","..killerNum..","..meansOfDeath.." )")
		local Killer = zapi.client.get(killerNum)
		local Victim = zapi.client.get(victimNum)
		if not Killer and not Victim then
			-- Non client death, not sure if this happens, other than in a lua error
			return
		end
		if Killer and not Victim then
			-- Killer killed an unknown victim/entity
			return
		end
		Victim:died()
		if not Killer and Victim then
			-- A world death (The map killed the player, i think falling to death too)
			zapi.WorldDeath(Victim, meansOfDeath)
			return
		end
		if Killer.id == Victim.id then
			-- Player killed himself.
			zapi.SelfKill(Victim, meansOfDeath)
			return
		end
		
		if Killer:getTeam() == Victim:getTeam() then
			-- A teamkill
			zapi.TeamKill(Killer,Victim,meansOfDeath)
			return
		else
			-- A normal kill
			zapi.Kill(Killer,Victim,meansOfDeath)
			return
		end
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_Obituary", callbackReturn)
	end
end

--- These obituary callbacks expect that Killer and Victim are valid since they are already checked in et_Obituary
function zapi.Kill(Killer,Victim,mod)
	
end

function zapi.TeamKill(Killer,Victim,mod)
	
end

function zapi.WorldKill(Victim,mod)
	
end

function zapi.SelfKill(Victim,mod)
	
end

--- Damage
-- [target] Target id
-- [attacker] Attacker id
-- [damage] Damage amount
-- [dflags] Damage flags
-- [mod] method of death
--[[
function et_Damage( target, attacker, damage, dflags, mod )
	local status,callbackReturn = pcall( function()
		
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_Damage", callbackReturn)
	end
end]]--

--- Print
-- [text] text printed to server console
function et_Print( text )
	local status,callbackReturn = pcall( function()
		zapi.client.getETProIACGuid(text)
	end) -- end pcall (error checking)
	if not status then
		zapi.logger.error("et_Print", callbackReturn)
	end
end

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

function zapi.getTeamNum(team)
	if not team then return nil end
	if ( team == "b" or team == "allies" or team == "allied" or tonumber(team) == et.TEAM_ALLIES ) then
		team = et.TEAM_ALLIES
	elseif ( team == "r" or team == "axis" or tonumber(team) == et.TEAM_AXIS ) then
		team = et.TEAM_AXIS
	elseif ( team == "s" or team == "spectator" or team == "spec" or tonumber(team) == et.TEAM_SPEC ) then
		team = et.TEAM_SPEC
	end
	if ( team ~= et.TEAM_AXIS and team ~= et.TEAM_ALLIES and team ~= et.TEAM_SPEC ) then return end
	return team
end

function zapi.getTeams()
	zapi.teams.bots[et.TEAM_AXIS] = 0
	zapi.teams.bots[et.TEAM_ALLIES] = 0
	zapi.teams.bots[et.TEAM_SPEC] = 0
	zapi.teams.players[et.TEAM_AXIS] = 0
	zapi.teams.players[et.TEAM_ALLIES] = 0
	zapi.teams.players[et.TEAM_SPEC] = 0
	for k=1, o(zapi.client.clients) do
		local Client = zapi.client.clients[k]
		local team = Client:getTeam()
		if Client:isBot() then
			if team == et.TEAM_AXIS then
				zapi.teams.bots[et.TEAM_AXIS] = zapi.teams.bots[et.TEAM_AXIS] + 1
			elseif team == et.TEAM_ALLIES then
				zapi.teams.bots[et.TEAM_ALLIES] = zapi.teams.bots[et.TEAM_ALLIES] + 1
			elseif team == et.TEAM_SPEC then
				zapi.teams.bots[et.TEAM_SPEC] = zapi.teams.bots[et.TEAM_SPEC] + 1
			else
				zapi.logger.debug("zapi.getTeams(): got bot " .. Client.id .. " on invalid team " .. team)
				zapi.teams.bots[et.TEAM_SPEC] = zapi.teams.bots[et.TEAM_SPEC] + 1
			end
		else
			if team == et.TEAM_AXIS then
				zapi.teams.players[et.TEAM_AXIS] = zapi.teams.players[et.TEAM_AXIS] + 1
			elseif team == et.TEAM_ALLIES then
				zapi.teams.players[et.TEAM_ALLIES] = zapi.teams.players[et.TEAM_ALLIES] + 1
			elseif team == et.TEAM_SPEC then
				zapi.teams.players[et.TEAM_SPEC] = zapi.teams.players[et.TEAM_SPEC] + 1
			else
				zapi.logger.debug("zapi.getTeams(): got player " .. Client.id .. " on invalid team " .. team)
				zapi.teams.players[et.TEAM_SPEC] = zapi.teams.players[et.TEAM_SPEC] + 1
			end
		end
	end
end

function zapi.isPlayerOnServer()
	local players = (zapi.teams.players[et.TEAM_AXIS] + zapi.teams.players[et.TEAM_ALLIES] + zapi.teams.players[et.TEAM_SPEC])
	if players > 0 then
		return true
	else
		return false
	end
end

function zapi.isPlayerOnTeam()
	local players = (zapi.teams.players[et.TEAM_AXIS] + zapi.teams.players[et.TEAM_ALLIES])
	if players > 0 then
		return true
	else
		return false
	end
end

function zapi.isClientOnTeam() -- includes bots
	local players = (zapi.teams.players[et.TEAM_AXIS] + zapi.teams.players[et.TEAM_ALLIES] + zapi.teams.bots[et.TEAM_AXIS] + zapi.teams.bots[et.TEAM_ALLIES])
	if players > 0 then
		return true
	else
		return false
	end
end

