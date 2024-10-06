// Clase para manejar la conexión WebSocket
class WebSocketController {
    constructor(url) {
        this.url = url;
        this.socket = null;
    }

    connect() {
        this.socket = new WebSocket(this.url);
        this.socket.addEventListener('open', this.onOpen.bind(this));
        this.socket.addEventListener('message', this.onMessage.bind(this));
        this.socket.addEventListener('error', this.onError.bind(this));
        this.socket.addEventListener('close', this.onClose.bind(this));
    }

    onOpen(event) {
        console.log('Conexión WebSocket establecida');
    }

    onMessage(event) {
        console.log('Mensaje del servidor:', event.data);
    }

    onError(event) {
        console.error('Error en la conexión WebSocket:', event);
    }

    onClose(event) {
        console.log('Conexión WebSocket cerrada');
    }

    send(data) {
        if (this.socket && this.socket.readyState === WebSocket.OPEN) {
            this.socket.send(JSON.stringify(data));
            console.log('Datos enviados a través de WebSocket:', JSON.stringify(data));
        } else {
            console.error('No se puede enviar: conexión no abierta');
        }
    }
}


// Clase principal del controlador
class MainController {
    constructor() {
        console.log("Constructor MainController iniciado");
        this.states = this.getInitialStates();
        this.websocketController = new WebSocketController('ws://192.168.4.1/ws');
        this.websocketController.connect();
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
            back: { state: "BACK" },
            left: { state: "LEFT" },
            right: { state: "RIGHT" },
            light_on: { state: "LIGHT_ON" },
            light_off: { state: "LIGHT_OFF" }
        };
    }

    cacheDOMElements() {
        this.mainOptions = document.getElementById("main-options");
        this.playOptions = document.getElementById("play-options");
        this.controlSection = document.getElementById("controls-section");
        this.gyroSection = document.getElementById("gyro-section");
        this.play = document.getElementById("play");
        this.playButtons = document.getElementById("buttons");
        this.playGyro = document.getElementById("gyro");
        this.backBtn = document.getElementById("back-btn");

        if (!this.mainOptions || !this.playOptions || !this.controlSection || !this.playButtons || !this.backBtn || !this.play) {
            throw new Error('Uno o más elementos DOM están indefinidos.');
        }
    }

    bindEvents() {
        console.log("Enlazando eventos");
        this.playButtons.addEventListener("click", this.showControlSection.bind(this));
        this.playGyro.addEventListener("click", this.showGyroSection.bind(this));
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
            this.buttonController = new ControlController(this.websocketController, this.states);
        }
        this.toggleVisibility(this.controlSection, true);
        this.toggleVisibility(this.playOptions, false);
    }

    toggleVisibility(element, isVisible) {
        element.classList.toggle("toggle", isVisible);
    }
    showGyroSection() {
        console.log("Mostrar sección de gyro");
        if (!this.buttonController) {
            console.log("Creando nueva instancia de ControlController");
            this.buttonController = new GyroController(this.websocketController, this.states);
        }
        this.toggleVisibility(this.gyroSection, true);
        this.toggleVisibility(this.playOptions, false);
    }

    toggleVisibility(element, isVisible) {
        element.classList.toggle("toggle", isVisible);
    }
}

class GyroController{
    constructor(websocketController, states) {
    this.websocketController = websocketController;
    this.states = states;
    this.lightOn = false;
    this.isForward = false;
    this.isBackward = false;
    this.isStop = false;
    this.GyroInit();
    }

