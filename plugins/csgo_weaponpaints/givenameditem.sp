#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#define _givenameditem_server
#include <givenameditem>
#include "givenameditem/convars.inc"
#include "givenameditem/hook.inc"
#include "givenameditem/items.inc"
#include "givenameditem/mm_server.inc"
#include "givenameditem/natives.inc"
#include "givenameditem/commands.inc"
#pragma semicolon 1
#pragma newdecls required

Handle g_hOnGiveNamedItemFoward = null;

public Plugin myinfo =
{
    name = "CS:GO GiveNamedItem Hook",
    author = "Neuro Toxin",
    description = "Hook for GiveNamedItem to allow other plugins to force classnames and paintkits",
    version = "1.0.8"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("givenameditem");
	CreateNatives();
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (!HookOnGiveNamedItem())
	{
		SetFailState("Unable to hook GiveNamedItem using DHooks");
		return;
	}
	
	RegisterCommands();
	BuildItems();
	RegisterConvars();
	g_hOnGiveNamedItemFoward = CreateGlobalForward("OnGiveNamedItemEx", ET_Ignore, Param_Cell, Param_String);
}

public void OnConfigsExecuted()
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		OnClientPutInServer(client);
	}
}

public void OnClientPutInServer(int client)
{	
	HookPlayer(client);
}

public MRESReturn OnGiveNamedItemPre(int client, Handle hReturn, Handle hParams)
{
	// We dont need to do much if the server hook is in use
	// -> This means GivePlayerItem is being called by the hook
	if (g_hServerHook.InUse)
	{
		// Switch the players team back if it has been switched
		if (g_hServerHook.TeamSwitch)
			SwitchPlayerTeam(client);
		
		return MRES_Ignored;
	}
	
	// Get the classname parameter
	char classname[64];
	DHookGetParamString(hParams, 1, classname, sizeof(classname));
	
	// Prepare the hooks data
	g_hServerHook.Client = client;
	g_hServerHook.InUse = true;
	
	if (cvar_print_debugmsgs)
	{
		int itemdefinition = g_hServerHook.GetItemDefinitionByClassname(classname);
		PrintToConsole(client, "-=> HOOK CREATED for %s (itemdefinition=%d)", classname, itemdefinition);
	}
	
	// Call GiveNamedItemEx forward
	Call_StartForward(g_hOnGiveNamedItemFoward);
	Call_PushCell(client);
	Call_PushString(classname);
	
	// Do nothing if the forward fails
	if (Call_Finish() != SP_ERROR_NONE)
	{
		g_hServerHook.Reset(client);
		return MRES_Ignored;
	}
	
	// Vanilla paintkits need some special attention to ensure they spawn without any glitchs
	if (g_hServerHook.Paintkit == PAINTKIT_VANILLA)
	{
		int itemdefinition = g_hServerHook.GetItemDefinitionByClassname(classname);
		int weaponteam = g_hServerHook.GetWeaponTeamByItemDefinition(itemdefinition);
		int playerteam = GetClientTeam(client);
		
		// Switch the players team to force the named item to spawn for the wrong team
		if (weaponteam != CS_TEAM_NONE && !g_hServerHook.IsItemDefinitionKnife(itemdefinition))
		{
			if (weaponteam == CS_TEAM_CT && playerteam == CS_TEAM_CT
			 || weaponteam == CS_TEAM_T && playerteam == CS_TEAM_T)
			{
				g_hServerHook.TeamSwitch = true;
				
				// Ensure the classname has been reset
				if (!g_hServerHook.ClassnameReset)
					g_hServerHook.SetClassname(classname);
			}
		}
	}
	
	// Some special treatment for TeamSwitch
	if (g_hServerHook.TeamSwitch && !g_hServerHook.ClassnameReset)
		g_hServerHook.SetClassname(classname);
	
	// Override give named item if a classname has been specified
	if (g_hServerHook.ClassnameReset)
	{
		// Override with new parameter and get the created entity index
		int entity = GivePlayerItemEx(client, g_sNewClassname);
		
		// Ok, something went wrong. Better log it...
		if (entity == -1)
		{
			LogError("Unable to create named item '%s'.", g_sNewClassname);
			g_hServerHook.Reset(client);
			return MRES_Ignored;
		}
		
		// Force knives to equip
		if (g_hServerHook.IsItemDefinitionKnife(g_hServerHook.ItemDefinition) && !g_hServerHook.HasEquiped)
		{
			g_hServerHook.Entity = entity;
			g_hServerHook.InUse = false;
			EquipPlayerWeapon(client, entity);
		}
		
		// Reset the hook and parse the newly created named item
		g_hServerHook.Reset(client);
		DHookSetReturn(hReturn, entity);
		return MRES_Supercede;
	}
	
	// If the paintkit or accountid isnt being set, lets not do anything
	if (g_hServerHook.Paintkit == INVALID_PAINTKIT && g_hServerHook.AccountID == 0)
		g_hServerHook.Reset(client);
		
	return MRES_Ignored;
}

