# Proenergim Stock - Aplicación de Inventario Móvil

Aplicación corporativa desarrollada en **Flutter** para la gestión de inventario, almacenes, seguimiento de costos por proyecto, generación de reportes y lectura de códigos de barras.

> [!IMPORTANT]
> **DOCUMENTACIÓN OBLIGATORIA (NO OLVIDAR):**  
> Para comprender el estado exacto del proyecto, las contraseñas, los requerimientos y la arquitectura, es **crucial** que leas los siguientes 3 archivos Markdown ubicados en la raíz del proyecto antes de realizar cualquier cambio:
>
> 1. **`FL_act.md`** -> Contiene la Bitácora técnica de cambios, las contraseñas de acceso y el mapeo de toda la estructura de carpetas de Flutter.
> 2. **`RF.md`** -> Contiene la lista estricta de todos los Requerimientos Funcionales, No Funcionales y los Casos de Uso del sistema.
> 3. **`avance.md`** -> Contiene el reporte ejecutivo del progreso, qué se ha terminado y qué falta por programar para conectar con la Nube (Backend).

## Tecnologías Principales
- **Flutter** (Framework UI)
- **Supabase (PostgreSQL)** (Backend en la nube y base de datos en tiempo real)
- **Provider** (Gestión de estado)
- **GoRouter** (Navegación y ShellRoutes)
- **Mobile Scanner & QR Flutter** (Lectura y Generación de Códigos)
- **PDF & Printing** (Generación nativa de reportes y etiquetas)

## 🛠️ Cómo Iniciar y Compilar el Proyecto (SDK Local)

Este proyecto cuenta con una versión del SDK de Flutter integrada localmente. Si la herramienta `flutter` no está agregada en tus Variables de Entorno del sistema (PATH), debes utilizar la ruta local: `.\flutter\bin\flutter.bat` en PowerShell o CMD.

### 1. Preparar el Entorno y Dependencias
Antes de ejecutar la app, instala todas las librerías necesarias:
```bash
.\flutter\bin\flutter.bat pub get
```

### 2. Configuración y Detección de Dispositivos USB
Si tu teléfono está conectado por USB pero Flutter no lo detecta, realiza lo siguiente:
1. Asegúrate de tener habilitada la **Depuración USB** en el teléfono.
2. Configura a Flutter para que encuentre el Android SDK de tu computadora:
   ```bash
   .\flutter\bin\flutter.bat config --android-sdk "C:\Users\MARI\AppData\Local\Android\Sdk"
   ```
3. Verifica que tu teléfono móvil sea reconocido:
   ```bash
   .\flutter\bin\flutter.bat devices
   ```
   *Deberías ver listado tu dispositivo móvil (ej. `ALT LX3` o similar).*

---

### 3. Ejecutar en Modo Debug y Actualizar en Caliente (Hot Reload)

#### A. Desde la Consola (Terminal)
Ejecuta la aplicación en modo desarrollo en tu teléfono utilizando su ID o nombre de dispositivo:
```bash
# Ejecutar en el dispositivo móvil detectado
.\flutter\bin\flutter.bat run -d APMDBB5428101977
```
Una vez que la aplicación esté corriendo en tu teléfono, la consola se mantendrá interactiva. Para aplicar tus cambios visuales en caliente:
* **Presiona `r`**: **Hot Reload (Cambio en Caliente)**. Aplica cambios visuales/de interfaz en segundos sin perder el estado actual de la pantalla de la app.
* **Presiona `R`**: **Hot Restart**. Reinicia el estado de la aplicación y vuelve a cargar desde el inicio.
* **Presiona `q`**: Detener la ejecución de la app en modo debug.

#### B. Desde Visual Studio Code (Recomendado)
Para una experiencia más fluida sin comandos de consola:
1. Conecta tu teléfono por USB.
2. Abre VS Code y en la barra inferior derecha selecciona el dispositivo móvil (ej. **ALT LX3**).
3. Presiona **F5** (o ve a la pestaña *Run and Debug* y dale al botón de play).
4. **¡Listo!** Cada vez que realices cambios en tus archivos de código y **guardes (Ctrl + S)**, el editor aplicará el Hot Reload de forma totalmente automática.

---

### 4. Generar el APK para Producción (Instalación Manual)
Si deseas compilar la versión optimizada de producción para enviarla e instalarla de forma manual:
```bash
.\flutter\bin\flutter.bat build apk
```
*El archivo compilado se guardará en `build/app/outputs/flutter-apk/app-release.apk`.*

### 5. Instalar APK compilado vía USB manualmente
Si tienes el APK generado y quieres instalarlo a la fuerza en tu dispositivo USB conectado:
```bash
.\flutter\bin\flutter.bat install -d APMDBB5428101977
```

> **Tip de Solución de Errores:** Si al cambiar ramas de Git o al actualizar librerías nativas obtienes errores raros de compilación, limpia el caché y vuelve a construir:
> ```bash
> .\flutter\bin\flutter.bat clean
> .\flutter\bin\flutter.bat pub get
> ```
