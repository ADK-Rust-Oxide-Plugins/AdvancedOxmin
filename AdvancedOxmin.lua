--[[ ******************************** ]]--
--[[  Advanced Oxmin - ADKGamers.com  ]]--
--[[ ******************************** ]]--


-- Define plugin variables
PLUGIN.Title = "Advanced Oxmin"
PLUGIN.Description = "Administration mod"
PLUGIN.Author = "raziel23x"
PLUGIN.Version = "0.0.1"

-- Load Advanced Oxmin module
if (not advancedoxmin) then
	advancedoxmin = {}
	advancedoxmin.flagtostr = {}
	advancedoxmin.strtoflag = {}
	advancedoxmin.nextflagid = 1
end
function advancedoxmin.AddFlag( name )
	if (advancedoxmin.strtoflag[ name ]) then return advancedoxmin.strtoflag[ name ] end
	local id = advancedoxmin.nextflagid
	advancedoxmin.flagtostr[ id ] = name
	advancedoxmin.strtoflag[ name ] = id
	advancedoxmin.nextflagid = advancedoxmin.nextflagid + 1
	return id
end

-- Add all default flags
local FLAG_ALL = advancedoxmin.AddFlag( "all" )
local FLAG_BANNED = advancedoxmin.AddFlag( "banned" )
local FLAG_CANKICK = advancedoxmin.AddFlag( "cankick" )
local FLAG_CANBAN = advancedoxmin.AddFlag( "canban" )
local FLAG_CANUNBAN = advancedoxmin.AddFlag( "canunban" )
local FLAG_CANNOTICE = advancedoxmin.AddFlag( "cannotice" )
local FLAG_CANTIME = advancedoxmin.AddFlag( "cantime" )
local FLAG_CANTELEPORT = advancedoxmin.AddFlag( "canteleport" )
local FLAG_CANGIVE = advancedoxmin.AddFlag( "cangive" )
local FLAG_CANGOD = advancedoxmin.AddFlag( "cangod" )
local FLAG_GODMODE = advancedoxmin.AddFlag( "godmode" )
local FLAG_CANLUA = advancedoxmin.AddFlag( "canlua" )
local FLAG_CANCALLAIRDROP = advancedoxmin.AddFlag( "cancallairdrop" )
local FLAG_RESERVED = advancedoxmin.AddFlag( "reserved" )
local FLAG_CANDESTROY = advancedoxmin.AddFlag( "candestroy" )

-- *******************************************
-- PLUGIN:Init()
-- Initialises the Advanced Oxmin plugin
-- *******************************************
function PLUGIN:Init()
	-- Notify console that Advanced Oxmin is loading
	print( "Loading Advanced Oxmin..." )
	
	-- Load the user datafile
	self.DataFile = util.GetDatafile( "AdvancedOxmin" )
	local txt = self.DataFile:GetText()
	if (txt ~= "") then
		self.Data = json.decode( txt )
	else
		self.Data = {}
		self.Data.Users = {}
	end
	
	-- Count and output the number of users
	local cnt = 0
	for _, _ in pairs( self.Data.Users ) do cnt = cnt + 1 end
	print( tostring( cnt ) .. " users are tracked by Advanced Oxmin!" )
	
	-- Load the config file
	local b, res = config.Read( "AdvancedOxmin" )
	self.Config = res or {}
	if (not b) then
		self:LoadDefaultConfig()
		if (res) then config.Save( "AdvancedOxmin" ) end
	end
	
	-- Add chat commands
	self:AddOxminChatCommand( "kick", { FLAG_CANKICK }, self.cmdKick )
	self:AddOxminChatCommand( "ban", { FLAG_CANBAN }, self.cmdBan )
	self:AddOxminChatCommand( "unban", { FLAG_CANBAN }, self.cmdUnban )
	self:AddOxminChatCommand( "lua", { FLAG_CANLUA }, self.cmdLua )
	self:AddOxminChatCommand( "god", { FLAG_CANGOD }, self.cmdGod )
	self:AddOxminChatCommand( "timeday", { FLAG_CANTIME }, self.cmdTimeday )
	self:AddOxminChatCommand( "timenight", { FLAG_CANTIME }, self.cmdTimenight )
	self:AddOxminChatCommand( "airdrop", { FLAG_CANCALLAIRDROP }, self.cmdAirdrop )
	self:AddOxminChatCommand( "notice", { FLAG_CANNOTICE }, self.cmdnotice )	
	self:AddOxminChatCommand( "give", { FLAG_CANGIVE }, self.cmdGive )
	self:AddOxminChatCommand( "help", { }, self.cmdHelp )
	self:AddOxminChatCommand( "who", { }, self.cmdWho )
	self:AddOxminChatCommand( "where", { }, self.cmdWhere )
	self:AddOxminChatCommand( "tp", { FLAG_CANTELEPORT }, self.cmdTeleport )
	self:AddOxminChatCommand( "bring", { FLAG_CANTELEPORT }, self.cmdBring )
	self:AddOxminChatCommand( "destroy", { FLAG_CANDESTROY }, self.cmdDestroy )
	
	-- Add console commands
	self:AddCommand( "advancedoxmin", "giveflag", self.ccmdGiveFlag )
	self:AddCommand( "advancedoxmin", "takeflag", self.ccmdTakeFlag )
