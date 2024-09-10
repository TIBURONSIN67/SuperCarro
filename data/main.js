class MainController {
    constructor() {
        console.log("constructor init iniciado");
        this.states = this.getInitialStates();
        this.gyroController = null;
        this.buttonController = null;
        this.gameModes = {
            control: { gamemode: "CONTROL" },
            gyro: { gamemode: "GYRO" }
        };
        this.init();
    }

    init() {
        this.cacheDOMElements();
        this.bindEvents();
    }

    getInitialStates() {
        return {
            go: { state: "GO" },
            none: { state: "NONE" },
            stop: { state: "STOP" },
            left: { state: "LEFT" },
            right: { state: "RIGHT" },
            back: { state: "BACK" },
            light_on: { state: "LIGHT_ON" },
            light_off: { state: "LIGHT_OFF" }
        };
    }

    cacheDOMElements() {
        this.mainOptions = document.getElementById("main-options");
        this.playOptions = document.getElementById("play-options");
        this.controlSection = document.getElementById("controls-section");
        this.gyroSection = document.getElementById("gyro-section");
        this.playGyro = document.getElementById("gyro");
        this.play = document.getElementById("play");
        this.playButtons = document.getElementById("buttons");
        this.backBtn = document.getElementById("back-btn");

        if (!this.mainOptions || !this.playOptions || !this.controlSection || !this.gyroSection ||
            !this.playGyro || !this.playButtons || !this.backBtn) {
            throw new Error('Uno o más elementos DOM están indefinidos.');
        }
    }

    bindEvents() {
        console.log("Enlazando eventos");
        this.playGyro.addEventListener("click", this.showGyroSection.bind(this));
        this.playButtons.addEventListener("click", this.showControlSection.bind(this));
        this.backBtn.addEventListener("click", this.showMainOptions.bind(this));
        this.play.addEventListener("click", this.showPlayOptions.bind(this));
    }

    showPlayOptions() {
        console.log("Mostrar opciones de juego");
        this.toggleVisibility(this.mainOptions, false);
        this.toggleVisibility(this.playOptions, true);
        this.toggleVisibility(this.controlSection, false);
    }

    showMainOptions() {
        console.log("Mostrar opciones principales");
        this.toggleVisibility(this.mainOptions, true);
        this.toggleVisibility(this.playOptions, false);
        this.toggleVisibility(this.controlSection, false);
        this.toggleVisibility(this.gyroSection, false);
    }
    showControlSection() {
        console.log("Mostrar sección de control");
        if (!this.buttonController) {
            console.log("Creando nueva instancia de ControlController");
            this.buttonController = new ControlController();
        }
        this.toggleVisibility(this.controlSection, true);
        this.toggleVisibility(this.playOptions, false);
        this.sendData(this.gameModes.control);
    }

    showGyroSection() {
        console.log("Mostrar sección de giroscopio");
        if (!this.gyroController) {
            console.log("Creando nueva instancia de GyroController");
            this.gyroController = new GyroController();
        }
        this.toggleVisibility(this.gyroSection, true);
        this.toggleVisibility(this.playOptions, false);
        this.toggleVisibility(this.controlSection, false);
        this.sendData(this.gameModes.gyro);
    }

    toggleVisibility(element, isVisible) {
        element.classList.toggle("toggle", isVisible);
    }

    sendData(state) {
        console.log('Datos enviados:', JSON.stringify(state));
        fetch("/control", {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(state)
        })
        .then(response => response.text())
        .then(data => console.log('Respuesta del servidor:', data))
        .catch(error => console.error('Error en la solicitud:', error));
    }
}

// Asegúrate de que MainController se cree solo una vez
let mainControllerInstance = null;

document.addEventListener("DOMContentLoaded", () => {
    if (!mainControllerInstance) {
        mainControllerInstance = new MainController();
    }
});

class ControlController extends MainController {
    constructor() {
        super();
        console.log('Instancia de ControlController creada');
        this.lightOn = false;
        this.isLeft = false;
        this.isRight =false;
        this.isForward = false;
        this.isBackward = false;
        this.isStop = false;
        this.controllerInit();
    }

    controllerInit() {
        console.log("Inicializando Control Controller...");
        this.cacheDOMElements();
        this.controlBindEvents();
    }

