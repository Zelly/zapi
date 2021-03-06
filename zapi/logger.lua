zapi.logger = { }
zapi.logger.path = "zapi/logs/"
zapi.logger.filename = os.date("%B %d %A") .. ".log"
zapi.logger.filedata = { }
zapi.logger.debugging = false
zapi.logger.debugstream = false
zapi.logger.debugfilename = "zapi_debug.log"
zapi.logger.debugdata = { }
zapi.logger.errorcount = 0
zapi.logger.printerrors = true
local errorFilePath = zapi.homepath .. 'zapi_errors.log' -- keep this out of zapi & logs dir because we can't guarntee they are created

--[[

Print to server only:
zapi.logger.log(logType, message)
zapi.logger.debug(message)
zapi.logger.info(message)
zapi.logger.error(errorLocation, errorTraceback)

Print to all players:
zapi.logger.chat(message)
zapi.logger.echo(message)
zapi.logger.banner(message)
zapi.logger.centerprint(message)
zapi.logger.print(message)

zapi.logger.save()
zapi.logger.savedebugstream()
]]--


--- logType is generally the function the log message is coming from
function zapi.logger.log(logType, message)
	local datetime = os.date("%X")
	local newLog = {
		datetime,
		logType,
		message,
	}
	zapi.logger.filedata[o(zapi.logger.filedata)+1] = newLog
end

function zapi.logger.error(errorLocation, errorTraceback)
	if not errorLocation or not errorTraceback then return end
	zapi.logger.errorcount = zapi.logger.errorcount + 1
	local errorFile = io.open(errorFilePath, "ab")
	errorFile:write("\n(" .. zapi.logger.errorcount .. ") " .. os.date("%c") .. " " .. errorLocation .. "\n" .. errorTraceback .. "\n")
	errorFile:close()
	et.G_LogPrint("zapi-error(" .. zapi.logger.errorcount .. "): " .. errorLocation .. "\n")
	if zapi.logger.printerrors then
		et.G_LogPrint(errorTraceback .. "\n")
	end
	if zapi.logger.errorcount >= 1000 then
		-- Wayyyy too many errors happening force a shutdown
		et.G_LogPrint("zapi-error: ****FATAL**** Forcing zapi shutdown, too many errors\n")
		et.G_LogPrint("zapi-error: Check " .. errorFilePath .. "\n")
		et_ShutdownGame()
		zapi = nil
	end
end


function zapi.logger.debug(message)
	if not zapi.logger.debugging then return end
	et.G_LogPrint("[DEBUG] ".. message  .."\n")
	if zapi.logger.debugstream then
		-- debug stream file saves should be done in routines
		zapi.logger.debugdata[o(zapi.logger.debugdata)+1] = os.date("%X") .. " " .. message
	end
end

function zapi.logger.info(message)
	et.G_LogPrint("[INFO] ".. message  .."\n")
end

function zapi.logger.chat(message)
	et.trap_SendServerCommand( -1, "chat \"" .. message .. zapi.color.white .. "\"")
end

function zapi.logger.centerprint(message)
	et.trap_SendServerCommand( -1, "cp \"" .. message .. zapi.color.white .. "\"")
end

function zapi.logger.banner(message)
	et.trap_SendServerCommand( -1, "bp \"" .. message .. zapi.color.white .. "\"")
end

function zapi.logger.echo(message)
	et.trap_SendServerCommand( -1, "echo \"" .. message .. zapi.color.white .. "\"")
end

function zapi.logger.print(message)
	et.trap_SendServerCommand( -1, "print \"" .. message .. zapi.color.white .. "\"")
end

function zapi.logger.save()
	if not next(zapi.logger.filedata) then return end
	local saveData = { }
	for k=1, o(zapi.logger.filedata) do
		saveData[o(saveData)+1] = zapi.logger.filedata[k][1] .. " " .. zapi.logger.filedata[k][2] .. " " .. zapi.logger.filedata[k][3]
	end
	
	if not next(saveData) then return end
	zapi.file.save(zapi.logger.path .. zapi.logger.filename, saveData, "a")
end

function zapi.logger.savedebugstream()
	if not zapi.logger.debugging or not zapi.logger.debugstream then return end
	if not next(zapi.logger.debugdata) then return end
	zapi.file.save(zapi.logger.path .. zapi.logger.debugfilename, zapi.logger.debugdata, "a")
	zapi.logger.debugdata = { } -- refresh file data
end