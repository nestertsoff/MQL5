//+------------------------------------------------------------------+
//|                                                    MyEA.mq5      |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

/*******************************************************
 * 1) Include your CJAVal-based JSON library
 *    (which you provided as json.mqh)
 *******************************************************/
#include <json.mqh>   // Make sure this file has the entire CJAVal code

//--- EA Inputs
input string          ApiUrl       = "http://127.0.0.1:5231";
input string          SymbolsList  = "BTCUSD,ETHUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,NZDUSD,USDCHF,USDCAD,EURGBP,EURJPY,GBPJPY,CHFJPY,AUDJPY,AUDNZD,CADJPY,EURCAD,EURAUD,GBPCAD,GBPAUD,NZDJPY,AUDCAD,XAUUSD,XAGUSD";
input ENUM_TIMEFRAMES Timeframe    = PERIOD_H4;
input int             CandlesLimit = 600;

//--- Derived URLs
string processClosedCandlesApiUrl;
string processCurrentCandlesApiUrl;

//--- Global connectivity flag
bool isConnected = false;

//+------------------------------------------------------------------+
//| Forward Declarations                                             |
//+------------------------------------------------------------------+
void     GetSymbolsArray(string &dest[]);
int      TimeframeToMinutes(ENUM_TIMEFRAMES tf);
string   FormatJson(const string symbol, int timeframeInMinutes, MqlRates &rates[]);
string   FormatCurrentCandleJson(const string symbol, int timeframeInMinutes, const MqlRates &rate);
string   CreateMultiSymbolCurrentCandleJson(string &symbols[], int timeframeInMinutes);
void     SendDataToApi(const string apiUrl, const string jsonData);
void     SendClosedCandles(const string symbol, const string apiUrl, int offset, int count, bool logMessage=false);
void     SendInitialData();
void     SendCurrentCandleData();
void     DrawLabelOnChart(const string symbol, const bool connectedState);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Build final URLs
   processClosedCandlesApiUrl  = ApiUrl + "/process-closed-candles";
   processCurrentCandlesApiUrl = ApiUrl + "/process-current-candles";

   // Set a timer to call OnTimer() every 10 seconds
   EventSetTimer(10);

   // Send initial (historical) data
   SendInitialData();

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| OnTimer: check new bars, send updates                            |
//+------------------------------------------------------------------+
void OnTimer()
{
   static datetime lastBarTimes[]; // Tracks the last bar time for each symbol

   // Get symbol list
   string symbols[];
   GetSymbolsArray(symbols);

   // Initialize lastBarTimes if needed
   if(ArraySize(lastBarTimes) == 0)
   {
      ArrayResize(lastBarTimes, ArraySize(symbols));
      ArrayFill(lastBarTimes, 0, ArraySize(lastBarTimes), (datetime)0);
   }

   // Check each symbol for a new bar
   for(int i = 0; i < ArraySize(symbols); i++)
   {
      string   symbol         = symbols[i];
      datetime currentBarTime = iTime(symbol, Timeframe, 0);

      if(currentBarTime > lastBarTimes[i])
      {
         lastBarTimes[i] = currentBarTime;
         Print("New bar detected for ", symbol);

         // Send closed-candle data (including newly closed bar)
         SendClosedCandles(symbol, processClosedCandlesApiUrl, 0, CandlesLimit);
      }
   }

   // Always send the current candle data for all symbols
   SendCurrentCandleData();
}

//+------------------------------------------------------------------+
//| 1) Get array of symbols from input string                        |
//+------------------------------------------------------------------+
void GetSymbolsArray(string &dest[])
{
   // Splits the comma-separated SymbolsList into a string array
   StringSplit(SymbolsList, ',', dest);
}

//+------------------------------------------------------------------+
//| 2) Convert ENUM_TIMEFRAMES to minutes                            |
//+------------------------------------------------------------------+
int TimeframeToMinutes(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:   return 1;
      case PERIOD_M5:   return 5;
      case PERIOD_M15:  return 15;
      case PERIOD_M30:  return 30;
      case PERIOD_H1:   return 60;
      case PERIOD_H4:   return 240;
      case PERIOD_D1:   return 1440;
      case PERIOD_W1:   return 10080;
      case PERIOD_MN1:  return 43200;
      default:          return 0; // Unknown timeframe
   }
}

