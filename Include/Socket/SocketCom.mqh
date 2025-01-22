//+------------------------------------------------------------------+
//| Class to manage sockets with SignalR support                     |
//+------------------------------------------------------------------+
class CSocket
  {
private:
   string            m_server;
   uint              m_port;
   uint              m_timeout;
   int               m_socket;
   string            SockReceive();
   bool              SockSend(string request);
   string            SendReceive(string request);

public:
                     CSocket(string server, uint port, uint timeout); // Constructor
                    ~CSocket();                                       // Destructor

   string            PerformHandshake(string endpoint);              // Perform SignalR handshake
   string            ExtractConnectionId(string jsonResponse);       // Extract connection ID from JSON
   string            SendCommand(string hubPath, string jsonCommand);// Send a SignalR command
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSocket::CSocket(string server, uint port, uint timeout)
  {
   m_server = server;
   m_port = port;
   m_timeout = timeout;
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSocket::~CSocket()
  {

  }

//+------------------------------------------------------------------+
//| Perform HTTP POST for SignalR handshake                          |
//+------------------------------------------------------------------+
string CSocket::PerformHandshake(string endpoint)
  {
   string request =
      "POST " + endpoint + " HTTP/1.1\r\n" +
      "Host: " + m_server + "\r\n" +
      "Content-Type: application/json\r\n" +
      "Content-Length: 0\r\n" +
      "Connection: close\r\n\r\n";

   return SendReceive(request);
  }

//+------------------------------------------------------------------+
//| Extract connection ID from SignalR handshake response            |
//+------------------------------------------------------------------+
string CSocket::ExtractConnectionId(string jsonResponse)
  {
   int start = StringFind(jsonResponse, "\"connectionId\":\"");
   if (start == -1)
      return "";

   start += StringLen("\"connectionId\":\"");
   int end = StringFind(jsonResponse, "\"", start);
   if (end == -1)
      return "";

   return StringSubstr(jsonResponse, start, end - start);
  }

//+------------------------------------------------------------------+
//| Send SignalR command                                             |
//+------------------------------------------------------------------+
string CSocket::SendCommand(string hubPath, string jsonCommand, string connectionId)
{
   // Append the connection ID as a query parameter
   string fullPath = hubPath + "?id=" + connectionId;

   // Form the HTTP POST request
   string request =
      "POST " + fullPath + " HTTP/1.1\r\n" +
      "Host: " + m_server + "\r\n" +
      "Content-Type: application/json\r\n" +
      "Content-Length: " + IntegerToString(StringLen(jsonCommand)) + "\r\n" +
      "Connection: close\r\n\r\n" +
      jsonCommand;

   return SendReceive(request);
}

//+------------------------------------------------------------------+
//| SocketSend implementation                                        |
//+------------------------------------------------------------------+
bool CSocket::SockSend(string request)
  {
   // Open socket
   m_socket = SocketCreate();
   if (m_socket != INVALID_HANDLE)
   {
      if (!SocketConnect(m_socket, m_server, m_port, m_timeout))
      {
         Print("Cannot connect to " + m_server + ":" + IntegerToString(m_port) +
               " Error: " + IntegerToString(GetLastError()));
         return false;
      }
   }
   else
   {
      Print("Failed to create socket. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Send data
   char req[];
   int len = StringToCharArray(request, req) - 1;
   if (len <= 0)
   {
      Print("No data to send.");
      return false;
   }

   return SocketSend(m_socket, req, len) == len;
  }

//+------------------------------------------------------------------+
//| SocketReceive implementation                                     |
//+------------------------------------------------------------------+
string CSocket::SockReceive()
  {
   char rsp[];
   string result = "";
   uint timeout_check = GetTickCount() + m_timeout;

   while (GetTickCount() < timeout_check)
   {
      int len = SocketIsReadable(m_socket);
      if (len > 0)
      {
         int rsp_len = SocketRead(m_socket, rsp, len, m_timeout);
         if (rsp_len > 0)
            result += CharArrayToString(rsp, 0, rsp_len);
      }
   }

   SocketClose(m_socket);
   return result;
  }

//+------------------------------------------------------------------+
//| Combine Send and Receive                                         |
//+------------------------------------------------------------------+
string CSocket::SendReceive(string request)
  {
   if (SockSend(request))
      return SockReceive();
   return "";
  }
