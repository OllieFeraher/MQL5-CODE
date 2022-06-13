//+------------------------------------------------------------------+
//|                                                      ASFX_A2.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <OrderSim.mqh>
#include <Arrays\List.mqh>
#include <Trade/Trade.mqh>
#include <VirtualPosition2.mqh>;

CTrade   Trade;
CList    virtualSFPositionList;
int vpSFNum = 0;

int emaHandle;
int asfxTDIHandle;
int atrHandle;
int adrHandle;

double ema8[];
double ema21[];
double ema50[];
double ema200[];
double ema800[];
double _ADR[];

double _ATR[];
double _RSI[];
double _RSIavg2[];
double _RSIavg7[];
double _RSIavg34[];
double _RSIbbUpper[];
double _RSIbbLower[];

string _recordSFString[];

int bars; //amount of bars;
bool isNewBar;
datetime oldTime;
datetime NewTime[];

MqlRates mrate[];   

bool lastRed, lastGreen;

bool cross_21Up = false, cross_21Down = false;

double TP;

bool buy,sell,inBuy,inSell;

bool liquid50Falling, liquid50Rising;

bool fullTrend;

int a = 1;
int b = 2;

int structureHandle;
double _structure[];
double _buySL[];
double _sellSL[];

double _lastLow[];
double _lastHigh[];
double _currentSwing[];

double _lastMainHigh[];
double _lastMainLow[];

double stopPercent;
double percentOfCurrentSwing;
double percentOfMainSwing;

double stopLoss;
double takeProfit;
double entry;

string confluence;

bool   trend;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   createFileSF();
   
   buy = false; sell = false; inBuy = false; inSell = false;
   emaHandle = iCustom(_Symbol,PERIOD_CURRENT,"ASFX_EMA_Dev");
   asfxTDIHandle = iCustom(_Symbol,PERIOD_CURRENT,"ASFX_TDI");
   //adrHandle = iATR(_Symbol,PERIOD_D1,20);
   //atrHandle = iATR(_Symbol,PERIOD_CURRENT,200);
   
   structureHandle = iCustom(_Symbol,PERIOD_CURRENT,"zzZoneStructure2");
