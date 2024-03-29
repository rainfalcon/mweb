//+------------------------------------------------------------------+
//|                                           ProfessionalZigZag.mq4 |
//|                                      Copyright 2017, nicholishen |
//|                         https://www.forexfactory.com/nicholishen |
//+------------------------------------------------------------------+

#property strict

//+------------------------------------------------------------------+
//|                                          AlexSTAL_ZigZagProf.mq5 |
//|                                         Copyright 2011, AlexSTAL |
//|                                           http://www.alexstal.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, AlexSTAL"
#property link      "http://www.alexstal.ru"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
//---- plot Zigzag
#property indicator_label1  "Zigzag"
#property indicator_type1   DRAW_ZIGZAG
#property indicator_color1  Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Zigzag"
#property indicator_type2   DRAW_ZIGZAG
#property indicator_color2  Red
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#include "alexstal_outsidebar.mqh"

// Êîëè÷åñòâî áàðîâ äëÿ ðàñ÷åòà ýêñòðåìóìîâ
// íå ìîæåò áûòü ìåíüøå 2
input uchar iExtPeriod=12;
// Ìèíèìàëüíîå ðàññòîÿíèå öåíû ìåæäó ñîñåäíèìè ïèêîì è âïàäèíîé (èíà÷å íå ðåãèñòðèðóåòñÿ)
input uchar iMinAmplitude=10;
// Ìèíèìàëüíîå äâèæåíèå öåíû â ïóíêòàõ íà íóëåâîì áàðå äëÿ ïåðåðàñ÷åòà èíäèêàòîðà
input uchar iMinMotion=0;
// Èñïîëüçîâàòü áîëåå òî÷íûé àëãîðèòì âû÷èñëåíèÿ ïîðÿäêà ôîðìèðîâàíèÿ High/Low áàðà
input bool iUseSmallerTFforEB=true;

uchar ExtPeriod,MinAmplitude,MinMotion;

// Áóôåðû èíäèêàòîðà
double UP[],DN[];

// Áóôåð äëÿ êýøèðîâàíèÿ âíåøíåãî áàðà
double OB[];

// Âðåìÿ îòêðûòèÿ ïîñëåäíåãî îáñ÷èòàííîãî áàðà
datetime LastBarTime;
// Çàùèòà îò äîêà÷êè èñòîðèè
//int LastBarNum;
// Äëÿ îïòèìèçàöèè ðàñ÷åòîâ
double LastBarLastHigh,LastBarLastLow;
// Âðåìÿ ïåðâîãî ýêñòðåìóìà (íåîáõîäèìî äëÿ àëãîðèòìà âíåøíåãî áàðà)
datetime TimeFirstExtBar;

// Ñòàòè÷åñêèå ïåðåìåííûå äëÿ óñêîðåíèÿ ðàñ÷åòîâ
double MP,MM;

// Âñïîìîãàòåëüíàÿ ïåðåìåííàÿ
bool DownloadHistory;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   if(iExtPeriod>=2)
      ExtPeriod=iExtPeriod;
   else
      ExtPeriod=2;

   MinAmplitude=iMinAmplitude;
   MP=NormalizeDouble(MinAmplitude*_Point,_Digits);

   if(iMinMotion>=1)
      MinMotion=iMinMotion;
   else
      MinMotion=1;
   MM=NormalizeDouble(MinMotion*_Point,_Digits);

//--- indicator buffers mapping
   SetIndexBuffer(0,UP,INDICATOR_DATA);
   SetIndexBuffer(1,DN,INDICATOR_DATA);
   SetIndexBuffer(2,OB,INDICATOR_CALCULATIONS);

   ArraySetAsSeries(UP,true);
   ArraySetAsSeries(DN,true);
   ArraySetAsSeries(OB,true);

