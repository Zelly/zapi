zapi.client = { }
zapi.client.clients = { }

-- todo: add guid validator
-- left out all guid stuff for now to make sure it works right
-- todo: comments, messaging(chat,print,etc.), logging
-- todo obituary callbacks? pretty sure not possible here

-- todo a test if local Client is the same memory location as zapi.misc.table.get, then we can do away with zapi.misc.table.get
function zapi.client.new(clientNum)
	local Client = zapi.misc.table.get(zapi.client.clients, clientNum, "id")
	if Client then return Client end
	
	Client = zapi.client.Client(clientNum)
	
	if zapi.misc.table.insert(zapi.client.clients, Client, true, "id") then
		zapi.logger.debug("zapi.client.new: Created new client for clientNum: " .. clientNum)
		table.sort(zapi.client.clients, function(a, b) return a.id < b.id end )
		return zapi.misc.table.get(zapi.client.clients, clientNum, "id")
	else
		zapi.logger.debug("zapi.client.new: Could not create new client(already exists) for clientNum: " .. clientNum)
		return nil
	end
end

function zapi.client.delete(clientNum)
	local Client, clientindex = zapi.misc.table.get(zapi.client.clients, clientNum, "id")
	if ( Client ~= nil or clientIndex ~= nil ) then table.remove(zapi.client.clients, clientIndex) end
	table.sort(zapi.client.clients, function(a, b) return a.id < b.id end)
	zapi.logger.debug("zapi.client.delete: Deleted client " .. clientNum)
end

function zapi.client.getWithName(name)
	if et.ClientNumberFromString then
		local clientNum = tonumber( et.ClientNumberFromString( name ) ) or -1
		if clientNum < 0 then return nil end
		return zapi.misc.table.get(zapi.client.clients, clientNum, "id")
	else
		name = zapi.misc.string.trim(name, true, true) -- lower and clean color codes
		if name == "" then return nil end
		if tonumber(name) and tonumber(name) >= 0 and tonumber(name) <= 64 then
			-- Match client slot
			return zapi.misc.table.get(zapi.client.clients, tonumber(name), "id")
		end
		for k=1, o(zapi.client.clients) do
			local Client = zapi.client.clients[k]
			local clientName = zapi.misc.string.trim(Client:getName(), true, true)
			if name == clientName then return Client end
			if string.find(clientName, name, 1, true) then
				return Client
			end
		end
		return nil
	end
end

--- Iterate over clients and run function(Client)
function zapi.client.iterate(func)
	if not func or type(func) ~= "function" then return end
	for k=1, o(zapi.client.clients) do
		func(zapi.client.clients[k])
	end
end

function zapi.client.getETProIACGuid(text)
	if zapi.modname ~= "etpro" or not text or string.len(text) < 40 then return end
	-- etpro IAC: 0 GUID [GUIDISHEREGUIDISHEREGUIDISHEREGUIDISHERE] [name]
	--      Only called once per connection
	-- etpro IAC: 0 [NAMEISHERECANCONTAINALOTOFCHARACHTERS] [GUIDISHEREGUIDISHEREGUIDISHEREGUIDISHERE] [win32]
	--      Called every game init
	-- Kind of relys on globalcombinedfixes.lua to verify this isn't malformed, so put that first.
	local clientNum, guid = string.match(text, "^etpro IAC: (%d+) %[.+%] %[(%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)%]")
	if not clientNum or not guid then return end
	if string.len(guid) ~= 40 then return end
	local Client = zapi.client.new(clientNum)
	if not Client then
		zapi.logger.debug("getETProIACGuid: " .. clientNum .. " Could not create Client")
		return
	end
	zapi.logger.debug("getETProIACGuid: " .. clientNum .. " " .. Client:getName() .. " " .. guid)
	Client.etproGuid = guid
	Client:validate()
end

zapi.client.Client = { }
zapi.client.Client.__index = zapi.client.Client
zapi.client.Client.__tostring = function(t)
	return "Client slot(" .. t.id ..")"
end

function zapi.client.Client.new(clientNum)
	local clientData = {
		id = clientNum,
		newClient = true, -- mainly for future use if we need to progamtically know its fresh client
		firstConnect = true,
		valid = false, -- Mod GUID has been validated
		team = 0,
		cvars = { },
		userinfo = { },
	}
	return setmetatable(clientData, zapi.client.Client)
end

function zapi.client.Client:begin()
end