public MRESReturn OnGiveNamedItemPost(int client, Handle hReturn, Handle hParams)
{
	// If the hook isn't in use, dont do anything
	if (!g_hServerHook.InUse)
		return MRES_Ignored;
	
	// Get thew newly created named item index
	int entity = DHookGetReturn(hReturn);
	
	// If no entity was spawned, cleanup and run for the hills
	if (entity == -1)
	{
		if (g_hServerHook.TeamSwitch)
			SwitchPlayerTeam(client);
			
		g_hServerHook.Reset(client);
		return MRES_Ignored;
	}
	
	// Force the item definition if required
	if (g_hServerHook.ItemDefinition > 0)
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", g_hServerHook.ItemDefinition);
	
	if (cvar_print_debugmsgs)
	{
		char classname[64];
		DHookGetParamString(hParams, 1, classname, sizeof(classname));
		PrintToConsole(client, "----====> OnGiveNamedItemPost(entity=%d, classname=%s)", entity, classname);
	}
	
	// Switch the players team back if required
	if (g_hServerHook.TeamSwitch)
	{
		SwitchPlayerTeam(client);
		SetEntProp(entity, Prop_Send, "m_iOriginalTeamNumber", GetClientTeam(client));
	}
	
	// Allow the accountid here so AWS can detected it's processed weapons
	if (g_hServerHook.AccountID > 0)
	{
		SetEntProp(entity, Prop_Send, "m_iAccountID", g_hServerHook.AccountID);
		
		// Detect if we need to reset the hook here
		if (g_hServerHook.Paintkit == INVALID_PAINTKIT && !g_hServerHook.ClassnameReset)
		{
			g_hServerHook.Reset(client);
			return MRES_Ignored;
		}
	}
	
	// If a paintkit isnt being set do nothing
	if (g_hServerHook.Paintkit == INVALID_PAINTKIT)
	{
		// This can happen for TeamSwitch
		//g_hServerHook.Reset(client);
		return MRES_Ignored;
	}
	
	// This is the magic peice
	SetEntProp(entity, Prop_Send, "m_iItemIDLow", -1);
	
	// Some more special attention around vanilla paintkits
	if (g_hServerHook.Paintkit == PAINTKIT_VANILLA)
	{
		if (!g_hServerHook.TeamSwitch)
			SetEntProp(entity, Prop_Send, "m_nFallbackPaintKit", g_hServerHook.Paintkit);
	}
	
	// Set fallback paintkit if the paintkit isnt vanilla
	else SetEntProp(entity, Prop_Send, "m_nFallbackPaintKit", g_hServerHook.Paintkit);
	
	// Set wear and seed if required
	if (g_hServerHook.Paintkit != PAINTKIT_PLAYERS)
	{
		SetEntProp(entity, Prop_Send, "m_nFallbackSeed", g_hServerHook.Seed);
		SetEntPropFloat(entity, Prop_Send, "m_flFallbackWear", g_hServerHook.Wear);
	}
	
	// Special treatment for stattrak items
	if (g_hServerHook.Kills > -1)
	{
		SetEntProp(entity, Prop_Send, "m_nFallbackStatTrak", g_hServerHook.Kills);
		
		if (g_hServerHook.EntityQuality == -1)
			g_hServerHook.EntityQuality = 1;
			
		if (g_hServerHook.AccountID == 0)
			g_hServerHook.AccountID = GetSteamAccountID(g_hServerHook.Client);
	}
	
	// The last few things
	if (g_hServerHook.EntityQuality > -1)
		SetEntProp(entity, Prop_Send, "m_iEntityQuality", g_hServerHook.EntityQuality);
	
	if (cvar_print_debugmsgs)
	{
		PrintToConsole(client, "-----=====> SETPAINTKIT(Paintkit=%d, Seed=%d, Wear=%f, Kills=%d, EntityQuality=%d)",
								g_hServerHook.Paintkit, g_hServerHook.Seed, g_hServerHook.Wear, g_hServerHook.Kills, g_hServerHook.EntityQuality);
	}
	
	// Dont forget to reset the hook
	if (!g_hServerHook.ClassnameReset)
		g_hServerHook.Reset(client);
	return MRES_Ignored;
}

public Action OnWeaponEquip(int client, int weapon)
{
	// Skip if a knife isnt being equipped
	int itemdefinition = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (!g_hServerHook.IsItemDefinitionKnife(itemdefinition))
		return Plugin_Continue;
		
	// Block weapon equip if a knife is being equipped (this stops animation glitches)
	if (g_hServerHook.InUse)
	{
		if (g_hServerHook.ClassnameReset)
		{
			if (cvar_print_debugmsgs)
			{
				PrintToConsole(client, "----====> OnWeaponEquip(weapon=%d)", weapon);
				PrintToConsole(client, "-----=====> BLOCKED");
			}
			return Plugin_Stop;
		}
	}
	else if (g_hServerHook.Entity == weapon)
	{
		if (cvar_print_debugmsgs)
		{
			PrintToConsole(client, "----====> OnWeaponEquip(weapon=%d)", weapon);
			PrintToConsole(client, "-----=====> NOT BLOCKED");
		}
		
		g_hServerHook.HasEquiped = true;
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

stock int GivePlayerItemEx(int client, const char[] classname)
{
	if (cvar_print_debugmsgs)
	{
		PrintToConsole(client, "---===> Forcing classname '%s'", classname);
		int entity = SDKCall(g_hGiveNamedItemCall, client, classname, 0);
		PrintToConsole(client, "---===> Forced classname '%s' (Entity=%d)", classname, entity);
		return entity;
	}
	
	return SDKCall(g_hGiveNamedItemCall, client, classname, 0);
}

stock void SwitchPlayerTeam(int client)
{
	int team = GetEntProp(client, Prop_Data, "m_iTeamNum");
	if (team == CS_TEAM_CT)
	{
		if (cvar_print_debugmsgs)
			PrintToConsole(client, "----====> SwitchPlayerTeam() -> CS_TEAM_T");
		SetEntProp(client, Prop_Data, "m_iTeamNum", CS_TEAM_T);
	}
	else if (team == CS_TEAM_T)
	{
		if (cvar_print_debugmsgs)
			PrintToConsole(client, "----====> SwitchPlayerTeam() -> CS_TEAM_CT");
		SetEntProp(client, Prop_Data, "m_iTeamNum", CS_TEAM_CT);
	}
}