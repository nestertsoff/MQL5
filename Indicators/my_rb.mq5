//+------------------------------------------------------------------+
//| Rejection Block Indicator                                        |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0

#include <Trade\Trade.mqh>

input color BullishRBColor = clrBlue;    // Color for Bullish Rejection Block
input color BearishRBColor = clrRed;    // Color for Bearish Rejection Block
input int MinWickLengthFactor = 1;      // Factor to determine wick length

//+------------------------------------------------------------------+
//| Custom Indicator Initialization                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Calculate Average Wick Length                                    |
//+------------------------------------------------------------------+
double CalculateAverageWickLength(const double &high[], const double &low[], const double &open[], const double &close[], int start, int count)
{
   double totalWickLength = 0.0;
   int candles = 0;
   for (int i = start; i < start + count; i++)
   {
      if (i >= 0)
      {
         double upperWick = high[i] - MathMax(open[i], close[i]);
         double lowerWick = MathMin(open[i], close[i]) - low[i];
         totalWickLength += (upperWick + lowerWick);
         candles++;
      }
   }
   return (candles > 0) ? (totalWickLength / candles) : 0.0;
}

//+------------------------------------------------------------------+
//| Detect Rejection Blocks                                          |
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
   int start = MathMax(prev_calculated - 1, 5); // Ensure we have enough candles for comparison

   double avgWickLength = CalculateAverageWickLength(high, low, open, close, start - 5, 5);

   for (int i = start; i < rates_total - 1; i++)
   {
      // Check for Bullish Rejection Block
      if (close[i - 1] == open[i] && close[i - 1] > open[i - 1] && close[i] > open[i]) // Bullish RB condition
      {
         double upperWick = high[i] - MathMax(open[i], close[i]);
         double lowerWick = MathMin(open[i], close[i]) - low[i];
         double wickLength = MathMax(upperWick, lowerWick);

         if (wickLength > avgWickLength * MinWickLengthFactor)
         {
            string rectName = "BullishRB_" + IntegerToString(i);
            double rectTop = MathMax(open[i], close[i]);
            double rectBottom = MathMin(open[i - 1], close[i - 1]);
            ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, time[i - 1], rectTop, time[i], rectBottom);
            ObjectSetInteger(0, rectName, OBJPROP_COLOR, BullishRBColor);
            ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
         }
      }

      // Check for Bearish Rejection Block
      if (close[i - 1] == open[i] && close[i - 1] < open[i - 1] && close[i] < open[i]) // Bearish RB condition
      {
         double upperWick = high[i] - MathMax(open[i], close[i]);
         double lowerWick = MathMin(open[i], close[i]) - low[i];
         double wickLength = MathMax(upperWick, lowerWick);

         if (wickLength > avgWickLength * MinWickLengthFactor)
         {
            string rectName = "BearishRB_" + IntegerToString(i);
            double rectTop = MathMax(open[i], close[i]);
            double rectBottom = MathMin(open[i - 1], close[i - 1]);
            ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, time[i - 1], rectTop, time[i], rectBottom);
            ObjectSetInteger(0, rectName, OBJPROP_COLOR, BearishRBColor);
            ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
         }
      }
   }

   return rates_total;
}
