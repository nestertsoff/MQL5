//+------------------------------------------------------------------+
//|                                                        WSMQL.mqh |
//|                                     Copyright 2022, Nikki Samson |
//|                       https://www.mql5.com/en/users/nikkirachael |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Nikki Samson"
#property link      "https://www.mql5.com/en/users/nikkirachael"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define WSHANDLE  ulong

//--- websocket close code
enum ENUM_CLOSE_CODE {               // possible reasons for disconnecting sent with a close frame
   NORMAL_CLOSE = 1000,            // normal closure initiated by choice
   GOING_AWAY_CLOSE,               // close code for client navigating away from end point, used in browsers
   PROTOCOL_ERROR_CLOSE,           // close caused by some violation of a protocol, usually application defined
   FRAME_TYPE_ERROR_CLOSE,         // close caused by an endpoint receiving frame type that is not supportted or allowed
   UNDEFINED_CLOSE_1,              // close code is not defined by websocket protocol
   UNUSED_CLOSE_1,                 // unused
   UNUSED_CLOSE_2,                 // values
   ENCODING_TYPE_ERROR_CLOSE,      // close caused data in message is of wrong encoding type, usually referring to strings
   APP_POLICY_ERROR_CLOSE,         // close caused by violation of user policy
   MESSAGE_SIZE_ERROR_CLOSE,       // close caused by endpoint receiving message that is too large
   EXTENSION_ERROR_CLOSE,          // close caused by non compliance to or no support for specified extension of websocket protocol
   SERVER_SIDE_ERROR_CLOSE,        // close caused by some error that occurred on the server
   UNUSED_CLOSE_3 = 1015,          // unused
};

//--- websocket state
enum ENUM_WEBSOCKET_STATE {
   CLOSED = 0,
   CLOSING,
   CONNECTING,
   CONNECTED
};

//--- logging levels
enum ENUM_LOG_LEVEL {
   LOG_LEVEL_NONE,
   LOG_LEVEL_DEBUG,
   LOG_LEVEL_INFO,
   LOG_LEVEL_ERROR
};
//+------------------------------------------------------------------+
// Callback Handler
//+------------------------------------------------------------------+
typedef void(*OnWebsocketMessage)(string);
typedef void(*OnWebsocketBinaryMessage)(uchar& []);
//---
class WSCBHandler {
public:
   OnWebsocketMessage callback;
   OnWebsocketMessage pingCallback;
   OnWebsocketMessage pongCallback;
   OnWebsocketMessage closeCallback;
   OnWebsocketBinaryMessage binaryCallback;
};
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
#import "Native Websocket.ex5"
WSHANDLE Initialize(void);
void ZeroHandle(void);
ENUM_WEBSOCKET_STATE ClientState(WSHANDLE handle);
void SetMaxSendSize(WSHANDLE handle, int max_send_size);
bool SetOnMessageHandler(const WSHANDLE handle, WSCBHandler& handler);
bool SetOnPingHandler(const WSHANDLE handle, WSCBHandler& handler);
bool SetOnPongHandler(const WSHANDLE handle, WSCBHandler& handler);
bool SetOnCloseHandler(const WSHANDLE handle, WSCBHandler& handler);
bool SetOnBinaryMessageHandler(const WSHANDLE handle, WSCBHandler& handler);
bool Connect(const WSHANDLE handle, const string url, const uint port = 443, const uint timeout = 5000, bool use_tls = true, ENUM_LOG_LEVEL log_level = LOG_LEVEL_NONE);
bool ConnectUnsecured(const WSHANDLE handle, const string url, const uint port = 80, const uint timeout = 5000, ENUM_LOG_LEVEL log_level = LOG_LEVEL_NONE);
bool ConnectSecured(const WSHANDLE handle, const string url, const uint port = 443, const uint timeout = 5000, ENUM_LOG_LEVEL log_level = LOG_LEVEL_NONE);
bool Disconnect(WSHANDLE handle, ENUM_CLOSE_CODE close_code = NORMAL_CLOSE, const string msg = "");
int  SendString(WSHANDLE handle, const string message);
int  SendData(WSHANDLE handle, uchar& message_buffer[]);
int  SendPong(WSHANDLE handle, const string msg = "");
int  SendPing(WSHANDLE handle, const string msg);
uint ReadString(WSHANDLE handle, string& out);
uint ReadBinary(WSHANDLE handle, uchar& out[]);
uint ReadStrings(WSHANDLE handle, string& out[]);
uint OnStringMessages(WSHANDLE handle);
uint OnBinaryMessages(WSHANDLE handle);
uint OnMessages(WSHANDLE handle);
#import
//+------------------------------------------------------------------+
// Here is a wrapper class for the methods above
//+------------------------------------------------------------------+
class CWebSocketClient {
private:
   WSHANDLE handle;
   WSCBHandler handler;

public:
   CWebSocketClient(void) {
      handle = ::Initialize();
   }
   ~CWebSocketClient(void) {
      ::Disconnect(handle);
   }
   bool Initialized(void) {
      return handle != 0;
   }
   ENUM_WEBSOCKET_STATE State(void) {
      return ::ClientState(handle);
   }
   void SetMaxSendSize(int max_send_size) {
      ::SetMaxSendSize(handle, max_send_size);
   }