//+------------------------------------------------------------------+
//| 3) Format JSON for closed candles using CJAVal                   |
//+------------------------------------------------------------------+
string FormatJson(const string symbol, int timeframeInMinutes, MqlRates &rates[])
{
   // Create a root CJAVal object (an 'object' type)
   CJAVal root;
   root.m_type = jtOBJ;

   // root["symbol"] = symbol
   CJAVal *pSymbol = root["symbol"];
   *pSymbol        = symbol; // operator= (string)

   // root["timeframeInMinutes"] = timeframeInMinutes
   CJAVal *pTfMins = root["timeframeInMinutes"];
   *pTfMins        = (int)timeframeInMinutes; // operator= (int)

   // Create an array CJAVal for "closedCandles"
   CJAVal closedCandles;
   closedCandles.m_type = jtARRAY;

   // Build each candle sub-object
   for(int i=0; i<ArraySize(rates); i++)
   {
      CJAVal candle;
      candle.m_type = jtOBJ;

      // candle["time"] = TimeToString(...)
      *(candle["time"])  = TimeToString(rates[i].time);
      *(candle["open"])  = DoubleToString(rates[i].open,  6);
      *(candle["high"])  = DoubleToString(rates[i].high,  6);
      *(candle["low"])   = DoubleToString(rates[i].low,   6);
      *(candle["close"]) = DoubleToString(rates[i].close, 6);

      // closedCandles.Add(candle)
      closedCandles.Add(candle);
   }

   // root["closedCandles"] = closedCandles
   *(root["closedCandles"]) = closedCandles;

   // Return the serialized JSON
   return root.Serialize();
}

//+------------------------------------------------------------------+
//| 4) Format JSON for a single current candle using CJAVal          |
//+------------------------------------------------------------------+
string FormatCurrentCandleJson(const string symbol, int timeframeInMinutes, const MqlRates &rate)
{
   // root object
   CJAVal candleObj;
   candleObj.m_type = jtOBJ;

   // candleObj["symbol"] = symbol
   *(candleObj["symbol"]) = symbol;

   // currentCandle subobject
   CJAVal currentCandle;
   currentCandle.m_type = jtOBJ;

   *(currentCandle["time"])  = TimeToString(rate.time);
   *(currentCandle["open"])  = DoubleToString(rate.open,  6);
   *(currentCandle["high"])  = DoubleToString(rate.high,  6);
   *(currentCandle["low"])   = DoubleToString(rate.low,   6);
   *(currentCandle["close"]) = DoubleToString(rate.close, 6);

   // candleObj["currentCandle"] = currentCandle
   *(candleObj["currentCandle"]) = currentCandle;

   return candleObj.Serialize();
}

//+------------------------------------------------------------------+
//| 5) Build JSON for multiple symbols' current candles (CJAVal)     |
//+------------------------------------------------------------------+
string CreateMultiSymbolCurrentCandleJson(string &symbols[], int timeframeInMinutes)
{
   // root object
   CJAVal root;
   root.m_type = jtOBJ;

   // root["timeframeInMinutes"] = timeframeInMinutes
   *(root["timeframeInMinutes"]) = (int)timeframeInMinutes;

   // symbolCandles => array
   CJAVal symbolCandles;
   symbolCandles.m_type = jtARRAY;

   // For each symbol, build a sub-object with a "currentCandle"
   for(int i=0; i<ArraySize(symbols); i++)
   {
      MqlRates currentCandle[];
      int copied = CopyRates(symbols[i], Timeframe, 0, 1, currentCandle);
      if(copied > 0)
      {
         CJAVal candleObj;
         candleObj.m_type = jtOBJ;

         // candleObj["symbol"] = symbols[i]
         *(candleObj["symbol"]) = symbols[i];

         // subobject currentCandle
         CJAVal currentCandleObj;
         currentCandleObj.m_type = jtOBJ;

         *(currentCandleObj["time"])  = TimeToString(currentCandle[0].time);
         *(currentCandleObj["open"])  = DoubleToString(currentCandle[0].open,  6);
         *(currentCandleObj["high"])  = DoubleToString(currentCandle[0].high,  6);
         *(currentCandleObj["low"])   = DoubleToString(currentCandle[0].low,   6);
         *(currentCandleObj["close"]) = DoubleToString(currentCandle[0].close, 6);

         // candleObj["currentCandle"] = currentCandleObj
         *(candleObj["currentCandle"]) = currentCandleObj;

         // symbolCandles.Add(candleObj)
         symbolCandles.Add(candleObj);
      }
   }

   // root["symbolCandles"] = symbolCandles
   *(root["symbolCandles"]) = symbolCandles;

   return root.Serialize();
}

