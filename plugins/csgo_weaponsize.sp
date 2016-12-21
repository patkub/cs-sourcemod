#pragma semicolon 1
#include <sourcemod>

new OffAW = -1;

public OnPluginStart()
{
	OffAW = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	RegAdminCmd("sm_wepsize", Command_WeaponSize, ADMFLAG_CUSTOM6, "Change weapon size.");
}

public Action:Command_WeaponSize(client, args)
{	
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_wepsize <client> <size>");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new String:arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float:size = StringToFloat(arg2);
	for (new i = 0; i < target_count; i++)
	{
		if (IsValidClient(target_list[i]))
		{
			new wep = GetEntDataEnt2(target_list[i], OffAW);
			if (wep != -1)
			{
				SetEntPropFloat(wep, Prop_Send, "m_flModelScale", size);
			}
		}
	}
	
	ReplyToCommand(client, "[SM] Player %s's Current Weapon Size Set To: %f", target_name, size);
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}
