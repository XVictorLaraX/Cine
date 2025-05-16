import 'package:app_cine/pantallas/pantalla_saleccionar_asientos.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pantalla que muestra el resumen de la compra antes de seleccionar asientos
class PantallaResumen extends StatefulWidget {
  final String idPelicula;
  final String titulo;
  final String cineteca;
  final String horario;
  final String imagen;
  final DateTime fechaFuncion;

  const PantallaResumen({
    super.key,
    required this.idPelicula,
    required this.titulo,
    required this.cineteca,
    required this.horario,
    required this.imagen,
    required this.fechaFuncion,
  });

  @override
  State<PantallaResumen> createState() => _EstadoPantallaResumen();
}
// Valores por default
class _EstadoPantallaResumen extends State<PantallaResumen> {
  int _asientosSeleccionados = 1;  // Cantidad de asientos, mínimo 1
  double _precioAsiento = 0.0;     // Precio por cada asiento
  String _sala = 'Sala no asignada'; // Sala donde se proyecta
  bool _cargando = true;           // Flag para mostrar spinner

  @override
  void initState() {
    super.initState();
    _cargarDatosFuncion();  // Al iniciar, cargamos los datos de Firestore
  }

  // Método para traer los datos de la función desde Firestore
  Future<void> _cargarDatosFuncion() async {
    try {
      // Obtenemos el documento de la película
      final doc = await FirebaseFirestore.instance
          .collection('peliculas') // Busca la colección
          .doc(widget.idPelicula) //Busca el Id especifico entre todos los documentos
          .get();

      if (doc.exists) {
        final datos = doc.data()!;

        // Precio viene directo del documento (si no hay, ponemos 120 como default)
        setState(() {
          _precioAsiento = (datos['precio'] ?? 120.0).toDouble();
        });

        // La sala está en horariosPorCineteca -> [cineteca] -> salas -> [horario]
        final horariosCineteca = datos['horariosPorCineteca'] as Map<String, dynamic>? ?? {};
        final datosCineteca = horariosCineteca[widget.cineteca] as Map<String, dynamic>? ?? {};
        final salas = datosCineteca['salas'] as Map<String, dynamic>? ?? {};

        setState(() {
          _sala = salas[widget.horario] ?? 'Sala no asignada';
          _cargando = false;  // Ya terminamos de cargar
        });
      } else {
        // Si no existe el doc, ponemos valores por defecto
        setState(() {
          _precioAsiento = 120.0;
          _cargando = false;
        });
      }
    } catch (e) {
      // Por si algo falla, mostramos en consola y ponemos valores por defecto
      debugPrint('Error al cargar datos de la función: $e');
      setState(() {
        _precioAsiento = 120.0;
        _cargando = false;
      });
    }
  }
  // Widget de la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Compra'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())  // Spinner mientras carga
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta con la info de la película
            _crearTarjetaPelicula(),

            const SizedBox(height: 20),

            // Selector de cantidad de asientos
            _crearSelectorAsientos(),

            const SizedBox(height: 16),

            // Resumen del precio total
            _crearResumenPrecio(),

            const SizedBox(height: 24),

            // Botón para ir a seleccionar asientos
            _crearBotonAsientos(),
          ],
        ),
      ),
    );
  }

  // Widget que muestra la tarjeta con la info de la película
  Widget _crearTarjetaPelicula() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Imagen de la película (con placeholder por si falla)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.imagen,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.movie, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _crearFilaInfo(Icons.movie_filter, '${widget.cineteca}'),
            const SizedBox(height: 8),
            _crearFilaInfo(Icons.access_time, 'Horario: ${widget.horario}'),
            const SizedBox(height: 8),
            _crearFilaInfo(Icons.room, 'Sala: $_sala'),
            const SizedBox(height: 8),
            _crearFilaInfo(Icons.attach_money, 'Precio: \$${_precioAsiento.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  // Selector para la cantidad de asientos
  Widget _crearSelectorAsientos() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cantidad de asientos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón para disminuir cantidad
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red,
                  iconSize: 30,
                  onPressed: () {
                    if (_asientosSeleccionados > 1) {
                      setState(() {
                        _asientosSeleccionados--;
                      });
                    }
                  },
                ),
                // Cantidad actual de asientos seleccionados
                Text(
                  '$_asientosSeleccionados',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Botón para aumentar cantidad
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green,
                  iconSize: 30,
                  onPressed: () {
                    setState(() {
                      _asientosSeleccionados++;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget que muestra el resumen del precio
  Widget _crearResumenPrecio() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Precio por asiento:', style: TextStyle(fontSize: 16)),
                Text('\$${_precioAsiento.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '\$${(_precioAsiento * _asientosSeleccionados).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Botón grande para ir a seleccionar asientos
  Widget _crearBotonAsientos() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Navegamos a la pantalla de selección de asientos
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaSeleccionarAsiento(
                idPelicula: widget.idPelicula,
                titulo: widget.titulo,
                cineteca: widget.cineteca,
                horario: widget.horario,
                sala: _sala,
                cantidadAsientos: _asientosSeleccionados,
                precioTotal: _precioAsiento * _asientosSeleccionados,
                fechaFuncion: widget.fechaFuncion,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Seleccionar Asientos',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Widget para crear filas de información con icono
  Widget _crearFilaInfo(IconData icono, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}