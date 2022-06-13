//+------------------------------------------------------------------+
//|                                                          zzS.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Object.mqh>

class zzS : public CObject
  {
private:

public:
                     zzS();
                    ~zzS();
                     zzS(int id);
                     zzS(double zzLevel, datetime zzDT, string zzName);
                     bool checkBreak(double currentPrice);
                     double zzLevel;
                     int    extreme; //1 if high 2 if low
                     int    vsLast; //1 if greater HH or LL, -1 if lesser LH or HL
                     datetime zzDT;
                     string zzName;
                     bool broken;
                     int id;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
zzS::zzS()
  {
  }
zzS::zzS(int id)
  {
   this.id = id;
  }
  
zzS::zzS(double zzLevel, datetime zzDT, string zzName){
   this.zzLevel = zzLevel;
   this.zzDT = zzDT; 
   this.zzName = zzName;
   broken = false;
} 

bool zzS::checkBreak(double price){
   if(extreme == 1 && !broken){ //high
      if(price > zzLevel) broken = true;
      Alert("Broken zone high " + price + " level: " + zzLevel);
   }
   if(extreme == -1 && !broken){   //low
      if(price < zzLevel) broken = true;
      Alert("Broken zone low price: " + price + " level: " + zzLevel);
   }
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
zzS::~zzS()
  {
  }
//+------------------------------------------------------------------+
