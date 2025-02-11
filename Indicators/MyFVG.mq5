//--- Индикатор для определения непокрытых FVG
#property indicator_chart_window
#property strict

//--- Параметры
input int CheckBars = 500; // Количество баров для проверки

//--- Глобальные переменные
double FVGBufferUp[];
double FVGBufferDown[];

void InitializeBuffers(int rates_total)
{
    ArrayResize(FVGBufferUp, rates_total);
    ArrayResize(FVGBufferDown, rates_total);
    SetIndexBuffer(0, FVGBufferUp, INDICATOR_DATA);
    SetIndexBuffer(1, FVGBufferDown, INDICATOR_DATA);
    ArraySetAsSeries(FVGBufferUp, true);
    ArraySetAsSeries(FVGBufferDown, true);
}

bool IsFVGTested(double high_level, double low_level, double current_high, double current_low)
{
    return (current_low <= high_level && current_high >= low_level);
}

void CheckAndMarkFVG(int index, double high_level, double low_level, double &buffer, const double &current_high, const double &current_low)
{
    buffer = high_level;
    if (IsFVGTested(high_level, low_level, current_high, current_low))
    {
        buffer = EMPTY_VALUE;
        PrintFormat("FVG протестирован на свече %d", index);
    }
}

//--- Инициализация
int OnInit()
{
    Print("FVG Indicator initialized.");
    return(INIT_SUCCEEDED);
}

//--- Главная функция индикатора
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
    if (prev_calculated == 0)
        InitializeBuffers(rates_total);

    int start = rates_total - CheckBars - 1;
    if (start < 2) start = 2;

    for (int i = start; i < rates_total - 1; i++)
    {
        if (i + 1 >= rates_total || i - 1 < 0)
            continue;

        double prev_high = high[i + 1];
        double prev_low = low[i + 1];
        double next_high = high[i - 1];
        double next_low = low[i - 1];

        double current_high = high[i];
        double current_low = low[i];

        if (next_low > prev_high)
        {
            CheckAndMarkFVG(i, prev_high, next_low, FVGBufferUp[i], current_high, current_low);
        }

        if (next_high < prev_low)
        {
            CheckAndMarkFVG(i, prev_low, next_high, FVGBufferDown[i], current_high, current_low);
        }
    }

    return(rates_total);
}
