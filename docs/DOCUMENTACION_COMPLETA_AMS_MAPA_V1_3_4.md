# DOCUMENTACION COMPLETA - AMS MAPA

Version documentada: `1.3.4+9`  
Aplicacion: `AMS MAPA`  
Paquete Android: `com.dannyestrada.mtsanandres_base`  
Proyecto Firebase revisado: `mt-sanandres-app`  
Fecha de documentacion: 2026-08-16

---

## 1. Resumen General

AMS MAPA es una aplicacion Flutter para gestion tecnica en campo mediante tecnologia geoespacial. Su objetivo principal es permitir que un tecnico o supervisor pueda cargar mapas anteriores en formato KML/KMZ, visualizar activos en mapa, organizar rutas, crear tareas, registrar evidencias, guardar observaciones, revisar novedades y trabajar aun cuando no exista conexion constante.

La app esta disenada como una solucion `local-first`: los datos se guardan primero en el dispositivo y se mantiene una cola de cambios pendientes para sincronizacion. En la version actual, esa sincronizacion esta modelada localmente, pero todavia no envia datos a Firebase ni a un backend externo.

La version `1.3.4+9` incluye un mapa blindado para evitar pantalla blanca. El mapa operativo no depende del render visual nativo de Google Maps; usa OpenStreetMap, respaldo Carto, Esri para satelital y una base local vectorial visible aun si fallan los proveedores externos.

---

## 2. Objetivo de la App

La app busca optimizar el trabajo tecnico en campo para:

- Visualizar activos georreferenciados.
- Importar informacion de mapas anteriores en KML/KMZ.
- Clasificar activos por tipo y estado.
- Crear tareas automaticamente por activo importado.
- Agrupar tareas en rutas diarias por tecnico.
- Registrar evidencias fotograficas.
- Guardar observaciones tecnicas.
- Registrar ubicacion GPS cuando sea posible.
- Mantener historial local de novedades.
- Operar sin conexion mediante almacenamiento local.
- Preparar la base para futura sincronizacion con Firebase.

---

## 3. Alcance Actual

### Incluido

- App Flutter funcional.
- APK debug arm64 generado.
- Mapa blindado con respaldo visual local.
- Importacion KML/KMZ.
- Activos georreferenciados.
- Filtros por tipo y estado.
- Busqueda por nombre, ID, estado, archivo o coordenada.
- Ubicacion exacta con coordenadas y precision.
- Rutas diarias automaticas.
- Tareas por activo.
- Evidencias locales.
- Observaciones tecnicas.
- Historial de eventos.
- Modo online/offline simulado.
- Diagnostico de base local.
- Estado Firebase visible en Control.
- Validaciones automatizadas con `flutter test`.

### No Incluido Todavia

- Sincronizacion real con Firebase.
- Login de usuarios.
- Roles con permisos reales por autenticacion.
- Backend centralizado.
- Subida real de evidencias a almacenamiento remoto.
- Firma Android release de produccion.
- Panel web administrativo remoto.

---

## 4. Usuarios y Roles

La app maneja dos perfiles operativos dentro de la interfaz:

### Tecnico

Usuario que trabaja en campo. Puede:

- Ver activos en mapa.
- Revisar tareas asignadas.
- Agregar evidencia.
- Registrar observaciones.
- Cambiar estado de tareas.
- Usar ubicacion exacta.

### Supervisor

Usuario de control operativo. Puede:

- Revisar metricas.
- Revisar historial.
- Ver pendientes de sincronizacion.
- Cambiar tecnico activo.
- Cambiar modo online/offline.
- Limpiar operacion local.
- Revisar diagnostico de base local.
- Ver estado Firebase.

Nota: en la version actual los roles son funcionales a nivel de interfaz, no estan protegidos por autenticacion real.

---

## 5. Funciones Principales

### 5.1 Mapa Blindado

La app usa un mapa operativo resistente a fallos. El objetivo es evitar definitivamente que el usuario vea una pantalla blanca.

Capas usadas:

- OpenStreetMap para vista normal.
- Carto como respaldo de tiles.
- Esri World Imagery para vista satelital.
- Carto como respaldo de vista satelital.
- Base local vectorial de San Andres/Providencia.

Si fallan OSM, Esri, Carto, internet o los tiles de un nivel de zoom, la base local sigue dibujando:

