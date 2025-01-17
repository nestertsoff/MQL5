void OnStart()
{
   bool fixScaleNeeded = !ChartGetInteger(0, CHART_SCALEFIX);
   
   if(fixScaleNeeded)
   {
      ChartSetInteger(0, CHART_AUTOSCROLL, false);
      
      double chartMax  = ChartGetDouble(0, CHART_PRICE_MAX);
      double chartMin  = ChartGetDouble(0, CHART_PRICE_MIN);
      double midPrice  = (chartMax + chartMin) / 2.0;
      double halfRange = chartMax - midPrice;
      
      double multiplier = 3.0;
      double offset     = halfRange * multiplier;
      
      int firstVisibleBar = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
      int visibleBars     = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
      int totalBars       = (int)iBars(_Symbol, Period());
      int ratesBar        = totalBars - firstVisibleBar - 3 + visibleBars;
      if(ratesBar < 0)
         ratesBar = 0;
      
      double openBar  = iOpen(_Symbol, Period(), ratesBar);
      double closeBar = iClose(_Symbol, Period(), ratesBar);
      if(openBar < 0 || closeBar < 0)
         return;
      
      ChartSetInteger(0, CHART_SCALEFIX, true);
      
      double barMid = (openBar + closeBar) / 2.0;
      ChartSetDouble(0, CHART_FIXED_MAX, barMid + offset);
      ChartSetDouble(0, CHART_FIXED_MIN, barMid - offset);
   }
   else
   {
      ChartSetInteger(0, CHART_SCALEFIX, false);
      ChartSetInteger(0, CHART_AUTOSCROLL, true);
   }
}