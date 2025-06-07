#ifndef CONTROLLER_H
#define CONTROLLER_H

class Controller {
private:
    int pinLeftDir1, pinLeftDir2, pinLeftPWM;
    int pinRightDir1, pinRightDir2, pinRightPWM;
    int velocidadIzq, velocidadDer;

    const int freq = 1000;
    const int pwmChannelLeft = 0;
    const int pwmChannelRight = 1;
    const int resolution = 8;

public:
    Controller(int leftDir1, int leftDir2, int leftPWM, int rightDir1, int rightDir2, int rightPWM);

    void begin();
    void updateSpeeds(int leftSpeed, int rightSpeed);
    void executeMovement();
    void disconnected();
};
#endif
