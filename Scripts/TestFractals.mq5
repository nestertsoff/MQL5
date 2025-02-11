//+------------------------------------------------------------------+
//|                                                         Test.mq5 |
//| Скрипт для тестирования FilterOpposite                          |
//+------------------------------------------------------------------+
#include <FractalLibrary.mqh>

//+------------------------------------------------------------------+
//| Главная функция                                                  |
//+------------------------------------------------------------------+
void OnStart()
{
   TestCase1_BasicCase();
   TestCase2_NoOppositeFractals();
   TestCase3_AllOppositeBetweenPrimary();
   TestCase4_OnePrimarySeveralOpposite();
   TestCase5_OneOppositeBetweenTwoPrimary();
   TestCase6_NoPrimaryFractals();
   TestCase7_OnePrimaryOneOpposite();
   TestCase8_AllPrimaryOverlapWithOpposite();
   TestCase9_ComplexCaseWithMultipleFractals();
   TestCase10_OnlyOnePrimaryFractal();
   TestCase11_ConsecutiveDuplicateFractals();
   TestCase12_UnsortedFractals();
   TestCase13_OppositeOutsidePrimaryBounds();
   TestCase14_MultipleOppositesBetweenPrimary();
}

//+------------------------------------------------------------------+
//| Вспомогательная функция для сравнения массивов                  |
//+------------------------------------------------------------------+
bool CompareFractals(const Fractal &expected[], const Fractal &actual[])
{
   if (ArraySize(expected) != ArraySize(actual))
      return false;

   for (int i = 0; i < ArraySize(expected); i++)
   {
      if (expected[i].Index != actual[i].Index || 
          expected[i].Time != actual[i].Time || 
          expected[i].Value != actual[i].Value || 
          expected[i].Type != actual[i].Type)
         return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Вспомогательная функция для вывода результата теста             |
//+------------------------------------------------------------------+
void Assert(const string testName, const Fractal &expected[], const Fractal &actual[])
{
   if (CompareFractals(expected, actual))
      Print(testName, ": PASSED");
   else
   {
      Print(testName, ": FAILED");
      Print("Expected:");
      for (int i = 0; i < ArraySize(expected); i++)
         Print("Index=", expected[i].Index, " Time=", TimeToString(expected[i].Time), " Value=", expected[i].Value);

      Print("Actual:");
      for (int i = 0; i < ArraySize(actual); i++)
         Print("Index=", actual[i].Index, " Time=", TimeToString(actual[i].Time), " Value=", actual[i].Value);
   }
}

//+------------------------------------------------------------------+
//| Тест 1: Базовый случай                                           |
//| Проверяем, что фильтрация работает корректно                     |
//| Ожидаемое поведение: все фракталы сохраняются                    |
//+------------------------------------------------------------------+
void TestCase1_BasicCase()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 3);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 01:00"), Ltl);
   primary[2] = CreateFractal(3, 94.0, StringToTime("2023.01.01 02:00"), Ltl);

   ArrayResize(opposite, 2);
   opposite[0] = CreateFractal(1, 109.0, StringToTime("2023.01.01 01:30"), Lth);
   opposite[1] = CreateFractal(2, 108.0, StringToTime("2023.01.01 00:30"), Lth);

   ArrayResize(expected, 3);
   expected[0] = primary[0];
   expected[1] = primary[1];
   expected[2] = primary[2];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase1_BasicCase", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 2: Нет противоположных фракталов                           |
//| Проверяем случай, когда нет противоположных фракталов            |
//| Ожидаемое поведение: выбирается только самый экстремальный       |
//+------------------------------------------------------------------+
void TestCase2_NoOppositeFractals()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 3);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 01:00"), Ltl);
   primary[2] = CreateFractal(3, 94.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(expected, 1);
   expected[0] = primary[0]; // Самый экстремальный фрактал

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase2_NoOppositeFractals", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 3: Все противоположные между соседними                     |
//| Проверяем случай, когда между каждым парой primary есть opposite |
//| Ожидаемое поведение: все primary сохраняются                     |
//+------------------------------------------------------------------+
void TestCase3_AllOppositeBetweenPrimary()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 3);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 01:00"), Ltl);
   primary[2] = CreateFractal(3, 94.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(opposite, 2);
   opposite[0] = CreateFractal(1, 109.0, StringToTime("2023.01.01 01:30"), Lth);
   opposite[1] = CreateFractal(2, 108.0, StringToTime("2023.01.01 00:30"), Lth);

   ArrayResize(expected, 3);
   expected[0] = primary[0];
   expected[1] = primary[1];
   expected[2] = primary[2];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase3_AllOppositeBetweenPrimary", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 4: Один primary и несколько opposite                       |
//| Проверяем случай с несколькими opposite между соседними primary  |
//| Ожидаемое поведение: current primary сохраняется                 |
//+------------------------------------------------------------------+
void TestCase4_OnePrimarySeveralOpposite()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 2);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(opposite, 3);
   opposite[0] = CreateFractal(1, 109.0, StringToTime("2023.01.01 01:30"), Lth);
   opposite[1] = CreateFractal(2, 108.0, StringToTime("2023.01.01 01:00"), Lth);
   opposite[2] = CreateFractal(3, 107.0, StringToTime("2023.01.01 00:30"), Lth);

   ArrayResize(expected, 2);
   expected[0] = primary[0];
   expected[1] = primary[1];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase4_OnePrimarySeveralOpposite", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 5: Один opposite между двумя primary                       |
