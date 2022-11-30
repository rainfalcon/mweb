//+------------------------------------------------------------------+
//|                                          AlexSTAL_OutsideBar.mq5 |
//|                                         Copyright 2011, AlexSTAL |
//|                                           http://www.alexstal.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, AlexSTAL"
#property link      "http://www.alexstal.ru"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum OrderFormationBarHighLow
  {
   OFBError=0,
   OFBLowEqualHigh=1,
   OFBHighLow = 2,
   OFBLowHigh = 3,
   OFBErrorFindSmallTF=4
  };
//+------------------------------------------------------------------+
//| ГЛАВНАЯ ФУНКЦИЯ                                                  |
//+------------------------------------------------------------------+
//| функция возвращает порядок формирования High Low для бара        |
//|                                                                  |
//| Параметры:                                                       |
//|   symbol            - cимвольное имя инструмента                 |
//|   timeframe         - стандартный период                         |
//|   shift             - индекс бара                                |
//|   UseSmallerTFforEB - использовать при определение порядка       |
//|                       формирования точный алгоритм (на основе    |
//|                       баров с меньшего периода)                  |
//+------------------------------------------------------------------+ 
OrderFormationBarHighLow GetOrderFormationBarHighLow(string symbol,ENUM_TIMEFRAMES timeframe,int shift,bool UseSmallerTFforEB)
  {
   OrderFormationBarHighLow tmp=OFBError;

// Вычисление по двум алгоритмам
// Для минутного периода нельзя применить меньший ТФ
   if(UseSmallerTFforEB)
     {
      // Будем постепенно уменьшать периоды для достижения результата )))
      for(int i=1; i<=NumberOfPassesSearch(timeframe); i++)
        {
         tmp=SmallTFLogicBarHighLow(symbol,timeframe,shift,SmallTFforNumberOfPassesSearch(timeframe,i));
         if((tmp==OFBHighLow) || (tmp==OFBLowHigh))
            break;
        }
      if((tmp!=OFBHighLow) && (tmp!=OFBLowHigh))
         tmp=SimpleLogicBarHighLow(symbol,timeframe,shift);
        } else {
      tmp=SimpleLogicBarHighLow(symbol,timeframe,shift);
     }
   return(tmp);
  }
//+------------------------------------------------------------------+
//| Функция возвращает порядок формирования High Low для бара        |
//| с заданного меньшего тайфрейма                                   |
//|                                                                  |
//| Параметры:                                                       |
//|   symbol     - cимвольное имя инструмента                        |
//|   timeframe  - стандартный период                                |
//|   shift      - индекс бара                                       |
//|   TFsmall    - меньший стандартный период для поиска             |
//+------------------------------------------------------------------+
OrderFormationBarHighLow SmallTFLogicBarHighLow(string symbol,ENUM_TIMEFRAMES timeframe,int shift,ENUM_TIMEFRAMES TFsmall)
  {
   MqlRates tmp[1];
   int copied = CopyRates(symbol, timeframe, shift, 1, tmp);
   if(copied <= 0)
      return(OFBError);

   double BarH = tmp[0].high;     // High бара
   double BarL = tmp[0].low;      // Low бара
   if(BarH==BarL)
      return(OFBLowEqualHigh);
   datetime BarDTs = tmp[0].time; // Начало бара
   datetime BarDTe;               // Конец бара
   if(timeframe!=PERIOD_MN1)
      BarDTe=BarDTs+PeriodSeconds(timeframe)-1;
   else
// Особый алгоритм определения последнего числа для месяца
      BarDTe=BarDTs+1440*NumberDaysMonth(BarDTs)*60-1;

// Получаем котировки с меньшего таймфрейма
   MqlRates tmpSmall[];
   copied=CopyRates(symbol,TFsmall,BarDTs,BarDTe,tmpSmall);
   if(copied<=0)
      return(OFBError);

// Цикл по барам
// Оставлен допуск на превышение экстремумов (рудимент от MT4)
   int tmpI=0;
   for(int i=0; i<ArraySize(tmpSmall); i++)
     {
      if(tmpSmall[i].high>=BarH)
         tmpI=tmpI+1;
      if(tmpSmall[i].low<=BarL)
         tmpI=tmpI+2;
      if(tmpI!=0)
         break;
     }
   switch(tmpI)
     {
      case 0:
         return(OFBError);  // Ошибка поиска (нет истории, или история рассинхронизирована)
         break;
      case 1:
         return(OFBHighLow);  // Сначала High
         break;
      case 2:
         return(OFBLowHigh); // Сначала Low
         break;
      case 3:
         return(OFBErrorFindSmallTF);  // Ошибка поиска - High и Low найдены на одном баре одновременно
         break;
      default:
         return(OFBError);  // Ошибка поиска (нет истории, или история рассинхронизирована)
         break;
     }
  }
