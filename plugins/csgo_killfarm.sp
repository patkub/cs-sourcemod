#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <morecolors>

#define PLUGIN_VERSION		"1.0"

#include "tf2perks/health.sp"
#include "tf2perks/rof.sp"

new g_offsCollisionGroup;
new Handle:ClientTimer[MAXPLAYERS+1];
new Float:flStartTime[MAXPLAYERS+1];
new Bot[MAXPLAYERS+1];
new AttackType[MAXPLAYERS+1];
new KillMax[MAXPLAYERS+1];
new Kills[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "CS:GO StatTrack Level Up",
	author = "Patka",
	description = "Level up StatTrack weapons.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("tf_kill_farm_version", PLUGIN_VERSION, "CS:GO StatTrack Level Up plugin version.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	RegAdminCmd("sm_killfarm", Command_KillFarm, ADMFLAG_CUSTOM6, "Level up StatTrack weapon.");
	RegAdminCmd("sm_stopkillfarm", Command_StopKillFarm, ADMFLAG_CUSTOM6, "Stop StatTrack weapon level up.");
	RegAdminCmd("sm_killfarmstats", Command_KillFarmStats, ADMFLAG_CUSTOM6, "Show StatTrack weapon level up stats.");
	HookEvent("player_death", OnPlayerDeath);
	OffAW = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

public OnClientPostAdminCheck(client)
{
	StopKillFarm(client);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	new attackerid = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attackerid);
	
	if (IsValidClient(client) && IsValidClient(attacker) && client != attacker)
	{
		if (client == Bot[attacker])
		{
			if (Kills[attacker] < (KillMax[attacker] - 1))
			{
				Kills[attacker]++;
				ShowStatsPanel(attacker);
			}
			else
			{
				Kills[attacker]++;
				ShowStatsPanel(attacker);
				StopKillFarm(attacker);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_KillFarm(client, args)
{
	if (args < 5)
	{
		ReplyToCommand(client, "[SM] Usage: sm_killfarm <client> <attach to client> <attack 1|2> <rof amount> <kills>");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	new String:arg2[32];
	new String:arg3[32];
	new String:arg4[32];
	new String:arg5[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	GetCmdArg(5, arg5, sizeof(arg5));
	
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
	
	decl String:target_name2[MAX_TARGET_LENGTH];
	decl target_list2[MAXPLAYERS], target_count2, bool:tn_is_ml2;
	
	if ((target_count2 = ProcessTargetString(
			arg2,
			client,
			target_list2,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name2,
			sizeof(target_name2),
			tn_is_ml2)) <= 0)
	{
		ReplyToTargetError(client, target_count2);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		new Float:flROFMulti = StringToFloat(arg4);
		ModRateOfFire(target_list[i], flROFMulti);
		
		Kills[target_list[i]] = 0;
		AttackType[target_list[i]] = StringToInt(arg3);
		KillMax[target_list[i]] = StringToInt(arg5);
		UnblockEntity(target_list[i]);		
		flStartTime[target_list[i]] = GetGameTime();
		ShowStatsPanel(target_list[i]);
		
		if (ClientTimer[target_list[i]] != INVALID_HANDLE)
		{
			ClientTimer[target_list[i]] = INVALID_HANDLE;
		}
		
		for (new j = 0; j < target_count2; j++)
		{
			Bot[target_list[i]] = target_list2[j];
			ClientTimer[target_list[i]] = CreateTimer(0.01, TimerKillFarm, target_list[i], TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_StopKillFarm(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_stopkillfarm <client>");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
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
	
	for (new i = 0; i < target_count; i++)
	{
		StopKillFarm(target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:Command_KillFarmStats(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_killfarmstats <client>");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
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
	
	for (new i = 0; i < target_count; i++)
	{
		ShowStats(client, target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:TimerKillFarm(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsValidClient(Bot[client]))
	{
		SetHealth(Bot[client], 1);
		TeleportToFront(client, Bot[client]);
	}
	else
	{
		StopKillFarm(client);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

stock ShowStats(client, target)
{
	if (IsValidClient(target) && IsValidClient(Bot[target]))
	{
		new KillsLeft = KillMax[target] - Kills[target];
		new Float:flTimeElapsed = GetGameTime() - flStartTime[target];
		new Float:flSpeed = Kills[target] / flTimeElapsed;
		new Float:flTimeRemaining = KillsLeft / flSpeed;
		
		new Minutes, Hours;
		while(flTimeElapsed >= 60)
		{
			Minutes++;
			flTimeElapsed -= 60;
		}
		
		while (Minutes >= 60)
		{
			Hours++;
			Minutes -= 60;
		}
		
		new String:Buffer1[256];
		new String:Buffer2[256];
		FormatEx(Buffer1, sizeof(Buffer1), "Time Elapsed: ");
		
		if (Hours > 0)
		{
			FormatEx(Buffer1, sizeof(Buffer1), "%s%i hours ", Buffer1, Hours);
		}
		
		if (Minutes > 0)
		{
			FormatEx(Buffer1, sizeof(Buffer1), "%s%i minutes ", Buffer1, Minutes);
		}
		
		if (flTimeElapsed > 0)
		{
			FormatEx(Buffer1, sizeof(Buffer1), "%s%f seconds ", Buffer1, flTimeElapsed);
		}
		
		new HoursRemaining, MinutesRemaining;
		while(flTimeRemaining >= 60)
		{
			MinutesRemaining++;
			flTimeRemaining -= 60;
		}
		
		while (MinutesRemaining >= 60)
		{
			HoursRemaining++;
			MinutesRemaining -= 60;
		}
		
		FormatEx(Buffer2, sizeof(Buffer2), "Time Remaining: ");
		
		if (HoursRemaining > 0)
		{
			FormatEx(Buffer2, sizeof(Buffer2), "%s%i hours ", Buffer2, HoursRemaining);
		}
		
		if (MinutesRemaining > 0)
		{
			FormatEx(Buffer2, sizeof(Buffer2), "%s%i minutes ", Buffer2, MinutesRemaining);
		}
		
		if (flTimeRemaining > 0)
		{
			FormatEx(Buffer2, sizeof(Buffer2), "%s%f seconds ", Buffer2, flTimeRemaining);
		}
		
		PrintToConsole(client, "===================================");
		PrintToConsole(client, "Client: %N", target);
		PrintToConsole(client, "Victim: %N", Bot[target]);
		PrintToConsole(client, "Kills: %i", Kills[target]);
		PrintToConsole(client, "Kills Left: %i", KillsLeft);
		PrintToConsole(client, "Speed: %f kps", flSpeed);
		PrintToConsole(client, Buffer1);
		PrintToConsole(client, Buffer2);
		PrintToConsole(client, "===================================");
	}
	else
	{
		PrintToConsole(client, "===================================");
		PrintToConsole(client, "The specified client is ");
		PrintToConsole(client, "currently not kill farming.");
		PrintToConsole(client, "===================================");
	}
}

stock ShowStatsPanel(client)
{
	if (IsValidClient(client) && IsValidClient(Bot[client]))
	{
		new Handle:StatsPanel = CreatePanel(INVALID_HANDLE);
		SetPanelTitle(StatsPanel, "TF2 Kill Farm Stats:");
		
		new String:Buffer1[256];
		new String:Buffer2[256];
		new String:Buffer3[256];
		new String:Buffer4[256];
		new String:Buffer5[256];
		new String:Buffer6[256];
		
		new KillsLeft = KillMax[client] - Kills[client];
		new Float:flTimeElapsed = GetGameTime() - flStartTime[client];
		new Float:flSpeed = Kills[client] / flTimeElapsed;
		new Float:flTimeRemaining = KillsLeft / flSpeed;
		
		new MinutesElapsed, HoursElapsed;
		while(flTimeElapsed >= 60)
		{
			MinutesElapsed++;
			flTimeElapsed -= 60;
		}
		
		while (MinutesElapsed >= 60)
		{
			HoursElapsed++;
			MinutesElapsed -= 60;
		}
		
		new HoursRemaining, MinutesRemaining;
		while(flTimeRemaining >= 60)
		{
			MinutesRemaining++;
			flTimeRemaining -= 60;
		}
		
		while (MinutesRemaining >= 60)
		{
			HoursRemaining++;
			MinutesRemaining -= 60;
		}
		
		FormatEx(Buffer1, sizeof(Buffer1), "Victim: %N", Bot[client]);
		FormatEx(Buffer2, sizeof(Buffer2), "Kills: %i", Kills[client]);
		FormatEx(Buffer3, sizeof(Buffer3), "Kills Left: %i", KillsLeft);
		FormatEx(Buffer4, sizeof(Buffer4), "Speed: %f kps", flSpeed);
		FormatEx(Buffer5, sizeof(Buffer5), "Time Elapsed: ");
		
		if (HoursElapsed > 0)
		{
			FormatEx(Buffer5, sizeof(Buffer5), "%s%i hours ", Buffer5, HoursElapsed);
		}
		
		if (MinutesElapsed > 0)
		{
			FormatEx(Buffer5, sizeof(Buffer5), "%s%i minutes ", Buffer5, MinutesElapsed);
		}
		
		if (flTimeElapsed > 0)
		{
			FormatEx(Buffer5, sizeof(Buffer5), "%s%f seconds ", Buffer5, flTimeElapsed);
		}
		
		FormatEx(Buffer6, sizeof(Buffer6), "Time Remaining: ");
		
		if (HoursRemaining > 0)
		{
			FormatEx(Buffer6, sizeof(Buffer6), "%s%i hours ", Buffer6, HoursRemaining);
		}
		
		if (MinutesRemaining > 0)
		{
			FormatEx(Buffer6, sizeof(Buffer6), "%s%i minutes ", Buffer6, MinutesRemaining);
		}
		
		if (flTimeRemaining > 0)
		{
			FormatEx(Buffer6, sizeof(Buffer6), "%s%f seconds ", Buffer6, flTimeRemaining);
		}
		
		DrawPanelText(StatsPanel, Buffer1);
		DrawPanelText(StatsPanel, Buffer2);
		DrawPanelText(StatsPanel, Buffer3);
		DrawPanelText(StatsPanel, Buffer4);
		DrawPanelText(StatsPanel, Buffer5);
		DrawPanelText(StatsPanel, Buffer6);
		
		SendPanelToClient(StatsPanel, client, Handler_PanelNoAction, 5);
		CloseHandle(StatsPanel);
	}
}

stock StopKillFarm(client)
{
	if (ClientTimer[client] != INVALID_HANDLE)
	{
		KillTimer(ClientTimer[client]);
		ClientTimer[client] = INVALID_HANDLE;
	}
	
	ModRateOfFire(client, 1.0);
	BlockEntity(client);
	AttackType[client] = -1;
	Bot[client] = -1;
	KillMax[client] = 0;
	Kills[client] = 0;
}

stock BlockEntity(client)
{
    SetEntData(client, g_offsCollisionGroup, 5, 4, true);
}

stock UnblockEntity(client)
{
    SetEntData(client, g_offsCollisionGroup, 2, 4, true);
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

public Handler_PanelNoAction(Handle:menu, MenuAction:action, param1, param2)
{
	return;
}

stock TeleportToFront(player1, player2)
{
	new Float:velocity[3];
	velocity[0] = 0.0;
	velocity[1] = 0.0;
	velocity[2] = 0.0;
	
	decl Float:location[3], Float:ang[3], Float:location2[3];
	GetClientAbsOrigin(player1, location);
	GetClientEyeAngles(player1, ang);
	
	location2[0] = (location[0]+(50*(Cosine(DegToRad(ang[1])))));
	location2[1] = (location[1]+(50*(Sine(DegToRad(ang[1])))));
	location2[2] = location[2] - 1.0;
	
	if (!IsPlayerAlive(player2))
	{
		CS_RespawnPlayer(player2);
	}
	
	TeleportEntity(player2, location2, NULL_VECTOR, velocity);
}
