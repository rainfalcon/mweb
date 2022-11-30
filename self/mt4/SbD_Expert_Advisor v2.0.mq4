//+------------------------------------------------------------------+
//  SUPPLY AND DEMAND EA                                             |
//+------------------------------------------------------------------+
#property version   "1.00"
#property strict
input string comEAsettings="[EA settings]";//~
input double lots=0.1;
input int MagicNumber=55545;
input string EA_Comment="";
extern string str = "   -  =  shved_supply_and_demand =  -";//set
extern int BackLimit=1000;

extern string pus1="/////////////////////////////////////////////////";
extern bool zone_show_weak=true;
extern bool zone_show_untested = true;
extern bool zone_show_turncoat = false;
extern double zone_fuzzfactor=0.75;

extern string pus2="/////////////////////////////////////////////////";
extern bool fractals_show=false;
extern double fractal_fast_factor = 3.0;
extern double fractal_slow_factor = 6.0;
extern bool SetGlobals=true;

extern string pus3="/////////////////////////////////////////////////";
double _point=1;
double last_sup,last_res;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
//Get Symbol digit
   string _sym=Symbol();
   double _digits=MarketInfo(_sym,MODE_DIGITS);
   if(_digits==5||_digits==3) _point=1/MathPow(10,(_digits-1));
   if(_digits==4||_digits==2) _point=1/MathPow(10,(_digits));
   if(_digits==1) _point=0.1;
   last_sup=-1;last_res=-1;
//
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
    get_indi();
    double current_res=get_res();
    if(OrdersTotalT(OP_SELL)==0 && Ask>current_res && current_res!=last_res) {
        double _sl= MathAbs(current_res -get_res_sl())/_point;
        SendOrder(OP_SELL,_sl);
        last_res=current_res;
    }
    double _sup=get_sup();
    if(OrdersTotalT(OP_BUY)==0 && Bid<_sup && _sup!=0 && last_sup!=_sup) {
        double _sl = MathAbs(_sup -get_sup_sl())/_point;//
        SendOrder(OP_BUY,_sl);
        last_sup=_sup;
    }
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    //---
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
    //---

}
//+------------------------------------------------------------------+
// function to send order
bool SendOrder(int type,double _sl) {
    while(IsTradeContextBusy());
    int ticket=-1;
    double SL,TP;
    if(type==OP_BUY) {
        if(_sl==0){SL=0;}else{SL=Ask-_sl*_point;}
        if(_sl==0){TP=0;}else{TP=Ask+3*_sl*_point;}
        ticket=OrderSend(Symbol(),OP_BUY,NormalizeLots(lots,Symbol()),Ask,3,SL,TP,EA_Comment,MagicNumber,0);
    }
    if(type==OP_SELL) {
        if(_sl==0){SL=0;}else{SL=Bid+_sl*_point;}
        if(_sl==0){TP=0;}else{TP=Bid-3*_sl*_point;}
        ticket=OrderSend(Symbol(),OP_SELL,NormalizeLots(lots,Symbol()),Bid,3,SL,TP,EA_Comment,MagicNumber,0);
    }
    if(ticket<0) {
        Print("OrderSend  failed with error #",GetLastError());
        return(false);
    }
    return(true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//make lots to right format
double NormalizeLots(double _lots,string pair="") {
    if(pair=="") pair=Symbol();
    double  lotStep=MarketInfo(pair,MODE_LOTSTEP),
    minLot=MarketInfo(pair,MODE_MINLOT);
    _lots=MathRound(_lots/lotStep)*lotStep;
    if(_lots<MarketInfo(pair,MODE_MINLOT)) _lots=MarketInfo(pair,MODE_MINLOT);
    if(_lots>MarketInfo(pair,MODE_MAXLOT)) _lots=MarketInfo(pair,MODE_MAXLOT);
    return(_lots);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// get res level from the chart
double get_res() {
    double _res=999999999999;
    double _tmp=0;
    long _chart=ChartID();
    for(int i=0;i<ObjectsTotal(_chart);i++) {
        string _name=ObjectName(_chart,i);
        if(StringFind(_name,"R#R",0)>0 && StringFind(_name,"Untested",0)>0) _tmp=ObjectGetDouble(_chart,_name,OBJPROP_PRICE2);
        if(_res>_tmp && _tmp!=0) _res=_tmp;
    }
    return(_res);
}

double get_res_sl() {
    double _res=999999999999;
    double _tmp=0;
    long _chart=ChartID();
    for(int i=0;i<ObjectsTotal(_chart);i++) {
        string _name=ObjectName(_chart,i);
        if(StringFind(_name,"R#R",0)>0 && StringFind(_name,"Untested",0)>0) _tmp=ObjectGetDouble(_chart,_name,OBJPROP_PRICE1);
        if(_res>_tmp && _tmp!=0) _res=_tmp;
    }
    return(_res);
}
//+------------------------------------------------------------------+

int OrdersTotalT(int _type) {
    int _total=0;
    for(int cnt=OrdersTotal()-1;cnt>=0;cnt--) {
        bool select=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
        if(OrderMagicNumber()==MagicNumber && OrderSymbol()==Symbol() && OrderType()==_type) {
            _total++;
        }
    }
    return(_total);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

double get_sup() {
    double _res=0;
    double _tmp=0;
    long _chart=ChartID();
    for(int i=0;i<ObjectsTotal(_chart);i++) {
        string _name=ObjectName(_chart,i);
        if(StringFind(_name,"R#S",0)>0 && StringFind(_name,"Untested",0)>0){ _tmp=ObjectGetDouble(_chart,_name,OBJPROP_PRICE1);}
        if(_res<_tmp && _tmp!=0) _res=_tmp;
    }
    return(_res);// return lower untested support
}

double get_sup_sl() {
    double _res=0;
    double _tmp=0;
    long _chart=ChartID();
    for(int i=0;i<ObjectsTotal(_chart);i++) {
        string _name=ObjectName(_chart,i);
        if(StringFind(_name,"R#S",0)>0 && StringFind(_name,"Untested",0)>0) _tmp=ObjectGetDouble(_chart,_name,OBJPROP_PRICE2);

        if(_res<_tmp && _tmp!=0) _res=_tmp;
    }
    return(_res);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

double get_indi() {
    return(iCustom(NULL,0,"shved_supply_and_demand",BackLimit,pus1,zone_show_weak,zone_show_untested,zone_show_turncoat,zone_fuzzfactor,pus2,fractals_show,fractal_fast_factor,fractal_slow_factor,SetGlobals,pus3,0,0));
}
//+------------------------------------------------------------------+
