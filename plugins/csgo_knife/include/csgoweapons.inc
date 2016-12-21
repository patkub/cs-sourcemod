#include <sourcemod>

stock Client_RemoveAllWeapons(client)
{
	new offset = Client_GetWeaponsOffset(client) - 4;
	
	for (new i = 0; i < 32; i++)
	{
		offset += 4;
		new weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon))
		{
			continue;
		}
		
		if (RemovePlayerItem(client, weapon))
		{
			Entity_Kill(weapon);
		}
	}
}

stock bool:Client_RemoveWeaponKnife(client,const String:className[],  bool:firstOnly=true)
{
	new offset = Client_GetWeaponsOffset(client) - 4;
	
	for (new i = 0; i < 32; i++)
	{
		offset += 4;
		new weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon) || !Entity_ClassNameMatches(weapon, className, true))
		{
			continue;
		}
			
		if (RemovePlayerItem(client, weapon))
		{
			Entity_Kill(weapon);
		}
		
		if (firstOnly)
		{
			return true;
		}
	}

	return false;
}

stock Weapon_IsValid(weapon)
{
	if (!IsValidEdict(weapon))
	{
		return false;
	}
	
	return Entity_ClassNameMatches(weapon, "weapon_", true);
}

stock bool:Entity_IsPlayer(entity)
{
	if (entity < 1 || entity > MaxClients)
	{
		return false;
	}
	
	return true;
}

stock bool:Entity_ClassNameMatches(entity, const String:className[], partialMatch=false)
{
	decl String:entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));

	if (partialMatch)
	{
		return (StrContains(entity_className, className) != -1);
	}

	return StrEqual(entity_className, className);
}

stock Entity_GetClassName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);	
}

stock bool:Entity_Kill(entity, killChildren=false)
{
	if (Entity_IsPlayer(entity))
	{
		ForcePlayerSuicide(entity);
		return true;
	}
	
	if(killChildren)
	{
		return AcceptEntityInput(entity, "KillHierarchy");
	}
	else
	{
		return AcceptEntityInput(entity, "Kill");
	}
}

stock Client_GetWeaponsOffset(client)
{
	return FindDataMapOffs(client, "m_hMyWeapons");
}
