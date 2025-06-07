#ifndef WEBSOCKETSERVERHANDLER_H
#define WEBSOCKETSERVERHANDLER_H

#include <Arduino.h>
#include <WiFi.h>
#include <WiFiMulti.h>
#include <WiFiClientSecure.h>
#include <WebSocketsServer.h>

class WebSocketServerHandler {
public:
    WebSocketServerHandler(uint16_t port, HardwareSerial& serialRef);
    void begin(const char* ssid, const char* password);
    void loop();

private:
    WiFiMulti wifiMulti;
    WebSocketsServer webSocket;
    HardwareSerial& serial;
    
    void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length);
    void hexdump(const void* mem, uint32_t len, uint8_t cols = 16);

    static WebSocketServerHandler* instance; // Para acceder desde static callback
    static void _webSocketEventStatic(uint8_t num, WStype_t type, uint8_t * payload, size_t length);
};

#endif
