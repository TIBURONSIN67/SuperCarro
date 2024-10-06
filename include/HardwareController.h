#ifndef HARDWARE_CONTROLLER_H
#define HARDWARE_CONTROLLER_H

#include <Arduino.h>

class HardwareController {
public:
    HardwareController(int pinMotorLeftForward, int pinMotorRightForward, int pinMotorLeftBackward, int pinMotorRightBackward, int pinLight, int velocity_fordward, int velocity_backward)
        : PIN_MOTOR_LEFT_FORWARD(pinMotorLeftForward), PIN_MOTOR_RIGHT_FORWARD(pinMotorRightForward), 
          PIN_MOTOR_LEFT_BACKWARD(pinMotorLeftBackward), PIN_MOTOR_RIGHT_BACKWARD(pinMotorRightBackward), 
          PIN_LIGHT(pinLight), PIN_VELOCITY_FORWARD(velocity_fordward),PIN_VELOCITY_BACKWARD(velocity_backward), currentState("") {}

    void begin() {
        pinMode(PIN_MOTOR_LEFT_FORWARD, OUTPUT);
        pinMode(PIN_MOTOR_RIGHT_FORWARD, OUTPUT);
        pinMode(PIN_MOTOR_LEFT_BACKWARD, OUTPUT);
        pinMode(PIN_MOTOR_RIGHT_BACKWARD, OUTPUT);
        pinMode(PIN_LIGHT, OUTPUT);
        pinMode(PIN_VELOCITY_FORWARD, OUTPUT);
        pinMode(PIN_VELOCITY_BACKWARD,OUTPUT);

        // Inicializa los pines en LOW
        stop();
        setLight(false);
    }

    // Función para controlar el movimiento
    void control(String state) {

        if (state == "GO") {
            // Avanza en línea recta
            digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
            digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
            digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH);
            digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH);
        } 
        else if (state == "BACK") {
            // Retrocede en línea recta
            digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
            digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
            digitalWrite(PIN_MOTOR_LEFT_BACKWARD, HIGH);
            digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, HIGH);
        } 
        else if (state == "LEFT") {  // Si no se está avanzando ni retrocediendo (el robot está detenido), gira sobre su propio eje
            Serial.print("girando a la izquierda");
            // Gira sobre su eje hacia la izquierda
            digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
            digitalWrite(PIN_MOTOR_LEFT_BACKWARD, HIGH); // Motor izquierdo hacia atrás
            digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH); // Motor derecho hacia adelante
            digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
        } 
        else if (state == "RIGHT") {
            Serial.print("girando a la derecha");
            // Gira sobre su eje hacia la derecha
            digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH); // Motor izquierdo hacia adelante
            digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
            digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
            digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, HIGH); // Motor derecho hacia atrás
        }
        else if (state == "STOP" || state == "NONE") {
            // Avanza en línea recta
            digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
            digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
            digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
            digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        } 
        else if (state == "LIGHT_ON") {
            setLight(true);
        }
        else if (state == "LIGHT_OFF") {
            setLight(false);
        } 
    } 
    // Detiene el movimiento de todos los motores
    void stop() {
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
    }
    // Controla la luz (on/off)
    void setLight(bool on) {
        digitalWrite(PIN_LIGHT, on ? HIGH : LOW);
    }

    private:
        int PIN_MOTOR_LEFT_FORWARD, PIN_MOTOR_RIGHT_FORWARD, PIN_MOTOR_LEFT_BACKWARD, PIN_MOTOR_RIGHT_BACKWARD, PIN_LIGHT, PIN_VELOCITY_FORWARD,PIN_VELOCITY_BACKWARD;
        String currentState;  // Variable para almacenar el estado actual de avance o retroceso
};

#endif
