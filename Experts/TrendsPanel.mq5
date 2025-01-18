//+------------------------------------------------------------------+
//|            Пример эксперта: фракталы, тренды и GUI-кнопки       |
//+------------------------------------------------------------------+
#property script_show_inputs
#property strict

#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Button.mqh>
#include <Strings\String.mqh>

// Подключаем библиотеку для фракталов/трендов
#include <FractalLibrary.mqh>   // Или "FractalLibrary.mqh" если в той же папке

//--- Входные параметры
input string InpSymbolsList   = "BTCUSD,ETHUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,NZDUSD,USDCHF,USDCAD,EURGBP,EURJPY,GBPJPY,CHFJPY,AUDJPY,AUDNZD,CADJPY,EURCAD,EURAUD,GBPCAD,GBPAUD,NZDJPY,AUDCAD,XAUUSD,XAGUSD";  
input string InpTimeframes    = "M1,M5,M15,H1,H4,D1";              

// Константы и настройки GUI
#define PANEL_NAME       "Trends Dashboard"
#define ROW_HEIGHT       25
#define COL_MARGIN       10       // Отступ между элементами в строке
#define ROW_MARGIN       10       // Отступ по вертикали между строками

// Главный диалог
CAppDialog app;

//------------------------------------------------------------------+
// Глобальные массивы
string g_symbols[];      // [symCount]
string g_timeframes[];   // [tfCount]

// ID вкладки по каждому символу (один чарт на символ)
long   g_chart_ids[];    // [symCount]

// Лейблы таймфреймов (верхняя строка)
CLabel *g_labelTimeframes[];  // [tfCount]

// Лейблы символов (левый столбец)
CLabel *g_labelSymbols[];     // [symCount]

// Кнопки - всего symCount * tfCount
CButton *g_tfButtons[];       // [symCount*tfCount]

// Храним время последнего бара для (символ, таймфрейм)
datetime g_lastBarTime[];     // [symCount*tfCount]

//------------------------------------------------------------------+
// Получаем размеры текущего окна (чарта)
int GetChartWidth()  { return 10000; }
int GetChartHeight() { return 10000; }

//------------------------------------------------------------------+
// Парсим входные строки символов и таймфреймов
bool ParseInputs()
{
   // Символы
   if(StringSplit(InpSymbolsList, ',', g_symbols) < 1)
   {
      Print("Пустой список символов!");
      return false;
   }
   // Таймфреймы
   if(StringSplit(InpTimeframes, ',', g_timeframes) < 1)
   {
      Print("Пустой список таймфреймов!");
      return false;
   }
   return true;
}

//------------------------------------------------------------------+
// Переводим строковый таймфрейм (например "M5") в ENUM_TIMEFRAMES
ENUM_TIMEFRAMES ParseTimeframe(const string tf)
{
   if(tf=="M1")    return(PERIOD_M1);
   if(tf=="M5")    return(PERIOD_M5);
   if(tf=="M15")   return(PERIOD_M15);
   if(tf=="M30")   return(PERIOD_M30);
   if(tf=="H1")    return(PERIOD_H1);
   if(tf=="H4")    return(PERIOD_H4);
   if(tf=="D1")    return(PERIOD_D1);
   if(tf=="W1")    return(PERIOD_W1);
   if(tf=="MN1")   return(PERIOD_MN1);

   return(PERIOD_CURRENT);
}

//------------------------------------------------------------------+
// TrendType -> символ
string TrendTypeToString(TrendType type)
{
   switch(type)
   {
   case Uptrend:   return "⏫";
   case Downtrend: return "⏬";
   case Neutral:   return "⏩";
   }
   return "?";
}

//------------------------------------------------------------------+
// Получаем TrendAnalysis И строку трендов (Long->Intermediate->Short)
// Возвращаем строку, а объект TrendAnalysis — через &outTa
//------------------------------------------------------------------+
string CalculateTrendStringAndAnalysis(const string symbol,
                                       const ENUM_TIMEFRAMES tf,
                                       TrendAnalysis &outTa)
{
   // Возьмём ~600 баров
   int need_bars = 600;

   MqlRates rates[];
   int copied = CopyRates(symbol, tf, 0, need_bars, rates);
   if(copied < 5)
   {
      outTa.ShortTerm = Neutral;
      outTa.IntermediateTerm = Neutral;
      outTa.LongTerm = Neutral;
      return "NoBars";
   }

   // Разворачиваем в отдельные массивы
   double high[], low[], open[], close[];
   datetime time[];
   ArrayResize(high,   copied);
   ArrayResize(low,    copied);
   ArrayResize(open,   copied);
   ArrayResize(close,  copied);
   ArrayResize(time,   copied);

   for(int i=0; i<copied; i++)
   {
      high[i]  = rates[i].high;
      low[i]   = rates[i].low;
      open[i]  = rates[i].open;
      close[i] = rates[i].close;
      time[i]  = rates[i].time;
   }

   Fractal allFractals[], filtered[];
   GenerateFractals(high, low, open, close, time, copied, allFractals, filtered, need_bars);

   // Получаем тренды
   outTa = AnalyzeTrends(filtered);

   // Формируем строку: LongTerm -> IntermediateTerm -> ShortTerm
   string result = TrendTypeToString(outTa.LongTerm)
                 + TrendTypeToString(outTa.IntermediateTerm)
                 + TrendTypeToString(outTa.ShortTerm);

   return result;
}