- Territorio base.
- Grilla visual.
- Vias base.
- Etiquetas de referencia.
- Marcadores de referencia.

Indicadores visibles:

- `Mapa blindado`: estado normal.
- `Base local activa`: aparece cuando los tiles externos fallan.

### 5.2 Ubicacion Exacta

El boton de ubicacion permite obtener la posicion actual del dispositivo.

La app muestra:

- Marcador propio de "Mi ubicacion exacta".
- Latitud y longitud con 7 decimales.
- Precision en metros.
- Hora de lectura.
- Centrado automatico a zoom 19.

El servicio GPS usa:

```dart
LocationAccuracy.bestForNavigation
```

Esto solicita la mejor precision disponible en el telefono.

Condiciones para mejor resultado:

- GPS activo.
- Permiso de ubicacion concedido.
- Ubicacion precisa habilitada en Android.
- Buena senal GPS.
- Preferiblemente probar al aire libre.

### 5.3 Importacion KML/KMZ

La app permite subir mapas anteriores en formato:

- `.kml`
- `.kmz`

Tipos de activos importables:

- Cajas.
- Trafos.
- Gabinetes.
- Concentradores.

Proceso:

1. Tocar el boton de subir KML/KMZ.
2. Elegir el tipo de activo.
3. Seleccionar archivo.
4. La app lee los `Placemark`.
5. Extrae la primera coordenada valida de cada punto.
6. Crea activos.
7. Crea tareas asociadas.
8. Crea o actualiza ruta diaria del tecnico activo.
9. Ajusta el mapa para mostrar los puntos importados.

Si un `Placemark` no tiene coordenadas validas, se omite y se cuenta como omitido.

### 5.4 Activos

Un activo representa un punto operativo en mapa.

Campos principales:

- `id`
- `name`
- `type`
- `latitude`
- `longitude`
- `sourceFile`
- `importedAt`
- `status`
- `lastObservation`
- `lastUpdatedAt`

Tipos:

- `caja`
- `trafo`
- `gabinete`
- `concentrador`

Estados:

- `activo`
- `pendiente`
- `danado`
- `atendido`

### 5.5 Busqueda y Filtros

La busqueda permite encontrar activos por:

- ID.
- Nombre.
- Tipo.
- Estado.
- Archivo de origen.
- Observacion.
- Coordenada.

Filtros disponibles:

- Por tipo de activo.
- Por estado operativo.

En la version `1.3.4`, estos filtros quedaron en secciones desplegables para limpiar la interfaz.

### 5.6 Rutas

La app crea una ruta diaria automaticamente para el tecnico activo cuando se importan activos.

Campos de ruta:

- `id`
- `name`
- `technicianId`
- `date`
- `taskIds`

La ruta agrupa tareas generadas desde activos importados en el mismo dia.

### 5.7 Tareas

Cada activo importado genera una tarea.

Estados de tarea:

- `pendiente`
- `enProceso`
- `completada`
- `bloqueada`

Una tarea contiene:

- Activo asociado.
- Ruta asociada.
- Tecnico.
- Estado.
- Observacion.
- Evidencias.
- Fecha de creacion.
- Fecha de actualizacion.
- Coordenada de cierre si aplica.

Regla importante:

- Para completar una tarea, debe tener evidencia.

### 5.8 Evidencias

La app permite adjuntar archivos de evidencia:

- `.jpg`
- `.jpeg`
- `.png`
- `.heic`
- `.webp`

La evidencia guarda:

- ID.
- Nombre de archivo.
- Ruta local del archivo.
- Tamano.
- Fecha de creacion.
- Latitud si se pudo obtener GPS.
- Longitud si se pudo obtener GPS.

Nota: en la version actual, la evidencia queda registrada por referencia local. No se sube a Firebase Storage ni a ningun backend remoto.

### 5.9 Observaciones

Cada tarea puede recibir observaciones tecnicas.

Al guardar una observacion:

- Se actualiza la tarea.
- Se actualiza el activo relacionado.
- Se registra evento en historial.
- Se persiste el cambio localmente.

### 5.10 Historial de Novedades

La app registra eventos operativos:

- Importaciones.
- Cambios de tarea.
- Evidencias.
- Sincronizaciones.
- Eventos del sistema.

Cada evento contiene:

- `id`
- `type`
- `title`
- `detail`
- `createdAt`
- `synced`

### 5.11 Modo Offline / Online

La app permite alternar entre:

- Modo online.
- Modo offline.

En modo offline, los eventos quedan marcados como pendientes.

En modo online, los nuevos eventos se marcan como sincronizados.

Importante: esta sincronizacion aun es local. El boton de sincronizar marca eventos como enviados dentro del dispositivo, pero todavia no envia datos a Firebase.

### 5.12 Panel Control

El panel Control muestra:

- Activos.
- Tareas.
- Tareas completadas.
- Tareas bloqueadas.
- Evidencias.
- Pendientes de sincronizacion.
- Rol activo.
- Tecnico activo.
- Modo online/offline.
- Estado de base local.
- Estado Firebase.
- Seguridad / configuracion Google Maps.

En la version `1.3.4` se agrego diagnostico visible de la base local.

---

## 6. Base de Datos Local

La app usa `shared_preferences` como almacenamiento local.

Clave usada:

```text
ams_mapa_operation_snapshot_v2
```

El almacenamiento guarda un snapshot completo de la operacion:

```json
{
  "assets": [],
  "tasks": [],
  "routes": [],
  "events": [],
  "onlineMode": true,
  "activeRole": "supervisor",
  "activeTechnician": "Tecnico 1"
}
```

### Diagnostico Local

La version `1.3.4` incluye `OperationStoreDiagnostics`, que revisa:

- Si existe data local.
- Si el JSON es valido.
- Tamano del guardado.
- Cantidad de activos.
- Cantidad de tareas.
- Cantidad de rutas.
- Cantidad de eventos.
- Cantidad de evidencias.
- Pendientes de sincronizacion.
- Ultimo evento registrado.

Estados posibles:

- `Base local vacia`
- `Base local sana`
- `Base local con error`

### Limitaciones de shared_preferences

`shared_preferences` es suficiente para MVP y datos pequenos/medianos, pero no es ideal para bases grandes.

Riesgos:

- El JSON puede crecer mucho si se importan miles de puntos.
- Las evidencias solo guardan referencia local, no archivo binario.
- No hay consultas indexadas.
- No hay control multiusuario.
- No hay auditoria remota real.

Recomendacion futura:

- Migrar datos operativos a Firebase Firestore o SQLite local + sincronizacion remota.

---

## 7. Estado Firebase

Se reviso Firebase desde Firebase CLI.

### Proyecto

```text
projectId: mt-sanandres-app
estado: ACTIVE
```

### App Android

```text
package: com.dannyestrada.mtsanandres_base
estado: ACTIVE
```

### Firestore

```text
database: (default)
tipo: FIRESTORE_NATIVE
region: nam5
freeTier: true
estado: activa
```

### Realtime Database

```text
instance: mt-sanandres-app-default-rtdb
region: us-central1
url: https://mt-sanandres-app-default-rtdb.firebaseio.com
estado: ACTIVE
```

Lectura superficial de raiz:

```text
null
```

Interpretacion:

- Realtime Database existe.
- Esta activa.
- La raiz esta vacia al momento de revision.

### Estado de Integracion en la App

La app todavia no tiene SDK Firebase conectado.

No existen en el codigo actual:

- `firebase_core`
- `cloud_firestore`
- `firebase_database`
- `firebase_storage`
- `google-services.json`

Por eso la app muestra Firebase como revisado pero no conectado.

### Siguiente Paso Recomendado Para Firebase

1. Descargar `google-services.json` de la app Android registrada.
2. Colocarlo en:

```text
android/app/google-services.json
```

3. Agregar dependencias:

```yaml
firebase_core:
cloud_firestore:
firebase_storage:
firebase_auth:
```

4. Inicializar Firebase en `main.dart`.
5. Crear servicio de sincronizacion.
6. Mapear colecciones:

```text
assets
tasks
routes
events
evidence
users
```

7. Crear reglas de seguridad.
8. Probar sincronizacion con usuario tecnico/supervisor.

---

## 8. Google Maps y API Key

La app conserva configuracion para Google Maps, pero el mapa operativo principal no depende visualmente de Google.

La API key se inyecta mediante:

```text
MAPS_API_KEY
```

Fuentes posibles:

- Variable de entorno.
- `android/gradle.properties` local.

