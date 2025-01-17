#property strict

#include <HistoryPositionInfo.mqh>
#include <JAson.mqh>
#include <Trade\Trade.mqh>

// Define your REST API endpoint URL
string endpoint = "https://script.google.com/macros/s/AKfycbyJUqdvXCLNcTVWaQsPmt-NWt95AhvisIg_Gkc773vKRxZJY2RyhYCQtI-6B4FddBh2/exec";
input double initialBalance = 60000;
// Global variable to store the last sent position's ticket
ulong lastSentPositionTicket = 0;

// Function to send data to the endpoint
bool SendDataToEndpoint(string data)
{
     Print(data);
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

// Function to format the time as MM/DD/YYYY HH:MM:SS
string FormatDateTime(datetime serverTime)
{
    string formattedDate = TimeToString(serverTime, TIME_DATE | TIME_SECONDS);
    string month = StringSubstr(formattedDate, 5, 2);
    string day = StringSubstr(formattedDate, 8, 2);
    string year = StringSubstr(formattedDate, 0, 4);
    string hour = StringSubstr(formattedDate, 11, 2);
    string minute = StringSubstr(formattedDate, 14, 2);
    string second = StringSubstr(formattedDate, 17, 2);

    return month + "/" + day + "/" + year + " " + hour + ":" + minute + ":" + second;
}

// Function to get the SL and TP from the history
void GetSLAndTPFromHistory(ulong positionId, double &sl, double &tp)
{
    sl = 0;
    tp = 0;

    if (!HistorySelectByPosition(positionId))
    {
        Print("Failed to select history by position.");
        return;
    }

    int totalDeals = HistoryDealsTotal();
    for (int i = totalDeals - 1; i >= 0; i--)
    {
        ulong dealTicket = HistoryDealGetTicket(i);

        if (HistoryDealSelect(dealTicket))
        {
            if (HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == positionId)
            {
                sl = HistoryDealGetDouble(dealTicket, DEAL_SL);
                tp = HistoryDealGetDouble(dealTicket, DEAL_TP);
                return;
            }
        }
    }
}

// Function to send position data to the API
string HistoryToJSON(CHistoryPositionInfo &positionInfo)
{
    CJAVal json;
    ulong positionId = positionInfo.Identifier();

    json["accountId"] = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    json["time"] = FormatDateTime((datetime)positionInfo.TimeOpen());
    json["positionId"] = IntegerToString(positionId);
    json["symbol"] = positionInfo.Symbol();
    json["type"] = (positionInfo.PositionType() == POSITION_TYPE_BUY ? "Buy" : "Sell");
    json["volume"] = DoubleToString(positionInfo.Volume());
    json["price"] = DoubleToString(positionInfo.PriceOpen());

    json["closeTime"] = FormatDateTime((datetime)positionInfo.TimeClose());
    json["closePrice"] = DoubleToString(positionInfo.PriceClose());

    double commission = DoubleToString(positionInfo.Commission());
    double swap = DoubleToString(positionInfo.Swap());
    double profit = DoubleToString(positionInfo.Profit());

    json["commission"] = commission;
    json["swap"] = swap;
    json["profit"] = NormalizeDouble(profit,2);

    json["initialBalance"] = initialBalance;
    json["balance"] =  NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE), 2);
    
    double percentageDiff = ((AccountInfoDouble(ACCOUNT_BALANCE) - initialBalance) / initialBalance) * 100;
    
    json["diff"] =  NormalizeDouble(percentageDiff, 2);

    double sl, tp;
    GetSLAndTPFromHistory(positionId, sl, tp);

    json["sl"] = DoubleToString(sl);
    json["tp"] = DoubleToString(tp);

    string jsonData = json.Serialize();
    return jsonData;
}

void GetAndSendLastPosition()
{
    // Create position info object
    CHistoryPositionInfo positionInfo;

    // Select all positions from a specific date range (e.g., the last 24 hours)
    datetime from_date = 0; // Start from the earliest available position
    datetime to_date = TimeCurrent(); // Until the current time
    
    if (!positionInfo.HistorySelect(from_date, to_date))
    {
        Print("Failed to select history.");
        return;
    }

    // Get the total number of positions
    int totalPositions = positionInfo.PositionsTotal();
    
    if (totalPositions == 0)
    {
        Print("No positions found.");
        return;
    }
    
    // Select the most recent position (last position)
    if (positionInfo.SelectByIndex(totalPositions - 1))
    {
        // Get position details
        ulong positionTicket = positionInfo.Ticket();
        
        // Check if this position has already been sent (by comparing ticket IDs)
        if (positionTicket != lastSentPositionTicket)
        {
            // Position hasn't been sent before, send it now
            string symbol = positionInfo.Symbol();
            datetime timeOpen = positionInfo.TimeOpen();
            datetime timeClose = positionInfo.TimeClose();
            double profit = positionInfo.Profit();
            
            // Convert position data to JSON or format it as needed
            string jsonData = HistoryToJSON(positionInfo);  // Assuming you have HistoryToJSON() method
            
            // Send position data to endpoint
            bool success = SendDataToEndpoint(jsonData);   // Assuming you have SendDataToEndpoint() method
            
            if (success)
            {
                // Update last sent position ticket to prevent resending the same position
                lastSentPositionTicket = positionTicket;
                
                Print("Sent position data: Symbol = ", symbol, ", TimeOpen = ", timeOpen, ", TimeClose = ", timeClose, ", Profit = ", profit);
            }
            else
            {
                Print("Error sending position data for position: ", positionTicket);
            }
        }
    }
    else
    {
        Print("Failed to select the last position.");
    }
}

// Event handler to set up periodic checking
int OnInit()
{
    EventSetTimer(1);  // Check every second
    return INIT_SUCCEEDED;
}

// Cleanup when the EA is removed
void OnDeinit(const int reason)
{
    EventKillTimer();
}

// Main function called every tick
void OnTick()
{
    GetAndSendLastPosition();
}
