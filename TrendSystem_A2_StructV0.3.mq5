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

//CTrade   Trade;
CList    virtualA2PositionList;
CList    virtualSFPositionList;

int vpA2Num = 0;
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
double _CTF[];
double _DEV[];
double _ADR[];

double _ATR[];
double _RSI[];
double _RSIavg2[];
double _RSIavg7[];
double _RSIavg34[];
double _RSIbbUpper[];
double _RSIbbLower[];

string _recordA2String[];
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

int structureHandle;
input int InpDepth = 12;
input int InpDeviation = 5;
input int InpBackstep = 3;
input int InpGapPoints = 30;
input int InpSensitivity = 2; 
input int RecentSensitivity = 1;
input int RecentLookBack = 24;
input int InpLookBack = 50;
input string InpPrefix = "SRLevel_"; //OBJECT NAME PREFIX
input string InpPrefixLineColour = clrWhite;
input int InpLineWidth = 2;

double recentStructure[4];
double _zzBuffer[];

struct zzLevel{
   double zzLevel;
   datetime zzDT;
};

zzLevel zzTurns[];

int a = 1;
int b = 2;

datetime lastA2datetime;

double currentDev;
double openBuys;
double openSells;

bool ema800AboveCTF;
bool priceAboveCTF;
   
string confluence;

bool allowBuys;
bool allowSells;