//+------------------------------------------------------------------+
//| 6) Send data to API via WebRequest                               |
//+------------------------------------------------------------------+
void SendDataToApi(const string apiUrl, const string jsonData)
{
   char   requestData[];
   char   result[];
   string errorMessage;
   int    timeout = 1000;

   // Convert JSON string to char array (UTF-8)
   StringToCharArray(jsonData, requestData, 0, StringLen(jsonData), CP_UTF8);

   // Send WebRequest
   int res = WebRequest("POST",
                        apiUrl,
                        "Content-Type: application/json",
                        timeout,
                        requestData,
                        result,
                        errorMessage);

   if(res == -1)
   {
      Print("WebRequest Error: ", errorMessage);
      isConnected = false;
      return;
   }
   if(res != 200)
   {
      Print("Response Code: ", res, " | Response: ", CharArrayToString(result));
      isConnected = false;
   }
   else
   {
      isConnected = true;
   }
}

//+------------------------------------------------------------------+
//| 7) Send closed-candles data for a symbol                         |
//+------------------------------------------------------------------+
void SendClosedCandles(const string symbol, const string apiUrl, int offset, int count, bool logMessage)
{
   MqlRates rates[];
   int copied = CopyRates(symbol, Timeframe, offset, count, rates);

   if(copied > 0)
   {
      if(logMessage)
         Print("Sending data for ", symbol);

      // Use our FormatJson() to build JSON w/ CJAVal
      string jsonData = FormatJson(symbol, TimeframeToMinutes(Timeframe), rates);
      SendDataToApi(apiUrl, jsonData);
   }
}

//+------------------------------------------------------------------+
//| 8) Send historical data for all symbols (on EA init)            |
//+------------------------------------------------------------------+
void SendInitialData()
{
   string symbols[];
   GetSymbolsArray(symbols);

   // For each symbol, skip the current candle => offset=1
   for(int i = 0; i < ArraySize(symbols); i++)
   {
      SendClosedCandles(symbols[i], processClosedCandlesApiUrl, 1, CandlesLimit + 1, true);
   }
}

//+------------------------------------------------------------------+
//| 9) Send current candle data for all symbols                      |
//+------------------------------------------------------------------+
void SendCurrentCandleData()
{
   string symbols[];
   GetSymbolsArray(symbols);

   // Build combined JSON for all current candles
   string json = CreateMultiSymbolCurrentCandleJson(symbols, TimeframeToMinutes(Timeframe));
   SendDataToApi(processCurrentCandlesApiUrl, json);

   // Draw the connectivity label on each chart
   for(int i=0; i<ArraySize(symbols); i++)
   {
      DrawLabelOnChart(symbols[i], isConnected);
   }
}

//+------------------------------------------------------------------+
//| 10) Draw or update connectivity label on chart                   |
//+------------------------------------------------------------------+
void DrawLabelOnChart(const string symbol, const bool connectedState)
{
   long chartId   = ChartFirst();
   bool chartFound = false;

   while(chartId >= 0)
   {
      if(ChartSymbol(chartId) == symbol)
      {
         chartFound = true;
         break;
      }
      chartId = ChartNext(chartId);
   }

   // If no chart found for this symbol, do nothing
   if(!chartFound)
      return;

   // Build object name
   string objectName = "Label_" + symbol;

   // Delete if exists
   if(ObjectFind(chartId, objectName) >= 0)
      ObjectDelete(chartId, objectName);

   // Create label
   ObjectCreate(chartId, objectName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, objectName, OBJPROP_CORNER,    CORNER_LEFT_LOWER);
   ObjectSetInteger(chartId, objectName, OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(chartId, objectName, OBJPROP_YDISTANCE, 50);

   if(connectedState)
   {
      ObjectSetString(chartId, objectName, OBJPROP_TEXT, "connected");
      ObjectSetInteger(chartId, objectName, OBJPROP_COLOR, clrGreen);
   }
   else
   {
      ObjectSetString(chartId, objectName, OBJPROP_TEXT, "disconnected");
      ObjectSetInteger(chartId, objectName, OBJPROP_COLOR, clrRed);
   }

   ObjectSetInteger(chartId, objectName, OBJPROP_FONTSIZE, 10);
   ObjectSetString(chartId, objectName, OBJPROP_FONT, "Arial");

   Print("Label created/updated on chart for symbol: ", symbol);
}
