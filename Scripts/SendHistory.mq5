#property strict

#include <HistoryPositionInfo.mqh>
#include <JAson.mqh>
#include <Trade\Trade.mqh>

// Define your REST API endpoint URL
string endpoint = "http://188.245.72.139:8080/api/positions";
const string BarDataURL = "http://188.245.72.139:8086/api/v2/write?org=docs&bucket=home&precision=s";
double totalProfit = 0;

const string currentSymbol = Symbol();

int totalBars = 0;
int totalBarsSent = 0;

ENUM_TIMEFRAMES timeFrames[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1};

string UniqueSymbols[];

// Function to send data to the REST API
bool SendDataToEndpoint(string data)
{
    uchar postData[];
    StringToCharArray(data, postData, 0, StringLen(data), CP_UTF8);
    
    char result[];
    string resultHeaders;
    int timeout = 500;
    string headers = "Content-Type: application/json\r\n";

    bool success = WebRequest("POST", endpoint, headers, timeout, postData, result, resultHeaders);

    if (success)
    {
        //Print("Data sent successfully: ", CharArrayToString(result));
    }
    else
    {
        Print("Failed to send data.");
    }

    return success;
}

string FormatDateTime(datetime serverTime) {
    // Get the formatted date as MM/DD/YYYY HH:MM:SS
    string formattedDate = TimeToString(serverTime, TIME_DATE | TIME_SECONDS);
  
    // Replace the default format (YYYY.MM.DD) with MM/DD/YYYY
    string month = StringSubstr(formattedDate, 5, 2);
    string day = StringSubstr(formattedDate, 8, 2);
    string year = StringSubstr(formattedDate, 0, 4);
    string hour = StringSubstr(formattedDate, 11, 2);
    string minute = StringSubstr(formattedDate, 14, 2);
    string second = StringSubstr(formattedDate, 17, 2);

    // Return the date in MM/DD/YYYY HH:MM:SS format
    return month + "/" + day + "/" + year + " " + hour + ":" + minute + ":" + second;
}

void GetSLAndTPFromHistory(ulong positionId, double &sl, double &tp)
{
    sl = 0;
    tp = 0;

    // Select the history of orders and deals by position ID
    if (!HistorySelectByPosition(positionId))
    {
        Print("Failed to select history by position.");
        return;
    }

    // Loop through all historical deals
    int totalDeals = HistoryDealsTotal();
    for (int i = totalDeals - 1; i >= 0; i--)
    {
        ulong dealTicket = HistoryDealGetTicket(i);
        
        if (HistoryDealSelect(dealTicket))
        {
            if (HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == positionId)
            {
                // Get SL and TP from the historical deal if it's related to the position
                sl = HistoryDealGetDouble(dealTicket, DEAL_SL);
                tp = HistoryDealGetDouble(dealTicket, DEAL_TP);
                return;
            }
        }
    }
}


// Function to convert position history data to JSON format
string HistoryToJSON(CHistoryPositionInfo &positionInfo) {
    CJAVal json;  
    ulong positionId = positionInfo.Identifier();

    // Create JSON object
    json["accountId"] = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    json["time"] = ConvertToUTC((datetime)positionInfo.TimeOpen());
    json["positionId"] = IntegerToString(positionId);
    json["symbol"] = positionInfo.Symbol();
    json["type"] = (positionInfo.PositionType() == POSITION_TYPE_BUY ? "Buy" : "Sell");
    json["volume"] = DoubleToString(positionInfo.Volume());
    json["price"] = DoubleToString(positionInfo.PriceOpen());
    
    json["closeTime"] = ConvertToUTC((datetime)positionInfo.TimeClose());
    json["closePrice"] = DoubleToString(positionInfo.PriceClose());
    
    double commission = DoubleToString(positionInfo.Commission());
    double swap = DoubleToString(positionInfo.Swap());
    double profit = DoubleToString(positionInfo.Profit());
    
    json["commission"] = commission;
    json["swap"] = swap;
    json["profit"] = profit;
    
    totalProfit = totalProfit + commission + swap + profit;
    
    json["totalProfit"] = totalProfit;

    double sl, tp;
    GetSLAndTPFromHistory(positionId, sl, tp);

    json["sl"] = DoubleToString(sl);  // Use SL from orders
    json["tp"] = DoubleToString(tp);  // Use TP from orders

    string jsonData = json.Serialize();
    
    return jsonData;
}



// Function to add a symbol to the unique symbols array if not already present
void AddUniqueSymbol(string symbol)
{
    for (int i = 0; i < ArraySize(UniqueSymbols); i++)
    {
        if (UniqueSymbols[i] == symbol)
            return; // Symbol already exists
    }
    // Add new symbol to the array
    ArrayResize(UniqueSymbols, ArraySize(UniqueSymbols) + 1);
    UniqueSymbols[ArraySize(UniqueSymbols) - 1] = symbol;
}

