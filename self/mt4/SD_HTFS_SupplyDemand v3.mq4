//+------------------------------------------------------------------+
//|                                                    II_SupDem.mq4 |
//|                            Copyright � 2010, Insanity Industries |
//|                                http://www.insanityindustries.net |                                                                 |
//| v.2.3.1 21/7/2010                                                |
//| code by bredin, except where noted                               |
//| donations can be made via PayPal to bredin@lpemail.com           |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2010, Insanity Industries"
#property link      "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=JEHPJ5XSPPN62"

#property indicator_chart_window
#property indicator_buffers 2
extern int  forced.tf = 0;
extern int  FixedHTF = 0;
extern bool draw.zones = true;
extern bool solid.zones = false;
extern bool solid.retouch = false;
extern bool recolor.retouch = true;
extern bool recolor.weak.retouch = false;
extern bool zone.strength = true;
extern bool no.weak.zones = true;
extern bool draw.edge.price = false;
extern int zone.width = 2;
extern bool zone.fibs = false;
extern int fib.style = 0;
extern bool HUD.on = false;
extern bool timer.on = true;
extern int layer.zone = 0;
extern int layer.HUD = 20;
extern int corner.HUD = 3;
extern int pos.x = 100;
extern int pos.y = 20;
extern bool alert.on = true;
extern bool alert.popup = true;
extern string alert.sound = "alert.wav";
extern color color.sup.strong = White;
extern color color.sup.weak = DarkGray;
extern color color.sup.retouch = DarkGray;
extern color color.dem.strong = White;
extern color color.dem.weak = DarkGray;
extern color color.dem.retouch = DarkGray;
extern color color.fib = DodgerBlue;
extern color color.HUD.tf = Navy;
extern color color.arrow.up = SeaGreen;
extern color color.arrow.dn = Crimson;
extern color color.timer.back = DarkGray;
extern color color.timer.bar = Red;
extern color color.shadow = DarkSlateGray;

extern bool limit.zone.vis = false;
extern bool same.tf.vis = true;
extern bool show.on.m1 = false;
extern bool show.on.m5 = true;
extern bool show.on.m15 = false;
extern bool show.on.m30 = false;
extern bool show.on.h1 = false;
extern bool show.on.h4 = false;
extern bool show.on.d1 = false;
extern bool show.on.w1 = false;
extern bool show.on.mn = false;


extern int Price_Width = 1;

extern int time.offset = 0;

extern bool globals = false;

double BuferUp1[];
double BuferDn1[];

double sup.RR[4];
double dem.RR[4];
double sup.width,dem.width;

string l.hud,l.zone;
int HUD.x;
string font.HUD = "Comic Sans MS";
int font.HUD.size = 20;
string font.HUD.price = "Arial Bold";
int font.HUD.price.size = 12;
int arrow.UP = 0x70;
int arrow.DN = 0x71;
string font.arrow = "WingDings 3";
int font.arrow.size = 40;
int font.pair.size = 8;


string arrow.glance;
color color.arrow;
int visible;
int rotation=270;
int lenbase;
string s_base="|||||||||||||||||||||||";
string timer.font="Arial Bold";
int size.timer.font=8;

double min,max;
double iPeriod[4] = {3,8,13,34};
int Dev[4] = {2,5,8,13};
int Step[4] = {2,3,5,8};
datetime t1,t2;
double p1,p2;
string pair;
double point;
int digits;
int tf;
string TAG;

double M1=PERIOD_H1;
double fib.sup,fib.dem;
int SupCount,DemCount;
int SupAlert,DemAlert;
double up.cur,dn.cur;
double fib.level.array[13]={0,0.236,0.386,0.5,0.618,0.786,1,1.276,1.618,2.058,2.618,3.33,4.236};
string fib.level.desc[13]={"0","23.6%","38.6%","50%","61.8%","78.6%","100%","127.6%","161.8%","205.8%","261.80%","333%","423.6%"};

int hud.timer.x,hud.timer.y,hud.arrow.x,hud.arrow.y,hud.tf.x,hud.tf.y;
int hud.sup.x,hud.sup.y,hud.dem.x,hud.dem.y;
int hud.timers.x,hud.timers.y,hud.arrows.x,hud.arrows.y,hud.tfs.x,hud.tfs.y;
int hud.sups.x,hud.sups.y,hud.dems.x,hud.dems.y;

