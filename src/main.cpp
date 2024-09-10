#include <Arduino.h>
#include "HardwareController.h"
#include "WebServerController.h"

// Pines definidos
#define PIN_LEFT 13
#define PIN_RIGHT 12
#define PIN_GO 14
#define PIN_BACK 27
#define PIN_LIGHT 2
#define PIN_PWM 25

// Configuración de la red WiFi
const char *SSID = "Super Lambo";
const char *PASSWORD = "12345678";

// Instancia del controlador de hardware
HardwareController hardwareController(PIN_LEFT, PIN_RIGHT, PIN_GO, PIN_BACK, PIN_LIGHT, PIN_PWM);

// Instancia del controlador del servidor web
WebServerController webServerController(hardwareController);

void setup() {
    Serial.begin(115200);

    // Iniciar hardware
    hardwareController.begin();

    // Iniciar WiFi
    WiFi.softAP(SSID, PASSWORD);
    Serial.println("WiFi iniciado");

    // Iniciar servidor web
    webServerController.begin();
}

void loop() {
    // No es necesario hacer nada aquí
}
