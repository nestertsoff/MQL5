#include <FractalLibrary.mqh> // Подключаем библиотеку фракталов

// Входные параметры для линий фракталов

input group "Long-Term (LT) Structure";
input bool showLtTrend = true;      // Show trend
input bool showLtTrendLabel = true; // Show trend type
input bool showLtFractals = true;   // Show fractals
input color ltColor = clrGreen;     // Line color
input int ltWidth = 2;              // Line width
input int ltPointSize = 2;          // Fractal point size

input group "Intermediate-Term (IT) Structure";
input bool showItTrend = true;      // Show trend
input bool showItTrendLabel = true; // Show trend type
input bool showItFractals = true;   // Show fractals
input color itColor = clrOrange;    // Line color
input int itWidth = 2;              // Line width
input int itPointSize = 2;          // Fractal point size

input group "Short-Term (ST) Structure";
input bool showStTrend = true;      // Show trend
input bool showStTrendLabel = true; // Show trend type
input bool showStFractals = true;   // Show fractals
input color stColor = clrBlack;     // Line color
input int stWidth = 2;              // Line width
input int stPointSize = 2;          // Fractal point size

input group "Common settings";
input int candlesLimit = 600; // Number of candles to calculate fractals
input string font_face = "Arial";
input int font_size = 20;

// Массив для хранения имён линий (чтобы их можно было удалять при перезапуске EA)
string lineNames[];

// Массив для хранения имён точек фракталов
string fractalPointNames[];

//+------------------------------------------------------------------+
//| Инициализация EA                                                 |
//+------------------------------------------------------------------+
int OnInit()
{
  DoMagic();
  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Деинициализация EA                                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Удаляем все нарисованные линии
  for (int i = 0; i < ArraySize(lineNames); i++)
    ObjectDelete(0, lineNames[i]);

  // Удаляем все нарисованные точки фракталов
  for (int i = 0; i < ArraySize(fractalPointNames); i++)
    ObjectDelete(0, fractalPointNames[i]);
}