    GyroInit() {
        console.log("Inicializando ControlController...");
        this.cacheDOMElements();
        this.controlBindEvents();
    }
    cacheDOMElements(){
    // Agregar referencias de los controles en gyro-section
        this.gyroLight = document.getElementById("gyro-light");
        this.gyroForwardBtn = document.getElementById("gyro-forward"); // ID actualizado
        this.gyroBackwardBtn = document.getElementById("gyro-backward"); // ID actualizado
        this.gyroStopBtn = document.getElementById("gyro-stop"); // ID actualizado

        if (!this.gyroLight || !this.gyroForwardBtn || !this.gyroBackwardBtn || !this.gyroStopBtn){
            throw new Error('Uno o más elementos DOM están indefinidos.');
        }
    }
    controlBindEvents(){
        this.gyroForwardBtn.addEventListener("click", () => this.handleForwardButtonClick());
        this.gyroBackwardBtn.addEventListener("click", () => this.handleBackwardButtonClick());
        this.gyroStopBtn.addEventListener("click", () => this.handleStopButtonClick());

        this.gyroLight.addEventListener("click", this.toggleLight.bind(this));
    }
    toggleLight() {
        this.lightOn = !this.lightOn;
        this.gyroLight.classList.toggle("toggle", this.lightOn);
        const state = this.lightOn ? this.states.light_on : this.states.light_off;
        this.websocketController.send(state);
    }
    handleForwardButtonClick() {
        if (!this.isForward) {
            this.deactivateOtherButtons(this.gyroForwardBtn);
            this.gyroForwardBtn.classList.add("toggle");
            this.websocketController.send(this.states.go);
            this.isForward = true;
        } else {
            this.gyroForwardBtn.classList.remove("toggle");
            this.websocketController.send(this.states.stop);
            this.isForward = false;
        }
    }

    handleBackwardButtonClick() {
        if (!this.isBackward) {
            this.deactivateOtherButtons(this.gyroBackwardBtn);
            this.gyroBackwardBtn.classList.add("toggle");
            this.websocketController.send(this.states.back);
            this.isBackward = true;
        } else {
            this.gyroBackwardBtn.classList.remove("toggle");
            this.websocketController.send(this.states.stop);
            this.isBackward = false;
        }
    }

    handleStopButtonClick() {
        if (!this.isStop) {
            this.deactivateOtherButtons(this.gyroStopBtn);
            this.gyroStopBtn.classList.add("toggle");
            this.websocketController.send(this.states.stop);
            this.isStop = true;
        } else {
            this.gyroStopBtn.classList.remove("toggle");
            this.websocketController.send(this.states.stop);
            this.isStop = false;
        }
    }

    deactivateOtherButtons(activeButton) {
        if (activeButton !== this.gyroForwardBtn && this.isForward) {
            this.gyroForwardBtn.classList.remove("toggle");
            this.isForward = false;
        }

        if (activeButton !== this.gyroBackwardBtn && this.isBackward) {
            this.gyroBackwardBtn.classList.remove("toggle");
            this.isBackward = false;
        }

        if (activeButton !== this.gyroStopBtn && this.isStop) {
            this.gyroStopBtn.classList.remove("toggle");
            this.isStop = false;
        }
    }
}
// Clase para el control del carro
class ControlController {
    constructor(websocketController, states) {
        this.websocketController = websocketController;
        this.states = states;
        this.lightOn = false;
        this.isForward = false;
        this.isBackward = false;
        this.isStop = false;
        this.controllerInit();
    }

    controllerInit() {
        console.log("Inicializando ControlController...");
        this.cacheDOMElements();
        this.controlBindEvents();
    }

    cacheDOMElements() {
        this.light = document.getElementById("light");
        this.leftSlider = document.getElementById("left");
        this.rightSlider = document.getElementById("right");
        this.forwardBtn = document.getElementById("forward-btn"); // ID actualizado
        this.backwardBtn = document.getElementById("backward-btn"); // ID actualizado
        this.stopBtn = document.getElementById("stop-btn"); // ID actualizado

        // Verificar si todos los elementos DOM están definidos
        if (!this.light || !this.leftSlider || !this.rightSlider ||
            !this.forwardBtn || !this.backwardBtn || !this.stopBtn) {
            throw new Error('Uno o más elementos DOM están indefinidos.');
        }
    }

