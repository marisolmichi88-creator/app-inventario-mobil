# Evaluación de Requerimientos - Proenergim Mobile

Este documento detalla el estado actual del proyecto de la aplicación móvil de inventario frente a los requerimientos funcionales y no funcionales definidos. El proyecto actual es una **plantilla frontend** con datos simulados (mock data).

## Requerimientos Funcionales (RF)

### 🟢 Implementado (Parcial o Totalmente)
- **RF04. Gestión de productos (Lectura):** Existe la pantalla `products.tsx` que lista los productos (con datos de prueba). Aún falta la lógica de registrar, editar y eliminar.
- **RF07. Consulta de stock:** La lista de productos muestra el stock disponible actual.
- **RF17. Historial de movimientos:** Existe la pantalla `movements.tsx` que muestra una lista del historial simulado de entradas y salidas.
- **RF20. Dashboard administrativo:** Existe la pantalla `dashboard.tsx` con indicadores iniciales simulados.
- **RF05, RF09, RF10. Escaneo de código de barras:** Se implementó `expo-camera` para leer códigos QR/Barras y enlazarlos al formulario de movimientos.
- **RF15, RF16, RF23. Operaciones de Proyectos (Costos, materiales):** Se creó el CRUD de Proyectos y se obligó a seleccionarlos al hacer salidas en los movimientos.
- **RF13, RF17, RF21, RF24. Visualización, filtros, reportes y alertas de stock bajo:** Se implementó lógica para advertencias de stock mínimo en ventas, filtros dinámicos (Almacén y Stock Bajo) en la lista de productos, dashboard interactivo y exportación de movimientos a CSV.

### 🔴 No Implementado (Falta desarrollar / Suspendido temporalmente)
- **RF11, RF18, RF19, RF22.** Backend remoto (Nube / MySQL), reportes PDF avanzados y notificaciones push en tiempo real.
- **RF01. Inicio de sesión:** No existe pantalla de autenticación ni validación de credenciales.
- **RF02, RF25. Gestión de usuarios y Roles:** No hay lógica de administración de usuarios (Admin/Trabajador).
- **RF03, RF12, RF14. Gestión de categorías, almacenes y proyectos (CRUD):** No hay pantallas ni formularios para crear, editar o eliminar estas entidades.
- **RF06. Registro de número de serie:** El modelo actual simulado no contempla un flujo específico de números de serie.
- **RF08. Registro de entradas:** No hay formulario para ingresar stock nuevo.
- **RF11. Descuento automático de stock:** No hay backend que procese la resta de stock al registrar salidas.
- **RF13, RF17. Visualización por almacén y filtros:** Faltan los filtros específicos por almacén en la vista de productos.
- **RF18. Auditoría de movimientos completa:** Se requiere backend.
- **RF19, RF22. Notificaciones automáticas:** No hay sistema de alertas en tiempo real o bandeja de notificaciones implementada.
- **RF21. Reportes:** No se ha integrado ninguna librería para exportar a Excel o PDF desde la app.
- **RF24. Alertas de stock bajo:** Falta implementar la lógica visual en el frontend y en el backend para notificar cuando cruce el mínimo.

---

## Requerimientos No Funcionales (RNF)

- **RNF01 (Accesible móvil y web):** 🟢 Cumple. Desarrollado en React Native con Expo, lo que permite exportar a iOS, Android y potencialmente Web.
- **RNF02 (Protección por Autenticación):** 🔴 Falta. Requiere implementar sistema JWT o sesiones (Sprint 1).
- **RNF03 (Base de datos MySQL):** 🔴 Falta. Actualmente usa datos estáticos simulados. Se necesita construir o conectar la API.
- **RNF04 (Respuesta < 3s):** 🟡 Parcial. Al usar datos estáticos es rápido, pero dependerá de la API futura.
- **RNF05 (Trazabilidad):** 🔴 Falta. Requiere diseño completo en el backend.
- **RNF06 (Interfaz intuitiva):** 🟢 Cumple. La estructura base de las pantallas es limpia y estandarizada.
- **RNF07 (Permitir ampliaciones):** 🟢 Cumple. Arquitectura modular (`app`, `components`, `data`, `services`).
- **RNF08 (Seguridad):** 🔴 Falta. Requiere desarrollo de roles y tokens en el backend.

---

## Resumen y Próximos Pasos (Sprints)

Actualmente, el proyecto se encuentra en una **fase temprana de maquetación (Mockups/Frontend base)**. Para cumplir con las historias de usuario (HU) descritas, se debe priorizar lo siguiente:

1. **Backend / Base de datos (MySQL):** Es obligatorio para cumplir casi el 80% de los requerimientos.
2. **Sprint 1:** Desarrollar pantallas de Login y CRUDs básicos (Administración de usuarios y productos).
3. **Sprint 2:** Darle funcionalidad real al componente `scanner.tsx` para escanear y generar movimientos.
4. **Sprint 3 y 4:** Conectar los flujos de proyectos, costos, y notificaciones.
