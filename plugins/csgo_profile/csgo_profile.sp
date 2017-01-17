#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAX_ITEMS 1000

#define MENU_PROFILE		(1 << 1)
#define MENU_RANK			(1 << 2)
#define MENU_COIN			(1 << 3)
#define MENU_LEVEL			(1 << 4)
#define MENU_COMMEND		(1 << 5)

enum coin
{
	String:name[64],
	value
}

new iRank[MAXPLAYERS+1];
new iCoin[MAXPLAYERS+1];
new iLevel[MAXPLAYERS+1];
new iLeader[MAXPLAYERS+1];
new iTeacher[MAXPLAYERS+1];
new iFriendly[MAXPLAYERS+1];

new iRankOffset = -1;
new iCoinOffset = -1;
new iLevelOffset = -1;
new iLeaderOffset = -1;
new iTeacherOffset = -1;
new iFriendlyOffset = -1;

new g_Coins[MAX_ITEMS][coin];
new g_iCoinCount;

new String:strRanks[][256] = {"\x08No Rank", "\x0ASilver I", "\x0ASilver II", "\x0ASilver III", "\x0ASilver IV", "\x0ASilver Elite", "\x0ASilver Elite Master",
							"\x0BGold Nova I", "\x0BGold Nova II", "\x0BGold Nova III", "\x0BGold Nova Master",
							"\x0CMaster Guardian I", "\x0CMaster Guardian II", "\x0CMaster Guardian Elite", "\x0CDistinguished Master Guardian",
							"\x0ELegendary Eagle", "\x0ELegandary Eagle Master", "\x0ESupreme Master First Class", "\x0FThe Global Elite"};

public Plugin:myinfo =
{
	name = "[CS:GO] Player Profile",
	author = "Patka",
	description = "Edit scoreboard profile.",
	version = "1.2"
}

public OnPluginStart()
{
	iRankOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
	iCoinOffset = FindSendPropInfo("CCSPlayerResource", "m_nActiveCoinRank");
	iLevelOffset = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicLevel");
	
	iLeaderOffset = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicCommendsLeader");
	iTeacherOffset = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicCommendsTeacher");
	iFriendlyOffset = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicCommendsFriendly");
	
	HookEvent("announce_phase_end", Event_AnnouncePhaseEnd);
	RegConsoleCmd("sm_profile", Command_Profile);
}

public OnMapStart()
{
	new ent = FindEntityByClassname2(MaxClients+1, "cs_player_manager");
	if (ent == -1)
	{
		SetFailState("Unable to find cs_player_manager entity.");
	}
	SDKHook(ent, SDKHook_ThinkPost, Hook_OnThinkPost);
}

public OnClientPostAdminCheck(client)
{
	iCoin[client] = 0;
	iRank[client] = 0;
	iLevel[client] = 0;
	iLeader[client] = 0;
	iTeacher[client] = 0;
	iFriendly[client] = 0;
}

