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
            go: { state: "FORWARD" },
            none: { state: "NONE" },
            stop: { state: "STOP" },
            back: { state: "BACKWARD" },
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
        this.gyroForwardBtn.addEventListener("click", this.handleForwardButtonClick.bind(this));
        this.gyroBackwardBtn.addEventListener("click", this.handleBackwardButtonClick.bind(this));
        this.gyroStopBtn.addEventListener("click", this.handleStopButtonClick.bind(this));

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
        // Inicialización de la clase
        this.websocketController = websocketController;
        this.states = states;

        // Variables para mantener el estado de la interfaz
        this.lightOn = false;
        this.isForward = false;
        this.isBackward = false;
        this.isStop = false;
        this.lastVelocity = 0; // Almacenar el último valor enviado

        // Llamada a la inicialización del controlador
        this.controllerInit();
    }

    // ------------------------------
    // Inicialización y Setup
    // ------------------------------

    // Inicializa el controlador y configura los elementos del DOM y eventos
    controllerInit() {
        console.log("Inicializando ControlController...");
        this.cacheDOMElements();   // Obtener elementos DOM
        this.controlBindEvents();  // Enlazar los eventos
    }

    // Cachear los elementos del DOM para evitar buscarlos repetidamente
    cacheDOMElements() {
        this.light = document.getElementById("light");
        this.leftSlider = document.getElementById("left");
        this.rightSlider = document.getElementById("right");
        this.forwardBtn = document.getElementById("forward-btn");
        this.backwardBtn = document.getElementById("backward-btn");
        this.stopBtn = document.getElementById("stop-btn");

        // Verificar si los elementos DOM se obtuvieron correctamente
        if (!this.light || !this.leftSlider || !this.rightSlider ||
            !this.forwardBtn || !this.backwardBtn || !this.stopBtn) {
            throw new Error('Uno o más elementos DOM están indefinidos.');
        }
    }

    // ------------------------------
    // Enlace de Eventos
    // ------------------------------

    // Enlaza los eventos de los sliders y botones a sus funciones correspondientes
    controlBindEvents() {

        // Eventos para los botones
        this.forwardBtn.addEventListener("click", this.handleForwardButtonClick.bind(this));
        this.backwardBtn.addEventListener("click", this.handleBackwardButtonClick.bind(this));
        this.stopBtn.addEventListener("click", this.handleStopButtonClick.bind(this));

        // Evento para encender/apagar la luz
        this.light.addEventListener("click", this.toggleLight.bind(this));

        // Eventos para reiniciar sliders 
        this.leftSlider.addEventListener("touchend", this.handleSliderEnd.bind(this, this.leftSlider));
        this.rightSlider.addEventListener("touchend", this.handleSliderEnd.bind(this, this.rightSlider));

        this.leftSlider.addEventListener("input", this.handleLeftSlider.bind(this));
        this.rightSlider.addEventListener("input", this.handleRightSlider.bind(this));
    }


    // ------------------------------
    // Manejo de Sliders
    // ------------------------------

    // Reinicia el valor del slider a 0 cuando se suelta
    handleSliderEnd(slider) {
        slider.value = 0;  // Reiniciar el slider
        this.websocketController.send(this.states.none)
        if (this.isBackward){
            this.backwardBtn.classList.add("toggle");
            this.websocketController.send(this.states.back);
            console.log("retrocediendo");
        }
        else if (this.isForward){
            this.forwardBtn.classList.add("toggle");
            this.websocketController.send(this.states.go);
            console.log("avanzando");
        }
        else if (this.isStop){
            this.stopBtn.classList.add("toggle");
            this.websocketController.send(this.states.stop);
            console.log("detenido");
        }
    }

    // Maneja el slider izquierdo
    handleLeftSlider() {
        // Redondear el valor del slider a pasos de 15
        let velocity = Math.round(this.leftSlider.value / 15) * 17; // Redondear a múltiplos de 15

        // Si el valor redondeado está en el rango permitido y es diferente del último valor enviado
        if (velocity > 0 && velocity <= 255 && velocity !== this.lastLeftVelocity) {
            this.websocketController.send({"velocity": velocity}); // Enviar la velocidad
            this.websocketController.send(this.states.left); // Enviar el estado de "left"
            console.log(velocity); // Imprimir el valor
            this.lastLeftVelocity = velocity; // Actualizar el último valor enviado
        }
    }

    // Maneja el slider derecho
    handleRightSlider() {
        // Redondear el valor del slider a pasos de 15
        let velocity = Math.round(this.rightSlider.value / 15) * 15; // Redondear a múltiplos de 15

        // Si el valor redondeado está en el rango permitido y es diferente del último valor enviado
        if (velocity > 0 && velocity <= 255 && velocity !== this.lastRightVelocity) {
            this.websocketController.send({"velocity": velocity}); // Enviar la velocidad
            this.websocketController.send(this.states.right); // Enviar el estado de "right"
            console.log(velocity); // Imprimir el valor
            this.lastRightVelocity = velocity; // Actualizar el último valor enviado
        }
    }
    // ------------------------------
    // Manejo de Botones
    // ------------------------------

    // Manejador para el botón de retroceder
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
    // Manejador para el botón de retroceder
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

    // Manejador para el botón de detener
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

    // Desactivar los botones que no están activos para mantener la interfaz clara
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

    // ------------------------------
    // Manejo de la Luz
    // ------------------------------

    // Manejador para encender/apagar la luz
    toggleLight() {
        this.lightOn = !this.lightOn;  // Cambiar el estado de la luz
        this.light.classList.toggle("toggle", this.lightOn);
        
        // Enviar el estado correspondiente al WebSocket
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
