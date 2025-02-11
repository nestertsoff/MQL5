//+------------------------------------------------------------------+
//|       Example Expert: Fractals, Trends, GUI-Buttons, Toggle TF  |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>
#include <Strings\String.mqh>

// Include your fractal/trend library
#include <FractalLibrary.mqh>
#include <ConfigureTool.mqh>

// GUI settings
#define PANEL_NAME   ""
#define ROW_HEIGHT   25
#define COL_MARGIN   10
#define ROW_MARGIN   10

// Main dialog
CAppDialog app;

//------------------------------------------------------------------+
// Global arrays
string   g_symbols[] = {
   "BTCUSD", "ETHUSD", "AUDCAD", "AUDCHF", "AUDJPY", "AUDNZD", "AUDUSD",
   "CADCHF", "CADJPY", "CHFJPY", "EURAUD", "EURCAD", "EURCHF", "EURGBP",
   "EURJPY", "EURNZD", "EURUSD", "GBPAUD", "GBPCAD", "GBPCHF", "GBPJPY",
   "GBPNZD", "GBPUSD", "NZDCAD", "NZDCHF", "NZDJPY", "NZDUSD", "USDCAD",
   "USDCHF", "USDJPY", "DAX40", "NAS100", "SP500", "XAUUSD", "XAGUSD"
};
string   g_timeframes[] = { "M1", "M5", "M15", "H1", "H4", "D1" };

// One chart ID per symbol (or -1 if no chart is open)
long     g_chart_ids[];

// Labels for TF columns
CLabel  *g_labelTimeframes[];

// Labels for symbols (left column)
CLabel  *g_labelSymbols[];

// Buttons for displaying trend states [symbols x timeframes]
CButton *g_tfButtons[];

// Last bar time for each (symbol, timeframe)
datetime g_lastBarTime[];

// We store which symbol/timeframe label is currently highlighted
int g_selectedSymbol   = -1;
int g_selectedTimeframe= -1;

//------------------------------------------------------------------+
// Convert string (like "M5") to ENUM_TIMEFRAMES
ENUM_TIMEFRAMES ParseTimeframe(const string tf)
{
   if(tf == "M1")   return(PERIOD_M1);
   if(tf == "M5")   return(PERIOD_M5);
   if(tf == "M15")  return(PERIOD_M15);
   if(tf == "M30")  return(PERIOD_M30);
   if(tf == "H1")   return(PERIOD_H1);
   if(tf == "H4")   return(PERIOD_H4);
   if(tf == "D1")   return(PERIOD_D1);
   if(tf == "W1")   return(PERIOD_W1);
   if(tf == "MN1")  return(PERIOD_MN1);

   return(PERIOD_CURRENT);
}

string TimeframeToString(ENUM_TIMEFRAMES timeframe)
{
   switch(timeframe)
   {
      case PERIOD_M1:   return "M1";
      case PERIOD_M5:   return "M5";
      case PERIOD_M15:  return "M15";
      case PERIOD_M30:  return "M30";
      case PERIOD_H1:   return "H1";
      case PERIOD_H4:   return "H4";
      case PERIOD_D1:   return "D1";
      case PERIOD_W1:   return "W1";
      case PERIOD_MN1:  return "MN1";
      default:          return "";
   }
}

//------------------------------------------------------------------+
// Convert TrendType -> symbol
string TrendTypeToString(TrendType type)
{
   switch(type)
   {
   case Uptrend:   return "⏫";
   case Downtrend: return "⏬";
   case Neutral:   return "⏩";
   }
   return "?";
}