double accountBalance;
double accountEquity;
double EB;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   createFileA2();
   
   buy = false; sell = false; inBuy = false; inSell = false;
   
   emaHandle = iCustom(_Symbol,PERIOD_CURRENT,"ASFX_EMA_Dev");
   asfxTDIHandle = iCustom(_Symbol,PERIOD_CURRENT,"ASFX_TDI");
   adrHandle = iATR(_Symbol,PERIOD_D1,20);
   atrHandle = iATR(_Symbol,PERIOD_CURRENT,200);
   structureHandle = iCustom(_Symbol,PERIOD_CURRENT,"ZZLastXturns", InpDepth, InpDeviation, InpBackstep);
   
   ArraySetAsSeries(_zzBuffer,true);
   
   SetIndexBuffer(0,_zzBuffer,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0,PLOT_SHIFT,0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,0);
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,1);
      
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- set an empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

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

   
   
   
   //IF EQUITY IS X PERCENT OVER BALANCE WE TAKE THE MONEY BABY!
   
   accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   EB = accountEquity/accountBalance;
   //Alert("Account Balance: " + accountBalance + " Equity: " + accountEquity + " EQ/BAL " + accountEquity/accountBalance);
   if(accountEquity/accountBalance >= 1.02) Alert("2% UP: " + accountEquity/accountBalance);
   if(accountEquity/accountBalance >= 1.03) Alert("3% UP: " + accountEquity/accountBalance);
   if(accountEquity/accountBalance >= 1.035) Alert("3.5% UP" + accountEquity/accountBalance);
   if(accountEquity/accountBalance >= 1.035){ 
      closeAllTrades();
      Alert("Equity: " + accountEquity + " Balance: " + accountBalance + " EQ/BAL " + accountEquity/accountBalance);
   }
   
   bars = Bars(_Symbol,_Period); 
   MqlTick latestPrice; 
   
   MqlDateTime mqlCurrentTime;
   datetime currentTime = TimeCurrent();
   TimeToStruct(currentTime,mqlCurrentTime);
   
   if(!SymbolInfoTick(_Symbol,latestPrice)){Alert("Error getting latest price quoute", GetLastError()); return;}
   if(CopyRates(_Symbol,_Period,0,bars,mrate) < 0){
      Alert("Error getting rates" + GetLastError()); return;}
      
   ArraySetAsSeries(mrate,true);   
   ArraySetAsSeries(ema8,true);
   ArraySetAsSeries(ema21,true);
   ArraySetAsSeries(ema50,true);
   ArraySetAsSeries(ema200,true);
   ArraySetAsSeries(ema800,true);
   ArraySetAsSeries(_CTF,true);
   ArraySetAsSeries(_ADR,true);
   ArraySetAsSeries(_ATR,true);
   
   ArraySetAsSeries(_RSI,true);
   ArraySetAsSeries(_RSIavg2,true);
   ArraySetAsSeries(_RSIavg7,true);
   ArraySetAsSeries(_RSIavg34,true);
   ArraySetAsSeries(_RSIbbLower,true);
   ArraySetAsSeries(_RSIbbUpper,true);
   ArraySetAsSeries(_DEV,true);
   
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
   CopyBuffer(emaHandle,5,0,bars,_ADR);
   CopyBuffer(emaHandle,11,0,bars,_CTF);
   CopyBuffer(emaHandle,14,0,bars,_DEV);
   
   CopyBuffer(atrHandle,0,0,bars,_ATR);
   
   CopyBuffer(asfxTDIHandle,0,0,bars,_RSI);
   CopyBuffer(asfxTDIHandle,1,0,bars,_RSIavg2);
   CopyBuffer(asfxTDIHandle,2,0,bars,_RSIavg7);
   
   CopyBuffer(asfxTDIHandle,3,0,bars,_RSIbbUpper);
   CopyBuffer(asfxTDIHandle,4,0,bars,_RSIbbLower);
   CopyBuffer(asfxTDIHandle,5,0,bars,_RSIavg34);
   CopyBuffer(structureHandle,0,0,bars,_zzBuffer);
   
   bool first = true; //dont take first peak as not formed
   
   ArrayResize(zzTurns, 4);
   int zzCount = 0;
   
   for(int i = 0; i < bars-1 && zzCount < 4; i++){ 
      double zz = _zzBuffer[i];
      
      if(zz!=0 && zz!= EMPTY_VALUE){ //if zz not zero it is a peak so add it to peaks
         if(first){ first = false; continue;}
         zzTurns[zzCount].zzLevel = zz;
         zzTurns[zzCount].zzDT = TimeCurrent();
         zzCount++;
      }
   }
   sortZZ(zzTurns);
   
   int listSize = virtualA2PositionList.Total();
   
   openBuys = 0;
   openSells = 0;
   
   
   if(listSize != 0){
      VirtualPosition2 *vp;
      for(int i = 0; i < listSize; i++){
         vp = virtualA2PositionList.GetNodeAtIndex(i);
         if(vp.direction == "Long") openBuys++;
         if(vp.direction == "Short") openSells++;
          if(vp.CheckPrice(mrate[0].high,mrate[0].low) == true){
            _recordA2String[vp.tradeNumber] += vp.returnResults();
            Alert(_recordA2String[vp.tradeNumber]);
            writeToFileA2(_recordA2String[vp.tradeNumber], "A2");
            virtualA2PositionList.Delete(i);
            listSize = virtualA2PositionList.Total();
          }
      }
   }
   
   double candleMid = (mrate[1].high + mrate[1].low)/2;
   double takeProfit;
   double stopLoss;
   
   confluence = "c";
   
   if(_DEV[1] != 0){
   currentDev = (mrate[1].close - ema800[1])/_DEV[1];
   }
   
   ema800[a] > _CTF[a] ? ema800AboveCTF = true : ema800AboveCTF = false;
   mrate[a].close > _CTF[a] ? priceAboveCTF = true : priceAboveCTF = false;
   
   
   bool baseTP = false; // base stoplosses on a single tp if true, if false base tps on a single stoploss
   
   double timeGap = 60*60;
   if(TimeCurrent() > lastA2datetime + timeGap){
   
      fullTrend = false;
      if(ema50[a] > ema200[a]) fullTrend = true;
      if(ema50[a] < ema200[a]) fullTrend = true;
      
      ema50[a] > ema200[a] ? allowBuys = true : allowBuys = false;
      ema50[a] < ema200[a] ? allowSells = true : allowSells = false;
      
      if(mrate[a].close < ema21[a] && mrate[a].high > ema21[a] && mrate[a].close > ema800[a] && _RSIavg34[a] > 50.0 && ema8[a] > ema21[a] && allowBuys){
         cross_21Down = true;
         //check half candle above
         if(candleMid > ema21[a]){  //buy
         //we have broken below the 21 ema but majority above it so buy
            takeProfit = latestPrice.ask + 4 * _ATR[a];
            //double tpSize = takeProfit - latestPrice.ask;
            double entry = latestPrice.ask;
            stopLoss = stopLossM(entry,1); // latestPrice.ask - 4 * _ATR[a];
            
            if(ema200[a] < entry && ema200[a] > stopLoss) confluence += "+200EMA";
            if(ema800[a] < entry && ema800[a] > stopLoss) confluence += "+800EMA";
//VirtualPosition2(int tradeNumber, double entry, double stopLoss, double takeProfit, string tradeType, bool baseTP, int posNumber, bool realTrade , int mainReal , int play){
  
            VirtualPosition2 *vp = new VirtualPosition2(vpA2Num,latestPrice.ask,stopLoss,takeProfit,"A2",baseTP,6,true,3,3);
            virtualA2PositionList.Add(vp);
            Alert("E/B: " + EB + " Add new pos: " + vp.tradeNumber + " Buy: TP = " +  takeProfit + " volume: " + mrate[0].real_volume + " / " + mrate[0].tick_volume 
            + " Dev: " + currentDev);  
            vp.drawLevels();
            recordTrade(vpA2Num,vp);
            vpA2Num++;
         }
      }
      if(mrate[a].close > ema21[a] && mrate[a].low < ema21[a] && mrate[a].close < ema800[a] && _RSIavg34[a] < 50.0 && ema8[a] < ema21[a] && allowSells){
         cross_21Up = true;
         //check half candle below
         if(candleMid < ema21[a]){
         //we have broken above the 21 ema but majority below it so sell
            double entry = latestPrice.bid;
            takeProfit = latestPrice.bid - 4 *_ATR[a];
            
            double stopLoss = stopLossM(entry, 2);  //latestPrice.bid + 4 * _ATR[a];
            
            if(ema200[a] > entry && ema200[a] < stopLoss) confluence += "+200EMA";
            if(ema800[a] > entry && ema800[a] < stopLoss) confluence += "+800EMA";
            
//VirtualPosition2(int tradeNumber, double entry, double stopLoss, double takeProfit, string tradeType, bool baseTP, int posNumber, bool realTrade , int mainReal , int play){
            
            VirtualPosition2 *vp = new VirtualPosition2(vpA2Num,latestPrice.bid,stopLoss,takeProfit,"A2",baseTP,6,true,3,3);
            virtualA2PositionList.Add(vp);
            Alert("E/B: " + EB + "Add new pos: " + vp.tradeNumber + " SELL: TP = " +  takeProfit + "volume: " + mrate[0].real_volume + " / " + mrate[0].tick_volume
            + " Dev: " + currentDev);  
            vp.drawLevels();
            recordTrade(vpA2Num,vp);
            vpA2Num++;
            //Print("last turn: " + zzTurns[0].zzLevel);
         }
      }
   }
   /*
   if(_RSI[a] > _RSIbbLower[a] && _RSI[b] < _RSIbbLower[b] && mrate[a].close > ema800[a]){
         takeProfit = latestPrice.ask + 4 * _ATR[a];
         double tpSize = takeProfit - latestPrice.ask;
         stopLoss = latestPrice.ask - 2 * _ATR[a];
         Alert("SF BUY: TP = " + takeProfit + "volume: " + mrate[0].real_volume + " / " + mrate[0].tick_volume);
         VirtualPosition *vp = new VirtualPosition(vpSFNum,latestPrice.ask,stopLoss,takeProfit,"SF",baseTP,5);
         virtualSFPositionList.Add(vp);
         vp.drawLevels();
         recordTrade(vpSFNum,vp);
         vpSFNum++;
   }
   
   if(_RSI[a] < _RSIbbUpper[a] && _RSI[b] > _RSIbbUpper[b] && mrate[a].close < ema800[a]){
         takeProfit = latestPrice.bid - 4 * _ATR[a];
         stopLoss = latestPrice.bid + 2 * _ATR[a];
         double tpSize = latestPrice.bid - takeProfit;
         Alert("SF SELL: TP = " +  takeProfit + "volume: " + mrate[0].real_volume + " / " + mrate[0].tick_volume);  
         VirtualPosition *vp = new VirtualPosition(vpSFNum,latestPrice.bid,stopLoss,takeProfit,"SF",baseTP,5);
         virtualSFPositionList.Add(vp);
         vp.drawLevels();
         recordTrade(vpSFNum,vp);
         vpSFNum++;
   }
   */
   /*
   int sfListSize = virtualSFPositionList.Total();
   
   if(sfListSize != 0){
      VirtualPosition *vp;
      for(int i = 0; i < sfListSize; i++){
         vp = virtualSFPositionList.GetNodeAtIndex(i);
          if(vp.CheckPrice(mrate[1].high,mrate[1].low) == true){
            _recordSFString[vp.tradeNumber] += vp.returnResults();
            //Alert("Trade checked " + vp.returnResults());
            Alert(_recordSFString[vp.tradeNumber]);
            writeToFile(_recordSFString[vp.tradeNumber], "SF");
            virtualSFPositionList.Delete(i);
            sfListSize = virtualSFPositionList.Total();
          }
      }
   }
   */
}
//+------------------------------------------------------------------+

