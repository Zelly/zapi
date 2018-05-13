zapi.file = { }
zapi.file.ERROR = 0
zapi.file.SUCCESS = 1
zapi.file.NO_PATH = 2
zapi.file.NO_DATA = 3
--[[
zapi.file.save(filePath, fileData, saveType)
	Returns a number value depending on success or error.
zapi.file.load(filePath)
	Returns a number value depending on error, otherwise returns the file in string form.
zapi.file.exists(filePath)
	returns true or false
zapi.file.touch(filePath)
	creates empty file at destination
	No check done to whether it exists, if it does it will overwrite with empty file.

All "filePath"'s are relative to fs_homepath
TODO: Maybe look into doing more with files but for now the basics is good enough.
	JSON/Lua
]]--
-- zapi.file.save(filePath, fileData, saveType)
-- zapi.file.exists

function zapi.file.save(filePath, fileData, saveType)
	if not filePath then return zapi.file.NO_PATH end
	if not fileData then return zapi.file.NO_DATA end
	if not saveType then saveType = "w" end
	
	local status, fileObject, err = pcall(io.open, zapi.homepath .. filePath, saveType)
	if not fileObject or not status then return zapi.file.ERROR, fileObject or err end
	if type(fileData) == "table" then
		for k=1, o(fileData) do
			fileObject:write(fileData[k] .. "\n")
		end
	else
		fileObject:write(fileData[k] .. "\n")
	end
	fileObject:close()
	zapi.logger.debug("Wrote to " .. tostring(filePath))
	return zapi.file.SUCCESS
end

function zapi.file.load(filePath)
	if not filePath then return zapi.file.NO_PATH end
	if not zapi.file.exists(filePath) then return zapi.file.NO_DATA end
	local status, fileObject, err = pcall(io.open, zapi.homepath .. filePath, "r")
	if not fileObject or not status then return zapi.file.ERROR, fileObject or err end
	
	local fileData = { }
	for line in fileObject:lines() do
		if not line then break end
		line = string.gsub(line, "\r", "") -- Remove carriage returns
		if line ~= "" then
			fileData[o(fileData)+1] = line
		end
	end
	return table.concat(fileData,'\n')
end

function zapi.file.exists(filePath)
	if not filePath then return false end
	local fileObject = io.open(zapi.homepath .. filePath, "r")
	if fileObject then
		io.close(fileObject)
		zapi.logger.debug(filePath .. " - file exists: true")
		return true
	else
		zapi.logger.debug(filePath .. " - file exists: false")
		return false
	end
end

function zapi.file.touch(filePath)
	local status, fileObject = pcall(io.open, zapi.homepath .. filePath, "w")
	if status then
		fileObject:write("")
		fileObject:close()
		zapi.logger.debug("Created empty file at " .. filePath)
	end
end