end

-- *******************************************
-- PLUGIN:LoadDefaultConfig()
-- Loads the default configuration into the config table
-- *******************************************
function PLUGIN:LoadDefaultConfig()
	-- Set default configuration settings
	self.Config.chatname = "Advanced Oxmin"
	self.Config.reservedslots = 5
	self.Config.showwelcomenotice = true
	self.Config.welcomenotice = "Welcome to the server %s! Type /help for a list of commands."
	self.Config.showconnectedmessage = true
	self.Config.showdisconnectedmessage = true
	self.Config.helptext =
	{
		"Welcome to the server!",
		"This server is powered by the Oxide Modding API for Rust.",
		"Use /who to see how many players are online."
	}
end

-- *******************************************
-- PLUGIN:AddOxminChatCommand()
-- Adds an internal chat command with flag requirements
-- *******************************************
function PLUGIN:AddOxminChatCommand( name, flagsrequired, callback )
	-- Add external chat command to ourself
	self:AddExternalOxminChatCommand( self, name, flagsrequired, callback )
end

-- *******************************************
-- PLUGIN:AddExternalOxminChatCommand()
-- Adds an external chat command with flag requirements
-- *******************************************
function PLUGIN:AddExternalOxminChatCommand( plugin, name, flagsrequired, callback )
	-- Get a reference to the Advanced Oxmin plugin
	local oxminplugin = plugins.Find( "AdvancedOxmin" )
	if (not oxminplugin) then
		error( "Advanced Oxmin plugin file was renamed (don't do this)!" )
		return
	end
	
	-- Define a "proxy" callback that checks for flags
	local function FixedCallback( self, netuser, cmd, args )
		for i=1, #flagsrequired do
			if (not oxminplugin:HasFlag( netuser, flagsrequired[i] )) then
				rust.Notice( netuser, "You don't have permission to use this command!" )
				return true
			end
		end
		print( "'" .. netuser.displayName .. "' (" .. rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) ) .. ") ran command '/" .. cmd .. " " .. table.concat( args, " " ) .. "'" )
		callback( self, netuser, args )
	end
	
	-- Add the chat command
	plugin:AddChatCommand( name, FixedCallback )
end

-- *******************************************
-- PLUGIN:ccmdGiveFlag()
-- Console command callback (advancedoxmin.giveflag <user> <flag>)
-- *******************************************
function PLUGIN:ccmdGiveFlag( arg )
	-- Check the caller has admin or rcon
	local user = arg.argUser
	if (user and not user:CanAdmin()) then return end
	
	-- Locate the target user
	local b, targetuser = rust.FindNetUsersByName( arg:GetString( 0 ) )
	if (not b) then
		if (targetuser == 0) then
			arg:ReplyWith( "No players found with that name!" )
		else
			arg:ReplyWith( "Multiple players found with that name!" )
		end
		return
	end
	
	-- Locate the flag
	local flagid = advancedoxmin.strtoflag[ arg:GetString( 1 ) ]
	if (not flagid) then
		arg:ReplyWith( "Unknown flag!" )
		return
	end
	
	-- Give the flag
	local targetname = util.QuoteSafe( targetuser.displayName )
	self:GiveFlag( targetuser, flagid )
	arg:ReplyWith( "Flag given to " .. targetname .. "." )
	
	-- Handled
	return true