   bool SetOnMessageHandler(OnWebsocketMessage callback) {
      handler.callback = callback;
      return ::SetOnMessageHandler(handle, handler);
   }

   bool SetOnPingHandler(OnWebsocketMessage callback) {
      handler.pingCallback = callback;
      return ::SetOnPingHandler(handle, handler);
   }

   bool SetOnPongHandler(OnWebsocketMessage callback) {
      handler.pongCallback = callback;
      return ::SetOnPongHandler(handle, handler);
   }

   bool SetOnCloseHandler(OnWebsocketMessage callback) {
      handler.closeCallback = callback;
      return ::SetOnCloseHandler(handle, handler);
   }

   bool SetOnBinaryMessageHandler(OnWebsocketBinaryMessage callback) {
      handler.binaryCallback = callback;
      return ::SetOnBinaryMessageHandler(handle, handler);
   }

   bool Connect(const string url, const uint port = 443, const uint timeout = 5000, bool use_tls = true, ENUM_LOG_LEVEL log_level = LOG_LEVEL_NONE) {
      return ::Connect(handle, url, port, timeout, use_tls, log_level);
   }

   //+------------------------------------------------------------------+
   bool ConnectUnsecured(const string url, const uint port = 80, const uint timeout = 5000, ENUM_LOG_LEVEL log_level = LOG_LEVEL_NONE) {
      return ::ConnectUnsecured(handle, url, port, timeout, log_level);
   }
   //+------------------------------------------------------------------+
   bool ConnectSecured(const string url, const uint port = 443, const uint timeout = 5000, ENUM_LOG_LEVEL log_level = LOG_LEVEL_NONE) {
      return ::ConnectSecured(handle, url, port, timeout, log_level);
   }

   bool Disconnect(ENUM_CLOSE_CODE close_code = NORMAL_CLOSE, const string msg = "") {
      return ::Disconnect(handle, close_code, msg);
   }
   int  SendString(const string message) {
      return ::SendString(handle, message);
   }
   int  SendData(uchar& message_buffer[]) {
      return ::SendData(handle, message_buffer);
   }
   int  SendPong(const string msg = "") {
      return ::SendPong(handle, msg);
   }
   int  SendPing(const string msg) {
      return ::SendPing(handle, msg);
   }
   uint ReadString(string& out) {
      return ::ReadString(handle, out);
   }
   uint ReadStrings(string& out[]) {
      return ::ReadStrings(handle, out);
   }
   uint OnStringMessages() {
      return ::OnStringMessages(handle);
   }
   uint OnBinaryMessages() {
      return ::OnBinaryMessages(handle);
   }
   uint OnMessages() {
      return ::OnMessages(handle);
   }
};