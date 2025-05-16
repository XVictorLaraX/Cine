import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PantallaUbicacion extends StatefulWidget {
  const PantallaUbicacion({super.key});

  @override
  State<PantallaUbicacion> createState() => _EstadoPantallaUbicacion();
}

class _EstadoPantallaUbicacion extends State<PantallaUbicacion>
    with AutomaticKeepAliveClientMixin {
  // Constructor por default
  @override
  bool get wantKeepAlive => true;

  String _textoCoordenadas = "";
  bool _cargando = false;
  String _ultimaActualizacion = "";
  LatLng? _miPosicionActual;
  LatLng? _destinoSeleccionado;
  List<LatLng> _puntosRuta = [];
  final MapController _controladorMapa = MapController();
  String? _cineSeleccionado;

  // Valores fijos para cada cineteca
  final Map<String, LatLng> _cinesDisponibles = {
    'Cineteca Nacional México': const LatLng(19.360724, -99.164477),
    'Cineteca Nacional de las Artes': const LatLng(19.356206, -99.135220),
    'Cineteca Nacional Chapultepec': const LatLng(19.388790, -99.228939),
  };
  // Funcion para solicitar permiso de acceder a la ubicación del dispositivo
  Future<Position> _obtenerPermisosUbicacion() async {
    bool servicioActivo;
    LocationPermission permiso;

    // Verificar si el GPS está activado
    servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return Future.error('Por favor activa tu GPS');
    }

    // Verificar permisos
    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return Future.error('Necesitamos acceso a tu ubicación');
      }
    }
    // Si la opción esta bloqueada en los ajustes del dispositivo
    if (permiso == LocationPermission.deniedForever) {
      return Future.error('Debes habilitar los permisos en ajustes');
    }

    return await Geolocator.getCurrentPosition();
  }
  // Recupera los datos de la ubicación
  Future<void> _guardarUbicacion(double latitud, double longitud) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión');
    }
    // Recupera los datos del usuario desde Firebase y adjunta los valores de su ubicación actual a otra coleccion
    try {
      await FirebaseFirestore.instance
          .collection('ubicaciones_usuarios')
          .doc(usuario.uid)
          .set({
        'userId': usuario.uid,
        'email': usuario.email,
        'latitud': latitud,
        'longitud': longitud,
        'fecha': FieldValue.serverTimestamp(),
        'fechaLegible': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
      }, SetOptions(merge: true));

      setState(() {
        _ultimaActualizacion = 'Última actualización: ${DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.now())}';
      });
    } catch (e) {
      debugPrint('Error al guardar: $e');
      rethrow;
    }
  }

  Future<void> _obtenerMiUbicacion() async {
    try {
      setState(() {
        _cargando = true;
        _textoCoordenadas = "Buscando tu ubicación...";
      });
      // No actua hasta que se acepte el uso de la ubicación
      final posicion = await _obtenerPermisosUbicacion();

      setState(() {
        _miPosicionActual = LatLng(posicion.latitude, posicion.longitude);
        _textoCoordenadas = "Latitud: ${posicion.latitude.toStringAsFixed(4)}\n"
            "Longitud: ${posicion.longitude.toStringAsFixed(4)}";

        _controladorMapa.move(_miPosicionActual!, 15.0);
      });

      await _guardarUbicacion(posicion.latitude, posicion.longitude);
    } catch (e) {
      setState(() {
        _textoCoordenadas = "Error: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oops! $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }
  // Función para dibujar una ruta hasta la cineteca elegida
  Future<void> _calcularRuta() async {
    if (_miPosicionActual == null || _destinoSeleccionado == null) return;

    setState(() {
      _cargando = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
              '${_miPosicionActual!.longitude},${_miPosicionActual!.latitude};'
              '${_destinoSeleccionado!.longitude},${_destinoSeleccionado!.latitude}'
              '?overview=full&geometries=geojson'
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          _puntosRuta = geometry.map((coord) =>
              LatLng(coord[1].toDouble(), coord[0].toDouble())
          ).toList();
        });
      } else {
        throw Exception('No se pudo calcular la ruta');
      }
    } catch (e) {
      debugPrint('Error en ruta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }
  // Elige una de las cinetecas
  void _seleccionarCine(String? value) {
    if (value == null) return;

    setState(() {
      _cineSeleccionado = value;
      _destinoSeleccionado = _cinesDisponibles[value];
    });

    if (_miPosicionActual != null) {
      _calcularRuta();
    }
  }
  // Limpia los datos anteriores
  void _limpiarSeleccion() {
    setState(() {
      _cineSeleccionado = null;
      _destinoSeleccionado = null;
      _puntosRuta.clear();
    });
  }
  // Widget para la pantalla
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      floatingActionButton: _destinoSeleccionado != null
          ? FloatingActionButton(
        onPressed: _limpiarSeleccion,
        child: const Icon(Icons.close),
      )
          : null,
      body: Column(
        children: [
          // Sección superior con controles
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Botón para obtener ubicación
                SizedBox(
                  width: double.infinity,
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _obtenerMiUbicacion,
                    child: const Text(
                      '¿Dónde estoy?',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de cines
                DropdownButtonFormField<String>(
                  value: _cineSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Selecciona una Cineteca',
                    border: OutlineInputBorder(),
                  ),
                  items: _cinesDisponibles.keys.map((String cine) {
                    return DropdownMenuItem<String>(
                      value: cine,
                      child: Text(cine),
                    );
                  }).toList(),
                  onChanged: _seleccionarCine,
                ),
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: FlutterMap(
              mapController: _controladorMapa,
              options: MapOptions(
                initialCenter: _miPosicionActual ?? const LatLng(19.4326, -99.1332),
                initialZoom: 12.0,
              ),
              children: [
                // Capa base del mapa
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),

                // Marcadores
                if (_miPosicionActual != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _miPosicionActual!,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      if (_destinoSeleccionado != null)
                        Marker(
                          point: _destinoSeleccionado!,
                          child: const Icon(
                            Icons.movie_creation,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                    ],
                  ),

                // Ruta
                if (_puntosRuta.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _puntosRuta,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Información de coordenadas
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _textoCoordenadas,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 9),
                if (_ultimaActualizacion.isNotEmpty)
                  Text(
                    _ultimaActualizacion,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}