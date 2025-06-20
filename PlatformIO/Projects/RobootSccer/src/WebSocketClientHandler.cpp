#include "WebSocketClientHandler.h"
#include "Controller.h"

// Inicializa el puntero estático
WebSocketClientHandler* WebSocketClientHandler::instance = nullptr;

Controller controller(2, 5, 26, 12, 14, 25); // Ajusta pines si es necesario

WebSocketClientHandler::WebSocketClientHandler() {
    instance = this;
}

void WebSocketClientHandler::begin(const char* host, const char* path, const char* origin, uint16_t port, const char* protocol) {
    // Conectar al servidor Godot
    webSocket.begin(host, port, path, protocol);
    webSocket.onEvent(_webSocketEventStatic);  // callback con nueva firma
    webSocket.setReconnectInterval(5000);
    controller.begin();

}

void WebSocketClientHandler::loop() {
    webSocket.loop();
}

// Callback estático que redirige al método de instancia
void WebSocketClientHandler::_webSocketEventStatic(WStype_t type, uint8_t* payload, size_t length) {
    if (instance != nullptr) {
        instance->webSocketEvent(type, payload, length);
    }
}

void WebSocketClientHandler::webSocketEvent(WStype_t type, uint8_t* payload, size_t length) {
    switch (type) {
        case WStype_CONNECTED:
            Serial.println("WebSocket Connected to Godot server");
            webSocket.sendTXT(R"({"type":"register", "role":"carro"})");
            break;

        case WStype_DISCONNECTED:
            Serial.println("WebSocket Disconnected");
            break;

        case WStype_TEXT: {
            String msg = String((char*)payload);
            Serial.print("Received text: ");
            Serial.println(msg);

            // Si es un ping, responder y terminar
            if (msg == "ping") {
                Serial.println("📩 Ping recibido, respondiendo pong...");
                webSocket.sendTXT("pong");
                break;  // ✅ No seguir intentando parsear JSON innecesariamente
            }

            // Si no es "ping", asumimos que es JSON válido
            StaticJsonDocument<128> doc;
            auto error = deserializeJson(doc, payload, length);
            if (!error) {
                if (doc["left"].is<float>() && doc["right"].is<float>()) {
                    float leftValue = doc["left"].as<float>();
                    float rightValue = doc["right"].as<float>();
                    Serial.printf("left: %.2f, right: %.2f\n", leftValue, rightValue);
                    controller.updateSpeeds(leftValue, rightValue);
                } else {
                    Serial.println("⚠️ JSON no contiene 'left' y 'right' como floats");
                }
            } else {
                Serial.println("❌ Error al parsear JSON recibido");
            }
            break;
        }


        case WStype_BIN:
            Serial.println("Received binary data (no procesado)");
            break;

        case WStype_ERROR:
            Serial.println("WebSocket error");
            break;

        default:
            break;
    }
}
