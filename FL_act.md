# Actualización y Migración a Flutter (Bitácora de Cambios)

Este documento registra todo el progreso de la migración y creación del proyecto desde cero en Flutter, con un diseño moderno (Tema Claro) y funcionalidades orientadas a la experiencia del usuario (UX) corporativa.

## 🔑 Credenciales de Acceso (¡No Olvidar!)
Para iniciar sesión en la aplicación, utilizamos la base de datos viva en Supabase:
- **Admin:** (Tu correo de pruebas) | Clave: (Tu clave)
- *Nota:* Puedes recuperar la contraseña desde la app y gestionar usuarios en el panel.

## 🚀 Mejoras y Funcionalidades Recientes Implementadas
1. **Asignación y Costos por Proyecto:** 
   - Las *salidas* de inventario requieren ahora obligatoriamente seleccionar el Proyecto destino.
   - Nueva pantalla `Detalle de Costos` dentro de Proyectos, que cruza los materiales extraídos y su precio para dar el "Presupuesto Consumido".
2. **Generador Automático de Etiquetas QR:** 
   - Pantalla nueva en *Extras* que renderiza QRs nativos y permite imprimir masivamente en formato PDF todo el inventario (Ideal para papel autoadhesivo).
3. **Reportes PDF Oficiales:** 
   - Botón desplegable en el Dashboard para exportar el historial de movimientos en CSV (Excel) o un hermoso PDF membretado listo para compartir por WhatsApp.
4. **Números de Serie (S/N):** 
   - El catálogo de productos ahora soporta y muestra Números de Serie únicos (`serialNumber`), requerido para equipos especiales (La base de datos SQLite fue actualizada a la versión 4).
5. **Escáner Inteligente (UX Refactor):**
   - El Escáner se mejoró agregando linterna, animación láser y vibración háptica.
   - **Flujo Perfecto:** Al detectar un producto, la cámara se pausa y abre el Formulario de Movimientos flotando sobre la pantalla, lo cual evita clics redundantes y retrocesos visuales.
6. **Refinamientos de UI y Búsqueda (Últimos Cambios):**
   - **Buscador en Generador:** Se agregó una barra de búsqueda inteligente por Nombre/SKU en la lista de impresión de etiquetas.
   - **Interruptor Códigos de Barras:** Se implementó un "Toggle" para cambiar entre generación/impresión de Códigos QR o Códigos de Barras tradicionales (Code 128) tanto en pantalla como en PDF.
   - **Formulario Inteligente:** El formulario de movimientos ahora muestra un indicador de carga (`CircularProgressIndicator`) mientras obtiene los datos más frescos de la base de datos, evitando bloqueos.
   - **Prevención de Overflows:** Se aplicó `isExpanded: true` y `TextOverflow.ellipsis` a todos los menús desplegables (`Dropdowns`) garantizando que nombres largos no rompan la pantalla en celulares pequeños.
7. **Características Premium Locales (Mega Actualización):**
   - **Seguridad por Roles:** El menú lateral y el Dashboard ahora se adaptan. Los administradores ven la gestión financiera y de usuarios, mientras que los trabajadores (`worker`) solo ven el escáner y el catálogo básico para prevenir fuga de información.
   - **Analítica Gráfica:** Se integró la librería `fl_chart` para mostrar un hermoso gráfico circular (PieChart) interactivo en el Dashboard que detalla la proporción de "Stock Saludable vs Stock Crítico".
   - **Búsqueda Global Nativa:** Nuevo icono de lupa en la barra superior. Implementa un `SearchDelegate` que busca coincidencias instantáneas tanto en Productos (SKU/Nombre) como en Proyectos simultáneamente.
   - **Sistema de Copias de Seguridad (Backup):** Rediseñado. Ahora las copias de seguridad son automáticas y gestionadas por los servidores de Supabase en la nube.
8. **Mega Actualización Cloud-Native (Sin SQLite):**
   - **Backend Nube:** Toda la arquitectura local (SQLite) fue removida. La app ahora se comunica directamente con **Supabase (PostgreSQL)**.
   - **Recuperación OTP:** Flujo completo de "Olvidé mi contraseña" implementado, enviando un código numérico de 6 dígitos al correo y restableciéndolo directamente en la app.
   - **Limpieza Absoluta:** Se eliminaron por completo las dependencias de `sqflite` del `pubspec.yaml` y los archivos residuales locales (`database_helper.dart` y `sync_service.dart`), garantizando un código 100% puro en la nube.

## 🗂️ Estructura del Proyecto Actual
```text
lib/
├── core/
│   ├── database/
│   │   ├── database_helper.dart  # Esquema SQLite v4
│   │   └── sync_service.dart     # Esqueleto de sincronización
│   ├── router/
│   │   └── app_router.dart       # Rutas GoRouter
│   ├── services/
│   │   └── pdf_service.dart      # Generador de PDFs
│   └── widgets/
│       └── global_search_delegate.dart # Buscador Global nativo
├── data/
│   ├── models/                   # (user, product, movement, project, warehouse)
│   └── providers/                # Gestores de estado (ChangeNotifier)
├── features/
│   ├── admin/                    # CRUDs, qr_generator_screen.dart, backup_screen.dart
│   ├── auth/                     # login_screen, splash_screen
│   ├── dashboard/                # dashboard_screen (Gráficos), main_layout
│   ├── inventory/                # products, movements y movement_form_dialog
│   └── scanner/                  # scanner_screen.dart
└── main.dart                     # Punto de entrada
```

## 🛠️ Cómo Compilar y Ejecutar la App
1. **Descargar Dependencias:** `flutter pub get`
2. **Ejecutar en Emulador/Dispositivo (Debug):** `flutter run`
3. **Generar APK (Producción):** Ejecuta `flutter build apk`.
4. **Solución de Problemas (Caché):** Si surge un error de compilación tras actualizar paquetes, ejecuta `flutter clean` seguido de `flutter pub get`.
5. **Solución de Problemas (Cámara/ML Kit):** Para evitar que el compilador estricto (R8) triture la librería del escáner en los APKs, existe un archivo de reglas en `android/app/proguard-rules.pro`.

## 🟡 Pendiente (Próximos Pasos)
- **Notificaciones Push:** Implementar Firebase Cloud Messaging para alertas en vivo.
