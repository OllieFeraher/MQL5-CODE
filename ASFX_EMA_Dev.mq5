//+------------------------------------------------------------------+
//|                                                    ASFX_EMAs.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 15
#property indicator_plots 15

#property indicator_type1 DRAW_LINE //VWAP
#property indicator_color1 clrYellow
#property indicator_width1 1
#property indicator_style1 STYLE_SOLID
#property indicator_label1 "EMA_8"

#property indicator_type2 DRAW_LINE //VWAP
#property indicator_color2 clrRed
#property indicator_width2 1
#property indicator_style2 STYLE_SOLID
#property indicator_label2 "EMA_21"

#property indicator_type3 DRAW_LINE //VWAP
#property indicator_color3 clrLightBlue
#property indicator_width3 1
#property indicator_style3 STYLE_SOLID
#property indicator_label3 "EMA_50"

#property indicator_type4 DRAW_LINE //VWAP
#property indicator_color4 clrAntiqueWhite
#property indicator_width4 1
#property indicator_style4 STYLE_SOLID
#property indicator_label4 "EMA_200"

#property indicator_type5 DRAW_LINE //VWAP
#property indicator_color5 clrViolet
#property indicator_width5 1
#property indicator_style5 STYLE_SOLID
#property indicator_label5 "EMA_800"

#property indicator_type12 DRAW_LINE //VWAP
#property indicator_color12 clrOrange
#property indicator_width12 3
#property indicator_style12 STYLE_SOLID
#property indicator_label12 "COMMANDING"

#property indicator_type13 DRAW_LINE 
#property indicator_color13 clrPink
#property indicator_width13 2
#property indicator_style13 STYLE_DASH
#property indicator_label13 "DEVAbove"

#property indicator_type14 DRAW_LINE 
#property indicator_color14 clrPink
#property indicator_width14 2
#property indicator_style14 STYLE_DASH
#property indicator_label14 "DEVBelow"


/*
#property indicator_type7 DRAW_LINE //VWAP
#property indicator_color7 clrPink
#property indicator_width7 1
#property indicator_style7 STYLE_DASH
#property indicator_label7 "Asian High"

#property indicator_type8 DRAW_LINE //VWAP
#property indicator_color8 clrPink
#property indicator_width8 1
#property indicator_style8 STYLE_DASH
#property indicator_label8 "Asian Low"

#property indicator_type10 DRAW_LINE 
#property indicator_color10 clrWhite
#property indicator_width10 1
#property indicator_style10 STYLE_DASH
#property indicator_label10 "HOD"

#property indicator_type11 DRAW_LINE
#property indicator_color11 clrWhite
#property indicator_width11 1
#property indicator_style11 STYLE_DASH
#property indicator_label11 "LOD"
*/

double _8EMA[];
double _21EMA[];
double _50EMA[];
double _200EMA[];
double _800EMA[];

double _DEV[];
double _800DEVAbove[];
double _800DEVBelow[];

double _CTF[];

double _ADR[];

double _asianHigh[];
double _asianLow[];

double asianHighValue;
double asianLowValue;

double _avgCandleSize[];
double _HOD[];
double _LOD[];

double averageCandleSize;
double candlesCumulative;
double HOD;
double LOD;

int ema8Handle;
int ema21Handle;
int ema50Handle;
int ema200Handle;
int ema800Handle;
int ctfHandle;
int adrHandle;

int MaxPeriod = 0;

int currentDay;