    cacheDOMElements() {
        super.cacheDOMElements();
        this.light = document.getElementById("light");
        this.leftBtn = document.getElementById("left");
        this.rightBtn = document.getElementById("right");
        this.forwardBtn = document.getElementById("forward");
        this.backwardBtn = document.getElementById("backward");
        this.stopBtn = document.getElementById("stop");

        if (!this.light || !this.leftBtn || !this.rightBtn ||
            !this.forwardBtn || !this.backwardBtn || !this.stopBtn) {
            throw new Error('Uno o más elementos DOM están indefinidos.');
        }
    }

    controlBindEvents() {
        this.sendData(this.gameModes.control);
        // Aplicamos el comportamiento de toggle al presionar y none al soltar
        this.addToggleBehavior(this.leftBtn, this.states.left);
        this.addToggleBehavior(this.rightBtn, this.states.right);
    
        // Asignamos eventos para los otros botones
        this.forwardBtn.addEventListener("click", () => this.handleForwardButtonClick());
        this.backwardBtn.addEventListener("click", () => this.handleBackwardButtonClick());
        this.stopBtn.addEventListener("click", () => this.handleStopButtonClick());
    
        // Evento para la luz
        this.light.addEventListener("click", this.toggleLight.bind(this));
    }
    
    addToggleBehavior(button, state) {
        // Para eventos de touch (dispositivos móviles)
        button.addEventListener("touchstart", (event) => {
            event.preventDefault(); // Prevenir comportamientos no deseados como el zoom o scroll.
            button.classList.add("toggle");
            this.sendData(state);  // Enviar el estado correspondiente (por ejemplo, 'left' o 'right')
        });
    
        button.addEventListener("touchend", (event) => {
            event.preventDefault(); // Prevenir comportamientos no deseados.
            button.classList.remove("toggle");
            this.sendData(this.states.none);  // Al soltar, enviar estado 'none'
        });
    
        // Opción para manejar mouse en caso de que también se quiera en dispositivos no táctiles
        button.addEventListener("mousedown", (event) => {
            event.preventDefault();
            button.classList.add("toggle");
            this.sendData(state);
        });
    
        button.addEventListener("mouseup", (event) => {
            event.preventDefault();
            button.classList.remove("toggle");
            this.sendData(this.states.none);
        });
    
        // Si el mouse se sale del área del botón, se desactiva también
        button.addEventListener("mouseleave", (event) => {
            event.preventDefault();
            button.classList.remove("toggle");
            this.sendData(this.states.none);
        });
    }
    
    handleForwardButtonClick() {
        if (!this.isForward) {
            this.activateButton('forward');
            this.sendData(this.states.go);
        } else {
            this.deactivateButton('forward');
            this.sendData(this.states.stop);
        }
    }
    
    handleBackwardButtonClick() {
        if (!this.isBackward) {
            this.activateButton('backward');
            this.sendData(this.states.back);
        } else {
            this.deactivateButton('backward');
            this.sendData(this.states.stop);
        }
    }
    
    handleStopButtonClick() {
        if (!this.isStop) {
            this.activateButton('stop');
            this.sendData(this.states.stop);
        } else {
            this.deactivateButton('stop');
            this.sendData(this.states.stop);
        }
    }
    
    // Función para activar un botón y desactivar los demás
    activateButton(buttonType) {
        this.stopBtn.classList.remove("toggle");
        this.forwardBtn.classList.remove("toggle");
        this.backwardBtn.classList.remove("toggle");
    
        if (buttonType === 'forward') {
            this.forwardBtn.classList.add("toggle");
            this.isForward = true;
            this.isBackward = false;
            this.isStop = false;
        } else if (buttonType === 'backward') {
            this.backwardBtn.classList.add("toggle");
            this.isForward = false;
            this.isBackward = true;
            this.isStop = false;
        } else if (buttonType === 'stop') {
            this.stopBtn.classList.add("toggle");
            this.isForward = false;
            this.isBackward = false;
            this.isStop = true;
        }
    }
    
    // Función para desactivar un botón
    deactivateButton(buttonType) {
        if (buttonType === 'forward') {
            this.forwardBtn.classList.remove("toggle");
            this.isForward = false;
        } else if (buttonType === 'backward') {
            this.backwardBtn.classList.remove("toggle");
            this.isBackward = false;
        } else if (buttonType === 'stop') {
            this.stopBtn.classList.remove("toggle");
            this.isStop = false;
        }
    }
    
