#define    SHAKE_START                    0            // Starts the screen shake for all players within the radius. 
#define    SHAKE_STOP                    1            // Stops the screen shake for all players within the radius. 
#define    SHAKE_AMPLITUDE                2            // Modifies the amplitude of an active screen shake for all players within the radius. 
#define    SHAKE_FREQUENCY                3            // Modifies the frequency of an active screen shake for all players within the radius. 
#define    SHAKE_START_RUMBLEONLY        4            // Starts a shake effect that only rumbles the controller, no screen effect. 
#define    SHAKE_START_NORUMBLE        5            // Starts a shake that does NOT rumble the controller. 

// Sounds
stock static char g_BlipSound[PLATFORM_MAX_PATH];
stock static char g_BeepSound[PLATFORM_MAX_PATH];
stock static char g_FinalSound[PLATFORM_MAX_PATH];
stock static char g_BoomSound[PLATFORM_MAX_PATH];
stock static char g_FreezeSound[PLATFORM_MAX_PATH];

// Following are model indexes for temp entities
stock static int g_BeamSprite        = -1;
stock static int g_BeamSprite2       = -1;
stock static int g_ExplosionSprite   = -1;
stock static int g_GlowSprite        = -1;
stock static int g_HaloSprite        = -1;

// Basic color arrays for temp entities
stock static int redColor[4]		= {255, 75, 75, 255};
stock static int orangeColor[4]	= {255, 128, 0, 255};
stock static int greenColor[4]	= {75, 255, 75, 255};
stock static int blueColor[4]	= {75, 75, 255, 255};
stock static int whiteColor[4]	= {255, 255, 255, 255};
stock static int greyColor[4]	= {128, 128, 128, 255};

stock static bool EffectReady = false;

stock void AC_EffectsLoad() {
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if (gameConfig == null)	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}
	
	if (GameConfGetKeyValue(gameConfig, "SoundBlip", g_BlipSound, sizeof(g_BlipSound)) && g_BlipSound[0])
		PrecacheSound(g_BlipSound, true);
	
	if (GameConfGetKeyValue(gameConfig, "SoundBeep", g_BeepSound, sizeof(g_BeepSound)) && g_BeepSound[0])
		PrecacheSound(g_BeepSound, true);
	
	if (GameConfGetKeyValue(gameConfig, "SoundFinal", g_FinalSound, sizeof(g_FinalSound)) && g_FinalSound[0])
		PrecacheSound(g_FinalSound, true);
	
	if (GameConfGetKeyValue(gameConfig, "SoundBoom", g_BoomSound, sizeof(g_BoomSound)) && g_BoomSound[0])
		PrecacheSound(g_BoomSound, true);
	
	if (GameConfGetKeyValue(gameConfig, "SoundFreeze", g_FreezeSound, sizeof(g_FreezeSound)) && g_FreezeSound[0])
		PrecacheSound(g_FreezeSound, true);

	char buffer[PLATFORM_MAX_PATH];
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
		g_BeamSprite = PrecacheModel(buffer);
	
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam2", buffer, sizeof(buffer)) && buffer[0])
		g_BeamSprite2 = PrecacheModel(buffer);
	
	if (GameConfGetKeyValue(gameConfig, "SpriteExplosion", buffer, sizeof(buffer)) && buffer[0])
		g_ExplosionSprite = PrecacheModel(buffer);
	
	if (GameConfGetKeyValue(gameConfig, "SpriteGlow", buffer, sizeof(buffer)) && buffer[0])
		g_GlowSprite = PrecacheModel(buffer);
	
	if (GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
		g_HaloSprite = PrecacheModel(buffer);
	
	delete gameConfig;
	
	EffectReady = true;
}
/*
* FREEZE
*/
stock static int g_FreezeTime[MAXPLAYERS+1] = { 0, ... };

