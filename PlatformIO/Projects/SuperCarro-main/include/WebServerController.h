#ifndef WEBSERVER_CONTROLLER_H
#define WEBSERVER_CONTROLLER_H

#include <ArduinoWebsockets.h>
#include <ArduinoJson.h>
#include <Arduino.h>
#include <WiFi.h>
#include <string>

using namespace websockets;

WebsocketsClient client;

class WebSocketController {
public:
    // Constructor de la clase
    WebSocketController(
        const char* ssid, 
        const char* password, 
        const char* websocketHost, 
        const uint16_t websocketServerPort
    ) : 
    SSID(ssid), 
    PASSWORD(password), 
    WebSocketServerHost(websocketHost), 
    WebSocketServerPort(websocketServerPort) {}

    // Método para iniciar la conexión WiFi y WebSocket
    void begin() {
        WiFi.begin(SSID, PASSWORD);

        // Intento de conexión a WiFi con reintentos
        for (int i = 0; i < 10 && WiFi.status() != WL_CONNECTED; i++) {
            Serial.print(".");
            delay(1000);
        }

        // Comprobación de conexión WiFi
        if (WiFi.status() == WL_CONNECTED) {
            Serial.print("Se estableció la conexión a: ");
            Serial.println(SSID);
        } else {
            Serial.print("No se pudo conectar a: ");
            Serial.println(SSID);
            return;
        }

        // Intentar conectarse al servidor de Websockets
        bool connected = client.connect(WebSocketServerHost, WebSocketServerPort, "/ws");
        if (connected) {
            Serial.println("¡Conectado al servidor WebSocket!");
        } else {
            Serial.println("¡No se pudo conectar al servidor WebSocket!");
        }

        // Ejecuta un callback cuando se reciben mensajes
        // Dentro de la configuración del callback onMessage
        client.onMessage([&](WebsocketsMessage message){
            // Crear un objeto JSON en memoria
            StaticJsonDocument<200> jsonDoc;
            // Analizar el mensaje JSON
            DeserializationError error = deserializeJson(jsonDoc, message.data());
            // Verificar si hubo un error al analizar el JSON
            if (error) {
                Serial.print("Error al analizar JSON: ");
                Serial.println(error.c_str());
                return;
            }
            // Extraer el valor de "state" del JSON
            state = jsonDoc["state"];
            if (state) {
                Serial.print("Estado recibido: ");
                Serial.println(state);
            } else {
                Serial.println("El campo 'state' no está presente en el JSON.");
            }
        });
    };

    void loop() {
        // Permite al cliente de Websockets comprobar mensajes entrantes
        if(client.available()) {
            client.poll();
        }
    };

    const char* get_state(){
        return state;
    }

    private:
        const char* SSID;
        const char* PASSWORD;
        const char* WebSocketServerHost;
        const uint16_t WebSocketServerPort;
        const char* state;
};

#endif
