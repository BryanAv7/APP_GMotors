# APP GMotors 

Aplicación móvil desarrollada en Flutter para la gestión de clientes, vehículos y mantenimientos automotrices de Gorila Motos.

## 📖 Descripción

APP GMotors es una aplicación móvil que permite administrar y consultar información relacionada con clientes, vehículos y servicios de mantenimiento. La aplicación consume una API REST desarrollada externamente para gestionar la información de forma segura y eficiente.

## ✨ Características

- Inicio de sesión de usuarios.
- Gestión de clientes.
- Registro y consulta de vehículos.
- Visualización de mantenimientos.
- Consulta de historial de servicios.
- Interfaz intuitiva y responsiva.
- Integración con API REST.

## 📱 Tecnologías Utilizadas

- Flutter
- Dart
- Material Design
- HTTP Client
- Shared Preferences

## 📂 Estructura del Proyecto

```plaintext
lib/
│
├── models/
├── services/
├── screens/
├── widgets/
├── providers/
├── utils/
└── main.dart
```

## ⚙️ Requisitos

- Flutter SDK 3.x o superior
- Dart SDK
- Android Studio o Visual Studio Code
- Dispositivo Android o emulador

## 🚀 Instalación

### Clonar el repositorio

```bash
git clone https://github.com/BryanAv7/APP_GMotors.git
```

### Ingresar al proyecto

```bash
cd APP_GMotors
```

### Instalar dependencias

```bash
flutter pub get
```

### Ejecutar la aplicación

```bash
flutter run
```

## 🔌 Configuración de la API

Configura la URL del servidor backend dentro del archivo correspondiente:

```dart
const String apiUrl = "http://TU_SERVIDOR/api";
```

## 📸 Capturas de Pantalla

Agregar aquí imágenes de la aplicación:

- Pantalla de Inicio de Sesión
- Dashboard Principal
- Gestión de Clientes
- Gestión de Vehículos
- Historial de Mantenimientos

## 🎯 Objetivo

Facilitar la gestión y seguimiento de los servicios automotrices mediante una aplicación móvil moderna, rápida y fácil de utilizar.

## 👨‍💻 Autores

Bryan Ávila
Paul Paute

## 📄 Licencia

Proyecto desarrollado con fines académicos y de aprendizaje.