La clave no debe quedar quemada en el codigo fuente.

Android Manifest:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}" />
```

Permisos Android:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Estado validado:

- Key inyectada en APK: `True`.
- Longitud detectada: `39`.
- La clave no se incluye en el zip de codigo fuente.

---

## 9. Arquitectura Tecnica

### Framework

```text
Flutter
Dart SDK >=3.0.0 <4.0.0
```

### Dependencias Principales

```yaml
file_picker: seleccion de archivos KML/KMZ/evidencia
archive: lectura de KMZ
xml: parseo de KML
flutter_map: mapa operativo
latlong2: coordenadas para flutter_map
google_maps_flutter: modelos/control Google Maps
geolocator: GPS y permisos de ubicacion
shared_preferences: almacenamiento local
```

### Estructura Principal

```text
lib/
  app.dart
  ui/
    home_map_page.dart
  models/
    asset_point.dart
    asset_status.dart
    asset_type.dart
    field_route.dart
    field_task.dart
    import_result.dart
    operation_event.dart
    operation_snapshot.dart
  services/
    kml_import_service.dart
    location_service.dart
    marker_clusterer.dart
    operation_store.dart
```

### Pantalla Principal

Archivo:

```text
lib/ui/home_map_page.dart
```

Responsabilidades:

- Render del mapa.
- Importacion.
- Filtros.
- Busqueda.
- Rutas.
- Tareas.
- Evidencias.
- Observaciones.
- Historial.
- Control.
- Diagnostico DB.
- Estado Firebase.

### Servicios

#### KmlImportService

Archivo:

```text
lib/services/kml_import_service.dart
```

Responsable de:

- Leer KML.
- Abrir KMZ.
- Buscar primer KML dentro del KMZ.
- Parsear XML.
- Extraer coordenadas.
- Crear `AssetPoint`.
- Contar puntos omitidos.

#### LocationService

Archivo:

```text
lib/services/location_service.dart
```

Responsable de:

- Verificar GPS activo.
- Solicitar permiso.
- Manejar permiso denegado.
- Obtener posicion con alta precision.

#### MarkerClusterer

Archivo:

```text
lib/services/marker_clusterer.dart
```

Responsable de:

- Agrupar activos en clusters segun zoom.
- Reducir saturacion visual de marcadores.

#### OperationStore

Archivo:

```text
lib/services/operation_store.dart
```

Responsable de:

- Cargar snapshot local.
- Guardar snapshot local.
- Limpiar datos.
- Inspeccionar estado de base local.

---

## 10. Modelo de Datos

### AssetPoint

Representa activo geografico.

```json
{
  "id": "caja_1",
  "name": "Caja 001",
  "type": "caja",
  "latitude": 12.5847,
  "longitude": -81.7006,
  "sourceFile": "archivo.kml",
  "importedAt": "2026-08-16T00:00:00.000",
  "status": "pendiente",
  "lastObservation": "",
  "lastUpdatedAt": null
}
```

### FieldTask

Representa tarea tecnica asociada a un activo.

```json
{
  "id": "task_1",
  "assetId": "caja_1",
  "routeId": "route_1",
  "technicianId": "Tecnico 1",
  "status": "pendiente",
  "observation": "",
  "evidence": [],
  "createdAt": "2026-08-16T00:00:00.000",
  "updatedAt": "2026-08-16T00:00:00.000",
  "completedLatitude": null,
  "completedLongitude": null
}
```

### EvidenceRecord

Representa evidencia adjunta.

```json
{
  "id": "ev_1",
  "fileName": "foto.jpg",
  "sizeBytes": 120000,
  "createdAt": "2026-08-16T00:00:00.000",
  "localPath": "ruta/local/foto.jpg",
  "latitude": 12.5847,
  "longitude": -81.7006
}
```

### FieldRoute

Representa ruta diaria.

```json
{
  "id": "route_1",
  "name": "Ruta 2026-08-16",
  "technicianId": "Tecnico 1",
  "date": "2026-08-16T00:00:00.000",
  "taskIds": ["task_1"]
}
```

### OperationEvent

Representa novedad/historial.

```json
{
  "id": "event_1",
  "type": "importacion",
  "title": "Importacion de cajas",
  "detail": "10 activos y 10 tareas desde cajas.kml",
  "createdAt": "2026-08-16T00:00:00.000",
  "synced": true
}
```

### OperationSnapshot

Representa el estado completo local.

```json
{
  "assets": [],
  "tasks": [],
  "routes": [],
  "events": [],
  "onlineMode": true,
  "activeRole": "supervisor",
  "activeTechnician": "Tecnico 1"
}
```

---

## 11. Flujo Operativo Recomendado

### Preparacion

1. Instalar APK.
2. Abrir app.
3. Conceder permisos de ubicacion si se van a usar GPS/evidencias.
4. Revisar que el mapa muestre `Mapa blindado`.
5. Entrar a Control y verificar base local.

### Importar Mapas Anteriores

1. Tocar boton de subir KML/KMZ.
2. Seleccionar tipo de activo.
3. Elegir archivo.
4. Confirmar que los puntos aparezcan.
5. Revisar filtros si algun activo no aparece.

### Trabajo en Campo

1. Ir a mapa.
2. Tocar activo.
3. Abrir tarea.
4. Adjuntar evidencia.
5. Registrar observacion.
6. Cambiar estado.
7. Completar tarea si ya tiene evidencia.

### Supervision

1. Ir a Control.
2. Revisar metricas.
3. Revisar estado de base local.
4. Revisar pendientes.
5. Revisar historial de novedades.

---

## 12. Instalacion del APK

Archivo generado:

```text
C:\Users\CONVENIO\Documents\Codex\2026-07-16\c\outputs\version_1_3_4\AMSMAPA_V1_3_4_interfaz_limpia_db_firebase_arm64.apk
```

Recomendacion:

1. Desinstalar una version anterior si el telefono conserva datos viejos.
2. Instalar APK.
3. Permitir instalacion desde origen externo si Android lo pide.
4. Abrir la app.
5. Conceder permiso de ubicacion precisa.

Nota:

- Este APK es debug arm64.
- Es adecuado para pruebas en telefonos Android modernos arm64.
- Para produccion se debe generar APK/AAB release firmado.

---

## 13. Compilacion y Desarrollo

### Obtener Dependencias

```powershell
flutter pub get
```

### Formatear

```powershell
dart format lib test
```

### Analizar

```powershell
flutter analyze
```

### Ejecutar Pruebas

```powershell
flutter test
```

### Generar APK Debug arm64

```powershell
flutter build apk --debug --target-platform android-arm64
```

### Generar Build Web

```powershell
flutter build web
```

---

## 14. Firma Android Release

Para firma release, crear:

```text
android/key.properties
```

Contenido esperado:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=../release-keystore.jks
```

