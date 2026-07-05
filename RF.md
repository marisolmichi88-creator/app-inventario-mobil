# Requerimientos Funcionales y No Funcionales - Proenergim Mobile (Flutter)

## Requerimientos Funcionales
- **RF01. Inicio de sesión:** El sistema permitirá a los usuarios autenticarse mediante correo electrónico y contraseña.
- **RF02. Gestión de usuarios:** El administrador podrá registrar, editar, activar y desactivar usuarios.
- **RF03. Gestión de categorías:** El administrador podrá registrar, editar, eliminar y consultar categorías de productos.
- **RF04. Gestión de productos:** El administrador podrá registrar, editar, eliminar y consultar productos del inventario.
- **RF05. Identificación por código de barras:** El sistema permitirá asociar un código de barras único a cada producto.
- **RF06. Registro de número de serie:** El sistema permitirá registrar números de serie para equipos que lo requieran.
- **RF07. Consulta de stock:** El sistema permitirá visualizar el stock disponible de cada producto por almacén.
- **RF08. Registro de entradas:** El administrador podrá registrar ingresos de productos a un almacén específico.
- **RF09. Registro de salidas mediante escaneo:** El trabajador podrá registrar salidas de productos mediante el escaneo del código de barras, indicando el proyecto o destino correspondiente.
- **RF10. Reconocimiento automático:** El sistema mostrará automáticamente la información del producto escaneado.
- **RF11. Descuento automático de stock:** El sistema actualizará automáticamente el inventario cuando se registre una salida.
- **RF12. Gestión de almacenes:** El sistema permitirá administrar múltiples almacenes.
- **RF13. Visualización por almacén:** El sistema permitirá consultar el stock de cada almacén por separado.
- **RF14. Gestión de proyectos:** El sistema permitirá registrar, editar y consultar proyectos asociados al uso de materiales.
- **RF15. Asignación de materiales a proyectos:** El sistema permitirá relacionar productos retirados con un proyecto específico.
- **RF16. Cálculo de costo por proyecto:** El sistema calculará automáticamente el costo acumulado de materiales utilizados por proyecto.
- **RF17. Historial de movimientos:** El sistema almacenará el historial completo de entradas y salidas.
- **RF18. Auditoría de movimientos de inventario:** El sistema registrará: Usuario, Producto, Cantidad, Fecha, Hora, Almacén, Destino/Proyecto, Tipo de movimiento.
- **RF19. Notificaciones automáticas:** El sistema enviará notificaciones automáticas a los administradores cuando se registre una salida de producto.
- **RF20. Dashboard administrativo:** El sistema mostrará indicadores operativos del almacén (Stock actual, Alertas, Movimientos, Proyectos, Reportes).
- **RF21. Reportes:** El administrador podrá generar reportes de inventario, movimientos y proyectos.
- **RF22. Consulta de notificaciones:** El administrador podrá visualizar el historial de notificaciones generadas por movimientos de inventario.
- **RF23. Consulta de materiales por proyecto:** El sistema permitirá visualizar los materiales y equipos utilizados en cada proyecto.
- **RF24. Alerta de stock bajo:** El sistema generará alertas automáticas cuando el stock de un producto alcance niveles mínimos establecidos por el administrador.
- **RF25. Gestión de roles:** El sistema permitirá asignar roles de Administrador o Trabajador a los usuarios para controlar el acceso a las funcionalidades disponibles.

## Requerimientos No Funcionales
- **RNF01:** El sistema deberá ser accesible desde dispositivos móviles y permitir futuras adaptaciones para entornos web.
- **RNF02:** La autenticación deberá proteger el acceso al sistema e incluir recuperación segura vía código OTP al correo.
- **RNF03:** La información deberá almacenarse en una base de datos en la nube (Supabase / PostgreSQL) en tiempo real.
- **RNF04:** El sistema deberá responder en menos de 3 segundos para operaciones comunes.
- **RNF05:** El sistema deberá mantener trazabilidad completa de los movimientos de inventario.
- **RNF06:** La interfaz deberá ser intuitiva y fácil de utilizar para personal sin conocimientos técnicos.
- **RNF07:** La aplicación deberá permitir futuras ampliaciones como transferencias entre almacenes.
- **RNF08:** La información deberá almacenarse de forma segura y protegida contra accesos no autorizados.

## Casos de Uso del Sistema

### Actores del Sistema
- **Administrador:** Gestiona usuarios, roles, categorías, productos, almacenes, proyectos. Registra entradas, consulta inventario, historial, notificaciones, reportes y supervisa vía dashboard.
- **Trabajador:** Escanea productos, consulta información, registra salidas, asocia materiales a proyectos y consulta inventario básico.

### Detalle de Casos de Uso (Resumen)
- **CU01 – Iniciar Sesión:** Acceso por credenciales y roles.
- **CU02 a CU04, CU08, CU09 – Gestión (CRUD):** Usuarios, Categorías, Productos, Proyectos, Almacenes.
- **CU05 / CU07 – Registrar Entradas y Salidas:** Afectación de inventario con validación de stock y asociación a proyectos.
- **CU06 – Escanear Producto:** Identificación automática.
- **CU10 a CU16 – Consultas y Reportes:** Inventario, Historial, Dashboard, Reportes, Notificaciones, Materiales por Proyecto, Alertas de Stock.
- **CU17 – Asignar Roles:** Control de accesos de usuarios.
