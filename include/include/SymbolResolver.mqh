//+------------------------------------------------------------------+
//|                                               SymbolResolver.mqh |
//|                   Copyright 2026, Architectural Framework Sample |
//+------------------------------------------------------------------+
#property strict

class CSymbolResolver
{
public:
   CSymbolResolver() {}

   string ResolveSilverSymbol()
   {
      string candidates[] = {
         "XAGUSD",
         "SILVER",
         "XAGUSDm",
         "XAGUSD.a",
         "XAGUSDpro",
         "XAG"
      };

      int totalCandidates = ArraySize(candidates);
      for(int i = 0; i < totalCandidates; i++)
      {
         ResetLastError();
         double bid = MarketInfo(candidates[i], MODE_BID);
         if(GetLastError() == 0 && bid > 0.0)
         {
            PrintFormat("[SymbolResolver] Successfully bound correlated asset: %s (Bid: %.4f)", candidates[i], bid);
            return candidates[i];
         }
      }

      Print("[SymbolResolver] Warning: Unable to resolve Silver ticker. Falling back to default.");
      return "";
   }
};
