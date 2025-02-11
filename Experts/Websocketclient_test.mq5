//+------------------------------------------------------------------+
//|                                         Websocketclient_test.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include<WebSocketClient.mqh>

input string Address="127.0.0.1";
input int    Port   =7681;
input bool   ExtTLS =false;
input int    MaxSize=256;
input int Timeout=5000;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string _msg="For the mql5-program to operate, it must be compiled (Compile button or F7 key). Compilation should"
            "pass without errors (some warnings are possible; they should be analyzed). At this process, an"
            "executable file with the same name and with EX5 extension must be created in the corresponding"
            "directory, terminal_dir\\MQL5\\Experts, terminal_dir\\MQL5\\indicators or terminal_dir\\MQL5\\scripts."
            "This file can be run."
            "Operating features of MQL5 programs are described in the following sections:"
            "- Program running – order of calling predefined event-handlers."
            "- Testing trading strategies – operating features of MQL5 programs in the Strategy Tester."
            "- Client terminal events – description of events, which can be processed in programs."
            "- Call of imported functions – description order, allowed parameters, search details and call agreement"
            "for imported functions."
            "· Runtime errors – getting information about runtime and critical errors."
            "Expert Advisors, custom indicators and scripts are attached to one of opened charts by Drag'n'Drop"
            "method from the Navigator window."
            "For an expert Advisor to stop operating, it should be removed from a chart. To do it select 'Expert'"
            "'list' in chart context menu, then select an Expert Advisor from list and click 'Remove' button."
            "Operation of Expert Advisors is also affected by the state of the 'AutoTrading' button."
            "In order to stop a custom indicator, it should be removed from a chart."
            "Custom indicators and Expert Advisors work until they are explicitly removed from a chart;"
            "information about attached Expert Advisors and Indicators is saved between client terminal sessions."
            "Scripts are executed once and are deleted automatically upon operation completion or change of the"
            "current chart state, or upon client terminal shutdown. After the restart of the client terminal scripts"
            "are not started, because the information about them is not saved."
            "Maximum one Expert Advisor, one script and unlimited number of indicators can operate in one chart."
            "Services do not require to be bound to a chart to work and are designed to perform auxiliary functions."
            "For example, in a service, you can create a custom symbol, open its chart, receive data for it in an"
            "endless loop using the network functions and constantly update it."
            "Each script, each service and each Expert Advisor runs in its own separate thread. All indicators"
            "calculated on one symbol, even if they are attached to different charts, work in the same thread."
            "Thus, all indicators on one symbol share the resources of one thread."
            "All other actions associated with a symbol, like processing of ticks and history synchronization, are"
            "also consistently performed in the same thread with indicators. This means that if an infinite action is"
            "performed in an indicator, all other events associated with its symbol will never be performed."
            "When running an Expert Advisor, make sure that it has an actual trading environment and can access"
            "the history of the required symbol and period, and synchronize data between the terminal and the"
            "server. For all these procedures, the terminal provides a start delay of no more than 5 seconds, after"
            "which the Expert Advisor will be started with available data. Therefore, in case there is no connection"
            "to the server, this may lead to a delay in the start of an Expert Advisor.";
//---
CWebSocketClient wsc;
//---
int sent=-1;
uint received=-1;
//---
// string subject,issuer,serial,thumbprint;
//---
// datetime expiration;
//---
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(2);
//---
   wsc.SetMaxSendSize(MaxSize);
//---
   if(wsc.Connect(Address,Port,Timeout,ExtTLS,true))
     {
      sent=wsc.SendString(_msg);
      //--
      Print("sent data is "+IntegerToString(sent));
      //---
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   Print("Deinit call");
   wsc.Close();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(wsc.Readable()>0)
     {
      CFrame msg_frames[];
      received=wsc.Read(msg_frames);
      if(received>0)
        {
         int ll=ArraySize(msg_frames);
         Print("number of received frames is "+IntegerToString(ll));
         for(int i=0; i<ll; i++)
           {
            Print(msg_frames[i].ToString());
           }

         if(msg_frames[ll-1].IsFinal())
           {
            Print("\n Final frame received");
            wsc.Close(NORMAL_CLOSE,"good bye");
            ExpertRemove();
           }
        }
     }
   else
     {
      Print("\n Nothing readable in socket");
      if(wsc.ClientState()!=CONNECTED)
        {
         Print("\n Client disconnected");
         ExpertRemove();
        }
     }
  }
//+------------------------------------------------------------------+ 
//+------------------------------------------------------------------+
