#include "Controller.h"
#include "Arduino.h"

Controller::Controller(int leftDir1, int leftDir2, int leftPWM, int rightDir1, int rightDir2, int rightPWM) {
    pinLeftDir1 = leftDir1;
    pinLeftDir2 = leftDir2;
    pinLeftPWM = leftPWM;
    pinRightDir1 = rightDir1;
    pinRightDir2 = rightDir2;
    pinRightPWM = rightPWM;
}

void Controller::begin() {
    pinMode(pinLeftDir1, OUTPUT);
    pinMode(pinLeftDir2, OUTPUT);
    pinMode(pinLeftPWM, OUTPUT);

    pinMode(pinRightDir1, OUTPUT);
    pinMode(pinRightDir2, OUTPUT);
    pinMode(pinRightPWM, OUTPUT);

    // Configurar canales PWM
    ledcSetup(pwmChannelLeft, freq, resolution);
    ledcAttachPin(pinLeftPWM, pwmChannelLeft);

    ledcSetup(pwmChannelRight, freq, resolution);
    ledcAttachPin(pinRightPWM, pwmChannelRight);
}

void Controller::updateSpeeds(int leftSpeed, int rightSpeed) {
    velocidadIzq = constrain(leftSpeed, -255, 255);
    velocidadDer = constrain(rightSpeed, -255, 255);
    executeMovement();
}

void Controller::executeMovement() {
    // Motor izquierdo
    if (velocidadIzq >= 0) {
        digitalWrite(pinLeftDir1, HIGH);
        digitalWrite(pinLeftDir2, LOW);
        ledcWrite(pwmChannelLeft, velocidadIzq);
    } else {
        digitalWrite(pinLeftDir1, LOW);
        digitalWrite(pinLeftDir2, HIGH);
        ledcWrite(pwmChannelLeft, -velocidadIzq);
    }

    // Motor derecho
    if (velocidadDer >= 0) {
        digitalWrite(pinRightDir1, HIGH);
        digitalWrite(pinRightDir2, LOW);
        ledcWrite(pwmChannelRight, velocidadDer);
    } else {
        digitalWrite(pinRightDir1, LOW);
        digitalWrite(pinRightDir2, HIGH);
        ledcWrite(pwmChannelRight, -velocidadDer);
    }
}

void Controller::disconnected(){
    digitalWrite(pinRightDir1, LOW);
    digitalWrite(pinRightDir2, LOW);
}
