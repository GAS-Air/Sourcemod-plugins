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
#define HIDEHUD_RADAR 1 << 12
#define SHOWHUD_RADAR 1 >> 12

bool Started = false, AskStart = false;
int informer[MAXPLAYERS + 1] = {0,...}, g_iTarget1 = -1, g_iTarget2 = -1, id = -1;
bool g_bThirdperson[MAXPLAYERS + 1] = {false, ...}, g_bPumpkin[MAXPLAYERS + 1] = {false, ...};
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
		if(client == g_iTarget1 || client == g_iTarget2) {
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
		do {
			g_iTarget1 = AC_GetRandomPlayer();
			
			if(g_iTarget1 == -1) {
				MG_Stop();
				return; 
			}
		} while (IsFakeClient(g_iTarget1));
		
		do {
			g_iTarget2 = AC_GetRandomPlayer();
			
			if(g_iTarget2 == -1) {
				MG_Stop();
				return; 
			}
		} while (IsFakeClient(g_iTarget2));
		
		for (int i = 0; i <= MaxClients; i++) {
	 		if(AC_IsClientValid(i) && IsPlayerAlive(i)) {
	 			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
	 			CS_RemoveAllWeapons(i);
				GivePlayerItem(i, "weapon_knife");
				if(i != g_iTarget1 || i != g_iTarget2) {
					int type = GetRandomInt(1, 5);
					switch(type){
						case 1:{
							 //chickenbirth
							AC_SetSpeed(i, 1.15);
							PrintToChat(i, "%s У вас повышенная скорость!", TAG);
						}
						case 2:{
							 //ghost
							SetEntityRenderMode(i, RENDER_TRANSCOLOR);
  							SetEntityRenderColor(i, 255,255,255,80);
  							PrintToChat(i, "%s Вы прозрачный УУУУУУ!", TAG);
							
						}
						case 3:{
							//christm
							SetEntProp(i, Prop_Data, "m_iHealth", 1555);
							PrintToChat(i, "%s У вас повышенное здоровье!", TAG);
						}
						case 4:{
							//krolick
							SetEntityGravity(i, 0.9);
							PrintToChat(i, "%s У вас пониженная гравитация!", TAG);
						}
						case 5:{
							//pumphin
							g_bPumpkin[i] = true;
							PrintToChat(i, "%s Вы живете по понятиям, пастухи нет, атакуйте его!", TAG);
						}
					}
					CreateTimer(2.0, Timer_PetyxInform, i);
			 		SetEntityModel(i, CHICKENMODEL);
			 		SetEntProp(i, Prop_Send, "m_nBody", type);
			 		ClientCommand(i, "thirdperson");
					g_bThirdperson[i] = true;
					//PrintToChatAll("%N пастух!", g_iTarget);
				} else {
					AC_SetSpeed(i, 1.15);
					AC_CreateBeacon(i, 25, {240,230,0,255});
					AC_SetNeon(i, "240 230 0 255");
					CreateTimer(2.0, Timer_PastuhInform, i);
					GivePlayerItem(i, "weapon_p90");
					AC_FreezeClient(i, 15);
					SetEntProp(i, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
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
	} while (client == g_iTarget1 || client == g_iTarget2 || client == last);
	if(AC_IsClientReal(client)) {
		FakeClientCommand(client, "say \"ко ко ко\"");
	}
	
	if(count++%4==0 && AC_IsClientReal(g_iTarget1)) {
		FakeClientCommand(g_iTarget1, "say \"цыпа цыпа цыпа\"");
	}
	if(count++%3==0 && AC_IsClientReal(g_iTarget2)) {
		FakeClientCommand(g_iTarget2, "say \"цыпа цыпа цыпа\"");
	}
	return Plugin_Handled;
}

public Action Timer_PetyxInform(Handle timer, int client) {
	static char chan[24], buff[128];
	Format(chan, sizeof(chan), "petyx%d-0", client);
	Format(buff, sizeof(buff), "%N , %N пастухи, они быстрее вас и могут свернуть шею! ко ко ко", g_iTarget1, g_iTarget2);
	PrintHudText(chan, client, client, buff, 6, HUDIcon_Arm, HUDColor_Gray, _, 0.01);
	Format(chan, sizeof(chan), "petyx%d-1", client);
	PrintHudText(chan, client, client, "Вы петушок, убегайте от пастуха! ко ко ко", 6, HUDIcon_Arm, "240,230,0", _, 0.01);
	return Plugin_Handled;
}

public Action Timer_PastuhInform(Handle timer, int client) {
	PrintHudText("pastuh2", client, client, "У вас отключен радар, используйте пастушье чутьё!", 6, HUDIcon_None, HUDColor_White, _, 0.01);
	PrintHudText("pastuh1", client, client, "Вы пастух, ловите цыпочек, зарабатывайте очки!", 6, HUDIcon_Arm, "240,230,0", _, 0.01);
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
	SetEntProp(g_iTarget1, Prop_Send, "m_iHideHUD", SHOWHUD_RADAR);
	SetEntProp(g_iTarget2, Prop_Send, "m_iHideHUD", SHOWHUD_RADAR);
	kokokoTimer = null;
	SetConVarBool(FindConVar("mp_teammates_are_enemies"), false);
	Started = false;
	AskStart = false;
	for (int i = 0; i <= MaxClients; i++) {
		if(AC_IsClientValid(i)) {
			if(g_bPumpkin[i]) {
				SetEntityGravity(i, 1.0);
				g_bPumpkin[i] = false;
			}
			
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
			if(attacker != g_iTarget1 && attacker != g_iTarget2) {
				if(g_bPumpkin[attacker] && (victim == g_iTarget1 || victim == g_iTarget2)) {
					PrintToChatAll("Цыпа %N клюнул пастуха %N", attacker, victim);
					damage = 5.0;
					return Plugin_Changed;
				}
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
				//if (slot == 4 ) return; // Бомба
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}