int init()
{
   SetIndexBuffer(1,BuferUp1);
   SetIndexEmptyValue(1,0.0);
   SetIndexStyle(1,DRAW_NONE);
   SetIndexBuffer(0,BuferDn1);
   SetIndexEmptyValue(0,0.0);
   SetIndexStyle(0,DRAW_NONE);

   if(layer.HUD > 25) layer.HUD = 25;
   l.hud = CharToStr(0x61+layer.HUD);
   if(layer.zone > 25) layer.zone = 25;
   l.zone = CharToStr(0x61+layer.zone);

   pair=Symbol();
   if(forced.tf != 0) tf = forced.tf;
      else
   if(Period()==PERIOD_M1)tf =  5;
      else
   if(Period()==PERIOD_M5)tf =  15;
      else
   if(Period()==PERIOD_M15)tf = 30;
      else
   if(Period()==PERIOD_M30)tf = 60;
      else
   if(Period()==PERIOD_H1)tf = 240;
      else
   if(Period()==PERIOD_H4)tf = 1440;
      else
   if(Period()==PERIOD_D1)tf = 10080;
      else
   if(Period()==PERIOD_W1)tf = 43200;
      else
   if(Period()==PERIOD_MN1)tf = 43200;
      else tf = Period();
   point = Point;
   digits = Digits;
   if(digits == 3 || digits == 5) point*=10;
   if(HUD.on && !draw.zones) TAG = "II_HUD"+tf;
   else TAG = "II_SupDem"+tf;
   lenbase=StringLen(s_base);

   if(HUD.on) setHUD();
   if(limit.zone.vis) setVisibility();
   ObDeleteObjectsByPrefix(l.hud+TAG);
   ObDeleteObjectsByPrefix(l.zone+TAG);
   DoLogo();
   return(0);
}

int deinit()
{
   ObDeleteObjectsByPrefix(l.hud+TAG);
   ObDeleteObjectsByPrefix(l.zone+TAG);
   Comment("");
   return(0);
}

int start()
{
   if(NewBar()==true)
   {
      SupAlert = 1;
      DemAlert = 1;
      ObDeleteObjectsByPrefix(l.zone+TAG);
      CountZZ(BuferUp1,BuferDn1,iPeriod[0],Dev[0],Step[0]);
      GetValid(BuferUp1,BuferDn1);
      Draw();
      if(HUD.on) HUD();
   }
   if(HUD.on && timer.on) BarTimer();
   if(alert.on) CheckAlert();
   return(0);
}

void CheckAlert(){
//   SupCount DemCount
//   SupAlert DemAlert
   double price = ObjectGet(l.zone+TAG+"UPAR"+SupAlert,OBJPROP_PRICE1);
   if(Close[0] > price && price > point){
      if(alert.popup) Alert(pair+" "+TimeFrameToString(tf)+" Supply Zone Entered at "+DoubleToStr(price,Digits));
      PlaySound(alert.sound);
      SupAlert++;
   }
   price = ObjectGet(l.zone+TAG+"DNAR"+DemAlert,OBJPROP_PRICE1);
   if(Close[0] < price){
      Alert(pair+" "+TimeFrameToString(tf)+" Demand Zone Entered at "+DoubleToStr(price,Digits));
      PlaySound(alert.sound);
      DemAlert++;
   }
}