end

-- *******************************************
-- PLUGIN:ccmdTakeFlag()
-- Console command callback (advancedoxmin.takeflag <user> <flag>)
-- *******************************************
function PLUGIN:ccmdTakeFlag( arg )
	-- Check the caller has admin or rcon
	local user = arg.argUser
	if (user and not user:CanAdmin()) then return end
	
	-- Locate the target user
	local b, targetuser = rust.FindNetUsersByName( arg:GetString( 0 ) )
	if (not b) then
		if (targetuser == 0) then
			arg:ReplyWith( "No players found with that name!" )
		else
			arg:ReplyWith( "Multiple players found with that name!" )
		end
		return
	end
	
	-- Locate the flag
	local flagid = advancedoxmin.strtoflag[ arg:GetString( 1 ) ]
	if (not flagid) then
		arg:ReplyWith( "Unknown flag!" )
		return
	end
	
	-- Take the flag
	local targetname = util.QuoteSafe( targetuser.displayName )
	self:TakeFlag( targetuser, flagid )
	arg:ReplyWith( "Flag taken from " .. targetname .. "." )
	
	-- Handled
	return true
end

-- *******************************************
-- PLUGIN:Save()
-- Saves the player data to file
-- *******************************************
function PLUGIN:Save()
	self.DataFile:SetText( json.encode( self.Data ) )
	self.DataFile:Save()
end

-- *******************************************
-- Broadcasts a chat message
-- *******************************************
function PLUGIN:cmdNotice( netuser, cmd, args )
  local message = table.concat( args, " " )
  local netusers = rust.GetAllNetUsers()
  local rustnotice = notice.popupall
  rust.RunServerCommand( rustnotice, message )
 
end

-- *******************************************
-- PLUGIN:BroadcastChat()
-- Broadcasts a chat message
-- *******************************************
function PLUGIN:BroadcastChat( msg )
	rust.BroadcastChat( self.Config.chatname, msg )
end

-- *******************************************
-- PLUGIN:CanClientLogin()
-- Saves the player data to file
-- *******************************************
local SteamIDField = util.GetFieldGetter( Rust.ClientConnection, "UserID", true )
--local PlayerClientAll = util.GetStaticPropertyGetter( Rust.PlayerClient, "All" )
--local serverMaxPlayers = util.GetStaticFieldGetter( Rust.server, "maxplayers" )
function PLUGIN:CanClientLogin( approval, connection )
	-- Get the user ID and player data
	local userID = tostring( SteamIDField( connection ) )
	local data = self:GetUserDataFromID( userID, connection.UserName )
	
	-- Check if they have the banned flag
	for i=1, #data.Flags do
		local f = data.Flags[i]
		if (f == FLAG_BANNED) then
			return NetworkConnectionError.ConnectionBanned
		end
	end
	
	-- Get the maximum number of players
	local maxplayers = Rust.server.maxplayers
	local curplayers = self:GetUserCount()
	
	-- Are we biting into reserved slots?
	if (curplayers + self.Config.reservedslots >= maxplayers) then
		-- Check if they have reserved flag
		for i=1, #data.Flags do
			local f = data.Flags[i]
			if (f == FLAG_RESERVED or f == FLAG_ALL) then return end
		end
		return NetworkConnectionError.TooManyConnectedPlayers
	end
end

-- *******************************************
-- PLUGIN:GetUserCount()
-- Gets the number of connected users
-- *******************************************
function PLUGIN:GetUserCount()
	return Rust.PlayerClient.All.Count
end

-- *******************************************
-- PLUGIN:OnUserConnect()
-- Called when a user has connected
-- *******************************************
function PLUGIN:OnUserConnect( netuser )
	local sid = rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) )
	print( "User \"" .. util.QuoteSafe( netuser.displayName ) .. "\" connected with SteamID '" .. sid .. "'" )
	local data = self:GetUserData( netuser )
	data.Connects = data.Connects + 1
	self:Save()
	if (data.Connects == 1 and self.Config.showwelcomenotice) then
		rust.Notice( netuser, self.Config.welcomenotice:format( netuser.displayName ), 20.0 )
	end
	if (self.Config.showconnectedmessage) then self:BroadcastChat( netuser.displayName .. " has joined the game." ) end