void recordTrade(int vpNum, VirtualPosition2 &vp){
   
   lastA2datetime = TimeCurrent();
   
   if(vpNum > ArraySize(_recordA2String) - 1) ArrayResize(_recordA2String, vpNum + 20);
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
   record += vpNum + ", " + vp.tradeType + ", " + vp.direction + ", " + _ATR[a] + ", " + NormalizeDouble(_RSI[a],2) + ", " + NormalizeDouble(_RSIavg34[a],2) + ", " 
                           + NormalizeDouble(_RSIavg2[a],2) + ", " + NormalizeDouble(_RSIavg7[a],2) + ", " + mrate[a].tick_volume + ", "
                           + NormalizeDouble(_DEV[a],Digits()) + ", " + currentDev +  ", " + confluence + ", " + _CTF[a] + ", " +
                           ema800AboveCTF + ", " + priceAboveCTF + ", " + openBuys + ", " + openSells;
                           
   record += ", " + NormalizeDouble(ema8[a],_Digits) + ", " + NormalizeDouble(ema21[a],_Digits) + ", " + NormalizeDouble(ema50[a],_Digits) + ", " 
                           + NormalizeDouble(ema200[a],_Digits) + ", " + NormalizeDouble(ema800[a],_Digits) + ", " + fullTrend + ", ";
                           
   if(vp.tradeType == "A2") _recordA2String[vpNum] += record;
   if(vp.tradeType == "SF") _recordSFString[vpNum] += record;
                           
   Alert(_recordA2String[vpNum]);
}