void Draw()
{
   int fib.sup.hit=0;
   int fib.dem.hit=0;

   int sc=0,dc=0;
   int i,j,countstrong,countweak;
   color c;
   string s;
   bool exit,draw,fle,fhe,retouch;
   bool valid;
   double val;
   fhe=false;
   fle=false;
   SupCount=0;
   DemCount=0;
   fib.sup=0;
   fib.dem=0;
   for(i=0;i<iBars(pair,tf);i++){
      if(BuferDn1[i] > point){
         retouch = false;
         valid = false;
         t1 = iTime(pair,tf,i);
         t2 = Time[0];
         p2 = MathMin(iClose(pair,tf,i),iOpen(pair,tf,i));
         if(i>0) p2 = MathMax(p2,MathMax(iLow(pair,tf,i-1),iLow(pair,tf,i+1)));
         if(i>0) p2 = MathMax(p2,MathMin(iOpen(pair,tf,i-1),iClose(pair,tf,i-1)));
         p2 = MathMax(p2,MathMin(iOpen(pair,tf,i+1),iClose(pair,tf,i+1)));

         draw=true;
         if(recolor.retouch || !solid.retouch){
            exit = false;
            for(j=i;j>=0;j--){
               if(j==0 && !exit) {draw=false;break;}
               if(!exit && iHigh(pair,tf,j)<p2) {exit=true;continue;}
               if(exit && iHigh(pair,tf,j)>p2) {
                  retouch = true;
                  if(zone.fibs && fib.sup.hit==0){ fib.sup = p2; fib.sup.hit = j;}
                  break;
               }
            }
         }
         if(SupCount != 0) val = ObjectGet(TAG+"UPZONE"+SupCount,OBJPROP_PRICE2); //final sema cull
            else val=0;
         if(draw.zones && draw && BuferDn1[i]!=val) {
            valid=true;
            c = color.sup.strong;
            if(zone.strength && (retouch || !recolor.retouch)){
               countstrong=0;
               countweak=0;
               for(j=i;j<1000000;j++){
                  if(iHigh(pair,tf,j+1)<p2) countstrong++;
                  if(iHigh(pair,tf,j+1)>BuferDn1[i]) countweak++;
                  if(countstrong > 1) break;
                     else if(countweak > 1){
                        c=color.sup.weak;
                        if(no.weak.zones) draw = false;
                        break;
                     }
               }
            }
//         if(c == color.sup.weak && !no.weak.zones) draw = false;
         if(draw){
            if(recolor.retouch && retouch && countweak<2) c = color.sup.retouch;
               else if(recolor.weak.retouch && retouch && countweak>1) c = color.sup.retouch;
            SupCount++;
            if(draw.edge.price){
               s = l.zone+TAG+"UPAR"+SupCount;
               ObjectCreate(s,OBJ_ARROW,0,0,0);
               ObjectSet(s,OBJPROP_ARROWCODE,SYMBOL_RIGHTPRICE);
               ObjectSet(s, OBJPROP_TIME1, t2);
               ObjectSet(s, OBJPROP_PRICE1, p2);
               ObjectSet(s,OBJPROP_COLOR,c);
               ObjectSet(s,OBJPROP_WIDTH,Price_Width);
               if(limit.zone.vis) ObjectSet(s,OBJPROP_TIMEFRAMES,visible);
            }
            s = l.zone+TAG+"UPZONE"+SupCount;
            ObjectCreate(s,OBJ_RECTANGLE,0,0,0,0,0);
            ObjectSet(s,OBJPROP_TIME1,t1);
            ObjectSet(s,OBJPROP_PRICE1,BuferDn1[i]);
            ObjectSet(s,OBJPROP_TIME2,t2);
            ObjectSet(s,OBJPROP_PRICE2,p2);
            ObjectSet(s,OBJPROP_COLOR,c);
            ObjectSet(s,OBJPROP_BACK,true);
            if(limit.zone.vis) ObjectSet(s,OBJPROP_TIMEFRAMES,visible);
            if(!solid.zones) {ObjectSet(s,OBJPROP_BACK,false);ObjectSet(s,OBJPROP_WIDTH,zone.width);}
            if(!solid.retouch && retouch) {ObjectSet(s,OBJPROP_BACK,false);ObjectSet(s,OBJPROP_WIDTH,zone.width);}

            if(globals){
               GlobalVariableSet(TAG+"S.PH"+SupCount,BuferDn1[i]);
               GlobalVariableSet(TAG+"S.PL"+SupCount,p2);
               GlobalVariableSet(TAG+"S.T"+SupCount,iTime(pair,tf,i));
            }
            if(!fhe && c!=color.dem.retouch){fhe=true;GlobalVariableSet(TAG+"GOSHORT",p2);}
            }
         }
         if(draw && sc<4 && HUD.on && valid){
            if(sc==0) sup.width = BuferDn1[i] - p2;
            sup.RR[sc] = p2;
            sc++;
         }

      }

      if(BuferUp1[i] > point){
         retouch = false;
         valid=false;
         t1 = iTime(pair,tf,i);
         t2 = Time[0];
         p2 = MathMax(iClose(pair,tf,i),iOpen(pair,tf,i));
         if(i>0) p2 = MathMin(p2,MathMin(iHigh(pair,tf,i+1),iHigh(pair,tf,i-1)));
         if(i>0) p2 = MathMin(p2,MathMax(iOpen(pair,tf,i-1),iClose(pair,tf,i-1)));
         p2 = MathMin(p2,MathMax(iOpen(pair,tf,i+1),iClose(pair,tf,i+1)));

         c = color.dem.strong;
         draw=true;
         if(recolor.retouch || !solid.retouch){
            exit = false;
            for(j=i;j>=0;j--) {
               if(j==0 && !exit) {draw=false;break;}
               if(!exit && iLow(pair,tf,j)>p2) {exit=true;continue;}
               if(exit && iLow(pair,tf,j)<p2) {
                  retouch = true;
                  if(zone.fibs && fib.dem.hit==0){fib.dem = p2; fib.dem.hit = j; }
                  break;
               }
            }
         }
         if(DemCount != 0) val = ObjectGet(TAG+"DNZONE"+DemCount,OBJPROP_PRICE2); //final sema cull
            else val=0;
         if(draw.zones && draw && BuferUp1[i]!=val){
            valid = true;
            if(zone.strength && (retouch || !recolor.retouch)){
               countstrong=0;
               countweak=0;
               for(j=i;j<1000000;j++){
                  if(iLow(pair,tf,j+1)>p2) countstrong++;
                  if(iLow(pair,tf,j+1)<BuferUp1[i]) countweak++;
                  if(countstrong > 1) break;
                     else if(countweak > 1){
                        if(no.weak.zones) draw = false;
                        c=color.dem.weak;
                        break;
                     }
               }
            }

            if(draw){
            if(recolor.retouch && retouch && countweak<2) c = color.dem.retouch;
               else if(recolor.weak.retouch && retouch && countweak>1) c = color.dem.retouch;

            DemCount++;
            if(draw.edge.price){
               s = l.zone+TAG+"DNAR"+DemCount;
               ObjectCreate(s,OBJ_ARROW,0,0,0);
               ObjectSet(s,OBJPROP_ARROWCODE,SYMBOL_RIGHTPRICE);
               ObjectSet(s, OBJPROP_TIME1, t2);
               ObjectSet(s, OBJPROP_PRICE1, p2);
               ObjectSet(s,OBJPROP_COLOR,c);
               ObjectSet(s,OBJPROP_WIDTH,Price_Width);
               if(limit.zone.vis) ObjectSet(s,OBJPROP_TIMEFRAMES,visible);
            }
            s = l.zone+TAG+"DNZONE"+DemCount;
            ObjectCreate(s,OBJ_RECTANGLE,0,0,0,0,0);
            ObjectSet(s,OBJPROP_TIME1,t1);
            ObjectSet(s,OBJPROP_PRICE1,p2);
            ObjectSet(s,OBJPROP_TIME2,t2);
            ObjectSet(s,OBJPROP_PRICE2,BuferUp1[i]);
            ObjectSet(s,OBJPROP_COLOR,c);
            ObjectSet(s,OBJPROP_BACK,true);
            if(limit.zone.vis) ObjectSet(s,OBJPROP_TIMEFRAMES,visible);
            if(!solid.zones) {ObjectSet(s,OBJPROP_BACK,false);ObjectSet(s,OBJPROP_WIDTH,zone.width);}
            if(!solid.retouch && retouch) {ObjectSet(s,OBJPROP_BACK,false);ObjectSet(s,OBJPROP_WIDTH,zone.width);}
            if(globals){
               GlobalVariableSet(TAG+"D.PL"+DemCount,BuferUp1[i]);
               GlobalVariableSet(TAG+"D.PH"+DemCount,p2);
               GlobalVariableSet(TAG+"D.T"+DemCount,iTime(pair,tf,i));
            }
            if(!fle && c!=color.dem.retouch){fle=true;GlobalVariableSet(TAG+"GOLONG",p2);}
            }
         }
         if(draw && dc<4 && HUD.on && valid){
            if(dc==0) dem.width = p2-BuferUp1[i];
            dem.RR[dc] = p2;
            dc++;
         }
      }
   }
   if(zone.fibs || HUD.on){
      double a,b;
      int dr=0;
      int sr=0;
      int d1=0;
      int s1=0;
      int t;
      for(i=0;i<100000;i++){
         if(iHigh(pair,tf,i)>fib.sup && sr==0) sr = i;
         if(iHigh(pair,tf,i)>sup.RR[0] && s1==0) s1 = i;
         if(iLow(pair,tf,i)<fib.dem && dr==0) dr = i;
         if(iLow(pair,tf,i)<dem.RR[0] && d1==0) d1 = i;
         if(sr!=0&&s1!=0&&dr!=0&&d1!=0) break;
      }
   }

      if(zone.fibs){

         if(dr<sr) {b = fib.dem;a = sup.RR[0];}
            else {b = fib.sup;a = dem.RR[0];}


         s = l.zone+TAG+"FIBO";
         ObjectCreate(s, OBJ_FIBO, 0,Time[0],a,Time[0],b);
	      ObjectSet(s, OBJPROP_COLOR, CLR_NONE);
	      ObjectSet(s, OBJPROP_STYLE, fib.style);
	      ObjectSet(s, OBJPROP_RAY, true);
	      ObjectSet(s, OBJPROP_BACK, true);
         if(limit.zone.vis) ObjectSet(s,OBJPROP_TIMEFRAMES,visible);
         int level_count=ArraySize(fib.level.array);

         ObjectSet(s, OBJPROP_FIBOLEVELS, level_count);
         ObjectSet(s, OBJPROP_LEVELCOLOR, color.fib);

         for(j=0; j<level_count; j++){
            ObjectSet(s, OBJPROP_FIRSTLEVEL+j, fib.level.array[j]);
            ObjectSetFiboDescription(s,j,fib.level.desc[j]);
         }
      }
      if(HUD.on) {
         if(d1<s1) {b = dem.RR[0];a = sup.RR[0]; arrow.glance = CharToStr(arrow.UP); color.arrow = color.arrow.up;}
            else {b = sup.RR[0];a = dem.RR[0]; arrow.glance = CharToStr(arrow.DN); color.arrow = color.arrow.dn;}
         min = MathMin(a,b);
         max = MathMax(a,b);
      }


}

