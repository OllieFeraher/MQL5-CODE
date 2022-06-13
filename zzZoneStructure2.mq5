//+------------------------------------------------------------------+
//|                                                 ZZLastXturns.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots 1

//--- plot ZigZag
#property indicator_label1  "ZigZag1"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrLightBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  5

#include <Arrays\List.mqh>
#include <zzS.mqh>

CList zzSList;

int ZZHandle;
int ATRHandle;

//Zigzag inputs
input int InpDepth = 20; //12;
input int InpDeviation = 20; //5;
input int InpBackstep = 3;

//Peak analysis inputs
input int InpGapPoints = 30; //Minimum gap between peaks in points
//if two gaps are within this they are NOT DISTINCT PEAKS
//AND ARE PART OF A LEVEL 
//IF LESS THAN THIS CONSIDER PART OF SAME LEVEL

input int InpSensitivity = 2; //Peak sensitivity
//MUST BE AT LEASTY 2 PEAKS AT SAME LEVEL TO FORM A LEVEL
//IGNORE JUST 1 PEAK

input int RecentSensitivity = 1;
input int RecentLookBack = 24; //look back at last 12 recent
//hold only last 6 however 

input int InpLookBack = 50; //peaks to perform lookback on
//LOOK AT THE MOST RECENT PEAKS BABY!
//NOT 50 LEVELS BUT 50 PEAKS AND SEE HOW MANY LEVELS THEY CREATE

input string InpPrefix = "SRLevel_"; //OBJECT NAME PREFIX
input string InpPrefixLineColour = clrYellow;
input int InpLineWidth = 2;

double SRLevels[]; //need two points;
double SRRecent[]; //last X levels not necceassrily double

double zzBuffer[];

double atrBuffer[];

double buySell[];
double buySL[];
double sellSL[];

double lastLow;
double lastHigh;
double currentSwing;

double _lastLow[];
double _lastHigh[];
double _currentSwing[];


struct zzLevel{
   double   zzLevel;
   int      extreme; //1 if high 2 if low
   int      vsLast; //1 if greater HH or LL, -1 if lesser LH or HL
   datetime zzDT;
   string   zzName;
   double   prevHigh;
   double   prevLow;
   double   nextHigh;
   double   nextLow;
};


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

   //Deviation sets the minimal price change necessary for the indicator to form a high/low on the chart. It measures in %, by default set as 5.
   //Depth sets the minimal interval on which the indicator will draw a new extreme if the Deviation setting is complied with. 
   //    It is measured in the number of candlesticks, the default setting is 12.
   //Backstep is the minimal number of candlesticks that must divide two local extremes. At this interval, new highs/lows will not be drawn if 
   //they differ from the previous ones for the size of Deviation. The default setting is 3.
   
   ZZHandle = iCustom(Symbol(),Period(), "Examples\\ZigZag", InpDepth, InpDeviation, InpBackstep);
   
   ATRHandle = iATR(Symbol(),Period(),200);
   if(ZZHandle == INVALID_HANDLE){  Print("ZZ INVALID"); Alert("ZZ INVALID");
      return(INIT_FAILED);
   }
   else Alert("ZZ_HANDLE VALID");
   
   ArraySetAsSeries(zzBuffer,true);
   ArraySetAsSeries(atrBuffer,true);
   
   SetIndexBuffer(0,zzBuffer,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0,PLOT_SHIFT,0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,0);
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,5);
      
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- set an empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   
   ArraySetAsSeries(buySell,true);
   ArraySetAsSeries(buySL,true);
   ArraySetAsSeries(sellSL,true);
   
   SetIndexBuffer(1,buySell,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,buySL,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,sellSL,INDICATOR_CALCULATIONS);
   
   ArraySetAsSeries(_lastLow,true);
   ArraySetAsSeries(_lastHigh,true);
   ArraySetAsSeries(_currentSwing,true);
   
   SetIndexBuffer(4,_lastLow,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,_lastHigh,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,_currentSwing,INDICATOR_CALCULATIONS);
   
