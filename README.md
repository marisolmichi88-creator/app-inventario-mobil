# Inventario Proenergim Mobile

Plantilla frontend para la app movil de inventario de Proenergim E.I.R.L.

## Estado actual

Repositorio base para iniciar el desarrollo movil. Ya incluye una primera estructura de pantallas, datos simulados y documentacion tecnica para conectar un backend despues.

## Tecnologia elegida

- React Native con Expo.
- TypeScript.
- Expo Router para navegacion.
- Estructura preparada para conectar un backend despues.

Elegimos Expo porque la documentacion oficial de React Native recomienda iniciar apps nuevas con un framework, y Expo reduce configuracion para camara, rutas, pruebas en celular y builds.

Para este proyecto conviene React Native antes que web porque el requerimiento principal es registrar salidas en campo desde celular usando camara/codigo de barras. La web puede venir despues para administracion o reportes.

## Primeras pantallas

- Dashboard.
- Productos.
- Escaner.
- Movimientos.

## Alcance definido desde tus documentos

- Inicio de sesion.
- Roles de Administrador y Trabajador.
- Gestion de productos, categorias, almacenes y proyectos.
- Stock por almacen.
- Entradas y salidas de inventario.
- Salidas mediante escaneo de codigo de barras.
- Historial/auditoria de movimientos.
- Alertas de stock bajo.
- Costo de materiales por proyecto.
- Reportes y notificaciones para administracion.

## Cuando quieras correrla

```bash
pnpm install
pnpm start
```

Luego escaneas el QR con Expo Go o abres el emulador Android.

## ¿Cómo generar el APK instalable?

Para generar un archivo `.apk` puro e instalable en dispositivos Android sin depender de Expo Go, usamos el servicio gratuito **EAS Build** (Expo Application Services). No requiere instalar Android Studio ni configurar SDKs pesados localmente.

### Pasos:
1. Crea una cuenta gratuita en [expo.dev/signup](https://expo.dev/signup) si no la tienes.
2. Abre una terminal en la raíz del proyecto y ejecuta:
   ```bash
   npx eas-cli build -p android --profile preview
   ```
3. La terminal te pedirá iniciar sesión con tu cuenta de Expo.
4. El código se subirá a los servidores de Expo, quienes compilarán la aplicación. Este proceso suele demorar entre 5 a 10 minutos.
5. Al finalizar, la consola te mostrará un **Código QR** y un enlace directo. Escanéalo con tu celular para descargar e instalar el `.apk`.

*Nota: La configuración interna para que Expo sepa que debe generar un `.apk` y no un bundle para la Play Store ya está configurada en el archivo `eas.json`.*

## Backend futuro

La carpeta `src/services` ya separa la comunicacion con API. Cuando tengamos backend, cambiamos los datos simulados por llamadas reales sin rehacer las pantallas.

Documentos utiles:

- `docs/product-scope.md`
- `docs/database-model.md`
- `docs/backend-contract.md`

IMPORTANTE REVISAR AVANCE.MD Y RF.MD PARA CONOCER EL ESTADO ACTUAL DEL PROYECTO