bool NewBar() {
	static datetime LastTime = 0;
	if (iTime(pair,tf,0)+time.offset != LastTime) {
		LastTime = iTime(pair,tf,0)+time.offset;
		return (true);
	} else
		return (false);
}

void ObDeleteObjectsByPrefix(string Prefix){
   int L = StringLen(Prefix);
   int i = 0;
   while(i < ObjectsTotal()) {
      string ObjName = ObjectName(i);
      if(StringSubstr(ObjName, 0, L) != Prefix) {
         i++;
         continue;
      }
      ObjectDelete(ObjName);
   }
}

int CountZZ( double& ExtMapBuffer[], double& ExtMapBuffer2[], int ExtDepth, int ExtDeviation, int ExtBackstep ){ // based on code (C) metaquote{
    int    shift, back, lasthighpos, lastlowpos;
    double val, res;
    double curlow, curhigh, lasthigh, lastlow;
    int count = iBars(pair,tf)-ExtDepth;

    for(shift=count; shift>=0; shift--){
        val = iLow(pair,tf,iLowest(pair,tf,MODE_LOW,ExtDepth,shift));
        if(val==lastlow) val=0.0;
        else {
            lastlow=val;
            if((iLow(pair,tf,shift)-val)>(ExtDeviation*Point)) val=0.0;
            else{
                for(back=1; back<=ExtBackstep; back++){
                    res=ExtMapBuffer[shift+back];
                    if((res!=0)&&(res>val)) ExtMapBuffer[shift+back]=0.0;
                }
            }
        }
        ExtMapBuffer[shift]=val;

        //--- high
        val=iHigh(pair,tf,iHighest(pair,tf,MODE_HIGH,ExtDepth,shift));

        if(val==lasthigh) val=0.0;
        else {
            lasthigh=val;
            if((val-iHigh(pair,tf,shift))>(ExtDeviation*Point)) val=0.0;
            else{
                for(back=1; back<=ExtBackstep; back++){
                    res=ExtMapBuffer2[shift+back];
                    if((res!=0)&&(res<val)) ExtMapBuffer2[shift+back]=0.0;
                }
            }
        }
        ExtMapBuffer2[shift]=val;
    } //for loop

    // final cutting
    lasthigh=-1; lasthighpos=-1;
    lastlow=-1;  lastlowpos=-1;

    for(shift=count; shift>=0; shift--){
        curlow=ExtMapBuffer[shift];
        curhigh=ExtMapBuffer2[shift];
        if((curlow==0)&&(curhigh==0)) continue;
        //---
        if(curhigh!=0){
            if(lasthigh>0) {
                if(lasthigh<curhigh) ExtMapBuffer2[lasthighpos]=0;
                else ExtMapBuffer2[shift]=0;
            }
            //---
            if(lasthigh<curhigh || lasthigh<0){
                lasthigh=curhigh;
                lasthighpos=shift;
            }
            lastlow=-1;
        }
        //----
        if(curlow!=0){
            if(lastlow>0){
                if(lastlow>curlow) ExtMapBuffer[lastlowpos]=0;
                else ExtMapBuffer[shift]=0;
            }
            //---
            if((curlow<lastlow)||(lastlow<0)){
                lastlow=curlow;
                lastlowpos=shift;
            }
            lasthigh=-1;
        }
    } //for loop 2

    for(shift=iBars(pair,tf)-1; shift>=0; shift--){
        if(shift>=count) ExtMapBuffer[shift]=0.0;
        else {
            res=ExtMapBuffer2[shift];
            if(res!=0.0) ExtMapBuffer2[shift]=res;
        }
    } // for loop 3
}