//| Ожидаемое поведение: оба primary сохраняются                     |
//+------------------------------------------------------------------+
void TestCase5_OneOppositeBetweenTwoPrimary()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 2);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(opposite, 1);
   opposite[0] = CreateFractal(1, 108.0, StringToTime("2023.01.01 01:00"), Lth);

   ArrayResize(expected, 2);
   expected[0] = primary[0];
   expected[1] = primary[1];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase5_OneOppositeBetweenTwoPrimary", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 6: Нет primary фракталов                                   |
//| Ожидаемое поведение: возвращается пустой массив                  |
//+------------------------------------------------------------------+
void TestCase6_NoPrimaryFractals()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(opposite, 2);
   opposite[0] = CreateFractal(1, 109.0, StringToTime("2023.01.01 01:30"), Lth);
   opposite[1] = CreateFractal(2, 108.0, StringToTime("2023.01.01 00:30"), Lth);

   // Ожидаемый результат — пустой массив
   ArrayResize(expected, 0);

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase6_NoPrimaryFractals", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 7: Один primary и один opposite                            |
//| Ожидаемое поведение: primary сохраняется                        |
//+------------------------------------------------------------------+
void TestCase7_OnePrimaryOneOpposite()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 1);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 00:30"), Ltl);

   ArrayResize(opposite, 1);
   opposite[0] = CreateFractal(1, 109.0, StringToTime("2023.01.01 00:00"), Lth);

   ArrayResize(expected, 1);
   expected[0] = primary[0];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase7_OnePrimaryOneOpposite", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 8: Все primary перекрываются opposite                      |
//| Ожидаемое поведение: все primary сохраняются                    |
//+------------------------------------------------------------------+
void TestCase8_AllPrimaryOverlapWithOpposite()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 3);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 01:00"), Ltl);
   primary[2] = CreateFractal(3, 94.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(opposite, 2);
   opposite[0] = CreateFractal(1, 109.0, StringToTime("2023.01.01 01:30"), Lth);
   opposite[1] = CreateFractal(2, 108.0, StringToTime("2023.01.01 00:30"), Lth);

   ArrayResize(expected, 3);
   expected[0] = primary[0];
   expected[1] = primary[1];
   expected[2] = primary[2];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase8_AllPrimaryOverlapWithOpposite", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 9: Сложный случай с множеством фракталов                   |
//| Ожидаемое поведение: корректная фильтрация                      |
//+------------------------------------------------------------------+
void TestCase9_ComplexCaseWithMultipleFractals()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 4);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 03:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[2] = CreateFractal(3, 94.0, StringToTime("2023.01.01 01:00"), Ltl);
   primary[3] = CreateFractal(4, 96.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(opposite, 3);
   opposite[0] = CreateFractal(1, 110.0, StringToTime("2023.01.01 02:30"), Lth);
   opposite[1] = CreateFractal(2, 108.0, StringToTime("2023.01.01 01:30"), Lth);
   opposite[2] = CreateFractal(3, 107.0, StringToTime("2023.01.01 00:30"), Lth);

   ArrayResize(expected, 4);
   expected[0] = primary[0];
   expected[1] = primary[1];
   expected[2] = primary[2];
   expected[3] = primary[3];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase9_ComplexCaseWithMultipleFractals", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 10: Только один primary фрактал                           |
//| Ожидаемое поведение: фрактал сохраняется                        |
//+------------------------------------------------------------------+
void TestCase10_OnlyOnePrimaryFractal()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 1);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(expected, 1);
   expected[0] = primary[0];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase10_OnlyOnePrimaryFractal", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 11: Дублирующиеся фракталы подряд                          |