/*
string dayOfWeek(int day){
   string f;
   switch(day)
     {
      case 1: f="MON";    break;
      case 2: f="TUE";   break;
      case 3: f="WED"; break;
      case 4: f="THU";  break;
      case 5: f="FRI";    break;
      case 6: f="SAT";  break;
      case 0: f="SUN";    break;
     }
     return f;
}
*/

void createFileA2(){
   string fileName = "A2_" + Symbol() + "_" + Period() + ".csv";
   int c = FileOpen(fileName,FILE_WRITE|FILE_ANSI|FILE_TXT);
   if(c == INVALID_HANDLE){Alert("Error opening / creating: " + fileName);}
   string firstLine = "Date, Day, Time, Num, Type, Dir, Rsi, Atr, Liq50, Rsi2, Rsi7, Volume, SD_Size, SD, confluence, CTF, 800aboveCTF, priceAboveCTF, openBuys, openSells, ema8, ema21, ema50, ema200, ema800, FullTrend, 100%, 78.6%, 50.0%, 61.8%, 38.2%, 23.6%"; 
   FileWrite(c,firstLine);
   FileClose(c);
   
}

void writeToFileA2(string line, string type){
   string fileName;
   if(type == "A2") fileName = "A2_" + Symbol() + "_" + Period() + ".csv";
   int c = FileOpen(fileName,FILE_READ|FILE_WRITE|FILE_ANSI|FILE_TXT);
   if(c == INVALID_HANDLE){Alert("Error opening / creating: " + fileName);}
   FileSeek(c,0,SEEK_END); // move pointer to end of file. 
   FileWrite(c,line);
   FileClose(c);
}


