#include <ChartObjects\ChartObjectsTxtControls.mqh>
input string SymbolsList = "BTCUSD,EURUSD,GBPUSD,USDJPY"; // List of symbols

// Button click event handler
void OnButtonClick(const string &buttonName)
{
   string symbol = StringSubstr(buttonName, 7); // Remove "Symbol_" prefix

   // Check if the chart is already open
   long chartId = ChartFirst();
   while (chartId >= 0)
   {
      if (ChartSymbol(chartId) == symbol)
      {
         // Close the chart if it is already open
         ChartClose(chartId);
         Print("Closed chart for ", symbol);
         return;
      }
      chartId = ChartNext(chartId);
   }

   // Open the chart if it is not already open
   chartId = ChartOpen(symbol, 0);
   if (chartId != 0)
   {
      Print("Opened chart for ", symbol);
   }
   else
   {
      Print("Failed to open chart for ", symbol);
   }
}

// Create graphical panel with buttons
void CreateSymbolPanel()
{
   string symbols[];
   StringSplit(SymbolsList, ',', symbols);

   int buttonCount = ArraySize(symbols);
   int buttonWidth = 100;
   int buttonHeight = 30;
   int xOffset = 10;
   int yOffset = 10;
   int ySpacing = 40;

   for (int i = 0; i < buttonCount; i++)
   {
      string buttonName = "Symbol_" + symbols[i];
      int xPosition = xOffset;
      int yPosition = yOffset + (i * ySpacing);

      // Create a button for each symbol
      if (!ObjectCreate(0, buttonName, OBJ_BUTTON, 0, 0, 0))
      {
         Print("Failed to create button for ", symbols[i]);
         continue;
      }

      ObjectSetInteger(0, buttonName, OBJPROP_XDISTANCE, xPosition);
      ObjectSetInteger(0, buttonName, OBJPROP_YDISTANCE, yPosition);
      ObjectSetInteger(0, buttonName, OBJPROP_XSIZE, buttonWidth);
      ObjectSetInteger(0, buttonName, OBJPROP_YSIZE, buttonHeight);
      ObjectSetString(0, buttonName, OBJPROP_TEXT, symbols[i]);
      ObjectSetInteger(0, buttonName, OBJPROP_CORNER, 0);
      ObjectSetInteger(0, buttonName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, buttonName, OBJPROP_HIDDEN, false);
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   CreateSymbolPanel();
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   string symbols[];
   StringSplit(SymbolsList, ',', symbols);

   for (int i = 0; i < ArraySize(symbols); i++)
   {
      string buttonName = "Symbol_" + symbols[i];
      ObjectDelete(0, buttonName);
   }
}

//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (id == CHARTEVENT_OBJECT_CLICK)
   {
      if (StringFind(sparam, "Symbol_") == 0)
      {
         OnButtonClick(sparam);
      }
   }
}