//------------------------------------------------------------------+
// Проверяем, появился ли новый бар на (i, j). 
// Если да — пересчитываем, обновляем текст кнопки + цвет рамки.
//------------------------------------------------------------------+
void CheckNewBarAndUpdate(const int i, const int j)
{
   int tfCount = ArraySize(g_timeframes);
   int indexBtn = i*tfCount + j;

   string symbol = g_symbols[i];
   ENUM_TIMEFRAMES tf = ParseTimeframe(g_timeframes[j]);

   datetime currentBarTime = iTime(symbol, tf, 0);
   if(currentBarTime <= 0)
      return;  // нет данных

   if(currentBarTime != g_lastBarTime[indexBtn])
   {
      // Новая свеча, обновим
      g_lastBarTime[indexBtn] = currentBarTime;

      // Получаем TrendAnalysis + итоговую строку
      TrendAnalysis ta;
      string trendStr = CalculateTrendStringAndAnalysis(symbol, tf, ta);

      // Обновляем текст кнопки
      if(g_tfButtons[indexBtn] != NULL)
         g_tfButtons[indexBtn].Text(trendStr);

      // --------------------------
      // Определяем, синхронизированы ли тренды
      // (ваш критерий: ST=IT или IT=LT) и не Neutral
      // --------------------------
      bool isSynced = false;
      TrendType syncTrend = Neutral;

      // Проверяем ST=IT
      if(ta.ShortTerm == ta.IntermediateTerm && ta.ShortTerm!=Neutral)
      {
         isSynced   = true;
         syncTrend  = ta.ShortTerm;
      }
      // Если не совпали, проверяем IT=LT
      else if(ta.IntermediateTerm == ta.LongTerm && ta.IntermediateTerm!=Neutral)
      {
         isSynced  = true;
         syncTrend = ta.IntermediateTerm;
      }

      // Если синхронизированы — меняем цвет рамки
      if(isSynced && g_tfButtons[indexBtn] != NULL)
      {
         if(syncTrend == Uptrend)
         {
            // Зелёная рамка
            g_tfButtons[indexBtn].ColorBackground(C'171,235,198');  
         }
         else if(syncTrend == Downtrend)
         {
            // Красная рамка
            g_tfButtons[indexBtn].ColorBackground(C'230,176,170');
         }
      }
      else
      {
        //g_tfButtons[indexBtn].Hide();
      }
   }
}

//------------------------------------------------------------------+
// Функция, открывающая или переключающая вкладку
// одного символа (g_chart_ids[i]) на нужный TF
//------------------------------------------------------------------+
void OpenOrChangeChart(const int symIndex, const ENUM_TIMEFRAMES tf)
{
   if(symIndex < 0 || symIndex >= ArraySize(g_symbols))
      return;

   string sym = g_symbols[symIndex];

   // Если чарт ещё не открыт
   if(g_chart_ids[symIndex] == -1)
   {
      long new_chart_id = ChartOpen(sym, tf);
      if(new_chart_id > 0)
      {
         g_chart_ids[symIndex] = new_chart_id;
         // Вперёд
         ChartSetInteger(new_chart_id, CHART_BRING_TO_TOP, true);
      }
      else
      {
         Print("Не удалось открыть чарт для ", sym, " / ", EnumToString(tf));
      }
   }
   else
   {
      // Уже открыт, меняем TF
      long cid = g_chart_ids[symIndex];
      bool res = ChartSetSymbolPeriod(cid, sym, tf);
      if(!res)
      {
         Print("Не удалось сменить TF (", EnumToString(tf), ") для ", sym, " (chart_id=", cid, ")");
      }
      else
      {
         // Поднимаем вкладку
         ChartSetInteger(cid, CHART_BRING_TO_TOP, true);
      }
   }
}

