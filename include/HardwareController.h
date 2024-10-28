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

        stop();
        lightOff();
    }

  // Método para avanzar
    void Forward() {
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH);
    }

    // Método para retroceder
    void Backward() {
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, HIGH);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, HIGH);
    }

    // Método para girar a la izquierda
    void turnLeft() {
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, HIGH); // Motor izquierdo hacia atrás
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH); // Motor derecho hacia adelante
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
    }

    // Método para girar a la derecha
    void turnRight() {
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH); // Motor izquierdo hacia adelante
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, HIGH); // Motor derecho hacia atrás
    }

    // Método para detener el robot
    void stop() {
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_RIGHT_BACKWARD, LOW);
        digitalWrite(PIN_MOTOR_LEFT_FORWARD, HIGH);
        digitalWrite(PIN_MOTOR_RIGHT_FORWARD, HIGH);
    }

    // Método para apagar las luces
    void lightOff() {
        digitalWrite(PIN_LIGHT, LOW);
    }

    // Método para encender
    void lightOn() {
        digitalWrite(PIN_LIGHT, HIGH);
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
