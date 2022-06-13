//+------------------------------------------------------------------+
//|                                                VwapEAMethods.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Trade/Trade.mqh>
CTrade   Trade;

//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

enum ValueEntry{
   SuperTrendEntryBuy,  StrongTrendEntryBuy, ValueTrendEntryBuy,  GoodValueEntryBuy,   DeepValueEntryBuy,   YesterdayVWAPEntryBuy,
   SuperTrendEntrySell,  StrongTrendEntrySell,  ValueTrendEntrySell, GoodValueEntrySell,  DeepValueEntrySell,  YesterdayVWAPEntrySell,
   NoEntry
};

string trendCondition(int trendNumber){
    string trendCondition;
    switch(trendNumber){
      case 0 : trendCondition = "Calm";                     break;
      case 1 : trendCondition = "Uptrend Moderate";         break;
      case 2 : trendCondition = "Uptrend Strong";           break;
      case 3 : trendCondition = "Downtrend Moderate";       break;
      case 4 : trendCondition = "Downtrend Strong";         break;
      default: trendCondition = "Error determining trend";  break;
   }
   return trendCondition;
}

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

int getRow(int play){
   int row;
   switch(play){
        case -1 : row = 0; break; //MR -1SD 
        case -2 : row = 1; break; //MR -2SD 
        case -3 : row = 2; break; //MR -3SD 
                  
        case 10:  row = 3; break; //TVWBUT 
        case -10: row = 4; break; //TVWSELL 
                  
        case 11:  row = 5; break; //T1SDBUY 
        case -11: row = 6; break; //T-1SDSELL 
                 
        case  1 : row = 7; break; //MR 1SD 
        case  2 : row = 8; break; //MR 2SD 
        case  3 : row = 9; break; //MR 3SD 
        
        case 12  : row = 10; break; //YDAYW Buy
        case -12 : row = 11; break; //YDAYVW Sell
        
        case  -20: row = 12; break;//weekly vwap buy
        case  20 : row = 13; break;//weekly vwap sell
        case  22 : row = 14; break;//weekly 2sd sell
        case  -22: row = 15; break;//weekly 2sd buy
        case  23 : row = 16; break;//weekly 2sd sell
        case  -23: row = 17; break;//weekly 2sd buy
        
        default: break;
   }
   return row;
}

string getPlay(int play){
   string playS;
   switch(play){
        case -1  : playS = "MR -1SD"; break; //MR -1SD 
        case -2  : playS = "MR -2SD"; break; //"MR -2SD" 
        case -3  : playS = "MR -3SD"; break; //"MR -3SD" 
                  
        case 10  : playS = "T VW B"; break; //"T VW B" 
        case -10 : playS = "T VW S"; break; //"T VW S"
                  
        case 11  : playS = "T 1SD B"; break; //"T 1SD B" 
        case -11 : playS = "T-1SD S"; break; //"T-1SD S" 
                 
        case  1  : playS = "MR 1SD"; break;  //"MR 1SD"  
        case  2  : playS = "MR 2SD"; break; //"MR 2SD" 
        case  3  : playS = "MR 3SD"; break; //"MR 3SD" 
        
        case 12  : playS = "YDVW Buy"; break; //YDAYW Buy
        case -12 : playS = "YDVW Sell"; break; //YDAYVW Sell
        
        case  -20: playS = "weekVW B"; break;//weekly vwap buy
        case  20 : playS = "weekVW S"; break;//weekly vwap sell
        case  22 : playS = "week2SD S"; break;//weekly 2sd sell
        case  -22: playS = "week2SD B"; break;//weekly 2sd buy
        case  23 : playS = "week3SD S"; break;//weekly 2sd sell
        case  -23: playS = "week3SD B"; break;//weekly 2sd buy
                  
        default: break;
   }
   return playS;
}

double tradeSize(double percent, double slSize){
   double maxVolume = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   int digit = _Digits; int tsDigit = 0;
   double mod = 1;
   double stepVolume = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP); //minimal change for deal execution
   if(stepVolume == 0.1)   tsDigit = 1;
   if(stepVolume == 0.01)  tsDigit = 2;
   double tickSize = SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE); 
   double lotSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk = balance * percent/100; //set risk to 1% of account balance in test
   double tradeSize = MathAbs(NormalizeDouble(risk/(slSize*lotSize*mod),tsDigit));
   if(tradeSize > maxVolume) tradeSize = maxVolume;
   return tradeSize;
}


