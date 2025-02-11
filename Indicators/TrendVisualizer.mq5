//+------------------------------------------------------------------+
//|                                             FractalsIndicator.mq5  |
//|                 Индикатор отображающий фракталы через буферы       |
//+------------------------------------------------------------------+
#property version "1.05"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots 6

//--- Определяем свойства plot-ов с константными значениями.
#property indicator_label1 "Sth"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrBlack
#property indicator_width1 2
#property indicator_style1 STYLE_SOLID

#property indicator_label2 "Stl"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrBlack
#property indicator_width2 2
#property indicator_style2 STYLE_SOLID

#property indicator_label3 "Ith"
#property indicator_type3 DRAW_ARROW
#property indicator_color3 clrOrange
#property indicator_width3 2
#property indicator_style3 STYLE_SOLID

#property indicator_label4 "Itl"
#property indicator_type4 DRAW_ARROW
#property indicator_color4 clrOrange
#property indicator_width4 2
#property indicator_style4 STYLE_SOLID

#property indicator_label5 "Lth"
#property indicator_type5 DRAW_ARROW
#property indicator_color5 clrGreen
#property indicator_width5 2
#property indicator_style5 STYLE_SOLID

#property indicator_label6 "Ltl"
#property indicator_type6 DRAW_ARROW
#property indicator_color6 clrGreen
#property indicator_width6 2
#property indicator_style6 STYLE_SOLID

//--- Подключаем библиотеку фракталов (убедитесь, что FractalLibrary.mqh находится в Include)
#include <FractalLibrary.mqh>
#include <GapLibrary.mqh>

//--- Входные параметры (настройки отображения)
input group "Long-Term (LT) Structure";
input bool showLtTrend = true;      // Показывать линию тренда LT
input bool showLtTrendLabel = true; // Показывать текстовую метку LT
input bool showLtFractals = true;   // Отображать фракталы LT
input color ltColor = clrGreen;     // Цвет LT фракталов
input int ltWidth = 2;              // Ширина линии для LT
input int ltPointSize = 2;          // Размер точки для LT

input group "Intermediate-Term (IT) Structure";
input bool showItTrend = true;      // Показывать линию тренда IT
input bool showItTrendLabel = true; // Показывать текстовую метку IT
input bool showItFractals = true;   // Отображать фракталы IT
input color itColor = clrOrange;    // Цвет IT фракталов
input int itWidth = 2;              // Ширина линии для IT
input int itPointSize = 2;          // Размер точки для IT

input group "Short-Term (ST) Structure";
input bool showStTrend = true;      // Показывать линию тренда ST
input bool showStTrendLabel = true; // Показывать текстовую метку ST
input bool showStFractals = true;   // Отображать фракталы ST
input color stColor = clrBlack;     // Цвет ST фракталов (и метки)
input int stWidth = 2;              // Ширина линии для ST
input int stPointSize = 2;          // Размер точки для ST

int candlesLimit = 600;     // Количество свечей для расчёта фракталов
string font_face = "Arial"; // Шрифт для меток трендов
int font_size = 20;         // Размер шрифта для меток трендов

//--- Глобальные буферы индикатора
double Buffer_Sth[];
double Buffer_Stl[];
double Buffer_Ith[];
double Buffer_Itl[];
double Buffer_Lth[];
double Buffer_Ltl[];

string lineNames[];
string gapObjNames[];
Gap gaps[];