//---
   return(INIT_SUCCEEDED); 
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   bars = Bars(_Symbol,_Period); 
   MqlTick latestPrice; 
   ArraySetAsSeries(mrate,true);
   MqlDateTime mqlCurrentTime;
   datetime currentTime = TimeCurrent();
   TimeToStruct(currentTime,mqlCurrentTime);
   
   if(!SymbolInfoTick(_Symbol,latestPrice)){Alert("Error getting latest price quoute", GetLastError()); return;}
   if(CopyRates(_Symbol,_Period,0,bars,mrate) < 0){
      Alert("Error getting rates" + GetLastError()); return;}
      
   ArraySetAsSeries(ema8,true);
   ArraySetAsSeries(ema21,true);
   ArraySetAsSeries(ema50,true);
   ArraySetAsSeries(ema200,true);
   ArraySetAsSeries(ema800,true);
   //ArraySetAsSeries(_ADR,true);
   ArraySetAsSeries(_ATR,true);
   
   ArraySetAsSeries(_RSI,true);
   ArraySetAsSeries(_RSIavg2,true);
   ArraySetAsSeries(_RSIavg7,true);
   ArraySetAsSeries(_RSIavg34,true);
   ArraySetAsSeries(_RSIbbLower,true);
   ArraySetAsSeries(_RSIbbUpper,true);
   
   ArraySetAsSeries(_structure,true);
   ArraySetAsSeries(_buySL,true);
   ArraySetAsSeries(_sellSL,true);
   
   ArraySetAsSeries(_lastLow,true);
   ArraySetAsSeries(_lastHigh,true);
   ArraySetAsSeries(_currentSwing,true);
   
   isNewBar = false;
   int copied = CopyTime(_Symbol,_Period,0,1,NewTime);
   if(copied >0){
      if(oldTime != NewTime[0]){
         isNewBar = true; 
         oldTime = NewTime[0];
      }
   }
   else{ Alert("Error copying data: " + GetLastError()); ResetLastError(); return;}
   if(isNewBar == false){ return; }
   
   CopyBuffer(emaHandle,0,0,bars,ema8);
   CopyBuffer(emaHandle,1,0,bars,ema21);
   CopyBuffer(emaHandle,2,0,bars,ema50);
   CopyBuffer(emaHandle,3,0,bars,ema200);
   CopyBuffer(emaHandle,4,0,bars,ema800);
   //CopyBuffer(emaHandle,5,0,bars,_ADR);
   //CopyBuffer(atrHandle,0,0,bars,_ATR);
   
   CopyBuffer(asfxTDIHandle,0,0,bars,_RSI);
   CopyBuffer(asfxTDIHandle,1,0,bars,_RSIavg2);
   CopyBuffer(asfxTDIHandle,2,0,bars,_RSIavg7);
   
   CopyBuffer(asfxTDIHandle,3,0,bars,_RSIbbUpper);
   CopyBuffer(asfxTDIHandle,4,0,bars,_RSIbbLower);
   CopyBuffer(asfxTDIHandle,5,0,bars,_RSIavg34);
   
   //Structure handles
   CopyBuffer(structureHandle,1,0,bars,_structure);
   CopyBuffer(structureHandle,2,0,bars,_buySL);
   CopyBuffer(structureHandle,3,0,bars,_sellSL);
   
   CopyBuffer(structureHandle,4,0,bars,_lastLow);
   CopyBuffer(structureHandle,5,0,bars,_lastHigh);
   CopyBuffer(structureHandle,6,0,bars,_currentSwing);
   
   
   double candleMid = (mrate[1].high + mrate[1].low)/2;
   bool baseTP = false; // base stoplosses on a single tp if true, if false base tps on a single stoploss
   
   double timeGap = 60*60;
   inBuy = false;
   inSell = false;
   
   int sfListSize = virtualSFPositionList.Total();
   if(sfListSize != 0){
      //Alert("Check vps:");
      VirtualPosition2 *vp;
      for(int i = 0; i < sfListSize; i++){
         vp = virtualSFPositionList.GetNodeAtIndex(i);
          if(vp.CheckPrice(mrate[1].high,mrate[1].low) == true){
            _recordSFString[vp.tradeNumber] += vp.returnResults();
            Alert("Trade checked " + vp.returnResults());
            Alert(_recordSFString[vp.tradeNumber]);
            writeToFileSF(_recordSFString[vp.tradeNumber], "SF");
            if(vp.direction == "Long"){ inBuy = false; Alert("CLOSE BUY");}
            else if(vp.direction == "Short"){ inSell = true; Alert("CLOSE SELL");}
            virtualSFPositionList.Delete(i);
            
            sfListSize = virtualSFPositionList.Total();
          }
      }
   }
   trend = false;
   fullTrend = false;
   confluence = "";
   
   if(_RSI[a] > _RSIbbLower[a] && _RSI[b] < _RSIbbLower[b] && _structure[0] == 1){ // && !inBuy){
         Alert("SharkFin Buy");
         Alert("Last low: " + _lastLow[0] + " high: " + _lastHigh[0] + " current: " + _currentSwing[0]);
         
         mrate[0].close > ema800[0] ? trend = true : trend = false;
         if(trend && mrate[0].close > ema200[0]) fullTrend = true;
         
         entry = latestPrice.ask;
         double swingLength = _lastHigh[0] - _currentSwing[0];
         stopLoss = _lastHigh[0] - 1.172 * swingLength;
         
         if(ema200[0] < entry && ema200[0] > stopLoss) confluence += "+200";
         if(ema800[0] < entry && ema800[0] > stopLoss) confluence += "+800";
         if(confluence == "") confluence = "NA";
         
         double mainSwingLength = _lastHigh[0] - _lastLow[0];
         percentOfCurrentSwing = (_lastHigh[0] - latestPrice.ask)/mainSwingLength; //want > 50% higher is greater pullback
         
         stopPercent = (_lastHigh[0] - stopLoss)/mainSwingLength;
         
         Alert("Percent of swing: " + percentOfCurrentSwing);
         double entryToStop = latestPrice.ask - stopLoss;
         takeProfit = entry + 2*entryToStop;
         
         VirtualPosition2 *vp = new VirtualPosition2(vpSFNum,latestPrice.ask,stopLoss,takeProfit,"SF",false,6,false,3,0);
         virtualSFPositionList.Add(vp);
         vp.drawLevels();
         recordTrade(vpSFNum,vp);
         vpSFNum++;
         
   }
   
   if(_RSI[a] < _RSIbbUpper[a] && _RSI[b] > _RSIbbUpper[b] && _structure[0] == -1){ // && !inSell){
         Alert("SharkFin Sell");
         Alert("Last low: " + _lastLow[0] + " high: " + _lastHigh[0] + " current: " + _currentSwing[0]);
         
         entry = latestPrice.bid;
         double swingLength = _currentSwing[0] - _lastLow[0];
         stopLoss = _lastLow[0] + 1.172 * swingLength;
         
         
         if(ema200[0] > entry && ema200[0] < stopLoss) confluence += "+200";
         if(ema800[0] > entry && ema800[0] < stopLoss) confluence += "+800";
         if(confluence == "") confluence = "NA";
         
         mrate[0].close < ema800[0] ? trend = true : trend = false;
         if(trend && mrate[0].close < ema200[0]) fullTrend = true;
         
         double mainSwingLength = _lastHigh[0] - _lastLow[0];
         
         percentOfCurrentSwing = (latestPrice.bid - _lastLow[0])/mainSwingLength;
         
         Alert("Current percent of swing: " + percentOfCurrentSwing);
         
         stopPercent = (stopLoss - _lastLow[0])/mainSwingLength;
         
         double entryToStop = stopLoss - latestPrice.bid;
         takeProfit = entry - 2*entryToStop;
         
         VirtualPosition2 *vp = new VirtualPosition2(vpSFNum,latestPrice.bid,stopLoss,takeProfit,"SF",false,6,false,3,0);
         virtualSFPositionList.Add(vp);
         vp.drawLevels();
         recordTrade(vpSFNum,vp);
         vpSFNum++;
   }
}
//+------------------------------------------------------------------+