void GetValid(double& ExtMapBuffer[], double& ExtMapBuffer2[]){
   up.cur = 0;
   int upbar = 0;
   dn.cur = 0;
   int dnbar = 0;
   double cur.hi = 0;
   double cur.lo = 0;
   double last.up = 0;
   double last.dn = 0;
   double low.dn = 0;
   double hi.up = 0;
   int i;
   for(i=0;i<iBars(pair,tf);i++) if(ExtMapBuffer[i] > 0){
      up.cur = ExtMapBuffer[i];
      cur.lo = ExtMapBuffer[i];
      last.up = cur.lo;
      break;
   }
   for(i=0;i<iBars(pair,tf);i++) if(ExtMapBuffer2[i] > 0){
      dn.cur = ExtMapBuffer2[i];
      cur.hi = ExtMapBuffer2[i];
      last.dn = cur.hi;
      break;
   }

   for(i=0;i<iBars(pair,tf);i++) // remove higher lows and lower highs
   {
      if(ExtMapBuffer2[i] >= last.dn) {
         last.dn = ExtMapBuffer2[i];
         dnbar = i;
      }
         else ExtMapBuffer2[i] = 0.0;
      if(ExtMapBuffer2[i] <= dn.cur && ExtMapBuffer[i] > 0.0) ExtMapBuffer2[i] = 0.0;
      if(ExtMapBuffer[i] <= last.up && ExtMapBuffer[i] > 0) {
         last.up = ExtMapBuffer[i];
         upbar = i;
      }
         else ExtMapBuffer[i] = 0.0;
      if(ExtMapBuffer[i] > up.cur) ExtMapBuffer[i] = 0.0;
   }
   low.dn = MathMin(iOpen(pair,tf,dnbar),iClose(pair,tf,dnbar));
   hi.up = MathMax(iOpen(pair,tf,upbar),iClose(pair,tf,upbar));
   for(i=MathMax(upbar,dnbar);i>=0;i--) {// work back to zero and remove reentries into s/d
      if(ExtMapBuffer2[i] > low.dn && ExtMapBuffer2[i] != last.dn) ExtMapBuffer2[i] = 0.0;
         else if(ExtMapBuffer2[i] > 0) {
            last.dn = ExtMapBuffer2[i];
         low.dn = MathMin(iClose(pair,tf,i),iOpen(pair,tf,i));
         if(i>0) low.dn = MathMax(low.dn,MathMax(iLow(pair,tf,i-1),iLow(pair,tf,i+1)));
         if(i>0) low.dn = MathMax(low.dn,MathMin(iOpen(pair,tf,i-1),iClose(pair,tf,i-1)));
         low.dn = MathMax(low.dn,MathMin(iOpen(pair,tf,i+1),iClose(pair,tf,i+1)));
         }
      if(ExtMapBuffer[i] <= hi.up && ExtMapBuffer[i] > 0 && ExtMapBuffer[i] != last.up) ExtMapBuffer[i] = 0.0;
         else if(ExtMapBuffer[i] > 0){
            last.up = ExtMapBuffer[i];
            hi.up = MathMax(iClose(pair,tf,i),iOpen(pair,tf,i));
            if(i>0) hi.up = MathMin(hi.up,MathMin(iHigh(pair,tf,i+1),iHigh(pair,tf,i-1)));
            if(i>0) hi.up = MathMin(hi.up,MathMax(iOpen(pair,tf,i-1),iClose(pair,tf,i-1)));
            hi.up = MathMin(hi.up,MathMax(iOpen(pair,tf,i+1),iClose(pair,tf,i+1)));
         }
   }
}

