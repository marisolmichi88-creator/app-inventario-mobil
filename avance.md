# Avance del Proyecto - Proenergim Mobile

Este documento sirve como bitácora para registrar los módulos completados, decisiones técnicas y la información necesaria para el desarrollo de la aplicación.

## Arquitectura de Datos (Decisión Técnica)
- **Enfoque Híbrido (Local-First):** La aplicación almacenará los datos de manera local (offline) utilizando una base de datos en el dispositivo (ej. SQLite / AsyncStorage). 
- **Sincronización Futura:** La arquitectura de los servicios (`src/services`) está diseñada para que en el futuro se implemente una cola de sincronización. Los datos creados o modificados localmente se marcarán como "pendientes de sincronización" y se enviarán a la base de datos MySQL en la nube cuando haya conexión y el backend esté disponible.

---

## Módulos Completados

### Fase de Preparación
- [x] **Carga inicial de datos:** Inserción de 122 productos reales desde Excel hacia la estructura de datos locales (`mockInventory.ts`).
- [x] **Evaluación de requerimientos:** Creación del documento `RF.md` analizando la plantilla base frente a los RF/RNF.
- [x] **Definición de arquitectura offline:** Establecimiento del enfoque *Local-First* con preparación para futura sincronización en la nube.

## Próximos Pasos (Pendientes)

### Sprint 1 – Gestión básica del sistema
- [x] **HU01 – Iniciar sesión:** Implementar pantalla de Login con protección de rutas y sesión persistente real (`AuthContext.tsx`).
  - **Credenciales de prueba (Admin):** 
    - Correo: `admin@proenergim.com`
    - Contraseña: `123456`
- [x] **Gestión de Base de Datos Local:** Configurar SQLite (`expo-sqlite`) y `<SQLiteProvider>` para datos reales y offline (configurado en modo de memoria temporal para evitar bloqueos del navegador).
- [x] **CRUD Usuarios:** Vistas para listar, registrar, editar y desactivar administradores/operarios (Módulo Admin).
- [x] **CRUD Categorías:** Vistas para listar, registrar y editar categorías (Módulo Admin).
- [x] **CRUD Productos:** Vistas para registrar, editar y desactivar productos.
- [x] **Módulo de Movimientos:** Interfaz de historial de entradas/salidas y formulario modal con actualización automática del stock de productos.
- [x] **Módulo Escáner (Sprint 2):** Integración de `expo-camera` para leer códigos de barras, enlazado directamente al formulario de Movimientos.
- [x] **Gestión de Proyectos (Sprint 3):** CRUD de Proyectos e integración con el formulario de movimientos (RF15, RF16, RF23).
- [x] **Mejoras Lógicas y UX (Sprint 4):** Dashboard interactivo, filtros rápidos de stock en productos, alertas visuales de peligro y bloqueos/warnings inteligentes al registrar salidas (RF13, RF17, RF24).
- [x] **Filtros Avanzados y Exportación (Sprint 5):** Funcionalidad de exportación de historial de movimientos a formato CSV (Excel) compartible, y filtros dinámicos por almacenes (RF13, RF21).
- [x] **Completar Panel de Administración (Sprint 6):** Construcción del CRUD de Almacenes (`warehouses.tsx`) para gestionar las ubicaciones físicas de inventario (RF12), complementando a Usuarios y Categorías del Sprint 1.
