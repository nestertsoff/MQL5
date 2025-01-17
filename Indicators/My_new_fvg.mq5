//+------------------------------------------------------------------+
//| Script to Mark Fair Value Gaps (FVG) on Chart                    |
//| Author: Your Name                                               |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#include <Trade\Trade.mqh>

input color BullishFVGColor = clrGold; // Color of Bullish FVG markers
input color BearishFVGColor = clrRed;  // Color of Bearish FVG markers
input int FVGWidth = 2;                // Line width for FVG markers

// Indicator buffers
double UpperBuffer[];
double LowerBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set up indicator buffers
   SetIndexBuffer(0, UpperBuffer);
   SetIndexBuffer(1, LowerBuffer);

   // Set plot properties
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Loop through each candle
   for (int i = prev_calculated; i < rates_total - 2; i++)
   {
      // Check for a Bullish Fair Value Gap (FVG)
      if (low[i+2] > high[i])
      {
         UpperBuffer[i] = high[i];
         LowerBuffer[i] = low[i+2];

         // Draw rectangle to mark Bullish FVG
         string rect_name = "BullishFVG_" + IntegerToString(i);
         datetime start_time = time[i+2];
         datetime end_time = time[i];
         if (!ObjectFind(0, rect_name))
         {
            ObjectCreate(0, rect_name, OBJ_RECTANGLE, 0, start_time, high[i], end_time, low[i+2]);
            ObjectSetInteger(0, rect_name, OBJPROP_COLOR, BullishFVGColor);
            ObjectSetInteger(0, rect_name, OBJPROP_WIDTH, FVGWidth);
            ObjectSetInteger(0, rect_name, OBJPROP_BACK, true);
         }
      }

      // Check for a Bearish Fair Value Gap (FVG)
      if (high[i+2] < low[i])
      {
         UpperBuffer[i] = low[i];
         LowerBuffer[i] = high[i+2];

         // Draw rectangle to mark Bearish FVG
         string rect_name = "BearishFVG_" + IntegerToString(i);
         datetime start_time = time[i+2];
         datetime end_time = time[i];
         if (!ObjectFind(0, rect_name))
         {
            ObjectCreate(0, rect_name, OBJ_RECTANGLE, 0, start_time, low[i], end_time, high[i+2]);
            ObjectSetInteger(0, rect_name, OBJPROP_COLOR, BearishFVGColor);
            ObjectSetInteger(0, rect_name, OBJPROP_WIDTH, FVGWidth);
            ObjectSetInteger(0, rect_name, OBJPROP_BACK, true);
         }
      }
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
