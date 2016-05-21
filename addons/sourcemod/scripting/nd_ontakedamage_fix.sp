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
#include <sdktools>
#include <nd_commander>

//Version is auto-filled by the travis builder
public Plugin:myinfo =
{
	name 		= "[ND] Damage Fixes",
	author 		= "stickz",
	description 	= "Fixes critical issues with ND damage calculations",
    	version 	= "dummy",
    	url     	= "https://github.com/stickz/Redstone/"
}

#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_ontakedamage_fix/nd_ontakedamage_fix.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_BlockGizmo, EventHookMode_Pre);
	HookEvent("player_spawn", Event_BlockGizmo, EventHookMode_Pre);
	HookEvent("structure_damage_sparse", Event_StructDamageSparse, EventHookMode_Pre);
	
	AddCommandListener(CommandListener:CMD_JoinClass, "joinclass");	
	AddCommandListener(CommandListener:CMD_JoinSquad, "joinsquad");
	
	AddUpdaterLibrary(); //for updater support
}

public Action:Event_BlockGizmo(Handle:event, const String:name[], bool:dontBroadcast) 
{
	CheckGizmoReset(GetClientOfUserId(GetEventInt(event, "userid")));	
	return Plugin_Continue;
}

/* Note: This hook will be removed soon if deemed redundant by further testing */
public Action:Event_StructDamageSparse(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	if (NDC_IsCommander(client) && HasGizmo(client))
		CheckGizmoReset(client);
		
	return Plugin_Continue;
}

public Action:CMD_JoinClass(client, args)
{
	CheckGizmoReset(client);	
	return Plugin_Continue;
}

public Action:CMD_JoinSquad(client, args)
{
	if (NDC_IsCommander(client))
		return Plugin_Handled;
		
	return Plugin_Continue; 
}

CheckGizmoReset(client)
{
	if (NDC_IsCommander(client))
	{
		SetEntProp(client, Prop_Send, "m_iActiveGizmo", 0);
		SetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0);
		
		/*new propValues[2];		
		propValues[0] = GetEntProp(client, Prop_Send, "m_iActiveGizmo", 0);
		propValues[1] =	GetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0);			
		PrintToChatAll("debug: prop values 1: %d , 2: %d", propValues[0], propValues[1]);*/
	}
}

bool:HasGizmo(client)
{
	return 	GetEntProp(client, Prop_Send, "m_iActiveGizmo", 0) != 0 || 
			GetEntProp(client, Prop_Send, "m_iDesiredGizmo", 0) != 0;
}