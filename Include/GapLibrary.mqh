//+------------------------------------------------------------------+
//|  GapLibrary.mqh                                                 |
//|  Упрощённая библиотека для обнаружения FVG (гепов)              |
//|  (адаптация C#-логики на MQL5)                                  |
//+------------------------------------------------------------------+
#ifndef __GAP_LIBRARY__
#define __GAP_LIBRARY__

//--- Перечисление типов гепа
enum GapType
{
    GapType_Bullish = 0, // бычий геп
    GapType_Bearish      // медвежий геп
};

//--- Перечисление статусов гепа
enum GapStatus
{
    GapStatus_NotTested = 0, // ещё не тестировался
    GapStatus_Tested,        // протестирован
    GapStatus_Overlapped     // «перекрыт» (overlapped)
};

//+------------------------------------------------------------------+
//| Структура свечи                                                 |
//+------------------------------------------------------------------+
struct Candle
{
    datetime Time; // время открытия свечи
    double Open;
    double High;
    double Low;
    double Close;

    bool IsBullish() const { return (Close > Open); }
    bool IsBearish() const { return (Close < Open); }

    double BodySize() const
    {
        return MathAbs(Close - Open);
    }

    double UpperWick() const
    {
        return (IsBullish() ? (High - Close) : (High - Open));
    }

    double LowerWick() const
    {
        return (IsBullish() ? (Open - Low) : (Close - Low));
    }

    // Дополнительно — проверки фрактала (необязательно)
    bool IsBullishFractal(const Candle &prevCandle, const Candle &nextCandle) const
    {
        return (High > prevCandle.High && High > nextCandle.High);
    }

    bool IsBearishFractal(const Candle &prevCandle, const Candle &nextCandle) const
    {
        return (Low < prevCandle.Low && Low < nextCandle.Low);
    }
};

//+------------------------------------------------------------------+
//| Структура гепа (FVG)                                            |
//+------------------------------------------------------------------+
struct Gap
{
    GapType Type;       // бычий / медвежий
    datetime StartTime; // "середина" (по аналогии candle2)
    datetime EndTime;   // "конец"   (по аналогии candle3)
    double High;        // верхняя граница гепа
    double Low;         // нижняя граница гепа
    GapStatus Status;   // NotTested, Tested, Overlapped

    // Проверяет, "тестирует" ли данная свеча геп (если он ещё NotTested)
    bool IsTestedByCandle(const Candle &candle) const
    {
        if (Status != GapStatus_NotTested)
            return false;

        // Для одной свечи делаем упрощённую проверку "IsTested"
        Candle tempCandleArray[];
        ArrayResize(tempCandleArray, 1);
        tempCandleArray[0] = candle;

        return IsTested(tempCandleArray);
    }

    // Обновляет статус гепа на основе списка свечей
    void UpdateStatus(const Candle &candles[])
    {
        if (IsOverlapped(candles))
        {
            Status = GapStatus_Overlapped;
            return;
        }
        if (IsTested(candles))
        {
            Status = GapStatus_Tested;
            return;
        }
        Status = GapStatus_NotTested;
    }

    // Аналог IsTested(candles): проверяем, были ли свечи,
    // которые "закрывают" диапазон [Low, High] после EndTime
    bool IsTested(const Candle &candles[]) const
    {
        int count = ArraySize(candles);
        for (int i = 0; i < count; i++)
        {
            // В C#: x => x.Time > EndTime && x.High >= Low && x.Low <= High
            if (candles[i].Time > EndTime)
            {
                if (candles[i].High >= Low && candles[i].Low <= High)
                {
                    return true;
                }
            }
        }
        return false;
    }

    // Аналог IsOverlapped(candles)
    bool IsOverlapped(const Candle &candles[]) const
    {
        int count = ArraySize(candles);
        for (int i = 0; i < count; i++)
        {
            // Проверяем только свечи, которые идут позже EndTime
            if (candles[i].Time <= EndTime)
                continue;

            if (Type == GapType_Bullish)
            {
                // Если свеча ушла ниже Low (x.Close < Low или x.Open < Low)
                if (candles[i].Close < Low || candles[i].Open < Low)
                    return true;
            }
            else // GapType_Bearish
            {
                // Если свеча ушла выше High (x.Close > High или x.Open > High)
                if (candles[i].Close > High || candles[i].Open > High)
                    return true;
            }
        }
        return false;
    }
};

//+------------------------------------------------------------------+
//| Вспомогательные функции                                         |
//+------------------------------------------------------------------+
bool IsBullishGap(const Candle &candle1, const Candle &candle3)
{
    return (candle3.Low > candle1.High);
}

bool IsBearishGap(const Candle &candle1, const Candle &candle3)
{
    return (candle3.High < candle1.Low);
}

