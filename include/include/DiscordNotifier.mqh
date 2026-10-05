//+------------------------------------------------------------------+
//|                                              DiscordNotifier.mqh |
//|                   Copyright 2026, Architectural Framework Sample |
//+------------------------------------------------------------------+
#property strict

class CDiscordNotifier
{
private:
   string m_webhookUrl;

   int ReadFileBinary(string filename, char &dataBuffer[])
   {
      ResetLastError();
      int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN);
      if(fileHandle == INVALID_HANDLE)
      {
         PrintFormat("[Discord] FileOpen failed. Error: %d", GetLastError());
         return 0;
      }

      ulong fileSize = FileSize(fileHandle);
      ArrayResize(dataBuffer, (int)fileSize);
      uint bytesRead = FileReadArray(fileHandle, dataBuffer, 0, (int)fileSize);
      FileClose(fileHandle);

      return (int)bytesRead;
   }

public:
   CDiscordNotifier() : m_webhookUrl("") {}

   void Init(string webhookUrl)
   {
      m_webhookUrl = webhookUrl;
   }

   bool SendTextMessage(string message)
   {
      if(m_webhookUrl == "") return false;

      char postData[];
      char resultData[];
      string resultHeaders;
      string jsonPayload = StringFormat("{\"content\":\"%s\"}", message);

      StringToCharArray(jsonPayload, postData, 0, WHOLE_ARRAY, CP_UTF8);
      if(ArraySize(postData) > 0 && postData[ArraySize(postData)-1] == 0)
         ArrayResize(postData, ArraySize(postData)-1);

      string headers = "Content-Type: application/json; charset=utf-8\r\n";

      int res = WebRequest("POST", m_webhookUrl, headers, 5000, postData, resultData, resultHeaders);
      return (res >= 200 && res < 300);
   }

   bool SendMultipartMessage(string imageFilename, string message)
   {
      if(m_webhookUrl == "") return false;

      char imageBytes[];
      int imageSize = ReadFileBinary(imageFilename, imageBytes);
      if(imageSize == 0)
      {
         Print("[Discord] Binary load failed. Falling back to text-only dispatch.");
         return SendTextMessage(message);
      }

      string boundary = "----Mql4Boundary" + IntegerToString(GetTickCount());
      string headerPart = "--" + boundary + "\r\n"
                        + "Content-Disposition: form-data; name=\"content\"\r\n\r\n"
                        + message + "\r\n"
                        + "--" + boundary + "\r\n"
                        + "Content-Disposition: form-data; name=\"file\"; filename=\"" + imageFilename + "\"\r\n"
                        + "Content-Type: image/png\r\n\r\n";

      string footerPart = "\r\n--" + boundary + "--\r\n";

      char headerBytes[];
      char footerBytes[];
      StringToCharArray(headerPart, headerBytes, 0, WHOLE_ARRAY, CP_UTF8);
      if(ArraySize(headerBytes) > 0 && headerBytes[ArraySize(headerBytes)-1] == 0)
         ArrayResize(headerBytes, ArraySize(headerBytes)-1);

      StringToCharArray(footerPart, footerBytes, 0, WHOLE_ARRAY, CP_UTF8);
      if(ArraySize(footerBytes) > 0 && footerBytes[ArraySize(footerBytes)-1] == 0)
         ArrayResize(footerBytes, ArraySize(footerBytes)-1);

      char fullPayload[];
      int totalSize = ArraySize(headerBytes) + imageSize + ArraySize(footerBytes);
      ArrayResize(fullPayload, totalSize);

      ArrayCopy(fullPayload, headerBytes, 0, 0, ArraySize(headerBytes));
      ArrayCopy(fullPayload, imageBytes, ArraySize(headerBytes), 0, imageSize);
      ArrayCopy(fullPayload, footerBytes, ArraySize(headerBytes) + imageSize, 0, ArraySize(footerBytes));

      string requestHeaders = "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";
      char resultData[];
      string resultHeaders;

      ResetLastError();
      int res = WebRequest("POST", m_webhookUrl, requestHeaders, 10000, fullPayload, resultData, resultHeaders);
      
      if(res < 200 || res >= 300)
      {
         PrintFormat("[Discord] Multipart POST failed: HTTP %d, Error: %d. Retrying text fallback...", res, GetLastError());
         return SendTextMessage(message);
      }

      FileDelete(imageFilename);
      return true;
   }
};
