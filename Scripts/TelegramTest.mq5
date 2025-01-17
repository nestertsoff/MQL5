#include <SendToTelegram.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
  //------------------------------------------------------------------  

  TelegramSendMessage("Test");
  TelegramSendMessage("Test");
  TelegramSendMessage("Test");
  TelegramSendMessage("Test Unique " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
  TelegramSendMessage("Test Unique " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
  TelegramSendMessage("Test Unique " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
   
  }
//+------------------------------------------------------------------+
