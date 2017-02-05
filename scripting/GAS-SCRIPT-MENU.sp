
public Plugin:myinfo = 
{
	name = "Menu",
	author = "GAS",
	description = "Мой первый плагин меню",
	version ="1.0.0",
	url = "https://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins"
}; 
public void OnPluginStart() { 
	RegConsoleCmd("sm_menu", Cmd_MyMenu); 
}

public Action Cmd_MyMenu(int client, int args) { 


	if(args == 0) { 
		PrintToChat(client, "1 - Доступные команды сервера");
		PrintToChat(client, "2 - Личный кабинет");
		PrintToChat(client, "3 - Контакты сервера");
		PrintToChat(client, "4 - О сервере");
	} else {
		
		char buff[16]; 
		GetCmdArg(1, buff, sizeof(buff)); 
		int choise = StringToInt(buff);
		switch(choise) {
			case 1: {
				PrintToChat(client, "1!mg");
			}
			case 2: { 
				PrintToChat(client, "2!rankm");
			}
			case 3: {
				PrintToChat(client, "3!ac");
	        }
	   	}
	}
}