void HUD()
{
   string s = TimeFrameToString(tf);
   string u = DoubleToStr(ObjectGet(l.zone+TAG+"UPAR"+1,OBJPROP_PRICE1),Digits);
   string d = DoubleToStr(ObjectGet(l.zone+TAG+"DNAR"+1,OBJPROP_PRICE1),Digits);
   string l = "b";
   DrawText(l,s,hud.tf.x,hud.tf.y,color.HUD.tf,font.HUD,font.HUD.size,corner.HUD);
   DrawText(l,arrow.glance,hud.arrow.x,hud.arrow.y,color.arrow,font.arrow,font.arrow.size,corner.HUD,0,true);
   DrawText(l,u,hud.sup.x,hud.sup.y,color.sup.strong,font.HUD.price,font.HUD.price.size,corner.HUD);
   DrawText(l,d,hud.dem.x,hud.dem.y,color.dem.strong,font.HUD.price,font.HUD.price.size,corner.HUD);

   l = "a";
   DrawText(l,s,hud.tfs.x,hud.tfs.y,color.shadow,font.HUD,font.HUD.size,corner.HUD);
   DrawText(l,arrow.glance,hud.arrows.x,hud.arrows.y,color.shadow,font.arrow,font.arrow.size,corner.HUD,0,true);
   DrawText(l,u,hud.sups.x,hud.sups.y,color.shadow,font.HUD.price,font.HUD.price.size,corner.HUD);
   DrawText(l,d,hud.dems.x,hud.dems.y,color.shadow,font.HUD.price,font.HUD.price.size,corner.HUD);

}