//+------------------------------------------------------------------+
//| Инициализация индикатора                                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Связываем буферы с plot-ами
   SetIndexBuffer(0, Buffer_Sth, INDICATOR_DATA);
   SetIndexBuffer(1, Buffer_Stl, INDICATOR_DATA);
   SetIndexBuffer(2, Buffer_Ith, INDICATOR_DATA);
   SetIndexBuffer(3, Buffer_Itl, INDICATOR_DATA);
   SetIndexBuffer(4, Buffer_Lth, INDICATOR_DATA);
   SetIndexBuffer(5, Buffer_Ltl, INDICATOR_DATA);

   // Устанавливаем динамические свойства plot-ов на основе входных параметров
   // Для фракталов Short-Term (plots 0 и 1)
   PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, -10);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, (uint)stColor);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, stPointSize);

   PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, 10);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, (uint)stColor);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, stPointSize);

   // Для фракталов Intermediate-Term (plots 2 и 3)
   PlotIndexSetInteger(2, PLOT_ARROW_SHIFT, -10);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, (uint)itColor);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, itPointSize);

   PlotIndexSetInteger(3, PLOT_ARROW_SHIFT, 10);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, (uint)itColor);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, itPointSize);

   // Для фракталов Long-Term (plots 4 и 5)
   PlotIndexSetInteger(4, PLOT_ARROW_SHIFT, -10);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, (uint)ltColor);
   PlotIndexSetInteger(4, PLOT_LINE_WIDTH, ltPointSize);

   PlotIndexSetInteger(5, PLOT_ARROW_SHIFT, 10);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, (uint)ltColor);
   PlotIndexSetInteger(5, PLOT_LINE_WIDTH, ltPointSize);

   return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Деинициализация индикатора                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Удаляем все нарисованные линии
   for (int i = 0; i < ArraySize(lineNames); i++)
      ObjectDelete(0, lineNames[i]);

   for (int i = 0; i < ArraySize(gapObjNames); i++)
      ObjectDelete(0, gapObjNames[i]);

   // Удаляем метки трендов, аналогично тому, как удаляются линии
   if (ObjectFind(0, "TrendText_ST") != -1)
      ObjectDelete(0, "TrendText_ST");
   if (ObjectFind(0, "TrendText_IT") != -1)
      ObjectDelete(0, "TrendText_IT");
   if (ObjectFind(0, "TrendText_LT") != -1)
      ObjectDelete(0, "TrendText_LT");
}

//+------------------------------------------------------------------+
//| Основная функция расчёта индикатора (OnCalculate)                |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Если баров меньше, чем установлено во входном параметре — выходим
   if (rates_total < candlesLimit)
      return (0);

   if (IsNewCandle())
   {

      // Обнуляем все буферы (заполняем значением EMPTY_VALUE)
      ArrayInitialize(Buffer_Sth, EMPTY_VALUE);
      ArrayInitialize(Buffer_Stl, EMPTY_VALUE);
      ArrayInitialize(Buffer_Ith, EMPTY_VALUE);
      ArrayInitialize(Buffer_Itl, EMPTY_VALUE);
      ArrayInitialize(Buffer_Lth, EMPTY_VALUE);
      ArrayInitialize(Buffer_Ltl, EMPTY_VALUE);

      // Удаляем ранее нарисованные линии, чтобы старые объекты не накапливались
      for (int i = 0; i < ArraySize(lineNames); i++)
         ObjectDelete(0, lineNames[i]);
      ArrayResize(lineNames, 0);

      // Рассчитываем фракталы используя входные массивы OHLC и time.
      // Функция GenerateFractals из FractalLibrary.mqh должна вернуть два массива:
      // - fractals: все найденные фракталы
      // - filteredFractals: отфильтрованные фракталы (для анализа трендов)
      Fractal fractals[];
      Fractal filteredFractals[];
      ArrayResize(fractals, 0);
      ArrayResize(filteredFractals, 0);
      GenerateFractals(high, low, open, close, time, rates_total, fractals, filteredFractals, candlesLimit);

      CreateGapsFromCandles(high, low, open, close, time, rates_total, gaps);

      // Заполняем индикаторные буферы согласно типу фрактала.
      for (int i = 0; i < ArraySize(fractals); i++)
      {
         // Если индекс фрактала выходит за пределы массива баров — пропускаем
         if (fractals[i].Index < 0 || fractals[i].Index >= rates_total)
            continue;

         switch (fractals[i].Type)
         {
         case Sth:
            if (showStFractals)
               Buffer_Sth[fractals[i].Index] = fractals[i].Value;
            break;
         case Stl:
            if (showStFractals)
               Buffer_Stl[fractals[i].Index] = fractals[i].Value;
            break;
         case Ith:
            if (showItFractals)
               Buffer_Ith[fractals[i].Index] = fractals[i].Value;
            break;
         case Itl:
            if (showItFractals)
               Buffer_Itl[fractals[i].Index] = fractals[i].Value;
            break;
         case Lth:
            if (showLtFractals)
               Buffer_Lth[fractals[i].Index] = fractals[i].Value;
            break;
         case Ltl:
            if (showLtFractals)
               Buffer_Ltl[fractals[i].Index] = fractals[i].Value;
            break;
         default:
            break;
         }
      }

      // Отрисовка меток трендов и линий фракталов
      DrawTrendLabels(filteredFractals);
      DrawFractalLines(filteredFractals);
   }

   CheckAndAlertGaps(gaps, high, low, open, close, time, rates_total);
   return (rates_total);
}

