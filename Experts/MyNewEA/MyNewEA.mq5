//+------------------------------------------------------------------+
//|                                                    MyEA.mq5      |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

//--- EA Inputs
input string          ApiUrl                     = "http://188.245.72.139:5231";
input string          SymbolsList                = "BTCUSD,ETHUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,NZDUSD,USDCHF,USDCAD,EURGBP,EURJPY,GBPJPY,CHFJPY,AUDJPY,AUDNZD,CADJPY,EURCAD,EURAUD,GBPCAD,GBPAUD,NZDJPY,AUDCAD,XAUUSD,XAGUSD";

//--- Timeframes & Limits
input ENUM_TIMEFRAMES HigherTimeframe            = PERIOD_H1;
input int             HigherTimeframeCandlesLimit= 600;
input ENUM_TIMEFRAMES LowerTimeframe             = PERIOD_M5;
input int             LowerTimeframeCandlesLimit = 20;

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
string   FormatJson(const string symbol, int timeframeInMinutes, MqlRates &rates[], bool isHigherTF);
void     SendDataToApi(const string apiUrl, const string jsonData);
void     SendClosedCandles(const string symbol, const string apiUrl, int offset, int count,
                           bool logMessage, ENUM_TIMEFRAMES timeframe);
void     SendInitialData();
void     SendCurrentCandleData(ENUM_TIMEFRAMES timeframe);
void     DrawLabelOnChart(const string symbol, const bool connectedState);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   processClosedCandlesApiUrl  = ApiUrl + "/process-closed-candles";
   processCurrentCandlesApiUrl = ApiUrl + "/process-current-candles";

   EventSetTimer(10);  // Timer triggers OnTimer every 10 seconds

   // Send initial historical data for both timeframes
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
//| OnTimer: Check new bars on both timeframes, then update          |
//+------------------------------------------------------------------+
void OnTimer()
{
   static datetime lastBarTimesHigh[];
   static datetime lastBarTimesLow[];

   // Split symbol list
   string symbols[];
   GetSymbolsArray(symbols);

   // Initialize tracking arrays if needed
   if(ArraySize(lastBarTimesHigh) == 0)
   {
      ArrayResize(lastBarTimesHigh, ArraySize(symbols));
      ArrayFill(lastBarTimesHigh, 0, ArraySize(lastBarTimesHigh), (datetime)0);
   }
   if(ArraySize(lastBarTimesLow) == 0)
   {
      ArrayResize(lastBarTimesLow, ArraySize(symbols));
      ArrayFill(lastBarTimesLow, 0, ArraySize(lastBarTimesLow), (datetime)0);
   }

   for(int i=0; i<ArraySize(symbols); i++)
   {
      string symbol = symbols[i];

      datetime currentBarTimeH = iTime(symbol, HigherTimeframe, 0);
      datetime currentBarTimeL = iTime(symbol, LowerTimeframe, 0);

      // Check HigherTimeframe
      if(currentBarTimeH > lastBarTimesHigh[i])
      {
         lastBarTimesHigh[i] = currentBarTimeH;
         //Print("New bar detected [HIGH] for ", symbol);

         // Send newly closed bar data
         SendClosedCandles(symbol,
                           processClosedCandlesApiUrl,
                           0,
                           HigherTimeframeCandlesLimit,
                           false,
                           HigherTimeframe);
      }

      // Check LowerTimeframe
      if(currentBarTimeL > lastBarTimesLow[i])
      {
         lastBarTimesLow[i] = currentBarTimeL;
         //Print("New bar detected [LOW] for ", symbol);

         SendClosedCandles(symbol,
                           processClosedCandlesApiUrl,
                           0,
                           LowerTimeframeCandlesLimit,
                           false,
                           LowerTimeframe);
      }
   }

   // Always send current candle data for both TF
   SendCurrentCandleData(HigherTimeframe);
   SendCurrentCandleData(LowerTimeframe);
}

//+------------------------------------------------------------------+
//| 1) Split symbols from input string                               |
//+------------------------------------------------------------------+
void GetSymbolsArray(string &dest[])
{
   StringSplit(SymbolsList, ',', dest);
}

//+------------------------------------------------------------------+
//| 2) Convert timeframe to minutes                                  |
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
      default:          return 0; // Unknown
   }
}

//+------------------------------------------------------------------+
//| 3) Format JSON for closed candles manually                       |
//|    Includes "isHigherTimeframe" boolean                          |
//+------------------------------------------------------------------+
string FormatJson(const string symbol, int timeframeInMinutes, MqlRates &rates[], bool isHigherTF)
{
   // Build JSON via string concatenation
   // e.g. 
   // {
   //   "symbol":"EURUSD",
   //   "timeframeInMinutes":240,
   //   "isHigherTimeframe":true,
   //   "closedCandles":[{ "time":"xxx", "open":"1.2345", ... }, ...]
   // }

   string json;
   json  = "{";
   json += "\"symbol\":\"" + symbol + "\",";
   json += "\"timeframeInMinutes\":" + IntegerToString(timeframeInMinutes) + ",";
   // isHigherTimeframe is a boolean => "true" or "false" in JSON
   json += "\"isHigherTimeframe\":" + (isHigherTF ? "true" : "false") + ",";

   // Build array of closedCandles
   json += "\"closedCandles\":[";

   for(int i=0; i<ArraySize(rates); i++)
   {
      // For each candle, build an object
      json += "{";
      json += "\"time\":\""  + TimeToString(rates[i].time)             + "\",";
      json += "\"open\":"    + DoubleToString(rates[i].open,  6)       + ",";
      json += "\"high\":"    + DoubleToString(rates[i].high,  6)       + ",";
      json += "\"low\":"     + DoubleToString(rates[i].low,   6)       + ",";
      json += "\"close\":"   + DoubleToString(rates[i].close, 6);
      json += "}";

      if(i < ArraySize(rates)-1)
         json += ",";
   }
   json += "]";  // end of closedCandles array
   json += "}";  // end of root object

   return json;
}

