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
	return self.SUCCESS
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

function FileHandler:LoadFile(fileName,ignoreComments)
    if not fileName then return self.NOT_EXIST end
    if not self:exists(fileName) then return self.NOT_EXIST end
    if ignoreComments ~= true then ignoreComments = false end
    
    local status , FileObject , err = pcall(io.open,Core.homepath .. fileName, "r")
    if not FileObject then return self.ERROR,err end
    if not status then return self.ERROR,FileObject end
    
    local fileData = { }
    local inBlockComment = false
    for line in FileObject:lines() do
        if not line then break end
        line = string.gsub( line , "\r" , "" ) -- FUCK MOTHER FUCKING CARRIAGE RETURNS
        if ignoreComments then
            -- WIP still needs testing
            -- I believe string find will need to be subtracted by 2
            local commentStart = string.find(line,'/%*')
            local commentEnd = -1
            if commentStart then -- Checks if block comment ends same line
                if string.find(line,'%*/') then commentEnd = string.find(line,'%*/') else inBlockComment = true end
            elseif not commentStart and inBlockComment then
                if string.find(line,'%*/') then commentEnd = string.find(line,'%*/') end
            elseif not commentStart and not inBlockComment then
                commentStart = string.find(line,'//')
                commentEnd   = -1
            end
            if commentStart then
                local newLine = string.sub(line,1,commentStart)
                if Misc:trim(newLine) ~= "" then fileData[tlen(fileData)+1] = newLine end
            end
        else
            if line ~= "" then fileData[tlen(fileData)+1] = line end
        end
    end
    FileObject:close()
    Console:Debug("Read " .. tlen(fileData) .. " lines from " .. fileName,"file")
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