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
            ) : 
                PIN_MOTOR_LEFT_FORWARD(pinMotorLeftForward), 
                PIN_MOTOR_RIGHT_FORWARD(pinMotorRightForward), 
                PIN_MOTOR_LEFT_BACKWARD(pinMotorLeftBackward), 
                PIN_MOTOR_RIGHT_BACKWARD(pinMotorRightBackward), 
                PIN_LIGHT(pinLight)
            {}

    void begin() {
        pinMode(PIN_MOTOR_LEFT_FORWARD, OUTPUT);
        pinMode(PIN_MOTOR_RIGHT_FORWARD, OUTPUT);
        pinMode(PIN_MOTOR_LEFT_BACKWARD, OUTPUT);
        pinMode(PIN_MOTOR_RIGHT_BACKWARD, OUTPUT);
        pinMode(PIN_LIGHT, OUTPUT);

        // Inicializa los pines en LOW
        stop();
        setLight(false);
    }

  // Método para avanzar
    void moveForward() {
        Serial.println("Avanzando");
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH);
    }

    // Método para retroceder
    void moveBackward() {
        Serial.println("Retrocediendo");
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, HIGH);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, HIGH);
    }

    // Método para girar a la izquierda
    void turnLeft() {
        Serial.println("Girando a la izquierda");
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, HIGH); // Motor izquierdo hacia atrás
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH); // Motor derecho hacia adelante
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
    }

    // Método para girar a la derecha
    void turnRight() {
        Serial.println("Girando a la derecha");
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH); // Motor izquierdo hacia adelante
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, HIGH); // Motor derecho hacia atrás
    }

    // Método para detener el robot
    void stop() {
        Serial.println("PARADO");
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
    }

    // Método para encender/apagar las luces
    void setLight(bool state) {
        if (state) {
            Serial.println("LUCES_ENCENDIDAS");
            // Aquí va el código para encender las luces
        } else {
            Serial.println("LUCES_APAGADAS");
            // Aquí va el código para apagar las luces
        }
    }


    private:
        const int 
                PIN_MOTOR_LEFT_FORWARD, 
                PIN_MOTOR_RIGHT_FORWARD, 
                PIN_MOTOR_LEFT_BACKWARD, 
                PIN_MOTOR_RIGHT_BACKWARD, 
                PIN_LIGHT;
};

#endif