//--- set short name and digits   
   PlotIndexSetString(0,PLOT_LABEL,"ZigZag("+(string)ExtPeriod+","+(string)MinAmplitude+","+(string)MinMotion+","+(string)iUseSmallerTFforEB+")");
   PlotIndexSetString(1,PLOT_LABEL,"ZigZag("+(string)ExtPeriod+","+(string)MinAmplitude+","+(string)MinMotion+","+(string)iUseSmallerTFforEB+")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//--- set empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   DownloadHistory=true;

//---
   return(0);
  }
//+------------------------------------------------------------------+
//|  searching index of the highest bar                              |
//+------------------------------------------------------------------+
int iHighest(const double &array[],int depth,int startPos)
  {
   int index=startPos;
   int MaxBar=ArraySize(array)-1;
//--- start index validation
   if((startPos<0) || (startPos>MaxBar))
     {
      Print("Invalid parameter in the function iHighest, startPos =",startPos);
      return -1;
     }
   double max=array[startPos];

//--- start searching
   for(int i=MathMin(startPos+depth-1,MaxBar); i>=startPos; i--)
     {
      if(array[i]>max)
        {
         index=i;
         max=array[i];
        }
     }
//--- return index of the highest bar
   return(index);
  }
//+------------------------------------------------------------------+
//|  searching index of the lowest bar                               |
//+------------------------------------------------------------------+
int iLowest(const double &array[],int depth,int startPos)
  {
   int index=startPos;
   int MaxBar=ArraySize(array)-1;
//--- start index validation
   if((startPos<0) || (startPos>MaxBar))
     {
      Print("Invalid parameter in the function iLowest, startPos =",startPos);
      return -1;
     }
   double min=array[startPos];

//--- start searching
   for(int i=MathMin(startPos+depth-1,MaxBar); i>=startPos; i--)
     {
      if(array[i]<min)
        {
         index=i;
         min=array[i];
        }
     }
//--- return index of the lowest bar
   return(index);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   int i;
   for(i=(rates_total-prev_calculated-1); i>=0; i--)
     {
      UP[i] = EMPTY_VALUE;
      DN[i] = EMPTY_VALUE;
      OB[i] = EMPTY_VALUE;
     }

//---
// Áëîê ïîëíîé èíèöèàëèçàöèè ïðè ïîäêà÷êå èñòîðèè
// ----------------------------------------------
   int counted_bars=prev_calculated;

// IndicatorCounted() ìîæåò îáíóëèòñÿ ïðè âîññòàíîâëåíèè ñâÿçè
   if(counted_bars==0)
      DownloadHistory=true;

// Çàùèòà îò äîêà÷êè ïðîïóùåííîé èñòîðèè âíóòðü ðàñ÷åòà
/*if ( (counted_bars != 0) && (LastBarNum != 0) )
      if ( (rates_total - iBarShift(NULL, 0, LastBarTime, true)) != LastBarNum )
         DownloadHistory = true;*/

// Ïîëíàÿ èíèöèàëèçàöèÿ
   if(DownloadHistory)
     {
      ArrayInitialize(UP,EMPTY_VALUE);
      ArrayInitialize(DN,EMPTY_VALUE);
      ArrayInitialize(OB,EMPTY_VALUE);
      TimeFirstExtBar=0;
      counted_bars= 0;
      LastBarTime = 0;
      //LastBarNum = 0;
      DownloadHistory=false;
     }

// Áëîê îïðåäåëåíèÿ ôîðìèðîâàíèÿ íîâîãî áàðà (ïåðâûé äîøåäøèé òèê)
   bool NewBar=false;
   if(LastBarTime!=time[0])
     {
      NewBar=true;
      LastBarTime=time[0];
      //LastBarNum = rates_total;
      // íîâûé áàð - îáíóëèì ïåðåìåííûå äëÿ îïòèìèçàöèè ðàñ÷åòîâ
      LastBarLastHigh= high[0];
      LastBarLastLow = low[0];
     }

// Âû÷èñëèì íåîáõîäèìîå êîëè÷åñòâî áàðîâ äëÿ ïåðåñ÷åòà
   int BarsForRecalculation;
   if(counted_bars!=0)
     {
      BarsForRecalculation=rates_total-counted_bars;
      // Áëîê îïòèìèçàöèè ðàñ÷åòîâ
      if(!NewBar)
        {
         if((NormalizeDouble(high[0]-LastBarLastHigh,_Digits)>=MM) || (NormalizeDouble(LastBarLastLow-low[0],_Digits)>=MM))
           {
            LastBarLastHigh= high[0];
            LastBarLastLow = low[0];
              } else {
            // Íà äàííîì òèêå ðàñ÷åò ïðîèçâîäèòü íå áóäåì, òàê êàê öåíà èçìåíÿëàñü âíóòðè
            // íóëåâîãî áàðà èëè æå å¸ èçìåíåíèÿ íå áûëè áîëüøå ìèíèìàëüíîãî ïîðîãà,
            // çàäàííîãî â ïåðåìåííîé MinMotion
            return(rates_total);
           }
        }
        } else {
      BarsForRecalculation=rates_total-ExtPeriod;
     }

//======================================================
//======== îñíîâíîé öèêë ===============================
//======================================================
   int LET;
   double H,L,Fup,Fdn;
   int lastUPbar,lastDNbar;
   double lastUP,lastDN;
   int m,n; // Äëÿ ïîèñêà ïîñëåäíåãî ýêñòðåìóìà
   for(i=BarsForRecalculation; i>=0; i--)
     {
      // Ïîèñê ïîñëåäíåãî ýêñòðåìóìà
      // ---------------------------
      lastUP = 0;
      lastDN = 0;
      lastUPbar = i;
      lastDNbar = i;
      LET=0;
      m=0; n=0;
      while(UP[lastUPbar]==EMPTY_VALUE)
        {
         if(lastUPbar>(rates_total-ExtPeriod))
            break;
         lastUPbar++;
        }
      lastUP=UP[lastUPbar]; //âîçìîæíî íàøëè ïîñëåäíèé ïèê
      while(DN[lastDNbar]==EMPTY_VALUE)
        {
         if(lastDNbar>(rates_total-ExtPeriod))
            break;
         lastDNbar++;
        }
      lastDN=DN[lastDNbar]; //âîçìîæíî íàøëè ïîñëåäíþþ âïàäèíó

      if(lastUPbar<lastDNbar)
         LET=1;
      if(lastUPbar>lastDNbar)
         LET=-1;
      if(lastUPbar==lastDNbar)
        {
         //lastUPbar==lastDNbar íàäî óçíàòü, êàêîé îäèíî÷íûé ýêñòðåìóì áûë ïîñëåäíèì:
         m = lastUPbar;
         n = m;
         while(m==n)
           {
            m++; n++;
            while(UP[m]==EMPTY_VALUE)
              {
               if(m>(rates_total-ExtPeriod))
                  break;
               m++;
              } //âîçìîæíî íàøëè ïîñëåäíèé ïèê
            while(DN[n]==EMPTY_VALUE)
              {
               if(n>(rates_total-ExtPeriod))
                  break;
               n++;
              } //âîçìîæíî íàøëè ïîñëåäíþþ âïàäèíó
            if(MathMax(m,n)>(rates_total-ExtPeriod))
               break;
           }
         if(m<n)
            LET=1;       //áàçîâûé îòñ÷åò - ïèê
         else
         if(m>n)
            LET=-1; //áàçîâûé îòñ÷åò - âïàäèíà
        }
      // åñëè LET==0 - çíà÷èò ýòî íà÷àëî îòñ÷åòà èëè â ñàìîì íà÷àëå çàôèêñèðîâàí âíåøíèé áàð ñ 2 ýêñòðåìóìàìè
      // Êîíåö ïîèñêà ïîñëåäíåãî ýêñòðåìóìà
      // ----------------------------------

      //---- ðàññìîòðèì öåíîâûå ýêñòðåìóìû çà ðàñ÷åòíûé ïåðèîä:       
      H = high[iHighest(high, ExtPeriod, i)];
      L = low[iLowest(low, ExtPeriod, i)];
      Fup = high[i];
      Fdn = low[i];

      //---- ïðîàíàëèçèðóåì ñèòóàöèþ è ðàññìîòðèì âîçìîæíîñòü ðåãèñòðàöèè íîâûõ ýêñòðåìóìîâ: 
      switch(Comb(i,H,L,Fup,Fdn))
        {
         //---- íà ðàñ÷åòíîì áàðå ïîòåíöèàëüíûé ïèê (Comb)      
         case 1 :
            switch(LET)
              {
               case 1 :
                  //ïðåäûäóùèé ýêñòðåìóì òîæå ïèê, âûáèðàåì áîëüøèé:
                  if(lastUP<Fup)
                    {
                     UP[lastUPbar]=EMPTY_VALUE;
                     UP[i]=Fup;
                    }
                  break;
               case -1 :
                  if((Fup-lastDN)>MP) //ïðåäûäóùèé ýêñòðåìóì - âïàäèíà
                  UP[i]=Fup;
                  break;
               default :
                  UP[i]=Fup;
                  TimeFirstExtBar=time[i]; //0 - çíà÷èò ýòî íà÷àëî ðàñ÷åòà 
                  break;
              }
            break;

            //---- íà ðàñ÷åòíîì áàðå ïîòåíöèàëüíàÿ âïàäèíà  (Comb)          
         case -1 :
            switch(LET)
              {
               case 1 :
                  if((lastUP-Fdn)>MP) //ïðåäûäóùèé ýêñòðåìóì - ïèê
                  DN[i]=Fdn;
                  break;
               case -1 :
                  //ïðåäûäóùèé ýêñòðåìóì òîæå âïàäèíà, âûáèðàåì ìåíüøóþ:
                  if(lastDN>Fdn)
                    {
                     DN[lastDNbar]=EMPTY_VALUE;
                     DN[i]=Fdn;
                    }
                  break;
               default :
                  DN[i]=Fdn;
                  TimeFirstExtBar=time[i]; //0 - çíà÷èò ýòî íà÷àëî ðàñ÷åòà 
                  break;
              }
            break;

            //---- íà ðàñ÷åòíîì áàðå ïîòåíöèàëüíûé ïèê è ïîòåíöèàëüíàÿ âïàäèíà (Comb)        
         case 2 : //ïðåäïîëîæèòåëüíî ñíà÷àëà ñôîðìèðîâàëñÿ LOW ïîòîì HIGH (áû÷èé áàð)
            switch(LET)
              {
               case 1 : //ïðåäûäóùèé ýêñòðåìóì - ïèê
                  if((Fup-Fdn)>MP)
                    {
                     if((lastUP-Fdn)>MP)
                       {
                        UP[i] = Fup;
                        DN[i] = Fdn;
                          } else {
                        if(lastUP<Fup)
                          {
                           UP[lastUPbar]=EMPTY_VALUE;
                           UP[i]=Fup;
                          }
                       }
                       } else {
                     if((lastUP-Fdn)>MP)
                        DN[i]=Fdn;
                     else 
                       {
                        if(lastUP<Fup)
                          {
                           UP[lastUPbar]=EMPTY_VALUE;
                           UP[i]=Fup;
                          }
                       }
                    }
                  break;
               case -1 : //ïðåäûäóùèé ýêñòðåìóì - âïàäèíà
                  if((Fup-Fdn)>MP)
                    {
                     UP[i]=Fup;
                     if((Fdn<lastDN) && (time[lastDNbar]>TimeFirstExtBar))
                       {
                        DN[lastDNbar]=EMPTY_VALUE;
                        DN[i]=Fdn;
                       }
                       } else {
                     if((Fup-lastDN)>MP)
                        UP[i]=Fup;
                     else 
                       {
                        if(lastDN>Fdn)
                          {
                           DN[lastDNbar]=EMPTY_VALUE;
                           DN[i]=Fdn;
                          }
                       }
                    }
                  break;
               default: break;
              } //switch LET
            break;

            //---- íà ðàñ÷åòíîì áàðå ïîòåíöèàëüíûé ïèê è ïîòåíöèàëüíàÿ âïàäèíà (Comb)        
         case -2 : //ïðåäïîëîæèòåëüíî ñíà÷àëà ñôîðìèðîâàëñÿ HIGH ïîòîì LOW (ìåäâåæèé áàð)
            switch(LET)
              {
               case 1 : //ïðåäûäóùèé ýêñòðåìóì - ïèê
                  if((Fup-Fdn)>MP)
                    {
                     DN[i]=Fdn;
                     if((lastUP<Fup) && (time[lastUPbar]>TimeFirstExtBar))
                       {
                        UP[lastUPbar]=EMPTY_VALUE;
                        UP[i]=Fup;
                       }
                       } else {
                     if((lastUP-Fdn)>MP)
                        DN[i]=Fdn;
                     else 
                       {
                        if(lastUP<Fup)
                          {
                           UP[lastUPbar]=EMPTY_VALUE;
                           UP[i]=Fup;
                          }
                       }
                    }
                  break;
               case -1 : //ïðåäûäóùèé ýêñòðåìóì - âïàäèíà
                  if((Fup-Fdn)>MP)
                    {
                     if((Fup-lastDN)>MP)
                       {
                        UP[i] = Fup;
                        DN[i] = Fdn;
                          } else {
                        if(lastDN>Fdn)
                          {
                           DN[lastDNbar]=EMPTY_VALUE;
                           DN[i]=Fdn;
                          }
                       }
                       } else {
                     if((Fup-lastDN)>MP)
                        UP[i]=Fup;
                     else 
                       {
                        if(lastDN>Fdn)
                          {
                           DN[lastDNbar]=EMPTY_VALUE;
                           DN[i]=Fdn;
                          }
                       }
                    }
                  break;
               default: break;
              } //switch LET
            break;

         default: break;
        } // switch (ãëàâíûé)
     } // for (ãëàâíûé)
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ôóíêöèÿ àíàëèçà òåêóùåé ñèòóàöèè                                 |
//+------------------------------------------------------------------+ 
int Comb(int i,double H,double L,double Fup,double Fdn)
  {
//----
   if(Fup==H && (Fdn==0 || (Fdn>0 && Fdn>L))) return(1);  //íà ðàñ÷åòíîì áàðå ïîòåíöèàëüíûé ïèê
   if(Fdn==L && (Fup==0 || (Fup>0 && Fup<H))) return(-1); //íà ðàñ÷åòíîì áàðå ïîòåíöèàëüíàÿ âïàäèíà
   if(Fdn==L && Fup==H)                                   //íà ðàñ÷åòíîì áàðå ïîòåíöèàëüíûé ïèê è ïîòåíöèàëüíàÿ âïàäèíà 
     {
      OrderFormationBarHighLow OrderFormationHL=OFBError;
      // Ïîïûòêà íàéòè êåøèðîâàííûå äàííûå â áóôåðå OB[]
      if(OB[i]==EMPTY_VALUE)
         OrderFormationHL=GetOrderFormationBarHighLow(Symbol(),(ENUM_TIMEFRAMES)Period(),i,iUseSmallerTFforEB);
      if(OrderFormationHL!=OFBError)
         OB[i]=OrderFormationHL;
      else
         OrderFormationHL=(OrderFormationBarHighLow)OB[i];

      switch(OrderFormationHL)
        {
         case OFBLowHigh:       //ïðåäïîëîæèòåëüíî ñíà÷àëà ñôîðìèðîâàëñÿ LOW ïîòîì HIGH (áû÷èé áàð)
            return(2);
            break;
         case OFBHighLow:       //ïðåäïîëîæèòåëüíî ñíà÷àëà ñôîðìèðîâàëñÿ HIGH ïîòîì LOW (ìåäâåæèé áàð)
            return(-2);
            break;
        }
     }
//----  
   return(0);           //íà ðàñ÷åòíîì áàðå ïóñòî...
  }
//+------------------------------------------------------------------+
