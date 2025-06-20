#ifndef WEBSOCKETCLIENTHANDLER_H
#define WEBSOCKETCLIENTHANDLER_H

#include <ArduinoJson.h>
#include <WebSocketsClient.h>
#include <WiFi.h>

class WebSocketClientHandler {
public:
    WebSocketClientHandler();

    // Parámetros para conectar al servidor Godot
    void begin(const char* host, const char* path, const char* origin, uint16_t port, const char* protocol);
    void loop();

private:
    WebSocketsClient webSocket;

    // Nuevo callback estático con firma correcta
    static void _webSocketEventStatic(WStype_t type, uint8_t* payload, size_t length);

    // Método para manejar evento
    void webSocketEvent(WStype_t type, uint8_t* payload, size_t length);

    // Puntero a instancia para usar en callback estático
    static WebSocketClientHandler* instance;
};

#endif