void writeToFile(string line, string name){
   Alert("WriteToFile");
   string fileName = name; //Symbol() + "_demoVWAP.csv";
   int c = FileOpen(fileName,FILE_READ|FILE_WRITE|FILE_ANSI|FILE_CSV);
   if(c == INVALID_HANDLE){Alert("Error opening / creating: " + fileName);}
   FileSeek(c,0,SEEK_END); // move pointer to end of file. 
   FileWrite(c,line);
   FileClose(c);
}
void createFile(string name){
   //TradeRecord(mqlCurrentDT, "LONG", sdFromVW, tdiSignal, trendCondition, vsYDVW, vsHTF, htfDIR); + result + profit
   string fileName = name; //Symbol() + "_demoVWAP.csv";
   int c = FileOpen(fileName,FILE_WRITE|FILE_ANSI|FILE_CSV);
   if(c == INVALID_HANDLE){Alert("Error opening / creating: " + fileName);}
   
   string initialLine = "#,Date,Day,Time,Pos,Play,SD,Entry,Sl,Tp,TdiSignal,TdiFast,TdiSlow,TdiMid";
   initialLine += ",VW_TREND,VWvsYVW,T15,T30,T60,T120,T240, TAvg, earlyTrend, aznVWBox";
   initialLine += "ema8,ema21,ema50,ema200,ema800";
   initialLine +=  ",sdWeek, sdWeekTrend";
   initialLine += ",PvsHTF,HTF_DIR, confYVW, sdYVW, yHODBroken, yLODBroken, confYHOD, sdYHOD, condYLOD, sdYLOD, scoreA, Results, , , , ,  , ,  ,  Loss, Win, BE";
   FileWrite(c,initialLine);
   FileClose(c);
}

void createFiles(){

   
   string idFileName = Symbol() + "ALL_ID_VWAP.csv";
   string id3SDFileName = Symbol() + "MR_3SD_ID_VWAP.csv";
   string id2SDFileName = Symbol() + "MR_2SD_ID_VWAP.csv";
   string idO1SDFileName = Symbol() + "TO_1SD_ID_VWAP.csv";
   string idVWFileName = Symbol() + "T_VW_ID_VWAP.csv";
   string idS1SDFileName = Symbol() + "TS_1SD_ID_VWAP.csv";
   string idYDVWFileName = Symbol() + "MR_ID_YDVW.csv";
   
   string idWFileName = Symbol() + "ALL_ID_WEEKLY_VWAP.csv";
   string idW3SDFileName = Symbol() + "MR_3SD_ID_WEEKLY_VWAP.csv";
   string idW2SDFileName = Symbol() + "MR_2SD_ID_WEEKLY_VWAP.csv";
   string idWO1SDFileName = Symbol() + "TO_1SD_ID_WEEKLY_VWAP.csv";
   string idWVWFileName = Symbol() + "T_VW_ID_WEEKLY_VWAP.csv";
   string idWS1SDFileName = Symbol() + "TS_1SD_ID_WEEKLY_VWAP.csv";
   string idWYDVWFileName = Symbol() + "MR_ID_WEEKLY_YDVW.csv";
   
   string scFileName = Symbol() + "ALL_SC_VW_TDI.csv";
   //INTRADAY FILES
   createFile(idFileName); //create initial line of file
   createFile(id3SDFileName);
   createFile(id2SDFileName);
   createFile(idO1SDFileName);
   createFile(idVWFileName);
   createFile(idYDVWFileName);
   createFile(idS1SDFileName); 
   
   //WEEKLY FILES
   createFile(idW3SDFileName);
   createFile(idW2SDFileName);
   createFile(idWO1SDFileName);
   createFile(idWVWFileName);
   createFile(idWYDVWFileName);
   createFile(idWS1SDFileName); 
   
   //SCALPS
   createFile(scFileName);
}

string intEntryToString(int ve){
   if(ve == 0)             return "Super Trend";
   else if(ve == 1)        return "Strong Trend";
   else if(ve == 2)        return "Value Trend";
   else if(ve == 3)        return "Good Value";
   else if(ve == 4)        return "Deep Value";
   
   else if(ve == 5)        return "Super Trend";
   else if(ve == 6)        return "Strong Trend";
   else if(ve == 7)        return "Value Trend";
   else if(ve == 8)        return "Good Value";
   else if(ve == 9)        return "Deep Value";
   
   else if(ve == 10)       return "YVW Buy";
   else if(ve == 11)       return "YVW Sell";
   
   else return 12;
}

