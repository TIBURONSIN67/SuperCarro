#include "WebSocketServerHandler.h"
#include "Controller.h"
#include <WiFi.h>
#include <ArduinoJson.h>

Controller controller(2, 5, 26, 12, 14, 25); // Ajusta pines si es necesario



WebSocketServerHandler* WebSocketServerHandler::instance = nullptr;

WebSocketServerHandler::WebSocketServerHandler(uint16_t port): webSocket(port){
    instance = this;
}

#include <IPAddress.h>

void WebSocketServerHandler::begin(const char* ssid, const char* password) {
    ssidGlobal = ssid;
    passwordGlobal = password;

    Serial.setDebugOutput(true);

    // IP estática deseada
    IPAddress local_IP(192, 168, 1, 100);       // Cambia esto según tu red
    IPAddress gateway(192, 168, 36, 199);          // Generalmente la IP del router
    IPAddress subnet(255, 255, 255, 0);         // Máscara de subred

    // Solo IP, puerta de enlace y máscara
    if (!WiFi.config(local_IP, gateway, subnet)) {
        Serial.println("⚠️ Error al configurar la IP estática");
    }


    int intento = 1;
    while (WiFi.status() != WL_CONNECTED) {
        Serial.printf("⏳ Intento %d: Conectando a WiFi...\n", intento);

        WiFi.disconnect(true);
        WiFi.mode(WIFI_STA);
        WiFi.begin(ssidGlobal, passwordGlobal);

        delay(1000);

        if (WiFi.status() != WL_CONNECTED) {
            Serial.println("❌ No se pudo conectar. Reintentando...");
            delay(1000);
            intento++;
        }
    }

    Serial.println("✅ Conectado a la red WiFi.");
    Serial.print("🌐 Dirección IP: ");
    Serial.println(WiFi.localIP());


    // ==== CÓDIGO COMENTADO PARA CREAR ACCESS POINT ====
    /*
    WiFi.mode(WIFI_AP);
    bool result = WiFi.softAP(ssidGlobal, passwordGlobal);

    if (result) {
        Serial.println("✅ Punto de acceso creado exitosamente.");
        Serial.print("📡 Dirección IP del AP: ");
        Serial.println(WiFi.softAPIP());
    } else {
        Serial.println("❌ Error al crear el punto de acceso.");
    }
    */

    controller.begin();
    webSocket.begin();
    webSocket.onEvent(_webSocketEventStatic);

    wasConnected = true;
}



void WebSocketServerHandler::loop() {
    webSocket.loop();
}




void WebSocketServerHandler::_webSocketEventStatic(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
    if (instance) {
        instance->webSocketEvent(num, type, payload, length);
    }
}

void WebSocketServerHandler::webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
    switch (type) {
        case WStype_DISCONNECTED:
            Serial.printf("[%u] Disconnected!\n", num);
            controller.disconnected();
            break;

        case WStype_CONNECTED: {
            IPAddress ip = webSocket.remoteIP(num);
            Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\n", num, ip[0], ip[1], ip[2], ip[3], payload);
            webSocket.sendTXT(num, "Connected");
            break;
        }

        case WStype_TEXT: {
            // Intentamos interpretar el payload como JSON
            StaticJsonDocument<128> doc;
            DeserializationError error = deserializeJson(doc, payload, length);

            if (!error && doc.containsKey("left") && doc.containsKey("right")) {
                int leftSpeed = doc["left"];
                int rightSpeed = doc["right"];
                Serial.printf("Recibido JSON: left=%d, right=%d\n", leftSpeed, rightSpeed);
                controller.updateSpeeds(leftSpeed, rightSpeed);

                char response[64];
                snprintf(response, sizeof(response), "Vel izq: %d, der: %d", leftSpeed, rightSpeed);
                webSocket.sendTXT(num, response);
            } else {
                //EN CASO DE QUE EL JSON NO SEA VALIDO
                Serial.print("el JSON no es valid");
            }
            break;
        }

        case WStype_BIN:
            Serial.printf("[%u] get binary length: %u\n", num, length);
            hexdump(payload, length);
            break;

        default:
            break;
    }
}

void WebSocketServerHandler::hexdump(const void* mem, uint32_t len, uint8_t cols) {
    const uint8_t* src = (const uint8_t*) mem;
    Serial.printf("\n[HEXDUMP] Address: 0x%08X len: 0x%X (%d)", (ptrdiff_t)src, len, len);
    for (uint32_t i = 0; i < len; i++) {
        if (i % cols == 0) {
            Serial.printf("\n[0x%08X] 0x%08X: ", (ptrdiff_t)src, i);
        }
        Serial.printf("%02X ", *src++);
    }
    Serial.printf("\n");
}
