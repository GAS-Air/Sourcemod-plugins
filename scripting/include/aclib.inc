/*
* Библиотека полезностей от команды Aircaft!
* https://aircr.ru/
* https://vk.com/aircraft/
*/
#if defined _AC_included
	#endinput
#endif
#define _AC_included

#include <aclib\hudtext>
#include <aclib\effects>

stock bool AC_IsClientReal(int client) {
	if(client <= 0 || (client > MaxClients) || !IsClientConnected(client) || IsFakeClient(client)) return false;
	return IsClientInGame(client);
}
stock bool AC_IsClientValid(int client) {
	if(client > 0 && client <= MaxClients && IsClientInGame(client)) return true;
	return false;
}

#define HIDE_CROSSHAIR_CSGO 1<<8
#define HIDE_RADAR_CSGO 1<<12

stock void AC_SetThirdPersonView(int client, bool third) {
	ConVar mp_forcecamera = FindConVar("mp_forcecamera");
	if (!IsPlayerAlive(client) || IsFakeClient(client)) {
		return;
	}
	if(third) {
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		SendConVarValue(client, mp_forcecamera, "1");
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_CROSSHAIR_CSGO);
	} else {
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		char valor[6];
		GetConVarString(mp_forcecamera, valor, 6);
		SendConVarValue(client, mp_forcecamera, valor);		
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR_CSGO);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_CROSSHAIR_CSGO);
	}
}

/*
MOVETYPE_NONE - заморозить 
MOVETYPE_ISOMETRIC - для игроков 
MOVETYPE_WALK - движение по земле (для игроков) 
MOVETYPE_STEP - gravity, special edge handling -- monsters use this 
MOVETYPE_FLY - полет, джет пак (jet pack) 
MOVETYPE_FLYGRAVITY - flies through the air + is affected by gravity 
MOVETYPE_VPHYSICS - uses VPHYSICS for simulation (используется, например, для мяча) 
MOVETYPE_PUSH - no clip to world, push and crush 
MOVETYPE_NOCLIP - ноклип, можно летать по карте сквозь все объекты 
MOVETYPE_LADDER - Used by players only when going onto a ladder 
MOVETYPE_OBSERVER - Observer movement, depends on player's observer mode 
MOVETYPE_CUSTOM - Allows the entity to describe its own physics 

// Например: 
SetEntityMoveType(client, MOVETYPE_NOCLIP);

if (GetEntityMoveType(client) == MOVETYPE_NONE) 
{ 
     // заморожен 
}
*/

/*
	Выдает рандомного, действительного, живого игрока
	Если игроков меньше 2 (0, 1), возвращает -1
	return int client - индект игрока
*/
stock int AC_GetRandomClient() {
	if (GetClientCount() < 2) return -1;
	int client = -1, count = 0;
	do {
		client = GetRandomInt(1, GetClientCount());
		count++;
	} while (count<32 || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client));
	if (count > 30)return -1;
	return client;
}

stock int AC_GetRandomPlayer() { 
    int[] clients = new int[MaxClients]; 
    int clientCount; 
    for (int i = 1; i <= MaxClients; i++) { 
        if (IsClientInGame(i)) { 
            clients[clientCount++] = i; 
        } 
    } 
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)]; 
}  