    controlBindEvents() {
        this.leftSlider.addEventListener("input", () => this.handleSliderChange(this.leftSlider, this.states.left));
        this.rightSlider.addEventListener("input", () => this.handleSliderChange(this.rightSlider, this.states.right));

        this.forwardBtn.addEventListener("click", () => this.handleForwardButtonClick());
        this.backwardBtn.addEventListener("click", () => this.handleBackwardButtonClick());
        this.stopBtn.addEventListener("click", () => this.handleStopButtonClick());

        this.light.addEventListener("click", this.toggleLight.bind(this));

        // Agregar eventos para el mouseup y touchend en los sliders
        this.leftSlider.addEventListener("mouseup", () => this.resetSlider(this.leftSlider));
        this.leftSlider.addEventListener("touchend", () => this.resetSlider(this.leftSlider));
        this.rightSlider.addEventListener("mouseup", () => this.resetSlider(this.rightSlider));
        this.rightSlider.addEventListener("touchend", () => this.resetSlider(this.rightSlider));
    }

handleSliderChange(slider,state) {
    const X_velocity = this.roundSliderValue(slider); // Redondear el valor del slider
    console.log(`Slider ${slider.id} changed to: ${X_velocity}`);
    
    // Crear un objeto JSON para enviar
    const message = {
        state : state
    };

    // Enviar el objeto JSON si la velocidad es mayor a 0
    if (X_velocity > 0) {
        this.websocketController.send(state);
    } else {
        this.websocketController.send(this.states.none); // Detener cuando el slider está en 0
    }
}


    resetSlider(slider) {
        slider.value = 0; // Reiniciar el valor del slider a 0
        this.websocketController.send(this.states.none); // Detener el estado
        console.log(`Slider ${slider.id} reset to 0`);
    }

    roundSliderValue(slider) {
        const roundedValue = Math.round(slider.value / 15) * 15; // Redondear a múltiplos de 15
        slider.value = roundedValue; // Actualizar el valor del slider
        return roundedValue;
    }

    handleForwardButtonClick() {
        if (!this.isForward) {
            this.deactivateOtherButtons(this.forwardBtn);
            this.forwardBtn.classList.add("toggle");
            this.websocketController.send(this.states.go);
            this.isForward = true;
        } else {
            this.forwardBtn.classList.remove("toggle");
            this.websocketController.send(this.states.stop);
            this.isForward = false;
        }
    }

    handleBackwardButtonClick() {
        if (!this.isBackward) {
            this.deactivateOtherButtons(this.backwardBtn);
            this.backwardBtn.classList.add("toggle");
            this.websocketController.send(this.states.back);
            this.isBackward = true;
        } else {
            this.backwardBtn.classList.remove("toggle");
            this.websocketController.send(this.states.stop);
            this.isBackward = false;
        }
    }

    handleStopButtonClick() {
        if (!this.isStop) {
            this.deactivateOtherButtons(this.stopBtn);
            this.stopBtn.classList.add("toggle");
            this.websocketController.send(this.states.stop);
            this.isStop = true;
        } else {
            this.stopBtn.classList.remove("toggle");
            this.websocketController.send(this.states.stop);
            this.isStop = false;
        }
    }

    deactivateOtherButtons(activeButton) {
        if (activeButton !== this.forwardBtn && this.isForward) {
            this.forwardBtn.classList.remove("toggle");
            this.isForward = false;
        }

        if (activeButton !== this.backwardBtn && this.isBackward) {
            this.backwardBtn.classList.remove("toggle");
            this.isBackward = false;
        }

        if (activeButton !== this.stopBtn && this.isStop) {
            this.stopBtn.classList.remove("toggle");
            this.isStop = false;
        }
    }

    toggleLight() {
        this.lightOn = !this.lightOn;
        this.light.classList.toggle("toggle", this.lightOn);
        const state = this.lightOn ? this.states.light_on : this.states.light_off;
        this.websocketController.send(state);
    }
}

// Asegúrate de que MainController se cree solo una vez
let mainControllerInstance = null;

document.addEventListener("DOMContentLoaded", () => {
    if (!mainControllerInstance) {
        mainControllerInstance = new MainController();
    }
});
