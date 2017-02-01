/*
public void OnPluginStart() {
	RegConsoleCmd("!menu",menu, "!menu");
}

<<<<<<< HEAD
{public void OnPluginStart()

    RegConsoleCmd("sm_menu", Cmd_MyMeny);
    int a int b
    PrintToChat(a=1, "1Доступные команды сервера");
     PrintToChat(a=2, "2Личный кабинет");
     PrintToChat(a=3, "3Контакты сервера");
     PrintToChat(a=4, "4 О сервере");
     {
    if a=1 do 
     PrintToChat(b = 1"1!mg"); //Начало скрипта по открытию команд
     PrintToChat(b = 2"2!rankm");
    PrintToChat(b = 3"3!ac");
    PrintToChat(b = 4"4!rq");
     PrintToChat(b = 5"5!rq");
    PrintToChat(b = 6"6!admins");
    if b=1 do 
    PrintToChat("текст");
    if b=2 do 
    PrintToChat("текст");
    if b = 3 do
    PrintToChat("текст");
    if b=4 do
    PrintToChat("текст");
    if b=5 do 
    PrintToChat("текст");
    if b=6 do 
    PrintToChat("текст");
   }
}
*/

// 1. У тебя два  OnPluginStart()
 
public void OnPluginStart() { // Эта функция запускается 1 раз во время старта плагина.
	RegConsoleCmd("sm_menu", Cmd_MyMenu); // Регистрируем команду, и указываем какую функцию запускать, при её вводе.
}

public Action Cmd_MyMenu(int client, int args) { // Почему так, читать в документации https://sm.alliedmods.net/new-api/console/ConCmd
// Итак, человек ввел команду которую мы регистрировали, запустилась эта функция.
// Он ввел sm_menu, сервер запустил функцию Cmd_MyMenu. Только тогда, больше эта функция не запускается.
// И больше никто кроме этой функции не знает что игрок ввел эту команду.
// Итаааак, теперь нам нужно понять, что хотел игрок, получаем кол-во аргументов.

	if(args == 0) { // Аргументов не было, игрок просто хочет узнать что за команда
		PrintToChat(client, "1 - Доступные команды сервера");
		PrintToChat(client, "2 - Личный кабинет");
		PrintToChat(client, "3 - Контакты сервера");
		PrintToChat(client, "4 - О сервере");
	} else {
		// Тут мы знаем, что аргумент введен, игрок чего-то хочет, узнаем что:
		char buff[16]; 
		GetCmdArg(1, buff, sizeof(buff)); // Вот о функции https://sm.alliedmods.net/new-api/console/GetCmdArg
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