//------------------------------------------------------------------+
// OnInit
//------------------------------------------------------------------+
int OnInit()
{
   if(!ParseInputs()) 
      return(INIT_FAILED);

   int symCount = ArraySize(g_symbols);
   int tfCount  = ArraySize(g_timeframes);

   if(symCount<1 || tfCount<1)
      return(INIT_FAILED);

   // Ресайз глобальных массивов
   ArrayResize(g_labelTimeframes, tfCount);
   ArrayResize(g_labelSymbols,    symCount);
   ArrayResize(g_tfButtons,       symCount*tfCount);
   ArrayResize(g_chart_ids,       symCount);
   ArrayResize(g_lastBarTime,     symCount*tfCount);

   // Инициализируем
   for(int i=0; i<symCount; i++)
      g_chart_ids[i] = -1;
   for(int n=0; n<symCount*tfCount; n++)
      g_lastBarTime[n] = 0;

   // Создаём диалог
   int w = GetChartWidth();
   int h = GetChartHeight();
   app.Create(0, PANEL_NAME, 0, 0, 0, w, h);

   // Верхняя строка (таймфреймы)
   int headerTop   = 0;
   int headerLeft  = 80;   
   int tfLabelW    = 60;   

   for(int j=0; j<tfCount; j++)
   {
      g_labelTimeframes[j] = new CLabel;
      if(g_labelTimeframes[j] != NULL)
      {
         string lblName = "TF_Label_"+(string)j;
         int left  = headerLeft + j*(tfLabelW + COL_MARGIN);
         int right = left + tfLabelW;

         g_labelTimeframes[j].Create(0, lblName, 0,
                                     left, headerTop,
                                     right, headerTop + ROW_HEIGHT);

         g_labelTimeframes[j].Text(g_timeframes[j]);
         app.Add(*g_labelTimeframes[j]);
      }
   }

   // Левый столбец (символы) + кнопки
   int currentTop = ROW_HEIGHT + ROW_MARGIN;
   for(int i=0; i<symCount; i++)
   {
      // Лейбл символа
      g_labelSymbols[i] = new CLabel;
      if(g_labelSymbols[i] != NULL)
      {
         string symLblName = "Sym_Label_"+(string)i;
         int left  = 5;
         int right = left + 70;

         g_labelSymbols[i].Create(0, symLblName, 0,
                                  left, currentTop,
                                  right, currentTop + ROW_HEIGHT);

         g_labelSymbols[i].Text(g_symbols[i]);
         app.Add(*g_labelSymbols[i]);
      }

      // Кнопки (по таймфреймам)
      for(int j=0; j<tfCount; j++)
      {
         int indexBtn = i*tfCount + j;
         g_tfButtons[indexBtn] = new CButton;
         if(g_tfButtons[indexBtn] != NULL)
         {
            string btnName = "BTN_" + IntegerToString(i) + "_" + IntegerToString(j);

            int left  = headerLeft + j*(tfLabelW + COL_MARGIN);
            int top   = currentTop;
            int right = left + tfLabelW;
            int bot   = top + ROW_HEIGHT;

            g_tfButtons[indexBtn].Create(0, btnName, 0, left, top, right, bot);
            g_tfButtons[indexBtn].Text("...");

            app.Add(*g_tfButtons[indexBtn]);
         }
      }
      currentTop += (ROW_HEIGHT + ROW_MARGIN);
   }

   Print("Инициализация завершена: Symbols=", symCount, ", Timeframes=", tfCount);
   return(INIT_SUCCEEDED);
}

//------------------------------------------------------------------+
// OnDeinit
//------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Если нужно закрыть все вкладки:
   //for(int i=0; i<ArraySize(g_chart_ids); i++)
   //{
   //   if(g_chart_ids[i] != -1)
   //      ChartClose(g_chart_ids[i]);
   //}

   // Удаляем объекты
   for(int i=0; i<ArraySize(g_labelTimeframes); i++)
   {
      if(g_labelTimeframes[i] != NULL)
      {
         delete g_labelTimeframes[i];
         g_labelTimeframes[i] = NULL;
      }
   }
   for(int i=0; i<ArraySize(g_labelSymbols); i++)
   {
      if(g_labelSymbols[i] != NULL)
      {
         delete g_labelSymbols[i];
         g_labelSymbols[i] = NULL;
      }
   }
   for(int k=0; k<ArraySize(g_tfButtons); k++)
   {
      if(g_tfButtons[k] != NULL)
      {
         delete g_tfButtons[k];
         g_tfButtons[k] = NULL;
      }
   }
   // app.Destroy(); // если нужно явно
}

//------------------------------------------------------------------+
// OnTick: при каждом тике проверяем новые бары для (символ, TF)
//------------------------------------------------------------------+
void OnTick()
{
   int symCount = ArraySize(g_symbols);
   int tfCount  = ArraySize(g_timeframes);

   for(int i=0; i<symCount; i++)
   {
      for(int j=0; j<tfCount; j++)
      {
         CheckNewBarAndUpdate(i, j);
      }
   }
}

//------------------------------------------------------------------+
// OnChartEvent: реагируем на клики по кнопкам -> открываем/переключаем вкладку
//------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Ищем префикс "BTN_"
      string prefix = "BTN_";
      if(StringFind(sparam, prefix, 0) == 0)
      {
         // формат: BTN_i_j
         string indices = StringSubstr(sparam, StringLen(prefix));
         int pos_ = StringFind(indices, "_", 0);
         if(pos_>0)
         {
            string strI = StringSubstr(indices, 0, pos_);
            string strJ = StringSubstr(indices, pos_+1);

            int i = (int)StringToInteger(strI);
            int j = (int)StringToInteger(strJ);

            if(i>=0 && i<ArraySize(g_symbols) && j>=0 && j<ArraySize(g_timeframes))
            {
               ENUM_TIMEFRAMES tf = ParseTimeframe(g_timeframes[j]);
               OpenOrChangeChart(i, tf);
            }
         }
      }
   }
}
