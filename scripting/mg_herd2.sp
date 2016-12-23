#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <mg_core>
#include <sdkhooks>
#include <aclib>

#define IDENT "herd"
#define TITLE "Пастух"
#define COLOR "\x09"
#define RANK_REWARD 100
#define CHICKENMODEL "models/chicken/chicken.mdl"

bool Started = false, AskStart = false;
int informer[MAXPLAYERS + 1] = {0,...}, g_iTarget = -1, id = -1;
bool g_bThirdperson[MAXPLAYERS + 1] = {false, ...};
Handle kokokoTimer;

public Plugin myinfo = {
	name = "MiniGames: Chickenherd", author = "Aircraft", 
	description = "Herd catch chickens", version = "1.0"
};

public void OnPluginStart() {
	kokokoTimer = null;
	SetConVarBool(FindConVar("sv_allow_thirdperson"), true);
	RegConsoleCmd("sm_herdtest", Cmd_Herdtest);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	if(MG_IsCoreReady(id) && id==-1) {
		PrintToChatAll("%s Мини-игра %s%s\x01 загружена! (late)", TAG, COLOR, TITLE);
		id = MG_GameReg(IDENT, TITLE, COLOR);	
	}
}

public void OnPluginEnd(){
	PrintToChatAll("%s Мини-игра %s%s\x01 выключается.", TAG, COLOR, TITLE);
	if (Started)MG_Stop(_);
	if(id!=-1) MG_GameUnreg(id);
}

public void OnConfigsExecuted(){
  PrecacheModel(CHICKENMODEL, true);
}

//***********
// Events
//***********
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(AC_IsClientValid(client)) SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if(IsClientInGame(client) && g_bThirdperson[client]) {
		ClientCommand(client, "firstperson");
		
	}
	if(Started) {
		if(client == g_iTarget) {
			AC_RemoveNeon(client);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(AskStart){
		Started = true;
		AskStart = false;
		PrintToChatAll("%s Мини-игра \"%s%s\x01\" начинается!", TAG, COLOR, TITLE);
	}
	if(Started) {
		SetConVarBool(FindConVar("mp_teammates_are_enemies"), true);
		g_iTarget = AC_GetRandomPlayer();
		if(g_iTarget == -1) {
			MG_Stop();
			return;
		}
		for (int i = 0; i <= MaxClients; i++) {
	 		if(AC_IsClientValid(i) && IsPlayerAlive(i)) {
	 			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
	 			CS_RemoveAllWeapons(i);
				GivePlayerItem(i, "weapon_knife");
				if(i != g_iTarget) {
					CreateTimer(2.0, Timer_PetyxInform, i);
			 		SetEntityModel(i, CHICKENMODEL);
			 		SetEntProp(i, Prop_Send, "m_nBody", GetRandomInt(1, 5));
			 		ClientCommand(i, "thirdperson");
					g_bThirdperson[i] = true;
					//PrintToChatAll("%N пастух!", g_iTarget);
				} else {
					AC_SetSpeed(i, 1.3);
					AC_CreateBeacon(i, 25, {240,230,0,255});
					AC_SetNeon(i, "240 230 0 255");
					CreateTimer(2.0, Timer_PastuhInform, i);
					GivePlayerItem(i, "weapon_p90");
					AC_FreezeClient(i, 5);
				}
	 		}
		}
		kokokoTimer = CreateTimer(5.0, Timer_KokokoTimer, _, TIMER_REPEAT);
	}
}

public Action Timer_KokokoTimer(Handle timer, any data) {
	//PrintToChatAll("kokokoTimer: %d", kokokoTimer);
	if (kokokoTimer == null)return Plugin_Stop;
	int client = -1;
	static int last = 0;
	static int count = 0;
	//PrintToChatAll("client: %d count: %d", client, count);
	do {
		client = AC_GetRandomPlayer();
		//PrintToChatAll("AC_GetRandomPlayer(): %d", client);
		if (client == -1) {
			kokokoTimer = null;
			return Plugin_Stop;
		}	
	} while (client == g_iTarget || client == last);
	
	if(AC_IsClientReal(client)) {
		FakeClientCommand(client, "say \"ко ко ко\"");
	}
	
	if(count++%3==0 && AC_IsClientReal(g_iTarget)) {
		FakeClientCommand(g_iTarget, "say \"цыпа цыпа цыпа\"");
	}
	return Plugin_Handled;
}

public Action Timer_PetyxInform(Handle timer, int client) {
	static char chan[24], buff[128];
	Format(chan, sizeof(chan), "petyx%d-0", client);
	Format(buff, sizeof(buff), "%N пастух, он быстрее вас и может свернуть шею! ко ко ко", g_iTarget);
	PrintHudText(chan, client, client, buff, 6, HUDIcon_Arm, HUDColor_Gray, _, 0.01);
	Format(chan, sizeof(chan), "petyx%d-1", client);
	PrintHudText(chan, client, client, "Вы петушок, убегайте от пастуха! ко ко ко", 6, HUDIcon_Arm, "240,230,0", _, 0.01);
	return Plugin_Handled;
}

public Action Timer_PastuhInform(Handle timer, int client) {
	PrintHudText("pastuh", client, client, "Вы пастух, ловите цыпочек, зарабатывайте очки!", 6, HUDIcon_Arm, "240,230,0", _, 0.01);
	return Plugin_Handled;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	if(Started) {
		MG_Stop(_);
	}
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Started){
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
		CS_StripButKnife(client);
	}	
	return Plugin_Continue;
}