void CheckAndAlertGaps(const Gap &gaps[], const double &high[], const double &low[], const double &open[], const double &close[], const datetime &time[], int rates_total)
{
   static datetime lastPrintedBarTime = 0;
   int actualIndex = rates_total - 1;

   if (time[actualIndex] != lastPrintedBarTime)
   {
      Gap testingGaps[];
      GetGapsTestedByCandle(gaps, high[actualIndex], low[actualIndex], open[actualIndex], close[actualIndex], time[actualIndex], testingGaps);

      DrawGaps(testingGaps);

      // Значит, это новый бар -> Можно выполнить печать один раз
      if (ArraySize(testingGaps) > 0)
      {
         for (int i = 0; i < ArraySize(testingGaps); i++)
         {
            string msg = testingGaps[i].Type == GapType_Bullish ? "▲" : "▼";
            Alert(msg);

            // Проиграть кастомный звук (например, "my_alert.wav")
            PlaySound("chest.wav");
         }
         // Запоминаем время этого бара как "уже обработанного"
         lastPrintedBarTime = time[actualIndex];
      }
   }
}

bool IsNewCandle()
{
   // Получаем время текущего бара (незавершённый, индекс 0)
   datetime currentTime = iTime(Symbol(), Period(), 0);

   // Статическая переменная для хранения времени последнего бара
   static datetime lastCandleTime = 0;

   // Если время текущей свечи отличается от сохранённого, значит появилась новая свеча
   if (currentTime != lastCandleTime)
   {
      lastCandleTime = currentTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Функция разделения фракталов по типам и отрисовки линий           |
//+------------------------------------------------------------------+
void DrawFractalLines(Fractal &fractals[])
{
   // Здесь разделяем фракталы по структурам.
   // В примере рисуются линии только для IT- и LT-фракталов.
   Fractal stFractals[], itFractals[], ltFractals[];

   for (int i = 0; i < ArraySize(fractals); i++)
   {
      switch (fractals[i].Type)
      {
      case Sth:
      case Stl:
         if (showStTrend)
         {
            ArrayResize(stFractals, ArraySize(stFractals) + 1);
            stFractals[ArraySize(stFractals) - 1] = fractals[i];
         }
         break;
      case Ith:
      case Itl:
         if (showItTrend)
         {
            ArrayResize(itFractals, ArraySize(itFractals) + 1);
            itFractals[ArraySize(itFractals) - 1] = fractals[i];
         }
         break;
      case Lth:
      case Ltl:
         if (showLtTrend)
         {
            ArrayResize(ltFractals, ArraySize(ltFractals) + 1);
            ltFractals[ArraySize(ltFractals) - 1] = fractals[i];
         }
         break;
      default:
         break;
      }
   }

   if (showStTrend)
      DrawFractalLinesForStructure(stFractals, stColor, stWidth);

   if (showItTrend)
      DrawFractalLinesForStructure(itFractals, itColor, itWidth);

   if (showLtTrend)
      DrawFractalLinesForStructure(ltFractals, ltColor, ltWidth);
}

//+------------------------------------------------------------------+
//| Функция отрисовки линий для заданной группы фракталов             |
//+------------------------------------------------------------------+
void DrawFractalLinesForStructure(Fractal &fractals[], color clr, int width)
{
   // Начинаем с i = 1, чтобы соединить каждый фрактал с предыдущим
   for (int i = 1; i < ArraySize(fractals); i++)
   {
      string lineName = StringFormat("FractalLine_%d_%d", fractals[i - 1].Index, fractals[i].Index);
      ArrayResize(lineNames, ArraySize(lineNames) + 1);
      lineNames[ArraySize(lineNames) - 1] = lineName;
      DrawLine(lineName, fractals[i - 1].Time, fractals[i - 1].Value,
               fractals[i].Time, fractals[i].Value, clr, width);
   }
}

//+------------------------------------------------------------------+
//| Вспомогательная функция рисования линии                          |
//+------------------------------------------------------------------+
void DrawLine(string name, datetime time1, double price1,
              datetime time2, double price2, color clr, int width)
{
   // Удаляем старую линию (если существует)
   if (ObjectFind(0, name) != -1)
      ObjectDelete(0, name);

   // Создаём трендовую линию
   ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);

   // Настраиваем свойства линии
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
}

//+------------------------------------------------------------------+
//| Функция отрисовки меток трендов (Label)                          |
//| Создаются три объекта: для Short-Term, Intermediate-Term и Long-Term |
//+------------------------------------------------------------------+
void DrawTrendLabels(Fractal &filteredFractals[])
{
   // Анализируем тренды по отфильтрованным фракталам
   TrendAnalysis analysis = AnalyzeTrends(filteredFractals);

   // Формируем текст для каждого тренда
   string shortTrendText = TrendTypeToString(analysis.ShortTerm);
   string intTrendText = TrendTypeToString(analysis.IntermediateTerm);
   string longTrendText = TrendTypeToString(analysis.LongTerm);

   // Удаляем ранее созданные объекты меток, если они существуют
   if (ObjectFind(0, "TrendText_ST") != -1)
      ObjectDelete(0, "TrendText_ST");
   if (ObjectFind(0, "TrendText_IT") != -1)
      ObjectDelete(0, "TrendText_IT");
   if (ObjectFind(0, "TrendText_LT") != -1)
      ObjectDelete(0, "TrendText_LT");

   // Отрисовка метки для Long-Term, если включено
   if (showLtTrendLabel)
   {
      if (ObjectCreate(0, "TrendText_LT", OBJ_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, "TrendText_LT", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
         ObjectSetInteger(0, "TrendText_LT", OBJPROP_XDISTANCE, 40);
         ObjectSetInteger(0, "TrendText_LT", OBJPROP_YDISTANCE, 320);
         ObjectSetString(0, "TrendText_LT", OBJPROP_TEXT, longTrendText);
         ObjectSetString(0, "TrendText_LT", OBJPROP_FONT, font_face);
         ObjectSetInteger(0, "TrendText_LT", OBJPROP_FONTSIZE, font_size);
         ObjectSetInteger(0, "TrendText_LT", OBJPROP_COLOR, ltColor);
      }
   }

   // Отрисовка метки для Intermediate-Term, если включено
   if (showItTrendLabel)
   {
      if (ObjectCreate(0, "TrendText_IT", OBJ_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, "TrendText_IT", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
         ObjectSetInteger(0, "TrendText_IT", OBJPROP_XDISTANCE, 40);
         ObjectSetInteger(0, "TrendText_IT", OBJPROP_YDISTANCE, 350);
         ObjectSetString(0, "TrendText_IT", OBJPROP_TEXT, intTrendText);
         ObjectSetString(0, "TrendText_IT", OBJPROP_FONT, font_face);
         ObjectSetInteger(0, "TrendText_IT", OBJPROP_FONTSIZE, font_size);
         ObjectSetInteger(0, "TrendText_IT", OBJPROP_COLOR, itColor);
      }
   }

   // Отрисовка метки для Short-Term, если включено
   if (showStTrendLabel)
   {
      if (ObjectCreate(0, "TrendText_ST", OBJ_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, "TrendText_ST", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
         ObjectSetInteger(0, "TrendText_ST", OBJPROP_XDISTANCE, 40);
         ObjectSetInteger(0, "TrendText_ST", OBJPROP_YDISTANCE, 380);
         ObjectSetString(0, "TrendText_ST", OBJPROP_TEXT, shortTrendText);
         ObjectSetString(0, "TrendText_ST", OBJPROP_FONT, font_face);
         ObjectSetInteger(0, "TrendText_ST", OBJPROP_FONTSIZE, font_size);
         ObjectSetInteger(0, "TrendText_ST", OBJPROP_COLOR, stColor);
      }
   }
}

//+------------------------------------------------------------------+
//| Функция преобразования значения TrendType в строку               |
//+------------------------------------------------------------------+
string TrendTypeToString(TrendType type)
{
   switch (type)
   {
   case Neutral:
      return "⏩";
   case Uptrend:
      return "⏫";
   case Downtrend:
      return "⏬";
   default:
      return "Unknown";
   }
}
//+------------------------------------------------------------------+

void DrawGaps(const Gap &gaps[])
{
   // 1. Удаляем старые объекты гепов
   for (int i = 0; i < ArraySize(gapObjNames); i++)
      ObjectDelete(0, gapObjNames[i]);
   ArrayResize(gapObjNames, 0);

   // 2. Рисуем новые
   for (int i = 0; i < ArraySize(gaps); i++)
   {
      // Определяем цвет по типу гепа
      color gapColor = (gaps[i].Type == GapType_Bullish) ? clrGreen : clrRed;

      // --------------------------------------------------------------------------------
      // Первый луч (по нижней границе гепа)
      // --------------------------------------------------------------------------------
      string rayLowName = StringFormat("GapRayLow_%d", i);

      // Создаём OBJ_TREND: указываем две точки на одной горизонтали (Low),
      // и включаем Ray_Right = true, чтобы луч продолжался вправо.
      if (ObjectCreate(0, rayLowName, OBJ_TREND, 0,
                       gaps[i].StartTime, gaps[i].Low,
                       // Вторую точку ставим где-то правее, но на той же цене
                       gaps[i].EndTime, gaps[i].Low))
      {
         // Задаём свойства
         ObjectSetInteger(0, rayLowName, OBJPROP_COLOR, gapColor);
         ObjectSetInteger(0, rayLowName, OBJPROP_WIDTH, 1);
         // Включаем "луч вправо"
         ObjectSetInteger(0, rayLowName, OBJPROP_RAY_RIGHT, true);

         // Сохраняем имя для удаления в будущем
         int newSize = ArraySize(gapObjNames) + 1;
         ArrayResize(gapObjNames, newSize);
         gapObjNames[newSize - 1] = rayLowName;
      }

      // --------------------------------------------------------------------------------
      // Второй луч (по верхней границе гепа)
      // --------------------------------------------------------------------------------
      string rayHighName = StringFormat("GapRayHigh_%d", i);

      if (ObjectCreate(0, rayHighName, OBJ_TREND, 0,
                       gaps[i].StartTime, gaps[i].High,
                       gaps[i].EndTime, gaps[i].High))
      {
         ObjectSetInteger(0, rayHighName, OBJPROP_COLOR, gapColor);
         ObjectSetInteger(0, rayHighName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, rayHighName, OBJPROP_RAY_RIGHT, true);

         int newSize = ArraySize(gapObjNames) + 1;
         ArrayResize(gapObjNames, newSize);
         gapObjNames[newSize - 1] = rayHighName;
      }
   }
}