void BarTimer() // Original Code by Vasyl Gumenyak, I just fucked it up
{
   int i=0,sec=0;
   double pc=0.0;
   string time="",s_end="",s;
   s = l.hud+TAG+"btimerback";
   if (ObjectFind(s) == -1) {
      ObjectCreate(s , OBJ_LABEL,0,0,0);
      ObjectSet(s, OBJPROP_XDISTANCE, hud.timer.x);
      ObjectSet(s, OBJPROP_YDISTANCE, hud.timer.y);
      ObjectSet(s, OBJPROP_CORNER, corner.HUD);
      ObjectSet(s, OBJPROP_ANGLE, rotation);
      ObjectSetText(s, s_base, size.timer.font, timer.font, color.timer.back);
   }

   sec=TimeCurrent()-iTime(pair,tf,0);
   i=(lenbase-1)*sec/(tf*60);
   pc=100-(100.0*sec/(tf*60));
   if(i>lenbase-1) i=lenbase-1;
   if(i<lenbase-1) s_end=StringSubstr(s_base,i+1,lenbase-i-1);
   time=StringConcatenate("|",s_end);

   s = l.hud+TAG+"timerfront";
   if (ObjectFind(s) == -1) {
     ObjectCreate(s , OBJ_LABEL,0,0,0);
     ObjectSet(s, OBJPROP_XDISTANCE, hud.timer.x);
     ObjectSet(s, OBJPROP_YDISTANCE, hud.timer.y);
     ObjectSet(s, OBJPROP_CORNER, corner.HUD);
     ObjectSet(s, OBJPROP_ANGLE, rotation);
   }
   ObjectSetText(s, time, size.timer.font, timer.font, color.timer.bar);
}

void DrawText(string l, string t, int x, int y, color c, string f, int s, int k=0, int a=0, bool b=false)
{
   string tag = l.hud+TAG+l+x+y;
   ObjectDelete(tag);
   ObjectCreate(tag,OBJ_LABEL,0,0,0);
   ObjectSetText(tag,t,s,f,c);
   ObjectSet(tag,OBJPROP_XDISTANCE,x);
   ObjectSet(tag,OBJPROP_YDISTANCE,y);
   ObjectSet(tag,OBJPROP_CORNER,k);
   ObjectSet(tag,OBJPROP_ANGLE,a);
   if(b) ObjectSet(tag,OBJPROP_BACK,true);
}

string TimeFrameToString(int tf) //code by TRO
{
   string tfs;
   switch(tf) {
      case PERIOD_M1:  tfs="M1"  ; break;
      case PERIOD_M5:  tfs="M5"  ; break;
      case PERIOD_M15: tfs="M15" ; break;
      case PERIOD_M30: tfs="M30" ; break;
      case PERIOD_H1:  tfs="H1"  ; break;
      case PERIOD_H4:  tfs="H4"  ; break;
      case PERIOD_D1:  tfs="D1"  ; break;
      case PERIOD_W1:  tfs="W1"  ; break;
      case PERIOD_MN1: tfs="MN";
   }
   return(tfs);
}

void setHUD()
{
   switch(tf) {
      case PERIOD_M1:  HUD.x=7 ; break;
      case PERIOD_M5:  HUD.x=7 ; break;
      case PERIOD_M15: HUD.x=3 ; break;
      case PERIOD_M30: HUD.x=2 ; break;
      case PERIOD_H1:  HUD.x=12 ; break;
      case PERIOD_H4:  HUD.x=8 ; break;
      case PERIOD_D1 : HUD.x=12 ; break;
      case PERIOD_W1:  HUD.x=8 ; break;
      case PERIOD_MN1: HUD.x=7 ; break;
   }
   if(corner.HUD > 3) corner.HUD=0;
   if(corner.HUD == 0 || corner.HUD == 2) rotation = 90;
   switch(corner.HUD){
      case 0 : hud.tf.x = pos.x-HUD.x+10;
               hud.tf.y = pos.y+18;
               hud.arrow.x = pos.x-2;
               hud.arrow.y = pos.y+7;
               hud.sup.x = pos.x;
               hud.sup.y = pos.y;
               hud.dem.x = pos.x;
               hud.dem.y = pos.y+56;
               hud.timer.x = pos.x+50;
               hud.timer.y = pos.y+72;
               hud.tfs.x = hud.tf.x+1;
               hud.tfs.y = hud.tf.y+1;
               hud.arrows.x = hud.arrow.x+1;
               hud.arrows.y = hud.arrow.y+1;
               hud.sups.x = hud.sup.x+1;
               hud.sups.y = hud.sup.y+1;
               hud.dems.x = hud.dem.x+1;
               hud.dems.y = hud.dem.y+1;
               break;
      case 1 : hud.tf.x = pos.x+HUD.x;
               hud.tf.y = pos.y+18;
               hud.arrow.x = pos.x+2;
               hud.arrow.y = pos.y+7;
               hud.sup.x = pos.x;
               hud.sup.y = pos.y;
               hud.dem.x = pos.x;
               hud.dem.y = pos.y+56;
               hud.timer.x = pos.x-15;
               hud.timer.y = pos.y+71;
               hud.tfs.x = hud.tf.x-1;
               hud.tfs.y = hud.tf.y+1;
               hud.arrows.x = hud.arrow.x-1;
               hud.arrows.y = hud.arrow.y+1;
               hud.sups.x = hud.sup.x-1;
               hud.sups.y = hud.sup.y+1;
               hud.dems.x = hud.dem.x-1;
               hud.dems.y = hud.dem.y+1;
               break;
      case 2 : hud.tf.x = pos.x-HUD.x;
               hud.tf.y = pos.y+20;
               hud.arrow.x = pos.x-2;
               hud.arrow.y = pos.y+7;
               hud.sup.x = pos.x;
               hud.sup.y = pos.y+56;
               hud.dem.x = pos.x;
               hud.dem.y = pos.y;
               hud.timer.x = pos.x+62;
               hud.timer.y = pos.y+3;
               hud.tfs.x = hud.tf.x+1;
               hud.tfs.y = hud.tf.y-1;
               hud.arrows.x = hud.arrow.x+1;
               hud.arrows.y = hud.arrow.y-1;
               hud.sups.x = hud.sup.x+1;
               hud.sups.y = hud.sup.y-1;
               hud.dems.x = hud.dem.x+1;
               hud.dems.y = hud.dem.y-1;
               break;
      case 3 : hud.tf.x = pos.x+HUD.x;
               hud.tf.y = pos.y+20;
               hud.arrow.x = pos.x+2;
               hud.arrow.y = pos.y+7;
               hud.sup.x = pos.x;
               hud.sup.y = pos.y+56;
               hud.dem.x = pos.x;
               hud.dem.y = pos.y;
               hud.timer.x = pos.x-2;
               hud.timer.y = pos.y+3;
               hud.tfs.x = hud.tf.x-1;
               hud.tfs.y = hud.tf.y-1;
               hud.arrows.x = hud.arrow.x-1;
               hud.arrows.y = hud.arrow.y-1;
               hud.sups.x = hud.sup.x-1;
               hud.sups.y = hud.sup.y-1;
               hud.dems.x = hud.dem.x-1;
               hud.dems.y = hud.dem.y-1;
               break;
   }
}

