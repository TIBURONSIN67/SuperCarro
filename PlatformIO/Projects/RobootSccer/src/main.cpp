#include <Arduino.h>
#include "WebSocketServerHandler.h"

// Ajusta SSID y contraseña de tu punto de acceso WiFi
const char* ssid = "MiAP_Robot2";
const char* password = "12345678";

WebSocketServerHandler webSocketServer(81, Serial); // Puerto WebSocket y Serial para debug

void setup() {
  // Iniciar el WebSocket y el AP
  Serial.begin(115200);
  webSocketServer.begin(ssid, password);
}

void loop() {
  // Mantener el WebSocket escuchando
  webSocketServer.loop();
}