end

-- *******************************************
-- PLUGIN:OnUserDisconnect()
-- Called when a user has disconnected
-- *******************************************
function PLUGIN:OnUserDisconnect( networkplayer )
	--print( "OnUserDisconnect " .. tostring( networkplayer ) )
	local netuser = networkplayer:GetLocalData()
	if (not netuser or netuser:GetType().Name ~= "NetUser") then return end
	local sid = rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) )
	print( "User \"" .. util.QuoteSafe( netuser.displayName ) .. "\" disconnected with SteamID '" .. sid .. "'" )
	if (self.Config.showdisconnectedmessage) then self:BroadcastChat( netuser.displayName .. " has left the game." ) end
end

-- *******************************************
-- PLUGIN:GetUserData()
-- Gets a persistent table associated with the given user
-- *******************************************
function PLUGIN:GetUserData( netuser )
	local userID = rust.GetUserID( netuser )
	return self:GetUserDataFromID( userID, netuser.displayName )
end

-- *******************************************
-- PLUGIN:GetUserDataFromID()
-- Gets a persistent table associated with the given user ID
-- *******************************************
function PLUGIN:GetUserDataFromID( userID, name )
	local userentry = self.Data.Users[ userID ]
	if (not userentry) then
		userentry = {}
		userentry.Flags = {}
		userentry.ID = userID
		userentry.Name = name
		userentry.Connects = 0
		self.Data.Users[ userID ] = userentry
		self:Save()
	end
	return userentry
end

-- *******************************************
-- PLUGIN:HasFlag()
-- Returns true if the specified user has the specified flag
-- *******************************************
function PLUGIN:HasFlag( netuser, flag, ignoreall )
	local userID = rust.GetUserID( netuser )
	local data = self:GetUserData( netuser )
	for i=1, #data.Flags do
		local f = data.Flags[i]
		if (f == FLAG_ALL and not ignoreall) then return true end
		if (f == flag) then return true end
	end
	return false
end

-- *******************************************
-- PLUGIN:GiveFlag()
-- Gives the specified flag to the specified user
-- *******************************************
function PLUGIN:GiveFlag( netuser, flag )
	local userID = rust.GetUserID( netuser )
	local data = self:GetUserData( netuser )
	for i=1, #data.Flags do
		if (data.Flags[i] == flag) then return false end
	end
	table.insert( data.Flags, flag )
	rust.Notice( netuser, "You now have the flag '" .. advancedoxmin.flagtostr[ flag ] .. "'!" )
	self:Save()
	return true
end

-- *******************************************
-- PLUGIN:TakeFlag()
-- Takes the specified flag from the specified user
-- *******************************************
function PLUGIN:TakeFlag( netuser, flag )
	local userID = rust.GetUserID( netuser )
	local data = self:GetUserData( netuser )
	for i=1, #data.Flags do
		if (data.Flags[i] == flag) then
			table.remove( data.Flags, i )
			rust.Notice( netuser, "You no longer have the flag '" .. advancedoxmin.flagtostr[ flag ] .. "'!" )
			self:Save()
			return true
		end
	end
	return false
end

-- *******************************************
-- PLUGIN:OnTakeDamage()
-- Called when an entity take damage
-- *******************************************
function PLUGIN:ModifyDamage( takedamage, damage )
	local typ = takedamage:GetType()
	local GetComponent = takedamage.GetComponent
	if (GetComponent == "GetComponent") then
		print( "(oxmin:ModifyDamage) GetComponent was a string! takedamage is a " .. typ.Name )
		return
	end
	local controllable = takedamage:GetComponent( "Controllable" )
	if (not controllable) then return end
	--print( controllable )
	local netuser = controllable.playerClient.netUser
	if (not netuser) then return error( "Failed to get net user (ModifyDamage)" ) end
	local char = rust.GetCharacter( netuser )
	if (not char) then return error( "Failed to get Character (ModifyDamage)" ) end
	--local char = obj:GetComponent( "Character" )
	if (char) then
		local ct = char:GetType()
		--[[if (ct.Name == "DamageBeing") then
			char = char.character
			print( "Hacky fix, " .. ct.Name .. " is now " .. char:GetType().Name )
			if (char:GetType().Name == "DamageBeing") then
				print( "The hacky fix didn't work, it's still a DamageBeing!" )
				return
			end
		end]]
		--print( ct )
		local netplayer = char.networkViewOwner
		if (netplayer) then
			local netuser = rust.NetUserFromNetPlayer( netplayer )
			if (netuser) then
				if (self:HasFlag( netuser, FLAG_GODMODE, true )) then
					--print( "Damage denied" )
					damage.amount = 0
					return damage
				end
			end
		end
	end