function zapi.client.Client:validate()
	if self:isBot() then
		self.valid = true
		return
	end
	if zapi.modname == "silent" and self:getSilentGuid() == "" then
		self.valid = false
		zapi.scheduler.add(function() self:validate() end, 0, 5, "Validate silent guid for " .. self:getName())
		return
	elseif zapi.modname == "etpro" and self:getETProGuid() == "" then
		self.valid = false
		zapi.scheduler.add(function() self:validate() end, 0, 5, "Validate etpro guid for " .. self:getName())
		return
	elseif zapi.modname ~= "etpro" and zapi.modname ~= "silent" then
		local guid = self:getGuid()
		if guid == "" then
			-- could block here but I'll leave that up to server owners
			zapi.logger.debug("zapi.client.Client:validate: " .. self.id .. " " .. self:getName() .." missing default guid")
		end
	end
	
	-- Returned some sort of guid
	if not self.valid then
		zapi.logger.debug("zapi.client.Client: " .. self:getName() .. " guid validated")
		self.valid = true
		self:begin()
	end
end

function zapi.client.Client:getGuid()
	local guid = et.Info_ValueForKey( self:getUserInfo(), "cl_guid" )
	guid = string.upper(zapi.misc.trim(guid))
	if string.len(guid) ~= 32 then
		zapi.logger.debug("zapi.client.Client:getGuid: " .. self:getName() .. " guid invalid length: " .. guid)
		return nil -- return nil or empty string?
	end
	return guid
end

function zapi.client.Client:getSilentGuid()
	if zapi.modname ~= "silent" then return nil end -- return nil or empty string?
	local silentGuid = self:get("sess.guid")
	silentGuid = string.upper(zapi.misc.trim(string.gsub(silentGuid, ":%d*", "")))
	if string.len(silentGuid) == 32 then
		return silentGuid
	else
		return nil
	end
end

function zapi.client.Client:getETProGuid()
	if zapi.modname ~= "etpro" then return nil end
	if not self.etproGuid or self.etproGuid == "" then
		return nil
	end
	return string.upper(self.etproGuid)
end

function zapi.client.Client:get(fieldName, index)
	if not fieldName then return nil end
	if index then
		return et.gentity_get(self.id, fieldName, index)
	else
		return et.gentity_get(self.id, fieldName)
	end
end

function zapi.client.Client:set(fieldName, index, value)
	if not fieldName then return nil end
	if value then
		return et.gentity_get(self.id, fieldName, index, value)
	else
		return et.gentity_get(self.id, fieldName, index) -- index is actually the "value" here
	end
end

function zapi.client.Client:getLevel()
	if zapi.shrubbot() then
		return tonumber(et.G_shrubbot_level(self.id)) or 0
	else
		return 0
	end
end

function zapi.client.Client:setLevel(level)
	level = tonumber(level)
	if not level then return end
	-- not 100% sure that will work on one line may need to seperate readconfig on next line
	local cmd = string.format("setlevel %d %d\nreadconfig\n")
	et.trap_SendConsoleCommand( et.EXEC_APPEND, cmd)
end

--- Returns current total xp
function zapi.client.Client:getXp()
	local xp = 0.0
	local fieldName = "sess.skillpoints"
	if zapi.modname == "etpro" then fieldName = "sess.skill" end
	for k=0,6 do
		xp = xp + self:get(fieldName, k)
	end
	return zapi.misc.int(xp)
end

function zapi.client.Client:getSkillRank(skill)
	return self:get("sess.medals", skill)
end

function zapi.client.Client:getSkillXp(skill)
	local fieldName = "sess.skillpoints"
	if zapi.modname == "etpro" then fieldName = "sess.skill" end
	return self:get(fieldName, skill)
end

function zapi.client.Client:setSkillXp(skill, xp)
	xp = zapi.misc.int(xp)
	et.G_XP_Set(self.id, xp, skill, 0)
end

function zapi.client.Client:getSkillTable()
	return {
		self:getSkillXp(et.SKILL_SENSE),
		self:getSkillXp(et.SKILL_ENGINEER),
		self:getSkillXp(et.SKILL_MEDIC),
		self:getSkillXp(et.SKILL_SIGNAL),
		self:getSkillXp(et.SKILL_LIGHT),
		self:getSkillXp(et.SKILL_HEAVY),
		self:getSkillXp(et.SKILL_COVERT),
	}
end

