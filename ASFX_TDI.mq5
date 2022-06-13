//+------------------------------------------------------------------+
//|                                                    CustomOsc.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots 6
#property indicator_level1 20
#property indicator_level2 32
#property indicator_level3 50
#property indicator_level4 68
#property indicator_level5 80

#property indicator_levelcolor clrWhite
#property indicator_levelstyle STYLE_SOLID
#property indicator_levelwidth 1

#property indicator_color1 clrWhite
#property indicator_type1 DRAW_LINE
#property indicator_width1 3
#property indicator_style1 STYLE_SOLID
#property indicator_label1 "RSI PRICE LINE"

#property indicator_color2 clrLightPink
#property indicator_type2 DRAW_LINE
#property indicator_width2 3
#property indicator_style2 STYLE_SOLID
#property indicator_label2 "MA 2 RSI FAST"

#property indicator_color3 clrLightGreen
#property indicator_type3 DRAW_LINE
#property indicator_width3 3
#property indicator_style3 STYLE_SOLID
#property indicator_label3 "MA 7 RSI SLOW"

#property indicator_color4 clrAqua
#property indicator_type4 DRAW_LINE
#property indicator_width4 3
#property indicator_style4 STYLE_SOLID
#property indicator_label4 "BB UPPER"

#property indicator_color5 clrAqua
#property indicator_type5 DRAW_LINE
#property indicator_width5 3
#property indicator_style5 STYLE_SOLID
#property indicator_label5 "BB LOWER"

#property indicator_color6 clrOrange
#property indicator_type6 DRAW_LINE
#property indicator_width6 3
#property indicator_style6 STYLE_SOLID
#property indicator_label6 "BB MID"

int RSI_Period = 21;
input ENUM_APPLIED_PRICE RSI_PRICE = PRICE_CLOSE;
int Volatility_Band = 34; //20 - 40
double StdDev = 1.6185; //SD 1-3
int RSI_FastLine = 2;
int RSI_SlowLine = 7;
input ENUM_MA_METHOD RSI_Price_Type = MODE_SMA;
input  ENUM_TIMEFRAMES TDIPeriod;
double RSI_Buffer[];
double RSI_MAFast[];
double RSI_MASlow[];
double RSI_BBUpper[];
double RSI_BBLower[];
double RSI_BBMid[];

//int lastOB,lastOS;

//int _lastOB[];
//int _lastOS[];

int RSI_handle;
int MaxPeriod = 0;

int timeFrame;

bool adapt = false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, RSI_Buffer, INDICATOR_DATA);
   SetIndexBuffer(1, RSI_MAFast, INDICATOR_DATA);
   SetIndexBuffer(2, RSI_MASlow, INDICATOR_DATA);
   SetIndexBuffer(3, RSI_BBUpper, INDICATOR_DATA);
   SetIndexBuffer(4, RSI_BBLower, INDICATOR_DATA);
   SetIndexBuffer(5, RSI_BBMid, INDICATOR_DATA);
   
   ArraySetAsSeries(RSI_Buffer,true);
   ArraySetAsSeries(RSI_MAFast,true);
   ArraySetAsSeries(RSI_MASlow,true);
   ArraySetAsSeries(RSI_BBUpper,true);
   ArraySetAsSeries(RSI_BBLower,true);
   ArraySetAsSeries(RSI_BBMid,true);
   
   timeFrame = Period();
   Print("TimeFrame: " + timeFrame);
   
   //adapt set to false
   if(adapt && timeFrame == 1){
   RSI_Period = 13 * 5;
   Volatility_Band = 34 * 5;
   }
   
   
   
   RSI_handle = iRSI(Symbol(),TDIPeriod,RSI_Period,RSI_PRICE);
   
   IndicatorSetInteger(INDICATOR_DIGITS, Digits());
   
   MaxPeriod = Volatility_Band + RSI_Period; 
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0);
   
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MaxPeriod + RSI_FastLine);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MaxPeriod + RSI_SlowLine);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, MaxPeriod);
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, MaxPeriod);
   PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, MaxPeriod);
   PlotIndexSetInteger(5, PLOT_DRAW_BEGIN, MaxPeriod);
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
   double MA, RSI[];
   
  
   ArrayResize(RSI,Volatility_Band);
   
   int i;
   int counted_bars = prev_calculated;
   
   if(rates_total < MaxPeriod) return 0; //not enough bars
   
   i = rates_total - counted_bars; //remaining bars to calculate
   if(i > rates_total - MaxPeriod - 1) i = rates_total - MaxPeriod - 1; //recalc back from maxperiod on each new bar! -1 as position always -1 as arrays start at zero
   
   int RSI_bars = CopyBuffer(RSI_handle,0,0,rates_total,RSI_Buffer); //copy all RSI rates from rsi indicator to RSI BUFFER
   if(RSI_bars == -1) return 0; //error has occured
   
   while(i >= 0){
      //lastOB++; lastOS++;
      MA = 0;
      for(int x = i; x < i + Volatility_Band; x++){
         RSI[x - i] = RSI_Buffer[x]; //if i is 10 x is 10 then RSI[10-10] IS ZERO RSI[11 - 10] = RSI[1] and so on so forth
         MA += RSI_Buffer[x] / Volatility_Band;
      }
      double SD = StdDev * stdDev(RSI,Volatility_Band);
      RSI_BBUpper[i] = MA + SD;
      RSI_BBLower[i] = MA - SD;
      RSI_BBMid[i] = (RSI_BBUpper[i] + RSI_BBLower[i])/2;
      i--;
      //if(RSI_Buffer[i] > 70) lastOB = i;
      //if(RSI_Buffer[i] < 30) lastOS = i;
      
      //_lastOS[i] = lastOS;
      //_lastOB[i] = lastOB;
   }
   
   //reset i to recalc again our smoothed RSIs
   i = rates_total - counted_bars;
   if (i > rates_total - MaxPeriod - 1) i = rates_total - MaxPeriod - 1;
   while(i >= 0){
      RSI_MAFast[i] = maOnArray(RSI_Buffer,0,RSI_FastLine,0,i);
      //shifts by i so we start at i and work RSI_PRICE_LINE PERIODS BACK!
      RSI_MASlow[i] = maOnArray(RSI_Buffer,0,RSI_SlowLine,0,i);
      i--;
   }
   
   
   
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

double maOnArray(double &Array[], int total, int maPeriod, int maShift, int shift){
   double sum = 0; //shift can move us back by one
   for(int i = shift; i < shift + maPeriod; i++){ 
      sum += Array[i]/maPeriod;
   }
   return sum;
}

double variance(double& data[], int n){
   double sum = 0, ssum = 0;
   for(int i = 0; i < n; i++){
      sum += data[i];
      ssum+= MathPow(data[i],2);
   }
   return ((ssum*n - sum*sum)/(n*(n-1)));
}

double stdDev(double& data[], int n){
   return(MathSqrt(variance(data,n)));
}

