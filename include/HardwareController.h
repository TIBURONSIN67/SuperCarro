#ifndef HARDWARE_CONTROLLER_H
#define HARDWARE_CONTROLLER_H

#include <Arduino.h>

class HardwareController {
public:
    HardwareController(
        int pinMotorLeftForward, 
        int pinMotorRightForward, 
        int pinMotorLeftBackward, 
        int pinMotorRightBackward,
        int pinLight
        )
        : PIN_MOTOR_LEFT_FORWARD(pinMotorLeftForward), 
            PIN_MOTOR_RIGHT_FORWARD(pinMotorRightForward), 
            PIN_MOTOR_LEFT_BACKWARD(pinMotorLeftBackward), 
            PIN_MOTOR_RIGHT_BACKWARD(pinMotorRightBackward), 
            PIN_LIGHT(pinLight){}

    void begin() {
        pinMode(PIN_MOTOR_LEFT_FORWARD, OUTPUT);
        pinMode(PIN_MOTOR_RIGHT_FORWARD, OUTPUT);
        pinMode(PIN_MOTOR_LEFT_BACKWARD, OUTPUT);
        pinMode(PIN_MOTOR_RIGHT_BACKWARD, OUTPUT);
        pinMode(PIN_LIGHT, OUTPUT);

        stop();
        lightOff();
    }

    void forward() {
        Serial.println("Avanzando hacia adelante");
        // Avanza en línea recta
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH);
    }

    void backward() {
        Serial.println("Retrocediendo");
        // Retrocede en línea recta
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, HIGH);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, HIGH);
    }

    void turnLeft() {
        Serial.println("Girando a la izquierda");
        // Gira sobre su eje hacia la izquierda
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, HIGH); // Motor izquierdo hacia atrás
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH); // Motor derecho hacia adelante
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
    }

    void turnRight() {
        Serial.println("Girando a la derecha");
        // Gira sobre su eje hacia la derecha
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH); // Motor izquierdo hacia adelante
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, HIGH); // Motor derecho hacia atrás
    }

    void stop() {
        Serial.println("Deteniendo el movimiento");
        // Detiene el movimiento
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
    }

    void lightOn() {
        Serial.println("Encendiendo la luz");
        digitalWrite(PIN_LIGHT, HIGH);
    }

    void lightOff() {
        Serial.println("Apagando la luz");
        digitalWrite(PIN_LIGHT, LOW);
    }

    private:
        int PIN_MOTOR_LEFT_FORWARD, 
        PIN_MOTOR_RIGHT_FORWARD, 
        PIN_MOTOR_LEFT_BACKWARD, 
        PIN_MOTOR_RIGHT_BACKWARD,
        PIN_LIGHT;
};

#endif