--- Querys a client cvar
-- Can optionally add a function that will run 2 seconds after query
function zapi.client.Client:cvarFunction(cvar, func)
	if self:isBot() then return end
	if not et.G_QueryClientCvar then return end
	cvar = zapi.misc.string.trim(cvar, true, true)
	if cvar == "" then return end
	et.G_QueryClientCvar(self.id, cvar)
	if func and type(func) == "function" then
		zapi.scheduler.add(function()
			if self.cvars[cvar] then -- Only activate function if cvar successfully queried
				func(self)
			end
		end, 0, 2, self.id .. " query cvar " .. cvar)
	end
end

function zapi.client.Client:drop(kickTime, kickReason)
	kickTime = tonumber(kickTime) or 0
	kickReason = zapi.misc.string.trim(kickReason, true, true)
	et.trap_DropClient(self.id, kickReason, kickTime)
end

function zapi.client.Client:hasObjective()
	-- I believe 6 is obj if on allies 7 is obj on axis
	if self:get("ps.powerups", 6) == 1 or self:get("ps.powerups", 7) == 1 then
		return true
	else
		return false
	end
end

function zapi.client.Client:getPing()
	return self:get("ps.ping")
end

function zapi.client.Client:setPing(ping)
	ping = zapi.misc.int(ping)
	if ping == nil then
		return
	elseif ping > 999 then
		ping = 999
	elseif ping < 0 then
		ping = 0
	end
	self:set("ps.ping", ping)
end

function zapi.client.Client:isConnected()
	if self:get("pers.connected") == 2 then
		return true
	else
		return false
	end
end

function zapi.client.Client:isActive(bot)
	if not bot and self:isBot() then return false end
	if not self:isConnected() then return false end
	local team = self:getTeam()
	if ( team == 1 or team == 2 ) then
		return true
	else
		return false
	end
end

function zapi.client.Client:getTeam()
	return self:get("sess.sessionteam")
end

function zapi.client.Client:setTeam()
	team = zapi.getTeamNum(team)
	if not team or self:getTeam() == team then return end

	local method = {
		"ref putaxis "   .. self.id .. "\n",
		"ref putallies " .. self.id .. "\n",
		"ref remove "    .. self.id .. "\n",
	}
	if zapi.modname == "silent" then
		method = {
			"!putteam " .. self.id .. " r\n",
			"!putteam " .. self.id .. " b\n",
			"!putteam " .. self.id .. " s\n",
		}
	end
	et.trap_SendConsoleCommand(et.EXEC_APPEND, method[team])
end

function zapi.client.Client:getTeamName()
	return et.TEAM[self:getTeam()]
end

function zapi.client.Client:getClass()
	return self:get("sess.playerType")
end

function zapi.client.Client:getClassName()
	return et.CLASS[self:get("sess.playerType")]
end

function zapi.client.Client:getAliveState()
	if not self:isActive(true) then return 0 end -- Not on team
	-- allows bots
	local gibHealth = 50
	local health = self:getHealth()
	if zapi.modname == "silent" and et.trap_Cvar_Get( "g_forceLimboHealth" ) ~= 0 then
		gibHealth = 100
	end
	if health > 0 then
		return 1 -- Alive
	elseif ( health <= 0 and health > gibHealth ) then
		return 2 -- In gib state
	elseif health <= gibHealth then
		return 3 -- Is dead and gibbed
	end
	return 0
end

function zapi.client.Client:isMuted()
	-- Not Muted:  Silent(0)
	-- PermaMuted: Silent(-1)
	-- Muted:      Silent(Above 0,seconds from year 2000 + time muted I think...)
	if et.ClientIsFlooding and et.ClientIsFlooding(self.id) == 1 then return true end
	if self:get("sess.muted") ~= 0 then return true end
	return false
end

function zapi.client.Client:setMaxHealth(maxHealth)
	maxHealth = zapi.misc.int(maxHealth)
	if not maxHealth or maxHealth <= 0 then return end
	self:set("ps.stats", 4, maxHealth)
end

function zapi.client.Client:getHealth()
	return self:get("health")
end

function zapi.client.Client:setHealth(health)
	health = zapi.misc.int(health)
	self:set("health", health)
end

function zapi.client.Client:getOrigin()
	return self:get("ps.origin")
end

function zapi.client.Client:setOrigin(origin)
	if not origin or type(origin) ~= "table" then return end
	self:set("ps.origin", origin)
end

function zapi.client.Client:getWeapon()
	return self:get("s.weapon")
end

