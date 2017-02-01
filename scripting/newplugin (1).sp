public void OnPluginStart() {
	RegConsoleCmd("!menu",menu, "!menu");
}

public Action My_Command(int client, int args) {
	if(!args) { // Проверка были ли введены аргументы, 
	// Если аргументов больше 0, значит args == true,  а значит  !args = false
 		PrintToChat(client, "1 О сервере");
 		PrintToChat(client, "Введите 2 ...");
 		PrintToChat(client, "Введите 3 ...");
	} else {
		if(args == 1) {
			PrintToChat(client, "Текст");
		} else if(args == 2) {
			PrintToChat(client, "Вы ввели 2");
		} else if(args == 2) {
			PrintToChat(client, "Вы ввели 3");
		}
	}
	return Plugin_Handled;
}