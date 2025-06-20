#include <WiFi.h>
#include "WebSocketClientHandler.h"

const char* ssid = "SERVER";
const char* password = "12345678";

WebSocketClientHandler wsClient;

void setup() {
    Serial.begin(115200);
    WiFi.begin(ssid, password);

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    Serial.println();
    Serial.println("WiFi Connected.");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    WiFi.setSleep(false);
    // Conectar al servidor WebSocket Godot (IP + puerto + path)
    wsClient.begin("192.168.93.146", "/ws", nullptr, 9080, nullptr);
}

void loop() {
    wsClient.loop();
}