function zapi.client.Client:getAmmo(weapon)
	if not weapon then weapon = self:getWeapon() end
	return self:get("ps.ammo", weapon)
end

function zapi.client.Client:setAmmo(weapon, ammo)
	if not weapon then weapon = self:getWeapon() end
	if not ammo then return end
	self:set("ps.ammo", weapon, ammo)
end

function zapi.client.Client:getAmmoClip(weapon)
	if not weapon then weapon = self:getWeapon() end
	return self:get("ps.ammoclip", weapon)
end

function zapi.client.Client:setAmmoClip(weapon, ammo)
	if not weapon then weapon = self:getWeapon() end
	if not ammo then return end
	self:set("ps.ammoclip", weapon, ammo)
end

function zapi.client.Client:getAdren()
	return self:get("ps.powerups", 12)
end

function zapi.client.Client:setAdren(adrenTime) -- time in ms
	self:set("ps.powerups", 12, zapi.levelTime + adrenTime)
end


function zapi.client.Client:getUserinfo()
	if self.id == nil then return "" end -- little extra error check
	return et.trap_GetUserinfo(self.id) or ""
end

function zapi.client.Client:getClientUserinfoTable() -- mostly for inner userinfo lua info
	local ui = et.trap_GetUserinfo(self.id) or ""
	local protocol = et.Info_ValueForKey(ui, "protocol")
	if protocol == nil then
		return "missing protocol"
	elseif protocol == "" then
		return "empty protocol"
	elseif protocol == "82" then
		return "2.55"
	elseif protocol == "83" then
		return "2.56"
	elseif protocol == "84" then
		return "2.60b"
	else
		return "unknown protocol ( "..protocol..")"
	end
    local version = et.Info_ValueForKey(ui, "cg_etVersion")
    if version == nil then
        return "missing version"
    elseif version == "" then
        return "empty version"
    else
        return version
    end
	
	
	self.userinfo = { }
	self.userinfo.ip = string.gsub(et.Info_ValueForKey( ui, "ip" ), ":%d*","")
	self.userinfo.password = et.Info_ValueForKey( ui, "password" )
	self.userinfo.name = et.Info_ValueForKey( ui, "name" )
	self.userinfo.guid = et.Info_ValueForKey( ui, "cl_guid" )
	self.userinfo.protocol = protocol
	self.userinfo.version = version
	if zapi.modname == "silent" then
		self.userinfo.silent_guid = string.gsub(et.Info_ValueForKey( ui, "sil_guid" ), ":%d*", "")
	end
end

function zapi.client.Client:getConfigString()
	if et.CS_PLAYERS ~= nil then
		return et.trap_GetConfigstring(et.CS_PLAYERS + self.id)
	else
		return et.trap_GetConfigstring(689 + self.id)
	end
end

function zapi.client.Client:setConfigString(configString)
	if configString == nil then return end
	if et.CS_PLAYERS ~= nil then
		et.trap_SetConfigstring(et.CS_PLAYERS + self.id, configString)
	else
		et.trap_SetConfigstring(689 + self.id, configString)
	end
end

function zapi.client.Client:getConfigStringKey(key)
	if key == nil then return end
	return et.Info_ValueForKey(self:getConfigString(), key)
end

function zapi.client.Client:setConfigStringKey(key, value)
	if not key or not value then return end
	self:setConfigString(et.Info_SetValueForKey(self:getConfigString(), key, value))
end

function zapi.client.Client:getName()
	return et.Info_ValueForKey( self:getUserInfo(), "name" )
end

function zapi.client.Client:getCleanName()
	return zapi.misc.trim(self:getName(), false, true)
end

function zapi.client.Client:setName(name)
	name = zapi.misc.trim(name)
	if string.len(et.Q_CleanStr(name)) <= 0 then return end
	local userinfo = self:getUserInfo()
	userinfo = et.Info_SetValueForKey(userinfo, "name", name)
	et.trap_SetUserinfo(self.id, userinfo)
	et.ClientUserinfoChanged(self.id)
end

function zapi.client.Client:isBot()
	if zapi.misc.trim(self:getIp(), true) == "localhost" then
		return true
	else
		return false
	end
end

function zapi.client.Client:getCountry()
	local uci = self:get("sess.uci")
	if uci ~= nil and zapi.COUNTRY[uci] ~= nil then
		return zapi.COUNTRY[uci]
	else
		return "Unknown"
	end
end

setmetatable(zapi.client.Client, { __call = function(_, ...) return zapi.client.Client.new(...) end })
