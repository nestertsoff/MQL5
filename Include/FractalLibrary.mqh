//+------------------------------------------------------------------+
//|                      FractalLibrary.mqh                          |
//|         Упрощённая библиотека для работы с фракталами           |
//+------------------------------------------------------------------+
#ifndef __FRACTAL_LIBRARY__
#define __FRACTAL_LIBRARY__

//--- Перечисление типов фракталов
enum FractalType
{
   Sth, // Бычий ST
   Stl, // Медвежий ST
   Ith, // Бычий IT
   Itl, // Медвежий IT
   Lth, // Бычий LT
   Ltl  // Медвежий LT
};

//--- Структура фрактала
struct Fractal
{
   FractalType Type;
   datetime Time;
   double Value;
   int Index;
};

//--- Перечисление типов тренда
enum TrendType
{
   Neutral,
   Uptrend,
   Downtrend
};

//--- Структура анализа трендов
struct TrendAnalysis
{
   TrendType ShortTerm;
   TrendType IntermediateTerm;
   TrendType LongTerm;
};

//+------------------------------------------------------------------+
//| 1) Универсальная проверка на фрактал                            |
//|    (заменяет IsBullishFractal и IsBearishFractal)               |
//+------------------------------------------------------------------+
bool IsFractal(bool bullish, double prevPrice, double currPrice, double nextPrice)
{
   return bullish
              ? (currPrice > prevPrice && currPrice > nextPrice)
              : (currPrice < prevPrice && currPrice < nextPrice);
}

//+------------------------------------------------------------------+
//| 2) Универсальная функция для добавления фрактала                |
//|    (убираем повторяющийся код ArrayResize + заполнение)         |
//+------------------------------------------------------------------+
void AddFractal(FractalType type, double price, datetime time,
                int index, Fractal &fractals[])
{
   int newSize = ArraySize(fractals) + 1;
   ArrayResize(fractals, newSize);

   fractals[newSize - 1].Type = type;
   fractals[newSize - 1].Value = price;
   fractals[newSize - 1].Time = time;
   fractals[newSize - 1].Index = index;
}