//------------------------------------------------------------------+
// Generate fractals, analyze trends, produce a string (Long->Inter->Short)
// Also returns the TrendAnalysis via &outTa
//------------------------------------------------------------------+
string CalculateTrendStringAndAnalysis(const string symbol,
                                       const ENUM_TIMEFRAMES tf,
                                       TrendAnalysis &outTa)
{
   int needed_bars = 600;

   MqlRates rates[];
   int copied = CopyRates(symbol, tf, 0, needed_bars, rates);
   if(copied < 5)
   {
      outTa.ShortTerm        = Neutral;
      outTa.IntermediateTerm = Neutral;
      outTa.LongTerm         = Neutral;
      return "NoBars";
   }

   // Prepare arrays
   double   high[], low[], open[], close[];
   datetime time[];
   ArrayResize(high,  copied);
   ArrayResize(low,   copied);
   ArrayResize(open,  copied);
   ArrayResize(close, copied);
   ArrayResize(time,  copied);

   for(int i=0; i<copied; i++)
   {
      high[i]  = rates[i].high;
      low[i]   = rates[i].low;
      open[i]  = rates[i].open;
      close[i] = rates[i].close;
      time[i]  = rates[i].time;
   }

   // Generate fractals
   Fractal allFractals[], filtered[];
   GenerateFractals(high, low, open, close, time, copied, allFractals, filtered, needed_bars);

   // Analyze
   outTa = AnalyzeTrends(filtered);

   // Build string (Long->Intermediate->Short)
   string result = TrendTypeToString(outTa.LongTerm)
                 + TrendTypeToString(outTa.IntermediateTerm)
                 + TrendTypeToString(outTa.ShortTerm);

   return result;
}

//------------------------------------------------------------------+
// Check if new bar for (symbol i, timeframe j). If yes, recalc trend,
// update the button text and color (ST=IT) for closed charts only!
//------------------------------------------------------------------+
void CheckNewBarAndUpdate(const int i, const int j)
{
   int tfCount  = ArraySize(g_timeframes);
   int indexBtn = i*tfCount + j;

   string symbol = g_symbols[i];
   ENUM_TIMEFRAMES tf = ParseTimeframe(g_timeframes[j]);

   datetime currentBarTime = iTime(symbol, tf, 0);
   if(currentBarTime <= 0)
      return;

   // We allow ST=IT coloring only if the chart is closed 
   // (to not overwrite user-chosen color).
   if(g_chart_ids[i] != -1)
      return;

   if(currentBarTime != g_lastBarTime[indexBtn])
   {
      // New bar => fractal/trend analysis
      g_lastBarTime[indexBtn] = currentBarTime;

      TrendAnalysis ta;
      string trendStr = CalculateTrendStringAndAnalysis(symbol, tf, ta);

      // Update button text
      if(g_tfButtons[indexBtn] != NULL)
         g_tfButtons[indexBtn].Text(trendStr);

      // ST=IT or IT=LT, not Neutral
      bool isSynced = false;
      TrendType syncTrend = Neutral;

      if(ta.ShortTerm == ta.IntermediateTerm && ta.ShortTerm != Neutral)
      {
         isSynced  = true;
         syncTrend = ta.ShortTerm;
      }
      else if(ta.IntermediateTerm == ta.LongTerm && ta.IntermediateTerm != Neutral)
      {
         isSynced  = true;
         syncTrend = ta.IntermediateTerm;
      }

      // Color background if synced
      if(isSynced && g_tfButtons[indexBtn] != NULL)
      {
         if(syncTrend == Uptrend)
            g_tfButtons[indexBtn].ColorBackground((color)C'171,235,198'); // light green
         else if(syncTrend == Downtrend)
            g_tfButtons[indexBtn].ColorBackground((color)C'230,176,170'); // light red
      }
      else
      {
         // Default color
         g_tfButtons[indexBtn].ColorBackground(clrWhite);
      }
   }
}