//+------------------------------------------------------------------+
//| Основной обработчик событий (OnTick)                             |
//+------------------------------------------------------------------+
void OnTick()
{
  // DoMagic();
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

void DoMagic()
{
  // Получаем исторические данные (MqlRates) по текущему символу и таймфрейму
  MqlRates rates[];
  int copied = CopyRates(Symbol(), Period(), 0, candlesLimit, rates);
  if (copied < 3)
    return;

  // Количество полученных баров
  int count = ArraySize(rates);

  // Формируем массивы для high, low, open, close и time для расчёта фракталов
  double HighArray[], LowArray[], OpenArray[], CloseArray[];
  datetime TimeArray[];
  ArrayResize(HighArray, count);
  ArrayResize(LowArray, count);
  ArrayResize(OpenArray, count);
  ArrayResize(CloseArray, count);
  ArrayResize(TimeArray, count);

  for (int i = 0; i < count; i++)
  {
    HighArray[i] = rates[i].high;
    LowArray[i] = rates[i].low;
    OpenArray[i] = rates[i].open;
    CloseArray[i] = rates[i].close;
    TimeArray[i] = rates[i].time;
  }

  // Рассчитываем фракталы
  Fractal fractals[];
  Fractal filteredFractals[];
  ArrayResize(fractals, 0);
  ArrayResize(filteredFractals, 0);
  GenerateFractals(HighArray, LowArray, OpenArray, CloseArray, TimeArray, count, fractals, filteredFractals, candlesLimit);

  // Удаляем ранее нарисованные линии (если они есть)
  for (int i = 0; i < ArraySize(lineNames); i++)
    ObjectDelete(0, lineNames[i]);
  ArrayResize(lineNames, 0);

  // Удаляем ранее нарисованные точки
  for (int i = 0; i < ArraySize(fractalPointNames); i++)
    ObjectDelete(0, fractalPointNames[i]);
  ArrayResize(fractalPointNames, 0);

  // Рисуем линии фракталов (например, для отфильтрованных фракталов)
  DrawFractalLines(filteredFractals);

  // Отрисовываем точки для всех фракталов (неотфильтрованный массив)
  DrawFractalPoints(fractals);

  // Отображаем текст с трендами в левом верхнем углу
  DrawTrendLabels(filteredFractals);
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
//| Функция возвращает приоритет фрактала по типу                      |
//| Чем больше значение, тем старшая структура                        |
//+------------------------------------------------------------------+
int GetFractalPriority(Fractal &fractal)
{
  switch (fractal.Type)
  {
  case Lth:
  case Ltl:
    return 3; // старшая структура
  case Ith:
  case Itl:
    return 2;
  case Sth:
  case Stl:
    return 1;
  default:
    return 0;
  }
}

//+------------------------------------------------------------------+
//| Функция отрисовки точек (квадратиков) для фракталов               |
//| Отрисовывает для каждой свечи фрактал с наивысшим приоритетом      |
//+------------------------------------------------------------------+
void DrawFractalPoints(Fractal &fractals[])
{
  for (int i = 0; i < ArraySize(fractals); i++)
  {
    int size = 1;
    color clr = clrBlack;
    ENUM_ARROW_ANCHOR anchor = ANCHOR_TOP;
    bool skipDrawing = false;
    int zorder = 0;

    switch (fractals[i].Type)
    {
    case Sth:
      size = stPointSize;
      clr = stColor;
      anchor = ANCHOR_BOTTOM;
      skipDrawing = !showStFractals;
      break;
    case Stl:
      size = stPointSize;
      clr = stColor;
      anchor = ANCHOR_TOP;
      skipDrawing = !showStFractals;
      break;
    case Ith:
      size = itPointSize;
      clr = itColor;
      anchor = ANCHOR_BOTTOM;
      skipDrawing = !showItFractals;
      zorder = 100;
      break;
    case Itl:
      size = itPointSize;
      clr = itColor;
      anchor = ANCHOR_TOP;
      skipDrawing = !showItFractals;
      zorder = 100;
      break;
    case Lth:
      size = ltPointSize;
      clr = ltColor;
      anchor = ANCHOR_BOTTOM;
      skipDrawing = !showLtFractals;
      zorder = 200;
      break;
    case Ltl:
      size = ltPointSize;
      clr = ltColor;
      anchor = ANCHOR_TOP;
      skipDrawing = !showLtFractals;
      zorder = 200;
      break;
    default:
      break;
    }

    if (skipDrawing)
      continue;

    string pointName = StringFormat("FractalPoint_%d_%d", fractals[i].Index, fractals[i].Type);
    // Если объект с таким именем существует, удаляем его
    if (ObjectFind(0, pointName) != -1)
      ObjectDelete(0, pointName);

    // Создаём объект стрелки на позиции фрактала
    if (ObjectCreate(0, pointName, OBJ_ARROW, 0, fractals[i].Time, fractals[i].Value))
    {
      // Настраиваем свойства объекта-фрактала
      ObjectSetInteger(0, pointName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, pointName, OBJPROP_WIDTH, size);
      ObjectSetInteger(0, pointName, OBJPROP_ANCHOR, anchor);
      ObjectSetInteger(0, pointName, OBJPROP_ARROWCODE, 159);
      ObjectSetInteger(0, pointName, OBJPROP_ZORDER, zorder);

      // Сохраняем имя объекта для последующего удаления
      ArrayResize(fractalPointNames, ArraySize(fractalPointNames) + 1);
      fractalPointNames[ArraySize(fractalPointNames) - 1] = pointName;
    }
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

void DrawTrendLabels(Fractal &filteredFractals[])
{
  // Анализируем тренды по отфильтрованным фракталам
  TrendAnalysis analysis = AnalyzeTrends(filteredFractals);

  // Формируем текст для каждого тренда
  string shortTrendText = TrendTypeToString(analysis.ShortTerm);
  string intTrendText = TrendTypeToString(analysis.IntermediateTerm);
  string longTrendText = TrendTypeToString(analysis.LongTerm);

  // Удаляем ранее созданные объекты (если они существуют)
  if (ObjectFind(0, "TrendText_ST") != -1)
    ObjectDelete(0, "TrendText_ST");
  if (ObjectFind(0, "TrendText_IT") != -1)
    ObjectDelete(0, "TrendText_IT");
  if (ObjectFind(0, "TrendText_LT") != -1)
    ObjectDelete(0, "TrendText_LT");

  // Отрисовка текста для Long Term, если разрешено
  if (showLtTrendLabel)
  {
    if (ObjectCreate(0, "TrendText_LT", OBJ_LABEL, 0, 0, 0))
    {
      ObjectSetInteger(0, "TrendText_LT", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, "TrendText_LT", OBJPROP_XDISTANCE, 40);
      ObjectSetInteger(0, "TrendText_LT", OBJPROP_YDISTANCE, 320); // Смещаем ещё ниже
      ObjectSetString(0, "TrendText_LT", OBJPROP_TEXT, longTrendText);
      ObjectSetString(0, "TrendText_LT", OBJPROP_FONT, font_face);
      ObjectSetInteger(0, "TrendText_LT", OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(0, "TrendText_LT", OBJPROP_COLOR, ltColor);
    }
  }

  // Отрисовка текста для Intermediate Term, если разрешено
  if (showItTrendLabel)
  {
    if (ObjectCreate(0, "TrendText_IT", OBJ_LABEL, 0, 0, 0))
    {
      ObjectSetInteger(0, "TrendText_IT", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, "TrendText_IT", OBJPROP_XDISTANCE, 40);
      ObjectSetInteger(0, "TrendText_IT", OBJPROP_YDISTANCE, 350); // Смещаем ниже, чем ST
      ObjectSetString(0, "TrendText_IT", OBJPROP_TEXT, intTrendText);
      ObjectSetString(0, "TrendText_IT", OBJPROP_FONT, font_face);
      ObjectSetInteger(0, "TrendText_IT", OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(0, "TrendText_IT", OBJPROP_COLOR, itColor);
    }
  }

  // Отрисовка текста для Short Term, если разрешено
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
//| Функция преобразования TrendType в строку                        |
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
