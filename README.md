# TecnoShop 🛒

Aplicación móvil de comercio electrónico desarrollada con **Flutter y Firebase**, orientada a la consulta de productos y la gestión de compras.

## 📱 Funcionalidades

- Registro e inicio de sesión de usuarios.
- Recuperación de contraseña.
- Catálogo de productos desde Cloud Firestore.
- Visualización del detalle de cada producto.
- Carrito de compras.
- Validación de stock disponible.
- Procesamiento de compras mediante una Cloud Function.
- Registro de compras con información del usuario, productos y total.

## 🛠️ Tecnologías utilizadas

- Flutter y Dart.
- Firebase Authentication.
- Cloud Firestore.
- Cloud Functions for Firebase.
- Firebase Emulator Suite.

## 📋 Requisitos previos

Antes de ejecutar el proyecto, instala:

- [Flutter SDK](https://docs.flutter.dev/get-started/install).
- [Android Studio](https://developer.android.com/studio) o un entorno compatible.
- [Node.js](https://nodejs.org/) para las Cloud Functions.
- [Firebase CLI](https://firebase.google.com/docs/cli).

## 🚀 Instalación

Clona el repositorio:

```bash
git clone https://github.com/Matias2804/tecno_shop.git
cd tecno_shop
```

Instala las dependencias de Flutter:

```bash
flutter pub get
```

Instala las dependencias de las funciones:

```bash
cd functions
npm install
cd ..
```

## 🔥 Configuración de Firebase

El proyecto utiliza Firebase Authentication, Cloud Firestore y una función para procesar las compras.

Para ejecutar el proyecto en un entorno propio, debes configurar un proyecto de Firebase y sus aplicaciones correspondientes. Revisa la configuración de FlutterFire y el archivo `lib/firebase_options.dart`.

**Importante:** no publiques claves privadas, credenciales de cuentas de servicio ni otros secretos.

## 🧪 Ejecución con emuladores locales

El proyecto puede configurarse para trabajar con Firebase Emulator Suite, evitando realizar pruebas de compra contra servicios de producción.

Inicia los emuladores configurados:

```bash
firebase emulators:start --only auth,functions,firestore
```

En otra terminal, desde la raíz del proyecto, ejecuta:

```bash
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Comprueba que los emuladores estén activos y que la aplicación apunte a ellos antes de realizar pruebas.

Los datos creados en los emuladores son independientes de los datos de producción y pueden perderse al reiniciarlos si no se configura persistencia.

## 🛍️ Procesamiento de compras

La función `realizarCompra` valida la autenticación, los productos, las cantidades y el stock disponible. Cuando la compra es válida, registra la operación y actualiza el inventario mediante una transacción de Firestore.

Las pruebas locales permiten comprobar tanto las compras exitosas como los casos de stock insuficiente y solicitudes sin autenticación.

## 📌 Estado del proyecto

Proyecto en desarrollo. La compilación de Android y las funcionalidades principales se han probado localmente. El despliegue de Cloud Functions en producción requiere revisar la configuración del proyecto Firebase y su plan de facturación.

## 👨‍💻 Autor

**Matias2804**

Repositorio: [github.com/Matias2804/tecno_shop](https://github.com/Matias2804/tecno_shop)