end

-- CHAT COMMANDS --
function PLUGIN:cmdHelp( netuser, args )
	for i=1, #self.Config.helptext do
		rust.SendChatToUser( netuser, self.Config.helptext[i] )
	end
	plugins.Call( "SendHelpText", netuser )
end
function PLUGIN:cmdWho( netuser, args )
	rust.SendChatToUser( netuser, "There are " .. tostring( #rust.GetAllNetUsers() ) .. " survivors online." )
end
function PLUGIN:cmdKick( netuser, args )
	if (not args[1]) then
		rust.Notice( netuser, "Syntax: /kick name" )
		return
	end
	local b, targetuser = rust.FindNetUsersByName( args[1] )
	if (not b) then
		if (targetuser == 0) then
			rust.Notice( netuser, "No players found with that name!" )
		else
			rust.Notice( netuser, "Multiple players found with that name!" )
		end
		return
	end
	local targetname = util.QuoteSafe( targetuser.displayName )
	self:BroadcastChat( "'" .. targetname .. "' was kicked by '" .. util.QuoteSafe( netuser.displayName ) .. "'!" )
	rust.Notice( netuser, "\"" .. targetname .. "\" kicked." )
	targetuser:Kick( NetError.Facepunch_Kick_RCON, true )
end
function PLUGIN:cmdBan( netuser, args )
	if (not args[1]) then
		rust.Notice( netuser, "Syntax: /ban name" )
		return
	end
	local b, targetuser = rust.FindNetUsersByName( args[1] )
	if (not b) then
		if (targetuser == 0) then
			rust.Notice( netuser, "No players found with that name!" )
		else
			rust.Notice( netuser, "Multiple players found with that name!" )
		end
		return
	end
	local targetname = util.QuoteSafe( targetuser.displayName )
	self:BroadcastChat( "'" .. targetname .. "' was banned by '" .. util.QuoteSafe( netuser.displayName ) .. "'!" )
	rust.Notice( netuser, "\"" .. targetname .. "\" banned." )
	self:GiveFlag( targetuser, FLAG_BANNED )
	targetuser:Kick( NetError.Facepunch_Kick_Ban, true )
end
function PLUGIN:cmdUnban( netuser, args )
	if (not args[1]) then
		rust.Notice( netuser, "Syntax: /unban name" )
		return
	end
	local candidates = {}
	for id, data in pairs( self.Data.Users ) do
		if (data.Name:match( args[1] )) then
			candidates[ #candidates + 1 ] = data
		end
	end
	if (#candidates == 0) then
		rust.Notice( netuser, "No banned users found with that name!" )
		return
	elseif (#candidates > 1) then
		rust.Notice( netuser, "Multiple banned users found with that name!" )
		return
	end
	candidates[1].Flags = {}
	self:Save()
	rust.Notice( netuser, util.QuoteSafe( candidates[1].Name ) .. " unbanned." )
end
function PLUGIN:cmdTeleport( netuser, args )
	if (not args[1]) then
		rust.Notice( netuser, "Syntax: /tp target OR /tp player target" )
		return
	end
	local b, targetuser = rust.FindNetUsersByName( args[1] )
	if (not b) then
		if (targetuser == 0) then
			rust.Notice( netuser, "No players found with that name!" )
		else
			rust.Notice( netuser, "Multiple players found with that name!" )
		end
		return
	end
	if (not args[2]) then
		-- Teleport netuser to targetuser
		rust.ServerManagement():TeleportPlayerToPlayer( netuser.networkPlayer, targetuser.networkPlayer )
		rust.Notice( netuser, "You teleported to '" .. util.QuoteSafe( targetuser.displayName ) .. "'!" )
		rust.Notice( targetuser, "'" .. util.QuoteSafe( netuser.displayName ) .. "' teleported to you!" )
	else
		local b, targetuser2 = rust.FindNetUsersByName( args[2] )
		if (not b) then
			if (targetuser2 == 0) then
				rust.Notice( netuser, "No players found with that name!" )
			else
				rust.Notice( netuser, "Multiple players found with that name!" )
			end
			return
		end
		
		-- Teleport targetuser to targetuser2
		rust.ServerManagement():TeleportPlayerToPlayer( targetuser.networkPlayer, targetuser2.networkPlayer )
		rust.Notice( targetuser, "You were teleported to '" .. util.QuoteSafe( targetuser2.displayName ) .. "'!" )
		rust.Notice( targetuser2, "'" .. util.QuoteSafe( targetuser.displayName ) .. "' teleported to you!" )
	end
end
function PLUGIN:cmdGod( netuser, args )
	if (not args[1]) then
		if (not self:GiveFlag( netuser, FLAG_GODMODE )) then
			self:TakeFlag( netuser, FLAG_GODMODE )
		end
		return
	end
	local b, targetuser = rust.FindNetUsersByName( args[1] )
	if (not b) then
		if (targetuser == 0) then
			rust.Notice( netuser, "No players found with that name!" )
		else
			rust.Notice( netuser, "Multiple players found with that name!" )
		end
		return
	end
	local targetname = util.QuoteSafe( targetuser.displayName )
	if (self:GiveFlag( targetuser, FLAG_GODMODE )) then
		rust.Notice( netuser, "\"" .. targetname .. "\" now has godmode." )
	elseif (self:TakeFlag( targetuser, FLAG_GODMODE )) then
		rust.Notice( netuser, "\"" .. targetname .. "\" no longer has godmode." )
	end
end
function PLUGIN:cmdLua( netuser, args )
	local code = table.concat( args, " " )
	local b, res = util.LoadString( code, "Oxmin /lua" )
	if (not b) then
		rust.Notice( netuser, res )
		return
	end
	util.BeginCapture()
	b, res = pcall( res )
	local log_print, log_err = util.EndCapture()
	if (not b) then
		rust.Notice( netuser, res )
		return
	end
	if (#log_err > 0) then
		rust.Notice( netuser, tostring( #log_err ) .. " error(s) when executing Lua code!", 2.5 )
		for i=1, #log_err do
			timer.Once( i * 2.5, function() rust.Notice( netuser, log_err[i], 2.5 ) end )
		end
	elseif (#log_print > 0) then
		for i=1, #log_print do
			timer.Once( (i - 1) * 2.5, function() rust.Notice( netuser, log_print[i], 2.5 ) end )
		end
	else
		rust.Notice( netuser, "No output from Lua call." )
	end
end

function PLUGIN:cmdAirdrop( netuser, args )
	rust.Notice( netuser, "Airdrop called!" )
	rust.CallAirdrop()
end

-- *******************************************
-- Time functions day and night commands
-- *******************************************
function PLUGIN:cmdTimeday( netuser, cmd, args )

    local dayva = "env.time 10"
    local daytext = "Time set to day "
    rust.RunServerCommand (dayva)
    rust.BroadcastChat (daytext)
end
function PLUGIN:cmdTimenight( netuser, cmd, args )

    local nightva = "env.time 23"
    local nighttext = "Time set to night "
    rust.RunServerCommand (nightva)
    rust.BroadcastChat (nighttext)
end

-- ******************************************* 
-- Shows user location and direction
-- *******************************************
function PLUGIN:cmdWhere(netuser, cmd, args)
    if (not args[1]) then
        rust.SendChatToUser( netuser, "Current location: " .. self:findNearestPoint(netuser) .. " " .. self:getUserLocation(netuser) );
        rust.SendChatToUser( netuser, "You are currently facing " .. self:getUserDirection(netuser) );
        rust.SendChatToUser( netuser, "You can see yourself on the map at http://rustmap.net/" );
        return
    end

    if (not netuser:CanAdmin()) then
        return
    end

    -- Get the target user
    local b, targetuser = rust.FindNetUsersByName( args[1] )
    if (not b) then
        if (targetuser == 0) then
            rust.Notice( netuser, "No players found with that name!" )
        else
            rust.Notice( netuser, "Multiple players found with that name!" )
        end
        return
    end

    rust.SendChatToUser( netuser, targetuser.displayName .. "'s current location: " .. self:findNearestPoint(targetuser) .. " " .. self:getUserLocation(targetuser) );
    rust.SendChatToUser( netuser, "They are currently facing " .. self:getUserDirection(targetuser) );
end

function PLUGIN:compassLetter(dir)
        if (dir > 337.5) or (dir < 22.5) then
                return "North"
        elseif (dir >= 22.5) and (dir <= 67.5) then
                return "Northeast"
        elseif (dir > 67.5) and (dir < 112.5) then
                return "East"
        elseif (dir >= 112.5) and (dir <= 157.5) then
                return "Southeast"
        elseif (dir > 157.5) and (dir < 202.5) then
                return "South"
        elseif (dir >= 202.5) and (dir <= 247.5) then
                return "Southwest"
        elseif (dir > 247.5) and (dir < 292.5) then
                return "West"
        elseif (dir >= 292.5) and (dir <= 337.5) then
                return "Northwest"
        end
end
 
function PLUGIN:getUserDirection(netuser)
        local controllable = netuser.playerClient.controllable
        local char = controllable:GetComponent( "Character" )
 
        -- Convert unit circle angle to compass angle. 
        -- Known error: char.eyesYaw randomly returns a String value and breaks output
        local direction = (char.eyesYaw+90)%360
 
        return self:compassLetter(direction)
end

function PLUGIN:getUserLocation(netuser)
        local coords = netuser.playerClient.lastKnownPosition

        return "(x : " .. math.floor(coords.x) .. ", y : " .. math.floor(coords.y) .. ", z : " .. math.floor(coords.z) .. ")"
end

function PLUGIN:findNearestPoint(netuser)
        local coords = netuser.playerClient.lastKnownPosition
        local points = {
            { name = "Hacker Valley South", x = 5907, z = -1848 },
            { name = "Hacker Mountain South", x = 5268, z = -1961 },
            { name = "Hacker Valley Middle", x = 5268, z = -2700 },
            { name = "Hacker Mountain North", x = 4529, z = -2274 },
            { name = "Hacker Valley North", x = 4416, z = -2813 },
            { name = "Wasteland North", x = 3208, z = -4191 },
            { name = "Wasteland South", x = 6433, z = -2374 },
            { name = "Wasteland East", x = 4942, z = -2061 },
            { name = "Wasteland West", x = 3827, z = -5682 },
            { name = "Sweden", x = 3677, z = -4617 },
            { name = "Everust Mountain", x = 5005, z = -3226 },
            { name = "North Everust Mountain", x = 4316, z = -3439 },
            { name = "South Everust Mountain", x = 5907, z = -2700 },
            { name = "Metal Valley", x = 6825, z = -3038 },
            { name = "Metal Mountain", x = 7185, z = -3339 },
            { name = "Metal Hill", x = 5055, z = -5256 },
            { name = "Resource Mountain", x = 5268, z = -3665 },
            { name = "Resource Valley", x = 5531, z = -3552 },
            { name = "Resource Hole", x = 6942, z = -3502 },
            { name = "Resource Road", x = 6659, z = -3527 },
            { name = "Beach", x = 5494, z = -5770 },
            { name = "Beach Mountain", x = 5108, z = -5875 },
            { name = "Coast Valley", x = 5501, z = -5286 },
            { name = "Coast Mountain", x = 5750, z = -4677 },
            { name = "Coast Resource", x = 6120, z = -4930 },
            { name = "Secret Mountain", x = 6709, z = -4730 },
            { name = "Secret Valley", x = 7085, z = -4617 },
            { name = "Factory Radtown", x = 6446, z = -4667 },
            { name = "Small Radtown", x = 6120, z = -3452 },
            { name = "Big Radtown", x = 5218, z = -4800 },
            { name = "Hangar", x = 6809, z = -4304 },
            { name = "Tanks", x = 6859, z = -3865 },
            { name = "Civilian Forest", x = 6659, z = -4028 },
            { name = "Civilian Mountain", x = 6346, z = -4028 },
            { name = "Civilian Road", x = 6120, z = -4404 },
            { name = "Ballzack Mountain", x =4316, z = -5682 },
            { name = "Ballzack Valley", x = 4720, z = -5660 },
            { name = "Spain Valley", x = 4742, z = -5143 },
            { name = "Portugal Mountain", x = 4203, z = -4570 },
            { name = "Portugal", x = 4579, z = -4637 },
            { name = "Lone Tree Mountain", x = 4842, z = -4354 },
            { name = "Forest", x = 5368, z = -4434 },
            { name = "Rad-Town Valley", x = 5907, z = -3400 },
            { name = "Next Valley", x = 4955, z = -3900 },
            { name = "Silk Valley", x = 5674, z = -4048 },
            { name = "French Valley", x = 5995, z = -3978 },
            { name = "Ecko Valley", x = 7085, z = -3815 },
            { name = "Ecko Mountain", x = 7348, z = -4100 },
            { name = "Middle Mountain", x = 6346, z = -4028 },
            { name = "Zombie Hill", x = 6396, z = -3428 }
        }

        local min = -1
        local minIndex = -1
        for i = 1, #points do
           if (minIndex==-1) then
                min = (points[i].x-coords.x)^2+(points[i].z-coords.z)^2
                minIndex = i
           else
                local dist = (points[i].x-coords.x)^2+(points[i].z-coords.z)^2
                if (dist<min) then
                    min = dist
                    minIndex = i
                end
           end
        end

        return points[minIndex].name
end
 
function PLUGIN:SendHelpText(netuser)
                rust.SendChatToUser( netuser, "Use /where to find your location and direction");
end

local preftype = cs.gettype( "Inventory+Slot+Preference, Assembly-CSharp" )
--local AddItemAmount = util.FindOverloadedMethod( Rust.PlayerInventory, "AddItemAmount", bf.public_instance, { Rust.ItemDataBlock, System.Int32, preftype } )
function PLUGIN:cmdGive( netuser, args )
	if (not args[1]) then
		rust.Notice( netuser, "Syntax: /give itemname {quantity}" )
		return
	end
	local datablock = rust.GetDatablockByName( args[1] )
	if (not datablock) then
		rust.Notice( netuser, "No such item!" )
		return
	end
	local amount = tonumber( args[2] ) or 1
	-- IInventoryItem objA = current.AddItem(byName, Inventory.Slot.Preference.Define(Inventory.Slot.Kind.Default, false, Inventory.Slot.KindFlags.Belt), quantity);
	local pref = rust.InventorySlotPreference( InventorySlotKind.Default, false, InventorySlotKindFlags.Belt )
	--local controllable = netuser.playerClient.controllable
	--local inv = controllable:GetComponent( "PlayerInventory" )
	local inv = rust.GetInventory( netuser )
	local arr = util.ArrayFromTable( System.Object, { datablock, amount, pref } )
	--cs.convertandsetonarray( arr, 1, amount, System.Int32._type )
	util.ArraySet( arr, 1, System.Int32, amount )
	--util.PrintArray( arr )
	--print( datablock )
	--print( pref )
	--print( amount )
	--local invitem = inv:AddItem( datablock, pref, amount )
	if (type( inv.AddItemAmount ) == "string") then
		print( "AddItemAmount was a string! (inv = " .. tostring( inv ) .. " - " .. (inv and inv:GetType().Name or "") .. ")" )
		--AddItemAmount:Invoke( inv, arr )
	else
		inv:AddItemAmount( datablock, amount, pref )
	end
	rust.InventoryNotice( netuser, tostring( amount ) .. " x " .. datablock.name )
end

local RaycastHitDistance = util.GetPropertyGetter( UnityEngine.RaycastHit, "distance" )
local function TraceEyes( netuser )
	local controllable = netuser.playerClient.controllable
	local char = controllable:GetComponent( "Character" )
	local ray = char.eyesRay
	local hits = RaycastAll( ray )
	local tbl = cs.createtablefromarray( hits )
	if (#tbl == 0) then return end
	local closest = tbl[1]
	local closestdist = closest.distance
	for i=2, #tbl do
		if (tbl[i].distance < closestdist) then
			closest = tbl[i]
			closestdist = closest.distance
		end
	end
	return closest
end
function PLUGIN:cmdDestroy( netuser, args )
	
end