    // Llama a esta función en el inicio para asegurarte de que todos los estados estén desactivados
    resetButtons() {
        this.deactivateButton('forward');
        this.deactivateButton('backward');
        this.deactivateButton('stop');
        this.sendData(this.states.none);
    }
    

    toggleLight() {
        if (this.lightOn == false) {
            this.lightOn = true;
            this.light.classList.add("toggle");
            this.sendData(this.states.light_on);
        } else {
            this.lightOn = false;
            this.light.classList.remove("toggle");
            this.sendData(this.states.light_off);
        }
    }
}
class GyroController extends MainController {
    constructor() {
        super();
        console.log("Instancia de GyroController creada");
        this.config = {
            sendInterval: 100, // Ajustar según la capacidad del servidor
            gammaThreshold: 10,
            betaThreshold: 15,
            maxSpeed: 255,
            sensitivity: 30
        };
        this.lastBeta = 0;
        this.lastGamma = 0;
        this.lastSentState = null; // Almacena el último estado enviado para evitar duplicación
        this.init();
    }

    init() {
        this.lastSendTime = 0;
        this.setupDeviceOrientation();
        this.cacheDOMElements();
        this.bindEvents();
    }

    cacheDOMElements() {
        super.cacheDOMElements();
        this.gammaThresholdInput = document.getElementById("gammaThreshold");
        this.betaThresholdInput = document.getElementById("betaThreshold");
        this.sensitivityInput = document.getElementById("sensitivity");

        if (!this.gammaThresholdInput || !this.betaThresholdInput || !this.sensitivityInput) {
            throw new Error('Uno o más elementos DOM para la configuración del giroscopio están indefinidos.');
        }
    }

    bindEvents() {
        this.gammaThresholdInput.addEventListener("input", this.updateConfig.bind(this));
        this.betaThresholdInput.addEventListener("input", this.updateConfig.bind(this));
        this.sensitivityInput.addEventListener("input", this.updateConfig.bind(this));
    }

    setupDeviceOrientation() {
        if (window.DeviceOrientationEvent) {
            window.addEventListener('deviceorientation', this.handleDeviceOrientation.bind(this));
        } else {
            console.log('DeviceOrientationEvent no es soportado en este dispositivo.');
        }
    }

    handleDeviceOrientation(event) {
        const { beta = 0, gamma = 0 } = event;
        const now = Date.now();

        if (now - this.lastSendTime > this.config.sendInterval) {
            // Comparar si beta o gamma han cambiado significativamente
            if (Math.abs(beta - this.lastBeta) > this.config.betaThreshold) {
                this.handleBetaChange(beta);
                this.lastBeta = beta;
            } else if (Math.abs(gamma - this.lastGamma) > this.config.gammaThreshold) {
                this.handleGammaChange(gamma);
                this.lastGamma = gamma;
            } else if (this.lastSentState !== this.states.none) {
                // Si no hay cambios significativos, enviar estado "none" solo si es necesario
                this.sendData(this.states.none);
                this.lastSentState = this.states.none;
            }
            this.lastSendTime = now;
        }
    }

    handleBetaChange(beta) {
        let newState = beta > 0 ? this.states.right : this.states.left;
        // Solo enviar si el estado es diferente al último enviado
        if (this.lastSentState !== newState) {
            this.sendData(newState);
            this.lastSentState = newState;
        }
    }

    handleGammaChange(gamma) {
        let speed = Math.min(Math.abs(gamma) * (this.config.maxSpeed / this.config.sensitivity), this.config.maxSpeed);
        let newState = gamma > 0 ? { ...this.states.go, speed } : { ...this.states.back, speed };
        // Solo enviar si el estado es diferente al último enviado
        if (this.lastSentState !== newState) {
            this.sendData(newState);
            this.lastSentState = newState;
        }
    }

    updateConfig() {
        this.config.gammaThreshold = parseInt(this.gammaThresholdInput.value, 10) || this.config.gammaThreshold;
        this.config.betaThreshold = parseInt(this.betaThresholdInput.value, 10) || this.config.betaThreshold;
        this.config.sensitivity = parseInt(this.sensitivityInput.value, 10) || this.config.sensitivity;
    }
}

