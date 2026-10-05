//+------------------------------------------------------------------+
//|                                                  LicenseAuth.mqh |
//|                   Copyright 2026, Architectural Framework Sample |
//+------------------------------------------------------------------+
#property strict

class CLicenseAuth
{
private:
   string m_authEndpoint;
   int    m_maxRetries;
   int    m_retryIntervalSeconds;

   bool ExecuteHttpRequest(string url, string &responseBody)
   {
      char postData[];
      char resultData[];
      string resultHeaders;

      ResetLastError();
      int res = WebRequest("GET", url, NULL, 5000, postData, resultData, resultHeaders);
      if(res >= 200 && res < 300)
      {
         responseBody = CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
         return true;
      }
      PrintFormat("[LicenseAuth] WebRequest failed. HTTP Status: %d, Error: %d", res, GetLastError());
      return false;
   }

public:
   CLicenseAuth() 
      : m_authEndpoint("https://script.google.com/macros/s/YOUR_AUTH_ENDPOINT/exec"),
        m_maxRetries(5),
        m_retryIntervalSeconds(60)
   {}

   bool VerifyLicense(string licenseKey, long accountNumber)
   {
      string requestUrl = StringFormat("%s?key=%s&acc=%d", m_authEndpoint, licenseKey, accountNumber);
      string response = "";

      for(int attempt = 1; attempt <= m_maxRetries; attempt++)
      {
         PrintFormat("[LicenseAuth] Attempt %d/%d: Querying licensing gateway...", attempt, m_maxRetries);
         if(ExecuteHttpRequest(requestUrl, response))
         {
            if(StringFind(response, "\"status\":\"active\"") != -1)
            {
               Print("[LicenseAuth] Verification successful. Authorized session established.");
               return true;
            }
            PrintFormat("[LicenseAuth] Access denied by authority. Response: %s", response);
            return false;
         }

         if(attempt < m_maxRetries)
         {
            PrintFormat("[LicenseAuth] Transient network failure. Retrying in %d seconds...", m_retryIntervalSeconds);
            Sleep(m_retryIntervalSeconds * 1000);
         }
      }

      Print("[LicenseAuth] Critical: Exhausted all authorization retry attempts.");
      return false;
   }
};
