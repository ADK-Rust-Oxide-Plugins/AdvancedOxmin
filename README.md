Oxmin
==============


A flag-based admin tool for Oxide.

Commands
==
oxmin.giveflag "player name" "flag"

oxmin.takeflag "player name" "flag"

(Note: Player names with spaces MUST be enclosed in quotations.)

Flags
==
**all**
> Automatically grants all flags (apart from banned), but it counts as a single flag.

**banned**
> Prevents a player from joining the server, and is given to them when they are /ban'd.

**canban**
> Allows player to use the /ban command to ban players.

**cancallairdrop**
> Allows player to use the /airdrop command to call an airdrop.

**cangive**
> Allows player to use the /give command to give items to self.

**cangod**
> Allows player to use the /god command to enable/disable godmode on self.

**cankick**
> Allows player to use the /kick command to kick players from the server.

**canlua**
> Allows player to execute Lua directly from their console.

**canteleport**
> Allows player to use the /tp command to teleport to players or teleport them to their current location.

**godmode**
> Prevents a player from receiving any hurt/damage, and is given to them when they are in /godmode.

**reserved**
> Oxide reserves 5 player slots by default, this is editable in the config file - give players the "reserved" flag so they can use them.

CHAT COMMANDS
==
**/kick "player name"**
> Requires flag "cankick"

> Immediately kicks the target player

**/ban "player name"**
> Requires flag "canban"

> Immediately kicks and bans the target player permanently

**/unban "player name"**
> Requires flag "canban"

> Unbans the target player

**/lua "code"**
> Requires flag "canlua"

> Executes a line of Lua code

**/god**
> Requires flag "cangod"

> Gives the caller the "godmode" flag

**/airdrop**
> Requires flag "cancallairdrop"

> Calls an airdrop

**/give "item name" "quantity"**
> Requires flag "cangive"

> Gives the caller the specified item

**/help**
> Fills the caller's chat with help text (drawn from "SendHelpText" hook)

**/who**
> Displays the number of players currently online

**/tp "player name"**
> Requires flag "canteleport"

> Teleports the caller to the target player

Notes
==
Player names are case sensitive, but can be partial

Oxmin bans are different from standard Rust bans

CONFIG
==
The default configuration file generated upon server start is as follows.
Code (text):

```
{
  "showconnectedmessage":true,
  "chatname":"Oxmin",
  "helptext":["Welcome to the server!","This server is powered by the Oxide Modding API for Rust.","Use /who to see how many players are online."],  
  "reservedslots":5, 
  "showdisconnectedmessage":true,
  "showwelcomenotice":true, 
  "welcomenotice":"Welcome to the server %s! Type /help for a list of commands." 
}
```

**showconnectedmessage** - Determines whether the "Player has joined the game" message shows or not

**chatname** - Determines the name of the plugin in the chat box

**helptext** - Determines the text shown (in addition to the OnHelpText hook) when the /help command is executed

**reservedslots** - Determines the number of reserved slots to use

**showdisconnectedmessage** - Determines whether the "Player has left the game" message shows or not

**showwelcomenotice** - Determines whether the welcome notice is shown to new players or not

**welcomenotice** - The text to show new players in the welcome notice