El archivo `android/app/build.gradle.kts` usa esa firma si `key.properties` existe.

Si no existe:

- El release no queda firmado con llave de produccion.
- Debug usa firma debug de la maquina.

---

## 15. Pruebas y Validacion

La version `1.3.4+9` fue validada con:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
```

Resultados:

- `flutter analyze`: sin errores.
- `flutter test`: todas las pruebas pasaron.
- APK generado.
- Manifest Android verificado.
- Key de Maps inyectada.
- Permisos verificados.
- Zip de codigo sin archivos locales sensibles.

Pruebas automatizadas cubren:

- Parseo KML.
- Parseo KMZ.
- UI principal.
- Mapa blindado sin Google nativo.
- Diagnostico de base local.
- Estado Firebase visible.

---

## 16. Seguridad

### API Key Google Maps

La key no debe quedar en codigo fuente.

No incluir en repositorio:

- `android/gradle.properties`
- `android/local.properties`
- `key.properties`
- keystores privados

### Firebase

Antes de conectar Firebase:

- Definir reglas de seguridad.
- No dejar bases en modo abierto.
- Definir usuarios y roles.
- Limitar escritura por tecnico/supervisor.
- Validar estructura de documentos.

### Evidencias

Actualmente las evidencias son rutas locales. Para produccion:

- Subir archivos a Firebase Storage.
- Guardar URL segura.
- Usar reglas por usuario/rol.
- Evitar rutas locales como unica referencia.

---

## 17. Solucion de Problemas

### El mapa aparece en blanco

La version `1.3.4` tiene mapa blindado. Si aun se ve blanco:

1. Confirmar que se instalo el APK correcto V1.3.4.
2. Desinstalar versiones anteriores.
3. Instalar de nuevo.
4. Abrir con internet.
5. Esperar unos segundos.
6. Si fallan tiles, debe aparecer base local.

Si no aparece ni base local:

- Puede ser un fallo de instalacion.
- Puede estar abriendo una version anterior.
- Puede haber error de render Flutter del dispositivo.

### No aparece mi ubicacion

Revisar:

- GPS activo.
- Permiso de ubicacion concedido.
- Ubicacion precisa activada.
- Probar al aire libre.
- Reiniciar app.

### No importa KML/KMZ

Revisar:

- Archivo debe ser `.kml` o `.kmz`.
- KMZ debe contener al menos un KML.
- KML debe tener `Placemark`.
- Cada punto debe tener `coordinates`.
- Coordenadas deben estar en formato `longitud,latitud`.

### No puedo completar tarea

La app exige evidencia antes de completar.

Solucion:

1. Abrir tarea.
2. Adjuntar evidencia.
3. Cambiar estado a completada.

### Firebase aparece no sincronizado

Es correcto en esta version.

Firebase fue revisado y existe, pero la app todavia no tiene SDK Firebase integrado.

---

## 18. Roadmap Recomendado

### Fase 1 - Firebase Real

- Agregar `firebase_core`.
- Descargar `google-services.json`.
- Inicializar Firebase.
- Crear servicio `FirebaseSyncService`.
- Subir assets, tasks, routes y events.
- Subir evidencias a Firebase Storage.

### Fase 2 - Usuarios y Roles

- Agregar Firebase Auth.
- Crear usuarios tecnico/supervisor.
- Aplicar permisos reales.
- Separar vistas por rol.

### Fase 3 - Sincronizacion Robusta

- Cola offline real.
- Reintentos.
- Resolucion de conflictos.
- Timestamp servidor.
- Estado por documento.

### Fase 4 - Panel Web

- Dashboard de supervisor.
- Mapa web en tiempo real.
- Exportes.
- Reportes por tecnico.

### Fase 5 - Produccion

- Firma release.
- AAB para Play Store o distribucion empresarial.
- Reglas Firebase cerradas.
- Backup.
- Monitoreo.

---

## 19. Entregables Actuales

### APK

```text
C:\Users\CONVENIO\Documents\Codex\2026-07-16\c\outputs\version_1_3_4\AMSMAPA_V1_3_4_interfaz_limpia_db_firebase_arm64.apk
```

### Codigo Fuente

```text
C:\Users\CONVENIO\Documents\Codex\2026-07-16\c\outputs\version_1_3_4\AMSMAPA_V1_3_4_codigo_fuente.zip
```

### Notas de Version

```text
C:\Users\CONVENIO\Documents\Codex\2026-07-16\c\outputs\version_1_3_4\NOTAS_VERSION_1_3_4.txt
```

### Documentacion Completa

```text
C:\Users\CONVENIO\Documents\Codex\2026-07-16\c\outputs\DOCUMENTACION_COMPLETA_AMS_MAPA_V1_3_4.md
```

---

## 20. Glosario

### Activo

Punto geografico operativo importado desde KML/KMZ.

### KML

Formato geoespacial basado en XML que contiene puntos, lineas o poligonos.

### KMZ

Archivo comprimido que contiene uno o varios KML.

### Tarea

Trabajo operativo creado para atender un activo.

### Ruta

Agrupacion diaria de tareas para un tecnico.

### Evidencia

Archivo fotografico adjunto a una tarea.

### Cola Offline

Lista de eventos locales pendientes de sincronizar.

### Mapa Blindado

Estrategia de mapa con proveedores externos y base local para evitar pantalla blanca.

### Firebase

Plataforma de backend de Google. En esta app esta revisado y disponible como proyecto, pero aun no integrado al codigo Flutter.

---

## 21. Estado Final

AMS MAPA V1.3.4 funciona como una aplicacion local-first para gestion tecnica en campo. La app ya permite operar mapas, activos, rutas, tareas, evidencias, observaciones, historial, ubicacion exacta y diagnostico de base local. Firebase existe y esta activo en el proyecto, pero todavia falta integrar el SDK en Flutter para sincronizacion real.

La prioridad tecnica recomendada para la siguiente version es conectar Firebase de forma segura y mantener la operacion offline como respaldo.