void checkRealPositions(){
   int totalPos = PositionsTotal();

   if(totalPos > 0){
      for(int i = totalPos -1; i >= 0; i--){ 
          ulong ticket = PositionGetTicket(i);
          
          if(totalPos == 2){
            int oldTicket = PositionGetTicket(0);
            int newTicket = PositionGetTicket(1);
            //Trade.PositionCloseBy(oldTicket,newTicket);
          }
          /* //close all at time code:
          if(ticket>0){ 
               if(mqlCurrentDT.hour == 22) Trade.PositionClose(ticket,100);
               else{
                  double current;
                  PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? current = mrate[0].high : current = mrate[0].low;
                  double open = PositionGetDouble(POSITION_PRICE_OPEN);
                  double stop = PositionGetDouble(POSITION_SL);
                  double take = PositionGetDouble(POSITION_TP);
                  //if(MathAbs(current - open) > 0.8*MathAbs(take - open)){ Trade.PositionModify(ticket,open,take); Alert("80% To BE rule"); }
                  //else if(MathAbs(current - open) > MathAbs(open - stop)){ Trade.PositionModify(ticket,open,take); Alert("BE RULE"); }
               }
          }*/
      }
   }
}


string entryToString(ValueEntry ve){
   if(ve == SuperTrendEntryBuy)           return "Super Trend";
   else if(ve == StrongTrendEntryBuy)     return "Strong Trend";
   else if(ve == ValueTrendEntryBuy)      return "Value Trend";
   else if(ve == GoodValueEntryBuy)       return "Good Value";
   else if(ve == DeepValueEntryBuy)       return "Deep Value";
   
   else if(ve == SuperTrendEntrySell)     return "Super Trend";
   else if(ve == StrongTrendEntrySell)    return "Strong Trend";
   else if(ve == ValueTrendEntrySell)     return "Value Trend";
   else if(ve == GoodValueEntrySell)      return "Good Value";
   else if(ve == DeepValueEntrySell)      return "Deep Value";
   
   else if(ve == YesterdayVWAPEntryBuy)   return "YDVW Buy";
   else if(ve == YesterdayVWAPEntrySell)  return "YDVW Sell";
   else return "No Entry";
}

int entryToPlay(ValueEntry ve){
   if(ve == SuperTrendEntryBuy)           return 0;
   else if(ve == StrongTrendEntryBuy)     return 1;
   else if(ve == ValueTrendEntryBuy)      return 2; 
   else if(ve == GoodValueEntryBuy)       return 3;
   else if(ve == DeepValueEntryBuy)       return 4;
   
   else if(ve == SuperTrendEntrySell)     return 5;
   else if(ve == StrongTrendEntrySell)    return 6;
   else if(ve == ValueTrendEntrySell)     return 7;
   else if(ve == GoodValueEntrySell)      return 8;
   else if(ve == DeepValueEntrySell)      return 9;
   
   else if(ve == YesterdayVWAPEntryBuy)   return 10;
   else if(ve == YesterdayVWAPEntrySell)  return 11;
   
   else return 12;
}

void createFileVT(string name){
   //TradeRecord(mqlCurrentDT, "LONG", sdFromVW, tdiSignal, trendCondition, vsYDVW, vsHTF, htfDIR); + result + profit
   string fileName = name; //Symbol() + "_demoVWAP.csv";
   int c = FileOpen(fileName,FILE_WRITE|FILE_ANSI|FILE_CSV);
   if(c == INVALID_HANDLE){Alert("Error opening / creating: " + fileName);}
   
   string initialLine = "#,Date,Day,Time,Play,Pos, Signal, Entry,TP,RSI,TdiFast,TdiSlow,TdiMid, Volume, ";
   //initialLine += ",VW_TREND,VWvsYVW,T15,T30,T60,T120,T240, TAvg, earlyTrend, aznVWBox";
   initialLine += "ema8,ema21,ema50,ema200,ema800, SD, vwapTrend, VW>HTF, VW>MTF, MTF>HTF, VW>YVW, Wins, Losses, BEs, 100%, 78.6%, 61.8%, 50.0%, 38.2%, 23.6%";
   
   FileWrite(c,initialLine);
   FileClose(c);
   Alert("Created: " + name);
}

void writeToFileVT(string line, string name){
   
   string fileName = name; //Symbol() + "_demoVWAP.csv";
   int c = FileOpen(fileName,FILE_READ|FILE_WRITE|FILE_ANSI|FILE_CSV);
   if(c == INVALID_HANDLE){Alert("Error opening / creating: " + fileName);}
   FileSeek(c,0,SEEK_END); // move pointer to end of file. 
   FileWrite(c,line);
   FileClose(c);
}

void closeAllTrades(){
   Alert("Close All Trades");
   int totalPos = PositionsTotal();
   if(totalPos > 0){
      for(int i = totalPos -1; i >= 0; i--){ 
          ulong ticket = PositionGetTicket(i);
          Trade.PositionClose(ticket,100);
      }
   }
}