int count = 1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
   ema8Handle = iMA(_Symbol,PERIOD_CURRENT,8,0,MODE_EMA,PRICE_CLOSE);
   ema21Handle = iMA(_Symbol,PERIOD_CURRENT,21,0,MODE_EMA,PRICE_CLOSE);
   ema50Handle = iMA(_Symbol,PERIOD_CURRENT,50,0,MODE_EMA,PRICE_CLOSE);
   ema200Handle = iMA(_Symbol,PERIOD_CURRENT,200,0,MODE_EMA,PRICE_CLOSE);
   ema800Handle = iMA(_Symbol,PERIOD_CURRENT,800,0,MODE_EMA,PRICE_CLOSE);
   //adrHandle = iATR(_Symbol,PERIOD_D1,20);
   
   ctfHandle = iMA(_Symbol,PERIOD_CURRENT,200*12,0,MODE_EMA,PRICE_CLOSE);
   
   SetIndexBuffer(0, _8EMA, INDICATOR_DATA);
   SetIndexBuffer(1, _21EMA, INDICATOR_DATA);
   SetIndexBuffer(2, _50EMA, INDICATOR_DATA);
   SetIndexBuffer(3, _200EMA, INDICATOR_DATA);
   SetIndexBuffer(4, _800EMA, INDICATOR_DATA);
   SetIndexBuffer(5, _ADR, INDICATOR_DATA);
   
   SetIndexBuffer(7, _asianLow, INDICATOR_DATA);
   SetIndexBuffer(6, _asianHigh, INDICATOR_DATA);
   
   SetIndexBuffer(8,    _avgCandleSize, INDICATOR_DATA);
   SetIndexBuffer(9,    _LOD, INDICATOR_DATA);
   SetIndexBuffer(10,   _HOD, INDICATOR_DATA);
   
   SetIndexBuffer(11, _CTF, INDICATOR_DATA);
   SetIndexBuffer(12, _800DEVAbove, INDICATOR_DATA);
   SetIndexBuffer(13, _800DEVBelow, INDICATOR_DATA);
   SetIndexBuffer(14,_DEV,INDICATOR_DATA);
   
   ArraySetAsSeries(_8EMA,true);
   ArraySetAsSeries(_21EMA,true);
   ArraySetAsSeries(_50EMA,true);
   ArraySetAsSeries(_200EMA,true);
   ArraySetAsSeries(_800EMA,true);
   ArraySetAsSeries(_CTF,true);
   
   ArraySetAsSeries(_800DEVAbove,true);
   ArraySetAsSeries(_800DEVBelow,true);
   ArraySetAsSeries(_DEV,true);
   //ArraySetAsSeries(_ADR,true);
   
   ArraySetAsSeries(_asianHigh,true);
   ArraySetAsSeries(_asianLow,true);
   
   ArraySetAsSeries(_avgCandleSize,true);
   ArraySetAsSeries(_LOD,true);
   ArraySetAsSeries(_HOD,true);
   
   MaxPeriod = 800;
   
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(6, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(7, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(8, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(10, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(11, PLOT_EMPTY_VALUE, 0);
   
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(5, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(6, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(7, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(8, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(10, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetInteger(11, PLOT_DRAW_BEGIN, 0);
   
   PlotIndexSetDouble(12, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(12, PLOT_DRAW_BEGIN, 0);
   
   PlotIndexSetDouble(13, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(13, PLOT_DRAW_BEGIN, 0);
   
   PlotIndexSetDouble(14, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(14, PLOT_DRAW_BEGIN, 0);
   
   
   PlotIndexSetDouble(15, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(15, PLOT_DRAW_BEGIN, 0);
//---
   return(INIT_SUCCEEDED);
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
//---

   int i;
   int counted_bars = prev_calculated;
   
   if(rates_total < MaxPeriod) return 0; //not enough bars
   
   i = rates_total - counted_bars; //remaining bars to calculate
   if(i > rates_total - MaxPeriod - 1) i = rates_total - MaxPeriod - 1; 
   
   CopyBuffer(ema8Handle,0,0,rates_total, _8EMA);
   CopyBuffer(ema21Handle,0,0,rates_total, _21EMA);
   CopyBuffer(ema50Handle,0,0,rates_total, _50EMA);
   CopyBuffer(ema200Handle,0,0,rates_total, _200EMA);
   CopyBuffer(ema800Handle,0,0,rates_total, _800EMA);
   
   CopyBuffer(ctfHandle,0,0,rates_total, _CTF);
   
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(_avgCandleSize,true);
   ArraySetAsSeries(_HOD,true);
   ArraySetAsSeries(_LOD,true);
   
   datetime currentTime;
   while(i >= 0){
   count++;
   double candleDelta = MathAbs(open[i] - close[i]);
   candlesCumulative += candleDelta;
   averageCandleSize = candlesCumulative/count;
   //_avgCandleSize[i] =  averageCandleSize;
   //Print(_8EMA[i]);
   bool asianSession;
   currentTime = time[i];
   MqlDateTime mqlCurrentTime;
   TimeToStruct(currentTime,mqlCurrentTime);
   if(mqlCurrentTime.day != currentDay){
      currentDay = mqlCurrentTime.day;
      asianHighValue = close[i]; 
      asianLowValue = close[i];
      HOD = high[i];
      LOD = low[i];
   }
   if(mqlCurrentTime.hour < 7){
      if(low[i] < asianLowValue) asianLowValue = low[i];
      if(high[i] > asianHighValue) asianHighValue = high[i];
   }
   
   if(high[i] > HOD) HOD = high[i];
   if(low[i] < LOD)  LOD = low[i];
   
   _asianLow[i]   = asianLowValue;
   _asianHigh[i]  = asianHighValue;
   _HOD[i] = HOD;
   _LOD[i] = LOD;
   
   
   if(count > 800){
   _DEV[i] = stndDev(i,close,_800EMA);
   _800DEVAbove[i] = _800EMA[i] + 1.6182 * _DEV[i];
   _800DEVBelow[i] = _800EMA[i] - 1.6182 * _DEV[i];
   }
   //ChartRedraw(0);
   i--;   
   }
   
   string incTextLabel;
   string incTextLabel2;
   incTextLabel += TimeToString(currentTime) + " asian High: " + NormalizeDouble(asianHighValue,4) + " Low: " + NormalizeDouble(asianLowValue,4);
   incTextLabel2 += "LOD: " + NormalizeDouble(LOD,4) + " HOD: " + NormalizeDouble(HOD,4) + " avgC:" + NormalizeDouble(averageCandleSize,5);
   ObjectDelete(0,"incTextLabel ");
   ObjectCreate(_Symbol,"incTextLabel ",OBJ_LABEL,0,0,0);
   ObjectSetString(0,"incTextLabel ",OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,"incTextLabel ",OBJPROP_FONTSIZE,8);  
   ObjectSetInteger(0,"incTextLabel ",OBJPROP_COLOR,clrYellow);
   ObjectSetInteger(0,"incTextLabel ", OBJPROP_YDISTANCE,90);
   ObjectSetString(0,"incTextLabel ",OBJPROP_TEXT,incTextLabel); 
   
   ObjectDelete(0,"incTextLabel2");
   ObjectCreate(_Symbol,"incTextLabel2 ",OBJ_LABEL,0,0,0);
   ObjectSetString(0,"incTextLabel2 ",OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,"incTextLabel2 ",OBJPROP_FONTSIZE,8);  
   ObjectSetInteger(0,"incTextLabel2 ",OBJPROP_COLOR,clrYellow);
   ObjectSetInteger(0,"incTextLabel2 ", OBJPROP_YDISTANCE,120);
   ObjectSetString(0,"incTextLabel2 ",OBJPROP_TEXT,incTextLabel2); 
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

double stndDev(int c, const double &close[], double &array[]){
   int length = c + 800;
   double sum = 0;
   for(int i = c; i < length; i++){
      sum += MathPow(close[i] - array[i],2);
   }
   if(MathSqrt(sum/length) == 0) Alert("Dev is error 0");
   return MathSqrt(sum/length);
}