//------------------------------------------------------------------+
// Toggle open/close or switch timeframe for a single chart per symbol
//------------------------------------------------------------------+
void ToggleChartTF(const int i, const ENUM_TIMEFRAMES new_tf)
{
   if(i < 0 || i >= ArraySize(g_symbols))
      return;

   // If there's no chart open => open it 
   if(g_chart_ids[i] == -1)
   {
      long new_chart_id = ChartOpen(g_symbols[i], new_tf);
      if(new_chart_id > 0)
      {
         g_chart_ids[i] = new_chart_id;
         ChartSetInteger(new_chart_id, CHART_BRING_TO_TOP, true);
         ChartSetInteger(new_chart_id, CHART_AUTOSCROLL, false);

         for(int j=0; j<ArraySize(g_timeframes); j++)
         {
            if(g_timeframes[j] == TimeframeToString(new_tf))
            {
               g_labelTimeframes[j].Color(clrBlack);
               g_labelTimeframes[j].FontSize(12);
            }
            else
            {
               g_labelTimeframes[j].Color(C'97,106,107'); 
               g_labelTimeframes[j].FontSize(10);
            }
         }

          for(int j=0; j<ArraySize(g_symbols); j++)
         {
            if(g_symbols[j] == g_symbols[i])
            {
               g_labelSymbols[j].Color(clrBlack);
               g_labelSymbols[j].FontSize(12);
            }
            else
            {
               g_labelSymbols[j].Color(C'97,106,107'); 
               g_labelSymbols[j].FontSize(10);
            }
         }
      }
      else
      {
         Print("Failed to open chart: ", g_symbols[i], 
               " / ", EnumToString(new_tf));
      }
   }
   else
   {
      // We already have a chart open for symbol i
      long cid = g_chart_ids[i];

      // Check current TF
      long currentTF = ChartPeriod(cid);
      if(currentTF == new_tf)
      {
         // The user clicked the same TF => close chart
         if(ChartClose(cid))
         {
            g_chart_ids[i] = -1;
            Print("Closed chart for symbol #", i, " (", g_symbols[i], ")");
         }
         else
         {
            Print("Failed to close chart for ", g_symbols[i], 
                  " (chart_id=", cid, ")");
         }
      }
      else
      {
         // Switch TF
         bool res = ChartSetSymbolPeriod(cid, g_symbols[i], new_tf);
         if(!res)
         {
            Print("Failed to switch TF(", EnumToString(new_tf), 
                  ") for ", g_symbols[i], 
                  " (chart_id=", cid, ")");
         }
         else
         {
            ChartSetInteger(cid, CHART_BRING_TO_TOP, true);
            Print("Switched TF to ", EnumToString(new_tf), 
                  " for symbol #", i, " (", g_symbols[i], ")");
         }
      }
   }
}

//------------------------------------------------------------------+
// OnInit
//------------------------------------------------------------------+
int OnInit()
{
   long currentChart = ChartID();
   ConfigureChart(currentChart, 50, 50, 1200, 800);

   int symCount = ArraySize(g_symbols);
   int tfCount  = ArraySize(g_timeframes);
   if(symCount<1 || tfCount<1)
      return(INIT_FAILED);

   // Resize arrays
   ArrayResize(g_chart_ids,       symCount);
   ArrayResize(g_labelTimeframes, tfCount);
   ArrayResize(g_labelSymbols,    symCount);
   ArrayResize(g_tfButtons,       symCount*tfCount);
   ArrayResize(g_lastBarTime,     symCount*tfCount);

   // Initialize
   for(int i=0; i<symCount; i++)
      g_chart_ids[i] = -1;
   for(int n=0; n<symCount*tfCount; n++)
      g_lastBarTime[n] = 0;

   // Create main dialog
   app.Create(0, PANEL_NAME, 0, -5, -25, 10000, 10000);

   // Timeframe labels (top row)
   int headerTop   = 10;
   int headerLeft  = 75;
   int tfLabelW    = 60;

   for(int j=0; j<tfCount; j++)
   {
      g_labelTimeframes[j] = new CLabel;
      if(g_labelTimeframes[j] != NULL)
      {
         string lblName = "TF_Label_"+(string)j;
         int left  = headerLeft + j*(tfLabelW + COL_MARGIN);
         int right = left + tfLabelW;

         g_labelTimeframes[j].Create(0, lblName, 0,
                                     left, headerTop,
                                     right, headerTop + ROW_HEIGHT);

         g_labelTimeframes[j].Text(g_timeframes[j]);
         g_labelTimeframes[j].Color(C'97,106,107'); // some text color
         g_labelTimeframes[j].FontSize(10);
         // By default, no background color
         app.Add(*g_labelTimeframes[j]);
      }
   }

   // Create rows for each symbol
   int currentTop = 10 + ROW_HEIGHT + ROW_MARGIN;
   for(int i=0; i<symCount; i++)
   {
      // Symbol label
      g_labelSymbols[i] = new CLabel;
      if(g_labelSymbols[i] != NULL)
      {
         string lblName = "Sym_Label_"+(string)i;
         int left  = 10;
         int right = left + 10;
         g_labelSymbols[i].Create(0, lblName, 0, left, currentTop,
                                  right, currentTop + ROW_HEIGHT);

         g_labelSymbols[i].Text(g_symbols[i]);
         g_labelSymbols[i].Color(C'97,106,107');
         g_labelSymbols[i].FontSize(10);
         // no background by default
         app.Add(*g_labelSymbols[i]);
      }

      // Timeframe buttons
      for(int j=0; j<tfCount; j++)
      {
         int indexBtn = i*tfCount + j;
         g_tfButtons[indexBtn] = new CButton;
         if(g_tfButtons[indexBtn] != NULL)
         {
            string btnName = "BTN_" + IntegerToString(i) + "_" + IntegerToString(j);

            int left  = headerLeft + j*(tfLabelW + COL_MARGIN);
            int top   = currentTop;
            int right = left + tfLabelW;
            int bot   = top + ROW_HEIGHT;

            g_tfButtons[indexBtn].Create(0, btnName, 0, left, top, right, bot);
            g_tfButtons[indexBtn].Text("...");

            app.Add(*g_tfButtons[indexBtn]);
         }
      }

      currentTop += (ROW_HEIGHT + ROW_MARGIN);
   }

   Print("Initialization done. Symbols=", symCount, ", Timeframes=", tfCount);

   // We run OnTimer() every 5 seconds
   EventSetTimer(5);

   return(INIT_SUCCEEDED);
}

