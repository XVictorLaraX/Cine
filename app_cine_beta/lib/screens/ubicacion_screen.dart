import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  String _coordenadas = "";
  bool _isLoading = false;
  String _ultimaActualizacion = "";
  LatLng? _currentPosition;
  LatLng? _destinationPosition;
  List<LatLng> _polylinePoints = [];
  final MapController _mapController = MapController();
  String? _selectedLocation;

  final Map<String, LatLng> _locations = {
    'Cineteca Nacional México': const LatLng(19.36072431091757, -99.16447764797879),
    'Cineteca Nacional de las Artes': const LatLng(19.35620623782921, -99.13522033099476),
    'Cineteca Nacional Chapultepec': const LatLng(19.38879046129375, -99.2289394044762),
  };

  Future<Position> _determinarPosicion() async {
    bool serviceEnabled;
    LocationPermission permiso;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('El servicio de ubicación está desactivado');
    }

    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados');
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      return Future.error('Los permisos de ubicación fueron denegados permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _guardarUbicacionEnFirebase(double latitud, double longitud) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      await FirebaseFirestore.instance
          .collection('ubicaciones_usuarios')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'email': user.email,
        'latitud': latitud,
        'longitud': longitud,
        'fecha': FieldValue.serverTimestamp(),
        'fechaLegible': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
      }, SetOptions(merge: true));

      setState(() {
        _ultimaActualizacion = DateFormat('HH:mm:ss - dd/MM/yyyy').format(DateTime.now());
      });
    } catch (e) {
      debugPrint('Error al guardar ubicación: $e');
      rethrow;
    }
  }

  Future<void> obtenerCoordenadas() async {
    try {
      setState(() {
        _isLoading = true;
        _coordenadas = "Obteniendo ubicación...";
      });

      final posicion = await _determinarPosicion();

      setState(() {
        _currentPosition = LatLng(posicion.latitude, posicion.longitude);
        _coordenadas = "Latitud: ${posicion.latitude.toStringAsFixed(6)}\n"
            "Longitud: ${posicion.longitude.toStringAsFixed(6)}";

        _mapController.move(_currentPosition!, 15.0);
      });

      await _guardarUbicacionEnFirebase(posicion.latitude, posicion.longitude);
    } catch (e) {
      setState(() {
        _coordenadas = "Error: ${e.toString()}";
      });
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentPosition == null || _destinationPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
              '${_currentPosition!.longitude},${_currentPosition!.latitude};'
              '${_destinationPosition!.longitude},${_destinationPosition!.latitude}'
              '?overview=full&geometries=geojson'
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          _polylinePoints = geometry.map((coord) =>
              LatLng(coord[1].toDouble(), coord[0].toDouble())
          ).toList();
        });
      } else {
        throw Exception('Error al obtener la ruta: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calculando ruta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculando ruta: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void onLocationSelected(String? value) {
    if (value == null) return;

    setState(() {
      _selectedLocation = value;
      _destinationPosition = _locations[value];
    });

    if (_currentPosition != null) {
      _calculateRoute();
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedLocation = null;
      _destinationPosition = null;
      _polylinePoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      floatingActionButton: _destinationPosition != null
          ? FloatingActionButton(
        onPressed: _clearSelection,
        child: const Icon(Icons.clear),
      )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: obtenerCoordenadas,
                    child: const Text(
                      'Obtener mi Ubicación',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Selecciona una Cineteca',
                    border: OutlineInputBorder(),
                  ),
                  items: _locations.keys.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: onLocationSelected,
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition ?? const LatLng(19.4326, -99.1332),
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      if (_destinationPosition != null)
                        Marker(
                          point: _destinationPosition!,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                if (_polylinePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _polylinePoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _coordenadas,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 9),
                if (_ultimaActualizacion.isNotEmpty)
                  Text(
                    'Actualizado: $_ultimaActualizacion',
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