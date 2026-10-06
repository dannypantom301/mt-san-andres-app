# MT San Andres - Version 1.3.4

Aplicacion Flutter para gestion tecnica en campo con mapa, activos, rutas, tareas, evidencias, historial local y cola offline.

Version actual: `1.3.4+9`

Documentacion completa: [docs/DOCUMENTACION_COMPLETA_MT_SAN_ANDRES_V1_3_4.md](docs/DOCUMENTACION_COMPLETA_MT_SAN_ANDRES_V1_3_4.md)

## Funciones incluidas

- Mapa blindado con OpenStreetMap, respaldo Carto y base local vectorial para evitar pantalla blanca.
- Vista satelital Esri disponible desde el boton de capas, con respaldo Carto si falla el proveedor.
- Interfaz mas limpia con filtros desplegables e indicadores compactos en el mapa.
- Ubicacion exacta visible con marcador propio, coordenadas de 7 decimales y precision en metros.
- Importacion KML/KMZ de cajas, trafos, gabinetes y concentradores.
- Estados por punto: activo, pendiente, danado y atendido.
- Filtros por tipo de activo y por estado operativo.
- Busqueda por nombre, ID, estado, archivo o coordenada.
- Ruta diaria automatica por tecnico activo.
- Tareas por activo importado.
- Cambio de estado de tarea: pendiente, en proceso, completada o bloqueada.
- Evidencia obligatoria antes de completar una tarea.
- Registro de observaciones tecnicas.
- Registro GPS al agregar evidencia o completar una tarea cuando el permiso esta disponible.
- Historial de novedades por importacion, tarea, evidencia, sistema y sincronizacion.
- Modo offline: los cambios se guardan localmente y quedan pendientes de sincronizar.
- Panel basico de supervision con metricas de activos, tareas, evidencias y pendientes.
- Persistencia local con `shared_preferences`.
- Diagnostico de base local y estado Firebase visible desde Control.

## Alcance actual

La app ya funciona como MVP local-first. La sincronizacion esta modelada como cola local, pero todavia no envia datos a un servidor real. Firebase fue revisado: el proyecto `mt-sanandres-app` esta activo, la app Android esta registrada y Realtime Database esta vacia, pero esta compilacion Flutter aun no incluye `firebase_core`, `cloud_firestore` ni `google-services.json`. Para supervision en tiempo real se debe conectar esta cola a Firebase o a una API/backend centralizado.

El mapa principal inicia con OpenStreetMap normal, usa Carto como respaldo y siempre dibuja una base local vectorial de San Andres/Providencia debajo de los tiles. Asi no queda en blanco aunque falle la API key de Google, el proveedor externo, la red o un nivel de zoom sin tiles.

## Configurar Google Maps

La llave no esta quemada en el codigo fuente.

Android:

```powershell
$env:MAPS_API_KEY="TU_LLAVE_ANDROID_RESTRINGIDA"
flutter run
```

Tambien puedes crear `android/gradle.properties` localmente y agregar:

```properties
MAPS_API_KEY=TU_LLAVE_ANDROID_RESTRINGIDA
```

Web:

Edita `web/google_maps_config.js`:

```javascript
window.googleMapsApiKey = "TU_LLAVE_WEB_RESTRINGIDA";
```

iOS:

Define `GOOGLE_MAPS_API_KEY` en la configuracion de build de Xcode o en tus `.xcconfig` locales.

## Comandos utiles

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

## Firma Android release

Para firmar release, crea `android/key.properties` con:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=../release-keystore.jks
```

El build release usara esa firma si el archivo existe. Si no existe, no se usa la llave debug como firma de produccion.