// Попытка создать геп (TryCreate) из трёх свечей (c1,c2,c3)
bool TryCreateGap(const Candle &c1, const Candle &c2, const Candle &c3, /*out*/ Gap &gap)
{
    gap.Type = (GapType)(-1);
    gap.Status = GapStatus_NotTested;
    gap.StartTime = 0;
    gap.EndTime = 0;
    gap.High = 0;
    gap.Low = 0;

    // Быčий
    if (IsBullishGap(c1, c3))
    {
        gap.Type = GapType_Bullish;
        gap.High = c3.Low;       // верх гепа
        gap.Low = c1.High;       // низ гепа
        gap.StartTime = c2.Time; // серединная свеча
        gap.EndTime = c3.Time;   // последняя свеча
        gap.Status = GapStatus_NotTested;
        return true;
    }

    // Медвежий
    if (IsBearishGap(c1, c3))
    {
        gap.Type = GapType_Bearish;
        gap.High = c1.Low;
        gap.Low = c3.High;
        gap.StartTime = c2.Time;
        gap.EndTime = c3.Time;
        gap.Status = GapStatus_NotTested;
        return true;
    }

    return false;
}

// Возвращаем тройку свечей (c1, c2, c3) для индекса i
bool GetCandleTriple(const Candle &candles[], int i,
                     /*out*/ Candle &c1, /*out*/ Candle &c2, /*out*/ Candle &c3)
{
    int size = ArraySize(candles);
    if (i < 0 || i + 2 >= size)
        return false;

    c1 = candles[i];
    c2 = candles[i + 1];
    c3 = candles[i + 2];
    return true;
}

//+------------------------------------------------------------------+
//| Превращаем массив Candle[] в гепы со статусом NotTested         |
//| (внутренний метод)                                             |
//+------------------------------------------------------------------+
void ConvertCandlesToNotTestedGaps(const Candle &candles[],
                                   /*out*/ Gap &allGaps[])
{
    ArrayResize(allGaps, 0);

    int size = ArraySize(candles);
    if (size < 3)
        return;

    for (int i = 0; i < size - 2; i++)
    {
        Candle c1, c2, c3;
        if (!GetCandleTriple(candles, i, c1, c2, c3))
            continue;

        Gap gap;
        if (TryCreateGap(c1, c2, c3, gap))
        {
            // Обновляем статус, если нужно
            gap.UpdateStatus(candles);

            if (gap.Status == GapStatus_NotTested)
            {
                int newSize = ArraySize(allGaps) + 1;
                ArrayResize(allGaps, newSize);
                allGaps[newSize - 1] = gap;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 1) Основная функция: создаёт массив FVG (гепов) из RAW-данных   |
//|    (Open, High, Low, Close, Time).                              |
//|    Можно дополнить другими массивами (Volume и т. п.), если надо
//+------------------------------------------------------------------+
void CreateGapsFromCandles(const double &high[], const double &low[],
                           const double &open[], const double &close[],
                           const datetime &time[],
                           const int rates_total,
                           /*out*/ Gap &notTestedGaps[],
                           int limit = 600)
{
    int start = MathMax(1, rates_total - limit);
    // 1. Построим временный массив Candle[]
    Candle candles[];
    ArrayResize(candles, rates_total - limit);

    for (int i = start; i < rates_total - 1; i++)
    {
        candles[i - start].Time = time[i];
        candles[i - start].Open = open[i];
        candles[i - start].High = high[i];
        candles[i - start].Low = low[i];
        candles[i - start].Close = close[i];
    }

    // 2. Превращаем этот массив свечей в гепы
    ConvertCandlesToNotTestedGaps(candles, notTestedGaps);
}

//+------------------------------------------------------------------+
//| 2) Проверить, какие гепы тестирует ОДНА свеча                   |
//+------------------------------------------------------------------+
void GetGapsTestedByCandle(const Gap &allGaps[],
                           const double &high, const double &low,
                           const double &open, const double &close,
                           const datetime &time,
                           /*out*/ Gap &result[])
{
    ArrayResize(result, 0);
    int size = ArraySize(allGaps);

    Candle candle;

    candle.Time = time;
    candle.Open = open;
    candle.High = high;
    candle.Low = low;
    candle.Close = close;

    for (int i = 0; i < size; i++)
    {
        if (allGaps[i].IsTestedByCandle(candle))
        {
            int newSize = ArraySize(result) + 1;
            ArrayResize(result, newSize);
            result[newSize - 1] = allGaps[i];
        }
    }
}

//+------------------------------------------------------------------+
//| 3) Аналог: вернуть гепы, чей StartTime находится               |
//|    в пределах [startTime, endTime].                             |
//+------------------------------------------------------------------+
void GetGapsInTimeRange(const Gap &allGaps[],
                        datetime startTime, datetime endTime,
                        /*out*/ Gap &result[])
{
    ArrayResize(result, 0);
    int size = ArraySize(allGaps);

    for (int i = 0; i < size; i++)
    {
        if (allGaps[i].StartTime >= startTime && allGaps[i].StartTime <= endTime)
        {
            int newSize = ArraySize(result) + 1;
            ArrayResize(result, newSize);
            result[newSize - 1] = allGaps[i];
        }
    }
}

#endif // __GAP_LIBRARY__
