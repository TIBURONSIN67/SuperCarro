#include <Arduino.h>
#include "HardwareController.h"
#include "WebServerController.h"

// Pines definidos
#define PIN_MOTOR_LEFT_FORWARD 13    // Motor izquierdo hacia adelante
#define PIN_MOTOR_RIGHT_FORWARD 12   // Motor derecho hacia adelante
#define PIN_MOTOR_LEFT_BACKWARD 14   // Motor izquierdo hacia atrás
#define PIN_MOTOR_RIGHT_BACKWARD 27  // Motor derecho hacia atrás
#define PIN_LIGHT 2                  // Pin para la luz
#define PIN_PWM1 25                   // Pin para el control de velocidad PWM
#define PIN_PWM2 35                   // Pin para el control de velocidad PWM

// Configuración de la red WiFi
const char *SSID = "Super Lambo";
const char *PASSWORD = "12345678";

// Instancia del controlador de hardware
HardwareController hardwareController(PIN_MOTOR_LEFT_FORWARD, PIN_MOTOR_RIGHT_FORWARD, PIN_MOTOR_LEFT_BACKWARD, PIN_MOTOR_RIGHT_BACKWARD, PIN_LIGHT, PIN_PWM1, PIN_PWM2);

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
