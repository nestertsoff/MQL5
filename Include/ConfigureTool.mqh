#include <WinAPI\winuser.mqh>

// Additional WinAPI constants (if needed)
#define GW_CHILD        5
#define GW_HWNDNEXT     2
#define SWP_NOMOVE      2
#define SWP_NOZORDER    4

//+------------------------------------------------------------------+
//| ConfigureChart: removes indicators, undocks, and resizes        |
//+------------------------------------------------------------------+
void ConfigureChart(const long chart_id,
                    const int desiredLeft = 0,
                    const int desiredTop = 0,
                    const int desiredWidth = 800,
                    const int desiredHeight = 600)
{
   int subWindowsCount = (int)ChartGetInteger(chart_id, CHART_WINDOWS_TOTAL);
   for (int wnd = 0; wnd < subWindowsCount; wnd++)
   {
      int indicatorsCount = ChartIndicatorsTotal(chart_id, wnd);
      // We remove indicators in reverse order
      for (int i = indicatorsCount - 1; i >= 0; i--)
      {
         string indiName = ChartIndicatorName(chart_id, wnd, i);
         if (indiName != "")
         {
            ChartIndicatorDelete(chart_id, wnd, indiName);
         }
      }
   }

   ChartSetInteger(chart_id, CHART_IS_DOCKED, false);
   ChartSetInteger(chart_id, CHART_SHOW_DATE_SCALE, false);
   ChartSetInteger(chart_id, CHART_SHOW_PRICE_SCALE, false);
   ChartSetInteger(chart_id, CHART_WIDTH_IN_PIXELS, 600);
   ChartSetInteger(chart_id, CHART_HEIGHT_IN_PIXELS, 1200);
   ChartSetInteger(chart_id, CHART_SHOW, false);

   long chartHWND = ChartGetInteger(chart_id,CHART_WINDOW_HANDLE);
   long parentHWND = GetParent(chartHWND);

   long child = GetWindow(parentHWND, GW_CHILD);
   child = GetWindow(child,GW_HWNDNEXT);
   ShowWindow(child,0);
   uint flags = SWP_NOMOVE + SWP_NOZORDER;
   SetWindowPos(parentHWND,0, 0 ,0, 520, 1340, flags);
   SetWindowTextW(parentHWND, "Trends Dashboard");
}