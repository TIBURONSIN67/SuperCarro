#ifndef WEBSERVER_CONTROLLER_H
#define WEBSERVER_CONTROLLER_H

#include <ESPAsyncWebServer.h>
#include <SPIFFS.h>
#include <ArduinoJson.h>
#include "HardwareController.h"

#define JSON_BUFFER_SIZE 512 // Define el tamaño del buffer JSON

class WebServerController {
public:
    WebServerController(HardwareController &hardwareController) : server(80), hardwareController(hardwareController) {}

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

        // Configura la ruta para manejar solicitudes POST
        server.on("/control", HTTP_POST, [](AsyncWebServerRequest *request) {
            // No es necesario enviar una respuesta aquí, ya que se maneja en el callback
        }, NULL, [this](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
            this->handlePostRequest(request, data, len, index, total);
        });

        // Manejo de rutas no encontradas
        server.onNotFound([](AsyncWebServerRequest *request) {
            request->send(404, "text/plain", "Not Found");
        });

        // Inicia el servidor
        server.begin();
        Serial.println("Servidor HTTP iniciado");
    }

private:
    AsyncWebServer server;
    HardwareController &hardwareController;

    void handlePostRequest(AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
        static String body = "";

        if (index == 0) {
            body = "";
        }

        body += String((char*)data, len);

        if (index + len == total) {
            DynamicJsonDocument doc(JSON_BUFFER_SIZE);
            DeserializationError error = deserializeJson(doc, body);

            if (error) {
                Serial.println("Error al deserializar JSON: " + String(error.c_str()));
                request->send(400, "text/plain", "Error al deserializar JSON");
                return;
            }

            String state = doc["state"].as<String>();
            String gameMode = doc["gameMode"].as<String>();
            int speed = 255; // Valor predeterminado

            if (doc.containsKey("speed")) {
                speed = doc["speed"].as<int>();
                if (speed < 0) speed = 0;
                if (speed > 255) speed = 255;
            }

            Serial.print("Estado recibido: ");
            Serial.println(state);
            Serial.print("Velocidad recibida: ");
            Serial.println(speed);

            hardwareController.control(state,speed);

            request->send(200, "text/plain", "Datos recibidos correctamente");
        }
    }
};

#endif