//------------------------------------------------------------------+
// OnDeinit
//------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   // Optionally close all opened charts
   for(int i=0; i<ArraySize(g_chart_ids); i++)
   {
      if(g_chart_ids[i] != -1)
         ChartClose(g_chart_ids[i]);
   }

   // Delete all controls
   for(int i=0; i<ArraySize(g_labelTimeframes); i++)
   {
      if(g_labelTimeframes[i] != NULL)
      {
         delete g_labelTimeframes[i];
         g_labelTimeframes[i] = NULL;
      }
   }
   for(int i=0; i<ArraySize(g_labelSymbols); i++)
   {
      if(g_labelSymbols[i] != NULL)
      {
         delete g_labelSymbols[i];
         g_labelSymbols[i] = NULL;
      }
   }
   for(int k=0; k<ArraySize(g_tfButtons); k++)
   {
      if(g_tfButtons[k] != NULL)
      {
         delete g_tfButtons[k];
         g_tfButtons[k] = NULL;
      }
   }
   // app.Destroy(); // if needed
}

//------------------------------------------------------------------+
// OnTimer: called every 5 seconds
//------------------------------------------------------------------+
void OnTimer()
{
   int symCount = ArraySize(g_symbols);
   int tfCount  = ArraySize(g_timeframes);

   // Check new bars for each (symbol, timeframe),
   // but only if the chart is closed (to not overwrite user color).
   for(int i=0; i<symCount; i++)
   {
      for(int j=0; j<tfCount; j++)
      {
         CheckNewBarAndUpdate(i, j);
      }
   }
}

//------------------------------------------------------------------+
// OnChartEvent: handle button clicks (timeframe) => toggle open/close
//               plus highlight the corresponding symbol & timeframe label
//------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Format: BTN_<i>_<j>
      string prefixTF = "BTN_";
      if(StringFind(sparam, prefixTF, 0) == 0)
      {
         string indices = StringSubstr(sparam, StringLen(prefixTF));
         int pos_ = StringFind(indices, "_", 0);
         if(pos_ > 0)
         {
            string strI = StringSubstr(indices, 0, pos_);
            string strJ = StringSubstr(indices, pos_+1);

            int i = (int)StringToInteger(strI);
            int j = (int)StringToInteger(strJ);
            if(i >= 0 && i < ArraySize(g_symbols) &&
               j >= 0 && j < ArraySize(g_timeframes))
            {
               // 1) Toggle the chart open/close or switch TF
               ENUM_TIMEFRAMES tf = ParseTimeframe(g_timeframes[j]);
               ToggleChartTF(i, tf);
            }
         }
      }
   }
}