//| Ожидаемое поведение: только уникальные фракталы остаются         |
//+------------------------------------------------------------------+
void TestCase11_ConsecutiveDuplicateFractals()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 3);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 01:00"), Ltl);
   primary[1] = CreateFractal(1, 90.0, StringToTime("2023.01.01 00:00"), Ltl);
   primary[2] = CreateFractal(2, 92.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(expected, 2);
   expected[0] = primary[0];
   expected[1] = primary[2];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase11_ConsecutiveDuplicateFractals", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 12: Несортированные фракталы                               |
//| Ожидаемое поведение: массив фильтруется корректно               |
//+------------------------------------------------------------------+
void TestCase12_UnsortedFractals()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 3);
   primary[0] = CreateFractal(3, 94.0, StringToTime("2023.01.01 01:00"), Ltl);
   primary[1] = CreateFractal(1, 90.0, StringToTime("2023.01.01 00:00"), Ltl);
   primary[2] = CreateFractal(2, 92.0, StringToTime("2023.01.01 02:00"), Ltl);

   ArrayResize(expected, 3);
   expected[0] = primary[1];
   expected[1] = primary[2];
   expected[2] = primary[0];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase12_UnsortedFractals", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 13: Opposite за пределами primary                         |
//| Ожидаемое поведение: такие opposite игнорируются                |
//+------------------------------------------------------------------+
void TestCase13_OppositeOutsidePrimaryBounds()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 2);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(opposite, 3);
   opposite[0] = CreateFractal(1, 109.0, StringToTime("2023.01.02 03:00"), Lth);
   opposite[1] = CreateFractal(2, 108.0, StringToTime("2023.01.01 01:00"), Lth);
   opposite[2] = CreateFractal(3, 107.0, StringToTime("2022.12.31 23:00"), Lth);

   ArrayResize(expected, 2);
   expected[0] = primary[0];
   expected[1] = primary[1];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase13_OppositeOutsidePrimaryBounds", expected, filtered);
}

//+------------------------------------------------------------------+
//| Тест 14: Множество opposite между primary                      |
//| Ожидаемое поведение: primary остаются корректно                 |
//+------------------------------------------------------------------+
void TestCase14_MultipleOppositesBetweenPrimary()
{
   Fractal primary[], opposite[], filtered[], expected[];

   ArrayResize(primary, 2);
   primary[0] = CreateFractal(1, 90.0, StringToTime("2023.01.01 02:00"), Ltl);
   primary[1] = CreateFractal(2, 92.0, StringToTime("2023.01.01 00:00"), Ltl);

   ArrayResize(opposite, 4);
   opposite[0] = CreateFractal(1, 109.0, StringToTime("2023.01.01 01:45"), Lth);
   opposite[1] = CreateFractal(2, 108.0, StringToTime("2023.01.01 01:30"), Lth);
   opposite[2] = CreateFractal(3, 107.0, StringToTime("2023.01.01 01:00"), Lth);
   opposite[3] = CreateFractal(4, 106.0, StringToTime("2023.01.01 00:30"), Lth);

   ArrayResize(expected, 2);
   expected[0] = primary[0];
   expected[1] = primary[1];

   FilterOpposite(primary, opposite, filtered, true);
   Assert("TestCase14_MultipleOppositesBetweenPrimary", expected, filtered);
}


//+------------------------------------------------------------------+
//| Вспомогательная функция для создания фрактала                   |
//+------------------------------------------------------------------+
Fractal CreateFractal(int index, double value, datetime time, FractalType type)
{
   Fractal fractal;
   fractal.Index = index;
   fractal.Value = value;
   fractal.Time = time;
   fractal.Type = type;
   return fractal;
}