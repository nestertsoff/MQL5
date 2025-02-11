#include <FractalLibrary.mqh>
#property indicator_chart_window

input color itColor = clrOrange; // IT Trend Color
input color ltColor = clrGreen;  // LT Trend Color

input int itWidth = 3; // IT Trend Width
input int ltWidth = 2; // LT Trend Width

input int candlesLimit = 600; // Canldes limit

string lineNames[];

//+------------------------------------------------------------------+
//| Инициализация индикатора                                        |
//+------------------------------------------------------------------+
int OnInit()
{
   return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   for (int i = 0; i < ArraySize(lineNames); i++)
   {
      ObjectDelete(0, lineNames[i]);
   }
}

//+------------------------------------------------------------------+
//| Основной расчет индикатора                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[],
                const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
   // Минимум 3 бара для анализа
   if (rates_total < 3)
      return (0);

   // Логика анализа фракталов
   Fractal fractals[];
   GenerateFractals(high, low, open, close, time, rates_total, fractals, candlesLimit);

   DrawFractalLines(fractals);

   return (rates_total);
}

void DrawFractalLines(Fractal &fractals[])
{
   // Массивы для разделения фракталов по структурам
   Fractal stFractals[], itFractals[], ltFractals[];

   // Разделяем фракталы по структурам
   for (int i = 0; i < ArraySize(fractals); i++)
   {
      switch (fractals[i].Type)
      {
      case Sth:
      case Stl:
         ArrayResize(stFractals, ArraySize(stFractals) + 1);
         stFractals[ArraySize(stFractals) - 1] = fractals[i];
         break;

      case Ith:
      case Itl:
         ArrayResize(itFractals, ArraySize(itFractals) + 1);
         itFractals[ArraySize(itFractals) - 1] = fractals[i];
         break;

      case Lth:
      case Ltl:
         ArrayResize(ltFractals, ArraySize(ltFractals) + 1);
         ltFractals[ArraySize(ltFractals) - 1] = fractals[i];
         break;

      default:
         break;
      }
   }

   // Рисуем линии для ST-фракталов
   //DrawFractalLinesForStructure(stFractals, itColor, stWidth);

   // Рисуем линии для IT-фракталов
   DrawFractalLinesForStructure(itFractals, itColor, itWidth);
  

   // Рисуем линии для LT-фракталов
   DrawFractalLinesForStructure(ltFractals, ltColor, ltWidth);
}

//+------------------------------------------------------------------+
//| Рисуем линии для заданной структуры                             |
//+------------------------------------------------------------------+
void DrawFractalLinesForStructure(Fractal &fractals[], color clr, int width)
{
   for (int i = 1; i < ArraySize(fractals); i++)
   {
      // Соединяем текущий фрактал с предыдущим
      string lineName = StringFormat("FractalLine_%d_%d", fractals[i - 1].Index, fractals[i].Index);
      
      ArrayResize(lineNames, ArraySize(lineNames) + 1);
      lineNames[ArraySize(lineNames) - 1] = lineName;

      DrawLine(lineName, fractals[i - 1].Time, fractals[i - 1].Value,
               fractals[i].Time, fractals[i].Value, clr, width);
   }
}

//+------------------------------------------------------------------+
//| Вспомогательная функция для рисования линии                     |
//+------------------------------------------------------------------+
void DrawLine(string name, datetime time1, double price1, datetime time2, double price2, color clr, int width)
{
   // Удаляем старую линию, если она есть
   if (ObjectFind(0, name) != -1)
      ObjectDelete(0, name);

   // Создаём линию
   ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);

   // Настраиваем стиль линии
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY, false); // Линия без продолжения
}
