# Changelog

## 1.3.4+9 - Version 1.3.4 interfaz limpia + diagnostico

- Se limpia el panel lateral con filtros desplegables por tipo y estado.
- Se reemplaza el contador largo del mapa por indicadores compactos.
- Se agrega diagnostico de base local: estado, tamano, activos, tareas, rutas, eventos, evidencias y pendientes.
- Se agrega estado Firebase visible: proyecto `mt-sanandres-app` activo, app Android registrada, Realtime Database vacia y codigo Flutter aun sin SDK Firebase.
- Se agrega boton para revisar/actualizar el estado de la base desde Control.
- Se agregan pruebas para el diagnostico local y el estado Firebase.

## 1.3.3+8 - Version 1.3.3 mapa blindado

- El mapa operativo deja de depender del render nativo de Google para evitar pantalla blanca.
- Se agrega base local vectorial de San Andres/Providencia visible aun si fallan OSM, Esri o internet.
- El mapa normal usa OpenStreetMap con respaldo Carto.
- El mapa satelital usa Esri con respaldo Carto para no quedar vacio.
- Se agrega indicador "Mapa blindado" / "Base local activa" cuando los tiles externos fallan.
- Se mantiene ubicacion exacta, importacion KML/KMZ, activos, rutas, tareas, evidencias e historial.

## 1.3.2+7 - Version 1.3.2 ubicacion exacta

- Se muestra marcador propio de "Mi ubicacion exacta" en Google Maps y en el mapa estable OpenStreetMap/Esri.
- Se muestra latitud/longitud con 7 decimales, precision en metros y hora de lectura.
- El boton de ubicacion centra el mapa a zoom 19 y solicita precision `bestForNavigation`.
- Se conserva Google como opcion manual con la clave nueva restringida a esta app.

## 1.3.1+6 - Version 1.3.1 anti-blanco definitivo

- El mapa ya no inicia en Google Maps.
- El arranque usa OpenStreetMap normal por defecto para evitar pantalla blanca por restricciones de API key.
- La vista satelital Esri sigue disponible desde el boton de capas.
- Google Maps queda como opcion manual "Probar Google" usando la API original del proyecto.
- Se conserva la importacion KML/KMZ y todas las funciones operativas locales.

## 1.3.0+5 - Version 1.3 mapa anti-blanco

- Google Maps se mantiene como motor principal de camara, ubicacion y marcadores.
- La base visual del mapa en modo Google ahora usa tiles OpenStreetMap/Esri mediante `tileOverlays`, evitando depender de los tiles base de Google.
- La vista normal usa OpenStreetMap y la vista satelital usa Esri World Imagery.
- Se conserva el boton "Respaldo mapa" para cambiar al render FlutterMap si el SDK de Google no inicializa en algun telefono.
- Se elimina la dependencia operativa de corregir Google Cloud antes de poder ver el mapa.

## 1.2.0+4 - Version 1.2 Google principal + respaldo

- Google Maps vuelve a ser el mapa principal de la app.
- El APK se debe compilar inyectando la API key original del proyecto base.
- Se agrega un boton visible "Respaldo mapa" sobre el mapa para cambiar a OpenStreetMap/Esri si Google queda bloqueado por restricciones de la llave.
- Se agrega selector en el panel lateral para alternar entre Google Maps y OpenStreetMap/Esri.
- Se mantiene la importacion visible de mapas anteriores KML/KMZ y todas las funciones operativas locales.

## 1.1.1+3 - Version 1.1 mapa estable

- El mapa ahora inicia en OpenStreetMap normal por defecto.
- La vista satelital Esri queda disponible desde el boton de capas, pero ya no es la vista inicial.
- Esta correccion busca evitar pantallas en blanco cuando el proveedor satelital o Google Maps no cargan.

## 1.1.0+2 - Version 1.1

- Correccion principal: el mapa visible ahora usa OpenStreetMap/Esri para evitar pantalla en blanco por restricciones de Google Maps.
- Se mantiene el boton visible para subir mapas anteriores KML/KMZ.
- Se conserva la gestion operativa local: rutas, tareas, evidencias, observaciones, historial y cola offline.
- APK debug separado como entrega V1.1.

## 1.0.0+1 - Version 1

- Mapa interactivo con OpenStreetMap/Esri, sin depender de API key para visualizarse.
- Importacion visible de mapas anteriores en formato KML/KMZ.
- Importacion por tipo de activo: cajas, trafos, gabinetes y concentradores.
- Estados por activo: activo, pendiente, danado y atendido.
- Rutas diarias automaticas por tecnico.
- Tareas generadas por activo importado.
- Evidencia obligatoria antes de completar una tarea.
- Observaciones tecnicas por punto.
- Historial de novedades local.
- Modo offline con cola local de sincronizacion.
- Panel basico de supervision.
- Persistencia local con `shared_preferences`.
- API key de Google Maps configurada fuera del codigo fuente.