//---
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason){

    Alert("Deinitialize zones");
    ObjectsDeleteAll(0,"recent_",0,OBJ_HLINE);
    
    IndicatorRelease(ZZHandle);
    ChartRedraw();
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
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   
   static double levelGap = InpGapPoints*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
   
   if(rates_total == prev_calculated) return (rates_total); //loop around
   
   double zz = 0;
   double zzPeaks[];
   int zzCount = 0;
   int levelAmount = 10;
   zzLevel zzTurns[];
   ArrayResize(zzTurns, levelAmount);
   
   int zzCopy = CopyBuffer(ZZHandle,0,0,rates_total,zzBuffer); //count holds number of values
   if(zzCopy < 0){ Alert("Error copying " + GetLastError()); return 0; }
   int atrCopy = CopyBuffer(ATRHandle,0,0,rates_total,atrBuffer);
   
   bool first = false; //dont take first as not formed;
   
   int bar = rates_total - prev_calculated;
   
   buySell[0]  = 0;
   buySL[0]    = 0;
   sellSL[0]   = 0;
   //if(prev_calculated > 10) Alert("Buysell 0: " + buySell[0]);
   
   //for every new bar we begin a lookback and fill our zzPeaks with it.
   for(int i = 0; i < rates_total && zzCount < 10; i++){ //we are moving backwards
      zz = zzBuffer[i]; //save as zz if not zero it is a turn
      
      if(zz!=0 && zz!= EMPTY_VALUE){ //if zz not zero it is a local max / min
         if(first){ first = false; continue;}
         //zzPeaks[zzCount] = zz;
         zzTurns[zzCount].zzLevel = zz;
         zzTurns[zzCount].zzDT = time[i];
         zzTurns[zzCount].zzName = "zz_" + zzCount;
         if(i >=1){
         zzTurns[zzCount].prevHigh = high[i+1];
         zzTurns[zzCount].prevLow =  low[i+1];
         int lowTest = 0;
         int highTest = 0;
         zz < low[i+1] ? lowTest = 1 : lowTest = -1;
         zz > high[i+1] ? highTest = -1 : highTest = 1;
         
         if(lowTest == highTest) zzTurns[zzCount].extreme = lowTest;
         
         if(zzTurns[0].zzLevel > zzTurns[1].zzLevel) zzTurns[0].extreme = -1;
         if(zzTurns[0].zzLevel < zzTurns[1].zzLevel) zzTurns[0].extreme = 1;
         }
         
         if(zzCount >= 1){ //we do not want NEW zones forming with each move as each extrension of current trend will cause the old deleted!
            /*
            zzTurns[zzCount].nextHigh = high[i-1];
            zzTurns[zzCount].nextLow = low[i-1]; 
            if(zzTurns[zzCount].zzLevel < zzTurns[zzCount].nextLow) zzTurns[zzCount].extreme = 1;
            if(zzTurns[zzCount].zzLevel > zzTurns[zzCount].nextHigh) zzTurns[zzCount].extreme = -1;
            */
            zzS *newZZ = new zzS(zz, time[i], "zz_" + zzCount);
            if(zzSList.Total() == 9){
               zzS *currentLast = zzSList.GetLastNode();
               if(newZZ.zzDT > currentLast.zzDT){
                  zzSList.Delete(0);
                  zzSList.Add(newZZ);
               }
            }
            else{
               zzSList.Add(newZZ);
            }
         }
         
         /*
         if(zzCount == 1){
            zzTurns[1].zzLevel > zzTurns[0].zzLevel ? zzTurns[1].extreme = -1 : zzTurns[1].extreme = 1;
            zzTurns[1].zzLevel > zzTurns[0].zzLevel ? zzTurns[0].extreme = 1 : zzTurns[0].extreme = -1;
         }
         if(zzCount >= 2){
            zzTurns[zzCount].extreme = -1 * zzTurns[zzCount-1].extreme;
         }
         */
         
         zzCount++;
      }
   }
   
   for(int i = 0; i <= 8; i++){
      if(zzTurns[i].zzLevel > zzTurns[i + 1].zzLevel) zzTurns[i].extreme = -1;
      if(zzTurns[i].zzLevel < zzTurns[i + 1].zzLevel) zzTurns[i].extreme = 1;
   }
    
   if(zzSList.Total() == 9){  //SIZE IS ZERO TO EIGHT THE LAST EIGHT IS OUR 1
   
      for(int i = 1; i <= zzSList.Total(); i++){
      int zoneNumber = 9 - i;
      zzS *zzTemp = zzSList.GetNodeAtIndex(zoneNumber);
      if(zzTemp.extreme == 0) zzTemp.extreme = zzTurns[i].extreme;
      
      }
   }
   //CHECK ZONES INTACT
   
   for(int i = zzSList.Total() - 1; i >= 0; i--){
      zzS *zzCheck = zzSList.GetNodeAtIndex(i);
      if(!zzCheck.broken){
         //Alert("Test for break in " + i  + " ext: " + zzCheck.extreme + " zzLevel " + zzCheck.zzLevel + " open: " +  open[0]);
         if(zzCheck.extreme == 1 && open[0] < zzCheck.zzLevel){    zzCheck.broken = true; } //Alert(i + " " + "broken low");
         else if(zzCheck.extreme == -1 && open[0] > zzCheck.zzLevel){ zzCheck.broken = true;} //Alert(i + " " + "broken high "); 
         //else //Alert(i + " unbroken");
      }
   }
   
   
//--------------END OF GETTING ZONES
   
   
   for(int i = 0; i < zzTurns.Size(); i++){
      
      if(i >= 1){
      if(zzTurns[i].zzLevel >= zzTurns[i].prevHigh && zzTurns[i].zzLevel >= zzTurns[i].nextHigh) zzTurns[i].extreme = -1;
      else if(zzTurns[i].zzLevel <= zzTurns[i].prevLow && zzTurns[i].zzLevel <= zzTurns[i].nextLow) zzTurns[i].extreme = 1;
      else zzTurns[i].extreme = 0;
      }
      if(i == 0){
         if(zzTurns[0].zzLevel < zzTurns[1].zzLevel) zzTurns[0].extreme = 1;
         else if (zzTurns[0].zzLevel > zzTurns[1].zzLevel) zzTurns[0].extreme = 1;
         else zzTurns[0].extreme = 0;
      }
      
      color colour = clrWhite;
      ObjectDelete(0,zzTurns[i].zzName);
      ObjectCreate(0,zzTurns[i].zzName,OBJ_TREND,0,zzTurns[i].zzDT,zzTurns[i].zzLevel,time[0],zzTurns[i].zzLevel);
      ObjectSetInteger(0,zzTurns[i].zzName,OBJPROP_COLOR,colour);
      ObjectSetInteger(0,zzTurns[i].zzName,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,zzTurns[i].zzName,OBJPROP_SELECTABLE,true);
      double space = 0;
      string zzString = "";
      string intact = "";
      int checkExt = 0;
      double zzPrice = 0;
      
      if(zzSList.Total() == 9 && i >=1){
         zzS *zz = zzSList.GetNodeAtIndex(zzSList.Total()- i);
         zz.broken ? intact = "(BOS)" : intact = "(I)";
         checkExt = zz.extreme;
         zzPrice = NormalizeDouble(zz.zzLevel,6);
      }
      
      if(zzTurns[i].extreme == 0 && i < 9){
         bool greaterThan = (zzTurns[i].zzLevel > zzTurns[i+1].zzLevel);
         if(greaterThan) zzTurns[i].extreme = -1;
         else if(!greaterThan) zzTurns[i].extreme = 1;
         else zzString = "Undet";
      } 
      string type = "";
      //zzTurns[i].extreme == 1 ? type = "LOW" : type = "HIGH";
      
      //zzString = intact + "ext: " + zzTurns[i].extreme + " " + type + " ";
      
      
      if(zzTurns[i].extreme == -1){ 
         space = 0.5 * atrBuffer[0]; 
         
         for(int k = i + 1; k <= 9; k++){
            if(zzTurns[k].extreme == -1){ 
               if(zzTurns[i].zzLevel > zzTurns[k].zzLevel){ zzString += "Higher High"; zzTurns[i].vsLast = 1; k = 10; break;}
               else{ zzString += "Lower High"; zzTurns[i].vsLast = -1; k = 10; break;}
            }
         }
         if(i >= 8) zzString += "High";
         /*
         if(i < 8){
            if(zzTurns[i].zzLevel > zzTurns[i+2].zzLevel){ zzString = "Higher High"; zzTurns[i].vsLast = 1; }
            else{ zzString = "Lower High"; zzTurns[i].vsLast = 1; }
         }
         if(i >= 8) zzString = "High"; 
         */
      }
      else if(zzTurns[i].extreme == 1){ 
         space = 0;  
         
         for(int k = i + 1; k <= 9; k++){
            
            if(zzTurns[k].extreme == 1){ 
               if(zzTurns[i].zzLevel < zzTurns[k].zzLevel){ zzString += "Lower Low: "; zzTurns[i].vsLast = 1; k = 10; break; }
               else{ zzString += "Higher Low"; zzTurns[i].vsLast = -1; k = 10; break;}
            }
            
         }
         if(i >= 8) zzString += "Low";
      }
      zzString +=  " " + intact + " ext: " + zzTurns[i].extreme; //" " + NormalizeDouble(zzTurns[i].zzLevel,Digits()) +
      
      if(i == 0){
         zzString = "Forming";
         zzTurns[0].zzLevel > zzTurns[2].zzLevel ? zzString += " Higher " : zzString += " Lower ";
         zzTurns[0].zzLevel > zzTurns[1].zzLevel ? zzString += " High " : zzString += " Low ";
         //zzString += NormalizeDouble(zzTurns[0].zzLevel,Digits());
      }
      /*
      if(i < 9){ 
         bool greaterThan = (zzTurns[i].zzLevel > zzTurns[i+1].zzLevel);
         zzString += "zz[i]: " + NormalizeDouble(zzTurns[i].zzLevel,5) + " > zz[i+1]: " + NormalizeDouble(zzTurns[i+1].zzLevel,5) + " ? " + (greaterThan);
      }*/
      string zzText = zzTurns[i].zzName + "_text";
      ObjectDelete(0,zzText);
      ObjectCreate(0,zzText,OBJ_TEXT,0,zzTurns[i].zzDT,zzTurns[i].zzLevel + space);
      ObjectSetString(0,zzText,OBJPROP_TEXT,zzString);
      ObjectSetInteger(0,zzText,OBJPROP_FONTSIZE,10);
      ObjectSetInteger(0,zzText,OBJPROP_COLOR,clrWhite);
      ObjectSetString(0,zzText,OBJPROP_FONT,FONT_ITALIC);
   }
   
   //get last High and last Low
   
   lastHigh = 0;
   lastLow  = 0;
   
   
   for(int i = 1; i <= 9; i++){
      if(lastHigh == 0 && zzTurns[i].extreme == -1)       lastHigh = zzTurns[i].zzLevel;
      else if(lastLow == 0 && zzTurns[i].extreme == 1)  lastLow  = zzTurns[i].zzLevel;
      if(lastHigh == 0 && lastLow == 0) break;
   }
   
   _lastHigh[0] = lastHigh;
   _lastLow[0]  = lastLow;
   _currentSwing[0] = zzTurns[0].zzLevel;
   
   sellSL[0] = 0;
   buySL[0] = 0;
   //buy if higher high and price above last low;
   if(zzTurns[1].extreme == 1 && zzTurns[1].vsLast == 1){ //lower low
      if(zzTurns[2].extreme == -1 && zzTurns[2].vsLast == -1){   //lower high
         if(zzTurns[0].zzLevel < zzTurns[2].zzLevel){
            //Alert("1: Lower low, 2: lower high, 0 < 2 lower high, sells");
            buySell[0] = -1;
            sellSL[0] = zzTurns[2].zzLevel;
         }
      }
   }
   
   if(zzTurns[1].extreme == -1 && zzTurns[1].vsLast == 1){ //higher high
      if(zzTurns[2].extreme == 1 && zzTurns[2].vsLast == -1){   //higher low
         if(zzTurns[0].zzLevel > zzTurns[2].zzLevel){
            //Alert("1: higher high, 2: higher low, 0 > 2 higher low, buys");
            buySell[0] = 1;
            buySL[0] = zzTurns[2].zzLevel;
         }
      }
   }
   
   //if(buySell[0] == -1) Alert("CI [1] lower low, and [2] lower high: and [0] < [2] sells");
   //if(buySell[0] == 1)  Alert("CI [1] higher high, and [2] higher low: and [0] > [2] buys");
   /*
   //sell if lower low and price below last high
   if(zzTurns[0].extreme == -1 && zzTurns[0].vsLast == 1){ //currently in lower low move
      Alert("Higher High baby");
      if(open[0] < zzTurns[1].zzLevel){  //lower low and below last lower high
         Alert("SELL");
         string zzText = zzTurns[0].zzName + "_text";
         ObjectSetInteger(0,zzText,OBJPROP_COLOR,clrPink);
      }
   }
   */
   //Alert("1 h: " + zzTurns[1].prevHigh + " 1 l: " + zzTurns[1].prevLow);
   /*
   if(zzSList.Total() >= 9){
      int zzListSize = zzSList.Total();
      
      Alert("turns level 1: " + zzTurns[1].zzLevel + " at: " + zzTurns[1].zzDT + " extreme: " + zzTurns[1].extreme);
       
      zzS *zzLast = zzSList.GetNodeAtIndex(8);  //zzListSize - 1
      Alert("Last zzS: " + zzLast.zzLevel + " at: " + zzLast.zzDT + " extreme: " + zzLast.extreme);
      
      Alert("turns level 2: " + zzTurns[2].zzLevel + " at: " + zzTurns[2].zzDT + " extreme: " + zzTurns[2].extreme);
      zzS *zzLevel2 = zzSList.GetNodeAtIndex(7);
      Alert("zzS level 2: " + zzLevel2.zzLevel + " at: " + zzLevel2.zzDT + "extreme: " + zzLevel2.extreme);
      
      Alert("turns level 9: " + zzTurns[9].zzLevel + " at: " + zzTurns[9].zzDT + " extreme: " + zzTurns[9].extreme);
      zzS *zzLevel9 = zzSList.GetNodeAtIndex(0);
      Alert("zzS level 9: " + zzLevel9.zzLevel + " at: " + zzLevel9.zzDT + "extreme: " + zzLevel9.extreme);
   }
   */

   
   /*
   
         
   
   int zzListSize = zzSList.Total() - 1;
   zzS *zLast = zzSList.GetNodeAtIndex(zzListSize);
   Alert("class level "  + zzListSize + ": " + zLast.zzLevel);
   */
   
//--- return value of prev_calculated for next call
   return(rates_total);
  
//+------------------------------------------------------------------+
}
void sortZZ(zzLevel& turns[]){
   int size = ArraySize(turns);
   for(int i = 0; i < size; i++){
      for(int k = i + 1; k < size; k++){
         if(turns[k].zzLevel > turns[i].zzLevel){
            //swap i and K;
            zzLevel hold;
            hold.zzDT = turns[i].zzDT;
            hold.zzLevel = turns[i].zzLevel;
            turns[i].zzDT = turns[k].zzDT;
            turns[i].zzLevel = turns[k].zzLevel;
            turns[k].zzDT = hold.zzDT;
            turns[k].zzLevel = hold.zzLevel; 
         }
      }
   }
}