//+------------------------------------------------------------------+
//|                                              DrawSquares.mq5      |
//|                        Script to draw squares on the chart       |
//+------------------------------------------------------------------+
#property strict

// Input data structure
struct SquareData
{
   datetime          startTime;
   datetime          endTime;
   double            price1;
   double            price2;
   bool              isBullish;
   string            status;
};

SquareData squareData[]; // Dynamic array to hold data loaded from a file

// Function to load data from a plain text file
bool LoadSquareDataFromFile(const string &filename)
{
   ResetLastError();

   int fileHandle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_ANSI);
   if (fileHandle == INVALID_HANDLE)
   {
      Print("Failed to open file: ", filename, ", Error: ", GetLastError());
      return false;
   }

   ArrayResize(squareData, 0); // Clear any existing data

   while (!FileIsEnding(fileHandle))
   {
      string line = FileReadString(fileHandle);
      line = line;
      if (line == "" || StringFind(line, "#") == 0) // Skip empty or commented lines
         continue;

      SquareData entry;
      string fields[];
      int count = StringSplit(line, ',', fields);
      if (count < 6)
         continue; // Skip invalid lines

      entry.startTime = StringToTime(fields[0]);
      entry.endTime = StringToTime(fields[1]);
      entry.price1 = StringToDouble(fields[2]);
      entry.price2 = StringToDouble(fields[3]);
      entry.isBullish = fields[4] == "true";
      entry.status = fields[5];

      int newSize = ArraySize(squareData) + 1;
      ArrayResize(squareData, newSize);
      squareData[newSize - 1] = entry;
   }

   FileClose(fileHandle);
   return true;
}

//+------------------------------------------------------------------+
//| Script start function                                            |
//+------------------------------------------------------------------+
void OnStart()
{
   string currentSymbol = Symbol();
   int currentPeriodMinutes = PeriodSeconds() / 60;
   
   string fileName = StringFormat("%s_%d.txt", currentSymbol, currentPeriodMinutes);

   if (!LoadSquareDataFromFile(fileName))
   {
      Print("Failed to load square data from file.");
      return;
   }

   // Remove all previous drawings from the chart
   ObjectsDeleteAll(0, 0);

   for (int i = 0; i < ArraySize(squareData); i++)
   {
      // Extract data for the current rectangle
      datetime startTime = squareData[i].startTime;
      datetime endTime = squareData[i].endTime;
      double price1 = squareData[i].price1;
      double price2 = squareData[i].price2;
      bool isBullish = squareData[i].isBullish;
      string status = squareData[i].status;

      // Define the rectangle name
      string rectName = "Square_" + IntegerToString(i);

      // Set rectangle color based on isBullish
      color rectColor = isBullish ? clrGreen : clrRed;

      // Draw the rectangle on the chart
      if (!ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, price1, endTime, price2))
      {
         Print("Failed to create rectangle: ", rectName);
         continue;
      }

      // Set rectangle properties
      ObjectSetInteger(0, rectName, OBJPROP_COLOR, rectColor);
      ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, rectName, OBJPROP_BACK, true); // Draw in the background

      // Add index text near the rectangle
      string textName = "Index_" + IntegerToString(i);
      double midPrice = (price1 + price2) / 2.0; // Midpoint of the rectangle's price range
      if (!ObjectCreate(0, textName, OBJ_TEXT, 0, startTime, midPrice))
      {
         Print("Failed to create text: ", textName);
         continue;
      }
      //ObjectSetString(0, textName, OBJPROP_TEXT, IntegerToString(i) + " - " + status);
      ObjectSetString(0, textName, OBJPROP_TEXT, status);
      ObjectSetInteger(0, textName, OBJPROP_COLOR, rectColor);
      ObjectSetInteger(0, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 10);
   }

   Print("Rectangles successfully drawn.");
}
//+------------------------------------------------------------------+
