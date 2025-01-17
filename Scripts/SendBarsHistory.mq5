#include <Trade\Trade.mqh>

#property copyright "esthetic"
#property link      "https://www.mql5.com"
#property version   "1.00"

const string BarDataURL = "http://188.245.72.139:8086/api/v2/write?org=docs&bucket=home&precision=s";


const string currentSymbol = Symbol();

int totalBars = 0;
int totalBarsSent = 0;

ENUM_TIMEFRAMES timeFrames[] = {PERIOD_M1, PERIOD_D1, PERIOD_W1, PERIOD_MN1};


void OnStart() {
    datetime startTime = D'2024.01.01 00:00';
    datetime stopTime = TimeCurrent();

    for (int i = 0; i < ArraySize(timeFrames); i++) {
        totalBars += Bars(currentSymbol, timeFrames[i], startTime, stopTime);
    }

    for (int i = 0; i < ArraySize(timeFrames); i++) {
        SendBarsInChunks(timeFrames[i], startTime, stopTime);
    } 
}

void SendBarsInChunks(ENUM_TIMEFRAMES timeframe, datetime startTime, datetime stopTime) {

    Print("Start Time: " + startTime);
    const int MAX_BARS_PER_CHUNK = 1000; 
    string dataChunk = "";
    int barsCount = Bars(_Symbol, timeframe, startTime, stopTime);
    int lastPrintedPercentage = -1; // Initialize to an impossible percentage

    for (int i = 0; i < barsCount; i++) {
        string barData = FormatBarData(i, timeframe);
        dataChunk += barData + "\n";

        if ((i + 1) % MAX_BARS_PER_CHUNK == 0 || i == barsCount - 1) {
            SendData(dataChunk);

            totalBarsSent += (i % MAX_BARS_PER_CHUNK) + 1;
            int currentPercentage = (int)((double)totalBarsSent / totalBars * 100.0);

            if (currentPercentage != lastPrintedPercentage) {
                Print(StringFormat("%d%%", currentPercentage));
                lastPrintedPercentage = currentPercentage;
            }

            dataChunk = "";
        }
    }
}

string FormatBarData(int index, ENUM_TIMEFRAMES timeframe) {
    long time = (long)iTime(_Symbol, timeframe, index);
    string tf = TimeframeToString(timeframe);
    double open = iOpen(_Symbol, timeframe, index);
    double high = iHigh(_Symbol, timeframe, index);
    double low = iLow(_Symbol, timeframe, index);
    double close = iClose(_Symbol, timeframe, index);
    long volume = iVolume(_Symbol, timeframe, index);
   
    string server = AccountInfoString(ACCOUNT_SERVER); 
    string symbol = _Symbol;

    string dataLine = StringFormat("%s,timeframe=%s open=%f,high=%f,low=%f,close=%f,volume=%d %ld",
                                   symbol, tf, open, high, low, close, volume, time);

    return dataLine;
}

string TimeframeToString(ENUM_TIMEFRAMES timeframe) {
    switch(timeframe) {
        case PERIOD_M1:  return "1";
        case PERIOD_D1:  return "1D";
        case PERIOD_W1:  return "1W";
        case PERIOD_MN1: return "1M";
        default: return         "Unknown";
    }
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