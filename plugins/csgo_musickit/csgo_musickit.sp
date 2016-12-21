#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define MAX_ITEMS 1000

new g_iClientMusicKit[MAXPLAYERS+1];
new g_bEnabled[MAXPLAYERS+1];
new g_iMusicKitCount;

enum musickit
{
	String:name[64],
	value
}

new g_iMusicKits[MAX_ITEMS][musickit];

public Plugin:myinfo =
{
	name = "[CS:GO] Music Kits",
	author = "Patka",
	description = "Set music kit.",
	version = "1.0"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_musickit", Command_MusicKit);
}

public OnClientPostAdminCheck(client)
{
	g_iClientMusicKit[client] = -1;
	g_bEnabled[client] = false;
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

public OnPreThink(client)
{
	if (g_bEnabled[client])
	{
		SetEntProp(client, Prop_Send, "m_unMusicID", g_iMusicKits[g_iClientMusicKit[client]][value]);
	}
}

public Action:Command_MusicKit(client, args)
{
	if (args != 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_musickit");
		return Plugin_Handled;
	}
	
	ShowMusicKitMenu(client);
	return Plugin_Handled;
}

public ShowMusicKitMenu(client)
{
	new Handle:menu = CreateMenu(hMusicKitMenu);
	new String:strItem[25];
	SetMenuTitle(menu, "Music Kits Menu:");
	
	ReadMusicKits();
	for (new i = 0; i < g_iMusicKitCount; i++)
	{
		Format(strItem, sizeof(strItem), "%i", i);
		AddMenuItem(menu, strItem, g_iMusicKits[i][name]);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public hMusicKitMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:info[6];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			g_iClientMusicKit[client] = StringToInt(info);
			
			if (g_iClientMusicKit[client] == 0)
			{
				g_bEnabled[client] = false;
				PrintToChat(client, "[SM] Disabled Music Kit");
			}
			else
			{
				g_bEnabled[client] = true;
				PrintToChat(client, "[SM] Set Music Kit: %s", g_iMusicKits[g_iClientMusicKit[client]][name]);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock ReadMusicKits()
{
	new Handle:kvMusicKits = CreateKeyValues("csgo_profile_music_kits");
	new String:strLocation[256];
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, sizeof(strLocation), "configs/csgomusic_kits.cfg");
	FileToKeyValues(kvMusicKits, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvMusicKits)) 
	{
		SetFailState("Error, can't read file containing the music kits list: %s", strLocation);
		return;
	}
	
	new i = 0;
	do
	{
		KvGetSectionName(kvMusicKits, g_iMusicKits[i][name], 64);
		g_iMusicKits[i][value] = KvGetNum(kvMusicKits, "value", 0);
		i++;
	}
	while (KvGotoNextKey(kvMusicKits));
	
	g_iMusicKitCount = i;
	CloseHandle(kvMusicKits);
}
