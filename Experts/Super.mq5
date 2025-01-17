//+------------------------------------------------------------------+
//|                                                  FractalTrendEA.mq5 |
//|      Пример эксперта для анализа трендов по фракталам с выводом     |
//|      на панель итоговых значков в формате:                         |
//|      SYMBOL | TF : LT IT ST | TF : LT IT ST | ...                 |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <FractalLibrary.mqh>

//--- Входные параметры
input string SymbolsList    = "BTCUSD,ETHUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,NZDUSD,USDCHF,USDCAD,EURGBP,EURJPY,GBPJPY,CHFJPY,AUDJPY,AUDNZD,CADJPY,EURCAD,EURAUD,GBPCAD,GBPAUD,NZDJPY,AUDCAD,XAUUSD,XAGUSD";
input string TimeframesList = "M15,H1,D1";

//--- Функция для получения массива символов из строки SymbolsList
void GetSymbolsArray(string &dest[])
{
   int count = StringSplit(SymbolsList, ',', dest);
   if(count < 1)
   {
      Print("Не удалось разобрать строку символов: ", SymbolsList);
      return;
   }
}

//--- Функция для получения массива таймфреймов из строки TimeframesList
void GetTimeframesArray(ENUM_TIMEFRAMES &dest[])
{
   string tfStrings[];
   int count = StringSplit(TimeframesList, ',', tfStrings);
   if(count < 1)
   {
      Print("Не удалось разобрать строку таймфреймов: ", TimeframesList);
      return;
   }
   
   ArrayResize(dest, count);
   for (int i = 0; i < count; i++)
   {
      if(StringCompare(tfStrings[i], "M1") == 0)
         dest[i] = PERIOD_M1;
      else if(StringCompare(tfStrings[i], "M5") == 0)
         dest[i] = PERIOD_M5;
      else if(StringCompare(tfStrings[i], "M15") == 0)
         dest[i] = PERIOD_M15;
      else if(StringCompare(tfStrings[i], "M30") == 0)
         dest[i] = PERIOD_M30;
      else if(StringCompare(tfStrings[i], "H1") == 0)
         dest[i] = PERIOD_H1;
      else if(StringCompare(tfStrings[i], "H4") == 0)
         dest[i] = PERIOD_H4;
      else if(StringCompare(tfStrings[i], "D1") == 0)
         dest[i] = PERIOD_D1;
      else if(StringCompare(tfStrings[i], "W1") == 0)
         dest[i] = PERIOD_W1;
      else if(StringCompare(tfStrings[i], "MN1") == 0)
         dest[i] = PERIOD_MN1;
      else
      {
         Print("Неизвестный таймфрейм: ", tfStrings[i], ". Используется PERIOD_CURRENT.");
         dest[i] = PERIOD_CURRENT;
      }
   }
}

//--- Преобразование типа тренда в значок (выводим только значки)
//   Значения: Neutral -> "⏩", Uptrend -> "⏫", Downtrend -> "⏬"
string TrendTypeToIcon(TrendType tt)
{
   switch(tt)
   {
      case Neutral:   return "■";
      case Uptrend:   return "▲";
      case Downtrend: return "▼";
      default:        return "";
   }
}

//+------------------------------------------------------------------+
//| Функция анализа для одного символа на заданном таймфрейме         |
//| Возвращает строку в виде "LT IT ST" (значки в порядке LT, IT, ST) |
//| Если условие НЕ выполняется (LT != IT и IT != ST), возвращается ""    |
//+------------------------------------------------------------------+
string AnalyzeSymbolTimeframe(const string symbol, const ENUM_TIMEFRAMES timeframe)
{
   const int limit = 600; // количество баров для анализа
   MqlRates rates[];
   
   int copied = CopyRates(symbol, timeframe, 0, limit, rates);
   if(copied <= 0)
   {
      // Если данные не получены, возвращаем пустую строку
      return "";
   }
   
   // Заполняем массивы для свечей
   double high[], low[], open[], close[];
   datetime timeArray[];
   ArrayResize(high, copied);
   ArrayResize(low, copied);
   ArrayResize(open, copied);
   ArrayResize(close, copied);
   ArrayResize(timeArray, copied);
   for(int i = 0; i < copied; i++)
   {
      high[i]      = rates[i].high;
      low[i]       = rates[i].low;
      open[i]      = rates[i].open;
      close[i]     = rates[i].close;
      timeArray[i] = rates[i].time;
   }
   
   // Генерируем фракталы
   Fractal fractals[];
   Fractal filteredFractals[];
   ArrayResize(fractals, 0);
   ArrayResize(filteredFractals, 0);
   GenerateFractals(high, low, open, close, timeArray, copied, fractals, filteredFractals, limit);
   
   // Анализ трендов
   TrendAnalysis analysis = AnalyzeTrends(fractals);
   
   // Получаем значки в порядке LT, IT, ST
   string lt = TrendTypeToIcon(analysis.LongTerm);
   string it = TrendTypeToIcon(analysis.IntermediateTerm);
   string st = TrendTypeToIcon(analysis.ShortTerm);
   
   // Выводим данные только если внутри одного таймфрейма выполняется условие:
   // либо LT == IT, либо IT == ST (или все три равны)
   if( (analysis.LongTerm == analysis.IntermediateTerm && analysis.LongTerm != Neutral) || (analysis.IntermediateTerm == analysis.ShortTerm  && analysis.IntermediateTerm != Neutral) )
      return StringFormat("%s %s %s", lt, it, st);
      
   return ""; // иначе ничего не выводим
}

//+------------------------------------------------------------------+
//| Функция для сборки итогового текста панели                       |
//| Формирует строки вида:                                             |
//| SYMBOL | TF: LT IT ST | TF: LT IT ST | ...                         |
//+------------------------------------------------------------------+
string BuildFinalOutput()
{
   string finalText = "";
   string symbols[];
   GetSymbolsArray(symbols);
   
   ENUM_TIMEFRAMES timeframes[];
   GetTimeframesArray(timeframes);
   
   // Для каждого символа
   for(int i=0; i < ArraySize(symbols); i++)
   {
      string line = "";
      // Для каждого таймфрейма
      for(int j=0; j < ArraySize(timeframes); j++)
      {
         string res = AnalyzeSymbolTimeframe(symbols[i], timeframes[j]);
         if(StringLen(res) > 0)
         {
            line = symbols[i];
            line += " | " + EnumToString(timeframes[j]) + " : " + res + "\n";
         }
      }
      finalText += line;
   }
   return finalText;
}

//+------------------------------------------------------------------+
//| Функция для обновления панели (вывод итогового текста)             |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   // Собираем итоговый текст
   string panelText = BuildFinalOutput();
   
   Print(panelText);
}

//+------------------------------------------------------------------+
//| Функция OnInit: инициализация эксперта                           |
//+------------------------------------------------------------------+
int OnInit()
{
   UpdatePanel();
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Функция OnDeinit: очистка объектов при завершении работы           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete(0, "FinalPanel");
}

//+------------------------------------------------------------------+
//| Функция OnTick: (необязательно, если требуется динамическое обновление)|
//+------------------------------------------------------------------+
void OnTick()
{
   // Для динамического обновления можно вызвать UpdatePanel()
   // UpdatePanel();
}