//+------------------------------------------------------------------+
//| 4) Send to API via WebRequest                                    |
//+------------------------------------------------------------------+
void SendDataToApi(const string apiUrl, const string jsonData)
{
   char   requestData[];
   char   result[];
   string errorMessage;
   int    timeout = 1000;

   StringToCharArray(jsonData, requestData, 0, StringLen(jsonData), CP_UTF8);

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
//| 5) Send closed-candles for a given timeframe                     |
//+------------------------------------------------------------------+
void SendClosedCandles(const string symbol,
                       const string apiUrl,
                       int offset,
                       int count,
                       bool logMessage,
                       ENUM_TIMEFRAMES timeframe)
{
   MqlRates rates[];
   int copied = CopyRates(symbol, timeframe, offset, count, rates);

   if(copied > 0)
   {
      //if(logMessage)
         //Print("Sending data for ", symbol, " ", EnumToString(timeframe));

      bool isHigherTF = (timeframe == HigherTimeframe);

      string jsonData = FormatJson(symbol, TimeframeToMinutes(timeframe), rates, isHigherTF);
      SendDataToApi(apiUrl, jsonData);
   }
}

//+------------------------------------------------------------------+
//| 6) Send historical data for both timeframes (EA init)           |
//+------------------------------------------------------------------+
void SendInitialData()
{
   string symbols[];
   GetSymbolsArray(symbols);

   for(int i=0; i<ArraySize(symbols); i++)
   {
      // HigherTimeframe
      SendClosedCandles(symbols[i],
                        processClosedCandlesApiUrl,
                        1, // skip current candle
                        HigherTimeframeCandlesLimit+1,
                        true,
                        HigherTimeframe);

      // LowerTimeframe
      SendClosedCandles(symbols[i],
                        processClosedCandlesApiUrl,
                        1,
                        LowerTimeframeCandlesLimit+1,
                        true,
                        LowerTimeframe);
   }
}

//+------------------------------------------------------------------+
//| 7) Send current candle data for the given timeframe manually     |
//+------------------------------------------------------------------+
void SendCurrentCandleData(ENUM_TIMEFRAMES timeframe)
{
   // We'll build manual JSON with "symbolCandles" array
   string symbols[];
   GetSymbolsArray(symbols);

   // e.g. 
   // {
   //   "timeframeInMinutes":15,
   //   "isHigherTimeframe":false,
   //   "symbolCandles":[
   //       {"symbol":"EURUSD","currentCandle":{"time":"xxx","open":..., ...}},
   //       ...
   //   ]
   // }

   bool isHigherTF = (timeframe == HigherTimeframe);
   int  tfMinutes  = TimeframeToMinutes(timeframe);

   string json;
   json  = "{";
   json += "\"timeframeInMinutes\":" + IntegerToString(tfMinutes) + ",";
   json += "\"isHigherTimeframe\":"  + (isHigherTF ? "true" : "false") + ",";
   json += "\"symbolCandles\":[";

   bool firstSymbol = true;

   for(int i=0; i<ArraySize(symbols); i++)
   {
      MqlRates cur[];
      int copied = CopyRates(symbols[i], timeframe, 0, 1, cur);

      if(copied > 0)
      {
         if(!firstSymbol) 
            json += ","; // separate objects in array
         firstSymbol = false;

         // Build sub-object
         json += "{";
         json += "\"symbol\":\"" + symbols[i] + "\",";
         json += "\"currentCandle\":{";
         json += "\"time\":\""  + TimeToString(cur[0].time)          + "\",";
         json += "\"open\":"    + DoubleToString(cur[0].open,  6)    + ",";
         json += "\"high\":"    + DoubleToString(cur[0].high,  6)    + ",";
         json += "\"low\":"     + DoubleToString(cur[0].low,   6)    + ",";
         json += "\"close\":"   + DoubleToString(cur[0].close, 6);
         json += "}";
         json += "}";
      }
   }

   json += "]";  // close symbolCandles
   json += "}";  // close root

   // Send it
   SendDataToApi(processCurrentCandlesApiUrl, json);

   // Update connectivity label
   for(int i=0; i<ArraySize(symbols); i++)
      DrawLabelOnChart(symbols[i], isConnected);
}

//+------------------------------------------------------------------+
//| 8) Draw connectivity label on each chart                         |
//+------------------------------------------------------------------+
void DrawLabelOnChart(const string symbol, const bool connectedState)
{
   long chartId = ChartFirst();
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

   if(!chartFound)
      return;

   string objectName = "Label_" + symbol;

   if(ObjectFind(chartId, objectName) >= 0)
      ObjectDelete(chartId, objectName);

   ObjectCreate(chartId, objectName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, objectName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
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
}