//+------------------------------------------------------------------+
//| Main function                                                   |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("Start");
    
    CHistoryPositionInfo positionInfo;

    datetime from_date = 0;
    datetime to_date = TimeCurrent();
    if (!positionInfo.HistorySelect(from_date, to_date))
    {
        Print("Failed to select history.");
        return;
    }

    int totalPositions = positionInfo.PositionsTotal();

    ArrayFree(UniqueSymbols);

    for (int i = 0; i < totalPositions; i++)
    {
        if (positionInfo.SelectByIndex(i))
        {
            string symbol = positionInfo.Symbol();
            AddUniqueSymbol(symbol);

            string jsonData = HistoryToJSON(positionInfo);
            bool success = SendDataToEndpoint(jsonData);

            if (!success)
            {
                Print("Error sending history for position ", positionInfo.Ticket());
            }
        }
    }
    
    
    
    Print("---------------------------");

    SendAllSymbolsBars();
    
    Print("Finish");
}

void SendAllSymbolsBars(){
   datetime startTime = D'2024.01.01 00:00';
   datetime stopTime = TimeCurrent();

   for (int j = 0; j < ArraySize(UniqueSymbols); j++) {
       string symbol = UniqueSymbols[j];
       totalBars = 0;
       totalBarsSent = 0;

       for (int i = 0; i < ArraySize(timeFrames); i++) {
           totalBars += Bars(symbol, timeFrames[i], startTime, stopTime);
       }

       for (int i = 0; i < ArraySize(timeFrames); i++) {
           SendBarsInChunks(symbol, timeFrames[i], startTime, stopTime);
       }
   }
}

void SendBarsInChunks(string symbol, ENUM_TIMEFRAMES timeframe, datetime startTime, datetime stopTime) {
    const int MAX_BARS_PER_CHUNK = 1000; 
    string dataChunk = "";
    int barsCount = Bars(symbol, timeframe, startTime, stopTime);
    int lastPrintedPercentage = -1; // Initialize to an impossible percentage

    for (int i = 0; i < barsCount; i++) {
        string barData = FormatBarData(symbol, i, timeframe);
        dataChunk += barData + "\n";

        if ((i + 1) % MAX_BARS_PER_CHUNK == 0 || i == barsCount - 1) {
            SendData(dataChunk);

            totalBarsSent += (i % MAX_BARS_PER_CHUNK) + 1;
            int currentPercentage = (int)((double)totalBarsSent / totalBars * 100.0);

            if (currentPercentage != lastPrintedPercentage) {
                Print(StringFormat("%s %d%% %s", symbol, currentPercentage, TimeframeToString(timeframe) ));
                lastPrintedPercentage = currentPercentage;
            }

            dataChunk = "";
            Sleep(500);
        }
    }
}

string FormatBarData(string symbol, int index, ENUM_TIMEFRAMES timeframe) {
    long time = (long)ConvertToUTC((datetime)iTime(symbol, timeframe, index));
    string tf = TimeframeToString(timeframe);
    double open = iOpen(symbol, timeframe, index);
    double high = iHigh(symbol, timeframe, index);
    double low = iLow(symbol, timeframe, index);
    double close = iClose(symbol, timeframe, index);
    long volume = iVolume(symbol, timeframe, index);
   
    string dataLine = StringFormat("%s,timeframe=%s open=%f,high=%f,low=%f,close=%f,volume=%d %ld",
                                   symbol, tf, open, high, low, close, volume, time);

    return dataLine;
}

string TimeframeToString(ENUM_TIMEFRAMES timeframe) {
    switch(timeframe) {
        case PERIOD_M1:  return "1";
        case PERIOD_M5:  return "5";
        case PERIOD_M15: return "15";
        case PERIOD_H1:  return "60";
        case PERIOD_H4:  return "240";
        case PERIOD_D1:  return "1D";
        case PERIOD_W1:  return "1W";
        case PERIOD_MN1: return "1M";
        default: return         "Unknown";
    }
}


string ConvertToUTC(datetime serverTime)
{
   // Get the current server time and UTC time
   datetime currentServerTime = TimeLocal();
   datetime currentUTCTime = TimeGMT();
   
   // Calculate the time difference (offset) between server time and UTC in seconds
   int timeOffset = (int)(currentServerTime - currentUTCTime);
   
   // Subtract the offset from the input server time to get UTC time
   datetime utcTime = serverTime - timeOffset;
   
   return ""+ utcTime;
}

void SendData(string data) {
    uchar postData[];
    StringToCharArray(data, postData, 0, StringLen(data), CP_UTF8);
    
    char result[];
    string resultHeaders;
    int timeout = 5000;
    string headers = "Content-Type: text/plain\r\nAuthorization: Token otU9kQSaNKGdXKOUu3YcnIwZuSZUNb_JevXaidicpZKvasK5wX1Ac6fcX_faes2QbC_7w3CYy4818rC_FbnsnQ==";

    int response = WebRequest("POST", BarDataURL, headers, timeout, postData, result, resultHeaders);
    
    //Sleep(500);

    if (response == -1) {
        Alert("WebRequest error. Code: ", GetLastError());
    } else {
        string resultStr = CharArrayToString(result);
        if(resultStr != "")
        {
            Print("Server response: ", resultStr);
        }
    }
}