//***********
// MiniGames
//***********
public Action Cmd_Herdtest(int client, int args){
	SetEntityModel(client, CHICKENMODEL);
	SetEntProp(client, Prop_Send, "m_nBody", 3);
	ClientCommand(client, "thirdperson");
	g_bThirdperson[client] = true;
	return Plugin_Handled;
}

public void MG_OnCoreStart(){
	if(MG_IsCoreReady(id) && id==-1){
		id = MG_GameReg(IDENT, TITLE, COLOR);
		PrintToChatAll("%s Мини-игра %s%s\x01 загружена! (ontime)", TAG, COLOR, TITLE);
	}
}

public void MG_OnCoreStop(){
	MG_Stop();
	id = -1;
	PrintToChatAll("%s Мини-игра %s%s\x01 из-за отключения ядра.", TAG, COLOR, TITLE);
}

public void MG_OnGameStart(int identity){
	if(id == identity){
		AskStart = true;
		MG_GameConfirmStart(id);
	}
}

public void MG_OnGameStop(int identity){
	if(id == identity){
		MG_Stop();
		PrintToChatAll("%s Мини-игра %s%s\x01 остановлена!", TAG, COLOR, TITLE);
	}
}

stock void MG_Stop(int reward = 0){
	kokokoTimer = null;
	SetConVarBool(FindConVar("mp_teammates_are_enemies"), false);
	Started = false;
	AskStart = false;
	for (int i = 0; i <= MaxClients; i++) {
		if(AC_IsClientValid(i)) {
			ClientCommand(i, "firstperson");
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	MG_GameConfirmStop(id);
}

public Action OnWeaponCanUse(int client, int weapon) {
	if(Started) {
		char sWeapon[32];
		sWeapon[0] = '\0';
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "weapon_taser", false) || StrEqual(sWeapon, "weapon_knife", false)) {
			return Plugin_Continue;
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(Started && AC_IsClientValid(victim)) {
		if(AC_IsClientValid(attacker)) {
			if(attacker != g_iTarget) {
				PrintToChat(attacker, "%s Вы не можете атаковать цель во время %sПастуха.", TAG, COLOR);
				return Plugin_Stop;
			} else {
				PrintToChatAll("Пастух %N поймал петушка %N", attacker, victim);
				damage = 777.0;
				return Plugin_Changed;
			}
			
		}
	}
	return Plugin_Handled;
}

public Action CS_OnBuyCommand(int client, const char[] weapon) {
	if(Started){
		if (!IsFakeClient(client) && (GetTime()-informer[client])>3) {
			informer[client] = GetTime();
			PrintToChat(client, "%s Вы не можете покупать во время %s%s.", TAG, COLOR, TITLE);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


//********
// STOCKS
//********
stock bool CS_StripButKnife(int client, bool equip=true){
    if (!IsClientInGame(client) || GetClientTeam(client) <= 1) return false;
    int item_index;
    for (int i = 0; i < 5; i++) {
        if (i == 2) continue;
        if ((item_index = GetPlayerWeaponSlot(client, i)) != -1) {
            RemovePlayerItem(client, item_index);
            RemoveEdict(item_index);
        }
        if(equip) ClientCommand(client, "slot3");
    }
    return true;
}

stock void CS_RemoveAllWeapons(int client) {
	int weapon_index = -1;
	for (int slot = 0; slot < 6; slot++)	{
		while ((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1) {
			if (IsValidEntity(weapon_index)) {
				if (slot == 4 ) return; // Бомба
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}