//+------------------------------------------------------------------+
//| Попытка по внешнему виду бара определить порядок формирования    |
//| High/Low                                                         |
//+------------------------------------------------------------------+
//| Необходимо исправить под свой алгоритм!!!                        |
//+------------------------------------------------------------------+
//| Параметры:                                                       |
//|   symbol     - cимвольное имя инструмента                        |
//|   timeframe  - стандартный период                                |
//|   shift      - индекс бара                                       |
//+------------------------------------------------------------------+
OrderFormationBarHighLow SimpleLogicBarHighLow(string symbol,ENUM_TIMEFRAMES timeframe,int shift)
  {
   MqlRates tmp[1];
   int copied = CopyRates(symbol, timeframe, shift, 1, tmp);
   if(copied <= 0)
      return(OFBError);

// Простейшая логика по Open / Close
   OrderFormationBarHighLow res=OFBError;
   if(tmp[0].high==tmp[0].low)
      return(OFBLowEqualHigh);

   if(tmp[0].close>tmp[0].open)
      res=OFBLowHigh;
   if(tmp[0].close<tmp[0].open)
      res=OFBHighLow;

   if(res==OFBError) // Когда Close = Open
     {
      double a1 = tmp[0].high - tmp[0].close;
      double a2 = tmp[0].close - tmp[0].low;
      if(a1>a2)
         res=OFBLowHigh;
      if(a1<a2)
         res =OFBHighLow;
      if(res==OFBError) // Когда и это равно ))))
         res=OFBHighLow;    // :) - будем так считать! и баста!
     }
   return(res);
  }
//+------------------------------------------------------------------+
//| Возвращает количество попыток уменьшения ТФ для заданного ТФ     |
//| при поиске порядка формирования High/Low бара                    |
//+------------------------------------------------------------------+
int NumberOfPassesSearch(ENUM_TIMEFRAMES timeframe)
  {
   switch(timeframe)
     {
      case PERIOD_M1 :
         return(0);
         break;
      case PERIOD_M2 :
      case PERIOD_M3 :
      case PERIOD_M4 :
      case PERIOD_M5 :
      case PERIOD_M6 :
      case PERIOD_M10:
      case PERIOD_M12:
      case PERIOD_M15:
         return(1);
         break;
      case PERIOD_M20:
      case PERIOD_M30:
      case PERIOD_H1 :
      case PERIOD_H2 :
      case PERIOD_H3 :
      case PERIOD_H4 :
      case PERIOD_H6 :
         return(2);
         break;
      case PERIOD_H8 :
      case PERIOD_H12:
      case PERIOD_D1 :
         return(3);
         break;
      case PERIOD_W1 :
      case PERIOD_MN1:
         return(4);
         break;
      default:
         return(0);
         break;
     }
  }
//+------------------------------------------------------------------+
//| Возвращает ТФ для выбранного прохода выбранного ТФ               |
//| Количество проходов определяется функцией NumberOfPassesSearch   |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES SmallTFforNumberOfPassesSearch(ENUM_TIMEFRAMES timeframe,int Passes)
  {
   switch(timeframe)
     {
      case PERIOD_M2 :
      case PERIOD_M3 :
      case PERIOD_M4 :
      case PERIOD_M5 :
      case PERIOD_M6 :
      case PERIOD_M10:
      case PERIOD_M12:
      case PERIOD_M15:
         switch(Passes)
           {
            case 1: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      case PERIOD_M20:
         switch(Passes)
           {
            case 1: return(PERIOD_M2); break;
            case 2: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      case PERIOD_M30:
      case PERIOD_H1 :
         switch(Passes)
           {
            case 1: return(PERIOD_M5); break;
            case 2: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      case PERIOD_H2:
      case PERIOD_H3:
         switch(Passes)
           {
            case 1: return(PERIOD_M15); break;
            case 2: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      case PERIOD_H4:
      case PERIOD_H6:
         switch(Passes)
           {
            case 1: return(PERIOD_M30); break;
            case 2: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      case PERIOD_H8 :
      case PERIOD_H12:
         switch(Passes)
           {
            case 1: return(PERIOD_H1); break;
            case 2: return(PERIOD_M5); break;
            case 3: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      case PERIOD_D1:
         switch(Passes)
           {
            case 1: return(PERIOD_H4); break;
            case 2: return(PERIOD_M30); break;
            case 3: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      case PERIOD_W1:
         switch(Passes)
           {
            case 1: return(PERIOD_D1); break;
            case 2: return(PERIOD_H4); break;
            case 3: return(PERIOD_M30); break;
            case 4: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      case PERIOD_MN1:
         switch(Passes)
           {
            case 1: return(PERIOD_D1); break;
            case 2: return(PERIOD_H4); break;
            case 3: return(PERIOD_M30); break;
            case 4: return(PERIOD_M1); break;
            default: return(0); break;
           }
         break;
      default: return(0); break;
     }
  }
//+------------------------------------------------------------------+
//| Возвращает количество дней в месяце                              |
//+------------------------------------------------------------------+
int NumberDaysMonth(datetime Date)
  {
   MqlDateTime tmpDT;
   TimeToStruct(Date,tmpDT);
   switch(tmpDT.mon)
     {
      case  1: return(31); break;
      case  2:
         if((tmpDT.year%4)==0)
         return(29);
         else
            return(28);
         break;
      case  3: return(31); break;
      case  4: return(30); break;
      case  5: return(31); break;
      case  6: return(30); break;
      case  7: return(31); break;
      case  8: return(31); break;
      case  9: return(30); break;
      case 10: return(31); break;
      case 11: return(30); break;
      case 12: return(31); break;
      default: return(0); break;
     }
  }
//+------------------------------------------------------------------+
