/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <sourcemod>
#include <mapchooser>
#include <nd_stocks>
#include <nd_rounds>

enum Bools
{
	enableRTV,
	hasPassedRTV
};

#define TEAM_SPEC		1
#define TEAM_CONSORT		2
#define TEAM_EMPIRE		3

#define RTV_MAX_PLAYERS 	8
#define RTV_COMMANDS_SIZE 	3

new const String:nd_rtv_commands[RTV_COMMANDS_SIZE][] = 
{
	"rtv",
	"change map",
	"changemap"
};

new 	voteCount,	
	bool:g_Bool[Bools],
	bool:g_hasVoted[MAXPLAYERS+1] = {false, ... },
	Handle:RtvDisableTimer = INVALID_HANDLE;

public Plugin:myinfo =
{
	name 		= "[ND] Rock the Vote",
	author 		= "Stickz",
	description 	= "Vote to change map on ND",
	version 	= "dummy",
	url 		= "https://github.com/stickz/Redstone/"
};

/* Auto Updater */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_rockthevote/nd_rockthevote.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	RegConsoleCmd("sm_rtv", CMD_RockTheVote);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	LoadTranslations("nd_rockthevote.phrases");
	LoadTranslations("numbers.phrases");
	
	AddUpdaterLibrary(); //auto-updater
	
	if (ND_RoundStarted()) 
	{
		StartRTVDisableTimer();
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	StartRTVDisableTimer();
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if (client)
	{
		for (new idx = 0; idx < RTV_COMMANDS_SIZE; idx++)
		{
			if (strcmp(sArgs, nd_rtv_commands[idx], false) == 0) 
			{
				new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
				callRockTheVote(client);
					
				SetCmdReplySource(old);
				return Plugin_Stop;				
			}
		}
	}	
	return Plugin_Continue;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Bool[enableRTV] && RtvDisableTimer != INVALID_HANDLE)
		CloseHandle(RtvDisableTimer);
}

public OnMapStart()
{
	voteCount 		= 0;
	g_Bool[enableRTV] 	= true;
	g_Bool[hasPassedRTV] 	= false;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		g_hasVoted[client] = false;	
	}
}

public Action:CMD_RockTheVote(client, args)
{
	callRockTheVote(client);
	return Plugin_Handled;
}

public OnClientDisconnected(client)
{
	resetValues(client);
}

public Action:TIMER_DisableRTV(Handle:timer)
{
	g_Bool[enableRTV] = false;
}

callRockTheVote(client)
{
	new clientCount = ValidClientCount(true); 
	
	if (!g_Bool[enableRTV])
	{
		if (clientCount > RTV_MAX_PLAYERS)
			PrintToChat(client, "\x05[xG] %t", "Too Late");
	}
	
	else if (g_Bool[hasPassedRTV])
		PrintToChat(client, "\x05[xG] %t!", "Already Passed");	

	else if (g_hasVoted[client])
		PrintToChat(client, "\x05[xG] %t!", "Already RTVed");
	
	else if (ND_RoundEnded())
		PrintToChat(client, "\x05[xG] %t!", "Round Ended");
		
	else if (!ND_RoundStarted())
		PrintToChat(client, "\x05[xG] %t!", "Round Start");

	else
	{
		voteCount++;		
		g_hasVoted[client] = true;
		
		checkForPass(clientCount, true, client);
	}
}

checkForPass(clientCount, bool:display = false, client = -1)
{
	new Float:countFloat = clientCount * 0.51,
		Remainder = RoundToNearest(countFloat) - voteCount;
		
	if (Remainder <= 0)
		prepMapChange();
		
	else if (display)
		displayVotes(Remainder, client);
}

resetValues(client)
{
	if (g_hasVoted[client])
	{
		g_hasVoted[client] = false;
		checkForPass(ValidClientCount(true));
	}
}

prepMapChange()
{
	g_Bool[hasPassedRTV] = true;
	
	if (!CanMapChooserStartVote())
	{
		PrintToChatAll("\x05[xG] %t", "RTV Wait"); //Pending map change due to successful rtv vote.		
		CreateTimer(1.0, Timer_DelayMapChange, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
		FiveSecondChange();
}

public Action:Timer_DelayMapChange(Handle:timer)
{
	if (!CanMapChooserStartVote())
		return Plugin_Continue;
			
	else
	{
		FiveSecondChange();
		return Plugin_Stop;
	}
}

FiveSecondChange()
{
	ServerCommand("mp_roundtime 1");
	PrintToChatAll("\x05[xG] %t", "RTV Changing"); //RTV Successful: Map will change in five seconds.
}

displayVotes(Remainder, client)
{	
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
	
	PrintToChatAll("\x05%t", "Typed Change Map", name, NumberInEnglish(Remainder));
}

StartRTVDisableTimer()
{
	RtvDisableTimer = CreateTimer(480.0, TIMER_DisableRTV, _, TIMER_FLAG_NO_MAPCHANGE);
}