stock void AC_FreezeClient(int client, int time, int color[] = {0, 128, 255, 192}) {
	if (g_FreezeTime[client] != 0) {
		UnfreezeClient(client);
	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);

	if (g_FreezeSound[0]) {
		float vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_FreezeSound, vec, client, SNDLEVEL_RAIDSIREN);
	}
	g_FreezeTime[client] = time;
	CreateTimer(1.0, Timer_Freeze, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

stock void UnfreezeClient(int client) {
	g_FreezeTime[client] = 0;

	if (IsClientInGame(client))	{
		if (g_FreezeSound[0]) {
			float vec[3];
			GetClientAbsOrigin(client, vec);
			vec[2] += 10;	
			
			GetClientEyePosition(client, vec);
			EmitAmbientSound(g_FreezeSound, vec, client, SNDLEVEL_RAIDSIREN);
		}
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

stock Action Timer_Freeze(Handle timer, any client) {
	//int client = value & 0x7f;
	if (!IsClientInGame(client)	|| !IsPlayerAlive(client))	{
		UnfreezeClient(client);
		return Plugin_Stop;
	}
	if (g_FreezeTime[client] == 0) {
		UnfreezeClient(client);
		return Plugin_Stop;
	}

	g_FreezeTime[client]--;
	SetEntityMoveType(client, MOVETYPE_NONE);
	//SetEntityRenderColor(client, 0, 128, 255, 135);

	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	if (g_GlowSprite > -1) {
		TE_SetupGlowSprite(vec, g_GlowSprite, 0.95, 1.5, 50);
		TE_SendToAll();
	}
	else if (g_HaloSprite > -1)	{
		TE_SetupGlowSprite(vec, g_HaloSprite, 0.95, 1.5, 50);
		TE_SendToAll();
	}
	return Plugin_Continue;
}

/*
* BEACON
*/
stock static int g_BeaconTime[MAXPLAYERS+1] = { 0, ... };
stock static int g_BeaconColors[4] =  {255, 255, 255, 255};

stock void AC_CreateBeacon(int client, int time=15, int colors[4] = g_BeaconColors) {
	g_BeaconTime[client] = time;
	g_BeaconColors = colors;
	CreateTimer(1.0, Timer_Beacon, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

stock void AC_KillBeacon(int client) {
	g_BeaconTime[client] = 0;
	/*if (IsClientInGame(client))	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	} */
}

stock Action Timer_Beacon(Handle timer, int client) {
	g_BeaconTime[client]--;
	if (!IsClientInGame(client)	|| !IsPlayerAlive(client) || g_BeaconTime[client] < 1) {
		g_BeaconTime[client] = 0;
		AC_KillBeacon(client);
		return Plugin_Stop;
	}
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 5;
	
	if (g_BeamSprite > -1 && g_HaloSprite > -1)	{
		TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, g_BeaconColors, 5, 0);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, g_BeaconColors, 5, 0);
		
		TE_SendToAll();
	}
	
	if (g_BlipSound[0])	{
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_BlipSound, vec, client, SNDLEVEL_RAIDSIREN);	
	}
	return Plugin_Continue;
}

/*
 * NEON
 */
stock static int g_Neon[MAXPLAYERS+1] = { 0, ... };

stock void AC_RemoveNeon(int client) {
	if(g_Neon[client] > 0 && IsValidEdict(g_Neon[client])) {
		AcceptEntityInput(g_Neon[client], "Kill");
	} g_Neon[client] = 0;
}

stock void AC_SetNeon(int iClient, char color[] = "35 216 48 100", char dist[] = "300") {
	AC_RemoveNeon(iClient);
	float clientOrigin[3], pos[3], beampos[3], FurnitureOrigin[3];
	GetClientAbsOrigin(iClient, clientOrigin);
	GetCollisionPoint(iClient, pos);
	FurnitureOrigin[0] = pos[0];
	FurnitureOrigin[1] = pos[1];
	FurnitureOrigin[2] = (pos[2] + 50);
	beampos[0] = pos[0];
	beampos[1] = pos[1];
	beampos[2] = (FurnitureOrigin[2] + 20);
	int neon = CreateEntityByName("light_dynamic");
	DispatchKeyValue(neon, "brightness", "5");
	DispatchKeyValue(neon, "_light", color);
	DispatchKeyValue(neon, "spotlight_radius", "50");
	DispatchKeyValue(neon, "distance", dist);
	DispatchKeyValue(neon, "style", "0");
	SetEntPropEnt(neon, Prop_Send, "m_hOwnerEntity", iClient);
	if(DispatchSpawn(neon))	{
		AcceptEntityInput(neon, "TurnOn");
		g_Neon[iClient] = neon;
		TeleportEntity(neon, clientOrigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(neon, "SetParent", iClient, neon, 0);
	} else g_Neon[iClient] = 0;
}

stock void GetCollisionPoint(int iClient, float pos[3]) {
	float vOrigin[3], vAngles[3];
	GetClientEyePosition(iClient, vOrigin);
	GetClientEyeAngles(iClient, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return;
	}
	
	CloseHandle(trace);
}

stock bool TraceEntityFilterPlayer(int entity, int contentsMask) {
	return entity > MaxClients;
}

/*
* OTHER
*/
stock void AC_SetSpeed(int client, float mult = 1.0) {
	if(IsValidEntity(client) && HasEntProp(client, Prop_Data, "m_flLaggedMovementValue")) {
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", mult);
	}
}

stock void AC_ShakeScreen(int client, float Amp = 1.0) {
	Handle message = StartMessageOne("Shake", client, 1);
	PbSetInt(message, "command", 0);
	PbSetFloat(message, "local_amplitude", Amp);
	PbSetFloat(message, "frequency", 255.0);
	PbSetFloat(message, "duration", 5.0);
	EndMessage();
}

stock void AC_FadeScreen(int client, int duration = 1000, int hold = 300, int flags=0x0009, int color[4]={0, 0, 0, 255}) { 
    Handle message = StartMessageOne("Fade", client, USERMSG_RELIABLE);
    PbSetInt(message, "duration", duration); 
    PbSetInt(message, "hold_time", hold); 
    PbSetInt(message, "flags", flags); 
    PbSetColor(message, "clr", color); 
    EndMessage(); 
}  