//+------------------------------------------------------------------+
//|                                              VirtualPosition.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Arrays\List.mqh>
#include <Trade/Trade.mqh>
#include <VwapEAMethods.mqh>


enum TradeCommand{
   commandBE, commandHalfRisk, commandSecureProfit, modify
};
enum ProfitLevel{
   level80, level75, level50, level25
};


CTrade vpTrade;

class VirtualPosition2 : public CObject
  {
private:

public:
      VirtualPosition2();
      ~VirtualPosition2();
      bool addReal();
      bool closeReal();
      bool modifyReal(double sl, double tp, TradeCommand tc);
      
      bool CheckPrice(double high, double low);
      int      tradeNumber;
      int      tradePlayNumber;
      string   tradeType;
      string   direction;
      double   entry;
      double   stopLoss;
      
      double   newSL;
      double   halfSL;
      double   halfSLSize;
      
      double   takeProfit;
      double   stopLossChart; //for drawing
      double   takeProfitChart; //for drawing
      datetime entryDT;
      datetime exitDT;
      
      int      ticket;
      int      ticket2;
      
      int      mainReal;
      
      bool     realTrade;
      bool     mainHit;
      bool     atBE;             //set to break even
      bool     atHalfRisk;       //reduce stoploss by half
      bool     atSecureProfit;   //secure profit (stoploss hit = profit)
      
      ProfitLevel    levelPC;          //what level are we at 100% TP 90% TO 1R  50% TO BE  25% TO HALF BE
      
      int      posNumber;
      int      slNumber;
      int      tpNumber;
      double   sl[];
      double   tp[];
      double   result[];
      
      color    colourBE;
      double   reward[];
      double   risk[];
      string   tpBox;
      string   slBox;
      
      int magicN;
      bool baseTP;      //base SLs on TP if true, if false TPs are based on SL
      int checkCount;
         
      VirtualPosition2(int tradeNumber, double entry, double stopLoss, double takeProfit, string tradeType, bool baseTP, int posNumber, bool realTrade , int mainReal , int play){
      
         this.tradeType = tradeType;
         this.tradeNumber = tradeNumber; 
         this.posNumber = posNumber;
         this.entry = entry;
         this.stopLoss = stopLoss; 
         this.takeProfit = takeProfit;
         this.slNumber = posNumber;
         this.tpNumber = posNumber;
         this.baseTP = baseTP;
         this.realTrade = realTrade;
         if(mainReal == 0) this.mainReal = 1;
         this.mainReal = mainReal;
         
         tradePlayNumber = play;
         
         magicN = 3330 + play;
         mainHit = false;
         colourBE = clrBlue;
         ArrayResize(sl,posNumber);
         ArrayResize(tp,posNumber);
         ArrayResize(result,posNumber);
         atBE = atHalfRisk = atSecureProfit = false;
         checkCount = 0; 
         
         entryDT = TimeCurrent();
         direction = (takeProfit > entry) ? "Long" : "Short";
         //Alert("New VP: " + direction + " entry: " + entry + " TP: " + takeProfit + " SL: " + stopLoss);
         
         if(baseTP){ 
         
            double stopLossSize = entry - stopLoss; //negative if stopLoss > entry as short
            sl[0] = entry - 1    *stopLossSize;
            sl[1] = entry - 0.786*stopLossSize;
            sl[2] = entry - 0.618*stopLossSize;
            sl[3] = entry - 0.500*stopLossSize;
            sl[4] = entry - 0.382*stopLossSize;
            sl[5] = entry - 0.236*stopLossSize;
            stopLoss = sl[mainReal];
            stopLossChart = sl[mainReal]; // middle for graphic
            tp[0] = tp[1] = tp[2] = tp[3] = tp[4] = tp[5] = takeProfitChart = takeProfit;
            ArrayFill(result,0,posNumber,0);
            
         }
         
         else if(!baseTP){
            
            double stopLossSize = entry - stopLoss; //negative if stopLoss > entry as short
            tp[0] = entry + stopLossSize/1;
            tp[1] = entry + stopLossSize/0.786;
            tp[2] = entry + stopLossSize/0.618;
            tp[3] = entry + stopLossSize/0.500;
            tp[4] = entry + stopLossSize/0.382;
            tp[5] = entry + stopLossSize/0.236;
            takeProfitChart = tp[3]; //middle for graphic
            sl[0] = sl[1] = sl[2] = sl[3] = sl[4] = sl[5] = stopLoss;
            stopLoss = sl[mainReal];
            stopLossChart = sl[mainReal];
            ArrayFill(result,0,posNumber,0);
            
         }
         
         //Alert("New position: " + tradeType);
         //lert("New VP at: ", entry);
         tpBox = "tpBox_" + tradeNumber;
         slBox = "slBox_" + tradeNumber;
         
         if(realTrade){
            double tradeVol = tradeSize(0.75,entry-sl[mainReal]);
            //int magicN = 3330 + tradePlayNumber;
            vpTrade.SetExpertMagicNumber(magicN);
            if(direction == "Long" && magicN >= 3330){ 
               vpTrade.SetExpertMagicNumber(magicN);
               vpTrade.PositionOpen(_Symbol,ORDER_TYPE_BUY,tradeVol,entry,sl[3],tp[3],NULL); //Sleep(10000);   
               int position = PositionsTotal() - 1;
               ticket = PositionGetTicket(position);
               }
            if(direction == "Short" && magicN >= 3330){ 
               vpTrade.SetExpertMagicNumber(magicN);
               vpTrade.PositionOpen(_Symbol,ORDER_TYPE_SELL,tradeVol,entry,sl[3],tp[3],NULL); //Sleep(10000); 
               int position = PositionsTotal() - 1;
               ticket = PositionGetTicket(position);
               }
         }
      }
      
      void drawLevels(){
         color colourTP, colourSL;
         colourTP = clrDeepSkyBlue;  colourSL = clrPink;
         
         
         if(tradePlayNumber == 0 || tradePlayNumber == 5){ colourTP = clrOrange;       colourSL = clrPink;  } // superTrend 
         else if(tradePlayNumber == 1 || tradePlayNumber == 6){ colourTP = clrGold;         colourSL = clrPink;  } // strongTrend 
         else if(tradePlayNumber == 2 || tradePlayNumber == 7){ colourTP = clrMediumOrchid; colourSL = clrPink;  } // valueTrend 
         else if(tradePlayNumber == 3 || tradePlayNumber == 8){ colourTP = clrPaleGreen;    colourSL = clrPink;  }  //good value
         else if(tradePlayNumber == 4 || tradePlayNumber == 9){ colourTP = clrGreenYellow;  colourSL = clrPink;  } //deep value
         else{ colourTP = clrYellow; colourSL = clrPink; }
         
         if(tradeType == "SF"){ colourTP = clrPaleGreen; colourSL = clrPink; }
         
         
         if(atBE) colourSL = colourBE;
         ObjectCreate(0,tpBox,OBJ_RECTANGLE,0,entryDT,entry,entryDT + 60*60,takeProfitChart);
         ObjectSetInteger(0,tpBox,OBJPROP_COLOR,colourTP);
         ObjectCreate(0,slBox,OBJ_RECTANGLE,0,entryDT,entry,entryDT + 60*60,stopLossChart);
         ObjectSetInteger(0,slBox,OBJPROP_COLOR,colourSL);
         ObjectSetInteger(0,tpBox,OBJPROP_FILL,true);
         ObjectSetInteger(0,tpBox,OBJPROP_BACK,true);
         ObjectSetInteger(0,slBox,OBJPROP_FILL,true);
         ObjectSetInteger(0,slBox,OBJPROP_BACK,true);
      }
      void deleteLevels(){
         ObjectDelete(0,   tpBox);
         ObjectDelete(0,   slBox);
      }
      string returnResults(){
         return result[0] + ", " + result[1] + ", " + result[2] + ", " + result[3] + ", " + result[4] + ", " + result[5];
      }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
VirtualPosition2::VirtualPosition2()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
VirtualPosition2::~VirtualPosition2()
  {
   //Alert("Position destroyed");
  }
//+------------------------------------------------------------------+
bool VirtualPosition2::CheckPrice(double currentCandleHigh, double currentCandleLow){
   if(currentCandleHigh == 0 || currentCandleLow == 0) Alert("Error"); 
   if(currentCandleHigh < currentCandleLow) Alert("Error high < low");
   
   int size = ArraySize(sl);
   if(result[mainReal] == -1) mainHit = true;
   
   bool modify = false;
   for(int i = 0; i < size; i++){
   
         if(direction == "Long"){ //buys
            if(modify && (currentCandleHigh > entry + (takeProfit - entry)/4) && result[mainReal] == 0){ modifyReal(0,0,commandHalfRisk);    }
            if(modify && (currentCandleHigh > entry + (takeProfit - entry)/2) && (result[mainReal] == 0 || result[mainReal] == -0.5)){ modifyReal(0,0,commandBE);   }
         
            if(result[i] == 0){ //check        
               if(currentCandleLow <= sl[i]){         
                  result[i] = -1;       checkCount++;  
                  //Alert(direction + " Position " + tradeNumber + " SL[ " + i + "] hit checkcount = " + checkCount + " res[" + i + "] = " + result[i]);
               }  
               if(currentCandleHigh >= tp[i]){        
                  result[i] = MathAbs(tp[i] - entry) / MathAbs(entry - sl[i]);      
                  checkCount++;  
                  //Alert(direction + " Position " + tradeNumber + " TP[ " + i + "] hit checkcount = " + checkCount + " res[" + i + "] = " + result[i]);
               } 
            }
            //if(checkCount == 5){ Alert("VP num: " + tradeNumber + " fully checked"); return true; }
         }//end of buys
         if(direction == "Short"){ //sells
            
            if(modify && currentCandleLow < entry + (takeProfit - entry)/2){         modifyReal(0,0,commandHalfRisk);     }   //stoploss
            if(modify && currentCandleLow < entry + (takeProfit - entry)/1.5){       modifyReal(0,0,commandBE);           }   //BE
            
            if(result[i] == 0){ //check scalps                 
               if(currentCandleLow <= tp[i]){         
                  result[i] = MathAbs(entry - tp[i])/MathAbs(sl[i] - entry);   
                  checkCount++;  
                  //Alert(direction + " Position " + tradeNumber + " TP[ " + i + "] hit checkcount = " + checkCount + " res[" + i + "] = " + result[i]);
                  }  
               if(currentCandleHigh >= sl[i]){        
                  result[i] = -1;       checkCount++;  
                  //Alert(direction + " Position " + tradeNumber + " SL[ " + i + "] hit checkcount = " + checkCount + " res[" + i + "] = " + result[i]);
               }  
            }
            //if(checkCount == 5){ Alert("VP num: " + tradeNumber + " fully checked"); return true; }
         }//end of checking sells
         
      }//end of updating
      if(checkCount == posNumber){ 
         Alert("VP num: " + tradeNumber + " checked" + direction + " results: " + result[0] + ", " + result[1] + ", " + result[2] + ", " + result[3] + ", " + result[4] + ", " + result[5]);
         return true; 
      }
      return false;
      
}

bool VirtualPosition2::addReal(){
   realTrade = true;
   return true;
}
bool VirtualPosition2::closeReal(){
   return true;
}
bool VirtualPosition2::modifyReal(double newSL, double newTP, TradeCommand tc){
   
   
   if(tc == commandBE && !atBE && !atSecureProfit && !mainHit){ 
      atBE = true; //dont repeat
      newSL = entry;
      vpTrade.PositionModify(ticket,entry,takeProfit);
      Alert("N: " + tradeNumber + " set to BE");
      //stopLossChart = newSL;
      drawLevels();
   }
   
   if(tc == commandHalfRisk && !atHalfRisk && !atBE && !atSecureProfit && !mainHit){ 
      atHalfRisk = true;
      PositionSelectByTicket(ticket);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentStop = PositionGetDouble(POSITION_SL);
      halfSLSize = (entry - currentStop)/2;
      //Alert("N: " + tradeNumber + " SL SIZE: " + (entry - currentStop) + "halfsize: " + halfSLSize);
      newSL = entry - halfSLSize;
      Alert("N: " + tradeNumber + " Set to Half Risk old SL: " + NormalizeDouble(currentStop,5) + " new: " + NormalizeDouble(newSL,5));
      vpTrade.PositionModify(ticket,newSL,takeProfit);
      stopLossChart = newSL;
      drawLevels();
   }
   
   if(tc == commandSecureProfit){
      //finish method; 
   }
   return true;
}

