//+------------------------------------------------------------------+
//|                                            Removing Toolbars.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com/en/forum/337940"
#property version   "1.00"

#include <WinAPI\winuser.mqh>
#define GW_CHILD        5
#define GW_HWNDNEXT     2
#define SWP_NOMOVE      2
#define SWP_NOZORDER    4

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---

//can we assume that the code below goes in sensible places and should not be used "as-is"?
//and that defined constants are already done....

//we are going to need the winuser headers

//assuming we need to undock the chart first

   long chartID = 0;
   ChartSetInteger(chartID,CHART_IS_DOCKED,false);

//get the hwnd of the chart

   long chartHWND = ChartGetInteger(chartID,CHART_WINDOW_HANDLE);

//but we need the HWND of the main window for further processing

   long parentHWND = GetParent(chartHWND);

//then we can find the HWND of the toolbar
//first we get the HWND of the highest zorder child window

   long child = GetWindow(parentHWND,GW_CHILD);

// child is actually equal to chartHWND at this point. we could use an if or a while loop to proceed if they were not the same
//but we dont need to so.....
//we recycle the child var as we would if we used a while loop to wrap this

   child = GetWindow(child,GW_HWNDNEXT);

//since this child is not equal to the chartHWND we can then kill it... but...
//DestroyWindow() cant be used since the window was created in a different thread
//so we go back to the old days of "MQL4 ugly kludge just to make simple things happen" and...
//just hide the window.

   ShowWindow(child,0);

//then we can force a redraw by resizing the undocked window. in this case to 800x600.
//if we dont do this then it will look like the title bar is fat and ugly...

   uint flags = SWP_NOMOVE + SWP_NOZORDER;
   SetWindowPos(parentHWND,0, 0,0, 800, 600, flags);

//NOTE: YOU WILL NOT BE ABLE TO MANUALLY TURN THE TOOLBAR BACK ON :D

  }
//+------------------------------------------------------------------+
