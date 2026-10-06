export 'asset_point.dart';
export 'asset_status.dart';
export 'asset_type.dart';
export 'field_route.dart';
export 'field_task.dart';
export 'import_result.dart';
export 'operation_event.dart';
export 'operation_snapshot.dart';

class Usuario {
  const Usuario({required this.id, required this.nombre, required this.rol});

  final String id;
  final String nombre;
  final String rol;

  factory Usuario.fromMap(Map<String, dynamic> data, String documentId) {
    return Usuario(
      id: documentId,
      nombre: data['nombre'] as String? ?? '',
      rol: data['rol'] as String? ?? 'tecnico',
    );
  }

  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'rol': rol};
  }
}

class Caja {
  const Caja({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.estado,
  });

  final String id;
  final String nombre;
  final double lat;
  final double lng;
  final String estado;

  factory Caja.fromMap(Map<String, dynamic> data, String documentId) {
    return Caja(
      id: documentId,
      nombre: data['nombre'] as String? ?? '',
      lat: _readDouble(data['lat']),
      lng: _readDouble(data['lng']),
      estado: data['estado'] as String? ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'lat': lat, 'lng': lng, 'estado': estado};
  }
}

class Ruta {
  const Ruta({
    required this.id,
    required this.tecnicoId,
    required this.fecha,
    required this.estado,
  });

  final String id;
  final String tecnicoId;
  final String fecha;
  final String estado;

  factory Ruta.fromMap(Map<String, dynamic> data, String documentId) {
    return Ruta(
      id: documentId,
      tecnicoId: data['tecnicoId'] as String? ?? '',
      fecha: data['fecha'] as String? ?? '',
      estado: data['estado'] as String? ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {'tecnicoId': tecnicoId, 'fecha': fecha, 'estado': estado};
  }
}

class Tarea {
  const Tarea({
    required this.id,
    required this.cajaId,
    required this.rutaId,
    required this.estado,
  });

  final String id;
  final String cajaId;
  final String rutaId;
  final String estado;

  factory Tarea.fromMap(Map<String, dynamic> data, String documentId) {
    return Tarea(
      id: documentId,
      cajaId: data['cajaId'] as String? ?? '',
      rutaId: data['rutaId'] as String? ?? '',
      estado: data['estado'] as String? ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {'cajaId': cajaId, 'rutaId': rutaId, 'estado': estado};
  }
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse('$value') ?? 0;
}
