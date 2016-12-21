#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <givenameditem>

#define MAX_PAINTS 1000

enum item
{
	String:name[64],
	index,
	Float:wear,
	stattrak,
	quality,
	seed
}

new OffAW = -1;
new g_Paints[MAX_PAINTS][item];
new g_iPaintCount;

new g_iKnife[MAXPLAYERS+1];
new g_iPaintIndex[MAXPLAYERS+1][3];
new g_iOtherWep[MAXPLAYERS+1][3];			// 0 - P2000 / USP-S, 1 - M4A1 / M4A1-S, 2 - Five-Seven (or Tec-9) / CZ75-Auto

public Plugin:myinfo =
{
	name = "[CS:GO] Weapon Skins",
	author = "Patka",
	description = "Set weapon skins.",
	version = "1.0"
}

public OnPluginStart()
{
	OffAW = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	RegConsoleCmd("sm_knife", Command_Knife);
	RegConsoleCmd("sm_ws", Command_WeaponSkins);
	RegConsoleCmd("sm_weptype", Command_WeaponTypes);
	
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		if (IsValidClient(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	for (int i = 0; i < 3; i++)
	{
		g_iPaintIndex[client][i] = -1;
		g_iOtherWep[client][i] = 0;
	}
}

public OnGiveNamedItemEx(int client, const char[] classname)
{
	if (StrContains(classname, "weapon_") != 0 || !IsValidClient(client))
	{
		return;
	}
	
	int itemDef = GiveNamedItemEx.GetItemDefinitionByClassname(classname);
	
	if (itemDef == -1)
	{
		return;
	}
	
	if (GiveNamedItemEx.IsItemDefinitionKnife(itemDef))
	{
		switch(g_iKnife[client])
		{
			case 0:
			{
				new team = GetClientTeam(client);
				if (team == CS_TEAM_CT)
				{
					GiveNamedItemEx.SetClassname("weapon_knife");
				}
				else if (team == CS_TEAM_T)
				{
					GiveNamedItemEx.SetClassname("weapon_knife_t");
				}
			}
			
			case 1:
			{
				GiveNamedItemEx.SetClassname("weapon_bayonet");
				GiveNamedItemEx.ItemDefinition = 500;
			}
			
			case 2:
			{
				GiveNamedItemEx.SetClassname("weapon_knife_gut");
				GiveNamedItemEx.ItemDefinition = 506;
			}
			
			case 3:
			{
				GiveNamedItemEx.SetClassname("weapon_knife_flip");
				GiveNamedItemEx.ItemDefinition = 505;
			}
			
			case 4:
			{
				GiveNamedItemEx.SetClassname("weapon_knife_m9_bayonet");
				GiveNamedItemEx.ItemDefinition = 508;
			}
			
			case 5:
			{
				GiveNamedItemEx.SetClassname("weapon_knife_karambit");
				GiveNamedItemEx.ItemDefinition = 507;
			}
			
			case 6:
			{
				GiveNamedItemEx.SetClassname("weapon_knife_tactical");
				GiveNamedItemEx.ItemDefinition = 509;
			}
			
			case 7:
			{
				GiveNamedItemEx.SetClassname("weapon_knife_falchion");
				GiveNamedItemEx.ItemDefinition = 512;
			}
			
			case 8:
			{
				GiveNamedItemEx.SetClassname("weapon_knife_butterfly");
				GiveNamedItemEx.ItemDefinition = 515;
			}
			
			case 9:
			{
				GiveNamedItemEx.SetClassname("weapon_knifegg");
				GiveNamedItemEx.ItemDefinition = 516;
			}
			
			default:return;
		}
		
		new paintIndex = g_iPaintIndex[client][2];
		if (paintIndex != -1)
		{
			GiveNamedItemEx.Paintkit = g_Paints[paintIndex][index];
			
			if (g_Paints[paintIndex][wear] >= 0.0)
			{
				GiveNamedItemEx.Wear = g_Paints[paintIndex][wear];
			}
			
			if (g_Paints[paintIndex][stattrak] != -2)
			{
				GiveNamedItemEx.Kills = g_Paints[paintIndex][stattrak];
			}
			
			if (g_Paints[paintIndex][quality] != -2)
			{
				GiveNamedItemEx.EntityQuality = g_Paints[paintIndex][quality];
			}
			
			if (g_Paints[paintIndex][seed] != -2)
			{
				GiveNamedItemEx.Seed = g_Paints[paintIndex][seed];
			}
		}
	}
	else if (itemDef == 1 || itemDef == 2 || itemDef == 3 || itemDef == 4 || itemDef == 30 || itemDef == 32 || itemDef == 36 || itemDef == 2 || itemDef == 61 || itemDef == 63)
	{
		// pistol
		
		if (g_iOtherWep[client][0] == 0 && (itemDef == 32 || itemDef == 61))		// hkp2000 = 32, usp-s = 61
		{
			GiveNamedItemEx.SetClassname("weapon_hkp2000");
			GiveNamedItemEx.ItemDefinition = 32;
		}
		else if (g_iOtherWep[client][0] == 1 && (itemDef == 32 || itemDef == 61))
		{
			GiveNamedItemEx.SetClassname("weapon_usp_silencer");
			GiveNamedItemEx.ItemDefinition = 61;
		}
		else if (g_iOtherWep[client][2] == 0 && (itemDef == 3 || itemDef == 63))	// fiveseven = 3, CZ = 63
		{
			GiveNamedItemEx.SetClassname("weapon_fiveseven");
			GiveNamedItemEx.ItemDefinition = 3;
		}
		else if (g_iOtherWep[client][2] == 1 && (itemDef == 3 || itemDef == 63))
		{
			GiveNamedItemEx.SetClassname("weapon_cz75a");
			GiveNamedItemEx.ItemDefinition = 63;
		}
		
		new paintIndex = g_iPaintIndex[client][1];
		if (paintIndex != -1)
		{
			GiveNamedItemEx.Paintkit = g_Paints[paintIndex][index];
			
			if (g_Paints[paintIndex][wear] >= 0.0)
			{
				GiveNamedItemEx.Wear = g_Paints[paintIndex][wear];
			}
			
			if (g_Paints[paintIndex][stattrak] != -2)
			{
				GiveNamedItemEx.Kills = g_Paints[paintIndex][stattrak];
			}
			
			if (g_Paints[paintIndex][quality] != -2)
			{
				GiveNamedItemEx.EntityQuality = g_Paints[paintIndex][quality];
			}
			
			if (g_Paints[paintIndex][seed] != -2)
			{
				GiveNamedItemEx.Seed = g_Paints[paintIndex][seed];
			}
		}
	}
	else if (itemDef == 7 || itemDef == 8 || itemDef == 9 || itemDef == 10 || itemDef == 11 || itemDef == 13 || itemDef == 14 || itemDef == 16 || itemDef == 17 || itemDef == 19 ||
			 itemDef == 24 || itemDef == 25 || itemDef == 26 || itemDef == 27 || itemDef == 28 || itemDef == 29 || itemDef == 33 || itemDef == 34 || itemDef == 35 || itemDef == 38 ||
			 itemDef == 39 || itemDef == 40 || itemDef == 60)
	{
		// riffle
		
		if (g_iOtherWep[client][1] == 0 && (itemDef == 16 || itemDef == 60))
		{
			GiveNamedItemEx.SetClassname("weapon_m4a1");
			GiveNamedItemEx.ItemDefinition = 16;
		}
		else if (g_iOtherWep[client][1] == 1 && (itemDef == 16 || itemDef == 60))
		{
			GiveNamedItemEx.SetClassname("weapon_m4a1_silencer");
			GiveNamedItemEx.ItemDefinition = 60;
		}
		
		
		new paintIndex = g_iPaintIndex[client][0];
		if (paintIndex != -1)
		{
			GiveNamedItemEx.Paintkit = g_Paints[paintIndex][index];
			
			if (g_Paints[paintIndex][wear] >= 0.0)
			{
				GiveNamedItemEx.Wear = g_Paints[paintIndex][wear];
			}
			
			if (g_Paints[paintIndex][stattrak] != -2)
			{
				GiveNamedItemEx.Kills = g_Paints[paintIndex][stattrak];
			}
			
			if (g_Paints[paintIndex][quality] != -2)
			{
				GiveNamedItemEx.EntityQuality = g_Paints[paintIndex][quality];
			}
			
			if (g_Paints[paintIndex][seed] != -2)
			{
				GiveNamedItemEx.Seed = g_Paints[paintIndex][seed];
			}
		}
	}
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
	AddMenuItem(menu, "7", "Falchion");
	AddMenuItem(menu, "8", "Butterfly");
	AddMenuItem(menu, "9", "Golden Knife");
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
			ChangePaint(client, "weapon_knife", g_iPaintIndex[client][2]);
			FakeClientCommand(client, "use weapon_knife");
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:Command_WeaponSkins(client, args)
{
	decl String:strItem[25];
	new Handle:menu = CreateMenu(hSkinsMenu);
	SetMenuTitle(menu, "Select Weapon Paint:");
	AddMenuItem(menu, "-1", "Default paint");
	
	ReadPaints();
	for (new i = 0; i < g_iPaintCount; i++)
	{
		Format(strItem, sizeof(strItem), "%i", i);
		AddMenuItem(menu, strItem, g_Paints[i][name]);
	}
	
	DisplayMenu(menu, client, 0);
	return Plugin_Handled;
}

public Action:Command_WeaponTypes(client, args)
{
	new Handle:menu = CreateMenu(hWepTypeMenu);
	SetMenuTitle(menu, "Toggle Weapon Type:");
	AddMenuItem(menu, "0", "P2000 / USP-S");
	AddMenuItem(menu, "1", "M4A4 / M4A1-S");
	AddMenuItem(menu, "2", "Five-Seven (or Tec-9) / CZ75-Auto");
	DisplayMenu(menu, client, 0);
	return Plugin_Handled;
}

public hSkinsMenu(Handle:menu, MenuAction:action, client, param2) 
{
	if (action == MenuAction_Select) 
	{
		if (!IsPlayerAlive(client))
		{
			return;
		}
		
		decl String:strItem[25];
		GetMenuItem(menu, param2, strItem, sizeof(strItem));
		new paintIndex = StringToInt(strItem);
		
		new wep = GetEntDataEnt2(client, OffAW);
		if (wep != -1)
		{
			decl String:classname[64];
			GetEdictClassname(wep, classname, 64);
			
			new slot = -1;
			if (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == wep)
			{
				slot = 0;
			}
			else if (GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == wep)
			{
				slot = 1;
			}
			else if (GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == wep && !StrEqual(classname, "weapon_taser"))
			{
				slot = 2;
			}
			
			if (slot != -1)
			{
				g_iPaintIndex[client][slot] = paintIndex;
				ChangePaint(client, classname, wep);
				FakeClientCommand(client, "use %s", classname);
				
				if (paintIndex == -1)
				{
					PrintToChat(client, "[SM] Set Default Weapon Skin");
				}
				else
				{
					PrintToChat(client, "[SM] Selected Weapon Skin: %s", g_Paints[paintIndex][name]);
				}
			}
			else
			{
				PrintToChat(client, "[SM] This weapon is unpaintable");
			}
		}
	}
}

public hWepTypeMenu(Handle:menu, MenuAction:action, client, param2) 
{
	if (action == MenuAction_Select) 
	{
		decl String:strItem[25];
		GetMenuItem(menu, param2, strItem, sizeof(strItem));
		new type = StringToInt(strItem);
		
		if (g_iOtherWep[client][type] <= 0)
		{
			g_iOtherWep[client][type] = 1;
		}
		else
		{
			g_iOtherWep[client][type] = 0;
		}
		
		char wepItem1[][] = {"P2000", "USP-S"};
		char wepItem2[][] = {"M4A4", "M4A1-S"};
		char wepItem3[][] = {"Five-Seven (or Tec-9)", "CZ75-Auto"};
		
		switch (type)
		{
			case 0:
			{
				PrintToChat(client, "Set Weapon %s", wepItem1[g_iOtherWep[client][type]]);
				new wep = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
				ChangePaint(client, "", wep);
			}
			
			case 1:
			{
				PrintToChat(client, "Set Weapon %s", wepItem2[g_iOtherWep[client][type]]);
				new wep = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
				ChangePaint(client, "", wep);
			}
			
			case 2:
			{
				PrintToChat(client, "Set Weapon %s", wepItem3[g_iOtherWep[client][type]]);
				new wep = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
				ChangePaint(client, "", wep);
			}
		}
	}
}

stock ChangePaint(client, String:classname[64], weapon = -1)
{
	new ammo, clip, iItem;
	new bool:knife = (StrContains(classname, "weapon_knife", false) == 0);
	new bool:c4 = (StrContains(classname, "weapon_c4", false) == 0);
	
	if (!IsValidClient(client) || !IsPlayerAlive(client) || c4)
	{
		return;
	}
	
	if (!knife)
	{
		ammo = GetReserveAmmo(client, weapon);
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	}
	
	if (knife)
	{
		new team = GetClientTeam(client);
		
		switch(g_iKnife[client])
		{
			case 0:
			{
				if (team == CS_TEAM_CT)
				{
					iItem = GivePlayerItem(client, "weapon_knife");
				}
				else if (team == CS_TEAM_T)
				{
					iItem = GivePlayerItem(client, "weapon_knife_t");
				}
			}
			
			case 1:iItem = GivePlayerItem(client, "weapon_bayonet");
			case 2:iItem = GivePlayerItem(client, "weapon_knife_gut");
			case 3:iItem = GivePlayerItem(client, "weapon_knife_flip");
			case 4:iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");
			case 5:iItem = GivePlayerItem(client, "weapon_knife_karambit");
			case 6:iItem = GivePlayerItem(client, "weapon_knife_tactical");
			case 7:iItem = GivePlayerItem(client, "weapon_knife_falchion");
			case 8:iItem = GivePlayerItem(client, "weapon_knife_butterfly");
			case 9:iItem = GivePlayerItem(client, "weapon_knifegg");
			default:return;
		}
		
		weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	}
	else
	{
		iItem = GivePlayerItem(client, classname);
	}
	
	if (weapon == -1 || !IsValidEntity(weapon))
	{
		return;
	}
	
	if (iItem > 0)
	{
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
		EquipPlayerWeapon(client, iItem);
	}
	
	if (!knife)
	{
		SetReserveAmmo(client, weapon, ammo);
		if (clip >= 0)
		{
			SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
		}
	}
}

stock GetReserveAmmo(client, weapon)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (ammotype == -1)
	{
		return -1;
	}
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

stock SetReserveAmmo(client, weapon, ammo)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (ammotype != -1 && ammo >= 0)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
	}
} 

stock ReadPaints()
{
	new Handle:kvWeaponPaints = CreateKeyValues("csgo_weapon_paints");
	new String:strLocation[256];
	
	// Load the key files.
	BuildPath(Path_SM, strLocation, sizeof(strLocation), "configs/csgo_wpaints.cfg");
	FileToKeyValues(kvWeaponPaints, strLocation);
	
	// Check if the parsed values are correct
	if (!KvGotoFirstSubKey(kvWeaponPaints)) 
	{
		SetFailState("Error, can't read file containing the paints list: %s", strLocation);
		return;
	}
	
	new i = 0;
	do
	{
		KvGetSectionName(kvWeaponPaints, g_Paints[i][name], 64);
		g_Paints[i][index] = KvGetNum(kvWeaponPaints, "paint", 0);
		g_Paints[i][wear] = KvGetFloat(kvWeaponPaints, "wear", -1.0);
		g_Paints[i][stattrak] = KvGetNum(kvWeaponPaints, "stattrak", -2);
		g_Paints[i][quality] = KvGetNum(kvWeaponPaints, "quality", -2);
		g_Paints[i][seed] = KvGetNum(kvWeaponPaints, "seed", -2);
		i++;
	}
	while (KvGotoNextKey(kvWeaponPaints));
	
	g_iPaintCount = i;
	CloseHandle(kvWeaponPaints);
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}
