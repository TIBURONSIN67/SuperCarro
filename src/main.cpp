#include <Arduino.h>
#include "HardwareController.h"
#include "WebServerController.h"
#include <ESP32Servo.h>

// Pines definidos
#define PIN_MOTOR_LEFT_FORWARD 26     // Motor izquierdo hacia adelante
#define PIN_MOTOR_RIGHT_FORWARD 25     // Motor derecho hacia adelante
#define PIN_MOTOR_LEFT_BACKWARD 27     // Motor izquierdo hacia atrás
#define PIN_MOTOR_RIGHT_BACKWARD 33    // Motor derecho hacia atrás
#define PIN_LIGHT 2                    // Pin para la luz
#define PIN_TRIGGER 5                  // Pin del trigger del sensor ultrasónico
#define PIN_ECHO 19                     // Pin del echo del sensor ultrasónico
#define PIN_SERVO 13                    //PIN PARA ELÑ SERVO

// Configuración de la red WiFi
const char *SSID = "Super Lambo";
const char *PASSWORD = "12345678";

const char* WebSocketServerHost = "192.168.60.59";
const uint16_t WebSocketServerPort = 5000;

String state; // Estado actual
String previousState; // Estado anterior

// Instancia del controlador de hardware
HardwareController hardwareController(
    PIN_MOTOR_LEFT_FORWARD, 
    PIN_MOTOR_RIGHT_FORWARD, 
    PIN_MOTOR_LEFT_BACKWARD, 
    PIN_MOTOR_RIGHT_BACKWARD, 
    PIN_LIGHT
);

// Instancia del controlador del servidor web
WebSocketController webSocketController(
    SSID, 
    PASSWORD,
    WebSocketServerHost,
    WebSocketServerPort
);

// Función para medir la distancia usando el sensor ultrasónico
long measureDistance() {
    digitalWrite(PIN_TRIGGER, LOW); // Asegurarse de que el trigger esté en LOW
    delayMicroseconds(2);
    
    digitalWrite(PIN_TRIGGER, HIGH); // Enviar un pulso
    delayMicroseconds(10);
    digitalWrite(PIN_TRIGGER, LOW); // Terminar el pulso

    long duration = pulseIn(PIN_ECHO, HIGH); // Medir la duración del eco
    return duration * 0.034 / 2; // Convertir a distancia en cm
}


void setup() {
    Serial.begin(115200);

    // Configurar pines del sensor ultrasónico
    pinMode(PIN_TRIGGER, OUTPUT);
    pinMode(PIN_ECHO, INPUT);
    pinMode(PIN_SERVO, OUTPUT);
    //servo
    // Iniciar hardware
    hardwareController.begin();

    // Iniciar servidor web
    webSocketController.begin();
}

void loop() {
    webSocketController.loop();
    state = webSocketController.get_state(); // Obtener el estado actual

    // Medir distancia
    long distance = measureDistance();

    if ((previousState == "FORWARD") && (distance < 40)){
        Serial.println("muro cerca");
        hardwareController.stop();
    }
    if (state != previousState) {
        if (state == "FORWARD") {
            hardwareController.Forward();
        } else if (state == "BACKWARD") {
            hardwareController.Backward();
        } else if (state == "STOP") {
            hardwareController.stop();
        } else if (state == "LEFT") {
            hardwareController.turnLeft();
        } else if (state == "RIGHT") {
            hardwareController.turnRight();
        } else if (state == "LIGHT_ON") {
            hardwareController.lightOn();
        } else if (state == "LIGHT_OFF") {
            hardwareController.lightOff();
        }
    }
        // Actualizar el estado anterior
    previousState = state;
    delay(10); // Pequeño retraso para evitar bucles rápidos
}
