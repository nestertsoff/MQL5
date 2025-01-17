#ifndef __TELEGRAM_LIBRARY_MQH__
#define __TELEGRAM_LIBRARY_MQH__

//============================================================================
// Настройки Telegram (замените на ваши реальные данные)
input string TelegramBotToken = "5464398064:AAEesoMFAjWsVR25d09bzLQQR_quLVxDEy0";  // Токен вашего бота
input string TelegramChatID   = "-1002380014192";    // ID чата (или пользовательский ID)
//============================================================================

// Функция для преобразования числа в шестнадцатеричное представление  
// digits – количество цифр в выходной строке (например, 2)
string IntegerToHex(ushort value, int digits)
{
   string hex = "";
   for(int i = digits - 1; i >= 0; i--)
   {
      ushort currentDigit = (value >> (i * 4)) & 0xF;
      char c;
      if(currentDigit < 10)
         c = '0' + currentDigit;
      else
         c = 'A' + (currentDigit - 10);
      hex += c;
   }
   return hex;
}

// Функция URL-энкодинга строки: заменяет спецсимволы на %XX
string UrlEncode(const string s)
{
   string encoded = "";
   int len = StringLen(s);
   for(int i = 0; i < len; i++)
   {
      // Получаем символьный код; приводим к ushort для безопасности
      ushort uc = (ushort)s[i];
      // Разрешённые символы: A-Z, a-z, 0-9
      if((uc >= 65 && uc <= 90) || (uc >= 97 && uc <= 122) || (uc >= 48 && uc <= 57))
         encoded += s[i];
      else
         encoded += "%" + IntegerToHex(uc, 2);
   }
   return encoded;
}

//------------------------------------------------------------------------------
// Функция AlreadySentMessage() возвращает true, если через getUpdates найдется  
// сообщение с таким же текстом, отправленное менее 4 часов назад.
//------------------------------------------------------------------------------
bool AlreadySentMessage(const string message)
{
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/getUpdates";
   
   // Для GET-запроса не передаём данные
   char empty[];
   ArrayResize(empty, 0);
   char result[];
   string errorMessage;
   int timeout = 5000;
   // Вызов WebRequest. Обратите внимание на правильную сигнатуру:

   int res = WebRequest("GET",
                        url,
                        "",
                        timeout,
                        empty,
                        result,
                        errorMessage);
   if(res != 200)
   {
      Print("Error in getUpdates: code=", res, ", Error: ", GetLastError());
      // Если запрос завершился ошибкой, разрешаем отправку (чтобы не блокировать сообщения)
      return false;
   }
   
   // Преобразуем полученный uchar массив в строку
   string response = CharArrayToString(result);
   datetime now = TimeCurrent();
   int pos = 0;
   // Простой поиск вхождений поля "date" в ответе
   while((pos = StringFind(response, "\"date\":", pos)) != -1)
   {
      pos += StringLen("\"date\":");
      int endPos = StringFind(response, ",", pos);
      if(endPos == -1)
         break;
      string dateStr = StringSubstr(response, pos, endPos - pos);
      // Преобразование строки в число с помощью atoi()
      datetime msgDate = (datetime)StringToInteger(dateStr);
      // Если сообщение отправлено менее 4 часов назад
      if(now - msgDate < 4 * 3600)
      {
         // Ищем поле "text" начиная с текущей позиции
         int textPos = StringFind(response, "\"text\":\"", pos);
         if(textPos != -1)
         {
            textPos += StringLen("\"text\":\"");
            int textEnd = StringFind(response, "\"", textPos);
            if(textEnd != -1)
            {
               string msgText = StringSubstr(response, textPos, textEnd - textPos);
               if(msgText == message)
                  return true;
            }
         }
      }
      pos = endPos;
   }
   return false;
}

//------------------------------------------------------------------------------
// Публичная функция TelegramSendMessage() отправляет текстовое сообщение
// в Telegram, если за последние 4 часа не было отправлено сообщение с таким же текстом.
//------------------------------------------------------------------------------
bool TelegramSendMessage(const string message)
{
   // Если сообщение с таким же текстом уже было отправлено за последние 4 часа, не отправляем
   if(AlreadySentMessage(message))
   {
      Print("Сообщение с таким текстом уже отправлено за последние 4 часа.");
      return false;
   }
   
   // Формирование URL для отправки сообщения
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
   // Формируем строку параметров: chat_id и текст (с URL-энкодингом)
   string params = "chat_id=" + TelegramChatID + "&text=" + UrlEncode(message);
   
   // Преобразуем строку параметров в массив uchar (UTF-8)
   uchar post[];
   
   int timeout = 5000;
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   uchar result[];
   string errorMessage;
   // Вызываем WebRequest методом POST.
   int res = WebRequest("POST", url, headers, timeout, post, result, errorMessage);
   if(res != 200)
   {
      Print("Ошибка отправки сообщения: code=", res, ", Error: ", GetLastError());
      return false;
   }
   Print("Сообщение успешно отправлено в Telegram.");
   return true;
}

#endif // __TELEGRAM_LIBRARY_MQH__
