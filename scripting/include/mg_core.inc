#define TAG "[\x07MG\x01]"
#define DEFAULTCOLOR "\x07"

/**
 * Register MiniGame in Core
 *
 * @param identity	String identify this game
 * @param title		String for title game in menus or console output
 * @param color		String for title coloring in chat outputs
 * @return			Game int identity
 */
native int MG_GameReg(char identity[32], char title[42], char color[32]);

/**
 * Unregister MiniGame in Core
 * 
 * @param identity 	Game int indentity returned on Register
 * @return			True on success, false otherwise
 */
native bool MG_GameUnreg(int identity);

/**
 * Confirm start of the game
 * 
 * @param identity 	Game int indentity returned on Register
 * @return			True on success, false otherwise
 */
native bool MG_GameConfirmStart(int identity);


/**
 * Confirm stop of the game
 * 
 * @param identity 	Game int indentity returned on Register
 * @return			True on success, false otherwise
 */
native bool MG_GameConfirmStop(int identity);

/**
 * Return current status of core
 * 1 - Ready for reg games, 0 - don't prepared, -1 - don't reg anytime
 *
 * @param id	Minigame id (-1 if non registerd)	
 * @return	(int)status
 */
native int MG_IsCoreReady(int id);

/**
 * Вызвывается при запуске ядра
 */
forward void MG_OnCoreStart();

/**
 * Вызвывается при отключении или перезагрузке ядра
 */
forward void MG_OnCoreStop();

/**
 * Вызвывается при начале голосования
 */
forward void MG_OnVoteStart();

/**
 * Вызвывается при принудительной остановке голосования
 * (админ командой, или прочих ограничивающих условиях)
 * 
 * @param (int)reason	Причина остановки голосования:
 * 						0 - админ команда, 1 - нехватка игроков, 2 - неопределенный выбор
 */
forward void MG_OnVoteStop(int reason);

/**
 * Вызвывается при окончании голосования с определенным выбором
 */
forward void MG_OnVoteFinish();

/**
 * Вызвывается 
 */
forward void MG_OnGameStart(int id);

/**
 * Вызвывается 
 */
forward void MG_OnGameStop(int id);

/**
 * Вызвывается 
 */
forward void MG_OnGameFinish();