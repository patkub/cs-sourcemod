#include <givenameditem>
#include <cstrike>

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "givenameditem"))
	{
		SetFailState("Required plugin 'givenameditem.smx' has been removed");
	}
}

public OnGiveNamedItemEx(int client, const char[] classname)
{
	if (StrContains(classname, "weapon_") != 0)
		return;

	if (IsFakeClient(client))
		return;
		
	int itemdefinition = GiveNamedItemEx.GetItemDefinitionByClassname(classname);
	
	if (itemdefinition == -1)
		return;
	
	// Change all knives to butterfly knives
	if (GiveNamedItemEx.IsItemDefinitionKnife(itemdefinition))
	{
		GiveNamedItemEx.ItemDefinition = 515;
		GiveNamedItemEx.SetClassname("weapon_knife_butterfly");
		GiveNamedItemEx.EntityQuality = 3;
	}
	
	// Make all weapons stattrak
	GiveNamedItemEx.Paintkit = PAINTKIT_PLAYERS;
	GiveNamedItemEx.Kills = 666;
	
	// Always weapon skins
	int weaponteam = GiveNamedItemEx.GetWeaponTeamByItemDefinition(itemdefinition);
	int playerteam = GetClientTeam(client);
	if (weaponteam != CS_TEAM_NONE && playerteam != weaponteam)
	{
		GiveNamedItemEx.SetClassname(classname);
		GiveNamedItemEx.TeamSwitch = true;
	}
	
	// Change all M4A4/1-s's to vanilla stattrak M4A1-S's
	if (itemdefinition == 16 || itemdefinition == 60)
	{
		GiveNamedItemEx.Paintkit = PAINTKIT_VANILLA;
		GiveNamedItemEx.Seed = 100;
		GiveNamedItemEx.Wear = 0.0001;
		GiveNamedItemEx.Kills = 666;
		GiveNamedItemEx.ItemDefinition = 60;
		GiveNamedItemEx.SetClassname("weapon_m4a1_silencer");
		GiveNamedItemEx.TeamSwitch = true;
		GiveNamedItemEx.EntityQuality = 1;
		GiveNamedItemEx.AccountID = GetSteamAccountID(client);
	}
	
	// Test items api
	char classnamecheck[64];
	GiveNamedItemEx.GetClassnameByItemDefinition(itemdefinition, classnamecheck, sizeof(classnamecheck));
	bool knifebyitemdefinition = GiveNamedItemEx.IsItemDefinitionKnife(itemdefinition);
	bool knifebyclassname = GiveNamedItemEx.IsClassnameKnife(classname);
	PrintToConsole(client, "--==> OnGiveNamedItemEx_Check(classname=%s, itemdefinition=%d, classnamecheck=%s, knifebyitemdefinition=%d, knifebyclassname=%d)", 
									classname, itemdefinition, classnamecheck, knifebyitemdefinition, knifebyclassname);
}