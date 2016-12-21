#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgoweapons>

#define PLUGIN_VERSION		"1.0"

public g_iKnife[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[CS:GO] Knife",
	author = "Patka",
	description = "Give Knife",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("cs_give_knife_version", PLUGIN_VERSION, "[CS:GO] Knife plugin version.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	RegConsoleCmd("sm_knife", Command_Knife, "Open Knife Menu.");
}

public OnClientPostAdminCheck(client)
{
	g_iKnife[client] = 0;
	SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("K_GetKnife", Native_GetKnife);
	RegPluginLibrary("csgo_knife");
	return APLRes_Success;
}

public Native_GetKnife(Handle:plugin, argc)
{  
	return g_iKnife[GetNativeCell(1)];
}

public Action:OnPostWeaponEquip(client, weapon)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !IsFakeClient(client) && IsValidEntity(weapon))
	{
		new m_iEntityQuality = GetEntProp(weapon, Prop_Send, "m_iEntityQuality");
		new m_iItemIDHigh = GetEntProp(weapon, Prop_Send, "m_iItemIDHigh");
		new m_iItemIDLow = GetEntProp(weapon, Prop_Send, "m_iItemIDLow");
		new check = m_iEntityQuality + m_iItemIDHigh + m_iItemIDLow;

		if (check >= 4)
		{
			return Plugin_Continue;
		}
		
		new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (index != 42 && index != 59)		//standard knife ct | knife t
		{
			return Plugin_Continue;
		}
		
		if (Client_RemoveWeaponKnife(client, "weapon_knife", true))
		{
			EquipKnife(client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Knife(client, args)
{
	if (args != 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_knife");
		return Plugin_Handled;
	}
	
	ShowKnifeMenu(client);
	return Plugin_Handled;
}

public ShowKnifeMenu(client)
{
	new Handle:menu = CreateMenu(hKnifeMenu);
	SetMenuTitle(menu, "CS:GO Knife Menu:");
	AddMenuItem(menu, "0", "Default Knife");
	AddMenuItem(menu, "1", "Bayonet");
	AddMenuItem(menu, "2", "Gut Knife");
	AddMenuItem(menu, "3", "Flip Knife");
	AddMenuItem(menu, "4", "M9 Bayonet");
	AddMenuItem(menu, "5", "Karambit");
	AddMenuItem(menu, "6", "Huntsman");
	AddMenuItem(menu, "7", "Butterfly");
	AddMenuItem(menu, "8", "Golden Knife");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public hKnifeMenu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			g_iKnife[client] = StringToInt(info);
			EquipKnife(client);
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public EquipKnife(client)
{
	new iItem;
	switch (g_iKnife[client])
	{
		case 0:iItem = GivePlayerItem(client, "weapon_knife");
		case 1:iItem = GivePlayerItem(client, "weapon_bayonet");
		case 2:iItem = GivePlayerItem(client, "weapon_knife_gut");
		case 3:iItem = GivePlayerItem(client, "weapon_knife_flip");
		case 4:iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");
		case 5:iItem = GivePlayerItem(client, "weapon_knife_karambit");
		case 6:iItem = GivePlayerItem(client, "weapon_knife_tactical");
		case 7:iItem = GivePlayerItem(client, "weapon_knife_butterfly");
		case 8:iItem = GivePlayerItem(client, "weapon_knifegg");
	}
	
	if (iItem > 0)
	{
		EquipPlayerWeapon(client, iItem);
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}
