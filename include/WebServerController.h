#ifndef WEBSERVER_CONTROLLER_H
#define WEBSERVER_CONTROLLER_H

#include <ESPAsyncWebServer.h>
#include <SPIFFS.h>
#include <ArduinoJson.h>
#include <string>
#include "HardwareController.h"

#define JSON_BUFFER_SIZE 512 // Define el tamaño del buffer JSON

String state = "STOP"; // Valor por defecto del estado

class WebServerController {
public:
    WebServerController(HardwareController &hardwareController) 
        : server(80), ws("/ws"), hardwareController(hardwareController) {}

    void begin() {
        // Inicia SPIFFS
        if (!SPIFFS.begin(true)) {
            Serial.println("Error al montar SPIFFS");
            return;
        }
        Serial.println("SPIFFS montado correctamente");

        // Configura las rutas del servidor
        server.on("/", HTTP_GET, [](AsyncWebServerRequest *request) {
            request->send(SPIFFS, "/index.html", "text/html");
        });
        server.on("/styles.css", HTTP_GET, [](AsyncWebServerRequest *request) {
            request->send(SPIFFS, "/styles.css", "text/css");
        });
        server.on("/main.js", HTTP_GET, [](AsyncWebServerRequest *request) {
            request->send(SPIFFS, "/main.js", "application/javascript");
        });

        // Configura WebSocket
        ws.onEvent([this](AsyncWebSocket *server, AsyncWebSocketClient *client, 
                          AwsEventType type, void *arg, uint8_t *data, size_t len) {
            this->handleWebSocketEvent(server, client, type, arg, data, len);
        });
        server.addHandler(&ws);

        // Manejo de rutas no encontradas
        server.onNotFound([](AsyncWebServerRequest *request) {
            request->send(404, "text/plain", "Not Found");
        });

        // Inicia el servidor
        server.begin();
        Serial.println("Servidor HTTP y WebSocket iniciado");
    }

    void sendWebSocketMessage(const String& message) {
        ws.textAll(message); // Enviar mensaje a todos los clientes conectados
    }

private:
    AsyncWebServer server;
    AsyncWebSocket ws;
    HardwareController &hardwareController;

    void handleWebSocketEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, 
    AwsEventType type, void *arg, uint8_t *data, size_t len) {
        if (type == WS_EVT_CONNECT) {
            Serial.printf("Cliente WebSocket conectado: %u\n", client->id());

            // Enviar el estado y la velocidad actuales al cliente conectado
            DynamicJsonDocument doc(JSON_BUFFER_SIZE);
            doc["state"] = state;
            String jsonString;
            serializeJson(doc, jsonString);
            client->text(jsonString);
        } else if (type == WS_EVT_DISCONNECT) {
            Serial.printf("Cliente WebSocket desconectado: %u\n", client->id());
        } else if (type == WS_EVT_DATA) {
            handleWebSocketMessage(client, data, len);
        }
    }

    void handleWebSocketMessage(AsyncWebSocketClient *client, uint8_t *data, size_t len) {
        String message = String((char*)data).substring(0, len);
        Serial.printf("Mensaje WebSocket recibido: %s\n", message.c_str());

        // Procesar el JSON recibido
        DynamicJsonDocument doc(JSON_BUFFER_SIZE);
        DeserializationError error = deserializeJson(doc, message);

        if (error) {
            Serial.println("Error al deserializar JSON: " + String(error.c_str()));
            client->text("Error al deserializar JSON");
            return;
        }

        // Manejar los datos recibidos
        if (doc.containsKey("state")) {
            state = doc["state"].as<String>();
        }

        // Controlar el hardware basado en los datos recibidos
        hardwareController.control(state);

        // Responder con éxito
        client->text("Datos recibidos correctamente");
    }
};

#endif