void DoLogo(){
   string TAG = CharToStr(0x61+27)+"II_Logo";
   if( ObjectFind(TAG+"ZZ"+0) >= 0 && ObjectFind(TAG+"ZZ"+1) >= 0 && ObjectFind(TAG+"ZZ"+2) >= 0  &&
       ObjectFind(TAG+"AZ"+0) >= 0 && ObjectFind(TAG+"AZ"+1) >= 0 && ObjectFind(TAG+"AZ"+2) >= 0 ) return;
   string str[3] = {".","."};
   int size[0] = {0,0,0};
   int pos.x[3] = {0,0,0};
   int pos.y[3] = {0,0,0};
   int pos.xs[3] = {0,0,0};
   int pos.ys[3] = {0,0,0};
   for(int i=0;i<3;i++){
      string n = TAG+"ZZ"+i;
      ObjectDelete(n);
      ObjectCreate(n,OBJ_LABEL,0,0,0);
      ObjectSetText(n,str[i],size[i],"Pieces Of Eight",AliceBlue);
      ObjectSet(n,OBJPROP_XDISTANCE,pos.x[i]);
      ObjectSet(n,OBJPROP_YDISTANCE,pos.y[i]);
      ObjectSet(n,OBJPROP_CORNER,3);
      n = TAG+"AZ"+i;
      ObjectDelete(n);
      ObjectCreate(n,OBJ_LABEL,0,0,0);
      ObjectSetText(n,str[i],size[i],"Pieces Of Eight",Black);
      ObjectSet(n,OBJPROP_XDISTANCE,pos.xs[i]);
      ObjectSet(n,OBJPROP_YDISTANCE,pos.ys[i]);
      ObjectSet(n,OBJPROP_CORNER,3);
   }
}

void setVisibility()
{
   int per = Period();
   visible=0;
   if(same.tf.vis){
  	   if(forced.tf == per || forced.tf == 0){
  	      switch(per){
            case PERIOD_M1:  visible= 0x0001 ; break;
            case PERIOD_M5:  visible= 0x0002 ; break;
            case PERIOD_M15: visible= 0x0004 ; break;
            case PERIOD_M30: visible= 0x0008 ; break;
            case PERIOD_H1:  visible= 0x0010 ; break;
            case PERIOD_H4:  visible= 0x0020 ; break;
            case PERIOD_D1:  visible= 0x0040 ; break;
            case PERIOD_W1:  visible= 0x0080 ; break;
            case PERIOD_MN1: visible= 0x0100 ;
  	      }
  	   }
  	} else {
  	  if(show.on.m1) visible += 0x0001;
	  if(show.on.m5) visible += 0x0002;
	  if(show.on.m15) visible += 0x0004;
	  if(show.on.m30) visible += 0x0008;
	  if(show.on.h1) visible += 0x0010;
	  if(show.on.h4) visible += 0x0020;
	  if(show.on.d1) visible += 0x0040;
	  if(show.on.w1) visible += 0x0080;
	  if(show.on.mn) visible += 0x0100;
   }

}
