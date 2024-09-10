#ifndef HARDWARE_CONTROLLER_H
#define HARDWARE_CONTROLLER_H

#include <Arduino.h>

class HardwareController {
public:
    HardwareController(int pinLeft, int pinRight, int pinGo, int pinBack, int pinLight, int pinPwm)
        : pinLeft(pinLeft), pinRight(pinRight), pinGo(pinGo), pinBack(pinBack), pinLight(pinLight), pinPwm(pinPwm) {}

    void begin() {
        pinMode(pinLeft, OUTPUT);
        pinMode(pinRight, OUTPUT);
        pinMode(pinGo, OUTPUT);
        pinMode(pinBack, OUTPUT);
        pinMode(pinLight, OUTPUT);
        pinMode(pinPwm, OUTPUT);

        // Inicializa los pines en LOW
        stop();
        setLight(false);
    }

    void control(String state, int speed) {
        // Ajustar y limitar el valor de velocidad
        speed = constrain(speed, 0, 255);
        analogWrite(pinPwm, speed);
        
        // Control de los pines según el estado recibido
        if (state == "LEFT") {
            Serial.println("Girando a la izquierda");
            digitalWrite(pinLeft, HIGH);
            digitalWrite(pinRight, LOW);
        } else if (state == "RIGHT") {
            Serial.println("Girando a la derecha");
            digitalWrite(pinLeft, LOW);
            digitalWrite(pinRight, HIGH);
        } else if (state == "GO") {
            Serial.println("Avanzando");
            digitalWrite(pinGo, HIGH);
            digitalWrite(pinBack, LOW);
        } else if (state == "BACK") {
            Serial.println("Retrocediendo");
            digitalWrite(pinGo, LOW);
            digitalWrite(pinBack, HIGH);
        } else if (state == "STOP"){
            Serial.println("Detenido STOP");
            digitalWrite(pinBack, LOW);
            digitalWrite(pinGo, LOW);
        } else if (state == "LIGHT_ON") {
            Serial.println("Encendiendo luces");
            setLight(true);
        } else if (state == "LIGHT_OFF") {
            Serial.println("Apagando luces");
            setLight(false);
        } else if (state == "NONE"){
            digitalWrite(pinLeft, LOW);
            digitalWrite(pinRight, LOW);
        }
    }

    void stop(){
        digitalWrite(pinRight, LOW);
        digitalWrite(pinLeft, LOW);
        digitalWrite(pinGo, LOW);
        digitalWrite(pinBack, LOW);
    }

    void setLight(bool on) {
        digitalWrite(pinLight, on ? HIGH : LOW);
    }

private:
    int pinLeft, pinRight, pinGo, pinBack, pinLight, pinPwm;
};

#endif
