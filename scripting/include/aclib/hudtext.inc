// Написано diller110 для http://hlmod.ru/
// За помощью обращайтесь в тему: %topic_url%

#define HUDChannel_Advert "HUDAdvert"
#define HUDChannel_Admin "HUDAdmin"
#define HUDChannel_Plugin1 "HUDPlugin1"
#define HUDChannel_Plugin2 "HUDPlugin2"
#define HUDChannel_Plugin3 "HUDPlugin3"
#define HUDChannel_Game	"HUDGame"

#define HUDColor_White "255,255,255"
#define HUDColor_Black "0,0,0"
#define HUDColor_Red "255,0,0"
#define HUDColor_Green "0,255,0"
#define HUDColor_Blue "0,0,255"
#define HUDColor_Gray "128,128,128"
#define HUDColor_Aircraft "33,156,197"
#define HUDColor_Yellow "221,221,0"
#define HUDColor_DarkRed "187,0,0"
#define HUDColor_DarkGreen "0,128,0"
#define HUDColor_DarkBlue "0,128,255"
#define HUDColor_Purple "127,3,193"
#define HUDColor_Orange "255,27,20"

enum // HUD Icon
{
	HUDIcon_None = 1,
	HUDIcon_BlackTip = 2,
	HUDIcon_WhiteTip = 3,
	HUDIcon_Arm = 8,
	HUDIcon_Door = 9,
	HUDIcon_Fire = 15,
	HUDIcon_Bind = 17
};

enum // HUD Effects
{
	HUDEffect_Static = 0,
	HUDEffect_Usual = 1,
	HUDEffect_Faster = 2,
	HUDEffect_Slower = 3,
	HUDEffect_Fastest = 4,
	HUDEffect_Blink = 8,
	HUDEffect_TurboBlink = 16,
	HUDEffect_AnotherBlink = 32,
	HUDEffect_Shake = 64,
	HUDEffect_TurboShake = 128
};

stock char icontype[][] =  { 
	"icon_bulb",	"icon_caution",	"icon_alert",
	"icon_alert_red",	"icon_tip",	"icon_skull",
	"icon_no",	"icon_run",	"icon_interact",
	"icon_door",	"icon_arrow_plain",
	"icon_arrow_plain_white_dn",	"icon_arrow_plain_white_up",
	"icon_arrow_up",	"icon_arrow_right",	"icon_fire",
	"icon_present",    "use_binding"
};

/**
 * Print HUD message (ingame frame with icon in middle of screen for tips)
 *
 * Force caption <bool> Show caption text even if hint is occluded by a wall? 0 : No 1 : Show when occluded
 * Onscreen Icon <char> Icon to use when hint is within the player's view.
 * Offscreen Icon <char> Icon to use when hint is outside the player's view.
 * Show offscreen <bool> When hint is offscreen, do we show an icon and arrow? 0 : Show 1 : Don't show
 * Allow invisible target <bool> Allow hint to follow entites with nodraw set? 0 : End immediately on nodraw 1 : Yes
 * Display Range <float> The visible range of the hint. 0 will show it at any distance.
 *
 * @param channel		(char)String identify current msg in HUD stream
 * @param fromclient	(int)Entity to bind HUD, 0 from server(on center)
 * @param toclient 		(int)Entity to display, 0 for all
 * @param message		(char)Text to display
 * @param timeout		(int)Time to display
 * @param icon_type		(int)Icon type 0-17, 17 - bind icon
 * @param color			(char)RGB color (255 0 255) (255,0,255)
 * @param offset		(float)???
 * @param range			(float)Distanse where MSG dissapear, 0 - unlim
 * @param flags			(int)???
 * @param bind			(char)Keys displayed on'use_binding'icon, ex:"+use", "+use;+reload"
 * @param force			(int)Should show MSG even by the wall
 * @noreturn
 */
stock void PrintHudText(char[] channel = HUDChannel_Plugin1, int fromclient = 0, int toclient = 0, char[] message = "",
						int timeout = 5, int icon_type = 4, char[] color = "255,255,255", float offset = 0.0,
						float range = 0.0, int flags = 1, char[] bind = "+moveleft;show_loadout_toggle;+reload;", bool offscreen = true, bool force = true) {
	Event event = CreateEvent("instructor_server_hint_create");
	if (event == INVALID_HANDLE) return;
	event.SetString("hint_name", channel);	event.SetString("hint_replace_key", channel);
	event.SetInt("hint_target", toclient);	event.SetInt("hint_activator_userid", fromclient);
	event.SetInt("hint_timeout", timeout);	event.SetString("hint_icon_onscreen", icontype[icon_type]);
	event.SetString("hint_icon_offscreen", icontype[icon_type]);	event.SetString("hint_caption", message);
	event.SetString("hint_activator_caption", message);	event.SetString("hint_color", color);
	event.SetFloat("hint_icon_offset", offset);	event.SetFloat("hint_range", range);
	event.SetInt("hint_flags", flags);	event.SetString("hint_binding", bind);
	event.SetBool("hint_allow_nodraw_target", true);	event.SetBool("hint_nooffscreen", offscreen);
	event.SetBool("hint_forcecaption", force);	event.SetBool("hint_local_player_only", false);
	event.Fire();
}