void recordTrade(int vpNum, VirtualPosition2 &vp){
   if(vpNum > ArraySize(_recordSFString) - 1) ArrayResize(_recordSFString, vpNum + 20);
   
   MqlDateTime mqlCurrentDT;
   TimeToStruct(vp.entryDT,mqlCurrentDT);
   
   string month, day, hour, min;
   if(mqlCurrentDT.mon < 10) month = "0" + mqlCurrentDT.mon;
   else month = mqlCurrentDT.mon;
   if(mqlCurrentDT.day < 10) day = "0" + mqlCurrentDT.day;
   else day = mqlCurrentDT.day;
   if(mqlCurrentDT.hour < 10) hour = "0" + mqlCurrentDT.hour;
   else hour = mqlCurrentDT.hour;
   if(mqlCurrentDT.min < 10) min = "0" + mqlCurrentDT.min;
   else min = mqlCurrentDT.min;
   
   string time = hour + ":" + min;
   string date = mqlCurrentDT.year + "." + month + "." + day; 
   string dayOfWeek = dayOfWeek(mqlCurrentDT.day_of_week);
   
   string record = date + ", " + dayOfWeek + ", " + time + ", ";
   record += vpNum + ", " + vp.tradeType + ", " + vp.direction + "," + entry + ", " + stopLoss + ", " + takeProfit + ", " + NormalizeDouble(_RSI[a],2) + ", " + NormalizeDouble(_RSIavg34[a],2) + ", " 
                           + NormalizeDouble(_RSIavg2[a],2) + ", " + NormalizeDouble(_RSIavg7[a],2) + ", " + trend + ", " +  fullTrend + ", " 
                            + NormalizeDouble(percentOfCurrentSwing,3) + ", " + NormalizeDouble(stopPercent,3) + ", " 
                            + confluence + ", " + mrate[a].tick_volume;
   record += ", " + NormalizeDouble(ema8[a],_Digits) + ", " + NormalizeDouble(ema21[a],_Digits) + ", " + NormalizeDouble(ema50[a],_Digits) + ", " 
                           + NormalizeDouble(ema200[a],_Digits) + ", " + NormalizeDouble(ema800[a],_Digits)  + ", ";
                           
   if(vp.tradeType == "SF") _recordSFString[vpNum] += record;
                           
}
void createFileSF(){
   string fileName2 = "SF_" + Symbol() + "_" + Period() + ".csv";
   int c2 = FileOpen(fileName2,FILE_WRITE|FILE_ANSI|FILE_TXT);
   if(c2 == INVALID_HANDLE){Alert("Error opening / creating: " + fileName2);}
   string firstLine2 = "Date, Day, Time, Num, Type, Dir, Entry, SL, TP, Rsi, Liq50, RsiFast, RsiSlow, Trend, Full Trend, percentageCurrent, stopPercent, confluence, Volume, ema8, ema21, ema50, ema200, ema800, 100%, 78.6%, 61.8%, 50.0%, 38.2%, 23.6%"; 
   FileWrite(c2,firstLine2);
   FileClose(c2);
}
void writeToFileSF(string line, string type){
   string fileName;
   if(type == "SF") fileName = "SF_" + Symbol() + "_" + Period() + ".csv";
   int c = FileOpen(fileName,FILE_READ|FILE_WRITE|FILE_ANSI|FILE_TXT);
   if(c == INVALID_HANDLE){Alert("Error opening / creating: " + fileName);}
   FileSeek(c,0,SEEK_END); // move pointer to end of file. 
   FileWrite(c,line);
   FileClose(c);
}


/*
double stopLoss(double entry, int dir){
   double potentialSL[7] = 
      {ema50[0],ema200[0],ema800[0],recentStructure[0],recentStructure[1],recentStructure[2],recentStructure[3]};
      
   double min = _ATR[0]*1.5; 
   double max = _ATR[0]*4;
   
   dir == 1 ? min = entry - _ATR[0]*2 : min = entry + _ATR[0]*2;
   dir == 2 ? max = entry - _ATR[0]*4 : max - entry - _ATR[0]*4;
   
   double pSL = min;
   for(int i = 0; i < 7; i++){
      if(potentialSL[i] > min && potentialSL[i] < max && potentialSL[i] > pSL){
         pSL = potentialSL[i];
      }
   }
   
   return pSL;
}
*/