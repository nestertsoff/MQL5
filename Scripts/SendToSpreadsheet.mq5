#property strict

#include <HistoryPositionInfo.mqh>
#include <JAson.mqh>
#include <Trade\Trade.mqh>

// Define your REST API endpoint URL
string endpoint = "https://script.google.com/macros/s/AKfycbyJUqdvXCLNcTVWaQsPmt-NWt95AhvisIg_Gkc773vKRxZJY2RyhYCQtI-6B4FddBh2/exec";
double totalProfit = 0;

bool SendDataToEndpoint(string data)
{
    uchar postData[];
    StringToCharArray(data, postData, 0, StringLen(data), CP_UTF8);
    
    char result[];
    string resultHeaders;
    int timeout = 500;
    string headers = "Content-Type: application/json\r\n";

    bool success = WebRequest("POST", endpoint, headers, timeout, postData, result, resultHeaders);
   
    if (!success)
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


string HistoryToJSON(CHistoryPositionInfo &positionInfo) {
    CJAVal json;  
    ulong positionId = positionInfo.Identifier();

    // Create JSON object
    json["accountId"] = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    json["time"] = FormatDateTime(ConvertToUTC((datetime)positionInfo.TimeOpen()));
    json["positionId"] = IntegerToString(positionId);
    json["symbol"] = positionInfo.Symbol();
    json["type"] = (positionInfo.PositionType() == POSITION_TYPE_BUY ? "Buy" : "Sell");
    json["volume"] = DoubleToString(positionInfo.Volume());
    json["price"] = DoubleToString(positionInfo.PriceOpen());
    
    json["closeTime"] = FormatDateTime(ConvertToUTC((datetime)positionInfo.TimeClose()));
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

    for (int i = 0; i < totalPositions; i++)
    {
        if (positionInfo.SelectByIndex(i))
        {
            string symbol = positionInfo.Symbol();
                       
            string jsonData = HistoryToJSON(positionInfo);
            bool success = SendDataToEndpoint(jsonData);

            if (!success)
            {
                Print("Error sending history for position ", positionInfo.Ticket());
            }
        }
    }
    
    Print("Finish");
}


datetime ConvertToUTC(datetime serverTime)
{
   // Get the current server time and UTC time
   datetime currentServerTime = TimeLocal();
   datetime currentUTCTime = TimeGMT();
   
   // Calculate the time difference (offset) between server time and UTC in seconds
   int timeOffset = (int)(currentServerTime - currentUTCTime);
   
   // Subtract the offset from the input server time to get UTC time
   datetime utcTime = serverTime - timeOffset;
   
   return utcTime;
}

void SendData(string data) {
    uchar postData[];
    StringToCharArray(data, postData, 0, StringLen(data), CP_UTF8);
    
    char result[];
    string resultHeaders;
    int timeout = 100;
    string headers = "Content-Type: text/plain";

    int response = WebRequest("POST", endpoint, headers, timeout, postData, result, resultHeaders);
    
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