double stopLossM(double entry, int dir){
   double potentialSL[7] = 
      {ema50[0],ema200[0],ema800[0],zzTurns[0].zzLevel,zzTurns[1].zzLevel,zzTurns[2].zzLevel,zzTurns[3].zzLevel};
      
   double min;// = _ATR[0]*1.5; 
   double max;// = _ATR[0]*4;
   string slString;
   int chosen = 0;
               //buy                      //sell
   dir == 1 ? min = entry - _ATR[0]*1 : min = entry + _ATR[0]*1; 
   
   dir == 1 ? max = entry - _ATR[0]*4 : max = entry + _ATR[0]*4; 
   
   double pSL = min;
   Alert("Entry: " + entry + " Minimum would be: " + min);
   Alert("Entry: " + entry + " Maximum would be: " + max);
   for(int i = 0; i < 7; i++){
      if( (dir == 1 && potentialSL[i] < entry) || (dir == 2 && potentialSL[i] > entry)){
         if(dir == 1 && potentialSL[i] < min && potentialSL[i] > max && potentialSL[i] < pSL){
            pSL = potentialSL[i]; chosen = i;
            Alert("new Sl: ", i + " psl " + pSL);
         }
         else if(dir == 2 && potentialSL[i] > min && potentialSL[i] < max && potentialSL[i] > pSL){
            pSL = potentialSL[i]; chosen = i;
            Alert("new Sl: ", i + " psl " + pSL);
         }
      }
   }
   string chosenString = "Default";
   
   switch(chosen){
      case 0: chosenString  = "SL ema50"; break;
      case 1: chosenString  = "SL ema200"; break;
      case 2: chosenString  = "SL ema800"; break;
      case 3: chosenString  = "SL Structure 1"; break;
      case 4: chosenString  = "SL Structure 2"; break;
      case 5: chosenString  = "SL Structure 3"; break;
      case 6: chosenString  = "SL Structure 4"; break;
      default: chosenString = "Default min"; break;
   }
   
   Alert("chosen " + chosen + " " + chosenString);
   
   if(dir == 1 && chosen < 6){
      if(potentialSL[chosen] != min)   Alert("SL is " + chosenString + " " + potentialSL[chosen] + " Psl: " + pSL + " " + chosenString);
      else Alert("1ATR used");
   }
   if(dir == 2 && chosen < 6){
      if(potentialSL[chosen] != min)   Alert("SL is " + chosenString + " " + potentialSL[chosen] + " Psl: " + pSL + " " + chosenString);
      else Alert("1ATR used");
   }
   return pSL;
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

void paintStructure(zzLevel& zzTurns[]){
   
   color colour = clrWhite;
   datetime timeNow = TimeCurrent();
   
   ObjectDelete(0,"zz1");
   ObjectDelete(0,"zz2");
   ObjectDelete(0,"zz3");
   ObjectDelete(0,"zz4");
   
   ObjectCreate(0,"zz1",OBJ_TREND,0,zzTurns[0].zzDT,zzTurns[0].zzLevel,timeNow,zzTurns[0].zzLevel);
   ObjectCreate(0,"zz2",OBJ_TREND,0,zzTurns[1].zzDT,zzTurns[1].zzLevel,timeNow,zzTurns[1].zzLevel); 
   ObjectCreate(0,"zz3",OBJ_TREND,0,zzTurns[2].zzDT,zzTurns[2].zzLevel,timeNow,zzTurns[2].zzLevel);
   ObjectCreate(0,"zz4",OBJ_TREND,0,zzTurns[3].zzDT,zzTurns[3].zzLevel,timeNow,zzTurns[3].zzLevel); 
   
   ObjectSetInteger(0,"zz1",OBJPROP_COLOR,colour);
   ObjectSetInteger(0,"zz1",OBJPROP_WIDTH,1);
   ObjectSetInteger(0,"zz1",OBJPROP_SELECTABLE,true);
   
   ObjectSetInteger(0,"zz2",OBJPROP_COLOR,colour);
   ObjectSetInteger(0,"zz2",OBJPROP_WIDTH,1);
   ObjectSetInteger(0,"zz2",OBJPROP_SELECTABLE,true);
   
   ObjectSetInteger(0,"zz3",OBJPROP_COLOR,colour);
   ObjectSetInteger(0,"zz3",OBJPROP_WIDTH,1);
   ObjectSetInteger(0,"zz3",OBJPROP_SELECTABLE,true);
   
   ObjectSetInteger(0,"zz4",OBJPROP_COLOR,colour);
   ObjectSetInteger(0,"zz4",OBJPROP_WIDTH,1);
   ObjectSetInteger(0,"zz4",OBJPROP_SELECTABLE,true);
   
   
   Alert("Objects printed");
}