public Hook_OnThinkPost(iEnt)
{
	SetEntDataArray(iEnt, iRankOffset, iRank, MAXPLAYERS+1, _, true);
	SetEntDataArray(iEnt, iCoinOffset, iCoin, MAXPLAYERS+1, _, true);
	SetEntDataArray(iEnt, iLevelOffset, iLevel, MAXPLAYERS+1, _, true);
	SetEntDataArray(iEnt, iLeaderOffset, iLeader, MAXPLAYERS+1, _, true);
	SetEntDataArray(iEnt, iTeacherOffset, iTeacher, MAXPLAYERS+1, _, true);
	SetEntDataArray(iEnt, iFriendlyOffset, iFriendly, MAXPLAYERS+1, _, true);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_SCORE) == IN_SCORE)
	{
		new Handle:hBuffer = StartMessageOne("ServerRankRevealAll", client);
		if (hBuffer != INVALID_HANDLE)
		{
			EndMessage();
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_AnnouncePhaseEnd(Handle:event, const String:strName[], bool:dontBroadcast)
{
	new Handle:hBuffer = StartMessageAll("ServerRankRevealAll");
	if (hBuffer != INVALID_HANDLE)
	{
		EndMessage();
	}
	
	return Plugin_Continue;
}

public Action:Command_Profile(client, args)
{
	if (args != 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_profile");
		return Plugin_Handled;
	}
	
	ShowProfileMenu(client, MENU_PROFILE);
	return Plugin_Handled;
}

public ShowProfileMenu(client, menutype)
{
	decl i;
	decl String:strItem[25];
	decl Handle:menu;
	
	if (menutype & MENU_PROFILE)
	{
		menu = CreateMenu(hProfileMenu);
		SetMenuTitle(menu, "Profile Menu:");
		
		AddMenuItem(menu, "0", "Rank");
		AddMenuItem(menu, "1", "Coin");
		AddMenuItem(menu, "2", "Level");
		AddMenuItem(menu, "3", "Commend");
	}
	
	if (menutype & MENU_RANK)
	{
		menu = CreateMenu(hRankMenu);
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "Rank Menu:");
		
		AddMenuItem(menu, "0", "Unranked");
		AddMenuItem(menu, "1", "Silver I");
		AddMenuItem(menu, "2", "Silver II");
		AddMenuItem(menu, "3", "Silver III");
		AddMenuItem(menu, "4", "Silver IV");
		AddMenuItem(menu, "5", "Silver Elite");
		AddMenuItem(menu, "6", "Silver Elite Master");
		AddMenuItem(menu, "7", "Gold Nova I");
		AddMenuItem(menu, "8", "Gold Nova II");
		AddMenuItem(menu, "9", "Gold Nova III");
		AddMenuItem(menu, "10", "Gold Nova Master");
		AddMenuItem(menu, "11", "Master Guardian I");
		AddMenuItem(menu, "12", "Master Guardian II");
		AddMenuItem(menu, "13", "Master Guardian Elite");
		AddMenuItem(menu, "14", "Distinguished Master Guardian");
		AddMenuItem(menu, "15", "Legendary Eagle");
		AddMenuItem(menu, "16", "Legandary Eagle Master");
		AddMenuItem(menu, "17", "Supreme Master First Class");
		AddMenuItem(menu, "18", "The Global Elite");
	}
	
	if (menutype & MENU_COIN)
	{
		menu = CreateMenu(hCoinMenu);
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "Coin Menu:");
		
		AddMenuItem(menu, "0", "No Coin");
		ReadCoins();
		for (i = 0; i < g_iCoinCount; i++)
		{
			Format(strItem, sizeof(strItem), "%i", i);
			AddMenuItem(menu, strItem, g_Coins[i][name]);
		}
	}
	
	if (menutype & MENU_LEVEL)
	{
		menu = CreateMenu(hLevelMenu);
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "Level Menu:");
		
		AddMenuItem(menu, "0", "Unranked");
		AddMenuItem(menu, "1", "Private 1");
		AddMenuItem(menu, "2", "Private 2");
		AddMenuItem(menu, "3", "Private 3");
		AddMenuItem(menu, "4", "Private 4");
		AddMenuItem(menu, "5", "Corporal 5");
		AddMenuItem(menu, "6", "Corporal 6");
		AddMenuItem(menu, "7", "Corporal 7");
		AddMenuItem(menu, "8", "Corporal 8");
		AddMenuItem(menu, "9", "Sergeant 9");
		AddMenuItem(menu, "10", "Sergeant 10");
		AddMenuItem(menu, "11", "Sergeant 11");
		AddMenuItem(menu, "12", "Sergeant 12");
		AddMenuItem(menu, "13", "Master Sergeant 13");
		AddMenuItem(menu, "14", "Master Sergeant 14");
		AddMenuItem(menu, "15", "Master Sergeant 15");
		AddMenuItem(menu, "16", "Master Sergeant 16");
		AddMenuItem(menu, "17", "Sergeant Major 17");
		AddMenuItem(menu, "18", "Sergeant Major 18");
		AddMenuItem(menu, "19", "Sergeant Major 19");
		AddMenuItem(menu, "20", "Sergeant Major 20");
		AddMenuItem(menu, "21", "Lieutenant 21");
		AddMenuItem(menu, "22", "Lieutenant 22");
		AddMenuItem(menu, "23", "Lieutenant 23");
		AddMenuItem(menu, "24", "Lieutenant 24");
		AddMenuItem(menu, "25", "Captain 25");
		AddMenuItem(menu, "26", "Captain 26");
		AddMenuItem(menu, "27", "Captain 27");
		AddMenuItem(menu, "28", "Captain 28");
		AddMenuItem(menu, "29", "Major 29");
		AddMenuItem(menu, "30", "Major 30");
		AddMenuItem(menu, "31", "Major 31");
		AddMenuItem(menu, "32", "Major 32");
		AddMenuItem(menu, "33", "Colonel 33");
		AddMenuItem(menu, "34", "Colonel 34");
		AddMenuItem(menu, "35", "Colonel 35");
		AddMenuItem(menu, "36", "Brigadier General 36");
		AddMenuItem(menu, "37", "Major General 37");
		AddMenuItem(menu, "38", "Lieutenant General 38");
		AddMenuItem(menu, "39", "General 39");
		AddMenuItem(menu, "40", "Global General 40");
	}
	
	if (menutype & MENU_COMMEND)
	{
		menu = CreateMenu(hCommendMenu);
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, "Commend Menu:");
		
		AddMenuItem(menu, "0", "Leader");
		AddMenuItem(menu, "1", "Teacher");
		AddMenuItem(menu, "2", "Friendly");
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public hProfileMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:info[6];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			new index = StringToInt(info);
			
			switch (index)
			{
				case 0:
				{
					ShowProfileMenu(client, MENU_RANK);
				}
				
				case 1:
				{
					ShowProfileMenu(client, MENU_COIN);
				}
				
				case 2:
				{
					ShowProfileMenu(client, MENU_LEVEL);
				}
				
				case 3:
				{
					ShowProfileMenu(client, MENU_COMMEND);
				}
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public hRankMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:info[6];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			iRank[client] = StringToInt(info);
			PrintToChat(client, "[SM] Your Rank Is: %s", strRanks[iRank[client]]);
		}
		
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				ShowProfileMenu(client, MENU_PROFILE);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public hCoinMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:info[6];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			new index = StringToInt(info);
			
			iCoin[client] = g_Coins[index][value];
			PrintToChat(client, "[SM] Coin Selected: %s", g_Coins[index][name]);
		}
		
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				ShowProfileMenu(client, MENU_PROFILE);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public hLevelMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:info[6];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			iLevel[client] = StringToInt(info);
			PrintToChat(client, "[SM] Level Selected: %i", iLevel[client]);
		}
		
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				ShowProfileMenu(client, MENU_PROFILE);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public hCommendMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:info[6];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			new index = StringToInt(info);
			
			switch (index)
			{
				case 0:
				{
					iLeader[client] = 1;
					iTeacher[client] = 0;
					iFriendly[client] = 0;
					PrintToChat(client, "[SM] You are a leader.");
				}
				
				case 1:
				{
					iLeader[client] = 0;
					iTeacher[client] = 1;
					iFriendly[client] = 0;
					PrintToChat(client, "[SM] You are a teacher.");
				}
				
				case 2:
				{
					iLeader[client] = 0;
					iTeacher[client] = 0;
					iFriendly[client] = 1;
					PrintToChat(client, "[SM] You are friendly.");
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
			{
				ShowProfileMenu(client, MENU_PROFILE);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock ReadCoins()
{
	new Handle:kvCoins = CreateKeyValues("csgo_profile_coins");
	new String:strLocation[256];
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, sizeof(strLocation), "configs/csgoprofile_coins.cfg");
	FileToKeyValues(kvCoins, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvCoins)) 
	{
		SetFailState("Error, can't read file containing the coins list: %s", strLocation);
		return;
	}
	
	new i = 0;
	do
	{
		KvGetSectionName(kvCoins, g_Coins[i][name], 64);
		g_Coins[i][value] = KvGetNum(kvCoins, "value", 0);
		i++;
	}
	while (KvGotoNextKey(kvCoins));
	
	g_iCoinCount = i;
	CloseHandle(kvCoins);
}

/**
 * Finds a valid entity by classname
 *
 * @param startEnt			Starting entity
 * @param classname			String entity classname
 * @return					Next valid entity
 */
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}
