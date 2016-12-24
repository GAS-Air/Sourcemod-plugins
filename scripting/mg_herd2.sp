#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <mg_core>
#include <sdkhooks>
#include <aclib>
#include <cstrike>

#define IDENT "herd"
#define TITLE "Пастух"
#define COLOR "\x09"
#define RANK_REWARD 100
#define CHICKENMODEL "models/chicken/chicken.mdl"
#define HIDEHUD_RADAR 1 << 12
#define SHOWHUD_RADAR 1 >> 12

bool Started = false, AskStart = false;
int informer[MAXPLAYERS + 1] = {0,...}, id = -1;
bool g_bThirdperson[MAXPLAYERS + 1] = {false, ...}, g_bPumpkin[MAXPLAYERS + 1] = {false, ...};
Handle kokokoTimer;
KeyValues kvRating;
char confPath[256];
float Rating[5];
char RatingNames[5][32];
float StartTime = 0.0;
Menu RatingMenu;

// Targets
int g_iTarget1 = -1, g_iTarget2 = -1, 
	TargetCount1 = 0, TargetCount2 = 0;
StringMap smTags;


public Plugin myinfo = {
	name = "MiniGames: Chickenherd", author = "Aircraft", 
	description = "Herd catch chickens", version = "1.0"
};

public void OnPluginStart() {
	kokokoTimer = null;
	smTags = new StringMap();
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
	LoadKv();
}

public void LoadKv() {
	BuildPath(Path_SM, confPath, sizeof(confPath), "/configs/mg_herd2.txt");
	kvRating = new KeyValues("mg_herd2");
	kvRating.ImportFromFile(confPath);
	char buff[6];
	for (int i = 0; i < sizeof(Rating); i++) {
		Format(buff, sizeof(buff), "%d", i);
		Rating[i] = kvRating.GetFloat(buff, -0.0);
		Format(buff, sizeof(buff), "0%d", i);
		kvRating.GetString(buff, RatingNames[i], sizeof(RatingNames[]), "null");
		if(StrEqual(RatingNames[i], "")) {
			RatingNames[i] = "null";
		}
	}
}

public void UnloadKv() {
	kvRating.Rewind();
	char buff[6];
	for (int i = 0; i < sizeof(Rating); i++) {
		Format(buff, sizeof(buff), "%d", i);
		kvRating.SetFloat(buff, Rating[i]);
		Format(buff, sizeof(buff), "0%d", i);
		PrintToServer("%f %s", Rating[i], RatingNames[i]);
		if(StrEqual(RatingNames[i], "")) {
			RatingNames[i] = "null";
		}
		kvRating.SetString(buff, RatingNames[i]);
	}
	kvRating.ExportToFile(confPath);
	kvRating.Close();
}

public void OnPluginEnd(){
	PrintToChatAll("%s Мини-игра %s%s\x01 выключается.", TAG, COLOR, TITLE);
	if (Started)MG_Stop(_);
	if(id!=-1) MG_GameUnreg(id);
	UnloadKv();
}

public void OnConfigsExecuted(){
  PrecacheModel(CHICKENMODEL, true);
}

//***********
// Events
//***********
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(AC_IsClientValid(client)) SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if(IsClientInGame(client) && g_bThirdperson[client]) {
		ClientCommand(client, "firstperson");
	}
	if(Started) {
		static int count = 0;
		for (int i = 1; i < MaxClients; i++) {
			if(AC_IsClientValid(i) && IsPlayerAlive(i)) {
				count++;
			}
		}
		if(count==2 && (IsClientInGame(g_iTarget1) && IsClientInGame(g_iTarget2) && IsPlayerAlive(g_iTarget1) && IsPlayerAlive(g_iTarget2))) {
			CS_TerminateRound(8.0, CSRoundEnd_VIPKilled, false);
		}
		count = 0;
		if(client == g_iTarget1 || client == g_iTarget2) {
			AC_RemoveNeon(client);
		} else {
			if(attacker) {
				if (attacker == g_iTarget1)TargetCount1++;
				if (attacker == g_iTarget2)TargetCount2++;
			} 
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
		StartTime = GetGameTime();
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
		} while (g_iTarget1 != g_iTarget2 && IsFakeClient(g_iTarget2));
		
		for (int i = 0; i <= MaxClients; i++) {
	 		if(AC_IsClientValid(i) && IsPlayerAlive(i)) {
	 			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
	 			CS_RemoveAllWeapons(i);
				GivePlayerItem(i, "weapon_knife");
				if(i != g_iTarget1 && i != g_iTarget2) {
					int type = GetRandomInt(1, 5);
					switch(type) {
						case 1: { //chickenbirth
							AC_SetSpeed(i, 1.15);
							PrintToChat(i, "%s У вас повышенная скорость!", TAG);
						}
						case 2: { //ghost
							SetEntityRenderMode(i, RENDER_TRANSCOLOR);
  							SetEntityRenderColor(i, 255,255,255,80);
  							PrintToChat(i, "%s Вы прозрачный УУУУУУ!", TAG);
						}
						case 3: { //christm
							SetEntProp(i, Prop_Data, "m_iHealth", 1555);
							PrintToChat(i, "%s У вас повышенное здоровье!", TAG);
						}
						case 4: { //krolick
							SetEntityGravity(i, 0.9);
							PrintToChat(i, "%s У вас пониженная гравитация!", TAG);
						}
						case 5: { //pumphin
							g_bPumpkin[i] = true;
							PrintToChat(i, "%s Вы живете по понятиям, пастухи нет, атакуйте его!", TAG);
						}
					}
					CreateTimer(2.0, Timer_PetyxInform, i);
			 		SetEntityModel(i, CHICKENMODEL);
			 		SetEntProp(i, Prop_Send, "m_nBody", type);
			 		ClientCommand(i, "thirdperson");
					g_bThirdperson[i] = true;
				} else {
					char buff[32], buff2[6];
					CS_GetClientClanTag(i, buff, sizeof(buff));
					Format(buff2, sizeof(buff2), "%d-1", GetClientUserId(i));
					smTags.SetString(buff2, buff, true);
					GetClientName(i, buff, 32);
					Format(buff2, sizeof(buff2), "%d-2", GetClientUserId(i));
					smTags.SetString(buff2, buff, true);
					CS_SetClientClanTag(i, "ПАСТУХ");
					AC_SetSpeed(i, 1.15);
					AC_CreateBeacon(i, 10, {240,230,0,255});
					AC_SetNeon(i, "240 230 0 255");
					CreateTimer(2.0, Timer_PastuhInform, i);
					GivePlayerItem(i, "weapon_p90");
					AC_FreezeClient(i, 13);
					SetEntProp(i, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
				}
	 		}
		}
		kokokoTimer = CreateTimer(5.0, Timer_KokokoTimer, _, TIMER_REPEAT);
	}
}