//+------------------------------------------------------------------+
//| 3) Поиск соседних фракталов (универсальная версия)              |
//|    Вместо FindPrevFractal / FindNextFractal                     |
//|    direction = -1 (влево) или +1 (вправо).                      |
//+------------------------------------------------------------------+
int FindFractal(const Fractal &fractals[], int startIndex,
                FractalType sameType, FractalType newType, int direction)
{
   int size = ArraySize(fractals);
   if (size < 1)
      return -1;

   for (int i = startIndex + direction; i >= 0 && i < size; i += direction)
   {
      if (fractals[i].Type == sameType)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| 4) Универсальная сортировка (по времени)                        |
//|    ascending = true для сортировки по возрастанию, false – по убыванию
//+------------------------------------------------------------------+
void SortFractalsByTime(Fractal &fractals[], bool ascending = true)
{
   int size = ArraySize(fractals);
   for (int i = 0; i < size - 1; i++)
   {
      for (int j = i + 1; j < size; j++)
      {
         bool needSwap = ascending
                             ? (fractals[i].Time > fractals[j].Time)
                             : (fractals[i].Time < fractals[j].Time);

         if (needSwap)
         {
            Fractal temp = fractals[i];
            fractals[i] = fractals[j];
            fractals[j] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 5) Обновление типа фрактала (ST->IT->LT)                         |
//|    (Замена UpdateFractalType + FindPrev/NextFractal)            |
//+------------------------------------------------------------------+
void PromoteFractals(Fractal &fractals[], FractalType oldType, FractalType newType, bool bullish)
{
   int size = ArraySize(fractals);
   for (int i = 0; i < size; i++)
   {
      int leftIndex = FindFractal(fractals, i, oldType, newType, -1);
      int rightIndex = FindFractal(fractals, i, oldType, newType, +1);

      // Если слева и справа есть фракталы того же типа,
      // проверяем, является ли тек. фрактал “промежуточным максимумом” (бычьим)
      // или “промежуточным минимумом” (медвежьим).
      if (leftIndex != -1 && rightIndex != -1)
      {
         double leftVal = fractals[leftIndex].Value;
         double currVal = fractals[i].Value;
         double rightVal = fractals[rightIndex].Value;

         bool condition = IsFractal(bullish, leftVal, currVal, rightVal);

         if (condition)
            AddFractal(newType, fractals[i].Value, fractals[i].Time, fractals[i].Index, fractals);

         SortFractalsByTime(fractals, false);
      }
   }
}

//+------------------------------------------------------------------+
//| 6) Фильтрация фракталов по наличию “противоположных”            |
//|    (Упрощённый вариант FilterByOppositePresence)                |
//+------------------------------------------------------------------+
void FilterOpposite(const Fractal &primary[], const Fractal &opposite[],
                    Fractal &filtered[], bool isLower)
{
   int pSize = ArraySize(primary);
   if (pSize == 0)
      return;

   // Инициализируем результирующий массив как пустой
   ArrayResize(filtered, 0);

   // Инициализируем кандидата группировки первым (самым новым) фракталом
   Fractal candidate = primary[0];

   // Идем по оставшимся фракталам массива primary.
   // Цикл завершается либо когда просмотрены все элементы, либо когда найдено 4 значимых фрактала.
   for (int i = 1; i < pSize && ArraySize(filtered) < 4; i++)
   {
      bool foundOpposite = false;

      // Проверяем, есть ли хотя бы один opposite-фрактал, время которого строго между
      // временем кандидата и временем текущего primary[i]:
      // candidate.Time > opposite[j].Time > primary[i].Time
      int oppositeSize = ArraySize(opposite);
      for (int j = 0; j < oppositeSize; j++)
      {
         if(opposite[j].Time == primary[i].Time)
         {
            foundOpposite = true;
            break;
         }

         if (opposite[j].Time < candidate.Time && opposite[j].Time > primary[i].Time)
         {
            foundOpposite = true;
            break;
         }
      }

      if (foundOpposite)
      {
         // Если противоположный фрактал найден, значит группа кандидата завершена:
         // сохраняем кандидата как значимый фрактал.
         int newSize = ArraySize(filtered) + 1;
         ArrayResize(filtered, newSize);
         filtered[newSize - 1] = candidate;

         // Начинаем новую группу с текущего фрактала primary[i]
         candidate = primary[i];
      }
      else
      {
         // Если противоположного фрактала между кандидатом и primary[i] нет,
         // обновляем кандидата выбором более экстремального фрактала.
         if (isLower)
            candidate = (primary[i].Value < candidate.Value ? primary[i] : candidate);
         else
            candidate = (primary[i].Value > candidate.Value ? primary[i] : candidate);
      }
   }

   // После прохода по всем элементам не добавляем финального кандидата,
   // если он не завершён обнаружением противоположного фрактала,
   // чтобы итоговое число значимых фракталов не превышало 4.
}

//+------------------------------------------------------------------+
//| 7) Основная функция фильтрации. Разбивает фракталы на группы,   |
//|   применяет FilterOpposite и снова объединяет (KISS-версия).    |
//+------------------------------------------------------------------+
void FilterSignificantFractals(Fractal &source[], Fractal &filtered[])
{
   SortFractalsByTime(source, false);

   // 7.1) Разделяем исходные фракталы по типам
   //     (чтобы не городить 6 отдельных циклов, можно завести массив массивов)
   Fractal listSth[], listStl[], listIth[], listItl[], listLth[], listLtl[];
   for (int i = 0; i < ArraySize(source); i++)
   {
      FractalType t = source[i].Type;
      // Добавляем в нужный список
      switch (t)
      {
      case Sth:
         ArrayResize(listSth, ArraySize(listSth) + 1);
         listSth[ArraySize(listSth) - 1] = source[i];
         break;
      case Stl:
         ArrayResize(listStl, ArraySize(listStl) + 1);
         listStl[ArraySize(listStl) - 1] = source[i];
         break;
      case Ith:
         ArrayResize(listIth, ArraySize(listIth) + 1);
         listIth[ArraySize(listIth) - 1] = source[i];
         break;
      case Itl:
         ArrayResize(listItl, ArraySize(listItl) + 1);
         listItl[ArraySize(listItl) - 1] = source[i];
         break;
      case Lth:
         ArrayResize(listLth, ArraySize(listLth) + 1);
         listLth[ArraySize(listLth) - 1] = source[i];
         break;
      case Ltl:
         ArrayResize(listLtl, ArraySize(listLtl) + 1);
         listLtl[ArraySize(listLtl) - 1] = source[i];
         break;
      }
   }

   // 7.2) Фильтруем противоположные фракталы: бычьи/медвежьи пары
   Fractal sthF[], stlF[], ithF[], itlF[], lthF[], ltlF[];
   FilterOpposite(listStl, listSth, stlF, true);  // ST Bearish
   FilterOpposite(listSth, listStl, sthF, false); // ST Bullish

   FilterOpposite(listItl, listIth, itlF, true);  // IT Bearish
   FilterOpposite(listIth, listItl, ithF, false); // IT Bullish

   FilterOpposite(listLtl, listLth, ltlF, true);  // LT Bearish
   FilterOpposite(listLth, listLtl, lthF, false); // LT Bullish

   // 7.3) Объединяем отфильтрованные фракталы в один массив
   int totalSize = ArraySize(sthF) + ArraySize(stlF) + ArraySize(ithF) +
                   ArraySize(itlF) + ArraySize(lthF) + ArraySize(ltlF);
   ArrayResize(filtered, totalSize);

   int pos = 0;
#define COPY_FRACTALS(src)                            \
   {                                                  \
      for (int k = 0; k < ArraySize(src); k++, pos++) \
      {                                               \
         filtered[pos] = src[k];                      \
      }                                               \
   }
   COPY_FRACTALS(stlF);
   COPY_FRACTALS(sthF);
   COPY_FRACTALS(itlF);
   COPY_FRACTALS(ithF);
   COPY_FRACTALS(ltlF);
   COPY_FRACTALS(lthF);
#undef COPY_FRACTALS

   // Сортируем по возрастанию времени, если нужно
   SortFractalsByTime(filtered, false);
}

//+------------------------------------------------------------------+
//| 8) Получение трендовых фракталов (аналог GetTrendFractals)      |
//|   Берём по несколько последних бычьих/медвежьих и “склеиваем”.  |
//+------------------------------------------------------------------+
void GetTrendFractals(const Fractal &source[], FractalType bearType, FractalType bullType,
                      Fractal &trendFractals[], int maxCount = 10, int maxOut = 4)
{
   // 8.1) Собираем последние N медвежьих и бычьих
   Fractal bears[], bulls[];
   for (int i = ArraySize(source) - 1; i >= 0 && (ArraySize(bears) < maxCount || ArraySize(bulls) < maxCount); i--)
   {
      if (source[i].Type == bearType && ArraySize(bears) < maxCount)
      {
         ArrayResize(bears, ArraySize(bears) + 1);
         bears[ArraySize(bears) - 1] = source[i];
      }
      if (source[i].Type == bullType && ArraySize(bulls) < maxCount)
      {
         ArrayResize(bulls, ArraySize(bulls) + 1);
         bulls[ArraySize(bulls) - 1] = source[i];
      }
   }

   // 8.2) Объединяем и сортируем по убыванию времени
   int total = ArraySize(bears) + ArraySize(bulls);
   Fractal allFractals[];
   ArrayResize(allFractals, total);

   int pos = 0;
   for (int i = 0; i < ArraySize(bears); i++, pos++)
      allFractals[pos] = bears[i];
   for (int i = 0; i < ArraySize(bulls); i++, pos++)
      allFractals[pos] = bulls[i];
   SortFractalsByTime(allFractals, false); // по убыванию

   // 8.3) "Упрощаем" до maxOut
   Fractal optimized[];
   if (ArraySize(allFractals) > 0)
   {
      ArrayResize(optimized, 1);
      optimized[0] = allFractals[0];

      for (int i = 1; i < ArraySize(allFractals); i++)
      {
         if (ArraySize(optimized) == maxOut)
            break;

         // Добавляем фрактал, если он другого типа, иначе пропускаем
         if (allFractals[i].Type != optimized[ArraySize(optimized) - 1].Type)
         {
            int newSize = ArraySize(optimized) + 1;
            ArrayResize(optimized, newSize);
            optimized[newSize - 1] = allFractals[i];
         }
      }
   }

   // 8.4) Возвращаем результат
   ArrayResize(trendFractals, ArraySize(optimized));
   for (int i = 0; i < ArraySize(optimized); i++)
      trendFractals[i] = optimized[i];
}

//+------------------------------------------------------------------+
//| 9) Итоговое объединение (CombineFractalArrays)                   |
//|   Теперь достаточно одного универсального метода                 |
//+------------------------------------------------------------------+
void CombineFractals(Fractal &result[],
                     const Fractal &arr1[], const Fractal &arr2[], const Fractal &arr3[])
{
   int sz1 = ArraySize(arr1), sz2 = ArraySize(arr2), sz3 = ArraySize(arr3);
   int totalSize = sz1 + sz2 + sz3;
   ArrayResize(result, totalSize);

   int pos = 0;
   for (int i = 0; i < sz1; i++, pos++)
      result[pos] = arr1[i];
   for (int i = 0; i < sz2; i++, pos++)
      result[pos] = arr2[i];
   for (int i = 0; i < sz3; i++, pos++)
      result[pos] = arr3[i];
}

//+------------------------------------------------------------------+
//| 10) Основная функция генерации фракталов                         |
//+------------------------------------------------------------------+
void GenerateFractals(const double &high[], const double &low[],
                      const double &open[], const double &close[],
                      const datetime &time[], const int rates_total,
                      Fractal &fractals[], Fractal &filtered[], int limit = 600)
{
   // 10.1) Готовим диапазон (не более limit последних свечей)
   int start = MathMax(1, rates_total - limit);

   // Очищаем массив выходных фракталов
   ArrayResize(fractals, 0);
   ArrayResize(filtered, 0);

   // 10.2) Ищем ST-фракталы (бычьи и медвежьи)
   for (int i = start; i < rates_total - 1; i++)
   {
      if (IsFractal(true, high[i - 1], high[i], high[i + 1]))
         AddFractal(Sth, high[i], time[i], i, fractals);

      if (IsFractal(false, low[i - 1], low[i], low[i + 1]))
         AddFractal(Stl, low[i], time[i], i, fractals);
   }

   // 10.3) Преобразуем ST->IT->LT
   PromoteFractals(fractals, Sth, Ith, true);
   PromoteFractals(fractals, Stl, Itl, false);

   PromoteFractals(fractals, Ith, Lth, true);
   PromoteFractals(fractals, Itl, Ltl, false);

   // 10.4) Фильтруем значимые
   FilterSignificantFractals(fractals, filtered);

   // 10.5) Получаем трендовые фракталы ST, IT, LT
   Fractal stFractals[], itFractals[], ltFractals[];
   GetTrendFractals(filtered, Stl, Sth, stFractals);
   GetTrendFractals(filtered, Itl, Ith, itFractals);
   GetTrendFractals(filtered, Ltl, Lth, ltFractals);

   // 10.6) “Склеиваем” результаты
   CombineFractals(filtered, stFractals, itFractals, ltFractals);
   // По желанию можно ещё раз отсортировать fractals, если нужно
}

//+------------------------------------------------------------------+
//| Анализирует все тренды (Short, Intermediate, Long)              |
//+------------------------------------------------------------------+
TrendAnalysis AnalyzeTrends(Fractal &fractals[])
{
   TrendAnalysis analysis;
   analysis.ShortTerm = AnalyzeSpecificTrend(fractals, Stl, Sth);
   analysis.IntermediateTerm = AnalyzeSpecificTrend(fractals, Itl, Ith);
   analysis.LongTerm = AnalyzeSpecificTrend(fractals, Ltl, Lth);
   return analysis;
}

//+------------------------------------------------------------------+
//| Анализирует конкретный тренд (Short, Intermediate, Long)        |
//+------------------------------------------------------------------+
TrendType AnalyzeSpecificTrend(Fractal &fractals[], FractalType lowerType, FractalType upperType)
{
   Fractal filteredFractals[];
   int count = 0;

   // Фильтруем фракталы по типам lowerType и upperType
   for (int i = 0; i < ArraySize(fractals); i++)
   {
      if (fractals[i].Type == lowerType || fractals[i].Type == upperType)
      {
         ArrayResize(filteredFractals, count + 1);
         filteredFractals[count] = fractals[i];
         count++;
      }
   }

   // Сортируем по убыванию времени
   SortFractalsByTime(filteredFractals, false);

   // Берём первые 4 фрактала
   Fractal trendFractals[];
   int take = MathMin(4, ArraySize(filteredFractals));
   for (int i = 0; i < take; i++)
   {
      ArrayResize(trendFractals, i + 1);
      trendFractals[i] = filteredFractals[i];
   }

   // Если меньше 4 фракталов, тренд нейтральный
   if (ArraySize(trendFractals) < 4)
   {
      return Neutral;
   }

   // Сортируем по возрастанию времени
   SortFractalsByTime(trendFractals, true);

   // Определяем тип тренда
   if (IsUptrend(trendFractals))
   {
      return Uptrend;
   }
   else if (IsDowntrend(trendFractals))
   {
      return Downtrend;
   }
   else
   {
      return Neutral;
   }
}

//+------------------------------------------------------------------+
//| Проверяет, является ли набор фракталов восходящим трендом      |
//+------------------------------------------------------------------+
bool IsUptrend(Fractal &fractals[])
{
   if (ArraySize(fractals) < 4)
      return false;

   // Извлекаем значения High и Low для каждого фрактала
   double f0_high = 0, f0_low = 0;
   double f1_high = 0, f1_low = 0;
   double f2_high = 0, f2_low = 0;
   double f3_high = 0, f3_low = 0;

   // Присваиваем значения High или Low в зависимости от типа фрактала
   if (fractals[0].Type == Sth || fractals[0].Type == Ith || fractals[0].Type == Lth)
      f0_high = fractals[0].Value;
   else
      f0_low = fractals[0].Value;

   if (fractals[1].Type == Sth || fractals[1].Type == Ith || fractals[1].Type == Lth)
      f1_high = fractals[1].Value;
   else
      f1_low = fractals[1].Value;

   if (fractals[2].Type == Sth || fractals[2].Type == Ith || fractals[2].Type == Lth)
      f2_high = fractals[2].Value;
   else
      f2_low = fractals[2].Value;

   if (fractals[3].Type == Sth || fractals[3].Type == Ith || fractals[3].Type == Lth)
      f3_high = fractals[3].Value;
   else
      f3_low = fractals[3].Value;

   // Применяем условия для восходящего тренда
   bool condition1 = (f0_low < f2_low && f1_high < f3_high);
   bool condition2 = (f0_high < f2_high && f1_low < f3_low);

   return (condition1 || condition2);
}

//+------------------------------------------------------------------+
//| Проверяет, является ли набор фракталов нисходящим трендом      |
//+------------------------------------------------------------------+
bool IsDowntrend(Fractal &fractals[])
{
   if (ArraySize(fractals) < 4)
      return false;

   // Извлекаем значения High и Low для каждого фрактала
   double f0_high = 0, f0_low = 0;
   double f1_high = 0, f1_low = 0;
   double f2_high = 0, f2_low = 0;
   double f3_high = 0, f3_low = 0;

   // Присваиваем значения High или Low в зависимости от типа фрактала
   if (fractals[0].Type == Sth || fractals[0].Type == Ith || fractals[0].Type == Lth)
      f0_high = fractals[0].Value;
   else
      f0_low = fractals[0].Value;

   if (fractals[1].Type == Sth || fractals[1].Type == Ith || fractals[1].Type == Lth)
      f1_high = fractals[1].Value;
   else
      f1_low = fractals[1].Value;

   if (fractals[2].Type == Sth || fractals[2].Type == Ith || fractals[2].Type == Lth)
      f2_high = fractals[2].Value;
   else
      f2_low = fractals[2].Value;

   if (fractals[3].Type == Sth || fractals[3].Type == Ith || fractals[3].Type == Lth)
      f3_high = fractals[3].Value;
   else
      f3_low = fractals[3].Value;

   // Применяем условия для нисходящего тренда
   bool condition1 = (f0_high > f2_high && f1_low > f3_low);
   bool condition2 = (f0_low > f2_low && f1_high > f3_high);

   return (condition1 || condition2);
}

//+------------------------------------------------------------------+

#endif // __FRACTAL_LIBRARY__
