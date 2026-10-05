//+------------------------------------------------------------------+
//|                                               CircuitBreaker.mqh |
//|                   Copyright 2026, Architectural Framework Sample |
//+------------------------------------------------------------------+
#property strict

class CCircuitBreaker
{
private:
   double m_initialBalance;
   double m_maxLossPercentage;
   datetime m_lastResetDate;

   void CheckDailyReset()
   {
      MqlDateTime dtCurrent, dtReset;
      TimeToStruct(TimeCurrent(), dtCurrent);
      TimeToStruct(m_lastResetDate, dtReset);

      if(dtCurrent.day != dtReset.day)
      {
         m_initialBalance = AccountBalance();
         m_lastResetDate = TimeCurrent();
         PrintFormat("[Breaker] Daily baseline balance reset: %.2f", m_initialBalance);
      }
   }

public:
   CCircuitBreaker() : m_initialBalance(0.0), m_maxLossPercentage(4.5), m_lastResetDate(0) {}

   void Init(double maxLossPct)
   {
      m_maxLossPercentage = maxLossPct;
      m_initialBalance    = AccountBalance();
      m_lastResetDate     = TimeCurrent();
      PrintFormat("[Breaker] Initialized. Baseline Balance: %.2f, Max Daily Loss: %.2f%%", 
                  m_initialBalance, m_maxLossPercentage);
   }

   bool CheckBreakerTripped()
   {
      if(m_initialBalance <= 0.0) return false;

      CheckDailyReset();

      double currentEquity = AccountEquity();
      double drawdownAmount = m_initialBalance - currentEquity;
      double currentDrawdownPct = (drawdownAmount / m_initialBalance) * 100.0;

      if(currentDrawdownPct >= m_maxLossPercentage)
      {
         PrintFormat("[Breaker TRIP] Daily limit hit! Initial: %.2f, Equity: %.2f, DD: %.2f%% (Limit: %.2f%%)",
                     m_initialBalance, currentEquity, currentDrawdownPct, m_maxLossPercentage);
         return true;
      }

      return false;
   }
};