public Action Timer_KokokoTimer(Handle timer, any data) {
	if (kokokoTimer == null)return Plugin_Stop;
	int client = -1;
	static int last = 0, count = 0;
	do {
		client = AC_GetRandomPlayer();
		if (client == -1) {
			kokokoTimer = null;
			return Plugin_Stop;
		}	
	} while (client == g_iTarget1 || client == g_iTarget2 || client == last);
	if(AC_IsClientReal(client)) {
		FakeClientCommand(client, "say \"ко ко ко\"");
	}
	
	if(count++%3==0 && AC_IsClientReal(g_iTarget1)) {
		FakeClientCommand(g_iTarget1, "say \"цыпа цыпа цыпа\"");
	}
	if(count++%7==0 && AC_IsClientReal(g_iTarget2)) {
		FakeClientCommand(g_iTarget2, "say \"цыпа цыпа цыпа\"");
	}
	return Plugin_Handled;
}

public Action Timer_PetyxInform(Handle timer, int client) {
	static char chan[24], buff[128];
	Format(chan, sizeof(chan), "petyx%d-0", client);
	Format(buff, sizeof(buff), "%N и %N пастухи", g_iTarget1, g_iTarget2);
	PrintHudText(chan, client, client, buff, 6, HUDIcon_Arm, HUDColor_Yellow, _, 0.01);
	Format(chan, sizeof(chan), "petyx%d-1", client);
	PrintHudText(chan, client, client, "Пастухи, они быстрее вас и могут свернуть шею! ко ко ко", 6, HUDIcon_Arm, HUDColor_Gray, _, 0.01);
	Format(chan, sizeof(chan), "petyx%d-2", client);
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
		MG_Stop(1);
	}
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Started){
		ShowMOTDPanel(client, "Chicken", "http://aircr.ru/mg-chicken.php", MOTDPANEL_TYPE_URL);
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
	/* Для тестов */
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

public void MG_OnGameStart(int identity) {
	if(id == identity){
		AskStart = true;
		MG_GameConfirmStart(id);
	}
}

public void MG_OnGameStop(int identity) {
	if(id == identity)
		MG_Stop();
}

/*
 * type - причина остановки мини-игры.
 * 		0 - принудительно
 *		1 - игра успешно завершена
 */
stock void MG_Stop(int type = 0) {
	Started = false;
	AskStart = false;
	char buff2[6], nick[32], buff[256];
	if(type == 1) {
		float time = GetGameTime() - StartTime;
		float scores1, scores2 = 0.0;
		scores1 = TargetCount1 * 100 / time;
		scores2 = TargetCount2 * 100 / time;
		for (int i = 0; i < sizeof(Rating); i++) {
			if(scores1 >= Rating[i]) {
				GetClientName(g_iTarget1, nick, sizeof(nick));
				for (int i2 = sizeof(Rating)-1; i2 > 0; i2--){
					Rating[i2] = Rating[i2-1];
					strcopy(RatingNames[i2], sizeof(RatingNames[]), RatingNames[i2-1]);
				}
				Rating[i] = scores1;
				Format(buff2, sizeof(buff2), "%d-2", GetClientUserId(g_iTarget1));
				if(smTags.GetString(buff2, buff, sizeof(buff))) {
					strcopy(RatingNames[i], sizeof(RatingNames[]), buff);
				} else {
					strcopy(RatingNames[i], sizeof(RatingNames[]), nick);
				}
				break;
			}
		}
		for (int i = 0; i < sizeof(Rating); i++) {
			if(scores2 >= Rating[i]) {
				GetClientName(g_iTarget2, nick, sizeof(nick));
				for (int i2 = sizeof(Rating)-1; i2 > 0; i2--){
					Rating[i2] = Rating[i2-1];
					strcopy(RatingNames[i2], sizeof(RatingNames[]), RatingNames[i2-1]);
				}
				Rating[i] = scores2;
				Format(buff2, sizeof(buff2), "%d-2", GetClientUserId(g_iTarget2));
				if(smTags.GetString(buff2, buff, sizeof(buff))) {
					strcopy(RatingNames[i], sizeof(RatingNames[]), buff);
				} else {
					strcopy(RatingNames[i], sizeof(RatingNames[]), nick);
				}
				break;
			}
		}
		RatingMenu = new Menu(MenuHandler_None);
		RatingMenu.SetTitle("Мини-игра \"Пастух\"");
		RatingMenu.ExitButton = false;
		RatingMenu.ExitBackButton = false;
		
		Format(buff, sizeof(buff), "%15N: %d кур(ы)", g_iTarget1, TargetCount1);
		RatingMenu.AddItem("", buff);
		Format(buff, sizeof(buff), "%15N: %d кур(ы)", g_iTarget2, TargetCount2);
		RatingMenu.AddItem("", buff);
		buff[0] = '\0';
		for (int i = 0; i < sizeof(Rating); i++) {
			Format(buff, sizeof(buff), "%s\n%d. %15s: %.3f кур/мин", buff, i+1, RatingNames[i], Rating[i]);
		}
		RatingMenu.AddItem("", buff, ITEMDRAW_DISABLED);
		
		for (int i = 0; i < MaxClients; i++) {
			if(AC_IsClientReal(i))
				RatingMenu.Display(i, 10);
		}	
	}
	if(AC_IsClientValid(g_iTarget1)) {
		SetEntProp(g_iTarget1, Prop_Send, "m_iHideHUD", SHOWHUD_RADAR);
		Format(buff2, sizeof(buff2), "%d-1", GetClientUserId(g_iTarget1));
		if(smTags.GetString(buff2, buff, sizeof(buff))) {
			CS_SetClientClanTag(g_iTarget1, buff);
		}
	}
	if(AC_IsClientValid(g_iTarget2)) {
		SetEntProp(g_iTarget2, Prop_Send, "m_iHideHUD", SHOWHUD_RADAR);
		Format(buff2, sizeof(buff2), "%d-1", GetClientUserId(g_iTarget2));
		if(smTags.GetString(buff2, buff, sizeof(buff))) {
			CS_SetClientClanTag(g_iTarget2, buff);
		}
	}
	TargetCount1 = TargetCount2 = 0;
	g_iTarget1 = g_iTarget2 = -1;
	kokokoTimer = null;
	SetConVarBool(FindConVar("mp_teammates_are_enemies"), false, false, false);
	for (int i = 0; i <= MaxClients; i++) {
		if(AC_IsClientValid(i)) {
			if(g_bPumpkin[i]) {
				SetEntityGravity(i, 1.0);
				g_bPumpkin[i] = false;
			}
			ShowMOTDPanel(i, "Chicken", "0", MOTDPANEL_TYPE_URL);
			ClientCommand(i, "firstperson");
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
		}
	}
	PrintToChatAll("%s Мини-игра %s%s\x01 остановлена!", TAG, COLOR, TITLE);
	MG_GameConfirmStop(id);
}

public int MenuHandler_None(Menu menu, MenuAction action, int param1, int param2) {
	return;
}

public Action OnWeaponCanUse(int client, int weapon) {
	if(Started) {
		char sWeapon[32];
		sWeapon[0] = '\0';
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "weapon_knife", false) || StrEqual(sWeapon, "weapon_taser", false)) {
			return Plugin_Continue;
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(Started && AC_IsClientValid(victim) && AC_IsClientValid(attacker)) {
		if(attacker != g_iTarget1 && attacker != g_iTarget2) {
			if(g_bPumpkin[attacker] && (victim == g_iTarget1 || victim == g_iTarget2)) {
				PrintToChatAll("%s \x01Цыпа %s%N \x01клюнул пастуха %s%N.", TAG, COLOR, attacker, COLOR, victim);
				damage = 5.0;
				return Plugin_Changed;
			}
			PrintToChat(attacker, "%s Вы не можете атаковать цель во время %sПастуха.", TAG, COLOR);
			return Plugin_Stop;
		} else {
			if (victim == g_iTarget1 || victim == g_iTarget2)	return Plugin_Stop;
			PrintToChatAll("%s \x01Пастух %s%N \x01поймал петушка %s%N.", TAG, COLOR, attacker, COLOR, victim);
			damage = 777.0;
			return Plugin_Changed;
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